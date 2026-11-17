// Bar keys for the system tray icons of running apps.
// Edit: icon size and spacing here.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../../config"

RowLayout {
    id: root
    spacing: 8

    Repeater {
        model: SystemTray.items

        delegate: Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 18
            implicitHeight: 18

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: modelData.icon
                sourceSize.width: 32
                sourceSize.height: 32
                smooth: true
                asynchronous: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.LeftButton) modelData.activate()
                    else modelData.secondaryActivate()
                }
            }
        }
    }
}
