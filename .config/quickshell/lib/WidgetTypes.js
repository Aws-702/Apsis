.pragma library

// Every desktop widget type: size, shelf title, look options and personal fields.
// Edit: TYPES; a new type also needs desktop/widgets/<Name>Widget.qml.

var TYPES = {
    clock:    { w: 336, h: 148, title: "Clock",    file: "ClockWidget.qml",    style: { seconds: false, h24: true },   personal: [] },
    calendar: { w: 264, h: 252, title: "Calendar", file: "CalendarWidget.qml", style: { weekStart: 0 },                personal: [] },
    weather:  { w: 264, h: 160, title: "Weather",  file: "WeatherWidget.qml",  style: { forecast: false },             personal: [] },
    media:    { w: 360, h: 132, title: "Media",    file: "MediaWidget.qml",    style: {},                              personal: [] },
    todo:     { w: 280, h: 300, title: "To-do",    file: "TodoWidget.qml",     style: {},                              personal: ["items"] },
    note:     { w: 240, h: 200, title: "Note",     file: "NoteWidget.qml",     style: { tint: "accent" },              personal: ["text"] },
    stats:    { w: 280, h: 128, title: "System",   file: "StatsWidget.qml",    style: {},                              personal: [] },
    visualizer: { w: 420, h: 168, title: "Visualizer", file: "VisualizerWidget.qml", style: { look: "blocks" },    personal: [] },
    lyrics:   { w: 440, h: 196, title: "Lyrics",   file: "LyricsWidget.qml",   style: {},                              personal: [] },
    events:   { w: 300, h: 230, title: "Events",   file: "EventsWidget.qml",   style: {},                              personal: ["events"] },
    image:    { w: 240, h: 240, title: "Picture",  file: "ImageWidget.qml",    style: { square: false },               personal: ["path"] },
    palette:  { w: 420, h: 100, title: "Palette",  file: "PaletteWidget.qml",  style: {},                              personal: [] },
    user:     { w: 320, h: 112, title: "You",      file: "UserWidget.qml",     style: {},                              personal: [] }
}

var ORDER = ["clock", "calendar", "weather", "media", "visualizer", "lyrics", "todo", "note", "events", "image", "palette", "user", "stats"]

function has(type) {
    return TYPES.hasOwnProperty(type)
}

function info(type) {
    return has(type) ? TYPES[type] : null
}

function size(type, style) {
    var t = info(type)
    if (!t) return { w: 0, h: 0 }
    if (type === "weather" && style && style.forecast === true) return { w: 340, h: 268 }
    return { w: t.w, h: t.h }
}

function styleOf(type, style) {
    var t = info(type)
    if (!t) return {}
    var out = {}
    for (var k in t.style) out[k] = (style && style.hasOwnProperty(k)) ? style[k] : t.style[k]
    return out
}
