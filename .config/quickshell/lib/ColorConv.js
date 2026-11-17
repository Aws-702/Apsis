.pragma library

// Colour codes typed in Apps search: hex, rgb() and hsl() in and out.
// Edit: output formats in the format functions.

function clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }

function parse(s) {
    s = String(s || "").trim().toLowerCase()
    var m
    if ((m = /^#?([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/.exec(s)) && (s.charAt(0) === "#" || m[1].length === 6)) {
        var h = m[1]
        if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2]
        return { r: parseInt(h.substr(0, 2), 16), g: parseInt(h.substr(2, 2), 16), b: parseInt(h.substr(4, 2), 16),
                 a: h.length === 8 ? Math.round(parseInt(h.substr(6, 2), 16) / 255 * 100) / 100 : 1 }
    }
    if ((m = /^rgba?\(\s*(\d+)\s*,?\s*(\d+)\s*,?\s*(\d+)\s*(?:[,/]\s*([\d.]+%?))?\s*\)$/.exec(s)))
        return { r: clamp(+m[1], 0, 255), g: clamp(+m[2], 0, 255), b: clamp(+m[3], 0, 255), a: alpha(m[4]) }
    if ((m = /^hsla?\(\s*([\d.]+)(?:deg)?\s*,?\s*([\d.]+)%\s*,?\s*([\d.]+)%\s*(?:[,/]\s*([\d.]+%?))?\s*\)$/.exec(s))) {
        var c = fromHsl(+m[1], +m[2], +m[3])
        c.a = alpha(m[4])
        return c
    }
    return null
}

function alpha(v) {
    if (v === undefined) return 1
    return clamp(String(v).indexOf("%") >= 0 ? parseFloat(v) / 100 : parseFloat(v), 0, 1)
}

function fromHsl(h, s, l) {
    h = ((h % 360) + 360) % 360; s = clamp(s, 0, 100) / 100; l = clamp(l, 0, 100) / 100
    var c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs((h / 60) % 2 - 1)), m = l - c / 2
    var rgb = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x]
    return { r: Math.round((rgb[0] + m) * 255), g: Math.round((rgb[1] + m) * 255), b: Math.round((rgb[2] + m) * 255), a: 1 }
}

function hex(c) {
    function two(v) { var s = Math.round(v).toString(16); return s.length < 2 ? "0" + s : s }
    return "#" + two(c.r) + two(c.g) + two(c.b) + (c.a < 1 ? two(c.a * 255) : "")
}

function rgb(c) { return c.a < 1 ? "rgba(" + c.r + ", " + c.g + ", " + c.b + ", " + c.a + ")" : "rgb(" + c.r + ", " + c.g + ", " + c.b + ")" }

function hsl(c) {
    var r = c.r / 255, g = c.g / 255, b = c.b / 255
    var max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min
    var h = 0, s = 0, l = (max + min) / 2
    if (d > 0) {
        s = d / (1 - Math.abs(2 * l - 1))
        h = max === r ? 60 * (((g - b) / d) % 6) : max === g ? 60 * ((b - r) / d + 2) : 60 * ((r - g) / d + 4)
    }
    if (h < 0) h += 360
    return "hsl(" + Math.round(h) + ", " + Math.round(s * 100) + "%, " + Math.round(l * 100) + "%)"
}

function isLight(c) { return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 160 }
