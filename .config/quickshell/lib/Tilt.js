.pragma library

// The 2.5D phone: one perspective matrix and the side wall shape.
// Edit: the default angle and camera distance in phone/PhoneStage.qml.

function ident() { return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1] }

function mul(a, b) {
    var r = new Array(16)
    for (var i = 0; i < 4; i++)
        for (var j = 0; j < 4; j++) {
            var s = 0
            for (var k = 0; k < 4; k++) s += a[i * 4 + k] * b[k * 4 + j]
            r[i * 4 + j] = s
        }
    return r
}

function trans(x, y, z) { return [1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, z, 0, 0, 0, 1] }

function rotY(deg) {
    var r = deg * Math.PI / 180, c = Math.cos(r), s = Math.sin(r)
    return [c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1]
}

function rotX(deg) {
    var r = deg * Math.PI / 180, c = Math.cos(r), s = Math.sin(r)
    return [1, 0, 0, 0, 0, c, -s, 0, 0, s, c, 0, 0, 0, 0, 1]
}

function persp(d) { return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, -1 / d, 1] }

function matrix(W, H, yaw, pitch, d) {
    var m = trans(W / 2, H / 2, 0)
    m = mul(m, persp(d))
    m = mul(m, rotY(-yaw))
    m = mul(m, rotX(pitch))
    return mul(m, trans(-W / 2, -H / 2, 0))
}

function flat(m) {
    var r = m.slice()
    r[8] = 0; r[9] = 0; r[10] = 0; r[11] = 0
    return r
}

function project(m, x, y, z) {
    var X = m[0] * x + m[1] * y + m[2] * z + m[3]
    var Y = m[4] * x + m[5] * y + m[6] * z + m[7]
    var Wc = m[12] * x + m[13] * y + m[14] * z + m[15]
    return { x: X / Wc, y: Y / Wc }
}

function outline(W, H, R, perCorner) {
    var n = perCorner || 8
    var r = Math.max(0, Math.min(R, W / 2, H / 2))
    var corners = [[r, r, Math.PI], [W - r, r, 1.5 * Math.PI], [W - r, H - r, 0], [r, H - r, 0.5 * Math.PI]]
    var pts = []
    for (var c = 0; c < 4; c++)
        for (var i = 0; i <= n; i++) {
            var a = corners[c][2] + (i / n) * Math.PI / 2
            pts.push({ x: corners[c][0] + r * Math.cos(a), y: corners[c][1] + r * Math.sin(a) })
        }
    return pts
}

function hull(pts) {
    var p = pts.slice().sort(function (a, b) { return a.x === b.x ? a.y - b.y : a.x - b.x })
    if (p.length < 3) return p
    function cross(o, a, b) { return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) }
    var lower = [], upper = []
    for (var i = 0; i < p.length; i++) {
        while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], p[i]) <= 0) lower.pop()
        lower.push(p[i])
    }
    for (var j = p.length - 1; j >= 0; j--) {
        while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], p[j]) <= 0) upper.pop()
        upper.push(p[j])
    }
    upper.pop()
    lower.pop()
    return lower.concat(upper)
}

function wall(m, W, H, R, z0, z1) {
    var o = outline(W, H, R, 8)
    var pts = []
    for (var i = 0; i < o.length; i++) {
        pts.push(project(m, o[i].x, o[i].y, z0))
        pts.push(project(m, o[i].x, o[i].y, z1))
    }
    return hull(pts)
}

function sideKey(m, W, y0, y1, stick, z0, z1) {
    var pts = []
    var xs = [W - 2, W + stick], ys = [y0, y1], zs = [z0, z1]
    for (var a = 0; a < 2; a++)
        for (var b = 0; b < 2; b++)
            for (var c = 0; c < 2; c++) pts.push(project(m, xs[a], ys[b], zs[c]))
    return hull(pts)
}

function svg(pts) {
    if (!pts.length) return ""
    var s = "M" + pts[0].x.toFixed(2) + "," + pts[0].y.toFixed(2)
    for (var i = 1; i < pts.length; i++) s += " L" + pts[i].x.toFixed(2) + "," + pts[i].y.toFixed(2)
    return s + " Z"
}
