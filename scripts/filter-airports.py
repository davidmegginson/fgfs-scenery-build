""" Filter airports in one or more apt.dat-format files for a specific bucket
n
Example:

    zcat apt.dat.gz | python3 filter-airports.py w080n40 > w080n40/apt.dat

Will include all airports with a runway end or node within the bucket.

Expects apt.dat version 1000. Use downgrade-apt.py to downgrade if needed.

"""

import re, sys


OPENING = """I"""

VERSION = """1200 version - Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA."""

END = """99"""

def filter_airports(bounds, input, output):
    """ Filter to dump only airports that appear in the specified boundaries.

    Bounds format: (min_lon, min_lat, max_lon, max_lat,)

    """

    airports_seen = set()

    current_airport = ""
    in_bounds = False

    
    def check_bounds(fields, lat_index, lon_index):
        """ Pull a lat/lon pair from an array and check if it's in bounds
        The indices into the array are provided.

        """
        nonlocal in_bounds
        if not in_bounds:
            lat = float(fields[lat_index])
            lon = float(fields[lon_index])
            if (bounds[0] <= lon <= bounds[2]) and (bounds[1] <= lat <= bounds[3]):
                in_bounds = True

    for i, line in enumerate(input):

        tokens = re.split(r'\s+', line)

        type = tokens[0]

        if i == 0 and type in ('I', 'A',):
            continue

        elif i <= 2 and type in ('1000', '1100', '1200',):
            continue

        # new airport
        elif type in ('1', '16', '17'):
            ident = tokens[4]
            if in_bounds and current_airport and ident not in airports_seen:
                print(current_airport, end='', file=output)
                airports_seen.add(ident)
            current_airport = ''
            in_bounds = False

        # runway
        elif type in ('100',):
            check_bounds(tokens, 9, 10)
            check_bounds(tokens, 18, 19)

        # water runway
        elif type in ('101',):
            check_bounds(tokens, 4, 5)
            check_bounds(tokens, 7, 8)

        # helipad
        elif type in ('102',):
            check_bounds(tokens, 2, 3)

        # feature node
        elif type in ('111', '112', '113', '114', '115', '116',):
            check_bounds(tokens, 1, 2)

        # positions of various types
        elif type in ('14', '15', '18', '19', '20', '21', '1201', '1300',):
            check_bounds(tokens, 1, 2)

        # see if there's a better identifier
        elif type in ('1302',):
            pass

        elif type in ('99'):
            continue

        current_airport += line

    # print final airport
    if current_airport:
        print(current_airport, end='', file=output)


def parse_bucket(bucket):
    """ Parse a bucket into a 4-element tuple
    (min_lon, min_lat, max_lon, max_lat,)

    """

    result = re.match(r'^([ew])(\d{3})([ns])(\d{2})$', bucket.lower())
    if not result:
        raise Exception("Badly formatted bucket \"{}\"".format(bucket))
    min_lon = int(result.group(2))
    if result.group(1) == 'w':
        min_lon *= -1
    min_lat = int(result.group(4))
    if result.group(3) == 's':
        min_lat *= -1

    return (min_lon, min_lat, min_lon+10, min_lat+10,)


########################################################################
# Main entry point
########################################################################

if __name__ == "__main__":

    if len(sys.argv) < 3:
        print("Usage: {} <bucket> <file> [file...] > dest.apt".format(sys.argv[0]), file=sys.stderr)
        sys.exit(2)

    bounds = parse_bucket(sys.argv[1])

    with open(sys.stdout.fileno(), 'w', encoding='latin1') as output:
        print(OPENING, file=output)
        print(VERSION, file=output)
        for file in sys.argv[2:]:
            with open(file, 'r', encoding='latin1') as input:
                filter_airports(bounds, input, output)
        print(END, file=output)

