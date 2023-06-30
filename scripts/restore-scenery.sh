#!/bin/sh
########################################################################
# Restore scenery from Dropbox download directory
########################################################################

set -e

cd 04-output

for file in $HOME/Dropbox/Downloads/fgfs-canada-us-scenery*.tar; do
    tar xvf $file
done
