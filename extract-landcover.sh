IN=../land-cover/w080n40.shp
OUT=./data/shapefiles

while read line; do
    if echo $line | grep ',yes,' > /dev/null; then
        type=`echo $line | sed -e 's/,yes,.*$//'`
        name=`echo $line | sed -e 's/^.*,yes,//'`
        echo $type $name ...
        ogr2ogr $OUT/lc-${name}.shp $IN -sql "select * from w080n40 where type=$type"
    fi
done < landcover.csv


