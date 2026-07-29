#!/usr/bin/env bash
# install-linux-source.sh — One-command zero-cost Linux source installer for Buzz for Hermes.
#
# Builds the app from an immutable tagged checkout on the user's Linux machine.
# No paid signing, no package manager required. Produces an AppImage and installs
# to ~/.local/bin with a .desktop launcher.
set -euo pipefail

log() { printf '[buzz-for-hermes] %s\n' "$*" >&2; }
die() { printf '[buzz-for-hermes] ERROR: %s\n' "$*" >&2; exit 1; }
warn() { printf '[buzz-for-hermes] WARNING: %s\n' "$*" >&2; }

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="${BUZZ_INSTALL_LOG:-$HOME/buzz-for-hermes-install.log}"
INSTALL_BIN_DIR="${BUZZ_INSTALL_BIN_DIR:-$HOME/.local/bin}"
INSTALL_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
INSTALL_ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
TARGET_TRIPLE="${BUZZ_TARGET_TRIPLE:-x86_64-unknown-linux-gnu}"

# --- Platform check ---
[ "$(uname -s)" = "Linux" ] || die "This installer is for Linux only."

# --- Verify clean checkout at release tag ---
cd "$REPO_ROOT"
git diff --quiet HEAD || die "Checkout is dirty. Please use a clean release tag."

CURRENT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
[ -n "$CURRENT_TAG" ] || die "Not on a release tag. Please checkout a release tag."

log "Building Buzz for Hermes from tag: $CURRENT_TAG"
log "Target: $TARGET_TRIPLE"
log "Log file: $LOG_FILE"
: > "$LOG_FILE"

# --- Check prerequisites ---
check_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is required. Install it and re-run."
}

check_cmd git
check_cmd cargo
check_cmd node
check_cmd pnpm
check_cmd python3

# Check webkit2gtk (required by Tauri on Linux)
pkg-config --exists webkit2gtk-4.1 2>/dev/null || {
    log "webkit2gtk-4.1 not found."
    if command -v pacman >/dev/null 2>&1; then
        die "Install it with: sudo pacman -S webkit2gtk-4.1 libappindicator-gtk3"
    elif command -v apt >/dev/null 2>&1; then
        die "Install it with: sudo apt install libwebkit2gtk-4.1-dev libappindicator3-dev"
    elif command -v dnf >/dev/null 2>&1; then
        die "Install it with: sudo dnf install webkit2gtk4.1-devel libappindicator-gtk3-devel"
    else
        die "Install webkit2gtk-4.1 and libappindicator-gtk3 for your distribution."
    fi
}

# --- Check disk space (need ~15GB for Rust + Tauri build) ---
FREE_SPACE_GB="$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')"
[ "$FREE_SPACE_GB" -gt 15 ] || \
    die "Insufficient disk space. Need >15GB, have ${FREE_SPACE_GB}GB."

# --- Activate hermit toolchain ---
export PATH="$REPO_ROOT/bin:$PATH"
log "Using hermit toolchain..."

# --- Install JS dependencies ---
log "Installing JavaScript dependencies..."
(cd "$REPO_ROOT" && PATH="$REPO_ROOT/bin:$PATH" just desktop-install-ci) 2>&1 | tee -a "$LOG_FILE"

# --- Install/verify Hermes companion runtime ---
log "Installing Hermes companion runtime..."
bash "$REPO_ROOT/scripts/install-hermes-runtime.sh" 2>&1 | tee -a "$LOG_FILE"

# --- Build release sidecars + Tauri app ---
log "Building release sidecars and Tauri app (this takes ~15-30 min)..."
CI=true PATH="$REPO_ROOT/bin:$PATH" \
  just desktop-release-build "$TARGET_TRIPLE" 2>&1 | tee -a "$LOG_FILE"

# --- Find the built binary ---
RELEASE_DIR="$REPO_ROOT/desktop/src-tauri/target/$TARGET_TRIPLE/release"
BUNDLE_DIR="$RELEASE_DIR/bundle"
BINARY="$RELEASE_DIR/buzz-desktop"

# Prefer AppImage if available, fall back to deb, then binary
APPIMAGE=""
DEB_PKG=""
if [ -d "$BUNDLE_DIR" ]; then
    APPIMAGE="$(find "$BUNDLE_DIR" -maxdepth 2 -name '*.AppImage' -print -quit 2>/dev/null || true)"
    DEB_PKG="$(find "$BUNDLE_DIR" -maxdepth 2 -name '*.deb' -print -quit 2>/dev/null || true)"
fi

if [ -n "$APPIMAGE" ] && [ -x "$APPIMAGE" ]; then
    ARTIFACT="$APPIMAGE"
    ARTIFACT_TYPE="AppImage"
elif [ -n "$DEB_PKG" ] && command -v dpkg >/dev/null 2>&1; then
    ARTIFACT="$DEB_PKG"
    ARTIFACT_TYPE="deb"
elif [ -f "$BINARY" ] && [ -x "$BINARY" ]; then
    ARTIFACT="$BINARY"
    ARTIFACT_TYPE="binary"
else
    die "No build artifact found. Check $LOG_FILE"
fi

log "Found $ARTIFACT_TYPE: $ARTIFACT"

# --- Install ---
APP_NAME="buzz-for-hermes"
mkdir -p "$INSTALL_BIN_DIR"

if [ "$ARTIFACT_TYPE" = "AppImage" ]; then
    # Install AppImage to ~/.local/bin
    cp "$ARTIFACT" "$INSTALL_BIN_DIR/$APP_NAME"
    chmod +x "$INSTALL_BIN_DIR/$APP_NAME"
    log "Installed AppImage to: $INSTALL_BIN_DIR/$APP_NAME"
elif [ "$ARTIFACT_TYPE" = "deb" ]; then
    warn "deb package found. Install it with: sudo dpkg -i $ARTIFACT (Debian/Ubuntu)"
    warn "For a zero-cost install without dpkg, the raw binary is available at:"
    warn "  $RELEASE_DIR/buzz-desktop"
    die "To install the binary instead, run: cp $RELEASE_DIR/buzz-desktop $INSTALL_BIN_DIR/$APP_NAME"
else
    # Plain binary
    cp "$ARTIFACT" "$INSTALL_BIN_DIR/$APP_NAME"
    chmod +x "$INSTALL_BIN_DIR/$APP_NAME"
    log "Installed binary to: $INSTALL_BIN_DIR/$APP_NAME"
fi

# --- Create .desktop launcher ---
DESKTOP_FILE="$INSTALL_APPS_DIR/$APP_NAME.desktop"
mkdir -p "$INSTALL_APPS_DIR"

# Try to find an icon
ICON_SRC=""
for candidate in \
    "$REPO_ROOT/desktop/public/runtime-icons/hermes.png" \
    "$REPO_ROOT/desktop/src-tauri/icons/128x128.png" \
    "$REPO_ROOT/desktop/src-tauri/icons/128x128@2x.png"; do
    if [ -f "$candidate" ]; then
        ICON_SRC="$candidate"
        break
    fi
done

ICON_PATH=""
if [ -n "$ICON_SRC" ]; then
    mkdir -p "$INSTALL_ICON_DIR"
    cp "$ICON_SRC" "$INSTALL_ICON_DIR/$APP_NAME.png"
    ICON_PATH="$INSTALL_ICON_DIR/$APP_NAME.png"
fi

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Buzz for Hermes
Comment=Collaborative coding workspace with Hermes Agent
Exec=$INSTALL_BIN_DIR/$APP_NAME
Icon=$ICON_PATH
Terminal=false
Categories=Development;IDE;
StartupWMClass=Buzz for Hermes
EOF

log "Created desktop launcher: $DESKTOP_FILE"

# --- Runtime wrapper: ensure companion hermes is on PATH ---
# The companion runtime lives at the XDG data dir; create a wrapper
# that prepends it to PATH so Buzz can find it at spawn time.
RUNTIME_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/buzz-for-hermes"
RUNTIME_CURRENT="$RUNTIME_DATA_DIR/runtimes/hermes/current.json"

if [ -f "$RUNTIME_CURRENT" ]; then
    HERMES_RUNTIME_PATH="$(python3 -c "import json; print(json.load(open('$RUNTIME_CURRENT'))['path'])" 2>/dev/null || true)"
    if [ -n "$HERMES_RUNTIME_PATH" ]; then
        HERMES_RUNTIME_DIR="$(dirname "$HERMES_RUNTIME_PATH")"
        # Update the .desktop file to include the runtime in PATH
        sed -i "s|^Exec=.*|Exec=env PATH=\"$HERMES_RUNTIME_DIR:\$PATH\" $INSTALL_BIN_DIR/$APP_NAME|" "$DESKTOP_FILE"
        log "Wired companion runtime: $HERMES_RUNTIME_PATH"
    fi
fi

# --- Run Hermes runtime verification ---
log "Running Hermes runtime verification..."
bash "$REPO_ROOT/scripts/test-hermes-runtime.sh" 2>&1 | tee -a "$LOG_FILE"

log ""
log "========================================"
log "  Buzz for Hermes installed successfully!"
log "  Binary: $INSTALL_BIN_DIR/$APP_NAME"
log "  Launcher: $DESKTOP_FILE"
log "========================================"
log ""
log "  Next steps:"
log "  1. Configure a provider: hermes model"
log "  2. Launch from your app menu, or run: $INSTALL_BIN_DIR/$APP_NAME"
log "  3. Select Hermes as your agent runtime"
log "  4. Choose a provider/model from the picker"
log "========================================"
