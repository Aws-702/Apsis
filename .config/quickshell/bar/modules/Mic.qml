// Bar key: microphone muted or live; click toggles it.
// Edit: icon and size here.

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
    implicitWidth: 34
    Layout.fillHeight: true
    implicitHeight: 29
    fill: Theme.bgItem
    pressed: pressArea.pressed

    property bool muted: true

    readonly property string micOn:  "M12,2A3,3 0 0,1 15,5V11A3,3 0 0,1 9,11V5A3,3 0 0,1 12,2M19,11C19,14.53 16.39,17.44 13,17.93V21H11V17.93C7.61,17.44 5,14.53 5,11H7A5,5 0 0,0 12,16A5,5 0 0,0 17,11H19Z"
    readonly property string micOff: "M19,11C19,12.19 18.66,13.3 18.1,14.28L16.87,13.05C17.14,12.43 17.3,11.74 17.3,11H19M15,11.16L9,5.18V5A3,3 0 0,1 12,2A3,3 0 0,1 15,5V11L15,11.16M4.27,3L21,19.73L19.73,21L15.54,16.81C14.77,17.27 13.91,17.58 13,17.72V21H11V17.72C7.72,17.23 5,14.41 5,11H6.7C6.7,14 9.24,16.1 12,16.1C12.81,16.1 13.6,15.91 14.31,15.58L12.65,13.92L12,14A3,3 0 0,1 9,11V10.28L4.27,3Z"

    Poll {
        interval: 1000
        command: ["sh", "-c", "pamixer --default-source --get-mute 2>/dev/null"]
        onUpdated: function(out) { root.muted = (out.trim() === "true") }
    }

    Process { id: micToggle; command: ["pamixer", "--default-source", "-t"] }

    VIcon {
        anchors.centerIn: parent
        size: 16
        d: root.muted ? root.micOff : root.micOn
        color: root.muted ? Theme.danger : Theme.accent
    }

    MouseArea {
        id: pressArea
        anchors.fill: parent
        onClicked: micToggle.running = true
    }
}
