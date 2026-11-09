/**
 * GuitarStringProcessor — an AudioWorkletProcessor modelling one guitar string.
 *
 * Physical model (extended Karplus-Strong / digital waveguide, after Jaffe & Smith):
 *
 *   excitation ──►(+)──► delay line (fractional, cubic interpolation) ──► loop low-pass
 *                  ▲      (length = period − filter phase delay)              │
 *                  │                                                          ▼
 *                  └──────────── × loop gain ◄──── dispersion all-pass ◄──────┘
 *
 *   output = Σ pickups [ w(t − p·P/2) − w(t − (P − p·P/2)) ]   (pickup-position comb)
 *
 *  - Pitch: the loop length is set so that period = sampleRate / f0 *including*
 *    the phase delay of the loop filters at f0 (computed analytically), so the
 *    synthesized pitch matches equal temperament, not an approximation of it.
 *  - Pluck: a burst of low-passed noise shaped by a pick-position comb filter.
 *    Velocity controls level, brightness, pick-click level and a brief sharp
 *    pitch bend (tension modulation) that relaxes over ~50 ms.
 *  - Damping: loop gain derived from a target T60; "release" and "mute" simply
 *    shorten the T60 so the string rings down the way a muted string does.
 *  - Slides / hammer-ons: the loop length glides to the new value.
 *  - Sympathetic resonance: the node input (a quiet mix of the other strings)
 *    is injected into the loop.
 *
 * Messages (port.postMessage):
 *   { type:'config', ... }             per-string parameters (t60, brightness, dispersion, pickups…)
 *   { type:'pitch', frequency, glide, lengthFraction, time? }
 *   { type:'pluck', velocity, pickPosition, damping, frequency?, lengthFraction?, time? }
 *   { type:'damp', amount, time? }     0 = ring freely, 1 = full mute
 *   { type:'noise', level, duration, time? }  fret/slide noise burst
 *   { type:'panic' }                   clear everything
 *   { type:'ping', id }                echoed back as { type:'pong', id } once all earlier messages were received
 */

const TWO_PI = Math.PI * 2;
const BUFFER_SIZE = 8192; // samples; enough for ~5.8 Hz at 48 kHz
const MASK = BUFFER_SIZE - 1;

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
  // one-pole low-pass  H1 = (1-a) / (1 - a e^{-jw})
  const cw = Math.cos(omega), sw = Math.sin(omega);
  let re = 1 - lpA * cw, im = lpA * sw; // denominator of H1 (conjugate handled below)
  // angle(H1) = -angle(1 - a e^{-jw}) = -atan2(a sin w, 1 - a cos w)
  let phase = -Math.atan2(im, re);
  // first-order all-pass  H2 = (c + e^{-jw}) / (1 + c e^{-jw})
  const nRe = apC + cw, nIm = -sw;
  const dRe = 1 + apC * cw, dIm = -apC * sw;
  phase += Math.atan2(nIm, nRe) - Math.atan2(dIm, dRe);
  return -phase / omega;
}

class GuitarStringProcessor extends AudioWorkletProcessor {
  constructor(options) {
    super();
    const o = (options && options.processorOptions) || {};
    this.index = o.stringIndex ?? 0;
    this.buf = new Float32Array(BUFFER_SIZE);
    this.write = 0;

    // Loop state
    this.targetDelay = 200;
    this.curDelay = 200;
    this.glideCoef = 1;
    this.lp = 0;
    this.apX = 0; this.apY = 0;
    this.loopGain = 0.99;
    this.lpA = 0.4;      // loop low-pass coefficient (higher = darker / faster HF decay)
    this.apC = -0.05;    // dispersion all-pass coefficient (negative = stiff string)
    this.frequency = 110;
    this.lengthFraction = 1;
    this.damping = 0;    // 0 = ringing, 1 = fully muted

    // Per-string character
    this.t60Ring = o.t60 ?? 5;
    this.t60Muted = 0.04;
    this.baseLpA = o.brightness ?? 0.4;
    this.baseApC = o.dispersion ?? -0.05;
    this.outGain = o.outGain ?? 0.5;
    this.couplingGain = o.couplingGain ?? 1;
    this.pickupDistances = o.pickupDistances ?? [0.063]; // fraction of scale length from the bridge
    this.pickupWeights = o.pickupWeights ?? [1];
    this.clickLevel = o.clickLevel ?? 0.08;
    this.brightnessScale = 1;

    // Pickup taps (samples behind the write head)
    this.tapA = [10]; this.tapB = [190];

    // Excitation / click / noise bursts
    this.exc = new Float32Array(4096); this.excLen = 0; this.excPos = 0;
    this.click = new Float32Array(512); this.clickLen = 0; this.clickPos = 0;

    // Output DC blocker
    this.dcX = 0; this.dcY = 0;

    this.rng = new Xorshift(0x1234567 + this.index * 7919);
    this.events = [];
    this.active = false;
    this.quietBlocks = 0;

    this.port.onmessage = (e) => this.enqueue(e.data);
    this.setPitch(this.frequency, 0, 1);
  }

  /* ------------------------------------------------------------------ */
  /* Messages                                                           */
  /* ------------------------------------------------------------------ */

  enqueue(msg) {
    if (!msg) return;
    if (msg.type === 'config') { this.configure(msg); return; }
    if (msg.type === 'panic') { this.panic(); return; }
    if (msg.type === 'ping') { this.port.postMessage({ type: 'pong', id: msg.id }); return; }
    const time = typeof msg.time === 'number' ? msg.time : -1;
    if (time <= currentTime) { this.handle(msg); return; }
    // keep sorted by time
    let i = this.events.length;
    while (i > 0 && this.events[i - 1].time > time) i--;
    this.events.splice(i, 0, { ...msg, time });
  }

  configure(c) {
    if (c.t60 !== undefined) this.t60Ring = c.t60;
    if (c.brightness !== undefined) this.baseLpA = c.brightness;
    if (c.brightnessScale !== undefined) this.brightnessScale = c.brightnessScale;
    if (c.dispersion !== undefined) this.baseApC = c.dispersion;
    if (c.outGain !== undefined) this.outGain = c.outGain;
    if (c.couplingGain !== undefined) this.couplingGain = c.couplingGain;
    if (c.clickLevel !== undefined) this.clickLevel = c.clickLevel;
    if (c.pickupDistances) { this.pickupDistances = c.pickupDistances.slice(); this.pickupWeights = (c.pickupWeights || c.pickupDistances.map(() => 1)).slice(); }
    this.setPitch(this.frequency, 0, this.lengthFraction, true);
  }

  handle(msg) {
    switch (msg.type) {
      case 'pitch':
        this.setPitch(msg.frequency, msg.glide ?? 0, msg.lengthFraction ?? this.lengthFraction);
        break;
      case 'pluck':
        if (msg.frequency) this.setPitch(msg.frequency, 0, msg.lengthFraction ?? this.lengthFraction);
        this.pluck(msg.velocity ?? 0.8, msg.pickPosition ?? 0.13, msg.damping ?? 0);
        break;
      case 'damp':
        this.setDamping(msg.amount ?? 1);
        break;
      case 'noise':
        this.noiseBurst(msg.level ?? 0.03, msg.duration ?? 0.03);
        break;
      default:
        break;
    }
  }

  panic() {
    this.buf.fill(0);
    this.lp = 0; this.apX = 0; this.apY = 0;
    this.excLen = this.excPos = 0;
    this.clickLen = this.clickPos = 0;
    this.events.length = 0;
    this.active = false;
  }

  /* ------------------------------------------------------------------ */
  /* Model control                                                      */
  /* ------------------------------------------------------------------ */

  /**
   * Set the loop so that it resonates at `frequency` Hz.
   * `glide` (seconds) is the time constant of the pitch transition.
   */
  setPitch(frequency, glide, lengthFraction, keepCurrent = false) {
    if (!(frequency > 10)) return;
    this.frequency = frequency;
    this.lengthFraction = Math.max(0.05, Math.min(1, lengthFraction || 1));
    this.period = sampleRate / frequency;
    const wasActive = this.active;
    const previousDelay = this.curDelay;
    this.recomputeLoop();
    if (!keepCurrent) {
      if (glide <= 0 || !wasActive) {
        this.curDelay = this.targetDelay;
        this.glideCoef = 1;
      } else {
        // Glide from where the string currently is towards the new length:
        // exponential approach reaching ~98% of the change in `glide` seconds.
        this.curDelay = previousDelay;
        this.glideCoef = 1 - Math.exp(-4 / (glide * sampleRate));
      }
    }
    this.updateTaps(this.period);
  }

  /**
   * Derive loop filter coefficients, loop gain and the compensated loop length
   * from the current frequency and damping. Called whenever either changes.
   */
  recomputeLoop() {
    const frequency = this.frequency;
    const period = this.period || (sampleRate / frequency);
    // Loop low-pass gets a touch brighter for higher notes so short strings keep sparkle.
    const brightnessComp = Math.min(1, Math.max(0.55, 1 - (frequency - 150) / 1800));
    const ringLpA = this.baseLpA * this.brightnessScale * brightnessComp;
    // Muting also darkens the string (flesh damps high partials first).
    this.lpA = Math.min(0.95, Math.max(0.02, ringLpA + this.damping * 0.35));
    this.apC = this.baseApC;
    // Interpolate T60 geometrically between ringing and muted values.
    const t60 = Math.exp(Math.log(this.t60Ring) * (1 - this.damping) + Math.log(this.t60Muted) * this.damping);
    // Loop gain per pass so that amplitude falls 60 dB in t60 seconds.
    this.loopGain = Math.pow(10, -3 * period / (t60 * sampleRate));
    // Loop length compensated for the filters' phase delay at the fundamental.
    const omega = TWO_PI * frequency / sampleRate;
    const filterDelay = loopFilterPhaseDelay(omega, this.lpA, this.apC);
    const delay = Math.max(2.5, period - filterDelay);
    if (this.curDelay === this.targetDelay) this.curDelay = delay; // not gliding: follow exactly
    this.targetDelay = delay;
  }

  updateTaps(period) {
    const n = this.pickupDistances.length;
    if (this.tapA.length !== n) { this.tapA = new Array(n); this.tapB = new Array(n); }
    for (let k = 0; k < n; k++) {
      // Pickup position as a fraction of the *vibrating* length.
      let p = this.pickupDistances[k] / this.lengthFraction;
      p = Math.min(0.49, Math.max(0.01, p));
      const a = Math.max(1, Math.round(p * period * 0.5));
      const b = Math.max(a + 1, Math.round(period - p * period * 0.5));
      this.tapA[k] = Math.min(a, MASK - 4);
      this.tapB[k] = Math.min(b, MASK - 4);
    }
  }

  setDamping(amount) {
    this.damping = Math.min(1, Math.max(0, amount));
    this.recomputeLoop();
  }

  /** Excite the string. velocity 0..1, pickPosition = fraction of scale length from the bridge. */
  pluck(velocity, pickPosition, damping) {
    velocity = Math.min(1, Math.max(0.02, velocity));
    this.setDamping(damping);
    const period = this.period || (sampleRate / this.frequency);
    // Picking a ringing string: the pick briefly stops the string before releasing it.
    if (this.active) {
      const keep = 0.25;
      for (let i = 0; i < BUFFER_SIZE; i++) this.buf[i] *= keep;
      this.lp *= keep;
    }
    const mu = Math.min(0.45, Math.max(0.04, pickPosition / this.lengthFraction));
    const combDelay = Math.max(1, Math.round(mu * period));
    const burst = Math.ceil(period);
    const len = Math.min(this.exc.length, burst + combDelay);

    // Deterministic pluck: an impulse through two one-pole low-passes. The
    // first, with its corner just below the fundamental, gives the 1/k envelope
    // of a plucked string's velocity wave (what a magnetic pickup senses); the
    // second (velocity dependent) sets the attack brightness: a soft touch is
    // dark, a hard pick is bright. A quieter noise component adds the pick's
    // scrape so no two plucks are identical.
    const a1 = Math.exp(-TWO_PI * (0.75 * this.frequency) / sampleRate);
    const cutoff = 1200 + Math.pow(velocity, 1.6) * 9500;
    const a2 = Math.exp(-TWO_PI * cutoff / sampleRate);
    const noiseLevel = 0.06 + 0.1 * velocity;
    const tmp = new Float32Array(len);
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
      const direct = tmp[i] || 0;
      const delayed = i - combDelay >= 0 ? tmp[i - combDelay] || 0 : 0;
      // Pick-position comb filter: zeros at harmonics whose node is under the pick.
      let v = (direct - delayed) * amp;
      if (v > 1.5) v = 1.5; else if (v < -1.5) v = -1.5;
      this.exc[i] = v;
    }
    this.excLen = len;
    this.excPos = 0;

    // Pick click: a few ms of bright noise straight to the output.
    const clickLen = Math.min(this.click.length, Math.round(sampleRate * 0.0025));
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
    this.glideCoef = 1 - Math.exp(-4 / (0.06 * sampleRate));
    this.active = true;
    this.quietBlocks = 0;
  }

  /** Fret/slide noise: a short band-limited burst injected into the loop. */
  noiseBurst(level, duration) {
    const len = Math.min(this.exc.length, Math.max(8, Math.round(duration * sampleRate)));
    const a = Math.exp(-TWO_PI * 2500 / sampleRate);
    let lp = 0;
    for (let i = 0; i < len; i++) {
      lp = a * lp + (1 - a) * this.rng.next();
      const env = Math.sin(Math.PI * i / len);
      this.exc[i] = lp * env * level * 6;
    }
    this.excLen = len; this.excPos = 0;
    this.active = true;
    this.quietBlocks = 0;
  }

  /* ------------------------------------------------------------------ */
  /* DSP                                                                */
  /* ------------------------------------------------------------------ */

  readDelayed(delay) {
    // Cubic (3rd-order Lagrange) fractional delay read.
    const n = delay | 0;
    const d = delay - n;
    const w = this.write;
    const buf = this.buf;
    const x0 = buf[(w - (n - 1)) & MASK];
    const x1 = buf[(w - n) & MASK];
    const x2 = buf[(w - (n + 1)) & MASK];
    const x3 = buf[(w - (n + 2)) & MASK];
    const dm1 = d - 1, dm2 = d - 2, dp1 = d + 1;
    const c0 = -d * dm1 * dm2 / 6;
    const c1 = dp1 * dm1 * dm2 / 2;
    const c2 = -dp1 * d * dm2 / 2;
    const c3 = dp1 * d * dm1 / 6;
    return c0 * x0 + c1 * x1 + c2 * x2 + c3 * x3;
  }

  process(inputs, outputs) {
    const out = outputs[0][0];
    const input = inputs[0] && inputs[0][0];
    const frames = out.length;
    const blockStart = currentTime;
    const buf = this.buf;
    let peak = 0;

    // Fire scheduled events that fall inside this block (sample-accurate).
    let nextEvent = this.events.length ? this.events[0] : null;
    const secondsPerFrame = 1 / sampleRate;

    for (let i = 0; i < frames; i++) {
      const t = blockStart + i * secondsPerFrame;
      while (nextEvent && nextEvent.time <= t + secondsPerFrame * 0.5) {
        this.events.shift();
        this.handle(nextEvent);
        nextEvent = this.events.length ? this.events[0] : null;
      }

      // Pitch glide
      if (this.curDelay !== this.targetDelay) {
        const diff = this.targetDelay - this.curDelay;
        if (Math.abs(diff) < 1e-4) this.curDelay = this.targetDelay;
        else this.curDelay += diff * this.glideCoef;
      }

      // Read the loop
      const y = this.readDelayed(this.curDelay);
      // Loop low-pass (string damping, frequency dependent)
      const a = this.lpA;
      this.lp = a * this.lp + (1 - a) * y;
      // Dispersion all-pass
      const c = this.apC;
      const ap = c * this.lp + this.apX - c * this.apY;
      this.apX = this.lp; this.apY = ap;

      let v = ap * this.loopGain;
      // Excitation
      if (this.excPos < this.excLen) v += this.exc[this.excPos++];
      // Sympathetic coupling from the other strings
      if (input) v += input[i] * this.couplingGain;
      // Safety: keep the loop bounded (never audible in normal operation)
      if (v > 2) v = 2; else if (v < -2) v = -2;
      buf[this.write] = v;

      // Pickup read-out: displacement at the pickup position(s)
      let o = 0;
      const w = this.write;
      for (let k = 0; k < this.tapA.length; k++) {
        o += (buf[(w - this.tapA[k]) & MASK] - buf[(w - this.tapB[k]) & MASK]) * this.pickupWeights[k];
      }
      // Pick click
      if (this.clickPos < this.clickLen) o += this.click[this.clickPos++];
      // Output DC blocker
      const dc = o - this.dcX + 0.9975 * this.dcY;
      this.dcX = o; this.dcY = dc;
      const s = dc * this.outGain;
      out[i] = s;
      const abs = s < 0 ? -s : s;
      if (abs > peak) peak = abs;

      this.write = (w + 1) & MASK;
    }

    if (peak < 1e-6 && this.excPos >= this.excLen) {
      if (++this.quietBlocks > 40 && this.active) {
        this.active = false;
        // Flush tiny residues so a silent string is truly silent.
        buf.fill(0); this.lp = 0; this.apX = 0; this.apY = 0;
      }
    } else {
      this.quietBlocks = 0;
    }
    // Copy mono to any additional output channels
    for (let ch = 1; ch < outputs[0].length; ch++) outputs[0][ch].set(out);
    return true;
  }
}

registerProcessor('guitar-string-processor', GuitarStringProcessor);
