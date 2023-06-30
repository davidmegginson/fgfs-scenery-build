#!/bin/sh
########################################################################
# Merge airports into a single file
########################################################################

set -e

BUCKET=${BUCKET:-w080n40}
echo $BUCKET 1>&2

SPLIT=data/airports/split
MODIFIED=data/airports/modified/$BUCKET

cat <<__EOF__
I
1000 Version - data cycle 2013.10, build 20131335, metadata AptXP1000, further modified by the FlightGear team (cf. <https://sourceforge.net/p/flightgear/fgmeta/ci/next/tree/changes-in-dat-files/apt.dat>).  Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
nnn

__EOF__

# Override with modified airports
cp -v $MODIFIED/*.apt.dat $SPLIT 1>&2

# Send the original airports next
cat $SPLIT/*.apt.dat | egrep -v '^99'

echo '99'
