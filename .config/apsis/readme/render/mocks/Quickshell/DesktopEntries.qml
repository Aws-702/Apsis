// Stand-in for DesktopEntries: the demo apps from demo.json.
// Edit: the apps in demo.json (apps).

pragma Singleton
import QtQuick
import ShotLab
QtObject {
    function om(a) { var r = []; for (var i = 0; a && i < a.length; i++) r.push(a[i]); return { values: r } }
    readonly property var applications: om(Shot.apps())
    function byId(id) { var a = applications.values; for (var i = 0; i < a.length; i++) if (a[i].id === id) return a[i]; return null }
    function heuristicLookup(name) { var a = applications.values; var n = String(name || "").toLowerCase(); for (var i = 0; i < a.length; i++) if (a[i].id.toLowerCase().indexOf(n) >= 0 || a[i].name.toLowerCase() === n) return a[i]; return null }
}
