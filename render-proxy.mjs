#!/usr/bin/env node
// Tiny reverse proxy so Render can detect an open public port immediately.
// The OpenClaw gateway starts slowly on the free plan (512 MB) and binds
// loopback only; this process listens on 0.0.0.0:$PORT and forwards to it.
import http from "node:http";
import net from "node:net";

const listenPort = Number(process.env.PORT || 8080);
const targetPort = Number(process.env.OPENCLAW_GATEWAY_PORT || 18789);
const targetHost = "127.0.0.1";

function gatewayRequest(req) {
  const headers = { ...req.headers };
  // Gateway is loopback-only; a public Host / forwarded chain can make it
  // reject the request as a non-local or untrusted-proxy call.
  for (const key of Object.keys(headers)) {
    if (key.toLowerCase().startsWith("x-forwarded-")) delete headers[key];
  }
  headers.host = `${targetHost}:${targetPort}`;
  return {
    hostname: targetHost,
    port: targetPort,
    path: req.url,
    method: req.method,
    headers,
  };
}

function serviceUnavailable(res) {
  if (res.headersSent) return;
  res.writeHead(503, {
    "content-type": "text/plain; charset=utf-8",
    "retry-after": "5",
  });
  res.end("OpenClaw gateway is starting. Retry in a few seconds.\n");
}

const server = http.createServer((req, res) => {
  const proxyReq = http.request(gatewayRequest(req), (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });
  proxyReq.on("error", () => serviceUnavailable(res));
  req.pipe(proxyReq);
});

server.on("upgrade", (req, socket, head) => {
  const dest = net.connect(targetPort, targetHost, () => {
    const headers = { ...req.headers };
    for (const key of Object.keys(headers)) {
      if (key.toLowerCase().startsWith("x-forwarded-")) delete headers[key];
    }
    headers.host = `${targetHost}:${targetPort}`;
    const lines = [`${req.method} ${req.url} HTTP/${req.httpVersion}`];
    for (const [key, value] of Object.entries(headers)) {
      if (value === undefined) continue;
      const rendered = Array.isArray(value) ? value.join(", ") : String(value);
      lines.push(`${key}: ${rendered}`);
    }
    dest.write(lines.join("\r\n") + "\r\n\r\n");
    if (head.length) dest.write(head);
    dest.pipe(socket);
    socket.pipe(dest);
  });
  dest.on("error", () => socket.destroy());
  socket.on("error", () => dest.destroy());
});

server.listen(listenPort, "0.0.0.0", () => {
  console.log(
    `[render-proxy] listening on 0.0.0.0:${listenPort} -> ${targetHost}:${targetPort}`,
  );
});
