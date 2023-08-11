#######################################################################
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
# BUCKET - **required** the bucket being build (e.g. w080n40)
#
# MIN_LON, MIN_LAT, MAX_LON, MAX_LAT - the bottom left and top right
# corners of the area being built (e.g. -80 40 -70 50); default to the
# corners of the bucket.
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
# extract
#   run *all* extraction targets for the bucket.
#
# landcover-extract
#   extract landcover shapefile for the requested bucket
#
# osm-extract
#   extract OSM per-feature shapefiles for a bucket
#
#
# 2.2. Data-preparation targets
#
# Process data in INPUTS_DIR and place the output in DATA_DIR. Works
# at the BUCKET level.
#
# prepare
#   run *all* preparation targets for the requested bucket.
#
# landmass-prepare
#   prepare the landmass mask for the bucket.
#
# airports-prepare
#   prepare the airports file for the bucket.
#
# landcover-shapefiles-prepare
#   prepare the background landcover shapefiles for the bucket.
#
# osm-shapefiles-prepare
#   prepare the detailed OSM features for the bucket.
#
#
# 2.3. Data-building targets
#
# Build the TerraGear input files for scenery, working at the latlon
# level (can build an area smaller than a full bucket).
#
# build
#   run *all* build targets for the requested area.
#
# landmass
#   build the landmass mask for the requested area.
#
# airports
#   build the airport areas and objects for the requested area.
#
# layers
#   build the landcover and OSM layers for the requested area.
#
# 2.3.1 Elevation (DEM) targets
#
# The elevation-related targets should be run rarely, and may need to
# use an older version of TerraGear. Set the DEM Makefile variable to
# "FABDEM" (default) or "SRTM-3" to choose the data source.
#
# elevations
#   build the elevation data from the *.hgt or *.tif files in INPUT_DIR 
#
# 2.4. Scenery-construction targets
#
# This can work on a 1x1 deg area or larger.
#
# scenery
#   build scenery for the requested area.
#
# 2.5. Publishing targets
#
# Publish a 10x10 deg bucket as a tarball.
#
# publish
#   prepare support files for a scenery distribution, create a
#   tarball, and copy to the publish directory.
#
# update-download-links
#   update the Dropbox download links and push a new version of the
#   website (requires an access token in config/dropbox-config.json)
#
#
# 3. Author
#
# Written by David Megginson
#
########################################################################

# Basic setup
SHELL=/bin/bash
MAX_THREADS=1

# Directories
SCENERY_NAME=fgfs-canada-us-scenery
CONFIG_DIR=./config
INPUTS_DIR=./01-inputs
DATA_DIR=./02-prep
WORK_DIR=./03-work
OUTPUT_DIR=./04-output
SCRIPT_DIR=./scripts
STATIC_DIR=./static
HTML_DIR=./docs
SCENERY_DIR=${OUTPUT_DIR}/${SCENERY_NAME}
LANDCOVER_SOURCE_DIR=${INPUTS_DIR}/MODIS-250
PUBLISH_DIR="${HOME}/Dropbox/Downloads"

# What area are we building (must be set)
ifndef BUCKET
$(error BUCKET is not defined)
endif

# default bounds if not overridden
MIN_LON?=$(shell ${SHELL} ${SCRIPT_DIR}/bucket.sh ${BUCKET} | cut -d ' ' -f 1)
MIN_LAT?=$(shell ${SHELL} ${SCRIPT_DIR}/bucket.sh ${BUCKET} | cut -d ' ' -f 2)
MAX_LON?=$(shell ${SHELL} ${SCRIPT_DIR}/bucket.sh ${BUCKET} | cut -d ' ' -f 3)
MAX_LAT?=$(shell ${SHELL} ${SCRIPT_DIR}/bucket.sh ${BUCKET} | cut -d ' ' -f 4)

# common command-line parameters
SPAT=${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT}
LATLON=--min-lon=${MIN_LON} --min-lat=${MIN_LAT} --max-lon=${MAX_LON} --max-lat=${MAX_LAT}
DECODE_OPTS=--spat ${SPAT} --threads ${MAX_THREADS}
TERRAFIT_OPTS=-j ${MAX_THREADS} -m 50 -x 10000 -e 10

#
# Data sources
#

AIRPORTS_SOURCE=${INPUTS_DIR}/airports/apt.dat
LANDCOVER_SOURCE_DIR=${INPUTS_DIR}/MODIS-250

OSM_DIR=${INPUTS_DIR}/osm
OSM_SOURCE=${OSM_DIR}/north-america-latest.osm.pbf
OSM_CONF=config/osmconf.ini

LANDMASS_SOURCE=${INPUTS_DIR}/land-polygons-split-4326/land_polygons.shp # complete version is very slow
LANDCOVER_BASE=modis-250-clipped
LANDCOVER_SOURCE=${LANDCOVER_SOURCE_DIR}/${LANDCOVER_BASE}.shp

# Output dir for per-area shapefiles
SHAPEFILES_DIR=${DATA_DIR}/shapefiles/${BUCKET}

# DEM type (SRTM-3 or FABDEM); FABDEM is higher res, but goes only to 80N
DEM=FABDEM

#
# Data extracts (specific to bucket)
#

OSM_PBF=${OSM_DIR}/${BUCKET}.osm.pbf

LANDMASS=${DATA_DIR}/landmass/${BUCKET}.shp
LANDCOVER=${DATA_DIR}/landcover/${BUCKET}.shp
AIRPORTS=${DATA_DIR}/airports/${BUCKET}/apt.dat

#
# Build flags
#

FLAGS_BASE=./flags
FLAGS_DIR=${FLAGS_BASE}/${BUCKET}

OSM_SHAPEFILES_EXTRACTED_FLAG=${FLAGS_DIR}/osm-shapefiles-extracted.flag

LANDCOVER_SHAPEFILES_PREPARED_FLAG=${FLAGS_DIR}/landcover-shapefiles-prepared.flag
OSM_SHAPEFILES_PREPARED_FLAG=${FLAGS_DIR}/osm-shapefiles-prepared.flag

ELEVATIONS_FLAG=${FLAGS_DIR}/${DEM}-elevations.flag # depends on DEM as well as BUCKET
ELEVATIONS_FIT_FLAG=${FLAGS_DIR}/${DEM}-elevations-fit.flag
AIRPORTS_FLAG=${FLAGS_DIR}/${DEM}-airports.flag # depends on DEM as well as BUCKET
LANDMASS_FLAG=${FLAGS_DIR}/landmass.flag
LANDCOVER_LAYERS_FLAG=${FLAGS_DIR}/landcover-areas.flag
OSM_AREA_LAYERS_FLAG=${FLAGS_DIR}/osm-areas.flag
OSM_LINE_LAYERS_FLAG=${FLAGS_DIR}/osm-lines.flag

#
# Python virtual environment
#
VENV=./venv/bin/activate

#
# Top-level targets (assume elevations are already in place)
#

all: prepare build construct publish

construct: scenery

reconstruct: scenery-rebuild

publish: archive publish-cloud


########################################################################
# 1. Extract
########################################################################

extract: landcover-extract osm-extract

#
# Prepare landcover for current bucket (single file; no flag needed)
#

landcover-extract: ${LANDCOVER}

landcover-extract-rebuild: landcover-extract-clean landcover-extract

landcover-extract-clean:
	rm -fv ${LANDCOVER}

${LANDCOVER}: ${LANDCOVER_SOURCE}
	ogr2ogr -spat ${SPAT} $@ $<

#
# Clip PBF to speed processing
#

osm-extract: ${OSM_SHAPEFILES_EXTRACTED_FLAG}

${OSM_SHAPEFILES_EXTRACTED_FLAG}: ${OSM_PBF} ${OSM_CONF} ${SCRIPT_DIR}/extract-osm-shapefiles.sh
	rm -f $@
	${SHELL} ${SCRIPT_DIR}/extract-osm-shapefiles.sh ${OSM_DIR} ${OSM_DIR}/shapefiles ${OSM_CONF} ${BUCKET}
	mkdir -p ${FLAGS_DIR} && touch $@

${OSM_PBF}: ${OSM_SOURCE} # clip PBF to bucket to make processing more efficient; no flag needed
	osmconvert $< -v -b=${MIN_LON},${MIN_LAT},${MAX_LON},${MAX_LAT} --complete-ways --complete-multipolygons --complete-boundaries -o=$@

osm-extract-clean:
	rm -rvf ${OSM_DIR}/shapefiles/${BUCKET} ${OSM_SHAPEFILES_EXTRACTED_FLAG}


########################################################################
# 2. Prepare
########################################################################

prepare: landmass-prepare airports-prepare shapefiles-prepare

prepare-clean: landmass-prepare-clean airports-prepare-clean shapefiles-prepare-clean

#
# Prepare landmass (single file; no flag needed)
#

landmass-prepare: ${LANDMASS}

landmass-prepare-clean:
	rm -rfv  ${LANDMASS}

landmass-prepare-rebuild: landmass-prepare-clean landmass-prepare

${LANDMASS}: ${LANDMASS_SOURCE}
	ogr2ogr -spat ${SPAT} ${LANDMASS} ${LANDMASS_SOURCE}

#
# Prepare airports
#

airports-prepare: ${AIRPORTS} # single file - no flag needed

${AIRPORTS}: ${VENV} ${AIRPORTS_SOURCE}
	mkdir -p ${DATA_DIR}/airports/${BUCKET}/
	. ${VENV} && cat ${AIRPORTS_SOURCE} \
	| python3 ${SCRIPT_DIR}/downgrade-apt.py \
	| python3 ${SCRIPT_DIR}/filter-airports.py ${BUCKET} \
	> $@

#
# Prepare shapefiles
#

shapefiles-prepare: landcover-shapefiles-prepare osm-shapefiles-prepare

shapefiles-clean: landcover-shapefiles-clean osm-shapefiles-clean

landcover-shapefiles-prepare: ${LANDCOVER_SHAPEFILES_PREPARED_FLAG}

${LANDCOVER_SHAPEFILES_PREPARED_FLAG}: ${LANDCOVER} ${CONFIG_DIR}/lc-extracts.csv
	rm -f $@
	grep ',yes,' ${CONFIG_DIR}/lc-extracts.csv \
	| while read -r row; do \
	  row=$$(echo "$$row" | sed -e 's/\r//'); \
	  value=$$(echo "$$row" | sed -e 's/,.*$$//'); \
	  dest=$$(echo "$$row" | sed -e 's/^.*,//'); \
          dest_dir=${SHAPEFILES_DIR}; \
	  mkdir -p $$dest_dir; \
	  echo "Building $$dest for ${BUCKET}..."; \
	  ogr2ogr $$dest_dir/$$dest ${LANDCOVER} -sql "select * from ${BUCKET} where value='$$value'" || exit 1; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

landcover-shapefiles-clean:
	rm -rfv ${SHAPEFILES_DIR}/lc-* ${LANDCOVER_SHAPEFILES_PREPARED_FLAG}

osm-shapefiles-prepare: ${OSM_SHAPEFILES_PREPARED_FLAG}

${OSM_SHAPEFILES_PREPARED_FLAG}: ${OSM_SHAPEFILES_EXTRACTED_FLAG} ${CONFIG_DIR}/osm-extracts.csv
	rm -f $@
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
	mkdir -p ${FLAGS_DIR} && touch $@

osm-shapefiles-clean:
	rm -rfv ${SHAPEFILES_DIR}/osm-* ${OSM_SHAPEFILES_PREPARED_FLAG}



########################################################################
# 3. Build (excludes elevations; must be done manually
########################################################################

build: elevations airports landmass layers

rebuild: airports-rebuild landmass-rebuild layers-rebuild

build-clean: airports-clean landmass-clean layers-clean

#
# Build elevation data from the DEMs
# Set the Makefile var DEM to SRTM-3 or FABDEM (default)
#

elevations: ${ELEVATIONS_FIT_FLAG}

elevations-fit: ${ELEVATIONS_FIT_FLAG}

${ELEVATIONS_FLAG}:
	rm -f ${ELEVATIONS_FLAG}
	find ${INPUTS_DIR}/${DEM}/Unpacked/${BUCKET} -type f | xargs gdalchop ${WORK_DIR}/${DEM}
	mkdir -p ${FLAGS_DIR} && touch ${ELEVATIONS_FLAG}

${ELEVATIONS_FIT_FLAG}: ${ELEVATIONS_FLAG}
	rm -f ${ELEVATIONS_FIT_FLAG}
	terrafit ${WORK_DIR}/${DEM}/${BUCKET} ${TERRAFIT_OPTS}
	mkdir -p ${FLAGS_DIR} && touch ${ELEVATIONS_FIT_FLAG}

elevations-rebuild: elevations-clean elevations

elevations-fit-all:
	terrafit ${WORK_DIR}/${DEM} ${TERRAFIT_OPTS}

elevations-fit-force-all:
	terrafit ${WORK_DIR}/${DEM} -f ${TERRAFIT_OPTS} # refit every time

elevations-clean:
	rm -rvf ${WORK_DIR}/${DEM}/${BUCKET}/ ${ELEVATIONS_FLAG} ${FIT_IN_PROGRESS_FLAG}

#
# Build the airport areas and objects
#

airports: ${AIRPORTS_FLAG}

${AIRPORTS_FLAG}: ${AIRPORTS} ${ELEVATIONS_FIT_FLAG}
	rm -f ${AIRPORTS_FLAG}
	genapts850 --input=${AIRPORTS} ${LATLON} --max-slope=0.2618 \
	  --work=${WORK_DIR} --dem-path=${DEM} # can't use threads here, due to errors with .idx files; not SRTM-3
	mkdir -p ${FLAGS_DIR} && touch ${AIRPORTS_FLAG}

airports-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${BUCKET}/ ${WORK_DIR}/AirportArea/${BUCKET}/ ${AIRPORTS_FLAG}

airports-rebuild: airports-clean airports


#
# Build the default landmass
#

landmass: ${LANDMASS_FLAG}

${LANDMASS_FLAG}: ${LANDMASS}
	rm -f ${LANDMASS_FLAG}
	ogr-decode ${DECODE_OPTS} --area-type Default ${WORK_DIR}/Default ${LANDMASS}
	mkdir -p ${FLAGS_DIR} && touch ${LANDMASS_FLAG}

landmass-clean:
	rm -rvf ${WORK_DIR}/Default/${BUCKET}/ ${LANDMASS_FLAG}

landmass-rebuild: landmass-clean landmass

#
# OSM and landcover layers
# The configuration for these is in layers.csv
#

# Build any layers that don't exist for this bucket
layers: areas lines

# Remove all layers for this bucket
layers-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET}/ ${WORK_DIR}/lc-*/${BUCKET}/ ${LANDCOVER_LAYERS_FLAG} ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

# Rebuild all layers for this bucket
layers-rebuild: layers-clean areas lines

# Build area layers
areas: landcover-areas osm-areas

# Build line layers
lines: osm-lines

landcover-areas: ${LANDCOVER_LAYERS_FLAG}

${LANDCOVER_LAYERS_FLAG}: ${CONFIG_DIR}/layers.csv
	rm -f $@
	for row in $$(grep lc- ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

landcover-clean:
	rm -rfv ${WORK_DIR}/lc-*/${BUCKET}/ ${LANDCOVER_LAYERS_FLAG}

osm-areas: ${OSM_AREA_LAYERS_FLAG}

${OSM_AREA_LAYERS_FLAG}: ${CONFIG_DIR}/layers.csv
	rm -rf $@
	for row in $$(grep osm- ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

osm-lines: ${OSM_LINE_LAYERS_FLAG}

${OSM_LINE_LAYERS_FLAG}: ${CONFIG_DIR}/layers.csv
	rm -rf $@
	for row in $$(grep ,line, ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,line,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} \
	      ${WORK_DIR}/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

osm-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET}/ ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

#
# Special handling for cliffs (this is wrong right now)
#

#cliffs:
#	cliff-decode ${DECODE_OPTS} ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/${BUCKET}/osm-cliff-natural.shp

#cliffs-clean:
#	rm -vf ${WORK_DIR}/SRTM-3/${BUCKET}/*/*.cliffs

#cliffs-rebuild: cliffs-clean cliffs

# optional step (probably not worth it for non-mountainous terrain)
#rectify-cliffs:
#	rectify_height ${LATLON} --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-dist=100


########################################################################
# 4. Construct
########################################################################

scenery: # no dependencies, because we run this in smaller batches
	mkdir -p ${SCENERY_DIR}/Terrain/${BUCKET}
	tg-construct --threads=${MAX_THREADS} --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
	  ${LATLON} --priorities=${CONFIG_DIR}/default_priorities.txt \
	  ${DEM} Default AirportObj AirportArea $$(ls ${WORK_DIR} | grep osm-) $$(ls ${WORK_DIR} | grep lc-) # not SRTM

scenery-clean:
	rm -rf ${SCENERY_DIR}/Terrain/${BUCKET}/

scenery-rebuild: scenery-clean scenery

static-files:
	cp -v ${STATIC_DIR}/* ${SCENERY_DIR}

#
# Generate custom threshold and navdata files for modified airports
#

thresholds: ${VENV}
	. ${VENV} && python3 ${SCRIPT_DIR}/gen-thresholds.py ${SCENERY_DIR}/Airports ${DATA_DIR}/airports/${BUCKET}/apt.dat

thresholds-clean:
	rm -rf ${SCENERY_DIR}/Airports

navdata:
	mkdir -p ${SCENERY_DIR}/NavData/apt
	cp -v ${DATA_DIR}/airports/${BUCKET}/apt.dat ${SCENERY_DIR}/NavData/apt/${BUCKET}.dat


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

archive: static-files navdata thresholds-clean thresholds
	cd ${OUTPUT_DIR} \
	  && tar cvf fgfs-canada-us-scenery-${BUCKET}-$$(date +%Y%m%d).tar ${SCENERY_NAME}/README.md ${SCENERY_NAME}/UNLICENSE.md ${SCENERY_NAME}/clean-symlinks.sh ${SCENERY_NAME}/gen-symlinks.sh ${SCENERY_NAME}/Airports ${SCENERY_NAME}/NavData/apt/${BUCKET}.dat ${SCENERY_NAME}/Terrain/${BUCKET}

# Will move
publish-cloud:
	cp -v ${STATIC_DIR}/README.md "${PUBLISH_DIR}" \
	  && mkdir -p "${PUBLISH_DIR}"/Old \
	  && (mv -fv "${PUBLISH_DIR}"/*-${BUCKET}-*.tar "${PUBLISH_DIR}"/Old || echo "No previous file") \
	  && mv -fv "${OUTPUT_DIR}"/*-${BUCKET}-*.tar "${PUBLISH_DIR}"

update-download-links: ${VENV}
	. ${VENV} && python3 ${SCRIPT_DIR}/make-download-links.py ${CONFIG_DIR}/dropbox-config.json ${HTML_DIR}/download-links.txt > ${HTML_DIR}/download-links.json
	git checkout main
	git add ${HTML_DIR}/download-links.json ${HTML_DIR}/download-links.txt
	git commit -m 'Update download links'
	git push origin main

#
# Set up Python when needed
#
${VENV}: requirements.txt
	python3 -m venv venv && . ${VENV} && pip3 install -r requirements.txt

${FLAGS_DIR}:
	mkdir -p ${FLAGS_DIR}

########################################################################
# Test that do-make.sh is working
########################################################################

echo:
	echo -- BUCKET=${BUCKET} ${LATLON}
