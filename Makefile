# What area are we building?
AREA=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50

# Standard setup
SHELL=/bin/bash
DATA_DIR=./data
WORK_DIR=./work
OUTPUT_DIR=./output
DECODE_OPTS=--spat ${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT} --threads 2

# Steps that require TerraGear (prepare-airports needs Python, which isn't in the Docker image)
all: elevations airports landmass layers scenery

all-rebuild: elevations-rebuild airports-rebuild landmass-rebuild layers-rebuild scenery

# Build elevation data from the SRTM-3x
elevations:
	if [ ! -d ${WORK_DIR}/SRTM-3/${AREA} ]; then \
	  gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/${AREA}/*.hgt; \
	  terrafit ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1; \
	fi

elevations-clean:
	rm -rvf ${WORK_DIR}/SRTM-3/${AREA}/

elevations-rebuild: elevations-clean elevations


# Build the airport areas and objects
airports:
	if [ ! -d ${WORK_DIR}/AirportObj/${AREA}/ ]; then \
	  genapts850 --input=${DATA_DIR}/airports/modified.apt.dat --work=${WORK_DIR} --threads=4 \
		--dem-path=SRTM-3 \
		--min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT}; \
	fi

airports-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${AREA}/ ${WORK_DIR}/AirportArea/${AREA}/

airports-rebuild: airports-clean airports


# Build the default landmass
landmass:
	if [ ! -d ${WORK_DIR}/Default/${AREA}/ ]; then \
	  ogr-decode ${DECODE_OPTS} --area-type Default work/Default ${DATA_DIR}/land-polygons-split-4326/; \
	fi

landmass-clean:
	rm -rvf ${WORK_DIR}/Default/${AREA}/

landmass-rebuild: landmass-clean landmass


# OSM and landcover layers
# The configuration for these is in layers.csv

layers: areas lines

clean-layers:
	rm -rfv ${WORK_DIR}/osm-*/${AREA}/ ${WORK_DIR}/lc-*/${AREA}/

layers-rebuild: clean-layers areas lines

areas:
	for row in $$(grep ,area, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,area,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]}/${AREA}/ ]; then \
				ogr-decode ${DECODE_OPTS} --area-type $${F[3]} work/$${F[0]} ${DATA_DIR}/shapefiles/$${F[0]}.shp;\
			fi; \
		fi; \
	done

lines:
	for row in $$(grep ,line, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,line,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]}/${AREA}/ ]; then \
				ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} work/$${F[0]} ${DATA_DIR}/shapefiles/$${F[0]}.shp;\
			fi; \
		fi; \
	done

# Special handling for cliffs (currently skipping; causes scenery building to crash later)
cliffs:
	cliff-decode ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/osm-cliff-natural.shp
	rectify_height --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT} --min-dist=100


# Pull it all together and generate scenery in the output directory
scenery:
	rm -rvf ${OUTPUT_DIR}/Terrain/${AREA}/
	tg-construct --threads=4 --priorities=./default_priorities.txt --work-dir=${WORK_DIR} --output-dir=${OUTPUT_DIR}/Terrain \
		--ignore-landmass \
		--min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT} \
		Default AirportObj AirportArea SRTM-3 $$(ls ${WORK_DIR} | grep osm-) $$(ls ${WORK_DIR} | grep lc-)
	cp -v ${DATA_DIR}/airports/modified/*.dat ${OUTPUT_DIR}/NavData/apt/


#
# Data preparation (does not require TerraGear)
#

prepare-airports:
	rm -f ${DATA_DIR}/airports/modified.apt.dat ${DATA_DIR}/airports/original/*
	zcat ${DATA_DIR}/airports/apt.dat.gz | python3 split-airports.py ${DATA_DIR}/airports/original
	sh merge-airports.sh > ${DATA_DIR}/airports/modified.apt.dat


