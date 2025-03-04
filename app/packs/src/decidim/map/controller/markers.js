import "src/decidim/vendor/jquery-tmpl"
import MapController from "src/decidim/map/controller"
import "leaflet.markercluster";

export default class MapMarkersController extends MapController {
    start() {
        this.markerClusters = null;

        if (Array.isArray(this.config.markers) && this.config.markers.length > 0) {
            this.addMarkers(this.config.markers);
        } else {
            this.map.fitWorld();
        }
    }

    addMarkers(markersData) {
        if (this.markerClusters === null) {
            this.markerClusters = new L.MarkerClusterGroup({removeOutsideVisibleBounds: false});
            this.map.addLayer(this.markerClusters);
        }
        // Pre-compiles the template
        $.template(
            this.config.popupTemplateId,
            $(`#${this.config.popupTemplateId}`).html()
        );

        const bounds = new L.LatLngBounds(
            markersData.map(
                (markerData) => [markerData.latitude, markerData.longitude]
            )
        );

        markersData.forEach((markerData) => {
            let marker = new L.Marker([markerData.latitude, markerData.longitude], {
                icon: this.createIcon(),
                keyboard: true,
                title: markerData.title
            });

            let node = document.createElement("div");

            $.tmpl(this.config.popupTemplateId, markerData).appendTo(node);
            const options = {
                maxwidth: 640,
                minWidth: 500,
                keepInView: false,    // set it to true if you want to prevent users from panning the popup off of the screen while it is open.
                className: "map-info",
                autoPan: true,        // whether to pan the map when dragging this marker near its edge or not.
            }
            const portrait = window.matchMedia("(orientation: portrait)").matches;
            if (portrait === true){
                options["maxHeight"] = 130 // map is height 200
            }
            marker.bindPopup(node, options).openPopup();

            this.markerClusters.addLayer(marker);
        });

        // Make sure there is enough space in the map for the padding to be
        // applied. Otherwise the map will automatically zoom out (test it on
        // mobile). Make sure there is at least the same amount of width and
        // height available on both sides + the padding (i.e. 4x padding in
        // total).
        const size = this.map.getSize();
        if (size.y >= 400 && size.x >= 400) {
            this.map.fitBounds(bounds, { padding: [100, 100] });
        } else if (size.y >= 120 && size.x >= 120) {
            this.map.fitBounds(bounds, { padding: [30, 30] });
        } else {
            this.map.fitBounds(bounds);
        }
    }

    clearMarkers() {
        this.map.removeLayer(this.markerClusters);
        this.markerClusters = new L.MarkerClusterGroup({removeOutsideVisibleBounds: false});
        this.map.addLayer(this.markerClusters);
    }
}
