/**
 * GuitarAudioEngine — owns the AudioContext, the six-string worklet (the
 * waveguide model in string-processor.js, including the bridge coupling
 * between strings) and the amp / effects chain.
 *
 *   strings (one AudioWorkletNode, mono) ─► pickup EQ ─► body EQ ─► preGain ─► shaper ─► postGain
 *   ─► DC filter ─► tone LPF ─► cabinet ─► chorus ─► delay ─► reverb ─► master ─► soft limiter ─► analyser ─► out
 *
 * The graph is a straight chain (no feedback cycles outside the delay effect's
 * own DelayNode loop), so it renders identically in every browser.
 *
 * Two backends run the same string model (StringBank):
 *   - 'worklet': an AudioWorkletNode on the audio thread (lowest latency). Needs
 *     a secure context — https or localhost.
 *   - 'script': a ScriptProcessorNode on the main thread. Used automatically
 *     when AudioWorklet is unavailable, which is the case on a phone or tablet
 *     that opens the app over plain http from a computer on the local network.
 * All timing uses AudioContext time; `when` arguments default to "now".
 * The engine is theory-agnostic: callers pass frequencies and vibrating
 * length fractions (which the processor needs for pickup/pick positions).
 */
import { makeDistortionCurve, makeSoftLimiterCurve, makeReverbImpulse, expMap, clamp, setParamSmooth } from './effects.js';
import { PRESETS, getPreset } from './presets.js';
import { StringBank } from './string-processor.js';

export const STRING_COUNT = 6;

/** Per-string character, thick (index 0) to thin (index 5). */
const STRING_T60 = [8.0, 7.5, 7.0, 5.5, 5.0, 4.5];               // seconds to −60 dB when ringing
const STRING_BRIGHTNESS = [0.50, 0.47, 0.44, 0.30, 0.26, 0.22];   // loop low-pass coefficient (higher = darker)
const STRING_DISPERSION = [-0.12, -0.10, -0.08, -0.04, -0.03, -0.02]; // all-pass coefficient (stiffness)
const STRING_OUT_GAIN = [0.62, 0.62, 0.64, 0.72, 0.78, 0.84];
/** Fraction of the summed string motion absorbed by the shared bridge each sample (sympathetic resonance). */
const BRIDGE_COUPLING = 0.0003;

/**
 * Pickup positions as a fraction of the scale length measured from the bridge.
 * This is a 24-fret layout: the neck pickup sits a little closer to the bridge
 * than on a 21/22-fret guitar because the fingerboard reaches further.
 */
export const PICKUP_DISTANCES = Object.freeze({ bridge: 0.06, middle: 0.135, neck: 0.21 });

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

/** Block size of the ScriptProcessor fallback (frames). */
const SCRIPT_BUFFER_SIZE = 512;

/** iPhone / iPad (iPadOS reports itself as a Mac with touch). */
export function isIOS() {
  if (typeof navigator === 'undefined') return false;
  return /iPad|iPhone|iPod/.test(navigator.userAgent || '') || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}

let silentAudio = null;

/**
 * Must run synchronously inside a user gesture. Starts the context, and on
 * iOS makes the instrument audible even when the ring/silent switch is set to
 * silent (Web Audio alone is treated as "ambient" sound and muted by it).
 */
function unlockAudio(ctx) {
  try { if (ctx.state !== 'running') ctx.resume().catch(() => {}); } catch { /* older Safari returns no promise */ }
  try {
    // One silent buffer through the destination fully unlocks older iOS versions.
    const buffer = ctx.createBuffer(1, 1, ctx.sampleRate);
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.connect(ctx.destination);
    src.start(0);
  } catch { /* not fatal */ }
  try {
    if (typeof navigator !== 'undefined' && navigator.audioSession) {
      // Safari 16.4+: declare this as media playback (ignores the silent switch).
      navigator.audioSession.type = 'playback';
    } else if (isIOS() && !silentAudio) {
      // Older iOS: a looping silent <audio> element switches the whole page to the playback category.
      silentAudio = document.createElement('audio');
      silentAudio.setAttribute('playsinline', '');
      silentAudio.setAttribute('x-webkit-airplay', 'deny');
      silentAudio.loop = true;
      silentAudio.src = silentWavUrl();
      const p = silentAudio.play();
      if (p && typeof p.catch === 'function') p.catch(() => {});
    }
  } catch { /* not fatal */ }
}

/** Object URL of half a second of silence as a WAV file. */
function silentWavUrl() {
  const rate = 8000, samples = rate / 2;
  const view = new DataView(new ArrayBuffer(44 + samples * 2));
  const text = (offset, str) => { for (let i = 0; i < str.length; i++) view.setUint8(offset + i, str.charCodeAt(i)); };
  text(0, 'RIFF'); view.setUint32(4, 36 + samples * 2, true); text(8, 'WAVE');
  text(12, 'fmt '); view.setUint32(16, 16, true); view.setUint16(20, 1, true); view.setUint16(22, 1, true);
  view.setUint32(24, rate, true); view.setUint32(28, rate * 2, true); view.setUint16(32, 2, true); view.setUint16(34, 16, true);
  text(36, 'data'); view.setUint32(40, samples * 2, true);
  return URL.createObjectURL(new Blob([view.buffer], { type: 'audio/wav' }));
}

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
  /**
   * @param {object} [o]
   * @param {boolean} [o.forceScriptBackend] always use the ScriptProcessor backend (testing / troubleshooting)
   */
  constructor({ forceScriptBackend = false } = {}) {
    super();
    this.forceScriptBackend = forceScriptBackend;
    this.ctx = null;
    this.ready = false;
    this.initializing = null;
    this.params = Object.fromEntries(PARAM_DEFS.map((d) => [d.id, d.default]));
    this.presetId = 'clean';
    this.body = 'electric';
    this.pickupPosition = 4;
    this.delayTimeId = 'dotted';
    this.palmMute = false;
    this.stringsNode = null;
    /** 'worklet' | 'script' once initialised */
    this.backend = null;
    this.bank = null; // StringBank instance when running the 'script' backend
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
    const forceScriptBackend = this.forceScriptBackend;
    if (this.ready) return this;
    if (this.initializing) return this.initializing;
    // Everything up to the first `await` runs inside the user's tap, which is
    // what iOS needs to let the context start.
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!existingContext && !Ctx) return Promise.reject(new Error('This browser has no Web Audio support'));
    const ctx = existingContext || new Ctx({ latencyHint: 'interactive' });
    if (!existingContext) unlockAudio(ctx);
    this.initializing = (async () => {
      try {
        let backend = 'script';
        if (!forceScriptBackend && ctx.audioWorklet && typeof AudioWorkletNode !== 'undefined') {
          try {
            await ctx.audioWorklet.addModule(this.moduleUrl);
            backend = 'worklet';
          } catch (err) {
            console.warn('AudioWorklet unavailable, using the ScriptProcessor backend', err);
          }
        }
        if (backend === 'script' && typeof ctx.createScriptProcessor !== 'function') {
          throw new Error('Neither AudioWorklet nor ScriptProcessor is available in this browser');
        }
        this.ctx = ctx;
        this.backend = backend;
        this.buildGraph();
      } catch (err) {
        // Leave the engine in a state where the next user gesture can try again.
        this.initializing = null;
        this.ctx = null;
        this.backend = null;
        if (!existingContext && typeof ctx.close === 'function') ctx.close().catch(() => {});
        throw err;
      }
      this.ready = true;
      this.applyAllParams();
      this.applyBody(this.body); // also applies the pickup selector for the electric body
      this.dispatchEvent(new CustomEvent('ready'));
      return this;
    })();
    return this.initializing;
  }

  /** Resume after the browser suspended or (on iOS) interrupted the context. Call from a user gesture. */
  async resume() {
    if (!this.ctx) return;
    if (this.ctx.state !== 'running' && typeof this.ctx.resume === 'function') {
      try { await this.ctx.resume(); } catch { /* ignored: offline contexts */ }
    }
  }

  buildGraph() {
    const ctx = this.ctx;
    const selector = PICKUP_SELECTOR.find((p) => p.position === this.pickupPosition);
    // All six strings and their bridge coupling live in one StringBank.
    const stringOptions = {
      strings: STRING_T60.map((t60, i) => ({ t60, brightness: STRING_BRIGHTNESS[i], dispersion: STRING_DISPERSION[i], outGain: STRING_OUT_GAIN[i] })),
      pickupDistances: selector.pickups.map((p) => PICKUP_DISTANCES[p]),
      pickupWeights: selector.pickups.map(() => (selector.pickups.length > 1 ? 0.72 : 1)),
      coupling: BRIDGE_COUPLING,
    };
    if (this.backend === 'worklet') {
      this.stringsNode = new AudioWorkletNode(ctx, 'guitar-strings-processor', {
        numberOfInputs: 0,
        numberOfOutputs: 1,
        outputChannelCount: [1],
        processorOptions: stringOptions,
      });
      this.stringsNode.onprocessorerror = (e) => console.error('String processor error', e);
      this.stringsNode.port.onmessage = (e) => this.onStringMessage(e.data);
    } else {
      // Same model on the main thread. 512 frames ≈ 11 ms at 48 kHz: small enough
      // to feel immediate, large enough to survive a busy frame.
      this.bank = new StringBank(ctx.sampleRate, stringOptions);
      this.stringsNode = ctx.createScriptProcessor(SCRIPT_BUFFER_SIZE, 1, 1);
      this.stringsNode.onaudioprocess = (e) => {
        const out = e.outputBuffer.getChannelData(0);
        this.bank.process(out, Number.isFinite(e.playbackTime) ? e.playbackTime : ctx.currentTime);
      };
    }
    for (let i = 0; i < STRING_COUNT; i++) {
      this.post(i, { type: 'pitch', frequency: this.stringState[i].frequency, glide: 0, lengthFraction: this.stringState[i].lengthFraction });
    }
    this.stringMix = ctx.createGain();
    this.stringMix.gain.value = 1;
    this.stringsNode.connect(this.stringMix);

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
    this.shaper.oversample = 'none'; // switched to 4x only when the amp is driven hard (see applyDrive)
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

    // Master: volume → zero-latency soft safety limiter (linear in normal use)
    this.master = ctx.createGain();
    this.safetyIn = ctx.createGain();
    this.safetyIn.gain.value = 0.5;
    this.safety = ctx.createWaveShaper();
    this.safety.curve = makeSoftLimiterCurve();
    this.safety.oversample = 'none';
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
    this.master.connect(this.safetyIn).connect(this.safety).connect(this.analyser).connect(ctx.destination);
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
    const v = Number(value);
    if (!Number.isFinite(v)) return; // ignore garbage instead of poisoning the audio graph
    this.params[id] = clamp(v, 0, 1);
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
        // Leaves headroom so ordinary playing stays inside the limiter's linear range.
        setParamSmooth(this.master.gain, Math.pow(v, 1.6) * 0.62, ctx);
        break;
      case 'tone':
        setParamSmooth(this.toneFilter.frequency, expMap(420, 12000, v), ctx, 0.03);
        break;
      case 'gain': {
        // Pre-gain drives the saturation stage; post-gain roughly matches loudness
        // (a saturated signal has a much higher RMS than a clean one).
        const drive = 1 + v * v * 60;
        setParamSmooth(this.preGain.gain, drive, ctx);
        setParamSmooth(this.postGain.gain, Math.pow(drive, -0.2), ctx);
        this.applyDrive();
        break;
      }
      case 'distortion':
        this.shaper.curve = makeDistortionCurve(v);
        this.applyDrive();
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

  /**
   * Oversample the amp stage only when it is driven hard enough to alias.
   * Clean settings stay at zero added latency; overdriven ones trade ~4 ms
   * for clean high notes.
   */
  applyDrive() {
    const heavy = this.params.distortion > 0.25 || this.params.gain > 0.4;
    const mode = heavy ? '4x' : 'none';
    if (this.shaper.oversample !== mode) this.shaper.oversample = mode;
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
        this.postAll({ type: 'config', pickupDistances: distances, pickupWeights: weights });
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
      this.postAll({ type: 'config', pickupDistances: [0.19], pickupWeights: [1.15], brightnessScale: 0.72, clickLevel: 0.14 });
    } else {
      this.bodyFilters.forEach((f) => setParamSmooth(f.gain, 0, ctx, 0.05));
      setParamSmooth(this.cabLow.frequency, 6500, ctx, 0.03);
      this.postAll({ type: 'config', brightnessScale: 1, clickLevel: 0.08 });
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
      this.applyBody(preset.body); // applies the pickup selector too
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
    this.send({ ...msg, string: stringIdx });
  }

  /** Send a message addressed to every string (config / panic). */
  postAll(msg) {
    this.send(msg);
  }

  /** Deliver a message to the string model on whichever backend is running. */
  send(msg) {
    if (this.backend === 'worklet') this.stringsNode.port.postMessage(msg);
    else if (this.bank) this.bank.enqueue(msg, this.ctx.currentTime);
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
      velocity: clamp(Number.isFinite(velocity) ? velocity : 0.8, 0.02, 1),
      pickPosition: clamp(Number.isFinite(pickPosition) ? pickPosition : 0.14, 0.03, 0.45),
      damping: damp,
      frequency: st.frequency,
      lengthFraction: st.lengthFraction,
      time: when,
    });
    this.dispatchEvent(new CustomEvent('pluck', { detail: { string: stringIdx, velocity, frequency: st.frequency, when: when ?? this.now } }));
  }

  /**
   * Is a played note still clearly audible on this string? Thick strings ring
   * much longer than thin ones, so the window follows each string's decay time.
   */
  isAudible(stringIdx) {
    const st = this.stringState[stringIdx];
    return st.ringing && this.now - st.lastPluck < STRING_T60[stringIdx] * 0.85;
  }

  /**
   * Fret-hand release / mute: the string rings down quickly. `cancel` also drops
   * plucks still scheduled for the string (the tail of a strum), for "mute everything".
   */
  release(stringIdx, { amount = 1, when, cancel = false } = {}) {
    const st = this.stringState[stringIdx];
    st.ringing = false;
    if (!this.ready) return;
    this.post(stringIdx, { type: 'damp', amount, time: when, cancel });
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

  onStringMessage(msg) {
    if (msg && msg.type === 'pong') {
      const resolve = this.pending.get(msg.id);
      if (resolve) { this.pending.delete(msg.id); resolve(); }
    }
  }

  /**
   * Resolves once the string processor has received every message posted so
   * far (useful before offline rendering, or to detect a dead worklet).
   */
  sync() {
    if (!this.ready || this.backend !== 'worklet') return Promise.resolve();
    return new Promise((resolve) => {
      const id = ++this.pingId;
      this.pending.set(id, resolve);
      this.stringsNode.port.postMessage({ type: 'ping', id });
    });
  }

  /** Mute all strings immediately. */
  releaseAll() {
    for (let i = 0; i < STRING_COUNT; i++) this.release(i);
  }

  panic() {
    this.postAll({ type: 'panic' });
    for (const st of this.stringState) st.ringing = false;
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
