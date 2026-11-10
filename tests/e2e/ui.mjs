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
  // A desktop with a mouse; touch input is switched on only for the multi-touch and phone parts below.
  const context = await browser.newContext({ viewport: { width: 1400, height: 860 }, deviceScaleFactor: 1 });
  const watch = (pg) => {
    pg.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') { errors.push(m.text()); console.log('[console]', m.type(), m.text()); } });
    pg.on('pageerror', (e) => { errors.push(e.message); console.log('[pageerror]', e.message); });
  };
  let page = await context.newPage();
  watch(page);
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
  let canvasBox = await page.locator('#guitar').boundingBox();
  const desktop = await page.evaluate(() => ({ coarse: matchMedia('(pointer: coarse)').matches, pannable: window.__guitar.canvas.pannable }));
  assert(!desktop.coarse && !desktop.pannable, 'with a mouse the whole 24-fret neck fits the desktop window');
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
  const headline = (await page.textContent('#learning .np-note')).trim();
  assert(headline === 'A2', `the now-playing headline must follow a slide, got ${headline}`);
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
  // A fast sweep (pointer events skip strings) still plays every string once, in order
  await clearRecent();
  const s7a = await screenPos(5, 7);
  const s7b = await screenPos(0, 7);
  await page.mouse.move(s7a.x, s7a.y);
  await page.mouse.down();
  await page.mouse.move(s7b.x, s7b.y, { steps: 2 });
  await page.mouse.up();
  await page.waitForTimeout(120);
  names = await recentNames();
  console.log('Fast sweep at fret 7 (high to low):', names.join(' '));
  assert(names.join(' ') === 'B4 F#4 D4 A3 E3 B2', `fast fret-7 sweep should be B4 F#4 D4 A3 E3 B2, got ${names.join(' ')}`);
  // A finger wobbling near the boundary between two strings does not retrigger
  await clearRecent();
  const hold = await screenPos(2, 9);
  const spacingPx = await page.evaluate(() => window.__guitar.canvas.layout.spacing);
  await page.mouse.move(hold.x, hold.y);
  await page.mouse.down();
  for (let i = 0; i < 6; i++) await page.mouse.move(hold.x, hold.y + (i % 2 ? -1 : 1) * spacingPx * 0.56, { steps: 2 });
  await page.mouse.up();
  await page.waitForTimeout(60);
  names = await recentNames();
  console.log('Wobble on D string fret 9:', names.join(' '));
  assert(names.join(' ') === 'B3', `wobbling near a string boundary must not retrigger, got ${names.join(' ')}`);
  // Bend mode: dragging sideways bends the held string instead of strumming
  await page.evaluate(() => window.__guitar.state.setOption('dragAcross', 'bend'));
  await clearRecent();
  const bendPos = await screenPos(2, 7); // D string, 7th fret = A3 (220 Hz)
  await page.mouse.move(bendPos.x, bendPos.y);
  await page.mouse.down();
  await page.waitForTimeout(40);
  await page.mouse.move(bendPos.x, bendPos.y - spacingPx * 1.15, { steps: 8 });
  await page.waitForTimeout(40);
  const bent = await page.evaluate(() => ({ fingers: [...window.__guitar.state.fingers.values()].map((f) => ({ string: f.string, fret: f.fret, bend: f.bend })), freq: window.__guitar.engine.stringState[2].frequency, played: window.__guitar.state.recent.map((n) => n.name) }));
  console.log('Bend:', JSON.stringify(bent));
  assert(bent.fingers.length === 1 && bent.fingers[0].string === 2 && bent.fingers[0].fret === 7, 'bending keeps the finger on its string and fret');
  assert(Math.abs(bent.fingers[0].bend - 2) < 0.05, `1.15 spacings of pull should bend two semitones, got ${bent.fingers[0].bend}`);
  assert(Math.abs(bent.freq - 220 * Math.pow(2, 2 / 12)) < 0.8, `bent pitch should be B3 (246.94 Hz), got ${bent.freq}`);
  assert(bent.played.join(' ') === 'A3', `a bend must not retrigger or pick other strings, got ${bent.played.join(' ')}`);
  const bentReadout = await page.evaluate(() => ({ record: window.__guitar.state.ringing[2].bend, text: document.querySelector('#learning .now-playing').textContent.replace(/\s+/g, ' ') }));
  assert(Math.abs(bentReadout.record - 2) < 0.05 && /246\.9\d Hz/.test(bentReadout.text) && /bent \+2\.0 st/.test(bentReadout.text), `the read-out shows the bent pitch: ${bentReadout.text}`);
  await page.mouse.up();
  await page.waitForTimeout(40);
  const unbent = await page.evaluate(() => ({ freq: window.__guitar.engine.stringState[2].frequency, text: document.querySelector('#learning .now-playing').textContent.replace(/\s+/g, ' ') }));
  assert(Math.abs(unbent.freq - 220) < 0.01, `released bend should return to A3 (220 Hz), got ${unbent.freq}`);
  assert(/220\.00 Hz/.test(unbent.text) && !/bent/.test(unbent.text), `the read-out returns to the unbent note: ${unbent.text}`);
  await page.evaluate(() => window.__guitar.state.setOption('dragAcross', 'strum'));
  // A finger entering the fretboard by dragging (bend mode on) must not get a spurious bend
  await page.evaluate(() => window.__guitar.state.setOption('dragAcross', 'bend'));
  await clearRecent();
  const enter = await page.evaluate(() => { const c = window.__guitar.canvas, L = c.layout; const x = (L.fretX(6) + L.fretX(7)) / 2; return { from: c.toScreen(x, L.H - 3), to: c.toScreen(x, L.stringY(0)) }; });
  await page.mouse.move(canvasBox.x + enter.from.x, canvasBox.y + enter.from.y);
  await page.mouse.down();
  await page.mouse.move(canvasBox.x + enter.to.x, canvasBox.y + enter.to.y, { steps: 10 });
  await page.waitForTimeout(40);
  const entered = await page.evaluate(() => { const f = [...window.__guitar.state.fingers.values()][0]; return { finger: f && { string: f.string, fret: f.fret, bend: f.bend || 0 }, played: window.__guitar.state.recent.map((n) => n.name), freqs: window.__guitar.engine.stringState.map((s) => s.frequency) }; });
  await page.mouse.up();
  console.log('Drag into the fretboard in bend mode:', JSON.stringify(entered.finger), entered.played.join(' '));
  assert(entered.finger && entered.finger.bend < 0.05, `a finger that arrives by dragging must start unbent, got ${JSON.stringify(entered.finger)}`);
  const expectedFreq = await page.evaluate(([s, f]) => window.__guitar.state.fretboard.frequencyAt(s, f), [entered.finger.string, entered.finger.fret]);
  assert(Math.abs(entered.freqs[entered.finger.string] - expectedFreq) < 0.01, 'the entered note must sound at its fretted pitch');
  await page.evaluate(() => window.__guitar.state.setOption('dragAcross', 'strum'));

  // Resting a finger right on a fret wire must not trill between two frets
  await clearRecent();
  const wire = await page.evaluate(() => { const c = window.__guitar.canvas, L = c.layout; return { down: c.positionCenterScreen(3, 5), wire: c.toScreen(L.fretX(5), L.stringY(3)) }; });
  await page.mouse.move(canvasBox.x + wire.down.x, canvasBox.y + wire.down.y);
  await page.mouse.down();
  for (let i = 0; i < 8; i++) await page.mouse.move(canvasBox.x + wire.wire.x + (i % 2 ? 2 : -2), canvasBox.y + wire.wire.y);
  const wobbleFret = await page.evaluate(() => [...window.__guitar.state.fingers.values()][0].fret);
  await page.mouse.up();
  assert(wobbleFret === 5, `a 2 px wobble across a fret wire must not change fret, got ${wobbleFret}`);
  // … but a deliberate move past the wire does slide
  await page.mouse.move(canvasBox.x + wire.down.x, canvasBox.y + wire.down.y);
  await page.mouse.down();
  const next = await screenPos(3, 6);
  await page.mouse.move(next.x, next.y, { steps: 5 });
  const slidFret = await page.evaluate(() => [...window.__guitar.state.fingers.values()][0].fret);
  await page.mouse.up();
  assert(slidFret === 6, `moving to the next fret slides, got ${slidFret}`);

  // An open-string strum that drifts a little over the nut keeps strumming open strings
  await clearRecent();
  const drift = await page.evaluate(() => { const c = window.__guitar.canvas, L = c.layout; return { a: c.toScreen(L.openW * 0.6, L.fbTop - 2), b: c.toScreen(L.nutX + 24, L.fbBottom + 2) }; });
  await page.mouse.move(canvasBox.x + drift.a.x, canvasBox.y + drift.a.y);
  await page.mouse.down();
  await page.mouse.move(canvasBox.x + drift.b.x, canvasBox.y + drift.b.y, { steps: 16 });
  await page.mouse.up();
  await page.waitForTimeout(100);
  names = await recentNames();
  console.log('Open strum drifting over the nut:', names.join(' '));
  assert(names.join(' ') === 'E4 B3 G3 D3 A2 E2', `a drifting open strum must stay open, got ${names.join(' ')}`);

  // The right mouse button does not play
  await clearRecent();
  const rc = await screenPos(2, 3);
  await page.mouse.click(rc.x, rc.y, { button: 'right' });
  await page.waitForTimeout(40);
  assert((await recentNames()).length === 0, 'right-click must not play a note');

  // Sweep the open strings again so all six ring for the next check
  await clearRecent();
  await page.mouse.move(s5a.x, s5a.y);
  await page.mouse.down();
  await page.mouse.move(s5b.x, s5b.y, { steps: 14 });
  await page.mouse.up();
  await page.waitForTimeout(100);
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
  // After clicking panel buttons, Space still strums (focus returns to playing) and Hold stays on
  await clearRecent();
  await page.keyboard.press('Space');
  await page.waitForTimeout(250);
  const afterSpace = await page.evaluate(() => ({ hold: window.__guitar.state.holdChord, notes: window.__guitar.state.recent.map((n) => n.pitchClassName) }));
  assert(afterSpace.hold === true, 'Space must not toggle the Hold chord button that was clicked last');
  assert(afterSpace.notes.length === 6 && afterSpace.notes.every((n) => ['G', 'B', 'D'].includes(n)), `Space should strum the held G chord, got ${afterSpace.notes.join(' ')}`);
  // Capo: the same chord name still sounds the same chord, fingered above the capo
  await page.selectOption('#capo-select', '2');
  await clearRecent();
  await page.click('#learning .btn.primary');
  await page.waitForTimeout(250);
  const capoChord = await page.evaluate(() => ({ notes: window.__guitar.state.recent.map((n) => n.pitchClassName), frets: window.__guitar.state.recent.map((n) => n.fret), title: document.querySelector('#learning .chord-title').textContent }));
  console.log('G with capo 2:', capoChord.notes.join(' '), '| frets', capoChord.frets.join(' '), '|', capoChord.title);
  assert(capoChord.notes.length >= 4 && capoChord.notes.every((n) => ['G', 'B', 'D'].includes(n)), `G with a capo must still sound G B D, got ${capoChord.notes.join(' ')}`);
  assert(capoChord.frets.every((f) => f >= 2), 'no chord note may be behind the capo');
  await page.screenshot({ path: `${outDir}/05b-capo-chord.png` });
  await page.selectOption('#capo-select', '0');
  await page.click('#learning .btn.ghost'); // clear

  // Scale overlay + note highlight render without errors
  await page.click('[data-tab="scales"]');
  await page.click('#learning [data-panel="scales"] .btn.primary');
  await page.waitForTimeout(100);
  await page.screenshot({ path: `${outDir}/06-scale.png` });
  await page.evaluate(() => window.__guitar.state.setScale(null));

  // Pick sliders are wired to the playing options
  await page.locator('input[aria-label="Pick position"]').evaluate((el) => { el.value = '0.25'; el.dispatchEvent(new Event('input', { bubbles: true })); });
  await page.locator('input[aria-label="Pick strength"]').evaluate((el) => { el.value = '0.4'; el.dispatchEvent(new Event('input', { bubbles: true })); });
  const pickOpts = await page.evaluate(() => ({ pos: window.__guitar.state.options.pickPosition, strength: window.__guitar.state.options.pickStrength }));
  assert(pickOpts.pos === 0.25 && pickOpts.strength === 0.4, `pick sliders should update options, got ${JSON.stringify(pickOpts)}`);
  await clearRecent();
  await page.keyboard.press('3');
  await page.waitForTimeout(60);
  note = await lastNote();
  assert(note && note.name === 'G3' && Math.abs(note.velocity - 0.4) < 1e-9, `key 3 picks the G string at the chosen strength, got ${note && note.name} ${note && note.velocity}`);
  await page.evaluate(() => { window.__guitar.state.setOption('pickPosition', 0.14); window.__guitar.state.setOption('pickStrength', 0.8); });

  // Presets & knobs
  await page.click('[data-preset="distortion"]');
  const preset = await page.evaluate(() => ({ id: window.__guitar.engine.presetId, pickup: window.__guitar.engine.pickupPosition, gain: window.__guitar.engine.params.gain }));
  console.log('Preset:', JSON.stringify(preset));
  assert(preset.id === 'distortion' && preset.pickup === 1, 'distortion preset applied');
  await page.click('[data-preset="clean"]');

  // "Prefer flats" reaches every label: tuning read-out and menu, ring dots, and the scale-label menu keeps its value
  await page.evaluate(() => { const g = window.__guitar; g.state.setHoldChord(false); g.state.setChord(null); g.state.setCapo(0); g.state.setTuning('half-step-down'); g.state.setOption('scaleLabels', 'names'); g.state.setOption('flats', true); });
  await page.waitForTimeout(60);
  const flat = await page.evaluate(() => ({
    info: document.getElementById('tuning-info').textContent.replace(/\s+/g, ' '),
    menu: document.getElementById('tuning-select').selectedOptions[0].textContent,
    scaleLabels: document.querySelector('select[aria-label="Scale labels"]').value,
  }));
  console.log('Flats:', JSON.stringify(flat));
  assert(/Eb2/.test(flat.info) && !/#/.test(flat.info), `tuning read-out uses flats: ${flat.info}`);
  assert(/Eb Ab Db Gb Bb Eb/.test(flat.menu), `tuning menu uses flats: ${flat.menu}`);
  assert(flat.scaleLabels === 'names', 'the scale-label menu keeps its value when the panels are rebuilt');
  await page.evaluate(() => { const g = window.__guitar; g.state.setOption('flats', false); g.state.setOption('scaleLabels', 'degrees'); g.state.setTuning('standard'); });

  // The pickup selector is switched off (not just ignored) for the acoustic preset
  await page.click('[data-preset="acoustic"]');
  const acoustic = await page.evaluate(() => ({ disabled: [...document.querySelectorAll('[data-pickup]')].every((b) => b.disabled), pressed: document.querySelectorAll('[data-pickup][aria-pressed="true"]').length, hint: !document.querySelector('[data-pickup]').closest('section').querySelector('.hint-text').hidden }));
  assert(acoustic.disabled && acoustic.pressed === 0 && acoustic.hint, `pickup selector is disabled with an explanation in the acoustic preset: ${JSON.stringify(acoustic)}`);
  await page.click('[data-preset="clean"]');
  const electric = await page.evaluate(() => ({ disabled: [...document.querySelectorAll('[data-pickup]')].some((b) => b.disabled), pressed: document.querySelectorAll('[data-pickup][aria-pressed="true"]').length, preset: document.querySelector('[data-preset="clean"]').getAttribute('aria-pressed') }));
  assert(!electric.disabled && electric.pressed === 1 && electric.preset === 'true', 'pickup selector works again on an electric preset');

  // Clearing the chord also clears the highlighted root
  await page.click('#learning [data-tab="chords"]');
  await page.click('#learning [data-panel="chords"] .root-btn[data-pc="7"]');
  const picked = await page.evaluate(() => [...document.querySelectorAll('#learning [data-panel="chords"] .root-btn[aria-pressed="true"]')].map((b) => b.textContent));
  assert(picked.join() === 'G', `the picked root is marked: ${picked.join()}`);
  await page.click('#learning [data-panel="chords"] button:text-is("Clear")');
  const cleared = await page.evaluate(() => ({ chord: window.__guitar.state.chord, active: document.querySelectorAll('#learning [data-panel="chords"] .root-btn.active').length }));
  assert(cleared.chord === null && cleared.active === 0, `no root stays highlighted after Clear: ${JSON.stringify(cleared)}`);

  // The up/down arrow keys belong to the page (scrolling), not to strumming
  await clearRecent();
  await page.keyboard.press('ArrowDown');
  await page.waitForTimeout(80);
  assert((await recentNames()).length === 0, 'ArrowDown does not strum');
  await page.evaluate(() => window.scrollTo(0, 0));

  // Every fret can be played from the keyboard: Tab to the fretboard, arrows move a cursor, Enter plays
  await page.evaluate(() => document.getElementById('help-btn').focus());
  for (let i = 0; i < 14; i++) {
    await page.keyboard.press('Tab');
    if (await page.evaluate(() => document.activeElement.id === 'guitar')) break;
  }
  const focused = await page.evaluate(() => ({ id: document.activeElement.id, cursor: window.__guitar.canvas.cursor }));
  assert(focused.id === 'guitar' && focused.cursor && focused.cursor.string === 0 && focused.cursor.fret === 0, `Tab reaches the fretboard and shows the cursor: ${JSON.stringify(focused)}`);
  await clearRecent();
  for (let i = 0; i < 3; i++) await page.keyboard.press('ArrowRight');
  await page.keyboard.press('Enter');
  await page.keyboard.press('ArrowUp');
  await page.keyboard.down('Enter');
  await page.waitForTimeout(40);
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(40);
  const slidTo = await page.evaluate(() => ({ note: window.__guitar.state.ringing[1] && window.__guitar.state.ringing[1].name, hz: window.__guitar.engine.stringState[1].frequency, fingers: window.__guitar.state.fingers.size }));
  await page.keyboard.up('Enter');
  await page.keyboard.press('End');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(60);
  const kbd = await page.evaluate(() => ({ played: window.__guitar.state.recent.map((n) => n.name), status: document.getElementById('cursor-status').textContent, fingers: window.__guitar.state.fingers.size, cursor: window.__guitar.canvas.cursor }));
  console.log('Keyboard cursor:', JSON.stringify({ slidTo, ...kbd }));
  assert(kbd.played.join(' ') === 'G2 C3 A4', `cursor notes should be G2 C3 A4, got ${kbd.played.join(' ')}`);
  assert(slidTo.note === 'D3' && Math.abs(slidTo.hz - 146.83) < 0.05 && slidTo.fingers === 1, `holding Enter while moving slides the note: ${JSON.stringify(slidTo)}`);
  assert(kbd.status === 'String 5, fret 24: A4' && kbd.fingers === 0, `the cursor position is announced: ${kbd.status}`);
  await page.screenshot({ path: `${outDir}/06b-keyboard-cursor.png` });
  await page.keyboard.press('Tab');
  assert(await page.evaluate(() => window.__guitar.canvas.cursor === null), 'the cursor disappears when the fretboard loses focus');
  await page.evaluate(() => { document.activeElement.blur(); window.scrollTo(0, 0); });

  // Tabs: arrow keys move between them and they are tied to their panels
  await page.focus('#tab-chords');
  await page.keyboard.press('ArrowRight');
  const tabState = await page.evaluate(() => ({ active: document.activeElement.id, selected: document.getElementById('tab-scales').getAttribute('aria-selected'), panel: !document.getElementById('panel-scales').hidden, controls: document.getElementById('tab-scales').getAttribute('aria-controls') }));
  assert(tabState.active === 'tab-scales' && tabState.selected === 'true' && tabState.panel && tabState.controls === 'panel-scales', `arrow keys switch tabs: ${JSON.stringify(tabState)}`);
  await page.keyboard.press('ArrowLeft');
  await page.evaluate(() => { document.activeElement.blur(); window.scrollTo(0, 0); });

  // When nothing sounds the page goes idle: no animation-frame loops keep running
  await page.evaluate(() => window.__guitar.player.releaseEverything());
  await page.waitForTimeout(6000);
  const idleFrames = await page.evaluate(() => new Promise((resolve) => {
    const original = window.requestAnimationFrame;
    let calls = 0;
    window.requestAnimationFrame = (cb) => { calls++; return original.call(window, cb); };
    setTimeout(() => { window.requestAnimationFrame = original; resolve(calls); }, 1000);
  }));
  console.log('requestAnimationFrame calls per second when idle:', idleFrames);
  assert(idleFrames <= 2, `the page should be idle when nothing sounds, got ${idleFrames} animation frames per second`);

  // ---- Barre chords ----
  // Dragging a pressed finger across the strings inside one fret lays it down as a barre:
  // the strings stay fretted while it is down, and the barre moves as one.
  await page.evaluate(() => { const g = window.__guitar; g.player.releaseEverything(); g.state.setHoldChord(false); g.state.setChord(null); g.state.setCapo(0); g.state.setTuning('standard'); window.scrollTo(0, 0); });
  canvasBox = await page.locator('#guitar').boundingBox();
  const notesNow = () => page.evaluate(() => [0, 1, 2, 3, 4, 5].map((i) => { const n = window.__guitar.state.noteOn(i); return n ? n.name : 'x'; }).join(' '));
  const stripPos = async (string) => {
    const q = await page.evaluate((i) => { const c = window.__guitar.canvas; return c.toScreen(c.pickX + c.pickW / 2, c.layout.stringY(i)); }, string);
    return { x: canvasBox.x + q.x, y: canvasBox.y + q.y };
  };
  const b0 = await screenPos(0, 1), b5 = await screenPos(5, 1);
  await clearRecent();
  await page.mouse.move(b0.x, b0.y);
  await page.mouse.down();
  await page.mouse.move(b5.x, b5.y, { steps: 12 });
  await page.waitForTimeout(60);
  let barre = await page.evaluate(() => [...window.__guitar.state.fingers.values()].map((f) => [f.string, f.fret, f.from]));
  names = await recentNames();
  console.log('Barre at fret 1:', JSON.stringify(barre), '|', await notesNow());
  assert(barre.length === 1 && barre[0].join() === '5,1,0', `one finger lying across all six strings: ${JSON.stringify(barre)}`);
  assert((await notesNow()) === 'F2 A#2 D#3 G#3 C4 F4', 'every string is fretted at the barre');
  assert(names.join(' ') === 'F2 A#2 D#3 G#3 C4 F4', `laying the barre rakes each string once: ${names.join(' ')}`);
  await clearRecent();
  await page.keyboard.press('Space');
  await page.waitForTimeout(200);
  names = await recentNames();
  assert(names.join(' ') === 'F2 A#2 D#3 G#3 C4 F4', `a strum plays the barre, not open strings: ${names.join(' ')}`);
  const b5at3 = await screenPos(5, 3);
  await page.mouse.move(b5at3.x, b5at3.y, { steps: 8 });
  await page.waitForTimeout(60);
  const slidBarre = await page.evaluate(() => ({ hz: window.__guitar.engine.stringState.map((x) => +x.frequency.toFixed(1)), ringing: window.__guitar.state.ringing.map((r) => r && r.name).join(' ') }));
  assert((await notesNow()) === 'G2 C3 F3 A#3 D4 G4' && slidBarre.ringing === 'G2 C3 F3 A#3 D4 G4', `the whole barre slides to fret 3: ${JSON.stringify(slidBarre)}`);
  assert(Math.abs(slidBarre.hz[0] - 98.0) < 0.1 && Math.abs(slidBarre.hz[5] - 392.0) < 0.1, 'the engine follows every string of the sliding barre');
  await page.screenshot({ path: `${outDir}/05b-barre.png` });
  await page.mouse.up();
  await page.waitForTimeout(40);
  assert((await page.evaluate(() => window.__guitar.state.fingers.size)) === 0 && (await notesNow()) === 'E2 A2 D3 G3 B3 E4', 'lifting the barre frees every string');

  // The strum strip picks strings without fretting them
  await page.evaluate(() => window.__guitar.player.releaseEverything());
  await clearRecent();
  const sp5 = await stripPos(5), sp0 = await stripPos(0);
  await page.mouse.click(sp5.x, sp5.y);
  await page.waitForTimeout(60);
  assert((await recentNames()).join(' ') === 'E4' && (await page.evaluate(() => window.__guitar.state.fingers.size)) === 0, 'a tap on the strum strip picks that string and frets nothing');

  // Hold: fingers stay down after the pointer lifts, so a barre chord can be built one touch at a time
  await page.click('#tool-hold');
  await page.mouse.move(b0.x, b0.y);
  await page.mouse.down();
  await page.mouse.move(b5.x, b5.y, { steps: 12 });
  await page.mouse.up();
  for (const [string, fret] of [[3, 2], [1, 3], [2, 3]]) { const q = await screenPos(string, fret); await page.mouse.click(q.x, q.y); }
  await page.waitForTimeout(60);
  const heldShape = await page.evaluate(() => ({ held: [...window.__guitar.state.fingers.values()].filter((f) => f.held).length, pressed: document.getElementById('tool-hold').getAttribute('aria-pressed'), option: document.querySelector('#controls input[type="checkbox"]') !== null }));
  assert(heldShape.held === 4 && heldShape.pressed === 'true' && (await notesNow()) === 'F2 C3 F3 A3 C4 F4', `F major (E shape) built with Hold: ${JSON.stringify(heldShape)} ${await notesNow()}`);
  await clearRecent();
  await page.mouse.move(sp0.x, sp0.y);
  await page.mouse.down();
  await page.mouse.move(sp5.x, sp5.y, { steps: 10 });
  await page.mouse.up();
  await page.waitForTimeout(200);
  names = await recentNames();
  const chordShown = (await page.textContent('#learning .np-chord')).trim();
  console.log('Held F major strummed on the strip:', names.join(' '), '|', chordShown);
  assert(names.join(' ') === 'F2 C3 F3 A3 C4 F4' && chordShown === 'Chord: F', `sweeping the strum strip plays the held barre chord: ${names.join(' ')} / ${chordShown}`);
  await page.screenshot({ path: `${outDir}/05c-hold-barre-chord.png` });
  await page.click('#tool-mute');
  await page.waitForTimeout(60);
  assert((await page.evaluate(() => [...window.__guitar.state.fingers.values()].filter((f) => f.held).length)) === 4 && (await page.evaluate(() => window.__guitar.state.ringing.filter(Boolean).length)) === 0, 'Mute silences the strings but keeps the held shape');
  const heldG = await screenPos(3, 2);
  await page.mouse.click(heldG.x, heldG.y);
  await page.waitForTimeout(40);
  assert((await notesNow()) === 'F2 C3 F3 G#3 C4 F4', `tapping a held finger lets it go: ${await notesNow()}`);
  await page.click('#tool-hold');
  await page.waitForTimeout(40);
  assert((await page.evaluate(() => window.__guitar.state.fingers.size)) === 0 && (await notesNow()) === 'E2 A2 D3 G3 B3 E4', 'switching Hold off lifts every held finger');

  // A fretted note left to ring out survives events that do not concern its string:
  // looking at a chord diagram, choosing another voicing, retuning another string.
  await page.evaluate(() => { const g = window.__guitar; g.player.releaseEverything(); g.state.setHoldChord(false); g.state.setChord(null); g.state.setCapo(0); g.state.setTuning('standard'); window.scrollTo(0, 0); });
  canvasBox = await page.locator('#guitar').boundingBox();
  p = await screenPos(3, 5); // G string, 5th fret = C4
  await page.mouse.click(p.x, p.y);
  await page.waitForTimeout(80);
  const ringsC4 = () => page.evaluate(() => { const g = window.__guitar; const r = g.state.ringing[3]; return { name: r && r.name, engine: g.engine.stringState[3].ringing, hz: g.engine.stringState[3].frequency }; });
  let c4 = await ringsC4();
  assert(c4.name === 'C4' && c4.engine, `C4 rings after the tap: ${JSON.stringify(c4)}`);
  await page.evaluate(() => window.__guitar.state.setChord(0, 'maj', 0));          // only looking at a chord diagram
  await page.evaluate(() => window.__guitar.state.setChordVoicing(1));
  await page.evaluate(() => window.__guitar.state.setTuning('drop-d'));           // retunes the low E only
  await page.waitForTimeout(60);
  c4 = await ringsC4();
  console.log('Ring-out note after chord/voicing/tuning events:', JSON.stringify(c4));
  assert(c4.name === 'C4' && c4.engine && Math.abs(c4.hz - 261.63) < 0.01, `a ringing fretted note must survive unrelated chord and tuning events: ${JSON.stringify(c4)}`);
  await page.evaluate(() => { const g = window.__guitar; g.state.setChord(null); g.state.setTuning('standard'); g.player.releaseEverything(); });

  // After the help is closed with the pointer, Space strums (focus does not stay on the help button)
  await page.click('#help-btn');
  await page.click('#help button[value="close"]');
  await clearRecent();
  await page.waitForFunction(() => document.activeElement === document.body); // the dialog's close event arrives with the next frame
  await page.keyboard.press('Space');
  await page.waitForTimeout(150);
  const afterHelp = await page.evaluate(() => ({ open: document.getElementById('help').open, played: window.__guitar.state.recent.length }));
  assert(!afterHelp.open && afterHelp.played === 6, `Space strums after closing the help: ${JSON.stringify(afterHelp)}`);

  // A mute sent right after a strum silences it (the strum's later strings must not sound afterwards)
  await page.evaluate(() => { const g = window.__guitar; g.state.setHoldChord(false); g.state.setChord(null); g.state.setCapo(0); g.player.releaseEverything(); });
  await page.waitForFunction(() => window.__guitar.engine.getLevel() < 0.0005, null, { timeout: 8000 }); // let earlier notes' reverb die away
  await page.evaluate(() => { const g = window.__guitar; g.player.strum('down'); g.player.releaseEverything(); });
  await page.waitForTimeout(600);
  const afterMute = await page.evaluate(() => ({ level: window.__guitar.engine.getLevel(), ringing: window.__guitar.state.ringing.filter(Boolean).length }));
  console.log('Strum then immediate mute:', JSON.stringify(afterMute));
  assert(afterMute.level < 0.003 && afterMute.ringing === 0, `mute right after a strum must be silent, level ${afterMute.level}`);

  // "Lifting a finger mutes the string": a very fast sweep must not leave strings ringing that the app shows as silent
  await page.evaluate(() => window.__guitar.state.setOption('releaseMutes', true));
  await page.mouse.move(s5a.x, s5a.y);
  await page.mouse.down();
  await page.mouse.move(s5b.x, s5b.y, { steps: 1 });
  await page.mouse.up();
  await page.waitForTimeout(1500);
  const fastMuted = await page.evaluate(() => ({ level: window.__guitar.engine.getLevel(), ringing: window.__guitar.state.ringing.filter(Boolean).length }));
  console.log('Fast sweep with lift-to-mute:', JSON.stringify(fastMuted));
  assert(fastMuted.level < 0.003 && fastMuted.ringing === 0, `fast sweep with lift-to-mute must end silent, level ${fastMuted.level}`);
  await page.evaluate(() => window.__guitar.state.setOption('releaseMutes', false));

  // Keyboard users can step through a menu: it keeps focus and the arrow keys do not strum
  await clearRecent();
  await page.focus('#tuning-select');
  await page.keyboard.press('ArrowDown');
  await page.keyboard.press('ArrowDown');
  await page.waitForTimeout(80);
  const menu = await page.evaluate(() => ({ active: document.activeElement.id, index: document.getElementById('tuning-select').selectedIndex, tuning: window.__guitar.state.tuning.id, played: window.__guitar.state.recent.length }));
  console.log('Keyboard menu:', JSON.stringify(menu));
  assert(menu.active === 'tuning-select' && menu.index === 2 && menu.played === 0, `stepping a menu with the keyboard keeps focus there: ${JSON.stringify(menu)}`);
  await page.selectOption('#tuning-select', 'standard');
  await page.evaluate(() => document.activeElement.blur());

  // The canvas box can change without a window resize; the layout follows and taps still hit the drawn fret
  await page.evaluate(() => { window.scrollTo(0, 0); document.getElementById('stage').style.marginRight = '60px'; });
  await page.waitForFunction(() => { const c = window.__guitar.canvas; return Math.abs(c.cssW - c.canvas.getBoundingClientRect().width) < 0.6; }, null, { timeout: 3000 });
  const squeezed = await page.evaluate(() => { const c = window.__guitar.canvas; const b = c.canvas.getBoundingClientRect(); const q = c.positionCenterScreen(5, 24); return { x: b.left + q.x, y: b.top + q.y, w: b.width }; });
  await page.mouse.click(squeezed.x, squeezed.y);
  await page.waitForTimeout(60);
  note = await lastNote();
  assert(note && note.name === 'E6', `after the stage was resized by layout, fret 24 still plays E6 (got ${note && note.name})`);
  await page.evaluate(() => { document.getElementById('stage').style.marginRight = ''; });
  await page.waitForFunction(() => { const c = window.__guitar.canvas; return Math.abs(c.cssW - c.canvas.getBoundingClientRect().width) < 0.6; }, null, { timeout: 3000 });
  console.log('Layout-driven canvas resize: ok');

  // ---- From here on the device has a touch screen as its main pointer (a large tablet first, then phones) ----
  await page.close();
  const touchContext = await browser.newContext({ viewport: { width: 1400, height: 860 }, deviceScaleFactor: 1, hasTouch: true });
  page = await touchContext.newPage();
  watch(page);
  await page.goto(`${server.url}/`);
  await page.waitForFunction(() => window.__guitar && window.__guitar.canvas.layout);
  await page.click('#start-overlay');
  await page.waitForFunction(() => window.__guitar.engine.ready);
  canvasBox = await page.locator('#guitar').boundingBox();
  const tablet = await page.evaluate(() => ({ coarse: matchMedia('(pointer: coarse)').matches, pannable: window.__guitar.canvas.pannable, fret24: window.__guitar.canvas.layout.cellWidth(24) }));
  console.log('Touch screen layout:', JSON.stringify(tablet));
  assert(tablet.coarse && tablet.pannable && tablet.fret24 >= 30, 'on a touch screen the neck is zoomed so that the 24th fret is finger-sized');

  // Multi-touch: two fingers on different strings (A string fret 2 = B2, D string fret 2 = E3), then strum
  await clearRecent();
  const t1 = await screenPos(1, 2);
  const t2 = await screenPos(2, 2);
  const cdp = await touchContext.newCDPSession(page);
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

  // A real two-handed barre chord: one touch lies across fret 1, three more fingers shape F major,
  // and a fifth touch strums on the strip (five touches is what an iPhone tracks).
  await page.evaluate(() => { window.__guitar.player.releaseEverything(); window.__guitar.canvas.setScroll(0); });
  const T = async (string, fret, id) => ({ ...(await screenPos(string, fret)), id });
  const many = (type, points) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: points.map((pt) => ({ x: pt.x, y: pt.y, id: pt.id })) });
  const lay0 = await T(0, 1, 1), lay5 = await T(5, 1, 1);
  await many('touchStart', [lay0]);
  for (let k = 1; k <= 10; k++) await many('touchMove', [{ x: lay0.x + ((lay5.x - lay0.x) * k) / 10, y: lay0.y + ((lay5.y - lay0.y) * k) / 10, id: 1 }]);
  const fG = await T(3, 2, 2), fA = await T(1, 3, 3), fD = await T(2, 3, 4);
  await many('touchStart', [lay5, fG]);
  await many('touchStart', [lay5, fG, fA]);
  await many('touchStart', [lay5, fG, fA, fD]);
  await page.waitForTimeout(60);
  const shape = await page.evaluate(() => [0, 1, 2, 3, 4, 5].map((i) => window.__guitar.state.noteOn(i).name).join(' '));
  assert(shape === 'F2 C3 F3 A3 C4 F4', `four touches hold F major as a barre chord: ${shape}`);
  await clearRecent();
  const strum0 = await page.evaluate(() => { const c = window.__guitar.canvas; const b = c.canvas.getBoundingClientRect(); const a = c.toScreen(c.pickX + c.pickW / 2, c.layout.stringY(0)); const z = c.toScreen(c.pickX + c.pickW / 2, c.layout.stringY(5)); return { ax: b.left + a.x, ay: b.top + a.y, zx: b.left + z.x, zy: b.top + z.y }; });
  await many('touchStart', [lay5, fG, fA, fD, { x: strum0.ax, y: strum0.ay, id: 5 }]);
  for (let k = 1; k <= 8; k++) await many('touchMove', [lay5, fG, fA, fD, { x: strum0.ax + ((strum0.zx - strum0.ax) * k) / 8, y: strum0.ay + ((strum0.zy - strum0.ay) * k) / 8, id: 5 }]);
  await many('touchEnd', [lay5, fG, fA, fD]);
  await page.waitForTimeout(200);
  names = await recentNames();
  console.log('Five-touch F major barre chord:', names.join(' '));
  assert(names.join(' ') === 'F2 C3 F3 A3 C4 F4', `the fifth touch strums the barre chord on the strip: ${names.join(' ')}`);
  await page.screenshot({ path: `${outDir}/04b-touch-barre-chord.png` });
  await many('touchEnd', []);
  await page.waitForTimeout(50);
  assert((await page.evaluate(() => window.__guitar.state.fingers.size)) === 0, 'all five touches lifted');

  // Mobile portrait
  await page.setViewportSize({ width: 390, height: 844 });
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(300);
  const mobile = await page.evaluate(() => { const c = window.__guitar.canvas; return { coarse: matchMedia('(pointer: coarse)').matches, orientation: c.orientation, frets: c.fretCount, spacing: c.layout.spacing, pannable: c.pannable, fret12Cell: c.layout.cellWidth(12), navHidden: document.getElementById('neck-nav').hidden, lowELeft: c.positionCenterScreen(0, 3).x < c.positionCenterScreen(5, 3).x, nutTop: c.positionCenterScreen(0, 1).y < c.positionCenterScreen(0, 5).y }; });
  console.log('Mobile layout:', JSON.stringify(mobile));
  assert(mobile.orientation === 'vertical', 'portrait phone uses vertical layout');
  assert(mobile.coarse, 'the phone part runs with a touch screen as the main pointer');
  assert(mobile.frets === 24, 'all 24 frets exist on a phone');
  assert(mobile.pannable && !mobile.navHidden, 'the neck is zoomed and the minimap is shown on a phone');
  assert(mobile.spacing >= 26, `string spacing on a phone should be >= 26 px, got ${mobile.spacing}`);
  assert(mobile.fret12Cell >= 44, `fret 12 should be finger-sized on a phone, got ${mobile.fret12Cell}`);
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

  // Starting from the keyboard: the first key both powers the amp on and is played once it is ready
  const page2 = await context.newPage();
  page2.on('pageerror', (e) => { errors.push(e.message); console.log('[pageerror]', e.message); });
  await page2.setViewportSize({ width: 1400, height: 860 });
  await page2.goto(`${server.url}/`);
  await page2.waitForFunction(() => window.__guitar && window.__guitar.canvas.layout);
  await page2.keyboard.press('Digit3');
  await page2.waitForFunction(() => window.__guitar.engine.ready && window.__guitar.state.recent.length > 0, null, { timeout: 5000 });
  await page2.waitForTimeout(900);
  const kb = await page2.evaluate(() => ({ note: window.__guitar.state.recent[0].name, overlay: !!document.getElementById('start-overlay'), ringing: window.__guitar.engine.stringState[3].ringing }));
  console.log('Keyboard start:', JSON.stringify(kb));
  assert(kb.note === 'G3' && kb.ringing, 'the first key press is played after the amp powers on');
  assert(kb.overlay === false, 'the start overlay is removed when audio starts from the keyboard');
  await page2.close();

  assert(errors.length === 0, `console errors: ${errors.join(' | ')}`);
  console.log('\nUI TESTS PASSED');
} finally {
  await browser.close();
  server.stop();
}
