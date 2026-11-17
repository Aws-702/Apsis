// The bar: one wide block on the top or bottom edge with the modules as small keycaps.
// Edit: height and margin in config/Config.qml; styles and key order here and in lib/BarLayout.js.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config"
import "../services"
import "../widgets"
import "modules"
import "../lib/BarLayout.js" as BarLayout

PanelWindow {
    id: bar

    property bool barShown: true

    anchors { top: !Settings.barAtBottom; bottom: Settings.barAtBottom; left: true; right: true }
    implicitHeight: Config.barHeight + Settings.barGap * 2
    color: "transparent"
    visible: barShown

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "apsis-bar"
    exclusiveZone: barShown ? Settings.barSpace : 0

    FileView {
        path: Config.cacheDir + "/apsis-bar"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: bar.barShown = (text().trim() !== "hide")
    }

    Block {
        id: shell
        anchors {
            left: parent.left; right: parent.right
            top: Settings.barAtBottom ? undefined : parent.top
            bottom: Settings.barAtBottom ? parent.bottom : undefined
            margins: Settings.barGap
        }
        height: Config.barHeight
        radius: Settings.barStyle === "slim" ? 0 : 16
        fill: Theme.bgCard

        bare: Settings.barStyle === "floating"
        flat: Settings.barStyle === "slim"

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 2
            spacing: 0
            Repeater { model: bar.layout.left; delegate: slotC }
        }

        RowLayout {
            anchors.centerIn: parent
            height: parent.height - 2
            spacing: 0
            Repeater { model: bar.layout.center; delegate: slotC }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height - 2
            spacing: 0
            Repeater { model: bar.layout.right; delegate: slotC }
        }
    }

    readonly property var layout: BarLayout.normalize(Settings.barModules)

    Component {
        id: slotC
        Loader {
            required property string modelData
            readonly property bool shown: item !== null && item.visible && item.implicitWidth > 0
            Layout.fillHeight: true
            Layout.preferredWidth: shown ? item.implicitWidth : 0
            Layout.maximumWidth: shown ? item.implicitWidth : 0
            Layout.leftMargin: shown ? 3 : 0
            Layout.rightMargin: shown ? 3 : 0
            sourceComponent: ({
                workspaces: cWorkspaces, resources: cResources, clock: cClock, media: cMedia,
                record: cRecord, ultra: cUltra, modes: cModes, tray: cTray, privacy: cPrivacy,
                keyboard: cKeyboard, network: cNetwork, bluetooth: cBluetooth, mic: cMic,
                volume: cVolume, battery: cBattery, name: cName, settings: cSettings
            })[modelData] || null
        }
    }
    Component { id: cWorkspaces; Workspaces {} }
    Component { id: cResources; Resources {} }
    Component { id: cClock; Clock {} }
    Component { id: cMedia; Media {} }
    Component { id: cRecord; RecordKey {} }
    Component { id: cUltra; UltraKey {} }
    Component { id: cModes; ModeKeys {} }
    Component { id: cTray; Tray {} }

    Component {
        id: cPrivacy
        Item {
            implicitWidth: pl.item && pl.item.visible ? pl.item.implicitWidth : 0
            implicitHeight: pl.item ? pl.item.implicitHeight : 0
            Loader { id: pl; anchors.fill: parent; source: "modules/Privacy.qml" }
        }
    }
    Component { id: cKeyboard; Keyboard {} }
    Component { id: cNetwork; Network {} }
    Component { id: cBluetooth; Bluetooth {} }
    Component { id: cMic; Mic {} }
    Component { id: cVolume; Volume {} }
    Component { id: cBattery; Battery {} }
    Component { id: cName; Label { text: Settings.userName; sub: true; leftPadding: 4; rightPadding: 2; verticalAlignment: Text.AlignVCenter } }
    Component { id: cSettings; SettingsButton {} }

    BarPopup { screen: bar.screen }
}
