#!/usr/bin/env bash
# install-hermes-runtime.sh — Isolated Hermes companion installer for Buzz for Hermes.
#
# Installs a pinned native Hermes checkout into an inactive version directory
# under ~/Library/Application Support/Buzz for Hermes/runtimes/hermes/<commit>/.
# Does NOT touch ~/.local/bin/hermes, ~/.hermes/hermes-agent, or user credentials.
# Reads the user's normal ~/.hermes config/auth at runtime only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/desktop/hermes-runtime.json"

# --- Configuration ---
APP_SUPPORT_DIR="${BUZZ_HERMES_APP_SUPPORT:-$HOME/Library/Application Support/Buzz for Hermes}"
RUNTIMES_DIR="$APP_SUPPORT_DIR/runtimes/hermes"
MANIFEST_REPO="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['repository'])")"
MANIFEST_COMMIT="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['commit'])")"
MANIFEST_TAG="$(python3 -c "import json; print(json.load(open('$MANIFEST'))['tag'])")"

RUNTIME_VERSION_DIR="$RUNTIMES_DIR/$MANIFEST_COMMIT"
CURRENT_JSON="$RUNTIMES_DIR/current.json"
INSTALLING_MARKER="$RUNTIME_VERSION_DIR/.installing"

# --- Helpers ---
log() { printf '[hermes-runtime] %s\n' "$*" >&2; }
die() { printf '[hermes-runtime] ERROR: %s\n' "$*" >&2; exit 1; }

# --- Guards ---
[ -f "$MANIFEST" ] || die "Manifest not found at $MANIFEST"
command -v git >/dev/null 2>&1 || die "git is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"

# --- Check existing installation ---
if [ -f "$CURRENT_JSON" ]; then
  EXISTING_COMMIT="$(python3 -c "import json,sys; print(json.load(open('$CURRENT_JSON')).get('commit',''))" 2>/dev/null || echo "")"
  if [ "$EXISTING_COMMIT" = "$MANIFEST_COMMIT" ] && [ -x "$RUNTIME_VERSION_DIR/source/venv/bin/hermes" ]; then
    log "Runtime $MANIFEST_COMMIT already installed and current."
    exit 0
  fi
  log "Upgrading from $EXISTING_COMMIT to $MANIFEST_COMMIT..."
fi

# --- Save existing hermes binary checksum (must not change) ---
OFFICIAL_HERMES=""
if command -v hermes >/dev/null 2>&1; then
  OFFICIAL_HERMES="$(command -v hermes)"
fi
OFFICIAL_CHECKSUM_BEFORE=""
if [ -n "$OFFICIAL_HERMES" ] && [ -f "$OFFICIAL_HERMES" ]; then
  OFFICIAL_CHECKSUM_BEFORE="$(shasum -a 256 "$OFFICIAL_HERMES" | awk '{print $1}')"
fi

# --- Clone the exact Hermes commit ---
TMPDIR_CLONE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_CLONE"' EXIT

log "Cloning $MANIFEST_REPO at tag $MANIFEST_TAG..."
git clone --quiet --depth 1 --branch "$MANIFEST_TAG" "$MANIFEST_REPO" "$TMPDIR_CLONE/source" || \
  die "Failed to clone $MANIFEST_REPO at tag $MANIFEST_TAG"

cd "$TMPDIR_CLONE/source"
CLONED_SHA="$(git rev-parse HEAD)"
[ "$CLONED_SHA" = "$MANIFEST_COMMIT" ] || \
  die "SHA mismatch: manifest=$MANIFEST_COMMIT cloned=$CLONED_SHA"

# --- Move to final version directory before creating venv ---
mkdir -p "$RUNTIMES_DIR"
if [ -d "$RUNTIME_VERSION_DIR" ]; then
  log "Removing stale version directory..."
  rm -rf "$RUNTIME_VERSION_DIR"
fi
mv "$TMPDIR_CLONE/source" "$RUNTIME_VERSION_DIR"
touch "$INSTALLING_MARKER"

# --- Staged install (companion-only bootstrap home) ---
COMPANION_BOOTSTRAP_HOME="$RUNTIME_VERSION_DIR/bootstrap-home"
RUNTIME_SOURCE="$RUNTIME_VERSION_DIR/source"

for stage in prerequisites venv python-deps; do
  log "Install stage: $stage..."
  HERMES_INSTALL_DIR="$RUNTIME_SOURCE" \
  HERMES_HOME="$COMPANION_BOOTSTRAP_HOME" \
    bash "$RUNTIME_SOURCE/scripts/install.sh" \
      --stage "$stage" \
      --dir "$RUNTIME_SOURCE" \
      --hermes-home "$COMPANION_BOOTSTRAP_HOME" \
      --skip-browser \
      --non-interactive || \
    die "Stage $stage failed"
done

# --- Verification ---
HERMES_BIN="$RUNTIME_SOURCE/venv/bin/hermes"
[ -x "$HERMES_BIN" ] || die "hermes binary not found at $HERMES_BIN"

log "Verifying hermes --version..."
HERMES_HOME="$COMPANION_BOOTSTRAP_HOME" "$HERMES_BIN" --version >/dev/null 2>&1 || \
  die "hermes --version failed"

# --- Verify official hermes binary unchanged ---
if [ -n "$OFFICIAL_HERMES" ] && [ -f "$OFFICIAL_HERMES" ]; then
  OFFICIAL_CHECKSUM_AFTER="$(shasum -a 256 "$OFFICIAL_HERMES" | awk '{print $1}')"
  [ "$OFFICIAL_CHECKSUM_BEFORE" = "$OFFICIAL_CHECKSUM_AFTER" ] || \
    die "Official hermes binary was modified! Aborting."
fi

# --- Atomically switch current.json ---
rm -f "$INSTALLING_MARKER"
python3 -c "
import json
data = {
    'commit': '$MANIFEST_COMMIT',
    'tag': '$MANIFEST_TAG',
    'path': '$HERMES_BIN',
    'installed_at': __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat()
}
with open('$CURRENT_JSON.tmp', 'w') as f:
    json.dump(data, f, indent=2)
import os
os.replace('$CURRENT_JSON.tmp', '$CURRENT_JSON')
"

log "Successfully installed Hermes runtime $MANIFEST_COMMIT"
log "Executable: $HERMES_BIN"
log "This does NOT modify your official hermes installation or ~/.hermes config."
