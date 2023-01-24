North American Scenery
======================

## Building the scenery

A Makefile drives the process. Note these variables at the top of the Makefile:

```
# What area are we building?
BUCKET=w080n40
MIN_LON=-80
MAX_LON=-70
MIN_LAT=40
MAX_LAT=50
```

You can override these whenever you need to work with a different area, e.g.

```
$ make BUCKET=w090n30 MIN_LON=-95 MAX_LON=-94 MIN_LAT=35 MAX_LAT=36 all
```

Once you have the data prepared, ``make all`` will run through the following steps:

1. Generate and fit elevation data in work/SRTM-3 (``make elevations`` and optionally, ``make cliffs``)
2. Generate airport objects and areas (``make airports``)
3. Generate the landmass layer (``make landmass``)
4. Generate the OSM and landcover layers (``make layers``)
5. Build the actual scenery (``make scenery``)

All of the steps but ``make scenery`` will skip anything that's already built under the ``work/`` directory. To force something to rebuild, use the *-rebuild variants of the targets above, including ``make all-rebuild``.

All of the steps will leave scenery alone that's already built for different areas.

### Splitting the work

The TerraGear scenery tools often fail over large areas. The do-make.sh script allows you to split the work into several smaller jobs:

```
$ sh do-make.sh <min-lon> <min-lat> <max-lon> <max-lat> <target>
```

_target_ is the Makefile target to run repeatedly over each area.

If you want to go by bigger that 1x1 degree squares, set the environment variable _STEP_. For example,

```
% STEP=2 do-make.sh -80 40 -70 50 layers
```

will go through in 2x2 degree increments instead of 1x1 degree.

Use the _do-make.sh_ script only for later steps in scenery building; earlier steps (like elevations and airports) need to work on the entire bucket.


### Making elevations

Once you've prepared the elevation data, run _make_ with the ``elevations`` target, and _BUCKET_ set to the bucket you're building, e.g.

```
$ make BUCKET=w090n40 elevations
```

This will run _gdalchop_ to prepare the elevation data. Expect it to run for a few minutes.

Once your done building elevations, run _make_ with the ``fit-elevations`` target. That will refit elevations for *all* buckets, and again, runs for a while:

```
$ make fit-elevations
```

If you want to remove all the data for a bucket, use the _elevations-clean_ target instead; if you want to remove and rebuild in a single step, use the _elevations-rebuild- target.


### Making the default landmass

Once you've prepared the default landmass data, run _make_ with the _landmass_ target, and _BUCKET_ set to the bucket you're building, e.g.

```
$ make BUCKET=w090n40 landmass
```

This will run the _ogr\_decode_ command to build the default landmass for your bucket.

If you want to delete the landmass, use the _landmass-clean_ target; if you want to delete and rebuild in a single step, use the _landmass-rebuild_ target.

### Making the layers

Once you've prepared the landcover and OSM layers, use the _do-make.sh_ script to build layers degree by degree (if you attempt the whole bucket at once, it will generally fail). For example

```
$ sh do-make -90 40 -80 50 layers
```

will use the ``layers.csv`` file to control which layers to generate for scenery, what materials to apply to each, and how wide to make line-style data, all using the _ogr-decode_ command. You can edit ``layers.csv`` to tweak how your scenery is being built.

Using _areas_ or _lines_ as the target at the end of the command will build only that type of layer. If you want to build a single layer or area, you can do it using the _single-layer_ target and the _AREA\_MATERIAL_ and _AREA\_LAYER_ environment variables like this:

```
$ AREA_MATERIAL=Town AREA_LAYER=lc-urban sh do-make.sh -90 40 -80 50 single-layer
```

### Making cliffs

This step is optional, but makes nicer scenery. If you've included the osm-cliff-natural layer in the previous step (and you should), you can give the scenery engine hints to allow steeper cliffs rather than smoothing them out. You will need to provide both lat/lon and the bucket:

```
$ make BUCKET=w090n40 MIN_LON=-90 MIN_LAT=40 MAX_LON=-80 MAX_LAT=50 cliffs
```

This command will run both _cliff-decode_ and _rectify\_height_ with the appropriate arguments.

### Making airports

(Note: this should run _after_ cliffs, since making cliffs can affect elevation data.)

Once you've prepared the airport data, run _make_ with the ``airports`` target, and _MIN\_LON_, _MIN\_LAT_, _MAX\_LON_ and _MAX\_LAT_ set to the area you're building, e.g.

```
$ make MIN_LON=-90 MIN_LAT=40 MAX_LON=-80 MAX_LAT=50 airports
```

This will run the _genapts850_ command to build the airport areas and objects within those bounds, overriding the default airports with any custom ones you supplied during the preparation process.

If you want to remove all the airports for a bucket, use the _airports-clean_ target (and supply the _BUCKET_). If you want to rebuild, use the _airports-rebuild_ target (and supply both lat/lon bounds and the bucket).


## Data download and preparation

### Elevations preparation

Download SRTM-3 from e.g. https://e4ftl01.cr.usgs.gov//DP133/SRTM/SRTMGL1.003/2000.02.11/N05E014.SRTMGL1.hgt.zip (needs login)

Place the data in ``data/SRTM-3`` in the appropriate buckets. For example, data/SRTM-3/w090n40/ should include files from N40W081.hgt to N49W090.hgt.


### Airports preparation

Create the directory ``data/airports`` and copy the ``Airports/apt.dat.gz`` copy from the FlightGear distribution into it.

Add any custom airports you want under data/airports/modified in uncompressed .apt.dat format, in the appropriate bucket (e.g. data/airports/modified/w080n40/CYRO.apt.dat)

Run ``make prepare-airports`` to generate a new airports file for scenery building (requires Python3).


### OSM preparation

(TODO)

The Makefile expects to find OSM shapefiles for your bucket in the directory ../osm, e.g. ``../osm/shapefiles/w080n40/highways.shp``

If you have them somewhere else, you can override OSM_DIR on the command line, e.g.

```
$ make BUCKET=w090n40 OSM_DIR=/usr/share/osm osm-shapefiles-prepare
```

### Landcover preparation

This section describes the default background, for when we don't have any more-detailed scenery to place on top. It is lower priority than airports or anything we take from OSM.

We will use the MODIS (250m) North American landcover raster from http://www.cec.org/north-american-environmental-atlas/land-cover-2010-modis-250m/

Run each step on the output from the previous step.

Inside qgis:

- go to Raster/Projections/Warp (Reproject) and reproject to EPSG:4326/WGS 84 using "Nearest neighbours" (fast) or "Mode" (slower, but maybe better; try both and see which you prefer)
- go to Raster/Extraction/Clip Raster by Extent and clip to the desired area (min lon, max lon, min lat, max lat)

In the qgis toolbox:

- run the GRASS/Raster/r.null function to change value 18 (water) to null
- run the GRASS/Raster/r.neighbours function with 3 neighbours (median, not average)
- run the GRASS/Raster/r.neighbours function with 3 neighbours again (median, not average)
- use GRASS r.to.vect to vectorise, selecting rounded corners
- save the layer in ESRI Shapefile format

Next, generate the input polygons for FlightGear, e.g.

```
$ make BUCKET=w090n40 lc-shapefiles-prepare
```

