//@ pragma IconTheme Papirus-Dark

// Apsis shell entry: loads every layer (bar, phone, desktop, dock, lock, overview, polkit,
// pairing card...) in its own loader, starts polkit-gnome as a fallback, and answers qs ipc calls.
// Edit: add or drop a layer here; new `qs ipc call` targets go in the IpcHandler blocks.

import QtQuick
import Quickshell
import Quickshell.Io
import "config"
import "services"
import "bar"
import "osd"
import "panel"
import "phone"
import "notifications"
import "desktop"
import "dock"
import "lock"

ShellRoot {
    Component.onCompleted: SysTheme.start()

    LazyLoader { active: !Config.ultra && !(LockState.locked && Settings.lockSleep); DesktopLayer {} }
    Bar {}
    LazyLoader { active: !Config.ultra; DockBar {} }
    Osd {}
    Notifications {}
    Phone {}
    EditOverlay {}
    PowerMenu {}
    Lock {}

    LazyLoader { id: overview; active: true; source: Qt.resolvedUrl("overview/Overview.qml") }
    LazyLoader { id: cheats; active: true; source: Qt.resolvedUrl("overview/CheatSheet.qml") }
    LazyLoader { id: wheel; active: true; source: Qt.resolvedUrl("wallpaper/WallWheel.qml") }

    LazyLoader { id: polkit; active: true; source: Qt.resolvedUrl("polkit/PolkitAuth.qml") }
    Timer {
        interval: 4000
        running: true
        onTriggered: {
            if (polkit.item && polkit.item.registered) return
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\"; printf fallback > \"$HOME/.cache/quickshell/apsis-polkit\"; "
                + "pgrep -f polkit-gnome-authentication-agent >/dev/null || pgrep -f polkit-kde-authentication-agent >/dev/null || pgrep -x hyprpolkitagent >/dev/null || "
                + "setsid -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1"])
        }
    }

    LazyLoader { id: btagent; active: true; source: Qt.resolvedUrl("btagent/BtAgent.qml") }

    IpcHandler {
        target: "phone"
        function toggle(screen: string): void { PhoneState.toggle(screen) }
        function open(screen: string): void {
            if (screen === "settings") PhoneState.openSettings("")
            else PhoneState.openOn(screen)
        }
        function close(): void { PhoneState.close() }

        function search(text: string): void { PhoneState.search(text) }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { PhoneState.close(); if (overview.item) overview.item.toggle() }
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { if (cheats.item) cheats.item.toggle() }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { PhoneState.close(); if (wheel.item) wheel.item.toggle() }
    }

    IpcHandler {
        target: "edit"
        function toggle(): void { if (Config.ultra) return; PhoneState.close(); EditMode.toggle() }
    }

    IpcHandler {
        target: "dock"
        function toggle(): void { Dock.toggle() }
    }

    IpcHandler {
        target: "modes"
        function game(): void { Sys.script("apsis-game.sh", "toggle") }
        function focus(): void { Sys.script("apsis-focus.sh", "toggle") }
    }

    IpcHandler {
        target: "ultra"
        function toggle(): void { Ultra.toggle() }

        function train(): void { Ultra.train() }
    }

    IpcHandler {
        target: "power"
        function open(): void { UiState.powerMenuOpen = true }
    }
}
