# Buzz for Hermes Community Fork

Buzz for Hermes is a community-maintained derivative of
[`block/buzz`](https://github.com/block/buzz). It adds a first-class native
[`NousResearch/hermes-agent`](https://github.com/NousResearch/hermes-agent)
ACP runtime path while the generic changes are reviewed upstream.

## Status

- This is **not** an official Block, Inc. release of Buzz.
- This is **not** an official Nous Research release of Hermes Agent.
- The integration continues to use Hermes's native `hermes acp` command; it
  does not replace ACP with a custom protocol or model proxy.
- Fork-only branding, the temporary compatibility-runtime pin, and the
  zero-cost source installer are intentionally kept out of upstream PRs.

## Zero-cost distribution

The supported macOS installation path builds the app locally from an immutable
source tag, applies an ad-hoc signature to that locally produced app bundle,
and installs it under `~/Applications`. No Apple Developer Program membership,
notarization service, paid CI runner, hosted backend, or paid artifact service
is required.

No prebuilt `.app` or `.dmg` is represented as a trusted notarized release.
Users authenticate their own model providers and are responsible for any
provider-specific account, subscription, or usage cost.

## Data and runtime isolation

The fork uses its own bundle identifier and application-support directory. Its
temporary Hermes compatibility runtime is installed in a versioned directory
under the fork's application-support root. It must not replace an official
Hermes checkout, `~/.local/bin/hermes`, shell startup files, or the user's
normal `~/.hermes` configuration and authentication data.

## Upstream path

The generally useful work is submitted as focused PRs:

1. Hermes cross-provider ACP model state and provider-aware switching.
2. Hermes host-requested configured-MCP startup isolation.
3. Buzz packaged-sidecar resolution.
4. Buzz native Hermes ACP runtime integration and model persistence.

Once official releases contain the required behavior, the temporary companion
runtime is retired and duplicate fork logic is removed.

## Licenses and attribution

Buzz remains distributed under the Apache License, Version 2.0; see
[`LICENSE`](LICENSE) and [`NOTICE`](NOTICE). Hermes Agent is distributed under
the MIT License; see
[`THIRD_PARTY_NOTICES/HERMES_AGENT_LICENSE`](THIRD_PARTY_NOTICES/HERMES_AGENT_LICENSE).
