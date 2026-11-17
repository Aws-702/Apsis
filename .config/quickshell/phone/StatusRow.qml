// The phone's status bar: time, the updates box, the notch, network and battery.
// Edit: sizes and the time format here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"

Item {
    id: root
    implicitHeight: 28
    property bool wide: false

    property string time: Qt.formatTime(new Date(), "HH:mm")
    Timer { interval: 5000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: root.time = Qt.formatTime(new Date(), "HH:mm") }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.wide ? 6 : 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7
        Label {
            text: root.time
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Block {
            visible: Updates.badge > 0
            Layout.preferredWidth: upd.implicitWidth + 12
            Layout.preferredHeight: 20 + shadowDy
            small: true
            flat: true
            radius: 7
            fill: Updates.qtRisk ? Theme.mix(Theme.bgItem, Theme.warn, 0.25) : Theme.bgItem
            ring: Updates.qtRisk ? Theme.warn : (updMa.containsMouse ? Theme.ringActive : Theme.ring)
            pressed: updMa.pressed
            RowLayout {
                id: upd
                anchors.centerIn: parent
                spacing: 4
                VIcon { size: 12; d: Icons.box; color: Updates.qtRisk ? Theme.warn : Theme.accent }
                Label { text: Updates.badge; font.pixelSize: 11; font.weight: Font.DemiBold }
            }
            MouseArea {
                id: updMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: PhoneState.go("updates")
            }
        }
    }
    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: root.wide ? 6 : 22
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        VIcon { size: 14; d: Sys.wifiOn ? Icons.wifi : Icons.wifiOff; color: Sys.wifiOn ? Theme.textPrimary : Theme.textSecondary }
        VIcon { size: 14; visible: Sys.btOn; d: Icons.bluetooth; color: Theme.textPrimary }
        Label {
            visible: Sys.battery >= 0
            text: Sys.battery + "%" + (Sys.charging ? "+" : "")
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Sys.battery <= 15 && !Sys.charging ? Theme.danger : Theme.textPrimary
        }
    }
}
