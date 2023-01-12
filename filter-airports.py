""" Filter airports in one or more apt.dat-format files for a specific bucket

Example:

    zcat apt.dat.gz | python3 filter-airports.py w080n40 > w080n40/apt.dat

Will include all airports with a runway end or node within the bucket.

"""

import re, sys


def filter_airports(bounds, input):
    """ Filter to dump only airports that appear in the specified boundaries.

    Bounds format: (min_lon, min_lat, max_lon, max_lat,)

    """

    current_airport = ""
    airport_matches = False

    def check_bounds(fields, lat_index, lon_index):
        """ Pull a lat/lon pair from an array and check if it's in bounds
        The indices into the array are provided.

        """
        nonlocal airport_matches
        lat = float(fields[lat_index])
        lon = float(fields[lon_index])
        if (bounds[0] <= lon <= bounds[2]) and (bounds[1] <= lat <= bounds[3]):
            airport_matches = True

    def dump_airport():
        """ Dump an airport to standard output if it matches, then reset. """
        nonlocal airport_matches, current_airport
        if airport_matches:
            print(current_airport)
        airport_matches = False
        current_airport = ""

    for line in input:
        
        if re.match(r'^(1|16|17)\s.*$', line):
            dump_airport()

        else:
            fields = re.split(r'\s+', line)
            if fields[0] == '100': # land runway
                check_bounds(fields, 9, 10)
                check_bounds(fields, 18, 19)
            elif fields[0] == '101': # water runway
                check_bounds(fields, 4, 5)
                check_bounds(fields, 7, 8)
            elif fields[0] == '102': # helipad
                check_bounds(fields, 2, 3)
            elif fields[0] in ('111', '112', '113', '114', '115', '116',): # node
                check_bounds(fields, 1, 2)

        current_airport += line


#
# Main entry point
#
if __name__ == "__main__":

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


    if len(sys.argv) == 1:
        print("Usage: {} <bucket> [file...]".format(sys.argv[0]), file=sys.stderr)
        sys.exit(2)
        
    bucket = sys.argv[1]
    bounds = parse_bucket(bucket)

    if len(sys.argv) == 2:
        with open(sys.stdin.fileno(), 'r', encoding='latin1') as input:
            filter_airports(bounds, input)
        
    else:
        for filename in sys.argv[2:]:
            with open(filename, 'r', encoding='latin1') as input:
                filter_airports(bounds, sys.stdin)


    print("99")
