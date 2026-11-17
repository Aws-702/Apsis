// Sound: output and input devices, their volumes and every app's own volume.
// Edit: row size here; EasyEffects' nodes are filtered by lib/AudioNodes.js.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../config"
import "../services"
import "../widgets"
import "../lib/AudioNodes.js" as AN

Item {
    id: root

    readonly property var nodes: Pipewire.nodes.values

    readonly property var outputs: AN.outputs(nodes)
    readonly property var inputs: AN.inputs(nodes)

    readonly property var apps: AN.apps(nodes)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool eeOn: AN.eeRunning(nodes)

    readonly property bool eeLoop: AN.isEeSink(sink)

    PwObjectTracker { objects: root.outputs.concat(root.inputs, root.apps) }

    function label(n) { return n ? (n.description || n.nickname || n.name || "") : "" }
    function prop(n, k) { var p = n && n.properties ? n.properties : {}; return p[k] || "" }
    function appName(n) { return prop(n, "application.name") || label(n) }
    function appIcon(n) {
        return Icons.app(prop(n, "application.icon-name") || prop(n, "application.process.binary") || appName(n).toLowerCase())
    }
    function pct(n) { return n && n.audio ? Math.round(n.audio.volume * 100) : 0 }
    function setPct(n, v) { if (n && n.audio) n.audio.volume = Math.max(0, Math.min(1.5, v / 100)) }
    function volIcon(n) {
        if (!n || !n.audio || n.audio.muted || n.audio.volume === 0) return Icons.volOff
        return n.audio.volume < 0.5 ? Icons.volMed : Icons.volHigh
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Sound"
        sub: root.eeLoop ? "No real output picked" : (root.eeOn ? "Easy Effects  /  " : "") + root.label(root.sink)
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 9

            BlockButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                align: Qt.AlignLeft
                icon: Icons.tune
                iconSize: 17
                text: "Equalizer"
                subText: Eq.on ? Eq.preset : "Off"
                onClicked: PhoneState.go("eq")
                VIcon { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; size: 16; d: Icons.chevronRight; color: Theme.textSecondary }
            }

            Label { caps: true; text: "Output"; Layout.topMargin: 4 }
            BlockSlider {
                Layout.fillWidth: true
                enabled: root.sink !== null
                icon: root.volIcon(root.sink)
                value: root.pct(root.sink)
                onMoved: function(v) { root.setPct(root.sink, v) }
                onReleased: function(v) { root.setPct(root.sink, v) }
                onIconClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
            }
            Block {
                Layout.fillWidth: true
                Layout.preferredHeight: loopCol.implicitHeight + 22
                visible: root.eeLoop
                small: true
                fill: Theme.mix(Theme.bgItem, Theme.accent, 0.18)
                ColumnLayout {
                    id: loopCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11 }
                    spacing: 8
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        text: "Easy Effects Sink is set as the output, so it plays into itself. Easy Effects picks up every app on its own: pick your speakers or headphones instead."
                    }
                    BlockButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        small: true
                        visible: root.outputs.length > 0
                        active: true
                        fontSize: 11
                        text: root.outputs.length ? "Use " + root.label(root.outputs[0]) : ""
                        onClicked: Pipewire.preferredDefaultAudioSink = root.outputs[0]
                    }
                }
            }
            Repeater {
                model: root.outputs
                DeviceKey {
                    required property var modelData
                    node: modelData
                    current: root.sink === modelData
                    onPicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }

            Label { caps: true; text: "Input"; Layout.topMargin: 6; visible: root.inputs.length > 0 }
            BlockSlider {
                Layout.fillWidth: true
                visible: root.source !== null
                icon: root.source && root.source.audio && root.source.audio.muted ? Icons.micOff : Icons.mic
                value: root.pct(root.source)
                onMoved: function(v) { root.setPct(root.source, v) }
                onReleased: function(v) { root.setPct(root.source, v) }
                onIconClicked: if (root.source && root.source.audio) root.source.audio.muted = !root.source.audio.muted
            }
            Repeater {
                model: root.inputs.length > 1 ? root.inputs : []
                DeviceKey {
                    required property var modelData
                    node: modelData
                    current: root.source === modelData
                    onPicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }

            Label { caps: true; text: "Apps"; Layout.topMargin: 6 }
            Label { sub: true; visible: root.apps.length === 0; text: "Nothing is playing"; Layout.bottomMargin: 4 }
            Repeater {
                model: root.apps
                Block {
                    id: appRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    small: true
                    fill: Theme.bgItem
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Item {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                Image {
                                    id: aic
                                    anchors.fill: parent
                                    sourceSize.width: 40
                                    sourceSize.height: 40
                                    source: root.appIcon(appRow.modelData)
                                    visible: status === Image.Ready
                                }
                                VIcon { anchors.centerIn: parent; size: 16; d: Icons.music; color: Theme.textSecondary; visible: aic.status !== Image.Ready }
                            }
                            Label { text: root.appName(appRow.modelData); font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { sub: true; text: root.prop(appRow.modelData, "media.name"); font.pixelSize: 10; elide: Text.ElideRight; Layout.maximumWidth: 150 }
                        }
                        BlockSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            icon: root.volIcon(appRow.modelData)
                            value: root.pct(appRow.modelData)
                            onMoved: function(v) { root.setPct(appRow.modelData, v) }
                            onReleased: function(v) { root.setPct(appRow.modelData, v) }
                            onIconClicked: appRow.modelData.audio.muted = !appRow.modelData.audio.muted
                        }
                    }
                }
            }
        }
    }

    component DeviceKey: BlockButton {
        property var node: null
        property bool current: false
        signal picked()
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        small: true
        align: Qt.AlignLeft
        icon: current ? Icons.check : ""
        iconSize: 14
        text: node ? (node.description || node.nickname || node.name || "") : ""
        fontSize: 11
        active: current
        onClicked: if (!current) picked()
    }
}
