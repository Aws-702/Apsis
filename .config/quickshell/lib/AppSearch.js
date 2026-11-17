.pragma library

// App search ranking for the Apps screen: prefix, word start, then anywhere; starred first.
// Edit: the ranking order in rank().

function score(e, q) {
    var name = (e.name || "").toLowerCase()
    if (q === "") return 1
    if (name.indexOf(q) === 0) return 100
    var words = name.split(/[\s\-_.]+/)
    for (var i = 0; i < words.length; i++)
        if (words[i].indexOf(q) === 0) return 70
    if (name.indexOf(q) >= 0) return 50
    var rest = [(e.genericName || ""), (e.comment || ""), (e.id || "")].join(" ").toLowerCase()
    if (rest.indexOf(q) >= 0) return 20
    return 0
}

function filter(entries, query, opts) {
    opts = opts || {}
    var starred = opts.starred || []
    var hidden = opts.hidden || []
    var q = String(query || "").trim().toLowerCase()
    var out = []
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i]
        if (!e || e.noDisplay) continue
        if (!opts.showHidden && hidden.indexOf(e.id) >= 0) continue
        var s = score(e, q)
        if (s > 0) out.push({ s: s, star: starred.indexOf(e.id) >= 0 ? 1 : 0, e: e })
    }
    out.sort(function (a, b) {
        if (a.s !== b.s) return b.s - a.s
        if (a.star !== b.star) return b.star - a.star
        return (a.e.name || "").toLowerCase().localeCompare((b.e.name || "").toLowerCase())
    })
    return out.map(function (o) { return o.e })
}

function hiddenCount(entries, hidden) {
    var n = 0
    for (var i = 0; i < entries.length; i++)
        if (entries[i] && !entries[i].noDisplay && (hidden || []).indexOf(entries[i].id) >= 0) n++
    return n
}
