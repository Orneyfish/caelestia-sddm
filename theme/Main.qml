/**
 * Pixie SDDM (caelestia-lock-screen-styled rebuild)
 * Base: Pixie SDDM by xCaptaiN09 (https://github.com/xCaptaiN09/pixie-sddm)
 * Structure/tokens/colors mirror caelestia-shell's modules/lock/* and
 * plugin/src/Caelestia/Config/tokens.hpp
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components"

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "black"

    // ---- Live Material You palette from the real matugen output ----
    MColours {
        id: colours
    }

    readonly property bool uiReady: colours.ready

    // ---- User & Session Logic (Root Level) ----
    property int userIndex: 0
    property int sessionIndex: 0
    property bool isLoggingIn: false
    property string loginError: ""

    Component.onCompleted: {
        if (typeof userModel !== "undefined" && userModel.lastIndex >= 0) userIndex = userModel.lastIndex;
        if (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) sessionIndex = sessionModel.lastIndex;
        passwordField.forceFocus();
    }

    function cleanName(name) {
        if (!name) return "";
        var s = name.toString();
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        if (s.indexOf("/") !== -1) s = s.substring(s.lastIndexOf("/") + 1);
        if (s.indexOf(".desktop") !== -1) s = s.substring(0, s.indexOf(".desktop"));
        s = s.replace(/[-_]/g, ' ');
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function currentSessionName() {
        if (typeof sessionModel !== "undefined" && sessionModel.count > 0) {
            var idx = container.sessionIndex;
            var modelIdx = sessionModel.index(idx, 0);
            var n = sessionModel.data(modelIdx, Qt.UserRole + 4);
            var f = sessionModel.data(modelIdx, Qt.UserRole + 2);
            var d = sessionModel.data(modelIdx, Qt.DisplayRole);
            var finalName = n ? n.toString() : (f ? f.toString() : (d ? d.toString() : ""));
            return finalName ? cleanName(finalName) : "Hyprland";
        }
        return "Hyprland";
    }

    function currentUserName() {
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex;
            var modelIdx = userModel.index(idx, 0);
            var display = userModel.data(modelIdx, Qt.DisplayRole);
            var edit = userModel.data(modelIdx, Qt.EditRole);
            var nr = userModel.data(modelIdx, Qt.UserRole + 1);
            return (edit ? edit.toString() : (nr ? nr.toString() : (display ? display.toString() : "")));
        }
        return sddm.lastUser ? sddm.lastUser : "user";
    }

    function doLogin() {
        if (container.isLoggingIn) return;

        var user = "";
        if (typeof userModel !== "undefined" && userModel.count > 0) {
            var idx = container.userIndex;
            if (idx < 0 || idx >= userModel.count) idx = 0;

            var edit = userModel.data(userModel.index(idx, 0), Qt.EditRole);
            var nameRole = userModel.data(userModel.index(idx, 0), Qt.UserRole + 1);
            var display = userModel.data(userModel.index(idx, 0), Qt.DisplayRole);

            user = edit ? edit.toString() : (nameRole ? nameRole.toString() : (display ? display.toString() : ""));
        }

        if (!user || user === "" || user === "User") {
            user = sddm.lastUser;
        }

        if (!user && typeof userModel !== "undefined" && userModel.count > 0) {
            var firstEdit = userModel.data(userModel.index(0, 0), Qt.EditRole);
            user = firstEdit ? firstEdit.toString() : "";
        }

        if (!user) return;

        container.isLoggingIn = true;
        container.loginError = "";
        var pass = passwordField.text;
        var sess = container.sessionIndex;

        if (typeof sessionModel !== "undefined") {
            if (sess < 0 || sess >= sessionModel.count) sess = 0;
        } else {
            sess = 0;
        }

        sddm.login(user.trim(), pass, sess);
        loginTimeout.start();
    }

    Timer {
        id: loginTimeout
        interval: 5000
        onTriggered: container.isLoggingIn = false
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            container.isLoggingIn = false;
            loginTimeout.stop();
            container.loginError = "Incorrect password";
            shakeAnimation.start();
            passwordField.text = "";
            passwordField.forceFocus();
        }
        function onLoginSucceeded() {
            loginTimeout.stop();
        }
    }

    // ---- Fonts ----
    FontLoader { id: googleSansFlex; source: "assets/fonts/GoogleSansFlex.ttf" }
    readonly property string fontFamily: googleSansFlex.name
    readonly property string monoFontFamily: "CaskaydiaCove NF"

    Shortcut {
        sequence: "Escape"
        onActivated: passwordField.text = ""
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        onActivated: container.doLogin()
    }

    // ---- Full-bleed blurred wallpaper (matches LockSurface.qml's `background` item) ----
    Image {
        id: backgroundImage
        source: config.background
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
    }

    MultiEffect {
        anchors.fill: parent
        source: backgroundImage
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        autoPaddingEnabled: false
    }

    PowerBar {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 30
            rightMargin: 40
        }
        textColor: colours.m3onSurface
        z: 100
        opacity: container.uiReady ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ---- Centered floating surface card (matches LockSurface.qml's `lockContent`) ----
    readonly property real surfaceHeight: container.height * 0.7
    readonly property real surfaceWidth: surfaceHeight * (16 / 9)
    readonly property real centerScale: Math.min(1, container.height / 1440)

    MultiEffect {
        anchors.fill: surface
        source: surface
        shadowEnabled: true
        shadowColor: Qt.alpha(colours.shadow, 0.7)
        shadowBlur: 0.6
        shadowVerticalOffset: 4
        shadowOpacity: 0.7
        autoPaddingEnabled: true
        z: -1
        opacity: container.uiReady ? 1 : 0
    }

    Rectangle {
        id: surface
        anchors.centerIn: parent
        width: container.surfaceWidth
        height: container.surfaceHeight
        radius: 42
        color: colours.surface
        opacity: container.uiReady ? 1 : 0
        scale: container.uiReady ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 400 } }
        Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuad } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 32
            spacing: 40

            // ---- Left column: Weather, Fetch, Media ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                WeatherCard {
                    Layout.fillWidth: true
                    primary: colours.primary
                    surfaceContainer: colours.surfaceContainer
                    onSurface: colours.m3onSurface
                    onSurfaceVariant: colours.onSurfaceVariant
                    fontFamily: container.fontFamily
                }

                FetchCard {
                    Layout.fillWidth: true
                    primary: colours.primary
                    m3onPrimary: colours.m3onPrimary
                    surfaceContainer: colours.surfaceContainer
                    onSurface: colours.m3onSurface
                    sessionName: container.currentSessionName()
                    userName: container.currentUserName()
                }

                GoogleCalendarCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    primary: colours.primary
                    onPrimaryColor: colours.m3onPrimary
                    surfaceContainer: colours.surfaceContainer
                    surfaceContainerHigh: colours.surfaceContainerHigh
                    onSurface: colours.m3onSurface
                    onSurfaceVariant: colours.onSurfaceVariant
                    fontFamily: container.fontFamily
                    icalUrl: config.calendarIcalUrl || ""
                }
            }

            // ---- Center column: Clock, avatar, password ----
            ColumnLayout {
                Layout.preferredWidth: 600 * container.centerScale
                Layout.fillWidth: false
                Layout.fillHeight: true
                spacing: 20 * container.centerScale

                Item { Layout.preferredHeight: 4 }

                LockClock {
                    Layout.alignment: Qt.AlignHCenter
                    hourColor: colours.primary
                    minuteColor: colours.secondary
                    badgeColor: colours.surfaceContainerHigh
                    badgeTextColor: colours.m3onSurface
                    fontFamily: container.fontFamily
                    use24Hour: config.use24HourClock === "true"
                    pixelSize: 108 * container.centerScale
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(new Date(), "dddd").toUpperCase() + " • " + Qt.formatDateTime(new Date(), "d MMM").toUpperCase()
                    color: colours.m3onSurface
                    font.family: container.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold

                    Timer {
                        interval: 30000
                        running: true
                        repeat: true
                        onTriggered: parent.text = Qt.formatDateTime(new Date(), "dddd").toUpperCase() + " • " + Qt.formatDateTime(new Date(), "d MMM").toUpperCase()
                    }
                }

                Avatar {
                    id: avatar
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 48 * container.centerScale
                    Layout.bottomMargin: 28 * container.centerScale
                    size: Math.round(600 * container.centerScale * 0.7)
                    bgColor: colours.surfaceContainerHighest
                    iconColor: colours.onSurfaceVariant
                    avatarSource: Qt.resolvedUrl("assets/avatar.jpg")
                    fallbackAvatarSource: Qt.resolvedUrl("assets/default-avatar.jpg")

                    MouseArea {
                        anchors.fill: parent
                        enabled: typeof userModel !== "undefined" && userModel.count > 1
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: userPopup.open()
                    }
                }

                PasswordField {
                    id: passwordField
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 600 * container.centerScale * 0.8
                    isLoggingIn: container.isLoggingIn
                    surfaceColor: colours.surfaceContainerHigh
                    m3onSurfaceColor: colours.m3onSurface
                    onSurfaceVariantColor: colours.onSurfaceVariant
                    accentColor: colours.primary
                    m3onAccentColor: colours.m3onPrimary
                    fontFamily: container.fontFamily
                    onAccepted: container.doLogin()
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: container.loginError || ((typeof keyboard !== "undefined" && keyboard.numLock) ? "Num lock is on" : "")
                    color: container.loginError ? colours.error : colours.onSurfaceVariant
                    font.family: container.fontFamily
                    font.pixelSize: 13
                    opacity: text ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Text {
                    visible: typeof sessionModel !== "undefined" && sessionModel.count > 1
                    Layout.alignment: Qt.AlignHCenter
                    text: container.currentSessionName() + " ▾"
                    color: colours.onSurfaceVariant
                    font.family: container.fontFamily
                    font.pixelSize: 13

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sessionPopup.open()
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ---- Right column: Resources, NotifDock ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                StatsRow {
                    Layout.alignment: Qt.AlignRight
                    primary: colours.primary
                    primaryContainer: colours.primaryContainer
                    secondary: colours.secondary
                    secondaryContainer: colours.secondaryContainer
                    tertiary: colours.tertiary
                    m3onTertiary: colours.m3onTertiary
                    onSurface: colours.m3onSurface
                    error: colours.error
                    errorContainer: colours.errorContainer
                }

                GoogleNewsCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    primary: colours.primary
                    surfaceContainer: colours.surfaceContainer
                    surfaceContainerHigh: colours.surfaceContainerHigh
                    onSurface: colours.m3onSurface
                    onSurfaceVariant: colours.onSurfaceVariant
                    fontFamily: container.fontFamily
                    feedUrl: config.newsFeedUrl || "https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en"
                }
            }
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        loops: 2
        PropertyAnimation { target: surface; property: "x"; from: 0; to: -10; duration: 50; easing.type: Easing.InOutQuad }
        PropertyAnimation { target: surface; property: "x"; from: -10; to: 10; duration: 50; easing.type: Easing.InOutQuad }
        PropertyAnimation { target: surface; property: "x"; from: 10; to: 0; duration: 50; easing.type: Easing.InOutQuad }
    }

    Popup {
        id: userPopup
        width: 260
        height: (typeof userModel !== "undefined") ? Math.min(300, userModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 - 50
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: userList.forceActiveFocus()
        background: Rectangle {
            color: colours.surfaceContainerHigh
            radius: 24
            border.color: colours.outlineVariant
            border.width: 1
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
        ListView {
            id: userList
            anchors.fill: parent
            anchors.margins: 10
            model: (typeof userModel !== "undefined") ? userModel : null
            spacing: 5
            clip: true
            focus: true
            currentIndex: container.userIndex
            highlightFollowsCurrentItem: true
            delegate: ItemDelegate {
                width: parent.width
                height: 40
                property bool isCurrent: index === userList.currentIndex
                background: Rectangle {
                    color: isCurrent ? colours.surfaceContainerHighest : (hovered ? colours.surfaceContainer : "transparent")
                    radius: 12
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: colours.primary
                        radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: isCurrent ? colours.primary : colours.surfaceContainerHighest
                        radius: 14
                        Text {
                            anchors.centerIn: parent
                            text: {
                                var mIdx = userModel.index(index, 0);
                                var d = userModel.data(mIdx, Qt.DisplayRole);
                                var n_r = userModel.data(mIdx, Qt.UserRole + 1);
                                var finalVal = d ? d.toString() : (n_r ? n_r.toString() : "U");
                                return finalVal.charAt(0).toUpperCase();
                            }
                            color: isCurrent ? colours.m3onPrimary : colours.m3onSurface
                            font.pixelSize: 12
                            font.family: container.fontFamily
                            font.bold: true
                        }
                    }
                    Item { Layout.preferredWidth: 12 }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var mIdx = userModel.index(index, 0);
                            var d = userModel.data(mIdx, Qt.DisplayRole);
                            var n_r = userModel.data(mIdx, Qt.UserRole + 1);
                            var r = userModel.data(mIdx, Qt.UserRole + 2);
                            var e = userModel.data(mIdx, Qt.EditRole);
                            return cleanName(d ? d : (r ? r : (n_r ? n_r : e)));
                        }
                        color: isCurrent ? colours.m3onSurface : colours.onSurfaceVariant
                        font.family: container.fontFamily
                        font.pixelSize: 15
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60
                        elide: Text.ElideRight
                    }
                }
                onClicked: {
                    container.userIndex = index;
                    userPopup.close();
                }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.userIndex = currentIndex; userPopup.close(); }
            Keys.onEnterPressed: { container.userIndex = currentIndex; userPopup.close(); }
        }
    }

    Popup {
        id: sessionPopup
        width: 260
        height: (typeof sessionModel !== "undefined") ? Math.min(250, sessionModel.count * 50 + 20) : 100
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + 80
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onOpened: sessionList.forceActiveFocus()
        background: Rectangle {
            color: colours.surfaceContainerHigh
            radius: 24
            border.color: colours.outlineVariant
            border.width: 1
        }
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
        ListView {
            id: sessionList
            anchors.fill: parent
            anchors.margins: 10
            model: (typeof sessionModel !== "undefined") ? sessionModel : null
            spacing: 5
            clip: true
            focus: true
            currentIndex: container.sessionIndex
            highlightFollowsCurrentItem: true
            delegate: ItemDelegate {
                width: parent.width
                height: 40
                property bool isCurrent: index === sessionList.currentIndex
                background: Rectangle {
                    color: isCurrent ? colours.surfaceContainerHighest : (hovered ? colours.surfaceContainer : "transparent")
                    radius: 12
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        width: 4
                        height: isCurrent ? 16 : 0
                        color: colours.primary
                        radius: 2
                        Behavior on height { NumberAnimation { duration: 150 } }
                    }
                }
                contentItem: RowLayout {
                    anchors.fill: parent
                    spacing: 0
                    Item { Layout.preferredWidth: 20 }
                    Text {
                        Layout.preferredWidth: 40
                        text: "desktop_windows"
                        font.family: "Material Symbols Rounded"
                        color: isCurrent ? colours.primary : colours.onSurfaceVariant
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var n_val = sessionModel.data(sessionModel.index(index, 0), Qt.UserRole + 4);
                            var f_val = sessionModel.data(sessionModel.index(index, 0), Qt.UserRole + 2);
                            return cleanName(n_val ? n_val : f_val);
                        }
                        color: isCurrent ? colours.m3onSurface : colours.onSurfaceVariant
                        font.family: container.fontFamily
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        rightPadding: 60
                        elide: Text.ElideRight
                    }
                }
                onClicked: {
                    container.sessionIndex = index;
                    sessionPopup.close();
                }
            }
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: { container.sessionIndex = currentIndex; sessionPopup.close(); }
            Keys.onEnterPressed: { container.sessionIndex = currentIndex; sessionPopup.close(); }
        }
    }
}
