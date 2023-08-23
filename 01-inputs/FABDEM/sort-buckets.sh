#!/bin/bash
########################################################################
# Sort FABDEM geotiff files into buckets
#
#
# Usage:
#   $ bash sort-buckets.sh
#
# 1. Download the FABDEM zipfiles for your area.
# 2. Unzip the contents into the Unpacked/ directory
# 3. Run this script from its own directory to sort the .tiff files
#    into buckets.
########################################################################

DIR=Unpacked

abs () {
    if [ $1 -lt 0 ]; then
        echo $(expr $1 \* -1)
    else
        echo $1
    fi
}

latlon2num() {
    n=$1
    n=$(echo $n | sed -e 's/^[ne]//i')
    n=$(echo $n | sed -e 's/^[sw]/-/i')
    echo $n
}

floor10 () {
    num=$1
    fl=$(expr $num / 10 \* 10)
    if [ $fl -gt $num ]; then
        fl=$(expr $fl - 10)
    fi
    echo $fl
}

latlon2bucket() {
    lat_h=$(echo $1 | cut -b 1 | tr NS ns)
    lon_h=$(echo $2 | cut -b 1 | tr EW ew)
    lat=$(floor10 $(latlon2num $1))
    lon=$(floor10 $(latlon2num $2))
    printf "%s%03d%s%02d" $lon_h $(abs $lon) $lat_h $(abs $lat)
}

for file in $DIR/*.tif; do
    lat_s=$(echo $file | sed -e 's/.*\([NS]..\).*/\1/')
    lon_s=$(echo $file | sed -e 's/.*\([EW]...\)_FABDEM.*/\1/')
    bucket=$(latlon2bucket $lat_s $lon_s)
    mkdir -p $DIR/$bucket && mv -v $file $DIR/$bucket
done

# end
