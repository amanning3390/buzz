#!/usr/bin/env bash
# test-hermes-runtime.sh — Verify the installed companion Hermes runtime works.
set -euo pipefail

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
CURRENT_JSON="$RUNTIMES_DIR/current.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/desktop/hermes-runtime.json"

log() { printf '[hermes-runtime-test] %s\n' "$*" >&2; }
fail() { printf '[hermes-runtime-test] FAIL: %s\n' "$*" >&2; exit 1; }

# --- Check manifest exists ---
[ -f "$MANIFEST" ] || fail "Missing manifest: $MANIFEST"

MANIFEST_COMMIT="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['commit'])")"
MANIFEST_REPO="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['repository'])")"
MANIFEST_TAG="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['tag'])")"

# --- Validate manifest structure ---
[ "${#MANIFEST_COMMIT}" -eq 40 ] || fail "Manifest commit is not a full 40-char SHA"
case "$MANIFEST_REPO" in
  https://github.com/*.git) ;;
  *) fail "Manifest repository URL is not a valid GitHub URL: $MANIFEST_REPO" ;;
esac
[ -n "$MANIFEST_TAG" ] || fail "Manifest tag is empty"

log "Manifest: repo=$MANIFEST_REPO tag=$MANIFEST_TAG commit=${MANIFEST_COMMIT:0:12}"

# --- Check current.json exists ---
if [ ! -f "$CURRENT_JSON" ]; then
  fail "No current.json at $CURRENT_JSON

Runtime not installed. Run:
  $REPO_ROOT/scripts/install-hermes-runtime.sh"
fi

INSTALLED_COMMIT="$(python3 -c "import json; print(json.load(open('$CURRENT_JSON')).get('commit',''))")"
INSTALLED_PATH="$(python3 -c "import json; print(json.load(open('$CURRENT_JSON')).get('path',''))")"

# --- Verify commit matches manifest ---
[ "$INSTALLED_COMMIT" = "$MANIFEST_COMMIT" ] || \
  fail "Commit mismatch:
  manifest = $MANIFEST_COMMIT
  installed = $INSTALLED_COMMIT

Reinstall with:
  $REPO_ROOT/scripts/install-hermes-runtime.sh"

# --- Verify binary exists and is executable ---
[ -n "$INSTALLED_PATH" ] || fail "current.json has no 'path' field"
[ -f "$INSTALLED_PATH" ] || fail "Binary not found: $INSTALLED_PATH"
[ -x "$INSTALLED_PATH" ] || fail "Binary not executable: $INSTALLED_PATH"

# --- Verify hermes runs (use isolated bootstrap home if ~/.hermes doesn't exist) ---
HERMES_HOME_FOR_TEST="$HOME/.hermes"
if [ ! -d "$HERMES_HOME_FOR_TEST" ]; then
  # Use the companion's bootstrap home for the version check
  VERSION_DIR="$RUNTIMES_DIR/$MANIFEST_COMMIT"
  if [ -d "$VERSION_DIR/bootstrap-home" ]; then
    HERMES_HOME_FOR_TEST="$VERSION_DIR/bootstrap-home"
  fi
fi

log "Testing hermes --version (HERMES_HOME=$HERMES_HOME_FOR_TEST)..."
HERMES_HOME="$HERMES_HOME_FOR_TEST" "$INSTALLED_PATH" --version >/dev/null 2>&1 || {
  # --version may fail without full config; try a simpler check
  log "hermes --version failed, trying --help..."
  HERMES_HOME="$HERMES_HOME_FOR_TEST" "$INSTALLED_PATH" --help >/dev/null 2>&1 || \
    fail "Companion binary does not run: $INSTALLED_PATH

This may indicate:
  - Corrupt installation (reinstall: scripts/install-hermes-runtime.sh)
  - Python dependency issues in the companion venv
  - Architecture mismatch (this is an arm64 build)"
}

log "PASS: Companion runtime verified"
log "  Binary: $INSTALLED_PATH"
log "  Commit: ${INSTALLED_COMMIT:0:12}..."
log ""
log "Your official Hermes installation is separate:"
log "  $(command -v hermes 2>/dev/null || echo 'hermes not in PATH')"
