import QtQuick

Item {
    id: root

    property color hourColor: "#fbba73"
    property color minuteColor: "#e0c1a3"
    property color badgeColor: "#3b332c"
    property color badgeTextColor: "#eee0d5"
    property string fontFamily: "sans-serif"
    property bool use24Hour: false
    property int pixelSize: 108
    property int spacing: 10

    implicitWidth: hourText.implicitWidth + spacing + minuteText.implicitWidth + (ampmLoader.active ? spacing + ampmLoader.width : 0)
    implicitHeight: hourText.implicitHeight

    property string hourStr: ""
    property string minuteStr: ""
    property string ampmStr: ""

    function update() {
        var now = new Date();
        var h = now.getHours();
        root.ampmStr = h >= 12 ? "PM" : "AM";
        if (!root.use24Hour) {
            h = h % 12;
            if (h === 0)
                h = 12;
        }
        var m = now.getMinutes();
        root.hourStr = (h < 10 ? "0" : "") + h;
        root.minuteStr = (m < 10 ? "0" : "") + m;
    }

    Component.onCompleted: update()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Text {
        id: hourText
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.hourStr
        color: root.hourColor
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
    }

    Text {
        id: minuteText
        anchors.left: hourText.right
        anchors.leftMargin: root.spacing
        anchors.baseline: hourText.baseline
        text: root.minuteStr
        color: root.minuteColor
        font.family: root.fontFamily
        font.pixelSize: root.use24Hour ? root.pixelSize : root.pixelSize * 0.56
        font.weight: Font.Medium
    }

    Loader {
        id: ampmLoader
        anchors.left: minuteText.right
        anchors.leftMargin: root.spacing
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.pixelSize * 0.06
        active: !root.use24Hour

        sourceComponent: Rectangle {
            radius: 10
            color: root.badgeColor
            implicitWidth: ampmText.implicitWidth + root.pixelSize * 0.13
            implicitHeight: ampmText.implicitHeight + root.pixelSize * 0.07

            Text {
                id: ampmText
                anchors.centerIn: parent
                text: root.ampmStr
                color: root.badgeTextColor
                font.family: root.fontFamily
                font.pixelSize: root.pixelSize * 0.17
                font.bold: true
            }
        }
    }
}
