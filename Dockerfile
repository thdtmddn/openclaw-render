# Thin wrapper around the official prebuilt OpenClaw image.
# Building OpenClaw from source is too heavy for Render's free plan (512 MB RAM).
# Pin a stable release; bump the tag to update.
FROM ghcr.io/openclaw/openclaw:2026.11.3

# Keep the Node heap inside the 512 MB free-plan limit (leave room for the OS).
ENV NODE_OPTIONS="--max-old-space-size=256"

# Official gateway port. PORT must match so Render routes public HTTP traffic here.
ENV OPENCLAW_GATEWAY_PORT=8080
ENV PORT=8080
EXPOSE 8080

# Do not set OPENCLAW_STATE_DIR / OPENCLAW_WORKSPACE_DIR to /data.
# Free instances cannot attach a disk, and an unmounted /data is not writable
# by the image's non-root `node` user. State uses the image defaults under
# /home/node and is discarded on every deploy, restart, and free-plan spin-down.

# --allow-unconfigured lets a fresh instance start before the user finishes onboarding.
# The base image ENTRYPOINT (tini + docker-entrypoint.mjs) is preserved.
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured"]
