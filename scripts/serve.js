/* ============================================================
   Lume — local static server

   ES modules are fetched, not read, so the app no longer opens
   from file://. A browser refuses a module script on that
   origin outright. `npm run serve` is the supported way to run
   it locally, and it is dependency-free on purpose: the project
   ships nothing at runtime, and it should not need anything to
   be looked at either.
   ============================================================ */
const fs = require('fs');
const path = require('path');
const http = require('http');

const ROOT = path.resolve(__dirname, '..');
const PORT = Number(process.env.PORT) || 8080;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2'
};

const server = http.createServer((req, res) => {
  const rel = decodeURIComponent(req.url.split('?')[0]).replace(/^\/+/, '') || 'index.html';
  const file = path.join(ROOT, rel);

  /* Nothing above the project root is servable, however the path is spelt. */
  if (!file.startsWith(ROOT + path.sep) && file !== path.join(ROOT, 'index.html')) {
    res.writeHead(403); res.end('forbidden'); return;
  }
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404, { 'Content-Type': 'text/plain' }); res.end('not found: /' + rel); return;
  }

  res.writeHead(200, {
    'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream',
    'Cache-Control': 'no-cache'
  });
  res.end(fs.readFileSync(file));
});

/* A port already in use is an ordinary thing to happen — usually another
   copy of this server — and deserves an answer rather than a stack trace. */
server.on('error', err => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      'Port ' + PORT + ' is already in use.\n' +
      'Either something else is serving it — try http://localhost:' + PORT + '/ —\n' +
      'or pick another: PORT=8081 npm run serve'
    );
    process.exit(1);
  }
  throw err;
});

server.listen(PORT, () => {
  console.log('Lume is running at http://localhost:' + PORT + '/');
  console.log('Press Ctrl+C to stop.');
});
