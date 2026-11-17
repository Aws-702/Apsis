.pragma library

// Update list parsing, pinned groups, the review's choices and snapshot wording.
// Edit: TITLES for group names, protection() for the snapshot sentences.

function parse(text) {
    var repo = [], aur = []
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var f = lines[i].split("\t")
        if (f.length < 4 || !f[1]) continue
        var u = { name: f[1], from: f[2], to: f[3], held: f[4] === "held", group: f[5] && f[5] !== "-" ? f[5] : "" }
        if (f[0] === "aur") aur.push(u)
        else if (f[0] === "repo") repo.push(u)
    }
    var all = repo.concat(aur)
    var held = all.filter(function(u) { return u.held }).length

    return { repo: repo, aur: aur, total: all.length - held, heldCount: held, qtRisk: qtRisk(all), groups: groups(all) }
}

function qtRisk(list) {
    var qt = false, qs = false
    for (var i = 0; i < list.length; i++) {
        if (/^qt6-(base|declarative|wayland)$/.test(list[i].name)) qt = true
        if (/^quickshell(-git)?$/.test(list[i].name) && !list[i].held) qs = true
    }
    return qt && !qs
}

var TITLES = { hypr: "Hyprland and its libraries", shell: "Quickshell and Qt" }
var HEADLINE = { hypr: /^hyprland$/, shell: /^quickshell(-git)?$/ }

function groups(list) {
    var by = {}, order = []
    for (var i = 0; i < list.length; i++) {
        var g = list[i].group
        if (!g) continue
        if (!by[g]) { by[g] = { id: g, title: TITLES[g] || g, items: [], from: "", to: "", state: "free" }; order.push(g) }
        by[g].items.push(list[i])
    }
    return order.map(function(id) {
        var o = by[id], held = 0, head = null
        for (var j = 0; j < o.items.length; j++) {
            if (o.items[j].held) held++
            if (HEADLINE[id] && HEADLINE[id].test(o.items[j].name)) head = o.items[j]
        }
        if (!head) head = o.items[0]
        o.from = head.from
        o.to = head.to
        o.state = held === 0 ? "free" : (held === o.items.length ? "held" : "mixed")
        return o
    })
}

function pinStates(text) {
    var out = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var f = lines[i].trim().split(/\s+/)
        if (f.length >= 2 && /^(free|held|mixed)$/.test(f[1])) out[f[0]] = f[1]
    }
    return out
}

function applyPins(gs, pins) {
    return gs.map(function(g) {
        var c = {}
        for (var k in g) c[k] = g[k]
        if (pins && pins[g.id]) c.state = pins[g.id]
        return c
    })
}

function defaults(gs) {
    var d = {}
    for (var i = 0; i < gs.length; i++) d[gs[i].id] = gs[i].state !== "free"
    return d
}

function changes(gs, keep) {
    var hold = [], release = []
    for (var i = 0; i < gs.length; i++) {
        var g = gs[i]
        if (keep[g.id] && g.state !== "held") hold.push(g.id)
        if (!keep[g.id] && g.state !== "free") release.push(g.id)
    }
    return { hold: hold, release: release }
}

function runArgs(ch, snapshot) {
    var a = ["run"]
    if (ch.hold.length) a.push("--hold", ch.hold.join(","))
    if (ch.release.length) a.push("--release", ch.release.join(","))
    if (snapshot) a.push("--snapshot")
    return a
}

function selfStatus(text) {
    var f = String(text || "").trim().split("\t")
    var ok = /^(new|current|ahead|offline|none)$/.test(f[0])
    return { status: ok ? f[0] : "", from: ok ? (f[1] || "") : "", to: ok ? (f[2] || "") : "", count: ok ? (Number(f[3]) || 0) : 0 }
}

function selfCard(s) {
    if (!s || s.status !== "new") return null
    var title = s.to && s.to !== s.from ? "Apsis " + s.to + " is out" : "Apsis has " + s.count + (s.count === 1 ? " new change" : " new changes")
    var sub = "You have " + (s.from || "an older version") + (s.count ? " · " + s.count + (s.count === 1 ? " change" : " changes") : "")
    return { title: title, sub: sub }
}

function protection(text) {
    var s = { snapper: false, snappac: false, bootable: false }
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
        var f = lines[i].trim().split(/\s+/)
        if (f.length === 2 && f[0] in s) s[f[0]] = f[1] === "yes"
    }
    s.choice = s.snapper && !s.snappac
    s.line = s.snappac ? (s.bootable ? "A snapshot is taken before and after, and you can boot into it from the boot menu."
                                      : "A snapshot is taken before and after. Restoring one needs a bootable snapshot entry or a live USB.")
           : s.snapper ? "Snapper is set up, but nothing snapshots updates by itself."
           : "No snapshots are set up (snapper on btrfs would add them)."
    return s
}
