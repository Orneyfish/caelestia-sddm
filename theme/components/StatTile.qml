import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import M3Shapes

Item {
    id: tile

    required property int shapeType
    required property string icon
    required property string valueText
    required property color shapeColor
    required property color fillColor
    required property color iconColor
    required property color valueColor
    property real fillValue: 0
    property int size: 96
    property string badgeText: ""
    property color badgeColor: "#000000"
    property color badgeTextColor: "#ffffff"

    implicitWidth: size
    implicitHeight: size

    MaterialShape {
        id: shape
        anchors.fill: parent
        shape: tile.shapeType
        color: tile.shapeColor
        layer.enabled: true
    }

    Rectangle {
        id: fillRect
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * Math.max(0, Math.min(1, tile.fillValue))
        color: tile.fillColor
        visible: false

        Behavior on height {
            NumberAnimation {
                duration: 400
                easing.type: Easing.OutQuad
            }
        }
    }

    MultiEffect {
        anchors.fill: shape
        source: fillRect
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.1
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            font.family: "Material Symbols Rounded"
            text: tile.icon
            color: tile.iconColor
            font.pixelSize: 22
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: tile.valueText
            color: tile.valueColor
            font.pixelSize: 17
            font.bold: true
        }
    }

    Rectangle {
        visible: tile.badgeText !== ""
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -2
        anchors.rightMargin: -2
        radius: 8
        color: tile.badgeColor
        implicitWidth: badgeLabel.implicitWidth + 10
        implicitHeight: badgeLabel.implicitHeight + 4

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: tile.badgeText
            color: tile.badgeTextColor
            font.pixelSize: 10
            font.bold: true
        }
    }
}
