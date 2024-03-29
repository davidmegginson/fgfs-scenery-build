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
# BUCKET - the 10x10 bucket being built (e.g. w080n40); required for most targets
#
# MIN_LON, MIN_LAT, MAX_LON, MAX_LAT - the bottom left and top right
# corners of the area being built (e.g. -80 40 -70 50); default to the
# corners of the bucket. Required for the scenery-no-bucket bucket.
#
# THREADS - the maximum number of concurrent threads to run for
# some processes (e.g. 8; increase to speed up the build; decrease to
# avoid crashes).
#
# PUBLISH_DIR - the directory where you want to upload scenery packages
# to the cloud (e.g. $HOME/Dropbox/Downloads)
#
# DEM - set to FABDEM or SRTM-3 to force using an elevation model
# (defaults to FABDEM between 80N and 80S; otherwise SRTM-3).
#
#
# 2. Important targets
#
# Most major targets have a *-clean and *-rebuild option,
# e.g. "landcover-extract-clean" will remove existing data extracts
# for BUCKET, while "landcover-extract-rebuild" will clean and then
# re-extract the landcover.
#
# The BUCKET variable is required for all targets unless otherwise
# noted.
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
#   extract OSM line and area shapefiles the requested bucket
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
#   run *all* prepare targets for the requested area (except elevations)
#
# elevations
#   chop the elevation data from the *.hgt or *.tif files
#   in INPUT_DIR, then run terrafit on all elevations for the current
#   DEM (not just the BUCKET). Note that the prepare target does not
#   run this automatically, because normally you will want to do all
#   of the elevations at once.
#
# elevations-all
#   chop all available elevation data (all buckets) for the
#   requested DEM. Run this before other scenery-building tasks.
#
# elevations-fit-all
#   run terrafit on all chopped elevation data for the requested DEM,
#   filling in where not yet fit
#
# elevations-refit-all
#   force run terrafit on all chopped elevation data for the requested
#   DEM, refitting everything
#
# landmass
#   prepare the landmass mask for the requested area.
#
# airports
#   prepare the airport areas and objects for the requested area.
#
# landcover
#   prepare the background landcover layers for the requested area.
#
# osm
#   prepare the foreground OpenStreetMap layers for the requested
#   bucket (lines and areas)
#
# osm-lines
#   prepare just the OSM lines for the requested bucket
#
# osm-areas
#   prepare just the OSM polygons for the requested bucket
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
THREADS=1
LOG_LEVEL=info

# Directories
SCENERY_NAME=fgfs-americas-scenery
CONFIG_DIR=./config
TEMP_DIR=./temp
INPUTS_DIR=./01-inputs
DATA_DIR=./02-prep
WORK_DIR=./03-work
OUTPUT_DIR=./04-output
SCRIPT_DIR=./scripts
STATIC_DIR=./static
HTML_DIR=./docs
SCENERY_DIR=${OUTPUT_DIR}/${SCENERY_NAME}
PUBLISH_DIR="${HOME}/Dropbox/Downloads"

# Extract coords from the bucket name
ifdef BUCKET

BUCKET_MIN_LON=$(shell echo ${BUCKET} | sed -e 's/^w0*/-/' -e 's/^e0*//' -e 's/[ns].*$$//')
BUCKET_MIN_LAT=$(shell echo ${BUCKET} | sed -e 's/^.*s0*/-/' -e 's/^.*n//')
BUCKET_MAX_LON=$(shell expr ${BUCKET_MIN_LON} + 10)
BUCKET_MAX_LAT=$(shell expr ${BUCKET_MIN_LAT} + 10)

# expanded by 1 deg in each direction to allow overlap for elevations and land areas
BUCKET_MIN_LON_EXPANDED=$(shell [ ${BUCKET_MIN_LON} -eq -180 ] && echo -180 || expr ${BUCKET_MIN_LON} - 1)
BUCKET_MIN_LAT_EXPANDED=$(shell [ ${BUCKET_MIN_LAT} -eq -90 ] && echo -90 || expr ${BUCKET_MIN_LAT} - 1)
BUCKET_MAX_LON_EXPANDED=$(shell [ ${BUCKET_MAX_LON} -eq 180 ] && echo 180 || expr ${BUCKET_MAX_LON} + 1)
BUCKET_MAX_LAT_EXPANDED=$(shell [ ${BUCKET_MAX_LAT} -eq 90 ] && echo 90 || expr ${BUCKET_MAX_LAT} + 1)

# Quadrant
QUADRANT=$(shell [ ${BUCKET_MIN_LAT} -lt 0 ] && echo s || echo n)$(shell [ ${BUCKET_MIN_LON} -lt 0 ] && echo w || echo e)
QUADRANT_MIN_LON=$(shell [ ${BUCKET_MIN_LON} -lt 0 ] && echo 179 || echo 0)
QUADRANT_MIN_LAT=$(shell [ ${BUCKET_MIN_LAT} -lt 0 ] && echo -90 || echo 0)
QUADRANT_MAX_LON=$(shell [ ${BUCKET_MIN_LON} -ge 0 ] && echo -179 || echo 0)
QUADRANT_MAX_LAT=$(shell [ ${BUCKET_MIN_LAT} -ge 0 ] && echo 90 || echo 0)

#
# Data extracts (specific to bucket)
#

LANDMASS_SHAPEFILE=${DATA_DIR}/landmass/${BUCKET}.shp
LANDCOVER_SHAPEFILE=${DATA_DIR}/landcover/${BUCKET}.shp
OSM_PBF=${DATA_DIR}/osm/${BUCKET}.osm.pbf
OSM_LINES_SHAPEFILE=${DATA_DIR}/osm/${BUCKET}-lines.shp
OSM_AREAS_SHAPEFILE=${DATA_DIR}/osm/${BUCKET}-areas.shp

endif

# Area to actually build (scenery only)
MIN_LAT:=${BUCKET_MIN_LAT}
MIN_LON:=${BUCKET_MIN_LON}
MAX_LAT:=${BUCKET_MAX_LAT}
MAX_LON:=${BUCKET_MAX_LON}
INCREMENT=10

MIN_FEATURE_AREA=0.00000004 # approx 200m^2 (for landcover and OSM area features)

#
# Clip extents
# Raster extent is padded one degree in each direction, for more-consistent polygons
#
QUADRANT_EXTENT=$(shell expr ${QUADRANT_MIN_LON} - 1),$(shell expr ${QUADRANT_MIN_LAT} - 1),$(shell ${QUADRANT_MAX_LON} + 1),$(shell ${QUADRANT_MAX_LAT} + 1)
SPAT=${BUCKET_MIN_LON} ${BUCKET_MIN_LAT} ${BUCKET_MAX_LON} ${BUCKET_MAX_LAT}
SPAT_EXPANDED=${BUCKET_MIN_LON_EXPANDED} ${BUCKET_MIN_LAT_EXPANDED} ${BUCKET_MAX_LON_EXPANDED} ${BUCKET_MAX_LAT_EXPANDED}
BUCKET_LATLON_EXPANDED=${BUCKET_MIN_LON_EXPANDED},${BUCKET_MIN_LAT_EXPANDED},${BUCKET_MAX_LON_EXPANDED},${BUCKET_MAX_LAT_EXPANDED}
BUCKET_LATLON_OPTS=--min-lon=${BUCKET_MIN_LON} --min-lat=${BUCKET_MIN_LAT} --max-lon=${BUCKET_MAX_LON} --max-lat=${BUCKET_MAX_LAT}
LATLON_OPTS=--min-lon=${MIN_LON} --min-lat=${MIN_LAT} --max-lon=${MAX_LON} --max-lat=${MAX_LAT}

# common command-line parameters
DECODE_OPTS=--spat ${SPAT_EXPANDED} --threads ${THREADS}
TERRAFIT_OPTS=-j ${THREADS} -m 50 -x 10000 -e 10

#
# Data sources
#

AIRPORTS_SOURCE=${INPUTS_DIR}/airports/apt.dat
LANDCOVER_SOURCE_DIR=${INPUTS_DIR}/global-landcover

OSM_DIR=${INPUTS_DIR}/osm
OSM_PLANET=${OSM_DIR}/planet-latest.osm.pbf
OSM_SOURCE=${OSM_DIR}/hemisphere-${QUADRANT}.osm.pbf
OSM_PBF_CONF=config/osmconf.ini

LANDMASS_SOURCE=${INPUTS_DIR}/land-polygons-split-4326/land_polygons.shp # complete version is very slow
# old
LANDCOVER_BASE=landcover-${QUADRANT}-clipped
# new
#LANDCOVER_BASE=landcover-${QUADRANT}-valid
LANDCOVER_SOURCE=${LANDCOVER_SOURCE_DIR}/${LANDCOVER_BASE}.shp

# Output dir for per-area shapefiles
SHAPEFILES_DIR=${DATA_DIR}/shapefiles/${BUCKET}

# DEM type (SRTM-3 or FABDEM); FABDEM is higher res, but goes only to 80N
ifeq ($(BUCKET_MIN_LAT), 80)
DEM=SRTM-3
else
DEM=FABDEM
endif

# Queries for creating intermediate shapefiles from the OSM PBF
# TODO this duplicates info in config/osm-layers.tsv; we need it all in one place

OSM_LINES_QUERY=highway IN ('motorway', 'primary', 'secondary', 'tertiary', 'trunk') OR \
	man_made IN ('breakwater', 'pier') OR \
	natural IN ('reef') OR \
	power IN ('line') OR \
	railway IN ('abandoned', 'rail') OR \
	waterway IN ('dam', 'lock_gate')

OSM_AREAS_QUERY=man_made IN ('breakwater', 'pier') OR \
	natural IN ('bay', 'beach', 'cliff', 'gully', 'reef', 'sand', 'shoal', 'strait', 'water', 'volcano') OR \
	water IS NOT NULL OR \
	waterway IS NOT NULL OR \
	natural IS NOT NULL OR \
	landuse IN ('forest', 'grass', 'meadow', 'orchard', 'wood') OR \
	(OGR_GEOM_AREA >= ${MIN_FEATURE_AREA} AND ( \
		amenity IN ('college', 'school', 'university') OR \
		landuse IN ('brownfield', 'cemetery', 'commercial', 'construction', 'education', \
			'greenfield', 'industrial', 'institutional', \
			'landfill', 'quarry', 'recreation_ground', \
			'residential', 'retail', 'vineyard') OR \
		leisure IN ('golf_course', 'nature_reserve', 'park') OR \
		man_made IN ('mine') OR \
		sport IN ('golf') \
	))

AIRPORTS=${DATA_DIR}/airports/${BUCKET}/apt.dat

#
# Prepare areas to include
#

DEM_AREAS=${DEM}/DEM

AIRPORT_AREAS=${DEM}/AirportObj ${DEM}/AirportArea

LC_AREAS=$(shell cd ${WORK_DIR} && ls | grep lc-)

OSM_AREAS=$(shell cd ${WORK_DIR} && ls | grep osm-)


PREPARE_AREAS=${DEM_AREAS} Default ${AIRPORT_AREAS} ${LC_AREAS} ${OSM_AREAS}

CONSTRUCT_OPTS=--ignore-landmass --nudge=${NUDGE} --threads=${THREADS} --work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain

#
# Build flags
#

FLAGS_BASE=./flags
FLAGS_DIR=${FLAGS_BASE}/${BUCKET}

NUDGE=0

LANDCOVER_EXTRACTED_FLAG=${FLAGS_DIR}/landcover-extracted.flag

OSM_AREAS_EXTRACTED_FLAG=${FLAGS_DIR}/osm-areas-extracted.flag
OSM_LINES_EXTRACTED_FLAG=${FLAGS_DIR}/osm-lines-extracted.flag

LANDCOVER_SHAPEFILES_PREPARED_FLAG=${FLAGS_DIR}/landcover-shapefiles-prepared.flag

ELEVATIONS_FLAG=${FLAGS_DIR}/${DEM}-elevations.flag # depends on DEM as well as BUCKET
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

rebuild: extract-clean prepare-clean scenery-rebuild

rebuild-all: elevations-rebuild rebuild

construct: scenery

reconstruct: scenery-rebuild

publish: archive publish-cloud


########################################################################
# 1. Extract
########################################################################

extract: landmass-extract landcover-extract osm-extract airports-extract

extract-clean: landmass-extract-clean landcover-extract-clean osm-extract-clean airports-extract-clean

extract-clean-all: landmass-extract-clean landcover-extract-clean osm-extract-clean-all airports-extract-clean

extract-rebuild: extract-clean extract

extract-rebuild-all: extract-clean-all extract

#
# Extract landmass (single file; no flag needed)
#

landmass-extract: ${LANDMASS_SHAPEFILE}

landmass-extract-clean:
	rm -rfv  ${LANDMASS_SHAPEFILE}

landmass-extract-rebuild: landmass-extract-clean landmass-extract

${LANDMASS_SHAPEFILE}: ${LANDMASS_SOURCE}
	@echo -e "\nExtracting landmass for ${BUCKET}..."
	ogr2ogr -spat ${SPAT_EXPANDED} $@ ${LANDMASS_SOURCE} -dialect sqlite -sql "SELECT ST_MakeValid(geometry) AS geometry,* FROM land_polygons"
	@echo -e "\nCreating index for ${LANDMASS_SHAPEFILE}..."
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}" $@ # indexed for clipping landcover

#
# Extract background landcover for current bucket
#

landcover-extract: ${LANDCOVER_EXTRACTED_FLAG}

landcover-extract-clean:
	rm -fv ${LANDCOVER_SHAPEFILE} ${LANDCOVER_EXTRACTED_FLAG}

landcover-extract-rebuild: landcover-extract-clean landcover-extract

${LANDCOVER_EXTRACTED_FLAG}: ${LANDCOVER_SOURCE}
	mkdir -p ${FLAGS_DIR}
	rm -f ${LANDCOVER_EXTRACTED_FLAG}
	@echo -e "\nExtracting background landcover for ${BUCKET}..."
	ogr2ogr -spat ${SPAT_EXPANDED} ${LANDCOVER_SHAPEFILE} ${LANDCOVER_SOURCE}
	@echo -e "\nCreating index for ${LANDCOVER_SHAPEFILE}..."
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}" ${LANDCOVER_SHAPEFILE}
	touch ${LANDCOVER_EXTRACTED_FLAG}

#
# Extract OSM foreground features for current bucket
#

osm-extract: osm-areas-extract osm-lines-extract

osm-extract-clean: osm-areas-extract-clean osm-lines-extract-clean

osm-extract-rebuild: osm-extract-clean osm-extract

# use rarely -- also re-extracts PBF
osm-extract-clean-all: osm-extract-clean
	rm -rf  ${OSM_PBF}

osm-areas-extract:  ${OSM_AREAS_EXTRACTED_FLAG}

osm-areas-extract-clean:
	rm -rf ${OSM_AREAS_EXTRACTED_FLAG} ${OSM_AREAS_SHAPEFILE}

osm-areas-extract-rebuild: osm-areas-extract-clean osm-areas-extract

osm-lines-extract: ${OSM_LINES_EXTRACTED_FLAG}

osm-lines-extract-clean:
	rm -rf ${OSM_LINES_EXTRACTED_FLAG} ${OSM_LINES_SHAPEFILE}

osm-lines-extract-rebuild: osm-lines-extract-clean osm-lines-extract


# extract the quadrant (e.g. north half of western hemisphere) to speed things up
${OSM_SOURCE}: ${OSM_PLANET}
	@echo -e "\nExtracting OSM PBF for quadrant ${QUADRANT_EXTENT}..."
	osmconvert ${OSM_PLANET} -v -b=${QUADRANT_EXTENT} --complete-ways --complete-multipolygons --complete-boundaries -o=$@

${OSM_PBF}: ${OSM_SOURCE} # clip PBF to bucket to make processing more efficient; no flag needed
	@echo -e "\nExtracting OSM PBF for ${BUCKET}..."
	osmconvert ${OSM_SOURCE} -v -b=${BUCKET_LATLON_EXPANDED} --complete-ways --complete-multipolygons --complete-boundaries -o=$@

${OSM_LINES_EXTRACTED_FLAG}: ${OSM_PBF} ${OSM_PBF_CONF}
	@echo -e "\nExtracting foreground OSM line features for ${BUCKET}..."
	@rm -f $@ ${OSM_LINES_SHAPEFILE}
	ogr2ogr -oo CONFIG_FILE="${OSM_PBF_CONF}" -spat ${SPAT_EXPANDED} -progress ${OSM_LINES_SHAPEFILE} ${OSM_PBF} -sql "SELECT * FROM lines WHERE ${OSM_LINES_QUERY}"
	@echo Creating spatial index...
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}-lines" ${OSM_LINES_SHAPEFILE}
	@mkdir -p ${FLAGS_DIR} && touch $@

${OSM_AREAS_EXTRACTED_FLAG}: ${OSM_PBF} ${OSM_PBF_CONF}
	@echo -e "\nExtracting foreground OSM area features for ${BUCKET}..."
	@rm -f $@ ${OSM_AREAS_SHAPEFILE}
	ogr2ogr -oo CONFIG_FILE="${OSM_PBF_CONF}" -spat ${SPAT_EXPANDED} -progress ${OSM_AREAS_SHAPEFILE} ${OSM_PBF} -sql "SELECT * FROM multipolygons WHERE ${OSM_AREAS_QUERY}"
	@echo Creating spatial index...
	ogrinfo -sql "CREATE SPATIAL INDEX ON ${BUCKET}-areas" ${OSM_AREAS_SHAPEFILE}
	@mkdir -p ${FLAGS_DIR} && touch $@


#
# Extract airports
#

airports-extract: ${AIRPORTS} # single file - no flag needed

${AIRPORTS}: ${AIRPORTS_SOURCE} $(wildcard ${INPUTS_DIR}/airports/custom/*.dat) ${SCRIPT_DIR}/filter-airports.py ${VENV}
	mkdir -p ${DATA_DIR}/airports/${BUCKET}/
	@echo -e "\nExtracting airport-data file ${AIRPORTS}..."
	. ${VENV} && python3 ${SCRIPT_DIR}/filter-airports.py ${BUCKET} ${INPUTS_DIR}/airports/custom/*.dat ${AIRPORTS_SOURCE} > $@

airports-extract-clean:
	rm -f ${AIRPORTS}

airports-extract-rebuild: airports-extract-clean airports-extract



########################################################################
# 2. Prepare
########################################################################

prepare: elevations airports landmass landcover osm

prepare-clean: airports-clean landmass-clean landcover-clean osm-clean

prepare-clean-all: prepare-clean elevations-clean # don't clean elevations by default

prepare-rebuild: prepare-clean prepare

prepare-rebuild-all: prepare-clean-all prepare

#
# Prepare elevation data from the DEMs
# Set the Makefile var DEM to SRTM-3 or FABDEM (default)
#

elevations: ${ELEVATIONS_FLAG}

elevations-clean:
	rm -rvf ${WORK_DIR}/${DEM}/DEM/${BUCKET}/ ${ELEVATIONS_FLAG}

elevations-rebuild: elevations-clean elevations

${ELEVATIONS_FLAG}:  ${INPUTS_DIR}/${DEM}/Unpacked/${BUCKET} ${SCRIPT_DIR}/list-dem.py
	rm -rf ${ELEVATIONS_FLAG} ${TEMP_DIR}/${DEM}/DEM/${BUCKET}
	mkdir -p ${TEMP_DIR}/${DEM}/DEM
	gdalchop ${TEMP_DIR}/${DEM}/DEM $$(python3 ${SCRIPT_DIR}/list-dem.py ${INPUTS_DIR}/${DEM}/Unpacked ${BUCKET})
	terrafit ${TEMP_DIR}/${DEM}/DEM/${BUCKET} ${TERRAFIT_OPTS}
	rm -rf ${WORK_DIR}/${DEM}/DEM/${BUCKET} # remove any old stuff to avoid errors
	if [ -d ${TEMP_DIR}/${DEM}/DEM/${BUCKET} ]; then mv -v ${TEMP_DIR}/${DEM}/DEM/${BUCKET} ${WORK_DIR}/${DEM}/DEM/${BUCKET}; fi; \
	mkdir -p ${FLAGS_DIR} && touch ${ELEVATIONS_FLAG}

elevations-fit-all:
	@echo -e "\nFitting all elevations..."
	terrafit ${WORK_DIR}/${DEM}/DEM ${TERRAFIT_OPTS}

elevations-fit-bucket:
	@echo -e "\nFitting all elevations..."
	terrafit ${WORK_DIR}/${DEM}/DEM/${BUCKET} ${TERRAFIT_OPTS}

elevations-refit-all:
	@echo -e "\nRefitting all elevations..."
	terrafit -f ${WORK_DIR}/${DEM}/DEM ${TERRAFIT_OPTS}

#
# Prepare the airport areas and objects
#

airports: ${AIRPORTS_FLAG}

airports-clean:
	rm -rvf ${WORK_DIR}/${DEM}/AirportObj/${BUCKET}/ ${WORK_DIR}/${DEM}/AirportArea/${BUCKET}/ ${AIRPORTS_FLAG}

airports-rebuild: airports-clean airports

${AIRPORTS_FLAG}: ${AIRPORTS} ${ELEVATIONS_FLAG}
	rm -f ${AIRPORTS_FLAG}
	rm -rf ${WORK_DIR}/${DEM}/AirportArea/${BUCKET} ${WORK_DIR}/${DEM}/AirportObj/${BUCKET}
	@echo -e "\nRegenerating airports for ${BUCKET}..."
	genapts --input=${AIRPORTS} ${BUCKET_LATLON_OPTS} --max-slope=0.4 --threads=${THREADS} \
	  --work=${WORK_DIR}/${DEM} --clear-dem-path --dem-path=DEM
	mkdir -p ${FLAGS_DIR} && touch ${AIRPORTS_FLAG}

#
# Prepare the default landmass
#

landmass: ${LANDMASS_FLAG}

landmass-clean:
	rm -rvf ${WORK_DIR}/Default/${BUCKET}/ ${LANDMASS_FLAG}

landmass-rebuild: landmass-clean landmass

${LANDMASS_FLAG}: ${LANDMASS_SHAPEFILE}
	rm -f ${LANDMASS_FLAG}
	rm -rf ${WORK_DIR}/Default/${BUCKET}
	@echo -e "\nPreparing default landmass for ${BUCKET}..."
	ogr-decode ${DECODE_OPTS} --area-type Default ${WORK_DIR}/Default ${LANDMASS_SHAPEFILE}
	mkdir -p ${FLAGS_DIR} && touch ${LANDMASS_FLAG}

#
# Prepare the background landcover layers
#

landcover: ${LANDCOVER_LAYERS_FLAG}

landcover-clean:
	rm -rfv ${WORK_DIR}/lc-*/${BUCKET}/ ${LANDCOVER_LAYERS_FLAG}

landcover-rebuild: landcover-clean landcover

${LANDCOVER_LAYERS_FLAG}: ${LANDCOVER_EXTRACTED_FLAG} ${CONFIG_DIR}/landcover-layers.tsv
	rm -f $@
	@echo -e "\nPreparing landcover area layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/landcover-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'area' ]; then \
	    echo -e "\nTrying $$name..."; \
	    rm -rf ${TEMP_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --area-type $$material --where "$$query" \
	      ${TEMP_DIR}/$$name ${LANDCOVER_SHAPEFILE} || exit 1;\
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    if [ -d ${TEMP_DIR}/$$name/${BUCKET} ]; then mv -v ${TEMP_DIR}/$$name/${BUCKET} ${WORK_DIR}/$$name; fi; \
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

#
# Prepare the foreground OSM layers
#

osm: ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

osm-clean:
	rm -rfv ${WORK_DIR}/osm-*/${BUCKET} ${OSM_AREA_LAYERS_FLAG} ${OSM_LINE_LAYERS_FLAG}

osm-rebuild: osm-clean osm

osm-areas: ${OSM_AREA_LAYERS_FLAG}

osm-areas-clean:
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$type" = 'area' ]; then \
	    d=${WORK_DIR}/$$name/${BUCKET}; \
            echo Removing $$d ...; \
	    rm -rf $$d; \
	  fi; \
	done
	rm -fv ${OSM_AREA_LAYERS_FLAG}

${OSM_AREA_LAYERS_FLAG}: ${OSM_AREAS_EXTRACTED_FLAG} ${CONFIG_DIR}/osm-layers.tsv
	rm -f $@
	@echo -e "\nPreparing OSM area layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'area' ]; then \
	    echo -e "\nTrying $$name with $$query..."; \
	    rm -rf ${TEMP_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --area-type $$material --where "$$query" \
	      ${TEMP_DIR}/$$name ${OSM_AREAS_SHAPEFILE} || exit 1;\
	    echo Moving from ${TEMP_DIR}; \
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    if [ -d ${TEMP_DIR}/$$name/${BUCKET} ]; then mv -v ${TEMP_DIR}/$$name/${BUCKET} ${WORK_DIR}/$$name; fi; \
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@

osm-lines: ${OSM_LINE_LAYERS_FLAG}

osm-lines-clean:
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$type" = 'line' ]; then \
	    d=${WORK_DIR}/$$name/${BUCKET}; \
            echo Removing $$d ...; \
	    rm -rf $$d; \
	  fi; \
	done
	rm -fv ${OSM_LINE_LAYERS_FLAG}

${OSM_LINE_LAYERS_FLAG}: ${OSM_LINES_EXTRACTED_FLAG} ${CONFIG_DIR}/osm-layers.tsv
	rm -f $@
	@echo -e "\nPreparing OSM line layers...\n"
	IFS="\t" cat ${CONFIG_DIR}/osm-layers.tsv | while read name include type material line_width query; do \
          if [ "$$include" = 'yes' -a "$$type" = 'line' ]; then \
	    echo -e "\nTrying $$name with $$query ..."; \
	    rm -rf ${TEMP_DIR}/$$name/${BUCKET}; \
	    ogr-decode ${DECODE_OPTS} --texture-lines --line-width $$line_width --area-type $$material --where "$$query" \
	      ${TEMP_DIR}/$$name ${OSM_LINES_SHAPEFILE} || exit 1;\
	    rm -rf ${WORK_DIR}/$$name/${BUCKET}; \
	    if [ -d ${TEMP_DIR}/$$name/${BUCKET} ]; then mv -v ${TEMP_DIR}/$$name/${BUCKET} ${WORK_DIR}/$$name; fi; \
	  fi; \
	done
	mkdir -p ${FLAGS_DIR} && touch $@


########################################################################
# 3. Construct
########################################################################

TG_OPTS=--ignore-landmass --nudge=${NUDGE} --threads=${THREADS} \
	--work-dir=${WORK_DIR} --output-dir=${SCENERY_DIR}/Terrain \
	--priorities=${CONFIG_DIR}/default_priorities.txt

# Build a 10x10 scenery bucket, possibly split up into smaller areas
scenery: extract prepare
	for lat in $$(seq ${BUCKET_MIN_LAT} ${INCREMENT} $$(expr ${BUCKET_MAX_LAT} - 1)); do \
	  for lon in $$(seq ${BUCKET_MIN_LON} ${INCREMENT} $$(expr ${BUCKET_MAX_LON} - 1)); do \
	    tg-construct ${TG_OPTS} \
		--min-lat=$$lat --min-lon=$$lon --max-lat=$$(expr $$lat + ${INCREMENT}) --max-lon=$$(expr $$lon + ${INCREMENT}) \
		${PREPARE_AREAS};\
	  done; \
	done

scenery-clean:
	rm -rf ${SCENERY_DIR}/Terrain/${BUCKET} ${WORK_DIR}/Shared/stage1/${BUCKET} ${WORK_DIR}/Shared/stage2/${BUCKET}

scenery-rebuild: scenery-clean scenery

# Build or rebuild an area of scenery with no dependencies bucket limitation (can cross bucket): HANDLE WITH CARE
scenery-no-bucket:
	tg-construct ${TG_OPTS} ${LATLON_OPTS} ${PREPARE_AREAS}

# Build a single scenery tile (see scripts/tile-index.py)
scenery-tile:
	tg-construct ${TG_OPTS} --tile-id=${TILE_ID} ${PREPARE_AREAS}



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

static-files:
	cp -v ${STATIC_DIR}/* ${SCENERY_DIR}


${SCENERY_DIR}/NavData/apt/${BUCKET}.apt: ${AIRPORTS}
	mkdir -p ${SCENERY_DIR}/NavData/apt
	cp -v ${AIRPORTS} ${SCENERY_DIR}/NavData/apt/${BUCKET}.dat


archive: static-files navdata thresholds-clean thresholds
	cd ${OUTPUT_DIR} \
	  && tar cvf ${SCENERY_NAME}-${BUCKET}-$$(date +%Y%m%d).tar ${SCENERY_NAME}/README.md ${SCENERY_NAME}/UNLICENSE.md ${SCENERY_NAME}/clean-symlinks.sh ${SCENERY_NAME}/gen-symlinks.sh ${SCENERY_NAME}/gen-symlinks.bat ${SCENERY_NAME}/Airports ${SCENERY_NAME}/NavData/apt/${BUCKET}.dat ${SCENERY_NAME}/Terrain/${BUCKET}

# Will move
publish-cloud:
	cp -v ${STATIC_DIR}/README.md "${PUBLISH_DIR}" \
	  && mkdir -p "${PUBLISH_DIR}"/Old \
	  && (mv -fv "${PUBLISH_DIR}"/*-${BUCKET}-*.tar ${PUBLISH_DIR}/Old/ || echo "No previous file") \
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
