""" List DEM source files to use for a 10x10 bucket with gdalchop

Include a 1 deg overlap on each side

Usage:

  python list-dem.py DEM_SOURCE_PATH BUCKET

Where BUCKET is a 10x10 deg bucket name like w080n40.

"""

import pathlib, re, sys

def parse_bucket (bucket):
    """ Parse a bucket into its bounds, with a 1 deg overlap in each direction"""

    def norm_lon(lon):
        if lon < -180:
            lon = -180
        elif lon > 180:
            lon -= 180
        return lon

    def norm_lat(lat):
        if lat < -90:
            lat = -90
        elif lat > 90:
            lat = 90
        return lat
    
    result = re.match(r'^([ew])(\d{3})([ns])(\d{2})$', bucket)
    if not result:
        raise Exception("Badly-formatted bucket " + bucket)
    min_lon = norm_lon(int(result.group(2)) * (1 if result.group(1) == 'e' else -1))
    min_lat = norm_lat(int(result.group(4)) * (1 if result.group(3) == 'n' else -1))
    return (
        norm_lon(min_lon - 1),
        norm_lat(min_lat - 1),
        norm_lon(min_lon + 11),
        norm_lat(min_lat + 11),
    )


def get_bucket (lon, lat):
    """ Get the 10x10 bucket that contains lon and lat (e.g. w080n40) """
    lon -= lon % 10
    lat -= lat % 10
    return "{}{:03d}{}{:02d}".format(
        "w" if lon < 0.0 else "e",
        abs(lon),
        "s" if lat < 0.0 else "n",
        abs(lat)
    )


def check_in_bounds(lon, lat, bounds):
    """ Check that a point appears in bounds 
    Handles antimeridian (assumes smallest box)

    """
    (min_lon, min_lat, max_lon, max_lat,) = bounds

    if lat < min_lat or lat > max_lat or lon < min_lon or lon > max_lon:
        return False
    else:
        return True

def dem_file_in_bounds_p (filename, bounds):
    """ Check a DEM filename against the bounds
    The filename is in the format N00W000 (etc) with a .tif or .hgt extension
    
    """
    result = re.match(r'([NS])(\d{2})([EW])(\d{3}).*\.(TIF|HGT)$', filename.upper())
    if not result:
        raise Exception("Badly-formatted DEM name " + filename)
    lat = int(result.group(2)) * (1 if result.group(1) == 'N' else -1)
    lon = int(result.group(4)) * (1 if result.group(3) == 'E' else -1)
    return check_in_bounds(lon, lat, bounds)


def find_matching_dem_files (input_dir, bounds):
    """ Return a sorted list of DEM files for the 10x10 bucket 

    File names will be absolute.
    """
    files = []
    path = pathlib.Path(input_dir)
    for glob in ('*.tif', '*.hgt',):
        for entry in path.rglob(glob):
            if entry.is_file() and dem_file_in_bounds_p(entry.name, bounds):
                files.append(entry.absolute())
    return sorted(files)


#
# Run the script from the command line
#
if __name__ == "__main__":
    if len(sys.argv) != 3:
       print("Usage: {} INPUT_DIR BUCKET".format(sys.argv[0]), file=sys.stderr)
       sys.exit(2)

    INPUT_DIR=sys.argv[1]
    BUCKET=sys.argv[2]

    bounds = parse_bucket(BUCKET)
    files = find_matching_dem_files(INPUT_DIR, bounds)
    for file in files:
        print(file)

    exit(0)
