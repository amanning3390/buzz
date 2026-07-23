# Buzz for Hermes — Execution Progress

Updated: 2026-07-23

## Current repositories

- Buzz clean worktree: `$HOME/buzz-hermes-release`
  - upstream: `block/buzz`
  - fork: `amanning3390/buzz`
  - baseline: `710ed9fff57878a1d69f809b80a6ee0416c53fc4` (`v0.4.24` release head)
- Hermes clean worktree: `$HOME/hermes-agent-buzz-acp`
  - upstream: `NousResearch/hermes-agent`
  - fork: `amanning3390/hermes-agent`
  - baseline: `5be99b6fce16e7d5304196bc9faf3f0cdfc3031f`

## Status

- [x] Preserved tracked Buzz integration patch.
- [x] Preserved tracked Hermes ACP patch, excluding unrelated MiniMax OAuth work.
- [x] Preserved exactly three untracked source artifacts with AppleDouble metadata disabled.
- [x] Verified SHA-256 manifests.
- [x] Created public `amanning3390/buzz` fork.
- [x] Created clean current-upstream Buzz and Hermes clones.
- [ ] Hermes PR H1: cross-provider ACP model state.
- [ ] Hermes PR H2: configured-MCP startup isolation.
- [ ] Buzz PR B1: release sidecar resolution.
- [ ] Buzz PR B2: native Hermes ACP integration.
- [ ] Combined Hermes compatibility tag.
- [ ] Fork-only zero-cost source installer and release path.
- [ ] Fresh-install and live provider acceptance.
- [ ] Public source release.

## Preservation artifacts

Directory: `$HOME/buzz-hermes-preservation`

- `buzz-hermes-integration.patch`
- `hermes-buzz-acp.patch`
- `buzz-hermes-untracked-source.tar.gz`
- `heads.txt`
- `SHA256SUMS`

## Verification log

### Preservation

- SHA-256 verification: PASS.
- Untracked archive contents: exactly `hermes.png`, `hermes.rs`, and the implementation plan.
- Patch files are non-empty.

### Clean clones

- Buzz clean status: PASS.
- Buzz `HEAD == upstream/main`: PASS.
- Hermes clean status: PASS.
- Hermes `HEAD == upstream/main`: PASS.

## Decisions

- Public distribution remains $0: no Apple Developer Program, notarization, paid runner, hosted backend, or retained binary release artifact.
- The supported macOS release is an immutable-tag local source build installed under `~/Applications`.
- Upstream changes remain separated from fork-only branding, companion pinning, and installer code.
