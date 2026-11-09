/**
 * Small DSP helpers used by the audio engine: wave-shaping curves, a
 * procedural reverb impulse response, and parameter mapping utilities.
 */

export const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
export const lerp = (a, b, t) => a + (b - a) * t;
/** Exponential (logarithmic-feeling) mapping of t in [0,1] onto [min,max]. */
export const expMap = (min, max, t) => min * Math.pow(max / min, clamp(t, 0, 1));
export const dbToGain = (db) => Math.pow(10, db / 20);
export const gainToDb = (g) => 20 * Math.log10(Math.max(1e-9, g));

/**
 * Asymmetric soft-clipping transfer curve. `amount` 0 is practically linear;
 * 1 approaches hard clipping. A small bias adds even harmonics for a
 * tube-like character.
 */
export function makeDistortionCurve(amount, samples = 4096) {
  const a = clamp(amount, 0, 1);
  const k = 0.6 + Math.pow(a, 1.5) * 38;
  const bias = 0.09 * a;
  const curve = new Float32Array(samples);
  const norm = Math.tanh(k * (1 + bias)) - Math.tanh(k * bias);
  for (let i = 0; i < samples; i++) {
    const x = (i / (samples - 1)) * 2 - 1;
    curve[i] = (Math.tanh(k * (x + bias)) - Math.tanh(k * bias)) / norm;
  }
  return curve;
}

/**
 * Procedural stereo room/plate impulse response: exponentially decaying noise
 * whose high frequencies die faster than its lows, plus a handful of early
 * reflections. Deterministic (seeded) so renders are reproducible.
 */
export function makeReverbImpulse(ctx, { duration = 2.6, decay = 2.8, predelay = 0.015, damping = 0.3, seed = 1 } = {}) {
  const rate = ctx.sampleRate;
  const length = Math.max(1, Math.floor(rate * duration));
  const buffer = ctx.createBuffer(2, length, rate);
  let s = seed >>> 0 || 1;
  const rand = () => {
    s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0;
    return (s / 4294967296) * 2 - 1;
  };
  const pre = Math.floor(predelay * rate);
  const early = [0.011, 0.019, 0.027, 0.034, 0.047, 0.061].map((t, i) => ({ at: Math.floor(t * rate), gain: 0.55 * Math.pow(0.78, i) }));
  for (let ch = 0; ch < 2; ch++) {
    const data = buffer.getChannelData(ch);
    let lp = 0;
    for (let i = pre; i < length; i++) {
      const t = (i - pre) / rate;
      const env = Math.pow(1 - (i - pre) / (length - pre), decay);
      // Progressive low-pass: cutoff falls as the tail decays.
      const coef = clamp(damping + (1 - damping) * (i - pre) / (length - pre) * 0.85, 0, 0.98);
      const n = rand();
      lp = coef * lp + (1 - coef) * n;
      data[i] = lp * env;
      void t;
    }
    for (const e of early) {
      const idx = pre + e.at + (ch === 1 ? 37 : 0);
      if (idx < length) data[idx] += e.gain * (ch === 0 ? 1 : -0.8);
    }
  }
  // Normalise to a sensible peak
  let peak = 0;
  for (let ch = 0; ch < 2; ch++) {
    const d = buffer.getChannelData(ch);
    for (let i = 0; i < d.length; i++) peak = Math.max(peak, Math.abs(d[i]));
  }
  if (peak > 0) {
    for (let ch = 0; ch < 2; ch++) {
      const d = buffer.getChannelData(ch);
      for (let i = 0; i < d.length; i++) d[i] /= peak * 1.6;
    }
  }
  return buffer;
}

/** Schedule a smooth parameter change (avoids zipper noise / clicks). */
export function setParamSmooth(param, value, ctx, time = 0.02) {
  const now = ctx.currentTime;
  param.cancelScheduledValues(now);
  param.setValueAtTime(param.value, now);
  param.linearRampToValueAtTime(value, now + time);
}
