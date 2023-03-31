#!/bin/bash
########################################################################
# Extract OSM features into general shapefiles
########################################################################

set -e

AREA_FEATURES="aeroway amenity geological landuse military natural place sport water"
LINE_FEATURES="highway power railway"


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/utils.sh"

# fixme - param should be bucket
if [ $# -lt 4 ]; then
    echo "Usage: bash $0 <OSM-DIR> <SHAPEFILE-DIR> <CONFIG-FILE> [BUCKET...]" >&2
    exit 2
fi

OSM_DIR=$1; shift
SHAPEFILE_DIR=$1; shift
CONFIG_FILE=$1; shift


for BUCKET in $@; do
    echo "Starting $BUCKET ..."
    SPAT=$(bucket2spat $BUCKET)

    SOURCE="$OSM_DIR/$BUCKET.osm.pbf"
    DEST_DIR="$SHAPEFILE_DIR/$BUCKET"

    # make the destination directory if it doesn't already exist
    mkdir -p "$DEST_DIR"

    # add the area features
    for FEATURE in $AREA_FEATURES; do
        echo "Extracting area feature $FEATURE in $BUCKET ..."
        ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -spat $SPAT -progress "$DEST_DIR/$FEATURE.shp" "$SOURCE" -sql "SELECT * FROM multipolygons WHERE $FEATURE IS NOT NULL"
    done

    # add the line features
    for FEATURE in $LINE_FEATURES; do
        echo "Extracting line feature $FEATURE in $BUCKET ..."
        ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -spat $SPAT -progress "$DEST_DIR/$FEATURE.shp" "$SOURCE" -sql "SELECT * FROM lines WHERE $FEATURE IS NOT NULL"
    done
done
