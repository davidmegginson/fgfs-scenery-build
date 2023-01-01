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

MAX_THREADS=1
DATA_DIR=./data
WORK_DIR=./work
OUTPUT_DIR=./output
DECODE_OPTS=--spat ${SPAT} --threads ${MAX_THREADS}

#
# Data sources
#

OSM_DIR=../osm
LANDMASS_SOURCE=../land-polygons-split-4326/land_polygons.shp

#
# Top-level targets
#

all: elevations airports landmass layers cliffs scenery

all-rebuild: elevations-rebuild airports-rebuild landmass-rebuild layers-rebuild scenery

########################################################################
# Scenery building
########################################################################

#
# Build elevation data from the SRTM-3x
#

elevations:
	gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/${BUCKET}/*.hgt; \
	terrafit ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1; \

elevations-clean:
	rm -rvf ${WORK_DIR}/SRTM-3/${BUCKET}/

elevations-rebuild: elevations-clean elevations


#
# Build the airport areas and objects
#

airports:
	genapts850 --input=${DATA_DIR}/airports/modified.apt.dat ${LATLON} \
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
areas:
	for row in $$(grep ,area, layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,area,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
	      work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
	  fi; \
	done

# Single area
MATERIAL ?= TOWN
LAYER ?= lc-urban
single-area:
	ogr-decode ${DECODE_OPTS} --area-type ${MATERIAL} work/${LAYER} ${DATA_DIR}/shapefiles/${BUCKET}/${LAYER}.shp

# Build line layers
lines:
	for row in $$(grep ,line, layers.csv); do \
	  row=`echo $$row | sed -e 's/\r//'`; \
	  if echo $$row | grep ',yes,line,' > /dev/null; then \
	    readarray -d ',' -t F <<< $$row; \
	    echo Trying $${F[0]}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} \
	      work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
	  fi; \
	done

#
# Special handling for cliffs
#

cliffs:
	cliff-decode ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/${BUCKET}/osm-cliff-natural.shp
	rectify_height --work-dir=${WORK_DIR} --height-dir=SRTM-3 ${LATLON} --min-dist=100

#
# Pull it all together and generate scenery in the output directory
#

scenery:
	tg-construct --threads=${MAX_THREADS} --work-dir=${WORK_DIR} --output-dir=${OUTPUT_DIR}/Terrain \
	  ${LATLON} --priorities=./default_priorities.txt \
	  Default AirportObj AirportArea SRTM-3 \
	  $$(ls ${WORK_DIR} | grep osm-) \
	  $$(ls ${WORK_DIR} | grep lc-)


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

airports-source-prepare:
	zcat ${DATA_DIR}/airports/apt.dat.gz | python3 split-airports.py ${DATA_DIR}/airports/original
	sh merge-airports.sh > ${DATA_DIR}/airports/modified.apt.dat

airports-source-clean:
	rm -f ${DATA_DIR}/airports/modified.apt.dat ${DATA_DIR}/airports/original/*

airports-source-rebuild: airports-source-clean airports-source-rebuild


#
# Prepare landcover shapefiles
#

shapefiles-prepare:
	grep ',yes,' osm-extracts.csv \
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

shapefiles-clean:
	rm -fv ${DATA_DIR}/shapefiles/${BUCKET}/osm-*

shapefiles-rebuild: shapefiles-clean shapefiles-prepare


########################################################################
# Test that do-make.sh is working
########################################################################

echo:
	echo -- BUCKET=${BUCKET} ${LATLON}
