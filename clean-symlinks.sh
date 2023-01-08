#!/bin/sh
########################################################################
# Clean symlinks to TerraSync osm2city objects
#
# Written by David Megginson, 2023-01
########################################################################

echo Removing symlinks ...
rm -fv Buildings Details Models Objects Pylons Roads
echo done

exit 0
