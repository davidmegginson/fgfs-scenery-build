#!/bin/bash
########################################################################
# Extract OSM features into general shapefiles
#
# Note: for w080n40, failing on power or railway, so need to be
# more specific
#
# WHERE power='line'
# WHERE railway in ('abandoned', 'disused', 'light_rail', 'preserved', 'rail')
########################################################################

set -e

AREA_FEATURES="aeroway amenity geological landuse man_made military natural place sport water waterway"
LINE_FEATURES="highway man_made power railway waterway"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/utils.sh"

if [ $# -lt 4 ]; then
    fail "Usage: bash $0 <OSM-DIR> <SHAPEFILE-DIR> <CONFIG-FILE> [BUCKET...]" 2
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
        file="$DEST_DIR/${FEATURE}_areas.shp"
        echo "Extracting area feature $FEATURE in $BUCKET to $file..."
        ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -spat $SPAT -progress $file "$SOURCE" -sql "SELECT * FROM multipolygons WHERE $FEATURE IS NOT NULL" \
                || (rm -rf "$DEST_DIR/$FEATURE".* && fail "Failed to build area $FEATURE" $?)
    done

    # add the line features
    for FEATURE in $LINE_FEATURES; do
        file="$DEST_DIR/${FEATURE}_lines.shp"
        echo "Extracting line feature $FEATURE in $BUCKET to $file..."
        ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -spat $SPAT -progress $file "$SOURCE" -sql "SELECT * FROM lines WHERE $FEATURE IS NOT NULL" \
                || (rm -rf "$DEST_DIR/$FEATURE".* && fail "Failed to build line $FEATURE" $?)
    done
done
