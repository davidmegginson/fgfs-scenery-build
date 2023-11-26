#!/bin/bash
########################################################################
# Run FlightGear using the newly-generated scenery.
# Start the UFO at 3,000 ft MSL facing north.
########################################################################

BASEDIR=$(cd $(dirname $0)/.. && pwd)

fgfs --no-default-config --disable-sound --disable-ai-traffic \
     --disable-clouds --disable-clouds3d --disable-real-weather-fetch \
     --timeofday=morning --terrasync-dir=/tmp --enable-fullscreen \
     --enable-hud --fg-scenery=$BASEDIR/04-output/fgfs-canada-us-scenery/ \
     --aircraft=ufo "$@" --heading=0 --altitude=3000
