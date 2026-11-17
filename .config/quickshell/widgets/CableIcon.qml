// A drawn network cable jack icon.
// Edit: the shapes here.

import QtQuick

Item {
    id: root
    property color color: "white"
    property real  size: 16
    width: size
    height: size

    Item {
        anchors.centerIn: parent
        width: 16
        height: 16
        scale: root.size / 16

        Rectangle {
            id: body
            width: 13
            height: 9
            radius: 2
            y: 2
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            border.width: 1.6
            border.color: root.color
        }

        Rectangle {
            width: 5
            height: 3
            radius: 1
            anchors.top: body.bottom
            anchors.topMargin: -0.5
            anchors.horizontalCenter: body.horizontalCenter
            color: root.color
        }

        Row {
            anchors.horizontalCenter: body.horizontalCenter
            y: 4
            spacing: 1.4
            Repeater {
                model: 4
                Rectangle { width: 1.1; height: 3; radius: 0.4; color: root.color }
            }
        }
    }
}
