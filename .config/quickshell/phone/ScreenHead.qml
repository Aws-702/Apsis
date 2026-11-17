// The top of a detail screen: Back, the title, the subtitle and a slot on the right.
// Edit: title size here.

import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"
import "../widgets"

RowLayout {
    id: root
    property string title: ""
    property string sub: ""
    default property alias trailing: slot.data

    spacing: 10
    BlockButton { Layout.preferredWidth: 46; Layout.preferredHeight: 48; icon: Icons.back; onClicked: PhoneState.back() }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Label { text: root.title; font.pixelSize: 18; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
        Label { sub: true; text: root.sub; visible: text !== ""; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
    }
    RowLayout {
        id: slot
        spacing: 8
    }
}
