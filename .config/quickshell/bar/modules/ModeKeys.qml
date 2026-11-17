// Bar keys for Game and Focus mode, only while one is on; click to turn it off.
// Edit: labels and colours here; the modes in apsis-game.sh and apsis-focus.sh.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

RowLayout {
    spacing: 6
    Repeater {
        model: [
            { name: "GAME", on: Sys.game, script: "apsis-game.sh" },
            { name: "FOCUS", on: Sys.focus, script: "apsis-focus.sh" }
        ]
        Block {
            required property var modelData
            small: true
            radius: 10
            Layout.fillHeight: true
            implicitHeight: 29
            visible: modelData.on
            implicitWidth: visible ? label.implicitWidth + 18 : 0
            fill: Theme.accent
            ring: Theme.ringActive
            pressed: ma.pressed
            Label { id: label; anchors.centerIn: parent; text: modelData.name; font.pixelSize: 10; font.weight: Font.Black; color: Theme.onAccent }
            MouseArea {
                id: ma
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sys.script(modelData.script, "off")
            }
        }
    }
}
