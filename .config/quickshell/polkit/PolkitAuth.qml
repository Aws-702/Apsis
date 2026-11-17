// The password card apps get when they need root (the shell's polkit agent).
// Edit: card width and text here; colours: config/Theme.qml, motion: config/Motion.qml; the fallback agent is started in shell.qml.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../config"
import "../services"
import "../widgets"

Scope {
    id: root

    readonly property bool registered: agent.isRegistered
    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive && flow !== null

    PolkitAgent { id: agent }

    onRegisteredChanged: if (registered) Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell\" && printf apsis > \"$HOME/.cache/quickshell/apsis-polkit\""])

    PanelWindow {
        id: win
        visible: root.active || fade.running

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "apsis-polkit"
        WlrLayershell.keyboardFocus: root.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim
            opacity: root.active ? 1 : 0
            Behavior on opacity { NumberAnimation { id: fade; duration: Motion.popOutMs } }
        }

        Pop {
            id: pop
            shown: root.active
            anchors.centerIn: parent
            width: 420
            height: card.height

            property real shake: 0
            transform: Translate { x: pop.shake }
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: pop; property: "shake"; to: -14; duration: 45 }
                NumberAnimation { target: pop; property: "shake"; to: 12; duration: 70 }
                NumberAnimation { target: pop; property: "shake"; to: -8; duration: 60 }
                NumberAnimation { target: pop; property: "shake"; to: 5; duration: 50 }
                NumberAnimation { target: pop; property: "shake"; to: 0; duration: 45 }
            }

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
                            VIcon { anchors.centerIn: parent; size: 20; d: Icons.lock; color: Theme.onAccent }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Label { text: "Authentication needed"; font.pixelSize: 16; font.weight: Font.DemiBold }
                            Label { sub: true; text: root.flow ? root.flow.actionId : ""; font.pixelSize: 9; elide: Text.ElideMiddle; Layout.fillWidth: true }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        text: root.flow ? (root.flow.message || "An app wants to do something that needs your password.") : ""
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: root.flow !== null && root.flow.identities.length > 1
                        Repeater {
                            model: root.flow ? root.flow.identities : []
                            BlockButton {
                                required property var modelData
                                small: true
                                height: 32
                                width: Math.max(90, implicitWidth)
                                fontSize: 11
                                text: modelData.displayName || modelData.string
                                active: root.flow && root.flow.selectedIdentity === modelData
                                onClicked: root.flow.selectedIdentity = modelData
                            }
                        }
                    }

                    Block {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        visible: root.flow !== null && root.flow.isResponseRequired
                        small: true
                        fill: Theme.bgMain
                        ring: input.activeFocus ? Theme.ringActive : Theme.ring
                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.textPrimary
                            font.family: Theme.fontText
                            font.pixelSize: 14
                            echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "•"
                            clip: true
                            focus: root.active
                            onAccepted: root.submit()
                            Keys.onEscapePressed: root.cancel()
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                sub: true
                                visible: input.text === ""
                                text: root.flow && root.flow.inputPrompt ? root.flow.inputPrompt.replace(/:\s*$/, "") : "Password"
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        color: root.flow && (root.flow.supplementaryIsError || root.flow.failed) ? Theme.danger : Theme.textSecondary
                        text: root.flow ? (root.flow.supplementaryMessage || (root.flow.failed ? "That wasn't it. Try again." : "")) : ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        BlockButton { Layout.fillWidth: true; Layout.preferredHeight: 44; text: "Cancel"; onClicked: root.cancel() }
                        BlockButton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            text: "Authenticate"
                            active: true
                            enabled: root.flow !== null && (!root.flow.isResponseRequired || input.text.length > 0)
                            onClicked: root.submit()
                        }
                    }
                }
            }
        }
    }

    function submit() {
        if (!flow) return
        flow.submit(input.text)
        input.text = ""
    }
    function cancel() {
        if (flow) flow.cancelAuthenticationRequest()
        input.text = ""
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() { shakeAnim.restart() }
        function onIsResponseRequiredChanged() { input.text = ""; input.forceActiveFocus() }
    }
}
