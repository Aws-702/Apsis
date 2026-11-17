// Bar key: cover, title and artist of what's playing; clicks and the wheel control it.
// Edit: max width and cover size here.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    small: true
    radius: 10
    Layout.fillHeight: true
    implicitHeight: 29
    visible: Sys.hasPlayer && Sys.title !== ""
    implicitWidth: visible ? Math.min(280, row.implicitWidth + 14) : 0
    fill: Theme.bgItem
    pressed: ma.pressed

    Component.onCompleted: Sys.wantMedia++
    Component.onDestruction: Sys.wantMedia--

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        width: Math.min(implicitWidth, 266)
        spacing: 8
        opacity: Sys.playing ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }

        Item {
            Layout.preferredWidth: 21
            Layout.preferredHeight: 21
            RoundImage {
                id: art
                anchors.fill: parent
                radius: 6
                source: Sys.artUrl
                sourceSize.width: 42
                sourceSize.height: 42
                asynchronous: true
                visible: status === Image.Ready
            }
            VIcon { anchors.centerIn: parent; size: 14; d: Sys.playing ? Icons.pause : Icons.play; color: Theme.accent; visible: art.status !== Image.Ready }
        }
        Label {
            text: Sys.title
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.maximumWidth: 150
        }
        Label {
            visible: Sys.artist !== ""
            sub: true
            text: Sys.artist
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.maximumWidth: 90
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(m) {
            if (m.button === Qt.RightButton) Sys.media("next")
            else if (m.button === Qt.MiddleButton) Sys.media("previous")
            else Sys.media("play-pause")
        }
        onWheel: function(w) {
            var dy = w.angleDelta.y !== 0 ? w.angleDelta.y : w.pixelDelta.y
            if (dy > 0) Sys.media("next")
            else if (dy < 0) Sys.media("previous")
        }
    }
}
