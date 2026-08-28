import QtQuick
import QtQuick.Layouts
import M3Shapes

RowLayout {
    id: root

    property color primary: "#fbba73"
    property color primaryContainer: "#683d00"
    property color secondary: "#e0c1a3"
    property color secondaryContainer: "#58432c"
    property color tertiary: "#becc9c"
    property color m3onTertiary: "#293411"
    property color onSurface: "#eee0d5"
    property color error: "#ffb4ab"
    property color errorContainer: "#93000a"

    spacing: 14

    property real cpuPct: 0
    property real memPct: 0
    property int batteryPct: -1
    property bool batteryCharging: false
    property real cpuTemp: 0

    property var prevIdle: 0
    property var prevTotal: 0

    function readFile(path, cb) {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState === XMLHttpRequest.DONE && (x.status === 200 || x.status === 0))
                cb(x.responseText);
        };
        x.open("GET", "file://" + path);
        x.send();
    }

    function refreshCpu() {
        readFile("/proc/stat", function (text) {
            var line = text.split("\n")[0];
            var parts = line.trim().split(/\s+/).slice(1).map(Number);
            var idle = parts[3] + (parts[4] || 0);
            var total = parts.reduce(function (a, b) {
                return a + b;
            }, 0);

            if (root.prevTotal > 0) {
                var totalDelta = total - root.prevTotal;
                var idleDelta = idle - root.prevIdle;
                if (totalDelta > 0)
                    root.cpuPct = Math.max(0, Math.min(1, 1 - idleDelta / totalDelta));
            }
            root.prevIdle = idle;
            root.prevTotal = total;
        });
    }

    function refreshCpuTemp() {
        readFile("/sys/class/thermal/thermal_zone0/temp", function (text) {
            var v = parseInt(text.trim(), 10);
            if (!isNaN(v))
                root.cpuTemp = v / 1000;
        });
    }

    function refreshMem() {
        readFile("/proc/meminfo", function (text) {
            var lines = text.split("\n");
            var vals = {};
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^(\w+):\s+(\d+)/);
                if (m)
                    vals[m[1]] = parseInt(m[2], 10);
            }
            if (vals.MemTotal && vals.MemAvailable)
                root.memPct = Math.max(0, Math.min(1, 1 - vals.MemAvailable / vals.MemTotal));
        });
    }

    function refreshBattery() {
        readFile("/sys/class/power_supply/BAT0/capacity", function (text) {
            var v = parseInt(text.trim(), 10);
            if (!isNaN(v))
                root.batteryPct = v;
        });
        readFile("/sys/class/power_supply/BAT0/status", function (text) {
            root.batteryCharging = text.trim() === "Charging";
        });
    }

    Component.onCompleted: {
        refreshCpu();
        refreshCpuTemp();
        refreshMem();
        refreshBattery();
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refreshCpu()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            root.refreshCpuTemp();
            root.refreshMem();
            root.refreshBattery();
        }
    }

    StatTile {
        shapeType: MaterialShape.Pentagon
        icon: "memory"
        valueText: Math.round(root.cpuPct * 100) + "%"
        fillValue: root.cpuPct
        shapeColor: root.primaryContainer
        fillColor: Qt.alpha(root.secondary, 0.3)
        iconColor: root.primary
        valueColor: root.onSurface
        badgeText: root.cpuTemp > 0 ? Math.round(root.cpuTemp) + "°" : ""
        badgeColor: root.primary
        badgeTextColor: root.onSurface
    }

    StatTile {
        shapeType: MaterialShape.Slanted
        icon: "memory_alt"
        valueText: Math.round(root.memPct * 100) + "%"
        fillValue: root.memPct
        shapeColor: root.m3onTertiary
        fillColor: Qt.alpha(root.tertiary, 0.3)
        iconColor: root.tertiary
        valueColor: root.onSurface
    }

    StatTile {
        visible: root.batteryPct >= 0
        shapeType: MaterialShape.Gem
        icon: root.batteryCharging ? "battery_charging_full" : "battery_full"
        valueText: root.batteryPct + "%"
        fillValue: root.batteryPct / 100
        shapeColor: root.batteryPct <= 15 ? root.errorContainer : root.secondaryContainer
        fillColor: Qt.alpha(root.batteryPct <= 15 ? root.error : root.secondary, 0.35)
        iconColor: root.batteryPct <= 15 ? root.error : root.secondary
        valueColor: root.onSurface
    }
}
