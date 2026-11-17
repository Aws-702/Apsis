// The GPU card for Ultra saver and Training mode: memory, heat, power, load and what holds memory.
// Edit: the readout is widgets/GpuReadout.qml, the keys widgets/TrainKeys.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    implicitWidth: 360
    implicitHeight: col.implicitHeight + 28 + 2 * inset + shadowDy
    fill: Theme.bgCard
    ring: Theme.ringActive

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        Label {
            text: Ultra.training ? "Training mode" : Ultra.on ? "Ultra saver is on" : "GPU"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        GpuReadout { Layout.fillWidth: true; maxRows: 5 }

        TrainKeys { Layout.fillWidth: true; onUsed: UiState.barPopup = "" }
    }
}
