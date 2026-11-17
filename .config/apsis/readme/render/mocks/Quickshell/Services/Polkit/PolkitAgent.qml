// Stand-in for the polkit agent: never asks.
// Edit: nothing.

import QtQuick
QtObject { readonly property bool isRegistered: false; readonly property bool isActive: false; readonly property var flow: null; property string path }
