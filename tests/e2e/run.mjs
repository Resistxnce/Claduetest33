// Runs every end-to-end suite in sequence and fails on the first error.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const dir = resolve(fileURLToPath(new URL('.', import.meta.url)));
const suites = ['ui.mjs', 'audio-pitch.mjs'];
for (const suite of suites) {
  console.log(`\n=== ${suite} ===`);
  const code = await new Promise((res) => {
    const child = spawn(process.execPath, [resolve(dir, suite)], { stdio: 'inherit' });
    child.on('exit', res);
  });
  if (code !== 0) { console.error(`${suite} failed with exit code ${code}`); process.exit(code || 1); }
}
console.log('\nALL E2E SUITES PASSED');
