// Screen recording state, followed from ~/.cache/quickshell/apsis-record (apsis-record.sh).
// Edit: recording options are in hypr/scripts/apsis-record.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property bool on: false
    property real since: 0
    property string file: ""
    property real now: Date.now()
    readonly property string elapsed: {
        var s = Math.max(0, Math.floor((now - since) / 1000))
        var m = Math.floor(s / 60)
        return (m < 10 ? "0" : "") + m + ":" + (s % 60 < 10 ? "0" : "") + (s % 60)
    }

    function start(what) {
        PhoneState.close()
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; exec \"$0\" start \"$1\"", Config.scripts + "/apsis-record.sh", what || "screen"])
    }
    function stop() { Quickshell.execDetached([Config.scripts + "/apsis-record.sh", "stop"]) }

    FileView {
        path: Config.cacheDir + "/apsis-record"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            var f = text().trim().split("\t")
            root.on = f.length >= 3 && f[0] !== ""
            root.since = root.on ? (parseInt(f[1]) || 0) * 1000 : 0
            root.file = root.on ? f[2] : ""
        }
        onLoadFailed: { root.on = false; root.since = 0; root.file = "" }
    }
    Timer { interval: 1000; repeat: true; running: root.on; triggeredOnStart: true; onTriggered: root.now = Date.now() }
}
