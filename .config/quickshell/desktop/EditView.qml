// What Edit Desktop draws on one monitor: dimmed dot grid, widgets with handles, snap guides, shelf.
// Edit: grid spacing and guide look here; snapping rules in lib/EditGridMath.js.

import QtQuick
import "../config"
import "../services"
import "../widgets"

Item {
    id: root
    property string screenName: ""
    property bool firstScreen: false

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bgMain, 0.55)
    }

    Canvas {
        id: dots
        anchors.fill: parent
        opacity: Settings.gridSnap ? 0.55 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }
        readonly property int step: Settings.gridSize
        readonly property color ink: Theme.ring
        onStepChanged: requestPaint()
        onInkChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = ink
            for (var x = 16; x < width; x += step)
                for (var y = 16; y < height; y += step)
                    ctx.fillRect(x - 1, y - 1, 2, 2)
        }
    }

    WidgetCanvas {
        anchors.fill: parent
        screenName: root.screenName
        firstScreen: root.firstScreen
        editing: true
    }

    Repeater {
        model: EditMode.dragScreen === root.screenName ? EditMode.guides : []
        Rectangle {
            required property var modelData
            readonly property bool vertical: modelData.axis === "x"
            x: vertical ? modelData.pos - 1 : 0
            y: vertical ? 0 : modelData.pos - 1
            width: vertical ? 2 : root.width
            height: vertical ? root.height : 2
            color: modelData.kind === "room" ? Theme.cyan : Theme.accentHot
            opacity: 0.9
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: shelf.top
        anchors.bottomMargin: 14
        caps: true
        font.pixelSize: 12
        color: Theme.textPrimary
        text: "Edit desktop  /  drag to move  /  Esc or Done to finish"
    }

    EditShelf {
        id: shelf
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: Math.min(parent.width - 48, 1180)
        height: implicitHeight
        screenName: root.screenName
        firstScreen: root.firstScreen
        roomW: root.width
        roomH: root.height
    }
}
