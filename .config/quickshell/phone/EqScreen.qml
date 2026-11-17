// The equalizer screen: ten bands, a preamp and starting curves.
// Edit: slider sizes here; curves in lib/EqPresets.js.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"
import "../lib/EqPresets.js" as P

Item {
    id: root
    readonly property bool shown: PhoneState.open && PhoneState.screen === "eq"
    onShownChanged: if (shown) Eq.check()

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Equalizer"
        sub: Eq.backend === "missing" ? "Needs EasyEffects" : Eq.backend === "nolsp" ? "Needs LSP plugins" : (Eq.on ? Eq.preset : "Off")
        BlockSwitch { checked: Eq.on; enabled: Eq.backend !== "missing" && Eq.backend !== "nolsp"; onToggled: Eq.setOn(!Eq.on) }
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        spacing: 12

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: note.implicitHeight + 34
            visible: Eq.backend === "missing" || Eq.backend === "notrunning" || Eq.backend === "nolsp"
            small: true
            fill: Theme.bgItem
            ring: Theme.warn
            ColumnLayout {
                id: note
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                spacing: 8
                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    font.pixelSize: 11
                    text: Eq.backend === "missing"
                          ? "The equalizer works through EasyEffects. Install it (sudo pacman -S easyeffects), then come back."
                          : Eq.backend === "nolsp"
                          ? "EasyEffects' equalizer needs the LSP plugins (sudo pacman -S lsp-plugins-lv2). Until then Apsis keeps EasyEffects empty so your sound still plays."
                          : "EasyEffects isn't running, so changes won't be heard yet."
                }
                BlockButton {
                    visible: Eq.backend === "notrunning" || Eq.backend === "nolsp"
                    Layout.preferredWidth: 150
                    Layout.preferredHeight: 34
                    small: true
                    text: Eq.backend === "nolsp" ? "Check again" : "Start EasyEffects"
                    fontSize: 11
                    active: true
                    onClicked: Eq.backend === "nolsp" ? Eq.check() : Eq.startBackend()
                }
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: P.ORDER
                BlockButton {
                    required property string modelData
                    width: implicitW
                    readonly property real implicitW: modelData.length * 7 + 26
                    height: 32
                    small: true
                    text: modelData
                    fontSize: 10
                    active: Eq.on && Eq.preset === modelData
                    onClicked: Eq.usePreset(modelData)
                }
            }
        }

        Block {
            Layout.fillWidth: true
            Layout.fillHeight: true
            fill: Theme.bgItem
            opacity: Eq.on ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: Motion.quickMs } }

            Label { x: 10; y: 8; sub: true; font.pixelSize: 9; text: "+12" }
            Label { x: 10; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; sub: true; font.pixelSize: 9; text: "-12" }

            Row {
                id: bands
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 30; rightMargin: 8; topMargin: 14; bottomMargin: 6 }
                readonly property real colW: width / 10
                Repeater {
                    model: 10
                    Item {
                        id: col
                        required property int index
                        width: bands.colW
                        height: bands.height
                        BlockVSlider {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.min(24, col.width - 6)
                            height: parent.height - 22
                            value: Eq.gains[col.index] || 0
                            onMoved: function(v) { if (!Eq.on) Eq.setOn(true); Eq.setGain(col.index, v) }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            sub: true
                            font.pixelSize: 9
                            text: P.label(P.FREQS[col.index])
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Label { text: "Preamp"; font.pixelSize: 11 }
            BlockSlider {
                id: pre
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                readonly property real db: Math.round((shown / 100 * 18 - 12) * 2) / 2
                valueText: (db > 0 ? "+" : "") + db.toFixed(1)

                value: (Eq.preamp + 12) / 18 * 100
                onMoved: function(v) { Eq.setPreamp(v / 100 * 18 - 12) }
                onReleased: function(v) { Eq.setPreamp(v / 100 * 18 - 12) }
            }
        }
    }
}
