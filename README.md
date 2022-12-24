North American Scenery
======================

## Building the scenery

A Makefile drives the process. Note these variables at the top of the Makefile:

```
# What area are we building?
AREA=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50
```

You can override these whenever you need to work with a different area, e.g.

```
$ make AREA=w090n30 MIN_LON=-95 MAX_LON=-94 MIN_LAT=35 MAX_LAT=36 all
```

Once you have the data prepared, ``make all`` will run through the following steps:

1. Generate and fit elevation data in work/SRTM-3 (``make elevations``)
2. Generate airport objects and areas (``make airports``)
3. Generate the landmass layer (``make landmass``)
4. Generate the OSM and landcover layers (``make layers``)
5. Build the actual scenery (``make scenery``)

All of the steps but ``make scenery`` will skip anything that's already built under the ``work/`` directory. To force something to rebuild, use the *-rebuild variants of the targets above, including ``make all-rebuild``.

All of the steps will leave scenery alone that's already built for different areas.


## Data download and preparation

### Elevations preparation

Download SRTM-3 from e.g. https://e4ftl01.cr.usgs.gov//DP133/SRTM/SRTMGL1.003/2000.02.11/N05E014.SRTMGL1.hgt.zip (needs login)

### Airports preparation

Create the directory ``./data/airports`` and copy the ``Airports/apt.dat.gz`` copy from the FlightGear distribution into it.

Run ``make prepare-airports`` to generate a new airports file for scenery building (requires Python3).

### OSM preparation

(TODO)

The Makefile expects to find OSM shapefiles for your bucket in the directory ../osm, e.g. ``../osm/shapefiles/w080n40/highways.shp``

If you have them somewhere else, you can override OSM_DIR on the command line, e.g.

```
$ make OSM_DIR=/usr/share/osm shapefiles-prepare
```

### Landcover preparation

This section describes the default background, for when we don't have any more-detailed scenery to place on top. It is lower priority than airports or anything we take from OSM.

We will use the MODIS (250m) North American landcover raster from http://www.cec.org/north-american-environmental-atlas/land-cover-2010-modis-250m/

Inside qgis:

- go to Raster/Projections/Warp (Reproject) and reproject to EPSG:4326/WGS 84
- go to Raster/Extraction/Clip Raster by Extent and clip to the desired area (min lon, max lon, min lat, max lat)

In the qgis toolbox:

- run the GRASS/Raster/r.neighbours function with 3 neighbours (median, not average)
- run GDAL/Raster analysis/Sieve to remove areas smaller than 32 pixels
- run the GRASS/Raster/r.neighbours function again with 3 neighbours (median, not average)
- run GDAL/Raster analysis/Sieve again to remove areas smaller than 32 pixels
- use GRASS r.to.vect to vectorise, selecting rounded corners
- (Could also try GRASS v.generalize, but not doing that for now.)
- save the layer in ESRI Shapefile format

Put the result in source/vector/<whatever>.shp

Next, generate the input polygons for FlightGear. Put the appropriate source in extract-landcover.sh, check the type mappings in landcover.csv, and then run extract-landcover.sh
