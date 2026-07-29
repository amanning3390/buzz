# AGENTS.md — Buzz for Hermes

Instructions for AI coding assistants and contributors working on the
**Buzz for Hermes** community fork.

This fork adds native [Hermes Agent](https://github.com/NousResearch/hermes-agent)
ACP integration to [Buzz](https://github.com/block/buzz). It is **not** an
official Block or Nous Research release.

---

## What This Fork Is

A community fork of Buzz that:

1. Registers `hermes acp` as a first-class managed agent runtime
2. Shows all authenticated providers/models in the agent picker
3. Installs an isolated pinned Hermes companion runtime
4. Ships zero-cost source build installers for macOS and Linux

The fork tracks `block/buzz` upstream and is designed to dissolve once the
four upstream PRs (2 to Buzz, 2 to Hermes Agent) are merged.

---

## Repository Layout

```
buzz-fork-release/
├── desktop/
│   ├── hermes-runtime.json          # Pinned Hermes commit/tag manifest
│   ├── fork-config.json             # Fork identity config
│   ├── public/runtime-icons/
│   │   └── hermes.png               # Official Hermes icon
│   └── src-tauri/
│       ├── tauri.conf.json          # Product name, bundle ID, deep-link
│       └── src/managed_agents/
│           ├── config_bridge/hermes.rs   # Hermes config.yaml reader
│           ├── discovery.rs              # Runtime registration + sidecar search
│           └── readiness.rs              # Provider-not-configured detection
├── crates/buzz-acp/src/
│   ├── acp.rs                       # Spawn supervisor for Hermes process group
│   ├── config.rs                    # Agent arg defaults (hermes → ["acp"])
│   └── lib.rs                       # Cold-start timeout + MCP isolation env
├── scripts/
│   ├── install-macos-source.sh      # One-command build + install
│   ├── install-hermes-runtime.sh    # Isolated companion runtime installer
│   ├── test-hermes-runtime.sh       # Runtime verification
│   ├── update-macos-source.sh       # Tag-based atomic update
│   ├── repair-macos-source.sh       # Rebuild current tag
│   ├── uninstall-macos.sh           # App removal
│   ├── uninstall-hermes-runtime.sh  # Companion runtime removal
│   └── tests/test_manifest.py       # Manifest validation
├── .github/workflows/
│   ├── ci-hermes.yml                # Fork-specific CI
│   └── release-hermes-source.yml    # Tag-triggered source release
├── README.md                        # User-facing quick start
├── AGENTS.md                        # This file
├── NOTICE                           # Material modifications notice
├── COMMUNITY_FORK.md                # Fork status and disclaimers
└── RELEASING-HERMES.md              # Release process checklist
```

---

## Fork vs Upstream

### Fork-only files (do not exist in upstream Buzz)

- `desktop/hermes-runtime.json`
- `desktop/fork-config.json`
- `scripts/install-hermes-runtime.sh`
- `scripts/install-macos-source.sh`
- `scripts/install-linux-source.sh`
- `scripts/test-hermes-runtime.sh`
- `scripts/update-macos-source.sh`
- `scripts/update-linux-source.sh`
- `scripts/repair-macos-source.sh`
- `scripts/repair-linux-source.sh`
- `scripts/uninstall-macos.sh`
- `scripts/uninstall-linux.sh`
- `scripts/uninstall-hermes-runtime.sh`
- `scripts/tests/test_manifest.py`
- `.github/workflows/ci-hermes.yml`
- `.github/workflows/release-hermes-source.yml`
- `desktop/src-tauri/src/managed_agents/config_bridge/hermes.rs`
- `desktop/public/runtime-icons/hermes.png`
- `NOTICE`, `COMMUNITY_FORK.md`, `THIRD_PARTY_NOTICES/`
- `RELEASING-HERMES.md`
- `PROGRESS.md`

### Files modified from upstream

- `crates/buzz-acp/src/acp.rs` — `build_agent_spawn_command` for Hermes
- `crates/buzz-acp/src/config.rs` — `default_agent_args("hermes")` → `["acp"]`
- `crates/buzz-acp/src/lib.rs` — `model_probe_timeout_for_agent`, `acp_env_for_agent`
- `crates/buzz-acp/README.md` — Hermes section
- `desktop/src-tauri/src/managed_agents/discovery.rs` — Hermes in `KNOWN_ACP_RUNTIMES`, sidecar search refactor (B1)
- `desktop/src-tauri/src/managed_agents/discovery/tests.rs` — Hermes runtime contract tests
- `desktop/src-tauri/src/managed_agents/readiness.rs` — Hermes provider-not-configured requirement
- `desktop/src-tauri/src/managed_agents/config_bridge/mod.rs` — `mod hermes`
- `desktop/src-tauri/src/managed_agents/config_bridge/reader.rs` — Hermes config bridge wiring
- `desktop/src-tauri/tauri.conf.json` — Product name, bundle ID, deep-link scheme
- `desktop/src/features/onboarding/ui/RuntimeIcon.tsx` — Hermes icon
- `desktop/src/features/onboarding/ui/SetupStep.tsx` — 3-col grid, empty state text
- `desktop/src/features/onboarding/ui/onboardingRuntimeSelection.ts` — Hermes in order array
- `desktop/src/features/settings/ui/DoctorSettingsPanel.tsx` — Hermes logo, scale, sort priority
- `desktop/tests/e2e/onboarding-agent-defaults.spec.ts` — Hermes in e2e test
- `Justfile` — Release recipe uses `scripts/bundle-sidecars.sh`

---

## Hermes Runtime Manifest

The manifest (`desktop/hermes-runtime.json`) pins the exact Hermes commit:

```json
{
  "repository": "https://github.com/amanning3390/hermes-agent.git",
  "commit": "b405f0a16bd7e9ecd87fe1a9c8e9d0f3196b3ec1",
  "tag": "buzz-acp-v0.19.0.1",
  "protocol": "acp",
  "officialMinVersion": null,
  "requiredFeatures": [
    "cross-provider-model-state",
    "provider-qualified-session-set-model",
    "skip-configured-mcp-startup"
  ]
}
```

**Rules:**
- `commit` must be a full 40-character SHA (no branches, no HEAD, no abbreviations)
- `tag` must be an annotated git tag matching the commit
- `officialMinVersion` is `null` until upstream Hermes merges H1+H2; then it becomes the minimum official version that includes the required features
- The manifest is validated by `scripts/tests/test_manifest.py`

---

## Companion Runtime Isolation

The companion installer (`scripts/install-hermes-runtime.sh`) is the most
safety-critical script in this fork. It must:

1. **Never modify** `~/.local/bin/hermes`
2. **Never modify** `~/.hermes/hermes-agent/`
3. **Never modify** shell startup files
4. **Never copy credentials** — it reads `~/.hermes` at runtime only
5. **Verify SHA** before installing — fail on mismatch
6. **Use staged install** (prerequisites → venv → python-deps) with a companion-only bootstrap `HERMES_HOME`
7. **Not run** `path`, `config`, `setup`, `gateway`, or `complete` install stages
8. **Atomically swap** `current.json` only after successful verification
9. **Checksum** the official `hermes` binary before and after — fail if it changed
10. **Be idempotent** — safe to re-run

---

## Upstream PRs

This fork is temporary. Four PRs make it dissolve into upstream:

| PR | Target | Branch | Status |
|---|---|---|---|
| H1 | [NousResearch/hermes-agent#70404](https://github.com/NousResearch/hermes-agent/pull/70404) | `feat/acp-cross-provider-models` | Open |
| H2 | [NousResearch/hermes-agent#70405](https://github.com/NousResearch/hermes-agent/pull/70405) | `fix/acp-skip-configured-mcp` | Open |
| B1 | [block/buzz#2655](https://github.com/block/buzz/pull/2655) | `fix/release-sidecar-resolution` | Open |
| B2 | [block/buzz#2656](https://github.com/block/buzz/pull/2656) | `feat/native-hermes-acp-runtime` | Open |

Once all four merge:
1. Update `officialMinVersion` in `hermes-runtime.json` to the tested minimum
2. Remove the companion runtime requirement
3. The fork can track upstream directly

---

## Development

### Getting Started

```bash
. ./bin/activate-hermit     # Rust, Node toolchain
cp .env.example .env         # Configure relay
just setup                   # Install deps, run migrations
just relay                   # Start relay at ws://localhost:3000
```

### Quality Gates (Fork-Specific)

```bash
# Fork CI scope (fast, free, runs on standard runners)
PATH="$PWD/bin:$PATH" cargo fmt --all -- --check
PATH="$PWD/bin:$PATH" cargo test -p buzz-acp --lib
PATH="$PWD/bin:$PATH" cargo test --manifest-path desktop/src-tauri/Cargo.toml hermes -- --nocapture
python3 scripts/tests/test_manifest.py
```

### Full Quality Gates (upstream)

```bash
just ci    # fmt + clippy + desktop lint + unit tests + builds
```

Note: `cargo clippy --workspace` may flag pre-existing upstream issues. Fork CI
only runs `cargo test -p buzz-acp --lib` and desktop Hermes tests to stay fast
and free.

### Creating a Release

See [RELEASING-HERMES.md](RELEASING-HERMES.md). Key rules:
- Tag format: `v<upstream-version>-hermes.<fork-version>` (e.g., `v0.4.24-hermes.1`)
- No binary artifacts uploaded — source build only
- Standard GitHub Actions runners only (no larger-runner labels)
- No `actions/upload-artifact` or `actions/cache` in fork workflows

### Syncing with Upstream

```bash
git fetch upstream
git rebase upstream/main   # or merge
# Resolve conflicts in discovery.rs, Justfile (shared with B1)
```

---

## Safety Constraints

- **Zero cost**: No paid tools, signing, runners, or hosting
- **Isolation**: Companion runtime never modifies user's Hermes installation
- **Immutable pins**: Tags and commits, never branches
- **Ad-hoc signing only**: Locally built, not redistributable as binary
- **No telemetry**: No analytics, attribution, or usage tracking
- **License compliance**: Apache-2.0 (Buzz) + MIT (Hermes) attribution preserved
