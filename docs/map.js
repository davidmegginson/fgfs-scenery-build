/**
 * Set up the download map for FlightGear Canada/US scenery.
 *
 * Uses Leaflet.
 */


/**
 * Create interactive map.
 */
function setup_map (config) {

    /**
     * Parse a bucket name to get the lat/lon
     */
    function parse_bucket_name(name) {
        let lon = parseInt(name.substr(1, 3));
        let lat = parseInt(name.substr(5, 2));
        if (name.substr(0, 1).toLowerCase() == 'w') {
            lon *= -1;
        }
        if (name.substr(4, 1).toLowerCase() == 's') {
            lat *= -1;
        }
        return [lat, lon];
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
    for (const [bucket_name, props] of Object.entries(config)) {
        const [lat, lon] = parse_bucket_name(bucket_name);
        const bounds = [[lat, lon], [lat+10, lon+10]];
        const style = available_style;
        const rect = L.rectangle(bounds, style);

        // add the bucket name to the rect
        rect.bucket_name = bucket_name;

        // show the bucket name on mouseover
        rect.bindTooltip(bucket_name);

        // Download when the user clicks on an area
        rect.on('click', (e) => {
            console.log(props);
            download(props.url, props.name);
        })

        // add to the bucket group (for now, skip unavailable buckets)
        rectangle_layer.addLayer(rect);
    }

    // add the bucket group to the map
    map.addLayer(rectangle_layer);

    // set the map's zoom
    map.fitBounds(rectangle_layer.getBounds());
}


/**
 * Create list of direct download links.
 */
function list_links (config) {
    let parent_node = document.getElementById("links");

    for (const [bucket_name, props] of Object.entries(config)) {
        let label_node = document.createElement("dt");
        label_node.setAttribute("id", bucket_name);
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
