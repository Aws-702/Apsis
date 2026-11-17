// Shot: the desktop with its widgets and the dock.
// Edit: widget places in demo/state/widgets.json, dock pins in demo/state/dock.json.

import QtQuick
import "../qs/desktop"
import "../qs/dock"
Item {
    DesktopLayer {}
    DockBar {}
}
