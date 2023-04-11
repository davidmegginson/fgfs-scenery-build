var map = L.map('map').setView([45, -100], 4);
L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 15,
    attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
}).addTo(map);

var rectangle_layer = L.featureGroup();

var buckets = [
    [60, -140, false],
    [50, -140, false],
    [60, -130, false],
    [50, -130, false],
    [40, -130, false],
    [30, -130, false],
    [60, -120, false],
    [50, -120, true],
    [40, -120, true],
    [30, -120, true],
    [20, -120, false],
    [60, -110, false],
    [50, -110, true],
    [40, -110, true],
    [30, -110, true],
    [20, -110, false],
    [60, -100, false],
    [50, -100, true],
    [40, -100, true],
    [30, -100, true],
    [20, -100, false],
    [60, -90, false],
    [50, -90, true],
    [40, -90, true],
    [30, -90, true],
    [20, -90, false],
    [60, -80, false],
    [50, -80, true],
    [40, -80, true],
    [30, -80, true],
    [20, -80, false],
    [60, -70, false],
    [50, -70, true],
    [40, -70, true],
    [50, -60, true],
    [40, -60, true],
];

function make_bucket(lat, lon) {
    if (lon < 0) {
        lon = "w" + (lon * -1).toString().padStart(3, "0");
    } else {
        lon = "e" + lon.toString().padStart(3, "0");
    }
    if (lat < 0) {
        lat = "s" + (lat * -1).toString().padStart(2, "0");
    } else {
        lat = "n" + lat.toString().padStart(2, "0");
    }

    return lon + lat;
}

    
let available_style = { color: "green", weight: 1 };
let unavailable_style = { color: "red", weight: 1 };

buckets.forEach((bucket) => {
    let lat = bucket[0];
    let lon = bucket[1];
    let available = bucket[2];
    let bounds = [[lat, lon], [lat+10, lon+10]];
    let text = "w080n40";
    let style = available ? available_style : unavailable_style;
    let rect = L.rectangle(bounds, style);
    rect.bindTooltip(make_bucket(lat, lon));
    rectangle_layer.addLayer(rect);
});

map.addLayer(rectangle_layer);

map.fitBounds(rectangle_layer.getBounds());
