// Settings > Shortcuts: rebind keys (apsis-keybind.sh rewrites the line and keeps a .bak).
// Edit: which binds are editable is decided in hypr/scripts/apsis-keybind.sh.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"

ColumnLayout {
    id: root
    spacing: 10

    property bool active: false
    property var binds: []
    property string editId: ""
    property bool emSuper: false
    property bool emCtrl: false
    property bool emAlt: false
    property bool emShift: false
    property string emKey: ""

    onActiveChanged: if (active) { editId = ""; lister.running = true }
    Component.onCompleted: if (active) lister.running = true

    function beginEdit(id, combo) {
        editId = id
        emSuper = combo.indexOf("SUPER") >= 0
        emCtrl = combo.indexOf("CONTROL") >= 0
        emAlt = combo.indexOf("ALT") >= 0
        emShift = combo.indexOf("SHIFT") >= 0
        var parts = combo.split("+")
        emKey = parts[parts.length - 1].trim()
    }
    function buildCombo() {
        var m = []
        if (emSuper) m.push("SUPER")
        if (emCtrl) m.push("CONTROL")
        if (emAlt) m.push("ALT")
        if (emShift) m.push("SHIFT")
        if (emKey.length) m.push(emKey)
        return m.join(" + ")
    }
    function saveEdit() {
        if (!emKey.length) return
        Quickshell.execDetached([Config.scripts + "/apsis-keybind.sh", "set", editId, buildCombo()])
        editId = ""
        delay.restart()
    }
    function pretty(c) {
        var map = { "XF86AudioRaiseVolume": "Volume Up", "XF86AudioLowerVolume": "Volume Down", "XF86AudioMute": "Mute",
                    "XF86AudioMicMute": "Mic Mute", "XF86MonBrightnessUp": "Brightness Up", "XF86MonBrightnessDown": "Brightness Down",
                    "XF86AudioPlay": "Play / Pause", "XF86AudioNext": "Next", "XF86AudioPrev": "Previous" }
        return map[c] || c
    }
    function keyName(ev) {
        var k = ev.key
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F12) return "F" + (k - Qt.Key_F1 + 1)
        var named = {}
        named[Qt.Key_Left] = "left"; named[Qt.Key_Right] = "right"; named[Qt.Key_Up] = "up"; named[Qt.Key_Down] = "down"
        named[Qt.Key_Space] = "space"; named[Qt.Key_Escape] = "Escape"; named[Qt.Key_Return] = "Return"; named[Qt.Key_Enter] = "Return"
        named[Qt.Key_Tab] = "Tab"; named[Qt.Key_Print] = "Print"; named[Qt.Key_Minus] = "minus"; named[Qt.Key_Equal] = "equal"
        named[Qt.Key_Comma] = "comma"; named[Qt.Key_Period] = "period"; named[Qt.Key_Slash] = "slash"
        if (named[k]) return named[k]
        if (ev.text && ev.text.trim().length === 1) return ev.text.toUpperCase()
        return ""
    }

    Process {
        id: lister
        command: [Config.scripts + "/apsis-keybind.sh", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text.trim()
                var arr = []
                if (out.length) {
                    var lines = out.split("\n")
                    for (var i = 0; i < lines.length; i++) {
                        var p = lines[i].split("\t")
                        if (p.length >= 2) arr.push({ id: p[0], combo: p[1], label: p.length > 2 ? p[2] : p[1] })
                    }
                }
                root.binds = arr
            }
        }
    }
    Timer { id: delay; interval: 500; onTriggered: lister.running = true }
    Process { id: restoreP; command: [Config.scripts + "/apsis-keybind.sh", "restore"] }

    RowLayout {
        Layout.fillWidth: true
        Label { caps: true; text: "Shortcuts"; Layout.fillWidth: true }
        BlockButton { small: true; Layout.preferredWidth: 120; Layout.preferredHeight: 32; fontSize: 11; text: "Restore last"; onClicked: { restoreP.running = true; delay.restart() } }
    }

    Repeater {
        model: root.binds
        Block {
            id: row
            required property var modelData
            readonly property bool editing: root.editId === modelData.id
            readonly property bool canEdit: modelData.combo.indexOf("XF86") < 0
            Layout.fillWidth: true
            Layout.preferredHeight: editing ? 96 : 50
            small: true
            ColumnLayout {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8; leftMargin: 14 }
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: row.modelData.label; font.pixelSize: 12; Layout.fillWidth: true }
                    BlockButton {
                        small: true
                        Layout.preferredHeight: 30
                        Layout.preferredWidth: Math.max(80, comboText.implicitWidth + 30)
                        enabled: row.canEdit
                        active: row.editing
                        onClicked: row.editing ? root.editId = "" : root.beginEdit(row.modelData.id, row.modelData.combo)
                        Label { id: comboText; anchors.centerIn: parent; font.pixelSize: 11; color: row.editing ? Theme.onAccent : Theme.textPrimary
                            text: row.editing ? (root.buildCombo() || "...") : root.pretty(row.modelData.combo) }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    visible: row.editing
                    spacing: 6
                    component Mod: BlockButton { small: true; Layout.preferredWidth: 64; Layout.preferredHeight: 30; fontSize: 10 }
                    Mod { text: "Super"; active: root.emSuper; onClicked: root.emSuper = !root.emSuper }
                    Mod { text: "Ctrl"; active: root.emCtrl; onClicked: root.emCtrl = !root.emCtrl }
                    Mod { text: "Alt"; active: root.emAlt; onClicked: root.emAlt = !root.emAlt }
                    Mod { text: "Shift"; active: root.emShift; onClicked: root.emShift = !root.emShift }
                    Block {
                        id: cap
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        small: true
                        fill: capFocus.activeFocus ? Theme.bgHover : Theme.bgMain
                        Item {
                            id: capFocus
                            anchors.fill: parent
                            focus: row.editing
                            Keys.onPressed: function(ev) { var n = root.keyName(ev); if (n.length) { root.emKey = n; ev.accepted = true } }
                        }
                        Label { anchors.centerIn: parent; font.pixelSize: 10; sub: root.emKey === ""; text: root.emKey.length ? root.emKey : "press a key" }
                        MouseArea { anchors.fill: parent; onClicked: capFocus.forceActiveFocus() }
                    }
                    Mod { text: "Save"; active: true; onClicked: root.saveEdit() }
                }
            }
        }
    }
    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        sub: true
        font.pixelSize: 10
        text: "Workspace and mouse binds live in hyprland.lua and are not listed here. Binds you add in custom.lua show up here."
    }
}
