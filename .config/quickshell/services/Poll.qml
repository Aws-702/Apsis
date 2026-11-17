// Runs a command every interval ms while active and hands out its output.
// Edit: interval for the default rate.

import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property var command: []
    property int interval: 3000
    property bool active: true
    signal updated(string out)

    function now() { if (root.command.length > 0 && !root.proc.running) root.proc.exec(root.command) }

    property Process proc: Process {
        stdout: StdioCollector {
            onStreamFinished: root.updated(this.text)
        }
    }

    property Timer timer: Timer {
        interval: Math.max(250, root.interval)
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now()
    }
}
