#!/bin/sh
########################################################################
# Generate Makefile variables for a bucket
#
# e.g. "w080n40" becomes
#   BUCKET=w080n40 MIN_LON=-80 MIN_LAT=40 MAX_LON=-70 MAX_LAT=50
########################################################################

if [ $# -ne 1 ]; then
    echo "Usage: sh $0 <bucket>" >&2
    echo "Bucket example: w080n40" >&2
    exit 2
fi

BUCKET=$1

for value in `echo $BUCKET | sed -e 's/[sSwW]/ -/g' | tr 'nNeE' ' '`; do
    if [ -z "$MIN_LON" ]; then
        MIN_LON=`expr 0 + $value`
        MAX_LON=`expr $value + 10`
    else
        MIN_LAT=`expr 0 + $value`
        MAX_LAT=`expr $value + 10`
    fi
done

echo "BUCKET=$BUCKET MIN_LON=$MIN_LON MIN_LAT=$MIN_LAT MAX_LON=$MAX_LON MAX_LAT=$MAX_LAT"
    
