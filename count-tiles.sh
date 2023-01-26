#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <bucket>" >&2
    exit 2
fi

for d in ./fgfs-canada-us-scenery/Terrain/$1/*; do
    num=$(ls $d/*.stg | wc -l)
    if [ $num -ne 32 ]; then
        echo $d $num
    fi
done

