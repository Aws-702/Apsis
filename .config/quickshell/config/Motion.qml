// One set of timings and curves for the whole shell: press, pop, rise, sink, flip.
// Edit: the ms and overshoot values here change how everything moves.

pragma Singleton
import QtQuick
import Quickshell

Singleton {

    readonly property int pressMs: 80
    readonly property int releaseMs: 260
    readonly property real releaseOvershoot: 2.2

    readonly property int popInMs: 320
    readonly property real popOvershoot: 1.6
    readonly property int popOutMs: 170
    readonly property real popFrom: 0.86

    readonly property int riseMs: 460
    readonly property real riseOvershoot: 1.25
    readonly property int sinkMs: 260
    readonly property int flipMs: 640
    readonly property real flipOvershoot: 1.1

    readonly property int quickMs: 140
    readonly property int snapMs: 120
}
