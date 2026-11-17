// Which apps have the microphone, a camera or the screen right now.
// Edit: row look here.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    implicitWidth: 280
    implicitHeight: col.implicitHeight + 28 + 2 * inset + shadowDy
    fill: Theme.bgCard
    ring: Theme.danger

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10
        Label { text: "In use right now"; font.pixelSize: 14; font.weight: Font.DemiBold }
        Repeater {
            model: [
                { icon: Icons.mic, label: "Microphone", apps: UiState.privacyMic },
                { icon: Icons.camera, label: "Camera or screen", apps: UiState.privacyVideo }
            ].filter(function(g) { return g.apps.length > 0 })
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 10
                Block {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 38
                    small: true
                    fill: Theme.mix(Theme.bgCard, Theme.danger, 0.22)
                    ring: Theme.danger
                    VIcon { anchors.centerIn: parent; size: 17; d: modelData.icon; color: Theme.danger }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { text: modelData.label; font.pixelSize: 12; font.weight: Font.DemiBold }
                    Label { sub: true; text: modelData.apps.join(", "); font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }
        }
        Label {
            visible: UiState.privacyMic.length === 0 && UiState.privacyVideo.length === 0
            sub: true
            text: "Nothing is recording."
        }
    }
}
