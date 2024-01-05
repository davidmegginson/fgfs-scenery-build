Improved FlightGear scenery for the Americas
============================================

The scenery is optimised for low-level visual navigation, and contains
much more detail (roads, rivers, streams, coastlines, railroads,
lakes, etc) than is available in the default "TerraSync" FlightGear
scenery as of early 2024, as well as more-varied (and up-to-date)
landcover. The scenery will work with both the stable "release/2020.3"
branch and the "next" branch of FlightGear (but note that a bug in
some releases of both might cause crashes in Bermuda and eastern
Brasil).

By default, you will not have scenery models and other
buildings/roads/etc in this scenery, but see below for an easy hack to
include them.

Original download directory:
https://www.dropbox.com/sh/ozjlc32jsnw97bd/AABfQ4sMzFRjTn3AqT_-FfP5a?dl=0

Scripts to build scenery:
https://github.com/davidmegginson/fgfs-scenery-build

## Coverage

The release contains scenery buckets for all of the Americas,
including North and Central America, South America, the Caribbean,
Greenland, Iceland, Hawaii, Bermuda, the Aleutians, the
Falklands/Malvinas, the Galapagos, the South Sandwich and South
Georgia Islands, Easter Island, and several smaller islands
geographically or politically-associated with the Americas.

## Installation

Unpack the scenery files somewhere on your hard drive, then add the
full path (including fgfs-americas-scenery/) to your FlightGear
scenery path.

### Scenery models and osm2city

I have not yet added scenery models and osm2city to this
scenery. However, I have included a script that will allow you to
cheat. If you want to include buildings (etc) added via TerraSync,
_and_ you are using a Unix-like operating system (including Linux or
MacOS), you can use the follow script to set up symbolic links to the
data that TerraSync downloads:

  $ sh gen-symlinks.sh
  
To remove the links, run

  $ sh clean-symlinks.sh
  
Because the elevations are not exactly identical with the default
scenery, there will be occasional issues: buildings may occasionally
appear partly submerged, and road segments will occasionally disappear
underground, but for the most part, it works well as a short-term
hack. I will learn how to include those features properly in the
future.

(There is also a contributed file ``gen-symlinks.bat`` for Windows,
but I haven't tested it.)

## Sources

The scenery uses the following open GIS data sources:

* Elevations from the 1-arcsec Copernicus Glo DEM with Fields and
  Buildings Removed (FABDEM) or the 3-arcsec SRTM-3 DEM (mainly north
  of 80N)
* Coarse background landcover from the 15-arcsec Global Land Cover by
  National Mapping Organizations (GLCNMO) raster
* Airport layouts from the X-Plane Scenery Gateway, via the FlightGear
  base package
* Landmass, detailed landcover, inland water, roads, railways, and
  powerline areas from OpenStreetMap

For more details, see https://github.com/davidmegginson/fgfs-scenery-build , which contains the build scripts.


## UNLICENSE

The author, David Megginson, asserts no intellectual property rights
over this scenery, so it is likely in the Public Domain. See
UNLICENSE.md for details.

The airport source data itself is GPL, including the following
statement in the original FlightGear copy:

> 1000 Version - data cycle 2013.10, build 20131335, metadata AptXP1000, further modified by the FlightGear team (cf. <https://sourceforge.net/p/flightgear/fgmeta/ci/next/tree/changes-in-dat-files/apt.dat>).  Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

It is not clear whether the GPL can legally extend to an artistic
derivation of data, and the answer may vary by jurisdiction. Since
FlightGear itself is GPL, this does not affect the scenery's use
within the simulator.
