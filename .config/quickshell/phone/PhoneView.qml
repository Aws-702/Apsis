// The phone with its screens; portrait screens slide, Settings lives in landscape.
// Edit: the slide distance here; screen order in lib/PhoneRoute.js.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"
import "../lib/PhoneRoute.js" as Route

PhoneStage {
    id: stage

    readonly property string scr: PhoneState.screen
    focus: true
    Keys.onEscapePressed: PhoneState.back()

    portrait: [
        Item {
            id: portraitScreens
            anchors.fill: parent

            component Slot: Item {
                id: slot
                property string name
                property int order: 0
                readonly property bool on: PhoneState.open ? PhoneState.lastPortrait === name : (name === "quick" && !PhoneState.alerting)
                readonly property int current: Route.order(PhoneState.lastPortrait)
                width: parent.width
                height: parent.height
                x: on ? 0 : (order <= current ? -width * 0.35 : width * 0.35)
                opacity: on ? 1 : 0
                visible: opacity > 0.01
                enabled: on
                Behavior on x { NumberAnimation { duration: Motion.popInMs; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on opacity { NumberAnimation { duration: Motion.popOutMs } }
            }

            Slot { name: "quick"; order: 0; QuickScreen { anchors.fill: parent } }
            Slot { name: "apps"; order: 1; AppsScreen { anchors.fill: parent } }

            component Lazy: Loader {
                id: lazy
                property string name
                property string needs
                anchors.fill: parent
                active: PhoneState.lastPortrait === name || item !== null
                asynchronous: false
                source: ({ sound: "SoundScreen.qml", eq: "EqScreen.qml", wifi: "WifiScreen.qml", bluetooth: "BluetoothScreen.qml", updates: "UpdatesScreen.qml", notifications: "NotificationsScreen.qml" })[name] || ""
                Item {
                    anchors.fill: parent
                    visible: lazy.status === Loader.Error
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 60
                        spacing: 10
                        Label { text: "Can't open this screen"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                        Label { sub: true; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                            text: "It needs Quickshell's " + lazy.needs + " module. Update quickshell, then restart the shell (qs kill; qs -d)." }
                        BlockButton { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 120; Layout.preferredHeight: 44; icon: Icons.back; text: "Back"; onClicked: PhoneState.back() }
                    }
                }
            }
            Slot { name: "sound"; order: 2; Lazy { name: "sound"; needs: "Pipewire" } }
            Slot { name: "eq"; order: 3; Lazy { name: "eq"; needs: "Io" } }
            Slot { name: "wifi"; order: 4; Lazy { name: "wifi"; needs: "Io" } }
            Slot { name: "bluetooth"; order: 5; Lazy { name: "bluetooth"; needs: "Bluetooth" } }
            Slot { name: "updates"; order: 6; Lazy { name: "updates"; needs: "Io" } }
            Slot { name: "notifications"; order: 7; Lazy { name: "notifications"; needs: "Io" } }

            Item {
                anchors.fill: parent
                opacity: PhoneState.alerting ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.popOutMs } }
                AlertCard { anchors.fill: parent }
            }
        }
    ]

    landscape: [
        SettingsScreen { anchors.fill: parent }
    ]

}
