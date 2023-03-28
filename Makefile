SHELL=/bin/bash

#
# What area are we building (override on the command line)
#
BUCKET=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50
SPAT=${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT}
LATLON=--min-lon=${MIN_LON} --min-lat=${MIN_LAT} --max-lon=${MAX_LON} --max-lat=${MAX_LAT}

#
# Build configuration variables
#

SCENERY_NAME=fgfs-canada-us-scenery
MAX_THREADS=16
SCRIPT_DIR=./scripts
CONFIG_DIR=./config
SOURCE_DIR=./source
DATA_DIR=./data
WORK_DIR=./work
OUTPUT_DIR=./output
SCENERY_DIR=${OUTPUT_DIR}/${SCENERY_NAME}
DECODE_OPTS=--spat ${SPAT} --threads ${MAX_THREADS}

#
# Data sources
#

AIRPORTS_SOURCE=${SOURCE_DIR}/airports/apt.dat
LC_DIR=${SOURCE_DIR}/MODIS-250
OSM_DIR=${SOURCE_DIR}/osm
SRTM_SOURCE=${SOURCE_DIR}/SRTM-3/unpacked
LANDMASS_SOURCE=${SOURCE_DIR}/land-polygons-split-4326/land_polygons.shp

#
# Top-level targets
#

all: elevations airports landmass layers cliffs scenery thresholds

all-rebuild: elevations-rebuild airports-rebuild landmass-rebuild layers-rebuild cliffs scenery thresholds

########################################################################
# Scenery building
########################################################################

#
# Build elevation data from the SRTM-3x
#

elevations:
	for file in ${SRTM_SOURCE}/*.hgt; do \
		hgtchop 3 $$file ${WORK_DIR}/SRTM-3; \
	done

# gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/${BUCKET}/*.hgt

elevations-clean:
	rm -rvf ${WORK_DIR}/SRTM-3/${BUCKET}/

elevations-clean-all:
	rm -rfv ${WORK_DIR}/SRTM-3/*

elevations-rebuild: elevations-clean elevations


fit-elevations:
	terrafit --threads ${MAX_THREADS} ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1



#
# Build the airport areas and objects
#

airports:
	genapts850 --threads --input=${DATA_DIR}/airports/${BUCKET}/apt.dat ${LATLON} \
	  --work=${WORK_DIR} --threads=${MAX_THREADS} --dem-path=SRTM-3

airports-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${BUCKET}/ ${WORK_DIR}/AirportArea/${BUCKET}/

airports-rebuild: airports-clean airports


#
# Build the default landmass
#

landmass:
	ogr-decode ${DECODE_OPTS} --area-type Default work/Default ${DATA_DIR}/landmass/${BUCKET}/land_polygons.shp

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
	      work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
	  fi; \
	done

osm-areas:
	for row in $$(grep osm- ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
	  fi; \
	done

# Single area
AREA_MATERIAL ?= Town
AREA_LAYER ?= lc-urban
single-area:
	ogr-decode ${DECODE_OPTS} --area-type ${AREA_MATERIAL} work/${AREA_LAYER} ${DATA_DIR}/shapefiles/${BUCKET}/${AREA_LAYER}.shp


# Build line layers
lines:
	for row in $$(grep ,line, ${CONFIG_DIR}/layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,line,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} \
	      work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
	  fi; \
	done

# Single line
LINE_MATERIAL ?= Road-Secondary
LINE_LAYER ?= osm-motorway-highway
LINE_WIDTH ?= 10
single-line:
	ogr-decode ${DECODE_OPTS} --texture-lines --line-width ${LINE_WIDTH} --area-type ${LINE_MATERIAL} \
	  work/${LINE_LAYER} ${DATA_DIR}/shapefiles/${BUCKET}/${LINE_LAYER}.shp;\


#
# Special handling for cliffs
#

cliffs:
	cliff-decode --log-level bulk --all-threads --spat ${SPAT} ${WORK_DIR}/SRTM-3/${BUCKET} ${DATA_DIR}/shapefiles/${BUCKET}/osm-cliff-natural.shp

# optional step (probably not worth it for non-mountainous terrain)
rectify-cliffs:
	rectify_height ${LATLON} --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-dist=100

#
# Pull it all together and generate scenery in the output directory
#

scenery:
	tg-construct --threads --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
	  ${LATLON} --priorities=${CONFIG_DIR}/default_priorities.txt \
	  Default AirportObj AirportArea SRTM-3 \
	  $$(ls ${WORK_DIR} | grep osm-) \
	  $$(ls ${WORK_DIR} | grep lc-)
	cp -v gen-symlinks.sh clean-symlinks.sh ${SCENERY_DIR}

#
# Generate custom threshold and navdata files for modified airports
#

thresholds:
	python3 ${SCRIPT_DIR}/gen-thresholds.py ${SCENERY_DIR}/Airports ${DATA_DIR}/airports/modified/${BUCKET}/*.apt.dat

thresholds-clean:
	rm -rf ${DATA_DIR}/Airports

navdata:
	mkdir -p ${SCENERY_DIR}/NavData/apt
	cp -v ${DATA_DIR}/airports/modified/${BUCKET}/*.apt.dat ${SCENERY_DIR}/NavData/apt


########################################################################
# Data preparation (does not require TerraGear)
########################################################################

#
# Prepare landmass
#

landmass-source-prepare:
	mkdir -p data/landmass/${BUCKET}/
	ogr2ogr -spat ${SPAT} ${DATA_DIR}/landmass/${BUCKET}/ ${LANDMASS_SOURCE}

landmass-source-clean:
	rm -rf ${DATA_DIR}/landmass/${BUCKET}/

landmass-source-rebuild: landmass-source-clean landmass-source-prepare


#
# Prepare airports
#

airports-prepare:
	mkdir -p data/airports/${BUCKET}/
	cat ${AIRPORTS_SOURCE} \
	| python3 ${SCRIPT_DIR}downgrade-apt.py \
	| python3 ${CONFIG_DIR}/filter-airports.py ${BUCKET} \
	> data/airports/${BUCKET}/apt.dat

#airports-source-prepare:
#	zcat ${DATA_DIR}/airports/apt.dat.gz | python3 ${SCRIPT_DIR}/split-airports.py ${DATA_DIR}/airports/split
#	BUCKET=${BUCKET} sh ${SCRIPT_DIR}/merge-airports.sh > ${DATA_DIR}/airports/modified.apt.dat

#airports-source-clean:
#	rm -f ${DATA_DIR}/airports/modified.apt.dat ${DATA_DIR}/airports/original/*

airports-source-rebuild: airports-source-clean airports-source-rebuild


#
# Prepare landcover shapefiles
#

lc-shapefiles-prepare:
	grep ',yes,' ${CONFIG_DIR}/lc-extracts.csv \
	| while read -r row; do \
	  row=$$(echo "$$row" | sed -e 's/\r//'); \
	  value=$$(echo "$$row" | sed -e 's/,.*$$//'); \
	  dest=$$(echo "$$row" | sed -e 's/^.*,//'); \
	  source_dir=${LC_DIR}; \
          dest_dir=${DATA_DIR}/shapefiles/${BUCKET}; \
	  mkdir -p $$dest_dir; \
	  echo "Building $$dest for ${BUCKET}..."; \
	  ogr2ogr $$dest_dir/$$dest $$source_dir/${BUCKET}.shp -sql "select * from ${BUCKET} where value='$$value'"; \
	done

# TODO lc shapefiles

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
	    if [ ! -e $$dest_dir/$$dest ]; then \
	      echo "Creating $$dest..."; \
	      ogr2ogr $$dest_dir/$$dest $$source_dir/$$source \
	        -sql "$$query"; \
	    fi; \
	  done

osm-shapefiles-clean:
	rm -fv ${DATA_DIR}/shapefiles/${BUCKET}/osm-*

osm-shapefiles-rebuild: osm-shapefiles-clean osm-shapefiles-prepare

archive:
	cd ${OUTPUT_DIR} && tar cvf fgfs-canada-us-scenery-${BUCKET}-$$(date +%Y%m%d).tar ${SCENERY_NAME}/README.md ${SCENERY_NAME}/UNLICENSE.md ${SCENERY_NAME}/clean-symlinks.sh ${SCENERY_NAME}/gen-symlinks.sh ${SCENERY_NAME}/Airports ${SCENERY_NAME}/NavData ${SCENERY_NAME}/Terrain/${BUCKET}


########################################################################
# Test that do-make.sh is working
########################################################################

echo:
	echo -- BUCKET=${BUCKET} ${LATLON}
