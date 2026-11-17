// The Bluetooth pairing card: runs apsis-bt-agent.py and shows the code to compare or a PIN box.
// Edit: card width, top margin and texts here (texts in lib/BtAgent.js view()); colours: config/Theme.qml, motion: config/Motion.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"
import "../lib/BtAgent.js" as Proto

Scope {
    id: root

    property bool registered: false
    property bool gaveUp: false
    property var queue: []
    readonly property var current: queue.length > 0 ? queue[0] : null
    readonly property var view: current ? Proto.view(current) : null
    readonly property bool active: current !== null

    property int crashes: 0
    function flag(text) {
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && printf %s \"$1\" > \"$HOME/.cache/quickshell/apsis-btagent\"", "sh", text])
    }

    Process {
        id: proc
        running: true
        stdinEnabled: true
        command: ["python3", Config.scripts + "/apsis-bt-agent.py"]
        stdout: SplitParser { onRead: function(line) { root.onLine(line) } }
        onExited: {
            root.registered = false
            root.queue = []
            if (root.crashes >= 4) { root.gaveUp = true; root.flag("failed"); return }
            root.crashes++
            root.flag("down")
            retry.start()
        }
    }
    Timer { id: retry; interval: 4000; onTriggered: proc.running = true }

    function onLine(line) {
        var m = Proto.parse(line)
        if (!m) return
        switch (m.event) {
        case "registered":
            registered = true
            crashes = 0
            flag("apsis")
            break
        case "unregistered":
            registered = false
            queue = []
            flag("down")
            break
        case "request":
        case "display":
            if (m.event === "request" && Proto.overLimit(queue)) { send(m.id, false); break }
            m.at = Date.now()
            queue = Proto.push(queue, m)
            break
        case "cancel":
            queue = m.id === -1 ? [] : Proto.drop(queue, m.id)
            break
        }
    }

    function send(id, accept, value) { proc.write(Proto.reply(id, accept, value)) }

    function accept(text) {
        var c = current
        if (!c) return
        if (view.input !== "" && !Proto.inputOk(view.input, text)) return
        send(c.id, true, view.input !== "" ? text : "")
        queue = Proto.drop(queue, c.id)
    }
    function reject() {
        var c = current
        if (!c) return
        if (c.kind !== "display") send(c.id, false)
        queue = Proto.drop(queue, c.id)
    }

    Timer {
        interval: 5000
        running: root.queue.length > 0
        repeat: true
        onTriggered: root.queue = root.queue.filter(r => r.kind !== "display" || Date.now() - r.at < 60000)
    }

    PanelWindow {
        id: win
        visible: root.active || pop.settled === false

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "apsis-btagent"
        WlrLayershell.keyboardFocus: root.active ? (root.view && root.view.input !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true }
        margins { top: 56 }
        implicitWidth: 400
        implicitHeight: card.height + 16
        color: "transparent"

        Pop {
            id: pop
            shown: root.active
            width: 400
            height: card.height
            transformOrigin: Item.Top

            Block {
                id: card
                width: parent.width
                height: col.implicitHeight + 36 + 2 * inset + shadowDy
                fill: Theme.bgCard
                ring: Theme.ringActive

                ColumnLayout {
                    id: col
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Block {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 47
                            small: true
                            fill: Theme.accent
                            ring: Theme.ringActive
                            VIcon { anchors.centerIn: parent; size: 20; d: Icons.bluetooth; color: Theme.onAccent }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Label { text: root.view ? root.view.title : ""; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label {
                                sub: true
                                font.pixelSize: 9
                                visible: root.queue.length > 1
                                text: (root.queue.length - 1) + " more waiting"
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        visible: text !== ""
                        text: root.view ? root.view.lead : ""
                    }

                    Block {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 62
                        visible: root.view !== null && root.view.code !== ""
                        small: true
                        fill: Theme.bgMain
                        Text {
                            anchors.centerIn: parent
                            text: root.view ? root.view.code : ""
                            color: Theme.textPrimary
                            font.family: Theme.fontText
                            font.pixelSize: 30
                            font.weight: Font.DemiBold
                            font.letterSpacing: 4
                        }
                    }

                    Block {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        visible: root.view !== null && root.view.input !== ""
                        small: true
                        fill: Theme.bgMain
                        ring: input.activeFocus ? Theme.ringActive : Theme.ring
                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.textPrimary
                            font.family: Theme.fontText
                            font.pixelSize: 16
                            maximumLength: 16
                            inputMethodHints: root.view && root.view.input === "passkey" ? Qt.ImhDigitsOnly : Qt.ImhNone
                            clip: true
                            focus: root.active
                            onAccepted: root.accept(text)
                            Keys.onEscapePressed: root.reject()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                sub: true
                                visible: input.text === ""
                                text: root.view && root.view.input === "passkey" ? "Passkey" : "PIN"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        BlockButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            text: root.view ? root.view.reject : ""
                            onClicked: root.reject()
                        }
                        BlockButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            visible: root.view !== null && root.view.accept !== ""
                            text: root.view ? root.view.accept : ""
                            active: true
                            enabled: root.view === null || root.view.input === "" || Proto.inputOk(root.view.input, input.text)
                            onClicked: root.accept(input.text)
                        }
                    }
                }
            }
        }
    }

    onCurrentChanged: input.text = ""
}
