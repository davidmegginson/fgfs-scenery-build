#!/bin/bash
########################################################################
# Extract OSM tags into shapefile features
########################################################################

set -e

# OSM tags that we want to extract into shapefiles
AREA_FEATURES="aeroway amenity geological landuse military natural place sport water"
LINE_FEATURES="highway power railway"

if [ $# -ne 3 ]; then
    echo "Usage: bash $0 <OSM-SOURCE> <DEST-DIR> <CONFIG-FILE>"
    exit 2
fi

OSM_SOURCE=$1
DEST_DIR=$2
CONFIG_FILE=$3


# add the area features
for FEATURE in $AREA_FEATURES; do
    echo "Extracting area feature $FEATURE ..."
    ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -progress "$DEST_DIR/$FEATURE.shp" "$OSM_SOURCE" -sql "SELECT * FROM multipolygons WHERE $FEATURE IS NOT NULL"
done

# add the line features
for FEATURE in $LINE_FEATURES; do
    echo "Extracting line feature $FEATURE ..."
    ogr2ogr -oo CONFIG_FILE="$CONFIG_FILE" -progress "$DEST_DIR/$FEATURE.shp" "$OSM_SOURCE" -sql "SELECT * FROM lines WHERE $FEATURE IS NOT NULL"
done
