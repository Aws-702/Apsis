// Wi-Fi: the radio switch, your network and the ones nearby; join, disconnect, forget.
// Edit: row size here; nmcli calls in hypr/scripts/apsis-wifi.sh.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"
import "../services"
import "../widgets"

Item {
    id: root

    readonly property bool shown: PhoneState.open && PhoneState.screen === "wifi"
    readonly property string script: Config.scripts + "/apsis-wifi.sh"

    property var networks: []
    property string connName: ""
    property string connIp: ""
    property string asking: ""
    property string busy: ""
    property string failed: ""
    property bool scanning: false

    function refresh() { if (!lister.running) lister.running = true; if (!statusP.running) statusP.running = true }
    function rescan() { if (rescanP.running) return; root.scanning = true; rescanP.running = true }

    function join(n, pass) {
        if (root.busy !== "") return
        if (n.active) return
        if (n.secured && !n.saved && !pass) { root.asking = n.ssid; root.failed = ""; return }
        root.busy = n.ssid
        root.failed = ""
        joinP.secured = n.secured
        joinP.command = pass ? [root.script, "connect", n.ssid, pass] : [root.script, "connect", n.ssid]
        joinP.running = true
    }

    onShownChanged: if (shown) { asking = ""; failed = ""; rescan(); refresh() }

    Process {
        id: lister
        command: [root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var arr = []
                var lines = this.text.trim().split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split("\t")
                    if (f.length >= 4 && f[3])
                        arr.push({ active: f[0] === "yes", signal: parseInt(f[1]) || 0, secured: f[2] !== "", ssid: f[3], saved: f[4] === "yes" })
                }
                arr.sort(function(a, b) { return (b.active - a.active) || (b.saved - a.saved) || (b.signal - a.signal) })
                root.networks = arr
            }
        }
    }
    Process {
        id: statusP
        command: [root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.trim().split("\t")
                root.connName = f[0] || ""
                root.connIp = f[1] || ""
            }
        }
    }
    Process { id: rescanP; command: [root.script, "rescan"]; onExited: { root.scanning = false; root.refresh() } }
    Process {
        id: joinP
        property bool secured: false
        onExited: function(code) {
            if (code !== 0) {
                root.failed = root.busy
                if (secured) root.asking = root.busy
            } else {
                root.asking = ""
            }
            root.busy = ""
            root.refresh()
        }
    }
    Process { id: actP; onExited: root.refresh() }
    function act(args) { actP.command = [root.script].concat(args); actP.running = true }

    Timer { interval: 4000; repeat: true; running: root.shown; onTriggered: root.refresh() }

    StatusRow {
        id: status
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
    }
    ScreenHead {
        id: head
        anchors { left: parent.left; right: parent.right; top: status.bottom; topMargin: 10; leftMargin: 16; rightMargin: 16 }
        title: "Wi-Fi"
        sub: Sys.wifiOn ? (root.scanning ? "Looking for networks..." : root.networks.length + " networks nearby") : "Off"
        BlockButton {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 44
            icon: Icons.restart
            iconSize: 17
            enabled: Sys.wifiOn && !root.scanning
            onClicked: root.rescan()
        }
        BlockSwitch { checked: Sys.wifiOn; onToggled: { Sys.toggleWifi(); if (Sys.wifiOn) rescanLater.restart() } }
    }
    Timer { id: rescanLater; interval: 2500; onTriggered: root.rescan() }

    Flickable {
        id: flick
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; topMargin: 12; leftMargin: 16; rightMargin: 16; bottomMargin: 60 }
        contentHeight: col.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        visible: Sys.wifiOn

        ColumnLayout {
            id: col
            width: flick.width
            spacing: 8

            Block {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                visible: root.connName !== ""
                fill: Theme.bgItem
                ring: Theme.ringActive
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        WifiIcon { size: 20; color: Theme.accent }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { text: root.connName; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { sub: true; text: root.connIp ? "Connected  /  " + root.connIp : "Connected"; font.pixelSize: 10 }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 36; small: true; text: "Disconnect"; fontSize: 11; onClicked: root.act(["disconnect"]) }
                        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 36; small: true; text: "Forget"; fontSize: 11; inkIdle: Theme.danger; onClicked: root.act(["forget", root.connName]) }
                    }
                }
            }

            Label { caps: true; text: "Networks"; Layout.topMargin: 4 }
            Label { sub: true; visible: root.networks.length === 0; text: root.scanning ? "Scanning..." : "No networks found" }

            Repeater {
                model: root.networks.filter(function(n) { return !n.active })
                NetRow {
                    required property var modelData
                    net: modelData
                    open: root.asking === modelData.ssid
                    busy: root.busy === modelData.ssid
                    failed: root.failed === modelData.ssid
                    onJoin: function(pass) { root.join(modelData, pass) }
                    onForget: root.act(["forget", modelData.ssid])
                    onCancel: { root.asking = ""; root.failed = "" }
                }
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: !Sys.wifiOn
        sub: true
        text: "Wi-Fi is off"
    }

    component NetRow: Block {
        id: row
        property var net: ({})
        property bool open: false
        property bool busy: false
        property bool failed: false
        signal join(string pass)
        signal forget()
        signal cancel()

        property real h: open ? 112 : 52
        Behavior on h { NumberAnimation { duration: Motion.quickMs; easing.type: Easing.OutCubic } }
        Layout.fillWidth: true
        Layout.preferredHeight: h
        small: true
        clip: true
        fill: hit.containsMouse && !open ? Theme.bgHover : Theme.bgItem
        ring: open ? Theme.ringActive : Theme.ring
        pressed: hit.pressed && !open

        MouseArea {
            id: hit
            width: parent.width
            height: 44
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(m) {
                if (m.button === Qt.RightButton) { if (row.net.saved) row.forget() }
                else if (!row.open) row.join("")
            }
        }

        ColumnLayout {
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12; topMargin: 0 }
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                spacing: 10
                SignalBars { strength: row.net.signal || 0; size: 15 }
                Label { text: row.net.ssid || ""; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                Label { sub: true; visible: row.net.saved && !row.busy; text: "Saved"; font.pixelSize: 9 }
                Label { sub: true; visible: row.busy; text: "Joining..."; font.pixelSize: 10; color: Theme.accent }
                VIcon { visible: row.net.secured; size: 13; d: Icons.lock; color: Theme.textSecondary }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: row.open
                spacing: 8
                Block {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    small: true
                    flat: true
                    fill: Theme.bgMain
                    ring: pw.activeFocus ? Theme.ringActive : Theme.ring
                    TextInput {
                        id: pw
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.textPrimary
                        font.family: Theme.fontText
                        font.pixelSize: 13
                        clip: true
                        onAccepted: if (text.length) row.join(text)
                        Keys.onEscapePressed: row.cancel()
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pw.text === ""
                            sub: true
                            text: row.failed ? "Wrong password, try again" : "Password"
                            color: row.failed ? Theme.danger : Theme.textSecondary
                        }
                    }
                }
                BlockButton {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 42
                    small: true
                    text: "Join"
                    active: true
                    enabled: pw.text.length > 0 && !row.busy
                    onClicked: row.join(pw.text)
                }
            }
        }
        onOpenChanged: if (open) { pw.text = ""; pw.forceActiveFocus() }
    }
}
