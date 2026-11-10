/**
 * End-to-end UI test: loads the real page in Chromium, powers the amp on,
 * frets and picks with the mouse, strums, uses multi-touch, changes tuning
 * and checks the notes the simulator reports. Also saves screenshots.
 */
import { startServer, launchBrowser, assert } from './lib.mjs';
import { mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const outDir = resolve(fileURLToPath(new URL('.', import.meta.url)), 'output');
mkdirSync(outDir, { recursive: true });

const server = await startServer(8128);
const browser = await launchBrowser();
const errors = [];
try {
  const context = await browser.newContext({ viewport: { width: 1400, height: 860 }, deviceScaleFactor: 1, hasTouch: true });
  const page = await context.newPage();
  page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') { errors.push(m.text()); console.log('[console]', m.type(), m.text()); } });
  page.on('pageerror', (e) => { errors.push(e.message); console.log('[pageerror]', e.message); });
  await page.goto(`${server.url}/`);
  await page.waitForFunction(() => window.__guitar && window.__guitar.canvas.layout);
  await page.screenshot({ path: `${outDir}/01-start.png` });

  // Power on
  await page.click('#start-overlay');
  await page.waitForFunction(() => window.__guitar.engine.ready);
  await page.waitForTimeout(300);
  const ctxState = await page.evaluate(() => window.__guitar.engine.ctx.state);
  console.log('AudioContext state:', ctxState);
  await page.screenshot({ path: `${outDir}/02-desktop.png` });

  const desktopFrets = await page.evaluate(() => window.__guitar.canvas.fretCount);
  assert(desktopFrets === 24, `desktop should show 24 frets, got ${desktopFrets}`);
  const fret24 = await page.evaluate(() => window.__guitar.state.fretboard.noteNameAt(5, 24));
  assert(fret24 === 'E6', 'fret 24 on the high E is E6');
  const canvasBox = await page.locator('#guitar').boundingBox();
  const screenPos = async (string, fret) => {
    const p = await page.evaluate(([s, f]) => window.__guitar.canvas.positionCenterScreen(s, f), [string, fret]);
    return { x: canvasBox.x + p.x, y: canvasBox.y + p.y };
  };
  const lastNote = () => page.evaluate(() => { const r = window.__guitar.state.recent; return r.length ? r[r.length - 1] : null; });
  const recentNames = () => page.evaluate(() => window.__guitar.state.recent.map((n) => n.name));
  const clearRecent = () => page.evaluate(() => { window.__guitar.state.recent.length = 0; });

  // Fret + tap-to-play: low E, 3rd fret must be G2
  let p = await screenPos(0, 3);
  await page.mouse.move(p.x, p.y);
  await page.mouse.down();
  await page.waitForTimeout(80);
  let note = await lastNote();
  console.log('Pressed string 6 fret 3 ->', note && note.name, note && note.frequency.toFixed(2));
  assert(note && note.name === 'G2', `expected G2, got ${note && note.name}`);
  assert(Math.abs(note.frequency - 97.9989) < 0.01, 'G2 frequency');
  let fingers = await page.evaluate(() => window.__guitar.state.fingers.size);
  assert(fingers === 1, 'one finger down');
  // Slide to fret 5 (A2) while holding
  const p5 = await screenPos(0, 5);
  await page.mouse.move(p5.x, p5.y, { steps: 6 });
  await page.waitForTimeout(60);
  let sounding = await page.evaluate(() => window.__guitar.state.noteOn(0).name);
  console.log('Slid to fret 5 ->', sounding);
  assert(sounding === 'A2', `slide should sound A2, got ${sounding}`);
  await page.screenshot({ path: `${outDir}/03-fretting.png` });
  await page.mouse.up();
  fingers = await page.evaluate(() => window.__guitar.state.fingers.size);
  assert(fingers === 0, 'finger lifted');
  let stillRinging = await page.evaluate(() => window.__guitar.engine.stringState[0].ringing && Math.abs(window.__guitar.engine.stringState[0].frequency - 110) < 0.01);
  assert(stillRinging, 'tapped note should keep ringing at its own pitch (A2) after lifting');
  // Turn on fret-hand muting: lifting now mutes
  await page.evaluate(() => window.__guitar.state.setOption('releaseMutes', true));
  p = await screenPos(2, 2);
  await page.mouse.move(p.x, p.y);
  await page.mouse.down();
  await page.waitForTimeout(40);
  await page.mouse.up();
  await page.waitForTimeout(30);
  const mutedAfterLift = await page.evaluate(() => window.__guitar.engine.stringState[2].ringing === false);
  assert(mutedAfterLift, 'with "lifting mutes" on, the string is muted on release');
  await page.evaluate(() => window.__guitar.state.setOption('releaseMutes', false));

  // Strum open strings by sweeping down the open zone (top to bottom = low E to high E)
  await clearRecent();
  const strum = await page.evaluate(() => {
    const L = window.__guitar.canvas.layout;
    const c = window.__guitar.canvas;
    const a = c.toScreen(L.openW * 0.5, L.fbTop - 2);
    const b = c.toScreen(L.openW * 0.5, L.fbBottom + 2);
    return { a, b };
  });
  await page.mouse.move(canvasBox.x + strum.a.x, canvasBox.y + strum.a.y);
  await page.mouse.down();
  await page.mouse.move(canvasBox.x + strum.b.x, canvasBox.y + strum.b.y, { steps: 14 });
  await page.mouse.up();
  await page.waitForTimeout(120);
  let names = await recentNames();
  console.log('Swept open strings (top to bottom):', names.join(' '));
  // High E is the top string and low E the bottom one (tablature orientation).
  assert(names.join(' ') === 'E4 B3 G3 D3 A2 E2', `open sweep should be E4 B3 G3 D3 A2 E2, got ${names.join(' ')}`);
  const order = await page.evaluate(() => { const c = window.__guitar.canvas; return c.positionCenterScreen(5, 3).y < c.positionCenterScreen(0, 3).y; });
  assert(order, 'high E must be drawn above low E');

  // Tap an open string directly
  await clearRecent();
  const openB = await screenPos(4, 0);
  await page.mouse.click(openB.x, openB.y);
  await page.waitForTimeout(60);
  note = await lastNote();
  console.log('Tapped open B ->', note && note.name);
  assert(note && note.name === 'B3', `open tap should play B3, got ${note && note.name}`);

  // Sweep across the strings on the fretboard at fret 5 plays each string's 5th-fret note
  await clearRecent();
  const s5a = await screenPos(0, 5);
  const s5b = await screenPos(5, 5);
  await page.mouse.move(s5a.x, s5a.y);
  await page.mouse.down();
  await page.waitForTimeout(30);
  await page.mouse.move(s5b.x, s5b.y, { steps: 14 });
  await page.mouse.up();
  await page.waitForTimeout(120);
  names = await recentNames();
  console.log('Swept fret 5:', names.join(' '));
  assert(names.join(' ') === 'A2 D3 G3 C4 E4 A4', `fret-5 sweep should be A2 D3 G3 C4 E4 A4, got ${names.join(' ')}`);
  // With "lifting mutes" off, the swept notes keep ringing in the engine
  const ringing = await page.evaluate(() => window.__guitar.engine.stringState.filter((s) => s.ringing).length);
  assert(ringing === 6, `all six strings should still ring after the sweep, got ${ringing}`);

  // Keyboard: Space strums down (low to high)
  await clearRecent();
  await page.keyboard.press('Space');
  await page.waitForTimeout(200);
  names = await recentNames();
  console.log('Space strum:', names.join(' '));
  assert(names.join(' ') === 'E2 A2 D3 G3 B3 E4', `keyboard strum, got ${names.join(' ')}`);

  // Multi-touch: two fingers on different strings (A string fret 2 = B2, D string fret 2 = E3), then strum
  await clearRecent();
  const t1 = await screenPos(1, 2);
  const t2 = await screenPos(2, 2);
  const cdp = await context.newCDPSession(page);
  const touch = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points.map((pt, i) => ({ x: pt.x, y: pt.y, id: i + 1 })) });
  await touch('touchStart', [t1]);
  await touch('touchStart', [t1, t2]);
  await page.waitForTimeout(80);
  fingers = await page.evaluate(() => [...window.__guitar.state.fingers.values()]);
  console.log('Multi-touch fingers:', JSON.stringify(fingers));
  assert(fingers.length === 2, `two fingers expected, got ${fingers.length}`);
  const held = await page.evaluate(() => [window.__guitar.state.noteOn(1).name, window.__guitar.state.noteOn(2).name]);
  assert(held.join(' ') === 'B2 E3', `held notes should be B2 E3, got ${held.join(' ')}`);
  await clearRecent();
  await page.evaluate(() => window.__guitar.player.strum('down'));
  await page.waitForTimeout(250);
  names = await recentNames();
  console.log('Strum with two fingers held:', names.join(' '));
  assert(names.join(' ') === 'E2 B2 E3 G3 B3 E4', `expected E2 B2 E3 G3 B3 E4, got ${names.join(' ')}`);
  await page.screenshot({ path: `${outDir}/04-multitouch.png` });
  await touch('touchEnd', []);
  await page.waitForTimeout(50);
  fingers = await page.evaluate(() => window.__guitar.state.fingers.size);
  assert(fingers === 0, 'all touches lifted');

  // Tuning change updates everything
  await page.selectOption('#tuning-select', 'drop-d');
  const dropD = await page.evaluate(() => [0, 1, 2, 3, 4, 5].map((s) => window.__guitar.state.noteOn(s).name));
  console.log('Drop D open strings:', dropD.join(' '));
  assert(dropD.join(' ') === 'D2 A2 D3 G3 B3 E4', 'drop D tuning');
  const dropDFret3 = await page.evaluate(() => window.__guitar.state.fretboard.noteNameAt(0, 3));
  assert(dropDFret3 === 'F2', 'drop D low string fret 3 = F2');
  const engineFreq = await page.evaluate(() => window.__guitar.engine.stringState[0].frequency);
  assert(Math.abs(engineFreq - 73.4162) < 0.01, `engine retuned to D2, got ${engineFreq}`);
  await page.selectOption('#tuning-select', 'standard');

  // Chord library: select G major, hold, strum
  await page.click('[data-tab="chords"]');
  await page.click('#learning .root-picker .root-btn[data-pc="7"]');
  await page.waitForTimeout(50);
  const chordInfo = await page.evaluate(() => ({ name: window.__guitar.state.chord && window.__guitar.state.chordVoicing.frets.join(','), count: window.__guitar.state.chord.voicings.length }));
  console.log('G major voicing:', JSON.stringify(chordInfo));
  assert(chordInfo.count >= 2, 'G major has voicings');
  await page.click('#learning .btn.primary'); // strum chord (enables hold)
  await page.waitForTimeout(250);
  const chordNotes = await page.evaluate(() => [...new Set(window.__guitar.state.recent.slice(-6).map((n) => n.pitchClassName))].sort());
  console.log('Held G chord strummed notes:', chordNotes.join(' '));
  assert(chordNotes.every((n) => ['G', 'B', 'D'].includes(n)), 'all strummed notes belong to G major');
  await page.screenshot({ path: `${outDir}/05-chord.png` });
  await page.click('#learning .btn.ghost'); // clear

  // Scale overlay + note highlight render without errors
  await page.click('[data-tab="scales"]');
  await page.click('#learning [data-panel="scales"] .btn.primary');
  await page.waitForTimeout(100);
  await page.screenshot({ path: `${outDir}/06-scale.png` });
  await page.evaluate(() => window.__guitar.state.setScale(null));

  // Presets & knobs
  await page.click('[data-preset="distortion"]');
  const preset = await page.evaluate(() => ({ id: window.__guitar.engine.presetId, pickup: window.__guitar.engine.pickupPosition, gain: window.__guitar.engine.params.gain }));
  console.log('Preset:', JSON.stringify(preset));
  assert(preset.id === 'distortion' && preset.pickup === 1, 'distortion preset applied');
  await page.click('[data-preset="clean"]');

  // Mobile portrait
  await page.setViewportSize({ width: 390, height: 844 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  const mobile = await page.evaluate(() => { const c = window.__guitar.canvas; return { orientation: c.orientation, frets: c.fretCount, spacing: c.layout.spacing, pannable: c.pannable, fret12Cell: c.layout.cellWidth(12), navHidden: document.getElementById('neck-nav').hidden, lowELeft: c.positionCenterScreen(0, 3).x < c.positionCenterScreen(5, 3).x, nutTop: c.positionCenterScreen(0, 1).y < c.positionCenterScreen(0, 5).y }; });
  console.log('Mobile layout:', JSON.stringify(mobile));
  assert(mobile.orientation === 'vertical', 'portrait phone uses vertical layout');
  assert(mobile.frets === 24, 'all 24 frets exist on a phone');
  assert(mobile.pannable && !mobile.navHidden, 'the neck is zoomed and the minimap is shown on a phone');
  assert(mobile.spacing >= 26, `string spacing on a phone should be >= 26 px, got ${mobile.spacing}`);
  assert(mobile.fret12Cell >= 24, `fret 12 should be at least 24 px wide on a phone, got ${mobile.fret12Cell}`);
  assert(mobile.lowELeft && mobile.nutTop, 'vertical layout: nut at the top, low E on the left');
  await page.screenshot({ path: `${outDir}/07-mobile.png`, fullPage: false });
  const mBox = await page.locator('#guitar').boundingBox();
  const mp = await page.evaluate(() => window.__guitar.canvas.positionCenterScreen(5, 1));
  await clearRecent();
  await touch('touchStart', [{ x: mBox.x + mp.x, y: mBox.y + mp.y }]);
  await page.waitForTimeout(60);
  await touch('touchEnd', []);
  note = await lastNote();
  console.log('Mobile tap high E fret 1 ->', note && note.name);
  assert(note && note.name === 'F4', `mobile tap should play F4, got ${note && note.name}`);
  // Pan to the top of the neck with the minimap and tap fret 24 on the high E (E6).
  const navBox = await page.locator('#neck-nav').boundingBox();
  await touch('touchStart', [{ x: navBox.x + navBox.width / 2, y: navBox.y + navBox.height - 3 }]);
  await touch('touchEnd', []);
  await page.waitForTimeout(80);
  const panned = await page.evaluate(() => ({ scroll: window.__guitar.canvas.scroll, max: window.__guitar.canvas.maxScroll }));
  console.log('Minimap pan:', JSON.stringify(panned));
  assert(panned.max > 0 && Math.abs(panned.scroll - panned.max) < 1, 'minimap tap at the end scrolls to the last frets');
  const p24 = await page.evaluate(() => window.__guitar.canvas.positionCenterScreen(5, 24));
  await clearRecent();
  await touch('touchStart', [{ x: mBox.x + p24.x, y: mBox.y + p24.y }]);
  await page.waitForTimeout(60);
  await touch('touchEnd', []);
  note = await lastNote();
  console.log('Mobile tap high E fret 24 ->', note && note.name, note && note.frequency.toFixed(2));
  assert(note && note.name === 'E6' && Math.abs(note.frequency - 1318.51) < 0.01, `fret 24 should play E6, got ${note && note.name}`);
  await page.screenshot({ path: `${outDir}/08b-mobile-high-frets.png` });
  await page.evaluate(() => window.__guitar.canvas.setScroll(0));
  await page.screenshot({ path: `${outDir}/08-mobile-full.png`, fullPage: true });

  // Landscape phone
  await page.setViewportSize({ width: 844, height: 390 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  const land = await page.evaluate(() => ({ orientation: window.__guitar.canvas.orientation, frets: window.__guitar.canvas.fretCount, spacing: window.__guitar.canvas.layout.spacing }));
  console.log('Landscape phone layout:', JSON.stringify(land));
  await page.screenshot({ path: `${outDir}/09-landscape-phone.png` });

  assert(errors.length === 0, `console errors: ${errors.join(' | ')}`);
  console.log('\nUI TESTS PASSED');
} finally {
  await browser.close();
  server.stop();
}
