// Bar keys: workspaces as tiny keycaps, the active one lit and wider.
// Edit: key sizes and how many show here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../config"
import "../../widgets"
import "../../lib/HyprLua.js" as HL

Block {
    id: root
    small: true
    radius: 10
    implicitWidth: row.implicitWidth + 18
    implicitHeight: 29
    fill: Theme.bgItem

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Repeater {
            model: Hyprland.workspaces

            Block {
                id: key
                required property var modelData
                readonly property bool on: modelData.active
                small: true
                borderWidth: 1.5
                ringWidth: 0
                shadowDy: 2
                radius: 4
                implicitWidth: on ? 24 : 12
                implicitHeight: 12
                fill: on ? Theme.accentHot : Theme.bgHover
                pressed: ma.pressed
                Behavior on implicitWidth { NumberAnimation { duration: Motion.releaseMs; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    anchors.margins: -3
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(HL.workspace(key.modelData.id))
                }
            }
        }
    }
}
