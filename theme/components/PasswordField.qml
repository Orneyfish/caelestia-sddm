import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import M3Shapes

Item {
    id: root

    property alias text: field.text
    property bool isLoggingIn: false
    property color surfaceColor: "#251e17"
    property color m3onSurfaceColor: "#eee0d5"
    property color onSurfaceVariantColor: "#d5c4b5"
    property color accentColor: "#fbba73"
    property color m3onAccentColor: "#492900"
    property string fontFamily: "sans-serif"
    property string placeholderText: ""

    signal accepted

    implicitWidth: 380
    implicitHeight: 56

    function forceFocus() {
        field.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.surfaceColor
        border.width: field.activeFocus ? 2 : 0
        border.color: root.accentColor

        Behavior on border.width {
            NumberAnimation {
                duration: 100
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Item {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "lock"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                color: root.onSurfaceVariantColor
            }
        }

        TextField {
            id: field
            Layout.fillWidth: true
            Layout.fillHeight: true
            echoMode: TextInput.Password
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 16
            font.family: root.fontFamily
            color: root.m3onSurfaceColor
            enabled: !root.isLoggingIn
            background: Item {}

            Text {
                text: root.placeholderText
                color: root.onSurfaceVariantColor
                opacity: 0.6
                font.pixelSize: 15
                font.family: root.fontFamily
                anchors.verticalCenter: parent.verticalCenter
                visible: !field.text && !field.activeFocus
            }

            onAccepted: root.accepted()
        }

        Item {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter

            MaterialShape {
                anchors.fill: parent
                shape: field.text ? MaterialShape.Arrow : MaterialShape.Circle
                color: field.text ? root.accentColor : root.surfaceColor
                rotation: 90

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "arrow_forward"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                color: field.text ? root.m3onAccentColor : root.onSurfaceVariantColor
            }

            MouseArea {
                anchors.fill: parent
                enabled: !!field.text
                cursorShape: field.text ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.accepted()
            }
        }
    }
}
