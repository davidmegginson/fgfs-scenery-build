#!/bin/sh
########################################################################
# Unpack downloaded DEMs from zip files
#
# Downloaded zips should be in BASE_DIR/orig/
#
# Unpacked *.hgt files will be in BASE_DIR/unpacked/
########################################################################

if [ $# -ne 1 ]; then
    echo "Usage: bash $0 BASE-DIR" >&2
    exit 2
fi

BASE_DIR=$1

mkdir -p $BASE_DIR/unpacked/

cd $BASE_DIR/unpacked/

for file in $BASE_DIR/orig/*.zip; do
    unzip -o $file
done

for d in ???; do
    mv -v $d/* .
    rmdir $d
done

