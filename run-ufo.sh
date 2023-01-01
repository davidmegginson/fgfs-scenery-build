#!/bin/sh

AIRPORT=$1
if [ -z "$AIRPORT" ]; then
    AIRPORT=CYRO
fi

fgfs --fg-scenery=/home/david/GIS/fgfs/output --enable-fullscreen --disable-sound --disable-real-weather-fetch --timeofday=noon --altitude=3000 --enable-hud --airport=$AIRPORT --aircraft=UFO "$@"
