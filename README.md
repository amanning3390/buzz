# Buzz for Hermes

A community fork of [Buzz](https://github.com/block/buzz) that adds native [Hermes Agent](https://github.com/NousResearch/hermes-agent) integration via the Agent Client Protocol (ACP).

**Not an official Block or Nous Research release.** This is a community project.

---

## What This Gives You

Buzz is a collaborative coding workspace with real-time channels, agent harnesses, and a desktop app. This fork adds **Hermes Agent** as a first-class runtime alongside Claude Code and Codex:

- **All your providers in one picker** — Hermes exposes every authenticated provider (OpenRouter, Anthropic, OpenAI, DeepSeek, xAI, Google, local Ollama, etc.) in the Buzz model selector
- **Per-agent model switching** — change providers and models per-agent through ACP
- **Your `~/.hermes` config, untouched** — the fork installs an isolated companion runtime; your existing Hermes installation and credentials are never modified
- **45-second cold-start budget** — accommodates Hermes's heavier Python initialization without false timeouts
- **MCP isolation** — Hermes manages its own MCP servers per-session; Buzz's global MCP startup is skipped for Hermes

---

## Quick Start (macOS Apple Silicon, $0)

### 1. Prerequisites

| Requirement | How to check | How to install |
|---|---|---|
| macOS 14+ (Sonoma) | `sw_vers` | — |
| Apple Silicon (M1/M2/M3/M4) | `uname -m` → `arm64` | — |
| Xcode Command Line Tools | `xcode-select -p` | `xcode-select --install` (free) |
| Git | `git --version` | Comes with CLT |
| 15 GB free disk | `df -h ~` | — |

No paid tools required. No Apple Developer Program. No Gatekeeper bypass.

### 2. Install

```bash
xcode-select -p >/dev/null 2>&1 \
  || { xcode-select --install; echo "Install the free tools, then re-run."; exit 1; }; \
WORKDIR="$(mktemp -d)" \
  && git clone --depth 1 --branch v0.4.24-hermes.1 \
    https://github.com/amanning3390/buzz.git "$WORKDIR/buzz-for-hermes" \
  && "$WORKDIR/buzz-for-hermes/scripts/install-macos-source.sh"
```

**What happens:**
1. Clones the immutable release tag
2. Activates the bundled Hermit toolchain (Rust, Node — no manual install)
3. Installs JavaScript dependencies via pnpm
4. Installs the pinned Hermes companion runtime (isolated, verified by SHA)
5. Builds all five Rust sidecars in release mode
6. Builds the Tauri desktop app
7. Ad-hoc signs the locally-built bundle
8. Installs to `~/Applications/Buzz for Hermes.app`
9. Verifies the Hermes runtime

**Time:** ~20-30 min on M2+, ~30-40 min on M1.

**Disk:** ~15 GB during build (can reclaim afterwards: `cargo clean`).

### 3. Configure a Provider

Before launching the app, configure at least one AI provider for Hermes:

```bash
hermes setup    # interactive wizard
# or just set a key:
echo 'OPENROUTER_API_KEY=sk-or-v1-...' >> ~/.hermes/.env
# or:
echo 'ANTHROPIC_API_KEY=sk-ant-...' >> ~/.hermes/.env
```

Hermes supports 20+ providers. See `hermes model` for the interactive picker.

### 4. Launch and Use

```bash
open ~/Applications/Buzz\ for\ Hermes.app
```

In the app:
1. Complete onboarding (you'll see **Hermes Agent** alongside Claude Code and Codex)
2. Select **Hermes Agent** as your runtime
3. The model dropdown shows all your authenticated providers and models
4. Pick one — it persists per-agent

---

## Architecture

### How the Companion Runtime Works

This fork does **not** modify your official Hermes installation. Instead, it installs a **pinned companion runtime**:

```
~/Library/Application Support/Buzz for Hermes/
└── runtimes/hermes/
    ├── b405f0a16.../          # immutable version directory (pinned by commit SHA)
    │   ├── source/            # Hermes Agent source at exact commit
    │   │   └── venv/bin/hermes
    │   ├── bootstrap-home/    # isolated install-time HERMES_HOME
    │   └── .installing         # marker removed on success
    └── current.json            # atomic pointer to active version
```

Properties:
- **Pinned to immutable commit** `b405f0a16` (tag `buzz-acp-v0.19.0.1`)
- **Reads your `~/.hermes` config** at runtime (provider, model, credentials)
- **Never writes to `~/.hermes`** — it's read-only
- **Never touches `~/.local/bin/hermes`** — your official CLI is safe
- **Rollback-capable** — `current.json` swaps atomically

### What Changed from Upstream Buzz

This fork contains two upstream-targeted PRs layered on `block/buzz` main:

| Change | Files | Upstream PR |
|---|---|---|
| **B1: Release sidecar resolution** | `discovery.rs`, `discovery/tests.rs`, `Justfile` | [#2655](https://github.com/block/buzz/pull/2655) |
| **B2: Native Hermes ACP runtime** | 15 files (Rust + TypeScript + assets) | [#2656](https://github.com/block/buzz/pull/2656) |

And two corresponding Hermes Agent PRs:

| Change | Files | Upstream PR |
|---|---|---|
| **H1: Cross-provider ACP model choices** | `acp_adapter/server.py`, `tests/acp/test_server.py` | [#70404](https://github.com/NousResearch/hermes-agent/pull/70404) |
| **H2: Skip configured MCP startup** | `acp_adapter/entry.py`, `tests/acp/test_entry.py` | [#70405](https://github.com/NousResearch/hermes-agent/pull/70405) |

### Fork-Only Additions

| Artifact | Purpose |
|---|---|
| `desktop/hermes-runtime.json` | Pinned Hermes commit/tag manifest |
| `desktop/fork-config.json` | Fork identity (bundle ID, deep-link, runtime config) |
| `desktop/src-tauri/tauri.conf.json` | Product name, version, identifier, deep-link scheme |
| `scripts/install-hermes-runtime.sh` | Isolated companion installer |
| `scripts/install-macos-source.sh` | One-command zero-cost macOS build |
| `scripts/test-hermes-runtime.sh` | Runtime verification |
| `scripts/update-macos-source.sh` | Atomic tag-based update with rollback |
| `scripts/repair-macos-source.sh` | Rebuild current tag in place |
| `scripts/uninstall-macos.sh` | App removal (preserves `~/.hermes`) |
| `.github/workflows/ci-hermes.yml` | Zero-cost fork CI |
| `.github/workflows/release-hermes-source.yml` | Source release workflow |

---

## Provider Configuration

Hermes supports 20+ providers. Set API keys in `~/.hermes/.env`:

| Provider | Env var | Free tier? |
|---|---|---|
| OpenRouter | `OPENROUTER_API_KEY` | Some free models |
| Anthropic | `ANTHROPIC_API_KEY` | No |
| OpenAI | `OPENAI_API_KEY` | No |
| Google Gemini | `GOOGLE_API_KEY` | Yes (limited) |
| DeepSeek | `DEEPSEEK_API_KEY` | Cheap |
| xAI / Grok | `XAI_API_KEY` | No |
| Z.AI / GLM | `GLM_API_KEY` | Yes (limited) |
| Hugging Face | `HF_TOKEN` | Yes (limited) |
| Kimi / Moonshot | `KIMI_API_KEY` | No |
| Alibaba | `DASHSCOPE_API_KEY` | Yes (limited) |
| Local (Ollama) | Set `model.base_url` in config.yaml | Yes |

After setting keys, all authenticated providers appear in the Buzz model picker.

**Multiple providers?** Hermes supports credential pools — configure multiple keys and it rotates automatically.

---

## Update, Repair, Uninstall

### Update to a New Release

```bash
cd /path/to/buzz-for-hermes
git fetch --tags
git checkout v0.4.24-hermes.2    # the new tag
scripts/install-macos-source.sh   # rebuilds
```

Or use the update script:
```bash
scripts/update-macos-source.sh v0.4.24-hermes.2
```

Updates rebuild in-place and atomically swap. The previous version is preserved for rollback.

### Rebuild Current Version

```bash
scripts/repair-macos-source.sh
```

Clean rebuild of the current tag. Fixes build corruption, stale caches.

### Uninstall

```bash
# Remove app + companion runtime (preserves ~/.hermes)
scripts/uninstall-macos.sh

# Remove everything including fork app data
scripts/uninstall-macos.sh --purge-buzz-data
```

Your `~/.hermes` config, sessions, and credentials are **never touched** by uninstall.

---

## Troubleshooting

### "Hermes Agent not detected" in the picker

The companion runtime may not be installed or may be stale:
```bash
scripts/test-hermes-runtime.sh    # verify
scripts/install-hermes-runtime.sh # reinstall
```

### Empty model list

No provider configured:
```bash
# Check your config
cat ~/.hermes/config.yaml | head -5
# Set a key
echo 'OPENROUTER_API_KEY=sk-or-v1-...' >> ~/.hermes/.env
# Verify Hermes sees providers
hermes model
```

### Build fails

```bash
# Check you have Xcode CLT
xcode-select -p

# Check disk space (need >15 GB)
df -h ~

# Clean rebuild
scripts/repair-macos-source.sh

# Check the build log
tail -50 ~/buzz-for-hermes-install.log
```

### App won't launch

```bash
# Check Gatekeeper
spctl --assess --type execute ~/Applications/Buzz\ for\ Hermes.app

# Remove quarantine if present (locally built shouldn't have this)
xattr -l ~/Applications/Buzz\ for\ Hermes.app
# If com.apple.quarantine appears:
xattr -cr ~/Applications/Buzz\ for\ Hermes.app
```

### Companion runtime conflicts

The companion is isolated from your official Hermes:
```bash
# Official Hermes (your terminal uses this)
which hermes
# → ~/.local/bin/hermes

# Companion (Buzz uses this)
cat ~/Library/Application\ Support/Buzz\ for\ Hermes/runtimes/hermes/current.json
```

Both coexist safely.

---

## Documentation

- [Hermes Setup Guide](docs/hermes-setup.md) — provider configuration details
- [Troubleshooting](docs/hermes-troubleshooting.md) — comprehensive problem solving
- [Zero-Cost Build Guide](docs/building-macos-zero-cost.md) — build requirements and process
- [Release Process](RELEASING-HERMES.md) — maintainer checklist

## License

Buzz is [Apache-2.0](LICENSE). Hermes Agent is [MIT](THIRD_PARTY_NOTICES/HERMES_AGENT_LICENSE). See [NOTICE](NOTICE) for material modifications and [COMMUNITY_FORK.md](COMMUNITY_FORK.md) for fork status.

This is not an official Block or Nous Research release.
