-- Apsis -- what starts at login: the shell, wallpaper daemon, clipboard history, idle.
-- Edit: add autostart lines here, or in custom.lua to keep them out of updates.

hl.on("hyprland.start", function()

    hl.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-session.sh"]])

    hl.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-shell.sh start"]])
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd([[sh -c "$HOME/.config/hypr/scripts/apsis-wall-restore.sh"]])

    hl.exec_cmd([[sh -c "wl-paste --type text --watch cliphist store"]])
    hl.exec_cmd([[sh -c "wl-paste --type image --watch cliphist store"]])
end)
