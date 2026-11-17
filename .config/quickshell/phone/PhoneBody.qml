// The phone's hardware drawn in the block style; one body turns between portrait and landscape.
// Edit: outlineW, ringW, bezelW, bodyRadius and shadowLen here.

import QtQuick
import "../config"

Item {
    id: root

    property real p: 0

    property real flatness: 1
    property size portraitSize: Qt.size(380, 780)
    property size landscapeSize: Qt.size(940, 560)

    property alias portrait: portraitLayer.data
    property alias landscape: landscapeLayer.data

    readonly property real outlineW: 4
    readonly property real ringW: 2.5
    readonly property real bezelW: 10
    readonly property real inset: outlineW + ringW + bezelW
    readonly property real bodyRadius: 52
    readonly property real screenRadius: Math.max(8, bodyRadius - inset)

    readonly property real portraitW: portraitSize.width - 2 * inset
    readonly property real portraitH: portraitSize.height - 2 * inset
    readonly property real landscapeW: landscapeSize.width - 2 * inset
    readonly property real landscapeH: landscapeSize.height - 2 * inset

    function lerp(a, b, t) { return a + (b - a) * t }
    function smooth(a, b, x) { var t = Math.max(0, Math.min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t) }

    width: lerp(portraitSize.height, landscapeSize.width, p)
    height: lerp(portraitSize.width, landscapeSize.height, p)
    rotation: 90 * (1 - p)

    readonly property real shadowLen: 7
    readonly property real _rad: rotation * Math.PI / 180

    Rectangle {
        opacity: root.flatness
        x: root.shadowLen * Math.sin(root._rad)
        y: root.shadowLen * Math.cos(root._rad)
        width: root.width
        height: root.height
        radius: root.bodyRadius
        color: Theme.shadow
        antialiasing: true
    }

    Rectangle {
        opacity: root.flatness
        x: parent.width * 0.16
        y: -5
        width: 86
        height: 12
        radius: 5
        color: Theme.line
        Rectangle { anchors.fill: parent; anchors.margins: 2; anchors.bottomMargin: 5; radius: 3; color: Theme.ring; opacity: 0.55 }
    }
    Rectangle {
        opacity: root.flatness
        x: parent.width * 0.16 + 104
        y: -4
        width: 54
        height: 10
        radius: 5
        color: Theme.line
    }

    Rectangle {
        anchors.fill: parent
        radius: root.bodyRadius
        color: Theme.line
        antialiasing: true
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outlineW
        radius: root.bodyRadius - root.outlineW
        color: Theme.ring
        antialiasing: true
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outlineW + root.ringW
        radius: root.bodyRadius - root.outlineW - root.ringW
        color: Theme.mix(Theme.line, Theme.bgMain, 0.25)
        antialiasing: true
    }

    Rectangle {
        id: screenRect
        anchors.fill: parent
        anchors.margins: root.inset
        radius: root.screenRadius
        color: Theme.bgCard
        antialiasing: true
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Theme.alpha(Theme.accent, Theme.light ? 0.10 : 0.12) }
                GradientStop { position: 0.45; color: "transparent" }
            }
        }

        Item {
            id: portraitLayer
            width: root.portraitW
            height: root.portraitH
            anchors.centerIn: parent
            rotation: -90
            scale: screenRect.height / root.portraitW
            opacity: 1 - root.smooth(0.25, 0.6, root.p)
            visible: opacity > 0.01
            enabled: root.p < 0.5
        }

        Item {
            id: landscapeLayer
            width: root.landscapeW
            height: root.landscapeH
            anchors.centerIn: parent
            scale: screenRect.width / root.landscapeW
            opacity: root.smooth(0.45, 0.85, root.p)
            visible: opacity > 0.01
            enabled: root.p >= 0.5
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.inset - 2
        width: 26
        height: 92
        radius: 13
        color: Theme.mix(Theme.line, Theme.bgMain, 0.25)
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            width: 11
            height: 11
            radius: 6
            color: Theme.line
            Rectangle { x: 3; y: 2.5; width: 3; height: 3; radius: 2; color: Theme.alpha(Theme.accent, 0.8) }
        }
    }
}
