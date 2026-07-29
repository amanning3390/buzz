#!/usr/bin/env bash
# update-linux-source.sh — Tag-based atomic update for Buzz for Hermes on Linux.
#
# Usage: ./scripts/update-linux-source.sh [TAG]
#   TAG defaults to the latest release tag on the remote.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ "$(uname -s)" = "Linux" ] || die "This updater is for Linux only."

cd "$REPO_ROOT"

# Determine target tag
if [ $# -ge 1 ]; then
    TARGET_TAG="$1"
else
    log "Fetching latest release tag..."
    git fetch --tags origin 2>/dev/null || die "Failed to fetch tags. Is the remote reachable?"
    TARGET_TAG="$(git tag -l 'v*' --sort=-v:refname | head -1)"
    [ -n "$TARGET_TAG" ] || die "No release tags found."
fi

log "Updating to tag: $TARGET_TAG"

# Stash any local changes
if ! git diff --quiet; then
    log "Stashing local changes..."
    git stash
fi

# Checkout the tag
git checkout "$TARGET_TAG" 2>/dev/null || die "Failed to checkout $TARGET_TAG"

# Rebuild and install
log "Rebuilding from $TARGET_TAG..."
bash "$REPO_ROOT/scripts/install-linux-source.sh"

log "Update complete: $(git describe --tags --exact-match)"
