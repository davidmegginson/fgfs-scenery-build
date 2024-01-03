#!/usr/bin/python3
""" Print the tile index for a lat/lon """

import sys

from math import floor, trunc

TILE_WIDTHS = (
    (-89.0, 12.0,),
    (-86.0, 4.0,),
    (-83.0, 2.0,),
    (-76.0, 1.0,),
    (-62.0, 0.5,),
    (-22.0, 0.25,),
    (22.0, 0.125,),
    (62.0, 0.25,),
    (76.0, 0.5,),
    (83.0, 1.0,),
    (86.0, 2.0,),
    (89.0, 4.0,),
    (90.0, 12.0),
)

if len(sys.argv) != 3:
    print("Usage: {} LAT LON".format(sys.argv[0]), file=sys.stderr)
    sys.exit(2)

lat = float(sys.argv[1])
if lat < -90 or lat > 90:
    print("Latitude out of range", lat, file=sys.stderr)
    sys.exit(1)

lon = float(sys.argv[2])
if lon < -180 or lon > 180:
    print("Longitude out of range", lon, file=sys.stderr)
    sys.exit(1)

# Look up the tile width in degrees for this latitude
tile_width = None
for entry in TILE_WIDTHS:
    if lat < entry[0]:
        tile_width = entry[1]
if tile_width is None:
    raise Exception("Error looking up tile width for latitude {}".format(lat))

# Do the calculations
base_y = floor(lat)
y = trunc((lat - base_y) * 8)
base_x = floor(floor(lon / tile_width) * tile_width)
x = int(floor((lon - base_x) / tile_width))
index=(int(lon + 180) << 14) + (int(lat + 90) << 6) + (y << 3) + x

# display the index
print(index)
