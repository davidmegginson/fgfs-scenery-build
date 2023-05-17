North American Scenery
======================

## Configuration

A Makefile drives the process. Note these variables and their default values at the top of the Makefile:

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
$ make BUCKET=w090n30 MIN_LON=-95 MAX_LON=-94 MIN_LAT=35 MAX_LAT=36 scenery
```


## Data download and preparation

The scenery requires GIS data from several sources

* An elevation raster (DEM) to define the shape of the landscape. We use the 3 arc second SRTM-3 data, which includes an elevation point (nominally) every 90 metres. Higher-resolution DEMs are available, but combined with the other data, they may make the scenery too complex and slow down most graphics cards. If you're building scenery for a ground-based simulation, then the higher resolutions might be appropriate.
* The MODIS-250 250m Canada/US landcover raster, which provides background landcover to fill in any gaps in more-detailed OSM data (see below).
* Airport data in the [apt.dat format](http://developer.x-plane.com/wp-content/uploads/2015/11/XP-APT1000-Spec.pdf) that FlightGear shares with the commercial X-Plane simulator. This data defines the shape of runways, taxiways, etc., as well as other information.
* OpenStreetMap (OSM) data in [PBF format](https://wiki.openstreetmap.org/wiki/PBF_Format) covering the area where you want to build scenery. This data defines detailed landcover (like parks and forests), lakes and rivers, as well as linear features like roads, railroads, and powerlines.
    * (Special case) OSM landmass data defining the boundaries between land and ocean (no scenery outside these polygons will be built)

### SRTM-3 data preparation

Download the 3-arcsecond Shuttle Radar Topography Mission (SRTM-3) elevation data for the areas you need from the [original USGS source](https://e4ftl01.cr.usgs.gov//DP133/SRTM/SRTMGL1.003/2000.02.11/N05E014.SRTMGL1.hgt.zip) (needs login) or the interactive map at [Viewfinder Panoramas](http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm). Place them in 01-data/SRTM-3/orig/

To unpack the files, run

```
$ make srtm-unpack
```

Unzip and place all of the *.hgt files together in ``02-data/SRTM-3/``

If you are missing *.hgt files for any of the areas you're building, you will end up with flat scenery all at sea level.


### Airport data preparation

Obtain an apt.dat file, from the FlightGear distribution (``$FG\_ROOT/Airports/apt.dat.gz``), X-Plane (``Custom Scenery/Global Airports/Earth nav 02-data/apt.dat``) or by manually downloading airport data from the [X-Plane Scenery Gateway API]() and stiching the individual airport files together.

Uncompress the file (if needed) and rename to ``01-inputs/airports/apt.dat``

This file can be very large, depending on where you source it from. The next step is to extract the areas you need into buckets under ``02-data/airports/`` using the ``./downgrade-airports.py`` (if you're using an apt.dat format after 1000) and ``./filter-airports.py`` Python3 scripts, or simply run ``make airports-prepare`` defining the bucket you need. Example:

```
$ make BUCKET=w090n40 airports-prepare
```

This will downgrade the file to apt.dat 1000 format, extract the airports inside the 10x10 deg w090n40 area, and place the result in ``02-data/airports/w090n40/apt.dat``


### MODIS-250 landcover raster preparation

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


### OSM data preparation

(TODO)

The Makefile expects to find OSM shapefiles for your bucket in the directory ../osm, e.g. ``../osm/shapefiles/w080n40/highways.shp``

If you have them somewhere else, you can override OSM_DIR on the command line, e.g.

```
$ make BUCKET=w090n40 OSM_DIR=/usr/share/osm osm-shapefiles-prepare
```


#### OSM landmass preparation

(TODO)

```
$ make MIN_LON=-90 MIN_LAT=40 MAX_LON=-80 MAX_LAT=50 BUCKET=w090n40 landmass
```


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

1. Generate and fit elevation data in 03-work/SRTM-3 (``make elevations`` and optionally, ``make cliffs``)
2. Generate airport objects and areas (``make airports``)
3. Generate the landmass layer (``make landmass``)
4. Generate the OSM and landcover layers (``make layers``)
5. Build the actual scenery (``make scenery``)

All of the steps but ``make scenery`` will skip anything that's already built under the ``03-work/`` directory. To force something to rebuild, use the *-rebuild variants of the targets above, including ``make all-rebuild``.

All of the steps will leave scenery alone that's already built for different areas.


### Splitting the work with do-make.sh

The TerraGear scenery tools often fail over large areas. The do-make.sh script allows you to split the work into several smaller jobs:

```
$ bash sh do-make.sh <min-lon> <min-lat> <max-lon> <max-lat> <target>
```

_target_ is the Makefile target to run repeatedly over each area.

If you want to go by bigger that 1x1 degree squares, set the environment variable _STEP_. For example,

```
$ STEP=2 bash do-make.sh -80 40 -70 50 scenery
```

will go through in 2x2 degree increments instead of 1x1 degree.

If you want to restart at a specific latlon within the area (e.g. after a crash), set the environment variables _START\_LAT_ and/or _START\_LON_. For example,

```
$ START_LON=72 START_LAT=41 bash do-make.sh -80 40 -70 50 scenery
```

If you want to change the number of concurrent threads from the default in the Makefile, set the environment variable _THREADS_. For example,

```
$ THREADS=16 bash do-make.sh -80 40 -70 50 scenery
```

Use the _do-make.sh_ script only for later steps in scenery building; earlier steps (like elevations and airports) need to work on the entire bucket.

*Note:* _\*-clean_ targets like _layers_clean_ or _scenery\_clean_ will clean the whole bucket for _every_ iteration, so don't combine them with a build target like _layers_ or _scenery_.

*Note:* after a crash, changing the number of threads will often fix the problem.


### Making elevations

Once you've prepared the elevation data, run _make_ with the ``elevations`` target, and _BUCKET_ set to the bucket you're building, e.g.

```
$ make BUCKET=w090n40 elevations
```

This will run _gdalchop_ to prepare the elevation data. Expect it to run for a few minutes.

Once you're done building elevations, run _make_ with the ``fit-elevations`` target. That will refit elevations for *all* buckets, and again, runs for a while:

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
$ STEP=10 make MIN_LON=-90 MIN_LAT=40 MAX_LON=-80 MAX_LAT=50 airports
```

Note the STEP. Using the default STEP of 1 seems to result in a lot of errors.

This will run the _genapts850_ command to build the airport areas and objects within those bounds, overriding the default airports with any custom ones you supplied during the preparation process.

If you want to remove all the airports for a bucket, use the _airports-clean_ target (and supply the _BUCKET_). If you want to rebuild, use the _airports-rebuild_ target (and supply both lat/lon bounds and the bucket).

## Scenery build

Once everything is actually ready, to build the scenery for an area use

```
$ bash do-make.sh <MIN-LON> <MIN-LAT> <MAX-LON> <MAX-LAT> scenery
```

The output will appear in ``04-output/fgfs-canada-us-scenery/Terrain/``

You may choose to build in bigger than 1x1 degree areas at once. For example, to build the w090n40 scenery doing a 2x2 degree area at once, do

```
$ STEP=2 bash do-make.sh -90 40 -80 50 scenery
```
