// The building block of every surface: thick outline, bright ring, fill, hard shadow, keycap press.
// Edit: the shape tokens (radiusBlock, blockBorder, blockRing, shadowOffset) in config/Theme.qml.

import QtQuick
import "../config"

Item {
    id: root

    property color fill: Theme.bgItem
    property color line: Theme.line
    property color ring: Theme.ring
    property bool small: false
    property real radius: Theme.radiusBlock
    property real borderWidth: small ? Theme.blockBorderSm : Theme.blockBorder
    property real ringWidth: small ? Theme.blockRingSm : Theme.blockRing
    property real shadowDx: 0
    property real shadowDy: small ? Theme.shadowOffsetSm : Theme.shadowOffset
    property color shadowColor: Theme.shadow
    property bool pressed: false
    property bool flat: false
    property bool bare: false

    readonly property real keyWidth: width - shadowDx
    readonly property real keyHeight: height - shadowDy

    readonly property real inset: bare ? 0 : borderWidth + ringWidth

    default property alias content: inner.data

    implicitWidth: 120
    implicitHeight: 40

    Behavior on fill { ColorAnimation { duration: Motion.quickMs } }

    Rectangle {
        id: shadowRect
        visible: !root.bare && !root.flat
        x: root.shadowDx
        y: root.shadowDy
        width: root.keyWidth
        height: root.keyHeight
        radius: root.radius
        color: root.shadowColor
        antialiasing: true
    }

    Item {
        id: cap
        x: (root.pressed && !root.flat) ? root.shadowDx : 0
        y: root.pressed ? (root.flat ? 1 : root.shadowDy) : 0
        width: root.keyWidth
        height: root.keyHeight

        Behavior on x {
            NumberAnimation {
                duration: root.pressed ? Motion.pressMs : Motion.releaseMs
                easing.type: root.pressed ? Easing.OutQuad : Easing.OutBack
                easing.overshoot: root.pressed ? 0 : Motion.releaseOvershoot
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: root.pressed ? Motion.pressMs : Motion.releaseMs
                easing.type: root.pressed ? Easing.OutQuad : Easing.OutBack
                easing.overshoot: root.pressed ? 0 : Motion.releaseOvershoot
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: !root.bare
            radius: root.radius
            color: root.line
            antialiasing: true
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: root.borderWidth
            visible: !root.bare && root.ringWidth > 0
            radius: Math.max(0, root.radius - root.borderWidth)
            color: root.ring
            antialiasing: true
        }
        Rectangle {
            id: face
            anchors.fill: parent
            anchors.margins: root.inset
            visible: !root.bare
            radius: Math.max(0, root.radius - root.inset)
            color: root.fill
            antialiasing: true
        }
        Item {
            id: inner
            anchors.fill: face
        }
    }
}
