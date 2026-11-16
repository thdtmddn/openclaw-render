# OpenClaw on Render (free plan)

Install-only deployment of [OpenClaw](https://github.com/openclaw/openclaw) on Render's free plan. This repository is a thin Docker wrapper around the official prebuilt image (`ghcr.io/openclaw/openclaw:2026.11.3`). It does not build OpenClaw from source.

Official guide: [Deploy on Render](https://docs.openclaw.ai/install/render)

## Why this wrapper exists

Render's free plan has 512 MB RAM and cannot attach a persistent disk. The upstream Blueprint defaults to a paid plan plus a disk, and building the official Dockerfile from source can run out of memory. This image only pulls the official container and starts the gateway with `--allow-unconfigured` so you can finish first-time setup yourself.

## Caveats

- **No persistent disk.** Config, sessions, and workspace files live under the image defaults in `/home/node` and are lost on every deploy, restart, and free-plan spin-down (after about 15 minutes idle).
- **Cold starts.** After spin-down, the first request can take a while while the container starts.
- **Memory.** 512 MB is below Render's documented recommended minimum for OpenClaw (`2c-4g`). The Node heap is capped at 256 MB. If the process is killed, upgrade the plan or add a disk on a paid instance.
- **Do not set `OPENCLAW_STATE_DIR` to `/data`** on the free plan. That path is not writable without a mounted disk.

## Environment

Set these in the Render Dashboard (Environment):

- `OPENCLAW_GATEWAY_TOKEN` — shared secret for the Control UI (required)
- `OPENCLAW_GATEWAY_PORT=8080` and `PORT=8080`
- `NODE_OPTIONS=--max-old-space-size=256`

## First-time setup

1. Open the service URL.
2. Paste `OPENCLAW_GATEWAY_TOKEN` from **Dashboard → Environment**.
3. Complete onboarding in the Control UI (model provider API key, then channels such as Telegram or Discord).

Docs:

- [Control UI](https://docs.openclaw.ai/web/control-ui)
- [Onboarding wizard](https://docs.openclaw.ai/start/wizard)
- [Channels](https://docs.openclaw.ai/channels)
- [Gateway configuration](https://docs.openclaw.ai/gateway/configuration)
