// Round profile picture from ~/.config/apsis/face.png, your initial when there is none.
// Edit: size, or set the picture with hypr/scripts/apsis-face.sh.

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import "../config"
import "../services"

Item {
    id: av
    property int size: 40
    implicitWidth: size
    implicitHeight: size

    readonly property string src: "file://" + Quickshell.env("HOME") + "/.config/apsis/face.png"
    readonly property string initial: Settings.userName.length ? Settings.userName.charAt(0).toUpperCase() : "?"

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.bgItem
        border.width: 2
        border.color: Theme.accent
        visible: face.status !== Image.Ready
        Text {
            anchors.centerIn: parent
            text: av.initial
            color: Theme.accent
            font.family: Theme.fontText
            font.pixelSize: Math.round(av.size * 0.42)
            font.weight: Font.Medium
        }
    }

    Image {
        id: face
        anchors.fill: parent
        source: av.src
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: av.size * 2
        sourceSize.height: av.size * 2
        cache: false
        asynchronous: true
        visible: face.status === Image.Ready
        layer.enabled: face.status === Image.Ready && !Config.soft
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: face.width
                height: face.height
                radius: width / 2
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        visible: face.status === Image.Ready
    }
}
