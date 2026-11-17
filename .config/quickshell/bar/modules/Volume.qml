// Bar key: volume; click mutes, right click opens Sound, the wheel changes it.
// Edit: the wheel step here; volume keys in hypr/scripts/apsis-volume.sh.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    small: true
    radius: 10
    implicitWidth: row.implicitWidth + 18
    Layout.fillHeight: true
    implicitHeight: 29
    fill: Theme.bgItem
    pressed: pressArea.pressed

    property int  vol: 0
    property bool muted: false

    readonly property string volHigh: "M14,3.23V5.29C16.89,6.15 19,8.83 19,12C19,15.17 16.89,17.84 14,18.7V20.77C18,19.86 21,16.28 21,12C21,7.72 18,4.14 14,3.23M16.5,12C16.5,10.23 15.5,8.71 14,7.97V16C15.5,15.29 16.5,13.76 16.5,12M3,9V15H7L12,20V4L7,9H3Z"
    readonly property string volMed:  "M3,9V15H7L12,20V4L7,9H3M14,7.97V16C15.5,15.29 16.5,13.76 16.5,12C16.5,10.23 15.5,8.71 14,7.97Z"
    readonly property string volOff:  "M12,4L9.91,6.09L12,8.18M4.27,3L3,4.27L7.73,9H3V15H7L12,20V13.27L16.25,17.53C15.58,18.04 14.83,18.46 14,18.7V20.77C15.38,20.45 16.63,19.82 17.68,18.96L19.73,21L21,19.73L12,10.73M19,12C19,12.94 18.8,13.82 18.46,14.64L19.97,16.15C20.62,14.91 21,13.5 21,12C21,7.72 18,4.14 14,3.23V5.29C16.89,6.15 19,8.83 19,12M16.5,12C16.5,10.23 15.5,8.71 14,7.97V10.18L16.45,12.63C16.5,12.43 16.5,12.21 16.5,12Z"

    Poll {
        interval: 1000
        command: ["sh", "-c", "echo \"$(pamixer --get-volume) $(pamixer --get-mute)\""]
        onUpdated: function(out) {
            var p = out.trim().split(" ")
            root.vol = parseInt(p[0]) || 0
            root.muted = (p[1] === "true")
        }
    }

    Process { id: muteProc; command: ["pamixer", "-t"] }
    Process { id: upProc;   command: ["pamixer", "-i", "5"] }
    Process { id: dnProc;   command: ["pamixer", "-d", "5"] }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        VIcon {
            size: 16
            d: (root.muted || root.vol === 0) ? root.volOff
                : (root.vol < 50 ? root.volMed : root.volHigh)
            color: root.muted ? Theme.textSecondary : Theme.accent
        }
        Text {
            text: root.muted ? "muted" : root.vol + "%"
            font.family: Theme.fontText
            font.pixelSize: 12
            color: Theme.textPrimary
        }
    }

    MouseArea {
        id: pressArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: function(m) {
            if (m.button === Qt.RightButton) PhoneState.toggle("sound")
            else muteProc.running = true
        }
        onWheel: function(w) {
            if (w.angleDelta.y > 0) upProc.running = true
            else dnProc.running = true
        }
    }
}
