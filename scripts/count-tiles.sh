#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <bucket>" >&2
    exit 2
fi

for d in ./04-output/fgfs-canada-us-scenery/Terrain/$1/*; do
    num=$(ls $d/*.stg | wc -l)
    echo $d $num
done

