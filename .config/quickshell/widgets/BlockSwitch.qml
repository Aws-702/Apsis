// An on and off switch: a block track with a keycap knob sliding across.
// Edit: implicitWidth and implicitHeight here.

import QtQuick
import "../config"

Item {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 52
    implicitHeight: 30

    Block {
        id: track
        anchors.fill: parent
        small: true
        radius: height / 2
        fill: root.checked ? Theme.accent : Theme.bgMain
        flat: true
    }
    Block {
        id: knob
        small: true
        width: track.keyHeight - 6
        height: width + Theme.shadowOffsetSm
        radius: width / 2
        y: 3
        x: root.checked ? track.width - width - 3 : 3
        fill: Theme.bgCard
        pressed: ma.pressed
        Behavior on x { NumberAnimation { duration: Motion.releaseMs; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
