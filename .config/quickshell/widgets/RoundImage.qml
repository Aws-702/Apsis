// An image clipped to rounded corners.
// Edit: radius.

import QtQuick
import Qt5Compat.GraphicalEffects
import "../config"

Image {
    id: img
    property real radius: 8

    fillMode: Image.PreserveAspectCrop
    asynchronous: true

    layer.enabled: status === Image.Ready && !Config.soft
    layer.smooth: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: img.width
            height: img.height
            radius: img.radius
        }
    }
}
