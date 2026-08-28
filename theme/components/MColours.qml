import QtQuick

Item {
    id: root

    property bool ready: false

    property color primary: "#fbba73"
    property color m3onPrimary: "#492900"
    property color primaryContainer: "#683d00"
    property color m3onPrimaryContainer: "#ffdcbc"
    property color secondary: "#e0c1a3"
    property color m3onSecondary: "#402d17"
    property color secondaryContainer: "#58432c"
    property color tertiary: "#becc9c"
    property color m3onTertiary: "#293411"
    property color tertiaryContainer: "#3f4b26"
    property color surface: "#19120c"
    property color m3onSurface: "#eee0d5"
    property color onSurfaceVariant: "#d5c4b5"
    property color surfaceContainer: "#251e17"
    property color surfaceContainerHigh: "#302921"
    property color surfaceContainerHighest: "#3b332c"
    property color surfaceContainerLow: "#211a14"
    property color surfaceContainerLowest: "#130d07"
    property color surfaceBright: "#403830"
    property color surfaceDim: "#19120c"
    property color outline: "#9d8e81"
    property color outlineVariant: "#50453a"
    property color shadow: "#000000"
    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color errorContainer: "#93000a"

    function readFile(path, cb) {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState === XMLHttpRequest.DONE && (x.status === 200 || x.status === 0))
                cb(x.responseText);
        };
        x.open("GET", "file://" + path);
        x.send();
    }

    function load() {
        readFile("/usr/share/sddm/themes/pixie/assets/colors.json", function (text) {
            try {
                var j = JSON.parse(text);
                if (j.primary)
                    root.primary = j.primary;
                if (j.on_primary)
                    root.m3onPrimary = j.on_primary;
                if (j.primary_container)
                    root.primaryContainer = j.primary_container;
                if (j.on_primary_container)
                    root.m3onPrimaryContainer = j.on_primary_container;
                if (j.secondary)
                    root.secondary = j.secondary;
                if (j.on_secondary)
                    root.m3onSecondary = j.on_secondary;
                if (j.secondary_container)
                    root.secondaryContainer = j.secondary_container;
                if (j.tertiary)
                    root.tertiary = j.tertiary;
                if (j.on_tertiary)
                    root.m3onTertiary = j.on_tertiary;
                if (j.tertiary_container)
                    root.tertiaryContainer = j.tertiary_container;
                if (j.surface)
                    root.surface = j.surface;
                if (j.on_surface)
                    root.m3onSurface = j.on_surface;
                if (j.on_surface_variant)
                    root.onSurfaceVariant = j.on_surface_variant;
                if (j.surface_container)
                    root.surfaceContainer = j.surface_container;
                if (j.surface_container_high)
                    root.surfaceContainerHigh = j.surface_container_high;
                if (j.surface_container_highest)
                    root.surfaceContainerHighest = j.surface_container_highest;
                if (j.surface_container_low)
                    root.surfaceContainerLow = j.surface_container_low;
                if (j.surface_container_lowest)
                    root.surfaceContainerLowest = j.surface_container_lowest;
                if (j.surface_bright)
                    root.surfaceBright = j.surface_bright;
                if (j.surface_dim)
                    root.surfaceDim = j.surface_dim;
                if (j.outline)
                    root.outline = j.outline;
                if (j.outline_variant)
                    root.outlineVariant = j.outline_variant;
                if (j.shadow)
                    root.shadow = j.shadow;
                if (j.error)
                    root.error = j.error;
                if (j.on_error)
                    root.errorText = j.on_error;
                if (j.error_container)
                    root.errorContainer = j.error_container;
            } catch (e) {
            }
            root.ready = true;
        });
    }

    Component.onCompleted: load()
}
