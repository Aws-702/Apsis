.pragma library

// Which keys sit where on the bar (left, center, right); settings can never be removed.
// Edit: DEFAULT for the starting layout, MODULES for the keys that exist.

var GROUPS = ["left", "center", "right"]

var MODULES = [
    { id: "workspaces", title: "Workspaces" },
    { id: "resources", title: "CPU and memory" },
    { id: "clock", title: "Clock" },
    { id: "media", title: "Now playing" },
    { id: "record", title: "Recording key" },
    { id: "ultra", title: "Ultra saver key" },
    { id: "modes", title: "Game and Focus keys" },
    { id: "tray", title: "Tray" },
    { id: "privacy", title: "Mic and camera in use" },
    { id: "keyboard", title: "Keyboard layout" },
    { id: "network", title: "Network" },
    { id: "bluetooth", title: "Bluetooth" },
    { id: "mic", title: "Microphone" },
    { id: "volume", title: "Volume" },
    { id: "battery", title: "Battery" },
    { id: "name", title: "Your name" },
    { id: "settings", title: "Settings key" }
]

var DEFAULT = {
    left: ["workspaces", "resources"],
    center: ["clock", "media"],
    right: ["record", "ultra", "modes", "tray", "privacy", "keyboard", "network", "bluetooth", "mic", "volume", "battery", "name", "settings"]
}

function known(id) {
    for (var i = 0; i < MODULES.length; i++) if (MODULES[i].id === id) return true
    return false
}

function copy(l) {
    return { left: l.left.slice(), center: l.center.slice(), right: l.right.slice() }
}

function normalize(saved) {
    var out = { left: [], center: [], right: [] }
    var seen = {}
    var src = (saved && typeof saved === "object") ? saved : DEFAULT
    for (var g = 0; g < GROUPS.length; g++) {
        var list = Array.isArray(src[GROUPS[g]]) ? src[GROUPS[g]] : []
        for (var i = 0; i < list.length; i++) {
            var id = list[i]
            if (typeof id === "string" && known(id) && !seen[id]) { seen[id] = true; out[GROUPS[g]].push(id) }
        }
    }
    if (!seen.settings) out.right.push("settings")
    return out
}

function groupOf(l, id) {
    for (var g = 0; g < GROUPS.length; g++) if (l[GROUPS[g]].indexOf(id) >= 0) return GROUPS[g]
    return "off"
}

function place(l, id, group, pos) {
    if (!known(id)) return l
    if (group === "off" && id === "settings") return l
    if (group !== "off" && GROUPS.indexOf(group) < 0) return l
    var out = copy(l)
    for (var g = 0; g < GROUPS.length; g++) {
        var i = out[GROUPS[g]].indexOf(id)
        if (i >= 0) out[GROUPS[g]].splice(i, 1)
    }
    if (group !== "off") {
        var at = (typeof pos === "number" && pos >= 0 && pos <= out[group].length) ? pos : out[group].length
        out[group].splice(at, 0, id)
    }
    return out
}

function shift(l, id, delta) {
    var g = groupOf(l, id)
    if (g === "off") return l
    var i = l[g].indexOf(id)
    var j = i + delta
    if (j < 0 || j >= l[g].length) return l
    var out = copy(l)
    out[g].splice(i, 1)
    out[g].splice(j, 0, id)
    return out
}

function title(id) {
    for (var i = 0; i < MODULES.length; i++) if (MODULES[i].id === id) return MODULES[i].title
    return id
}
