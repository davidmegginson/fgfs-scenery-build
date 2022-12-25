
if [ $# -ne 7 ]; then
    echo "Usage: $0 <bucket> <min-lon> <min-lat> <max-lon> <max-lat> <step> <target>" >&2
    exit 2
fi

BUCKET=$1
MIN_LON=$2
MIN_LAT=$3
MAX_LON=$4
MAX_LAT=$5
STEP=$6
TARGET=$7

lat=$MIN_LAT
while [ $lat -lt $MAX_LAT ]; do
    lon=$MIN_LON
    while [ $lon -lt $MAX_LON ]; do
        make BUCKET=$BUCKET MIN_LON=$lon MIN_LAT=$lat MAX_LON=$(expr $lon + $STEP) MAX_LAT=$(expr $lat + $STEP) $TARGET
        lon=$(expr $lon + $STEP)
    done
    lat=$(expr $lat + $STEP)
done

            
            
            
           
