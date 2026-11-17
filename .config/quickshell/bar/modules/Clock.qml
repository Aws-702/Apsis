// Bar key: the time and date; click for the month card.
// Edit: the time and date formats here.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    small: true
    radius: 10
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 29
    fill: Theme.bgItem

    property string timeText: "--:--"
    property string dateText: ""

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            root.timeText = Qt.formatTime(d, "HH:mm")
            root.dateText = Qt.formatDate(d, "ddd d MMM")
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            text: root.dateText
            color: Theme.textSecondary
            font.family: Theme.fontText
            font.pixelSize: 12
        }
        Text {
            text: root.timeText
            color: Theme.textPrimary
            font.family: Theme.fontText
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }

    pressed: clockArea.pressed
    MouseArea {
        id: clockArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleBarPopup("calendar", root.mapToItem(null, root.width / 2, 0).x)
    }
}
