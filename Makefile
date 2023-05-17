########################################################################
# Makefile to build different stages of FlightGear scenery
#
# For some stages, instead of using the Makefile directly, you might
# want to use the do-make.sh shell script, which breaks a large area
# into smaller ones, and makes it easier to restart the build at a
# specific spot after a failure. It is especially useful for the
# "layers" and "scenery" targets.
#
#
# 1. Important Makefile configuration variables
#
# BUCKET - the bucket being build (e.g. w080n40)
#
# MIN_LON, MIN_LAT, MAX_LON, MAX_LAT - the bottom left and top right
# corners of the area being built (e.g. -80 40 -70 50)
#
# MAX_THREADS - the maximum number of concurrent threads to run for
# some processes (e.g. 8; increase to speed up the build; decrease to
# avoid crashes).
#
# PUBLISH_DIR- the directory where you want to upload scenery packages
# to the cloud (e.g. $HOME/Dropbox/Downloads)
#
#
# 2. Important targets
#
# 2.1. Data-extraction targets
#
# Extract raw data in INPUTS_DIR. Works at the BUCKET level.
#
# extract - run all extraction targets for the bucket.
#
# landcover-extract - extract landcover shapefile for the requested
# bucket
#
# osm-extract - extract OSM per-feature shapefiles for a bucket
#
#
# 2.2. Data-preparation targets
#
# Process data in INPUTS_DIR and place the output in DATA_DIR. Works
# at the BUCKET level.
#
# prepare - run all preparation targets for the requested bucket.
#
# landmass-prepare - prepare the landmass mask for the bucket.
#
# airports-prepare - prepare the airports file for the bucket.
#
# lc-shapefiles-prepare - prepare the background landcover shapefiles
# for the bucket.
#
# osm-shapefiles-prepare - prepare the detailed OSM features for the
# bucket.
#
#
# 2.3. Data-building targets
#
# Build the TerraGear input files for scenery, working at the latlon
# level (can build an area smaller than a full bucket).
#
# build - run the landmass, cliffs, airports, and layers targets for
# the requested area.
#
# landmass - build the landmass mask for the requested area.
#
# cliffs - build the cliffs metadata for the requested area (not yet
# working).
#
# airports - build the airport areas and objects for the requested
# area.
#
# layers - build the landcover and OSM layers for the requested area.
#
# The elevation-related targets should be run rarely, and may need to
# use an older version of TerraGear:
#
# elevations - build the elevation data from the *.hgt files in
# INPUT_DIR
#
# fit-elevations - fit the elevation data (may need to run across
# buckets; run with care).
#
#
# 2.4. Scenery-construction targets
#
# This can work on a 1x1 area or larger.
#
# scenery - build scenery for the requested area.
#
# 2.5. Publishing targets
#
# Publish a 10x10 deg bucket as a tarball.
#
# publish - prepare support files for a scenery distribution, create a
# tarball, and copy to the publish directory.
#
#
# 3. Author
#
# Written by David Megginson
#
########################################################################

SHELL=/bin/bash
MAX_THREADS=4

#
# What area are we building (override on the command line)
#
BUCKET=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50

# set automatically
SPAT=${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT}
LATLON=--min-lon=${MIN_LON} --min-lat=${MIN_LAT} --max-lon=${MAX_LON} --max-lat=${MAX_LAT}

#
# Build configuration variables
#

SCENERY_NAME=fgfs-canada-us-scenery
SCRIPT_DIR=./scripts
CONFIG_DIR=./config
INPUTS_DIR=./01-inputs
DATA_DIR=./02-prep
WORK_DIR=./03-work
OUTPUT_DIR=./04-output
STATIC_DIR=./static
SCENERY_DIR=${OUTPUT_DIR}/${SCENERY_NAME}
LANDCOVER_SOURCE_DIR=${INPUT_DIR}/MODIS-250
DECODE_OPTS=--spat ${SPAT} --threads ${MAX_THREADS}

PUBLISH_DIR="${HOME}/Dropbox/Downloads"

#
# Data sources
#

SRTM_BASE=${INPUTS_DIR}/SRTM-3
SRTM_SOURCE=${SRTM_BASE}/unpacked
AIRPORTS_SOURCE=${INPUTS_DIR}/airports/apt.dat
LANDCOVER_SOURCE_DIR=${INPUTS_DIR}/MODIS-250
OSM_DIR=${INPUTS_DIR}/osm

OSM_CONF=config/osmconf.ini


LANDMASS_SOURCE=${INPUTS_DIR}/land-polygons-split-4326/land_polygons.shp
LANDCOVER_SOURCE=${INPUTS_DIR}/MODIS-250/modis-250-wgs84-nulled.tif

#
# Data extracts (specific to bucket)
#
LANDMASS=${DATA_DIR}/landmass/${BUCKET}.shp
LANDCOVER=${DATA_DIR}/landcover/${BUCKET}.shp

#
# Top-level targets (assume elevations are already in place)
#

all: prepare build construct publish

extract: landcover-extract osm-extract

prepare: landmass-prepare airports-prepare lc-shapefiles-prepare osm-shapefiles-prepare 

build: landmass cliffs airports layers

rebuild: landmass-rebuild cliffs-rebuild airports-rebuild layers-rebuild

construct: scenery

publish: archive publish-cloud

# TEMP

clip-modis:
	ogrinfo -sql "create spatial index on ${BUCKET} depth 5" ${LANDCOVER_SOURCE_DIR}/${BUCKET}.shp
	ogr2ogr -clipsrc ${LANDMASS} ${LANDCOVER_SOURCE_DIR}/${BUCKET}-clipped.shp ${LANDCOVER_SOURCE_DIR}/${BUCKET}.shp

# qgis_process run native:clip --distance_units=meters --area_units=m2 --ellipsoid=PARAMETER:6370997:6370997 --INPUT=${LANDCOVER_SOURCE_DIR}/${BUCKET}.shp --OVERLAY=${LANDMASS_SOURCE} --OUTPUT=${LANDCOVER_SOURCE_DIR}/${BUCKET}-clipped.shp

########################################################################
# Scenery building
########################################################################

#
# Build elevation data from the SRTM-3 DEMs
#

elevations:
	for file in ${SRTM_SOURCE}/*.hgt; do \
	  hgtchop 3 $$file ${WORK_DIR}/SRTM-3 || exit 1; \
	done

# gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/${BUCKET}/*.hgt

elevations-clean:
	rm -rvf ${WORK_DIR}/SRTM-3/${BUCKET}/

elevations-clean-all:
	rm -rfv ${WORK_DIR}/SRTM-3/*

elevations-rebuild: elevations-clean elevations


fit-elevations:
	terrafit ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1


force-fit-elevations:
	terrafit ${WORK_DIR}/SRTM-3 -f -m 50 -x 22500 -e 1


#
# Build the airport areas and objects
#

airports:
	genapts850 --input=${DATA_DIR}/airports/${BUCKET}/apt.dat ${LATLON} --max-slope=0.2618 \
	  --work=${WORK_DIR} --dem-path=SRTM-3 # can't use threads here, due to errors with .idx files

airports-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${BUCKET}/ ${WORK_DIR}/AirportArea/${BUCKET}/

airports-rebuild: airports-clean airports


#
# Build the default landmass
#

landmass:
	ogr-decode ${DECODE_OPTS} --area-type Default ${WORK_DIR}/Default ${LANDMASS}

landmass-clean:
	rm -rvf ${WORK_DIR}/Default/${BUCKET}/

landmass-rebuild: landmass-clean landmass

#
# OSM and landcover layers
# The configuration for these is in layers.csv
#

# Build any layers that don't exist for this bucket
layers: areas lines

# Remove all layers for this bucket
layers-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET}/ ${WORK_DIR}/lc-*/${BUCKET}/

# Rebuild all layers for this bucket
layers-rebuild: layers-clean areas lines

# Build area layers
areas: lc-areas osm-areas

lc-areas:
	for row in $$(grep lc- ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done

osm-areas:
	for row in $$(grep osm- ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done

# Single area
AREA_MATERIAL ?= Town
AREA_LAYER ?= lc-urban
single-area:
	ogr-decode ${DECODE_OPTS} --area-type ${AREA_MATERIAL} ${WORK_DIR}/${AREA_LAYER} ${DATA_DIR}/shapefiles/${BUCKET}/${AREA_LAYER}.shp


# Build line layers
lines:
	for row in $$(grep ,line, ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,line,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done

# Single line
LINE_MATERIAL ?= Road-Secondary
LINE_LAYER ?= osm-motorway-highway
LINE_WIDTH ?= 10
single-line:
	ogr-decode ${DECODE_OPTS} --texture-lines --line-width ${LINE_WIDTH} --area-type ${LINE_MATERIAL} \
	  ${WORK_DIR}/${LINE_LAYER} ${DATA_DIR}/shapefiles/${BUCKET}/${LINE_LAYER}.shp;\


#
# Special handling for cliffs
#

cliffs:
	cliff-decode ${DECODE_OPTS} ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/${BUCKET}/osm-cliff-natural.shp

cliffs-clean:
	rm -vf ${WORK_DIR}/SRTM-3/${BUCKET}/*/*.cliffs

cliffs-rebuild: cliffs-clean cliffs

# optional step (probably not worth it for non-mountainous terrain)
rectify-cliffs:
	rectify_height ${LATLON} --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-dist=100

#
# Pull it all together and generate scenery in the output directory
#

scenery:
	tg-construct --threads=${MAX_THREADS} --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
	  ${LATLON} --priorities=${CONFIG_DIR}/default_priorities.txt --ignore-landmass \
	  Default AirportObj AirportArea SRTM-3  $$(ls ${WORK_DIR} | grep osm-) $$(ls ${WORK_DIR} | grep lc-) 

scenery-clean:
	rm -rf ${SCENERY_DIR}/Terrain/${BUCKET}/

static-files:
	cp -v ${STATIC_DIR}/* ${SCENERY_DIR}

#
# Generate custom threshold and navdata files for modified airports
#

thresholds:
	python3 ${SCRIPT_DIR}/gen-thresholds.py ${SCENERY_DIR}/Airports ${DATA_DIR}/airports/${BUCKET}/apt.dat

thresholds-clean:
	rm -rf ${SCENERY_DIR}/Airports

navdata:
	mkdir -p ${SCENERY_DIR}/NavData/apt
	cp -v ${DATA_DIR}/airports/${BUCKET}/apt.dat ${SCENERY_DIR}/NavData/apt/${BUCKET}.dat


########################################################################
# Data preparation (does not require TerraGear)
########################################################################

#
# Prepare landmass
#

landmass-prepare: ${LANDMASS}

landmass-prepare-clean:
	rm -rfv ${LANDMASS}

landmass-prepare-rebuild: landmass-prepare-clean landmass-prepare

${LANDMASS}: ${LANDMASS_SOURCE}
	ogr2ogr -spat ${SPAT} ${LANDMASS} ${LANDMASS_SOURCE}


#
# Prepare landcover for current bucket
#
landcover-extract: ${LANDCOVER}

landcover-extract-rebuild: landcover-extract-clean landcover-extract

landcover-extract-clean:
	rm -fv ${LANDCOVER_SOURCE_DIR}/work/${BUCKET}*
	rm -fv ${LANDCOVER}

${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-raw.tif: ${LANDCOVER_SOURCE_DIR}/modis-250-wgs84-nulled.tif
	gdalwarp -te ${SPAT} ${LANDCOVER_SOURCE_DIR}/modis-250-wgs84-nulled.tif $@
	echo foo # extract rectangle

${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-neighbors.tif: ${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-raw.tif
	qgis_process run grass7:r.neighbors --input=$< --output=$@ --method=2 --size=5

${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-vectorized.shp: ${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-neighbors.tif
	qgis_process run grass7:r.to.vect --input=$< --type=2 --column=value ---s=true --output=$@ --GRASS_REGION_CELLSIZE_PARAMETER=.001

${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-buffered.shp: ${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-vectorized.shp
	qgis_process run native:buffer --INPUT=$< --DISTANCE=0.005 --SEGMENTS=5 --END_CAP_STYLE=0 --JOIN_STYLE=0 --MITER_LIMIT=2 --OUTPUT=$@

${LANDCOVER}: ${LANDCOVER_SOURCE_DIR}/work/${BUCKET}-buffered.shp ${LANDMASS}
	mkdir -p ${DATA_DIR}/landcover
	qgis_process run native:clip --INPUT=$< --OVERLAY=${LANDMASS} --OUTPUT=$@

#
# Unpack downloaded SRTM-3 DEMs
#

srtm-unpack:
	${SHELL} ${SCRIPT_DIR}/unpack-dems.sh ${SRTM_BASE}

#
# Extract OSM from PBF
#

osm-extract:
	${SHELL} ${SCRIPT_DIR}/extract-osm-shapefiles.sh ${OSM_DIR} ${OSM_DIR}/shapefiles ${CONFIG_DIR}/osmconf.ini ${BUCKET}

osm-extract-clean:
	rm -rvf ${OSM_DIR}/shapefiles/${BUCKET}

#
# Prepare airports
#

airports-prepare:
	mkdir -p ${DATA_DIR}/airports/${BUCKET}/
	cat ${AIRPORTS_SOURCE} \
	| python3 ${SCRIPT_DIR}/downgrade-apt.py \
	| python3 ${SCRIPT_DIR}/filter-airports.py ${BUCKET} \
	> ${DATA_DIR}/airports/${BUCKET}/apt.dat

#
# Prepare shapefiles
#

shapefiles-prepare: lc-shapefiles-prepare osm-shapefiles-prepare

shapefiles-clean-bucket:
	rm -rfv ${DATA_DIR}/shapefiles/${BUCKET}/lc-* -rfv ${DATA_DIR}/shapefiles/${BUCKET}/osm-*

lc-shapefiles-prepare:
	grep ',yes,' ${CONFIG_DIR}/lc-extracts.csv \
	| while read -r row; do \
	  row=$$(echo "$$row" | sed -e 's/\r//'); \
	  value=$$(echo "$$row" | sed -e 's/,.*$$//'); \
	  dest=$$(echo "$$row" | sed -e 's/^.*,//'); \
          dest_dir=${DATA_DIR}/shapefiles/${BUCKET}; \
	  mkdir -p $$dest_dir; \
	  echo "Building $$dest for ${BUCKET}..."; \
	  ogr2ogr $$dest_dir/$$dest ${LANDCOVER} -sql "select * from ${BUCKET} where value='$$value'" || exit 1; \
	done

osm-shapefiles-prepare:
	grep ',yes,' ${CONFIG_DIR}/osm-extracts.csv \
	| while read -r row; do \
	    row=`echo "$$row" | sed -e 's/\r//'`; \
	    dest=$$(echo "$$row" | sed -e 's/,.*//'); \
	    source=$$(echo "$$row" | sed -e 's/.*,yes,//' -e 's/,.*//'); \
	    query=$$(echo "$$row" | sed -e 's/[^"]*["]//' -e 's/["]//'); \
	    source_dir=${OSM_DIR}/shapefiles/${BUCKET}; \
            dest_dir=${DATA_DIR}/shapefiles/${BUCKET}; \
	    mkdir -p $$dest_dir; \
	    echo "Creating $$dest..."; \
	    ogr2ogr $$dest_dir/$$dest $$source_dir/$$source -sql "$$query" || exit 1; \
	  done

#
# Simple target to prepare a single OSM feature (using a single attribute)
#
OSM_PREPARE_SOURCE=natural
OSM_PREPARE_FEATURE=forest
OSM_PREPARE_MIN_AREA=0.0001

# set automatically
OSM_PREPARE_INPUT=${OSM_DIR}/shapefiles/${BUCKET}/${OSM_PREPARE_SOURCE}.shp
OSM_PREPARE_OUTPUT=${DATA_DIR}/shapefiles/${BUCKET}/osm-${OSM_PREPARE_FEATURE}-${OSM_PREPARE_SOURCE}.shp
OSM_PREPARE_QUERY="select * from ${OSM_PREPARE_SOURCE} where ${OSM_PREPARE_SOURCE}='${OSM_PREPARE_FEATURE}' and OGR_GEOM_AREA > ${OSM_PREPARE_MIN_AREA}"

osm-single-shapefile-prepare:
	ogr2ogr ${OSM_PREPARE_OUTPUT} ${OSM_PREPARE_INPUT} -sql ${OSM_PREPARE_QUERY}

archive: static-files navdata thresholds-clean thresholds
	cd ${OUTPUT_DIR} \
	  && tar cvf fgfs-canada-us-scenery-${BUCKET}-$$(date +%Y%m%d).tar ${SCENERY_NAME}/README.md ${SCENERY_NAME}/UNLICENSE.md ${SCENERY_NAME}/clean-symlinks.sh ${SCENERY_NAME}/gen-symlinks.sh ${SCENERY_NAME}/Airports ${SCENERY_NAME}/NavData/apt/${BUCKET}.dat ${SCENERY_NAME}/Terrain/${BUCKET}

publish-cloud:
	cp -v ${STATIC_DIR}/README.md "${PUBLISH_DIR}"
	mv -v ${OUTPUT_DIR}/*.tar "${PUBLISH_DIR}"

########################################################################
# Test that do-make.sh is working
########################################################################

echo:
	echo -- BUCKET=${BUCKET} ${LATLON}
