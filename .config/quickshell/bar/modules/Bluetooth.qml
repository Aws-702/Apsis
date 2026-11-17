// Bar key: Bluetooth on or off; click for the phone's Bluetooth screen.
// Edit: icon and size here; icons in services/Icons.qml.

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

    property bool powered: false
    property bool connected: false

    readonly property string btOn:  "M14.88,16.29L13,18.17V14.41M13,5.83L14.88,7.71L13,9.58M17.71,7.71L12,2H11V9.58L6.41,5L5,6.41L10.59,12L5,17.58L6.41,19L11,14.41V22H12L17.71,16.29L13.41,12L17.71,7.71Z"
    readonly property string btOff: "M13,5.83L14.88,7.71L13.4,9.19L14.81,10.6L17.71,7.71L12,2H11V6.61L13,8.61M5.41,4L4,5.41L10.59,12L5,17.58L6.41,19L11,14.41V22H12L15.3,18.7L18.59,22L20,20.59L5.41,4M13,18.17V14.41L14.88,16.29L13,18.17Z"

    Poll {
        interval: 4000
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && printf on || printf off; printf ' '; bluetoothctl devices Connected 2>/dev/null | grep -q . && printf conn || printf none"]
        onUpdated: function(out) {
            var p = out.trim().split(/\s+/)
            root.powered = (p[0] === "on")
            root.connected = (p[1] === "conn")
        }
    }

    VIcon {
        anchors.centerIn: parent
        size: 16
        d: root.powered ? root.btOn : root.btOff
        color: root.connected ? Theme.accent : Theme.textSecondary
    }

    MouseArea {
        id: pressArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: PhoneState.toggle("bluetooth")
    }
}
