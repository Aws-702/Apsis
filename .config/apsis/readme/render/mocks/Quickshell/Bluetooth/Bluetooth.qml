// Stand-in for Quickshell.Bluetooth: one powered adapter and the demo devices from demo.json.
// Edit: the devices in demo.json (bluetooth).

pragma Singleton
import QtQuick
import ShotLab
QtObject {
    function om(a) { var r = []; for (var i = 0; a && i < a.length; i++) r.push(a[i]); return { values: r } }
    property QtObject defaultAdapter: QtObject {
        property bool enabled: true
        property bool discovering: false
        property string name: "Studio"
        property var devices: om(Shot.btDevices())
    }
    readonly property var adapters: om([defaultAdapter])
    readonly property var devices: defaultAdapter.devices
}
