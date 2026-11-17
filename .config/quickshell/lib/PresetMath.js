.pragma library

// Desktop presets: what a look carries (palette, mode, widgets, dock, bar) and never your content.
// Edit: what a preset saves in capture() and apply().

var VERSION = 2

var V1_TYPES = ["clock", "calendar", "weather", "media", "visualizer", "lyrics", "todo", "note", "stats"]

function clone(v) {
    return JSON.parse(JSON.stringify(v))
}

function stripPersonal(w, types) {
    var t = types[w.type]
    var out = { id: w.id, type: w.type, x: w.x, y: w.y, screen: w.screen || "", style: clone(w.style || {}) }
    if (t) out.style = styleFrom(t, out.style)
    return out
}

function styleFrom(t, style) {
    var out = {}
    for (var k in t.style) out[k] = style.hasOwnProperty(k) ? style[k] : t.style[k]
    return out
}

function capture(name, state, types) {
    var widgets = []
    var src = state.widgets || []
    for (var i = 0; i < src.length; i++)
        if (types[src[i].type]) widgets.push(stripPersonal(src[i], types))
    return {
        version: VERSION,
        name: name,
        types: Object.keys(types).sort(),
        palette: state.palette || "cherry",
        mode: state.mode || "dark",
        widgets: widgets,
        dock: clone(state.dock || { enabled: true, autohide: true }),
        bar: clone(state.bar || { shown: true })
    }
}

function apply(preset, current, types) {
    var cur = current.widgets || []
    var byId = {}
    var byType = {}
    for (var i = 0; i < cur.length; i++) {
        byId[cur[i].id] = cur[i]
        if (!byType[cur[i].type]) byType[cur[i].type] = cur[i]
    }
    var widgets = []
    var src = preset.widgets || []
    for (var j = 0; j < src.length; j++) {
        var p = src[j]
        var t = types[p.type]
        if (!t) continue
        var w = { id: p.id, type: p.type, x: p.x, y: p.y, screen: p.screen || "", style: styleFrom(t, p.style || {}) }
        var donor = byId[p.id] || byType[p.type]
        for (var k = 0; k < t.personal.length; k++) {
            var f = t.personal[k]
            if (donor && donor.hasOwnProperty(f)) w[f] = clone(donor[f])
        }
        widgets.push(w)
    }

    var known = {}
    var kt = preset.types || V1_TYPES
    for (var q = 0; q < kt.length; q++) known[kt[q]] = true
    for (var r = 0; r < cur.length; r++)
        if (types[cur[r].type] && !known[cur[r].type]) widgets.push(clone(cur[r]))
    return {
        palette: preset.palette || current.palette,
        mode: preset.mode || current.mode,
        widgets: widgets,
        dock: preset.dock ? clone(preset.dock) : clone(current.dock),
        bar: preset.bar ? clone(preset.bar) : clone(current.bar)
    }
}

function safeName(name) {
    var s = String(name || "").trim().replace(/[^A-Za-z0-9 _-]/g, "").replace(/\s+/g, " ")
    return s.substring(0, 40)
}

function sortedNames(presets) {
    return Object.keys(presets || {}).sort(function(a, b) {
        var fa = presets[a] && presets[a].favorite ? 0 : 1
        var fb = presets[b] && presets[b].favorite ? 0 : 1
        if (fa !== fb) return fa - fb
        var la = a.toLowerCase(), lb = b.toLowerCase()
        return la < lb ? -1 : (la > lb ? 1 : 0)
    })
}

function rename(presets, from, to) {
    var n = safeName(to)
    if (!n.length) return { ok: false, presets: presets, why: "empty" }
    if (!presets || !presets.hasOwnProperty(from)) return { ok: false, presets: presets, why: "missing" }
    if (n !== from && presets.hasOwnProperty(n)) return { ok: false, presets: presets, why: "exists" }
    var out = {}
    var names = Object.keys(presets)
    for (var i = 0; i < names.length; i++) {
        if (names[i] === from) { var p = clone(presets[from]); p.name = n; out[n] = p }
        else out[names[i]] = presets[names[i]]
    }
    return { ok: true, presets: out, why: "" }
}
