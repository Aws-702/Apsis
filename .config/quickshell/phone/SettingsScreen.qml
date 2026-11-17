// The landscape phone: a rail of page keys on the left, the page on the right.
// Edit: the page list and rail width here; the pages in phone/settings/.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"
import "settings"

Item {
    id: root
    readonly property bool shown: PhoneState.open && PhoneState.screen === "settings"

    readonly property var pages: [
        { id: "theme", label: "Theme", icon: Icons.theme },
        { id: "wallpapers", label: "Wallpapers", icon: Icons.image },
        { id: "desktop", label: "Desktop", icon: Icons.layers },
        { id: "display", label: "Display", icon: Icons.display },
        { id: "keys", label: "Shortcuts", icon: Icons.keyboard },
        { id: "about", label: "About", icon: Icons.info }
    ]

    StatusRow {
        id: status
        wide: true
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 6; leftMargin: 30; rightMargin: 24 }
    }

    ColumnLayout {
        id: rail
        anchors { left: parent.left; top: status.bottom; bottom: parent.bottom; leftMargin: 30; topMargin: 8; bottomMargin: 22 }
        width: 186
        spacing: 10

        RowLayout {
            spacing: 10
            BlockButton { Layout.preferredWidth: 44; Layout.preferredHeight: 46; icon: Icons.back; onClicked: PhoneState.back() }
            Label { text: "Settings"; font.pixelSize: 18; font.weight: Font.DemiBold }
        }
        Item { Layout.preferredHeight: 4 }
        Repeater {
            model: root.pages
            BlockButton {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                align: Qt.AlignLeft
                icon: modelData.icon
                iconSize: 17
                text: modelData.label
                active: PhoneState.settingsPage === modelData.id
                onClicked: PhoneState.settingsPage = modelData.id
            }
        }
        Item { Layout.fillHeight: true }
    }

    Block {
        id: pane
        anchors { left: rail.right; right: parent.right; top: status.bottom; bottom: parent.bottom; leftMargin: 18; rightMargin: 24; topMargin: 8; bottomMargin: 18 }
        fill: Theme.bgMain
        small: true
        radius: 22

        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: pageBox.implicitHeight + 16
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: pageBox
                width: flick.width
                sourceComponent: {
                    switch (PhoneState.settingsPage) {
                    case "wallpapers": return wallPage
                    case "desktop": return desktopPage
                    case "display": return displayPage
                    case "keys": return keysPage
                    case "about": return aboutPage
                    default: return themePage
                    }
                }
                onLoaded: flick.contentY = 0
            }
        }
    }

    Component { id: themePage; ThemePage { active: root.shown } }
    Component { id: wallPage; WallpapersPage { active: root.shown } }
    Component { id: desktopPage; DesktopPage { active: root.shown } }
    Component { id: displayPage; DisplayPage { active: root.shown } }
    Component { id: keysPage; KeysPage { active: root.shown } }
    Component { id: aboutPage; AboutPage { active: root.shown } }
}
