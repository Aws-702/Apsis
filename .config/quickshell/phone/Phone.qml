// The phone's window: which monitor, which layer, keyboard focus and where input is taken.
// Edit: what it draws is phone/PhoneView.qml.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"

PanelWindow {
    id: win

    readonly property var targetScreen: {
        var all = Quickshell.screens
        for (var i = 0; i < all.length; i++)
            if (all[i].name === PhoneState.monitor) return all[i]
        return all.length ? all[0] : null
    }
    screen: targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-phone"

    WlrLayershell.keyboardFocus: PhoneState.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: !view.away

    mask: PhoneState.open ? null : peekRegion
    Region { id: peekRegion; item: view.hitBox }

    PhoneView {
        id: view
        width: win.targetScreen ? win.targetScreen.width : 1920
        height: win.targetScreen ? win.targetScreen.height : 1080
    }

    function grabKeys() { if (PhoneState.open && PhoneState.screen !== "apps") view.forceActiveFocus() }
    onVisibleChanged: Qt.callLater(grabKeys)
    Connections {
        target: PhoneState
        function onOpenChanged() { Qt.callLater(win.grabKeys) }
        function onScreenChanged() { Qt.callLater(win.grabKeys) }
    }

    component Nudge: FileView {
        id: nf
        property string screenName: "quick"
        property bool primed: false
        property string lastSeen: ""
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            var t = text().trim()
            if (t === "" || t === lastSeen) return
            lastSeen = t
            if (!primed) return
            PhoneState.toggle(nf.screenName)
        }

        property Timer primer: Timer { interval: 1200; running: true; onTriggered: nf.primed = true }
    }
    Nudge { path: Config.cacheDir + "/apsis-centre"; screenName: "quick" }
    Nudge { path: Config.cacheDir + "/apsis-launcher"; screenName: "apps" }
}
