# Security

## Versions

Only the newest Apsis (the `main` branch) gets fixes. `apsis update` moves you to it.

## Reporting a problem

Please don't open a public issue. Use **Security > Report a vulnerability** on this repository instead, which opens a private advisory only the maintainer can see. Include:

- the part of Apsis and the file, if you know it
- what an attacker could do, and what they need first (local user, same Wi-Fi, a crafted file, a nearby Bluetooth device)
- steps or a proof of concept
- your `apsis doctor` output and Apsis version (`cat ~/.config/apsis/VERSION`)

Replies and the fix are worked out in that advisory. The fix ships with a line in the changelog, which credits you unless you would rather not be named.

## What counts

The parts of Apsis that run with more rights or handle secrets matter most:

- the installer (`install.sh`, which can be piped into `sh`) and `setup.sh`, which use sudo
- the pins in `/etc/pacman.conf` written by `apsis-updates.sh`, and the snapshots around updates
- the polkit agent, the lockscreen and its PAM files, and the login screen
- the Bluetooth pairing agent (`apsis-bt-agent.py`, on the system D-Bus)
- `apsis update` and the daily check for a newer Apsis
- where secrets are kept, such as the weather API key in `~/.config/apsis/weather.conf`
- anything that runs text from outside: lyrics, weather, Wallhaven, clipboard history, app search

A bug in Hyprland, quickshell, Qt, BlueZ, polkit or another upstream project belongs with that project. Apsis using one of them unsafely belongs here.
