/**
 * Set up the download map for FlightGear Canada/US scenery.
 *
 * Uses Leaflet.
 */

const STALE_CUTOFF = '20240108'; // buckets before this are considered stale

/**
 * Set up the map and download links after the window is loaded
 */
window.onload = async function () {

    // display the cutoff date for the current build cycle
    show_cutoff(STALE_CUTOFF);

    // download the config file
    response = await fetch('download-links.json');
    config = await response.json();

    // draw the map
    setup_map(config);

    // list the links
    list_links(config);

    //
    // Variables
    //
    
    //
    // Top-level functions
    //

    /**
     * Display the cutoff date
     */
    function show_cutoff (date) {
        let node = document.getElementById("cutoff-date");
        node.appendChild(document.createTextNode(format_date(date)));
    }
    
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
        // Create a rectangle for each bucket
        for (const [bucket_name, props] of Object.entries(config)) {

            const STYLE_FRESH = { color: "green", weight: 1 }; // style for fresh buckets
            const STYLE_STALE = { color: "#aaaa00", weight: 1 }; // style for stale buckets

            const [lat, lon] = parse_bucket_name(bucket_name);
            const bounds = [[lat, lon], [lat+10, lon+10]];
            console.log('foo');
            let style = props.date >= STALE_CUTOFF ? STYLE_FRESH : STYLE_STALE;
            const rect = L.rectangle(bounds, style);

            // add the bucket name to the rect
            rect.bucket_name = bucket_name;

            // show the bucket name on mouseover
            rect.bindTooltip(bucket_name + " (" + format_size(props.size) + ", last updated " + format_date(props.date) + ")");

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
            description_node.appendChild(document.createTextNode(" (" + format_size(props.size) + ", last modified " + format_date(props.date) + ")"));
            parent_node.appendChild(description_node);
        }
    }

    //
    // Shared utility functions
    //

    function format_size(bytes){
        if (bytes >= 1073741824) {
            return (bytes / 1073741824).toFixed(2) + " GB";
        } else if (bytes >= 1048576) {
            return (bytes / 1048576).toFixed(2) + " MB";
        } else if (bytes >= 1024) {
            return (bytes / 1024).toFixed(2) + " KB";
        } else if (bytes > 1) {
            return bytes + " bytes";
        } else if (bytes == 1) {
            return bytes + " byte";
        } else {
            return "0 bytes";
        }
    }

    function format_date(d) {
        return d.substr(0, 4) + "-" + d.substr(4, 2) + "-" + d.substr(6, 2);
    }



};
