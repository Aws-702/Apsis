// The power menu: five big keycaps that pop in one after another (ALT + F4).
// Edit: the keys, their actions and sizes here; the pop timing in config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"

PanelWindow {
    id: root

    readonly property bool open: UiState.powerMenuOpen
    property bool _ready: false

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-powermenu"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || closing.running

    function act(args) {
        UiState.powerMenuOpen = false
        if (args === null) {
            if (Settings.lockWith === "hyprlock") Quickshell.execDetached(["hyprlock"])
            else LockState.lock()
            return
        }
        Quickshell.execDetached(args)
    }

    Timer { interval: 500; running: true; onTriggered: root._ready = true }
    Timer { id: closing; interval: Motion.popOutMs + 60 }
    onOpenChanged: if (!open) closing.restart()

    FileView {
        path: Config.cacheDir + "/apsis-powermenu"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: if (root._ready && text().trim().indexOf("open") === 0) UiState.powerMenuOpen = true
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.popInMs } }
        MouseArea { anchors.fill: parent; onClicked: UiState.powerMenuOpen = false }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: UiState.powerMenuOpen = false

        RowLayout {
            anchors.centerIn: parent
            spacing: 22
            Repeater {
                model: [
                    { label: "Lock", icon: Icons.lock, cmd: null },
                    { label: "Logout", icon: Icons.logout, cmd: ["sh", "-c", "uwsm stop || hyprctl dispatch 'hl.dsp.exit()' || loginctl terminate-user \"$USER\""] },

                    { label: "Sleep", icon: Icons.sleep, cmd: ["sh", "-c", Config.scripts + "/apsis-lock.sh & sleep 1; systemctl suspend"] },
                    { label: "Restart", icon: Icons.restart, cmd: ["systemctl", "reboot"] },
                    { label: "Shutdown", icon: Icons.power, cmd: ["systemctl", "poweroff"] }
                ]
                Pop {
                    id: pop
                    required property var modelData
                    required property int index
                    Layout.preferredWidth: 136
                    Layout.preferredHeight: 140
                    shown: false

                    Timer { running: root.open; interval: 35 * pop.index + 1; onTriggered: pop.shown = true }
                    Connections { target: root; function onOpenChanged() { if (!root.open) pop.shown = false } }
                    BlockButton {
                        anchors.fill: parent
                        vertical: true
                        icon: pop.modelData.icon
                        iconSize: 40
                        text: pop.modelData.label
                        fontSize: 14
                        fillIdle: Theme.bgCard
                        fillHover: pop.modelData.label === "Shutdown" ? Theme.danger : Theme.accent
                        onClicked: root.act(pop.modelData.cmd)
                    }
                }
            }
        }
    }
}
