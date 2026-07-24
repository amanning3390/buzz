# Buzz for Hermes

A community fork of [Buzz](https://github.com/block/buzz) that adds native [Hermes Agent](https://github.com/NousResearch/hermes-agent) ACP integration. This is **not** an official Block or Nous Research release.

## Quick Start (macOS Apple Silicon, zero cost)

```bash
xcode-select -p >/dev/null 2>&1 \
  || { xcode-select --install; echo "Install the free tools, then paste this command again."; exit 1; }; \
WORKDIR="$(mktemp -d)" \
  && git clone --depth 1 --branch <release-tag> \
    https://github.com/amanning3390/buzz.git "$WORKDIR/buzz-for-hermes" \
  && "$WORKDIR/buzz-for-hermes/scripts/install-macos-source.sh"
```

This builds the app **from source** on your Mac. No downloaded unsigned binaries, no Gatekeeper bypass, no paid Apple Developer membership required.

**Expected:** ~20-30 min build time, ~15 GB temporary disk, ~2 GB download (Rust/JS deps).

## What This Fork Does

- Registers **native Hermes ACP** as a managed agent runtime in Buzz
- Shows **all authenticated providers and their models** in the agent picker (not just one)
- Lets you **switch providers and models per-agent** through ACP `session/set_model`
- Skips Buzz's configured-MCP startup for Hermes sessions (Hermes manages its own MCP)
- Uses your normal `~/.hermes` configuration and credentials — nothing is copied or overwritten

## What This Fork Does NOT Do

- Does not modify your official Hermes installation (`~/.local/bin/hermes`, `~/.hermes/hermes-agent`)
- Does not import or copy official Buzz credentials or app data
- Does not auto-update (updates are explicit: `scripts/update-macos-source.sh <tag>`)
- Does not ship pre-built binaries (source build only for zero-cost trust)

## Relationship to Upstream

| PR | Upstream Target | Status | Branch |
|---|---|---|---|
| H1: Cross-provider ACP model choices | NousResearch/hermes-agent | Pending | `feat/acp-cross-provider-models` |
| H2: Skip configured MCP startup | NousResearch/hermes-agent | Pending | `fix/acp-skip-configured-mcp` |
| B1: Prefer packaged sidecars in release | block/buzz | Pending | `fix/release-sidecar-resolution` |
| B2: Native Hermes ACP runtime | block/buzz | Pending | `feat/native-hermes-acp-runtime` |

The fork pins a temporary combined Hermes tag (`buzz-acp-v0.19.0.1`) until upstream PRs merge.

## First Provider Setup

After installation, launch the app and:

1. Open **Settings → Agents**
2. Select **Hermes** as your runtime
3. Configure your provider in `~/.hermes/config.yaml` (or via `hermes setup`)
4. Choose a provider/model from the picker — all authenticated providers appear

## Update, Repair, Uninstall

```bash
# Update to a new release tag
scripts/update-macos-source.sh v0.4.24-hermes.2

# Rebuild the current tag (fixes build issues)
scripts/repair-macos-source.sh

# Remove the app (preserves ~/.hermes)
scripts/uninstall-macos.sh

# Remove app + all fork data
scripts/uninstall-macos.sh --purge-buzz-data
```

## Documentation

- [Hermes Setup](docs/hermes-setup.md)
- [Troubleshooting](docs/hermes-troubleshooting.md)
- [Zero-Cost macOS Build](docs/building-macos-zero-cost.md)
- [Release Process](RELEASING-HERMES.md)

## License

Buzz is Apache-2.0. Hermes Agent is MIT. See [NOTICE](NOTICE) and [COMMUNITY_FORK.md](COMMUNITY_FORK.md).
