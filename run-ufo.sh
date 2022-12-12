#!/bin/sh

AIRPORT=$1
if [ -z "$AIRPORT" ]; then
    AIRPORT=CYRO
fi

#fgfs --fg-scenery=/home/david/GIS/fgfs/output --enable-fullscreen --disable-sound --disable-real-weather-fetch --timeofday=noon --airport=$AIRPORT --aircraft=UFO --altitude=3000 "$@"
fgfs --enable-fullscreen --disable-sound --disable-real-weather-fetch --timeofday=noon --airport=$AIRPORT --aircraft=UFO --altitude=3000 "$@"
