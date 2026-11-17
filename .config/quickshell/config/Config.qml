// Shell wide settings: bar height and margin, the terminal, and the paths everything uses.
// Edit: barHeight, barMargin and terminal here.

pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property int  barHeight:   46
    property int  barMargin:   6

    property string terminal: "kitty"

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")) + "/apsis"
    readonly property string cacheDir: home + "/.cache/quickshell"
    readonly property string scripts: home + "/.config/hypr/scripts"

    readonly property bool ultra: Quickshell.env("APSIS_ULTRA") === "1"

    readonly property bool soft: Quickshell.env("QT_QUICK_BACKEND") === "software"
}
