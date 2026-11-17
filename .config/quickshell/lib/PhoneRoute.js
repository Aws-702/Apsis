.pragma library

// The phone's navigation as plain functions: one stack, a floor, Home, alerts.
// Edit: PORTRAIT and LANDSCAPE for which screens exist and their order.

var QUICK = "quick"
var APPS = "apps"
var SOUND = "sound"
var EQ = "eq"
var WIFI = "wifi"
var BLUETOOTH = "bluetooth"
var UPDATES = "updates"
var NOTIFICATIONS = "notifications"
var SETTINGS = "settings"

var PORTRAIT = [QUICK, APPS, SOUND, EQ, WIFI, BLUETOOTH, UPDATES, NOTIFICATIONS]
var ALL = PORTRAIT.concat([SETTINGS])
var LANDSCAPE = [SETTINGS]

function isScreen(name) {
    return ALL.indexOf(name) >= 0
}

function order(name) {
    var i = PORTRAIT.indexOf(name)
    return i < 0 ? 0 : i
}

function isLandscape(name) {
    return LANDSCAPE.indexOf(name) >= 0
}

function open(entry) {
    var first = QUICK
    if (isScreen(entry)) first = entry
    return { stack: [first] }
}

function top(state) {
    return state && state.stack.length > 0 ? state.stack[state.stack.length - 1] : QUICK
}

function floor(state) {
    return state && state.stack.length > 0 ? state.stack[0] : QUICK
}

function go(state, name) {
    if (!isScreen(name)) return state
    var s = state.stack.slice()
    var at = s.indexOf(name)
    if (at === s.length - 1) return state
    if (at >= 0) return { stack: s.slice(0, at + 1) }
    s.push(name)
    return { stack: s }
}

function back(state) {
    if (!state || state.stack.length <= 1) return { state: state, close: true }
    return { state: { stack: state.stack.slice(0, -1) }, close: false }
}

function home(state) {
    return { stack: [QUICK] }
}

function toggle(state, isOpen, name) {
    var target = isScreen(name) ? name : QUICK
    if (isOpen && top(state) === target) return { state: state, close: true }
    if (!isOpen) return { state: open(target), close: false }
    return { state: go(state, target), close: false }
}
