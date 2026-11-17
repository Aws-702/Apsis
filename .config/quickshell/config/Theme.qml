// The palettes (cherry, navy, auto) as roles, and every token derived from them for each mode.
// Edit: roles for colours, radius*, block*, shadowOffset* for the block shape, fontText for the font.

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string palette: "cherry"
    property string mode: "dark"
    readonly property bool isDarkMode: mode !== "light"
    readonly property bool darker: mode === "darker"
    readonly property bool light: mode === "light"

    property var autoColors: ({})

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/apsis-palette"
        watchChanges: true
        preload: true
        printErrors: false

        onFileChanged: { reload(); autoFile.reload() }
        onTextChanged: {
            var s = text().trim()
            if (s === "cherry" || s === "navy" || s === "auto") root.palette = s
        }
    }

    FileView {
        id: modeFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/apsis-mode"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            var s = text().trim()
            if (s === "dark" || s === "darker" || s === "light") root.mode = s
        }
    }

    FileView {
        id: autoFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/apsis-auto.json"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: {
            try {
                var t = text().trim()
                root.autoColors = t.length ? JSON.parse(t) : ({})
            } catch (e) {
                root.autoColors = ({})
            }
        }
    }

    readonly property var roles: ({
        cherry: {
            bgMain: "#17090F", bgCard: "#210D15", bgItem: "#351421", bgHover: "#4A1D2E",
            textPrimary: "#F6E9EF", textSecondary: "#C99BAB",
            accent: "#EC4C78", accentHot: "#FF5C8A", cyan: "#5AD1C8",
            warn: "#F6B17A", danger: "#FF6B81"
        },
        navy: {
            bgMain: "#0A0A3C", bgCard: "#101445", bgItem: "#1C2160", bgHover: "#2A3080",
            textPrimary: "#F3ECF5", textSecondary: "#98A0D0",
            accent: "#3AD6E0", accentHot: "#0FF0FC", cyan: "#0FF0FC",
            warn: "#F6B17A", danger: "#FF6B81"
        }
    })

    function role(key) {
        if (palette === "navy") return roles.navy[key]
        if (palette === "auto") {
            var v = autoColors ? autoColors[key] : undefined
            if (v !== undefined && v !== null && v !== "") return v
        }
        return roles.cherry[key]
    }

    function mix(a, b, t) {
        var ca = Qt.color(a), cb = Qt.color(b)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t,
                       ca.b + (cb.b - ca.b) * t, ca.a + (cb.a - ca.a) * t)
    }
    function alpha(c, a) {
        var q = Qt.color(c)
        return Qt.rgba(q.r, q.g, q.b, a)
    }

    readonly property color _deep: role("bgMain")
    readonly property color _card: role("bgCard")
    readonly property color _item: role("bgItem")
    readonly property color _hover: role("bgHover")
    readonly property color _ink: role("textPrimary")
    readonly property color _inkSub: role("textSecondary")

    readonly property color bgMain: light ? mix("#ffffff", accent, 0.07)
                                   : (darker ? Qt.darker(_deep, 1.45) : _deep)
    readonly property color bgCard: light ? mix("#ffffff", accent, 0.03)
                                   : (darker ? Qt.darker(_card, 1.4) : _card)
    readonly property color bgItem: light ? mix("#ffffff", accent, 0.11)
                                   : (darker ? Qt.darker(_item, 1.35) : _item)
    readonly property color bgHover: light ? mix("#ffffff", accent, 0.20)
                                    : (darker ? Qt.darker(_hover, 1.25) : _hover)
    readonly property color textPrimary: light ? mix(_deep, "#000000", 0.15) : _ink
    readonly property color textSecondary: light ? mix(textPrimary, "#ffffff", 0.42) : _inkSub

    readonly property color accent: role("accent")
    readonly property color accentHot: role("accentHot")
    readonly property color cyan: role("cyan")
    readonly property color warn: role("warn")
    readonly property color danger: role("danger")

    readonly property color onAccent: light ? "#ffffff" : bgMain
    readonly property color cream: "#FFF5C3"

    readonly property color outline: light ? alpha(textPrimary, 0.14) : alpha(_ink, 0.10)

    readonly property color accentGreen: accent
    readonly property color accentOrange: warn
    readonly property color accentRed: danger

    readonly property color line: light ? mix(_deep, "#ffffff", 0.18)
                                 : mix(_deep, "#000000", darker ? 0.75 : 0.55)
    readonly property color ring: light ? "#ffffff" : mix(_ink, accent, 0.16)
    readonly property color ringActive: light ? mix("#ffffff", accent, 0.35) : mix(_ink, accent, 0.45)
    readonly property color shadow: light ? alpha(mix("#ffffff", _deep, 0.55), 0.9)
                                   : alpha(mix(_deep, "#000000", 0.8), 0.92)

    readonly property color scrim: light ? alpha(_deep, 0.18) : alpha(mix(_deep, "#000000", 0.5), 0.55)

    readonly property int radiusOuter: 14
    readonly property int radiusInner: 10
    readonly property int radiusBlock: 14

    readonly property real blockBorder: 3
    readonly property real blockRing: 2
    readonly property real shadowOffset: 4

    readonly property real blockBorderSm: 2
    readonly property real blockRingSm: 1.5
    readonly property real shadowOffsetSm: 3

    readonly property string fontText: "JetBrainsMono Nerd Font"
    readonly property string fontIcon: "Symbols Nerd Font"
}
