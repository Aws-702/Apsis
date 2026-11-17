// Stand-in for SplitParser: hands the demo output over line by line.
// Edit: nothing.

import QtQuick
QtObject { property string splitMarker: "\n"; signal read(string data) }
