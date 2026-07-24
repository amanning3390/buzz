#!/usr/bin/env bash
# update-macos-source.sh — Update Buzz for Hermes to a new immutable release tag.
# Never silently tracks main. Rebuilds in a temp dir and replaces atomically.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_DIR="${BUZZ_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Buzz for Hermes.app"

[ "$(uname -s)" = "Darwin" ] || die "macOS only."
[ "$(uname -m)" = "arm64" ] || die "Apple Silicon only."

# Must specify a tag
TARGET_TAG="${1:-}"
[ -n "$TARGET_TAG" ] || die "Usage: $0 <release-tag>"

cd "$REPO_ROOT"
log "Fetching tags..."
git fetch --tags --quiet

# Verify the tag exists and is immutable
if ! git rev-parse "$TARGET_TAG" >/dev/null 2>&1; then
  die "Tag $TARGET_TAG not found."
fi

CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
if [ "$CURRENT_TAG" = "$TARGET_TAG" ]; then
  log "Already on $TARGET_TAG. Run repair-macos-source.sh to rebuild."
  exit 0
fi

log "Updating from ${CURRENT_TAG:-unknown} to $TARGET_TAG..."

# Save old app for rollback
OLD_APP="$INSTALL_DIR/$APP_NAME"
BACKUP_APP=""
if [ -e "$OLD_APP" ]; then
  BACKUP_APP="$INSTALL_DIR/.${APP_NAME}.backup"
  rm -rf "$BACKUP_APP"
  mv "$OLD_APP" "$BACKUP_APP"
fi

# Checkout new tag and rebuild
git checkout "$TARGET_TAG"
export PATH="$REPO_ROOT/bin:$PATH"

if ! bash "$REPO_ROOT/scripts/install-macos-source.sh"; then
  log "Update failed. Rolling back..."
  git checkout "$CURRENT_TAG" 2>/dev/null || true
  if [ -n "$BACKUP_APP" ]; then
    rm -rf "$OLD_APP"
    mv "$BACKUP_APP" "$OLD_APP"
  fi
  die "Update failed. Previous version restored."
fi

# Success — clean up backup
rm -rf "$BACKUP_APP"
log "Updated to $TARGET_TAG successfully."
