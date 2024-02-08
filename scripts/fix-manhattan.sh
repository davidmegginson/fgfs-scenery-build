#!/bin/sh
########################################################################
# Fix FABDEM elevation problems on Manhattan Island
########################################################################

FOLDER=04-output/fgfs-americas-scenery/Terrain/w080n40/

# 74W runs right down the middle of the island
TILES="1728680 1728688 1745064 1745072"

for tile in $TILES; do
    find $FOLDER -name $tile* | xargs rm -v
done

for tile in $TILES; do
    echo Rebuilding $tile with SRTM-3
    make DEM=SRTM-3 TILE_ID=$tile scenery-tile
done
