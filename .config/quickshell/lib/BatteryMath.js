.pragma library

// Battery numbers from /sys/class/power_supply: percent, time left, health, gauge forecast.
// Edit: LOW_LEVELS for when it warns.

function minutesLeft(now, full, rate, charging) {
    now = +now; full = +full; rate = Math.abs(+rate)
    if (!(rate > 0) || !(full > 0) || !(now >= 0)) return -1
    var amount = charging ? full - now : now
    if (amount <= 0) return -1
    return Math.round(amount / rate * 60)
}

function minutesTo(target, pct, full, rate, charging) {
    full = +full; rate = Math.abs(+rate)
    if (!(rate > 0) || !(full > 0)) return -1
    var diff = (target - pct) / 100 * full
    if (charging ? diff <= 0 : diff >= 0) return -1
    return Math.round(Math.abs(diff) / rate * 60)
}

function fmt(mins) {
    if (mins < 0) return ""
    if (mins < 60) return mins + "m"
    var h = Math.floor(mins / 60), m = mins % 60
    return h + "h " + (m < 10 ? "0" : "") + m + "m"
}

function health(full, design) {
    full = +full; design = +design
    if (!(full > 0) || !(design > 0)) return -1
    return Math.min(100, Math.round(full / design * 100))
}

function word(pct, charging) {
    if (charging && pct >= 99) return "Full"
    if (pct >= 80) return "Plenty"
    if (pct >= 45) return "Good"
    if (pct >= 20) return "Getting low"
    return "Low"
}

var LOW_LEVELS = [20, 10, 5]
function lowAlert(pct, charging, warned) {
    if (warned === undefined || warned === null) warned = 101
    if (charging || pct < 0) return { level: 0, warned: 101 }
    if (pct > warned + 3) warned = 101
    var hit = 0
    for (var i = 0; i < LOW_LEVELS.length; i++) if (pct <= LOW_LEVELS[i] && LOW_LEVELS[i] < warned) hit = LOW_LEVELS[i]
    return hit ? { level: hit, warned: hit } : { level: 0, warned: warned }
}
