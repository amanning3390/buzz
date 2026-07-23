# Zero-Cost Buzz for Hermes Fork, Upstream PR, and Source Release Plan

> **For Hermes:** Use the `subagent-driven-development` skill to implement this plan task-by-task.

**Goal:** Publish `amanning3390/buzz` as a zero-maintainer-cost community fork that a new Apple Silicon macOS user can install with one pasted source-build command, while submitting the generic integration as focused upstream PRs to both `block/buzz` and `NousResearch/hermes-agent`.

**Architecture:** Keep Buzz and Hermes as separate upstream projects. Submit generic ACP behavior to Hermes and generic runtime integration to Buzz through focused PRs. Until those PRs ship in official releases, the fork pins a temporary native Hermes companion in its own application-support directory. Because paid Apple signing is excluded, the supported distribution is a local source build: an immutable tagged checkout builds the app on the user's Mac, ad-hoc signs that locally built bundle, installs it under `~/Applications`, and never asks the user to bypass Gatekeeper for a downloaded binary.

**Tech Stack:** Rust/Cargo, Tauri 2, TypeScript/React/pnpm/Playwright, Python/pytest/uv, ACP JSON-RPC, Git/GitHub public repositories, free standard GitHub Actions runners, macOS Xcode Command Line Tools, local ad-hoc code signing.

---

## Non-Negotiable Cost Contract

The maintainer cost for this release must remain **$0**.

### Allowed free infrastructure

- Public GitHub forks, branches, PRs, issues, tags, and releases.
- Standard GitHub-hosted runners for public repositories.
- GitHub-generated source archives.
- Local builds on the maintainer's and users' Macs.
- Free Xcode Command Line Tools.
- Free/open-source Rust, Node, pnpm, uv, Python, and Hermes dependencies.
- Users' own existing model-provider accounts, subscriptions, or API keys.

### Prohibited paid dependencies

- Apple Developer Program membership.
- Developer ID signing or Apple notarization.
- Paid GitHub larger runners.
- Paid artifact storage or long-lived CI build artifacts.
- Hosted application servers, databases, queues, telemetry, or update services.
- Maintainer-funded model/API usage for end users.
- Bundled/shared provider credentials.
- A paid binary distribution service.

### Consequence of the $0 constraint

The project will **not** distribute a downloaded `.app` or `.dmg` as the primary install path. An unsigned downloaded application would require a Gatekeeper override, which is not an acceptable definition of “immediately usable.” Instead, users build from the immutable release tag on their own Mac. The locally produced app is ad-hoc signed and is not a quarantined downloaded application bundle.

The supported install command will have this shape. If the free Xcode Command Line Tools are absent, the same pasted command opens Apple's installer and tells the user to paste it again after installation completes:

```bash
xcode-select -p >/dev/null 2>&1 \
  || { xcode-select --install; echo "Install the free tools, then paste this command again."; exit 1; }; \
WORKDIR="$(mktemp -d)" \
  && git clone --depth 1 --branch <immutable-release-tag> \
    https://github.com/amanning3390/buzz.git "$WORKDIR/buzz-for-hermes" \
  && "$WORKDIR/buzz-for-hermes/scripts/install-macos-source.sh"
```

The installer must perform every remaining prerequisite check, dependency setup, Hermes companion installation, Buzz build, local signature verification, installation, and launch-readiness check.

---

## First Release Contract

- Product name: **Buzz for Hermes**.
- Repository: `https://github.com/amanning3390/buzz`, forked from `block/buzz`.
- Platform: Apple Silicon macOS only.
- Proposed tag: `v0.4.23-hermes.1`, adjusted to the current upstream Buzz version after rebase.
- Runtime protocol: native `hermes acp`; no custom ACP adapter.
- App installation: `~/Applications/Buzz for Hermes.app` by default, requiring no administrator access.
- Hermes companion installation:

  ```text
  ~/Library/Application Support/Buzz for Hermes/runtimes/hermes/<commit>/
  ```

- User configuration/authentication: normal `~/.hermes`; credentials are never copied into the fork.
- Updates: rerun the source installer for a newer immutable release tag. No automatic updater in the first zero-cost release.
- Release assets: source tag, GitHub-generated source archives, release notes, dependency manifest, checksums for small text manifests, and sanitized acceptance evidence. No end-user binary artifact.

### Out of scope

- Intel macOS, Windows, and Linux until each receives a native source installer and clean-machine acceptance test.
- Apple-notarized binaries.
- Automatic binary updates.
- Modifying an existing official Hermes source checkout.
- Modifying global Hermes model defaults for per-agent selections.
- Shipping the unrelated local `agent/auxiliary_client.py` MiniMax OAuth patch.
- Fork-only branding, installers, or companion pinning in upstream PRs.
- Claims that this is an official Block or Nous Research release.

---

## Repository and Isolation Model

| Property | Upstream Buzz | Buzz for Hermes fork | Hermes companion |
|---|---|---|---|
| Repository | `block/buzz` | `amanning3390/buzz` | Temporary tag in `amanning3390/hermes-agent` |
| Upstream target | N/A | Generic changes submitted back to Block | Generic changes submitted to Nous Research |
| Product identity | Buzz | Buzz for Hermes | Native Hermes CLI runtime |
| Bundle ID | `xyz.block.buzz.app` | `xyz.hermeshub.buzz` | N/A |
| App data | Official Buzz paths | Fork-specific paths | Versioned fork runtime path |
| Config/auth | Buzz-owned | Fork-owned Buzz data | Shared normal `~/.hermes` user config/auth |
| Model persistence | Managed-agent config | Provider-qualified per-agent model | ACP session state |
| Installation | Official packages/source | Local immutable-tag source build | Isolated venv, never replaces official Hermes |
| Update channel | Block | Explicit source tag | Pinned full commit/tag |

**Decision:** The companion is a temporary native Hermes checkout, not a protocol adapter, patch overlay, or vendored copy inside Buzz. Once official Hermes contains the required features, the manifest names a tested official minimum version and the companion is retired.

---

## Upstream PR Dependency Graph

```text
Hermes PR H1: cross-provider ACP models ───────┐
                                               ├── Buzz PR B2: native Hermes ACP runtime
Hermes PR H2: optional configured-MCP startup ┘

Buzz PR B1: packaged sidecar resolution ───────── independent prerequisite/bug fix

Fork-only F1: identity + companion + source installer + zero-cost release
              depends on H1, H2, B1, and B2 branches while upstream PRs are pending
```

### PR H1 — NousResearch/hermes-agent

**Title:** `feat(acp): expose authenticated cross-provider model choices`

**Branch:** `amanning3390/hermes-agent:feat/acp-cross-provider-models`

**Files:**

- `acp_adapter/server.py`
- `tests/acp/test_server.py`

**Contains only:**

- Build `SessionModelState` from Hermes's shared authenticated provider inventory.
- Provider-qualified IDs such as `<provider>:<model>`.
- Provider-aware labels such as `<Provider Label> · <model>`.
- Deduplication and deterministic ordering.
- Current provider/model fallback.
- Provider-aware `session/set_model` behavior and stale provider-state clearing.
- Targeted and full ACP tests.

**Must not contain:** Buzz names, environment markers, installers, bundle paths, fork metadata, or the MiniMax OAuth patch.

### PR H2 — NousResearch/hermes-agent

**Title:** `fix(acp): allow hosts to skip configured MCP startup`

**Branch:** `amanning3390/hermes-agent:fix/acp-skip-configured-mcp`

**Files:**

- `acp_adapter/entry.py`
- `tests/acp/test_entry.py`

**Contains only:**

- Honor `HERMES_ACP_SKIP_CONFIGURED_MCP=1` before global configured-MCP discovery.
- Preserve MCP servers provided by an ACP session.
- Tests for enabled, disabled, and unset behavior.

**Must not contain:** Buzz-specific process code or model catalog changes.

### PR B1 — block/buzz

**Title:** `fix(desktop): prefer packaged sidecars in release builds`

**Branch:** `amanning3390/buzz:fix/release-sidecar-resolution`

**Files:**

- `desktop/src-tauri/src/managed_agents/discovery.rs`
- `desktop/src-tauri/src/managed_agents/discovery/tests.rs`
- `Justfile` only where required for the canonical `scripts/bundle-sidecars.sh` lifecycle

**Contains only:**

- Release builds prefer bundled target-suffixed binaries beside the app executable.
- Debug builds prefer fresh workspace artifacts.
- Release/debug precedence regression tests.
- Canonical sidecar staging before Tauri packaging.

**Must not contain:** Hermes integration, model persistence, fork branding, or source installer.

### PR B2 — block/buzz

**Title:** `feat(agents): add native Hermes ACP runtime and model selection`

**Branch:** `amanning3390/buzz:feat/native-hermes-acp-runtime`

**Files:**

- `crates/buzz-acp/src/acp.rs`
- `crates/buzz-acp/src/config.rs`
- `crates/buzz-acp/src/lib.rs`
- `crates/buzz-acp/README.md`
- `desktop/src-tauri/src/managed_agents/config_bridge/hermes.rs`
- `desktop/src-tauri/src/managed_agents/config_bridge/mod.rs`
- `desktop/src-tauri/src/managed_agents/config_bridge/reader.rs`
- `desktop/src-tauri/src/managed_agents/discovery.rs`
- `desktop/src-tauri/src/managed_agents/discovery/tests.rs`
- `desktop/src-tauri/src/managed_agents/readiness.rs`
- `desktop/src/features/onboarding/ui/RuntimeIcon.tsx`
- `desktop/src/features/onboarding/ui/SetupStep.tsx`
- `desktop/src/features/onboarding/ui/onboardingRuntimeSelection.ts`
- `desktop/src/features/settings/ui/DoctorSettingsPanel.tsx`
- `desktop/public/runtime-icons/hermes.png`
- `desktop/tests/e2e/onboarding-agent-defaults.spec.ts`

**Contains only:**

- Register native command `hermes` with arguments `["acp"]` and `mcpServers: []`.
- Discover live ACP models with a 45-second Hermes cold-start timeout.
- Set `HERMES_ACP_SKIP_CONFIGURED_MCP=1` for probes and managed sessions.
- Persist provider-qualified models per agent.
- Apply selections through generic ACP `session/set_model`.
- Provider-aware picker labels supplied by Hermes.
- Official Hermes runtime branding.
- Readiness/error states and tests.

**Must not contain:** `Buzz for Hermes` bundle identity, companion fork URL, source installer, fork release workflow, or fork updater behavior.

---

## Phase 1 — Preserve the Acceptance-Tested Work

### Task 1: Snapshot tracked changes

**Objective:** Preserve local work without committing unrelated modifications.

```bash
cd $HOME/buzz
git diff --binary > $HOME/buzz-hermes-integration.patch

cd $HOME/.hermes/hermes-agent
git diff --binary -- \
  acp_adapter/entry.py acp_adapter/server.py \
  tests/acp/test_entry.py tests/acp/test_server.py \
  > $HOME/hermes-buzz-acp.patch
```

Do not include `agent/auxiliary_client.py`.

### Task 2: Preserve untracked source artifacts

```bash
cd $HOME/buzz
tar -czf $HOME/buzz-hermes-untracked-source.tar.gz \
  desktop/public/runtime-icons/hermes.png \
  desktop/src-tauri/src/managed_agents/config_bridge/hermes.rs \
  docs/plans/2026-07-23-hermes-buzz-fork-release.md
```

Verify the archive contains exactly those three source artifacts and excludes `.artifacts/`.

### Task 3: Record preservation evidence

- Compute SHA-256 for both patches and the archive.
- Record current Buzz/Hermes heads and upstream heads.
- Record current test results in `$HOME/buzz-hermes-release/PROGRESS.md` after the clean clone is created.
- Do not record secrets, OAuth details, or raw environment dumps.

---

## Phase 2 — Create Clean Current-Upstream Clones

### Task 4: Create the Buzz release clone

```bash
git clone https://github.com/block/buzz.git $HOME/buzz-hermes-release
cd $HOME/buzz-hermes-release
git remote rename origin upstream
git switch -c integration/hermes-acp upstream/main
```

Do not use a worktree: remotes are shared across worktrees and could mutate the dirty acceptance checkout.

### Task 5: Create the Hermes PR clone

```bash
git clone https://github.com/NousResearch/hermes-agent.git \
  $HOME/hermes-agent-buzz-acp
cd $HOME/hermes-agent-buzz-acp
git remote rename origin upstream
git remote add origin https://github.com/amanning3390/hermes-agent.git
```

### Task 6: Start `PROGRESS.md`

Create `$HOME/buzz-hermes-release/PROGRESS.md` with:

- Phase/task status.
- Branch and commit SHA.
- Exact verification command and summarized result.
- PR URL/check status when available.
- Blocker and decision log.
- Release acceptance evidence paths.

---

## Phase 3 — Build Hermes PR H1

### Task 7: Create the H1 branch

```bash
cd $HOME/hermes-agent-buzz-acp
git switch -c feat/acp-cross-provider-models upstream/main
```

### Task 8: Port failing model-state tests

**Test:** `tests/acp/test_server.py`

Required cases:

1. Two authenticated providers produce provider-qualified choices from both.
2. Provider-aware names are human-readable.
3. Unauthenticated providers are absent.
4. Duplicate choices are removed.
5. Current model remains available when not curated.
6. Provider-prefixed `session/set_model` rebuilds the agent with the requested provider/model.
7. Provider changes clear stale base URL and API mode.
8. Plain model input remains backward compatible.

Run targeted tests and confirm failures before implementation.

### Task 9: Port the minimal H1 implementation

Modify only `acp_adapter/server.py`. Adapt to current upstream inventory APIs; do not paste imports from the 187-commit-old checkout without inspection.

### Task 10: Verify and commit H1

```bash
export HERMES_HOME="$(mktemp -d)"
export TMPDIR=/tmp/hermes-h1-tests
export HERMES_YOLO_MODE=0
python -m pytest tests/acp/test_server.py -q -o 'addopts=' \
  -k 'cross_provider or provider_prefixed'
python -m pytest tests/acp -q -o 'addopts='

git add acp_adapter/server.py tests/acp/test_server.py
git commit -m "feat(acp): expose authenticated cross-provider model choices"
git push -u origin feat/acp-cross-provider-models
```

---

## Phase 4 — Build Hermes PR H2

### Task 11: Create the H2 branch independently

```bash
cd $HOME/hermes-agent-buzz-acp
git switch -c fix/acp-skip-configured-mcp upstream/main
```

H2 must not be stacked on H1.

### Task 12: Port failing MCP-isolation tests

**Test:** `tests/acp/test_entry.py`

Cases:

- Marker `1` skips global configured MCP discovery.
- Marker absent retains existing behavior.
- Marker false/empty retains existing behavior.
- ACP session MCP configuration remains available.

### Task 13: Port, verify, and commit H2

```bash
export HERMES_HOME="$(mktemp -d)"
export TMPDIR=/tmp/hermes-h2-tests
export HERMES_YOLO_MODE=0
python -m pytest tests/acp/test_entry.py -q -o 'addopts='
python -m pytest tests/acp -q -o 'addopts='

git add acp_adapter/entry.py tests/acp/test_entry.py
git commit -m "fix(acp): allow hosts to skip configured MCP startup"
git push -u origin fix/acp-skip-configured-mcp
```

### Task 14: Run full Hermes regressions on both branches

For H1 and H2 independently:

```bash
export HERMES_HOME="$(mktemp -d)"
export TMPDIR=/tmp/hermes-full-tests
export HERMES_YOLO_MODE=0
python -m pytest tests/ -q -o 'addopts='
```

Use current upstream's documented uv environment if direct Python lacks dependencies. Record warnings and results separately.

---

## Phase 5 — Build Buzz PR B1

### Task 15: Create the B1 branch

```bash
cd $HOME/buzz-hermes-release
git switch -c fix/release-sidecar-resolution upstream/main
```

### Task 16: Port B1 tests before implementation

Port only release/debug sidecar-precedence tests. Verify they fail on current upstream.

### Task 17: Port sidecar resolution and release staging

Use `scripts/bundle-sidecars.sh` as the canonical lifecycle. Do not introduce a fork-specific packaging path.

### Task 18: Verify and commit B1

```bash
export PATH="$(pwd)/bin:$PATH"
cargo fmt --all -- --check
cargo test --manifest-path desktop/src-tauri/Cargo.toml \
  managed_agents::discovery -- --nocapture

git add Justfile \
  desktop/src-tauri/src/managed_agents/discovery.rs \
  desktop/src-tauri/src/managed_agents/discovery/tests.rs
git commit -m "fix(desktop): prefer packaged sidecars in release builds"
```

Push after the Buzz fork is created in Task 31.

---

## Phase 6 — Build Buzz PR B2

### Task 19: Create B2 independently from upstream

```bash
cd $HOME/buzz-hermes-release
git switch -c feat/native-hermes-acp-runtime upstream/main
```

B2 may document B1 as a release-testing companion, but must not include B1 commits unless Block requests a stacked PR.

### Task 20: Port model persistence and ACP application tests

Test first:

- Provider-qualified model survives config serialization/deserialization.
- Managed session calls generic `session/set_model` after `session/new`.
- Default/no model does not issue unnecessary switching.
- Hermes environment isolation applies to probes and managed sessions.
- Non-Hermes ACP runtimes retain the normal timeout/environment.

### Task 21: Port Hermes config bridge and readiness tests

Test first:

- Command is `hermes`, args are `["acp"]`, `mcpServers` is empty.
- Live model discovery reaches the bundled `buzz-acp` helper.
- Hermes cold-start budget is 45 seconds.
- Failure states distinguish missing runtime, timeout, and empty provider inventory.

### Task 22: Port UI and Playwright behavior

Test first:

- Hermes appears with official runtime icon/label.
- Live provider-aware choices replace static fallback when discovery succeeds.
- Selection persists per agent.
- Saved provider-qualified model is shown on the agent card.
- Existing runtimes remain unchanged.

### Task 23: Verify and commit B2

```bash
export PATH="$(pwd)/bin:$PATH"
cargo fmt --all -- --check
cargo test -p buzz-acp
cd desktop/src-tauri && cargo test hermes -- --nocapture
cd ..
pnpm check
pnpm test
pnpm build:e2e
pnpm exec playwright test tests/e2e/onboarding-agent-defaults.spec.ts
```

Commit the native integration in reviewable commits if needed, but keep it within one upstream PR branch.

---

## Phase 7 — Assemble the Temporary Hermes Compatibility Tag

### Task 24: Create a temporary combined Hermes branch

The upstream PRs remain independent. The fork runtime needs both while they are pending:

```bash
cd $HOME/hermes-agent-buzz-acp
git switch -c release/buzz-acp-compat upstream/main
git cherry-pick <H1-commit-sha>
git cherry-pick <H2-commit-sha>
```

### Task 25: Verify and tag the combined runtime

Run all `tests/acp` and the complete Hermes suite. Then create an immutable annotated tag:

```bash
git tag -a buzz-acp-v0.19.0.1 \
  -m "Temporary native Hermes ACP compatibility runtime for Buzz"
git push origin release/buzz-acp-compat buzz-acp-v0.19.0.1
```

Record the full commit SHA. Never pin a branch or abbreviated SHA in a release.

---

## Phase 8 — Fork-Only Product and Runtime Work

### Task 26: Create the fork integration branch

After the Buzz fork exists, create a branch based on current upstream and cherry-pick/reapply B1 and B2:

```bash
git switch -c release/buzz-for-hermes upstream/main
git cherry-pick <B1-commit-sha>
git cherry-pick <B2-commit-sha-or-range>
```

### Task 27: Add a pinned Hermes runtime manifest

**Create:** `desktop/hermes-runtime.json`

```json
{
  "repository": "https://github.com/amanning3390/hermes-agent.git",
  "commit": "<full-40-character-sha>",
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

Add validation tests that reject mutable refs, short SHAs, tag/commit mismatches, malformed versions, and unexpected repository URLs.

### Task 28: Add the isolated Hermes companion installer

**Create:**

- `scripts/install-hermes-runtime.sh`
- `scripts/uninstall-hermes-runtime.sh`
- `scripts/test-hermes-runtime.sh`
- Shell/Python tests under `scripts/tests/`

Required behavior:

1. Read the manifest from the local immutable Buzz checkout.
2. Clone the exact Hermes repository/tag into a temporary directory.
3. Verify the full checked-out SHA.
4. Move the verified source checkout into its final inactive version directory before creating a venv. Python venvs are not relocatable. Create an `.installing` marker and do not point `current.json` at this directory yet.
5. Use Hermes's supported staged installer in that final version directory with a companion-only bootstrap home:

   ```bash
   COMPANION_BOOTSTRAP_HOME="$RUNTIME_VERSION_DIR/bootstrap-home"
   for stage in prerequisites venv python-deps; do
     HERMES_INSTALL_DIR="$RUNTIME_VERSION_DIR/source" \
     HERMES_HOME="$COMPANION_BOOTSTRAP_HOME" \
       bash "$RUNTIME_VERSION_DIR/source/scripts/install.sh" \
         --stage "$stage" \
         --dir "$RUNTIME_VERSION_DIR/source" \
         --hermes-home "$COMPANION_BOOTSTRAP_HOME" \
         --skip-browser \
         --non-interactive
   done
   ```

   Do **not** run the `path`, `config`, `setup`, `gateway`, or `complete` stages. In particular, do not let the installer create or replace `~/.local/bin/hermes`.
6. Launch `$RUNTIME_VERSION_DIR/source/venv/bin/hermes` directly for verification. At runtime only, pass the user's normal `HERMES_HOME` (default `~/.hermes`) so the companion reads existing configuration/auth without owning that directory.
7. Run `hermes --version` and an ACP initialize/session probe.
8. Remove `.installing` and atomically replace only `current.json` after successful verification. On failure, delete the inactive partial version and leave the prior pointer unchanged.
9. Preserve the previous runtime for rollback.
10. Record and compare the pre/post path, inode, and checksum of any existing `~/.local/bin/hermes`; fail if it changed.
11. Never touch `~/.hermes/hermes-agent`, shell startup files, or user credentials.
12. Be idempotent.

### Task 29: Resolve the Hermes executable deterministically

Resolution order:

1. Explicit `BUZZ_HERMES_BIN` absolute override.
2. Verified companion executable from `current.json`.
3. Official `hermes` only when `officialMinVersion` is non-null and its version meets the tested minimum.
4. Not-ready state with the exact install remediation.

For release 1, `officialMinVersion` remains `null`.

### Task 30: Give the fork a separate identity

Modify fork-only config:

- Product: `Buzz for Hermes`.
- Bundle ID: `xyz.hermeshub.buzz`.
- Deep-link scheme: `buzz-hermes`.
- Separate app-support and keyring service identifiers.
- Disable the official Buzz updater endpoint.
- Do not import official Buzz credentials or app data automatically.

### Task 31: Add license and fork notices

- Preserve Apache-2.0 `LICENSE` and Block copyright.
- Add `NOTICE` listing material modifications.
- Add `COMMUNITY_FORK.md`.
- Include Hermes MIT attribution and the pinned source commit.
- State that the fork is not an official Block or Nous Research release.

---

## Phase 9 — One-Command Zero-Cost macOS Installer

### Task 32: Add `scripts/install-macos-source.sh`

**Objective:** Turn the immutable source checkout into an installed, launchable application with no paid signing and no Gatekeeper bypass.

Required flow:

1. `set -euo pipefail`; readable progress stages and log file.
2. Verify `uname -s` is Darwin and `uname -m` is arm64.
3. Verify the checkout is at an annotated release tag and clean.
4. Verify `HEAD` matches the commit recorded by the release metadata.
5. Check free disk space and explain the estimated build time/disk use.
6. Verify Git and Xcode Command Line Tools; if CLT is missing, invoke the standard free `xcode-select --install` flow and stop with a resumable instruction.
7. Activate the repository's Hermit/toolchain wrappers using `PATH="$REPO_ROOT/bin:$PATH"`.
8. Install JavaScript dependencies with the lockfile-enforcing command:

   ```bash
   PATH="$REPO_ROOT/bin:$PATH" just desktop-install-ci
   ```

9. Install/verify the pinned Hermes companion.
10. Build all five release sidecars and the Apple Silicon Tauri app through the tested release recipe:

    ```bash
    CI=1 PATH="$REPO_ROOT/bin:$PATH" \
      just desktop-release-build aarch64-apple-darwin
    ```

    The recipe must call `scripts/bundle-sidecars.sh`; the installer must fail if it does not.

12. Verify all expected target-suffixed sidecars exist inside the bundle.
13. Ad-hoc sign the **locally built** app:

    ```bash
    codesign --force --deep --sign - "<built-app>"
    codesign --verify --deep --strict "<built-app>"
    ```

14. Confirm the built app has no quarantine attribute; do not run a blanket quarantine-removal command.
15. Atomically install to `~/Applications/Buzz for Hermes.app`.
16. Register/launch the application using standard macOS tools.
17. Run a non-secret health/readiness check.
18. Print the next exact step: configure provider or open Agents.

The script must be safe to rerun and must not require `sudo`.

### Task 33: Add update, repair, and uninstall commands

**Create:**

- `scripts/update-macos-source.sh`
- `scripts/repair-macos-source.sh`
- `scripts/uninstall-macos.sh`

Rules:

- Update requires an explicit immutable target tag; never silently tracks `main`.
- Rebuild in a temporary directory and replace atomically.
- Keep the previous app/runtime until the new build launches.
- Uninstall removes fork app/runtime only and preserves `~/.hermes` config/auth/sessions by default.
- A separate explicit `--purge-buzz-data` flag may remove fork-owned app data after confirmation.

### Task 34: Add installer tests

Tests must cover:

- Wrong OS/architecture.
- Missing CLT.
- Dirty checkout.
- Mutable branch instead of release tag.
- Insufficient disk.
- Failed Hermes install.
- Failed sidecar build.
- Missing packaged sidecar.
- Failed code-sign verification.
- Atomic rollback.
- Existing official Buzz/Hermes remains untouched.

---

## Phase 10 — Free CI and Source Release

### Task 35: Add zero-cost CI

**Create:** `.github/workflows/ci-hermes.yml`

Before enabling Actions in the fork, disable every inherited upstream workflow; some upload retained artifacts and the official release jobs depend on Block-owned credentials:

```bash
gh workflow list -R amanning3390/buzz
for workflow in ci.yml docker.yml release.yml signed-macos-canary.yml sprig.yml; do
  gh workflow disable "$workflow" -R amanning3390/buzz || true
done
```

Inventory and disable any additional inherited workflow that can run on the fork. Enable only `ci-hermes.yml` and `release-hermes-source.yml` after both are on the fork's default branch.

Use only standard public runners (`ubuntu-latest` and `macos-14`; never larger-runner labels). Jobs:

1. Rust formatting/clippy.
2. Full `buzz-acp` suite.
3. Desktop Hermes Rust tests.
4. TypeScript lint/typecheck/unit tests.
5. Playwright smoke tests.
6. Runtime manifest tests.
7. Installer shellcheck/unit tests.
8. Apple Silicon source build smoke test.
9. Secret and absolute-local-path scan.

To keep cost predictably zero:

- Do not use larger runners.
- Do not upload app/DMG build artifacts.
- Do not use `actions/upload-artifact` or `actions/cache` in fork-owned workflows.
- Build and discard the app only to prove reproducibility.
- Cancel superseded PR runs with workflow concurrency.

### Task 36: Add the zero-cost source release workflow

**Create:** `.github/workflows/release-hermes-source.yml`

On immutable `v*-hermes.*` tags:

1. Verify tag/version/source commit.
2. Run all CI gates.
3. Validate the Hermes manifest tag/commit remotely.
4. Run a clean Apple Silicon source build and discard the app after verification.
5. Generate small text-only release evidence: manifest summary, test summary, source commit, dependency commit, and install command.
6. Create/update the GitHub Release using the automatically generated source archives.
7. Publish no `.app`, `.dmg`, updater archive, or paid-hosted artifact.

No Apple secrets, signing keys, provider credentials, or paid services are required.

### Task 37: Disable incompatible updater behavior

For release 1:

- No automatic Tauri updater endpoint.
- UI explains that updates use an explicit source tag and the update script.
- Tests ensure the fork never points to `block/buzz/releases`.
- Later binary updates remain out of scope until a free trusted-distribution mechanism exists.

---

## Phase 11 — Documentation and Fresh-User Path

### Task 38: Rewrite the README quick start

Top-level quick start:

```bash
xcode-select -p >/dev/null 2>&1 \
  || { xcode-select --install; echo "Install the free tools, then paste this command again."; exit 1; }; \
WORKDIR="$(mktemp -d)" \
  && git clone --depth 1 --branch <release-tag> \
    https://github.com/amanning3390/buzz.git "$WORKDIR/buzz-for-hermes" \
  && "$WORKDIR/buzz-for-hermes/scripts/install-macos-source.sh"
```

Document:

- This is a local source build, not a downloaded unsigned binary.
- Expected time, bandwidth, and temporary disk use.
- No Apple Developer membership or payment required.
- Users use their own provider accounts.
- First provider setup command.
- How to choose a provider/model in Buzz.
- Update, repair, rollback, and uninstall.
- Community-fork status and upstream links.

### Task 39: Add troubleshooting docs

**Create:**

- `docs/hermes-setup.md`
- `docs/hermes-troubleshooting.md`
- `docs/building-macos-zero-cost.md`
- `docs/releasing-hermes-fork.md`

Cover missing CLT, PATH, provider auth, empty model inventory, MCP timeout, companion vs official Hermes, build logs, sidecar diagnostics, app location, and safe uninstall.

### Task 40: Add release checklist

**Create:** `RELEASING-HERMES.md`

Include:

- $0-cost assertion.
- No Apple/paid-runner/provider secrets configured in CI.
- Source and Hermes dependency SHAs.
- PR status/URLs.
- Full test results.
- Clean source install result.
- No retained binary artifacts.
- No maintainer-specific absolute home paths, credentials, or `.artifacts/` in branch history.
- Fresh-user model switch and live-turn proof.

---

## Phase 12 — Create Forks and Open the Required Upstream PRs

### Task 41: Create the Buzz fork

```bash
gh repo fork block/buzz --clone=false --remote=false
cd $HOME/buzz-hermes-release
git remote add origin https://github.com/amanning3390/buzz.git
```

Never push the dirty original `$HOME/buzz/main`.

### Task 42: Prepare four PR body files

**Create outside both repositories so coordination prose cannot leak into any upstream PR branch:**

- `$HOME/buzz-hermes-pr-bodies/hermes-cross-provider-models.md`
- `$HOME/buzz-hermes-pr-bodies/hermes-skip-configured-mcp.md`
- `$HOME/buzz-hermes-pr-bodies/buzz-release-sidecars.md`
- `$HOME/buzz-hermes-pr-bodies/buzz-native-hermes-acp.md`

Every PR body includes:

- Problem and generic user impact.
- Scope/non-scope.
- Architecture/protocol behavior.
- Security and backward compatibility.
- Exact tests/results.
- Screenshots only where UI-relevant.
- Dependency links to the other PRs.
- No claims that local acceptance equals upstream CI.

### Task 43: Open Hermes PR H1

```bash
gh pr create \
  -R NousResearch/hermes-agent \
  --head amanning3390:feat/acp-cross-provider-models \
  --base main \
  --title "feat(acp): expose authenticated cross-provider model choices" \
  --body-file $HOME/buzz-hermes-pr-bodies/hermes-cross-provider-models.md
```

### Task 44: Open Hermes PR H2

```bash
gh pr create \
  -R NousResearch/hermes-agent \
  --head amanning3390:fix/acp-skip-configured-mcp \
  --base main \
  --title "fix(acp): allow hosts to skip configured MCP startup" \
  --body-file $HOME/buzz-hermes-pr-bodies/hermes-skip-configured-mcp.md
```

### Task 45: Push/open Buzz PR B1

```bash
git switch fix/release-sidecar-resolution
git push -u origin fix/release-sidecar-resolution
gh pr create \
  -R block/buzz \
  --head amanning3390:fix/release-sidecar-resolution \
  --base main \
  --title "fix(desktop): prefer packaged sidecars in release builds" \
  --body-file $HOME/buzz-hermes-pr-bodies/buzz-release-sidecars.md
```

### Task 46: Push/open Buzz PR B2

```bash
git switch feat/native-hermes-acp-runtime
git push -u origin feat/native-hermes-acp-runtime
gh pr create \
  -R block/buzz \
  --head amanning3390:feat/native-hermes-acp-runtime \
  --base main \
  --title "feat(agents): add native Hermes ACP runtime and model selection" \
  --body-file $HOME/buzz-hermes-pr-bodies/buzz-native-hermes-acp.md
```

B2 links H1 and H2 as the enhanced Hermes capability path. B1 is linked as the release-sidecar correctness fix but remains independently reviewable.

### Task 47: Respond to review without polluting boundaries

- Fix H1 only on H1.
- Fix H2 only on H2.
- Fix B1 only on B1.
- Fix B2 only on B2.
- Rebase each independently when upstream moves.
- Keep fork-only commits out of all four PRs.
- Rerun that PR's complete test contract after every rebase.

---

## Phase 13 — Clean-Machine Acceptance

### Task 48: Test as a fresh standard macOS user

Use a separate standard user account, clean Mac, or disposable macOS VM.

1. Install only Git/Xcode CLT if absent.
2. Paste the documented immutable-tag command.
3. Confirm no administrator password is required.
4. Confirm the script builds from source and installs under `~/Applications`.
5. Confirm no Gatekeeper bypass or quarantine-removal instruction is used.
6. Confirm official Buzz and official Hermes, if present, remain unchanged.
7. Configure two existing provider accounts.
8. Verify provider-aware choices from both providers.
9. Select a non-default provider/model.
10. Save, quit, relaunch, and verify persistence.
11. Start the agent and send a deterministic probe.
12. Verify the exact response.
13. Inspect sanitized logs and prove `session/set_model`, provider, model, and endpoint.
14. Stop agents and verify zero remaining ACP processes.
15. Run repair, update-to-explicit-tag, rollback, and uninstall tests.
16. Confirm `~/.hermes` config/auth survives uninstall.

Use an existing local/free-quota/subscription-backed provider account and the shortest deterministic response practical. Do not create a new paid account or incur a new maintainer-funded API charge for acceptance.

### Task 49: Prove zero maintainer cost

Before release, verify:

- Repository is public.
- Workflows use only standard public runners.
- No larger-runner labels.
- No Apple Developer secrets.
- No provider API keys in GitHub secrets.
- No deployed infrastructure.
- No retained binary Actions artifacts.
- No required paid account in README.
- Acceptance used existing accounts only; end users supply their own.

### Task 50: Security and publication review

```bash
git status --short
git log --oneline upstream/main..HEAD
git diff --check upstream/main...HEAD
git diff --stat upstream/main...HEAD
```

Then:

- Run a secret scanner across branch history.
- Search for macOS/Linux absolute home-path patterns, token prefixes, app-support test data, and `.artifacts/`.
- Review every untracked file.
- Generate license/dependency inventory.
- Run `requesting-code-review` on fork-only changes and each PR branch.

---

## Phase 14 — Publish the Fork Source Release

### Task 51: Merge the fork release branch

Open a PR from `release/buzz-for-hermes` into `amanning3390/buzz:main`. The PR must identify:

- Which commits correspond to upstream B1/B2.
- Which commits are fork-only.
- Hermes compatibility tag/SHA.
- Zero-cost installer and CI behavior.
- Clean-machine acceptance evidence.

### Task 52: Tag and release

```bash
git switch main
git pull --ff-only origin main
git tag -a v0.4.23-hermes.1 \
  -m "Buzz for Hermes v0.4.23-hermes.1 — zero-cost source release"
git push origin v0.4.23-hermes.1
```

The free source release workflow runs. Release notes must lead with the immutable clone/install command and clearly state that no prebuilt app is distributed.

### Task 53: Reinstall from the published tag

Delete the test installation and temporary clone. Follow the public release instructions exactly using the published tag. Complete a short non-default-provider probe again. This final proof—not the original local app—is the release acceptance result.

---

## Post-Release Upstream Transition

### Task 54: Track all four PRs

Record PR URLs and CI status in `PROGRESS.md`. Keep the fork compatibility commits rebased as needed without rewriting the published release tag.

### Task 55: Retire the companion after Hermes release

When H1 and H2 are merged and included in an official Hermes release:

1. Acceptance-test that official version.
2. Set `officialMinVersion` in the manifest.
3. Prefer compatible official Hermes before the companion.
4. Keep the companion as one-release rollback.
5. Remove it in the following release if clean.

### Task 56: Reduce the fork after Buzz merges

When B1/B2 merge into Block Buzz:

- Sync from upstream.
- Drop equivalent fork commits.
- Retain only zero-cost product identity/installer/release documentation if a separate fork is still useful.
- Never maintain duplicate integration logic after upstream owns it.

---

## Final Definition of Done

The zero-cost fork is immediately usable only when a new Apple Silicon macOS user can:

1. Paste one immutable-tag clone/install command.
2. Build and install locally without `sudo`, Apple membership, or Gatekeeper bypass.
3. Install the pinned native Hermes companion without replacing official Hermes.
4. Configure their own providers normally.
5. See cross-provider, provider-aware model choices.
6. Persist a provider-qualified model per agent.
7. Start without unrelated configured-MCP startup stalls.
8. Complete a real turn through the selected non-default provider/model.
9. Update, repair, roll back, and uninstall without losing Hermes config/auth.

The maintainer has also opened the two focused Hermes PRs and two focused Buzz PRs, all with clean scope and passing test evidence. There are no paid services, Apple credentials, hosted backends, retained binary artifacts, or maintainer-funded provider accounts in the release path.
