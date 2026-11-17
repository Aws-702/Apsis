.pragma library

// Reads nvidia-smi output for the GPU card and the phone's GPU readout.
// Edit: which programs count as compute in the classify function.

function num(v) {
    var n = parseFloat(String(v === undefined ? "" : v).trim())
    return isNaN(n) ? -1 : n
}

function stats(text) {
    var line = String(text || "").trim().split("\n")[0] || ""
    var f = line.split(",")
    return { used: num(f[0]), total: num(f[1]), temp: num(f[2]), watts: num(f[3]), util: num(f[4]) }
}

function procs(text) {
    var out = []
    var lines = String(text || "").split("\n")
    var re = /^\|\s+\d+\s+\S+\s+\S+\s+(\d+)\s+(C\+G|C|G)\s+(.+?)\s+(\d+MiB|N\/A)\s+\|\s*$/
    for (var i = 0; i < lines.length; i++) {
        var m = re.exec(lines[i])
        if (!m) continue

        var path = m[3].trim().split(/\s+/)[0]
        var name = path.substring(path.lastIndexOf("/") + 1)

        name = name.replace(/^\.\.\./, "")
        out.push({ pid: parseInt(m[1]), type: m[2], name: name, mb: m[4] === "N/A" ? -1 : parseInt(m[4]) })
    }
    out.sort(function(a, b) { return b.mb - a.mb })
    return out
}

function compute(list) { return list.filter(function(p) { return p.type !== "G" }) }
function graphics(list) { return list.filter(function(p) { return p.type === "G" }) }

function gb(mb) { return mb < 0 ? "?" : (mb / 1024).toFixed(mb < 10240 ? 2 : 1) }
function frac(s) { return s.total > 0 && s.used >= 0 ? Math.min(1, s.used / s.total) : 0 }
