#!/bin/sh
# Used only when the image ENTRYPOINT is honored. Render's current
# dockerCommand runs `node openclaw.mjs ...` directly, so the wrapper at
# /app/openclaw.mjs is the path that matters.
set -e
exec tini -s -- node /app/docker-entrypoint.mjs "$@"
