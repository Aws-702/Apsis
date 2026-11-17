// Desktop widget: the music as 32 bands from cava, in six looks (blocks, bars, mirror, dots, peaks, ring).
// Edit: each look's drawing here; band count and smoothing in services/Cava.qml; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

Block {
    id: root
    property var widget: ({})
    property bool editing: false
    readonly property string look: (widget.style && widget.style.look) || "blocks"
    readonly property var looks: ["blocks", "bars", "mirror", "dots", "peaks", "ring"]
    readonly property var v: Cava.values
    readonly property bool live: v.length > 0

    fill: Theme.bgCard

    Component.onCompleted: { Cava.want++; Sys.wantMedia++ }
    Component.onDestruction: { Cava.want--; Sys.wantMedia-- }

    function level(i) { return i < v.length ? v[i] : 0 }

    Item {
        id: stage
        anchors.fill: parent
        anchors.margins: 14
        anchors.bottomMargin: root.editing ? 44 : 14

        Item {
            id: ringBox
            visible: root.look === "ring"
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height)
            height: width
            Repeater {
                model: root.look === "ring" ? Cava.bars : 0
                Item {
                    id: spoke
                    required property int index
                    readonly property real lv: root.level(index)
                    anchors.centerIn: parent
                    width: 1
                    height: 1
                    rotation: index / Cava.bars * 360
                    Rectangle {
                        width: Math.max(3, ringBox.width * 0.05)
                        height: ringBox.width * 0.1 + spoke.lv * ringBox.width * 0.38
                        radius: width / 2
                        x: -width / 2
                        y: -(ringBox.width * 0.1 + height)
                        color: Theme.mix(Theme.accent, Theme.accentHot, spoke.index / (Cava.bars - 1))
                    }
                }
            }
        }

        Row {
            id: bands
            visible: root.look !== "ring"
            anchors.fill: parent
            spacing: 3
            readonly property real bw: (width - (Cava.bars - 1) * spacing) / Cava.bars
            Repeater {
                model: Cava.bars
                Item {
                    id: band
                    required property int index
                    readonly property real lv: root.level(index)
                    width: bands.bw
                    height: bands.height
                    readonly property color tone: Theme.mix(Theme.accent, Theme.accentHot, index / (Cava.bars - 1))

                    Column {
                        visible: root.look === "blocks"
                        anchors.bottom: parent.bottom
                        width: parent.width
                        spacing: 2
                        readonly property int cells: Math.max(4, Math.floor((band.height + 2) / (band.width + 2)))
                        Repeater {
                            model: parent.cells
                            Rectangle {
                                required property int index
                                readonly property int fromBottom: parent.cells - 1 - index
                                width: band.width
                                height: band.width
                                radius: Math.min(4, width / 3)
                                color: fromBottom < Math.round(band.lv * parent.cells) || fromBottom === 0
                                       ? band.tone : Theme.mix(Theme.bgCard, Theme.bgMain, 0.6)
                            }
                        }
                    }

                    Rectangle {
                        visible: root.look === "dots"
                        width: parent.width
                        height: parent.width
                        radius: width / 2
                        y: (parent.height - height) * (1 - band.lv)
                        color: band.tone
                    }

                    Rectangle {
                        visible: root.look === "peaks"
                        width: Math.max(2, parent.width * 0.55)
                        x: (parent.width - width) / 2
                        radius: width / 2
                        height: Math.max(width, band.lv * parent.height)
                        y: parent.height - height
                        color: band.tone
                    }
                    Rectangle {
                        id: cap
                        visible: root.look === "peaks"
                        width: parent.width
                        height: 3
                        radius: 1.5
                        color: Theme.textPrimary

                        property real peak: 0
                        y: (parent.height - height) * (1 - peak)
                    }
                    Timer {
                        interval: 50
                        running: root.look === "peaks" && root.live
                        repeat: true
                        onTriggered: cap.peak = Math.max(band.lv, cap.peak - 0.02)
                    }

                    Rectangle {
                        visible: root.look === "bars" || root.look === "mirror"
                        width: parent.width
                        radius: Math.min(4, width / 2)
                        height: Math.max(width, (root.look === "mirror" ? 0.5 : 1) * band.lv * parent.height)
                        y: root.look === "mirror" ? (parent.height - height) / 2 : parent.height - height
                        color: band.tone
                    }
                    Rectangle {
                        visible: root.look === "mirror"
                        width: parent.width
                        radius: Math.min(4, width / 2)
                        height: Math.max(width, 0.5 * band.lv * parent.height)
                        y: parent.height / 2
                        color: Theme.alpha(band.tone, 0.45)
                    }
                }
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.live
        sub: true
        text: Sys.hasPlayer ? (Sys.playing ? "Listening..." : "Paused") : "Play something"
    }

    BlockButton {
        visible: root.editing
        small: true
        width: 74
        height: 28
        x: 10
        y: root.keyHeight - 38
        text: root.look
        fontSize: 10
        onClicked: {
            var i = root.looks.indexOf(root.look)
            Desktop.setStyle(root.widget.id, "look", root.looks[(i + 1) % root.looks.length])
        }
    }
}
