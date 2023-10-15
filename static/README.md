FlightGear scenery for Canada and the US (CONUS)
================================================

The scenery is optimised for low-level visual navigation, and contains much more detail (roads, rivers, streams, coastlines, railroads, lakes, etc) than is available in the default "TerraSync" FlightGear scenery as of early 2023, as well as more-varied (and up-to-date) landcover. The scenery will work with both the stable "release/2020.3" branch and the "next" branch of FlightGear.

By default, you will not have scenery models and other buildings/roads/etc in this scenery, but see below for an easy hack to include them.

Original download directory: https://www.dropbox.com/sh/ozjlc32jsnw97bd/AABfQ4sMzFRjTn3AqT_-FfP5a?dl=0

Scripts to build scenery: https://github.com/davidmegginson/fgfs-scenery-build

## Coverage

The release currently contains scenery buckets from 30N to 60N, 140W to 50W, covering all of CONUS, much of Canada, and bits of Alaska, Mexico, and France (St-Pierre and Miquelon).

Scenery download areas from west to east, south to north, with notable locations for each:

### w140n50

* Haida Gwaii, BC, CAN
* Juneau, AK, USA
* Prince Rupert, BC, CAN

### w130n30

San Francisco Bay area

* Sacramento, CA, USA
* San Francisco, CA, USA
* San Jose, CA, USA

### w130n40

US Pacific Northwest and southern British Columbia

* Portland, OR, USA
* Seattle, WA, USA
* Vancouver, BC, CAN
* Victoria, BC, CAN

### w130n50

Northern British Columbia

* Kamloops, BC, CAN
* Prince George, BC, CAN
* Terrance, BC, CAN

### w120n30

Grand Canyon, northern Baja California, and Southern California

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

Southern Great Plains and US Rockies

* Boise, ID, USA
* Coeur D'Alene, ID, USA
* Cranbrook, BC, CAN
* Helena, MT, USA
* Kelowna, BC, CAN
* Lethbridge, AB, CAN
* Salt Lake City, UT, USA
* Spokane, WA, USA

### w120n50

Alberta and the Canadian Rockies

* Banff, AB, CAN
* Calgary, AB, CAN
* Edmonton, AB, CAN
* Fort McMurray, AB, CAN
* Jasper, AB, CAN
* Vernon, BC, CAN

### w110n20

* Chihuahua, CHH, USA
* Del Rio, TX, USA
* Durango, DUR, MEX
* Guadalajara, JAL, MEX
* Mazatlán, SIN, MEX
* Monterrey, NLE, MEX
* Puerto Vallarta, JAL, MEX
* Saltillo, COA, MEX

### w110n30

Eastern US/Mexican border, southern US Rockies

* Albuquerque, NM, USA
* Ciudad Juárez, CHH, MEX
* Denver, CO, USA
* Dodge City, KS
* El Paso, TX, USA
* Santa Fe, NM, USA

### w110n40

Cattle country

* Billings, MT, USA
* Bismarck, ND, USA
* Cheyenne, WY, USA
* Esteven, SK, CAN
* Rapid City, SD, USA

### w110n50

Canadian prairies (Great Plains)

* Prince Albert, SK, CAN
* Regina, SK, CAN
* Saskatoon, SK, CAN

### w100n20

Western Gulf Coast

* Galveston, TX, USA
* Houston TX, USA
* Matamoros, TAM, MEX
* New Orleans, LA, USA
* Reynosa, TAM, MEX
* San Antonio, TX, USA

### w100n30

Northern and eastern Texas and surroundings

* Austin, TX, USA
* Baton Rouge, LA, USA
* Dallas, TX, USA
* Jackson, MS, USA
* Kansas City, MO, USA
* Little Rock, AK, USA
* Memphis, TN, USA
* Oklahoma City, OK, USA
* Shreveport, LA, USA
* St Louis, MO, USA
* Tulsa, OK, USA

### w100n40

US northern Great Plains, Lake Superior, and western Canadian Shield

* Des Moines, IA, USA
* Fargo, ND, USA
* Kenora, ON, CAN
* Minneapolis-Saint Paul, MN, USA
* Omaha, NE, USA
* Sioux Falls, SD, USA
* Winnipeg, MB, CAN

### w100n50

Northwestern Ontario and southern Manitoba (forest, Canadian Shield)

* Churchill, MB, CAN
* Gimli, MB, CAN
* Sioux Lookout, ON, CAN
* Thompson, MB, CAN
* Winnipeg, MB, CAN

### w090n00

Southern Central America

* San José, CRI
* Santiago, PAN

### w090n10

Western Central America and Cayman Islands

* Belize City, BLZ
* Belmopan, BLZ
* Chetumal, MEX
* George Town, CYM
* Liberia, CRI
* Puerto Barrios, GTM
* Managua, NIC
* San Andrés, COL
* San Salvador, SLV
* Tegucigalpa, HND

### w090n20

Eastern U.S. Gulf Coast, western Cuba

* Cancún, ROO, MEX
* Havana, CUB
* Key West, FL, USA
* Miami, FL, USA
* Mérida, YUC, MEX
* Orlando, FL, USA
* Tampa, FL, USA

### w090n30

U.S. South

* Atlanta, GA, USA
* Birmingham, AL, USA
* Charleston, WV, USA
* Charlotte, NC, USA
* Columbus, OH, USA
* Cincinnati, OH, USA
* Indianapolis, IN, USA
* Jacksonville, FL, USA
* Louisville, KY, USA
* Memphis, TN, USA
* Mobile, AL, USA
* Savannah, GA, USA

### w090n40

Central Great Lakes, US Rust Belt (home of Oshkosh!)

* Chicago, IL, USA
* Cleveland, OH, USA
* Detroit, MI, USA
* Green Bay, WI, USA
* London, ON, CAN
* Madison, WI, USA
* Marquette, MI, USA
* Milwaukee, WI, USA
* Oshkosh, WI, USA
* Pittsburgh, PA, USA
* Sudbury, ON, CAN
* Thunder Bay, ON, CAN
* Timmins, ON, CAN
* Windsor, ON, CAN

### w090n50

Western James Bay

* Armstrong, ON, CAN
* Attawapiskat, ON, CAN
* Fort Albany, ON, CAN
* Fort Severn, ON, CAN
* Moosonee, ON, CAN

### w080n00

Eastern Panama, Darién Gap, northwestern South America (north of the Equator)

* Barinas, VEN
* Bogotá, COL
* Colón, PAN
* Esmeraldas, ECU
* Medellín, COL
* Panama City, PAN

### w080n10

Central West Indies, western Spanish Main

* Barranquilla, COL
* Cartagena de Indias, COL
* Guantánamo Bay, CUB (U.S. naval base)
* Kingston, JAM
* La Vega, DOM
* Montego Bay, JAM
* Port-au-Prince, HTI
* Santa Marta, COL
* Santiago, DOM

### w080n20

Bahamas, Eastern Cuba, Turks and Caicos Islands

* Holguín, CUB
* Las Tunas, CUB
* Nassau, BHS
* Providenciales, TCA
* Santa Clara, CUB


### w080n30

US Mid Atlantic Seaboard (many U.S. Civil War battlefields)

* Baltimore, MD, USA
* Charleston, SC, USA
* Philadelphia, PA, USA
* Raleigh, NC, USA
* Richmond, VA, USA
* Washington, DC, USA (Capital of the US)
* Wilmington, DE, USA

### w080n40

US North Atlantic Seaboard, lower Great Lakes, St Lawrence River

* Boston, MA, USA
* Burlington, VT, USA
* Hartford, CT, USA
* Montreal, QC, CAN
* Newark, NJ, USA
* New York, NY, USA
* Ottawa, ON, CAN (Capital of Canada)
* Pittsburgh, PA, USA (shared with w090n40)
* Portland, ME, USA
* Providence, RI, USA
* Quebec, QC, CAN
* Toronto, ON, CAN

### w080n50

Eastern James Bay

* Inukjuak, QC, CAN
* La Grande Rivière, QC, CAN
* Umiujaq, NU, CAN

### w070n10

Eastern West Indies, eastern Spanish Main

* Basseterre, KNA
* Brades, MSR
* Caracas, VEN
* Castries, LCA
* Charlotte Amalie, VIR
* Fort-de-France, MTQ
* Gustavia, BLM
* Kingstown, VCT
* Marigot, MAF
* Oranjestad, ABW
* Philipsburg, SXM
* Pointe-à-Pitre, GLP
* Road Town, VGB
* Roseau, DMA
* San Fernando, TTO
* San Juan, PRI
* St. George's, GRD
* St. John's, ATG
* Santo Domingo, DOM
* The Valley, AIA

### w070n30

Bermuda

* St George's, BMU

### w070n40

Maine and Canadian Maritimes

* Bangor, ME, USA
* Charlottetown, PE, CAN
* Fredericton, NB, CAN
* Gaspé, QC, CAN
* Halifax, NS, CAN
* Moncton, NB, CAN
* Sydney, NS, CAN

### w070n50

Labrador and northeastern Quebec

* Churchill Falls, NL, CAN
* Goose Bay, NL, CAN
* Sept-Îles, QC, CAN

### w060n10

Barbados

* Bridgetown, BRB

### w060n40

Newfoundland and St Pierre-Miquelon (France)

* Gander, NL, CAN
* St. John's, NL, CAN
* Saint-Pierre, PM, FRA

### w060n50

Northern Newfoundland and eastern Labrador

* Cartwright, NL, CAN
* Fox Harbour, NL, CAN
* Lourdes-de-Blanc-Sablon, QC, CAN

## Scenery models and osm2city

I have not yet added scenery models and osm2city to this scenery. However, I have included a script that will allow you to cheat. If you want to include buildings (etc) added via TerraSync, _and_ you are using a Unix-like operating system (including Linux or MacOS), you can use the follow script to set up symbolic links to the data that TerraSync downloads:

  $ sh gen-symlinks.sh
  
To remove the links, run

  $ sh clean-symlinks.sh
  
Because the elevations are not exactly identical with the default scenery, there will be occasional issues: buildings may occasionally appear partly submerged, and road segments will occasionally disappear underground, but for the most part, it works well as a short-term hack. I will learn how to include those features properly in the future.

(There is also a file ``gen-symlinks.bat``, but I haven't tested it.)

## Sources

The scenery uses the following open sources:

* Elevations from the SRTM-3 DEM (Digital Elevation Model)
* Coarse landcover from the joint Canada/US 250m MODIS-250 landcover raster
* Airport layouts from the X-Plane Scenery Gateway
* Detailed landcover, inland water, roads, railways, and powerline areas from OpenStreetMap

For more details, see https://github.com/davidmegginson/fgfs-scenery-build , which contains the build scripts.


## UNLICENSE

The author, David Megginson, asserts no intellectual property rights over this scenery, so it is likely in the Public Domain. See UNLICENSE.md for details.

The airport source data itself is GPL, including the following statement in the original FlightGear copy:

> 1000 Version - data cycle 2013.10, build 20131335, metadata AptXP1000, further modified by the FlightGear team (cf. <https://sourceforge.net/p/flightgear/fgmeta/ci/next/tree/changes-in-dat-files/apt.dat>).  Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

It is not clear whether the GPL can legally extend to an artistic derivation of data, and the answer may vary by jurisdiction. Since FlightGear itself is GPL, this does not affect the scenery's use within the simulator.
