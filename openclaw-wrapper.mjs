#!/usr/bin/env node
// Runs when Render starts `node openclaw.mjs ...` (its dockerCommand
// replaces the image ENTRYPOINT). Start the public proxy first, write a
// minimal config on a fresh filesystem, then load the official CLI.
import { spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const gatewayPort = process.env.OPENCLAW_GATEWAY_PORT || "18789";
const configPath = path.join(os.homedir(), ".openclaw", "openclaw.json");

function publicOrigin() {
  if (process.env.RENDER_EXTERNAL_URL) return process.env.RENDER_EXTERNAL_URL;
  if (process.env.RENDER_EXTERNAL_HOSTNAME) {
    return `https://${process.env.RENDER_EXTERNAL_HOSTNAME}`;
  }
  return "";
}

function writeFreshConfig() {
  if (fs.existsSync(configPath)) return;
  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  const origin = publicOrigin();
  const controlUi = { allowInsecureAuth: true };
  if (origin) controlUi.allowedOrigins = [origin];
  const config = {
    gateway: {
      mode: "local",
      bind: "loopback",
      port: Number(gatewayPort),
      controlUi,
    },
  };
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`);
  console.log(
    `[start] wrote ${configPath}${origin ? ` with allowedOrigins ${origin}` : " without a public origin"}`,
  );
}

writeFreshConfig();

const proxy = spawn(process.execPath, ["/app/render-proxy.mjs"], {
  stdio: "inherit",
});
proxy.on("error", (err) => {
  console.error("[start] failed to start render-proxy:", err);
});

if (!process.argv.includes("--bind")) {
  process.argv.push("--bind", "loopback", "--port", String(gatewayPort));
}

await import("/app/openclaw.official.mjs");
