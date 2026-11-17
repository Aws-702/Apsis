// The Training mode and Ultra saver keys with a line on what each does.
// Edit: the texts here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

ColumnLayout {
    id: root
    signal used()
    spacing: 8

    Block {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        visible: Ultra.training
        small: true
        fill: Theme.bgItem
        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 6 }
            spacing: 8
            Rectangle { width: 8; height: 8; radius: 4; color: Ultra.sessionAlive ? Theme.cyan : Theme.textSecondary }
            Label {
                Layout.fillWidth: true
                font.pixelSize: 11
                elide: Text.ElideRight
                text: Ultra.sessionAlive ? "tmux apsis-train running" + root.since() : "No session yet"
            }
            BlockButton {
                Layout.preferredWidth: 78
                Layout.preferredHeight: 32
                small: true
                fontSize: 11
                text: Ultra.sessionAlive ? "Attach" : "Open"
                onClicked: { Ultra.attach(); root.used() }
            }
        }
    }
    function since() {
        if (!Ultra.trainSince) return ""
        var m = Math.round((Date.now() - Ultra.trainSince) / 60000)
        return m < 60 ? ", " + m + " min" : ", " + Math.floor(m / 60) + " h " + (m % 60) + " min"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            icon: Icons.memory
            text: Ultra.training ? "Stop training mode" : "Training mode"
            active: !Ultra.training
            onClicked: { Ultra.train(); root.used() }
        }
        BlockButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            visible: !Ultra.training
            icon: Icons.layers
            text: Ultra.on ? "Leave Ultra" : "Ultra saver"
            onClicked: { Ultra.toggle(); root.used() }
        }
    }
    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        sub: true
        font.pixelSize: 10
        text: Ultra.training ? "Leaving keeps your tmux session running; only the desktop comes back."
            : Ultra.on ? "The shell comes back in full, with the wallpaper, widgets and dock."
            : "Training mode: Ultra saver (no wallpaper, blur, animations or widgets; the shell drawn by the CPU) plus a tmux session for your run."
    }
}
