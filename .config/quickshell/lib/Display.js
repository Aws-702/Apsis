.pragma library

// Monitor modes for Settings > Display: resolutions, rates and scales that give whole pixels.
// Edit: the allowed scale list here.

function modes(available) {
    var by = {}, out = []
    var list = available || []
    for (var i = 0; i < list.length; i++) {
        var m = /^(\d+)x(\d+)@([\d.]+)/.exec(String(list[i]))
        if (!m) continue
        var res = m[1] + "x" + m[2]
        var rate = Math.round(parseFloat(m[3]) * 100) / 100
        if (!by[res]) { by[res] = { res: res, w: parseInt(m[1]), h: parseInt(m[2]), rates: [] }; out.push(by[res]) }
        if (by[res].rates.indexOf(rate) < 0) by[res].rates.push(rate)
    }
    out.forEach(function(r) { r.rates.sort(function(a, b) { return b - a }) })
    out.sort(function(a, b) { return b.w * b.h - a.w * a.h || b.w - a.w })
    return out
}

function mode(res, rate) { return res + "@" + Number(rate).toFixed(2) }

function nearest(rates, want) {
    var best = rates.length ? rates[0] : want
    for (var i = 0; i < rates.length; i++) if (Math.abs(rates[i] - want) < Math.abs(best - want)) best = rates[i]
    return best
}

var SCALES = [1, 1.25, 1.333333, 1.5, 1.6, 1.666667, 1.75, 2, 2.5, 3]
function scales(w, h) {
    return SCALES.filter(function(s) {
        var a = w / s, b = h / s
        return Math.abs(a - Math.round(a)) < 0.01 && Math.abs(b - Math.round(b)) < 0.01
    }).slice(0, 6)
}
function scaleText(s) { return String(Math.round(s * 100)) + "%" }

function scaleArg(s) { return String(Math.round(s * 1e6) / 1e6) }

function current(mon) {
    return {
        mode: mon.width + "x" + mon.height + "@" + Number(mon.refreshRate || 60).toFixed(2),
        pos: (mon.x || 0) + "x" + (mon.y || 0),
        scale: scaleArg(mon.scale || 1),
        transform: String((mon.transform || 0) % 8),
        mirror: mon.mirrorOf && mon.mirrorOf !== "none" ? String(mon.mirrorOf) : "-"
    }
}

function args(name, l) { return [name, l.mode, l.pos, l.scale, l.transform, l.mirror || "-"] }
