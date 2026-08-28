import QtQuick
import QtQuick.Effects
import M3Shapes

Item {
    id: root

    property int size: 300
    property color bgColor: "#3b332c"
    property color iconColor: "#d5c4b5"
    property string avatarSource: ""
    property string fallbackAvatarSource: ""

    implicitWidth: size
    implicitHeight: size

    MaterialShape {
        id: shape
        anchors.centerIn: parent
        implicitSize: root.size
        shape: MaterialShape.ClamShell
        color: root.bgColor
        layer.enabled: true
    }

    Text {
        anchors.centerIn: parent
        text: "person"
        font.family: "Material Symbols Rounded"
        font.pixelSize: root.size / 3
        color: root.iconColor
        visible: photo.status !== Image.Ready
    }

    Image {
        id: photo
        anchors.fill: shape
        source: root.avatarSource
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: false
        asynchronous: true
        onStatusChanged: {
            if (status === Image.Error && root.fallbackAvatarSource && source !== root.fallbackAvatarSource)
                source = root.fallbackAvatarSource;
        }
    }

    MultiEffect {
        anchors.fill: shape
        source: photo
        visible: photo.status === Image.Ready
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 0.1
    }
}
