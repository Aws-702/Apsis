// Updates: the list, PINNED marks, and the review that asks per group before updating.
// Edit: texts and sizes here; the groups in lib/Updates.js; the run in apsis-updates.sh.

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../services"
import "../widgets"
import "../lib/Updates.js" as U

Item {
    id: root

    readonly property bool shown: PhoneState.open && PhoneState.screen === "updates"
    readonly property var all: Updates.repo.concat(Updates.aur.map(u => ({ name: u.name, from: u.from, to: u.to, held: u.held, aur: true })))

    readonly property int listed: Updates.repo.length + Updates.aur.length

    property bool reviewing: false
    property var keep: ({})
    property bool snapshot: false

    function pressUpdate() {
        if (Updates.groups.length === 0) { PhoneState.close(); Updates.update({}, false); return }
        keep = U.defaults(Updates.groups)
        snapshot = Updates.protection.choice
        reviewing = true
    }
    function setKeep(id, v) { var k = {}; for (var x in keep) k[x] = keep[x]; k[id] = v; keep = k }
    function go() { reviewing = false; PhoneState.close(); Updates.update(keep, snapshot) }

    onShownChanged: {
        if (!shown) reviewing = false
        else if (Date.now() - Updates.checkedAt > 3 * 60000) Updates.check()
    }

    function ago(t) {
        if (!t) return ""
        var m = Math.round((Date.now() - t) / 60000)
        return m < 1 ? "checked just now" : m < 60 ? "checked " + m + " min ago" : "checked " + Math.round(m / 60) + " h ago"
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Updates"
        sub: Updates.missing ? "Needs pacman-contrib"
             : Updates.checking ? "Looking..."
             : Updates.total === 0 ? "Up to date, " + (Updates.heldCount > 0 ? Updates.heldCount + " held back, " : "") + root.ago(Updates.checkedAt)
             : Updates.repo.length + " from the repos" + (Updates.aur.length ? ", " + Updates.aur.length + " from the AUR" : "")
        BlockButton {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 40
            small: true
            icon: Icons.restart
            iconSize: 15
            enabled: !Updates.checking
            onClicked: Updates.check()
        }
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        spacing: 10
        visible: root.reviewing

        Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; text: "These can break a working desktop. Choose for each one." }

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: item ? item.implicitHeight : 0
            active: root.reviewing
            sourceComponent: ColumnLayout {
                spacing: 10
                Repeater {
                    model: Updates.groups
                    Block {
                        id: gcard
                        required property var modelData
                        readonly property bool pinned: root.keep[modelData.id] === true
                        Layout.fillWidth: true
                        Layout.preferredHeight: gcol.implicitHeight + 24
                        small: true
                        fill: modelData.state === "mixed" ? Theme.mix(Theme.bgItem, Theme.warn, 0.18) : Theme.bgItem
                        ring: modelData.state === "mixed" ? Theme.warn : Theme.ring
                        ColumnLayout {
                            id: gcol
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                            spacing: 6
                            Label { text: gcard.modelData.title; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { sub: true; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true
                                    text: gcard.modelData.from + "  to  " + gcard.modelData.to + "  (" + gcard.modelData.items.length + (gcard.modelData.items.length === 1 ? " package)" : " packages)") }
                            Label {
                                visible: gcard.modelData.state === "mixed"
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                font.pixelSize: 10
                                text: "Only part of this group is pinned, so a plain pacman update would fail. Keeping it pinned pins all of it."
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 36; small: true; fontSize: 11; text: "Update"; active: !gcard.pinned; onClicked: root.setKeep(gcard.modelData.id, false) }
                                BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 36; small: true; fontSize: 11; text: "Keep pinned"; active: gcard.pinned; onClicked: root.setKeep(gcard.modelData.id, true) }
                            }
                        }
                    }
                }
            }
        }

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: snapRow.implicitHeight + 24
            small: true
            fill: Theme.bgItem
            RowLayout {
                id: snapRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                spacing: 10
                Label { Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 10; text: Updates.protection.choice ? "Take a snapshot first" : Updates.protection.line }
                BlockSwitch { visible: Updates.protection.choice; checked: root.snapshot; onToggled: root.snapshot = !root.snapshot }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 46; text: "Back"; onClicked: root.reviewing = false }
            BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 46; text: "Continue"; active: true; onClicked: root.go() }
        }
        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            sub: true
            font.pixelSize: 10
            text: "Opens a terminal; nothing installs until you confirm there."
        }
    }

    ColumnLayout {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        spacing: 10
        visible: !root.reviewing

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: selfRow.implicitHeight + 24
            visible: Updates.selfCard !== null
            small: true
            fill: Theme.mix(Theme.bgItem, Theme.accent, 0.18)
            ring: Theme.ringActive
            RowLayout {
                id: selfRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Label { text: Updates.selfCard ? Updates.selfCard.title : ""; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { sub: true; text: Updates.selfCard ? Updates.selfCard.sub : ""; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                BlockButton {
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 36
                    small: true
                    fontSize: 11
                    text: "Update Apsis"
                    active: true
                    onClicked: { PhoneState.close(); Updates.updateSelf() }
                }
            }
        }

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: missText.implicitHeight + 24
            visible: Updates.missing
            small: true
            fill: Theme.bgItem
            ring: Theme.warn
            Label {
                id: missText
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                text: "Checking for updates needs checkupdates (sudo pacman -S pacman-contrib). It looks without touching your package database."
            }
        }

        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: warnText.implicitHeight + 24
            visible: Updates.qtRisk
            small: true
            fill: Theme.mix(Theme.bgItem, Theme.warn, 0.18)
            ring: Theme.warn
            Label {
                id: warnText
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                text: "Qt is updating but quickshell isn't. The shell may crash until a quickshell built for the new Qt arrives; waiting a day is safer."
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.listed === 0 && !Updates.missing
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 10
                VIcon { Layout.alignment: Qt.AlignHCenter; size: 40; d: Icons.box; color: Theme.textSecondary }
                Label { Layout.alignment: Qt.AlignHCenter; text: Updates.checking ? "Looking for updates" : "Everything is up to date"; font.pixelSize: 13; font.weight: Font.DemiBold }
            }
        }

        Block {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.listed > 0
            small: true
            fill: Theme.bgItem
            ListView {
                id: list
                anchors { fill: parent; margins: 10 }
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                model: root.all
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    spacing: 8
                    Label { text: modelData.name; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { visible: modelData.held === true; text: "PINNED"; font.pixelSize: 8; font.weight: Font.Black; color: Theme.warn }
                    Label { visible: modelData.aur === true; text: "AUR"; font.pixelSize: 8; font.weight: Font.Black; color: Theme.accent }
                    Label { sub: true; text: modelData.to; font.pixelSize: 10; elide: Text.ElideLeft; Layout.maximumWidth: 120 }
                }
            }
        }

        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            visible: Updates.total > 0
            icon: Icons.box
            text: "Update " + Updates.total + (Updates.total === 1 ? " package" : " packages")
            active: true
            onClicked: root.pressUpdate()
        }

        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            visible: Updates.total === 0 && Updates.groups.length > 0
            icon: Icons.box
            text: "Review held back updates"
            active: true
            onClicked: root.pressUpdate()
        }
        Label {
            Layout.fillWidth: true
            visible: Updates.total > 0 || Updates.groups.length > 0
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            sub: true
            font.pixelSize: 10
            text: "Opens a terminal; nothing installs until you confirm there."
        }
    }
}
