// Keeps apps outside the shell in the palette: writes apsis-theme.json, runs apsis-systheme.sh.
// Edit: what gets themed in Settings > Desktop > Other apps, or in hypr/scripts/apsis-systheme.sh.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
    id: root

    function hex(c) {
        function h(v) { var s = Math.round(v * 255).toString(16); return s.length < 2 ? "0" + s : s }
        return "#" + h(c.r) + h(c.g) + h(c.b)
    }

    readonly property var colors: ({
        bgMain: hex(Theme.bgMain), bgCard: hex(Theme.bgCard), bgItem: hex(Theme.bgItem), bgHover: hex(Theme.bgHover),
        textPrimary: hex(Theme.textPrimary), textSecondary: hex(Theme.textSecondary),
        accent: hex(Theme.accent), accentHot: hex(Theme.accentHot), cyan: hex(Theme.cyan),
        warn: hex(Theme.warn), danger: hex(Theme.danger), onAccent: hex(Theme.onAccent),
        light: Theme.light
    })
    readonly property bool any: Settings.data.sysThemeQt !== false || Settings.data.sysThemeKde !== false || Settings.data.sysThemeTerminal !== false

    function start() { settle.restart() }

    onColorsChanged: settle.restart()
    onAnyChanged: settle.restart()
    Connections {
        target: Settings
        function onReadyChanged() { settle.restart() }
    }

    Timer { id: settle; interval: 1200; onTriggered: root.write() }

    function write() {
        if (Config.ultra || !any || !Settings.ready) return
        writer.command = ["sh", "-c",
            "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$1/apsis-theme.json\" && exec \"$3\"",
            "sh", Config.cacheDir, JSON.stringify(colors), Config.scripts + "/apsis-systheme.sh"]
        writer.running = true
    }
    Process { id: writer }
}
