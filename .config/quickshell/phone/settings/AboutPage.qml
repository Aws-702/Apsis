// Settings > About: the version, the health check and where things live.
// Edit: the paths list and texts here; checks in hypr/scripts/apsis-doctor.sh.

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../services"
import "../../widgets"

ColumnLayout {
    id: root
    spacing: 12
    property bool active: false

    Block {
        Layout.fillWidth: true
        Layout.preferredHeight: 120
        fill: Theme.accent
        ring: Theme.ringActive
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            Label { text: "Apsis"; color: Theme.onAccent; font.pixelSize: 30; font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
            Label { text: "version " + (Updates.version || "?") + "  /  " + Theme.palette + "  /  " + Theme.mode; color: Theme.alpha(Theme.onAccent, 0.8); Layout.alignment: Qt.AlignHCenter }
        }
    }

    Label { caps: true; text: "Apsis updates" }
    SettingRow {
        title: "Check the repo every day"
        hint: Updates.selfNew ? (Updates.selfCard ? Updates.selfCard.title : "")
              : Updates.self.status === "current" ? "You have the newest Apsis"
              : Updates.self.status === "offline" ? "Couldn't reach the repo; trying again in an hour"
              : Updates.self.status === "ahead" ? "Yours has changes the repo doesn't"
              : "A note on the phone when a new Apsis is out"
        BlockSwitch {
            checked: Settings.data.apsisUpdateCheck !== false
            onToggled: Settings.toggle("apsisUpdateCheck")
        }
    }

    Label { caps: true; text: "Health check" }
    SettingRow {
        title: Doctor.running ? "Checking..." : Doctor.ranAt === 0 ? "Check what Apsis needs"
               : Doctor.fails + Doctor.warns === 0 ? "All good" : Doctor.fails + " to fix, " + Doctor.warns + " worth a look"
        hint: Doctor.ranAt === 0 ? "Programs, the session, versions, the GPU, your settings files" : Doctor.okCount + " checks passed"
        BlockButton {
            Layout.preferredWidth: 96
            Layout.preferredHeight: 36
            small: true
            fontSize: 11
            icon: Icons.restart
            iconSize: 13
            text: Doctor.ranAt === 0 ? "Check" : "Again"
            active: Doctor.ranAt === 0
            enabled: !Doctor.running
            onClicked: Doctor.run()
        }
    }
    Repeater {
        model: Doctor.problems
        Block {
            id: prob
            required property var modelData
            readonly property color tone: modelData.status === "fail" ? Theme.danger : modelData.status === "warn" ? Theme.warn : Theme.textSecondary
            Layout.fillWidth: true
            Layout.preferredHeight: probCol.implicitHeight + 24
            small: true
            fill: Theme.bgItem
            ring: modelData.status === "fail" ? Theme.danger : Theme.ring
            RowLayout {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10
                Rectangle { Layout.alignment: Qt.AlignTop; Layout.topMargin: 4; width: 10; height: 10; radius: 5; color: prob.tone }
                ColumnLayout {
                    id: probCol
                    Layout.fillWidth: true
                    spacing: 3
                    Label { text: prob.modelData.what; font.pixelSize: 12; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { sub: true; visible: text !== ""; text: prob.modelData.detail; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Label { visible: text !== ""; text: prob.modelData.fix; font.family: Theme.fontText; font.pixelSize: 10; color: Theme.accent; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
                }
                BlockButton {
                    Layout.alignment: Qt.AlignTop
                    visible: prob.modelData.fix !== ""
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 32
                    small: true
                    icon: Icons.copy
                    iconSize: 13
                    onClicked: Doctor.copy(prob.modelData.fix)
                }
            }
        }
    }

    Label { caps: true; text: "Where things live" }
    Repeater {
        model: [
            { k: "Widgets, presets, dock, settings", v: "~/.local/state/apsis/" },
            { k: "Palette, mode, toggles", v: "~/.cache/quickshell/apsis-*" },
            { k: "Wallpapers", v: "~/Apsis/wallpapers" },
            { k: "Profile pictures", v: "~/Apsis/pfps" },
            { k: "Logic tests", v: "node ~/.config/apsis/tests/run.js" },
            { k: "Health check", v: "apsis doctor" }
        ]
        SettingRow {
            required property var modelData
            title: modelData.k
            Label { sub: true; text: modelData.v; font.pixelSize: 11 }
        }
    }

    Label { caps: true; text: "From the keyboard" }
    Repeater {
        model: [
            { k: "SUPER + Space", v: "Phone (quick panel)" },
            { k: "SUPER + R", v: "Phone (apps)" },
            { k: "SUPER + I", v: "Phone (settings)" },
            { k: "SUPER + SHIFT + E", v: "Edit desktop" },
            { k: "SUPER + D", v: "Show / hide the dock" },
            { k: "SUPER + SHIFT + D", v: "Cycle dark / darker / light" },
            { k: "SUPER + SHIFT + T", v: "Toggle cherry / navy" },
            { k: "SUPER + Tab", v: "Overview" },
            { k: "SUPER + /", v: "Every shortcut" },
            { k: "SUPER + W", v: "Wallpaper wheel" },
            { k: "SUPER + V", v: "Clipboard history" },
            { k: "SUPER + .", v: "Emoji" },
            { k: "SUPER + N", v: "Notifications" },
            { k: "SUPER + SHIFT + R", v: "Record a region" },
            { k: "SUPER + ALT + R", v: "Record the screen" },
            { k: "SUPER + SHIFT + U", v: "Ultra saver" },
            { k: "SUPER + SHIFT + G", v: "Training mode" }
        ]
        SettingRow {
            required property var modelData
            title: modelData.v
            Block { small: true; flat: true; width: kt.implicitWidth + 24; height: 28; fill: Theme.bgMain
                Label { id: kt; anchors.centerIn: parent; text: modelData.k; font.pixelSize: 10 } }
        }
    }
}
