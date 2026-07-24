# Buzz for Hermes — Progress Log

## 2026-07-23: End-to-end execution

### PR Status

| PR | Repo | Branch | Commit | Tests | Status |
|---|---|---|---|---|---|
| H1 | hermes-h1 | feat/acp-cross-provider-models | `1a7cbff5b` | 312/312 ACP pass | ✅ Committed |
| H2 | hermes-h2 | fix/acp-skip-configured-mcp | `b9205bb48` | 315/315 ACP pass | ✅ Committed |
| B1 | buzz-b1 | fix/release-sidecar-resolution | `91deae67` | 76/77 cargo (1 pre-existing) | ✅ Committed |
| B2 | buzz-b2 | feat/native-hermes-acp-runtime | `354281f1` | 597 buzz-acp + 5 desktop Hermes | ✅ Committed |

### Combined Hermes Tag

- Tag: `buzz-acp-v0.19.0.1`
- Commit: `b405f0a16bd7e9ecd87fe1a9c8e9d0f3196b3ec1`
- Branch: `release/buzz-acp-compat` (H1 + H2 cherry-picked)
- Tests: 317/317 ACP pass

### Fork Assembly (release/buzz-for-hermes)

Commits on branch:
1. `1fa27bb7` — docs: zero-cost Hermes fork execution plan
2. `bd55ec87` — docs: identify community fork and upstream licenses
3. `99039727` — fix(desktop): prefer packaged sidecars in release builds (B1 cherry-pick)
4. `245f10d7` — feat: fork infrastructure (manifest, installer, identity)
5. `e206fac2` — feat: CI workflows, update/repair/uninstall scripts
6. `22179caa` — docs: README, setup, troubleshooting, build, release guides

Pending:
- B2 cherry-pick (waiting for subagent completion)
- Fresh-user acceptance test
- Fork release tag

### Verification Commands

```bash
# H1 verification
cd ~/hermes-h1
HERMES_HOME=/tmp/h1/home TMPDIR=/tmp/h1/tmp python -m pytest tests/acp/ -q

# H2 verification
cd ~/hermes-h2
HERMES_HOME=/tmp/h2/home TMPDIR=/tmp/h2/tmp python -m pytest tests/acp/ -q

# B1 verification
cd ~/buzz-b1
PATH=$PWD/bin:$PATH cargo test --manifest-path desktop/src-tauri/Cargo.toml managed_agents::discovery

# Combined Hermes tag
cd ~/hermes-agent-buzz-acp
HERMES_HOME=/tmp/compat/home python -m pytest tests/acp/ -q

# Manifest validation
cd ~/buzz-fork-release
python3 scripts/tests/test_manifest.py
```

### Notes

- B1's `refresh_login_shell_path_clears_cache` test failure is pre-existing (PATH ordering from hermit activation, identical entries reordered). Not related to B1's sidecar changes.
- H1's FTS5 failures on uv-managed Python 3.12.11 are pre-existing. Use `/opt/anaconda3/bin/python` (3.12.7) which has FTS5.
- All work is local. No pushes.
