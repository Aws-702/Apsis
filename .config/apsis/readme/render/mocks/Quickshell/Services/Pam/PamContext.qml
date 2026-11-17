// Stand-in for PamContext: never asks and never unlocks.
// Edit: nothing.

import QtQuick
QtObject { property string config; property string configDirectory; property string user; property bool active: false; readonly property bool responseRequired: false; readonly property string message: ""; readonly property bool messageIsError: false; signal completed(int result); signal error(int error); signal pamMessage(); function start() { return true }; function abort() {}; function respond(r) {} }
