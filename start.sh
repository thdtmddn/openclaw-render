#!/bin/sh
set -e

# Fresh free-plan filesystems have no persistent disk. Write a minimal
# gateway config so the Control UI accepts the public Render origin and
# the gateway stays on loopback behind the proxy.
CONFIG="${HOME}/.openclaw/openclaw.json"
mkdir -p "${HOME}/.openclaw"

if [ ! -f "$CONFIG" ]; then
  origin=""
  if [ -n "$RENDER_EXTERNAL_URL" ]; then
    origin="$RENDER_EXTERNAL_URL"
  elif [ -n "$RENDER_EXTERNAL_HOSTNAME" ]; then
    origin="https://$RENDER_EXTERNAL_HOSTNAME"
  fi
  port="${OPENCLAW_GATEWAY_PORT:-18789}"
  if [ -n "$origin" ]; then
    printf '%s\n' "{
  \"gateway\": {
    \"mode\": \"local\",
    \"bind\": \"loopback\",
    \"port\": ${port},
    \"controlUi\": {
      \"allowInsecureAuth\": true,
      \"allowedOrigins\": [\"${origin}\"]
    }
  }
}" > "$CONFIG"
    echo "[start] wrote $CONFIG with allowedOrigins ${origin}"
  else
    printf '%s\n' "{
  \"gateway\": {
    \"mode\": \"local\",
    \"bind\": \"loopback\",
    \"port\": ${port},
    \"controlUi\": {
      \"allowInsecureAuth\": true
    }
  }
}" > "$CONFIG"
    echo "[start] wrote $CONFIG without a public origin (RENDER_EXTERNAL_URL unset)"
  fi
fi

node /app/render-proxy.mjs &

# Keep the official image entrypoint (doctor / bootstrap), then start the
# gateway on loopback. Extra flags are appended so a Render dockerCommand
# that only overrides CMD still binds correctly.
exec tini -s -- node /app/docker-entrypoint.mjs "$@" --bind loopback --port "${OPENCLAW_GATEWAY_PORT:-18789}"
