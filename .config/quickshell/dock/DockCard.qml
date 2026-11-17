// The card that pops above the dock: media, timer, files, clipboard or shelf.
// Edit: card size and each card's content here; colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"
import "../services"
import "../widgets"
import "../phone"

Block {
    id: root

    property string kind: Dock.card

    property string showing: ""
    onKindChanged: if (kind !== "") showing = kind

    implicitWidth: 400
    implicitHeight: (showing === "media" ? 132 : showing === "timer" ? 214 : 252) + shadowDy
    fill: Theme.bgCard
    ring: Theme.ringActive

    MediaCard {
        anchors.fill: parent
        anchors.margins: -root.inset
        visible: root.showing === "media"
        fill: Theme.bgCard
    }

    ColumnLayout {
        visible: root.showing === "timer"
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: Countdown.active ? Countdown.text : (Countdown.rang ? "Time is up" : Countdown.fmt(pickMins.value * 60))
                font.pixelSize: 40
                font.weight: Font.Black
                color: Countdown.rang ? Theme.accent : Theme.textPrimary
                Layout.fillWidth: true
            }
            ColumnLayout {
                spacing: 6
                BlockButton {
                    Layout.preferredWidth: 110; Layout.preferredHeight: 40
                    active: true
                    icon: Countdown.running ? Icons.pause : Icons.play
                    text: Countdown.running ? "Pause" : (Countdown.paused ? "Resume" : "Start")
                    onClicked: Countdown.running ? Countdown.pause() : (Countdown.paused ? Countdown.resume() : Countdown.start(pickMins.value * 60))
                }
                BlockButton {
                    Layout.preferredWidth: 110; Layout.preferredHeight: 34
                    small: true
                    text: "Reset"
                    fontSize: 11
                    enabled: Countdown.active || Countdown.rang
                    onClicked: Countdown.reset()
                }
            }
        }

        QtObject { id: pickMins; property int value: 25 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Countdown.active ? [1, 5, 10] : [1, 5, 10, 15, 25, 45]
                BlockButton {
                    required property int modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    small: true
                    fontSize: 11
                    text: (Countdown.active ? "+" : "") + modelData + "m"
                    active: !Countdown.active && pickMins.value === modelData
                    onClicked: Countdown.active ? Countdown.add(modelData * 60) : (pickMins.value = modelData)
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: Theme.bgMain
            Rectangle {
                height: parent.height
                radius: 3
                color: Theme.accent
                width: parent.width * (Countdown.total > 0 && Countdown.active ? Countdown.left / Countdown.total : 0)
                Behavior on width { NumberAnimation { duration: 240 } }
            }
        }
    }

    Item {
        id: files
        visible: root.showing === "files"
        anchors.fill: parent
        property var list: []
        onVisibleChanged: if (visible) filesP.running = true
        Component.onCompleted: if (visible) filesP.running = true
        Process {
            id: filesP
            command: ["sh", "-c", "find \"$HOME/Downloads\" \"$HOME/Pictures\" \"$HOME/Pictures/Screenshots\" -maxdepth 1 -type f ! -name '.*' -printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -n 12 | cut -f2-"]
            stdout: StdioCollector { onStreamFinished: { var t = this.text.trim(); files.list = t.length ? t.split("\n") : [] } }
        }
        Label { x: 14; y: 12; width: parent.width - 28; elide: Text.ElideRight; caps: true; text: "Recent files  /  drag one out" }
        Flow {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12; topMargin: 34 }
            spacing: 4
            clip: true
            Repeater {
                model: files.list
                FileTile {
                    required property string modelData
                    path: modelData
                    onSecondary: Quickshell.execDetached(["sh", "-c", "dbus-send --session --dest=org.freedesktop.FileManager1 --type=method_call /org/freedesktop/FileManager1 org.freedesktop.FileManager1.ShowItems array:string:\"file://$1\" string:'' || xdg-open \"$(dirname \"$1\")\"", "sh", modelData])
                }
            }
        }
        Label { anchors.centerIn: parent; visible: files.list.length === 0; sub: true; text: "Nothing in Downloads or Pictures yet" }
    }

    Item {
        id: clip
        visible: root.showing === "clip"
        anchors.fill: parent
        property var list: []
        property bool missing: false
        onVisibleChanged: if (visible) clipP.running = true
        Component.onCompleted: if (visible) clipP.running = true
        Process {
            id: clipP
            command: ["sh", "-c", "command -v cliphist >/dev/null || { echo '!missing'; exit; }; cliphist list | head -n 6"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var t = this.text
                    clip.missing = t.indexOf("!missing") === 0
                    clip.list = clip.missing ? [] : t.split("\n").filter(function(l) { return l.indexOf("\t") > 0 })
                }
            }
        }
        Label { x: 14; y: 12; width: parent.width - 28; elide: Text.ElideRight; caps: true; text: "Clipboard  /  click to copy again" }
        ColumnLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12; topMargin: 34 }
            spacing: 5
            Repeater {
                model: clip.list
                BlockButton {
                    required property string modelData
                    readonly property string preview: modelData.substring(modelData.indexOf("\t") + 1).replace(/\s+/g, " ")
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    small: true
                    flat: true
                    align: Qt.AlignLeft
                    fontSize: 10
                    text: /^\[\[ binary data/.test(preview) ? "Image" : preview
                    onClicked: { Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", modelData]); Dock.card = "" }
                }
            }
        }
        Label {
            anchors.centerIn: parent
            width: parent.width - 30
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            visible: clip.list.length === 0
            sub: true
            text: clip.missing ? "Clipboard history needs cliphist (sudo pacman -S cliphist wl-clipboard)" : "Nothing copied yet"
        }
    }

    Item {
        visible: root.showing === "shelf"
        anchors.fill: parent
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            onDropped: function(d) { Shelf.add(d.urls); d.acceptProposedAction() }
        }
        RowLayout {
            x: 14; y: 8
            width: parent.width - 28
            Label { caps: true; text: "Shelf  /  drop files here"; elide: Text.ElideRight; Layout.fillWidth: true }
            BlockButton { visible: Shelf.items.length > 0; Layout.preferredWidth: 60; Layout.preferredHeight: 24; small: true; flat: true; text: "Clear"; fontSize: 9; onClicked: Shelf.clear() }
        }
        Flow {
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 12; topMargin: 38 }
            spacing: 4
            clip: true
            Repeater {
                model: Shelf.items
                FileTile {
                    required property var modelData
                    path: modelData.path
                    onSecondary: Shelf.remove(modelData.path)
                }
            }
        }
        Label {
            anchors.centerIn: parent
            visible: Shelf.items.length === 0
            sub: true
            text: "Drag files onto the shelf key or here"
        }
    }
}
