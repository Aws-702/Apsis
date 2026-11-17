// Ultra saver and Training mode state, and the GPU readings from nvidia-smi.
// Edit: the reading interval here; what the modes switch off in apsis-ultra.sh and apsis-train.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/Gpu.js" as G

Singleton {
    id: root

    readonly property bool on: Config.ultra
    property int want: 0
    property int used: -1
    property int total: -1
    property real temp: -1
    property real watts: -1
    property real util: -1
    property var compute: []
    property var graphics: []
    readonly property var apps: compute
    readonly property bool hasGpu: total > 0
    readonly property real frac: G.frac({ used: used, total: total })

    property bool training: false
    property bool sessionAlive: false
    property real trainSince: 0

    function toggle() { Quickshell.execDetached([Config.scripts + "/apsis-ultra.sh", "toggle"]) }
    function train() { Quickshell.execDetached([Config.scripts + "/apsis-train.sh", "toggle"]) }
    function attach() { Quickshell.execDetached([Config.scripts + "/apsis-train.sh", "attach"]) }
    function gb(mb) { return G.gb(mb) }

    Process {
        id: smi
        command: ["sh", "-c", "command -v nvidia-smi >/dev/null || exit 0; "
            + "nvidia-smi --query-gpu=memory.used,memory.total,temperature.gpu,power.draw,utilization.gpu --format=csv,noheader,nounits | head -1; "
            + "echo ---; nvidia-smi 2>/dev/null | sed -n '/Processes:/,$p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.split("---")
                var s = G.stats(parts[0])
                root.used = s.used; root.total = s.total
                root.temp = s.temp; root.watts = s.watts; root.util = s.util
                var p = G.procs(parts[1] || "")
                root.compute = G.compute(p)
                root.graphics = G.graphics(p)
            }
        }
    }
    Process {
        id: trainP
        command: [Config.scripts + "/apsis-train.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.trim().split("\t")
                root.training = f[0] === "on"
                root.sessionAlive = f[1] === "yes"
                root.trainSince = (parseInt(f[2]) || 0) * 1000
            }
        }
    }
    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: root.on || root.want > 0
        onTriggered: {
            if (!smi.running) smi.running = true
            if (!trainP.running) trainP.running = true
        }
    }
    Component.onCompleted: trainP.running = true
}
