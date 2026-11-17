.pragma library

// The Apps search calculator: its own parser (no eval), percent, trig in degrees.
// Edit: FN for functions, CONST for constants.

function tokens(s) {
    var out = [], i = 0
    s = s.replace(/×|x(?=\s*[\d(.])/g, "*").replace(/÷/g, "/").replace(/\*\*/g, "^").replace(/,/g, "")
    while (i < s.length) {
        var c = s[i]
        if (/\s/.test(c)) { i++; continue }
        var num = /^(\d+\.?\d*|\.\d+)(e[+-]?\d+)?/i.exec(s.substring(i))
        if (num) { out.push({ t: "n", v: parseFloat(num[0]) }); i += num[0].length; continue }
        var word = /^[a-z]+/i.exec(s.substring(i))
        if (word) { out.push({ t: "w", v: word[0].toLowerCase() }); i += word[0].length; continue }
        if ("+-*/%^()".indexOf(c) >= 0) { out.push({ t: "o", v: c }); i++; continue }
        throw new Error("bad character " + c)
    }
    return out
}

var FN = {
    sqrt: Math.sqrt, abs: Math.abs, round: Math.round, floor: Math.floor, ceil: Math.ceil,
    ln: Math.log, log: function(x) { return Math.log(x) / Math.LN10 },
    sin: function(x) { return Math.sin(x * Math.PI / 180) },
    cos: function(x) { return Math.cos(x * Math.PI / 180) },
    tan: function(x) { return Math.tan(x * Math.PI / 180) },
    asin: function(x) { return Math.asin(x) * 180 / Math.PI },
    acos: function(x) { return Math.acos(x) * 180 / Math.PI },
    atan: function(x) { return Math.atan(x) * 180 / Math.PI }
}
var CONST = { pi: Math.PI, e: Math.E }

function evaluate(src) {
    var tk = tokens(String(src).replace(/^\s*=/, "")), p = 0
    function peek() { return tk[p] }
    function eat(v) { if (tk[p] && tk[p].v === v) { p++; return true } return false }

    function expr() {
        var f = term()
        var v = f.pct ? f.v / 100 : f.v
        for (;;) {
            if (eat("+")) { var r = term(); v = r.pct ? v + v * r.v / 100 : v + r.v; continue }
            if (eat("-")) { var s = term(); v = s.pct ? v - v * s.v / 100 : v - s.v; continue }
            return v
        }
    }

    function term() {
        var a = unary(), pct = false
        for (;;) {
            var t = peek()
            if (t && t.v === "%") {
                var nx = tk[p + 1]
                if (nx && nx.t === "w" && nx.v === "of") { p += 2; a = a / 100 * unary(); continue }
                if (!nx || nx.v === ")" || nx.v === "+" || nx.v === "-") { p++; pct = true; continue }
                if (nx.v === "*" || nx.v === "/") { p++; a = a / 100; continue }
                p++; a = a % unary(); continue
            }
            if (eat("*")) { a = (pct ? a / 100 : a) * unary(); pct = false; continue }
            if (eat("/")) { a = (pct ? a / 100 : a) / unary(); pct = false; continue }
            return { v: a, pct: pct }
        }
    }

    function unary() {
        if (eat("-")) return -unary()
        if (eat("+")) return unary()
        return power()
    }
    function power() {
        var b = atom()
        if (eat("^")) return Math.pow(b, unary())
        return b
    }
    function atom() {
        var t = tk[p++]
        if (!t) throw new Error("end")
        if (t.t === "n") return t.v
        if (t.v === "(") { var v = expr(); if (!eat(")")) throw new Error(")"); return v }
        if (t.t === "w") {
            if (CONST.hasOwnProperty(t.v)) return CONST[t.v]
            if (FN.hasOwnProperty(t.v)) return FN[t.v](unary())
        }
        throw new Error("unexpected " + t.v)
    }
    var out = expr()
    if (p !== tk.length) throw new Error("trailing")
    return out
}

function answer(src) {
    try {
        var v = evaluate(src)
        if (typeof v !== "number" || !isFinite(v)) return ""
        var r = Math.abs(v) >= 1e15 || (Math.abs(v) < 1e-6 && v !== 0) ? v.toExponential(6) : String(parseFloat(v.toPrecision(12)))
        return r
    } catch (e) {
        return ""
    }
}

function looksLike(q) {
    q = String(q || "").trim()
    if (q === "") return false
    if (q.charAt(0) === "=") return true
    if (!/[\d]|\bpi\b/i.test(q)) return false
    if (!/[+\-*/^%×÷x()]|\b(sqrt|sin|cos|tan|log|ln|abs|of)\b/i.test(q)) return false
    return /^[\d\s+\-*/^%().,×÷xa-z]+$/i.test(q)
}
