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

TEMPLATE='https://data.bris.ac.uk/datasets/s5hqmjcdj8yo2ibzi9b4ew3sn/%s%02d%s%03d-%s%02d%s%03d_FABDEM_V1-2.zip'

MIN_LAT=-90
MIN_LON=-180
MAX_LAT=90
MAX_LON=0

function dir_x () {
    [ $1 -lt 0 ] && echo W || echo E
}

function dir_y () {
    [ $1 -lt 0 ] && echo S || echo N
}

function abs () {
    [ $1 -lt 0 ] && expr $1 '*' -1 || echo $1
}


lat=$MIN_LAT
lon=$MIN_LON
while [ $lat -lt $MAX_LAT ]; do
    while [ $lon -lt $MAX_LON ]; do
        max_lat=$(expr $lat + 10)
        max_lon=$(expr $lon + 10)
        url=$(printf "$TEMPLATE" \
                     $(dir_y $lat) $(abs $lat) \
                     $(dir_x $lon) $(abs $lon) \
                     $(dir_y $max_lat) $(abs $max_lat) \
                     $(dir_x $max_lon) $(abs $max_lon) )
        #echo $lat $lon $max_lat $max_lon $url; exit
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
