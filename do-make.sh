#!/bin/bash
########################################################################
# Run the Makefile over an area
#
# The TerraGear utils are unreliable over large geographical areas;
# This script allows breaking those down into smaller areas and
# iterating easily.
#
#
# USAGE
#
#  $ bash do-make.sh <min-lon> <min-lat> <max-lon> <max-lat> <target>
#
#  min-lon: minimum longitude in integer degrees, e.g. -80
#  min-lat: minimum latitude in integer degrees, e.g. 40
#  max-lon: maximum longitude in integer degrees, e.g. -70
#  max-lat: maximum latitude in integer degrees, e.g. 50
#  step: increment in integer degrees, e.g. 1
#  target: the Makefile target to build each time
#
#
# ENVIRONMENT VARIABLES
#
# STEP:build areas larger than 1x1 deg (STEP must be a factor
# of 10, i.e. 1, 2, 5, or 10):
#
# $ STEP=2 bash do-make.sh -80 40 -70 50 scenery
#
# START_LAT, START_LON: restart at a specific lat/lon within the area:
#
# $ START_LAT=42 START_LON=-75 sh do-make.sh -80 40 -70 50 scenery
#
#
# TESTING PARAMETERS
#
# Test with the 'echo' target:
#
# $ bash do-make.sh -80 40 -70 40 1 echo
#
#
# AUTHOR
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
: ${START_LAT:=$MIN_LAT} # starting latitude (for restarting)
: ${START_LON:=$MIN_LON} # starting longitude (for restarting)
: ${THREADS:=4} # default threads for build

# ensure STEP is reasonable for a full-bucket build
if [ $STEP -ne 1 -a $STEP -ne 2 -a $STEP -ne 5 -a $STEP -ne 10 ]; then
    echo "STEP is $STEP; must be 1, 2, 5, or 10." >&2
    exit 1
fi

#
# Main loop
#

# don't necessarily start at beginning
bucket_min_lat=$START_LAT
bucket_min_lon=$START_LON

while [ $bucket_min_lat -lt $MAX_LAT ]; do
    bucket_max_lat=$(expr $bucket_min_lat + $STEP)
    while [ $bucket_min_lon -lt $MAX_LON ]; do
        bucket_max_lon=$(expr $bucket_min_lon + $STEP)
        set_bucket $bucket_min_lon $bucket_min_lat
        # advance only if the build succeeded
        make MAX_THREADS=$THREADS BUCKET=$BUCKET MIN_LON=$bucket_min_lon MIN_LAT=$bucket_min_lat MAX_LON=$bucket_max_lon MAX_LAT=$bucket_max_lat $TARGETS \
            || exit
        bucket_min_lon=$bucket_max_lon
    done

    # start next row
    bucket_min_lon=$MIN_LON
    bucket_min_lat=$bucket_max_lat
done

