# Hermes Agent — Railway Template

Deploy [Hermes Agent](https://github.com/NousResearch/hermes-agent) on [Railway](https://railway.app) as a direct `hermes gateway` container.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/hermes-agent-ai?referralCode=QXdhdr&utm_medium=integration&utm_source=template&utm_campaign=generic)

> Hermes Agent is an autonomous AI agent by [Nous Research](https://nousresearch.com/) that lives on your server, connects to your messaging channels, and gets more capable the longer it runs.

## What This Runs

The container starts Hermes directly:

```text
tini
└── /app/start.sh
    └── hermes gateway
```

`start.sh` only prepares `/data/.hermes`, seeds `config.yaml` from the installed Hermes example when needed, removes a stale gateway PID file, and then `exec`s the command.

## Runtime Tooling

The image keeps the language runtimes Hermes and its tools may need:

- Python 3.12, pip, and uv from the base image
- Node.js 22, npm, and pnpm
- Bun

## Hermes Version

The upstream Hermes revision is pinned in the Dockerfile:

```dockerfile
ARG HERMES_REF=v2026.4.30
```

To bump Hermes, update `HERMES_REF` to a release tag or another git ref published by [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent).

## Environment Variables

Configure Hermes through Railway Variables. Container-level environment variables are inherited directly by `hermes gateway`.

For the intended first deploy, configure these Railway Variables:

```env
OPENROUTER_API_KEY=sk-or-...
LLM_MODEL=moonshotai/kimi-k2.6
TELEGRAM_BOT_TOKEN=123456:...
TELEGRAM_ALLOWED_USERS=123456789
TELEGRAM_HOME_CHANNEL=123456789
```

Useful optional variables:

```env
GITHUB_TOKEN=github_pat_...
HERMES_YOLO_MODE=true
```

The seeded Hermes config starts with OpenRouter-compatible defaults. `TELEGRAM_ALLOWED_USERS` is the comma-separated list of Telegram users allowed to use the agent, and `TELEGRAM_HOME_CHANNEL` is used for cron/default outbound Telegram delivery.

`LLM_MODEL` is a first-run bootstrap value so Hermes can start working immediately. After `/data/.hermes/config.yaml` exists on the mounted volume, the persisted Hermes config carries the selected model.

### Railway Variables Reference

Add these directly in Railway Variables as needed.

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENROUTER_API_KEY` | Yes | OpenRouter API key for the default template path. |
| `LLM_MODEL` | First run | Model slug Hermes should use on first boot, for example `moonshotai/kimi-k2.6` with OpenRouter. |
| `TELEGRAM_BOT_TOKEN` | Yes | Telegram bot token from BotFather. |
| `TELEGRAM_ALLOWED_USERS` | Yes | Comma-separated Telegram user IDs allowed to use the agent. |
| `TELEGRAM_HOME_CHANNEL` | Yes | Default Telegram chat/channel for cron and outbound delivery. |
| `GITHUB_TOKEN` | Optional | GitHub token for higher rate limits and GitHub tooling. |
| `EXA_API_KEY` | Optional | Exa web search integration. |
| `FIRECRAWL_API_KEY` | Optional | Firecrawl web scraping integration. |
| `PARALLEL_API_KEY` | Optional | Parallel web search integration. |
| `FAL_KEY` | Optional | FAL image generation integration. |
| `HONCHO_API_KEY` | Optional | Honcho cross-session user modeling. |
| `BROWSERBASE_API_KEY` | Optional | Browserbase browser automation. |
| `BROWSERBASE_PROJECT_ID` | Optional | Browserbase project identifier. |
| `GATEWAY_ALLOW_ALL_USERS` | Optional | Set to `true` to allow all users, or keep unset/false and use allowlists. |
| `TERMINAL_ENV` | Optional | Terminal backend. Typical values: `local`, `docker`, `modal`, `ssh`. |
| `TERMINAL_TIMEOUT` | Optional | Terminal command timeout in seconds. |
| `OPENAI_API_KEY` | Optional | Direct OpenAI provider key if you customize Hermes away from the default OpenRouter path. |
| `ANTHROPIC_API_KEY` | Optional | Direct Anthropic provider key if you customize Hermes away from the default OpenRouter path. |
| `HERMES_INFERENCE_PROVIDER` | Optional | Provider override, such as `openrouter`, `anthropic`, or `openai-codex`. |
| `HERMES_YOLO_MODE` | Optional | Set to `true` in Railway Variables to bypass approval prompts. |

## Deploying to Railway

1. Click the Deploy on Railway button.
2. Set your Hermes environment variables.
3. Attach a volume mounted at `/data` so `/data/.hermes` survives redeploys.
4. Deploy the service. It runs as a worker process, not as an HTTP web app.

## Running Locally

```bash
docker build -t hermes-agent .
docker run --rm -it \
  -e OPENROUTER_API_KEY=sk-or-... \
  -e LLM_MODEL=moonshotai/kimi-k2.6 \
  -e TELEGRAM_BOT_TOKEN=123456:... \
  -e TELEGRAM_ALLOWED_USERS=123456789 \
  -v hermes-data:/data \
  hermes-agent
```

To run another Hermes CLI command with the same image:

```bash
docker run --rm -it -v hermes-data:/data hermes-agent hermes --help
```

## Credits

- [Hermes Agent](https://github.com/NousResearch/hermes-agent) by [Nous Research](https://nousresearch.com/)
