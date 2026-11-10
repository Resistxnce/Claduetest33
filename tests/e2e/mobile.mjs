/**
 * Touch-device end-to-end test: iPad and phone viewports (both orientations)
 * with emulated touch. Covers the main-thread audio fallback used when
 * AudioWorklet is unavailable (plain http on the local network), the
 * full-screen play mode, touch target sizes, multi-touch and that sound
 * actually comes out.
 */
import { startServer, launchBrowser, assert } from './lib.mjs';
import { qrMatrix } from '../../src/ui/qr.js';
import { mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const outDir = resolve(fileURLToPath(new URL('.', import.meta.url)), 'output');
mkdirSync(outDir, { recursive: true });

const DEVICES = [
  // audio: 'script' = forced with ?audio=script, 'no-worklet' = AudioWorklet removed (what an insecure http origin looks like)
  { name: 'ipad-landscape', width: 1180, height: 820, scale: 2, audio: 'no-worklet', minSpacing: 40, expectVertical: false },
  { name: 'ipad-portrait', width: 820, height: 1180, scale: 2, audio: 'worklet', minSpacing: 40, expectVertical: false },
  { name: 'phone-portrait', width: 390, height: 844, scale: 3, audio: 'script', minSpacing: 30, expectVertical: true },
  { name: 'phone-landscape', width: 844, height: 390, scale: 3, audio: 'no-worklet', minSpacing: 30, expectVertical: false, autoPlayMode: true },
];

const server = await startServer(8129);
const browser = await launchBrowser();
try {
  for (const device of DEVICES) {
    const errors = [];
    const context = await browser.newContext({ viewport: { width: device.width, height: device.height }, deviceScaleFactor: device.scale, hasTouch: true, isMobile: true });
    if (device.audio === 'no-worklet') {
      await context.addInitScript(() => {
        // An insecure origin (http://192.168.x.x) has no AudioWorklet.
        Object.defineProperty(BaseAudioContext.prototype, 'audioWorklet', { get() { return undefined; }, configurable: true });
      });
    }
    const page = await context.newPage();
    page.on('console', (m) => { if (m.type() === 'error') { errors.push(m.text()); console.log(`[${device.name} console]`, m.text()); } });
    page.on('pageerror', (e) => { errors.push(e.message); console.log(`[${device.name} pageerror]`, e.message); });
    await page.goto(`${server.url}/?nosw${device.audio === 'script' ? '&audio=script' : ''}`);
    await page.waitForFunction(() => window.__guitar && window.__guitar.canvas.layout);

    // Power on with a real tap
    await page.touchscreen.tap(device.width / 2, device.height / 2);
    await page.waitForFunction(() => window.__guitar.engine.ready);
    await page.waitForTimeout(700);
    const info = await page.evaluate(() => {
      const g = window.__guitar, c = g.canvas, L = c.layout;
      return {
        backend: g.engine.backend, ctxState: g.engine.ctx.state, coarse: matchMedia('(pointer: coarse)').matches,
        orientation: c.orientation, playMode: document.body.classList.contains('play-mode'),
        spacing: +L.spacing.toFixed(1), fret1: +L.cellWidth(1).toFixed(1), fret12: +L.cellWidth(12).toFixed(1), fret24: +L.cellWidth(24).toFixed(1),
        pannable: c.pannable, stage: (() => { const r = document.getElementById('stage').getBoundingClientRect(); return [Math.round(r.width), Math.round(r.height)]; })(),
        overflowX: document.documentElement.scrollWidth - window.innerWidth,
      };
    });
    console.log(`${device.name}:`, JSON.stringify(info));
    assert(info.ctxState === 'running', `${device.name}: audio context should be running`);
    assert(info.backend === (device.audio === 'worklet' ? 'worklet' : 'script'), `${device.name}: expected ${device.audio} backend, got ${info.backend}`);
    assert((info.orientation === 'vertical') === device.expectVertical, `${device.name}: orientation ${info.orientation}`);
    assert(info.spacing >= device.minSpacing, `${device.name}: string spacing ${info.spacing} px is too small for fingers`);
    assert(info.coarse && info.fret24 >= 30, `${device.name}: the 24th fret is ${info.fret24} px wide — too small for a finger`);
    assert(info.fret12 >= 30, `${device.name}: fret 12 is only ${info.fret12} px wide`);
    assert(info.overflowX <= 0, `${device.name}: page overflows horizontally by ${info.overflowX} px`);
    if (device.autoPlayMode) assert(info.playMode, `${device.name}: a phone held sideways should start in play mode`);

    const cdp = await context.newCDPSession(page);
    const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points.map((pt, i) => ({ x: pt.x, y: pt.y, id: i + 1 })) });
    const pos = async (string, fret) => {
      const box = await page.locator('#guitar').boundingBox();
      const p = await page.evaluate(([s, f]) => { window.__guitar.canvas.ensureFretsVisible(Math.max(0, f - 1), f); return window.__guitar.canvas.positionCenterScreen(s, f); }, [string, fret]);
      return { x: box.x + p.x, y: box.y + p.y };
    };
    const tapNote = async (string, fret) => {
      await page.evaluate(() => { window.__guitar.state.recent.length = 0; });
      const p = await pos(string, fret);
      await touch('touchStart', [p]);
      await page.waitForTimeout(50);
      await touch('touchEnd', []);
      return page.evaluate(() => { const r = window.__guitar.state.recent; return r.length ? { name: r[r.length - 1].name, count: r.length } : null; });
    };

    // Single taps across the neck, including the open strings and the last fret
    for (const [string, fret, expected] of [[0, 0, 'E2'], [0, 3, 'G2'], [2, 7, 'A3'], [4, 12, 'B4'], [5, 24, 'E6'], [1, 17, 'D4']]) {
      const got = await tapNote(string, fret);
      assert(got && got.name === expected && got.count === 1, `${device.name}: string ${6 - string} fret ${fret} should play ${expected} once, got ${JSON.stringify(got)}`);
    }

    // Sound really comes out (through whichever backend is running)
    const p5 = await pos(1, 5);
    await touch('touchStart', [p5]);
    let level = 0;
    for (let i = 0; i < 12 && level < 0.004; i++) { await page.waitForTimeout(50); level = Math.max(level, await page.evaluate(() => window.__guitar.engine.getLevel())); }
    await touch('touchEnd', []);
    console.log(`${device.name}: output level after a tap ${level.toFixed(4)}`);
    assert(level >= 0.004, `${device.name}: no audio output (level ${level})`);

    // Three fingers at once: an A minor triad shape near the nut
    await page.evaluate(() => { window.__guitar.canvas.setScroll(0); window.__guitar.state.recent.length = 0; });
    const chord = [await pos(2, 2), await pos(3, 2), await pos(4, 1)];
    await touch('touchStart', [chord[0]]);
    await touch('touchStart', [chord[0], chord[1]]);
    await touch('touchStart', chord);
    await page.waitForTimeout(80);
    const held = await page.evaluate(() => ({ fingers: window.__guitar.state.fingers.size, notes: [2, 3, 4].map((s) => window.__guitar.state.noteOn(s).name) }));
    await touch('touchEnd', []);
    assert(held.fingers === 3 && held.notes.join(' ') === 'E3 A3 C4', `${device.name}: three-finger chord, got ${JSON.stringify(held)}`);

    await page.screenshot({ path: `${outDir}/m-${device.name}.png` });

    // Play mode: the neck fills the screen and stays playable
    if (!info.playMode) {
      const btn = await page.locator('#play-mode-btn').boundingBox();
      await page.touchscreen.tap(btn.x + btn.width / 2, btn.y + btn.height / 2);
      await page.waitForTimeout(350);
    }
    const play = await page.evaluate(() => {
      const c = window.__guitar.canvas, r = document.getElementById('stage').getBoundingClientRect();
      return { on: document.body.classList.contains('play-mode'), stage: [Math.round(r.width), Math.round(r.height)], spacing: +c.layout.spacing.toFixed(1), orientation: c.orientation, dockVisible: getComputedStyle(document.querySelector('.dock')).display !== 'none' };
    });
    console.log(`${device.name} play mode:`, JSON.stringify(play));
    assert(play.on && !play.dockVisible, `${device.name}: play mode should hide the panels`);
    assert(play.stage[0] >= device.width - 1 && play.stage[1] >= device.height - 1, `${device.name}: play mode should fill the screen, stage is ${play.stage}`);
    assert(play.spacing >= info.spacing - 0.5 && play.spacing >= device.minSpacing, `${device.name}: play mode spacing ${play.spacing}`);
    assert(play.orientation === (device.height > device.width ? 'vertical' : 'horizontal'), `${device.name}: in play mode the neck runs along the long side`);
    const inPlay = await tapNote(3, 9);
    assert(inPlay && inPlay.name === 'E4', `${device.name}: tap in play mode should play E4, got ${JSON.stringify(inPlay)}`);
    // Toolbar strum works in play mode
    await page.evaluate(() => { window.__guitar.state.recent.length = 0; });
    const strum = await page.locator('#tool-strum-down').boundingBox();
    await page.touchscreen.tap(strum.x + strum.width / 2, strum.y + strum.height / 2);
    await page.waitForTimeout(250);
    const strummed = await page.evaluate(() => window.__guitar.state.recent.map((n) => n.name).join(' '));
    assert(strummed === 'E2 A2 D3 G3 B3 E4', `${device.name}: toolbar strum, got ${strummed}`);
    await page.screenshot({ path: `${outDir}/m-${device.name}-play.png` });
    // Leave play mode again
    const exit = await page.locator('#play-mode-btn').boundingBox();
    await page.touchscreen.tap(exit.x + exit.width / 2, exit.y + exit.height / 2);
    await page.waitForTimeout(250);
    assert(!(await page.evaluate(() => document.body.classList.contains('play-mode'))), `${device.name}: play mode should toggle off`);

    assert(errors.length === 0, `${device.name}: console errors: ${errors.join(' | ')}`);
    await context.close();
  }

  // If a script cannot load (blocked connection, old browser) the start card says so instead of ignoring taps
  {
    const context = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true });
    const broken = await context.newPage();
    await broken.route('**/src/ui/knob.js', (route) => route.abort());
    await broken.goto(`${server.url}/?nosw`);
    await broken.waitForFunction(() => /could not start here/.test(document.getElementById('start-error').textContent), null, { timeout: 12000 });
    const message = await broken.textContent('#start-error');
    assert(/could not load/.test(message) && !(await broken.evaluate(() => !!window.__guitar)), `a failed start is explained on the page: ${message}`);
    const box = await broken.locator('#start-error').boundingBox();
    assert(box && box.width > 100 && box.x >= 0 && box.x + box.width <= 390, 'the explanation is visible inside the start card');
    console.log('start-up watchdog:', message);
    await context.close();
  }

  // The manifest and service worker are served and valid
  const page = await (await browser.newContext()).newPage();
  const manifest = await (await page.request.get(`${server.url}/manifest.webmanifest`)).json();
  assert(manifest.display === 'standalone' && manifest.icons.length >= 2, 'web app manifest');
  for (const icon of manifest.icons) assert((await page.request.get(`${server.url}/${icon.src}`)).ok(), `icon ${icon.src}`);
  assert((await page.request.get(`${server.url}/icons/apple-touch-icon.png`)).ok(), 'apple touch icon');
  await page.goto(`${server.url}/`);
  await page.waitForFunction(() => navigator.serviceWorker && navigator.serviceWorker.controller !== undefined);
  const sw = await page.evaluate(async () => { const reg = await navigator.serviceWorker.ready; return !!reg.active; });
  assert(sw, 'service worker should activate on localhost');
  const lan = await (await page.request.get(`${server.url}/__lan.json`)).json();
  assert(Array.isArray(lan.urls), 'the dev server reports its LAN addresses');
  // The server is reachable by every device on the network: dot-files stay private
  for (const secret of ['/.git/HEAD', '/.git/config', '/.gitignore', '/.cert/key.pem', '/src/../.git/HEAD', '/.github/workflows/ci.yml']) {
    const status = (await page.request.get(`${server.url}${secret}`)).status();
    assert(status === 404, `${secret} must not be served (got ${status})`);
  }
  assert((await page.request.get(`${server.url}/src/main.js`)).ok() && (await page.request.get(`${server.url}/`)).ok(), 'normal files are still served');

  // On the computer the help dialog shows the device address with a QR code that encodes exactly that address
  await page.setViewportSize({ width: 1280, height: 800 });
  await page.waitForFunction((expected) => document.getElementById('device-link').hidden !== expected, lan.urls.length > 0);
  if (lan.urls.length) {
    await page.click('#start-overlay');
    await page.click('#help-btn');
    assert(await page.evaluate(() => document.getElementById('help').scrollTop) === 0, 'help opens at the top');
    await page.keyboard.press('Escape');
    await page.click('#device-btn');
    const shown = await page.evaluate(() => {
      const canvas = document.getElementById('device-qr');
      const g = canvas.getContext('2d');
      const scale = 4, quiet = 3;
      const size = canvas.width / scale - quiet * 2;
      const rows = [];
      for (let r = 0; r < size; r++) {
        let row = '';
        for (let c = 0; c < size; c++) row += g.getImageData((c + quiet) * scale + 1, (r + quiet) * scale + 1, 1, 1).data[0] < 128 ? '1' : '0';
        rows.push(row);
      }
      const corner = g.getImageData(1, 1, 1, 1).data[0];
      const box = canvas.getBoundingClientRect();
      const dialog = document.getElementById('help').getBoundingClientRect();
      return { url: document.getElementById('device-url').textContent, rows, corner, visible: box.width > 100 && box.top >= dialog.top && box.bottom <= dialog.bottom + 1, note: document.getElementById('device-note').textContent };
    });
    assert(shown.url === lan.urls[0], `help shows the device address (${shown.url})`);
    assert(shown.visible && shown.corner === 255, 'the QR code is visible inside the help dialog with a white quiet zone');
    assert(shown.note.length > 10, 'the help explains http vs https');
    const expected = qrMatrix(lan.urls[0]).modules.map((row) => row.map((m) => (m ? '1' : '0')).join(''));
    assert(JSON.stringify(shown.rows) === JSON.stringify(expected), 'the drawn QR code encodes the device address');
    await page.screenshot({ path: `${outDir}/help-device-qr.png` });
    console.log(`help dialog QR for ${shown.url}: ok`);
  }
  console.log('manifest, icons, service worker and LAN endpoint: ok');

  console.log('\nMOBILE TESTS PASSED');
} finally {
  await browser.close();
  server.stop();
}
