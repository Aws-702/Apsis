// Stand-in for Process: answers each command with its demo output from demo.json instead of running it.
// Edit: outputs in demo.json (commands); which commands stay running in shot.py (keepsRunning).

import QtQuick
import ShotLab
QtObject {
    id: p
    property var command: []
    property bool running: false
    property bool stdinEnabled: false
    property var environment: ({})
    property string workingDirectory: ""
    property QtObject stdout: null
    property QtObject stderr: null
    readonly property int processId: running ? 4242 : 0
    signal started()
    signal exited(int exitCode, int exitStatus)
    function write(data) { Shot.log("stdin " + String(data).trim()) }
    function signal(sig) {}
    function startDetached() {}
    function exec(cmd) { if (cmd !== undefined && cmd !== null) command = cmd; running = false; running = true }
    function _deliver() {
        if (!p.running) return
        var out = Shot.output(p.command)
        if (p.stdout) {
            if (p.stdout.read !== undefined && p.stdout.splitMarker !== undefined) {
                var lines = out.split("\n")
                for (var i = 0; i < lines.length; i++) if (lines[i] !== "" || i < lines.length - 1) p.stdout.read(lines[i])
            } else {
                p.stdout.text = out
                p.stdout.streamFinished()
            }
        }
        if (Shot.keepsRunning(p.command)) return
        p.running = false
        p.exited(0, 0)
    }
    onRunningChanged: if (running) { started(); Qt.callLater(_deliver) }
    Component.onCompleted: if (running) Qt.callLater(_deliver)
}
