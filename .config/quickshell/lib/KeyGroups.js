.pragma library

// Sorts binds for the cheat sheet into groups, deals the groups into even columns, and splits combos into keycaps.
// Edit: NAMES for key names, the group() rules for which group a bind lands in.

var GROUPS = ["Apps", "Phone and desktop", "Windows", "Workspaces", "System", "Media"]

function group(label) {
    var l = String(label || "").toLowerCase()
    if (/volume|mic mute|brightness|play|track/.test(l)) return "Media"
    if (/game mode|focus mode/.test(l)) return "System"
    if (/workspace|scratchpad/.test(l)) return "Workspaces"
    if (/window|floating|fullscreen|group|split|focus/.test(l)) return "Windows"
    if (/phone|quick panel|settings|edit desktop|dock|palette|dark|overview|cheat|wallpaper|clipboard|emoji|notification/.test(l)) return "Phone and desktop"
    if (/lock|power|exit|screenshot|record|picker|ultra|training/.test(l)) return "System"
    return "Apps"
}

var NAMES = {
    "XF86AudioRaiseVolume": "Vol +", "XF86AudioLowerVolume": "Vol -", "XF86AudioMute": "Mute",
    "XF86AudioMicMute": "Mic", "XF86MonBrightnessUp": "Bright +", "XF86MonBrightnessDown": "Bright -",
    "XF86AudioPlay": "Play", "XF86AudioNext": "Next", "XF86AudioPrev": "Prev",
    "CONTROL": "Ctrl", "SUPER": "Super", "SHIFT": "Shift", "ALT": "Alt",
    "space": "Space", "slash": "/", "period": ".", "comma": ",", "Escape": "Esc", "Return": "Enter",
    "left": "Left", "right": "Right", "up": "Up", "down": "Down", "Print": "Print", "Tab": "Tab"
}

function caps(combo) {
    return String(combo || "").split("+").map(function(k) { k = k.trim(); return NAMES[k] || NAMES[k.toUpperCase()] || (k.length === 1 ? k.toUpperCase() : k) })
                               .filter(function(k) { return k !== "" })
}

function sections(binds, filter) {
    var f = String(filter || "").toLowerCase().trim()
    var by = {}
    for (var i = 0; i < binds.length; i++) {
        var b = binds[i]
        if (f && (b.label + " " + caps(b.combo).join(" ")).toLowerCase().indexOf(f) < 0) continue
        var g = b.group || group(b.label)
        if (!by[g]) by[g] = []
        by[g].push(b)
    }
    var out = []
    for (var k = 0; k < GROUPS.length; k++) if (by[GROUPS[k]]) out.push({ name: GROUPS[k], binds: by[GROUPS[k]] })
    return out
}

function columns(list, n) {
    var cols = [], load = [], i, k
    n = Math.max(1, n | 0)
    for (k = 0; k < n; k++) { cols.push([]); load.push(0) }
    var order = list.map(function(s, at) { return { s: s, at: at, w: s.binds.length + 2 } })
                    .sort(function(a, b) { return b.w - a.w || a.at - b.at })
    for (i = 0; i < order.length; i++) {
        var best = 0
        for (k = 1; k < n; k++) if (load[k] < load[best]) best = k
        cols[best].push(order[i])
        load[best] += order[i].w
    }
    var firsts = cols.map(function(c) { return c.length ? Math.min.apply(null, c.map(function(o) { return o.at })) : 1e9 })
    var idx = firsts.map(function(f, at) { return at }).sort(function(a, b) { return firsts[a] - firsts[b] })
    return idx.map(function(at) { return cols[at].sort(function(a, b) { return a.at - b.at }).map(function(o) { return o.s }) })
}

var EXTRA = [
    { combo: "SUPER + 1-0", label: "Go to workspace 1 to 10", group: "Workspaces" },
    { combo: "SUPER + SHIFT + 1-0", label: "Move window to workspace", group: "Workspaces" },
    { combo: "SUPER + Scroll", label: "Next / previous workspace", group: "Workspaces" },
    { combo: "SUPER + Drag", label: "Move window", group: "Windows" },
    { combo: "SUPER + Right drag", label: "Resize window", group: "Windows" }
]
