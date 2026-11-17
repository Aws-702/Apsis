// Bar key: CPU, memory and temperature.
// Edit: which readings show here; they come from hypr/scripts/apsis-sysinfo.sh.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../widgets"
import "../../services"

Block {
    id: root
    small: true
    radius: 10
    Layout.fillHeight: true
    implicitHeight: 29
    implicitWidth: row.implicitWidth + 20
    fill: Theme.bgItem

    property int cpu: 0
    property int ram: 0
    property int temp: 0

    Poll {
        interval: 3000
        command: ["sh", "-c", "$HOME/.config/hypr/scripts/apsis-sysinfo.sh"]
        onUpdated: function(out) {
            var p = out.trim().split(/\s+/)
            root.cpu  = parseInt(p[0]) || 0
            root.ram  = parseInt(p[1]) || 0
            root.temp = parseInt(p[2]) || 0
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Row {
            spacing: 3
            Text { text: "CPU"; color: Theme.textSecondary; font.family: Theme.fontText; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            Text { text: root.cpu + "%"; color: Theme.textPrimary; font.family: Theme.fontText; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            spacing: 3
            Text { text: "RAM"; color: Theme.textSecondary; font.family: Theme.fontText; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            Text { text: root.ram + "%"; color: Theme.textPrimary; font.family: Theme.fontText; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
        }
        Text {
            text: root.temp + "°"
            color: root.temp >= 80 ? Theme.danger : Theme.textPrimary
            font.family: Theme.fontText
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
