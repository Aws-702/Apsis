.pragma library

// The pairing agent's messages: parse its JSON lines, build replies, and the card's texts.
// Edit: view() for titles and button labels, SERVICES for names, MAX_WAITING for the queue.

var MAX_WAITING = 5

function parse(line) {
    var m
    try { m = JSON.parse(line) } catch (e) { return null }
    if (!m || typeof m !== "object" || typeof m.event !== "string") return null
    if (m.event === "request") {
        if (typeof m.id !== "number" || typeof m.kind !== "string") return null
        return {
            event: "request", id: m.id, kind: m.kind,
            name: String(m.name || m.address || "A device"),
            address: String(m.address || ""),
            code: m.code === undefined ? "" : String(m.code),
            uuid: m.uuid === undefined ? "" : String(m.uuid)
        }
    }
    if (m.event === "display") {
        return {
            event: "display",
            name: String(m.name || m.address || "A device"),
            address: String(m.address || ""),
            code: String(m.code === undefined ? "" : m.code),
            entered: Number(m.entered) || 0
        }
    }
    if (m.event === "cancel") return { event: "cancel", id: typeof m.id === "number" ? m.id : -1 }
    if (m.event === "error") return { event: "error", message: String(m.message || "") }
    if (m.event === "registered" || m.event === "unregistered") return { event: m.event }
    return null
}

function reply(id, accept, value) {
    var m = { id: id, accept: accept === true }
    if (value !== undefined && value !== null && value !== "") m.value = String(value)
    return JSON.stringify(m) + "\n"
}

function groupCode(code) {
    var c = String(code || "")
    if (c.length !== 6) return c
    return c.slice(0, 3) + " " + c.slice(3)
}

var SERVICES = {
    "0000110b": "play audio",
    "0000110a": "send audio",
    "0000110d": "play audio",
    "0000111e": "make calls",
    "0000111f": "make calls",
    "00001124": "act as a keyboard or mouse",
    "00001105": "send files",
    "00001106": "send files",
    "0000112f": "read contacts",
    "00001132": "read messages",
    "00001115": "share your network",
    "00001116": "share your network"
}
function serviceName(uuid) { return SERVICES[String(uuid || "").slice(0, 8).toLowerCase()] || "use a Bluetooth service" }

function view(r) {
    var who = r.name || "a device"
    switch (r.kind) {
    case "confirm":
        return { title: "Pair with " + who + "?", lead: "Check that this code is the same on " + who + ".",
                 code: groupCode(r.code), input: "", accept: "Pair", reject: "Cancel" }
    case "authorize":
        return { title: who + " wants to pair", lead: "Only allow it if you started this.",
                 code: "", input: "", accept: "Pair", reject: "Refuse" }
    case "pin":
        return { title: "Pairing with " + who, lead: "Type the PIN for " + who + ". Often 0000 or 1234.",
                 code: "", input: "pin", accept: "Pair", reject: "Cancel" }
    case "passkey":
        return { title: "Pairing with " + who, lead: "Type the passkey shown on " + who + ".",
                 code: "", input: "passkey", accept: "Pair", reject: "Cancel" }
    case "service":
        return { title: who + " wants to connect", lead: "It asks to " + serviceName(r.uuid) + ".",
                 code: "", input: "", accept: "Allow", reject: "Refuse" }
    case "display":
        return { title: "Pairing with " + who, lead: "Type this code on " + who + ", then press Enter.",
                 code: r.code, input: "", accept: "", reject: "Hide" }
    }
    return { title: who, lead: "", code: "", input: "", accept: "OK", reject: "Cancel" }
}

function inputOk(input, text) {
    var t = String(text || "")
    if (input === "pin") return t.length >= 1 && t.length <= 16
    if (input === "passkey") return /^[0-9]{1,6}$/.test(t)
    return true
}

function push(queue, req) {
    var q = queue.slice()
    var r = {}
    for (var k in req) r[k] = req[k]
    r.kind = r.kind || r.event
    if (r.event === "display") {
        r.id = "display:" + r.address
        for (var i = 0; i < q.length; i++) {
            if (q[i].id === r.id) { q[i] = r; return q }
        }
    }
    q.push(r)
    return q
}

function overLimit(queue) { return queue.length >= MAX_WAITING }

function drop(queue, id) { return queue.filter(function(r) { return r.id !== id }) }
