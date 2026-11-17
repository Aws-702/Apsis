// The notification server: block cards top right or a phone peek, with DND and muted apps.
// Edit: card width, timeout and stacking here; the style in Settings > Desktop > Notifications.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../config"
import "../services"
import "../widgets"

Scope {
    id: root

    readonly property bool phoneStyle: Settings.notifyStyle === "phone"
    property var shownAlert: null

    component NotifCard: Pop {
        id: card
        property var notif
        readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
        Layout.fillWidth: true
        Layout.preferredHeight: inner.implicitHeight + 30
        transformOrigin: Item.TopRight
        shown: false
        Component.onCompleted: shown = true

        Timer {
            running: true
            interval: {
                if (!card.notif) return 6000
                if (card.critical) return 0
                var t = card.notif.expireTimeout
                return t > 0 ? t : 6000
            }
            onTriggered: if (interval > 0 && card.notif) card.notif.dismiss()
        }

        Block {
            anchors.fill: parent
            fill: Theme.bgCard
            ring: card.critical ? Theme.danger : Theme.ring
            pressed: ma.pressed

            RowLayout {
                id: inner
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 12
                Block {
                    id: iconBox
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 43
                    Layout.alignment: Qt.AlignTop
                    small: true
                    fill: card.critical ? Theme.danger : Theme.accent
                    ring: Theme.ringActive
                    RoundImage {
                        id: img
                        anchors.fill: parent
                        radius: Math.max(0, iconBox.radius - iconBox.inset)
                        source: card.notif && card.notif.image ? card.notif.image : ""
                        sourceSize.width: 80
                        sourceSize.height: 80
                        visible: status === Image.Ready
                    }
                    Label { anchors.centerIn: parent; visible: img.status !== Image.Ready; color: Theme.onAccent; font.pixelSize: 16; font.weight: Font.Black
                        text: card.notif && card.notif.appName ? card.notif.appName.charAt(0).toUpperCase() : "!" }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label { caps: true; color: Theme.accent; text: card.notif ? card.notif.appName : ""; visible: text.length > 0; Layout.fillWidth: true }
                    Label { text: card.notif ? card.notif.summary : ""; font.pixelSize: 13; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { sub: true; text: card.notif ? card.notif.body : ""; font.pixelSize: 11; wrapMode: Text.WordWrap; visible: text.length > 0; Layout.fillWidth: true; maximumLineCount: 4 }
                }
            }
            MouseArea { id: ma; anchors.fill: parent; onClicked: if (card.notif) card.notif.dismiss() }
        }
    }

    property bool dnd: false
    FileView {
        path: Config.cacheDir + "/apsis-dnd"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root.dnd = (text().trim() === "on")
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: false
        bodySupported: true
        imageSupported: true
        onNotification: function(n) {
            var quiet = (root.dnd || Notifs.isMuted(String(n.appName || "").trim() || "Unknown")) && n.urgency !== NotificationUrgency.Critical
            Notifs.add(n, quiet)
            if (quiet) return
            n.tracked = true
            if (root.phoneStyle) PhoneState.showAlert(n)
        }
    }

    Connections {
        target: PhoneState
        function onAlertChanged() {
            var prev = root.shownAlert
            root.shownAlert = PhoneState.alert
            if (prev && prev !== PhoneState.alert && root.phoneStyle) {
                try { prev.dismiss() } catch (e) {}
            }
        }
    }

    PanelWindow {
        id: win
        visible: !root.phoneStyle && server.trackedNotifications.values.length > 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "apsis-notifications"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors { top: !Settings.barAtBottom; bottom: Settings.barAtBottom; right: true }
        margins.top: Settings.barAtBottom ? 8 : Settings.barSpace + 8
        margins.bottom: Settings.barAtBottom ? Settings.barSpace + 8 : 8
        margins.right: 12
        implicitWidth: 372
        implicitHeight: Math.max(1, col.implicitHeight + 10)
        color: "transparent"

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; rightMargin: 6 }
            spacing: 10
            Repeater {
                model: server.trackedNotifications
                delegate: NotifCard { required property var modelData; notif: modelData }
            }
        }
    }
}
