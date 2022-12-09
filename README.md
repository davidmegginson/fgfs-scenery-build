North American Scenery
======================

## Elevations preparation

## Airports preparation

## OSM preparation

## Landcover preparation

This section describes the default background, for when we don't have any more-detailed scenery to place on top. It is lower priority than airports or anything we take from OSM.

We will use the MODIS (250m) North American landcover raster from http://www.cec.org/north-american-environmental-atlas/land-cover-2010-modis-250m/

Clip to the scenery area (using gdalwarp?).

Inside qgis:

- run the GRASS neighbours function with 3 neighbours (median, not average)
- run GDAL sieve to remove areas smaller than 32 pixels
- run the GRASS neighbours function again with 3 neighbours (median, not average)
- run GDAL sieve again to remove areas smaller than 32 pixels
- use GRASS r.to.vect to vectorise, selecting rounded corners
- (Could also try GRASS v.generalize, but not doing that for now.)

Put the result in source/vector/<whatever>.shp

Next, generate the input polygons for FlightGear. Put the appropriate source in extract-landcover.sh, check the type mappings in landcover.csv, and then run extract-landcover.sh

