# Buzz BYOH Hermes Integration Plan

> **For Hermes:** Use the `subagent-driven-development` skill to implement this plan task-by-task. Use strict RED–GREEN TDD for every behavior change.

**Goal:** Integrate native Hermes ACP into the newly merged Buzz bring-your-own-harness UI, starting from the exact current `block/buzz:main` merge commit, and deliver a verified side-by-side `Buzz for Hermes.app` without modifying the clean official Buzz installation or its data.

**Architecture:** Treat merged Buzz PR [#2773](https://github.com/block/buzz/pull/2773) as the UI and data-model foundation. Do not replay the old harness-specific UI integration. Keep only the remaining load-bearing Hermes host contracts that generic BYOH does not yet provide: executable packaged sidecars, Hermes-specific cold-start headroom, host-owned MCP isolation, and process-group-safe teardown. Build and install the result under a distinct macOS identity.

**Tech Stack:** Git/GitHub CLI, Rust/Cargo, Tauri 2, TypeScript/React/pnpm, ACP JSON-RPC over stdio, macOS ad-hoc signing for local source builds.

---

## 1. Current Source-of-Truth Baseline

Captured from GitHub and the local machine on 2026-07-27.

### GitHub

- Latest published Buzz release: `v0.4.26`, published 2026-07-25.
- `v0.4.26` targets `0096d710ed2e6abab19aaf7cdc14e3ee603d7ec8` and **does not contain BYOH**.
- Buzz PR #2773 is merged.
- Current `block/buzz:main`: `95fdf978800982389b120c66ff5e766d785419c7`.
- #2773 provides the generic three-tier harness system and includes the preset:

```text
id: hermes
label: Hermes Agent
command: hermes-acp
args: []
```

- Buzz PR #2655 remains the reviewed packaged-sidecar fix needed for release bundles.
- Hermes PRs #70404 and #70405 are merged on Hermes main, but the local app continues to validate the installed Hermes runtime directly instead of assuming a future release version.

### Clean official app

```text
Path:       /Applications/Buzz.app
Version:    0.4.26
Bundle ID:  xyz.block.buzz.app
Signature:  valid
```

This app and its data are the clean comparison/control installation. The integration must not write to its bundle, application-support directories, preferences, or keychain identity.

### Active integration worktree

```text
Path:   /Users/am/buzz-upstream-main-hermes-test
Branch: test/upstream-main-hermes
Base:   95fdf978800982389b120c66ff5e766d785419c7
```

Current integration commits:

```text
001c246a8  fix(desktop): prefer packaged sidecars in release builds
03a8d8bed  test(desktop): prove bundled sidecars win over workspace artifacts
dfd17e6a6  fix(acp): give native Hermes probes cold-start headroom
9f05cc878  build(desktop): isolate upstream Hermes test app
```

### Installed side-by-side test app

```text
Path:       ~/Applications/Buzz for Hermes.app
Version:    0.4.26-byoh.95fdf978
Bundle ID:  xyz.hermeshub.buzz.byoh-test
Deep link:  buzz-hermes-test
Signature:  valid local ad-hoc signature
```

---

## 2. Isolation Model

| Property | Official clean Buzz | BYOH Hermes integration |
|---|---|---|
| App path | `/Applications/Buzz.app` | `~/Applications/Buzz for Hermes.app` |
| Bundle ID | `xyz.block.buzz.app` | `xyz.hermeshub.buzz.byoh-test` during local acceptance |
| Data namespace | Official Buzz namespace | Namespace derived from the fork bundle ID |
| Deep-link scheme | `buzz` | `buzz-hermes-test` |
| Signing | Official signed/notarized distribution | Local ad-hoc source-build signature |
| Update channel | Official Buzz updater | No updater; rebuild from an exact Git commit |
| Credentials/data | Existing official state | No automatic migration or copying |

**Decision:** Keep the apps side-by-side. Do not patch the downloaded `/Applications/Buzz.app` in place. “Integrate Hermes into the clean new Buzz” means rebuild from the exact GitHub source underlying the new UI architecture while preserving the official app as the control.

---

## 3. Superseded Approach

The previous plan used stable `v0.4.26` and ported the old Hermes-specific onboarding/runtime UI because BYOH had not merged.

That approach is now superseded:

1. Do **not** port the old `SetupStep.tsx` Hermes UI onto `v0.4.26`.
2. Do **not** maintain a competing harness registry.
3. Do **not** merge the old fork wholesale.
4. Use #2773’s `HarnessDefinition`, preset catalog, Settings → Agents gallery, effective descriptor, persistence, and model-discovery paths directly.
5. Port only behavior proven missing after exercising the merged implementation.

---

## 4. Non-Negotiable Decisions

1. **Base on the exact current upstream main commit containing #2773.** Pin the commit in the build record; do not build from an ambiguous moving checkout.
2. **Use #2773’s Hermes preset.** `hermes-acp` is Hermes’s native ACP entrypoint, not a third-party adapter.
3. **Preserve generic BYOH architecture.** Hermes-specific handling belongs only at runtime-host boundaries that genuinely differ from lightweight adapters.
4. **Package real sidecars.** A release bundle containing zero-byte/non-executable placeholders is a failed build even when Tauri itself exits successfully.
5. **Give Hermes cold-start headroom.** Keep the shared 10-second probe for other runtimes; use 45 seconds for `hermes`, `hermes-agent`, and `hermes-acp`.
6. **Make Buzz the MCP host.** Set `HERMES_ACP_SKIP_CONFIGURED_MCP=1` for Hermes ACP children unless the operator explicitly exported a value.
7. **Keep teardown group-scoped.** No Hermes, MCP, tool, child, or grandchild process may survive probe, cancellation, shutdown, or app exit.
8. **Do not migrate secrets.** Never copy Nostr private keys, keychain items, Hermes `.env`, provider tokens, or official Buzz app data.
9. **Do not publish yet.** Local operation and acceptance come before push/tag/release work.

---

## 5. Implementation Tasks

### Task 1: Freeze and verify the merged BYOH base — COMPLETE

**Objective:** Prove the integration starts from the actual merged UI architecture.

**Evidence:**

```bash
gh pr view 2773 --repo block/buzz \
  --json state,mergedAt,mergeCommit,headRefOid,url
gh api repos/block/buzz/commits/main

git fetch upstream main --tags
git rev-parse upstream/main
```

**Acceptance:** both GitHub and local `upstream/main` resolve to `95fdf978800982389b120c66ff5e766d785419c7`.

### Task 2: Preserve side-by-side macOS identity — COMPLETE

**Files:**
- `desktop/src-tauri/tauri.conf.json`

**Required local identity:**

```text
productName: Buzz for Hermes
version: 0.4.26-byoh.95fdf978
identifier: xyz.hermeshub.buzz.byoh-test
scheme: buzz-hermes-test
```

**Verification:** inspect the built and installed `Info.plist`; strict deep codesign verification must pass after local ad-hoc signing.

### Task 3: Package executable release sidecars — COMPLETE

**Source:** reviewed Buzz PR #2655 commits.

**Files:**
- `Justfile`
- `desktop/src-tauri/src/managed_agents/discovery.rs`
- `desktop/src-tauri/src/managed_agents/discovery/tests.rs`

**Acceptance:** the final app contains non-zero executable copies of:

```text
buzz-desktop
buzz-acp
buzz-agent
buzz-dev-mcp
git-credential-nostr
buzz
```

Run:

```bash
cargo test --manifest-path desktop/src-tauri/Cargo.toml \
  release_resolution -- --nocapture
```

### Task 4: Make merged Hermes discovery operational — COMPLETE

**Files:**
- `crates/buzz-acp/src/acp.rs`
- `crates/buzz-acp/src/lib.rs`

**RED:** native `hermes-acp` model discovery timed out on #2773’s shared 10-second budget.

**GREEN:**

- Recognize `hermes`, `hermes-agent`, and `hermes-acp`.
- Use a 45-second probe timeout only for Hermes.
- Apply `HERMES_ACP_SKIP_CONFIGURED_MCP=1` at the common `AcpClient::spawn` boundary.
- Preserve exported operator values.
- Wire the resolved timeout into models, auth-method, and authentication probes.

**Verification:**

```bash
cargo test -p buzz-acp hermes_acp_runtime_gets_ -- --nocapture
cargo test -p buzz-acp --lib
cargo clippy -p buzz-acp --all-targets -- -D warnings
```

Expected current results: two focused tests pass; complete library suite reports 600 passed; clippy is clean.

### Task 5: Port process-group fallback teardown — NEXT

**Objective:** Bring the already-proven group-scoped fallback contract onto the #2773-based branch without replaying unrelated old B2 code.

**Source reference:** `475d79fdf` in `/Users/am/buzz-hermes-v0426`.

**Files:**
- Modify: `crates/buzz-acp/src/acp.rs`

**TDD steps:**

1. Add a Unix regression that spawns a shell leader, child, and grandchild in the ACP process group.
2. Force the supervisor fallback after the direct child has already transitioned so `child.id()` is unavailable.
3. Assert the descendant does not survive shutdown.
4. Run the single test against current #2773-based code and record RED.
5. Retain the process-group ID independently from the mutable child handle.
6. Use that retained PGID for shutdown before falling back to direct-child kill.
7. Re-run the focused test and complete `buzz-acp` suite.
8. Commit with DCO.

**Commit:**

```bash
git commit -s -m "fix(agents): keep Hermes fallback teardown group-scoped"
```

### Task 6: Verify the actual BYOH UI path

**Objective:** Exercise the merged UI rather than an old Hermes-specific screen.

**Native path:**

```text
Settings → Agents → Harness gallery → Hermes Agent
```

**Acceptance:**

- `Hermes Agent` is labeled as a preset.
- It is shown as installed when `hermes-acp` resolves from the GUI-visible augmented PATH.
- The agent editor can select Hermes.
- Model discovery returns provider-qualified IDs.
- Model selection persists after save and relaunch.
- No permission, key import, or launch-at-login dialog is approved automatically.

**Path bridge:** when the git-installed entrypoint is not visible to GUI launch services, retain the explicit symlink:

```text
~/.local/bin/hermes-acp
  → ~/.hermes/hermes-agent/venv/bin/hermes-acp
```

### Task 7: Run full changed-path gates

From `/Users/am/buzz-upstream-main-hermes-test`:

```bash
. ./bin/activate-hermit
cargo fmt --all -- --check
cargo clippy -p buzz-acp --all-targets -- -D warnings
cargo test -p buzz-acp --lib
cargo test --manifest-path desktop/src-tauri/Cargo.toml \
  release_resolution -- --nocapture
cd desktop
pnpm check
pnpm test
pnpm build:e2e
pnpm exec playwright test tests/e2e/onboarding-agent-defaults.spec.ts
```

Any failure must be reproduced against untouched `95fdf9788` before it can be classified as upstream/unrelated.

### Task 8: Build, sign, inspect, and install from the clean commit

**Build:**

```bash
just desktop-release-build
```

**Expected outputs:**

```text
desktop/src-tauri/target/aarch64-apple-darwin/release/bundle/macos/Buzz for Hermes.app
desktop/src-tauri/target/aarch64-apple-darwin/release/bundle/dmg/Buzz for Hermes_0.4.26-byoh.95fdf978_aarch64.dmg
```

**Before installation:**

1. Require a clean git status.
2. Copy the app to a staging path.
3. Set effective display/name fields to `Buzz for Hermes`.
4. Ad-hoc sign the complete bundle.
5. Run strict deep signature verification.
6. Run `verify-source-app-bundle.py` with every required executable.
7. Execute model discovery using the `buzz-acp` inside the staged app.
8. Atomically swap only `~/Applications/Buzz for Hermes.app`.
9. Keep the prior fork app until launch succeeds.
10. Re-verify the installed copy and launch as the signed-in user.

### Task 9: Real Hermes ACP acceptance

Run against native `hermes-acp` with `mcpServers: []`:

1. `initialize`
2. `session/new`
3. Confirm provider-qualified model catalog.
4. Select a non-default model via `session/set_model`.
5. Send a real `session/prompt`.
6. Reconstruct streamed `agent_message_chunk` events.
7. Require `stopReason=end_turn`.
8. Terminate the ACP process group.
9. Prove no `hermes-acp`, adapter, MCP, or probe process remains.

Current proven acceptance selected `openai-codex:gpt-5.6-luna` and reconstructed the exact response `BUZZ_HERMES_LUNA_OK`.

### Task 10: Prepare upstream follow-up evidence — DEFER UNTIL LOCAL UI PASS

After the UI and relaunch gates pass, prepare a narrow upstream follow-up containing only:

- Hermes cold-start timeout resolution.
- `hermes-acp` identity coverage.
- host-owned MCP environment at the spawn boundary.
- process-group fallback teardown regression, if still absent upstream.

Do not revive the closed harness-specific PR #2656 and do not duplicate #2773’s preset/UI work.

---

## 6. Verification Record Required Before Completion

Record these values without secrets:

- Exact upstream merge/base SHA.
- Exact integration HEAD.
- App bundle ID and version.
- Final DMG SHA-256.
- Sidecar names, non-zero sizes, and executable status.
- Strict deep codesign result.
- Focused and full test counts.
- Hermes version returned by ACP.
- Number of discovered models.
- Selected provider-qualified model ID.
- Turn stop reason.
- Orphan process count.
- Current official Buzz version and bundle ID after installation.

---

## 7. Success Criteria

The integration is complete when all are true:

- [x] #2773 is the actual UI/data-model foundation.
- [x] Official Buzz `0.4.26` remains a separate valid app.
- [x] The fork installs side-by-side under a distinct identity.
- [x] Release bundles contain real executable sidecars.
- [x] Native `hermes-acp` model discovery succeeds.
- [x] Provider-qualified model switching succeeds over ACP.
- [x] A real non-default-model turn completes.
- [x] No ACP process remains after the acceptance turn.
- [ ] Process-group fallback teardown is ported and retested on the #2773 base.
- [ ] Full frontend/E2E changed-path gates pass on the final HEAD.
- [ ] Final clean artifact is rebuilt and reinstalled after the teardown commit.
- [ ] The merged Settings → Agents Hermes selection and relaunch persistence are visually verified on that final installed artifact.

---

## 8. Rollback

If the final integration fails:

1. Quit only `xyz.hermeshub.buzz.byoh-test`.
2. Restore the retained previous `Buzz for Hermes.app` bundle.
3. Do not touch `/Applications/Buzz.app`.
4. Do not delete official Buzz data.
5. Do not delete `~/.hermes` or its credentials.
6. Preserve logs/test output needed to report the narrow upstream gap.

The clean official Buzz app is always the control and remains independently launchable.
