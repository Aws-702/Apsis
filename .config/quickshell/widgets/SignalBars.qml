// Four rising bars lit to a signal strength from 0 to 100.
// Edit: size and the bar thresholds here.

import QtQuick
import "../config"

Row {
    id: root
    property int strength: 0
    property color color: Theme.accent
    property real size: 16
    readonly property int lit: strength >= 75 ? 4 : strength >= 50 ? 3 : strength >= 25 ? 2 : strength > 0 ? 1 : 0

    spacing: Math.max(1, size / 10)
    height: size
    Repeater {
        model: 4
        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: (root.size - 3 * root.spacing) / 4
            height: root.size * (0.35 + 0.65 * index / 3)
            radius: width / 3
            color: index < root.lit ? root.color : Theme.alpha(root.color, 0.22)
        }
    }
}
