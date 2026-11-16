# Thin wrapper around the official prebuilt OpenClaw image.
# Building OpenClaw from source is too heavy for Render's free plan (512 MB RAM).
# Pin a stable release; bump the tag to update.
FROM ghcr.io/openclaw/openclaw:2026.11.3

USER root
# Render dockerCommand replaces ENTRYPOINT, so the official CLI path itself
# must start the public proxy. Keep the original CLI next to the wrapper.
COPY render-proxy.mjs openclaw-wrapper.mjs start.sh /app/
RUN mv /app/openclaw.mjs /app/openclaw.official.mjs \
  && mv /app/openclaw-wrapper.mjs /app/openclaw.mjs \
  && chmod 755 /app/start.sh /app/render-proxy.mjs /app/openclaw.mjs /app/openclaw.official.mjs \
  && chown node:node /app/start.sh /app/render-proxy.mjs /app/openclaw.mjs /app/openclaw.official.mjs
USER node

# Keep the Node heap inside the 512 MB free-plan limit (leave room for the OS and proxy).
ENV NODE_OPTIONS="--max-old-space-size=256"

# Public HTTP port for Render. The gateway itself listens on loopback:18789
# and is reached through the tiny proxy in render-proxy.mjs.
ENV OPENCLAW_GATEWAY_PORT=18789
ENV PORT=8080
EXPOSE 8080

# Do not set OPENCLAW_STATE_DIR / OPENCLAW_WORKSPACE_DIR to /data.
# Free instances cannot attach a disk, and an unmounted /data is not writable
# by the image's non-root `node` user. State uses the image defaults under
# /home/node and is discarded on every deploy, restart, and free-plan spin-down.

# --allow-unconfigured lets a fresh instance start before the user finishes onboarding.
ENTRYPOINT ["tini", "-s", "--", "node", "/app/docker-entrypoint.mjs"]
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
