# What area are we building?
BUCKET=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50

# Standard setup
SHELL=/bin/bash
MAX_THREADS=4
DATA_DIR=./data
WORK_DIR=./work
OUTPUT_DIR=./output
OSM_DIR=../osm
DECODE_OPTS=--spat ${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT} --threads ${MAX_THREADS}


# Steps that require TerraGear (prepare-airports needs Python, which isn't in the Docker image)
all: elevations airports landmass layers cliffs scenery

all-rebuild: elevations-rebuild airports-rebuild landmass-rebuild layers-rebuild scenery

# Build elevation data from the SRTM-3x
elevations:
	if [ ! -d ${WORK_DIR}/SRTM-3/${BUCKET} ]; then \
	  gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/${BUCKET}/*.hgt; \
	  terrafit ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1; \
	fi

elevations-clean:
	rm -rvf ${WORK_DIR}/SRTM-3/${BUCKET}/

elevations-rebuild: elevations-clean elevations


# Build the airport areas and objects
airports:
	if [ ! -d ${WORK_DIR}/AirportObj/${BUCKET}/ ]; then \
	  genapts850 --input=${DATA_DIR}/airports/modified.apt.dat --work=${WORK_DIR} --threads=${MAX_THREADS} \
		--dem-path=SRTM-3 \
		--min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT}; \
	fi

airports-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${BUCKET}/ ${WORK_DIR}/AirportArea/${BUCKET}/

airports-rebuild: airports-clean airports


# Build the default landmass
landmass:
	if [ ! -d ${WORK_DIR}/Default/${BUCKET}/ ]; then \
	  ogr-decode ${DECODE_OPTS} --area-type Default work/Default ${DATA_DIR}/land-polygons-split-4326/; \
	fi

landmass-clean:
	rm -rvf ${WORK_DIR}/Default/${BUCKET}/

landmass-rebuild: landmass-clean landmass


# OSM and landcover layers
# The configuration for these is in layers.csv

layers: areas lines

clean-layers:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET}/ ${WORK_DIR}/lc-*/${BUCKET}/

layers-rebuild: clean-layers areas lines

areas:
	for row in $$(grep ,area, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,area,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]}/${BUCKET}/ ]; then \
				ogr-decode ${DECODE_OPTS} --area-type $${F[3]} \
					work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
			fi; \
		fi; \
	done

lines:
	for row in $$(grep ,line, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,line,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]}/${BUCKET}/ ]; then \
				ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} \
					work/$${F[0]} ${DATA_DIR}/shapefiles/${BUCKET}/$${F[0]}.shp;\
			fi; \
		fi; \
	done

# Special handling for cliffs (currently skipping; causes scenery building to crash later)
cliffs:
	cliff-decode ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/osm-cliff-natural.shp
	rectify_height --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT} --min-dist=100


# Pull it all together and generate scenery in the output directory
scenery:
	min_lat=${MIN_LAT}; \
	while [ $$min_lat -lt ${MAX_LAT} ]; do \
	  min_lon=${MIN_LON}; \
	  while [ $$min_lon -lt ${MAX_LON} ]; do \
	    echo Building $$min_lat $$min_lon; \
	    tg-construct --threads=${MAX_THREADS} --priorities=./default_priorities.txt --work-dir=${WORK_DIR} --output-dir=${OUTPUT_DIR}/Terrain \
		    --ignore-landmass \
		    --min-lon=$$min_lon --max-lon=$$(expr $$min_lon + 1) --min-lat=$$min_lat --max-lat=$$(expr $$min_lat + 1) \
		    Default AirportObj AirportArea SRTM-3 $$(ls ${WORK_DIR} | grep osm-) $$(ls ${WORK_DIR} | grep lc-); \
	    min_lon=$$(expr $$min_lon + 1); \
	  done; \
	  min_lat=$$(expr $$min_lat + 1); \
	done
	cp -v ${DATA_DIR}/airports/modified/*.dat ${OUTPUT_DIR}/NavData/apt/


#
# Data preparation (does not require TerraGear)
#

prepare-airports:
	rm -f ${DATA_DIR}/airports/modified.apt.dat ${DATA_DIR}/airports/original/*
	zcat ${DATA_DIR}/airports/apt.dat.gz | python3 split-airports.py ${DATA_DIR}/airports/original
	sh merge-airports.sh > ${DATA_DIR}/airports/modified.apt.dat


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
