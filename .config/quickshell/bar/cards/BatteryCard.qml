// The battery card: charge, time left, health, power profile and a gauge that forecasts levels.
// Edit: card layout here; the maths in lib/BatteryMath.js.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/BatteryMath.js" as BM

Block {
    id: root

    implicitWidth: 340
    implicitHeight: col.implicitHeight + 28 + 2 * inset + shadowDy
    fill: Theme.bgCard
    ring: Theme.ringActive

    property int pct: -1
    property string status: ""
    property real now: 0
    property real full: 0
    property real design: 0
    property real rate: 0
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool low: pct >= 0 && pct <= 15 && !charging
    readonly property int minsLeft: BM.minutesLeft(now, full, rate, status === "Charging")
    readonly property int health: BM.health(full, design)
    property int hoverSeg: -1

    Component.onCompleted: Sys.wantRadios++
    Component.onDestruction: Sys.wantRadios--

    Poll {
        interval: 5000
        command: ["sh", "-c", "b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -z \"$b\" ] && exit; for f in capacity status energy_now energy_full energy_full_design power_now charge_now charge_full charge_full_design current_now; do printf '%s ' \"$(cat $b/$f 2>/dev/null || echo -)\"; done"]
        onUpdated: function(out) {
            var p = out.trim().split(/\s+/)
            if (p.length < 10) { root.pct = -1; return }
            function n(v) { var x = parseFloat(v); return isNaN(x) ? 0 : x }
            root.pct = parseInt(p[0])
            root.status = p[1]
            var energy = p[2] !== "-"
            root.now = n(energy ? p[2] : p[6])
            root.full = n(energy ? p[3] : p[7])
            root.design = n(energy ? p[4] : p[8])
            root.rate = n(energy ? p[5] : p[9])
        }
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 12

        Label { visible: root.pct < 0; sub: true; text: "No battery found" }

        RowLayout {
            visible: root.pct >= 0
            Layout.fillWidth: true
            spacing: 12
            Label {
                text: root.pct + "%"
                font.pixelSize: 38
                font.weight: Font.Black
                color: root.low ? Theme.danger : Theme.textPrimary
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: root.status === "Charging" ? "Charging" : root.status === "Full" ? "Full" : root.status === "Not charging" ? "Plugged in" : BM.word(root.pct, false)
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: root.charging ? Theme.accent : (root.low ? Theme.danger : Theme.textPrimary)
                }
                Label {
                    sub: true
                    font.pixelSize: 11
                    text: root.minsLeft < 0 ? (root.charging ? "Plugged in" : "Working out the time...")
                          : BM.fmt(root.minsLeft) + (root.status === "Charging" ? " to full" : " left")
                }
            }
        }

        ColumnLayout {
            visible: root.pct >= 0
            Layout.fillWidth: true
            spacing: 6
            Row {
                id: gauge
                Layout.fillWidth: true
                spacing: 4
                readonly property real seg: (width - 9 * spacing) / 10
                Repeater {
                    model: 10
                    Block {
                        id: seg
                        required property int index
                        readonly property bool lit: root.pct > index * 10
                        readonly property bool hot: root.hoverSeg >= 0 && (root.charging ? index <= root.hoverSeg && !lit : index > root.hoverSeg && lit)
                        width: gauge.seg
                        height: 30
                        small: true
                        radius: 7
                        fill: hot ? Theme.mix(Theme.bgMain, Theme.accent, 0.4) : (lit ? (root.low ? Theme.danger : Theme.accent) : Theme.bgMain)
                        ring: root.hoverSeg === index ? Theme.ringActive : Theme.ring
                        pressed: root.hoverSeg === index
                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) root.hoverSeg = seg.index
                                else if (root.hoverSeg === seg.index) root.hoverSeg = -1
                            }
                        }
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                sub: true
                font.pixelSize: 11
                text: {
                    if (root.hoverSeg < 0) return root.health >= 0 ? "Health " + root.health + "% of when it was new" : " "
                    var target = (root.hoverSeg + 1) * 10
                    var m = BM.minutesTo(target, root.pct, root.full, root.rate, root.status === "Charging")
                    if (m < 0) return target + "%: not where it's heading"
                    return target + "% in about " + BM.fmt(m) + " at this pace"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: ["Quiet", "Balanced", "Performance"]
                BlockButton {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    small: true
                    text: modelData
                    fontSize: 11
                    active: Sys.profile === modelData.toLowerCase()
                    onClicked: Sys.setProfile(modelData)
                }
            }
        }
    }
}
