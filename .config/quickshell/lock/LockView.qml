// What a locked monitor shows: dimmed wallpaper, the time as keycaps, one keycap per typed character.
// Edit: clock and card sizes, the minimal style and the shake here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.now = new Date() }

    Rectangle { anchors.fill: parent; color: Theme.bgMain }

    readonly property string lockImage: {
        var p = Settings.lockWall !== "" ? Settings.lockWall : Wall.path
        if (p === "") return ""
        if (/\.(mp4|webm|mkv|mov|avi|gif)$/i.test(p)) return Config.home + "/.cache/apsis/wall-frame.jpg"
        return p
    }
    Image {
        anchors.fill: parent
        source: root.lockImage ? "file://" + root.lockImage : ""
        fillMode: Image.PreserveAspectCrop

        horizontalAlignment: Settings.lockCrop === "left" ? Image.AlignLeft : Settings.lockCrop === "right" ? Image.AlignRight : Image.AlignHCenter
        verticalAlignment: Settings.lockCrop === "top" ? Image.AlignTop : Settings.lockCrop === "bottom" ? Image.AlignBottom : Image.AlignVCenter
        asynchronous: true
        visible: status === Image.Ready
    }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.bgMain, 0.72) }

    readonly property bool minimal: Settings.lockStyle === "minimal"

    ColumnLayout {
        visible: root.minimal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 36
        spacing: 4
        Label { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(root.now, "HH:mm"); font.pixelSize: 132; font.weight: Font.Light }
        Label { Layout.alignment: Qt.AlignHCenter; sub: true; text: Qt.formatDate(root.now, "dddd, d MMMM"); font.pixelSize: 20 }
    }

    ColumnLayout {
        visible: !root.minimal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: card.top
        anchors.bottomMargin: 48
        spacing: 16

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Repeater {
                model: Qt.formatTime(root.now, "HH:mm").split("")
                Item {
                    id: cell
                    required property string modelData
                    readonly property bool colon: modelData === ":"
                    Layout.preferredWidth: colon ? 26 : 108
                    Layout.preferredHeight: 150
                    Column {
                        visible: cell.colon
                        anchors.centerIn: parent
                        spacing: 24
                        Repeater { model: 2; Block { width: 20; height: 24; radius: 7; small: true; fill: Theme.accent; ring: Theme.ringActive } }
                    }
                    Block {
                        visible: !cell.colon
                        anchors.fill: parent
                        radius: 24
                        fill: Theme.bgCard
                        Label { anchors.centerIn: parent; text: cell.modelData; font.pixelSize: 96; font.weight: Font.Black }
                    }
                }
            }
        }
        Block {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: dateText.implicitWidth + 40
            Layout.preferredHeight: 40
            small: true
            radius: 20
            fill: Theme.accent
            ring: Theme.ringActive
            Label { id: dateText; anchors.centerIn: parent; text: Qt.formatDate(root.now, "dddd  d MMMM"); color: Theme.onAccent; font.pixelSize: 15; font.weight: Font.DemiBold }
        }
    }

    Block {
        id: card
        width: 420
        height: 214
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 120
        fill: root.minimal ? Theme.alpha(Theme.bgCard, 0.55) : Theme.bgCard
        ring: LockState.message !== "" ? Theme.danger : Theme.ring

        property real shake: 0
        transform: Translate { x: card.shake }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "shake"; to: -14; duration: 45 }
            NumberAnimation { target: card; property: "shake"; to: 12; duration: 70 }
            NumberAnimation { target: card; property: "shake"; to: -8; duration: 60 }
            NumberAnimation { target: card; property: "shake"; to: 5; duration: 50 }
            NumberAnimation { target: card; property: "shake"; to: 0; duration: 45 }
        }
        Connections { target: LockState; function onShakeTickChanged() { shakeAnim.restart() } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Avatar { size: 48 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label { text: Settings.userName; font.pixelSize: 17; font.weight: Font.DemiBold }
                    Label { sub: true; text: LockState.checking ? "Checking..." : (LockState.message || "Type your password"); font.pixelSize: 12
                        color: LockState.message !== "" ? Theme.danger : Theme.textSecondary }
                }
            }

            Block {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                small: true
                fill: Theme.bgMain
                ring: input.activeFocus ? Theme.ringActive : Theme.ring

                Row {
                    id: dots
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    readonly property int shown: Math.min(LockState.buffer.length, 18)
                    Repeater {
                        model: dots.shown
                        Pop {
                            id: dot
                            width: 16
                            height: 19
                            shown: false
                            Component.onCompleted: shown = true
                            Block { anchors.fill: parent; small: true; radius: 5; fill: LockState.checking ? Theme.bgHover : Theme.accent; ring: Theme.ringActive }
                        }
                    }
                }
                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    visible: LockState.buffer.length === 0
                    sub: true
                    text: "Password"
                    font.pixelSize: 14
                }
                BlockButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 46
                    height: 40
                    small: true
                    icon: Icons.chevronRight
                    iconSize: 20
                    active: LockState.buffer.length > 0
                    enabled: !LockState.checking
                    onClicked: LockState.submit()
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    echoMode: TextInput.NoEcho
                    Keys.onPressed: function(ev) {
                        if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { LockState.submit(); ev.accepted = true }
                        else if (ev.key === Qt.Key_Backspace) { if (ev.modifiers & Qt.ControlModifier) LockState.clear(); else LockState.backspace(); ev.accepted = true }
                        else if (ev.key === Qt.Key_Escape) { LockState.clear(); ev.accepted = true }
                        else if (ev.text && ev.text.length > 0 && ev.text.charCodeAt(0) >= 32) { LockState.type(ev.text); ev.accepted = true }
                    }
                }
                MouseArea { anchors.fill: parent; anchors.rightMargin: 56; onClicked: input.forceActiveFocus() }
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                sub: true
                font.pixelSize: 10
                text: LockState.fingerMessage !== "" ? LockState.fingerMessage
                    : LockState.fingerActive ? "Touch the reader, or type your password"
                    : "Enter to unlock  /  Esc clears"
            }
        }
    }

    RowLayout {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 12
        component PowerKey: BlockButton { Layout.preferredWidth: 54; Layout.preferredHeight: 56; iconSize: 22; fillIdle: Theme.bgCard }
        PowerKey { icon: Icons.sleep; onClicked: Quickshell.execDetached(["systemctl", "suspend"]) }
        PowerKey { icon: Icons.restart; onClicked: Quickshell.execDetached(["systemctl", "reboot"]) }
        PowerKey { icon: Icons.power; fillHover: Theme.danger; onClicked: Quickshell.execDetached(["systemctl", "poweroff"]) }
    }

    Component.onCompleted: input.forceActiveFocus()
}
