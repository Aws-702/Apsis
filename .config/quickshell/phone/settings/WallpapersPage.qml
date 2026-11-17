// Settings > Wallpapers: your folder, random pick, Wallhaven and the lockscreen picture.
// Edit: rows here; downloading in hypr/scripts/apsis-wallhaven.sh.

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
    property bool active: false

    property var wallpapers: []
    property var results: []
    property int page: 1
    property int lastPage: 1
    property string status: ""
    property bool busy: false
    property string fingerHint: "Checking the reader..."
    property string pending: ""

    onActiveChanged: if (active) { wallLister.running = true; fingerStatus.running = true }
    Component.onCompleted: if (active) { wallLister.running = true; fingerStatus.running = true }
    Process {
        id: fingerStatus
        command: [Config.scripts + "/apsis-fingerprint.sh", "status"]
        stdout: StdioCollector { onStreamFinished: root.fingerHint = this.text.trim() || "Unknown" }
    }

    function search(p) {
        if (busy) return
        page = Math.max(1, p)
        busy = true
        status = "Searching..."
        searcher.command = [Config.scripts + "/apsis-wallhaven.sh", "search", queryField.text.trim(), String(page), Settings.wallhavenSort]
        searcher.running = true
    }

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
        id: searcher
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t")
                    if (p.length >= 5 && p[0]) {
                        out.push({ id: p[0], thumb: p[1], full: p[2], res: p[3] })
                        root.lastPage = Math.max(1, parseInt(p[4]) || 1)
                    }
                }
                root.results = out
                root.busy = false
                root.status = out.length ? "" : "Nothing found (or offline)"
            }
        }
        onExited: (code) => { if (code !== 0) { root.busy = false; root.status = "Search failed: offline, or too many requests (wait a minute)" } }
    }
    Process {
        id: getter
        stdout: StdioCollector { onStreamFinished: { root.pending = ""; wallLister.running = true } }
        onExited: (code) => { if (code !== 0) { root.pending = ""; root.status = "Download failed" } }
    }

    Label { caps: true; text: "From your folder" }
    BlockButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        icon: Icons.image
        text: "Random wallpaper"
        subText: "SUPER + SHIFT + W, from ~/Apsis/wallpapers"
        onClicked: Sys.script("apsis-wall-random.sh")
    }

    Label { caps: true; text: "Lockscreen" }
    SettingRow {
        title: "Lockscreen picture"
        hint: Settings.lockWall === "" ? "Same as the desktop wallpaper" : Settings.lockWall.split("/").pop()
        Row {
            spacing: 6
            BlockButton { small: true; width: 110; height: 32; text: "Use current"; onClicked: Settings.set("lockWall", Wall.path) }
            BlockButton { small: true; width: 110; height: 32; text: "Follow desktop"; active: Settings.lockWall === ""; onClicked: Settings.set("lockWall", "") }
        }
    }
    SettingRow {
        title: "Lockscreen style"
        hint: "Cards: big keycap clock. Minimal: a plain clock"
        Row {
            spacing: 6
            BlockButton { small: true; width: 80; height: 32; text: "Cards"; active: Settings.lockStyle === "cards"; onClicked: Settings.set("lockStyle", "cards") }
            BlockButton { small: true; width: 80; height: 32; text: "Minimal"; active: Settings.lockStyle === "minimal"; onClicked: Settings.set("lockStyle", "minimal") }
        }
    }
    SettingRow {
        title: "Unlock with a fingerprint"
        hint: root.fingerHint
        BlockSwitch { checked: Settings.lockFinger; onToggled: Settings.toggle("lockFinger") }
    }
    BlockButton {
        visible: Settings.lockFinger
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        small: true
        text: "Enroll a finger in a terminal"
        onClicked: Sys.script("apsis-fingerprint.sh", "enroll")
    }
    SettingRow {
        title: "Sleep the desktop while locked"
        hint: "Widgets, the visualizer and a video wallpaper stop until you unlock"
        BlockSwitch { checked: Settings.lockSleep; onToggled: Settings.toggle("lockSleep") }
    }
    SettingRow {
        title: "Keep this part in view"
        hint: "What stays visible when the picture is cropped to the screen"
        Row {
            spacing: 6
            Repeater {
                model: ["center", "top", "bottom", "left", "right"]
                BlockButton {
                    required property string modelData
                    small: true; width: 64; height: 32; fontSize: 10
                    text: modelData
                    active: Settings.lockCrop === modelData
                    onClicked: Settings.set("lockCrop", modelData)
                }
            }
        }
    }
    Flow {
        Layout.fillWidth: true
        spacing: 8
        visible: root.wallpapers.length > 0
        Repeater {
            model: root.wallpapers
            Block {
                id: lw
                required property var modelData
                width: 96
                height: 60
                small: true
                radius: 8
                line: lw.modelData.path === Settings.lockWall ? Theme.accent : Theme.line
                ring: lm.containsMouse ? Theme.ringActive : Theme.ring
                RoundImage {
                    anchors.fill: parent
                    radius: Math.max(0, lw.radius - lw.inset)
                    source: lw.modelData.thumb ? "file://" + lw.modelData.thumb : ""
                    sourceSize.width: 200
                    sourceSize.height: 130
                    asynchronous: true
                }
                MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.set("lockWall", lw.modelData.path) }
            }
        }
    }

    Label { caps: true; text: "Wallhaven" }
    Label { sub: true; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 11
        text: "Safe-for-work wallpapers from wallhaven.cc. Click one to download it into ~/Apsis/wallpapers and set it." }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            small: true
            fill: Theme.bgMain
            ring: queryField.activeFocus ? Theme.ringActive : Theme.ring
            TextInput {
                id: queryField
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.textPrimary
                font.family: Theme.fontText
                font.pixelSize: 13
                maximumLength: 60
                clip: true
                selectByMouse: true
                onAccepted: root.search(1)
                Keys.onEscapePressed: focus = false
                Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Search, or leave empty for the top list"; visible: queryField.text === "" }
            }
        }
        BlockButton { Layout.preferredWidth: 100; Layout.preferredHeight: 46; text: root.busy ? "..." : "Search"; onClicked: root.search(1) }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: [{ id: "toplist", label: "Top" }, { id: "relevance", label: "Relevant" }, { id: "random", label: "Random" }, { id: "date_added", label: "Newest" }, { id: "favorites", label: "Favorites" }]
            BlockButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                small: true
                fontSize: 11
                text: modelData.label
                active: Settings.wallhavenSort === modelData.id
                onClicked: { Settings.set("wallhavenSort", modelData.id); root.search(1) }
            }
        }
    }
    Label { visible: root.status !== ""; sub: true; text: root.status }
    Flow {
        Layout.fillWidth: true
        spacing: 10
        visible: root.results.length > 0
        Repeater {
            model: root.results
            Block {
                id: wh
                required property var modelData
                width: 150
                height: 94
                small: true
                radius: 10
                pressed: wm.pressed
                ring: wm.containsMouse ? Theme.ringActive : Theme.ring
                RoundImage {
                    anchors.fill: parent
                    radius: Math.max(0, wh.radius - wh.inset)
                    source: wh.modelData.thumb
                    sourceSize.width: 300
                    sourceSize.height: 190
                    asynchronous: true
                }
                Rectangle {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 5 }
                    radius: 6; color: Theme.alpha("black", 0.55)
                    width: resLabel.implicitWidth + 10; height: 16
                    Label { id: resLabel; anchors.centerIn: parent; text: wh.modelData.res; font.pixelSize: 9; color: "white" }
                }
                Rectangle {
                    anchors.fill: parent; radius: wh.radius; color: Theme.alpha("black", 0.5)
                    visible: root.pending === wh.modelData.id
                    Label { anchors.centerIn: parent; text: "Downloading"; font.pixelSize: 11; color: "white" }
                }
                MouseArea {
                    id: wm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.pending !== "") return
                        root.pending = wh.modelData.id
                        getter.command = [Config.scripts + "/apsis-wallhaven.sh", "get", wh.modelData.id, "apply"]
                        getter.running = true
                    }
                }
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: root.results.length > 0
        spacing: 10
        BlockButton { Layout.preferredWidth: 100; Layout.preferredHeight: 38; small: true; text: "Previous"; visible: root.page > 1; onClicked: root.search(root.page - 1) }
        Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; sub: true; text: "Page " + root.page + " of " + root.lastPage }
        BlockButton { Layout.preferredWidth: 100; Layout.preferredHeight: 38; small: true; text: "Next"; visible: root.page < root.lastPage; onClicked: root.search(root.page + 1) }
    }
}
