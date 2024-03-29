#!/usr/bin/python3
""" Generate a hierarchy of FlightGear Airport/* files from an apt.dat file

This script uses the general term "facility" to refer to an land or water aerodrome or a helipad.

The script parses facility data into a JSON-like object, then uses that to generate the output files.

Command-line example:

    cat apt.dat | python3 generate-airport-files.py scenery/Airports

The main programmatic entry point is generate_facility_files()

Started 2023-02-17 by David Megginson

"""

import json, math, os, re, sys

import xml.etree.cElementTree as X


RUNWAY_COORD_POS = {
    '100': (9, 10, 18, 19,),
    '101': (4, 5, 7, 8,),
    '102': (2, 3,),
}
    


def generate_facility_files(output_dir, input):
    """ Create FlightGear Airport/* files from an apt.dat file

    Parameters:

      output_dir: the root directory in which to create the files (including Airports/)

      input: a file object from which to read the apt.dat data

    """
    
    current_facility = None
    for line in input:
        tokens = re.split(r'\s+', line)
        type = tokens[0]
        
        if type in ('1', '16', '17',): # facilities
            if current_facility is not None:
                dump_facility(output_dir, current_facility)
            current_facility = parse_facility(tokens)
            
        elif type in ('100', '101', '102',): # landing/takeoff surfaces
            current_facility['runways'].append(parse_runway(tokens))

        elif type in ('1300',): # parking (no network)
            if current_facility:
                current_facility['parking'].append({
                    'type': tokens[4],
                    'lat': tokens[1],
                    'lon': tokens[2],
                    'hdg-deg': tokens[3],
                    'usage': tokens[5].split('|'),
                    'name': ' '.join(tokens[6:]).strip(),
                })
            
        elif type in ('1302'):
            if current_facility is not None and tokens[1]:
                value = ' '.join(tokens[2:]).strip()
                if value:
                    current_facility['metadata'][tokens[1]] = value

        elif type in ('50', '51', '52', '53', '54', '55', '56', '1050', '1051', '1052', '1053', '1054', '1055', '1056',):
            if len(type) == 2:
                type = '10' + type
            current_facility['frequencies'].append({
                'type': type,
                'frequency': tokens[1],
                'name': ' '.join(tokens[2:]).strip(),
            })

        elif type in ('14',):
            current_facility['viewpoints'].append({
                'lat': tokens[1],
                'lon': tokens[2],
                'elev-m': tokens[3],
                'name': ' '.join(tokens[4:]).strip(),
            })


def parse_facility(tokens):
    """ Start an facility object from a record """
    return {
        'type': tokens[0],
        'elev-m': int(tokens[1]),
        'ident': tokens[4],
        'name': ' '.join(tokens[5:]).strip(),
        'runways': [],
        'frequencies': [],
        'parking': [],
        'viewpoints': [],
        'metadata': {},
    }


def parse_runway(tokens):
    """ Create a runway record, including thresholds """
    type = tokens[0]
    pos = RUNWAY_COORD_POS[type]

    # Grab the coordinates for each end
    lat1 = tokens[pos[0]]
    lon1 = tokens[pos[1]]

    # If we have two ends
    if len(pos) > 2:
        lat2 = tokens[pos[2]]
        lon2 = tokens[pos[3]]

        # Calculate the headings (not in the apt.dat file)
        heading1 = round(calc_heading((float(lat1), float(lon1),), (float(lat2), float(lon2),)), 2)
        heading2 = round((heading1 + 180.0) % 360.0, 2) # reciprocal
    
    if type == '100': # land runway
        return {
            'type': type,
            'width': tokens[1],
            'surface': tokens[2],
            'thresholds': [
                {
                    'rwy': tokens[8],
                    'lat': lat1,
                    'lon': lon1,
                    'hdg-deg': heading1,
                    'displ-m': tokens[11],
                    'stopw-m': tokens[12],
                },
                {
                    'rwy': tokens[17],
                    'lat': lat2,
                    'lon': lon2,
                    'hdg-deg': heading2,
                    'displ-m': tokens[20],
                    'stopw-m': tokens[21],
                },
            ],
        }
    elif type == '101': # water runway
        return {
            'type': type,
            'width': tokens[1],
            'surface': tokens[2],
            'thresholds': [
                {
                    'rwy': tokens[3],
                    'lat': lat1,
                    'lon': lon1,
                    'hdg-deg': heading1,
                },
                {
                    'rwy': tokens[6],
                    'lat': lat2,
                    'lon': lon2,
                    'hdg-deg': heading2,
                },
            ],
        }
    elif type == '102': # helipad
        return {
            'type': type,
            'width': tokens[6],
            'length': tokens[5],
            'surface': tokens[7],
            'thresholds': [
                {
                    'rwy': tokens[1],
                    'lat': tokens[2],
                    'lon': tokens[3],
                    'hdg-deg': tokens[4],
                },
            ],
        }
    else:
        raise TypeError("Not a runway: {}".format(str(tokens)))


def dump_facility(output_dir, facility):
    """ Create files for a facility in the appropriate directory """

    dir = make_path(output_dir, facility['ident'])
    dump_thresholds(dir, facility)
    dump_tower(dir, facility)
    dump_groundnet(dir, facility)


def dump_thresholds(dir, facility):
    filename = os.path.join(dir, "{}.threshold.xml".format(facility['ident']))

    p = X.Element('PropertyList')
    for runway in facility['runways']:
        for threshold in runway['thresholds']:
            r = X.SubElement(p, 'runway')
            for prop in ('lon', 'lat', 'rwy', 'hdg-deg', 'displ-m', 'stopw-m',):
                if prop in threshold:
                    X.SubElement(r, prop).text = str(threshold[prop])

    save_xml(filename, p)


def dump_tower(dir, facility):
    
    if not facility['viewpoints']: # no tower
        return
    
    filename = os.path.join(dir, "{}.twr.xml".format(facility['ident']))

    twr = facility['viewpoints'][0] # assume first viewpoint is tower

    p = X.Element('PropertyList')
    x = X.SubElement(p, 'tower')
    y = X.SubElement(x, 'twr')
    for prop in ('lon', 'lat', 'elev-m',):
        X.SubElement(y, prop, twr[prop])

    save_xml(filename, p)


def dump_groundnet(dir, facility):
    filename = os.path.join(dir, "{}.groundnet.xml".format(facility['ident']))
    print(filename)


def make_path(output_dir, ident):
    """ Ensure that the output path for an airport exists, and return it """
    path = output_dir
    for i in range(0, 3):
        if i < len(ident) - 1:
            path = os.path.join(path, ident[i])
    if not os.path.exists(path):
        os.makedirs(path)
    return path


def save_xml(filename, root):
    tree = X.ElementTree(root)
    X.indent(tree, space='  ', level=0)
    tree.write(filename, encoding='utf-8', xml_declaration=True)


# Function by Jérôme Renard
# LICENSE: public domain
def calc_heading(pointA, pointB):
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


########################################################################
# Main entry point
########################################################################

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage {} <output-directory>".format(sys.argv[0]), file=sys.stderr)
    else:
        output_dir = sys.argv[1]

    with open(sys.stdin.fileno(), 'r', encoding='latin1') as input:
        generate_facility_files(output_dir, input)

    sys.exit(0)
