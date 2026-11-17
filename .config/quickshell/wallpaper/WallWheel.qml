// The wallpaper wheel (SUPER + W): every wallpaper as a card on a turning arc.
// Edit: card size here, the arc in lib/Wheel.js; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"
import "../widgets"
import "../lib/Wheel.js" as W

PanelWindow {
    id: win

    property bool open: false
    property var items: []
    property string sortBy: "name"
    property int pick: 0
    property real spin: 0
    Behavior on spin { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
    readonly property var list: W.sorted(items, sortBy)
    readonly property int n: list.length

    function toggle() { open ? close() : show() }
    function show() {
        var m = Hyprland.focusedMonitor
        var s = m ? Quickshell.screens.filter(x => x.name === m.name)[0] : null
        if (s) win.screen = s
        lister.running = true
        open = true
    }
    function close() { open = false }
    function turn(by) {
        if (n === 0) return
        pick = ((pick + by) % n + n) % n
        spin += by
    }
    function setNow() {
        if (n === 0) return
        Sys.script("apsis-wall.sh", list[pick].path)
        close()
    }

    function settleTo(i) { pick = i; spin = i }

    Process {
        id: lister
        command: [Config.scripts + "/apsis-wall-list.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t")
                    if (p.length >= 4 && p[1]) out.push({ mtime: parseInt(p[0]) || 0, path: p[1], thumb: p[2], kind: p[3] })
                }
                win.items = out
                var at = W.sorted(out, win.sortBy).map(x => x.path).indexOf(Wall.path)
                win.settleTo(at >= 0 ? at : 0)
            }
        }
    }
    onSortByChanged: {
        var cur = n ? list[Math.min(pick, n - 1)] : null
        Qt.callLater(function() { var i = cur ? win.list.map(x => x.path).indexOf(cur.path) : 0; win.settleTo(Math.max(0, i)) })
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-wallwheel"
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
        Keys.onEscapePressed: win.close()
        Keys.onLeftPressed: win.turn(-1)
        Keys.onRightPressed: win.turn(1)
        Keys.onReturnPressed: win.setNow()
        Keys.onEnterPressed: win.setNow()
        Keys.onTabPressed: win.sortBy = win.sortBy === "name" ? "new" : "name"
    }

    Pop {
        id: pop
        shown: win.open
        anchors.fill: parent

        Item {
            id: arc
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.36
            width: 1
            height: 1
            readonly property real cardW: Math.min(460, win.width * 0.3)
            readonly property real cardH: cardW * 9 / 16

            WheelHandler {
                target: null
                parent: pop
                onWheel: function(w) { win.turn(w.angleDelta.y > 0 || w.angleDelta.x > 0 ? -1 : 1) }
            }

            Repeater {
                model: win.list
                Block {
                    id: card
                    required property var modelData
                    required property int index

                    readonly property real d: W.offset(index, win.n ? ((win.spin % win.n) + win.n) % win.n : 0, win.n)
                    readonly property var at: W.place(d, arc.cardW * 0.62)
                    readonly property bool middle: index === win.pick
                    width: arc.cardW
                    height: arc.cardH + shadowDy
                    x: at.x - width / 2
                    y: at.y - height / 2
                    z: at.z
                    scale: at.scale
                    rotation: at.angle
                    opacity: at.opacity
                    visible: opacity > 0.01
                    fill: Theme.bgCard
                    ring: middle ? Theme.ringActive : Theme.ring
                    line: modelData.path === Wall.path ? Theme.accent : Theme.line
                    pressed: ma.pressed

                    RoundImage {
                        anchors.fill: parent
                        radius: Math.max(0, card.radius - card.inset)
                        source: card.modelData.thumb ? "file://" + card.modelData.thumb : ""
                        sourceSize.width: 640
                        sourceSize.height: 360
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                    }
                    VIcon { anchors.centerIn: parent; visible: !card.modelData.thumb; size: 40; d: Icons.image; color: Theme.textSecondary }

                    Block {
                        visible: card.modelData.kind === "video"
                        x: 10; y: 10
                        width: 34; height: 34 + Theme.shadowOffsetSm
                        small: true
                        radius: 17
                        fill: Theme.accent
                        VIcon { anchors.centerIn: parent; size: 16; d: Icons.play; color: Theme.onAccent }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.middle ? win.setNow() : win.turn(Math.round(card.d))
                    }
                }
            }
        }

        Block {
            anchors.horizontalCenter: caption.horizontalCenter
            y: caption.y - 14
            width: caption.width + 40
            height: caption.height + 28 + shadowDy
            fill: Theme.bgCard
        }

        ColumnLayout {
            id: caption
            anchors.horizontalCenter: parent.horizontalCenter
            y: arc.y + arc.cardH * 0.5 + 64
            spacing: 12
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: win.n ? W.baseName(win.list[win.pick].path) : "No wallpapers yet"
                font.pixelSize: 20
                font.weight: Font.Black
                color: Theme.textPrimary
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                sub: true
                text: win.n ? (win.pick + 1) + " of " + win.n + (win.list[win.pick].kind === "video" ? "  /  video" : "")
                            : "Drop images or videos in ~/Apsis/wallpapers"
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                BlockButton { Layout.preferredWidth: 44; Layout.preferredHeight: 40; icon: Icons.chevronRight; rotation: 180; onClicked: win.turn(-1) }
                BlockButton { Layout.preferredWidth: 110; Layout.preferredHeight: 40; text: "Set"; active: true; enabled: win.n > 0; onClicked: win.setNow() }
                BlockButton { Layout.preferredWidth: 44; Layout.preferredHeight: 40; icon: Icons.chevronRight; onClicked: win.turn(1) }
                Item { Layout.preferredWidth: 10 }
                BlockButton { Layout.preferredWidth: 80; Layout.preferredHeight: 34; small: true; text: "A to Z"; fontSize: 11; active: win.sortBy === "name"; onClicked: win.sortBy = "name" }
                BlockButton { Layout.preferredWidth: 80; Layout.preferredHeight: 34; small: true; text: "Newest"; fontSize: 11; active: win.sortBy === "new"; onClicked: win.sortBy = "new" }
            }
        }
    }
}
