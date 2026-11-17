// Settings > Display: resolution, rate, scale, rotation, mirroring, tried with a 15 second keep.
// Edit: rows here; the countdown and applying in hypr/scripts/apsis-display.sh.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/Display.js" as D

ColumnLayout {
    id: root
    spacing: 12

    property bool active: false
    property var monitors: []
    property string open: ""

    property var trial: null
    property int secondsLeft: 0

    onActiveChanged: if (active) refresh(); else if (trial) revert()
    Component.onCompleted: if (active) refresh()

    function script(args) { Quickshell.execDetached([Config.scripts + "/apsis-display.sh"].concat(args)) }
    function refresh() { if (!monGet.running) monGet.running = true }

    function tryLayout(mon, change) {
        if (trial) return
        var prev = D.current(mon)
        var next = Object.assign({}, prev, change)
        root.trial = { name: mon.name, prev: prev, next: next }
        script(["try"].concat(D.args(mon.name, next), D.args(mon.name, prev).slice(1)))
        root.secondsLeft = 15
        countdown.restart()
        later.restart()
    }
    function keep() {
        if (!trial) return
        script(["keep"].concat(D.args(trial.name, trial.next)))
        root.trial = null
        countdown.stop()
        later.restart()
    }
    function revert() {
        if (!trial) return
        script(["revert"])
        root.trial = null
        countdown.stop()
        later.restart()
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true

        onTriggered: { root.secondsLeft--; if (root.secondsLeft <= 0) { root.trial = null; stop(); later.restart() } }
    }
    Timer { id: later; interval: 600; onTriggered: root.refresh() }

    Process {
        id: monGet
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(this.text) } catch (e) { root.monitors = [] }
                if (root.open === "" && root.monitors.length) root.open = root.monitors[0].name
            }
        }
    }

    Block {
        Layout.fillWidth: true
        Layout.preferredHeight: 58
        visible: root.trial !== null
        small: true
        fill: Theme.mix(Theme.bgItem, Theme.accent, 0.2)
        ring: Theme.ringActive
        RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
            spacing: 8
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label { text: "Keep this?"; font.pixelSize: 13; font.weight: Font.DemiBold }
                Label { sub: true; font.pixelSize: 10; text: "Going back in " + root.secondsLeft + " s" }
            }
            BlockButton { Layout.preferredWidth: 90; Layout.preferredHeight: 38; small: true; fontSize: 11; text: "Go back"; onClicked: root.revert() }
            BlockButton { Layout.preferredWidth: 80; Layout.preferredHeight: 38; small: true; fontSize: 11; text: "Keep"; active: true; onClicked: root.keep() }
        }
    }

    Repeater {
        model: root.monitors
        Block {
            id: card
            required property var modelData
            readonly property var mon: modelData
            readonly property bool off: mon.disabled === true
            readonly property bool expanded: root.open === mon.name
            readonly property var modes: D.modes(mon.availableModes)
            readonly property string res: mon.width + "x" + mon.height
            readonly property var resInfo: modes.filter(m => m.res === res)[0] || { rates: [] }
            readonly property var others: root.monitors.filter(m => m.name !== mon.name && !m.disabled).map(m => m.name)
            readonly property bool mirroring: mon.mirrorOf && mon.mirrorOf !== "none"
            Layout.fillWidth: true
            Layout.preferredHeight: inner.implicitHeight + 26
            small: true
            fill: Theme.bgItem
            ring: expanded ? Theme.ringActive : Theme.ring

            ColumnLayout {
                id: inner
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13 }
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    VIcon { size: 18; d: Icons.display; color: card.off ? Theme.textSecondary : Theme.accent }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label { text: card.mon.name; font.pixelSize: 14; font.weight: Font.DemiBold }
                        Label {
                            sub: true
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: card.off ? "Off" : card.res + " @ " + Math.round(card.mon.refreshRate) + " Hz  /  " + D.scaleText(card.mon.scale) + (card.mirroring ? "  /  mirrors " + card.mon.mirrorOf : "")
                        }
                    }
                    BlockSwitch {
                        checked: !card.off
                        enabled: root.trial === null && (card.off || root.monitors.filter(m => !m.disabled).length > 1)
                        onToggled: {
                            if (card.off) root.script(["keep", card.mon.name, "preferred", "auto", "1", "0", "-"])
                            else root.script(["off", card.mon.name])
                            later.restart()
                        }
                    }
                    BlockButton {
                        visible: !card.off
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 34
                        small: true
                        icon: Icons.chevronRight
                        iconSize: 14
                        rotation: card.expanded ? 90 : 0
                        onClicked: root.open = card.expanded ? "" : card.mon.name
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: card.expanded && !card.off
                    spacing: 8

                    component Choice: BlockButton {
                        property bool current: false
                        small: true
                        height: 32
                        width: Math.max(64, implicitWidth + 4)
                        fontSize: 10
                        active: current
                        enabled: root.trial === null
                    }

                    Label { caps: true; text: "Resolution" }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: card.modes.slice(0, 8)
                            Choice {
                                required property var modelData
                                text: modelData.res.replace("x", " x ")
                                current: modelData.res === card.res
                                onClicked: if (!current) root.tryLayout(card.mon, { mode: D.mode(modelData.res, D.nearest(modelData.rates, card.mon.refreshRate)) })
                            }
                        }
                    }

                    Label { caps: true; text: "Refresh rate"; visible: card.resInfo.rates.length > 1 }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: card.resInfo.rates.length > 1
                        Repeater {
                            model: card.resInfo.rates
                            Choice {
                                required property real modelData
                                text: Math.round(modelData) + " Hz"
                                current: Math.abs(modelData - card.mon.refreshRate) < 0.6
                                onClicked: if (!current) root.tryLayout(card.mon, { mode: D.mode(card.res, modelData) })
                            }
                        }
                    }

                    Label { caps: true; text: "Scale" }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: D.scales(card.mon.width, card.mon.height)
                            Choice {
                                required property real modelData
                                text: D.scaleText(modelData)
                                current: Math.abs(modelData - card.mon.scale) < 0.01
                                onClicked: if (!current) root.tryLayout(card.mon, { scale: D.scaleArg(modelData) })
                            }
                        }
                    }

                    Label { caps: true; text: "Rotation" }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [{ t: 0, l: "Normal" }, { t: 1, l: "90" }, { t: 2, l: "180" }, { t: 3, l: "270" }]
                            Choice {
                                required property var modelData
                                text: modelData.l
                                current: (card.mon.transform || 0) === modelData.t
                                onClicked: if (!current) root.tryLayout(card.mon, { transform: String(modelData.t) })
                            }
                        }
                    }

                    Label { caps: true; text: "Show"; visible: card.others.length > 0 }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: card.others.length > 0
                        Choice {
                            text: "Its own picture"
                            current: !card.mirroring
                            onClicked: if (!current) root.tryLayout(card.mon, { mirror: "-", pos: "auto" })
                        }
                        Repeater {
                            model: card.others
                            Choice {
                                required property string modelData
                                text: "Same as " + modelData
                                current: card.mon.mirrorOf === modelData
                                onClicked: if (!current) root.tryLayout(card.mon, { mirror: modelData })
                            }
                        }
                    }
                }
            }
        }
    }
    Label { visible: root.monitors.length === 0; sub: true; text: "No monitors reported by hyprctl" }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            small: true
            fontSize: 11
            text: "Back to hyprland.lua"
            enabled: root.trial === null
            onClicked: { root.script(["reset"]); later.restart() }
        }
        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            small: true
            fontSize: 11
            text: "Arrange (nwg-displays)"
            onClicked: { Quickshell.execDetached(["sh", "-c", "command -v nwg-displays >/dev/null && exec nwg-displays"]); PhoneState.close() }
        }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 10
        text: "Kept layouts are saved in ~/.local/state/apsis/monitors.lua and come back at every login. \"Back to hyprland.lua\" forgets them." }
}
