// The equalizer: ten bands and a preamp (~/.local/state/apsis/eq.json), applied through EasyEffects.
// Edit: the apply delay here; bands and presets in lib/EqPresets.js.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/EqPresets.js" as P

Singleton {
    id: root

    readonly property bool on: store.data.on
    readonly property real preamp: store.data.preamp
    readonly property var gains: store.data.gains
    readonly property string preset: P.nameOf(gains)
    property string backend: ""

    onBackendChanged: if (backend === "ok" || backend === "nolsp") applyLater.restart()

    function setOn(v) { store.set("on", v); applyLater.restart() }
    function setGain(i, g) {
        store.update(function(d) { d.gains[i] = P.clamp(g); if (d.autoPreamp) d.preamp = P.headroom(d.gains) })
        applyLater.restart()
    }
    function setPreamp(g) { store.update(function(d) { d.preamp = Math.max(-12, Math.min(6, Math.round(g * 2) / 2)); d.autoPreamp = false }); applyLater.restart() }
    function usePreset(name) {
        var p = P.PRESETS[name]
        if (!p) return
        store.update(function(d) { d.gains = p.slice(); d.preamp = P.headroom(p); d.autoPreamp = true; d.on = true })
        applyLater.restart()
    }
    function check() { if (!statusP.running) statusP.running = true }
    function startBackend() {
        Quickshell.execDetached(["sh", "-c", "easyeffects --service-mode >/dev/null 2>&1 || easyeffects --gapplication-service >/dev/null 2>&1"])
        recheck.restart()
    }

    Timer { id: recheck; interval: 2500; onTriggered: { root.check(); applyLater.restart() } }
    Timer {
        id: applyLater
        interval: 250
        onTriggered: {
            if (root.backend === "missing") return
            Quickshell.execDetached([Config.scripts + "/apsis-eq.sh", "apply", root.on ? "on" : "off", String(root.preamp)].concat(root.gains.map(String)))
        }
    }
    Process {
        id: statusP
        command: [Config.scripts + "/apsis-eq.sh", "status"]
        stdout: StdioCollector { onStreamFinished: root.backend = this.text.trim() }
    }

    property JsonStore store: JsonStore {
        path: Config.stateDir + "/eq.json"
        defaults: ({ version: 1, on: false, preamp: 0, autoPreamp: true, gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0] })
    }
}
