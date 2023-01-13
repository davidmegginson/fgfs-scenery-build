#!/bin/sh

AIRPORT=$1
if [ -z "$AIRPORT" ]; then
    AIRPORT=CYRO
fi

fgfs --fg-scenery=/home/david/GIS/fgfs/output --enable-fullscreen --disable-sound --disable-real-weather-fetch --timeofday=noon --enable-hud --altitude=3000 --airport=$AIRPORT --aircraft=UFO "$@"
