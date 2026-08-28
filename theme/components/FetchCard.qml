import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property color primary: "#fbba73"
    property color m3onPrimary: "#492900"
    property color surfaceContainer: "#251e17"
    property color onSurface: "#eee0d5"
    property string sessionName: "Hyprland"
    property string userName: "user"

    property string uptimeStr: "--"
    property int batteryPct: -1
    property bool batteryCharging: false
    property bool hasBattery: false

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function readFile(path, cb) {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState === XMLHttpRequest.DONE && (x.status === 200 || x.status === 0))
                cb(x.responseText);
        };
        x.open("GET", "file://" + path);
        x.send();
    }

    function formatUptime(seconds) {
        seconds = Math.floor(seconds);
        var d = Math.floor(seconds / 86400);
        var h = Math.floor((seconds % 86400) / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var parts = [];
        if (d > 0)
            parts.push(d + "d");
        if (d > 0 || h > 0)
            parts.push(h + "h");
        parts.push(m + "m");
        return parts.join(" ");
    }

    function refresh() {
        readFile("/proc/uptime", function (text) {
            var secs = parseFloat(text.trim().split(" ")[0]);
            if (!isNaN(secs))
                root.uptimeStr = formatUptime(secs);
        });
        readFile("/sys/class/power_supply/BAT0/capacity", function (text) {
            var v = parseInt(text.trim(), 10);
            if (!isNaN(v)) {
                root.batteryPct = v;
                root.hasBattery = true;
            }
        });
        readFile("/sys/class/power_supply/BAT0/status", function (text) {
            root.batteryCharging = text.trim() === "Charging";
        });
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    MultiEffect {
        anchors.fill: card
        source: card
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        shadowBlur: 0.7
        shadowVerticalOffset: 10
        shadowHorizontalOffset: 0
        shadowOpacity: 0.5
        autoPaddingEnabled: true
        z: -1
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: root.surfaceContainer
        radius: 12
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
        implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 22
            spacing: 10

            RowLayout {
                spacing: 10

                Rectangle {
                    implicitWidth: promptText.implicitWidth + 16
                    implicitHeight: promptText.implicitHeight + 8
                    color: root.primary
                    radius: 8

                    Text {
                        id: promptText
                        anchors.centerIn: parent
                        text: ">"
                        color: root.m3onPrimary
                        font.family: "monospace"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "caelestiafetch.sh"
                    color: root.onSurface
                    font.family: "monospace"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }

            Repeater {
                model: {
                    var items = [];
                    items.push("WM  : " + root.sessionName);
                    items.push("USER: " + root.userName);
                    items.push("UP  : " + root.uptimeStr);
                    if (root.hasBattery)
                        items.push("BATT: " + (root.batteryCharging ? "(+) " : "") + root.batteryPct + "%");
                    return items;
                }
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    color: root.onSurface
                    font.family: "monospace"
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.topMargin: 4
                spacing: 10

                Repeater {
                    model: 6
                    delegate: Rectangle {
                        required property int index
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 6
                        color: Qt.hsva((root.primary.hsvHue + index / 6) % 1.0, 0.55, 0.85, 1.0)
                    }
                }
            }
        }
    }
}
