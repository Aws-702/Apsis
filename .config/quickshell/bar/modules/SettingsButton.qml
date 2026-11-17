// Bar key that opens the phone: left click quick panel, right click settings.
// Edit: icon and size here.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../services"
import "../../widgets"

BlockButton {
    id: root
    small: true
    radius: 10
    implicitWidth: 34
    implicitHeight: 29
    Layout.fillHeight: true
    icon: Icons.gear
    iconSize: 15
    active: PhoneState.open
    onClicked: PhoneState.toggle("quick")
    onRightClicked: PhoneState.openSettings("")
}
