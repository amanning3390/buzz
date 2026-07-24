# Releasing Buzz for Hermes

## Zero-Cost Assertion

This release process costs $0:
- No Apple Developer Program membership
- No paid GitHub features
- No paid CI runners
- No paid code signing
- No paid hosting

## Pre-Release Checklist

- [ ] All four upstream PRs have SHAs recorded:
  - H1: `<sha>` on `feat/acp-cross-provider-models`
  - H2: `<sha>` on `fix/acp-skip-configured-mcp`
  - B1: `<sha>` on `fix/release-sidecar-resolution`
  - B2: `<sha>` on `feat/native-hermes-acp-runtime`
- [ ] Combined Hermes tag `buzz-acp-v0.19.0.1` created and tested
- [ ] `desktop/hermes-runtime.json` points to correct commit/tag
- [ ] No secrets, absolute paths, or `.artifacts/` in branch history
- [ ] Full test suite passes:
  ```bash
  PATH="$PWD/bin:$PATH" just ci
  python3 scripts/tests/test_manifest.py
  scripts/test-hermes-runtime.sh
  ```
- [ ] Clean source install tested on a fresh checkout
- [ ] Fresh-user model switch verified (select provider, switch model, send a message)

## Creating a Release

1. **Tag the release:**
   ```bash
   git tag -a v0.4.24-hermes.1 -m "Buzz for Hermes v0.4.24-hermes.1"
   git push origin v0.4.24-hermes.1
   ```

2. **GitHub Actions** automatically:
   - Runs all CI gates
   - Builds Apple Silicon source smoke test
   - Creates a GitHub Release with source archives
   - Generates release notes

3. **No binary artifacts** are uploaded. Users build from source.

## Release Evidence

After release, record:
- Source commit SHA
- Hermes dependency SHA (from `hermes-runtime.json`)
- Full test results
- Clean install result
- Fresh-user acceptance result

## Upstream PR Status Tracking

Track the four upstream PRs. Once they merge:
1. Update `officialMinVersion` in `hermes-runtime.json`
2. Remove the companion runtime requirement
3. The fork can track upstream directly
