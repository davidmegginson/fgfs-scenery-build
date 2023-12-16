import pathlib, re, sys

def parse_bucket (bucket):
    """ Parse a bucket into its corners """
    result = re.match(r'^([ew])(\d{3})([ns])(\d{2})$', bucket)
    if not result:
        raise Exception("Badly-formatted bucket " + bucket)
    min_lon = int(result.group(2)) * (1 if result.group(1) == 'e' else -1)
    min_lat = int(result.group(4)) * (1 if result.group(3) == 'n' else -1)
    return (min_lon - 1, min_lat - 1, min_lon + 11, min_lat + 11,)

def get_bucket (lon, lat):
    lon -= lon % 10
    lat -= lat % 10
    return "{}{:03d}{}{:02d}".format(
        "w" if lon < 0.0 else "e",
        abs(lon),
        "s" if lat < 0.0 else "n",
        abs(lat)
    )

def check_dem (filename, bounds):
    """ Get the bottom left corner of a dem """
    result = re.match(r'([NS])(\d{2})([EW])(\d{3}).*\.(tif|hgt)$', filename)
    if not result:
        raise Exception("Badly-formatted DEM name " + filename)
    lat = int(result.group(2)) * (1 if result.group(1) == 'N' else -1)
    lon = int(result.group(4)) * (1 if result.group(3) == 'E' else -1)
    return (lat >= bounds[1] and lat < bounds[3] and lon >= bounds[0] and lon < bounds[2])

def find_files (input_dir, bounds):
    files = []
    path = pathlib.Path(input_dir)
    for glob in ('*.tif', '*.hgt',):
        for entry in path.rglob(glob):
            if entry.is_file() and (entry.name.endswith('.hgt') or entry.name.endswith('.tif')) and check_dem(entry.name, bounds):
                files.append(entry.absolute())
    return sorted(files)

if len(sys.argv) != 3:
   print("Usage: {} INPUT_DIR BUCKET".format(sys.argv[0]), file=sys.stderr)
   sys.exit(2)

INPUT_DIR=sys.argv[1]
BUCKET=sys.argv[2]

files = find_files(INPUT_DIR, parse_bucket(BUCKET))
for file in files:
    print(file)
