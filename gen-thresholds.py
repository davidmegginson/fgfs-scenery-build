""" Generate FlightGear threshold files for airports in apt.dat format

Usage:
    python3 get-thresholds.py <output-dir> [files...]

If no files are provided, the script will read from standard input.

The script will create <output-dir> and its subdirectories as needed.

"""

import collections, io, math, os, re, sys, xml.etree.ElementTree


#
# Keys for reading variables from an apt.dat file
#

RUNWAY_KEYS = {
    # land runway
    '100': (
        'type', 'width', 'surface', 'shoulder', 'smoothness', 'centreline_lighting', 'edge_lighting', 'distance_signs',
        'le_ident', 'le_lat', 'le_lon', 'le_displaced', 'le_overrun', 'le_markings', 'le_approach_lighting', 'le_tdz_lighting', 'le_reil',
        'he_ident', 'he_lat', 'he_lon', 'he_displaced', 'he_overrun', 'he_markings', 'he_approach_lighting', 'he_tdz_lighting', 'he_reil',
    ),
    # water runway
    '101': (
        'type', 'width', 'buoys',
        'le_ident', 'le_lat', 'le_lon',
        'he_ident', 'he_lat', 'he_lon',
    ),
    # helipad
    '102': (
        'type', 'ident', 'lat', 'lon', 'bearing', 'len', 'width', 'surface', 'markings', 'shoulder', 'smoothness', 'edge_lighting',
    ),
}


#
# XML output templates
#

PROPERTIES_PRE_XML = "<?xml version='1.0' encoding='UTF-8'?>\n<PropertyList>"
PROPERTIES_POST_XML = "</PropertyList>"

RUNWAY_XML_TEMPLATES = {

    "100":  """  <runway>
    <threshold>
      <lon>{le_lon}</lon>
      <lat>{le_lat}</lat>
      <rwy>{le_ident}</rwy>
      <hdg-deg>{le_bearing}</hdg-deg>
      <displ-m>{le_displaced}</displ-m>
      <stopw-m>{le_overrun}</stopw-m>
    </threshold>
    <threshold>
      <lon>{he_lon}</lon>
      <lat>{he_lat}</lat>
      <rwy>{he_ident}</rwy>
      <hdg-deg>{he_bearing}</hdg-deg>
      <displ-m>{he_displaced}</displ-m>
      <stopw-m>{he_overrun}</stopw-m>
    </threshold>
  </runway>""",

    "101": """  <runway>
    <threshold>
      <lon>{le_lon}</lon>
      <lat>{le_lat}</lat>
      <rwy>{le_ident}</rwy>
      <hdg-deg>{le_bearing}</hdg-deg>
    </threshold>
    <threshold>
      <lon>{he_lon}</lon>
      <lat>{he_lat}</lat>
      <rwy>{he_ident}</rwy>
      <hdg-deg>{he_bearing}</hdg-deg>
    </threshold>
  </runway>""",

    "102":  """  <runway>
    <threshold>
      <lon>{lat}</lon>
      <lat>{lon}</lat>
      <rwy>{ident}</rwy>
      <hdg-deg>{bearing}</hdg-deg>
    </threshold>
  </runway>""",

}


#
# Functions
#

def gen_airports(output_dir, input):
    """ Read through a file containing one or more airport definitions """
    line = next(input)
    while(line):
        result = re.match(r'^(1|16|17)\s+(\d+)\s+\d+\s+\d+\s+([a-zA-Z0-9]+)\s+(.+)$', line)
        if result:
            airport = {
                'code': result.group(3),
                'name': result.group(4),
                'type': result.group(1),
                'elevation': result.group(2),
                'runways': [],
            }
            line = gen_airport(output_dir, input, airport)
        else:
            try:
                line = next(input) # gen_airport has read ahead a line
            except StopIteration:
                break

def gen_airport(output_dir, input, airport):
    """ Read a single airport's definition.
    Returns:
      The first line that's not part of the airport definition

    """
    for line in input:
        values = re.split(r'\s+', line)
        if values[0] in RUNWAY_KEYS:
            keys = RUNWAY_KEYS[values[0]]
            airport['runways'].append({keys[i] : values[i] for i in range(len(keys))})
        elif re.match(r'^(1|16|17)\s+', line):
            save_airport(output_dir, airport)
            return line

    if airport is not None:
        save_airport(output_dir, airport)


def save_airport(output_dir, airport):
    """ Save a single airport to a file in output_dir """

    code = airport['code']
    path = make_path(output_dir, code)

    print("Saving {}...".format(code), file=sys.stderr)

    # Make the thresholds file
    threshold_file = os.path.join(path, code + '.threshold.xml')
    with open(threshold_file, 'w') as output:
        print(PROPERTIES_PRE_XML, file=output)
        
        for runway in airport['runways']:

            # These are missing for land and water runways
            add_bearings(runway)
            
            # too lazy to use a library like ElementTree
            escape_values(runway)
            print(RUNWAY_XML_TEMPLATES[runway['type']].format(**runway), file=output)

        print(PROPERTIES_POST_XML, file=output)


def make_path(output_dir, code):
    """ Ensure that the output path for an airport exists, and return it """
    path = output_dir
    for i in range(0, 3):
        if i < len(code) - 1:
            path = os.path.join(path, code[i])
    if not os.path.exists(path):
        os.makedirs(path)
    return path


def escape_values(runway):
    """ XML-escape property values """
    for k in runway:
        if runway[k] is not None:
            runway[k] = str(runway[k]).replace('&', '&amp;')
            runway[k] = str(runway[k]).replace('<', '&lt;')
    return runway


def add_bearings(runway):
    """ Calculate and add bearings to a directional runway """
    if 'he_lat' in runway:
        runway['le_bearing'] = "{:0.8f}".format(calculate_initial_compass_bearing(
            (float(runway['le_lat']), float(runway['le_lon']),),
            (float(runway['he_lat']), float(runway['he_lon']),),
        ))
        runway['he_bearing'] = ":0.8f".format(calculate_initial_compass_bearing(
            (float(runway['he_lat']), float(runway['he_lon']),),
            (float(runway['le_lat']), float(runway['le_lon']),),
        ))


# Function by Jérôme Renard
# LICENSE: public domain
def calculate_initial_compass_bearing(pointA, pointB):
    """
    Calculates the bearing between two points.

    The formulae used is the following:
        θ = atan2(sin(Δlong).cos(lat2),
                  cos(lat1).sin(lat2) − sin(lat1).cos(lat2).cos(Δlong))

    :Parameters:
      - `pointA: The tuple representing the latitude/longitude for the
        first point. Latitude and longitude must be in decimal degrees
      - `pointB: The tuple representing the latitude/longitude for the
        second point. Latitude and longitude must be in decimal degrees

    :Returns:
      The bearing in degrees

    :Returns Type:
      float
    """
    if (type(pointA) != tuple) or (type(pointB) != tuple):
        raise TypeError("Only tuples are supported as arguments")

    lat1 = math.radians(pointA[0])
    lat2 = math.radians(pointB[0])

    diffLong = math.radians(pointB[1] - pointA[1])

    x = math.sin(diffLong) * math.cos(lat2)
    y = math.cos(lat1) * math.sin(lat2) - (math.sin(lat1)
            * math.cos(lat2) * math.cos(diffLong))

    initial_bearing = math.atan2(x, y)

    # Now we have the initial bearing but math.atan2 return values
    # from -180° to + 180° which is not what we want for a compass bearing
    # The solution is to normalize the initial bearing as shown below
    initial_bearing = math.degrees(initial_bearing)
    compass_bearing = (initial_bearing + 360) % 360

    return compass_bearing


#
# Main entry point for a script
#

if __name__ == "__main__":

    if len(sys.argv) < 2:
        print("Usage: {} <output-dir> [file...]".format(sys.argv[0]), file=sys.stderr)
        exit(2)

    output_dir = sys.argv[1]

    if len(sys.argv) == 2:
        with io.open(sys.stdin.fileno(), 'r', encoding='latin-1') as input:
            gen_airports(output_dir, input)

    else:
        for filename in sys.argv[2:]:
            with open(filename, 'r', encoding='latin-1') as input:
                gen_airports(output_dir, input)

# end
