#!/usr/bin/env bash
# uninstall-hermes-runtime.sh — Remove the isolated Hermes companion runtime.
#
# Removes the versioned runtime directory and current.json pointer.
# Does NOT touch ~/.local/bin/hermes, ~/.hermes/hermes-agent, or user credentials.
set -euo pipefail

log() { printf '[hermes-runtime] %s\n' "$*" >&2; }

# --- Platform detection ---
detect_platform() {
    local os
    os="$(uname -s)"
    case "$os" in
        Darwin)  echo "macos" ;;
        Linux)   echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

PLATFORM="$(detect_platform)"

if [ "$PLATFORM" = "macos" ]; then
    DEFAULT_APP_SUPPORT="$HOME/Library/Application Support/Buzz for Hermes"
elif [ "$PLATFORM" = "linux" ]; then
    DEFAULT_APP_SUPPORT="${XDG_DATA_HOME:-$HOME/.local/share}/buzz-for-hermes"
else
    echo "ERROR: Unsupported platform: $(uname -s)" >&2
    exit 1
fi

APP_SUPPORT_DIR="${BUZZ_HERMES_APP_SUPPORT:-$DEFAULT_APP_SUPPORT}"
RUNTIMES_DIR="$APP_SUPPORT_DIR/runtimes/hermes"

if [ ! -d "$RUNTIMES_DIR" ]; then
    log "No companion runtime found at $RUNTIMES_DIR"
    exit 0
fi

log "Removing companion runtime at $RUNTIMES_DIR"
rm -rf "$RUNTIMES_DIR"

log "Companion runtime removed."
log "Your official Hermes installation and ~/.hermes config were NOT touched."
