// Settings > Theme: palette, mode, phone style, wallpaper engine and transition, name, picture.
// Edit: rows here; colours in config/Theme.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"

ColumnLayout {
    id: root
    spacing: 12

    property var wallpapers: []
    property var pfps: []
    property bool active: false
    onActiveChanged: if (active) { wallLister.running = true; pfpLister.running = true }
    Component.onCompleted: if (active) { wallLister.running = true; pfpLister.running = true }

    Process {
        id: wallLister

        command: [Config.scripts + "/apsis-wall-list.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t")
                    if (p.length >= 4 && p[1]) out.push({ path: p[1], thumb: p[2], kind: p[3] })
                }
                out.sort(function(a, b) { return a.path.toLowerCase() < b.path.toLowerCase() ? -1 : 1 })
                root.wallpapers = out
            }
        }
    }
    Process {
        id: pfpLister
        command: ["sh", "-c", "d=$HOME/Apsis/pfps; ls -1 \"$d\" 2>/dev/null | grep -iE '\\.(jpg|jpeg|png|webp)$' | sed \"s|^|$d/|\""]
        stdout: StdioCollector { onStreamFinished: { var o = this.text.trim(); root.pfps = o.length ? o.split("\n") : [] } }
    }

    Label { caps: true; text: "Palette" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: [
                { id: "cherry", label: "Cherry", sw: "#EC4C78", sw2: "#17090F" },
                { id: "navy", label: "Navy", sw: "#3AD6E0", sw2: "#0A0A3C" },
                { id: "auto", label: "Auto", sw: "#B9A0FF", sw2: "#2a2140" }
            ]
            BlockButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                active: Theme.palette === modelData.id
                text: modelData.label
                subText: modelData.id === "auto" ? "from wallpaper" : ""
                align: Qt.AlignLeft
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -6
                    Rectangle { width: 22; height: 22; radius: 11; color: modelData.sw2; border.width: 2; border.color: Theme.line }
                    Rectangle { width: 22; height: 22; radius: 11; color: modelData.sw; border.width: 2; border.color: Theme.line }
                }
                onClicked: Sys.script("apsis-palette.sh", modelData.id)
            }
        }
    }

    Label { caps: true; text: "Mode" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Repeater {
            model: [{ id: "dark", label: "Dark" }, { id: "darker", label: "Darker" }, { id: "light", label: "Light" }]
            BlockButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                small: true
                text: modelData.label
                active: Theme.mode === modelData.id
                onClicked: Sys.script("apsis-mode.sh", modelData.id)
            }
        }
    }

    Label { caps: true; text: "Phone" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 44; small: true; text: "2.5D"; active: Settings.phoneStyle === "2.5d"; onClicked: Settings.set("phoneStyle", "2.5d") }
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 44; small: true; text: "Flat"; active: Settings.phoneStyle === "flat"; onClicked: Settings.set("phoneStyle", "flat") }
        Item { Layout.fillWidth: true }
    }

    Label { caps: true; text: "Wallpaper" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 52; small: true; text: "Apsis"; subText: "shell draws it, with transitions"; active: Wall.engine === "apsis"; onClicked: Wall.setEngine("apsis") }
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 52; small: true; text: "awww"; subText: "as in Apsis V.1"; active: Wall.engine === "awww"; onClicked: Wall.setEngine("awww") }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        visible: Wall.engine === "apsis"
        Repeater {
            model: [{ id: "random", label: "Random" }, { id: "bloom", label: "Bloom" }, { id: "keys", label: "Keys" }, { id: "stripe", label: "Stripe" },
                    { id: "slide", label: "Slide" }, { id: "pixel", label: "Pixel" }, { id: "blinds", label: "Blinds" }, { id: "ripple", label: "Ripple" }, { id: "fade", label: "Fade" }]
            BlockButton {
                required property var modelData
                width: 84
                height: 38
                small: true
                fontSize: 11
                text: modelData.label
                active: Settings.wallTransition === modelData.id
                onClicked: Settings.set("wallTransition", modelData.id)
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 10
        visible: root.wallpapers.length > 0
        Repeater {
            model: root.wallpapers
            Block {
                id: wp
                required property var modelData
                width: 150
                height: 94
                small: true
                radius: 10
                pressed: wm.pressed
                ring: wm.containsMouse ? Theme.ringActive : Theme.ring
                line: wp.modelData.path === Wall.path ? Theme.accent : Theme.line
                RoundImage {
                    anchors.fill: parent
                    radius: Math.max(0, wp.radius - wp.inset)
                    source: wp.modelData.thumb ? "file://" + wp.modelData.thumb : ""
                    sourceSize.width: 300
                    sourceSize.height: 190
                    asynchronous: true
                }
                VIcon { visible: wp.modelData.kind === "video"; anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 6; size: 16; d: Icons.play; color: "white" }
                MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Sys.script("apsis-wall.sh", wp.modelData.path) }
            }
        }
    }
    Label { visible: root.wallpapers.length === 0; sub: true; text: "Drop images or videos in ~/Apsis/wallpapers (SUPER + W for the wheel)" }

    Label { caps: true; text: "Name" }
    Block {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        small: true
        fill: Theme.bgMain
        ring: nameField.activeFocus ? Theme.ringActive : Theme.ring
        TextInput {
            id: nameField
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.textPrimary
            font.family: Theme.fontText
            font.pixelSize: 14
            maximumLength: 40
            clip: true
            selectByMouse: true
            Component.onCompleted: text = Settings.data.userName || ""
            onTextChanged: saveName.restart()
            onEditingFinished: { saveName.stop(); Settings.set("userName", text.trim()) }
            Keys.onEscapePressed: focus = false
            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: nameField.text === ""
                sub: true
                font.pixelSize: 14
                text: Settings.systemName + "  (your account's name)"
            }
        }
        Timer { id: saveName; interval: 700; onTriggered: Settings.set("userName", nameField.text.trim()) }
    }

    Label { caps: true; text: "Profile picture" }
    Flow {
        Layout.fillWidth: true
        spacing: 10
        visible: root.pfps.length > 0
        Repeater {
            model: root.pfps
            Block {
                id: pf
                required property string modelData
                width: 70
                height: 74
                small: true
                radius: 33
                pressed: pm.pressed
                ring: pm.containsMouse ? Theme.ringActive : Theme.ring
                RoundImage {
                    anchors.fill: parent
                    radius: Math.max(0, pf.radius - pf.inset)
                    source: "file://" + pf.modelData
                    sourceSize.width: 140
                    sourceSize.height: 140
                    asynchronous: true
                }
                MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Sys.script("apsis-face.sh", pf.modelData) }
            }
        }
    }
    Label { visible: root.pfps.length === 0; sub: true; text: "Drop images in ~/Apsis/pfps" }
}
