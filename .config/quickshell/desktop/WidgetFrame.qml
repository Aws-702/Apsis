// One desktop widget: places it, loads its type, adds drag, snap and remove in Edit Desktop.
// Edit: handle and remove key look here; sizes per type in lib/WidgetTypes.js.

import QtQuick
import "../config"
import "../services"
import "../widgets"
import "../lib/WidgetTypes.js" as Types
import "../lib/EditGridMath.js" as GM

Item {
    id: root

    property var widget: ({})
    property bool editing: false
    property string screenName: ""
    property bool firstScreen: false
    property real roomW: 1920
    property real roomH: 1080

    readonly property var info: Types.info(widget.type)
    readonly property bool dragging: drag.active

    property real dragX: 0
    property real dragY: 0
    x: dragging ? dragX : widget.x
    y: dragging ? dragY : widget.y
    readonly property var size: Types.size(widget.type, widget.style)
    width: size.w
    height: size.h
    visible: info !== null
    z: dragging ? 10 : 0

    scale: dragging ? 1.03 : 1
    Behavior on scale { NumberAnimation { duration: Motion.releaseMs; easing.type: Easing.OutBack; easing.overshoot: 2 } }

    Loader {
        id: body
        anchors.fill: parent
        source: root.info ? "widgets/" + root.info.file : ""
        onLoaded: {
            item.widget = Qt.binding(function() { return root.widget })
            item.editing = Qt.binding(function() { return root.editing })
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        visible: root.editing
        radius: 18
        color: Theme.alpha(Theme.accent, root.dragging ? 0.12 : 0.04)
        border.width: 2
        border.color: Theme.alpha(Theme.accent, root.dragging ? 1 : 0.55)
    }

    MouseArea {
        id: mover
        anchors.fill: parent
        visible: root.editing
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property real ox: 0
        property real oy: 0
        drag.target: null

        property bool moved: false

        onPressed: function(m) {
            ox = m.x
            oy = m.y
            root.dragX = root.widget.x
            root.dragY = root.widget.y
            moved = false
        }
        onPositionChanged: function(m) {
            if (!pressed) return
            var p = mapToItem(root.parent, m.x, m.y)
            var raw = { x: p.x - ox, y: p.y - oy, w: root.width, h: root.height }
            if (!moved && (Math.abs(raw.x - root.widget.x) > 3 || Math.abs(raw.y - root.widget.y) > 3)) {
                moved = true
                EditMode.dragging = root.widget.id
                EditMode.dragScreen = root.screenName
            }
            if (!moved) return
            var r = GM.snap(raw, Desktop.rectsExcept(root.widget.id, root.screenName, root.firstScreen),
                            { roomW: root.roomW, roomH: root.roomH, grid: Settings.gridSize, snap: Settings.gridSnap })
            root.dragX = r.x
            root.dragY = r.y
            EditMode.guides = r.guides
        }
        onReleased: {
            if (moved) Desktop.move(root.widget.id, root.dragX, root.dragY)
            moved = false
            EditMode.dragging = ""
            EditMode.guides = []
        }
    }
    QtObject {
        id: drag
        readonly property bool active: mover.moved && mover.pressed
    }

    BlockButton {
        visible: root.editing
        small: true
        width: 30
        height: 31
        radius: 15
        x: root.width - 18
        y: -14
        icon: Icons.close
        iconSize: 14
        fillIdle: Theme.danger
        fillHover: Theme.accentHot
        onClicked: Desktop.remove(root.widget.id)
    }
}
