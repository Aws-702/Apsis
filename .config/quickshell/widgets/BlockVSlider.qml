// An upright gain slider growing up or down from 0; double click resets it.
// Edit: knobH, from and to here.

import QtQuick
import "../config"

Item {
    id: root
    property real value: 0
    property real from: -12
    property real to: 12
    property bool dragging: ma.pressed
    property real _drag: 0
    readonly property real shown: dragging ? _drag : value
    signal moved(real v)

    implicitWidth: 28
    implicitHeight: 180

    function frac(v) { return (v - from) / (to - from) }
    readonly property real knobH: 20
    readonly property real travel: height - knobH
    readonly property real zeroY: travel * (1 - frac(0)) + knobH / 2

    Block {
        id: track
        anchors.horizontalCenter: parent.horizontalCenter
        width: 12
        height: parent.height
        radius: 6
        small: true
        flat: true
        fill: Theme.bgMain
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 6
        radius: 3
        color: Theme.accent
        readonly property real y1: root.travel * (1 - root.frac(root.shown)) + root.knobH / 2
        y: Math.min(y1, root.zeroY)
        height: Math.abs(y1 - root.zeroY)
    }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: root.zeroY - 1; width: 16; height: 2; radius: 1; color: Theme.alpha(Theme.textSecondary, 0.6) }
    Block {
        small: true
        width: root.width
        height: root.knobH + Theme.shadowOffsetSm
        radius: 7
        y: root.travel * (1 - root.frac(root.shown)) - 1
        fill: Theme.bgCard
        pressed: ma.pressed
        Behavior on y { enabled: !root.dragging; NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function at(my) {
            var f = 1 - Math.max(0, Math.min(1, (my - root.knobH / 2) / Math.max(1, root.travel)))
            return root.from + f * (root.to - root.from)
        }
        onPressed: function(m) { root._drag = at(m.y) }
        onPositionChanged: function(m) { if (pressed) { root._drag = at(m.y); root.moved(root._drag) } }
        onReleased: root.moved(root._drag)
        onDoubleClicked: root.moved(0)
        onWheel: function(w) { root.moved(Math.max(root.from, Math.min(root.to, root.value + (w.angleDelta.y > 0 ? 0.5 : -0.5)))) }
    }
}
