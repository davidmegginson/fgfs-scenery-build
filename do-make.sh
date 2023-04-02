#!/bin/bash
########################################################################
# Run the Makefile repeatedly over an area
#
# The TerraGear utils are unreliable over large geographical areas;
# This script allows breaking those down into smaller areas and
# iterating easily.
#
# Usage:
#
#   $ bash do-make.sh <min-lon> <min-lat> <max-lon> <max-lat> <step> <target>
#
#  min-lon: minimum longitude in integer degrees, e.g. -80
#  min-lat: minimum latitude in integer degrees, e.g. 40
#  max-lon: maximum longitude in integer degrees, e.g. -70
#  max-lat: maximum latitude in integer degrees, e.g. 50
#  step: increment in integer degrees, e.g. 1
#  target: the Makefile target to build each time
#
# Test with the 'echo' target:
#
#   $ bash do-make.sh -80 40 -70 40 1 echo
#
# Warning: does not detect if the step will cross buckets.
#
# By David Megginson, 2022-12
# Released into the Public Domain
########################################################################

# Exit on error
set -e

#
# Functions
#

# Set the $BUCKET variable
# Usage:
#   set_bucket $lon $lat
set_bucket()
{
    D_LON='e'
    B_LON=$(expr $1 / 10 \* 10)

    D_LAT='n'
    B_LAT=$(expr $2 / 10 \* 10)

    if [ $MIN_LON -lt 0 ]; then
        D_LON='w'
        B_LON=$(expr $B_LON \* -1)
        if [ $(expr $1 % 10) -ne '0' ]; then
            B_LON=$(expr $B_LON + 10)
        fi
    fi

    if [ $MIN_LAT -lt 0 ]; then
        D_LAT='s'
        B_LAT=$(expr $B_LAT \* -1)
        if expr $2 \% 10 == 0 > /dev/null; then
            B_LAT=$(expr $B_LAT + 10)
        fi
    fi

    BUCKET=$(printf '%s%03d%s%02d' $D_LON $B_LON $D_LAT $B_LAT)
}


#
# Arguments and global variables
#

# Check usage
if [ $# -lt 5 ]; then
    echo "Usage: $0 <min-lon> <min-lat> <max-lon> <max-lat> <targets...>" >&2
    exit 2
fi

# Assign variables
BUCKET='' # will be assigned using set_bucket() with each iteration
MIN_LON=$1; shift
MIN_LAT=$1; shift
MAX_LON=$1; shift
MAX_LAT=$1; shift
TARGETS=$@
: ${STEP:=1} # use the STEP environment variable to override

#
# Main loop
#

min_lat=$MIN_LAT
while [ $min_lat -lt $MAX_LAT ]; do
    max_lat=$(expr $min_lat + $STEP)
    min_lon=$MIN_LON
    while [ $min_lon -lt $MAX_LON ]; do
        max_lon=$(expr $min_lon + $STEP)
        set_bucket $min_lon $min_lat
        make BUCKET=$BUCKET MIN_LON=$min_lon MIN_LAT=$min_lat MAX_LON=$max_lon MAX_LAT=$max_lat $TARGETS
        min_lon=$max_lon
    done
    min_lat=$max_lat
done

exit 0
