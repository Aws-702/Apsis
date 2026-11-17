# Changelog

## 1.0.0

The first public release.

Shell
- The phone: quick panel, apps, sound and EQ, Wi-Fi, Bluetooth, notifications, updates and settings, turning to landscape for settings.
- Desktop widgets: 13 widgets on a grid with Edit Desktop, a tray that scrolls sideways, and presets you can save and switch.
- The dock with pins, running apps and cards (media, timer, files, clipboard, shelf), smart search, the wallpaper wheel, the overview and the shortcut cheat sheet, which splits its groups into even columns and scrolls when the screen is short.
- Live palettes (cherry, navy, or auto from the wallpaper) in dark, darker and light, a keycap or minimal lockscreen with password or fingerprint, and a matching login screen.
- Music: a cava visualizer in 6 looks and synced lyrics. Modes: Ultra saver, Training, Game and Focus. Screen and region recording on the GPU.
- Bluetooth pairing through Apsis's own agent: the code shows on a card to compare, and the agent only answers bluetoothd.

Install and updates
- One command install that clones the repo, moves any files in the way to `~/.apsis-backup` and runs setup.
- `apsis update` shows what changes, backs up what it replaces, keeps your edits and restarts the shell; `apsis rollback` undoes it.
- Apsis checks its repo once a day (`apsis newer`) and shows a card on the phone when there is something new; it can be switched off in Settings > About.
- Hyprland and Qt are pinned as whole groups. Updates are reviewed group by group (update or keep pinned), with a snapshot first when snapper is set up.
- `apsis doctor` checks the whole setup and gives the command that fixes each problem.

Repo
- MIT license, issue forms, a pull request checklist, a security policy and a contributing guide.
- Each push runs the logic tests, shellcheck on every script and a parse of the Hyprland config. Shell test suites cover updates and pins, the pairing agent, the modes, `apsis update`, the installer and lyrics.
- The README pictures are drawn from the shell's own QML with demo data: `sh ~/.config/apsis/readme/render/render.sh`.
