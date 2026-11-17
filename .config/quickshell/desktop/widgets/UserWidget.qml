// Desktop widget: your picture, name, machine and uptime.
// Edit: layout here; the picture is widgets/Avatar.qml, the name in Settings > Theme.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    fill: Theme.bgCard

    property string host: ""
    property string up: ""
    Process {
        id: info
        command: ["sh", "-c", "printf '%s\\n' \"$(hostname 2>/dev/null)\"; uptime -p 2>/dev/null | sed 's/^up //'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var l = this.text.split("\n")
                root.host = l[0] || ""
                root.up = l[1] || ""
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: info.running = true }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        Avatar { size: 64 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { text: Settings.userName; font.pixelSize: 18; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            Label { sub: true; text: root.host; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
            Label { sub: true; text: root.up !== "" ? "up " + root.up : ""; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }
}
