// Bar key: ULTRA or TRAIN with GPU memory in use, only while those modes are on.
// Edit: label and look here; the card is bar/cards/GpuCard.qml.

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
    visible: Ultra.on
    implicitWidth: visible ? row.implicitWidth + 18 : 0
    fill: Theme.accent
    ring: Theme.ringActive
    pressed: ma.pressed

    function gb(mb) { return (mb / 1024).toFixed(1) }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Label { text: Ultra.training ? "TRAIN" : "ULTRA"; font.pixelSize: 10; font.weight: Font.Black; color: Theme.onAccent }
        Label {
            visible: Ultra.hasGpu
            text: root.gb(Ultra.used) + " / " + root.gb(Ultra.total) + " GB"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: Theme.onAccent
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleBarPopup("gpu", root.mapToItem(null, root.width / 2, 0).x)
    }
}
