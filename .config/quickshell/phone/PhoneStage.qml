// Where the phone sits on a monitor: the scrim, the rise from the bottom edge and the turn.
// Edit: alertShow, depth and camera here, the rise and turn timings in config/Motion.qml.

import QtQuick
import QtQuick.Shapes
import "../config"
import "../services"
import "../lib/Tilt.js" as Tilt

Item {
    id: root

    property alias body: body
    property alias portrait: body.portrait
    property alias landscape: body.landscape

    readonly property real peek: Math.max(0.5, Math.min(1, Settings.phonePeek))
    readonly property real alertShow: 168

    readonly property real restY: height - body.portraitSize.height * peek + body.portraitSize.height / 2
    readonly property real alertY: height - alertShow + body.portraitSize.height / 2
    readonly property real closedY: height + body.portraitSize.height / 2 + 40
    readonly property real targetY: PhoneState.open ? restY : (PhoneState.alerting ? alertY : closedY)

    property real py: closedY
    property bool rising: true
    onTargetYChanged: { rising = targetY < py; py = targetY }
    Behavior on py {
        NumberAnimation {
            duration: root.rising ? Motion.riseMs : Motion.sinkMs
            easing.type: root.rising ? Easing.OutBack : Easing.InCubic
            easing.overshoot: Motion.riseOvershoot
        }
    }

    property real flip: PhoneState.landscape ? 1 : 0
    Behavior on flip {
        NumberAnimation { duration: Motion.flipMs; easing.type: Easing.InOutBack; easing.overshoot: Motion.flipOvershoot }
    }

    readonly property bool away: !PhoneState.open && !PhoneState.alerting && py >= closedY - 1 && flip < 0.001

    property alias hitBox: hit

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Theme.scrim
        opacity: PhoneState.open ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Motion.popInMs; easing.type: Easing.OutQuad } }
        MouseArea {
            anchors.fill: parent
            enabled: PhoneState.open
            onClicked: PhoneState.close()
        }
    }

    Item {
        id: hit
        x: (root.width - body.portraitSize.width) / 2
        y: root.py - body.portraitSize.height / 2
        width: body.portraitSize.width
        height: Math.max(0, root.height - y)
    }

    readonly property real tiltOn: Settings.phoneStyle === "2.5d" && !Config.ultra ? 1 : 0
    property real tiltSetting: tiltOn
    Behavior on tiltSetting { NumberAnimation { duration: Motion.flipMs; easing.type: Easing.InOutCubic } }

    readonly property bool wide: flip > 0.5
    readonly property real tiltTurn: wide ? (flip - 0.88) / 0.12 : 1 - flip / 0.12
    readonly property real tilt: Math.max(0, Math.min(1, tiltSetting * tiltTurn * gate))

    property real gate: 1
    Connections {
        target: PhoneState
        function onLandscapeChanged() { gateIn.stop(); gateOut.restart(); landed.restart() }
    }
    NumberAnimation { id: gateOut; target: root; property: "gate"; to: 0; duration: 120; easing.type: Easing.OutQuad }
    Timer { id: landed; interval: Motion.flipMs; onTriggered: gateIn.restart() }
    NumberAnimation { id: gateIn; target: root; property: "gate"; to: 1; duration: 280; easing.type: Easing.OutCubic }

    readonly property size boxSize: wide ? body.landscapeSize : body.portraitSize

    readonly property real yaw: (wide ? 13 : 22) * tilt
    readonly property real pitch: 0
    readonly property real depth: 36
    readonly property real camera: 1500
    readonly property var tiltM: Tilt.matrix(boxSize.width, boxSize.height, yaw, pitch, camera)

    Item {
        id: tiltBox
        width: root.boxSize.width
        height: root.boxSize.height
        x: body.cx - width / 2
        y: body.cy - height / 2

        Shape {
            id: wallShape
            anchors.fill: parent
            visible: root.tilt > 0.01
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Theme.mix(Theme.line, Theme.ring, 0.28)
                PathSvg { path: root.tilt > 0.01 ? Tilt.svg(Tilt.wall(root.tiltM, tiltBox.width, tiltBox.height, body.bodyRadius, 0, -root.depth)) : "" }
            }
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Theme.mix(Theme.line, Theme.ring, 0.55)
                PathSvg { path: root.tilt > 0.01 ? Tilt.svg(Tilt.wall(root.tiltM, tiltBox.width, tiltBox.height, body.bodyRadius, 0, -root.depth * 0.16)) : "" }
            }

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Theme.line
                PathSvg { path: root.tilt > 0.01 && !root.wide ? Tilt.svg(Tilt.sideKey(root.tiltM, tiltBox.width, 150, 236, 5, -root.depth * 0.25, -root.depth * 0.75)) : "" }
            }
            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillColor: Theme.line
                PathSvg { path: root.tilt > 0.01 && !root.wide ? Tilt.svg(Tilt.sideKey(root.tiltM, tiltBox.width, 254, 308, 5, -root.depth * 0.25, -root.depth * 0.75)) : "" }
            }
        }

        Item {
            id: face
            anchors.fill: parent
            readonly property bool tilted: root.tilt > 0.001
            Matrix4x4 { id: tiltTransform; matrix: Qt.matrix4x4(Tilt.flat(root.tiltM)) }
            transform: face.tilted ? [tiltTransform] : []
            layer.enabled: face.tilted
            layer.smooth: true
            layer.mipmap: true

            layer.textureSize: Qt.size(width * 2, height * 2)

            PhoneBody {
                id: body
                p: root.flip

                readonly property real cx: root.width / 2
                readonly property real cy: root.lerp(root.py, root.height / 2, root.flip)
                x: (face.width - width) / 2
                y: (face.height - height) / 2

                flatness: 1 - root.tilt

                MouseArea { anchors.fill: parent; z: -1 }
            }
        }
    }

    function lerp(a, b, t) { return a + (b - a) * t }
}
