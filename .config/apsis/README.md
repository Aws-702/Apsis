# Apsis

A custom Hyprland rice on CachyOS. Modular quickshell UI, drawn-in-QML icons,
a wallpaper-derived "auto" palette, and a themed SDDM login that follows the
live colors. Built so any one layer can fail without taking the rest down.

**Version 1.0.0** · Hyprland (Lua) · quickshell (Qt6) · uwsm · SDDM

---

## Keyboard shortcuts

Edit any of these in the **Control Center → keyboard icon** (rebind the key,
with backup/restore). `SUPER` is the Windows key.

### Launch
| Shortcut | Action |
|----------|--------|
| `SUPER + Q` | Terminal |
| `SUPER + E` | File manager |
| `SUPER + B` | Browser |
| `SUPER + T` | Editor |
| `SUPER + P` | Color picker |
| `SUPER + R` | App launcher |
| `SUPER + Space` | Control center |

### Windows
| Shortcut | Action |
|----------|--------|
| `SUPER + X` | Close window |
| `SUPER + F` | Toggle floating |
| `SUPER + M` | Fullscreen |
| `SUPER + G` | Toggle group |
| `SUPER + Up` / `Down` | Toggle split |
| `SUPER + CTRL + Left` / `Right` | Previous / next in group |
| `SUPER + Left` / `Right` | Focus left / right |
| `SUPER + SHIFT + Up` / `Down` | Focus up / down |
| `SUPER + drag` / `SUPER + right-drag` | Move / resize window |

### Workspaces
| Shortcut | Action |
|----------|--------|
| `SUPER + 1..0` | Switch to workspace 1-10 |
| `SUPER + SHIFT + 1..0` | Move window to workspace |
| `SUPER + scroll` | Cycle workspaces |
| `SUPER + H` | Toggle scratchpad |
| `SUPER + SHIFT + S` | Move window to scratchpad |

### System
| Shortcut | Action |
|----------|--------|
| `SUPER + Escape` | Lock screen |
| `ALT + F4` | Power menu |
| `SUPER + ALT + F4` | Exit Hyprland |
| `SUPER + SHIFT + T` | Toggle palette (cherry / navy) |
| `Print` | Screenshot area |
| `SUPER + Print` | Screenshot screen |
| `SUPER + SHIFT + Print` | Screenshot monitor |
| Media / brightness keys | Volume, brightness, play/pause, next, prev |

---

## Media folders

- `~/Apsis/wallpapers` drop wallpapers here, pick in Control Center → Theme
- `~/Apsis/pfps` drop profile pictures here, pick in Control Center → Theme

## Layout

| Path | Contents |
|------|----------|
| `.config/quickshell/` | The shell: `bar/`, `panel/` (control center + power menu), `launcher/`, `osd/`, `net/`, `notifications/`, `widgets/`, `config/`, `services/`, `shell.qml` |
| `.config/hypr/` | `hyprland.lua` and `scripts/` (all the `apsis-*.sh` helpers) |
| `.config/apsis/` | `sddm/` (login theme + root helper), `setup.sh`, this README |
| `.config/matugen/` | Templates for the auto palette |

## Palettes

`cherry` (dark pink), `navy` (brand), `auto` (matugen from the wallpaper).
Switch in Control Center → Theme, or `SUPER + SHIFT + T` to toggle cherry/navy.
Auto drives the bar, panels, lock screen, and the SDDM greeter together.

## Rebuild

`~/.config/apsis/setup.sh` installs packages, deploys the SDDM theme and root
helper, and sets initial state. Runtime state lives in `~/.cache/quickshell/`.
