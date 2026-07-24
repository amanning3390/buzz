# Hermes Setup

## Prerequisites

1. **Hermes Agent installed** — if you don't have it, the fork's installer handles this via the companion runtime.
2. **At least one provider configured** in `~/.hermes/config.yaml`:
   ```bash
   hermes setup   # interactive wizard
   # or
   hermes model   # just pick a provider/model
   ```

## Configuring a Provider

Hermes supports 20+ providers. Pick one:

| Provider | Setup |
|----------|-------|
| OpenRouter | Set `OPENROUTER_API_KEY` in `~/.hermes/.env` |
| Anthropic | Set `ANTHROPIC_API_KEY` in `~/.hermes/.env` |
| OpenAI | Set `OPENAI_API_KEY` in `~/.hermes/.env` |
| DeepSeek | Set `DEEPSEEK_API_KEY` in `~/.hermes/.env` |
| xAI / Grok | Set `XAI_API_KEY` in `~/.hermes/.env` |
| Google Gemini | Set `GOOGLE_API_KEY` in `~/.hermes/.env` |
| Local (Ollama) | Set `model.base_url` in config.yaml |

After configuring, launch Buzz for Hermes and all authenticated providers will appear in the agent picker.

## Selecting a Model in Buzz

1. Open the app → **Settings → Agents**
2. Choose **Hermes** as your runtime
3. The model dropdown shows all models from your authenticated providers
4. Select one — it persists per-agent

## How the Companion Runtime Works

The fork installs a **pinned Hermes checkout** under:

```
~/Library/Application Support/Buzz for Hermes/runtimes/hermes/<commit>/
```

This is isolated from your official Hermes installation. It reads your `~/.hermes` config at runtime but never modifies it.

To verify the companion runtime:

```bash
scripts/test-hermes-runtime.sh
```

## Multiple Providers

Hermes supports credential pools — you can configure multiple API keys for the same provider and it rotates them automatically. All configured providers appear in the Buzz model picker.
