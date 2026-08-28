# caelestia-sddm

An SDDM login theme that mirrors the [caelestia-shell](https://github.com/caelestia-dots/shell)
Quickshell lock screen: live Material You colors (via matugen), the same M3 shapes
(avatar, stat tiles, password button), matching fonts, and the same three-column
layout (weather/system-info/calendar on the left, clock/avatar/password in the
center, stats/news on the right).

Based on [pixie-sddm](https://github.com/xCaptaiN09/pixie-sddm) by xCaptaiN09 (MIT).

## Requirements

- SDDM with the Qt6 QML greeter
- [caelestia-shell](https://github.com/caelestia-dots/shell) running as your Quickshell
  config, with matugen generating `~/.local/state/quickshell/user/generated/colors.json`
- The `M3Shapes` Qt6 QML plugin that ships with caelestia-shell (used for the avatar,
  stat tiles, and password button shapes)
- "CaskaydiaCove NF" installed system-wide (used for monospace text)
- Wayland + `hyprctl`-style compositor (tested on Hyprland)

## Install

```sh
sudo ./install.sh
```

This copies the theme to `/usr/share/sddm/themes/pixie`, sets it as the active
SDDM theme, installs a systemd path unit that keeps the login screen's wallpaper,
Material You colors, and profile picture in sync with your desktop, and sets the
`QML_XHR_ALLOW_FILE_READ=1` environment SDDM's greeter needs to read local files
(system stats, the synced color JSON).

It will **not** switch your display manager for you — if something other than
`sddm` is currently enabled, the script tells you and prints the two commands to
flip it, so that stays a deliberate, explicit step.

Re-running `install.sh` is safe: it never overwrites an existing `theme.conf`, so
your `calendarIcalUrl`/`newsFeedUrl` settings (see below) survive upgrades.

## Configuring the Calendar and News cards

Both are optional and degrade gracefully if left unconfigured. Edit
`/usr/share/sddm/themes/pixie/theme.conf`:

- `calendarIcalUrl` — your Google Calendar's private iCal address (Calendar
  Settings → your calendar → *Integrate calendar* → "Secret address in iCal
  format"). Leave blank and the card still shows a full month grid with today
  highlighted — it just has no events list under it. **This is a bearer-token-like
  secret**; the installer locks `theme.conf` to `root:sddm 640` when an `sddm`
  system group exists, but treat that URL like a password.
- `newsFeedUrl` — a Google News RSS URL. Leave blank for general Top Stories in
  your locale, or point it at a topic search feed, e.g.:
  `https://news.google.com/rss/search?q=Technology+OR+Sports&hl=en-US&gl=US&ceid=US:en`

Neither requires OAuth or an API key — both are plain authenticated/public URLs
fetched the same way the weather widget fetches open-meteo.

## What's live vs. static

Everything with a "why would this go stale" concern is backed by a real data
source and a refresh timer, not hardcoded:

| Widget | Source | Refresh |
|---|---|---|
| Clock | system time | every 1s |
| Weather | IP geolocation → open-meteo, no API key | every 30 min |
| System info card (WM/user/uptime/battery) | `sddm` session models, `/proc/uptime`, `/sys/class/power_supply` | uptime/battery every 30s |
| CPU / memory / battery tiles | `/proc/stat`, `/proc/meminfo`, `/sys/class/power_supply` | CPU every 2s, rest every 5s |
| CPU temp badge | `/sys/class/thermal/thermal_zone0/temp` | every 5s |
| Calendar month grid | system date | rebuilt hourly (so "today" stays correct across midnight) |
| Calendar events | your iCal secret URL, if set | every 15 min |
| News headlines | Google News RSS | every 30 min |
| Wallpaper / M3 colors / avatar | your desktop's actual files, via the systemd path-watcher | on change (event-driven, not polled) |
| Avatar photo | `~/.face`, synced automatically | falls back to a bundled placeholder if you haven't set one up yet |

All of the above run as QML timers *inside the greeter process itself* — when you
log in, SDDM kills the greeter and every timer/pending request dies with it.
Nothing runs in the background once you're logged in, other than the wallpaper
sync path-watcher (a tiny, always-idle systemd unit unrelated to any of this).

Machine-specific assumptions worth knowing about: the battery/CPU-temp tiles read
`/sys/class/power_supply/BAT0` and `.../thermal_zone0` specifically. The battery
tile already hides itself gracefully on desktops with no battery; a laptop whose
battery isn't named `BAT0`, or that lacks `thermal_zone0`, will just show `0%`/no
badge for that one reading rather than crashing.

## Troubleshooting

**The whole card is invisible; only a blurred wallpaper shows.** This means
`QML_XHR_ALLOW_FILE_READ` isn't reaching the greeter, so `MColours.qml` can
never read `colors.json`, `colours.ready` never becomes `true`, and every
widget (gated on that flag) stays at `opacity: 0`. Confirm the fix is actually
installed and working:

```sh
cat /etc/sddm.conf.d/greeter-env.conf   # should show GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1
journalctl -u sddm -n 100 | grep "QML_XHR_ALLOW_FILE_READ"   # should print nothing after a fresh login
```

If that warning *does* show up repeatedly in the journal, the setting isn't
reaching the greeter. The critical, easy-to-get-wrong detail: **a systemd
`sddm.service.d/override.conf` with `Environment=` does not work for this.**
`sddm-helper` spawns the greeter inside a fresh PAM session for the `sddm`
system user, and PAM session creation does not inherit the parent unit's
`Environment=`. The setting has to go through SDDM's own
`GreeterEnvironment=` key in `sddm.conf.d` instead (what `install.sh` sets
up) — that's the only mechanism guaranteed to reach the actual greeter
process, not just the `sddm` daemon.

This is also why testing with `sddm-greeter-qt6 --test-mode` in your own
shell can pass while the real login screen fails: test-mode runs as a plain
child of whatever shell invokes it, inheriting *that* shell's environment
directly — it never goes through the `sddm-helper`/PAM spawn path the real
login screen uses, so it can't catch this class of bug. Prefer restarting the
real `sddm.service` (`sudo systemctl restart sddm`, safe — it only respawns
the greeter on the unused VT, not your active session) over test-mode when
verifying anything environment-related.

## Development / testing

Since `theme.conf` may hold your calendar secret, it's locked to `root:sddm`
mode `640`. To test-mode-preview the greeter as yourself without `sudo -u sddm`
each time, add yourself to the `sddm` group once:

```sh
sudo usermod -aG sddm "$USER"
newgrp sddm   # or log out/in
```

Then:

```sh
qmllint theme/Main.qml theme/components/*.qml   # after editing
QML_XHR_ALLOW_FILE_READ=1 sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie
```

## License

MIT, see `LICENSE`. Original work by xCaptaiN09; caelestia-shell fidelity rebuild,
calendar/news cards, and portability work in this repo are additions on top of
that base.
