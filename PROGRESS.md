# Buzz for Hermes — Progress

## Current State (2026-07-27)

### Source

- **Base**: `block/buzz:main` at `95fdf9788` (merged BYOH PR #2773)
- **HEAD**: see `git log --oneline -1`
- **Branch**: `main`
- **Git status**: clean

### Integration Commits

| Commit | Description |
|---|---|
| `001c246a8` | Release builds prefer bundled sidecars over workspace artifacts |
| `03a8d8bed` | Regression tests proving bundled sidecars win |
| `dfd17e6a6` | Hermes 45s cold-start + `HERMES_ACP_SKIP_CONFIGURED_MCP` marker |
| `9f05cc878` | Isolated test app identity (bundle ID, scheme) |
| `1c0558a87` | Group-scoped fallback teardown (PGID retention) |
| `07a14fda1` | BYOH Hermes integration plan |
| `fcf196c42` | Extracted `release_resolution.rs` for file-size gate compliance |

### Verification Results

- `cargo test -p buzz-acp --lib`: **601 passed**
- `cargo clippy -p buzz-acp --all-targets -- -D warnings`: **clean**
- `cargo test release_resolution`: **5 passed**
- `pnpm check`: **passed** (biome + file-size + px + pubkey)
- `pnpm test`: **passed**
- `pnpm build:e2e`: **passed**
- Playwright `onboarding-agent-defaults.spec.ts`: **19/19 passed**

### Real ACP Acceptance

- Model discovery: **361 models**, ~10s
- Selected model: `openai-codex:gpt-5.6-luna`
- Turn stop reason: `end_turn`
- Streamed response: `BUZZ_HERMES_LUNA_OK`
- Orphan processes after teardown: **0**

### Installed App

```text
~/Applications/Buzz for Hermes.app
Version:      0.4.26-byoh.95fdf978
Bundle ID:    xyz.hermeshub.buzz.byoh-test
Signature:    valid local ad-hoc
```

### Official App (Untouched)

```text
/Applications/Buzz.app
Version:      0.4.26
Bundle ID:    xyz.block.buzz.app
Signature:    valid
```

### Upstream PR Status

| PR | Status |
|---|---|
| block/buzz#2773 (BYOH) | **Merged** into `block/buzz:main` |
| block/buzz#2655 (sidecars) | Open, reviewed, still applicable to stable releases |
| block/buzz#2656 (Hermes runtime) | **Closed** — superseded by #2773 |
| NousResearch/hermes-agent#70404 | **Merged** |
| NousResearch/hermes-agent#70405 | **Merged** |
