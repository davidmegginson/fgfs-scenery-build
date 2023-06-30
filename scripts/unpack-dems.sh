#!/bin/sh
########################################################################
# Unpack downloaded DEMs from zip files
#
# Downloaded zips should be in BASE_DIR/orig/
#
# Unpacked *.hgt files will be in BASE_DIR/unpacked/
########################################################################

set -e

if [ $# -ne 2 ]; then
    echo "Usage: bash $0 INPUT-DIR OUTPUT-DIR" >&2
    exit 2
fi

ROOT_DIR=SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

INPUT_DIR=$1
OUTPUT_DIR=$1

mkdir -p $OUTPUT_DIR && cd $OUTPUT_DIR

for file in $INPUT_DIR/*.zip; do
    unzip -o $file
done

for d in ???; do
    mv -v $d/* .
    rmdir $d
done

