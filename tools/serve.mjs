// Minimal dependency-free static file server for local development, tests and
// for playing on a phone or tablet on the same network.
//
//   node tools/serve.mjs              http on port 8080 (PORT or first argument overrides)
//   node tools/serve.mjs --https      https with a self-signed certificate on port 8443
//   node tools/serve.mjs --no-qr      do not print the QR code for the device address
//
// Over plain http a phone gets the main-thread audio backend (browsers only allow
// AudioWorklet and "Add to Home Screen" offline support on https or localhost);
// --https unlocks both after accepting the certificate warning once on the device.
import http from 'node:http';
import https from 'node:https';
import { execFileSync } from 'node:child_process';
import { createReadStream, existsSync, mkdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { qrToTerminal } from '../src/ui/qr.js';
import { lanAddresses } from './lan.mjs';

const root = resolve(fileURLToPath(new URL('..', import.meta.url)));
const args = process.argv.slice(2);
const useHttps = args.includes('--https');
const showQr = !args.includes('--no-qr') && (args.includes('--qr') || process.stdout.isTTY);
const portArg = args.find((a) => /^\d+$/.test(a));
const port = Number(process.env.PORT || portArg || (useHttps ? 8443 : 8080));

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.webmanifest': 'application/manifest+json',
  '.wav': 'audio/wav',
};

const scheme = useHttps ? 'https' : 'http';
const lanUrls = () => lanAddresses().map((ip) => `${scheme}://${ip}:${port}/`);

function handler(req, res) {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);
  let pathname;
  try { pathname = decodeURIComponent(url.pathname); } catch { res.writeHead(400); res.end('Bad request'); return; }
  if (pathname === '/__lan.json') {
    res.writeHead(200, { 'Content-Type': MIME['.json'], 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ urls: lanUrls(), https: useHttps }));
    return;
  }
  if (pathname.endsWith('/')) pathname += 'index.html';
  const file = normalize(join(root, pathname));
  if (file !== root && !file.startsWith(root + '/') && !file.startsWith(root + '\\')) {
    res.writeHead(403); res.end('Forbidden'); return;
  }
  let st;
  try { st = statSync(file); } catch { res.writeHead(404); res.end('Not found'); return; }
  if (st.isDirectory()) { res.writeHead(301, { Location: pathname + '/' }); res.end(); return; }
  res.writeHead(200, {
    'Content-Type': MIME[extname(file)] || 'application/octet-stream',
    'Content-Length': st.size,
    'Cache-Control': 'no-cache',
  });
  if (req.method === 'HEAD') { res.end(); return; }
  createReadStream(file).pipe(res);
}

/** Create (once) a self-signed certificate valid for localhost and this machine's LAN addresses. */
function selfSignedCertificate() {
  const dir = join(root, '.cert');
  const key = join(dir, 'key.pem');
  const cert = join(dir, 'cert.pem');
  const names = ['DNS:localhost', 'IP:127.0.0.1', ...lanAddresses().map((ip) => `IP:${ip}`)];
  const stamp = join(dir, 'names.txt');
  const current = existsSync(stamp) ? readFileSync(stamp, 'utf8') : '';
  if (!existsSync(key) || !existsSync(cert) || current !== names.join(',')) {
    mkdirSync(dir, { recursive: true });
    try {
      execFileSync('openssl', [
        'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '365',
        '-keyout', key, '-out', cert,
        '-subj', '/CN=Electric Guitar Simulator (local)',
        '-addext', `subjectAltName=${names.join(',')}`,
      ], { stdio: 'ignore' });
      writeFileSync(stamp, names.join(','));
    } catch (err) {
      console.error('Could not create a certificate (is openssl installed?). Use plain http instead: npm start');
      console.error(String(err.message || err));
      process.exit(1);
    }
  }
  return { key: readFileSync(key), cert: readFileSync(cert) };
}

const server = useHttps ? https.createServer(selfSignedCertificate(), handler) : http.createServer(handler);

server.on('error', (err) => {
  console.error(err.code === 'EADDRINUSE' ? `Port ${port} is already in use. Try: PORT=${port + 1} npm start` : String(err));
  process.exit(1);
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Guitar simulator served at ${scheme}://localhost:${port}/`);
  const urls = lanUrls();
  if (urls.length) {
    console.log('\nOn a phone or iPad connected to the same Wi-Fi, open:');
    for (const u of urls) console.log(`  ${u}`);
    // A scannable code for the most likely address (only when a person is looking at the terminal).
    if (showQr) console.log(`\n${qrToTerminal(urls[0])}\n  Scan with the device's camera to open ${urls[0]}`);
    if (useHttps) console.log('\nThe certificate is self-signed: accept the browser warning once on the device.');
    else console.log('\nTip: "npm run start:https" serves over https (lower-latency audio and offline install on the device).');
  } else {
    console.log('\nNo local network address found (not connected to Wi-Fi?).');
  }
});
