/**
 * Player — turns pointer / multi-touch / keyboard input into fretting and
 * picking actions on the AppState, and drives the audio engine accordingly.
 *
 * Playing model ("tap the strings")
 *  - Tapping a string at a fret presses it and plays that note; the finger
 *    holds the note while it stays down. Tapping a string left of the nut
 *    plays the open string (or the held chord's note on that string).
 *  - Dragging along a string slides (pitch glides, fret noise).
 *  - Sweeping across strings plays each string crossed — a strum. Sweep speed
 *    sets the picking intensity.
 *  - Lifting a finger lets the note ring out (default) or mutes it when
 *    "Lifting a finger mutes" is on; lifting onto a lower finger is a pull-off.
 *  - Pressing a higher fret while the string rings is a hammer-on.
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
    for (let s = 0; s < STRING_COUNT; s++) {
      // A note left ringing by an earlier tap is stopped rather than bent to the
      // string's new pitch (the hand that changes chord/capo/tuning damps it).
      const ring = this.state.ringing[s];
      if (ring && this.state.fingerFret(s) === null && this.isRinging(s)) {
        const note = this.state.noteOn(s);
        if (!note || note.midi !== ring.midi) {
          this.engine.release(s);
          this.canvas.stopVisual(s);
          this.state.setRinging(s, null);
        }
      }
      this.applyPitch(s, { glide });
    }
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
    const showVisual = () => this.canvas.pluckVisual(string, note ? velocity : velocity * 0.4, note ? note.fret : null, note ? note.name : '');
    if (!note) {
      // Muted string: percussive "chuck"
      this.engine.pluck(string, { velocity: velocity * 0.55, damping: 0.96, pickPosition, when });
      this.state.setRinging(string, null);
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
      this.state.setRinging(s, null);
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
        if (note) {
          this.engine.pluck(string, { velocity: 0.3, pickPosition: 0.2, frequency: note.frequency, lengthFraction: note.lengthFraction });
          this.state.setRinging(string, note);
          this.canvas.setRingPosition(string, note.fret, note.name);
        }
      }
    }
    if (this.state.options.tapToPlay) {
      this.pluck(string, { velocity: 0.78, pickPosition: 0.14 + Math.random() * 0.02 });
    }
  }

  moveFinger(pointerId, string, fret, speed) {
    const finger = this.state.fingers.get(pointerId);
    if (!finger) return;
    if (finger.string !== string) {
      // The finger swept onto another string. Pointer events can skip strings on
      // a fast sweep, so walk through every string in between: each one is left
      // behind in turn and the next one is picked (six in a row is a strum).
      const dir = string > finger.string ? 1 : -1;
      const velocity = clamp(0.45 + speed * 0.2, 0.45, 1);
      const base = this.engine.now;
      let i = 0;
      for (let s = finger.string + dir; dir > 0 ? s <= string : s >= string; s += dir) {
        const prev = this.state.fingers.get(pointerId);
        const prevBefore = this.state.soundingFret(prev.string);
        const ringingPrev = this.isRinging(prev.string);
        this.state.moveFinger(pointerId, s, fret);
        this.afterFingerLeft(prev.string, prevBefore, ringingPrev);
        this.applyPitch(s, { glide: 0 });
        if (this.state.options.tapToPlay) this.pluck(s, { velocity, pickPosition: 0.15, when: base + i * 0.004 });
        i++;
      }
      return;
    }
    const before = this.state.soundingFret(string);
    const ringing = this.isRinging(string);
    this.state.moveFinger(pointerId, string, fret);
    const after = this.state.soundingFret(string);
    if (after !== before) {
      // Slide along the string
      this.applyPitch(string, { glide: ringing ? 0.045 : 0 });
      if (ringing) {
        this.engine.slideNoise(string, clamp(0.015 + speed * 0.01, 0.01, 0.05));
        const note = this.state.noteOn(string);
        if (note) {
          this.state.setRinging(string, note);
          this.canvas.setRingPosition(string, note.fret, note.name);
        }
      }
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
      this.state.setRinging(string, null);
      return;
    }
    if (stillFretted) {
      // Pull-off to the lower finger: the string keeps ringing, a bit quieter.
      this.applyPitch(string, { glide: ringing ? 0.008 : 0 });
      if (ringing) {
        const note = this.state.noteOn(string);
        if (note) {
          this.engine.pluck(string, { velocity: 0.22, pickPosition: 0.25, frequency: note.frequency, lengthFraction: note.lengthFraction });
          this.state.setRinging(string, note);
          this.canvas.setRingPosition(string, note.fret, note.name);
        }
      }
      return;
    }
    if (!this.state.options.releaseMutes) {
      // Tapped notes ring out at their own pitch; the engine keeps the pitch it was
      // plucked at until the next pluck sets a new one.
      return;
    }
    // Fret hand releases the string: it is muted by the lifting finger.
    this.engine.release(string);
    this.canvas.stopVisual(string);
    this.state.setRinging(string, null);
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
      case 'open':
        rec.string = hit.string;
        this.pluck(hit.string, { velocity: 0.8, pickPosition: 0.16 });
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
    const hit = this.stickyHit(e.pointerId, rec, g);
    if (rec.zone === 'none' && hit.zone !== 'none') {
      // A drag that started off the strings and reaches them starts playing.
      rec.zone = hit.zone;
      if (hit.zone === 'fretboard') this.pressFinger(e.pointerId, hit.string, hit.fret);
      else { rec.string = hit.string; this.pluck(hit.string, { velocity: clamp(0.45 + speed * 0.2, 0.45, 1), pickPosition: 0.16 }); }
    } else if (rec.zone === 'fretboard') {
      if (hit.zone === 'fretboard') this.moveFinger(e.pointerId, hit.string, hit.fret, speed);
      else if (hit.zone === 'open') {
        // Slid off the nut into the open zone: lift the finger, keep sweeping open strings.
        this.liftFinger(e.pointerId);
        rec.zone = 'open';
        rec.string = hit.string;
        this.pluck(hit.string, { velocity: clamp(0.45 + speed * 0.2, 0.45, 1), pickPosition: 0.16 });
      }
    } else if (rec.zone === 'open') {
      if (hit.zone === 'open') {
        this.sweepOpen(rec, hit.string, speed);
      } else if (hit.zone === 'fretboard') {
        // Crossed the nut onto the fretboard: start fretting from here.
        rec.zone = 'fretboard';
        this.pressFinger(e.pointerId, hit.string, hit.fret);
      }
    }
    rec.x = g.x; rec.y = g.y; rec.t = now; rec.speed = speed;
    if (e.pointerType === 'mouse') this.canvas.setHover(this.canvas.hitTest(g.x, g.y));
  }

  /**
   * Hit test with hysteresis: a pointer already on a string must move clearly
   * past the midpoint to the neighbouring string before it switches, so a
   * finger resting near a boundary does not flip back and forth.
   */
  stickyHit(pointerId, rec, g) {
    const hit = this.canvas.hitTest(g.x, g.y);
    if (hit.zone === 'none') return hit;
    const finger = this.state.fingers.get(pointerId);
    const current = finger ? finger.string : (rec.zone === 'open' ? rec.string : undefined);
    if (current === undefined || hit.string === current) return hit;
    const L = this.canvas.layout;
    if (Math.abs(g.y - L.stringY(current)) < L.spacing * 0.64) return { ...hit, string: current };
    return hit;
  }

  /** In the open zone: play every string between the last string and the new one (sweep/strum). */
  sweepOpen(rec, string, speed) {
    if (rec.string === undefined || rec.string === string) return;
    const dir = string > rec.string ? 1 : -1;
    const velocity = clamp(0.4 + speed * 0.22, 0.4, 1);
    const base = this.engine.now;
    let i = 0;
    for (let s = rec.string + dir; dir > 0 ? s <= string : s >= string; s += dir) {
      this.pluck(s, { velocity, pickPosition: 0.16, when: base + i * 0.004 });
      i++;
    }
    rec.string = string;
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

  /** Focused buttons/knobs own Space, Enter and the arrow keys. */
  focusedControl(e) {
    const t = e.target;
    return t && typeof t.closest === 'function' && t.closest('button, [role="slider"], select, input, a, summary, dialog');
  }

  onKeyDown(e) {
    if (this.isTyping(e) || e.metaKey || e.ctrlKey || e.altKey) return;
    const navKey = e.code === 'Space' || e.key === 'Enter' || e.key.startsWith('Arrow');
    if (navKey && this.focusedControl(e)) return;
    if (/^[1-6]$/.test(e.key)) {
      this.ensureAudio();
      const string = 6 - Number(e.key); // key 1 = high E
      this.pluck(string, { velocity: e.shiftKey ? 1 : 0.8, pickPosition: 0.15 });
      e.preventDefault();
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      // Move along the neck when it is larger than the screen.
      if (this.canvas.pannable) {
        this.canvas.panBy((e.key === 'ArrowRight' ? 1 : -1) * this.canvas.viewLen * 0.35);
        e.preventDefault();
      }
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
