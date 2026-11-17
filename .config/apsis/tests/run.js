// Unit tests for the shell's pure logic in quickshell/lib/*.js.
// Run: node ~/.config/apsis/tests/run.js

"use strict"
const fs = require("fs")
const path = require("path")
const vm = require("vm")
const assert = require("assert")

const LIB = path.join(__dirname, "..", "..", "quickshell", "lib")

function load(name) {
    let src = fs.readFileSync(path.join(LIB, name), "utf8").replace(/^\.pragma library\s*$/m, "")
    const box = {}

    src = src.replace(/^\.import\s+"([^"]+)"\s+as\s+(\w+)\s*$/gm, (m, file, as) => { box[as] = load(file); return "" })
    vm.createContext(box)
    vm.runInContext(src, box, { filename: name })
    return box
}

const plain = v => (v === undefined ? v : JSON.parse(JSON.stringify(v)))
const eq = (a, b, m) => assert.deepStrictEqual(plain(a), plain(b), m)

let passed = 0
let failed = 0
function test(name, fn) {
    try {
        fn()
        passed++
    } catch (e) {
        failed++
        console.log("FAIL " + name + "\n     " + (e && e.message))
    }
}

const R = load("PhoneRoute.js")

test("route: open defaults to quick on unknown", () => {
    eq(R.open("nope").stack, ["quick"])
    eq(R.open("apps").stack, ["apps"])
})
test("route: go pushes, same screen is a no-op, lower screen pops back", () => {
    let s = R.open("quick")
    s = R.go(s, "apps")
    eq(s.stack, ["quick", "apps"])
    assert.strictEqual(R.go(s, "apps"), s)
    s = R.go(s, "settings")
    eq(s.stack, ["quick", "apps", "settings"])
    s = R.go(s, "quick")
    eq(s.stack, ["quick"])
})
test("route: back never goes below the floor and closes there", () => {
    let s = R.go(R.open("apps"), "settings")
    let b = R.back(s)
    assert.strictEqual(b.close, false)
    eq(b.state.stack, ["apps"])
    b = R.back(b.state)
    assert.strictEqual(b.close, true)
})
test("route: home clears to quick", () => {
    eq(R.home(R.go(R.open("apps"), "settings")).stack, ["quick"])
})
test("route: toggle closes only the showing screen", () => {
    let s = R.open("quick")
    assert.strictEqual(R.toggle(s, true, "quick").close, true)
    let t = R.toggle(s, true, "apps")
    assert.strictEqual(t.close, false)
    assert.strictEqual(R.top(t.state), "apps")
    t = R.toggle(s, false, "apps")
    eq(t.state.stack, ["apps"])
})
test("route: landscape screens", () => {
    assert.strictEqual(R.isLandscape("settings"), true)
    assert.strictEqual(R.isLandscape("apps"), false)
})
test("route: random walks keep invariants", () => {
    const names = ["quick", "apps", "settings", "bogus"]
    let seed = 7
    const rnd = n => { seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n }
    for (let run = 0; run < 2000; run++) {
        let s = R.open(names[rnd(4)])
        let open = true
        for (let k = 0; k < 20; k++) {
            const op = rnd(4)
            if (op === 0) s = R.go(s, names[rnd(4)])
            else if (op === 1) { const b = R.back(s); if (b.close) { open = false; s = R.open("quick") } else s = b.state }
            else if (op === 2) s = R.home(s)
            else { const t = R.toggle(s, open, names[rnd(4)]); if (t.close) open = false; else { open = true; s = t.state } }
            assert.ok(s.stack.length >= 1)
            assert.ok(s.stack.every(R.isScreen))
            assert.strictEqual(new Set(s.stack).size, s.stack.length, "no screen twice")
        }
    }
})

test("route: detail screens stack on quick and go back to it", () => {
    let st = R.open("quick")
    st = R.go(st, "wifi")
    eq(st.stack, ["quick", "wifi"])
    assert.strictEqual(R.isLandscape("wifi"), false)
    assert.ok(R.order("bluetooth") > R.order("apps"))
    const b = R.back(st)
    eq(b.state.stack, ["quick"])
    eq(R.open("sound").stack, ["sound"])
    assert.strictEqual(R.back(R.open("sound")).close, true)
})

const G = load("EditGridMath.js")
const room = { roomW: 1920, roomH: 1080, grid: 24, threshold: 10, margin: 16 }

test("grid: snaps left edge to another widget's left edge", () => {
    const r = G.snap({ x: 205, y: 500, w: 100, h: 50 }, [{ x: 200, y: 100, w: 300, h: 100 }], room)
    assert.strictEqual(r.x, 200)
    assert.ok(r.guides.some(g => g.axis === "x" && g.kind === "widget"))
})
test("grid: snaps center to the room center", () => {
    const r = G.snap({ x: 905, y: 300, w: 100, h: 50 }, [], room)
    assert.strictEqual(r.x, 910)
    assert.ok(r.guides.some(g => g.axis === "x" && g.kind === "room" && g.edge === "center"))
})
test("grid: falls back to the grid when nothing is close", () => {
    const r = G.snap({ x: 333, y: 333, w: 50, h: 50 }, [], room)
    assert.strictEqual((r.x - 16) % 24, 0)
    assert.strictEqual((r.y - 16) % 24, 0)
    assert.strictEqual(r.guides.length, 0)
})
test("grid: never leaves the room", () => {
    const r = G.snap({ x: -500, y: 5000, w: 300, h: 200 }, [], room)
    assert.strictEqual(r.x, 16)
    assert.strictEqual(r.y, 1080 - 16 - 200)
    const big = G.snap({ x: 0, y: 0, w: 3000, h: 50 }, [], room)
    assert.strictEqual(big.x, 16)
})
test("grid: snap off keeps the raw position (clamped)", () => {
    const r = G.snap({ x: 333.4, y: 401.6, w: 50, h: 50 }, [{ x: 330, y: 400, w: 10, h: 10 }], Object.assign({}, room, { snap: false }))
    assert.strictEqual(r.x, 333)
    assert.strictEqual(r.y, 402)
    assert.strictEqual(r.guides.length, 0)
})
test("grid: freeSpot avoids overlap", () => {
    const others = [{ x: 16, y: 64, w: 400, h: 200 }]
    const p = G.freeSpot(100, 100, others, room)
    const o = others[0]
    assert.ok(!(p.x < o.x + o.w && p.x + 100 > o.x && p.y < o.y + o.h && p.y + 100 > o.y))
})

const W = load("WidgetTypes.js")
const P = load("PresetMath.js")
const T = W.TYPES

test("types: styleOf fills defaults and drops unknown keys", () => {
    eq(W.styleOf("clock", { seconds: true, junk: 1 }), { seconds: true, h24: true })
    eq(W.styleOf("nope", {}), {})
    eq(W.size("weather", { forecast: true }), { w: 340, h: 268 })
    eq(W.size("weather", { forecast: false }), { w: 264, h: 160 })
    eq(W.size("clock", undefined), { w: 336, h: 148 })
})
test("preset: capture strips personal content", () => {
    const state = { palette: "navy", mode: "darker", widgets: [
        { id: "a", type: "todo", x: 10, y: 20, style: {}, items: [{ t: "secret", done: false }] },
        { id: "b", type: "note", x: 30, y: 40, style: { tint: "cyan" }, text: "private" },
        { id: "c", type: "removedType", x: 0, y: 0 }
    ] }
    const p = P.capture("Work", state, T)
    assert.strictEqual(p.widgets.length, 2)
    assert.ok(!("items" in p.widgets[0]))
    assert.ok(!("text" in p.widgets[1]))
    assert.strictEqual(p.widgets[1].style.tint, "cyan")
    assert.strictEqual(p.palette, "navy")
})
test("preset: apply keeps personal content by id, then by type", () => {
    const current = { palette: "cherry", mode: "dark", dock: { enabled: true }, bar: { shown: true }, widgets: [
        { id: "a", type: "todo", x: 0, y: 0, style: {}, items: [{ t: "mine" }] },
        { id: "n1", type: "note", x: 0, y: 0, style: {}, text: "hello" }
    ] }
    const preset = { palette: "navy", mode: "light", widgets: [
        { id: "a", type: "todo", x: 500, y: 60, style: {} },
        { id: "zz", type: "note", x: 9, y: 9, style: {} },
        { id: "k", type: "clock", x: 1, y: 2, style: {} }
    ] }
    const s = P.apply(preset, current, T)
    assert.strictEqual(s.palette, "navy")
    eq(s.widgets[0].items, [{ t: "mine" }])
    assert.strictEqual(s.widgets[0].x, 500)
    assert.strictEqual(s.widgets[1].text, "hello")
    eq(s.widgets[2].style, { seconds: false, h24: true })
    eq(s.dock, { enabled: true }, "old preset without dock keeps yours")
    current.widgets[0].items[0].t = "changed"
    assert.strictEqual(s.widgets[0].items[0].t, "mine", "apply returns copies")
})
test("preset: capture then apply round-trips the look", () => {
    const state = { palette: "navy", mode: "light", dock: { enabled: false, autohide: true }, bar: { shown: false }, widgets: [
        { id: "c", type: "clock", x: 100, y: 120, screen: "eDP-1", style: { seconds: true, h24: false } }
    ] }
    const s = P.apply(P.capture("x", state, T), { palette: "cherry", mode: "dark", widgets: [], dock: {}, bar: {} }, T)
    eq(s.widgets, state.widgets)
    eq(s.dock, state.dock)
    eq(s.bar, state.bar)
    assert.strictEqual(s.mode, "light")
})
test("preset: safeName", () => {
    assert.strictEqual(P.safeName("  My  Look/../..  "), "My Look")
    assert.strictEqual(P.safeName("a".repeat(80)).length, 40)
})

const A = load("AppSearch.js")
const apps = [
    { name: "Visual Studio Code", id: "code", genericName: "Text Editor" },
    { name: "Calculator", id: "calc" },
    { name: "Hidden", id: "h", noDisplay: true },
    { name: "Alacritty", id: "alacritty", genericName: "Terminal" },
    { name: "Code OSS", id: "code-oss" }
]
test("search: prefix beats word beats substring beats metadata", () => {
    const r = A.filter(apps, "co").map(e => e.id)
    eq(r, ["code-oss", "code"])
    eq(A.filter(apps, "term").map(e => e.id), ["alacritty"])
})
test("search: empty lists all visible by name", () => {
    eq(A.filter(apps, "").map(e => e.name), ["Alacritty", "Calculator", "Code OSS", "Visual Studio Code"])
})
test("search: starred apps come first, but never beat a better match", () => {
    eq(A.filter(apps, "", { starred: ["code", "calc"] }).map(e => e.id), ["calc", "code", "alacritty", "code-oss"])
    eq(A.filter(apps, "co", { starred: ["code"] }).map(e => e.id), ["code-oss", "code"])
    eq(A.filter(apps, "c", { starred: ["code-oss"] }).map(e => e.id).slice(0, 2), ["code-oss", "calc"])
})
test("search: hidden apps are left out unless shown, and counted", () => {
    eq(A.filter(apps, "", { hidden: ["calc"] }).map(e => e.id), ["alacritty", "code-oss", "code"])
    eq(A.filter(apps, "calc", { hidden: ["calc"] }).length, 0)
    eq(A.filter(apps, "", { hidden: ["calc"], showHidden: true }).length, 4)
    assert.strictEqual(A.hiddenCount(apps, ["calc", "h", "gone"]), 1)
})

const B = load("BatteryMath.js")
test("battery: time to empty and to full", () => {
    assert.strictEqual(B.minutesLeft(30e6, 60e6, 15e6, false), 120)
    assert.strictEqual(B.minutesLeft(30e6, 60e6, 15e6, true), 120)
    assert.strictEqual(B.minutesLeft(30e6, 60e6, 0, false), -1)
    assert.strictEqual(B.minutesLeft(60e6, 60e6, 5e6, true), -1)
    assert.strictEqual(B.minutesLeft(30e6, 60e6, -15e6, false), 120, "some drivers report negative draw")
})
test("battery: forecast only in the direction it is going", () => {
    assert.strictEqual(B.minutesTo(25, 50, 60e6, 15e6, false), 60)
    assert.strictEqual(B.minutesTo(75, 50, 60e6, 15e6, false), -1)
    assert.strictEqual(B.minutesTo(75, 50, 60e6, 15e6, true), 60)
})
test("battery: format, health, words", () => {
    assert.strictEqual(B.fmt(45), "45m")
    assert.strictEqual(B.fmt(125), "2h 05m")
    assert.strictEqual(B.fmt(-1), "")
    assert.strictEqual(B.health(46e6, 50e6), 92)
    assert.strictEqual(B.health(0, 50e6), -1)
    assert.strictEqual(B.word(100, true), "Full")
    assert.strictEqual(B.word(10, false), "Low")
})

const C = load("CalendarMath.js")
test("calendar: October 2026 starting Sunday", () => {
    const g = C.grid(2026, 9, 0)
    assert.strictEqual(g.length, 42)

    eq(g.slice(0, 5).map(c => c.d), [27, 28, 29, 30, 1])
    assert.strictEqual(g[4].inMonth, true)
    assert.strictEqual(g[3].inMonth, false)
    assert.strictEqual(g[4].key, "2026-10-01")
})
test("calendar: Monday start, month shifts, day counts", () => {
    const g = C.grid(2026, 9, 1)
    assert.strictEqual(g[3].d, 1)
    eq(C.shift(2026, 11, 1), { y: 2027, m: 0 })
    eq(C.shift(2026, 0, -1), { y: 2025, m: 11 })
    assert.strictEqual(C.daysIn(2028, 1), 29)
    eq(C.weekdays(6), [6, 0, 1, 2, 3, 4, 5])
})
test("calendar: relative days and ISO weeks", () => {
    assert.strictEqual(C.between(new Date(2026, 9, 19), new Date(2026, 9, 23)), 4)
    assert.strictEqual(C.relative(4), "in 4 days")
    assert.strictEqual(C.relative(-2), "2 days ago")
    assert.strictEqual(C.relative(1), "tomorrow")
    assert.strictEqual(C.isoWeek(new Date(2026, 9, 19)), 43)
    assert.strictEqual(C.isoWeek(new Date(2027, 0, 1)), 53)
})

const L = load("Lrc.js")
test("lrc: parse, repeated stamps, metadata dropped, sorted", () => {
    const l = L.parse("[ar:Someone]\n[00:10.00][01:10.00]hook\n[00:05.50]first\n\n[00:20]plain\n")
    eq(l.map(x => [x.t, x.text]), [[5.5, "first"], [10, "hook"], [20, "plain"], [70, "hook"]])
})
test("lrc: offset shifts earlier, never below zero", () => {
    const l = L.parse("[offset:+500]\n[00:00.20]a\n[00:02.00]b")
    eq(l.map(x => x.t), [0, 1.5])
})
test("lrc: line at a time, and progress through it", () => {
    const l = L.parse("[00:01.00]a\n[00:03.00]b\n[00:07.00]c")
    assert.strictEqual(L.at(l, 0.5), -1)
    assert.strictEqual(L.at(l, 1), 0)
    assert.strictEqual(L.at(l, 6.9), 1)
    assert.strictEqual(L.at(l, 100), 2)
    assert.strictEqual(L.progress(l, 1, 5), 0.5)
    assert.strictEqual(L.progress(l, -1, 5), 0)
})

const E = load("EqPresets.js")
test("eq: presets have ten bands, names come back, clamps and labels", () => {
    for (const n of E.ORDER) assert.strictEqual(E.PRESETS[n].length, 10, n)
    assert.strictEqual(E.nameOf(E.PRESETS.Bass.slice()), "Bass")
    assert.strictEqual(E.nameOf([1, 0, 0, 0, 0, 0, 0, 0, 0, 0]), "Custom")
    assert.strictEqual(E.clamp(20), 12)
    assert.strictEqual(E.clamp(-3.3), -3.5)
    assert.strictEqual(E.label(16000), "16k")
    assert.strictEqual(E.headroom([0, 6, -3]), -6)
})

const K = load("Calc.js")
test("calc: precedence, power, parentheses, functions, constants", () => {
    assert.strictEqual(K.answer("2+3*4"), "14")
    assert.strictEqual(K.answer("2^3^2"), "512")
    assert.strictEqual(K.answer("(1+2)*3"), "9")
    assert.strictEqual(K.answer("-3^2"), "-9")
    assert.strictEqual(K.answer("sqrt 16 + sin 30"), "4.5")
    assert.strictEqual(K.answer("2 pi"), "")
    assert.strictEqual(K.answer("2*pi"), "6.28318530718")
    assert.strictEqual(K.answer("0.1+0.2"), "0.3")
    assert.strictEqual(K.answer("3 x 4"), "12")
    assert.strictEqual(K.answer("1,000 * 2"), "2000")
})
test("calc: percentages and remainders", () => {
    assert.strictEqual(K.answer("15% of 80"), "12")
    assert.strictEqual(K.answer("80 + 15%"), "92")
    assert.strictEqual(K.answer("200 - 10%"), "180")
    assert.strictEqual(K.answer("50%"), "0.5")
    assert.strictEqual(K.answer("10 % 3"), "1")
    assert.strictEqual(K.answer("50% * 8"), "4")
})
test("calc: not maths stays out, never runs code", () => {
    assert.strictEqual(K.answer("1/0"), "")
    assert.strictEqual(K.answer("alert(1)"), "")
    assert.strictEqual(K.answer("2+"), "")
    assert.strictEqual(K.looksLike("firefox"), false)
    assert.strictEqual(K.looksLike("2+2"), true)
    assert.strictEqual(K.looksLike("= 7"), true)
    assert.strictEqual(K.looksLike("steam 2"), false)
})

const CC = load("ColorConv.js")
test("color: parse hex, rgb, hsl; convert back", () => {
    eq(CC.parse("#f36"), { r: 255, g: 51, b: 102, a: 1 })
    eq(CC.parse("rgb(10, 20, 30)"), { r: 10, g: 20, b: 30, a: 1 })
    assert.strictEqual(CC.hex(CC.parse("hsl(0, 100%, 50%)")), "#ff0000")
    assert.strictEqual(CC.hsl(CC.parse("#00ff00")), "hsl(120, 100%, 50%)")
    assert.strictEqual(CC.rgb(CC.parse("#ff336680")), "rgba(255, 51, 102, 0.5)")
    assert.strictEqual(CC.parse("banana"), null)
    assert.strictEqual(CC.isLight(CC.parse("#ffffff")), true)
})

const SM = load("Smart.js")
test("smart: prefixes and detection", () => {
    eq(SM.classify(":smile"), { kind: "emoji", q: "smile" })
    eq(SM.classify("> pass"), { kind: "clip", q: "pass" })
    eq(SM.classify("?weather riyadh"), { kind: "web", q: "weather riyadh" })
    assert.strictEqual(SM.classify("12*7").kind, "calc")
    assert.strictEqual(SM.classify("#ff3366").kind, "color")
    assert.strictEqual(SM.classify("github.com/Aws-702").kind, "url")
    assert.strictEqual(SM.classify("firefox").kind, "")
    assert.strictEqual(SM.classify("").kind, "")
    assert.strictEqual(SM.webUrl("https://x.test/?q=%s", "a b&c"), "https://x.test/?q=a%20b%26c")
})

const EM = load("Emoji.js")
test("emoji: every word must start a keyword; empty lists all", () => {
    assert.ok(EM.search("hea").some(x => x.e === "❤️"))
    eq(EM.search("thumbs up").map(x => x.e), ["👍"])
    assert.strictEqual(EM.search("zzzzqq").length, 0)
    assert.strictEqual(EM.search("", 10).length, 10)
})

const OV = load("OverviewMath.js")
test("overview: which workspaces get a card", () => {
    eq(OV.range([1, 3], 1, 4), [1, 2, 3, 4, 5])
    eq(OV.range([1, 2, 7], 2, 0), [1, 2, 3, 4, 5, 6, 7, 8])
    eq(OV.range([10, -98], 10, 0), [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    eq(OV.range([], 1, 0), [1, 2])
})
test("overview: grid fits the area at the monitor's shape", () => {
    const g = OV.grid(5, 1500, 700, 1920, 1080, 20)
    assert.ok(g.cardW * g.cols + (g.cols - 1) * 20 <= 1500 + 1e-6)
    assert.ok(g.cardH * g.rows + (g.rows - 1) * 20 <= 700 + 1e-6)
    assert.ok(Math.abs(g.cardW / g.cardH - 16 / 9) < 1e-6)
    assert.ok(Math.abs(g.scale - g.cardW / 1920) < 1e-9)
})
test("overview: tiles stay inside their card; addresses compare; hit test", () => {
    const t = OV.tile([1900, 1060], [800, 600], { x: 0, y: 0, width: 1920, height: 1080 }, 0.1, 192, 108)
    assert.ok(t.x + t.w <= 192 && t.y + t.h <= 108)
    assert.strictEqual(OV.addr("0x55AB"), OV.addr("55ab"))
    assert.strictEqual(OV.cardAt(250, 10, 3, 200, 100, 20, 5), 1)
    assert.strictEqual(OV.cardAt(205, 10, 3, 200, 100, 20, 5), -1, "in the gap")
    assert.strictEqual(OV.cardAt(450, 130, 3, 200, 100, 20, 5), -1, "past the last card")
})

const KG = load("KeyGroups.js")
test("keys: groups, keycaps, filtered sections", () => {
    assert.strictEqual(KG.group("Close window"), "Windows")
    assert.strictEqual(KG.group("Volume up"), "Media")
    assert.strictEqual(KG.group("Overview"), "Phone and desktop")
    assert.strictEqual(KG.group("Terminal"), "Apps")
    assert.strictEqual(KG.group("Ultra saver (free GPU memory)"), "System")
    eq(KG.caps("SUPER + SHIFT + slash"), ["Super", "Shift", "/"])
    eq(KG.caps("XF86AudioMute"), ["Mute"])
    const s = KG.sections([{ combo: "SUPER + Q", label: "Terminal" }, { combo: "SUPER + X", label: "Close window" }], "")
    eq(s.map(x => x.name), ["Apps", "Windows"])
    eq(KG.sections([{ combo: "SUPER + Q", label: "Terminal" }, { combo: "SUPER + X", label: "Close window" }], "term").map(x => x.name), ["Apps"])
})

test("keys: groups dealt into even columns, in order inside each", () => {
    const sec = (name, n) => ({ name: name, binds: new Array(n).fill({}) })
    const list = [sec("Apps", 4), sec("Phone", 15), sec("Windows", 15), sec("Workspaces", 5), sec("System", 22), sec("Media", 10)]
    const cols = KG.columns(list, 3)
    eq(cols.length, 3)
    eq(cols.flat().map(s => s.name).sort(), list.map(s => s.name).sort())
    const rows = cols.map(c => c.reduce((a, s) => a + s.binds.length + 2, 0))
    assert.ok(Math.max(...rows) <= 30, "tallest column " + Math.max(...rows))
    for (const c of cols) eq(c.map(s => list.indexOf(s)), c.map(s => list.indexOf(s)).slice().sort((a, b) => a - b))
    eq(KG.columns([], 3), [[], [], []])
    eq(KG.columns([sec("Apps", 2)], 3).filter(c => c.length).length, 1)
})

const WH = load("Wheel.js")
test("wheel: offsets wrap the short way round", () => {
    assert.strictEqual(WH.offset(0, 0, 10), 0)
    assert.strictEqual(WH.offset(9, 0, 10), -1)
    assert.strictEqual(WH.offset(1, 9, 10), 2)
    assert.strictEqual(WH.offset(3, 0, 0), 0)
    assert.ok(Math.abs(WH.offset(0, 9.5, 10) - 0.5) < 1e-9, "follows a gliding pick across the seam")
})
test("wheel: the middle card is biggest and on top, sides are symmetric", () => {
    const c = WH.place(0, 200), l = WH.place(-1, 200), r = WH.place(1, 200)
    assert.ok(c.scale > r.scale && c.z > r.z && c.x === 0)
    assert.ok(Math.abs(l.x + r.x) < 1e-9 && Math.abs(l.y - r.y) < 1e-9 && r.y > 0)
    assert.strictEqual(WH.place(6, 200).opacity, 0)
})
test("wheel: sort by name or newest, names without folder or extension", () => {
    const it = [{ path: "/w/b.png", mtime: 5 }, { path: "/w/A.jpg", mtime: 9 }, { path: "/w/c.mp4", mtime: 1 }]
    eq(WH.sorted(it, "name").map(x => x.path), ["/w/A.jpg", "/w/b.png", "/w/c.mp4"])
    eq(WH.sorted(it, "new").map(x => x.path), ["/w/A.jpg", "/w/b.png", "/w/c.mp4"])
    eq(WH.sorted([{ path: "/w/z", mtime: 1 }, { path: "/w/y", mtime: 2 }], "new").map(x => x.path), ["/w/y", "/w/z"])
    assert.strictEqual(WH.baseName("/w/night city.webp"), "night city")
})

const HL = load("HyprLua.js")
test("hypr lua: dispatchers, addresses cleaned, nothing injectable", () => {
    assert.strictEqual(HL.workspace(3), "hl.dsp.focus({ workspace = 3 })")
    assert.strictEqual(HL.workspace("2); os.exit("), "hl.dsp.focus({ workspace = 2 })")
    assert.strictEqual(HL.addr("0x55A1"), "55a1")
    assert.strictEqual(HL.addr("55a1\"); os.exit(\""), "")
    assert.ok(HL.focusWindow("0x55a1").indexOf("hl.dsp.focus({ window = w })") > 0)
    assert.ok(HL.moveWindow("0x55a1", 4).indexOf("workspace = 4, follow = false, window = w") > 0)
    assert.ok(HL.closeWindow("0x55a1").indexOf("hl.dsp.window.close({ window = w })") > 0)
})

test("hypr lua: every dispatch is valid Lua as Hyprland wraps it", () => {
    const { spawnSync } = require("child_process")
    const luac = ["luac", "luac5.4", "luac5.3"].find(c => spawnSync("sh", ["-c", "command -v " + c]).status === 0)
    if (!luac) return
    for (const expr of [HL.workspace(2), HL.focusWindow("0x55a1"), HL.moveWindow("0x55a1", 4), HL.closeWindow("0x55a1")]) {
        const r = spawnSync(luac, ["-p", "-"], { input: "return hl.dispatch(" + expr + ")" })
        assert.strictEqual(r.status, 0, String(r.stderr))
    }
})

test("battery: warns once at 20, then 10 and 5, resets when charging", () => {
    let w = 101, said = []
    for (const pct of [25, 21, 20, 19, 15, 11, 10, 9, 6, 5, 4]) { const r = B.lowAlert(pct, false, w); w = r.warned; if (r.level) said.push(r.level) }
    eq(said, [20, 10, 5])
    assert.strictEqual(B.lowAlert(15, true, 10).warned, 101, "plugging in starts over")
    assert.strictEqual(B.lowAlert(30, false, 20).warned, 101, "charged back above it starts over")
    eq(B.lowAlert(8, false, 101), { level: 10, warned: 10 }, "first look at 8% warns at the 10% level")
})
const UP = load("Updates.js")
test("updates: parse repo and aur lines, flag Qt without quickshell", () => {
    const u = UP.parse("repo\tqt6-base\t6.12.0-1\t6.12.1-1\nrepo\tfirefox\t1\t2\naur\tmpvpaper\t1.7\t1.8\njunk\n")
    assert.strictEqual(u.total, 3)
    eq(u.aur.map(x => x.name), ["mpvpaper"])
    assert.strictEqual(u.qtRisk, true)
    assert.strictEqual(UP.parse("repo\tqt6-base\t1\t2\nrepo\tquickshell\t1\t2").qtRisk, false)
    assert.strictEqual(UP.parse("").total, 0)
})

test("updates: held and group columns are read, old output still works", () => {
    const u = UP.parse("repo\thyprland\t0.56.2\t0.57.2\theld\thypr\nrepo\tfirefox\t1\t2\t-\t-\nrepo\tvim\t1\t2\n")
    eq(u.repo.map(x => [x.name, x.held, x.group]), [["hyprland", true, "hypr"], ["firefox", false, ""], ["vim", false, ""]])
})
test("updates: pinned packages are listed but not counted as an update to install", () => {
    const u = UP.parse("repo\thyprland\t1\t2\theld\thypr\nrepo\tfirefox\t1\t2\t-\t-\nrepo\taquamarine\t1\t2\theld\thypr")
    eq([u.repo.length, u.total, u.heldCount], [3, 1, 2])
    eq(UP.parse("repo\thyprland\t1\t2\theld\thypr").total, 0)
    eq(UP.parse("repo\thyprland\t1\t2\theld\thypr").groups.length, 1)
})
test("updates: a pinned quickshell still counts as left behind when Qt moves", () => {
    const l = (qs) => "repo\tqt6-base\t1\t2\t-\tshell\nrepo\tquickshell\t1\t2\t" + qs + "\tshell"
    assert.strictEqual(UP.parse(l("held")).qtRisk, true)
    assert.strictEqual(UP.parse(l("-")).qtRisk, false)
})
test("updates: groups with something waiting, and how pinned they are", () => {
    const u = UP.parse([
        "repo\thyprland\t0.56.2-3\t0.57.2-1\theld\thypr", "repo\taquamarine\t0.15\t0.16\t-\thypr", "repo\tfirefox\t1\t2\t-\t-",
        "repo\tquickshell\t0.2.1-1\t0.2.1-2\t-\tshell", "repo\tqt6-base\t6.12.0\t6.12.1\t-\tshell"
    ].join("\n"))
    eq(u.groups.map(g => [g.id, g.state, g.from, g.to, g.items.length]),
       [["hypr", "mixed", "0.56.2-3", "0.57.2-1", 2], ["shell", "free", "0.2.1-1", "0.2.1-2", 2]])
    eq(u.groups[0].title, "Hyprland and its libraries")
    eq(UP.parse("repo\tfirefox\t1\t2\t-\t-").groups, [])
    eq(UP.parse("repo\thyprland\t1\t2\theld\thypr\nrepo\taquamarine\t1\t2\theld\thypr").groups[0].state, "held")
})
test("updates: the review starts pinned where anything is pinned, never unpins by surprise", () => {
    const gs = UP.parse("repo\thyprland\t1\t2\theld\thypr\nrepo\taquamarine\t1\t2\t-\thypr\nrepo\tqt6-base\t1\t2\t-\tshell").groups
    eq(UP.defaults(gs), { hypr: true, shell: false })
})
test("updates: the system's pins decide a group's state, even when the pinned part has no update", () => {
    eq(UP.pinStates("hypr held\nshell mixed qt6-base qt6-wayland\nnonsense\n"), { hypr: "held", shell: "mixed" })
    eq(UP.pinStates(""), {})

    const gs = UP.parse("repo\tqt6-base\t1\t2\t-\tshell\nrepo\tqt6-wayland\t1\t2\t-\tshell").groups
    eq(gs[0].state, "free")
    const fixed = UP.applyPins(gs, { shell: "mixed" })
    eq(fixed[0].state, "mixed")
    eq(UP.defaults(fixed), { shell: true })
    eq(UP.changes(fixed, { shell: true }), { hold: ["shell"], release: [] })
    eq(UP.changes(fixed, { shell: false }), { hold: [], release: ["shell"] })
    eq(UP.applyPins(gs, {})[0].state, "free")
})
test("updates: choices become the pin changes", () => {
    const gs = UP.parse("repo\thyprland\t1\t2\theld\thypr\nrepo\taquamarine\t1\t2\t-\thypr\nrepo\tqt6-base\t1\t2\t-\tshell").groups

    eq(UP.changes(gs, { hypr: true, shell: false }), { hold: ["hypr"], release: [] })

    eq(UP.changes(gs, { hypr: false, shell: true }), { hold: ["shell"], release: ["hypr"] })

    const whole = UP.parse("repo\thyprland\t1\t2\theld\thypr").groups
    eq(UP.changes(whole, { hypr: true }), { hold: [], release: [] })
})
test("updates: the arguments for the script", () => {
    eq(UP.runArgs({ hold: [], release: [] }, false), ["run"])
    eq(UP.runArgs({ hold: ["hypr", "shell"], release: [] }, true), ["run", "--hold", "hypr,shell", "--snapshot"])
    eq(UP.runArgs({ hold: ["shell"], release: ["hypr"] }, false), ["run", "--hold", "shell", "--release", "hypr"])
})
test("updates: the daily Apsis check line, and its card", () => {
    const t = "\t"
    eq(UP.selfStatus("new" + t + "1.0.0" + t + "1.1.0" + t + "3\n"), { status: "new", from: "1.0.0", to: "1.1.0", count: 3 })
    eq(UP.selfStatus("current" + t + "1.0.0" + t + "1.0.0" + t + "0").status, "current")
    eq(UP.selfStatus("!! no Apsis repo").status, "")
    eq(UP.selfStatus("").count, 0)
    eq(UP.selfCard(UP.selfStatus("new" + t + "1.0.0" + t + "1.1.0" + t + "3")), { title: "Apsis 1.1.0 is out", sub: "You have 1.0.0 · 3 changes" })
    eq(UP.selfCard(UP.selfStatus("new" + t + "1.0.0" + t + "1.0.0" + t + "1")).title, "Apsis has 1 new change")
    eq(UP.selfCard(UP.selfStatus("current" + t + "1.0.0" + t + "1.0.0" + t + "0")), null)
})
test("updates: what protects an update, in words", () => {
    let p = UP.protection("snapper yes\nsnappac yes\nbootable yes\n")
    eq([p.snapper, p.snappac, p.bootable, p.choice], [true, true, true, false])
    assert.ok(/boot menu/.test(p.line))
    p = UP.protection("snapper yes\nsnappac no\nbootable no")
    eq(p.choice, true)
    p = UP.protection("snapper no\nsnappac no\nbootable no")
    eq([p.choice, /No snapshots/.test(p.line)], [false, true])
    eq(UP.protection("").choice, false)
})

const TL = load("Tilt.js")
const near = (a, b, e) => Math.abs(a - b) <= (e || 1e-6)

test("tilt: no angle is the identity on the face", () => {
    const m = TL.matrix(380, 780, 0, 0, 1400)
    for (const [x, y] of [[0, 0], [380, 0], [190, 390], [12, 700]]) {
        const p = TL.project(m, x, y, 0)
        assert.ok(near(p.x, x) && near(p.y, y))
    }
})
test("tilt: the face centre stays put", () => {
    const m = TL.matrix(380, 780, 26, 10, 1400)
    const c = TL.project(m, 190, 390, 0)
    assert.ok(near(c.x, 190, 1e-6) && near(c.y, 390, 1e-6))
})
test("tilt: yaw > 0 shows the right wall, pitch > 0 the bottom wall", () => {
    const m = TL.matrix(380, 780, 26, 10, 1400)
    const fr = TL.project(m, 380, 390, 0), br = TL.project(m, 380, 390, -26)
    assert.ok(br.x > fr.x, "back right edge lies right of the front right edge")

    const mp = TL.matrix(380, 780, 26, 25, 1400)
    const fb = TL.project(mp, 190, 780, 0), bb = TL.project(mp, 190, 780, -26)
    assert.ok(bb.y > fb.y, "back bottom edge lies below the front bottom edge")
    const fl = TL.project(m, 0, 390, 0), bl = TL.project(m, 0, 390, -26)
    assert.ok(bl.x > fl.x, "the left wall is hidden behind the face")
})
test("tilt: the right edge comes nearer (looks taller) than the left", () => {
    const m = TL.matrix(380, 780, 26, 0, 1400)
    const rt = TL.project(m, 380, 0, 0), rb = TL.project(m, 380, 780, 0)
    const lt = TL.project(m, 0, 0, 0), lb = TL.project(m, 0, 780, 0)
    assert.ok(rb.y - rt.y > lb.y - lt.y)
})
test("tilt: the wall hull is convex and contains every projected corner", () => {
    const m = TL.matrix(380, 780, 26, 10, 1400)
    const h = TL.wall(m, 380, 780, 52, 0, -26)
    assert.ok(h.length >= 8)
    const cross = (o, a, b) => (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    for (let i = 0; i < h.length; i++)
        assert.ok(cross(h[i], h[(i + 1) % h.length], h[(i + 2) % h.length]) > 0, "convex, counter-clockwise")
    const inside = p => h.every((a, i) => cross(a, h[(i + 1) % h.length], p) >= -1e-6)
    for (const [x, y] of [[60, 60], [320, 60], [320, 720], [60, 720]])
        for (const z of [0, -26]) assert.ok(inside(TL.project(m, x, y, z)))
})
test("tilt: flat() keeps x, y and w, drops z", () => {
    const m = TL.matrix(380, 780, 24, 5, 1500), f = TL.flat(m)
    for (const [x, y] of [[0, 0], [380, 780], [100, 600]]) {
        const a = TL.project(m, x, y, 0), b = TL.project(f, x, y, 0)
        assert.ok(near(a.x, b.x) && near(a.y, b.y))
    }
    assert.deepStrictEqual([f[8], f[9], f[10], f[11]], [0, 0, 0, 0])
})
test("tilt: svg path", () => {
    assert.strictEqual(TL.svg([{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }]), "M0.00,0.00 L1.00,0.00 L1.00,1.00 Z")
    assert.strictEqual(TL.svg([]), "")
})

const AN = load("AudioNodes.js")
{
    const au = { volume: 1 }
    const speakers = { name: "alsa_output.pci-0000_05_00.6.analog-stereo", audio: au, isSink: true, isStream: false, properties: {} }
    const hdmi = { name: "alsa_output.pci-0000_01_00.1.hdmi-stereo", audio: au, isSink: true, isStream: false, properties: {} }
    const eeSink = { name: "easyeffects_sink", audio: au, isSink: true, isStream: false, properties: { "application.id": "com.github.wwmm.easyeffects" } }
    const eeSrc = { name: "easyeffects_source", audio: au, isSink: false, isStream: false, properties: {} }
    const mic = { name: "alsa_input.pci.analog-stereo", audio: au, isSink: false, isStream: false, properties: {} }
    const eeFilter = { name: "ee_soe_equalizer", audio: au, isSink: false, isStream: false, properties: {} }
    const eeOut = { name: "output_stream", audio: au, isSink: false, isStream: true, properties: { "application.name": "Easy Effects" } }
    const firefox = { name: "Firefox", audio: au, isSink: false, isStream: true, properties: { "application.name": "Firefox" } }
    const spotify = { name: "spotify", audio: au, isSink: false, isStream: true, properties: { "application.name": "Spotify", "media.class": "Stream/Output/Audio" } }
    const cava = { name: "cava", audio: au, isSink: false, isStream: true, properties: { "application.name": "cava", "media.class": "Stream/Input/Audio", "stream.capture.sink": "true" } }
    const all = [speakers, hdmi, eeSink, eeSrc, mic, eeFilter, eeOut, firefox, spotify, cava]
    test("audio: EasyEffects' own nodes stay out of the lists", () => {
        eq(AN.outputs(all).map(n => n.name), [speakers.name, hdmi.name])
        eq(AN.inputs(all).map(n => n.name), [mic.name])
        eq(AN.apps(all).map(n => n.name), ["Firefox", "spotify"])
    })
    test("audio: spots the sink loop and a running EasyEffects", () => {
        assert.strictEqual(AN.isEeSink(eeSink), true)
        assert.strictEqual(AN.isEeSink(speakers), false)
        assert.strictEqual(AN.isEeSink(null), false)
        assert.strictEqual(AN.eeRunning(all), true)
        assert.strictEqual(AN.eeRunning([speakers, firefox]), false)
    })
}

const GP = load("Gpu.js")
test("gpu: stats, with fields a laptop can't report", () => {
    eq(GP.stats("812, 8188, 46, 12.31, 3\n"), { used: 812, total: 8188, temp: 46, watts: 12.31, util: 3 })
    eq(GP.stats("812, 8188, 46, [N/A], 3"), { used: 812, total: 8188, temp: 46, watts: -1, util: 3 })
    eq(GP.stats(""), { used: -1, total: -1, temp: -1, watts: -1, util: -1 })
})
test("gpu: process table, compute and graphics apart", () => {
    const smi = [
        "+-----------------------------------------------------------------------------------------+",
        "| Processes:                                                                              |",
        "|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |",
        "|        ID   ID                                                               Usage      |",
        "|=========================================================================================|",
        "|    0   N/A  N/A            1310      G   /usr/bin/Hyprland                       412MiB |",
        "|    0   N/A  N/A            2244      G   ...ave-browser/brave --type=gpu-process  160MiB |",
        "|    0   N/A  N/A           90210      C   ...envs/train/bin/python3.12            6021MiB |",
        "|    0   N/A  N/A            3001    C+G   /usr/bin/blender                          N/A  |",
        "+-----------------------------------------------------------------------------------------+"
    ].join("\n")
    const p = GP.procs(smi)
    eq(p.map(x => [x.pid, x.type, x.mb]), [[90210, "C", 6021], [1310, "G", 412], [2244, "G", 160], [3001, "C+G", -1]])
    assert.strictEqual(p[0].name, "python3.12")
    assert.strictEqual(p[2].name, "brave")
    eq(GP.compute(p).map(x => x.pid), [90210, 3001])
    eq(GP.graphics(p).map(x => x.pid), [1310, 2244])
    eq(GP.procs("No running processes found"), [])
})
test("gpu: formatting", () => {
    assert.strictEqual(GP.gb(812), "0.79")
    assert.strictEqual(GP.gb(12288), "12.0")
    assert.strictEqual(GP.gb(-1), "?")
    assert.strictEqual(GP.frac({ used: 4094, total: 8188 }), 0.5)
    assert.strictEqual(GP.frac({ used: -1, total: -1 }), 0)
})

const DP = load("Display.js")
test("display: modes grouped by resolution, fastest first", () => {
    const m = DP.modes(["1920x1080@144.00Hz", "1920x1080@60.01Hz", "1280x720@60.00Hz", "2560x1440@59.95Hz", "1920x1080@144.00Hz", "junk"])
    eq(m.map(r => r.res), ["2560x1440", "1920x1080", "1280x720"])
    eq(m[1].rates, [144, 60.01])
    assert.strictEqual(DP.mode("1920x1080", 144), "1920x1080@144.00")
    assert.strictEqual(DP.nearest([144, 60.01], 143.98), 144)
})
test("display: only scales that give whole pixels", () => {
    eq(DP.scales(1920, 1080).map(DP.scaleText), ["100%", "125%", "133%", "150%", "160%", "167%"])
    eq(DP.scales(2560, 1600).map(DP.scaleArg), ["1", "1.25", "1.333333", "1.6", "1.666667", "2"])
})
test("display: current layout and script arguments", () => {
    const c = DP.current({ width: 1920, height: 1080, refreshRate: 143.981, x: 0, y: 0, scale: 1.25, transform: 0, mirrorOf: "none" })
    eq(c, { mode: "1920x1080@143.98", pos: "0x0", scale: "1.25", transform: "0", mirror: "-" })
    eq(DP.args("eDP-1", c), ["eDP-1", "1920x1080@143.98", "0x0", "1.25", "0", "-"])
})

const EV = load("Events.js")
const now = new Date(2026, 9, 27, 15, 0)
test("events: parse the three line forms", () => {
    eq(EV.parseLine("2026-11-03 Dentist", now), { date: "2026-11-03", text: "Dentist", yearly: false })
    eq(EV.parseLine("11-03 Mum's birthday", now), { date: "2026-11-03", text: "Mum's birthday", yearly: true })
    eq(EV.parseLine("+3 Call back", now), { date: "2026-10-30", text: "Call back", yearly: false })
    eq(EV.parseLine("+5 Over the month end", now).date, "2026-11-01")
})
test("events: bad lines are refused", () => {
    eq(EV.parseLine("", now), null)
    eq(EV.parseLine("2026-02-30 nope", now), null)
    eq(EV.parseLine("13-40 nope", now), null)
    eq(EV.parseLine("2026-11-03", now), null)
    eq(EV.parseLine("just words", now), null)
    eq(EV.parseLine("02-29 Leap day", now).yearly, true)
})
test("events: upcoming sorts, drops past one-offs, rolls yearly forward", () => {
    const list = [
        { date: "2026-10-01", text: "past", yearly: false },
        { date: "2026-12-25", text: "xmas", yearly: false },
        { date: "1990-10-28", text: "birthday", yearly: true },
        { date: "2026-10-27", text: "today thing", yearly: false },
        { date: "2020-10-26", text: "just passed yearly", yearly: true }
    ]
    const u = EV.upcoming(list, now, 0)
    eq(u.map(e => e.text), ["today thing", "birthday", "xmas", "just passed yearly"])
    eq(u.map(e => e.days), [0, 1, 59, 364])
    eq(u[3].date, "2027-10-26")
    eq(EV.upcoming(list, now, 2).length, 2)
})
test("events: 29 Feb repeats in leap years only", () => {
    const u = EV.upcoming([{ date: "2024-02-29", text: "leap", yearly: true }], now, 0)
    eq(u[0].date, "2028-02-29")
})
test("events: when() wording", () => {
    eq([0, 1, 3, 8, 21].map(EV.when), ["today", "tomorrow", "in 3 days", "next week", "in 3 weeks"])
})

test("presets: an old preset leaves newer widget types alone", () => {
    const types = Object.assign({}, W.TYPES)
    const live = { palette: "cherry", mode: "dark", dock: {}, bar: {}, widgets: [
        { id: "a", type: "clock", x: 0, y: 0, screen: "", style: {} },
        { id: "e1", type: "events", x: 50, y: 60, screen: "", style: {}, events: [{ date: "2026-11-03", text: "x", yearly: false }] }
    ] }
    const old = { version: 1, palette: "navy", mode: "dark", widgets: [{ id: "b", type: "note", x: 5, y: 5, screen: "", style: {} }] }
    const out = P.apply(old, live, types)
    eq(out.widgets.map(w => w.id), ["b", "e1"])
    eq(out.widgets[1].events.length, 1)
})
test("presets: a new preset knows every type, so it replaces them", () => {
    const live = { palette: "cherry", mode: "dark", dock: {}, bar: {}, widgets: [{ id: "e1", type: "events", x: 0, y: 0, screen: "", style: {}, events: [] }] }
    const saved = P.capture("x", { palette: "navy", mode: "dark", widgets: [], dock: {}, bar: {} }, W.TYPES)
    assert.ok(saved.types.indexOf("events") >= 0)
    eq(P.apply(saved, live, W.TYPES).widgets, [])
})
test("presets: favourites sort first, then A to Z", () => {
    eq(P.sortedNames({ beta: {}, Alpha: {}, zed: { favorite: true }, cat: {} }), ["zed", "Alpha", "beta", "cat"])
})
test("presets: rename keeps data, refuses clashes and empties", () => {
    const pr = { one: { name: "one", palette: "navy" }, two: { name: "two" } }
    let r = P.rename(pr, "one", "Uno!")
    eq(r.ok, true); eq(Object.keys(r.presets), ["Uno", "two"]); eq(r.presets.Uno.palette, "navy"); eq(r.presets.Uno.name, "Uno")
    eq(P.rename(pr, "one", "two").why, "exists")
    eq(P.rename(pr, "one", "  ").why, "empty")
    eq(P.rename(pr, "gone", "x").why, "missing")
    eq(P.rename(pr, "one", "one").ok, true)
})

const BL = load("BarLayout.js")
test("bar layout: default is valid and complete", () => {
    eq(BL.normalize(null), BL.DEFAULT)
    eq(BL.normalize({}).right, ["settings"])
    const all = [].concat(BL.DEFAULT.left, BL.DEFAULT.center, BL.DEFAULT.right).sort()
    eq(all, BL.MODULES.map(m => m.id).sort())
})
test("bar layout: junk is cleaned", () => {
    const l = BL.normalize({ left: ["clock", "clock", "nope", 5], center: ["clock", "volume"], right: "x" })
    eq(l, { left: ["clock"], center: ["volume"], right: ["settings"] })
})
test("bar layout: place moves between groups and off", () => {
    let l = BL.place(BL.DEFAULT, "clock", "left", 0)
    eq(l.left[0], "clock"); eq(BL.groupOf(l, "clock"), "left"); eq(l.center, ["media"])
    l = BL.place(l, "media", "off")
    eq(BL.groupOf(l, "media"), "off")
    l = BL.place(l, "media", "right")
    eq(l.right[l.right.length - 1], "media")
    eq(BL.place(l, "settings", "off"), l)
    eq(BL.place(l, "ghost", "left"), l)
    eq(BL.place(l, "clock", "middle"), l)
})
test("bar layout: shift stays inside the group", () => {
    let l = BL.shift(BL.DEFAULT, "resources", -1)
    eq(l.left, ["resources", "workspaces"])
    eq(BL.shift(l, "resources", -1), l)
    eq(BL.shift(BL.DEFAULT, "settings", 1), BL.DEFAULT)
    eq(BL.shift(BL.place(BL.DEFAULT, "tray", "off"), "tray", 1).right.indexOf("tray"), -1)
})

test("lrc: enhanced lines carry words", () => {
    const L = load("Lrc.js")
    const l = L.parse("[00:12.00]<00:12.00>he<00:12.40>llo <00:13.00>world\n[00:20.00]plain line")
    eq(l[0].text, "hello world")
    eq(l[0].words.map(w => w.text), ["he", "llo ", "world"])
    eq(l[0].words.map(w => w.t), [12, 12.4, 13])
    eq(l[1].words, undefined)
    eq(l[1].text, "plain line")
})
test("lrc: word times follow an offset tag and a repeated stamp", () => {
    const L = load("Lrc.js")
    const l = L.parse("[offset:+500]\n[00:10.00][00:30.00]<00:10.00>a<00:11.00>b")
    eq(l.length, 2)
    eq(l[0].words.map(w => w.t), [9.5, 10.5])
    eq(l[1].t, 29.5)
    eq(l[1].words.map(w => w.t), [29.5, 30.5])
})
test("lrc: wordFrac sweeps each word and holds the last", () => {
    const L = load("Lrc.js")
    const w = [{ t: 10, text: "a " }, { t: 11, text: "b " }, { t: 12, text: "c" }]
    eq(L.wordFrac(w, 0, 10.5, 20), 0.5)
    eq(L.wordFrac(w, 0, 12, 20), 1)
    eq(L.wordFrac(w, 1, 10, 20), 0)
    eq(L.wordFrac(w, 2, 12.75, 20), 0.5)
    eq(L.wordFrac(w, 5, 12, 20), 0)
    eq(L.wordFrac(null, 0, 1, 2), 0)
})
test("lrc: text before the first tag is kept", () => {
    const L = load("Lrc.js")
    const l = L.parse("[00:01.00]oh <00:02.00>yeah")
    eq(l[0].words.map(w => w.text), ["oh ", "yeah"])
    eq(l[0].text, "oh yeah")
    eq(l[0].words.map(w => w.t), [1, 2])
})

test("cheat sheet: game and focus mode are System, random wallpaper is desktop", () => {
    const KG = load("KeyGroups.js")
    eq(KG.group("Game mode"), "System")
    eq(KG.group("Focus mode"), "System")
    eq(KG.group("Random wallpaper"), "Phone and desktop")
    eq(KG.group("Focus left"), "Windows")
})

test("btagent: a request from the helper is read", () => {
    const B = load("BtAgent.js")
    const r = B.parse('{"event":"request","id":3,"kind":"confirm","name":"Pixel","address":"AA:BB","code":"004242"}')
    eq(r, { event: "request", id: 3, kind: "confirm", name: "Pixel", address: "AA:BB", code: "004242", uuid: "" })
})
test("btagent: noise and half lines are ignored", () => {
    const B = load("BtAgent.js")
    eq(B.parse("Traceback (most recent call last):"), null)
    eq(B.parse('{"event":"request","kind":"confirm"}'), null)
    eq(B.parse('{"event":"nope"}'), null)
    eq(B.parse("[]"), null)
    eq(B.parse(""), null)
})
test("btagent: registered, cancel and display events", () => {
    const B = load("BtAgent.js")
    eq(B.parse('{"event":"registered"}'), { event: "registered" })
    eq(B.parse('{"event":"cancel"}'), { event: "cancel", id: -1 })
    eq(B.parse('{"event":"cancel","id":4}'), { event: "cancel", id: 4 })
    eq(B.parse('{"event":"display","name":"Keys","address":"A","code":"000987","entered":3}'),
       { event: "display", name: "Keys", address: "A", code: "000987", entered: 3 })
})
test("btagent: replies carry the id, the answer and a typed value", () => {
    const B = load("BtAgent.js")
    eq(JSON.parse(B.reply(7, true)), { id: 7, accept: true })
    eq(JSON.parse(B.reply(7, false)), { id: 7, accept: false })
    eq(JSON.parse(B.reply(7, true, "0000")), { id: 7, accept: true, value: "0000" })
    eq(B.reply(1, true).endsWith("\n"), true)
    eq(JSON.parse(B.reply(7, "yes")), { id: 7, accept: false })
})
test("btagent: the code is shown in two halves", () => {
    const B = load("BtAgent.js")
    eq(B.groupCode("004242"), "004 242")
    eq(B.groupCode("12"), "12")
})
test("btagent: each kind of request has its card", () => {
    const B = load("BtAgent.js")
    let v = B.view({ kind: "confirm", name: "Pixel", code: "123456" })
    eq([v.title, v.code, v.input, v.accept], ["Pair with Pixel?", "123 456", "", "Pair"])
    eq(B.view({ kind: "pin", name: "Pixel" }).input, "pin")
    eq(B.view({ kind: "passkey", name: "Pixel" }).input, "passkey")
    v = B.view({ kind: "service", name: "Buds", uuid: "0000110B-0000-1000-8000-00805f9b34fb" })
    eq([v.title, v.lead, v.accept], ["Buds wants to connect", "It asks to play audio.", "Allow"])
    eq(B.view({ kind: "service", name: "X", uuid: "deadbeef" }).lead, "It asks to use a Bluetooth service.")
    v = B.view({ kind: "display", name: "Keys", code: "000987" })
    eq([v.code, v.accept, v.reject], ["000987", "", "Hide"])
})
test("btagent: a PIN or passkey must be sane before it is sent", () => {
    const B = load("BtAgent.js")
    eq(B.inputOk("pin", "0000"), true)
    eq(B.inputOk("pin", ""), false)
    eq(B.inputOk("pin", "x".repeat(17)), false)
    eq(B.inputOk("passkey", "123456"), true)
    eq(B.inputOk("passkey", "1234567"), false)
    eq(B.inputOk("passkey", "12a"), false)
    eq(B.inputOk("", ""), true)
})
test("btagent: requests queue in order; a shown code updates in place", () => {
    const B = load("BtAgent.js")
    let q = []
    q = B.push(q, { event: "request", id: 1, kind: "confirm", address: "A" })
    q = B.push(q, { event: "request", id: 2, kind: "confirm", address: "A" })
    eq(q.map(r => r.id), [1, 2])
    q = B.push(q, { event: "display", address: "K", code: "000111", entered: 1 })
    q = B.push(q, { event: "display", address: "K", code: "000111", entered: 4 })
    eq(q.length, 3)
    eq(q[2].entered, 4)
    eq(q[2].kind, "display")
    eq(B.drop(q, 1).map(r => r.id), [2, "display:K"])
})
test("btagent: more than five waiting at once is refused", () => {
    const B = load("BtAgent.js")
    let q = []
    for (let i = 0; i < 5; i++) { eq(B.overLimit(q), false); q = B.push(q, { event: "request", id: i, kind: "authorize", address: "A" + i }) }
    eq(B.overLimit(q), true)
})

console.log(passed + " passed, " + failed + " failed")
process.exit(failed ? 1 : 0)
