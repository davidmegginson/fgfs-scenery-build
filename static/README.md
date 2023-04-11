FlightGear scenery for the St. Lawrence Seaway
==============================================

The St. Lawrence Seaway extends about halfway into the North American continent, from the Gulf of St Lawrence off the North Atlantic to Duluth, Minnesota. This project will eventually include all of the Great Lakes, the St Lawrence River, and the Gulf of St Lawrence, together with large stretches of surrounding scenery. Using the oversimplified assumption that a square degree (lat/lon) in the middle latitudes represents 70x100 km, the scenery will contain approximately 4 million km2 of scenery when complete (allowing for some empty ocean).

The scenery is optimised for low-level visual navigation, and contains much more detail (roads, rivers, streams, coastlines, railroads, lakes, etc) than is available in the default FlightGear scenery for this region as of 2023-01-25, as well as more-varied (and up-to-date) landcover.

By default, you will not have scenery models and other buildings/roads/etc in this scenery, but see below for an easy hack to include them.

Original download directory: https://www.dropbox.com/sh/ozjlc32jsnw97bd/AABfQ4sMzFRjTn3AqT_-FfP5a?dl=0

Scripts to build scenery: https://github.com/davidmegginson/fgfs-scenery-build

## Coverage

The release currently contains the 10x10 deg w100n40, w090n40, w090n30, w080n40, w080n30, w070n40, and w060n40 buckets, which include the following notable locations (among others), together with the Great Lakes, the St Lawrence River, and much of the Eastern and Central U.S. Note that you an unpack all of the archives into the same top-level directory.

Scenery download areas from west to east, south to north:

### w120n30

(Includes the Grand Canyon)

* Carson, NV, USA
* Cedar City, UT, USA
* Fresno, CA, USA
* Las Vegas, NV, USA
* Los Angeles, CA, USA
* Mexicali, BCN, MEX
* Phoenix, AZ, USA
* Reno, NV, USA
* San Diego, CA, USA
* Tijuana, BCN, MEX
* Tucson, AZ, USA

### w120n40

* Baker City, OR, USA
* Boise, ID, USA
* Castlegar, BC, CAN
* Coeur D'Alene, ID, USA
* Cranbrook, BC, CAN
* Great Falls, MT, USA
* Helena, MT, USA
* Kelowna, BC, CAN
* Lethbridge, AB, CAN
* Salt Lake City, UT, USA
* Spokane, WA, USA
* Walla Walla, WA, USA

### w120n50

* Athabasca, AB, CAN
* Calgary, AB, CAN
* Cold Lake, AB, CAN
* Edmonton, AB, CAN
* Fort McMurray, BC, CAN
* Golden, BC, CAN
* Jasper, AB, CAN
* Lloydminster, BC, CAN
* Medicine Hat, AB, CAN
* Red Deer, AB, CAN
* Revelstoke, BC, CAN
* Slave Lake, AB, CAN
* Vernon, BC, CAN

### w110n30

* Albuquerque, NM, USA
* Boulder, CO, USA
* Ciudad Juárez, CHH, MEX
* Colorado Springs, CO, USA
* Denver, CO, USA
* El Paso, TX, USA
* Roswell, NM, USA
* Santa Fe, NM, USA
* Salida, CO, USA
* Sonora, TX, USA
* Telluride, CO, USA

### w110n40

* Billings, MT, USA
* Bismarck, ND, USA
* Cheyenne, WY, USA
* Esteven, SK, CAN
* Loveland, CO, USA
* Pierre, SD, USA
* Rapid City, SD, USA
* Vernal, UT, USA

### w110n50

* Flin Flon, MB, CAN
* Lynn Lake, MB, CAN
* Moose Jaw, SK, CAN
* Prince Albert, SK, CAN
* Regina, SK, CAN
* Saskatoon, SK, CAN
* Swift Current, SK, CAN
* The Pas, MB, CAN
* Yorkton, SK, CAN

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

### w100n50

* Churchill, MB, CAN
* Deer Lake, ON, CAN
* Gimli, MB, CAN
* Norway House, MB, CAN
* Pickle Lake, ON, CAN
* Red Lake, ON, CAN
* Sioux Lookout, ON, CAN
* Thompson, MB, CAN
* Winnipeg, MB, CAN

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

### w090n40

* Bloomington, IL, USA
* Chicago, IL, USA
* Cleveland, OH, USA
* Detroit, MI, USA
* Green Bay, WI, USA
* Kapuskasing, ON, CAN
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

### w090n50

* Armstrong, ON, CAN
* Attawapiskat, ON, CAN
* Big Trout Lake, ON, CAN
* Fort Albany, ON, CAN
* Fort Severn, ON, CAN
* Moosonee, ON, CAN

### w080n30

* Baltimore, MD, USA
* Charleston, SC, USA
* Norfolk, VA, USA
* Philadelphia, PA, USA
* Raleigh, NC, USA
* Richmond, VA, USA
* Washington, DC, USA

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

### w080n50

* Eastmain River, QC, CAN
* Inukjuak, QC, CAN
* Kuujjuarapik, QC, CAN
* La Grande Rivière, QC, CAN
* Nemiscau, QC, CAN
* Sanikiluaq, NU, CAN
* Umiujaq, NU, CAN

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

### w070n50

* Churchill Falls, NL, CAN
* Goose Bay, NL, CAN
* Havre-St-Pierre, QC, CAN
* Kangiqsualujjuaq, QC, CAN
* Schefferville, QC, CAN
* Sept-Îles, QC, CAN
* Wabush, NL, CAN

### w060n40

* Cornerbrook, NL, CAN
* Gander, NL, CAN
* Miquelon, PM, FRA
* St. John's, NL, CAN
* Saint-Pierre, PM, FRA
* Stephenville, NL, CAN

### w060n50

* Cartwright, NL, CAN
* Chevery, QC, CAN
* Fox Harbour, NL, CAN
* Lourdes-de-Blanc-Sablon, QC, CAN
* St. Anthony, NL, CAN
* St. Augustin, QC, CAN
* Williams Harbour, NL, CAN

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
