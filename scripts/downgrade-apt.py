""" Downgrade an apt.dat file to version 1000 """

import re, sys

VERSION = """1000 version (downgraded) - Copyright © 2013, Robin A. Peel (robin@x-plane.com).   This data is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.  You should have received a copy of the GNU General Public License along with this program ("AptNavGNULicence.txt"); if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA."""

END = """99"""


def start_apt(output):
    print(VERSION, file=output)

def end_apt(output):
    print(END, file=output)
    
## TODO - skip airports we've already seen (for custom); right now this happens in filter airports, so it's only at the bucket level
def process_apt_file(input, output):

    context = None

    for i, line in enumerate(input):
        tokens = re.split(r'\s+', line)
        if not tokens:
            continue # empty line

        type = tokens[0]

        # computer type
        if i == 0 and type in ('I', 'A',):
            pass

        # version and copyright
        elif i == 1 and type in ('1000', '1050', '1100',):
            continue

        # airports
        elif type in ('1', '16', '17',):
            context = None

        # runways
        elif type in ('100', '101', '102',):
            context = None

        # taxiways, ramps, and boundaries
        elif type in ('110', '120', '130'):
            context = 'feature'

        # taxiway, ramp, and boundary components
        elif type in ('111', '112', '113', '114', '115', '116',):
            if context != 'feature':
                context = None
                continue

        # miscellaneous locations
        elif type in ('14', '15', '18', '19', '20', '21',):
            context = None

        # traffic flow
        elif type in ('1000',):
            context = 'traffic'

        # traffic-flow components
        elif type in ('1001', '1002', '1003', '1004', '1100', '1101',):
            if context != 'traffic':
                context = None
                continue

        # taxi route
        elif type in ('1200',):
            context = 'taxi'

        # taxi-route components
        elif type in ('1201', '1202', '1204',):
            if context != 'taxi':
                context = None
                continue

        # airport location
        elif type in ('1300',):
            context = None

        # communication frequencies
        elif type in ('50', '51', '52', '53', '54', '55', '56'):
            context = None

        # end of file
        elif type in ('99',):
            continue

        # unsupported
        else:
            context = None
            continue

        print(line, end='', file=output)

if __name__ == '__main__':
    with open(sys.stdout.fileno(), 'w', encoding='latin1') as output:
        start_apt(output)
        for file in sys.argv[1:]:
            with open(file, 'r', encoding='latin1') as input:
                process_apt_file(input, output)
        end_apt(output)
        
