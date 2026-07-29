#!/usr/bin/env bash
# uninstall-linux.sh — Remove Buzz for Hermes from Linux.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || die "This uninstaller is for Linux only."

APP_NAME="buzz-for-hermes"
INSTALL_BIN_DIR="$HOME/.local/bin"
INSTALL_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
INSTALL_ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
RUNTIME_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/buzz-for-hermes"

REMOVED=0

# Remove binary
if [ -f "$INSTALL_BIN_DIR/$APP_NAME" ]; then
    rm -f "$INSTALL_BIN_DIR/$APP_NAME"
    log "Removed: $INSTALL_BIN_DIR/$APP_NAME"
    REMOVED=1
fi

# Remove .desktop launcher
if [ -f "$INSTALL_APPS_DIR/$APP_NAME.desktop" ]; then
    rm -f "$INSTALL_APPS_DIR/$APP_NAME.desktop"
    log "Removed: $INSTALL_APPS_DIR/$APP_NAME.desktop"
    REMOVED=1
fi

# Remove icon
if [ -f "$INSTALL_ICON_DIR/$APP_NAME.png" ]; then
    rm -f "$INSTALL_ICON_DIR/$APP_NAME.png"
    log "Removed: $INSTALL_ICON_DIR/$APP_NAME.png"
fi

# Remove companion runtime
if [ -d "$RUNTIME_DATA_DIR" ]; then
    log "Removing companion runtime data..."
    rm -rf "$RUNTIME_DATA_DIR"
    log "Removed: $RUNTIME_DATA_DIR"
    REMOVED=1
fi

if [ "$REMOVED" -eq 1 ]; then
    log "Buzz for Hermes has been uninstalled."
else
    log "Buzz for Hermes was not found. Nothing to uninstall."
fi
