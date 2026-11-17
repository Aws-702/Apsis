-- Apsis -- the keys that call Apsis: phone, lock, power, palette, recording, hardware and mode keys.
-- Edit: change a key here or in Settings > Shortcuts; your own binds belong in custom.lua.

local mod = "SUPER"

hl.bind(mod .. " + R",     hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/apsis-launcher.sh"))
hl.bind(mod .. " + space", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/apsis-centre.sh"))

hl.bind(mod .. " + Escape",   hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-lock.sh"]]))
hl.bind("ALT + F4", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-powermenu.sh"]]))
hl.bind(mod .. " + ALT + F4", hl.dsp.exec_cmd([[hyprctl dispatch 'hl.dsp.exit()']]))

hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-palette.sh"]]))

hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-record.sh toggle region"]]))
hl.bind(mod .. " + ALT + R",   hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-record.sh toggle screen"]]))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-volume.sh up"]]), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-volume.sh down"]]), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-volume.sh mute"]]), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-mic.sh"]]), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-brightness.sh up"]]), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-brightness.sh down"]]), { locked = true, repeating = true })

hl.bind(mod .. " + I",         hl.dsp.exec_cmd("qs ipc call phone open settings"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("qs ipc call edit toggle"))
hl.bind(mod .. " + D",         hl.dsp.exec_cmd("qs ipc call dock toggle"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-mode.sh"]]))
hl.bind(mod .. " + Tab",       hl.dsp.exec_cmd("qs ipc call overview toggle"))
hl.bind(mod .. " + slash",     hl.dsp.exec_cmd("qs ipc call cheatsheet toggle"))
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
hl.bind(mod .. " + V",         hl.dsp.exec_cmd([[qs ipc call phone search ">"]]))
hl.bind(mod .. " + period",    hl.dsp.exec_cmd([[qs ipc call phone search ":"]]))
hl.bind(mod .. " + N",         hl.dsp.exec_cmd("qs ipc call phone toggle notifications"))

hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-ultra.sh toggle"]]))

hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-train.sh toggle"]]))

hl.bind(mod .. " + ALT + G",   hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-game.sh toggle"]]))
hl.bind(mod .. " + SHIFT + F", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-focus.sh toggle"]]))
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-wall-random.sh"]]))
