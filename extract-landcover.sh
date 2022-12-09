IN=./source/vector/w080n40_landcover.shp
OUT=./data/shapefiles

while read line; do
    if echo $line | grep ',yes,' > /dev/null; then
        type=`echo $line | sed -e 's/,yes,.*$//'`
        name=`echo $line | sed -e 's/^.*,yes,//'`
        echo $type $name ...
        ogr2ogr $OUT/lc-${name}.shp $IN -sql "select * from w080n40_landcover where value=$type"
    fi
done < landcover.csv


