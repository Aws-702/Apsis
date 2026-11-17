// Desktop widget: CPU, memory and temperature as three meters.
// Edit: meter look here; readings come from services/Sys.qml (apsis-sysinfo.sh).

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    Component.onCompleted: Sys.wantStats++
    Component.onDestruction: Sys.wantStats--

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10
        Repeater {
            model: [
                { k: "CPU", v: Sys.cpu, unit: "%", icon: Icons.memory, hot: Sys.cpu >= 85 },
                { k: "RAM", v: Sys.ram, unit: "%", icon: Icons.layers, hot: Sys.ram >= 85 },
                { k: "TEMP", v: Sys.temp, unit: "°", icon: Icons.thermometer, hot: Sys.temp >= 80 }
            ]
            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    spacing: 4
                    VIcon { size: 13; d: modelData.icon; color: modelData.hot ? Theme.danger : Theme.accent }
                    Label { caps: true; text: modelData.k }
                }
                Label { text: modelData.v + modelData.unit; font.pixelSize: 22; font.weight: Font.Black; color: modelData.hot ? Theme.danger : Theme.textPrimary }
                Block {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    small: true
                    flat: true
                    radius: 6
                    fill: Theme.bgMain
                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        width: Math.max(height, parent.width * Math.min(100, modelData.v) / 100)
                        color: modelData.hot ? Theme.danger : Theme.accent
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
