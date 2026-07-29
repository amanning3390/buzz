#!/usr/bin/env bash
# repair-linux-source.sh — Rebuild current tag for Buzz for Hermes on Linux.
#
# Useful when the build breaks due to system changes (new libraries, toolchain
# updates, etc.). Rebuilds from the currently checked-out tag without fetching.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ "$(uname -s)" = "Linux" ] || die "This repair tool is for Linux only."

cd "$REPO_ROOT"

CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
[ -n "$CURRENT_TAG" ] || die "Not on a release tag. Cannot repair. Checkout a tag first."

log "Repairing from tag: $CURRENT_TAG"

# Clean build artifacts but keep source
log "Cleaning Rust build artifacts..."
cargo clean 2>/dev/null || true

log "Rebuilding..."
bash "$REPO_ROOT/scripts/install-linux-source.sh"

log "Repair complete."
