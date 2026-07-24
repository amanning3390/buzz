# Troubleshooting

## Hermes runtime not detected

**Symptom:** Hermes doesn't appear in the agent runtime picker.

**Fix:**
```bash
scripts/test-hermes-runtime.sh
```

If it fails:
- Reinstall: `scripts/install-hermes-runtime.sh`
- Check the manifest: `python3 scripts/tests/test_manifest.py`

## Empty model list

**Symptom:** The model picker shows no models.

**Causes:**
1. No provider configured in `~/.hermes/config.yaml`
2. No API key set in `~/.hermes/.env`
3. Provider API unreachable

**Fix:**
```bash
# Verify Hermes can see providers
~/Library/Application\ Support/Buzz\ for\ Hermes/runtimes/hermes/current.json
# Then run hermes directly to test
HERMES_HOME=~/.hermes <path-from-current-json> chat -q "ping"
```

## MCP startup timeout

**Symptom:** Agent session takes very long to start or times out.

**Cause:** Buzz's configured-MCP servers are slow to start. This fork sets `HERMES_ACP_SKIP_CONFIGURED_MCP=1` for Hermes sessions, which should prevent this. If you still see it:

1. Check `~/.hermes/config.yaml` for MCP server configs
2. Verify MCP servers are reachable
3. The 45-second cold-start timeout is expected for first Hermes invocation

## Build fails

**Symptom:** `scripts/install-macos-source.sh` fails during build.

**Common fixes:**
```bash
# Ensure Xcode CLT
xcode-select --install

# Clean and rebuild
scripts/repair-macos-source.sh

# Check disk space (need >10 GB free)
df -h ~

# Check build log
cat ~/buzz-for-hermes-install.log
```

## Companion vs official Hermes

This fork installs an isolated Hermes under `~/Library/Application Support/Buzz for Hermes/`. It does **not** touch:
- `~/.local/bin/hermes` (official binary)
- `~/.hermes/hermes-agent/` (official source checkout)
- `~/.hermes/config.yaml` (your config)
- `~/.hermes/.env` (your credentials)

Both can coexist. Buzz uses the companion; your terminal uses the official one.

## PATH conflicts

If `hermes` in your terminal points to the wrong binary after installing this fork:

```bash
which hermes
```

It should show `~/.local/bin/hermes` or your venv path. If it shows a Buzz for Hermes path, your shell profile was not modified by this fork — check for other installations.
