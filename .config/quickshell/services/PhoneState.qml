// The phone's controller: open or closed, which screen, which monitor, a peeking alert.
// Edit: navigation rules in lib/PhoneRoute.js; the look in phone/.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../lib/PhoneRoute.js" as Route

Singleton {
    id: root

    property bool open: false
    property var route: Route.open("quick")
    readonly property string screen: Route.top(route)
    readonly property bool landscape: open && Route.isLandscape(screen)

    property string lastPortrait: "quick"
    onScreenChanged: if (!Route.isLandscape(screen)) lastPortrait = screen

    property string settingsPage: "theme"

    property string monitor: ""

    property var alert: null
    readonly property bool alerting: alert !== null && !open

    function focusedMonitor() {
        var m = Hyprland.focusedMonitor
        return m && m.name ? m.name : ""
    }

    function openOn(name) {
        if (!root.open) root.monitor = focusedMonitor()
        root.route = root.open ? Route.go(root.route, name) : Route.open(name)
        root.alert = null
        root.open = true
    }

    function toggle(name) {
        var t = Route.toggle(root.route, root.open, name)
        if (t.close) { close(); return }
        if (!root.open) root.monitor = focusedMonitor()
        root.route = t.state
        root.alert = null
        root.open = true
    }

    function go(name) {
        if (!root.open) { openOn(name); return }
        root.route = Route.go(root.route, name)
    }

    function back() {
        var b = Route.back(root.route)
        if (b.close) close()
        else root.route = b.state
    }

    function home() { root.route = Route.home(root.route) }

    function close() { root.open = false }

    property string pendingQuery: ""
    function search(text) {
        root.pendingQuery = text || ""
        if (root.open && root.screen === "apps") { root.pendingQueryChanged(); return }
        openOn("apps")
    }

    function openSettings(page) {
        if (page) root.settingsPage = page
        openOn("settings")
    }

    function showAlert(n) {
        if (root.open) return
        if (!root.alert) root.monitor = focusedMonitor()
        root.alert = n
        alertTimer.restart()
    }
    function clearAlert() { root.alert = null }

    property Timer alertTimer: Timer {
        interval: 5000
        onTriggered: root.alert = null
    }
}
