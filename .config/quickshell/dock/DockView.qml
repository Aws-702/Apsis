// The dock's tray: pinned apps, running ones, the Apps key and the card keys.
// Edit: key size, spacing and the running dot here; pins live in services/Dock.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"

Block {
    id: root
    radius: 22
    fill: Theme.bgCard
    implicitWidth: vertical ? 82 : row.implicitWidth + 2 * inset + 24
    implicitHeight: vertical ? row.implicitHeight + 2 * inset + 24 : 82

    property string screenName: ""

    readonly property bool vertical: Settings.dockEdge !== "bottom"

    Component.onCompleted: Sys.wantMedia++
    Component.onDestruction: Sys.wantMedia--

    QtObject { id: blink; property bool on: false }
    Timer { interval: 500; repeat: true; running: Countdown.rang; onTriggered: blink.on = !blink.on; onRunningChanged: if (!running) blink.on = false }

    function iconOf(id) {
        var e = Dock.entry(id)
        return Icons.app(e && e.icon ? e.icon : id)
    }

    GridLayout {
        id: row
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 1000
        rowSpacing: 10
        columnSpacing: 10

        Repeater {
            model: Dock.items
            Item {
                id: slot
                required property var modelData
                Layout.preferredWidth: 54
                Layout.preferredHeight: 62
                readonly property bool focused: {
                    var t = modelData.toplevels || []
                    for (var i = 0; i < t.length; i++) if (t[i].activated) return true
                    return false
                }

                BlockButton {
                    id: key
                    width: 54
                    height: 58
                    fillIdle: slot.focused ? Theme.bgHover : Theme.bgItem
                    ring: slot.focused ? Theme.ringActive : Theme.ring
                    onClicked: Dock.activate(slot.modelData)
                    onRightClicked: Dock.togglePin(slot.modelData.id)
                    Image {
                        id: ic
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        sourceSize.width: 60
                        sourceSize.height: 60
                        asynchronous: true
                        source: root.iconOf(slot.modelData.id)
                        visible: status === Image.Ready
                    }
                    VIcon { anchors.centerIn: parent; size: 24; d: Icons.apps; color: Theme.textSecondary; visible: ic.status !== Image.Ready }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    spacing: 3
                    Repeater {
                        model: Math.min(3, (slot.modelData.toplevels || []).length)
                        Rectangle { width: slot.focused ? 10 : 5; height: 4; radius: 2; color: Theme.accent }
                    }
                }
            }
        }

        Rectangle { Layout.preferredWidth: root.vertical ? 40 : 2; Layout.preferredHeight: root.vertical ? 2 : 40; Layout.alignment: root.vertical ? Qt.AlignHCenter : 0; radius: 1; color: Theme.outline }

        BlockButton {
            Layout.preferredWidth: 54
            Layout.preferredHeight: 58
            Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignTop
            icon: Icons.apps
            iconSize: 22
            active: PhoneState.open && PhoneState.screen === "apps"
            onClicked: PhoneState.toggle("apps")
        }

        Rectangle { visible: Settings.dockCards; Layout.preferredWidth: root.vertical ? 40 : 2; Layout.preferredHeight: root.vertical ? 2 : 40; Layout.alignment: root.vertical ? Qt.AlignHCenter : 0; radius: 1; color: Theme.outline }
        Repeater {
            model: Settings.dockCards ? [
                { id: "media", icon: Icons.music, show: Sys.hasPlayer },
                { id: "timer", icon: Icons.clock, show: true },
                { id: "files", icon: Icons.layers, show: true },
                { id: "clip", icon: Icons.clipboard, show: true },
                { id: "shelf", icon: Icons.boxEmpty, show: true }
            ].filter(function(k) { return k.show }) : []
            BlockButton {
                id: ck
                required property var modelData
                readonly property bool isTimer: modelData.id === "timer"
                readonly property bool isShelf: modelData.id === "shelf"
                Layout.preferredWidth: isTimer && (Countdown.active || Countdown.rang) ? 72 : 46
                Layout.preferredHeight: 58
                Layout.alignment: root.vertical ? Qt.AlignHCenter : Qt.AlignTop
                icon: isTimer && (Countdown.active || Countdown.rang) ? "" : modelData.icon
                iconSize: 19
                text: isTimer && (Countdown.active || Countdown.rang) ? (Countdown.rang ? "0:00" : Countdown.text) : ""
                fontSize: 12
                active: Dock.card === modelData.id || (isTimer && Countdown.rang && blink.on) || drop.containsDrag
                onClicked: { if (isTimer) Countdown.seen(); Dock.toggleCard(modelData.id, root.screenName) }

                RoundImage {
                    visible: ck.modelData.id === "media" && status === Image.Ready
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 8
                    source: ck.modelData.id === "media" ? Sys.artUrl : ""
                    sourceSize.width: 80
                    sourceSize.height: 80
                }

                Block {
                    visible: ck.isShelf && Shelf.items.length > 0
                    anchors { right: parent.right; top: parent.top; margins: -4 }
                    width: 20; height: 20; radius: 10
                    small: true; flat: true
                    fill: Theme.accent
                    Label { anchors.centerIn: parent; text: Shelf.items.length; font.pixelSize: 9; font.weight: Font.Black; color: Theme.onAccent }
                }
                DropArea {
                    id: drop
                    anchors.fill: parent
                    enabled: ck.isShelf
                    keys: ["text/uri-list"]
                    onDropped: function(d) { Shelf.add(d.urls); d.acceptProposedAction() }
                }
            }
        }
    }
}
