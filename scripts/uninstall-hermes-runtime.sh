#!/usr/bin/env bash
# uninstall-hermes-runtime.sh — Remove the isolated Hermes companion runtime.
# Does NOT remove ~/.hermes, ~/.local/bin/hermes, or any user config/credentials.
set -euo pipefail

APP_SUPPORT_DIR="${BUZZ_HERMES_APP_SUPPORT:-$HOME/Library/Application Support/Buzz for Hermes}"
RUNTIMES_DIR="$APP_SUPPORT_DIR/runtimes/hermes"
CURRENT_JSON="$RUNTIMES_DIR/current.json"

log() { printf '[hermes-runtime] %s\n' "$*" >&2; }

if [ ! -d "$RUNTIMES_DIR" ]; then
  log "No runtime directory found. Nothing to uninstall."
  exit 0
fi

if [ -f "$CURRENT_JSON" ]; then
  COMMIT="$(python3 -c "import json; print(json.load(open('$CURRENT_JSON')).get('commit','unknown'))" 2>/dev/null || echo "unknown")"
  log "Removing runtime $COMMIT..."
  rm -f "$CURRENT_JSON"
fi

rm -rf "$RUNTIMES_DIR"
log "Companion runtime removed."
log "Your ~/.hermes config and official hermes binary are untouched."
