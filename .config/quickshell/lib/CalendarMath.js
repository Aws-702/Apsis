.pragma library

// Date maths for the calendar card: month grid, distance to a day, week start.
// Edit: the wording of distances in describe().

function daysIn(year, month) { return new Date(year, month + 1, 0).getDate() }

function key(y, m, d) { return y + "-" + (m < 9 ? "0" : "") + (m + 1) + "-" + (d < 10 ? "0" : "") + d }

function shift(year, month, n) {
    var t = year * 12 + month + n
    return { y: Math.floor(t / 12), m: ((t % 12) + 12) % 12 }
}

function grid(year, month, weekStart) {
    var first = new Date(year, month, 1).getDay()
    var lead = (first - weekStart + 7) % 7
    var cells = []
    for (var i = 0; i < 42; i++) {
        var dt = new Date(year, month, 1 - lead + i)
        cells.push({ y: dt.getFullYear(), m: dt.getMonth(), d: dt.getDate(), inMonth: dt.getMonth() === month,
                     key: key(dt.getFullYear(), dt.getMonth(), dt.getDate()), dow: dt.getDay() })
    }
    return cells
}

function weekdays(weekStart) {
    var out = []
    for (var i = 0; i < 7; i++) out.push((weekStart + i) % 7)
    return out
}

function between(a, b) {
    var ua = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())
    var ub = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate())
    return Math.round((ub - ua) / 86400000)
}

function relative(n) {
    if (n === 0) return "today"
    if (n === 1) return "tomorrow"
    if (n === -1) return "yesterday"
    return n > 0 ? "in " + n + " days" : n * -1 + " days ago"
}

function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - yearStart) / 86400000 + 1) / 7)
}
