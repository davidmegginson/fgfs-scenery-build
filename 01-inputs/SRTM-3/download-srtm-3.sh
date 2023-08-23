#!/bin/sh
########################################################################
# Download SRTM-3 elevation zipfiles for North America
#
# Usage:
#   $ bash download-dems.sh
#
# Run from the directory containing this script. The downloaded files
# will appear in Downloads/
#
# Safe to run more than once, because it skips files that have already
# been downloaded.
########################################################################

DIR=Downloads

ROWS="A B C D E F G H I J K L M N O P Q R S T U "
COLS="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22"

cd $DIR

for row in $ROWS; do
    for col in $COLS; do
        file=$row$col.zip
        url=http://viewfinderpanoramas.org/dem3/$file
        if [ ! -e $DIR/$file ]; then
            wget -c -P $DIR -v $url || (rm -f $DIR/$file && exit 2)
        else
            echo "Skipping $file"
        fi
    done
done

# end
