#!/usr/bin/env bash
# repair-macos-source.sh — Rebuild the current release tag in place.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
[ -n "$CURRENT_TAG" ] || { echo "Not on a release tag." >&2; exit 1; }

echo "[buzz-for-hermes] Rebuilding $CURRENT_TAG..."
export PATH="$REPO_ROOT/bin:$PATH"

# Clean build artifacts
PATH="$REPO_ROOT/bin:$PATH" cargo clean --manifest-path desktop/src-tauri/Cargo.toml 2>/dev/null || true

# Rebuild
exec bash "$REPO_ROOT/scripts/install-macos-source.sh"
