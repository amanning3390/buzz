#!/usr/bin/env bash
# uninstall-macos.sh — Remove Buzz for Hermes app and companion runtime.
# Preserves ~/.hermes config/auth/sessions by default.
# Use --purge-buzz-data to also remove fork-owned app data.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }

INSTALL_DIR="${BUZZ_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Buzz for Hermes.app"
APP_PATH="$INSTALL_DIR/$APP_NAME"
APP_SUPPORT="${BUZZ_HERMES_APP_SUPPORT:-$HOME/Library/Application Support/Buzz for Hermes}"

PURGE=false
[ "${1:-}" = "--purge-buzz-data" ] && PURGE=true

if $PURGE; then
  read -rp "This will remove all Buzz for Hermes app data. Continue? (y/N) " confirm
  [ "$confirm" = "y" ] || { log "Aborted."; exit 0; }
fi

# Remove app bundle
if [ -e "$APP_PATH" ]; then
  log "Removing $APP_PATH..."
  rm -rf "$APP_PATH"
else
  log "App not found at $APP_PATH."
fi

# Remove companion runtime
if [ -d "$APP_SUPPORT/runtimes" ]; then
  log "Removing companion Hermes runtime..."
  rm -rf "$APP_SUPPORT/runtimes"
fi

# Optionally purge app data
if $PURGE; then
  if [ -d "$APP_SUPPORT" ]; then
    log "Removing fork app data ($APP_SUPPORT)..."
    rm -rf "$APP_SUPPORT"
  fi
  log "Buzz for Hermes data removed."
else
  log "App data preserved in $APP_SUPPORT."
  log "Run with --purge-buzz-data to also remove fork app data."
fi

log "Your ~/.hermes config, sessions, and credentials are untouched."
