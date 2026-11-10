// Unit tests for the string synthesis core, run directly in Node (no browser):
// the same StringBank drives the AudioWorklet and the ScriptProcessor fallback.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { StringBank } from '../src/audio/string-processor.js';

const STRINGS = [8.0, 7.5, 7.0, 5.5, 5.0, 4.5].map((t60, i) => ({
  t60,
  brightness: [0.5, 0.47, 0.44, 0.3, 0.26, 0.22][i],
  dispersion: [-0.12, -0.1, -0.08, -0.04, -0.03, -0.02][i],
  outGain: 0.6,
}));

function makeBank(fs = 48000) {
  return new StringBank(fs, { strings: STRINGS, pickupDistances: [0.135, 0.21], pickupWeights: [0.72, 0.72], coupling: 0.0003 });
}

/** Render `seconds` of audio in blocks of `block` frames (128 = worklet, 512 = ScriptProcessor). */
function render(bank, seconds, { block = 128, messages = [] } = {}) {
  const total = Math.floor(seconds * bank.fs);
  const out = new Float32Array(total);
  for (const m of messages) bank.enqueue(m, 0);
  for (let pos = 0; pos < total; pos += block) {
    const n = Math.min(block, total - pos);
    bank.process(out.subarray(pos, pos + n), pos / bank.fs);
  }
  return out;
}

const rms = (a, from, to, fs) => {
  const s = a.subarray(Math.floor(from * fs), Math.floor(to * fs));
  let sum = 0;
  for (let i = 0; i < s.length; i++) sum += s[i] * s[i];
  return Math.sqrt(sum / s.length);
};

/** Fundamental from the autocorrelation peak nearest the expected period (parabolic interpolation). */
function measurePitch(a, fs, expected, from = 0.3, to = 1.0) {
  const s = a.subarray(Math.floor(from * fs), Math.floor(to * fs));
  const p0 = fs / expected;
  const lo = Math.floor(p0 * 0.94), hi = Math.ceil(p0 * 1.06);
  const acf = (lag) => { let sum = 0; for (let i = 0; i + lag < s.length; i++) sum += s[i] * s[i + lag]; return sum; };
  let best = lo, bestVal = -Infinity;
  const vals = new Map();
  for (let lag = lo - 1; lag <= hi + 1; lag++) { const v = acf(lag); vals.set(lag, v); if (lag >= lo && lag <= hi && v > bestVal) { bestVal = v; best = lag; } }
  const y0 = vals.get(best - 1), y1 = vals.get(best), y2 = vals.get(best + 1);
  const shift = 0.5 * (y0 - y2) / (y0 - 2 * y1 + y2);
  return fs / (best + shift);
}

const cents = (a, b) => 1200 * Math.log2(a / b);

test('synthesised pitch matches equal temperament at 44.1, 48 and 96 kHz', () => {
  for (const fs of [44100, 48000, 96000]) {
    for (const [string, frequency, lengthFraction] of [[0, 82.4069, 1], [1, 110, 1], [3, 293.665, 2 ** (-7 / 12)], [5, 659.255, 0.5], [5, 1318.51, 0.25]]) {
      const bank = makeBank(fs);
      const out = render(bank, 1.1, { messages: [{ type: 'pluck', string, frequency, lengthFraction, velocity: 0.8, pickPosition: 0.14, damping: 0, time: 0.02 }] });
      const f = measurePitch(out, fs, frequency);
      assert.ok(Math.abs(cents(f, frequency)) < 3, `${frequency} Hz @ ${fs}: measured ${f.toFixed(3)} (${cents(f, frequency).toFixed(2)} cents)`);
    }
  }
});

test('the ScriptProcessor block size renders exactly the same audio as the worklet block size', () => {
  const messages = () => [
    { type: 'pluck', string: 1, frequency: 110, lengthFraction: 1, velocity: 0.9, pickPosition: 0.14, damping: 0, time: 0.013 },
    { type: 'pluck', string: 3, frequency: 196, lengthFraction: 1, velocity: 0.7, pickPosition: 0.14, damping: 0, time: 0.027 },
    { type: 'pitch', string: 1, frequency: 123.47, glide: 0.05, lengthFraction: 0.89, time: 0.2 },
    { type: 'damp', string: 3, amount: 1, time: 0.35 },
  ];
  const a = render(makeBank(), 0.5, { block: 128, messages: messages() });
  const b = render(makeBank(), 0.5, { block: 512, messages: messages() });
  let maxDiff = 0;
  for (let i = 0; i < a.length; i++) maxDiff = Math.max(maxDiff, Math.abs(a[i] - b[i]));
  assert.ok(maxDiff < 1e-9, `block size must not change the output (max diff ${maxDiff})`);
});

test('notes sustain, decay and are muted by a release', () => {
  const fs = 48000;
  const pluck = { type: 'pluck', string: 1, frequency: 110, lengthFraction: 1, velocity: 0.8, pickPosition: 0.14, damping: 0, time: 0.02 };
  const ring = render(makeBank(fs), 3, { messages: [{ ...pluck }] });
  assert.ok(rms(ring, 0.05, 0.25, fs) > 0.02, 'audible attack');
  assert.ok(rms(ring, 2.7, 2.95, fs) > rms(ring, 0.05, 0.25, fs) * 0.03, 'still ringing after 3 s');
  assert.ok(rms(ring, 2.7, 2.95, fs) < rms(ring, 0.05, 0.25, fs), 'decaying');
  const muted = render(makeBank(fs), 1.5, { messages: [{ ...pluck }, { type: 'damp', string: 1, amount: 1, time: 0.8 }] });
  assert.ok(rms(muted, 1.0, 1.2, fs) < rms(muted, 0.6, 0.78, fs) * 0.01, 'muted within 200 ms');
});

test('velocity controls loudness', () => {
  const fs = 48000;
  const at = (velocity) => rms(render(makeBank(fs), 0.4, { messages: [{ type: 'pluck', string: 3, frequency: 196, lengthFraction: 1, velocity, pickPosition: 0.14, damping: 0, time: 0.02 }] }), 0.05, 0.3, fs);
  assert.ok(at(1) > at(0.2) * 2.5);
});

test('unison notes on several strings decay (passive coupling), output stays finite and bounded', () => {
  const fs = 44100;
  const d5 = 587.33;
  const messages = [[1, 17], [2, 12], [3, 7], [4, 3]].map(([string, fret], i) => ({ type: 'pluck', string, frequency: d5, lengthFraction: 2 ** (-fret / 12), velocity: 1, pickPosition: 0.14, damping: 0, time: 0.02 + i * 0.01 }));
  const out = render(makeBank(fs), 8, { messages });
  let peak = 0;
  for (let i = 0; i < out.length; i++) { assert.ok(Number.isFinite(out[i])); peak = Math.max(peak, Math.abs(out[i])); }
  assert.ok(peak < 4);
  assert.ok(rms(out, 7.5, 8, fs) < rms(out, 0.5, 1, fs) * 0.1, 'must decay by 20 dB in 8 s');
});

test('sympathetic resonance is present but subtle', () => {
  const fs = 48000;
  // Pluck A2; its 3rd harmonic (330 Hz) matches the open high E string, which should ring faintly.
  const bank = makeBank(fs);
  bank.enqueue({ type: 'pitch', string: 5, frequency: 329.628, glide: 0, lengthFraction: 1 }, 0);
  bank.enqueue({ type: 'damp', string: 5, amount: 0 }, 0); // an open, undamped string
  render(bank, 1.0, { messages: [{ type: 'pluck', string: 1, frequency: 110, lengthFraction: 1, velocity: 1, pickPosition: 0.14, damping: 0, time: 0.02 }] });
  const voice = bank.voices[5];
  let energy = 0;
  for (let i = 0; i < voice.buf.length; i++) energy += voice.buf[i] * voice.buf[i];
  assert.ok(energy > 0, 'the open string picked up sympathetic vibration');
  let driven = 0;
  for (let i = 0; i < bank.voices[1].buf.length; i++) driven += bank.voices[1].buf[i] ** 2;
  assert.ok(energy < driven * 0.05, 'and stays well below the played string');
});

test('garbage messages are ignored and cannot poison the model', () => {
  const fs = 48000;
  const bank = makeBank(fs);
  const messages = [
    null, 42, {}, { type: 'pluck' }, { type: 'pluck', string: 9, frequency: 100 },
    { type: 'pluck', string: 0, frequency: NaN, velocity: NaN, pickPosition: Infinity, damping: 'x' },
    { type: 'pitch', string: 1, frequency: -5, glide: NaN },
    { type: 'damp', string: 2, amount: NaN },
    { type: 'config', coupling: NaN, pickupDistances: [NaN], t60: -1 },
    { type: 'noise', string: 3, level: Infinity, duration: NaN },
    { type: 'pluck', string: 4, frequency: 246.94, lengthFraction: 1, velocity: 0.8, pickPosition: 0.14, damping: 0, time: 0.1 },
  ];
  const out = render(bank, 0.6, { messages });
  for (let i = 0; i < out.length; i++) assert.ok(Number.isFinite(out[i]), `sample ${i} is not finite`);
  assert.ok(rms(out, 0.15, 0.5, fs) > 0.01, 'a valid pluck after the garbage still sounds');
});

test('panic silences everything', () => {
  const fs = 48000;
  const bank = makeBank(fs);
  render(bank, 0.3, { messages: [0, 1, 2, 3, 4, 5].map((string) => ({ type: 'pluck', string, frequency: 110 * (string + 1), lengthFraction: 1, velocity: 1, pickPosition: 0.14, damping: 0, time: 0.01 })) });
  bank.enqueue({ type: 'panic' }, 0.3);
  const after = new Float32Array(4800);
  bank.process(after, 0.3);
  assert.ok(rms(after, 0.01, 0.1, fs) < 1e-6);
});
