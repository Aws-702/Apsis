// Shot: the phone on Updates, reviewing the pinned groups.
// Edit: the update list and pins in demo.json (apsis-updates.sh).

import QtQuick
import ShotLab
import "../qs/desktop"
import "../qs/dock"
import "../qs/phone"
import "../qs/services"
Item {
    DesktopLayer {}
    DockBar {}
    Phone {}
    function find(it, name) {
        if (!it) return null
        if (typeof it[name] === "function") return it
        for (var i = 0; i < it.children.length; i++) { var r = find(it.children[i], name); if (r) return r }
        return null
    }
    Timer { interval: 400; running: true; onTriggered: PhoneState.openOn("updates") }
    Timer { interval: 1400; running: true; onTriggered: { var u = find(Shot.root, "pressUpdate"); if (u) u.pressUpdate() } }
}
