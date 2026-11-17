// Stand-in for StdioCollector: hands the demo output over in one piece.
// Edit: nothing.

import QtQuick
QtObject { property string text: ""; property bool waitForEnd: true; signal streamFinished() }
