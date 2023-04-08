FlightGear scenery for the St. Lawrence Seaway
==============================================

The St. Lawrence Seaway extends about halfway into the North American continent, from the Gulf of St Lawrence off the North Atlantic to Duluth, Minnesota. This project will eventually include all of the Great Lakes, the St Lawrence River, and the Gulf of St Lawrence, together with large stretches of surrounding scenery. Using the oversimplified assumption that a square degree (lat/lon) in the middle latitudes represents 70x100 km, the scenery will contain approximately 4 million km2 of scenery when complete (allowing for some empty ocean).

The scenery is optimised for low-level visual navigation, and contains much more detail (roads, rivers, streams, coastlines, railroads, lakes, etc) than is available in the default FlightGear scenery for this region as of 2023-01-25, as well as more-varied (and up-to-date) landcover.

By default, you will not have scenery models and other buildings/roads/etc in this scenery, but see below for an easy hack to include them.

Original download directory: https://www.dropbox.com/sh/ozjlc32jsnw97bd/AABfQ4sMzFRjTn3AqT_-FfP5a?dl=0

Scripts to build scenery: https://github.com/davidmegginson/fgfs-scenery-build

## Coverage

The release currently contains the 10x10 deg w100n40, w090n40, w090n30, w080n40, w080n30, w070n40, and w060n40 buckets, which include the following notable locations (among others), together with the Great Lakes, the St Lawrence River, and much of the Eastern and Central U.S. Note that you an unpack all of the archives into the same top-level directory.

### w100n40

* Brandon, MB, CAN
* Des Moines, IA, USA
* Duluth, MN, USA
* Fargo, ND, USA
* Kenora, ON, CAN
* Minneapolis-Saint Paul, MN, USA
* Omaha, NE, USA
* Portage-la-Prairie, MB, CAN
* Sioux Falls, SD, USA
* Winnipeg, MB, CAN

### w100n30

* Abilene, TX, USA
* Austin, TX, USA
* Dallas, TX, USA
* Jackson, MS, USA
* Kansas City, MO, USA
* Little Rock, AK, USA
* Oklahoma City, OK, USA
* Shreveport, LA, USA
* St Louis, MO, USA
* Tulsa, OK, USA

### w090n40

* Bloomington, IL, USA
* Chicago, IL, USA
* Cleveland, OH, USA
* Detroit, MI, USA
* Green Bay, WI, USA
* Kitchener-Waterloo, ON, CAN
* London, ON, CAN
* Madison, WI, USA
* Milwaukee, WI, USA
* Oshkosh, WI, USA
* Pittsburgh, PA, USA
* Sault Ste Marie, ON, CAN
* Saginaw, MI, USA
* Sarnia, ON, CAN
* Sudbury, ON, CAN
* Timmins, ON, CAN
* Thunder Bay, ON, CAN
* Toledo, OH, USA
* Traverse City, MI, USA
* Windsor, ON, CAN

### w090n30

* Asheville, NC, USA
* Atlanta, GA, USA
* Birmingham, AL, USA
* Charleston, WV, USA
* Charlotte, NC, USA
* Cincinnati, OH, USA
* Jacksonville, FL, USA
* Louisville, KY, USA
* Memphis, TN, USA
* Mobile, AL, USA
* Nashville, TN, USA
* Pensacola, FL, USA
* Savannah, GA, USA
* Tallahassee, FL, USA

### w080n40

* Albany, NY, USA
* Boston, MA, USA
* Buffalo, NY, USA
* Burlington, VT, USA
* Hamilton, ON, CAN
* Hartford, CT, USA
* Montreal, QC, CAN
* Newark, NJ, USA
* New York, NY, USA
* Ottawa, ON, CAN
* Pittsburgh, PA, USA
* Portland, ME, USA
* Providence, RI, USA
* Quebec, QC, CAN
* Rochester, NY,USA
* Syracuse, NY, USA
* Trenton, NJ, USA
* Toronto, ON, CAN

### w080n30

* Baltimore, MD, USA
* Charleston, SC, USA
* Norfolk, VA, USA
* Philadelphia, PA, USA
* Raleigh, NC, USA
* Richmond, VA, USA
* Washington, DC, USA

### w070n40

* Baie-Comeau, QC, CAN
* Bangor, ME, USA
* Bar Harbor, ME, USA
* Charlottetown, PE, CAN
* Chatham, MA, USA
* Fredericton, NB, CAN
* Halifax, NS, CAN
* Houlton, ME, USA
* Millinocket, ME, USA
* Miramichi, NB, CAN
* Moncton, NB, CAN
* Port Hawkesbury, NS, CAN
* Presque Isle, ME, USA
* St John, NB, CAN
* Sydney, NS, CAN
* Yarmouth, NS, CAN

### w060n40

* Cornerbrook, NL, CAN
* Gander, NL, CAN
* St. John's, NL, CAN
* Saint-Pierre, FRA

## Scenery models and osm2city

I have not yet added scenery models and osm2city to this scenery. However, I have included a script that will allow you to cheat. If you want to include buildings (etc) added via TerraSync, _and_ you are using a Unix-like operating system (including Linux or MacOS), you can use the follow script to set up symbolic links to the data that TerraSync downloads:

  $ sh gen-symlinks.sh
  
To remove the links, run

  $ sh clean-symlinks.sh
  
Because the elevations are not exactly identical with the default scenery, there will be occasional issues: buildings may occasionally appear partly submerged, and road segments will occasionally disappear underground, but for the most part, it works well as a short-term hack. I will learn how to include those features properly in the future.

## Sources

The scenery uses the following open sources:

* Elevations from the SRTM-3 DEM (Digital Elevation Model)
* Coarse landcover from the joint Canada/US 250m MODIS-250 landcover raster
* Airport layouts from the X-Plane Scenery Gateway (mostly via FlightGear)
* Detailed landcover, inland water, roads, railways, and powerline areas from OpenStreetMap

For more details, see https://github.com/davidmegginson/fgfs-scenery-build , which contains the build scripts.


## Future plans

The scenery will eventually contain all of the 10x10 degree buckets surrounding the Great Lakes, the St Lawrence River, and the Gulf of St Lawrence: w100n40, 1090n40, w080n40, w070n40, w060n50, w070n50, and w080n50.

## UNLICENSE

The author, David Megginson, asserts no intellectual property rights over this scenery, so it is likely in the Public Domain. See UNLICENSE.md for details.

The airport source data itself is GPL, including the following statement:

> 1000 Version - data cycle 2013.10, build 20131335, metadata AptXP1000, further modified by the FlightGear team (cf. <https://sourceforge.net/p/flightgear/fgmeta/ci/next/tree/changes-in-dat-files/apt.dat>).  Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

It is not clear whether the GPL can legally extend to an artistic derivation of data, and the answer may vary by jurisdiction. Since FlightGear itself is GPL, this does not affect the scenery's use within the simulator.
