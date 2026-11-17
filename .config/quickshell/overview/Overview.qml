// Every workspace as a card shaped like its monitor, with live window previews (SUPER + Tab).
// Edit: card layout maths in lib/OverviewMath.js; card sizes here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../config"
import "../services"
import "../widgets"
import "../lib/OverviewMath.js" as OM
import "../lib/HyprLua.js" as HL

PanelWindow {
    id: win

    property bool open: false
    property var clients: []
    property var monitor: ({ x: 0, y: 0, width: 1920, height: 1080, name: "", ws: 1 })
    property int activeWs: 1
    property int pick: 0

    readonly property var used: clients.map(c => c.workspace.id)
    readonly property var wsList: OM.range(used, activeWs, 4)
    readonly property var g: OM.grid(wsList.length, width * 0.86, height * 0.72, monitor.width, monitor.height, 22)

    function toggle() { open ? close() : show() }
    function show() {
        var m = Hyprland.focusedMonitor
        var s = m ? Quickshell.screens.filter(x => x.name === m.name)[0] : null
        if (s) win.screen = s
        read()
        open = true
    }
    function close() { open = false }
    function read() { if (!reader.running) reader.running = true }

    function go(ws) { Hyprland.dispatch(HL.workspace(ws)); close() }
    function focusWin(c) { Hyprland.dispatch(HL.focusWindow(c.address)); close() }
    function moveWin(c, ws) { Hyprland.dispatch(HL.moveWindow(c.address, ws)); refresh.restart() }
    function closeWin(c) { Hyprland.dispatch(HL.closeWindow(c.address)); refresh.restart() }

    function waylandOf(c) {
        var a = OM.addr(c.address)
        var all = Hyprland.toplevels ? Hyprland.toplevels.values : []
        for (var i = 0; i < all.length; i++) if (OM.addr(all[i].address) === a) return all[i].wayland || null
        return null
    }

    Process {
        id: reader
        command: ["sh", "-c", "printf '{\"clients\":%s,\"monitors\":%s}' \"$(hyprctl clients -j)\" \"$(hyprctl monitors -j)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    var mons = j.monitors || []
                    var m = mons.filter(x => x.focused)[0] || mons[0]
                    if (m) {

                        var sc = m.scale || 1
                        var rot = (m.transform || 0) % 2 === 1
                        win.monitor = { x: m.x, y: m.y, width: (rot ? m.height : m.width) / sc, height: (rot ? m.width : m.height) / sc, name: m.name }
                        win.activeWs = m.activeWorkspace ? m.activeWorkspace.id : 1
                        win.pick = Math.max(0, win.wsList.indexOf(win.activeWs))
                    }
                    win.clients = (j.clients || []).filter(c => c.mapped !== false && c.workspace && c.workspace.id > 0
                                                              && (!m || c.monitor === m.id))
                } catch (e) {
                    win.clients = []
                }
            }
        }
    }
    Timer { id: refresh; interval: 120; onTriggered: win.read() }
    Connections {
        target: Hyprland
        enabled: win.open
        function onRawEvent(ev) {
            var n = ev.name
            if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2" || n === "changefloatingmode") refresh.restart()
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-overview"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: open || fade.running

    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: Motion.popOutMs } }
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: win.close() }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: win.open
        Keys.onEscapePressed: win.close()
        Keys.onPressed: function(e) {
            var n = win.wsList.length
            if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) win.pick = (win.pick + 1) % n
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) win.pick = (win.pick - 1 + n) % n
            else if (e.key === Qt.Key_Down) win.pick = Math.min(n - 1, win.pick + win.g.cols)
            else if (e.key === Qt.Key_Up) win.pick = Math.max(0, win.pick - win.g.cols)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) win.go(win.wsList[win.pick])
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) win.go(e.key - Qt.Key_0)
            else if (e.key === Qt.Key_0) win.go(10)
            else return
            e.accepted = true
        }
    }

    Pop {
        id: pop
        shown: win.open
        anchors.centerIn: parent
        width: win.g.cols * win.g.cardW + (win.g.cols - 1) * 22
        height: win.g.rows * win.g.cardH + (win.g.rows - 1) * 22 + 34

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -6
            caps: true
            color: Theme.textPrimary
            text: "Workspaces  /  drag a window to move it  /  middle click closes it"
        }

        Grid {
            id: cards
            y: 34
            columns: win.g.cols
            spacing: 22
            Repeater {
                model: win.wsList
                Block {
                    id: card
                    required property int modelData
                    required property int index
                    readonly property int ws: modelData
                    readonly property bool current: ws === win.activeWs
                    readonly property bool picked: index === win.pick
                    readonly property bool dropHere: dnd.hoverWs === ws

                    property bool holding: false
                    z: holding ? 10 : 0
                    width: win.g.cardW
                    height: win.g.cardH + shadowDy
                    fill: dropHere ? Theme.mix(Theme.bgItem, Theme.accent, 0.25) : Theme.bgItem
                    ring: picked || dropHere ? Theme.ringActive : Theme.ring
                    line: current ? Theme.accent : Theme.line
                    pressed: cardMa.pressed

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.go(card.ws)
                        hoverEnabled: true
                        onEntered: win.pick = card.index
                    }

                    Item {
                        id: room
                        anchors.fill: parent
                        Repeater {
                            model: win.clients.filter(c => c.workspace.id === card.ws)
                            WinTile {
                                required property var modelData
                                host: win
                                onDraggingChanged: card.holding = dragging
                                client: modelData
                                cardW: room.width
                                cardH: room.height
                            }
                        }
                    }

                    Block {
                        x: 8; y: 8
                        width: 30; height: 30 + Theme.shadowOffsetSm
                        small: true
                        radius: 9
                        fill: card.current ? Theme.accent : Theme.bgCard
                        Label { anchors.centerIn: parent; text: card.ws; font.pixelSize: 13; font.weight: Font.Black; color: card.current ? Theme.onAccent : Theme.textPrimary }
                    }
                    Label {
                        anchors.centerIn: parent
                        visible: win.clients.filter(c => c.workspace.id === card.ws).length === 0
                        sub: true
                        text: "Empty"
                    }
                }
            }
        }

    }

    QtObject {
        id: dnd
        property int hoverWs: -1
    }
    readonly property QtObject dndState: dnd
    readonly property Item cardsItem: cards

    component WinTile: Block {
        id: t
        property var host: null
        property var client: ({})
        property real cardW: 100
        property real cardH: 60
        readonly property var rect: OM.tile(client.at || [0, 0], client.size || [100, 100], t.host.monitor, t.host.g.scale, cardW, cardH)
        readonly property var wl: t.host.waylandOf(client)
        property bool dragging: ma.drag.active

        x: rect.x; y: rect.y
        width: rect.w; height: rect.h
        z: dragging ? 50 : 1
        small: true
        radius: 8
        flat: true
        fill: Theme.bgCard
        ring: ma.containsMouse ? Theme.ringActive : Theme.ring
        opacity: dragging ? 0.85 : 1

        Image {
            id: ic
            anchors.centerIn: parent
            width: Math.min(40, parent.width * 0.4)
            height: width
            sourceSize.width: 80
            sourceSize.height: 80
            source: Icons.app(String(t.client.class || "").toLowerCase()) || Icons.app(t.client.initialClass || "")
            visible: status === Image.Ready && !shot.hasContent
        }
        ScreencopyView {
            id: shot
            anchors.fill: parent

            captureSource: t.host.open && !Config.ultra ? t.wl : null
            live: true
            visible: hasContent
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 18
            visible: t.height > 46
            color: Theme.alpha(Theme.bgCard, 0.85)
            Label { anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight; font.pixelSize: 9; text: t.client.title || t.client.class || "" }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: t
            drag.threshold: 6
            property point start

            property bool moved: false
            onPressed: { start = Qt.point(t.x, t.y); moved = false }
            onPositionChanged: if (drag.active) {
                moved = true
                var p = t.mapToItem(t.host.cardsItem, t.width / 2, t.height / 2)
                var i = OM.cardAt(p.x, p.y, t.host.g.cols, t.host.g.cardW, t.host.g.cardH + Theme.shadowOffset, 22, t.host.wsList.length)
                t.host.dndState.hoverWs = i >= 0 ? t.host.wsList[i] : -1
            }
            onReleased: {
                if (!moved) return
                var target = t.host.dndState.hoverWs
                t.host.dndState.hoverWs = -1

                t.x = start.x; t.y = start.y
                if (target > 0 && target !== t.client.workspace.id) t.host.moveWin(t.client, target)
            }
            onCanceled: { t.host.dndState.hoverWs = -1; t.x = start.x; t.y = start.y; moved = false }
            onClicked: function(m) {
                if (moved) return
                if (m.button === Qt.MiddleButton) t.host.closeWin(t.client)
                else t.host.focusWin(t.client)
            }
        }
    }
}
