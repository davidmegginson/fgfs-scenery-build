FlightGear Americas Scenery
===========================

## Goals

Build FlightGear scenery that

1. has full Americas coverage (including Greenland, Iceland, the
   Aleutians to 180W, Bermuda, Christmas Island, the
   Falklands/Malvinas, the South Georgia Islands, and the South
   Sandwich Islands)
2. is suitable for low-altitude VFR navigation, even without osm2city
   and 3D models enabled.
3. is compatible with stable versions of FlightGear, not just the
   _next_ branch.
4. includes detailed and accurate lakes, rivers, wetlands, and
   coastlines.

## Configuration

A Makefile drives the process. Most building happens using 10x10
buckets, and you must supply a _BUCKET_ variable to the make process,
e.g.

```
$ make BUCKET=w090n30 prepare
```

Dependency management is fairly complete — if something is missing,
the make process will probably try to build it before continuing.


## Data download and preparation

The scenery requires GIS data from several sources

* An elevation raster (DEM) to define the shape of the landscape. The
  build uses two different sources, in order of preference:
    * 1-arcsec (30m) FABDEM — Copernicus GLO DEM, with forests and
      buildings removed:
      https://data.bris.ac.uk/data/dataset/s5hqmjcdj8yo2ibzi9b4ew3sn
    * 3-arcsec (100m) SRTM-3 — Shuttle Radar Topography Mission:
      http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm
      (used automatically north of 80N)
* Global Land Cover by National Mapping Organizations (GLCNMO) at 15
  arcsec (nominally 250m) resolution, which provides background
  landcover to fill in any gaps in more-detailed OSM data (requires
  some manual preparation in qGIS; see below):
  https://globalmaps.github.io/glcnmo.html
* Airport data in the [apt.dat
  format](http://developer.x-plane.com/wp-content/uploads/2015/11/XP-APT1000-Spec.pdf)
  that FlightGear shares with the commercial X-Plane simulator. This
  data defines the shape of runways, taxiways, etc., as well as other
  information: https://gateway.x-plane.com/airports Use the
  Airports/apt.dat.ws3.gz file from the _next_ branch of the
  FlightGear base package
* OpenStreetMap (OSM) data in [PBF
  format](https://wiki.openstreetmap.org/wiki/PBF_Format) covering the
  area where you want to build scenery. This data defines detailed
  landcover (like parks and forests), lakes and rivers, as well as
  linear features like roads, railroads, and powerlines:
  https://download.geofabrik.de/north-america.html
    * (Special case) OSM landmass data defining the boundaries between
      land and ocean (no scenery outside these polygons will be
      built): https://osmdata.openstreetmap.de/data/land-polygons.html
    
### FABDEM elevation data preparation

FABDEM is the preferred elevation source. Download the 1-arcsecond
Copernicus GLO DEM, with forests and buildings removed (FABDEM) from
https://data.bris.ac.uk/data/dataset/s5hqmjcdj8yo2ibzi9b4ew3sn for all
of the areas that you want to build. Place the files in
01-data/FABDEM/Downloads/

If you are missing *.tif files for any of the areas you're building,
you will end up with flat scenery all at sea level.

Next, use the following commands to unpack the downloaded files and
sort them into bucket subdirectories:

```
$ cd 01-data/FABDEM/Unpacked
$ for file in ../Downloads/*.zip; do unzip $file; done
$ cd ..
$ sh sort-buckets.sh
```

### SRTM-3 elevation data preparation

Download the 3-arcsecond Shuttle Radar Topography Mission (SRTM-3)
elevation data for the areas you need from the [original USGS
source](https://e4ftl01.cr.usgs.gov//DP133/SRTM/SRTMGL1.003/2000.02.11/N05E014.SRTMGL1.hgt.zip)
(needs login) or the interactive map at [Viewfinder
Panoramas](http://www.viewfinderpanoramas.org/Coverage%20map%20viewfinderpanoramas_org3.htm). Place
them in 01-data/SRTM-3/Downloads/


If you are missing *.hgt files for any of the areas you're building,
you will end up with flat scenery all at sea level.

SRTM-3 is required north of 80N, which FABDEM doesn't cover, and for
some areas like Midtown Manhattan, where FABDEM doesn't fully succeed
in removing buildings.


```
$ cd 01-data/FABDEM/Unpacked
$ for file in ../Downloads/*.zip; do unzip $file; done
$ cd ..
$ sh sort-buckets.sh
```

### Airport data preparation

Obtain an apt.dat file, from the FlightGear distribution
(``$FG\_ROOT/Airports/apt.dat.ws3.gz``), X-Plane (``Custom
Scenery/Global Airports/Earth nav 02-data/apt.dat``) or by manually
downloading airport data from the [X-Plane Scenery Gateway API]() and
stiching the individual airport files together.

Uncompress the file (if needed) and rename to
``01-inputs/airports/apt.dat``

You may also place any custom airport .dat files in
01-inputs/airports/custom/ and they will be added to the build.


#### OSM landmass preparation

(TODO)


### Global landcover raster preparation

This section describes the default background, for when we don't have
any more-detailed scenery to place on top. It is lower priority than
airports or anything we take from OSM.

We will use the Global Landcover 15 arcsec (250m) North American
landcover raster from https://globalmaps.github.io/glcnmo.html and
save all files in the 01-inputs/global-landcover/ directory.

Preparation:

(Substitute "sw" for "nw" in the filenames below when working with the
southern half of the western hemisphere):

* ensure that the land-polygons-split package from the previous step
  is in ``01-inputs/land-polygons-split-4326/land_polygons.shp``
* open ``land\_polygons.shp`` in qGIS and use _Toolbox/GDAL/Vector
  geoprocessing/Clip vector by extent_ to make two landmass masks with
  the following extents:
  * ``landmass-nw-mask.shp`` -180, 0, 0, 90
  * ``landmass-sw-mask.shp`` -180, 0, -90, 0
* add an index to each of the masks using _Vector/Data
  Management Tools/Create Spatial Index_
* import the appropriate landcover raster into qGIS:
  * ``gm\_lc\_v3\_1\_1.tif`` - northern half of western hemisphere
  * ``gm\_lc\_v3\_2\_1.tif`` - southern half of western hemisphere
* run the _Toolbox/GRASS/Raster/r.null_ function to change value 20
  (water) to null, saving to ``landcover-nw-nulled.tif``
* convert the raster from floats to bytes and save to
  ``landcover-nw-nulled-bytes.tif``
* run the _Toolbox/GRASS/Raster/r.grow_ function with default
  parameters, saving to ``landcover-nw-filled.tif`` to fill into the
  empty water areas a bit and avoid Default slivers
* run the _Toolbox/GRASS/Raster/r.neighbors_ function with
  "Neighborhood operation" set to "Median" to simplify the raster
  slightly, and save to ``landcover-nw-neighbours.tif``
* run the _Toolbox/GRASS/Raster/r.to.vect_ to vectorise, selecting
  rounded corners and saving to ``landcover-nw-vect.shp``
* add an index to ``landcover-nw-vect.shp`` using _Vector/Data
  Management Tools/Create Spatial Index_
* run the _Toolbox/Vector geometry/Fix geometries_ function and save
  to ``landcover-nw-valid.shp``
- run the Vector/Geoprocessing Tools/Clip function to clip the
  landcover to the landmass, setting Invalid Feature Filtering to "Do
  not filter" with the wrench beside the input layer, saving to
  ``landcover-nw-clipped.shp`` modis-250-clipped.shp as the output
  file (this may take hours or days to run, and require over 10 GB of
  RAM)


### OSM data preparation

(TODO)

The Makefile expects to find OSM shapefiles for your bucket in the directory ../osm, e.g. ``../osm/shapefiles/w080n40/highways.shp``

If you have them somewhere else, you can override OSM_DIR on the command line, e.g.

```
$ make BUCKET=w090n40 OSM_DIR=/usr/share/osm osm-shapefiles-prepare
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
