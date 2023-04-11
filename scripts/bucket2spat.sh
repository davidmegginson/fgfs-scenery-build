#!/bin/sh
########################################################################
# Convert a single 10x10 bucket to lon/lat rectangle corners
#
# e.g. "w080n40" becomes "-80 40 -70 50"
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

echo $MIN_LON $MIN_LAT $MAX_LON $MAX_LAT
    
