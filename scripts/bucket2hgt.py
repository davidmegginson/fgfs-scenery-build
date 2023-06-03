""" Convert a 10x10 bucket to a list of hgt files """

import re, sys

if len(sys.argv) != 2:
    print("Usage: {} <bucket>".format(sys.argv[0]), file=sys.stderr)
    exit(2)

bucket = sys.argv[1].upper()

result = re.match(r'^([EW])(\d{2}0)([NS])(\d{1}0)$', bucket)

if not result:
    print("Bucket should look like \"w080n40\"", file=sys.stderr)
    exit(1)

vertical_hemisphere = result.group(3)
horizontal_hemisphere = result.group(1)
bucket_lat = int(result.group(4)) * (-1 if vertical_hemisphere == 's' else 1)
bucket_lon = int(result.group(2)) * (-1 if horizontal_hemisphere == 'w' else 1)

for lat in range(bucket_lat, bucket_lat + 10):
    for lon in range(bucket_lon, bucket_lon + 10):
        print("{}{:02d}{}{:03d}.hgt".format(vertical_hemisphere, lat, horizontal_hemisphere, lon))
