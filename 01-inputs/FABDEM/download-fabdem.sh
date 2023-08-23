#!/bin/sh
########################################################################
# Download FABDEM elevation zipfiles for North America
#
# Usage:
#   $ bash download-dems.sh
#
# Run from the directory containing this script. The downloaded files
# will appear in Downloads/
#
# Safe to run more than once, because it skips files that have already
# been downloaded.
#
# Some elevations from outside the area will also appear.
########################################################################

DIR=Downloads

TEMPLATE='https://data.bris.ac.uk/datasets/s5hqmjcdj8yo2ibzi9b4ew3sn/N%02dW%03d-N%02dW%03d_FABDEM_V1-2.zip'

MIN_LAT=0
MIN_LON=-180
MAX_LAT=90
MAX_LON=-50

lat=$MIN_LAT
lon=$MIN_LON
while [ $lat -lt $MAX_LAT ]; do
    while [ $lon -lt $MAX_LON ]; do
        url=$(printf "$TEMPLATE" $lat `expr $lon '*' -1` `expr $lat + 10` `expr $lon '*' -1 - 10`)
        file=$(echo "$url" | sed -e 's!^.*/!!')
        if [ ! -f $DIR/$file ]; then
            wget -c -P $DIR -v "$url" || ( rm -f "$DIR/$file" && exit 2)
        fi
        lon=`expr $lon + 10`
    done
    lon=$MIN_LON
    lat=`expr $lat + 10`
done

# end
