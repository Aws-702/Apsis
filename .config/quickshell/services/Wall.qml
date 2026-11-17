// The current wallpaper and its engine (apsis draws it with transitions, or awww).
// Edit: setting a wallpaper is hypr/scripts/apsis-wall.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    property string path: ""
    property string engine: "apsis"

    readonly property bool video: /\.(mp4|webm|mkv|mov|avi|gif)$/i.test(path)
    readonly property bool drawn: engine === "apsis" && path !== "" && !video

    readonly property var styles: ["fade", "bloom", "keys", "stripe", "slide", "pixel", "blinds", "ripple"]
    function pickMode() {
        var s = Settings.wallTransition

        if (s === "random") return 1 + Math.floor(Math.random() * (styles.length - 1))
        return Math.max(0, styles.indexOf(s))
    }

    function setEngine(e) {
        if (e !== "apsis" && e !== "awww") return
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf %s \"$2\" > \"$1/apsis-wall-engine\"", "sh", Config.cacheDir, e])
        root.engine = e
    }

    FileView {
        path: Config.cacheDir + "/apsis-wallpaper"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            var t = text().trim()
            if (t.length) root.path = t
        }
    }
    FileView {
        path: Config.cacheDir + "/apsis-wall-engine"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            var t = text().trim()
            if (t === "apsis" || t === "awww") root.engine = t
        }
    }
}
