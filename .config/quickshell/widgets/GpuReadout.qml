// The GPU at a glance: memory, a bar, temperature, power, load and which programs hold memory.
// Edit: maxRows and sizes here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    property bool lists: true
    property int maxRows: 5
    property bool big: true
    spacing: 8

    Component.onCompleted: Ultra.want++
    Component.onDestruction: Ultra.want--

    RowLayout {
        Layout.fillWidth: true
        visible: Ultra.hasGpu
        spacing: 6
        Label { text: Ultra.gb(Ultra.used); font.pixelSize: root.big ? 26 : 20; font.weight: Font.Black }
        Label { sub: true; text: "of " + Ultra.gb(Ultra.total) + " GB"; font.pixelSize: root.big ? 13 : 11; Layout.alignment: Qt.AlignBaseline }
        Item { Layout.fillWidth: true }
        Label { sub: true; font.pixelSize: 10; text: Math.round(Ultra.frac * 100) + "%" }
    }
    Rectangle {
        visible: Ultra.hasGpu
        Layout.fillWidth: true
        Layout.preferredHeight: 10
        radius: 5
        color: Theme.bgMain
        Rectangle {
            height: parent.height
            radius: 5
            width: parent.width * Ultra.frac
            color: Ultra.frac > 0.9 ? Theme.danger : Theme.accent
            Behavior on width { NumberAnimation { duration: 300 } }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: Ultra.hasGpu
        spacing: 6
        component Chip: Block {
            id: chip
            property string label: ""
            property string value: ""
            property bool hot: false
            Layout.fillWidth: true
            Layout.preferredHeight: 34 + shadowDy
            small: true
            flat: true
            radius: 8
            fill: hot ? Theme.mix(Theme.bgMain, Theme.danger, 0.3) : Theme.bgMain
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                Label { Layout.alignment: Qt.AlignHCenter; text: chip.value; font.pixelSize: 12; font.weight: Font.DemiBold }
                Label { Layout.alignment: Qt.AlignHCenter; sub: true; text: chip.label; font.pixelSize: 8 }
            }
        }
        Chip { label: "TEMP"; value: Ultra.temp < 0 ? "?" : Math.round(Ultra.temp) + " C"; hot: Ultra.temp >= 85 }
        Chip { label: "POWER"; value: Ultra.watts < 0 ? "?" : Math.round(Ultra.watts) + " W" }
        Chip { label: "LOAD"; value: Ultra.util < 0 ? "?" : Math.round(Ultra.util) + "%" }
    }
    Label { visible: !Ultra.hasGpu; sub: true; wrapMode: Text.WordWrap; Layout.fillWidth: true; text: "No NVIDIA GPU found (nvidia-smi isn't there)." }

    component ProcRow: RowLayout {
        property var p
        Layout.fillWidth: true
        spacing: 8
        Label { text: p.name; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
        Label { sub: true; text: "pid " + p.pid; font.pixelSize: 9 }
        Label { text: p.mb < 0 ? "?" : p.mb + " MB"; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.preferredWidth: 62; horizontalAlignment: Text.AlignRight }
    }
    Label { caps: true; text: "Computing"; visible: root.lists && Ultra.compute.length > 0; Layout.topMargin: 2 }
    Repeater {
        model: root.lists ? Ultra.compute.slice(0, root.maxRows) : []
        ProcRow { required property var modelData; p: modelData }
    }
    Label { caps: true; text: "Drawing"; visible: root.lists && Ultra.graphics.length > 0; Layout.topMargin: 2 }
    Repeater {
        model: root.lists ? Ultra.graphics.slice(0, root.maxRows) : []
        ProcRow { required property var modelData; p: modelData }
    }
    Label {
        visible: root.lists && Ultra.hasGpu && Ultra.compute.length + Ultra.graphics.length === 0
        sub: true
        font.pixelSize: 11
        text: "Nothing holds GPU memory right now."
    }
}
