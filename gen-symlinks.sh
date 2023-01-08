#!/bin/sh
########################################################################
# Generate symlinks to include osm2city objects
#
# TerraSync must be active for this to work, syncing to
# $HOME/.fgfs/TerraSync/
#
# Written by David Megginson, 2023-01
########################################################################

echo Linking to TerraSync directories for osm2city...

for d in Buildings Details Models Objects Pylons Roads; do
    ln -svf $HOME/.fgfs/TerraSync/$d .
done

echo done

exit 0
