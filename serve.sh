#!/usr/bin/env bash
# Start this folder as a local web server with Node.js.
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
port="${1:-8080}"

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required. Install it from https://nodejs.org/ and run this again." >&2
  exit 1
fi

if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "Usage: ./serve.sh [port]" >&2
  exit 1
fi

echo "Serving $script_dir"
echo "Open http://localhost:$port"
echo "Press Ctrl+C to stop."

cd "$script_dir"
node -e '
const http = require("http");
const fs = require("fs");
const path = require("path");
const root = process.cwd();
const port = Number(process.argv[1]);
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8", ".json": "application/json; charset=utf-8", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".ico": "image/x-icon" };

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent((req.url || "/").split("?")[0]);
  const requested = urlPath === "/" ? "/index.html" : urlPath;
  const file = path.resolve(root, "." + requested);
  if (!file.startsWith(root + path.sep)) { res.writeHead(403); return res.end("Forbidden"); }
  fs.stat(file, (err, stat) => {
    if (err || !stat.isFile()) { res.writeHead(404); return res.end("Not found"); }
    res.writeHead(200, { "Content-Type": types[path.extname(file).toLowerCase()] || "application/octet-stream", "Cache-Control": "no-store" });
    fs.createReadStream(file).pipe(res);
  });
});
server.on("error", err => {
  console.error("Could not start the server: " + err.message);
  process.exit(1);
});
server.listen(port, "127.0.0.1", () => console.log("Server ready."));
' "$port"
