PROG=~/Source/FlightGear/flightgear-debug-build/src/Main/fgfs

gdb --args $PROG "$@" --no-default-config --disable-terrasync --disable-sound --disable-ai-traffic --disable-clouds --disable-clouds3d --disable-real-weather-fetch --timeofday=morning --terrasync-dir=/tmp --enable-fullscreen --enable-hud --fg-scenery=/media/david/Storage/fgfs-scenery/04-output/fgfs-canada-us-scenery/ --aircraft=ufo --heading=0 --altitude=3000
