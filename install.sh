#!/bin/bash
# Installs the caelestia-sddm login theme system-wide.
#
# Usage: sudo ./install.sh [target-user]
#   target-user defaults to whichever user invoked sudo ($SUDO_USER), or the
#   user on the active seat if that's unset. This is the account whose
#   wallpaper/colors/profile picture get synced into the theme.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this with sudo: sudo ./install.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${1:-${SUDO_USER:-}}"
if [ -z "$TARGET_USER" ]; then
    TARGET_USER="$(loginctl list-sessions --no-legend 2>/dev/null | awk 'NR==1{print $3}')"
fi
if [ -z "$TARGET_USER" ]; then
    echo "Could not determine the target user. Run as: sudo ./install.sh <username>" >&2
    exit 1
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [ -z "$TARGET_HOME" ]; then
    echo "No such user: $TARGET_USER" >&2
    exit 1
fi

echo "==> Installing for user: $TARGET_USER ($TARGET_HOME)"

if ! command -v sddm >/dev/null 2>&1; then
    echo "WARNING: sddm does not appear to be installed. Install it first (e.g. pacman -S sddm)." >&2
fi
if [ ! -d /usr/lib/qt6/qml/M3Shapes ] && [ ! -d /usr/lib/qml/M3Shapes ]; then
    echo "WARNING: the M3Shapes QML plugin was not found. Avatar/stat-tile/password-button shapes will fail to render without it." >&2
fi

THEME_DIR=/usr/share/sddm/themes/pixie
echo "==> Installing theme to $THEME_DIR"
mkdir -p "$THEME_DIR/components" "$THEME_DIR/assets/fonts"
cp "$SCRIPT_DIR/theme/Main.qml" "$THEME_DIR/Main.qml"
cp "$SCRIPT_DIR/theme/components/"*.qml "$THEME_DIR/components/"
cp "$SCRIPT_DIR/theme/assets/fonts/"*.ttf "$THEME_DIR/assets/fonts/"
cp "$SCRIPT_DIR/theme/assets/default-avatar.jpg" "$THEME_DIR/assets/default-avatar.jpg"

if [ -f "$THEME_DIR/theme.conf" ]; then
    echo "==> theme.conf already exists, leaving it as-is (your calendarIcalUrl/newsFeedUrl are preserved)"
else
    echo "==> Writing initial theme.conf"
    cp "$SCRIPT_DIR/theme/theme.conf" "$THEME_DIR/theme.conf"
fi

echo "==> Installing sync script + systemd units"
install -m 755 "$SCRIPT_DIR/scripts/sync-sddm-wallpaper.sh" /usr/local/bin/sync-sddm-wallpaper.sh

ESCAPED_HOME=$(printf '%s\n' "$TARGET_HOME" | sed 's/[&/\]/\\&/g')
sed "s|__HOME__|$ESCAPED_HOME|g" "$SCRIPT_DIR/systemd/sddm-wallpaper-sync.path" > /etc/systemd/system/sddm-wallpaper-sync.path
cp "$SCRIPT_DIR/systemd/sddm-wallpaper-sync.service" /etc/systemd/system/sddm-wallpaper-sync.service

cat > /etc/sddm-wallpaper-sync.conf << EOF
SOURCE_USER=$TARGET_USER
EOF

mkdir -p /etc/systemd/system/sddm.service.d
cp "$SCRIPT_DIR/systemd/sddm-override.conf" /etc/systemd/system/sddm.service.d/override.conf

echo "==> Selecting the pixie theme in sddm.conf.d"
mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=pixie\n' > /etc/sddm.conf.d/theme.conf

echo "==> Locking down theme.conf (may contain your calendar secret)"
if getent group sddm >/dev/null; then
    chown root:sddm "$THEME_DIR/theme.conf"
    chmod 640 "$THEME_DIR/theme.conf"
else
    chmod 644 "$THEME_DIR/theme.conf"
fi
chmod -R a+rX "$THEME_DIR"

echo "==> Reloading systemd and syncing assets now"
systemctl daemon-reload
systemctl enable --now sddm-wallpaper-sync.path
systemctl start sddm-wallpaper-sync.service || true

CURRENT_DM=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)
echo
echo "==> Done."
echo
if [ "$CURRENT_DM" != "/usr/lib/systemd/system/sddm.service" ]; then
    echo "NOTE: your active display manager is currently: ${CURRENT_DM:-none set}"
    echo "This installer does NOT switch it automatically. To make sddm your login"
    echo "manager, disable whatever is currently enabled and enable sddm, e.g.:"
    echo "    sudo systemctl disable <your-current-display-manager>"
    echo "    sudo systemctl enable sddm"
else
    echo "sddm is already your enabled display manager."
fi
echo
echo "Optional: to preview without logging out, run as $TARGET_USER (in the sddm group,"
echo "or via 'sudo -u sddm'):"
echo "    QML_XHR_ALLOW_FILE_READ=1 sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
echo
echo "To enable Calendar/News cards, edit $THEME_DIR/theme.conf (calendarIcalUrl, newsFeedUrl)."
