// Stand-in for WlSessionLock: never locks.
// Edit: nothing.

import QtQuick
QtObject { default property Component surface; property bool locked: false; property bool secure: false }
