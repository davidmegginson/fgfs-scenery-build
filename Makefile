SHELL=/bin/bash
DATA_DIR=./data
WORK_DIR=./work
OUTPUT_DIR=./output
MIN_LON=-90
MAX_LON=-60
MIN_LAT=30
MAX_LAT=60
DECODE_OPTS=--spat ${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT} --threads 2

elevations:
	rm -rvf ${WORK_DIR}/SRTM-3
	gdalchop ${WORK_DIR}/SRTM-3 ${DATA_DIR}/SRTM-3/*.hgt
	terrafit ${WORK_DIR}/SRTM-3 -m 50 -x 22500 -e 1

cliffs:
	cliff-decode ${WORK_DIR}/SRTM-3 ${DATA_DIR}/shapefiles/osm-cliff-natural.shp
	rectify_height --work-dir=${WORK_DIR} --height-dir=SRTM-3 --min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT} --min-dist=100

prepare-airports:
	rm -f ${DATA_DIR}/airports/modified.apt.dat ${DATA_DIR}/airports/original/*
	cat ${DATA_DIR}/airports/apt.dat | python3 split-airports.py ${DATA_DIR}/airports/original
	sh merge-airports.sh > ${DATA_DIR}/airports/modified.apt.dat

airports:
	rm -rvf ${WORK_DIR}/AirportObj ${WORK_DIR}/AirportArea
	genapts850 --input=${DATA_DIR}/airports/modified.apt.dat --work=${WORK_DIR} --threads=4 \
		--dem-path=SRTM-3 \
		--min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT}

landmass:
	rm -rvf ${WORK_DIR}/Default
	ogr-decode ${DECODE_OPTS} --area-type Default work/Default ${DATA_DIR}/land-polygons-split-4326/

layers: clean-layers areas lines

clean-layers:
	rm -rfv ${WORK_DIR}/osm-* ${WORK_DIR}/lc-*

areas:
	for row in $$(grep ,area, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,area,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]} ]; then \
				ogr-decode ${DECODE_OPTS} --area-type $${F[3]} work/$${F[0]} ${DATA_DIR}/shapefiles/$${F[0]}.shp;\
			fi; \
		fi; \
	done

lines:
	for row in $$(grep ,line, layers.csv); do \
		row=`echo $$row | sed -e 's/\r//'`; \
		if echo $$row | grep ',yes,line,' > /dev/null; then \
			F=($${row//,/ }); \
			if [ ! -e work/$${F[0]} ]; then \
				ogr-decode ${DECODE_OPTS} --texture-lines --line-width $${F[4]} --area-type $${F[3]} work/$${F[0]} ${DATA_DIR}/shapefiles/$${F[0]}.shp;\
			fi; \
		fi; \
	done

scenery:
	rm -rvf ${OUTPUT_DIR}/Terrain/* ${OUTPUT_DIR}/NavData/apt/* ${WORK_DIR}/Shared 
	tg-construct --threads=4 --priorities=./default_priorities.txt --work-dir=${WORK_DIR} --output-dir=${OUTPUT_DIR}/Terrain \
		--ignore-landmass \
		--min-lon=${MIN_LON} --max-lon=${MAX_LON} --min-lat=${MIN_LAT} --max-lat=${MAX_LAT} \
		Default AirportObj AirportArea SRTM-3 $$(ls ${WORK_DIR} | grep osm-) $$(ls ${WORK_DIR} | grep lc-)
	cp -v ${DATA_DIR}/airports/modified/*.dat
