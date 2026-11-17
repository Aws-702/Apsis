// Now playing: cover, title, artist, progress and transport keys.
// Edit: cover size and key sizes here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"

Block {
    id: root
    fill: Theme.bgItem

    function fmt(s) {
        if (!s || s < 0) return "0:00"
        var m = Math.floor(s / 60), ss = Math.floor(s % 60)
        return m + ":" + (ss < 10 ? "0" + ss : ss)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 12

        Block {
            id: artBox
            Layout.fillHeight: true
            Layout.preferredWidth: height - shadowDy
            small: true
            radius: 10
            fill: Theme.bgHover
            RoundImage {
                id: art
                anchors.fill: parent
                radius: Math.max(0, artBox.radius - artBox.inset)
                source: Sys.artUrl
                sourceSize.width: 144
                sourceSize.height: 144
                asynchronous: true
                visible: status === Image.Ready
            }
            VIcon { anchors.centerIn: parent; size: 28; d: Icons.music; color: Theme.textSecondary; visible: art.status !== Image.Ready }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1
            Label { text: Sys.title || "Unknown"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
            Label { sub: true; text: Sys.artist; visible: text !== ""; Layout.fillWidth: true }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                height: 5
                radius: 3
                color: Theme.bgMain
                Rectangle {
                    width: parent.width * Sys.progress
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Label { sub: true; font.pixelSize: 9; text: root.fmt(Sys.position) }
                Item { Layout.fillWidth: true }
                BlockButton { small: true; Layout.preferredWidth: 32; Layout.preferredHeight: 27; icon: Icons.prev; iconSize: 14; onClicked: Sys.media("previous") }
                BlockButton { small: true; Layout.preferredWidth: 38; Layout.preferredHeight: 27; icon: Sys.playing ? Icons.pause : Icons.play; iconSize: 15; active: true; onClicked: Sys.media("play-pause") }
                BlockButton { small: true; Layout.preferredWidth: 32; Layout.preferredHeight: 27; icon: Icons.next; iconSize: 14; onClicked: Sys.media("next") }
                Item { Layout.fillWidth: true }
                Label { sub: true; font.pixelSize: 9; text: root.fmt(Sys.length) }
            }
        }
    }
}
