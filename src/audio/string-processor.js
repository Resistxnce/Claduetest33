/**
 * The string synthesis core: six waveguide strings coupled through a bridge.
 *
 * This file is used two ways:
 *   - as an AudioWorklet module (`audioWorklet.addModule`): it registers
 *     'guitar-strings-processor', which runs a StringBank on the audio thread;
 *   - as an ordinary ES module: `StringBank` is exported so the engine can run
 *     the very same model in a ScriptProcessorNode where AudioWorklet is not
 *     available (plain-http pages on a phone or tablet), and so the DSP can be
 *     unit-tested in Node.
 * It has no imports and touches no globals except the worklet registration at
 * the bottom.
 *
 * Per string (extended Karplus-Strong / digital waveguide, after Jaffe & Smith):
 *
 *   excitation ──►(+)──► delay line (fractional, cubic interpolation) ──► loop low-pass
 *                  ▲      (length = period − filter phase delay)              │
 *                  │                                                          ▼
 *                  └─(− bridge)─── × loop gain ◄──── dispersion all-pass ◄────┘
 *
 *   output = Σ pickups [ w(t − p·P/2) − w(t − (P − p·P/2)) ]   (pickup-position comb)
 *
 *  - Pitch: the loop length is set so that period = sampleRate / f0 *including*
 *    the phase delay of the loop filters at f0 (computed analytically), so the
 *    synthesized pitch matches equal temperament at any sample rate.
 *  - Pluck: a low-passed impulse (1/k velocity-wave spectrum) plus a little pick
 *    noise, shaped by a pick-position comb. Velocity controls level, brightness,
 *    pick-click level and a brief sharp pitch bend that relaxes over ~50 ms.
 *  - Damping: loop gain derived from a target T60; "release" and "mute" shorten
 *    the T60 so the string rings down the way a muted string does. Strings
 *    nobody is playing rest at a light "idle" damping.
 *  - Slides / hammer-ons / bends: the loop length and the pickup taps glide
 *    together to the new values (no discontinuity in the read-out).
 *  - Sympathetic resonance: the strings share a bridge. Each sample the bridge
 *    takes a small fraction of the summed string motion and that same amount is
 *    removed from every string's reflection (v = y − c·lowpass(Σy)). The
 *    coupling is passive — it can only move or absorb energy, never create it —
 *    so it is stable for any combination of notes.
 *
 * Messages (StringBank.enqueue / port.postMessage); `string` is the string
 * index 0..5 (omit on 'config'/'panic' to address all strings):
 *   { type:'config', string?, ... }            parameters (t60, brightness, pickups, coupling…)
 *   { type:'pitch', string, frequency, glide, lengthFraction, time? }
 *   { type:'pluck', string, velocity, pickPosition, damping, frequency?, lengthFraction?, time? }
 *   { type:'damp', string, amount, time? }     0 = ring freely, 1 = full mute
 *   { type:'noise', string, level, duration, time? }  fret/slide noise burst
 *   { type:'panic' }                           clear everything
 *   { type:'ping', id }                        (worklet only) echoed back as { type:'pong', id }
 */

const TWO_PI = Math.PI * 2;
const BUFFER_SIZE = 8192; // samples; enough for ~5.8 Hz at 48 kHz
const MASK = BUFFER_SIZE - 1;
const STRING_COUNT = 6;
const MAX_LOOP_GAIN = 0.99995;
const finite = (v, fallback) => (Number.isFinite(v) ? v : fallback);

class Xorshift {
  constructor(seed) { this.s = seed >>> 0 || 0x9e3779b9; }
  next() { // uniform in [-1, 1)
    let x = this.s;
    x ^= x << 13; x >>>= 0;
    x ^= x >>> 17;
    x ^= x << 5; x >>>= 0;
    this.s = x;
    return (x / 4294967296) * 2 - 1;
  }
}

/** Phase delay (in samples) at angular frequency `omega` of the loop filters. */
function loopFilterPhaseDelay(omega, lpA, apC) {
  // one-pole low-pass  H1 = (1-a) / (1 - a e^{-jw});  angle(H1) = -atan2(a sin w, 1 - a cos w)
  const cw = Math.cos(omega), sw = Math.sin(omega);
  let phase = -Math.atan2(lpA * sw, 1 - lpA * cw);
  // first-order all-pass  H2 = (c + e^{-jw}) / (1 + c e^{-jw})
  phase += Math.atan2(-sw, apC + cw) - Math.atan2(-apC * sw, 1 + apC * cw);
  return -phase / omega;
}

/** Magnitude of the one-pole loop low-pass at angular frequency `omega`. */
function lowpassMagnitude(omega, a) {
  return (1 - a) / Math.sqrt(1 - 2 * a * Math.cos(omega) + a * a);
}

/** One string: delay loop, excitation, pickup taps. */
class StringVoice {
  constructor(index, o = {}, fs = 48000) {
    this.index = index;
    this.fs = fs; // sample rate
    this.buf = new Float32Array(BUFFER_SIZE);
    this.write = 0;

    // Loop state
    this.targetDelay = 200;
    this.curDelay = 200;
    this.glideCoef = 1;
    this.lp = 0;
    this.apX = 0; this.apY = 0;
    this.loopGain = 0.99;
    this.lpA = 0.4;      // loop low-pass coefficient at this sample rate
    this.apC = -0.05;    // dispersion all-pass coefficient (negative = stiff string)
    this.frequency = 110;
    this.lengthFraction = 1;
    this.period = this.fs / 110;

    // Per-string character (brightness is specified for 48 kHz and converted)
    this.t60Ring = o.t60 ?? 5;
    this.t60Muted = 0.04;
    this.baseLpA = o.brightness ?? 0.4;
    this.baseApC = o.dispersion ?? -0.05;
    this.outGain = o.outGain ?? 0.5;
    this.pickupDistances = o.pickupDistances ?? [0.06]; // fraction of scale length from the bridge
    this.pickupWeights = o.pickupWeights ?? [1];
    this.clickLevel = o.clickLevel ?? 0.08;
    this.brightnessScale = 1;
    this.idleDamping = o.idleDamping ?? 0.5; // strings nobody is playing ring only briefly in sympathy
    this.damping = this.idleDamping;         // 0 = ringing, 1 = fully muted

    // Pickup taps (samples behind the write head; fractional, glide with the pitch)
    this.tapA = [10]; this.tapB = [190];
    this.tapATarget = [10]; this.tapBTarget = [190];

    // Excitation / click bursts and scratch space (no allocation while playing)
    this.exc = new Float32Array(4096); this.excLen = 0; this.excPos = 0;
    this.scratch = new Float32Array(4096);
    this.click = new Float32Array(512); this.clickLen = 0; this.clickPos = 0;

    // Output DC blocker
    this.dcX = 0; this.dcY = 0;

    this.rng = new Xorshift(0x1234567 + index * 7919);
    this.active = false;
    this.sounding = false; // true while a played note is meant to ring (not muted / idle)
    this.quiet = 0;
    this.peak = 0;
    this.setPitch(this.frequency, 0, 1);
  }

  configure(c) {
    if (Number.isFinite(c.t60) && c.t60 > 0) this.t60Ring = c.t60;
    if (Number.isFinite(c.brightness)) this.baseLpA = Math.min(0.98, Math.max(0, c.brightness));
    if (Number.isFinite(c.brightnessScale)) this.brightnessScale = c.brightnessScale;
    if (Number.isFinite(c.dispersion)) this.baseApC = Math.min(0.95, Math.max(-0.95, c.dispersion)); // all-pass pole inside the unit circle
    if (Number.isFinite(c.outGain)) this.outGain = Math.min(4, Math.max(0, c.outGain));
    if (Number.isFinite(c.clickLevel)) this.clickLevel = c.clickLevel;
    if (Number.isFinite(c.idleDamping)) this.idleDamping = c.idleDamping;
    if (Array.isArray(c.pickupDistances) && c.pickupDistances.length && c.pickupDistances.every(Number.isFinite)) {
      this.pickupDistances = c.pickupDistances.slice();
      const w = Array.isArray(c.pickupWeights) && c.pickupWeights.length === c.pickupDistances.length ? c.pickupWeights : c.pickupDistances.map(() => 1);
      this.pickupWeights = w.map((x) => finite(x, 1));
    }
    this.recomputeLoop();
    // Pickup changes crossfade by gliding the taps for a few milliseconds.
    this.updateTaps(this.active ? 0.006 : 0);
  }

  panic() {
    this.buf.fill(0);
    this.lp = 0; this.apX = 0; this.apY = 0;
    this.dcX = 0; this.dcY = 0;
    this.excLen = this.excPos = 0;
    this.clickLen = this.clickPos = 0;
    this.active = false;
    this.quiet = 0;
    this.damping = this.idleDamping;
    this.recomputeLoop();
    this.curDelay = this.targetDelay;
    this.glideCoef = 1;
    this.updateTaps(0);
  }

  /**
   * Set the loop so that it resonates at `frequency` Hz.
   * `glide` (seconds) is the time the pitch transition takes.
   */
  setPitch(frequency, glide, lengthFraction) {
    if (!(frequency > 10) || !Number.isFinite(frequency)) return;
    frequency = Math.min(frequency, this.fs / 8);
    this.frequency = frequency;
    this.lengthFraction = Math.max(0.05, Math.min(1, finite(lengthFraction, this.lengthFraction) || 1));
    this.period = this.fs / frequency;
    const previousDelay = this.curDelay;
    this.recomputeLoop();
    const gliding = glide > 0 && this.active;
    if (gliding) {
      // Glide from where the string currently is towards the new length:
      // exponential approach reaching ~98% of the change in `glide` seconds.
      this.curDelay = previousDelay;
      this.glideCoef = 1 - Math.exp(-4 / (glide * this.fs));
    } else {
      this.curDelay = this.targetDelay;
      this.glideCoef = 1;
    }
    this.updateTaps(gliding ? glide : 0);
  }

  /**
   * Derive loop filter coefficients, loop gain and the compensated loop length
   * from the current frequency and damping. Called whenever either changes.
   */
  recomputeLoop() {
    const frequency = this.frequency;
    const period = this.period;
    // Loop low-pass gets a touch brighter for higher notes so short strings keep sparkle.
    const brightnessComp = Math.min(1, Math.max(0.55, 1 - (frequency - 150) / 1800));
    // Brightness values are designed at 48 kHz; keep the same analogue corner at any rate.
    const design = Math.min(0.95, Math.max(0.02, this.baseLpA * this.brightnessScale * brightnessComp + this.damping * 0.35));
    this.lpA = Math.min(0.98, Math.pow(design, 48000 / this.fs));
    this.apC = this.baseApC;
    // Interpolate T60 geometrically between ringing and muted values.
    const t60 = Math.exp(Math.log(this.t60Ring) * (1 - this.damping) + Math.log(this.t60Muted) * this.damping);
    // Loop gain per pass so that the fundamental falls 60 dB in t60 seconds,
    // making up for what the loop low-pass removes at f0 (never reaching 1).
    const omega = TWO_PI * frequency / this.fs;
    const target = Math.pow(10, -3 * period / (t60 * this.fs));
    this.loopGain = Math.min(MAX_LOOP_GAIN, target / lowpassMagnitude(omega, this.lpA));
    // Loop length compensated for the filters' phase delay at the fundamental.
    const filterDelay = loopFilterPhaseDelay(omega, this.lpA, this.apC);
    const delay = Math.max(2.5, period - filterDelay);
    if (this.curDelay === this.targetDelay) this.curDelay = delay; // not gliding: follow exactly
    this.targetDelay = delay;
  }

  /** Pickup tap targets for the current note; `glide` > 0 moves the taps smoothly. */
  updateTaps(glide) {
    const n = this.pickupDistances.length;
    if (this.tapATarget.length !== n) {
      this.tapA = new Array(n).fill(0); this.tapB = new Array(n).fill(0);
      this.tapATarget = new Array(n).fill(0); this.tapBTarget = new Array(n).fill(0);
      glide = 0;
    }
    const period = this.period;
    for (let k = 0; k < n; k++) {
      // Pickup position as a fraction of the *vibrating* length. The comb
      // |sin(k·π·p)| is symmetric about the middle of the string.
      let p = this.pickupDistances[k] / this.lengthFraction;
      if (p > 0.5) p = 1 - p;
      p = Math.min(0.5, Math.max(0.05, p));
      const a = Math.max(1, p * period * 0.5);
      const b = Math.min(MASK - 4, Math.max(a + 1, period - p * period * 0.5));
      this.tapATarget[k] = a;
      this.tapBTarget[k] = b;
      if (!(glide > 0)) { this.tapA[k] = a; this.tapB[k] = b; }
    }
    this.tapCoef = glide > 0 ? 1 - Math.exp(-4 / (glide * this.fs)) : 1;
  }

  setDamping(amount) {
    this.damping = Math.min(1, Math.max(0, finite(amount, 1)));
    if (this.damping >= 0.9) this.sounding = false;
    this.recomputeLoop();
  }

  /** Kill sympathetic residue on a string nobody is playing (the muting hand rests on it too). */
  choke() {
    if (this.sounding || !this.active) return;
    this.damping = 1;
    this.recomputeLoop();
  }

  /** Excite the string. velocity 0..1, pickPosition = fraction of scale length from the bridge. */
  pluck(velocity, pickPosition, damping) {
    velocity = Math.min(1, Math.max(0.02, finite(velocity, 0.8)));
    pickPosition = finite(pickPosition, 0.14);
    this.setDamping(finite(damping, 0));
    this.sounding = this.damping < 0.9;
    const period = this.period;
    // Picking a ringing string: the pick briefly stops the string before releasing it.
    if (this.active) {
      const keep = 0.25;
      const live = Math.min(BUFFER_SIZE, Math.ceil(this.curDelay) + 8);
      for (let i = 1; i <= live; i++) this.buf[(this.write - i) & MASK] *= keep;
      this.lp *= keep; this.apX *= keep; this.apY *= keep;
    }
    let mu = pickPosition / this.lengthFraction;
    if (mu > 0.5) mu = 1 - mu;
    mu = Math.min(0.5, Math.max(0.04, mu));
    const combDelay = Math.max(1, Math.round(mu * period));
    const burst = Math.min(this.scratch.length, Math.ceil(period));
    const len = Math.min(this.exc.length, burst + combDelay);

    // Deterministic pluck: an impulse through two one-pole low-passes. The
    // first, with its corner just below the fundamental, gives the 1/k envelope
    // of a plucked string's velocity wave (what a magnetic pickup senses); the
    // second (velocity dependent) sets the attack brightness: a soft touch is
    // dark, a hard pick is bright. A quieter noise component adds the pick's
    // scrape so no two plucks are identical.
    const a1 = Math.exp(-TWO_PI * (0.75 * this.frequency) / this.fs);
    const cutoff = Math.min(this.fs * 0.45, 1200 + Math.pow(velocity, 1.6) * 9500);
    const a2 = Math.exp(-TWO_PI * cutoff / this.fs);
    const noiseLevel = 0.06 + 0.1 * velocity;
    const tmp = this.scratch;
    let y1 = 0, y2 = 0, nz = 0, energy = 0;
    for (let i = 0; i < burst; i++) {
      const impulse = i === 0 ? 1 : 0;
      y1 = a1 * y1 + (1 - a1) * impulse;
      y2 = a2 * y2 + (1 - a2) * y1;
      nz = a2 * nz + (1 - a2) * this.rng.next();
      const noiseEnv = 1 - i / burst;
      const v = y2 + nz * noiseEnv * noiseLevel * (1 - a1);
      tmp[i] = v;
      energy += v * v;
    }
    // Normalise so the RMS over one period follows velocity.
    const rms = Math.sqrt(energy / burst) || 1e-6;
    const amp = (0.16 * Math.pow(velocity, 0.9)) / rms;
    for (let i = 0; i < len; i++) {
      const direct = i < burst ? tmp[i] : 0;
      const j = i - combDelay;
      const delayed = j >= 0 && j < burst ? tmp[j] : 0;
      // Pick-position comb filter: zeros at harmonics whose node is under the pick.
      let v = (direct - delayed) * amp;
      if (v > 1.5) v = 1.5; else if (v < -1.5) v = -1.5;
      this.exc[i] = v;
    }
    this.excLen = len;
    this.excPos = 0;

    // Pick click: a few ms of bright noise straight to the output.
    const clickLen = Math.min(this.click.length, Math.round(this.fs * 0.0025));
    const clickAmp = this.clickLevel * velocity * velocity;
    let hp = 0, prev = 0;
    for (let i = 0; i < clickLen; i++) {
      const n = this.rng.next();
      hp = 0.6 * (hp + n - prev); prev = n;
      const env = 1 - i / clickLen;
      this.click[i] = hp * env * env * clickAmp;
    }
    this.clickLen = clickLen; this.clickPos = 0;

    // Tension modulation: a hard pluck starts slightly sharp and relaxes.
    const bend = 1 - 0.006 * velocity * velocity;
    this.curDelay = this.targetDelay * bend;
    this.glideCoef = 1 - Math.exp(-4 / (0.06 * this.fs));
    this.active = true;
    this.quiet = 0;
  }

  /** Fret/slide noise: a short band-limited burst injected into the loop. */
  noiseBurst(level, duration) {
    level = Math.min(0.2, Math.max(0, finite(level, 0.03)));
    const len = Math.min(this.exc.length, Math.max(8, Math.round(finite(duration, 0.03) * this.fs)));
    // The loop resonates: a burst that lasts many periods (a short, high note) would pump in far
    // more energy than a pluck, so its level follows the loop length. Finger squeak is also a
    // wound-string sound; the plain strings only whisper.
    const loopScale = Math.min(1, Math.sqrt(this.period / (this.fs / 110)));
    const gain = level * 6 * loopScale * (this.index <= 2 ? 1 : 0.4);
    // An excitation still being fed in (an earlier burst, the tail of a pluck) is kept, not cut off:
    // truncating a zero-mean burst would leave a DC offset circulating in the loop.
    const pending = Math.max(0, this.excLen - this.excPos);
    if (pending > 0) this.exc.copyWithin(0, this.excPos, this.excLen);
    const total = Math.max(len, pending);
    for (let i = pending; i < total; i++) this.exc[i] = 0;
    const a = Math.exp(-TWO_PI * 2500 / this.fs);
    const burst = this.scratch.length >= len ? this.scratch : new Float32Array(len);
    let lp = 0;
    let sum = 0, envSum = 0;
    for (let i = 0; i < len; i++) {
      lp = a * lp + (1 - a) * this.rng.next();
      const env = Math.sin(Math.PI * i / len);
      burst[i] = lp * env * gain;
      sum += burst[i]; envSum += env;
    }
    // Zero-mean, so the burst itself cannot leave a DC offset either.
    const mean = envSum > 0 ? sum / envSum : 0;
    for (let i = 0; i < len; i++) this.exc[i] += burst[i] - mean * Math.sin(Math.PI * i / len);
    this.excLen = total; this.excPos = 0;
    this.active = true;
    this.quiet = 0;
  }

  /** Stage 1 of a sample: the wave returning from the string, after loop filters and losses. */
  read() {
    // Pitch glide
    if (this.curDelay !== this.targetDelay) {
      const diff = this.targetDelay - this.curDelay;
      if (diff < 1e-4 && diff > -1e-4) this.curDelay = this.targetDelay;
      else this.curDelay += diff * this.glideCoef;
    }
    // Cubic (3rd-order Lagrange) fractional delay read
    const delay = this.curDelay;
    const n = delay | 0;
    const d = delay - n;
    const w = this.write;
    const buf = this.buf;
    const x0 = buf[(w - (n - 1)) & MASK];
    const x1 = buf[(w - n) & MASK];
    const x2 = buf[(w - (n + 1)) & MASK];
    const x3 = buf[(w - (n + 2)) & MASK];
    const dm1 = d - 1, dm2 = d - 2, dp1 = d + 1;
    const y = (-d * dm1 * dm2 / 6) * x0 + (dp1 * dm1 * dm2 / 2) * x1 + (-dp1 * d * dm2 / 2) * x2 + (dp1 * d * dm1 / 6) * x3;
    // Loop low-pass (string damping, frequency dependent)
    const a = this.lpA;
    this.lp = a * this.lp + (1 - a) * y;
    // Dispersion all-pass
    const c = this.apC;
    const ap = c * this.lp + this.apX - c * this.apY;
    this.apX = this.lp; this.apY = ap;
    return ap * this.loopGain;
  }

  /** Stage 2 of a sample: write the wave leaving the bridge end and read the pickups. */
  write1(v) {
    if (this.excPos < this.excLen) v += this.exc[this.excPos++];
    // Safety: keep the loop bounded and finite (never audible in normal operation)
    if (!(v > -2)) v = v < 0 ? -2 : 0; else if (v > 2) v = 2;
    const buf = this.buf;
    const w = this.write;
    buf[w] = v;
    // Pickup read-out: displacement at the pickup position(s), linearly interpolated taps
    let o = 0;
    const taps = this.tapA.length;
    for (let k = 0; k < taps; k++) {
      let ta = this.tapA[k], tb = this.tapB[k];
      if (ta !== this.tapATarget[k] || tb !== this.tapBTarget[k]) {
        const da = this.tapATarget[k] - ta, db = this.tapBTarget[k] - tb;
        ta = da < 1e-3 && da > -1e-3 ? this.tapATarget[k] : ta + da * this.tapCoef;
        tb = db < 1e-3 && db > -1e-3 ? this.tapBTarget[k] : tb + db * this.tapCoef;
        this.tapA[k] = ta; this.tapB[k] = tb;
      }
      const ia = ta | 0, fa = ta - ia;
      const ib = tb | 0, fb = tb - ib;
      const sa = buf[(w - ia) & MASK] * (1 - fa) + buf[(w - ia - 1) & MASK] * fa;
      const sb = buf[(w - ib) & MASK] * (1 - fb) + buf[(w - ib - 1) & MASK] * fb;
      o += (sa - sb) * this.pickupWeights[k];
    }
    if (this.clickPos < this.clickLen) o += this.click[this.clickPos++];
    // Output DC blocker
    const dc = o - this.dcX + 0.9975 * this.dcY;
    this.dcX = o; this.dcY = dc;
    this.write = (w + 1) & MASK;
    const s = dc * this.outGain;
    const abs = s < 0 ? -s : s;
    if (abs > this.peak) this.peak = abs;
    if (abs > 1e-5) this.active = true; // sympathetic vibration counts as activity too
    return s;
  }

  /** Once per block: detect silence, flush residues, return idle strings to their resting damping. */
  endBlock() {
    if (this.peak < 1e-6 && this.excPos >= this.excLen) {
      if (++this.quiet > 40 && this.active) {
        this.active = false;
        this.sounding = false;
        this.buf.fill(0); this.lp = 0; this.apX = 0; this.apY = 0;
        if (this.damping !== this.idleDamping) { this.damping = this.idleDamping; this.recomputeLoop(); }
      }
    } else {
      this.quiet = 0;
    }
    this.peak = 0;
  }
}

/**
 * Six coupled strings. Platform independent: give it a sample rate, feed it
 * messages with `enqueue(msg, now)` and pull audio with `process(out, blockStart)`.
 */
export class StringBank {
  /**
   * @param {number} fs sample rate in Hz
   * @param {object} [o] { strings:[{t60, brightness, dispersion, outGain}], pickupDistances, pickupWeights, coupling }
   */
  constructor(fs, o = {}) {
    this.fs = fs;
    const configs = o.strings || [];
    this.voices = [];
    for (let i = 0; i < STRING_COUNT; i++) {
      this.voices.push(new StringVoice(i, { ...(configs[i] || {}), pickupDistances: o.pickupDistances, pickupWeights: o.pickupWeights }, fs));
    }
    // Bridge coupling: fraction of the summed string motion taken by the bridge
    this.coupling = Math.min(0.01, Math.max(0, finite(o.coupling, 0.0003)));
    this.bridgeLp = 0;
    this.bridgeA = Math.exp(-TWO_PI * 1500 / fs);
    this.y = new Float64Array(STRING_COUNT);
    /** How strongly each string is moving right now (peak of its wave at the bridge, smoothed downward). */
    this.levels = new Float32Array(STRING_COUNT);
    this.blockPeaks = new Float32Array(STRING_COUNT);
    this.events = [];
  }

  /* ------------------------------------------------------------------ */
  /* Messages                                                           */
  /* ------------------------------------------------------------------ */

  /** Apply a message now, or queue it for its `time` (seconds on the caller's audio clock). */
  enqueue(msg, now = 0) {
    if (!msg || typeof msg.type !== 'string') return;
    if (msg.type === 'config' || msg.type === 'panic') { this.handle(msg); return; }
    let time = Number.isFinite(msg.time) ? msg.time : -1;
    // `cancel` drops whatever is still scheduled for the string (mute all: no late plucks from a strum).
    if (msg.cancel) this.events = this.events.filter((e) => e.string !== msg.string);
    // Messages for one string take effect in the order they were sent: a mute or pitch
    // change sent right after a strum waits for that string's scheduled pluck instead of
    // overtaking it (the queue is sorted, so the last match is the latest).
    for (let i = this.events.length - 1; i >= 0; i--) {
      if (this.events[i].string === msg.string) { if (this.events[i].time > time) time = this.events[i].time; break; }
    }
    if (time <= now) { this.handle(msg); return; }
    // keep sorted by time (stable for equal times)
    let i = this.events.length;
    while (i > 0 && this.events[i - 1].time > time) i--;
    msg.time = time;
    this.events.splice(i, 0, msg);
  }

  targets(msg) {
    if (Number.isInteger(msg.string) && msg.string >= 0 && msg.string < STRING_COUNT) return [this.voices[msg.string]];
    return msg.type === 'config' || msg.type === 'panic' ? this.voices : [];
  }

  handle(msg) {
    if (msg.type === 'config' && Number.isFinite(msg.coupling)) this.coupling = Math.min(0.01, Math.max(0, msg.coupling));
    if (msg.type === 'panic') { this.events.length = 0; this.bridgeLp = 0; }
    for (const voice of this.targets(msg)) {
      switch (msg.type) {
        case 'config':
          voice.configure(msg);
          break;
        case 'panic':
          voice.panic();
          break;
        case 'pitch':
          voice.setPitch(msg.frequency, finite(msg.glide, 0), msg.lengthFraction);
          break;
        case 'pluck':
          if (msg.frequency) voice.setPitch(msg.frequency, 0, msg.lengthFraction);
          voice.pluck(msg.velocity, msg.pickPosition, msg.damping);
          break;
        case 'damp':
          if (!Number.isFinite(msg.amount)) break; // garbage must not mute a ringing string
          voice.setDamping(msg.amount);
          // A muting hand also stops strings that were only ringing in sympathy.
          if (voice.damping >= 0.9) for (const other of this.voices) other.choke();
          break;
        case 'noise':
          voice.noiseBurst(msg.level, msg.duration);
          break;
        default:
          break;
      }
    }
  }

  /* ------------------------------------------------------------------ */
  /* DSP                                                                */
  /* ------------------------------------------------------------------ */

  /**
   * Render one block of mono audio.
   * @param {Float32Array} out
   * @param {number} blockStart time of out[0] on the same clock as message times
   */
  process(out, blockStart) {
    const frames = out.length;
    const dt = 1 / this.fs;
    const voices = this.voices;
    const y = this.y;
    const c = this.coupling;
    const ba = this.bridgeA;
    let bridge = this.bridgeLp;
    let nextEvent = this.events.length ? this.events[0] : null;
    const peaks = this.blockPeaks;
    peaks.fill(0);

    for (let i = 0; i < frames; i++) {
      // Fire scheduled events that fall on this sample.
      if (nextEvent) {
        const t = blockStart + (i + 0.5) * dt;
        while (nextEvent && nextEvent.time <= t) {
          this.events.shift();
          this.handle(nextEvent);
          nextEvent = this.events.length ? this.events[0] : null;
        }
      }
      // Waves arriving at the bridge from every string
      let sum = 0;
      for (let s = 0; s < STRING_COUNT; s++) {
        const v = voices[s].read(); y[s] = v; sum += v;
        const a = v < 0 ? -v : v;
        if (a > peaks[s]) peaks[s] = a;
      }
      // The bridge moves a little with the summed string motion (low-passed) …
      bridge = ba * bridge + (1 - ba) * sum;
      if (!(bridge > -12 && bridge < 12)) bridge = 0;
      const take = c * bridge;
      // … and that motion is taken out of every string's reflection.
      let o = 0;
      for (let s = 0; s < STRING_COUNT; s++) o += voices[s].write1(y[s] - take);
      out[i] = o;
    }
    this.bridgeLp = bridge;
    // Level meter per string: jumps up with the signal, falls 60 dB in a quarter of a second.
    const fall = Math.pow(10, (-3 * frames) / (this.fs * 0.25));
    for (let s = 0; s < STRING_COUNT; s++) {
      voices[s].endBlock();
      const held = this.levels[s] * fall;
      this.levels[s] = peaks[s] > held ? peaks[s] : held;
    }
  }
}

/* -------------------------------------------------------------------------- */
/* AudioWorklet wrapper (only when loaded with audioWorklet.addModule)        */
/* -------------------------------------------------------------------------- */

if (typeof AudioWorkletProcessor !== 'undefined' && typeof registerProcessor === 'function') {
  class GuitarStringsProcessor extends AudioWorkletProcessor {
    constructor(options) {
      super();
      // `sampleRate` and `currentTime` are globals of the worklet scope.
      this.bank = new StringBank(sampleRate, (options && options.processorOptions) || {});
      this.port.onmessage = (e) => {
        const msg = e.data;
        if (msg && msg.type === 'ping') this.port.postMessage({ type: 'pong', id: msg.id });
        else this.bank.enqueue(msg, currentTime);
      };
    }

    process(inputs, outputs) {
      const out = outputs[0][0];
      this.bank.process(out, currentTime);
      for (let ch = 1; ch < outputs[0].length; ch++) outputs[0][ch].set(out);
      // Tell the page how loud each string still is, about 15 times a second while anything moves
      // (and once more when everything has stopped).
      this.blocks = (this.blocks || 0) + 1;
      if (this.blocks % 24 === 0) {
        let moving = false;
        for (let s = 0; s < STRING_COUNT; s++) if (this.bank.levels[s] > 1e-5) moving = true;
        if (moving || this.wasMoving) this.port.postMessage({ type: 'levels', levels: Array.from(this.bank.levels) });
        this.wasMoving = moving;
      }
      return true;
    }
  }
  registerProcessor('guitar-strings-processor', GuitarStringsProcessor);
}
