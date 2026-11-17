.pragma library

// Geometry for the workspace overview: card sizes and window rectangles.
// Edit: gaps and columns in layout().

function range(usedIds, activeId, min) {
    var top = Math.max(activeId > 0 ? activeId : 1, min || 0)
    for (var i = 0; i < usedIds.length; i++) if (usedIds[i] > 0 && usedIds[i] <= 10) top = Math.max(top, usedIds[i])
    top = Math.min(10, top + (top < 10 ? 1 : 0))
    var out = []
    for (var k = 1; k <= top; k++) out.push(k)
    return out
}

function grid(count, areaW, areaH, monW, monH, gap) {
    var aspect = monW > 0 && monH > 0 ? monW / monH : 16 / 9
    var best = null
    for (var cols = 1; cols <= Math.min(5, Math.max(1, count)); cols++) {
        var rows = Math.ceil(count / cols)
        var w = Math.min((areaW - (cols - 1) * gap) / cols, ((areaH - (rows - 1) * gap) / rows) * aspect)
        if (!best || w > best.cardW) best = { cols: cols, rows: rows, cardW: w, cardH: w / aspect }
    }
    best.scale = monW > 0 ? best.cardW / monW : 0
    return best
}

function tile(at, size, mon, scale, cardW, cardH) {
    var x = (at[0] - mon.x) * scale, y = (at[1] - mon.y) * scale
    var w = Math.max(18, size[0] * scale), h = Math.max(14, size[1] * scale)
    x = Math.max(0, Math.min(cardW - w, x))
    y = Math.max(0, Math.min(cardH - h, y))
    return { x: x, y: y, w: Math.min(w, cardW), h: Math.min(h, cardH) }
}

function addr(a) { return String(a || "").toLowerCase().replace(/^0x/, "") }

function cardAt(px, py, cols, cardW, cardH, gap, count) {
    if (px < 0 || py < 0) return -1
    var c = Math.floor(px / (cardW + gap)), r = Math.floor(py / (cardH + gap))
    if (c >= cols || px - c * (cardW + gap) > cardW || py - r * (cardH + gap) > cardH) return -1
    var i = r * cols + c
    return i < count ? i : -1
}
