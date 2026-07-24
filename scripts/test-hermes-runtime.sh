#!/usr/bin/env bash
# test-hermes-runtime.sh — Verify the installed companion Hermes runtime works.
set -euo pipefail

APP_SUPPORT_DIR="${BUZZ_HERMES_APP_SUPPORT:-$HOME/Library/Application Support/Buzz for Hermes}"
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

# --- Validate manifest structure ---
[ "${#MANIFEST_COMMIT}" -eq 40 ] || fail "Manifest commit is not a full 40-char SHA"
case "$MANIFEST_REPO" in
  https://github.com/*.git) ;;
  *) fail "Manifest repository URL is not a valid GitHub URL: $MANIFEST_REPO" ;;
esac

# --- Check current.json ---
[ -f "$CURRENT_JSON" ] || fail "No current.json — runtime not installed. Run install-hermes-runtime.sh."

INSTALLED_COMMIT="$(python3 -c "import json; print(json.load(open('$CURRENT_JSON')).get('commit',''))")"
INSTALLED_PATH="$(python3 -c "import json; print(json.load(open('$CURRENT_JSON')).get('path',''))")"

[ "$INSTALLED_COMMIT" = "$MANIFEST_COMMIT" ] || \
  fail "Commit mismatch: manifest=$MANIFEST_COMMIT installed=$INSTALLED_COMMIT"

[ -x "$INSTALLED_PATH" ] || fail "Binary not executable: $INSTALLED_PATH"

# --- Verify hermes runs ---
log "Running hermes --version..."
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}" "$INSTALLED_PATH" --version >/dev/null 2>&1 || \
  fail "hermes --version failed"

log "PASS: Runtime verified at $INSTALLED_PATH"
