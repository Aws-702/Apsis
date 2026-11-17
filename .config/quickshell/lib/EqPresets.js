.pragma library

// The equalizer's ten bands and its starting curves.
// Edit: PRESETS for curves, MIN and MAX for the gain range.

var FREQS = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
var MIN = -12
var MAX = 12

var PRESETS = {
    "Flat":       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    "Bass":       [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
    "Vocal":      [-2, -2, -1, 1, 3, 4, 3, 1, 0, -1],
    "Treble":     [0, 0, 0, 0, 0, 1, 2, 4, 5, 6],
    "Rock":       [4, 3, 1, -1, -2, -1, 1, 3, 4, 4],
    "Electronic": [5, 4, 1, 0, -2, 1, 0, 1, 4, 5],
    "Acoustic":   [3, 3, 2, 1, 1, 1, 2, 2, 2, 1]
}
var ORDER = ["Flat", "Bass", "Vocal", "Treble", "Rock", "Electronic", "Acoustic"]

function clamp(g) { return Math.max(MIN, Math.min(MAX, Math.round(g * 2) / 2)) }

function label(f) { return f >= 1000 ? (f / 1000) + "k" : String(f) }

function nameOf(gains) {
    for (var i = 0; i < ORDER.length; i++) {
        var p = PRESETS[ORDER[i]], same = true
        for (var b = 0; b < 10; b++) if (Math.abs((gains[b] || 0) - p[b]) > 0.01) { same = false; break }
        if (same) return ORDER[i]
    }
    return "Custom"
}

function headroom(gains) {
    var top = 0
    for (var i = 0; i < gains.length; i++) top = Math.max(top, gains[i])
    return -top
}
