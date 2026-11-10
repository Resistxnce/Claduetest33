import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

// Playwright is pre-installed globally in the test environment (and may be a
// local dependency elsewhere); resolve it through CommonJS so both work.
const require = createRequire(import.meta.url);
let chromium;
try {
  ({ chromium } = require('playwright'));
} catch {
  throw new Error('The end-to-end tests need Playwright: npm install --no-save playwright && npx playwright install chromium');
}

const root = resolve(fileURLToPath(new URL('../..', import.meta.url)));

/**
 * Start the dev server on `port` (shifted by E2E_PORT_OFFSET, so two runs on one
 * machine do not collide) and wait for its banner.
 */
export async function startServer(port = 8123) {
  port += Number(process.env.E2E_PORT_OFFSET || 0);
  const child = spawn(process.execPath, [resolve(root, 'tools/serve.mjs')], { env: { ...process.env, PORT: String(port) }, stdio: ['ignore', 'pipe', 'pipe'] });
  let errors = '';
  await new Promise((res, rej) => {
    const timer = setTimeout(() => { child.kill(); rej(new Error(`the dev server did not start on port ${port} within 10 s ${errors}`)); }, 10000);
    child.stdout.on('data', (d) => { if (String(d).includes('served')) { clearTimeout(timer); res(); } });
    child.stderr.on('data', (d) => { errors += String(d); process.stderr.write(d); });
    child.on('exit', (code) => { clearTimeout(timer); rej(new Error(`the dev server exited with code ${code} ${errors}`)); });
  });
  return { child, url: `http://localhost:${port}`, stop: () => child.kill() };
}

export async function launchBrowser(opts = {}) {
  const browser = await chromium.launch({
    args: ['--autoplay-policy=no-user-gesture-required'],
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
