// Notifications by app, newest first, with DND and muting.
// Edit: row look here; history rules in services/Notifs.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    readonly property bool shown: PhoneState.open && PhoneState.screen === "notifications"
    onShownChanged: Notifs.markSeen()
    property var expanded: ({})

    function minutesToMorning() {
        var now = new Date()
        var t = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 8, 0, 0)
        if (t <= now) t.setDate(t.getDate() + 1)
        return Math.ceil((t - now) / 60000)
    }
    function dndText() {
        if (!Sys.dnd) return "Off"
        if (Notifs.dndUntil > 0) return "On until " + Qt.formatTime(new Date(Notifs.dndUntil), "HH:mm")
        return "On until you turn it off"
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Notifications"
        sub: Notifs.entries.length === 0 ? "Nothing yet" : Notifs.entries.length + " this session"
        BlockButton {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 40
            small: true
            visible: Notifs.entries.length > 0
            icon: Icons.trash
            iconSize: 15
            onClicked: Notifs.clearAll()
        }
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

            Block {
                id: dndBlock
                Layout.fillWidth: true
                Layout.preferredHeight: dndCol.implicitHeight + 24
                small: true
                fill: Sys.dnd ? Theme.mix(Theme.bgItem, Theme.accent, 0.16) : Theme.bgItem
                ColumnLayout {
                    id: dndCol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 9
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        VIcon { size: 16; d: Icons.bellOff; color: Sys.dnd ? Theme.accent : Theme.textSecondary }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { Layout.fillWidth: true; text: "Do not disturb"; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Label { Layout.fillWidth: true; sub: true; text: root.dndText(); font.pixelSize: 10 }
                        }
                        BlockSwitch { checked: Sys.dnd; onToggled: Sys.dnd ? Notifs.dndOff() : Notifs.dndFor(0) }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        component For: BlockButton {
                            property int minutes: 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            small: true
                            fontSize: 10
                            onClicked: Notifs.dndFor(minutes)
                        }
                        For { text: "1 hour"; minutes: 60 }
                        For { text: "Until 8:00"; minutes: root.minutesToMorning() }
                        For { text: "Until off"; minutes: 0; active: Sys.dnd && Notifs.dndUntil === 0 }
                    }
                    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 10
                        text: "While it's on, notifications come here quietly. Critical ones (a low battery) still show." }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(160, flick.height - dndBlock.height - col.spacing - 20)
                visible: Notifs.entries.length === 0
                Column {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 8
                    VIcon { anchors.horizontalCenter: parent.horizontalCenter; size: 36; d: Icons.bellOff; color: Theme.textSecondary }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "No notifications"; font.pixelSize: 13; font.weight: Font.DemiBold }
                    Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; sub: true; font.pixelSize: 10; text: "They stay here until you log out." }
                }
            }

            Repeater {
                model: Notifs.groups
                ColumnLayout {
                    id: grp
                    required property var modelData
                    readonly property bool muted: Notifs.isMuted(modelData.app)
                    readonly property bool open: root.expanded[modelData.app] === true
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Image {
                                id: gic
                                anchors.fill: parent
                                sourceSize.width: 36
                                sourceSize.height: 36
                                source: Icons.app(grp.modelData.icon || grp.modelData.app.toLowerCase())
                                visible: status === Image.Ready
                            }
                            Label { anchors.centerIn: parent; visible: gic.status !== Image.Ready; text: grp.modelData.app.charAt(0).toUpperCase(); font.pixelSize: 12; font.weight: Font.Black; color: Theme.accent }
                        }
                        Label { caps: true; text: grp.modelData.app; elide: Text.ElideRight; Layout.fillWidth: true }
                        Label { sub: true; font.pixelSize: 10; text: grp.muted ? "muted" : grp.modelData.items.length }
                        BlockButton { Layout.preferredWidth: 32; Layout.preferredHeight: 28; small: true; icon: Icons.bellOff; iconSize: 12; active: grp.muted; onClicked: Notifs.toggleMute(grp.modelData.app) }
                        BlockButton { Layout.preferredWidth: 32; Layout.preferredHeight: 28; small: true; icon: Icons.trash; iconSize: 12; onClicked: Notifs.clearApp(grp.modelData.app) }
                    }
                    Repeater {
                        model: grp.open ? grp.modelData.items : grp.modelData.items.slice(0, 3)
                        Block {
                            id: item
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: itemCol.implicitHeight + 20
                            small: true
                            fill: Theme.bgItem
                            ring: modelData.urgency === 2 ? Theme.danger : (ima.containsMouse ? Theme.ringActive : Theme.ring)
                            pressed: ima.pressed
                            ColumnLayout {
                                id: itemCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                spacing: 2
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Label { text: item.modelData.summary || item.modelData.app; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Label { visible: item.modelData.silenced; text: "QUIET"; font.pixelSize: 8; font.weight: Font.Black; color: Theme.textSecondary }
                                    Label { sub: true; text: Notifs.ago(item.modelData.time); font.pixelSize: 9 }
                                }
                                Label {
                                    visible: text !== ""
                                    sub: true
                                    text: item.modelData.body
                                    font.pixelSize: 11
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            MouseArea { id: ima; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.remove(item.modelData.id) }
                        }
                    }
                    BlockButton {
                        visible: grp.modelData.items.length > 3
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        small: true
                        fontSize: 10
                        text: grp.open ? "Show fewer" : (grp.modelData.items.length - 3) + " more"
                        onClicked: { var e = Object.assign({}, root.expanded); e[grp.modelData.app] = !grp.open; root.expanded = e }
                    }
                }
            }

            Label { caps: true; text: "Muted"; Layout.topMargin: 8; visible: mutedRest.count > 0 }
            Repeater {
                id: mutedRest
                model: Notifs.muted.filter(a => !Notifs.groups.some(g => g.app === a))
                SettingRow {
                    required property string modelData
                    title: modelData
                    hint: "Its notifications only come here"
                    BlockButton { Layout.preferredWidth: 86; Layout.preferredHeight: 32; small: true; fontSize: 11; text: "Unmute"; onClicked: Notifs.toggleMute(modelData) }
                }
            }
        }
    }
}
