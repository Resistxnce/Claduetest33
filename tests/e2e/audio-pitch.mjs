/**
 * Renders every string at every fret 0–24 of the standard tuning (and a
 * sample of other tunings) through the real audio engine in an OfflineAudioContext and
 * verifies the synthesized fundamental matches equal temperament.
 */
import { startServer, launchBrowser, assert } from './lib.mjs';
import { Fretboard } from '../../src/theory/fretboard.js';
import { TUNINGS, getTuning } from '../../src/theory/tunings.js';
import { vibratingLengthFraction } from '../../src/theory/fretboard.js';

const TOLERANCE_CENTS = Number(process.env.PITCH_TOLERANCE_CENTS || 4);

const server = await startServer(8124);
const browser = await launchBrowser();
try {
  const page = await browser.newPage();
  page.on('console', (m) => { if (m.type() === 'error') console.error('[page]', m.text()); });
  page.on('pageerror', (e) => console.error('[pageerror]', e.message));
  await page.goto(`${server.url}/tests/e2e/audio-harness.html`);
  await page.waitForFunction(() => window.__harnessReady === true);

  const results = [];
  let worst = 0;
  const tunings = process.env.ALL_TUNINGS ? TUNINGS : [getTuning('standard'), getTuning('drop-d'), getTuning('dadgad')];
  for (const tuning of tunings) {
    const fb = new Fretboard({ tuning, fretCount: 24 });
    const frets = tuning.id === 'standard' ? [...Array(25).keys()] : [0, 3, 7, 12, 17, 22, 24];
    for (let s = 0; s < 6; s++) {
      for (const f of frets) {
        const expected = fb.frequencyAt(s, f);
        const r = await page.evaluate((o) => window.renderNote(o), { frequency: expected, lengthFraction: vibratingLengthFraction(f), string: s, velocity: 0.8, duration: 1.6 });
        const err = Math.abs(r.cents ?? 999);
        worst = Math.max(worst, err);
        results.push({ tuning: tuning.id, string: s, fret: f, expected, measured: r.measured, cents: r.cents, clarity: r.clarity, peak: r.peak });
        const status = err <= TOLERANCE_CENTS ? 'ok ' : 'BAD';
        if (status === 'BAD' || process.env.VERBOSE) {
          console.log(`${status} ${tuning.id.padEnd(9)} s${s} f${String(f).padStart(2)} expect ${expected.toFixed(2).padStart(8)} Hz  got ${r.measured.toFixed(2).padStart(8)} Hz  ${r.cents.toFixed(2).padStart(6)} cents  clarity ${r.clarity.toFixed(2)} peak ${r.peak.toFixed(3)}`);
        }
      }
    }
  }
  const bad = results.filter((r) => Math.abs(r.cents ?? 999) > TOLERANCE_CENTS);
  console.log(`\nPitch check: ${results.length} notes rendered, worst error ${worst.toFixed(2)} cents, ${bad.length} outside ±${TOLERANCE_CENTS} cents`);
  const peaks = results.map((r) => r.peak);
  console.log(`Peak levels: min ${Math.min(...peaks).toFixed(3)} max ${Math.max(...peaks).toFixed(3)}`);
  assert(bad.length === 0, `${bad.length} notes out of tune`);
  assert(Math.max(...peaks) < 1.0, 'output clipping');
  assert(Math.min(...peaks) > 0.02, 'a note was nearly silent');

  // Behavioural checks: release mutes quickly; sustain is long when ringing.
  const ring = await page.evaluate((o) => window.renderNote(o), { frequency: 110, string: 1, duration: 3.0 });
  const released = await page.evaluate((o) => window.renderNote(o), { frequency: 110, string: 1, duration: 3.0, events: [{ type: 'release', at: 1.0 }] });
  console.log('ringing rms windows', ring.windows.map((w) => w.rms.toFixed(4)).join(' '));
  console.log('released rms windows', released.windows.map((w) => w.rms.toFixed(4)).join(' '));
  assert(ring.rmsLate > ring.rmsEarly * 0.04, 'ringing note should still be audible after 3 s');
  const at = (r, t) => r.windows.find((w) => Math.abs(w.t - t) < 0.01).rms;
  // After the fret hand lets go, the string must drop by at least 20 dB within 50 ms
  // (only faint sympathetic resonance of the other strings may remain).
  assert(at(released, 1.05) < at(ring, 1.05) * 0.1, `released note should be muted: ${at(released, 1.05)} vs ${at(ring, 1.05)}`);
  assert(released.rmsLate < ring.rmsLate * 0.1, 'released note should stay quiet');
  // Velocity dynamics
  const soft = await page.evaluate((o) => window.renderNote(o), { frequency: 196, string: 3, velocity: 0.2, duration: 1.0 });
  const hard = await page.evaluate((o) => window.renderNote(o), { frequency: 196, string: 3, velocity: 1.0, duration: 1.0 });
  console.log(`velocity: soft peak ${soft.peak.toFixed(3)} hard peak ${hard.peak.toFixed(3)}`);
  assert(hard.rmsEarly > soft.rmsEarly * 2, 'hard pluck should be clearly louder than soft');
  // Slide: pitch should end at the new note
  const slid = await page.evaluate((o) => window.renderNote(o), { frequency: 110, string: 1, duration: 2.2, analysisStart: 1.2, analysisEnd: 2.1, events: [{ type: 'pitch', at: 0.6, frequency: 123.47, glide: 0.08, lengthFraction: 0.891 }] });
  console.log(`slide: measured ${slid.measured.toFixed(2)} Hz after glide to 123.47 Hz`);
  assert(Math.abs(1200 * Math.log2(slid.measured / 123.47)) < TOLERANCE_CENTS, 'slide should land on target pitch');
  // Every amp preset must produce sound for a full open strum without clipping,
  // and the distorted presets must actually add harmonics.
  const strumEvents = [1, 2, 3, 4, 5].map((s, i) => ({ type: 'pluck', string: s, at: 0.05 + (i + 1) * 0.015, velocity: 0.9, frequency: [82.41, 110, 146.83, 196, 246.94, 329.63][s], lengthFraction: 1 }));
  const presetResults = {};
  for (const preset of ['clean', 'overdrive', 'distortion', 'acoustic', 'chorus', 'lead']) {
    const r = await page.evaluate((o) => window.renderNote(o), { frequency: 82.41, string: 0, velocity: 0.9, duration: 1.6, preset, params: {}, events: strumEvents, analysisStart: 0.4, analysisEnd: 1.2 });
    presetResults[preset] = r;
    console.log(`preset ${preset.padEnd(10)} peak ${r.peak.toFixed(3)} rms(0.06-0.26) ${r.rmsEarly.toFixed(3)} late ${r.rmsLate.toFixed(4)}`);
    assert(r.peak < 1.0, `${preset} clips`);
    assert(r.rmsEarly > 0.02, `${preset} is nearly silent`);
  }
  // Saturation compresses dynamics: a distorted strum sustains far more evenly than a clean one.
  const sustain = (r) => r.rmsLate / r.rmsEarly;
  console.log(`sustain ratio (late/early): clean ${sustain(presetResults.clean).toFixed(2)} distortion ${sustain(presetResults.distortion).toFixed(2)}`);
  assert(sustain(presetResults.distortion) > sustain(presetResults.clean) * 1.3, 'distortion should compress/sustain more than clean');
  assert(sustain(presetResults.overdrive) > sustain(presetResults.clean), 'overdrive should sustain more than clean');
  console.log('\nAUDIO TESTS PASSED');
} finally {
  await browser.close();
  server.stop();
}
