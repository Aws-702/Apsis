.pragma library

// Snapping for Edit Desktop: room edges, other widgets, then the grid.
// Edit: threshold, margin and grid defaults in snap().

function snapAxis(a, len, lines, threshold, grid, room, margin) {
    var mine = [
        { off: 0, edge: "start" },
        { off: len / 2, edge: "center" },
        { off: len, edge: "end" }
    ]
    var best = null
    for (var i = 0; i < lines.length; i++) {
        for (var j = 0; j < mine.length; j++) {
            var d = Math.abs(a + mine[j].off - lines[i].pos)
            if (d <= threshold && (best === null || d < best.d))
                best = { d: d, pos: lines[i].pos - mine[j].off, guide: { pos: lines[i].pos, kind: lines[i].kind, edge: mine[j].edge } }
        }
    }
    var pos
    var guide = null
    if (best) {
        pos = best.pos
        guide = best.guide
    } else if (grid > 0) {
        pos = Math.round((a - margin) / grid) * grid + margin
    } else {
        pos = a
    }
    var lo = margin
    var hi = Math.max(lo, room - margin - len)
    pos = Math.max(lo, Math.min(hi, pos))
    return { pos: Math.round(pos), guide: guide }
}

function linesFor(others, room, margin, horizontal) {
    var out = [
        { pos: margin, kind: "room" },
        { pos: room / 2, kind: "room" },
        { pos: room - margin, kind: "room" }
    ]
    for (var i = 0; i < others.length; i++) {
        var o = others[i]
        var s = horizontal ? o.x : o.y
        var l = horizontal ? o.w : o.h
        out.push({ pos: s, kind: "widget" })
        out.push({ pos: s + l / 2, kind: "widget" })
        out.push({ pos: s + l, kind: "widget" })
    }
    return out
}

function snap(rect, others, opts) {
    var o = opts || {}
    var roomW = o.roomW || 1920
    var roomH = o.roomH || 1080
    var grid = o.snap === false ? 0 : (o.grid === undefined ? 24 : o.grid)
    var threshold = o.snap === false ? -1 : (o.threshold === undefined ? 10 : o.threshold)
    var margin = o.margin === undefined ? 16 : o.margin

    var sx = snapAxis(rect.x, rect.w, linesFor(others || [], roomW, margin, true), threshold, grid, roomW, margin)
    var sy = snapAxis(rect.y, rect.h, linesFor(others || [], roomH, margin, false), threshold, grid, roomH, margin)
    var guides = []
    if (sx.guide) guides.push({ axis: "x", pos: sx.guide.pos, kind: sx.guide.kind, edge: sx.guide.edge })
    if (sy.guide) guides.push({ axis: "y", pos: sy.guide.pos, kind: sy.guide.kind, edge: sy.guide.edge })
    return { x: sx.pos, y: sy.pos, guides: guides }
}

function freeSpot(w, h, others, opts) {
    var o = opts || {}
    var roomW = o.roomW || 1920
    var roomH = o.roomH || 1080
    var grid = o.grid || 24
    var margin = o.margin === undefined ? 16 : o.margin
    var top = o.top === undefined ? 64 : o.top
    for (var y = top; y + h <= roomH - margin; y += grid) {
        for (var x = margin; x + w <= roomW - margin; x += grid) {
            var hit = false
            for (var i = 0; i < others.length && !hit; i++) {
                var q = others[i]
                if (x < q.x + q.w + 8 && x + w + 8 > q.x && y < q.y + q.h + 8 && y + h + 8 > q.y) hit = true
            }
            if (!hit) return { x: x, y: y }
        }
    }
    return { x: margin, y: top }
}
