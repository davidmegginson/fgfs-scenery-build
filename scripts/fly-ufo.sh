#!/bin/bash
########################################################################
# Run FlightGear using the newly-generated scenery.
# Start the UFO at 3,000 ft MSL facing north.
########################################################################

BASEDIR=$(cd $(dirname $0)/.. && pwd)

FG_HOME=$BASEDIR/config/fgfs
export FG_HOME

FG_ROOT=/usr/local/share/flightgear
export FG_ROOT

FG_SCENERY=$BASEDIR/04-output/fgfs-americas-scenery
export FG_SCENERY

fgfs --disable-sound --disable-ai-traffic \
     --disable-clouds --disable-clouds3d --disable-real-weather-fetch \
     --prop:string:/sim/thread-cpu-affinity=osg \
     --enable-hud --save-on-exit=1 \
     --fullscreen=1 --texture-filtering=16 --texture-cache=1 \
     --start-date-gmt=2023:06:30:16:00:00 --terrasync=0 \
     --generic=socket,out,10,255.255.255.255,49002,udp,foreflight-xatt \
     --generic=socket,out,1,255.255.255.255,49002,udp,foreflight-xgps \
     --aircraft=ufo "$@" --heading=0 --altitude=3000
