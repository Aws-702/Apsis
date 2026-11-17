// Bluetooth: the adapter switch, your devices, and new ones nearby to pair.
// Edit: row size and texts here; the pairing card is btagent/BtAgent.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    readonly property bool shown: PhoneState.open && PhoneState.screen === "bluetooth"
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter !== null && adapter.enabled
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var mine: devices.filter(d => d.paired || d.bonded)
            .sort((a, b) => (b.connected - a.connected) || String(a.name).localeCompare(String(b.name)))

    readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && d.name && d.name !== d.address
            && d.name.replace(/-/g, ":") !== d.address)

    onShownChanged: if (adapter && adapter.enabled) adapter.discovering = shown
    onOnChanged: if (on && shown) adapter.discovering = true

    function tap(d) {
        if (d.pairing) { d.cancelPair(); return }
        if (d.paired || d.bonded) {
            if (d.connected) d.disconnect()
            else d.connect()
        } else {
            d.trusted = true
            d.pair()
        }
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Bluetooth"
        sub: !root.adapter ? "No adapter" : (!root.on ? "Off" : (root.adapter.discovering ? "Looking for devices..." : (root.adapter.name || "On")))
        BlockSwitch {
            checked: root.on
            enabled: root.adapter !== null
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: root.on

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 8

            Label { caps: true; text: "My devices"; visible: root.mine.length > 0 }
            Repeater {
                model: root.mine
                DevRow {
                    required property var modelData
                    dev: modelData
                    onTapped: root.tap(modelData)
                    onForget: modelData.forget()
                }
            }

            Label { caps: true; text: "Nearby"; Layout.topMargin: 6 }
            Label { sub: true; visible: root.nearby.length === 0; text: "Nothing new nearby. Put the device in pairing mode." ; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Repeater {
                model: root.nearby
                DevRow {
                    required property var modelData
                    dev: modelData
                    onTapped: root.tap(modelData)
                }
            }

            Label {
                sub: true
                visible: root.mine.length > 0
                Layout.topMargin: 8
                font.pixelSize: 10
                text: "Right click one of your devices to forget it."
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !root.on
        sub: true
        text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter found"
    }

    component DevRow: BlockButton {
        id: row
        property var dev: null
        signal tapped()
        signal forget()

        readonly property bool busy: dev && (dev.pairing || dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting)

        Layout.fillWidth: true
        Layout.preferredHeight: 56
        small: true
        align: Qt.AlignLeft
        active: dev && dev.connected
        onClicked: tapped()
        onRightClicked: forget()

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Image {
                    id: dic
                    anchors.fill: parent
                    sourceSize.width: 44
                    sourceSize.height: 44
                    source: row.dev ? Icons.app(row.dev.icon) : ""
                    visible: status === Image.Ready
                }
                VIcon { anchors.centerIn: parent; size: 18; d: Icons.bluetooth; color: row.ink; visible: dic.status !== Image.Ready }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: row.dev ? (row.dev.name || row.dev.address) : ""
                    color: row.ink
                    font.family: Theme.fontText
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    color: row.inkSub
                    font.family: Theme.fontText
                    font.pixelSize: 10
                    text: {
                        var d = row.dev
                        if (!d) return ""
                        if (d.pairing) return "Pairing...  tap to cancel"
                        if (d.state === BluetoothDeviceState.Connecting) return "Connecting..."
                        if (d.state === BluetoothDeviceState.Disconnecting) return "Disconnecting..."
                        if (d.connected) return "Connected"
                        return (d.paired || d.bonded) ? "Not connected" : "Tap to pair"
                    }
                }
            }
            Text {
                visible: row.dev && row.dev.batteryAvailable
                text: row.dev ? Math.round(row.dev.battery * 100) + "%" : ""
                color: row.ink
                font.family: Theme.fontText
                font.pixelSize: 11
            }
        }
    }
}
