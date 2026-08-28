import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root

    property color primary: "#fbba73"
    property color surfaceContainer: "#251e17"
    property color surfaceContainerHigh: "#302921"
    property color onSurface: "#eee0d5"
    property color onSurfaceVariant: "#d5c4b5"
    property string fontFamily: "sans-serif"
    property string feedUrl: "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"
    property int maxItems: 5

    property var headlines: []
    property bool loadFailed: false

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function decodeEntities(s) {
        return s.replace(/&amp;/g, "&").replace(/&#39;/g, "'").replace(/&quot;/g, "\"").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    }

    function splitSource(title) {
        var idx = title.lastIndexOf(" - ");
        if (idx === -1)
            return {
                title: title,
                source: ""
            };
        return {
            title: title.substring(0, idx),
            source: title.substring(idx + 3)
        };
    }

    function refresh() {
        var x = new XMLHttpRequest();
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            if (x.status !== 200) {
                root.loadFailed = true;
                return;
            }
            try {
                var stories = [];
                var itemRe = /<item>([\s\S]*?)<\/item>/g;
                var titleRe = /<title>([\s\S]*?)<\/title>/;
                var itemMatch;
                while ((itemMatch = itemRe.exec(x.responseText)) !== null && stories.length < root.maxItems) {
                    var titleMatch = titleRe.exec(itemMatch[1]);
                    if (!titleMatch)
                        continue;
                    var raw = titleMatch[1].replace("<![CDATA[", "").replace("]]>", "");
                    stories.push(root.splitSource(root.decodeEntities(raw)));
                }
                root.headlines = stories;
                root.loadFailed = stories.length === 0;
            } catch (e) {
                root.loadFailed = true;
            }
        };
        x.open("GET", root.feedUrl);
        x.send();
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 1800000
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
                    text: "news"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: root.primary
                }

                Text {
                    text: "Top Stories"
                    color: root.primary
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.loadFailed
                text: "News unavailable"
                color: root.onSurfaceVariant
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            Repeater {
                model: root.headlines
                delegate: Rectangle {
                    id: storyTile
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: Math.max(storyRow.implicitHeight, 44) + 24
                    color: root.surfaceContainerHigh
                    radius: 16

                    RowLayout {
                        id: storyRow
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignTop
                            radius: 12
                            color: root.surfaceContainer

                            Text {
                                anchors.centerIn: parent
                                text: "article"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 18
                                color: root.primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                visible: storyTile.modelData.source !== ""
                                text: storyTile.modelData.source
                                color: root.primary
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: storyTile.modelData.title
                                color: root.onSurface
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
