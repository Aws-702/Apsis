// Every keyboard shortcut on one sheet (SUPER + /), read live from the Hyprland config.
// Edit: groups, names and the column split in lib/KeyGroups.js; sheet sizes here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"
import "../widgets"
import "../lib/KeyGroups.js" as KG

PanelWindow {
    id: win

    property bool open: false
    property var binds: []
    property string filter: ""
    readonly property var sections: KG.sections(binds.concat(KG.EXTRA), filter)
    readonly property var columns: KG.columns(sections, 3)
    onFilterChanged: list.contentY = 0

    function toggle() { open ? close() : show() }
    function show() {
        var m = Hyprland.focusedMonitor
        var s = m ? Quickshell.screens.filter(x => x.name === m.name)[0] : null
        if (s) win.screen = s
        filter = ""
        list.contentY = 0
        lister.running = true
        open = true
    }
    function close() { open = false }

    Process {
        id: lister
        command: [Config.scripts + "/apsis-keybind.sh", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var arr = []
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t")
                    if (p.length >= 3) arr.push({ combo: p[1], label: p[2] })
                }
                win.binds = arr
            }
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-cheatsheet"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || !pop.settled

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.popOutMs } }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: win.close() }
    }

    Item {
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: win.filter !== "" ? win.filter = "" : win.close()
        Keys.onPressed: function(e) {
            var page = Math.max(60, list.height - 60)
            var by = e.key === Qt.Key_Up ? -60 : e.key === Qt.Key_Down ? 60 : e.key === Qt.Key_PageUp ? -page : e.key === Qt.Key_PageDown ? page
                   : e.key === Qt.Key_Home ? -1e6 : e.key === Qt.Key_End ? 1e6 : 0
            if (by !== 0) { scroller.nudge(by); e.accepted = true }
            else if (e.key === Qt.Key_Backspace) { win.filter = win.filter.slice(0, -1); e.accepted = true }
            else if (e.text && e.text.length === 1 && e.text >= " " && !(e.modifiers & Qt.MetaModifier)) { win.filter += e.text; e.accepted = true }
        }
    }

    Pop {
        id: pop
        shown: win.open
        anchors.centerIn: parent
        width: Math.min(win.width - 80, 1180)
        height: Math.min(win.height - 80, sheet.implicitHeight)

        Block {
            id: sheet
            anchors.fill: parent
            implicitHeight: head.implicitHeight + body.spacing + Math.max(cols.implicitHeight, none.visible ? none.implicitHeight : 0) + 40 + 2 * inset + shadowDy
            fill: Theme.bgCard
            ring: Theme.ringActive
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            ColumnLayout {
                id: body
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    id: head
                    Layout.fillWidth: true
                    spacing: 12
                    VIcon { size: 22; d: Icons.keyboard; color: Theme.accent }
                    Label { text: "Shortcuts"; font.pixelSize: 22; font.weight: Font.Black }
                    Item { Layout.fillWidth: true }
                    Block {
                        Layout.preferredWidth: 260
                        Layout.preferredHeight: 38
                        small: true
                        flat: true
                        fill: Theme.bgMain
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            VIcon { size: 15; d: Icons.search; color: Theme.textSecondary }
                            Label { Layout.fillWidth: true; elide: Text.ElideLeft; text: win.filter === "" ? "Type to filter" : win.filter; sub: win.filter === "" }
                        }
                    }
                }

                Label { id: none; visible: win.sections.length === 0; sub: true; text: "No shortcut matches \"" + win.filter + "\"" }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Flickable {
                        id: list
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: width
                        contentHeight: cols.implicitHeight
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        Behavior on contentY { enabled: !scroller.dragging && !list.dragging && !list.flicking; NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: cols
                            width: list.width
                            spacing: 18
                            Repeater {
                                model: win.columns
                                ColumnLayout {
                                    id: col
                                    required property var modelData
                                    Layout.preferredWidth: (cols.width - 2 * cols.spacing) / 3
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 14
                                    Repeater {
                                        model: col.modelData
                                        ColumnLayout {
                                            id: sec
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Label { caps: true; text: sec.modelData.name; color: Theme.accent; Layout.bottomMargin: 2 }
                                            Repeater {
                                                model: sec.modelData.binds
                                                RowLayout {
                                                    id: bind
                                                    required property var modelData
                                                    Layout.fillWidth: true
                                                    spacing: 4
                                                    Label { text: bind.modelData.label; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                                    Repeater {
                                                        model: KG.caps(bind.modelData.combo)
                                                        Block {
                                                            required property string modelData
                                                            Layout.preferredWidth: Math.max(26, capText.implicitWidth + 14)
                                                            Layout.preferredHeight: 24 + Theme.shadowOffsetSm
                                                            small: true
                                                            radius: 6
                                                            fill: Theme.bgItem
                                                            Label { id: capText; anchors.centerIn: parent; text: modelData; font.pixelSize: 10; font.weight: Font.DemiBold }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    BlockScroller {
                        id: scroller
                        Layout.fillHeight: true
                        vertical: true
                        flick: list
                    }
                }
            }
        }
    }
}
