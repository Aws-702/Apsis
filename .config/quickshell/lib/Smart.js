.pragma library
.import "Calc.js" as Calc
.import "ColorConv.js" as Color

// What an Apps search is besides apps: emoji, clipboard, web, calculator, colour, address.
// Edit: the prefixes in classify().

function classify(query) {
    var s = String(query || "")
    var t = s.trim()
    if (t === "") return { kind: "", q: "" }
    var c = t.charAt(0)
    if (c === ":") return { kind: "emoji", q: t.substring(1).trim() }
    if (c === ">") return { kind: "clip", q: t.substring(1).trim() }
    if (c === "?") return { kind: "web", q: t.substring(1).trim() }
    if (Color.parse(t) && (c === "#" || /^(rgb|hsl)/i.test(t))) return { kind: "color", q: t }
    if (Calc.looksLike(t) && Calc.answer(t) !== "") return { kind: "calc", q: t }
    if (/^https?:\/\/\S+$/i.test(t) || /^[a-z0-9-]+(\.[a-z0-9-]+)*\.[a-z]{2,}(\/\S*)?$/i.test(t)) return { kind: "url", q: t }
    return { kind: "", q: t }
}

function url(q) { return /^https?:\/\//i.test(q) ? q : "https://" + q }

function webUrl(template, q) { return String(template || "https://duckduckgo.com/?q=%s").replace("%s", encodeURIComponent(q)) }
