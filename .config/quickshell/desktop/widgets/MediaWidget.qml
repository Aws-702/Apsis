// Desktop widget: now playing, the same card as on the phone.
// Edit: the card itself is phone/MediaCard.qml; the placeholder text is here.

import QtQuick
import "../../config"
import "../../services"
import "../../widgets"
import "../../phone"

Item {
    id: root
    property var widget: ({})
    property bool editing: false

    Component.onCompleted: Sys.wantMedia++
    Component.onDestruction: Sys.wantMedia--

    MediaCard {
        anchors.fill: parent
        visible: Sys.hasPlayer
        fill: Theme.bgCard
        enabled: !root.editing
    }
    Block {
        anchors.fill: parent
        visible: !Sys.hasPlayer
        fill: Theme.bgCard
        Row {
            anchors.centerIn: parent
            spacing: 10
            VIcon { anchors.verticalCenter: parent.verticalCenter; size: 22; d: Icons.music; color: Theme.textSecondary }
            Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Nothing playing" }
        }
    }
}
