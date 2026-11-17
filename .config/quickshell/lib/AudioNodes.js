.pragma library

// Tells EasyEffects' own PipeWire nodes apart from real devices and apps.
// Edit: EE_ID or the name checks if EasyEffects changes its node names.

var EE_ID = "com.github.wwmm.easyeffects"
var EE_NAMES = ["easyeffects_sink", "easyeffects_source"]

function props(n) { return n && n.properties ? n.properties : {} }

function isEe(n) {
    if (!n) return false
    var name = String(n.name || "")
    if (EE_NAMES.indexOf(name) >= 0 || name.indexOf("ee_") === 0) return true
    var p = props(n)
    if (p["application.id"] === EE_ID) return true
    var app = String(p["application.name"] || "").toLowerCase().replace(/\s+/g, "")
    return app === "easyeffects"
}

function isEeSink(n) { return !!n && n.name === "easyeffects_sink" }

function outputs(nodes) { return nodes.filter(n => n.audio && n.isSink && !n.isStream && !isEe(n)) }
function inputs(nodes) { return nodes.filter(n => n.audio && !n.isSink && !n.isStream && !isEe(n)) }

function mediaClass(n) { return String(props(n)["media.class"] || "") }
function apps(nodes) {
    return nodes.filter(n => {
        if (!n.audio || !n.isStream || isEe(n)) return false
        var mc = mediaClass(n)
        return mc ? mc === "Stream/Output/Audio" : !n.isSink
    })
}
function eeRunning(nodes) { return nodes.some(n => isEeSink(n)) }
