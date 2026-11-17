// Stand-in for the notification server: no notifications.
// Edit: nothing.

import QtQuick
QtObject { property bool keepOnReload: true; property bool actionsSupported; property bool bodySupported; property bool bodyMarkupSupported; property bool imageSupported; property bool persistenceSupported; property bool actionIconsSupported; property bool bodyHyperlinksSupported; property bool bodyImagesSupported; property bool inlineReplySupported; readonly property var trackedNotifications: ({ values: [] }); signal notification(var notification) }
