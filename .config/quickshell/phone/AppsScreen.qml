// The app launcher with smart search (maths, colours, emoji, clipboard, web).
// Edit: grid columns and icon size here; ranking in lib/AppSearch.js, prefixes in lib/Smart.js.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"
import "../services"
import "../widgets"
import "../lib/AppSearch.js" as Search
import "../lib/Smart.js" as Smart
import "../lib/Calc.js" as Calc
import "../lib/ColorConv.js" as Color
import "../lib/Emoji.js" as Emoji

Item {
    id: root

    property string query: ""
    property var results: []
    property int current: 0
    property bool showHidden: false
    property int hiddenCount: 0

    readonly property var prefs: [AppList.hidden, Dock.pinned]
    onPrefsChanged: refresh(true)
    onShowHiddenChanged: refresh(true)
    readonly property bool shown: PhoneState.open && PhoneState.screen === "apps"

    readonly property var smart: Smart.classify(query)
    readonly property string kind: smart.kind

    readonly property string view: kind === "emoji" ? "emoji" : (kind === "clip" ? "clip" : "apps")
    readonly property var emojis: view === "emoji" ? Emoji.search(smart.q, 140) : []
    property var clips: []
    readonly property var clipsShown: {
        var q = smart.q.toLowerCase()
        return q === "" ? clips : clips.filter(function(c) { return c.text.toLowerCase().indexOf(q) >= 0 })
    }

    readonly property string card: (kind === "calc" || kind === "color" || kind === "url" || kind === "web") ? kind
                                   : (kind === "" && query.trim() !== "" && results.length === 0 ? "web" : "")
    readonly property string webText: kind === "web" ? smart.q : query.trim()
    readonly property int count: view === "emoji" ? emojis.length : (view === "clip" ? clipsShown.length : results.length)
    readonly property int cols: view === "emoji" ? emojiGrid.columns : (view === "clip" ? 1 : grid.columns)
    property string flash: ""

    function all() {
        try {
            var m = DesktopEntries.applications
            return (m && m.values !== undefined) ? m.values : (m || [])
        } catch (e) {
            return []
        }
    }
    function refresh(keep) {
        var a = all()
        hiddenCount = Search.hiddenCount(a, AppList.hidden)
        if (hiddenCount === 0) showHidden = false

        var k = Smart.classify(query).kind
        var q = (k === "emoji" || k === "clip" || k === "web") ? null : query
        results = q === null ? [] : Search.filter(a, q, { starred: Dock.pinned, hidden: AppList.hidden, showHidden: showHidden })
        current = keep ? Math.max(0, Math.min(current, results.length - 1)) : 0
    }
    function openMenu(i) {
        if (view !== "apps" || i < 0 || i >= results.length) return
        current = i
        menu.show(results[i])
    }
    function launch(e) {
        if (!e) return
        try { e.execute() }
        catch (err) { Quickshell.execDetached(["sh", "-c", "uwsm app -- " + e.id + " >/dev/null 2>&1 || gtk-launch " + e.id]) }
        PhoneState.close()
    }

    function copy(text, what) {
        Quickshell.execDetached(["wl-copy", "--", String(text)])
        flash = what || "Copied"
        closeLater.restart()
    }
    function open(url) {
        Quickshell.execDetached(["xdg-open", url])
        PhoneState.close()
    }
    function enter() {
        if (menu.open) return
        if (view === "emoji") { if (emojis[current]) copy(emojis[current].e, "Copied " + emojis[current].e); return }
        if (view === "clip") { pasteClip(clipsShown[current]); return }
        if (card === "calc") { copy(Calc.answer(smart.q), "Copied " + Calc.answer(smart.q)); return }
        if (card === "color") { var c = Color.parse(smart.q); if (c) copy(Color.hex(c), "Copied " + Color.hex(c)); return }
        if (card === "url") { open(Smart.url(smart.q)); return }
        if (card === "web") { if (webText !== "") open(Smart.webUrl(Settings.webSearch, webText)); return }
        if (results.length) launch(results[current])
    }
    function pasteClip(c) {
        if (!c) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", c.line])
        flash = "Back on the clipboard"
        closeLater.restart()
    }
    function forgetClip(c) {
        if (!c) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", c.line])
        clips = clips.filter(function(x) { return x.line !== c.line })
    }

    onQueryChanged: refresh()
    onViewChanged: { current = 0; if (view === "clip") clipP.running = true }
    onShownChanged: {
        menu.close()
        flash = ""
        if (shown) { showHidden = false; clips = []; field.text = PhoneState.pendingQuery; PhoneState.pendingQuery = ""; refresh(); field.forceActiveFocus() }
    }

    Connections {
        target: PhoneState
        function onPendingQueryChanged() {
            if (!root.shown || PhoneState.pendingQuery === "") return
            field.text = PhoneState.pendingQuery
            PhoneState.pendingQuery = ""
            field.forceActiveFocus()
        }
    }
    Timer { id: closeLater; interval: 650; onTriggered: { root.flash = ""; PhoneState.close() } }

    property bool clipMissing: false
    Process {
        id: clipP
        command: ["sh", "-c", "command -v cliphist >/dev/null || { echo '!missing'; exit; }; cliphist list | head -n 200"]
        stdout: StdioCollector {
            onStreamFinished: {
                var t = this.text
                root.clipMissing = t.indexOf("!missing") === 0
                var out = []
                var lines = t.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var l = lines[i]
                    var tab = l.indexOf("\t")
                    if (tab < 0) continue
                    var preview = l.substring(tab + 1)
                    var img = /^\[\[ binary data (.*) \]\]$/.exec(preview)
                    out.push({ line: l, text: img ? "Image  " + img[1] : preview, image: !!img })
                }
                root.clips = out
            }
        }
    }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }

    RowLayout {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        spacing: 10
        BlockButton { Layout.preferredWidth: 46; Layout.preferredHeight: 48; icon: Icons.back; onClicked: PhoneState.back() }
        Block {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            fill: Theme.bgMain
            ring: field.activeFocus ? Theme.ringActive : Theme.ring
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8
                VIcon {
                    size: 17
                    color: root.kind === "" ? Theme.textSecondary : Theme.accent
                    d: ({ calc: Icons.calculator, color: Icons.theme, url: Icons.link, web: Icons.web, emoji: Icons.emoticon, clip: Icons.clipboard })[root.kind] || Icons.search
                }
                TextInput {
                    id: field
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.family: Theme.fontText
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: menu.open ? menu.close() : (text !== "" ? text = "" : PhoneState.back())
                    Keys.onReturnPressed: root.enter()
                    Keys.onEnterPressed: root.enter()
                    Keys.onDownPressed: if (!menu.open) root.current = Math.min(root.count - 1, root.current + root.cols)
                    Keys.onUpPressed: if (!menu.open) root.current = Math.max(0, root.current - root.cols)
                    Keys.onPressed: function(ev) {
                        if (ev.key === Qt.Key_Menu && !menu.open) { root.openMenu(root.current); ev.accepted = true }
                        else if (ev.key === Qt.Key_Delete && root.view === "clip" && (ev.modifiers & Qt.ShiftModifier)) { root.forgetClip(root.clipsShown[root.current]); ev.accepted = true }
                    }
                    Keys.onRightPressed: function(ev) { if (cursorPosition === text.length) { root.current = Math.min(root.count - 1, root.current + 1); ev.accepted = true } else ev.accepted = false }
                    Keys.onLeftPressed: function(ev) { if (cursorPosition === text.length && (text.length === 0 || root.view === "emoji")) { root.current = Math.max(0, root.current - 1); ev.accepted = true } else ev.accepted = false }
                    Label { anchors.verticalCenter: parent.verticalCenter; sub: true; text: "Search apps, or try 2+2"; visible: field.text === ""; font.pixelSize: 14 }
                }
            }
        }

        BlockButton {
            visible: root.hiddenCount > 0 && root.view === "apps"
            Layout.preferredWidth: 46
            Layout.preferredHeight: 48
            icon: root.showHidden ? Icons.eye : Icons.eyeOff
            active: root.showHidden
            onClicked: { root.showHidden = !root.showHidden; field.forceActiveFocus() }
            Block {
                anchors { right: parent.right; top: parent.top; margins: -4 }
                width: 20; height: 20; radius: 10
                small: true; flat: true
                fill: root.showHidden ? Theme.bgCard : Theme.accent
                Label { anchors.centerIn: parent; text: root.hiddenCount; font.pixelSize: 9; font.weight: Font.Black; color: root.showHidden ? Theme.accent : Theme.onAccent }
            }
        }
    }

    Row {
        id: hints
        anchors { top: head.bottom; topMargin: 10; horizontalCenter: parent.horizontalCenter }
        spacing: 10
        visible: root.query === ""
        height: visible ? 36 : 0
        Repeater {
            model: [
                { p: "=", label: "Maths", icon: Icons.calculator },
                { p: ":", label: "Emoji", icon: Icons.emoticon },
                { p: ">", label: "Clipboard", icon: Icons.clipboard },
                { p: "?", label: "Web", icon: Icons.web }
            ]
            BlockButton {
                required property var modelData
                width: 52
                height: 36
                small: true
                icon: modelData.icon
                iconSize: 17
                onClicked: { field.text = modelData.p + (modelData.p === "=" ? " " : ""); field.forceActiveFocus() }
            }
        }
    }

    Block {
        id: cardBox
        anchors { left: parent.left; right: parent.right; top: hints.bottom; topMargin: root.card !== "" ? 12 : 0; leftMargin: 16; rightMargin: 16 }
        height: root.card === "" ? 0 : (root.card === "color" ? 132 : 76)
        visible: root.card !== ""
        fill: Theme.bgItem
        ring: Theme.ringActive
        pressed: cardMa.pressed
        readonly property var col: root.card === "color" ? Color.parse(root.smart.q) : null

        MouseArea { id: cardMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.enter() }

        RowLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            height: 44
            spacing: 12
            Block {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 46
                small: true
                fill: cardBox.col ? Qt.rgba(cardBox.col.r / 255, cardBox.col.g / 255, cardBox.col.b / 255, 1) : Theme.accent
                VIcon {
                    anchors.centerIn: parent
                    visible: !cardBox.col
                    size: 20
                    color: Theme.onAccent
                    d: ({ calc: Icons.calculator, url: Icons.link, web: Icons.web })[root.card] || Icons.search
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: root.card === "calc" ? 22 : 14
                    font.weight: Font.Black
                    text: root.card === "calc" ? "= " + Calc.answer(root.smart.q)
                        : root.card === "color" ? (cardBox.col ? Color.hex(cardBox.col) : "")
                        : root.card === "url" ? Smart.url(root.smart.q)
                        : root.webText === "" ? "Type what to search for" : root.webText
                }
                Label {
                    sub: true
                    font.pixelSize: 10
                    text: root.card === "calc" ? "Enter copies the answer"
                        : root.card === "color" ? "Enter copies the hex, or pick a form below"
                        : root.card === "url" ? "Enter opens it"
                        : "Enter searches the web"
                }
            }
            VIcon { size: 16; d: root.card === "url" || root.card === "web" ? Icons.chevronRight : Icons.copy; color: Theme.textSecondary }
        }

        Row {
            visible: root.card === "color" && cardBox.col !== null
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 10 }
            spacing: 6
            Repeater {
                model: cardBox.col ? [Color.hex(cardBox.col), Color.rgb(cardBox.col), Color.hsl(cardBox.col)] : []
                BlockButton {
                    required property string modelData
                    width: (parent.width - 12) / 3
                    height: 32
                    small: true
                    text: modelData
                    fontSize: 9
                    onClicked: root.copy(modelData, "Copied " + modelData)
                }
            }
        }
    }

    GridView {
        id: grid
        visible: root.view === "apps"
        anchors { left: parent.left; right: parent.right; top: cardBox.bottom; bottom: parent.bottom; topMargin: 14; leftMargin: 12; rightMargin: 12; bottomMargin: 80 }
        readonly property int columns: 4
        cellWidth: Math.floor(width / columns)
        cellHeight: 104
        clip: true
        model: root.view === "apps" ? root.results : []
        currentIndex: root.current
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight
            readonly property bool sel: index === root.current
            readonly property bool isHidden: AppList.isHidden(modelData.id)
            opacity: isHidden ? 0.45 : 1

            BlockButton {
                id: keycap
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
                width: 64
                height: 64
                fillIdle: cell.sel ? Theme.bgHover : Theme.bgItem
                ring: cell.sel ? Theme.ringActive : Theme.ring
                onClicked: root.launch(cell.modelData)
                onRightClicked: root.openMenu(cell.index)
                Image {
                    id: ic
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    sourceSize.width: 68
                    sourceSize.height: 68
                    asynchronous: true
                    visible: status === Image.Ready
                    source: Icons.app(cell.modelData ? cell.modelData.icon : "")
                }
                VIcon { anchors.centerIn: parent; size: 26; d: Icons.apps; color: Theme.textSecondary; visible: ic.status !== Image.Ready }

                VIcon {
                    visible: Dock.isPinned(cell.modelData.id) || cell.isHidden
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 3
                    size: 12
                    d: cell.isHidden ? Icons.eyeOff : Icons.star
                    color: cell.isHidden ? Theme.textSecondary : Theme.accent
                }
            }
            Label {
                anchors.top: keycap.bottom
                anchors.topMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 6
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: cell.modelData ? cell.modelData.name : ""
                font.pixelSize: 10
                color: cell.sel ? Theme.textPrimary : Theme.textSecondary
            }
        }

        Label {
            anchors.centerIn: parent
            visible: root.results.length === 0 && root.card === ""
            sub: true
            text: root.query === "" ? "No applications found" : "Nothing matches \"" + root.query + "\""
        }
    }

    GridView {
        id: emojiGrid
        visible: root.view === "emoji"
        anchors { left: parent.left; right: parent.right; top: cardBox.bottom; bottom: parent.bottom; topMargin: 14; leftMargin: 14; rightMargin: 14; bottomMargin: 80 }
        readonly property int columns: 6
        cellWidth: Math.floor(width / columns)
        cellHeight: cellWidth
        clip: true
        model: root.emojis
        currentIndex: root.view === "emoji" ? root.current : -1
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)
        delegate: Item {
            id: ecell
            required property var modelData
            required property int index
            width: emojiGrid.cellWidth
            height: emojiGrid.cellHeight
            BlockButton {
                anchors.centerIn: parent
                width: parent.width - 8
                height: parent.height - 6
                small: true
                fillIdle: ecell.index === root.current ? Theme.bgHover : Theme.bgItem
                ring: ecell.index === root.current ? Theme.ringActive : Theme.ring
                onClicked: root.copy(ecell.modelData.e, "Copied " + ecell.modelData.e)
                Text { anchors.centerIn: parent; text: ecell.modelData.e; font.pixelSize: 24 }
            }
        }
        Label { anchors.centerIn: parent; visible: root.emojis.length === 0; sub: true; text: "No emoji for \"" + root.smart.q + "\"" }
    }
    Label {
        visible: root.view === "emoji" && root.emojis[root.current] !== undefined
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 56 }
        sub: true
        font.pixelSize: 11
        text: root.emojis[root.current] ? root.emojis[root.current].name : ""
    }

    ListView {
        id: clipList
        visible: root.view === "clip"
        anchors { left: parent.left; right: parent.right; top: cardBox.bottom; bottom: parent.bottom; topMargin: 14; leftMargin: 16; rightMargin: 16; bottomMargin: 80 }
        spacing: 6
        clip: true
        model: root.clipsShown
        currentIndex: root.view === "clip" ? root.current : -1
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
        delegate: BlockButton {
            id: crow
            required property var modelData
            required property int index
            width: clipList.width
            height: 46
            small: true
            align: Qt.AlignLeft
            icon: modelData.image ? Icons.image : ""
            iconSize: 15
            text: modelData.text.replace(/\s+/g, " ")
            fontSize: 11
            fillIdle: index === root.current ? Theme.bgHover : Theme.bgItem
            ring: index === root.current ? Theme.ringActive : Theme.ring
            onClicked: root.pasteClip(modelData)
            onRightClicked: root.forgetClip(modelData)
        }
        Label {
            anchors.centerIn: parent
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: root.clipsShown.length === 0
            sub: true
            text: root.clipMissing ? "Clipboard history needs cliphist: sudo pacman -S cliphist wl-clipboard, then log in again."
                : (root.clips.length === 0 ? "Nothing copied yet" : "Nothing in the history matches")
        }
    }
    Label {
        visible: root.view === "clip" && root.clipsShown.length > 0
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 56 }
        sub: true
        font.pixelSize: 10
        text: "Enter puts it back on the clipboard  /  right click forgets it"
    }

    Block {
        anchors.centerIn: parent
        visible: root.flash !== ""
        width: flashText.implicitWidth + 40
        height: 52
        z: 30
        fill: Theme.accent
        ring: Theme.ringActive
        Label { id: flashText; anchors.centerIn: parent; text: root.flash; color: Theme.onAccent; font.pixelSize: 14; font.weight: Font.Black }
    }

    AppMenu {
        id: menu
        anchors.fill: parent
        z: 20

        onOpenChanged: if (!open && root.shown) field.forceActiveFocus()
    }
}
