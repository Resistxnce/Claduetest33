/**
 * GuitarAudioEngine — owns the AudioContext, six string voices (AudioWorklet
 * nodes running the waveguide model in string-processor.js) and the amp /
 * effects chain.
 *
 *   strings[0..5] ─► stringMix ─► pickup EQ ─► body EQ ─► preGain ─► shaper ─► postGain
 *        ▲              │                                                  │
 *        └─ coupling ◄──┘ (sympathetic resonance, −45 dB, low-passed)      ▼
 *   tone LPF ─► cabinet ─► chorus ─► delay ─► reverb ─► master ─► limiter ─► analyser ─► out
 *
 * All timing uses AudioContext time; `when` arguments default to "now".
 * The engine is theory-agnostic: callers pass frequencies and vibrating
 * length fractions (which the processor needs for pickup/pick positions).
 */
import { makeDistortionCurve, makeSoftLimiterCurve, makeReverbImpulse, expMap, clamp, setParamSmooth } from './effects.js';
import { PRESETS, getPreset } from './presets.js';

export const STRING_COUNT = 6;

/** Per-string character, thick (index 0) to thin (index 5). */
const STRING_T60 = [8.0, 7.5, 7.0, 5.5, 5.0, 4.5];               // seconds to −60 dB when ringing
const STRING_BRIGHTNESS = [0.50, 0.47, 0.44, 0.30, 0.26, 0.22];   // loop low-pass coefficient (higher = darker)
const STRING_DISPERSION = [-0.12, -0.10, -0.08, -0.04, -0.03, -0.02]; // all-pass coefficient (stiffness)
const STRING_OUT_GAIN = [0.62, 0.62, 0.64, 0.72, 0.78, 0.84];

/** Pickup positions as a fraction of the scale length measured from the bridge (Stratocaster layout). */
export const PICKUP_DISTANCES = Object.freeze({ bridge: 0.0627, middle: 0.153, neck: 0.247 });

export const PICKUP_SELECTOR = Object.freeze([
  { position: 1, name: 'Bridge', short: 'B', pickups: ['bridge'], resonance: 4300, q: 2.4 },
  { position: 2, name: 'Bridge + Middle', short: 'B+M', pickups: ['bridge', 'middle'], resonance: 3900, q: 1.7 },
  { position: 3, name: 'Middle', short: 'M', pickups: ['middle'], resonance: 3600, q: 2.2 },
  { position: 4, name: 'Middle + Neck', short: 'M+N', pickups: ['middle', 'neck'], resonance: 3200, q: 1.7 },
  { position: 5, name: 'Neck', short: 'N', pickups: ['neck'], resonance: 2900, q: 2.0 },
]);

export const PARAM_DEFS = Object.freeze([
  { id: 'volume', name: 'Volume', min: 0, max: 1, default: 0.8 },
  { id: 'tone', name: 'Tone', min: 0, max: 1, default: 0.72 },
  { id: 'gain', name: 'Gain', min: 0, max: 1, default: 0.12 },
  { id: 'distortion', name: 'Distortion', min: 0, max: 1, default: 0.04 },
  { id: 'reverb', name: 'Reverb', min: 0, max: 1, default: 0.28 },
  { id: 'delay', name: 'Delay', min: 0, max: 1, default: 0 },
  { id: 'chorus', name: 'Chorus', min: 0, max: 1, default: 0 },
]);

export const DELAY_TIMES = Object.freeze([
  { id: 'eighth', name: '1/8 (250 ms)', seconds: 0.25 },
  { id: 'dotted', name: 'Dotted 1/8 (375 ms)', seconds: 0.375 },
  { id: 'quarter', name: '1/4 (500 ms)', seconds: 0.5 },
  { id: 'slap', name: 'Slapback (110 ms)', seconds: 0.11 },
]);

function makeWetDry(ctx) {
  const input = ctx.createGain();
  const output = ctx.createGain();
  const dry = ctx.createGain();
  const wet = ctx.createGain();
  input.connect(dry).connect(output);
  wet.connect(output);
  wet.gain.value = 0;
  return { input, output, dry, wet };
}

export class GuitarAudioEngine extends EventTarget {
  constructor() {
    super();
    this.ctx = null;
    this.ready = false;
    this.initializing = null;
    this.params = Object.fromEntries(PARAM_DEFS.map((d) => [d.id, d.default]));
    this.presetId = 'clean';
    this.body = 'electric';
    this.pickupPosition = 4;
    this.delayTimeId = 'dotted';
    this.palmMute = false;
    this.strings = [];
    // Default open-string pitches (standard tuning); the UI overrides these from the active tuning.
    const defaults = [82.4069, 110, 146.8324, 195.9977, 246.9417, 329.6276];
    this.stringState = Array.from({ length: STRING_COUNT }, (_, i) => ({ frequency: defaults[i], lengthFraction: 1, ringing: false, lastPluck: 0 }));
    this.moduleUrl = new URL('./string-processor.js', import.meta.url);
    this.pending = new Map();
    this.pingId = 0;
  }

  get now() {
    return this.ctx ? this.ctx.currentTime : 0;
  }

  get sampleRate() {
    return this.ctx ? this.ctx.sampleRate : 48000;
  }

  /**
   * Create the context and graph. Safe to call many times; must be triggered
   * from a user gesture the first time so the browser allows audio output.
   * @param {AudioContext} [existingContext] optional (e.g. an OfflineAudioContext for tests)
   */
  async init(existingContext = null) {
    if (this.ready) return this;
    if (this.initializing) return this.initializing;
    this.initializing = (async () => {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      this.ctx = existingContext || new Ctx({ latencyHint: 'interactive' });
      await this.ctx.audioWorklet.addModule(this.moduleUrl);
      this.buildGraph();
      this.applyAllParams();
      this.setPickupSelector(this.pickupPosition, true);
      this.applyBody(this.body);
      this.ready = true;
      this.dispatchEvent(new CustomEvent('ready'));
      return this;
    })();
    return this.initializing;
  }

  async resume() {
    if (!this.ctx) return;
    if (this.ctx.state !== 'running' && typeof this.ctx.resume === 'function') {
      try { await this.ctx.resume(); } catch { /* ignored: offline contexts */ }
    }
  }

  buildGraph() {
    const ctx = this.ctx;
    this.stringMix = ctx.createGain();
    this.stringMix.gain.value = 1;

    // Sympathetic coupling: a quiet, low-passed copy of all strings feeds every string.
    this.couplingGain = ctx.createGain();
    this.couplingGain.gain.value = 0.0005;
    this.couplingFilter = ctx.createBiquadFilter();
    this.couplingFilter.type = 'lowpass';
    this.couplingFilter.frequency.value = 1500;
    this.couplingFilter.Q.value = 0.5;
    this.stringMix.connect(this.couplingGain).connect(this.couplingFilter);

    this.strings = [];
    for (let i = 0; i < STRING_COUNT; i++) {
      const node = new AudioWorkletNode(ctx, 'guitar-string-processor', {
        numberOfInputs: 1,
        numberOfOutputs: 1,
        outputChannelCount: [1],
        processorOptions: {
          stringIndex: i,
          t60: STRING_T60[i],
          brightness: STRING_BRIGHTNESS[i],
          dispersion: STRING_DISPERSION[i],
          outGain: STRING_OUT_GAIN[i],
          pickupDistances: [PICKUP_DISTANCES.neck],
          pickupWeights: [1],
        },
      });
      node.onprocessorerror = (e) => console.error('String processor error', i, e);
      node.port.onmessage = (e) => this.onStringMessage(i, e.data);
      node.port.postMessage({ type: 'pitch', frequency: this.stringState[i].frequency, glide: 0, lengthFraction: this.stringState[i].lengthFraction });
      node.connect(this.stringMix);
      this.couplingFilter.connect(node);
      this.strings.push(node);
    }

    // Pickup: resonant low-pass (magnetic pickup + cable) and rumble filter.
    this.pickupFilter = ctx.createBiquadFilter();
    this.pickupFilter.type = 'lowpass';
    this.pickupFilter.frequency.value = 3200;
    this.pickupFilter.Q.value = 1.7;
    this.pickupHighpass = ctx.createBiquadFilter();
    this.pickupHighpass.type = 'highpass';
    this.pickupHighpass.frequency.value = 55;
    this.pickupHighpass.Q.value = 0.7;

    // Body EQ (used by the acoustic voicing, flat for electric).
    this.bodyFilters = [
      Object.assign(ctx.createBiquadFilter(), { type: 'peaking' }),
      Object.assign(ctx.createBiquadFilter(), { type: 'peaking' }),
      Object.assign(ctx.createBiquadFilter(), { type: 'peaking' }),
      Object.assign(ctx.createBiquadFilter(), { type: 'peaking' }),
    ];
    const bodyFreqs = [98, 205, 430, 2800];
    const bodyQs = [4.5, 3.5, 2, 1.1];
    this.bodyFilters.forEach((f, i) => { f.frequency.value = bodyFreqs[i]; f.Q.value = bodyQs[i]; f.gain.value = 0; });

    // Amp: pre-gain → wave shaper → post-gain
    this.preGain = ctx.createGain();
    this.shaper = ctx.createWaveShaper();
    this.shaper.oversample = '4x';
    this.shaper.curve = makeDistortionCurve(0);
    this.postGain = ctx.createGain();
    // Asymmetric clipping leaves a DC component behind; remove it.
    this.postHighpass = ctx.createBiquadFilter();
    this.postHighpass.type = 'highpass';
    this.postHighpass.frequency.value = 28;
    this.postHighpass.Q.value = 0.7;

    // Tone and cabinet
    this.toneFilter = ctx.createBiquadFilter();
    this.toneFilter.type = 'lowpass';
    this.toneFilter.Q.value = 0.8;
    this.cabLow = ctx.createBiquadFilter();
    this.cabLow.type = 'lowpass';
    this.cabLow.frequency.value = 6500;
    this.cabLow.Q.value = 0.9;
    this.cabPresence = ctx.createBiquadFilter();
    this.cabPresence.type = 'peaking';
    this.cabPresence.frequency.value = 2400;
    this.cabPresence.Q.value = 1.2;
    this.cabPresence.gain.value = 2;

    // Effects
    this.chorus = this.buildChorus();
    this.delay = this.buildDelay();
    this.reverb = this.buildReverb();

    // Master: volume → gentle glue compressor → soft safety limiter
    this.master = ctx.createGain();
    this.limiter = ctx.createDynamicsCompressor();
    this.limiter.threshold.value = -14;
    this.limiter.knee.value = 18;
    this.limiter.ratio.value = 3;
    this.limiter.attack.value = 0.004;
    this.limiter.release.value = 0.2;
    this.safetyIn = ctx.createGain();
    this.safetyIn.gain.value = 0.5;
    this.safety = ctx.createWaveShaper();
    this.safety.curve = makeSoftLimiterCurve();
    this.safety.oversample = '2x';
    this.analyser = ctx.createAnalyser();
    this.analyser.fftSize = 1024;
    this.analyser.smoothingTimeConstant = 0.6;
    this.levelBuffer = new Float32Array(this.analyser.fftSize);

    // Wire the chain
    let node = this.stringMix;
    node = node.connect(this.pickupFilter);
    node = node.connect(this.pickupHighpass);
    for (const f of this.bodyFilters) node = node.connect(f);
    node = node.connect(this.preGain);
    node = node.connect(this.shaper);
    node = node.connect(this.postGain);
    node = node.connect(this.postHighpass);
    node = node.connect(this.toneFilter);
    node = node.connect(this.cabLow);
    node = node.connect(this.cabPresence);
    node.connect(this.chorus.input);
    this.chorus.output.connect(this.delay.input);
    this.delay.output.connect(this.reverb.input);
    this.reverb.output.connect(this.master);
    this.master.connect(this.limiter).connect(this.safetyIn).connect(this.safety).connect(this.analyser).connect(ctx.destination);
  }

  buildChorus() {
    const ctx = this.ctx;
    const fx = makeWetDry(ctx);
    const merger = ctx.createChannelMerger(2);
    const voices = [
      { base: 0.012, depth: 0.0022, rate: 0.6 },
      { base: 0.019, depth: 0.0028, rate: 0.85 },
    ];
    fx.lfos = [];
    voices.forEach((v, i) => {
      const delay = ctx.createDelay(0.1);
      delay.delayTime.value = v.base;
      const lfo = ctx.createOscillator();
      lfo.type = 'sine';
      lfo.frequency.value = v.rate;
      const depth = ctx.createGain();
      depth.gain.value = v.depth;
      lfo.connect(depth).connect(delay.delayTime);
      lfo.start();
      fx.input.connect(delay);
      delay.connect(merger, 0, i);
      fx.lfos.push(lfo);
    });
    merger.connect(fx.wet);
    return fx;
  }

  buildDelay() {
    const ctx = this.ctx;
    const fx = makeWetDry(ctx);
    const delay = ctx.createDelay(2);
    delay.delayTime.value = 0.375;
    const feedback = ctx.createGain();
    feedback.gain.value = 0.38;
    const damp = ctx.createBiquadFilter();
    damp.type = 'lowpass';
    damp.frequency.value = 3200;
    fx.input.connect(delay);
    delay.connect(damp).connect(feedback).connect(delay);
    delay.connect(fx.wet);
    fx.delayNode = delay;
    fx.feedback = feedback;
    return fx;
  }

  buildReverb() {
    const ctx = this.ctx;
    const fx = makeWetDry(ctx);
    const convolver = ctx.createConvolver();
    convolver.buffer = makeReverbImpulse(ctx, { duration: 2.6, decay: 2.6, seed: 7 });
    const tone = ctx.createBiquadFilter();
    tone.type = 'lowpass';
    tone.frequency.value = 5500;
    fx.input.connect(convolver).connect(tone).connect(fx.wet);
    fx.convolver = convolver;
    return fx;
  }

  /* ------------------------------------------------------------------ */
  /* Parameters                                                         */
  /* ------------------------------------------------------------------ */

  getParams() {
    return { ...this.params };
  }

  setParam(id, value) {
    if (!(id in this.params)) throw new Error(`Unknown parameter ${id}`);
    this.params[id] = clamp(Number(value), 0, 1);
    if (this.ready) this.applyParam(id);
    this.dispatchEvent(new CustomEvent('param', { detail: { id, value: this.params[id] } }));
  }

  applyAllParams() {
    for (const id of Object.keys(this.params)) this.applyParam(id);
    this.applyDelayTime();
  }

  applyParam(id) {
    const ctx = this.ctx;
    const v = this.params[id];
    switch (id) {
      case 'volume':
        setParamSmooth(this.master.gain, Math.pow(v, 1.6) * 1.1, ctx);
        break;
      case 'tone':
        setParamSmooth(this.toneFilter.frequency, expMap(420, 12000, v), ctx, 0.03);
        break;
      case 'gain': {
        // Pre-gain drives the saturation stage; post-gain roughly matches loudness
        // (a saturated signal has a much higher RMS than a clean one).
        const drive = 1 + v * v * 60;
        setParamSmooth(this.preGain.gain, drive, ctx);
        setParamSmooth(this.postGain.gain, Math.pow(drive, -0.28), ctx);
        break;
      }
      case 'distortion':
        this.shaper.curve = makeDistortionCurve(v);
        break;
      case 'reverb':
        setParamSmooth(this.reverb.wet.gain, v * 0.9, ctx, 0.05);
        setParamSmooth(this.reverb.dry.gain, 1 - v * 0.35, ctx, 0.05);
        break;
      case 'delay':
        setParamSmooth(this.delay.wet.gain, v * 0.7, ctx, 0.05);
        break;
      case 'chorus':
        setParamSmooth(this.chorus.wet.gain, v * 0.8, ctx, 0.05);
        setParamSmooth(this.chorus.dry.gain, 1 - v * 0.3, ctx, 0.05);
        break;
      default:
        break;
    }
  }

  setDelayTime(id) {
    const t = DELAY_TIMES.find((d) => d.id === id);
    if (!t) throw new Error(`Unknown delay time ${id}`);
    this.delayTimeId = id;
    if (this.ready) this.applyDelayTime();
  }

  applyDelayTime() {
    const t = DELAY_TIMES.find((d) => d.id === this.delayTimeId);
    setParamSmooth(this.delay.delayNode.delayTime, t.seconds, this.ctx, 0.08);
  }

  /** Pickup selector position 1 (bridge) .. 5 (neck). */
  setPickupSelector(position, silent = false) {
    const sel = PICKUP_SELECTOR.find((p) => p.position === Number(position));
    if (!sel) throw new Error(`Unknown pickup position ${position}`);
    this.pickupPosition = sel.position;
    if (this.ready) {
      const distances = sel.pickups.map((p) => PICKUP_DISTANCES[p]);
      const weights = distances.map(() => (distances.length > 1 ? 0.72 : 1));
      if (this.body === 'electric') {
        for (const node of this.strings) node.port.postMessage({ type: 'config', pickupDistances: distances, pickupWeights: weights });
        setParamSmooth(this.pickupFilter.frequency, sel.resonance, this.ctx, 0.03);
        setParamSmooth(this.pickupFilter.Q, sel.q, this.ctx, 0.03);
      }
    }
    if (!silent) this.dispatchEvent(new CustomEvent('pickup', { detail: { position: this.pickupPosition } }));
  }

  /** 'electric' (magnetic pickups) or 'acoustic' (bright strings + resonant body). */
  applyBody(body) {
    this.body = body;
    if (!this.ready) return;
    const ctx = this.ctx;
    if (body === 'acoustic') {
      const gains = [5.5, 3.5, -2, 3];
      this.bodyFilters.forEach((f, i) => setParamSmooth(f.gain, gains[i], ctx, 0.05));
      setParamSmooth(this.pickupFilter.frequency, 16000, ctx, 0.03);
      setParamSmooth(this.pickupFilter.Q, 0.5, ctx, 0.03);
      setParamSmooth(this.cabLow.frequency, 11000, ctx, 0.03);
      for (const node of this.strings) {
        node.port.postMessage({ type: 'config', pickupDistances: [0.21], pickupWeights: [1.15], brightnessScale: 0.72, clickLevel: 0.14 });
      }
    } else {
      this.bodyFilters.forEach((f) => setParamSmooth(f.gain, 0, ctx, 0.05));
      setParamSmooth(this.cabLow.frequency, 6500, ctx, 0.03);
      for (const node of this.strings) node.port.postMessage({ type: 'config', brightnessScale: 1, clickLevel: 0.08 });
      this.setPickupSelector(this.pickupPosition, true);
    }
    this.dispatchEvent(new CustomEvent('body', { detail: { body } }));
  }

  setPreset(id) {
    const preset = getPreset(id);
    this.presetId = preset.id;
    for (const [k, v] of Object.entries(preset.params)) this.params[k] = v;
    this.body = preset.body;
    this.pickupPosition = preset.pickup;
    if (this.ready) {
      this.applyAllParams();
      this.applyBody(preset.body);
      this.setPickupSelector(preset.pickup, true);
    }
    this.dispatchEvent(new CustomEvent('preset', { detail: { preset, params: this.getParams() } }));
  }

  setPalmMute(on) {
    this.palmMute = !!on;
  }

  /* ------------------------------------------------------------------ */
  /* Playing                                                            */
  /* ------------------------------------------------------------------ */

  post(stringIdx, msg) {
    const node = this.strings[stringIdx];
    if (node) node.port.postMessage(msg);
  }

  /**
   * Set the pitch of a string. `glide` seconds > 0 slides from the current pitch.
   * `lengthFraction` is the vibrating length relative to the open string (2^(-fret/12)).
   */
  setStringPitch(stringIdx, frequency, { glide = 0, lengthFraction = 1, when } = {}) {
    const st = this.stringState[stringIdx];
    st.frequency = frequency;
    st.lengthFraction = lengthFraction;
    if (!this.ready) return;
    this.post(stringIdx, { type: 'pitch', frequency, glide, lengthFraction, time: when });
  }

  /**
   * Pluck a string.
   * @param {number} stringIdx
   * @param {object} o
   * @param {number} [o.velocity=0.8] 0..1
   * @param {number} [o.pickPosition=0.13] fraction of scale length from the bridge where the pick hits
   * @param {number} [o.damping] 0 (ring) .. 1 (fully muted "chuck"); defaults to palm-mute state
   * @param {number} [o.frequency] optionally (re)set the pitch in the same message
   * @param {number} [o.lengthFraction]
   * @param {number} [o.when] AudioContext time
   */
  pluck(stringIdx, { velocity = 0.8, pickPosition = 0.13, damping, frequency, lengthFraction, when } = {}) {
    const st = this.stringState[stringIdx];
    if (frequency) { st.frequency = frequency; st.lengthFraction = lengthFraction ?? st.lengthFraction; }
    st.ringing = damping === undefined || damping < 0.9;
    st.lastPluck = this.now;
    if (!this.ready) return;
    const damp = damping ?? (this.palmMute ? 0.62 : 0);
    this.post(stringIdx, {
      type: 'pluck',
      velocity: clamp(velocity, 0.02, 1),
      pickPosition: clamp(pickPosition, 0.03, 0.45),
      damping: damp,
      frequency: st.frequency,
      lengthFraction: st.lengthFraction,
      time: when,
    });
    this.dispatchEvent(new CustomEvent('pluck', { detail: { string: stringIdx, velocity, frequency: st.frequency, when: when ?? this.now } }));
  }

  /** Fret-hand release / mute: the string rings down quickly. */
  release(stringIdx, { amount = 1, when } = {}) {
    const st = this.stringState[stringIdx];
    st.ringing = false;
    if (!this.ready) return;
    this.post(stringIdx, { type: 'damp', amount, time: when });
  }

  /** Let a damped string ring again (e.g. palm mute lifted). */
  undamp(stringIdx, { when } = {}) {
    if (!this.ready) return;
    this.post(stringIdx, { type: 'damp', amount: this.palmMute ? 0.62 : 0, time: when });
  }

  /** Finger-on-string noise for slides. */
  slideNoise(stringIdx, level = 0.03, { when } = {}) {
    if (!this.ready) return;
    this.post(stringIdx, { type: 'noise', level, duration: 0.035, time: when });
  }

  onStringMessage(stringIdx, msg) {
    if (msg && msg.type === 'pong') {
      const resolve = this.pending.get(msg.id);
      if (resolve) { this.pending.delete(msg.id); resolve(); }
    }
  }

  /**
   * Resolves once every string processor has received all messages posted so
   * far (useful before offline rendering, or to detect a dead worklet).
   */
  sync() {
    if (!this.ready) return Promise.resolve();
    return Promise.all(this.strings.map((node) => new Promise((resolve) => {
      const id = ++this.pingId;
      this.pending.set(id, resolve);
      node.port.postMessage({ type: 'ping', id });
    })));
  }

  /** Mute all strings immediately. */
  releaseAll() {
    for (let i = 0; i < STRING_COUNT; i++) this.release(i);
  }

  panic() {
    for (let i = 0; i < STRING_COUNT; i++) this.post(i, { type: 'panic' });
  }

  /** Output level 0..1 (RMS) for meters. */
  getLevel() {
    if (!this.ready) return 0;
    this.analyser.getFloatTimeDomainData(this.levelBuffer);
    let sum = 0;
    for (let i = 0; i < this.levelBuffer.length; i++) sum += this.levelBuffer[i] * this.levelBuffer[i];
    return Math.sqrt(sum / this.levelBuffer.length);
  }
}

export { PRESETS };
