// Bar key: Wi-Fi strength or cable; click for the phone's Wi-Fi screen.
// Edit: icon size here; widgets/SignalBars.qml and CableIcon.qml draw them.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    small: true
    radius: 10
    implicitWidth: 34
    Layout.fillHeight: true
    implicitHeight: 29
    fill: Theme.bgItem
    pressed: pressArea.pressed

    property string kind: "none"

    Poll {
        interval: 4000
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE device 2>/dev/null | grep ':connected' | grep -E 'wifi|ethernet' | head -1 | cut -d: -f1"]
        onUpdated: function(out) {
            var k = out.trim()
            root.kind = (k === "wifi" || k === "ethernet") ? k : "none"
        }
    }

    Item {
        anchors.centerIn: parent
        width: 18; height: 18
        WifiIcon { anchors.centerIn: parent; size: 16; color: root.kind === "none" ? Theme.textSecondary : Theme.accent; visible: root.kind !== "ethernet" }
        CableIcon { anchors.centerIn: parent; size: 16; color: Theme.accent; visible: root.kind === "ethernet" }
        Rectangle { visible: root.kind === "none"; anchors.centerIn: parent; width: 24; height: 2.2; radius: 1.1; rotation: 45; color: Theme.danger }
    }

    MouseArea {
        id: pressArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: PhoneState.toggle("wifi")
    }
}
