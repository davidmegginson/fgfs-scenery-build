#!/bin/sh
########################################################################
# Merge airports into a single file
########################################################################

ORIGINAL=data/airports/original
MODIFIED=data/airports/modified

ALLOWED_LINES="1|1[4-9]|2[0-1]|5[0-6]|10[0-2]|11[0-6]|120|130|100[0-4]|110[0-1]|120[0-4]|1300"

cat <<__EOF__
I
1000 Version - data cycle 2013.10, build 20131335, metadata AptXP1000, further modified by the FlightGear team (cf. <https://sourceforge.net/p/flightgear/fgmeta/ci/next/tree/changes-in-dat-files/apt.dat>).  Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.


__EOF__

# Remove duplicates
for f in $MODIFIED/*.apt.dat; do
    rm -fv data/airports/original/`basename $f` 1>&2
done

# Send the modified airports first
cat $MODIFIED/*.apt.dat | egrep "^($ALLOWED_LINES)[ 	]"

# Send the original airports next
cat $ORIGINAL/*.apt.dat | egrep "^($ALLOWED_LINES)[ 	]"

echo '99'
