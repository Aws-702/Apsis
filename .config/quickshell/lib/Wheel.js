.pragma library

// The wallpaper wheel's arc: where each card sits, its size, tilt and order.
// Edit: the arc numbers in place().

function offset(i, pick, n) {
    if (n <= 0) return 0
    var d = ((i - pick) % n + n) % n
    return d > n / 2 ? d - n : d
}

function place(d, spread) {
    var a = Math.max(-1.4, Math.min(1.4, d * 0.32))
    var R = spread / 0.32
    var ad = Math.abs(d)
    return {
        x: Math.sin(a) * R,
        y: (1 - Math.cos(a)) * R * 0.55,
        scale: Math.max(0.45, 1 - ad * 0.14),
        angle: a * 180 / Math.PI * 0.5,
        z: 100 - Math.round(ad * 10),
        opacity: ad > 4.5 ? 0 : Math.max(0, 1 - Math.max(0, ad - 2.5) * 0.5)
    }
}

function sorted(items, by) {
    var a = items.slice()
    function name(p) { var s = String(p.path); return s.substring(s.lastIndexOf("/") + 1).toLowerCase() }
    if (by === "new") a.sort(function(x, y) { return (y.mtime - x.mtime) || (name(x) < name(y) ? -1 : 1) })
    else a.sort(function(x, y) { return name(x) < name(y) ? -1 : name(x) > name(y) ? 1 : 0 })
    return a
}

function baseName(p) {
    var s = String(p || "")
    s = s.substring(s.lastIndexOf("/") + 1)
    var dot = s.lastIndexOf(".")
    return dot > 0 ? s.substring(0, dot) : s
}
