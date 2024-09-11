#!/bin/bash
########################################################################
# Run FlightGear using the newly-generated scenery.
# Start the UFO at 3,000 ft MSL facing north.
########################################################################

BASEDIR=$(cd $(dirname $0)/.. && pwd)

FG_ROOT=$HOME/.local/share/flightgear
export FG_ROOT

FG_HOME=$BASEDIR/config/fgfs
export FG_HOME

FG_SCENERY=$BASEDIR/04-output/fgfs-americas-scenery
export FG_SCENERY

fgfs --no-default-config \
     --disable-sound --disable-ai-traffic \
     --disable-clouds --disable-clouds3d --disable-real-weather-fetch \
     --prop:string:/sim/thread-cpu-affinity=osg \
     --enable-hud --save-on-exit=1 \
     --fullscreen=1 --texture-filtering=16 --texture-cache=1 \
     --start-date-lat=2023:06:30:12:00:00 \
     --generic=broadcast,out,10,255.255.255.255,49002,foreflight-xatt \
     --generic=broadcast,out,1,255.255.255.255,49002,foreflight-xgps \
     --aircraft=ufo --heading=0 --altitude=3000 "$@"
