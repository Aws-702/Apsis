// Stand-in for Quickshell.Hyprland: workspaces, monitors and windows from demo.json; dispatch does nothing.
// Edit: the windows in demo.json (toplevels).

pragma Singleton
import QtQuick
import ShotLab
QtObject {
    function om(a) { var r = []; for (var i = 0; a && i < a.length; i++) r.push(a[i]); return { values: r } }
    readonly property var focusedMonitor: ({ name: Shot.screen.name, activeWorkspace: { id: 1 } })
    readonly property var focusedWorkspace: ({ id: 1, name: "1" })
    readonly property var workspaces: ([{ id: 1, name: "1", active: true, focused: true }, { id: 2, name: "2", active: false }, { id: 3, name: "3", active: false }, { id: 4, name: "4", active: false }])
    readonly property var toplevels: om(Shot.toplevels())
    readonly property var monitors: om([focusedMonitor])
    signal rawEvent(var event)
    function dispatch(cmd) { Shot.log("dispatch " + cmd) }
    function refreshToplevels() {}
    function refreshWorkspaces() {}
    function refreshMonitors() {}
}
