import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property color primary: "#fbba73"
    property color onPrimaryColor: "#492900"
    property color surfaceContainer: "#251e17"
    property color surfaceContainerHigh: "#302921"
    property color onSurface: "#eee0d5"
    property color onSurfaceVariant: "#d5c4b5"
    property string fontFamily: "sans-serif"
    property string icalUrl: ""
    property int maxItems: 4

    property var events: []
    property bool loadFailed: false
    property var monthGrid: []

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function buildMonthGrid() {
        var now = new Date();
        var year = now.getFullYear();
        var month = now.getMonth();
        var startOffset = new Date(year, month, 1).getDay();
        var daysInMonth = new Date(year, month + 1, 0).getDate();
        var todayDate = now.getDate();
        var cells = [];
        for (var i = 0; i < startOffset; i++)
            cells.push({
                day: 0,
                isToday: false
            });
        for (var d = 1; d <= daysInMonth; d++)
            cells.push({
                day: d,
                isToday: d === todayDate
            });
        while (cells.length % 7 !== 0)
            cells.push({
                day: 0,
                isToday: false
            });
        root.monthGrid = cells;
    }

    function unfold(text) {
        return text.replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "");
    }

    function parseDate(raw) {
        var isDateOnly = raw.indexOf("VALUE=DATE") !== -1;
        var value = raw.substring(raw.indexOf(":") + 1).trim();
        if (isDateOnly) {
            var y = parseInt(value.substring(0, 4), 10);
            var mo = parseInt(value.substring(4, 6), 10) - 1;
            var d = parseInt(value.substring(6, 8), 10);
            return {
                date: new Date(y, mo, d),
                allDay: true
            };
        }
        var y2 = parseInt(value.substring(0, 4), 10);
        var mo2 = parseInt(value.substring(4, 6), 10) - 1;
        var d2 = parseInt(value.substring(6, 8), 10);
        var hh = parseInt(value.substring(9, 11), 10) || 0;
        var mm = parseInt(value.substring(11, 13), 10) || 0;
        var isUtc = value.charAt(value.length - 1) === "Z";
        var dt = isUtc ? new Date(Date.UTC(y2, mo2, d2, hh, mm)) : new Date(y2, mo2, d2, hh, mm);
        return {
            date: dt,
            allDay: false
        };
    }

    function refresh() {
        if (!root.icalUrl) {
            root.events = [];
            return;
        }
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            if (x.status !== 200) {
                root.loadFailed = true;
                return;
            }
            try {
                var text = root.unfold(x.responseText);
                var blocks = text.match(/BEGIN:VEVENT[\s\S]*?END:VEVENT/g) || [];
                var now = new Date();
                var parsed = [];
                for (var i = 0; i < blocks.length; i++) {
                    var b = blocks[i];
                    var summaryMatch = b.match(/SUMMARY:(.*)/);
                    var dtMatch = b.match(/DTSTART[^:\r\n]*:[^\r\n]*/);
                    if (!summaryMatch || !dtMatch)
                        continue;
                    var parsedDate = root.parseDate(dtMatch[0]);
                    if (parsedDate.date < now)
                        continue;
                    var isToday = parsedDate.date.getFullYear() === now.getFullYear() && parsedDate.date.getMonth() === now.getMonth() && parsedDate.date.getDate() === now.getDate();
                    parsed.push({
                        date: parsedDate.date,
                        dayNum: Qt.formatDateTime(parsedDate.date, "d"),
                        monthAbbr: Qt.formatDateTime(parsedDate.date, "MMM").toUpperCase(),
                        timeStr: parsedDate.allDay ? "All day" : (isToday ? "Today · " : "") + Qt.formatDateTime(parsedDate.date, "h:mm AP"),
                        summary: summaryMatch[1].trim()
                    });
                }
                parsed.sort(function (a, b) {
                    return a.date - b.date;
                });
                root.events = parsed.slice(0, root.maxItems);
                root.loadFailed = false;
            } catch (e) {
                root.loadFailed = true;
            }
        };
        x.open("GET", root.icalUrl);
        x.send();
    }

    Component.onCompleted: {
        refresh();
        buildMonthGrid();
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.buildMonthGrid()
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
        radius: 28
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        implicitWidth: layout.implicitWidth + layout.anchors.margins * 2
        implicitHeight: layout.implicitHeight + layout.anchors.margins * 2
        clip: true

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            RowLayout {
                spacing: 8

                Text {
                    text: "calendar_month"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: root.primary
                }

                Text {
                    text: "Calendar"
                    color: root.primary
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }

            Text {
                text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                color: root.onSurface
                font.family: root.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 3
                columnSpacing: 0

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    delegate: Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: root.onSurfaceVariant
                        font.family: root.fontFamily
                        font.pixelSize: 10
                    }
                }

                Repeater {
                    model: root.monthGrid
                    delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20

                        Rectangle {
                            visible: modelData.isToday
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            radius: 9
                            color: root.primary
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? modelData.day : ""
                            color: modelData.isToday ? root.onPrimaryColor : root.onSurfaceVariant
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Text {
                text: "Upcoming"
                color: root.primary
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.topMargin: 2
            }

            Text {
                Layout.fillWidth: true
                visible: !root.icalUrl
                text: "Calendar not configured"
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            Text {
                Layout.fillWidth: true
                visible: root.icalUrl && root.loadFailed
                text: "Calendar unavailable"
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            Text {
                Layout.fillWidth: true
                visible: root.icalUrl && !root.loadFailed && root.events.length === 0
                text: "No upcoming events"
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            Repeater {
                model: root.events
                delegate: Rectangle {
                    id: eventTile
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: eventRow.implicitHeight + 20
                    color: root.surfaceContainerHigh
                    radius: 16

                    RowLayout {
                        id: eventRow
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignVCenter
                            radius: 12
                            color: root.primary

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: -2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: eventTile.modelData.dayNum
                                    color: root.onPrimaryColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 17
                                    font.weight: Font.Bold
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: eventTile.modelData.monthAbbr
                                    color: root.onPrimaryColor
                                    font.family: root.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: eventTile.modelData.summary
                                color: root.onSurface
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                text: eventTile.modelData.timeStr
                                color: root.onSurfaceVariant
                                font.family: root.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
