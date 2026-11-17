// Bar key: the keyboard layout as two letters, only with more than one layout; click to switch.
// Edit: layouts in hyprland.lua (kb_layout); the short names here.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root

    property string layouts: ""
    property string keymap: ""
    readonly property bool multi: layouts.indexOf(",") >= 0
    readonly property string code: keymap === "" ? "" : keymap.replace(/[^A-Za-z]/g, "").substring(0, 2).toUpperCase()

    small: true
    radius: 10
    Layout.fillHeight: true
    implicitHeight: 29
    implicitWidth: multi ? 40 : 0
    visible: multi
    fill: Theme.bgItem
    pressed: ma.pressed

    Process {
        id: read
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    var kbs = j.keyboards || []
                    var main = kbs.filter(function(k) { return k.main })[0] || kbs[0]
                    if (!main) return
                    root.layouts = main.layout || ""
                    root.keymap = main.active_keymap || ""
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name !== "activelayout") return
            var d = String(ev.data)
            root.keymap = d.substring(d.indexOf(",") + 1)
        }
    }
    Process { id: next; command: ["hyprctl", "switchxkblayout", "all", "next"] }

    Label {
        anchors.centerIn: parent
        text: root.code
        font.pixelSize: 11
        font.weight: Font.Black
        color: Theme.accent
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: next.running = true
    }
}
