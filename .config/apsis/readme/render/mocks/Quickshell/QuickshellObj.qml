// Stand-in for the Quickshell singleton: one screen, the demo environment and icons; execDetached only logs.
// Edit: the screen in shot.py (Shot.screen), the environment in shot.py (Shot.env).

pragma Singleton
import QtQuick
import ShotLab
QtObject {
    readonly property var screens: [Shot.screen]
    function execDetached(cmd) { Shot.log("exec " + JSON.stringify(cmd)) }
    function env(name) { return Shot.env(name) }
    function iconPath(name, fallback) { return Shot.iconPath(String(name || ""), typeof fallback === "string" ? fallback : "") }
    readonly property string shellDir: Shot.shellDir
}
