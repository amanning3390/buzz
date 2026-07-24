# Zero-Cost macOS Build Guide

This fork builds entirely from source on your Mac. No paid tools, signing certificates, or developer memberships are needed.

## Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| macOS | 14.0 (Sonoma) | 15.0+ |
| Architecture | Apple Silicon (M1+) | M2+ |
| RAM | 8 GB | 16 GB+ |
| Free disk | 15 GB | 20 GB |
| Xcode CLT | Latest | Latest |
| Build time | ~30 min (M1) | ~15 min (M4) |

## What You Need Installed

Nothing — the installer checks for and guides you through:

1. **Xcode Command Line Tools** (free from Apple):
   ```bash
   xcode-select --install
   ```

2. **Git** (comes with CLT)

The fork uses Hermit for Rust/Node toolchain management — no manual installs needed.

## One-Command Install

```bash
WORKDIR="$(mktemp -d)" \
  && git clone --depth 1 --branch <release-tag> \
    https://github.com/amanning3390/buzz.git "$WORKDIR/buzz-for-hermes" \
  && "$WORKDIR/buzz-for-hermes/scripts/install-macos-source.sh"
```

## What the Installer Does

1. ✅ Verifies macOS + Apple Silicon
2. ✅ Checks for Xcode CLT
3. ✅ Checks free disk space (>10 GB)
4. ✅ Activates Hermit toolchain (Rust, Node)
5. ✅ Installs JavaScript dependencies (pnpm)
6. ✅ Installs/verifies pinned Hermes companion runtime
7. ✅ Builds all five Rust sidecars (buzz-acp, buzz-agent, buzz-dev-mcp, git-credential-nostr, buzz)
8. ✅ Builds the Tauri desktop app
9. ✅ Ad-hoc signs the bundle (no paid certificate)
10. ✅ Installs to `~/Applications/Buzz for Hermes.app`
11. ✅ Runs verification tests

## What the Installer Does NOT Do

- ❌ Does not download pre-built binaries
- ❌ Does not require sudo
- ❌ Does not modify your shell profile
- ❌ Does not touch your official Hermes installation
- ❌ Does not contact paid signing/notarization services
- ❌ Does not set up auto-update

## Ad-Hoc Signing Explained

macOS requires apps to be signed to run. This fork uses **ad-hoc signing** (`codesign --sign -`), which:

- Is free (no Apple Developer Program)
- Signs locally on your machine
- Only works on your machine (not redistributable)
- Does not trigger Gatekeeper warnings for locally-built apps

The built app will not have a quarantine attribute since it was built locally.
