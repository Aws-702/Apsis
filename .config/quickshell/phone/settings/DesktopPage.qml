// Settings > Desktop: widgets, presets, dock, bar, modes, lock, idle, notifications, shell size.
// Edit: rows and their order here; defaults in services/Settings.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../services"
import "../../widgets"
import "../../lib/BarLayout.js" as BL

ColumnLayout {
    id: root
    spacing: 12
    property bool active: false

    property var scales: ({})
    function setScale(name, factor) {
        var cmd = [Config.scripts + "/apsis-shell.sh", "scale"]
        if (name !== "all") cmd.push(name)
        cmd.push(factor)
        Quickshell.execDetached(cmd)
    }
    onActiveChanged: if (active) scaleReader.running = true
    Process {
        id: scaleReader
        command: [Config.scripts + "/apsis-shell.sh", "scale"]
        stdout: StdioCollector {
            onStreamFinished: {
                var o = {}
                var rows = this.text.trim().split("\n")
                for (var i = 0; i < rows.length; i++) { var kv = rows[i].split("="); if (kv.length === 2) o[kv[0]] = kv[1] }
                root.scales = o
            }
        }
    }

    Label { caps: true; text: "Widgets" }
    SettingRow {
        title: "Show desktop widgets"
        hint: "Rearrange them with Edit Desktop (SUPER + SHIFT + E)"
        BlockSwitch { checked: Settings.showWidgets; onToggled: Settings.toggle("showWidgets") }
    }
    SettingRow {
        title: "Snap to grid and guides"
        BlockSwitch { checked: Settings.gridSnap; onToggled: Settings.toggle("gridSnap") }
    }
    BlockButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        icon: Icons.pencil
        text: "Edit desktop"
        onClicked: { PhoneState.close(); EditMode.enter() }
    }

    Label { caps: true; text: "Presets" }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "A preset saves the look: palette, mode, which widgets and where, dock and bar. Your to-do items and notes are never part of one." }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            small: true
            fill: Theme.bgMain
            ring: nameField.activeFocus ? Theme.ringActive : Theme.ring
            TextInput {
                id: nameField
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                font.family: Theme.fontText
                font.pixelSize: 13
                maximumLength: 40
                clip: true
                onAccepted: saveBtn.clicked()
                Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Preset name"; visible: nameField.text === "" }
            }
        }
        BlockButton {
            id: saveBtn
            Layout.preferredWidth: 110
            Layout.preferredHeight: 46
            small: true
            icon: Icons.save
            text: "Save"
            active: nameField.text.trim() !== ""
            onClicked: if (Desktop.savePreset(nameField.text)) nameField.text = ""
        }
    }
    BlockButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        small: true
        visible: Desktop.canUndo
        text: "Undo the last preset"
        onClicked: Desktop.undoPreset()
    }
    Repeater {
        model: Desktop.presetNames
        Block {
            id: row
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            small: true
            readonly property var preset: Desktop.presets[modelData]
            property bool renaming: false
            property string problem: ""
            function commit() {
                var why = Desktop.renamePreset(row.modelData, renameField.text)
                if (why === "") { renaming = false; problem = "" }
                else problem = why === "exists" ? "That name is taken" : "Pick another name"
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label { visible: !row.renaming; text: row.modelData; font.pixelSize: 13; Layout.fillWidth: true }
                    TextInput {
                        id: renameField
                        visible: row.renaming
                        Layout.fillWidth: true
                        color: Theme.textPrimary
                        font.family: Theme.fontText
                        font.pixelSize: 13
                        maximumLength: 40
                        selectByMouse: true
                        onAccepted: row.commit()
                        Keys.onEscapePressed: { row.renaming = false; row.problem = "" }
                    }
                    Label { sub: true; font.pixelSize: 10; Layout.fillWidth: true
                        color: row.problem !== "" ? Theme.warn : Theme.textSecondary
                        text: row.problem !== "" ? row.problem : (row.preset ? (row.preset.palette + " / " + row.preset.mode + " / " + (row.preset.widgets || []).length + " widgets") : "") }
                }
                BlockButton { small: true; Layout.preferredWidth: 36; Layout.preferredHeight: 34; icon: row.preset && row.preset.favorite ? Icons.star : Icons.starOutline; iconSize: 14; active: row.preset && row.preset.favorite === true
                    onClicked: Desktop.toggleFavorite(row.modelData) }
                BlockButton { small: true; Layout.preferredWidth: 36; Layout.preferredHeight: 34; icon: Icons.pencil; iconSize: 13
                    onClicked: { if (row.renaming) row.commit(); else { renameField.text = row.modelData; row.renaming = true; renameField.forceActiveFocus() } } }
                BlockButton { small: true; Layout.preferredWidth: 72; Layout.preferredHeight: 34; text: "Wear"; fontSize: 11; active: true; onClicked: Desktop.applyPreset(row.modelData) }
                BlockButton { small: true; Layout.preferredWidth: 36; Layout.preferredHeight: 34; icon: Icons.trash; iconSize: 14; onClicked: Desktop.deletePreset(row.modelData) }
            }
        }
    }
    Label { visible: Desktop.presetNames.length === 0; sub: true; text: "No presets yet." }

    Label { caps: true; text: "Bar" }
    SettingRow {
        title: "Where the bar sits"
        hint: "Top or bottom edge"
        Row {
            spacing: 6
            Repeater {
                model: [{ id: "top", label: "Top" }, { id: "bottom", label: "Bottom" }]
                BlockButton { required property var modelData; small: true; width: 76; height: 32; text: modelData.label
                    active: Settings.barEdge === modelData.id; onClicked: Settings.set("barEdge", modelData.id) }
            }
        }
    }
    SettingRow {
        title: "Bar style"
        hint: "Block: one raised bar. Floating: just the keys. Slim: flat, edge to edge"
        Row {
            spacing: 6
            Repeater {
                model: [{ id: "block", label: "Block" }, { id: "floating", label: "Floating" }, { id: "slim", label: "Slim" }]
                BlockButton { required property var modelData; small: true; width: 76; height: 32; text: modelData.label
                    active: Settings.barStyle === modelData.id; onClicked: Settings.set("barStyle", modelData.id) }
            }
        }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Layout: pick the side for each key, or Off. Use the arrows to reorder within a side. The settings key always stays." }
    Repeater {
        model: BL.MODULES
        SettingRow {
            id: modRow
            required property var modelData
            readonly property var lay: BL.normalize(Settings.barModules)
            readonly property string where: BL.groupOf(lay, modelData.id)
            title: modelData.title
            Row {
                spacing: 4
                Repeater {
                    model: [{ id: "left", label: "L" }, { id: "center", label: "C" }, { id: "right", label: "R" }, { id: "off", label: "Off" }]
                    BlockButton {
                        required property var modelData
                        small: true; width: modelData.id === "off" ? 40 : 32; height: 30; fontSize: 11
                        text: modelData.label
                        active: modRow.where === modelData.id
                        enabled: !(modelData.id === "off" && modRow.modelData.id === "settings")
                        onClicked: Settings.set("barModules", BL.place(modRow.lay, modRow.modelData.id, modelData.id))
                    }
                }
                BlockButton { small: true; width: 30; height: 30; text: "<"; fontSize: 13; visible: modRow.where !== "off"
                    onClicked: Settings.set("barModules", BL.shift(modRow.lay, modRow.modelData.id, -1)) }
                BlockButton { small: true; width: 30; height: 30; text: ">"; fontSize: 13; visible: modRow.where !== "off"
                    onClicked: Settings.set("barModules", BL.shift(modRow.lay, modRow.modelData.id, 1)) }
            }
        }
    }
    BlockButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        small: true
        text: "Reset the bar layout"
        onClicked: Settings.set("barModules", null)
    }

    Label { caps: true; text: "Dock" }
    SettingRow {
        title: "Where the dock sits"
        hint: "Bottom, left or right edge"
        Row {
            spacing: 6
            Repeater {
                model: [{ id: "bottom", label: "Bottom" }, { id: "left", label: "Left" }, { id: "right", label: "Right" }]
                BlockButton { required property var modelData; small: true; width: 70; height: 32; text: modelData.label
                    active: Settings.dockEdge === modelData.id; onClicked: Settings.set("dockEdge", modelData.id) }
            }
        }
    }
    SettingRow {
        title: "Show the dock"
        BlockSwitch { checked: Settings.dockEnabled; onToggled: Settings.toggle("dockEnabled") }
    }
    SettingRow {
        title: "Hide until the pointer reaches the bottom edge"
        BlockSwitch { checked: Settings.dockAutohide; onToggled: Settings.toggle("dockAutohide") }
    }
    SettingRow {
        title: "Media, timer, files, clipboard and shelf keys"
        hint: "Each opens a card above the dock"
        BlockSwitch { checked: Settings.dockCards; onToggled: Settings.toggle("dockCards") }
    }

    Label { caps: true; text: "Other apps" }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Colour apps outside the shell with the current palette. Qt needs qt5ct and qt6ct installed (changes show from the next login); terminals: kitty is included automatically, for foot and alacritty see ~/.config/apsis/terminal." }
    SettingRow {
        title: "Qt apps"
        hint: "qt5ct and qt6ct colour scheme"
        BlockSwitch { checked: Settings.data.sysThemeQt !== false; onToggled: Settings.set("sysThemeQt", Settings.data.sysThemeQt === false) }
    }
    SettingRow {
        title: "KDE apps"
        hint: "The Apsis colour scheme"
        BlockSwitch { checked: Settings.data.sysThemeKde !== false; onToggled: Settings.set("sysThemeKde", Settings.data.sysThemeKde === false) }
    }
    SettingRow {
        title: "Terminal"
        hint: "kitty, foot and alacritty colours"
        BlockSwitch { checked: Settings.data.sysThemeTerminal !== false; onToggled: Settings.set("sysThemeTerminal", Settings.data.sysThemeTerminal === false) }
    }

    Label { caps: true; text: "Shell size" }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Scales the bar, phone, dock and widgets only. Changing it restarts the shell." }
    Repeater {
        model: [{ name: "all", title: "Every monitor" }].concat(Quickshell.screens.map(function(s) { return { name: s.name, title: s.name } }))
        SettingRow {
            id: sizeRow
            required property var modelData
            title: modelData.title
            Row {
                spacing: 4
                Repeater {
                    model: ["0.9", "1", "1.1", "1.25", "1.5"]
                    BlockButton {
                        required property string modelData
                        small: true; width: 44; height: 30; fontSize: 11
                        text: modelData
                        active: (root.scales[sizeRow.modelData.name] || (sizeRow.modelData.name === "all" ? "1" : root.scales.all || "1")) === modelData
                        onClicked: root.setScale(sizeRow.modelData.name, modelData)
                    }
                }
            }
        }
    }

    Label { caps: true; text: "Lyrics sources" }
    SettingRow {
        title: "LRCLIB"
        hint: "lrclib.net, free and open. Sends the artist, title, album and length"
        BlockSwitch { checked: Settings.lyricsHas("lrclib"); onToggled: Settings.lyricsToggle("lrclib") }
    }
    SettingRow {
        title: "NetEase"
        hint: "music.163.com, unofficial; often has word-by-word timing. Sends the title and artist"
        BlockSwitch { checked: Settings.lyricsHas("netease"); onToggled: Settings.lyricsToggle("netease") }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "With both on, the best answer per song is used. Click the source name on the Lyrics widget to choose another." }

    Label { caps: true; text: "Modes" }
    SettingRow {
        title: "Game mode"
        hint: "SUPER + ALT + G. Silence on, wallpaper paused, no animations, blur or gaps"
        BlockSwitch { checked: Sys.game; onToggled: Sys.script("apsis-game.sh", "toggle") }
    }
    SettingRow {
        title: "Focus mode"
        hint: "SUPER + SHIFT + F. Bar hidden, silence on, inactive windows dimmed"
        BlockSwitch { checked: Sys.focus; onToggled: Sys.script("apsis-focus.sh", "toggle") }
    }
    BlockButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        icon: Icons.focus
        text: "Focus for 25 minutes"
        onClicked: Quickshell.execDetached([Config.scripts + "/apsis-focus.sh", "on", "25"])
    }

    Label { caps: true; text: "Idle" }
    SettingRow {
        title: "Lock and turn the screen off when idle"
        hint: "Paused while a video plays or Keep awake is on"
        BlockSwitch { checked: Settings.idleEnabled; onToggled: Settings.toggle("idleEnabled") }
    }
    Repeater {
        model: [
            { key: "idleLockMin", title: "Lock after", opts: [5, 10, 15, 30] },
            { key: "idleScreenMin", title: "Screen off after", opts: [10, 15, 30, 60] },
            { key: "idleSleepMin", title: "Suspend after", opts: [0, 30, 60, 120] }
        ]
        SettingRow {
            id: idleRow
            required property var modelData
            title: modelData.title
            hint: "Minutes; 0 means never"
            visible: Settings.idleEnabled
            Row {
                spacing: 6
                Repeater {
                    model: modelData.opts
                    BlockButton {
                        required property int modelData
                        small: true
                        width: 44; height: 32
                        text: String(modelData)
                        active: Settings.data[idleRow.modelData.key] === modelData
                        onClicked: Settings.set(idleRow.modelData.key, modelData)
                    }
                }
            }
        }
    }

    Label { caps: true; text: "Ultra saver" }
    SettingRow {
        title: "Free the desktop's GPU memory"
        hint: Ultra.on ? (Ultra.hasGpu ? "On: " + (Ultra.used / 1024).toFixed(1) + " of " + (Ultra.total / 1024).toFixed(1) + " GB in use" : "On")
                       : "No wallpaper, blur, shadows, animations, widgets or dock; the shell drawn by the CPU"
        BlockSwitch { checked: Ultra.on; onToggled: { PhoneState.close(); Ultra.toggle() } }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Also SUPER + SHIFT + U. It restarts the shell and tells you how much it freed; turning it off puts everything back. Every login starts with it off." }
    SettingRow {
        title: "Training mode"
        hint: Ultra.training ? (Ultra.sessionAlive ? "On, tmux session apsis-train running" : "On")
                             : "Ultra saver plus a tmux session for your run (SUPER + SHIFT + G)"
        BlockSwitch { checked: Ultra.training; onToggled: { PhoneState.close(); Ultra.train() } }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Turning it on opens a terminal in the session; start your run there. Turning it off brings the desktop back and leaves the session running, so the run is never stopped. tmux attach -t apsis-train gets you back in from any terminal." }

    Label { caps: true; text: "Recording" }
    SettingRow {
        title: "Record what you hear"
        hint: "SUPER + SHIFT + R a region, SUPER + ALT + R the whole screen; again to stop"
        BlockSwitch { checked: Settings.data.recordAudio !== false; onToggled: Settings.set("recordAudio", Settings.data.recordAudio === false) }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Uses gpu-screen-recorder, which encodes on the GPU, so recording costs almost nothing. Videos go to ~/Videos/Recordings and onto the dock's shelf." }

    Label { caps: true; text: "Lock" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "Apsis"; subText: "the block lockscreen"; active: Settings.lockWith === "apsis"; onClicked: Settings.set("lockWith", "apsis") }
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "hyprlock"; subText: "as in Apsis V.1"; active: Settings.lockWith === "hyprlock"; onClicked: Settings.set("lockWith", "hyprlock") }
    }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Used by SUPER + Escape, the power menu's Lock and Sleep keys. If the shell isn't running, hyprlock locks instead." }

    Label { caps: true; text: "Notifications" }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "Cards"; subText: "top right, as in Apsis V.1"; active: Settings.notifyStyle === "cards"; onClicked: Settings.set("notifyStyle", "cards") }
        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "Phone"; subText: "peeks up from the bottom"; active: Settings.notifyStyle === "phone"; onClicked: Settings.set("notifyStyle", "phone") }
    }
}
