-- Apsis -- Hyprland config: the base (environment, monitor, input, look, window keys), then
-- apsis-session.lua, apsis-keys.lua and your custom.lua; errors go to ~/.cache/apsis/hypr-errors.log.
-- Edit: term, files, browser, editor, the env lines and the look here; your own things in custom.lua.

local mod     = "SUPER"
local term    = "kitty"
local files   = "dolphin"
local browser = "brave"
local editor  = "zeditor"

local function has_nvidia()
    local f = io.open("/proc/driver/nvidia/version", "r")
    if f then f:close() return true end
    return false
end
if has_nvidia() then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
end
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_SIZE", "24")
hl.env("QS_ICON_THEME", "Papirus-Dark")

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
})

pcall(dofile, (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/apsis/monitors.lua")

hl.config({
    input = {

        kb_layout     = "us,ara",
        kb_options    = "grp:alt_shift_toggle",
        follow_mouse  = 1,
        accel_profile = "flat",
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
        },
    },
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        layout      = "dwindle",
    },
    decoration = {
        rounding = 10,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.bind(mod .. " + Q", hl.dsp.exec_cmd(term))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(files))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + T", hl.dsp.exec_cmd(editor))
hl.bind(mod .. " + P", hl.dsp.exec_cmd("hyprpicker -a"))

hl.bind(mod .. " + X", hl.dsp.window.close())
hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + M", hl.dsp.window.fullscreen())
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + Up",   hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + Down", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + CONTROL + left",  hl.dsp.group.prev())
hl.bind(mod .. " + CONTROL + right", hl.dsp.group.next())

hl.bind(mod .. " + left",        hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right",       hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + SHIFT + up",   hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + SHIFT + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,          hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mod .. " + H",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind("Print",                   hl.dsp.exec_cmd("grimblast --notify copysave area"))
hl.bind(mod .. " + Print",         hl.dsp.exec_cmd("grimblast --notify copysave screen"))
hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copysave output"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

local home = os.getenv("HOME")

do
    local log = io.open(home .. "/.cache/apsis/hypr-errors.log", "w")
    if log then log:close() end
end
local function part(name, optional)
    local path = home .. "/.config/hypr/" .. name
    local f = io.open(path, "r")
    if not f then
        if not optional then
            local log = io.open(home .. "/.cache/apsis/hypr-errors.log", "a")
            if log then log:write(os.date("%F %T"), "  missing ", path, "\n") log:close() end
        end
        return
    end
    f:close()
    local ok, err = pcall(dofile, path)
    if not ok then
        local log = io.open(home .. "/.cache/apsis/hypr-errors.log", "a")
        if log then log:write(os.date("%F %T"), "  ", name, ": ", tostring(err), "\n") log:close() end
    end
end
part("apsis-session.lua")
part("apsis-keys.lua")
part("custom.lua", true)
