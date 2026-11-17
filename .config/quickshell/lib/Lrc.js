.pragma library

// Parses synced lyrics (LRC, enhanced word timing, offset) for the Lyrics widget.
// Edit: nothing visual here.

function parse(text) {
    var out = []
    var offset = 0
    var lines = String(text || "").split(/\r?\n/)
    var stamp = /\[(\d+):(\d+(?:[.:]\d+)?)\]/g
    for (var i = 0; i < lines.length; i++) {
        var l = lines[i]
        var off = /^\[offset:\s*([+-]?\d+)\]/i.exec(l)
        if (off) { offset = parseInt(off[1]) / 1000; continue }
        var times = []
        var m
        stamp.lastIndex = 0
        var last = 0
        while ((m = stamp.exec(l)) !== null) {
            if (m.index !== last) break
            times.push(parseInt(m[1]) * 60 + parseFloat(m[2].replace(":", ".")))
            last = stamp.lastIndex
        }
        if (!times.length) continue
        var body = l.substring(last)
        var ws = wordsOf(body, times[0])
        var words = ws.length ? ws.map(function(w) { return w.text }).join("").trim() : body.trim()
        for (var k = 0; k < times.length; k++) {
            var item = { t: times[k], text: words }
            if (ws.length) item.words = ws.map(function(w) { return { t: w.t - times[0] + times[k], text: w.text } })
            out.push(item)
        }
    }
    for (var j = 0; j < out.length; j++) {
        out[j].t = Math.max(0, out[j].t - offset)
        if (out[j].words) for (var q = 0; q < out[j].words.length; q++) out[j].words[q].t = Math.max(0, out[j].words[q].t - offset)
    }
    out.sort(function(a, b) { return a.t - b.t })
    return out
}

function wordsOf(body, lineT) {
    var tag = /<(\d+):(\d+(?:[.:]\d+)?)>/g
    var marks = []
    var m
    while ((m = tag.exec(body)) !== null)
        marks.push({ at: m.index, end: tag.lastIndex, t: parseInt(m[1]) * 60 + parseFloat(m[2].replace(":", ".")) })
    if (!marks.length) return []
    var out = []
    var lead = body.substring(0, marks[0].at)
    if (lead.length) out.push({ t: typeof lineT === "number" ? Math.min(lineT, marks[0].t) : marks[0].t, text: lead })
    for (var i = 0; i < marks.length; i++) {
        var to = i + 1 < marks.length ? marks[i + 1].at : body.length
        var txt = body.substring(marks[i].end, to)
        if (txt.length) out.push({ t: marks[i].t, text: txt })
    }
    return out
}

function wordFrac(words, w, t, lineEnd) {
    if (!words || w < 0 || w >= words.length) return 0
    var start = words[w].t
    var end = w + 1 < words.length ? words[w + 1].t : Math.max(start + 0.3, Math.min(lineEnd, start + 1.5))
    var span = Math.max(0.05, end - start)
    return Math.max(0, Math.min(1, (t - start) / span))
}

function at(lines, t) {
    var lo = 0, hi = lines.length - 1, ans = -1
    while (lo <= hi) {
        var mid = (lo + hi) >> 1
        if (lines[mid].t <= t) { ans = mid; lo = mid + 1 } else hi = mid - 1
    }
    return ans
}

function progress(lines, i, t) {
    if (i < 0 || i >= lines.length) return 0
    var end = i + 1 < lines.length ? lines[i + 1].t : lines[i].t + 4
    var span = Math.max(0.1, end - lines[i].t)
    return Math.max(0, Math.min(1, (t - lines[i].t) / span))
}
