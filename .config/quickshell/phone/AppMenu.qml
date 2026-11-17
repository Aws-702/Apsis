// The right click menu on an app: Delete, Star, Hide.
// Edit: menu size and labels here; deleting runs hypr/scripts/apsis-uninstall.sh.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    property var app: null
    property bool confirming: false
    readonly property bool open: app !== null

    property var last: null
    onAppChanged: if (app) last = app
    readonly property string appId: last ? String(last.id) : ""
    readonly property string appName: last ? String(last.name || last.id) : ""
    readonly property bool starred: Dock.isPinned(appId)
    readonly property bool hiddenApp: AppList.isHidden(appId)

    function show(e) { confirming = false; app = e }
    function close() { app = null; confirming = false }

    visible: open || !pop.settled

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bgMain, 0.72)
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.popOutMs } }
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: root.close()
        }
    }

    Pop {
        id: pop
        shown: root.open
        anchors.centerIn: parent
        width: parent.width - 40
        height: card.height

        Block {
            id: card
            width: parent.width
            height: col.implicitHeight + 28 + 2 * inset + shadowDy
            fill: Theme.bgCard
            ring: Theme.ringActive

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton }

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Block {
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 58
                        small: true
                        fill: Theme.bgItem
                        Image {
                            id: ic
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            sourceSize.width: 60
                            sourceSize.height: 60
                            asynchronous: true
                            visible: status === Image.Ready
                            source: Icons.app(root.last ? root.last.icon : "")
                        }
                        VIcon { anchors.centerIn: parent; size: 24; d: Icons.apps; color: Theme.textSecondary; visible: ic.status !== Image.Ready }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: root.appName; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { sub: true; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true
                            text: root.last && root.last.genericName ? root.last.genericName : root.appId }
                    }
                }

                RowLayout {
                    visible: !root.confirming
                    Layout.fillWidth: true
                    spacing: 8
                    BlockButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        vertical: true
                        icon: Icons.trash
                        text: "Delete"
                        inkIdle: Theme.danger
                        ring: Theme.alpha(Theme.danger, 0.55)
                        onClicked: root.confirming = true
                    }
                    BlockButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        vertical: true
                        icon: root.starred ? Icons.star : Icons.starOutline
                        text: root.starred ? "Unstar" : "Star"
                        active: root.starred
                        onClicked: { Dock.togglePin(root.appId); root.close() }
                    }
                    BlockButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        vertical: true
                        icon: root.hiddenApp ? Icons.eye : Icons.eyeOff
                        text: root.hiddenApp ? "Unhide" : "Hide"
                        onClicked: {
                            if (root.hiddenApp) AppList.unhide(root.appId)
                            else AppList.hide(root.appId)
                            root.close()
                        }
                    }
                }

                ColumnLayout {
                    visible: root.confirming
                    Layout.fillWidth: true
                    spacing: 10
                    Label { text: "Delete " + root.appName + "?"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Label {
                        sub: true
                        font.pixelSize: 11
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "A terminal opens, shows what gets removed and asks you there. Nothing is removed before that."
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 44; text: "Cancel"; onClicked: root.confirming = false }
                        BlockButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            icon: Icons.trash
                            text: "Delete"
                            active: true
                            fillActive: Theme.danger
                            onClicked: {
                                AppList.uninstall(root.appId)
                                root.close()
                                PhoneState.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
