/**
 * Player — turns pointer / multi-touch / keyboard input into fretting and
 * picking actions on the AppState, and drives the audio engine accordingly.
 *
 * Playing model
 *  - Pressing the fretboard puts a finger down (the highest finger on a string
 *    sets its pitch). With "tap to play" the string is picked at the same time.
 *  - Dragging a finger along a string slides (pitch glides, fret noise).
 *  - Lifting the last finger mutes the string (or lets it ring open if
 *    "release mutes" is off); lifting onto a lower finger is a pull-off.
 *  - Pressing a higher fret while the string rings is a hammer-on.
 *  - The strum zone over the pickups picks strings: tapping a string plucks it,
 *    dragging across strings strums them. Speed sets velocity, position sets
 *    the pick position (bridge = bright, neck = warm).
 *  - The body volume/tone knobs and the pickup selector are live controls.
 */
import { STRING_COUNT } from '../theory/fretboard.js';

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

export class Player {
  /**
   * @param {object} o
   * @param {import('./guitar-canvas.js').GuitarCanvas} o.canvas
   * @param {import('../state.js').AppState} o.state
   * @param {import('../audio/engine.js').GuitarAudioEngine} o.engine
   */
  constructor({ canvas, state, engine }) {
    this.canvas = canvas;
    this.state = state;
    this.engine = engine;
    this.pointers = new Map();
    this.momentaryMute = false;
    this.onAudioStart = null;
    this.bound = {
      down: (e) => this.onPointerDown(e),
      move: (e) => this.onPointerMove(e),
      up: (e) => this.onPointerUp(e),
      leave: () => this.canvas.setHover(null),
      key: (e) => this.onKeyDown(e),
      keyUp: (e) => this.onKeyUp(e),
    };
    state.addEventListener('tuning', () => this.refreshAllPitches());
    state.addEventListener('capo', () => this.refreshAllPitches(0.02));
    state.addEventListener('chord', () => this.refreshAllPitches(0.02));
    engine.addEventListener('ready', () => this.refreshAllPitches());
  }

  attach() {
    const el = this.canvas.canvas;
    el.style.touchAction = 'none';
    el.addEventListener('pointerdown', this.bound.down);
    el.addEventListener('pointermove', this.bound.move);
    el.addEventListener('pointerup', this.bound.up);
    el.addEventListener('pointercancel', this.bound.up);
    el.addEventListener('pointerleave', this.bound.leave);
    el.addEventListener('contextmenu', (e) => e.preventDefault());
    window.addEventListener('keydown', this.bound.key);
    window.addEventListener('keyup', this.bound.keyUp);
    window.addEventListener('blur', () => this.releaseEverything());
  }

  /** Make sure audio is running (must be called from a user gesture). */
  ensureAudio() {
    if (!this.engine.ready) {
      this.engine.init().then(() => { this.engine.resume(); if (this.onAudioStart) this.onAudioStart(); });
    } else {
      this.engine.resume();
    }
  }

  /* ------------------------------------------------------------------ */
  /* Sound actions                                                      */
  /* ------------------------------------------------------------------ */

  /** Re-send the pitch of every string (after tuning/capo/chord changes). */
  refreshAllPitches(glide = 0) {
    for (let s = 0; s < STRING_COUNT; s++) this.applyPitch(s, { glide });
  }

  applyPitch(string, { glide = 0 } = {}) {
    const note = this.state.noteOn(string);
    if (!note) {
      this.engine.release(string);
      this.canvas.stopVisual(string);
      return;
    }
    this.engine.setStringPitch(string, note.frequency, { glide, lengthFraction: note.lengthFraction });
  }

  isRinging(string) {
    const st = this.engine.stringState[string];
    return st.ringing && this.engine.now - st.lastPluck < 4;
  }

  /**
   * Pick a string at its current sounding pitch.
   * @param {number} string
   * @param {object} [o]
   * @param {number} [o.velocity=0.8]
   * @param {number} [o.pickPosition=0.14]
   * @param {number} [o.when] audio time
   * @param {number} [o.visualDelayMs]
   */
  pluck(string, { velocity = 0.8, pickPosition = 0.14, when, visualDelayMs = 0 } = {}) {
    const note = this.state.noteOn(string);
    const showVisual = () => this.canvas.pluckVisual(string, note ? velocity : velocity * 0.4);
    if (!note) {
      // Muted string: percussive "chuck"
      this.engine.pluck(string, { velocity: velocity * 0.55, damping: 0.96, pickPosition, when });
    } else {
      this.engine.pluck(string, { velocity, pickPosition, frequency: note.frequency, lengthFraction: note.lengthFraction, when });
      this.state.notePlayed(note, velocity);
    }
    if (visualDelayMs > 0) setTimeout(showVisual, visualDelayMs); else showVisual();
  }

  /** Strum all strings. direction 'down' = low to high. */
  strum(direction = 'down', velocity = 0.85, spacingMs = 14) {
    this.ensureAudio();
    const order = [...Array(STRING_COUNT).keys()];
    if (direction === 'up') order.reverse();
    const start = this.engine.now + 0.005;
    order.forEach((s, i) => {
      const jitter = (Math.random() - 0.5) * 0.004;
      this.pluck(s, { velocity: clamp(velocity * (0.9 + Math.random() * 0.2), 0.1, 1), pickPosition: 0.16, when: start + i * spacingMs / 1000 + jitter, visualDelayMs: i * spacingMs });
    });
  }

  releaseEverything() {
    this.state.liftAll();
    this.pointers.clear();
    for (let s = 0; s < STRING_COUNT; s++) {
      this.engine.release(s);
      this.canvas.stopVisual(s);
    }
    this.refreshAllPitches();
  }

  /* ------------------------------------------------------------------ */
  /* Fretting                                                           */
  /* ------------------------------------------------------------------ */

  pressFinger(pointerId, string, fret) {
    const before = this.state.soundingFret(string);
    const ringing = this.isRinging(string);
    this.state.pressFinger(pointerId, string, fret);
    const after = this.state.soundingFret(string);
    if (after !== before) {
      // Hammer-on: pitch jumps almost instantly; the hammer adds a little energy.
      this.applyPitch(string, { glide: ringing ? 0.006 : 0 });
      if (ringing && after > before && !this.state.options.tapToPlay) {
        const note = this.state.noteOn(string);
        if (note) this.engine.pluck(string, { velocity: 0.3, pickPosition: 0.2, frequency: note.frequency, lengthFraction: note.lengthFraction });
      }
    }
    if (this.state.options.tapToPlay) {
      this.pluck(string, { velocity: 0.78, pickPosition: 0.14 + Math.random() * 0.02 });
    }
  }

  moveFinger(pointerId, string, fret, speed) {
    const finger = this.state.fingers.get(pointerId);
    if (!finger) return;
    const prevString = finger.string;
    const prevBefore = this.state.soundingFret(prevString);
    const ringingPrev = this.isRinging(prevString);
    const changedString = prevString !== string;
    this.state.moveFinger(pointerId, string, fret);
    if (changedString) {
      // The finger left its old string.
      this.afterFingerLeft(prevString, prevBefore, ringingPrev);
      this.applyPitch(string, { glide: 0 });
      return;
    }
    const after = this.state.soundingFret(string);
    if (after !== prevBefore) {
      // Slide along the string
      this.applyPitch(string, { glide: ringingPrev ? 0.045 : 0 });
      if (ringingPrev) this.engine.slideNoise(string, clamp(0.015 + speed * 0.01, 0.01, 0.05));
    }
  }

  liftFinger(pointerId) {
    const finger = this.state.fingers.get(pointerId);
    if (!finger) return;
    const string = finger.string;
    const before = this.state.soundingFret(string);
    const ringing = this.isRinging(string);
    this.state.liftFinger(pointerId);
    this.afterFingerLeft(string, before, ringing);
  }

  /** Decide what the string does once a finger has left it. */
  afterFingerLeft(string, before, ringing) {
    const after = this.state.soundingFret(string);
    const stillFretted = this.state.fingerFret(string) !== null;
    if (after === before) return; // another finger holds the same pitch
    if (after < 0) {
      this.engine.release(string);
      this.canvas.stopVisual(string);
      return;
    }
    if (stillFretted || this.state.holdChord || this.state.capo > 0 || !this.state.options.releaseMutes) {
      // Pull-off to the lower fret / open string: the string keeps ringing a bit quieter.
      this.applyPitch(string, { glide: ringing ? 0.008 : 0 });
      if (ringing) {
        const note = this.state.noteOn(string);
        if (note) this.engine.pluck(string, { velocity: 0.22, pickPosition: 0.25, frequency: note.frequency, lengthFraction: note.lengthFraction });
      }
      return;
    }
    // Fret hand releases the string: it is muted by the lifting finger.
    this.engine.release(string);
    this.canvas.stopVisual(string);
    this.applyPitch(string, { glide: 0 });
  }

  /* ------------------------------------------------------------------ */
  /* Pointer events                                                     */
  /* ------------------------------------------------------------------ */

  onPointerDown(e) {
    this.ensureAudio();
    e.preventDefault();
    const g = this.canvas.toGuitar(e.clientX, e.clientY);
    const hit = this.canvas.hitTest(g.x, g.y);
    const now = performance.now();
    const rec = { zone: hit.zone, x: g.x, y: g.y, t: now, startY: g.y, hit, speed: 0 };
    this.pointers.set(e.pointerId, rec);
    try { this.canvas.canvas.setPointerCapture(e.pointerId); } catch { /* ignore */ }
    switch (hit.zone) {
      case 'fretboard':
        this.pressFinger(e.pointerId, hit.string, hit.fret);
        break;
      case 'nut':
        this.pluck(hit.string, { velocity: 0.8, pickPosition: 0.3 });
        break;
      case 'strum':
        if (hit.string >= 0) this.pluck(hit.string, { velocity: 0.8, pickPosition: hit.pickPosition });
        break;
      case 'knob':
        rec.startValue = this.engine.params[hit.knob.id];
        break;
      case 'selector':
        this.engine.setPickupSelector(hit.position);
        break;
      default:
        break;
    }
    this.canvas.requestRender();
  }

  onPointerMove(e) {
    const g = this.canvas.toGuitar(e.clientX, e.clientY);
    const rec = this.pointers.get(e.pointerId);
    if (!rec) {
      if (e.pointerType === 'mouse') this.canvas.setHover(this.canvas.hitTest(g.x, g.y));
      return;
    }
    const now = performance.now();
    const dt = Math.max(1, now - rec.t);
    const dist = Math.hypot(g.x - rec.x, g.y - rec.y);
    const speed = dist / dt; // px per ms
    switch (rec.zone) {
      case 'fretboard': {
        const hit = this.canvas.hitTest(g.x, g.y);
        if (hit.zone === 'fretboard') this.moveFinger(e.pointerId, hit.string, hit.fret, speed);
        break;
      }
      case 'strum': {
        this.strumBetween(rec, g, speed);
        break;
      }
      case 'knob': {
        const delta = (rec.startY - g.y) / 160;
        const value = clamp(rec.startValue + delta, 0, 1);
        this.engine.setParam(rec.hit.knob.id, value);
        break;
      }
      default:
        break;
    }
    rec.x = g.x; rec.y = g.y; rec.t = now; rec.speed = speed;
    if (e.pointerType === 'mouse') this.canvas.setHover(this.canvas.hitTest(g.x, g.y));
  }

  /** Pluck every string the pointer crossed between its previous and current position. */
  strumBetween(rec, g, speed) {
    const L = this.canvas.layout;
    const st = L.strum;
    const x0 = clamp(rec.x, st.x0, st.x1), x1 = clamp(g.x, st.x0, st.x1);
    const xm = (x0 + x1) / 2;
    const crossings = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      const ys = L.stringY(s, xm);
      const d0 = rec.y - ys, d1 = g.y - ys;
      if ((d0 < 0 && d1 >= 0) || (d0 > 0 && d1 <= 0)) {
        const t = Math.abs(d0) / Math.max(1e-6, Math.abs(d0) + Math.abs(d1));
        crossings.push({ s, t, x: x0 + (x1 - x0) * t });
      }
    }
    if (!crossings.length) return;
    crossings.sort((a, b) => a.t - b.t);
    const velocity = clamp(0.35 + speed * 0.22, 0.3, 1);
    const base = this.engine.now;
    crossings.forEach((c, i) => {
      const pickPosition = clamp((L.bridgeX - c.x) / L.L, 0.03, 0.45);
      this.pluck(c.s, { velocity, pickPosition, when: base + i * 0.004 });
    });
  }

  onPointerUp(e) {
    const rec = this.pointers.get(e.pointerId);
    if (!rec) return;
    this.pointers.delete(e.pointerId);
    if (rec.zone === 'fretboard') this.liftFinger(e.pointerId);
    try { this.canvas.canvas.releasePointerCapture(e.pointerId); } catch { /* ignore */ }
    this.canvas.requestRender();
  }

  /* ------------------------------------------------------------------ */
  /* Keyboard                                                           */
  /* ------------------------------------------------------------------ */

  isTyping(e) {
    const t = e.target;
    return t && (t.tagName === 'INPUT' || t.tagName === 'SELECT' || t.tagName === 'TEXTAREA' || t.isContentEditable);
  }

  onKeyDown(e) {
    if (this.isTyping(e) || e.metaKey || e.ctrlKey || e.altKey) return;
    if (/^[1-6]$/.test(e.key)) {
      this.ensureAudio();
      const string = 6 - Number(e.key); // key 1 = high E
      this.pluck(string, { velocity: e.shiftKey ? 1 : 0.8, pickPosition: 0.15 });
      e.preventDefault();
    } else if (e.code === 'Space' || e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      if (e.repeat) { e.preventDefault(); return; }
      const up = e.shiftKey || e.key === 'ArrowUp';
      this.strum(up ? 'up' : 'down', 0.85);
      e.preventDefault();
    } else if (e.key === 'Escape') {
      this.releaseEverything();
    } else if (e.key === 'm' || e.key === 'M') {
      if (!this.momentaryMute) {
        this.momentaryMute = true;
        this.engine.setPalmMute(true);
        for (let s = 0; s < STRING_COUNT; s++) this.engine.release(s, { amount: 0.75 });
      }
    }
  }

  onKeyUp(e) {
    if ((e.key === 'm' || e.key === 'M') && this.momentaryMute) {
      this.momentaryMute = false;
      this.engine.setPalmMute(this.state.options.palmMute);
    }
  }
}
