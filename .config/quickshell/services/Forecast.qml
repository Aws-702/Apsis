// The coming days and hours from apsis-weather-full.sh, read every 30 minutes while shown.
// Edit: the refresh interval here; the API call in hypr/scripts/apsis-weather-full.sh.

pragma Singleton
import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    property int want: 0
    property var daily: []
    property var hourly: []
    readonly property bool has: daily.length > 0

    property Poll poll: Poll {
        active: root.want > 0
        interval: 1800000
        command: ["sh", "-c", Config.scripts + "/apsis-weather-full.sh"]
        onUpdated: function(out) {
            try {
                var j = JSON.parse(out)
                root.daily = j.daily || []
                root.hourly = j.hourly || []
            } catch (e) {}
        }
    }
}
