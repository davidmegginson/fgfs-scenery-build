/**
 * Set up the download map for FlightGear Canada/US scenery.
 *
 * Uses Leaflet.
 */


// Buckets to show on the map (lower left hand corner lat/lon and whether available)
// TODO: move to an external config file
const BUCKETS = [
    [60, -140, false],
    [50, -140, true],
    [60, -130, false],
    [50, -130, true],
    [40, -130, true],
    [30, -130, true],
    [60, -120, false],
    [50, -120, true],
    [40, -120, true],
    [30, -120, true],
    [60, -110, false],
    [50, -110, true],
    [40, -110, true],
    [30, -110, true],
    [20, -110, true],
    [60, -100, false],
    [50, -100, true],
    [40, -100, true],
    [30, -100, true],
    [20, -100, true],
    [60, -90, false],
    [50, -90, true],
    [40, -90, true],
    [30, -90, true],
    [20, -90, true],
    [60, -80, false],
    [50, -80, true],
    [40, -80, true],
    [30, -80, true],
    [60, -70, false],
    [50, -70, true],
    [40, -70, true],
    [50, -60, true],
    [40, -60, true],
];

/**
 * Function called after the window is rendered and the config file is loaded.
 */
function setup_map (config) {

    /**
     * Generate a bucket name from a lat/lon
     */
    function make_bucket_name(lat, lon) {
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

    
    /**
     * Start a download in the user's browser
     */
    function download(url, filename) {
        var a = document.createElement("a");
        a.setAttribute("href", url);
        a.setAttribute("download", filename);
        a.click();
    }

    
    // the Leaflet map object
    let map = L.map('map').setView([45, -100], 4);

    // add OpenStreetMap tiles
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 15,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    // feature group to hold the scenery-bucket rectangles
    let rectangle_layer = L.featureGroup();

    // set up the styles
    let available_style = { color: "green", weight: 1 };
    let unavailable_style = { color: "red", weight: 1 };

    // Create a rectangle for each bucket
    BUCKETS.forEach((bucket) => {
        let lat = bucket[0];
        let lon = bucket[1];
        let available = bucket[2];
        let bounds = [[lat, lon], [lat+10, lon+10]];
        let style = available ? available_style : unavailable_style;
        let rect = L.rectangle(bounds, style);
        let bucket_name = make_bucket_name(lat, lon);

        // add the bucket name to the rect
        rect.bucket_name = bucket_name;

        // show the bucket name on mouseover
        rect.bindTooltip(bucket_name);

        // Download when the user clicks on an area
        rect.on('click', (e) => {
            let entry = config[e.target.bucket_name];
            if (entry) {
                console.log(entry);
                download(entry.url, entry.name);
            } else {
                alert(bucket_name + " not yet available for download.")
            }
        })

        // add to the bucket group (for now, skip unavailable buckets)
        if (available) {
            rectangle_layer.addLayer(rect);
        }
    });

    // add the bucket group to the map
    map.addLayer(rectangle_layer);

    // set the map's zoom
    map.fitBounds(rectangle_layer.getBounds());
}

function list_links (config) {
    let parent_node = document.getElementById("links");

    for (const [bucket_name, props] of Object.entries(config)) {
        let label_node = document.createElement("dt");
        label_node.appendChild(document.createTextNode(bucket_name));
        parent_node.appendChild(label_node);

        let description_node = document.createElement("dd");
        let link_node = document.createElement("a");
        link_node.setAttribute("href", props.url);
        link_node.setAttribute("download", props.name);
        link_node.text = props.name;
        description_node.appendChild(link_node);
        description_node.appendChild(document.createTextNode(" (last modified " + props.date.substr(0, 4) + "-" + props.date.substr(4, 2) + "-" + props.date.substr(6, 2) + ")"));
        parent_node.appendChild(description_node);
    }
}


//
// Start here
//
window.onload = async function () {

    // download the config file
    response = await fetch('download-links.json');
    config = await response.json();

    // draw the map
    setup_map(config);

    // list the links
    list_links(config);
};
