# Utility functions for use by other scripts

# Report an error and exit
fail () {
    echo $1 >&2
    exit $2
}

# Get the closest number divisible by 10 that's less than the arg
floor10 () {
    python3 -c "from math import floor; print(floor($1/10)*10)"
}

# Return the 10x10 deg bucket containing a lat/lon
latlon2bucket () {
    local lat=$(floor10 $1)
    local lon=$(floor10 $2)
    local bucket
    if [ $lon -lt 0 ]; then
        bucket=$(printf 'w%03d' $(expr 0 - $lon))
    else
        bucket=$(printf 'e%03d' $lon)
    fi
    if [ $lat -lt 0 ]; then
        bucket="$bucket$(printf 's%02d' $(expr 0 - $lat))"
    else
        bucket="$bucket$(printf 'n%02d' $lat)"
    fi
    echo $bucket
}

# Give the spatial bounds for a bucket
bucket2spat () {
    local bucket=$1
    local lon_dir=${bucket:0:1}
    local lat_dir=${bucket:4:1}
    local lon=${bucket:1:3}
    local lat=${bucket:5:2}
    if [ $lon_dir = 'w' ]; then
        lon=$(expr -1 '*' $lon)
    else
        lon=$(expr 1 '*' $lon)
    fi
    if [ $lat_dir = 's' ]; then
        lat=$(expr -1 '*' $lat)
    else
        lat=$(expr 1 '*' $lat)
    fi
    echo $lon $lat $(expr $lon + 10) $(expr $lat + 10)
}
