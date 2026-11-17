.pragma library

// Builds the Lua dispatch expressions the shell sends to Hyprland 0.55+ (focus, move, close).
// Edit: add a dispatcher here when the shell needs a new Hyprland action.

function _int(n) {
    var v = parseInt(n)
    return isFinite(v) ? v : 0
}

function addr(a) {
    var s = String(a || "").toLowerCase().replace(/^0x/, "")
    return /^[0-9a-f]+$/.test(s) ? s : ""
}

function workspace(n) {
    return "hl.dsp.focus({ workspace = " + _int(n) + " })"
}

function _onWindow(address, dsp) {
    var a = addr(address)
    return "(function() local w for _, x in ipairs(hl.get_windows()) do "
         + "local a = string.lower(tostring(x.address)):gsub(\"^0x\", \"\") "
         + "if a == \"" + a + "\" then w = x end end "
         + "if not w then return nil end return " + dsp + " end)()"
}

function focusWindow(address) { return _onWindow(address, "hl.dsp.focus({ window = w })") }

function moveWindow(address, ws) {
    return _onWindow(address, "hl.dsp.window.move({ workspace = " + _int(ws) + ", follow = false, window = w })")
}

function closeWindow(address) { return _onWindow(address, "hl.dsp.window.close({ window = w })") }
