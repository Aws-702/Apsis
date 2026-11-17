// Audio levels for the visualizers: one cava, running only while one shows and music plays.
// Edit: bars for the band count; cava's own settings in ~/.config/apsis/cava/apsis.conf.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property int want: 0
    property var values: []
    readonly property bool running: proc.running
    readonly property int bars: 32

    Process {
        id: proc
        running: root.want > 0 && Sys.hasPlayer && Sys.playing && !(LockState.locked && Settings.lockSleep)
        command: ["cava", "-p", Config.home + "/.config/apsis/cava/apsis.conf"]
        stdout: SplitParser {
            onRead: function(line) {
                var p = line.split(";")
                var out = []
                for (var i = 0; i < p.length; i++) if (p[i] !== "") out.push(Math.min(1, (parseInt(p[i]) || 0) / 1000))
                root.values = out
            }
        }
        onRunningChanged: if (!running) root.values = []
    }
}
