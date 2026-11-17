// What the phone's screen shows while a notification peeks up.
// Edit: text sizes and lines here.

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../config"
import "../services"
import "../widgets"

Item {
    id: root
    readonly property var n: PhoneState.alert

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }

    Block {
        anchors { left: parent.left; right: parent.right; top: status.bottom; leftMargin: 16; rightMargin: 16; topMargin: 10 }
        height: 96
        fill: Theme.bgItem
        ring: root.n && root.n.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.ringActive
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12
            Block {
                id: iconBox
                Layout.preferredWidth: 46
                Layout.preferredHeight: 50
                small: true
                fill: Theme.accent
                ring: Theme.ringActive
                RoundImage {
                    id: img
                    anchors.fill: parent
                    radius: Math.max(0, iconBox.radius - iconBox.inset)
                    source: root.n && root.n.image ? root.n.image : (root.n && root.n.appIcon ? root.n.appIcon : "")
                    sourceSize.width: 92
                    sourceSize.height: 92
                    visible: status === Image.Ready
                }
                Label { anchors.centerIn: parent; visible: img.status !== Image.Ready; color: Theme.onAccent; font.pixelSize: 18; font.weight: Font.Black
                    text: root.n && root.n.appName ? root.n.appName.charAt(0).toUpperCase() : "!" }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { caps: true; color: Theme.accent; text: root.n ? root.n.appName : ""; Layout.fillWidth: true }
                Label { text: root.n ? root.n.summary : ""; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Label { sub: true; text: root.n ? root.n.body : ""; font.pixelSize: 11; Layout.fillWidth: true; maximumLineCount: 2; wrapMode: Text.WordWrap }
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: { if (root.n) { try { root.n.dismiss() } catch (e) {} } PhoneState.clearAlert() }
        }
    }
}
