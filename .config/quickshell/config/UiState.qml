// Small shared UI state: which bar card is open, privacy lists, power menu and phone toggles.
// Edit: nothing visual here.

pragma Singleton
import QtQuick
import Quickshell

Singleton {

    property string barPopup: ""
    property real barPopupX: 0
    function toggleBarPopup(name, x) {
        if (barPopup === name) { barPopup = ""; return }
        barPopupX = x
        barPopup = name
    }

    property var privacyMic: []
    property var privacyVideo: []

    property bool powerMenuOpen: false

    property bool settingsOpen: false
    property bool launcherOpen: false
    property real settingsAnchorX: 0
}
