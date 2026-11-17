# Contributing

Bug reports and ideas go through the issue forms. This page is for sending changes.

## How the repo is set up

Apsis is a bare git repo in `~/.apsis` whose files live straight in your home folder. The `apsis` command is git for that repo, so `apsis status`, `apsis diff` and `apsis log` work as usual (`apsis update`, `rollback`, `version` and `doctor` are its own).

Your whole home folder is the work tree, so add files by name (`apsis add .config/quickshell/phone/NewScreen.qml`), never `apsis add .` or `-A`. `apsis status` only lists files the repo already tracks. Some files stay out on purpose and must never be committed:

- `~/.config/apsis/weather.conf` (your weather API key and city)
- `~/.config/apsis/face.png` and `~/.config/apsis/sddm/apsis/face.png` (your picture)
- `~/.config/hypr/custom.lua` and `~/.config/hypr/monitors.lua` (your own settings and screens)

## Sending a change

1. Fork the repo on GitHub.
2. `apsis remote add fork https://github.com/YOUR-NAME/Apsis.git`
3. `apsis switch -c short-name`, make the change, try it on your own session.
4. `apsis push -u fork short-name` and open a pull request; the template has the checklist.

One change per pull request is easiest to review.

## Where things go

| Path | What lives there |
|---|---|
| `.config/quickshell/` | the shell: one folder per part (`phone/`, `desktop/`, `dock/`, `bar/`, `lock/` ...), shared pieces in `widgets/`, singletons in `services/` and `config/` |
| `.config/quickshell/lib/*.js` | pure logic with no QML in it, so it can be tested with node |
| `.config/hypr/` | the Hyprland config in Lua (0.55 and up) and the `apsis-*.sh` scripts the shell calls |
| `.config/apsis/` | install, setup, update, migrations, the login theme, tests and the README pictures |

A few rules keep it consistent:

- **Headers, no other comments.** Every file starts with two lines: what the file does, then `Edit:` and what to change for a different result. Nothing else is commented. Shebangs, `//@ pragma` lines and `# shellcheck` directives stay.
- **One block.** Surfaces are made from `widgets/Block.qml` and its buttons, sliders and switches, not new rectangles.
- **Colours from the theme.** Use the roles in `config/Theme.qml` so every palette and mode works, never a fixed colour.
- **Scripts are POSIX sh** unless they need bash, and they say which in their shebang.
- **Nothing private in demo data.** Example names, places and pictures are invented.

## Tests

```sh
node ~/.config/apsis/tests/run.js           # the shell's pure logic
sh ~/.config/apsis/tests/updates_test.sh    # pins, groups, the update list
sh ~/.config/apsis/tests/btagent_test.sh    # the pairing agent, against a fake BlueZ
sh ~/.config/apsis/tests/modes_test.sh      # Game and Focus mode, idle
sh ~/.config/apsis/tests/update_test.sh     # apsis update, rollback, merge mode, the daily check (not as root)
sh ~/.config/apsis/tests/install_test.sh    # the one command install
sh ~/.config/apsis/tests/lyrics_test.sh     # lyrics sources
```

New logic in `lib/` comes with a test in `run.js`. None of the tests touch your real system.

## Pictures and the changelog

If a change alters what the README pictures show, redraw them with `sh ~/.config/apsis/readme/render/render.sh` (it draws the real QML with demo data; it needs pyside6, xorg-server-xvfb, libfaketime and imagemagick). Add a line to `.config/apsis/CHANGELOG.md` under an Unreleased heading at the top (start one if there is none), in the group it belongs to.

By sending a change you agree it is released under the MIT license in `LICENSE`.
