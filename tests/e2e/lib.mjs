import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

// Playwright is pre-installed globally in the test environment (and may be a
// local dependency elsewhere); resolve it through CommonJS so both work.
const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const root = resolve(fileURLToPath(new URL('../..', import.meta.url)));

export async function startServer(port = 8123) {
  const child = spawn(process.execPath, [resolve(root, 'tools/serve.mjs')], { env: { ...process.env, PORT: String(port) }, stdio: ['ignore', 'pipe', 'pipe'] });
  await new Promise((res, rej) => {
    child.stdout.on('data', (d) => { if (String(d).includes('served')) res(); });
    child.stderr.on('data', (d) => process.stderr.write(d));
    child.on('exit', (code) => rej(new Error(`server exited ${code}`)));
    setTimeout(() => res(), 1500);
  });
  return { child, url: `http://localhost:${port}`, stop: () => child.kill() };
}

export async function launchBrowser(opts = {}) {
  const browser = await chromium.launch({
    args: ['--autoplay-policy=no-user-gesture-required', '--use-fake-ui-for-media-stream', '--enable-features=SharedArrayBuffer'],
    ...opts,
  });
  return browser;
}

export function assert(cond, msg) {
  if (!cond) throw new Error(`Assertion failed: ${msg}`);
}

export function cents(a, b) {
  return 1200 * Math.log2(a / b);
}
