#!/usr/bin/env bash
# install-macos-source.sh — One-command zero-cost macOS source installer for Buzz for Hermes.
#
# Builds the app from an immutable tagged checkout on the user's Mac.
# No paid signing, no Gatekeeper bypass, no downloaded binaries.
# Ad-hoc signs the locally-built bundle and installs to ~/Applications.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="${BUZZ_INSTALL_LOG:-$HOME/buzz-for-hermes-install.log}"
INSTALL_DIR="${BUZZ_INSTALL_DIR:-$HOME/Applications}"
TARGET_TRIPLE="aarch64-apple-darwin"

# --- Platform check ---
[ "$(uname -s)" = "Darwin" ] || die "This installer is for macOS only."
[ "$(uname -m)" = "arm64" ] || die "This installer requires Apple Silicon (arm64)."

# --- Verify clean checkout at release tag ---
cd "$REPO_ROOT"
git diff --quiet HEAD || die "Checkout is dirty. Please use a clean release tag."

CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
[ -n "$CURRENT_TAG" ] || die "Not on a release tag. Please checkout a release tag."

log "Building Buzz for Hermes from tag: $CURRENT_TAG"
log "Log file: $LOG_FILE"

# --- Check prerequisites ---
command -v git >/dev/null 2>&1 || die "git is required."
xcode-select -p >/dev/null 2>&1 || {
  log "Xcode Command Line Tools not found. Installing..."
  xcode-select --install 2>/dev/null || true
  die "Please re-run this script after Xcode CLT installation completes."
}

# --- Check disk space (need ~15GB for Rust + Tauri build) ---
FREE_SPACE_MB="$(df -m "$HOME" | awk 'NR==2 {print $4}')"
[ "$FREE_SPACE_MB" -gt 15360 ] || \
  die "Insufficient disk space. Need >15GB, have ${FREE_SPACE_MB}MB."

# --- Activate hermit toolchain ---
export PATH="$REPO_ROOT/bin:$PATH"
log "Using hermit toolchain..."

# --- Install JS dependencies ---
log "Installing JavaScript dependencies..."
PATH="$REPO_ROOT/bin:$PATH" just desktop-install-ci 2>&1 | tee -a "$LOG_FILE"

# --- Install/verify Hermes companion runtime ---
log "Installing Hermes companion runtime..."
bash "$REPO_ROOT/scripts/install-hermes-runtime.sh" 2>&1 | tee -a "$LOG_FILE"

# --- Build release sidecars + Tauri app ---
log "Building release sidecars and Tauri app (this takes ~15-30 min)..."
CI=1 PATH="$REPO_ROOT/bin:$PATH" \
  just desktop-release-build "$TARGET_TRIPLE" 2>&1 | tee -a "$LOG_FILE"

# --- Find the built app (target-suffixed release directory) ---
RELEASE_DIR="$REPO_ROOT/desktop/src-tauri/target/$TARGET_TRIPLE/release"
APP_BUNDLE="$(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)"
if [ -z "$APP_BUNDLE" ]; then
  # Fallback: unsuffixed release directory
  RELEASE_DIR="$REPO_ROOT/desktop/src-tauri/target/release"
  APP_BUNDLE="$(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' -print -quit 2>/dev/null || true)"
fi
[ -n "$APP_BUNDLE" ] || die "No .app bundle found after build. Check $LOG_FILE"

# --- Ad-hoc sign (no paid Apple Developer account needed) ---
log "Ad-hoc signing..."
# Walk the bundle from inside out to sign nested helpers first
find "$APP_BUNDLE" -type f \( -name '*.dylib' -o -perm +111 \) -exec \
  codesign --force --sign - {} + 2>&1 | tee -a "$LOG_FILE" || true
codesign --force --sign - "$APP_BUNDLE" 2>&1 | tee -a "$LOG_FILE"
codesign --verify --strict "$APP_BUNDLE" 2>&1 | tee -a "$LOG_FILE" || \
  log "WARNING: Code signature verification failed (non-fatal for local builds)"

# --- Install to ~/Applications ---
mkdir -p "$INSTALL_DIR"
APP_NAME="$(basename "$APP_BUNDLE")"
TARGET="$INSTALL_DIR/$APP_NAME"

if [ -e "$TARGET" ]; then
  log "Removing existing installation..."
  rm -rf "$TARGET"
fi

cp -R "$APP_BUNDLE" "$TARGET"
log "Installed to: $TARGET"

# --- Run Hermes runtime verification ---
log "Running Hermes runtime verification..."
bash "$REPO_ROOT/scripts/test-hermes-runtime.sh" 2>&1 | tee -a "$LOG_FILE"

log ""
log "========================================"
log "  Buzz for Hermes installed successfully!"
log "  Location: $TARGET"
log "  Launch with: open \"$TARGET\""
log "========================================"
log ""
log "  Next steps:"
log "  1. Configure a provider: hermes model"
log "  2. Launch the app: open \"$TARGET\""
log "  3. Select Hermes as your agent runtime"
log "  4. Choose a provider/model from the picker"
log "========================================"
