// The popup for volume, brightness and mic, driven by files the key scripts write.
// Edit: size, position and hold time here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apsis-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0
    implicitHeight: 150
    color: "transparent"
    visible: pop.visible
    mask: Region {}

    property string kind: "volume"
    property int value: 0
    property bool muted: false
    property bool _ready: false

    function iconPath() {
        if (kind === "mic") return muted ? Icons.micOff : Icons.mic
        if (kind === "brightness") return Icons.sun
        if (muted || value === 0) return Icons.volOff
        return value < 50 ? Icons.volMed : Icons.volHigh
    }
    readonly property color tone: (kind === "mic" && muted) ? Theme.danger : Theme.accent
    readonly property bool showBar: kind !== "mic"

    function show() { pop.shown = true; hideTimer.restart() }

    Timer { interval: 600; running: true; onTriggered: root._ready = true }
    Timer { id: hideTimer; interval: 1700; onTriggered: pop.shown = false }

    component Feed: FileView {
        property string kindName
        property var host
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            if (!host || !host._ready) return
            var p = text().trim().split(/\s+/)
            if (!p[0]) return
            host.kind = kindName
            if (kindName === "mic") { host.muted = p[0] === "true" }
            else { host.value = parseInt(p[0]) || 0; host.muted = kindName === "volume" && p[1] === "true" }
            host.show()
        }
    }
    Feed { host: root; kindName: "volume"; path: Config.cacheDir + "/apsis-osd-volume" }
    Feed { host: root; kindName: "brightness"; path: Config.cacheDir + "/apsis-osd-brightness" }
    Feed { host: root; kindName: "mic"; path: Config.cacheDir + "/apsis-osd-mic" }

    Pop {
        id: pop
        width: 320
        height: 70
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56
        transformOrigin: Item.Bottom

        Block {
            anchors.fill: parent
            fill: Theme.bgCard
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 16
                spacing: 14
                Block {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 46
                    small: true
                    fill: root.tone
                    ring: Theme.ringActive
                    VIcon { anchors.centerIn: parent; size: 22; d: root.iconPath(); color: Theme.onAccent }
                }
                Block {
                    visible: root.showBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    small: true
                    flat: true
                    radius: 9
                    fill: Theme.bgMain
                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        width: Math.max(height, parent.width * Math.min(100, Math.max(0, root.value)) / 100)
                        color: root.tone
                        Behavior on width { NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }
                    }
                }
                Label {
                    text: root.kind === "mic" ? (root.muted ? "Microphone muted" : "Microphone on") : root.value + "%"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    Layout.fillWidth: !root.showBar
                    Layout.preferredWidth: root.showBar ? 44 : -1
                    horizontalAlignment: root.showBar ? Text.AlignRight : Text.AlignLeft
                }
            }
        }
    }
}
