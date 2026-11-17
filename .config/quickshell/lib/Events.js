.pragma library

// Parsing and sorting for the Events widget (dates, yearly events, +N days).
// Edit: the accepted date forms in parse().

function pad(n) { return (n < 10 ? "0" : "") + n }
function key(y, m, d) { return y + "-" + pad(m + 1) + "-" + pad(d) }

function validDate(y, m, d) {
    var t = new Date(y, m, d)
    return t.getFullYear() === y && t.getMonth() === m && t.getDate() === d
}

function dayNumber(y, m, d) { return Math.round(Date.UTC(y, m, d) / 86400000) }
function today(now) { return dayNumber(now.getFullYear(), now.getMonth(), now.getDate()) }

function parseLine(line, now) {
    var s = String(line || "").trim()
    if (!s.length) return null
    var m = /^(\d{4})-(\d{1,2})-(\d{1,2})\s+(.+)$/.exec(s)
    if (m) {
        var y = +m[1], mo = +m[2] - 1, d = +m[3]
        if (!validDate(y, mo, d)) return null
        return { date: key(y, mo, d), text: m[4].trim(), yearly: false }
    }
    m = /^(\d{1,2})-(\d{1,2})\s+(.+)$/.exec(s)
    if (m) {
        var mo2 = +m[1] - 1, d2 = +m[2]

        if (!validDate(2024, mo2, d2)) return null
        return { date: key(now.getFullYear(), mo2, d2), text: m[3].trim(), yearly: true }
    }
    m = /^\+(\d{1,4})\s+(.+)$/.exec(s)
    if (m) {
        var t = new Date(now.getFullYear(), now.getMonth(), now.getDate() + (+m[1]))
        return { date: key(t.getFullYear(), t.getMonth(), t.getDate()), text: m[2].trim(), yearly: false }
    }
    return null
}

function upcoming(events, now, limit) {
    var base = today(now)
    var out = []
    var list = events || []
    for (var i = 0; i < list.length; i++) {
        var e = list[i]
        var p = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(e.date || ""))
        if (!p || !e.text) continue
        var y = +p[1], mo = +p[2] - 1, d = +p[3]
        var n = dayNumber(y, mo, d)
        if (e.yearly) {
            var yy = now.getFullYear()
            for (var tries = 0; tries < 9; tries++, yy++) {
                if (!validDate(yy, mo, d)) continue
                n = dayNumber(yy, mo, d)
                if (n >= base) { y = yy; break }
            }
            if (n < base) continue
        }
        if (n < base) continue
        var dt = new Date(Date.UTC(1970, 0, 1) + n * 86400000)
        out.push({ text: e.text, date: key(dt.getUTCFullYear(), dt.getUTCMonth(), dt.getUTCDate()), days: n - base, yearly: !!e.yearly, index: i })
    }
    out.sort(function(a, b) { return a.days - b.days || (a.text < b.text ? -1 : 1) })
    return limit > 0 ? out.slice(0, limit) : out
}

function when(days) {
    if (days === 0) return "today"
    if (days === 1) return "tomorrow"
    if (days < 7) return "in " + days + " days"
    if (days < 14) return "next week"
    return "in " + Math.round(days / 7) + " weeks"
}
