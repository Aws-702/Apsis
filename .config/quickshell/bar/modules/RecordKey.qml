// Bar key: a red dot and the time while recording; click to stop and save.
// Edit: the look here; recording in hypr/scripts/apsis-record.sh.

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
    visible: Record.on
    implicitWidth: visible ? row.implicitWidth + 18 : 0
    fill: Theme.mix(Theme.bgItem, Theme.danger, 0.3)
    ring: Theme.danger
    pressed: ma.pressed

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Rectangle {
            width: 9; height: 9; radius: 4.5
            color: Theme.danger
            SequentialAnimation on opacity {
                running: Record.on
                loops: Animation.Infinite
                NumberAnimation { to: 0.25; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
        Label { text: Record.elapsed; font.pixelSize: 12; font.weight: Font.DemiBold }
        VIcon { size: 12; d: Icons.stop; color: Theme.textPrimary }
    }
    MouseArea { id: ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Record.stop() }
}
