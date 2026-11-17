// Stand-in for ScreencopyView: an empty box (no live windows in shots).
// Edit: nothing.

import QtQuick
import ShotLab
Item {
    property var captureSource
    property bool live: false
    property bool paintCursor: false
    readonly property bool hasContent: true
    readonly property size sourceSize: Qt.size(width, height)
    Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; source: Shot.windowShot(parent.captureSource); smooth: true }
}
