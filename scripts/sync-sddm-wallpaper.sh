#!/bin/bash
# Copies the desktop user's caelestia wallpaper, matugen color scheme, and
# profile picture into the world-readable SDDM theme, so the login screen
# stays in sync without needing to grant the sddm user access to /home.
#
# Which user's files to sync is read from /etc/sddm-wallpaper-sync.conf
# (written by install.sh), falling back to whoever is logged into the
# active seat if that file is missing.
set -e

CONF=/etc/sddm-wallpaper-sync.conf
[ -f "$CONF" ] && source "$CONF"

SOURCE_USER="${SOURCE_USER:-$(logname 2>/dev/null || loginctl list-sessions --no-legend 2>/dev/null | awk 'NR==1{print $3}')}"
SOURCE_HOME="$(getent passwd "$SOURCE_USER" 2>/dev/null | cut -d: -f6)"

if [ -z "$SOURCE_USER" ] || [ -z "$SOURCE_HOME" ]; then
    echo "sync-sddm-wallpaper: could not resolve a source user, skipping" >&2
    exit 0
fi

THEME=/usr/share/sddm/themes/pixie

sync_file() {
    local src="$1" dst="$2"
    [ -e "$src" ] || return 0
    local tmp
    tmp="$(mktemp)"
    cp -L "$src" "$tmp"
    mv "$tmp" "$dst"
    chmod 644 "$dst"
}

sync_file "$SOURCE_HOME/.local/state/caelestia/wallpaper/current" "$THEME/assets/background.jpg"
sync_file "$SOURCE_HOME/.local/state/quickshell/user/generated/colors.json" "$THEME/assets/colors.json"
sync_file "$SOURCE_HOME/.face" "$THEME/assets/avatar.jpg"
