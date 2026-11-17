// Runs apsis-doctor.sh --tsv for Settings > About and keeps the checks.
// Edit: the checks themselves are in hypr/scripts/apsis-doctor.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property var checks: []
    property bool running: proc.running
    property real ranAt: 0
    readonly property int fails: checks.filter(c => c.status === "fail").length
    readonly property int warns: checks.filter(c => c.status === "warn").length

    readonly property var problems: checks.filter(c => c.status === "fail")
        .concat(checks.filter(c => c.status === "warn"), checks.filter(c => c.status === "info" && c.fix !== ""))
    readonly property int okCount: checks.filter(c => c.status === "ok").length

    function run() { if (!proc.running) proc.running = true }
    function copy(text) { Quickshell.execDetached(["wl-copy", text]) }

    Process {
        id: proc
        command: [Config.scripts + "/apsis-doctor.sh", "--tsv"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split("\t")
                    if (f.length < 2 || !f[0]) continue
                    out.push({ status: f[0], what: f[1] || "", detail: f[2] || "", fix: f[3] || "" })
                }
                root.checks = out
                root.ranAt = Date.now()
            }
        }
    }
}
