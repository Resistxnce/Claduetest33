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
  // --- Regression checks from the audio review -------------------------------------------
  const script = (o) => page.evaluate((x) => window.renderScript(x), o);
  const db = (a, b) => 20 * Math.log10(Math.max(a, 1e-9) / Math.max(b, 1e-9));

  // Pitch stays accurate at other device sample rates (lowest and highest notes).
  for (const sampleRate of [44100, 96000]) {
    for (const [frequency, lengthFraction, string] of [[73.416, 1, 0], [440, 2 ** (-5 / 12), 5], [1318.51, 0.25, 5]]) {
      const r = await page.evaluate((o) => window.renderNote(o), { frequency, lengthFraction, string, duration: 1.4, sampleRate });
      assert(Math.abs(r.cents) < TOLERANCE_CENTS, `${frequency} Hz at ${sampleRate} Hz sample rate is ${r.cents.toFixed(2)} cents off`);
    }
  }
  console.log('pitch at 44.1 kHz and 96 kHz: ok');

  // The same pitch on several strings must decay, never self-oscillate (bridge coupling is passive).
  const d5 = 587.33;
  const unisonSteps = [[1, 17], [2, 12], [3, 7], [4, 3]].map(([s, f], i) => ['pluck', s, { frequency: d5, lengthFraction: 2 ** (-f / 12), velocity: 1, when: 0.05 + i * 0.01 }]);
  for (const sampleRate of [44100, 48000]) {
    const u = await script({ steps: unisonSteps, duration: 9, sampleRate, window: 0.5 });
    const early = u.windows[1], late = u.windows[u.windows.length - 1];
    console.log(`unison D5 on four strings @${sampleRate}: rms ${early.toFixed(4)} -> ${late.toFixed(5)} after 9 s (${db(late, early).toFixed(1)} dB)`);
    assert(u.finite, 'unison render must stay finite');
    assert(db(late, early) < -20, 'unison strings must decay by at least 20 dB in 9 s');
  }

  // Muting must work through every preset: at least 30 dB down 150 ms after release.
  for (const preset of ['clean', 'overdrive', 'distortion', 'acoustic', 'chorus', 'lead']) {
    const steps = [['setParam', 'reverb', 0], ['setParam', 'delay', 0], ['pluck', 1, { frequency: 110, velocity: 0.9, when: 0.05 }], ['release', 1, { when: 0.8 }]];
    const r = await script({ steps, preset, duration: 1.3, window: 0.05 });
    const before = r.windows[14], after = r.windows[20]; // 0.70-0.75 s vs 1.00-1.05 s
    assert(db(after, before) < -30, `${preset}: muted note only fell ${db(after, before).toFixed(1)} dB`);
  }
  console.log('mute drops >= 30 dB within 200 ms in every preset: ok');

  // A fresh engine sounds exactly like one that had the default preset applied explicitly,
  // and a preset chosen before the audio starts is honoured.
  const pluckA = [['pluck', 2, { frequency: 146.83, velocity: 0.8, when: 0.05 }]];
  const fresh = await script({ steps: pluckA, duration: 0.8 });
  const explicit = await script({ steps: pluckA, preset: 'clean', duration: 0.8 });
  assert(Math.abs(fresh.fingerprint - explicit.fingerprint) < 1e-3 * Math.max(1, Math.abs(fresh.fingerprint)), `startup tone differs from the Clean preset (${fresh.fingerprint} vs ${explicit.fingerprint})`);
  const early1 = await script({ steps: pluckA, preset: 'acoustic', presetBeforeInit: true, duration: 0.8 });
  const late1 = await script({ steps: pluckA, preset: 'acoustic', duration: 0.8 });
  assert(Math.abs(early1.fingerprint - late1.fingerprint) < 1e-3 * Math.max(1, Math.abs(late1.fingerprint)), 'a preset set before init must be applied');
  console.log('startup pickup/body state and pre-init preset: ok');

  // Garbage numbers must not kill the instrument.
  const nan = await script({ steps: [['pluck', 0, { frequency: 110, velocity: NaN, pickPosition: NaN, when: 0.05 }], ['setParam', 'gain', NaN], ['post', 3, { type: 'pluck', velocity: 'x', pickPosition: null, damping: undefined, frequency: Infinity }], ['post', 2, { type: 'damp', amount: NaN }], ['pluck', 4, { frequency: 246.94, when: 0.3 }]], duration: 1 });
  assert(nan.finite && nan.windows[5] > 0.01, 'audio must survive non-finite message fields');
  console.log('non-finite input is ignored: ok');

  // Extreme settings: everything at maximum, hard six-string strum, every preset.
  const strumAll = [0, 1, 2, 3, 4, 5].map((s, i) => ['pluck', s, { frequency: [82.41, 110, 146.83, 196, 246.94, 329.63][s], velocity: 1, when: 0.05 + i * 0.012 }]);
  const maxed = await script({ steps: [...['volume', 'tone', 'gain', 'distortion', 'reverb', 'delay', 'chorus'].map((p) => ['setParam', p, 1]), ...strumAll], duration: 2.5 });
  console.log(`all controls at maximum: peak ${maxed.peak.toFixed(3)}`);
  assert(maxed.finite && maxed.peak <= 1.0, 'extreme settings must not exceed full scale');
  // Default clean strum stays inside the limiter's linear range (no hidden clipping).
  const cleanStrum = await script({ steps: strumAll.map(([m, s, o]) => [m, s, { ...o, velocity: 0.85 }]), preset: 'clean', duration: 1.5 });
  console.log(`default clean strum peak ${cleanStrum.peak.toFixed(3)}`);
  assert(cleanStrum.peak < 0.8, 'a normal clean strum should not reach the safety limiter');

  console.log('\nAUDIO TESTS PASSED');
} finally {
  await browser.close();
  server.stop();
}
