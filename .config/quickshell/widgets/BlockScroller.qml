// A slider that scrolls a Flickable, sideways or (vertical: true) up and down: recessed track and a keycap thumb as long as the part in view; drag, click or wheel it.
// Edit: track thickness and the thumb's minimum length here; colours: config/Theme.qml.

import QtQuick
import "../config"

Item {
    id: root

    property Flickable flick: null
    property bool vertical: false
    property real minThumb: 56
    property real step: 120

    readonly property real view: !flick ? 0 : vertical ? flick.height : flick.width
    readonly property real content: !flick ? 0 : vertical ? flick.contentHeight : flick.contentWidth
    readonly property real offset: !flick ? 0 : vertical ? flick.contentY : flick.contentX
    readonly property real span: Math.max(0, content - view)
    readonly property bool needed: span > 1
    readonly property bool dragging: ma.pressed
    readonly property real length: vertical ? height : width
    readonly property real thumbLen: Math.min(length, Math.max(minThumb, content > 0 ? length * view / content : length))
    readonly property real travel: Math.max(0, length - thumbLen)
    readonly property real pos: span > 0 ? Math.max(0, Math.min(1, offset / span)) : 0
    readonly property real trackH: 16

    implicitHeight: vertical ? 0 : trackH + Theme.shadowOffsetSm
    implicitWidth: vertical ? trackH + Theme.shadowOffsetSm : 0
    opacity: needed ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }

    function setOffset(v) {
        if (!flick) return
        v = Math.max(0, Math.min(span, v))
        if (vertical) flick.contentY = v
        else flick.contentX = v
    }

    function scrollTo(at) {
        if (travel > 0) setOffset(span * Math.max(0, Math.min(1, at / travel)))
    }

    function nudge(by) { setOffset(offset + by) }

    function wheelBy(w) {
        var main = vertical ? w.angleDelta.y : w.angleDelta.x
        var other = vertical ? w.angleDelta.x : w.angleDelta.y
        return -(main !== 0 ? main : other) / 120 * step
    }

    Block {
        id: track
        x: root.vertical ? Theme.shadowOffsetSm / 2 : 0
        y: root.vertical ? 0 : Theme.shadowOffsetSm / 2
        width: root.vertical ? root.trackH : root.width
        height: root.vertical ? root.height : root.trackH
        radius: root.trackH / 2
        small: true
        flat: true
        shadowDy: 0
        fill: Theme.bgMain
    }

    Block {
        id: thumb
        small: true
        width: root.vertical ? root.trackH : root.thumbLen
        height: (root.vertical ? root.thumbLen : root.trackH) + Theme.shadowOffsetSm
        radius: root.trackH / 2
        x: root.vertical ? 0 : root.travel * root.pos
        y: root.vertical ? root.travel * root.pos : 0
        fill: ma.pressed || ma.containsMouse ? Theme.accentHot : Theme.accent
        pressed: ma.pressed
    }

    MouseArea {
        id: ma
        property real grab: 0
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function at(m) { return (root.vertical ? m.y : m.x) - 6 }
        onPressed: function(m) {
            var p = at(m)
            var start = root.vertical ? thumb.y : thumb.x
            var onThumb = p >= start && p <= start + root.thumbLen
            grab = onThumb ? p - start : root.thumbLen / 2
            if (!onThumb) root.scrollTo(p - grab)
        }
        onPositionChanged: function(m) { if (pressed) root.scrollTo(at(m) - grab) }
        onWheel: function(w) { root.nudge(root.wheelBy(w)) }
    }
}
