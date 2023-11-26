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
# BUCKET - **required** the bucket being built (e.g. w080n40)
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
# Build the TerraGear input files for scenery, working at the latlon
# level (can build an area smaller than a full bucket).
#
# Set the DEM Makefile variable to "FABDEM" (default) or "SRTM-3" to
# choose the data source (default is SRTM-3 north of 80N; FABDEM
# otherwise).
#
# prepare
#   run *all* prepare targets for the requested area.
#
# elevations-prepare
#   prepare the elevation data from the *.hgt or *.tif files in INPUT_DIR 
#
# landmass-prepare
#   prepare the landmass mask for the requested area.
#
# airports-prepare
#   prepare the airport areas and objects for the requested area.
#
# landcover-prepare
#   prepare the background landcover layers for the requested area.
#
# osm-prepare
#   prepare the foreground OpenStreetMap layers for the requested area.
#
# 2.3. Scenery-construction targets
#
# This can work on a 1x1 deg area or larger.
#
# scenery
#   build scenery for the requested area.
#
# 2.4. Publishing targets
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
PUBLISH_DIR="${HOME}/Dropbox/Downloads"

# What area are we building (must be set)
ifndef BUCKET
$(error BUCKET is not defined)
endif

# Extract coords from the bucket name
MIN_LON:=$(shell echo ${BUCKET} | sed -e 's/^w0*/-/' -e 's/^e0*//' -e 's/[ns].*$$//')
MIN_LAT:=$(shell echo ${BUCKET} | sed -e 's/^.*s0*/-/' -e 's/^.*n//')
MAX_LON:=$(shell expr ${MIN_LON} + 10)
MAX_LAT:=$(shell expr ${MIN_LAT} + 10)

MIN_FEATURE_AREA=0.00000004 # approx 200m^2 (for landcover and OSM area features)

#
# Clip extents
# Raster extent is padded one degree in each direction, for more-consistent polygons
#
QUADRANT_EXTENT=-180,0,0,90
RASTER_CLIP_EXTENT=$(shell expr ${MIN_LON} - 1) $(shell expr ${MAX_LAT} + 1) $(shell expr ${MAX_LON} + 1)  $(shell expr ${MIN_LAT} - 1)
SPAT=${MIN_LON} ${MIN_LAT} ${MAX_LON} ${MAX_LAT}
LATLON_OPTS=--min-lon=${MIN_LON} --min-lat=${MIN_LAT} --max-lon=${MAX_LON} --max-lat=${MAX_LAT}

# common command-line parameters
DECODE_OPTS=--spat ${SPAT} --threads ${MAX_THREADS}
TERRAFIT_OPTS=-j ${MAX_THREADS} -m 50 -x 10000 -e 10

#
# Data sources
#

AIRPORTS_SOURCE=${INPUTS_DIR}/airports/apt.dat
LANDCOVER_SOURCE_DIR=${INPUTS_DIR}/global-landcover

OSM_DIR=${INPUTS_DIR}/osm
OSM_PLANET=${OSM_DIR}/planet-latest.osm.pbf
OSM_SOURCE=${OSM_DIR}/hemisphere-nw.osm.pbf
OSM_PBF_CONF=config/osmconf.ini

LANDMASS_SOURCE=${INPUTS_DIR}/land-polygons-split-4326/land_polygons.shp # complete version is very slow
LANDCOVER_BASE=landcover-nw-clipped
LANDCOVER_SOURCE=${LANDCOVER_SOURCE_DIR}/${LANDCOVER_BASE}.shp

# Output dir for per-area shapefiles
SHAPEFILES_DIR=${DATA_DIR}/shapefiles/${BUCKET}

# DEM type (SRTM-3 or FABDEM); FABDEM is higher res, but goes only to 80N
ifeq ($(MIN_LAT), 80)
DEM=SRTM-3
else
DEM=FABDEM
endif

#
# Data extracts (specific to bucket)
#

LANDMASS_SHAPEFILE=${DATA_DIR}/landmass/${BUCKET}.shp
LANDCOVER_SHAPEFILE=${DATA_DIR}/landcover/${BUCKET}.shp
OSM_PBF=${DATA_DIR}/osm/${BUCKET}.osm.pbf
OSM_LINES_SHAPEFILE=${DATA_DIR}/osm/${BUCKET}-lines.shp
OSM_AREAS_SHAPEFILE=${DATA_DIR}/osm/${BUCKET}-areas.shp

# Queries for creating intermediate shapefiles from the OSM PBF
# TODO this duplicates info in config/osm-layers.tsv; we need it all in one place
OSM_LINES_QUERY=(highway IN ('motorway', 'primary', 'secondary', 'tertiary', 'trunk') OR man_made IN ('breakwater', 'pier') OR natural IN ('reef') OR power IN ('line') OR railway IN ('abandoned', 'rail') OR waterway IN ('dam', 'lock_gate'))
OSM_AREAS_QUERY=((amenity IN ('college', 'school', 'university') OR landuse IN ('brownfield', 'cemetery', 'commercial', 'construction', 'education', 'forest', 'grass', 'greenfield', 'industrial', 'institutional', 'landfill', 'meadow', 'orchard', 'quarry', 'recreation_ground', 'residential', 'retail', 'vineyard', 'wood') OR leisure IN ('golf_course', 'nature_reserve', 'park') OR man_made IN ('mine') OR natural IN ('grassland', 'reef', 'wetland', 'wood') OR sport IN ('golf') OR water IS NOT NULL) AND OGR_GEOM_AREA >= ${MIN_FEATURE_AREA}) OR (water IS NOT NULL) OR (made_made IN ('breakwater', 'pier')) OR (waterway IN ('dam', 'lock_gate'))

AIRPORTS=${DATA_DIR}/airports/${BUCKET}/apt.dat

echo2: ${OSM_PBF}

#
# Prepare areas to include
#

DEM_AREAS=${DEM}

AIRPORT_AREAS=AirportObj AirportArea

LC_AREAS=lc-broadleaf-evergreen-forest lc-broadleaf-deciduous-forest	\
lc-needleleaf-evergreen-forest lc-needleleaf-deciduous-forest		\
lc-mixed-forest lc-tree-open lc-shrub lc-herbaceous			\
lc-herbaceous-tree-shrub lc-sparse-vegetation lc-cropland		\
lc-paddy-field lc-cropland-other-vegetation lc-mangrove lc-wetland	\
lc-gravel-rock lc-sand lc-urban lc-snow-ice

OSM_AREAS=osm-abandoned-railway osm-breakwater-man_made-areas		\
osm-breakwater-man_made-lines osm-brownfield-landuse			\
osm-cemetery-landuse osm-cliff-natural osm-commercial-landuse		\
osm-construction-landuse osm-dam-waterway-areas				\
osm-dam-waterway-lines osm-desert-natural osm-dirt-natural		\
osm-education-amenity osm-education-landuse osm-farmland-landuse	\
osm-forest-landuse-deciduous osm-forest-landuse-evergreen		\
osm-forest-landuse-mixed osm-glacier-natural osm-golf-leisure		\
osm-golf-sport osm-grass-landuse osm-grassland-natural			\
osm-greenfield-landuse osm-industrial-landuse				\
osm-institutional-landuse osm-landfill-landuse osm-lava-natural		\
osm-line-power osm-lock-gate-waterway-areas				\
osm-lock-gate-waterway-lines osm-meadow-landuse osm-mine-man_made	\
osm-motorway-highway osm-nature_reserve-leisure osm-orchard-landuse	\
osm-park-leisure osm-pier-man_made-areas osm-pier-man_made-lines	\
osm-primary-highway osm-quarry-landuse osm-railway-railway		\
osm-recreation-ground-landuse osm-reef-natural-areas			\
osm-reef-natural-lines osm-residential-landuse osm-retail-landuse	\
osm-rock-natural osm-sand-natural osm-scrub-natural			\
osm-secondary-highway osm-trunk-highway osm-tundra-natural		\
osm-vineyard-landuse osm-water-natural osm-water-water			\
osm-wetland-natural osm-wood-natural-deciduous				\
osm-wood-natural-evergreen osm-wood-natural-mixed			\
osm-wood-natural-unspecified

PREPARE_AREAS=${DEM_AREAS} ${AIRPORT_AREAS} ${LC_AREAS} ${OSM_AREAS}

#
# Build flags
#

FLAGS_BASE=./flags
FLAGS_DIR=${FLAGS_BASE}/${BUCKET}

NUDGE=0

OSM_AREAS_EXTRACTED_FLAG=${FLAGS_DIR}/osm-areas-extracted.flag
OSM_LINES_EXTRACTED_FLAG=${FLAGS_DIR}/osm-lines-extracted.flag

LANDCOVER_SHAPEFILES_PREPARED_FLAG=${FLAGS_DIR}/landcover-shapefiles-prepared.flag

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

all: extract prepare

all-rebuild: extract-rebuild prepare-rebuild scenery-rebuild

construct: scenery

reconstruct: scenery-rebuild

publish: archive publish-cloud


########################################################################
# 1. Extract
########################################################################

extract: landmass-extract landcover-extract osm-extract airports-extract

extract-clean: landmass-extract-clean landcover-extract-clean osm-extract-clean airports-extract-clean

extract-rebuild: extract-clean extract

#
# Extract landmass (single file; no flag needed)
#

landmass-extract: ${LANDMASS_SHAPEFILE}

landmass-extract-clean:
	rm -rfv  ${LANDMASS_SHAPEFILE}

landmass-extract-rebuild: landmass-extract-clean landmass-extract

${LANDMASS_SHAPEFILE}: ${LANDMASS_SOURCE}
	ogr2ogr -spat ${SPAT} ${LANDMASS_SHAPEFILE} ${LANDMASS_SOURCE}

#
# Extract background landcover for current bucket
#

landcover-extract: ${LANDCOVER_SHAPEFILE}

landcover-extract-clean:
	rm -fv ${LANDCOVER_SHAPEFILE}

landcover-extract-rebuild: landcover-extract-clean landcover-extract

${LANDCOVER_SHAPEFILE}: ${LANDCOVER_SOURCE}
	@echo -e "\nExtracting background landcover for ${BUCKET}..."
	ogr2ogr -spat ${SPAT} $@ $< -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry,* FROM '${LANDCOVER_BASE}'"
	@echo -e "\nCreating index for $@..."
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}" $@

#
# Extract OSM foreground features for current bucket
#

osm-extract: ${OSM_AREAS_EXTRACTED_FLAG} ${OSM_LINES_EXTRACTED_FLAG}

osm-extract-clean-all: osm-extract-clean
	rm -rf  ${OSM_PBF}

osm-extract-clean:
	rm -rf ${OSM_AREAS_EXTRACTED_FLAG} ${OSM_AREAS_SHAPEFILE} ${OSM_LINES_EXTRACTED_FLAG} ${OSM_LINES_SHAPEFILE}

osm-extract-rebuild: osm-extract-clean osm-extract

# convenience targets for testing
osm-quadrant: ${OSM_SOURCE}

osm-pbf: ${OSM_PBF}

osm-areas-shapefile: ${OSM_AREAS_SHAPEFILE}

# extract the quadrant (e.g. north half of western hemisphere) to speed things up
${OSM_SOURCE}: ${OSM_PLANET}
	@echo -e "\nExtracting OSM PBF for quadrant ${QUADRANT_EXTENT}..."
	osmconvert $< -v -b=${QUADRANT_EXTENT} --complete-ways --complete-multipolygons --complete-boundaries -o=$@

${OSM_PBF}: ${OSM_SOURCE} # clip PBF to bucket to make processing more efficient; no flag needed
	@echo -e "\nExtracting OSM PBF for ${BUCKET}..."
	osmconvert $< -v -b=${MIN_LON},${MIN_LAT},${MAX_LON},${MAX_LAT} --complete-ways --complete-multipolygons --complete-boundaries -o=$@

${OSM_LINES_EXTRACTED_FLAG}: ${OSM_PBF} ${OSM_PBF_CONF}
	@echo -e "\nExtracting foreground OSM line features for ${BUCKET}..."
	@rm -f $@ ${OSM_LINES_SHAPEFILE}
	ogr2ogr -oo CONFIG_FILE="${OSM_PBF_CONF}" -spat ${SPAT} -progress ${OSM_LINES_SHAPEFILE} ${OSM_PBF} -sql "SELECT * FROM lines WHERE ${OSM_LINES_QUERY}"
	@echo Creating spatial index...
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}-lines" ${OSM_LINES_SHAPEFILE}
	@touch $@

${OSM_AREAS_EXTRACTED_FLAG}: ${OSM_PBF} ${OSM_PBF_CONF}
	@echo -e "\nExtracting foreground OSM area features for ${BUCKET}..."
	@rm -f $@ ${OSM_AREAS_SHAPEFILE}
	ogr2ogr -oo CONFIG_FILE="${OSM_PBF_CONF}" -spat ${SPAT} -progress ${OSM_AREAS_SHAPEFILE} ${OSM_PBF} -sql "SELECT * FROM multipolygons WHERE ${OSM_AREAS_QUERY}"
	@echo Creating spatial index...
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}-areas" ${OSM_AREAS_SHAPEFILE}
	@touch $@


#
# Extract airports
#

airports-extract: ${AIRPORTS} # single file - no flag needed

${AIRPORTS}: ${VENV} ${AIRPORTS_SOURCE}  $(wildcard ${INPUTS_DIR}/airports/custom/*.dat) ${SCRIPT_DIR}/downgrade-apt.py ${SCRIPT_DIR}/filter-airports.py
	mkdir -p ${DATA_DIR}/airports/${BUCKET}/
	. ${VENV} && python3 ${SCRIPT_DIR}/downgrade-apt.py  ${INPUTS_DIR}/airports/custom/*.dat ${AIRPORTS_SOURCE} \
	| python3 ${SCRIPT_DIR}/filter-airports.py ${BUCKET} \
	> $@

airports-extract-clean:
	rm -f ${AIRPORTS}

airports-extract-rebuild: airports-extract-clean airports-extract



########################################################################
# 2. Prepare
########################################################################

prepare: elevations-prepare airports-prepare landmass-prepare landcover-prepare osm-prepare

prepare-clean: elevations-prepare-clean airports-prepare-clean landmass-prepare-clean landcover-prepare-clean osm-prepare-clean

prepare-rebuild: prepare-clean prepare

#
# Prepare elevation data from the DEMs
# Set the Makefile var DEM to SRTM-3 or FABDEM (default)
#

elevations-prepare: ${ELEVATIONS_FIT_FLAG}

elevations-prepare-clean:
	rm -rvf ${WORK_DIR}/${DEM}/${BUCKET}/ ${ELEVATIONS_FLAG} ${ELEVATIONS_FIT_FLAG}

elevations-prepare-rebuild: elevations-prepare-clean elevations-prepare

${ELEVATIONS_FLAG}:  ${INPUTS_DIR}/${DEM}/Unpacked/${BUCKET}
	rm -f ${ELEVATIONS_FLAG}
	rm -rf ${WORK_DIR}/${DEM}/${BUCKET}
	find ${INPUTS_DIR}/${DEM}/Unpacked/${BUCKET} -name '*.tif' -o -name '*.hgt' | xargs gdalchop ${WORK_DIR}/${DEM}
	mkdir -p ${FLAGS_DIR} && touch ${ELEVATIONS_FLAG}

${ELEVATIONS_FIT_FLAG}: ${ELEVATIONS_FLAG}
	rm -f ${ELEVATIONS_FIT_FLAG}
	terrafit ${WORK_DIR}/${DEM}/${BUCKET} ${TERRAFIT_OPTS}
	mkdir -p ${FLAGS_DIR} && touch ${ELEVATIONS_FIT_FLAG}

#
# Prepare the airport areas and objects
#

airports-prepare: ${AIRPORTS_FLAG} elevations-prepare

airports-prepare-clean:
	rm -rvf ${WORK_DIR}/AirportObj/${BUCKET}/ ${WORK_DIR}/AirportArea/${BUCKET}/ ${AIRPORTS_FLAG}

airports-prepare-rebuild: airports-prepare-clean airports-prepare

${AIRPORTS_FLAG}: ${AIRPORTS} ${ELEVATIONS_FIT_FLAG}
	rm -f ${AIRPORTS_FLAG}
	rm -rf ${WORK_DIR}/AirportArea/${BUCKET} ${WORK_DIR}/AirportObj/${BUCKET}
	genapts850 --input=${AIRPORTS} ${LATLON_OPTS} --max-slope=0.2618 \
	  --work=${WORK_DIR} --dem-path=${DEM} # can't use threads here, due to errors with .idx files; not SRTM-3
	mkdir -p ${FLAGS_DIR} && touch ${AIRPORTS_FLAG}

#
# Prepare the default landmass
#

landmass-prepare: ${LANDMASS_FLAG}

landmass-prepare-clean:
	rm -rvf ${WORK_DIR}/Default/${BUCKET}/ ${LANDMASS_FLAG}

landmass-prepare-rebuild: landmass-prepare-clean landmass-prepare

${LANDMASS_FLAG}: ${LANDMASS_SHAPEFILE}
	rm -f ${LANDMASS_FLAG}
	rm -rf ${WORK_DIR}/Default/${BUCKET}
	ogr-decode ${DECODE_OPTS} --area-type Default ${WORK_DIR}/Default ${LANDMASS_SHAPEFILE}
	mkdir -p ${FLAGS_DIR} && touch ${LANDMASS_FLAG}

#
# Prepare the background landcover layers
#

landcover-prepare: ${LANDCOVER_LAYERS_FLAG}

landcover-prepare-clean:
	rm -rfv ${WORK_DIR}/lc-*/${BUCKET}/ ${LANDCOVER_LAYERS_FLAG}

landcover-prepare-rebuild: landcover-prepare-clean landcover-prepare

${LANDCOVER_LAYERS_FLAG}: ${LANDCOVER_SHAPEFILE} ${CONFIG_DIR}/landcover-layers.tsv
	rm -f $@
	@echo -e "\nPrepareing landcover area layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/landcover-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'area' ]; then \
	    echo -e "\nTrying $$name..."; \
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --area-type $$material --where "$$query" \
	      ${WORK_DIR}/$$name ${LANDCOVER_SHAPEFILE} || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

#
# Prepare the foreground OSM layers
#

osm-prepare: ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

osm-prepare-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET} ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

osm-prepare-rebuild: osm-prepare-clean osm-prepare

osm-areas-prepare: ${OSM_AREA_LAYERS_FLAG}

osm-areas-prepare-clean:
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$type" = 'area' ]; then \
	    d=${WORK_DIR}/$$name/${BUCKET}; \
            echo Removing $$d ...; \
	    rm -rf $$d; \
	  fi; \
	done
	rm -fv ${OSM_AREA_LAYERS_FLAG}

${OSM_AREA_LAYERS_FLAG}: ${OSM_AREAS_SHAPEFILE} ${CONFIG_DIR}/osm-layers.tsv
	rm -f $@
	@echo -e "\nPrepareing OSM area layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'area' ]; then \
	    echo -e "\nTrying $$name..."; \
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --area-type $$material --where "$$query" \
	      ${WORK_DIR}/$$name ${OSM_AREAS_SHAPEFILE} || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

osm-lines-prepare: ${OSM_LINE_LAYERS_FLAG}

osm-lines-prepare-clean:
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$type" = 'line' ]; then \
	    d=${WORK_DIR}/$$name/${BUCKET}; \
            echo Removing $$d ...; \
	    rm -rf $$d; \
	  fi; \
	done
	rm -fv ${OSM_LINE_LAYERS_FLAG}

${OSM_LINE_LAYERS_FLAG}: ${OSM_LINES_SHAPEFILE} ${CONFIG_DIR}/osm-layers.tsv
	rm -f $@
	@echo -e "\nPrepareing OSM line layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'line' ]; then \
	    echo -e "\nTrying $$name..."; \
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $$line_width --area-type $$material --where "$$query" \
	      ${WORK_DIR}/$$name ${OSM_LINES_SHAPEFILE} || exit 1;\
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

osm-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET} ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}


########################################################################
# 3. Construct
########################################################################

#scenery: extract prepare
#	tg-construct --ignore-landmass --nudge=${NUDGE} --threads=${MAX_THREADS} --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
#	  ${LATLON_OPTS} --priorities=${CONFIG_DIR}/default_priorities.txt ${PREPARE_AREAS}

# Build the scenery in 1x1 deg areas (will replace scenery target soon)
scenery: extract prepare
	for lat in $$(seq ${MIN_LAT} $$(expr ${MAX_LAT} - 1)); do \
	  for lon in $$(seq ${MIN_LON} $$(expr ${MAX_LON} - 1)); do \
	    tg-construct --ignore-landmass --nudge=${NUDGE} --threads=${MAX_THREADS} --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
	      --min-lat=$$lat --min-lon=$$lon --max-lat=$$(expr $$lat + 1) --max-lon=$$(expr $$lon + 1) \
	      --priorities=${CONFIG_DIR}/default_priorities.txt ${PREPARE_AREAS};\
	  done; \
	done

scenery-clean:
	rm -rf ${SCENERY_DIR}/Terrain/${BUCKET}/

scenery-rebuild: scenery-clean scenery

static-files:
	cp -v ${STATIC_DIR}/* ${SCENERY_DIR}



########################################################################
# 4. Publish
########################################################################

#
# Generate custom threshold and navdata files for modified airports
#

thresholds: ${VENV} ${AIRPORTS}
	. ${VENV} && python3 ${SCRIPT_DIR}/gen-thresholds.py ${SCENERY_DIR}/Airports ${DATA_DIR}/airports/${BUCKET}/apt.dat

thresholds-clean:
	rm -rf ${SCENERY_DIR}/Airports

navdata: ${SCENERY_DIR}/NavData/apt/${BUCKET}.apt

${SCENERY_DIR}/NavData/apt/${BUCKET}.apt: ${AIRPORTS}
	mkdir -p ${SCENERY_DIR}/NavData/apt
	cp -v ${AIRPORTS} ${SCENERY_DIR}/NavData/apt/${BUCKET}.dat


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

#
# Make sure BUCKET is defined (when needed)
#
bucket-defined:
	test "${BUCKET}" == "" && echo BUCKET not defined. &>2 && exit 2

########################################################################
# Test that do-make.sh is working
########################################################################

echo:
	echo -- BUCKET=${BUCKET} ${LATLON_OPTS}
