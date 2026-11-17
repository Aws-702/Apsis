// Shot: Edit Desktop with the widget tray.
// Edit: widget places in demo/state/widgets.json.

import QtQuick
import "../qs/desktop"
import "../qs/services"
Item {
    DesktopLayer {}
    EditOverlay {}
    Timer { interval: 400; running: true; onTriggered: EditMode.toggle() }
}
