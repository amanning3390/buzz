# Buzz for Hermes — Community Fork

A community fork of [Buzz](https://github.com/block/buzz) that integrates native
[Hermes Agent](https://github.com/NousResearch/hermes-agent) ACP support on top
of the merged bring-your-own-harness (BYOH) architecture.

**This is not an official Block or Nous Research release.**

## What This Fork Does

Buzz PR [#2773](https://github.com/block/buzz/pull/2773) merged a generic
bring-your-own-harness system into `block/buzz:main`, with Hermes as a bundled
tier-2 preset. That merged code is the UI/data-model foundation for this fork.

This fork adds only what generic BYOH does not yet provide for Hermes:

1. **Packaged release sidecars** — release bundles ship real executable
   sidecars, not zero-byte placeholders.
2. **Cold-start headroom** — native `hermes-acp` gets a 45-second model-probe
   budget instead of the shared 10-second fast-fail.
3. **MCP host isolation** — `HERMES_ACP_SKIP_CONFIGURED_MCP=1` is set when Buzz
   owns a Hermes ACP session, so global MCP startup doesn't block discovery.
4. **Process-group-safe teardown** — the PGID is captured at spawn and retained
   so descendants are terminated even after the direct supervisor is reaped.

## Source Base

```text
Base:   block/buzz:main at 95fdf978800982389b120c66ff5e766d785419c7
        (merged BYOH PR #2773, 2026-07-27)
HEAD:   see git log
```

## Verification

All gates pass on this branch:

- `cargo test -p buzz-acp --lib` — 601 tests
- `cargo clippy -p buzz-acp --all-targets -- -D warnings` — clean
- `cargo test release_resolution` — 5 tests
- `pnpm check` (biome + file-size + px + pubkey) — passed
- `pnpm test` — passed
- Playwright onboarding E2E — 19/19 passed

Real ACP acceptance (native `hermes-acp`):

- Model discovery: 361 models in ~10s
- Model switch to `gpt-5.6-luna`: succeeded
- Turn: streamed response, `stopReason=end_turn`
- Orphan processes after teardown: 0

## License

Buzz is Apache-2.0. Hermes Agent is MIT.
