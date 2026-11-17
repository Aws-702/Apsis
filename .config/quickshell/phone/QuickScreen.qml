// The quick panel: profile, tiles, sliders, now playing, power profile, keys to the other screens.
// Edit: tiles and their order here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    function shot() {
        PhoneState.close()
        Quickshell.execDetached(["sh", "-c", "sleep 0.45; grimblast --notify copysave area"])
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: status.bottom; bottom: parent.bottom; topMargin: 8 }
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        contentHeight: col.implicitHeight + 90
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 11

            Block {
                Layout.fillWidth: true
                Layout.preferredHeight: 78
                fill: Theme.bgItem
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10
                    Avatar { size: 46 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label { text: Settings.userName; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Label { sub: true; text: Qt.formatDate(new Date(), "dddd d MMMM"); Layout.fillWidth: true }
                    }
                    BlockButton {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 46
                        icon: Sys.dnd ? Icons.bellOff : Icons.bell
                        iconSize: 18
                        onClicked: PhoneState.go("notifications")

                        Block {
                            visible: Notifs.unread > 0
                            anchors { right: parent.right; top: parent.top; rightMargin: -5; topMargin: -5 }
                            width: Math.max(18, badge.implicitWidth + 8)
                            height: 18
                            radius: 9
                            small: true
                            flat: true
                            fill: Theme.accent
                            ring: Theme.ringActive
                            Label { id: badge; anchors.centerIn: parent; text: Notifs.unread > 99 ? "99+" : Notifs.unread; font.pixelSize: 9; font.weight: Font.Black; color: Theme.onAccent }
                        }
                    }
                    BlockButton { Layout.preferredWidth: 42; Layout.preferredHeight: 46; icon: Icons.gear; iconSize: 18; onClicked: PhoneState.openSettings("") }
                    BlockButton { Layout.preferredWidth: 42; Layout.preferredHeight: 46; icon: Icons.power; iconSize: 18; fillIdle: Theme.bgHover; onClicked: { PhoneState.close(); UiState.powerMenuOpen = true } }
                }
            }

            Block {
                Layout.fillWidth: true
                Layout.preferredHeight: gpuCol.implicitHeight + 26
                visible: Ultra.on
                fill: Theme.bgItem
                ColumnLayout {
                    id: gpuCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13 }
                    spacing: 10
                    Label { caps: true; text: Ultra.training ? "Training mode" : "Ultra saver" }
                    Loader {
                        Layout.fillWidth: true
                        active: Ultra.on
                        sourceComponent: GpuReadout { big: false; maxRows: 3 }
                    }
                    TrainKeys { Layout.fillWidth: true; onUsed: PhoneState.close() }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                component Tile: BlockButton {
                    id: tile
                    property string screen: ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    align: Qt.AlignLeft
                    iconSize: 18
                    fontSize: 12
                    onRightClicked: if (screen !== "") PhoneState.go(screen)
                    Item {
                        visible: tile.screen !== ""
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: 34
                        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 1.5; height: parent.height * 0.5; radius: 1; color: Theme.alpha(tile.ink, 0.25) }
                        VIcon { anchors.centerIn: parent; size: 16; d: Icons.chevronRight; color: tile.ink }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PhoneState.go(tile.screen) }
                    }
                }

                Tile { text: "Wi-Fi"; subText: Sys.wifiOn ? (Sys.wifiName || "On") : "Off"; icon: Sys.wifiOn ? Icons.wifi : Icons.wifiOff; active: Sys.wifiOn; screen: "wifi"; onClicked: Sys.toggleWifi() }
                Tile { text: "Bluetooth"; subText: Sys.btOn ? "On" : "Off"; icon: Sys.btOn ? Icons.bluetooth : Icons.bluetoothOff; active: Sys.btOn; screen: "bluetooth"; onClicked: Sys.toggleBt() }
                Tile { text: "Night light"; subText: Sys.nightLight ? "Warm" : "Off"; icon: Icons.sleep; active: Sys.nightLight; onClicked: Sys.script("apsis-nightlight.sh", "toggle") }
                Tile { text: "Game mode"; subText: Sys.game ? "On" : "Off"; icon: Icons.game; active: Sys.game; onClicked: Sys.script("apsis-game.sh", "toggle") }
                Tile { text: "Focus"; subText: Sys.focus ? "On" : "Off"; icon: Icons.focus; active: Sys.focus; onClicked: Sys.script("apsis-focus.sh", "toggle") }
                Tile { text: "Silence"; subText: Sys.dnd ? "On" : "Off"; icon: Icons.bellOff; active: Sys.dnd; onClicked: Sys.script("apsis-dnd.sh") }
                Tile { text: "Keep awake"; subText: Sys.caffeine ? "On" : "Off"; icon: Icons.coffee; active: Sys.caffeine; onClicked: Sys.script("apsis-caffeine.sh") }
                Tile { text: "Hide bar"; subText: "(NON FUNCTIONAL)"; icon: Icons.eyeOff; enabled: false }
            }

            BlockSlider {
                Layout.fillWidth: true
                icon: Sys.muted || Sys.volume === 0 ? Icons.volOff : (Sys.volume < 50 ? Icons.volMed : Icons.volHigh)
                value: Sys.volume
                onReleased: function(v) { Sys.setVolume(v) }
                onMoved: function(v) { volThrottle.v = v; if (!volThrottle.running) volThrottle.start() }
                onIconClicked: Sys.toggleMute()
                more: true
                onMoreClicked: PhoneState.go("sound")
                Timer { id: volThrottle; property real v: 0; interval: 80; onTriggered: Sys.setVolume(v) }
            }
            BlockSlider {
                Layout.fillWidth: true
                visible: Sys.brightness >= 0
                icon: Icons.sun
                value: Math.max(0, Sys.brightness)
                onReleased: function(v) { Sys.setBrightness(v) }
                onMoved: function(v) { brThrottle.v = v; if (!brThrottle.running) brThrottle.start() }
                Timer { id: brThrottle; property real v: 0; interval: 80; onTriggered: Sys.setBrightness(v) }
            }

            MediaCard {
                Layout.fillWidth: true
                Layout.preferredHeight: Sys.hasPlayer ? 110 : 0
                visible: Sys.hasPlayer
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["Quiet", "Balanced", "Performance"]
                    BlockButton {
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        small: true
                        text: modelData
                        fontSize: 11
                        active: Sys.profile === modelData.toLowerCase()
                        onClicked: Sys.setProfile(modelData)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                component Key: BlockButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    vertical: true
                    iconSize: 20
                    fontSize: 10
                }
                Key { icon: Icons.apps; text: "Apps"; onClicked: PhoneState.go("apps") }
                Key { icon: Icons.pencil; text: "Desktop"; enabled: !Config.ultra; onClicked: { PhoneState.close(); EditMode.enter() } }
                Key { icon: Icons.camera; text: "Shot"; onClicked: root.shot() }
                Key { icon: Record.on ? Icons.stop : Icons.record; text: Record.on ? Record.elapsed : "Record"; active: Record.on; onClicked: Record.on ? Record.stop() : Record.start("screen") }
                Key { icon: Icons.theme; text: "Theme"; onClicked: PhoneState.openSettings("theme") }
            }
        }
    }
}
