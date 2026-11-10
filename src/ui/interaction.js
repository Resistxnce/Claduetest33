/**
 * Player — turns pointer / multi-touch / keyboard input into fretting and
 * picking actions on the AppState, and drives the audio engine accordingly.
 *
 * Playing model ("tap the strings")
 *  - Tapping a string at a fret presses it and plays that note; the finger
 *    holds the note while it stays down. Tapping a string before the nut
 *    plays the open string (or the held chord's note on that string).
 *  - Dragging along a string slides (pitch glides, fret noise).
 *  - Sweeping across strings plays each string crossed — a strum. Sweep speed
 *    sets the picking intensity.
 *  - Lifting a finger lets the note ring out (default) or mutes it when
 *    "Lifting a finger mutes" is on; lifting onto a lower finger is a pull-off.
 *  - Pressing a higher fret while the string rings is a hammer-on.
 *  - With "dragging across strings: bends", a held finger stays on its string
 *    and sideways movement bends the pitch (wiggle for vibrato).
 *
 * `state.ringing[string]` always describes the note that is actually sounding
 * on a string; every pitch change made here keeps it (and the fretboard's ring
 * marker) up to date.
 */
import { STRING_COUNT } from '../theory/fretboard.js';

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

/** Finger id used by the keyboard cursor (pointer ids are numbers). */
const KEYBOARD_FINGER = 'keyboard';

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
    /** pointerId -> { zone:'fretboard'|'open'|'none'|'dead', x, y, t, downY, string? } */
    this.pointers = new Map();
    this.momentaryMute = false;
    this.onAudioStart = null;
    /** plucks requested before the audio engine finished starting */
    this.queued = [];
    /** MIDI pitch last sent to the engine per string (-1 = muted), to refresh only what changed */
    this.sentMidi = new Array(STRING_COUNT).fill(null);
    this.bound = {
      down: (e) => this.onPointerDown(e),
      move: (e) => this.onPointerMove(e),
      up: (e) => this.onPointerUp(e),
      leave: () => this.canvas.setHover(null),
      key: (e) => this.onKeyDown(e),
      keyUp: (e) => this.onKeyUp(e),
    };
    state.addEventListener('tuning', () => this.refreshAllPitches());
    state.addEventListener('option', (e) => { if (e.detail.key === 'dragAcross' && e.detail.value !== 'bend') this.releaseBends(); });
    state.addEventListener('capo', () => this.refreshAllPitches(0.02));
    state.addEventListener('chord', () => this.refreshAllPitches(0.02));
    engine.addEventListener('ready', () => this.refreshAllPitches(0, true));
    // Panning or re-laying out the neck moves the frets under any held finger.
    canvas.onViewChange = () => this.dropPointers();
    this.cursor = { string: 0, fret: 0 };
    this.cursorActive = false;
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
    // Keyboard access to every fret: focus the fretboard (Tab), move the cursor with the
    // arrow keys, Enter plays the note under it (hold Enter and move to slide or sweep).
    el.addEventListener('focus', () => { if (el.matches(':focus-visible')) this.showCursor(true); });
    el.addEventListener('blur', () => this.showCursor(false));
    window.addEventListener('keydown', this.bound.key);
    window.addEventListener('keyup', this.bound.keyUp);
    const lostFocus = () => { this.endMomentaryMute(); this.releaseEverything(); };
    window.addEventListener('blur', lostFocus);
    document.addEventListener('visibilitychange', () => { if (document.hidden) lostFocus(); });
  }

  /** Make sure audio is running (must be called from a user gesture). */
  ensureAudio() {
    if (this.engine.ready) {
      this.engine.resume();
      return;
    }
    this.engine.init().then(() => {
      this.engine.resume();
      if (this.onAudioStart) this.onAudioStart();
      // Play what the user asked for while the engine was still starting.
      const queued = this.queued.splice(0);
      for (const q of queued) this.pluck(q.string, q.options);
    }).catch(() => { this.queued.length = 0; });
  }

  /* ------------------------------------------------------------------ */
  /* Sound actions                                                      */
  /* ------------------------------------------------------------------ */

  isRinging(string) {
    return this.engine.isAudible(string);
  }

  /**
   * Re-send string pitches after tuning / capo / chord changes. Only strings
   * whose pitch really changed are touched: a note left ringing on such a
   * string is stopped (the hand that changes chord or capo damps it), a note
   * under a held finger follows the change.
   */
  refreshAllPitches(glide = 0, force = false) {
    for (let s = 0; s < STRING_COUNT; s++) {
      const note = this.state.noteOn(s);
      const midi = note ? note.midi : -1;
      if (!force && this.sentMidi[s] === midi) continue;
      const fingered = this.state.fingerFret(s) !== null;
      const ring = this.state.ringing[s];
      const audible = this.isRinging(s);
      if (ring && audible && !fingered) {
        this.engine.release(s);
        this.canvas.stopVisual(s);
        this.state.setRinging(s, null);
      }
      this.applyPitch(s, { glide: fingered && audible ? glide : 0 });
      if (ring && audible && fingered && note) this.noteChanged(s, note);
    }
  }

  applyPitch(string, { glide = 0 } = {}) {
    const note = this.state.noteOn(string);
    this.sentMidi[string] = note ? note.midi : -1;
    if (!note) {
      this.engine.release(string);
      this.canvas.stopVisual(string);
      return;
    }
    this.engine.setStringPitch(string, note.playFrequency, { glide, lengthFraction: note.lengthFraction });
  }

  /** The note sounding on a string changed without a pluck: keep read-out and marker in step. */
  noteChanged(string, note) {
    this.state.setRinging(string, note);
    this.canvas.setRingPosition(string, note.fret, note.name);
  }

  /**
   * Pick a string at its current sounding pitch.
   * @param {number} string
   * @param {object} [o]
   * @param {number} [o.velocity] defaults to the "pick strength" option
   * @param {number} [o.pickPosition] defaults to the "pick position" option
   * @param {number} [o.when] audio time
   * @param {number} [o.visualDelayMs]
   */
  pluck(string, options = {}) {
    if (!this.engine.ready) {
      // The amp is still powering on: remember the latest few requests.
      this.queued.push({ string, options: { ...options, when: undefined, visualDelayMs: 0 } });
      if (this.queued.length > STRING_COUNT) this.queued.shift();
      return;
    }
    let { velocity = this.state.options.pickStrength, pickPosition, when, visualDelayMs = 0 } = options;
    // Every pluck lands in a slightly different spot, like a real picking hand.
    if (pickPosition === undefined) pickPosition = this.state.options.pickPosition + (Math.random() - 0.5) * 0.02;
    const note = this.state.noteOn(string);
    this.sentMidi[string] = note ? note.midi : -1;
    const showVisual = () => this.canvas.pluckVisual(string, note ? velocity : velocity * 0.4, note ? note.fret : null, note ? note.name : '');
    if (!note) {
      // Muted string: percussive "chuck"
      this.engine.pluck(string, { velocity: velocity * 0.55, damping: 0.96, pickPosition, when });
      this.state.setRinging(string, null);
    } else {
      this.engine.pluck(string, { velocity, pickPosition, frequency: note.playFrequency, lengthFraction: note.lengthFraction, when });
      this.state.notePlayed(note, velocity);
    }
    if (visualDelayMs > 0) setTimeout(showVisual, visualDelayMs); else showVisual();
  }

  /** A soft re-excitation without a pick: hammer-ons and pull-offs. */
  legato(string, velocity) {
    const note = this.state.noteOn(string);
    if (!note) return;
    this.engine.pluck(string, { velocity, pickPosition: 0.22, frequency: note.playFrequency, lengthFraction: note.lengthFraction });
    this.noteChanged(string, note);
  }

  /** Strum all strings. direction 'down' = low to high. */
  strum(direction = 'down', velocity = Math.min(1, this.state.options.pickStrength + 0.05), spacingMs = 14) {
    this.ensureAudio();
    const order = [...Array(STRING_COUNT).keys()];
    if (direction === 'up') order.reverse();
    const start = this.engine.now + 0.005;
    order.forEach((s, i) => {
      const jitter = (Math.random() - 0.5) * 0.004;
      this.pluck(s, { velocity: clamp(velocity * (0.9 + Math.random() * 0.2), 0.1, 1), when: start + i * spacingMs / 1000 + jitter, visualDelayMs: i * spacingMs });
    });
  }

  releaseEverything() {
    this.state.liftAll();
    this.dropPointers();
    for (let s = 0; s < STRING_COUNT; s++) {
      this.engine.release(s, { cancel: true });
      this.canvas.stopVisual(s);
      this.state.setRinging(s, null);
    }
    this.refreshAllPitches(0, true);
  }

  /** Lift every held finger and ignore the active pointers until they are released. */
  dropPointers() {
    for (const [id, rec] of this.pointers) {
      if (rec.zone === 'fretboard') this.liftFinger(id);
      rec.zone = 'dead';
    }
  }

  /* ------------------------------------------------------------------ */
  /* Fretting                                                           */
  /* ------------------------------------------------------------------ */

  /** Picking intensity of a tap: touch/pen pressure when the device reports it, else the pick-strength option. */
  tapVelocity(e) {
    const base = this.state.options.pickStrength;
    if (e && e.pointerType !== 'mouse' && e.pressure > 0 && e.pressure !== 0.5 && e.pressure < 1) {
      return clamp(base * (0.55 + e.pressure * 0.9), 0.2, 1);
    }
    return base;
  }

  /** Picking intensity of a sweep: faster movement picks harder. */
  sweepVelocity(speed) {
    return clamp(this.state.options.pickStrength * (0.6 + speed * 0.28), 0.2, 1);
  }

  /**
   * A finger arrived on a string (tap, or a sweep reaching it). The string is
   * picked when "tapping plays" is on; otherwise landing on a ringing string
   * is a hammer-on and landing on a silent one just frets it.
   */
  landOn(string, before, wasRinging, velocity, when) {
    const after = this.state.soundingFret(string);
    if (this.state.options.tapToPlay) {
      this.pluck(string, { velocity, when });
      return;
    }
    if (after === before) return;
    this.applyPitch(string, { glide: wasRinging ? 0.006 : 0 });
    if (wasRinging && after > before) this.legato(string, 0.3);
    else if (wasRinging) this.noteChanged(string, this.state.noteOn(string));
  }

  pressFinger(pointerId, string, fret, velocity = this.state.options.pickStrength) {
    const before = this.state.soundingFret(string);
    const ringing = this.isRinging(string);
    this.state.pressFinger(pointerId, string, fret);
    this.landOn(string, before, ringing, velocity);
  }

  moveFinger(pointerId, string, fret, speed) {
    const finger = this.state.fingers.get(pointerId);
    if (!finger) return;
    if (finger.string !== string) {
      // The finger swept onto another string. Pointer events can skip strings on
      // a fast sweep, so walk through every string in between: each one is left
      // behind in turn and the next one is picked (six in a row is a strum).
      const dir = string > finger.string ? 1 : -1;
      const velocity = this.sweepVelocity(speed);
      const base = this.engine.now;
      let i = 0;
      for (let s = finger.string + dir; dir > 0 ? s <= string : s >= string; s += dir) {
        const prev = this.state.fingers.get(pointerId);
        const prevBefore = this.state.soundingFret(prev.string);
        const prevRinging = this.isRinging(prev.string);
        const before = this.state.soundingFret(s);
        const ringing = this.isRinging(s);
        this.state.moveFinger(pointerId, s, fret);
        this.afterFingerLeft(prev.string, prevBefore, prevRinging);
        this.landOn(s, before, ringing, velocity, base + i * 0.004);
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
        this.engine.slideNoise(string, clamp(0.015 + speed * 0.01, 0.01, 0.04));
        this.noteChanged(string, this.state.noteOn(string));
      }
    }
  }

  /**
   * Bend mode: the finger stays on its string. Movement along the string still
   * slides; movement across it bends the pitch up — two semitones per string
   * spacing, after a small dead zone so ordinary taps stay in tune.
   */
  bendFinger(pointerId, rec, g, speed) {
    const finger = this.state.fingers.get(pointerId);
    const L = this.canvas.layout;
    const along = this.stickyFret(finger, this.canvas.hitTest(g.x, L.stringY(finger.string)), g);
    if (along.zone === 'fretboard' && along.fret !== finger.fret) this.moveFinger(pointerId, finger.string, along.fret, speed);
    // The bend origin ratchets toward the string's own line: moving a finger
    // back toward where the string rests never bends it, so a finger that
    // arrives by dragging (or lands off-centre) starts in tune, and a vibrato
    // wiggle is centred on the string.
    const centre = L.stringY(finger.string);
    if (Math.abs(g.y - centre) < Math.abs(rec.downY - centre)) rec.downY = g.y;
    const dy = g.y - rec.downY;
    const dead = L.spacing * 0.15;
    const semitones = clamp(((Math.abs(dy) - dead) / L.spacing) * 2, 0, 3);
    const offset = Math.abs(dy) > dead ? clamp(dy, -L.spacing * 1.65, L.spacing * 1.65) : 0;
    const current = this.state.fingers.get(pointerId);
    if (Math.abs((current.bend || 0) - semitones) < 0.004 && (current.offset || 0) === offset) return;
    this.state.setFingerBend(pointerId, semitones, offset);
    this.applyPitch(finger.string, { glide: 0.012 });
    // The read-out follows the bend: the ringing record carries the bent pitch.
    if (this.isRinging(finger.string)) this.state.setRinging(finger.string, this.state.noteOn(finger.string));
  }

  liftFinger(pointerId) {
    const finger = this.state.fingers.get(pointerId);
    if (!finger) return;
    const string = finger.string;
    const before = this.state.soundingFret(string);
    const ringing = this.isRinging(string);
    const wasBent = (finger.bend || 0) > 0;
    this.state.liftFinger(pointerId);
    this.afterFingerLeft(string, before, ringing);
    // A bent string that keeps ringing springs back to the fretted pitch.
    const ring = this.state.ringing[string];
    if (wasBent && ring && this.isRinging(string) && this.state.fingerFret(string) === null) {
      this.engine.setStringPitch(string, ring.frequency, { glide: 0.05, lengthFraction: ring.lengthFraction });
      this.state.setRinging(string, { ...ring, bend: 0, playFrequency: ring.frequency });
    }
  }

  /** Decide what the string does once a finger has left it. */
  afterFingerLeft(string, before, ringing) {
    const after = this.state.soundingFret(string);
    const stillFretted = this.state.fingerFret(string) !== null;
    if (after === before) return; // another finger holds the same pitch
    if (after < 0) {
      this.sentMidi[string] = -1;
      this.engine.release(string);
      this.canvas.stopVisual(string);
      this.state.setRinging(string, null);
      return;
    }
    if (stillFretted) {
      // Pull-off to the lower finger: the string keeps ringing, a bit quieter.
      this.applyPitch(string, { glide: ringing ? 0.008 : 0 });
      if (ringing) this.legato(string, 0.22);
      return;
    }
    const ring = this.state.ringing[string];
    if (!this.state.options.releaseMutes && ringing && ring && ring.fret === before) {
      // The note this finger was holding rings out at its own pitch; the engine
      // keeps that pitch until the next pluck sets a new one. As far as the state is
      // concerned the string is back at its resting note, so a later chord, capo or
      // tuning event that leaves this string alone must not touch (and mute) it.
      const rest = this.state.noteOn(string);
      this.sentMidi[string] = rest ? rest.midi : -1;
      return;
    }
    if (this.state.options.releaseMutes && ringing) {
      // Fret hand releases the string: it is muted by the lifting finger.
      this.engine.release(string);
      this.canvas.stopVisual(string);
      this.state.setRinging(string, null);
    }
    // Nothing of this finger's is sounding: the string returns to its resting pitch.
    this.applyPitch(string, { glide: 0 });
    if (ringing && this.state.ringing[string]) this.noteChanged(string, this.state.noteOn(string));
  }

  /* ------------------------------------------------------------------ */
  /* Pointer events                                                     */
  /* ------------------------------------------------------------------ */

  onPointerDown(e) {
    if (e.pointerType === 'mouse' && e.button !== 0) return; // only the primary button plays
    // Playing takes the keyboard back from whatever panel control was used last.
    const focused = document.activeElement;
    if (focused && focused !== document.body && typeof focused.blur === 'function') focused.blur();
    this.ensureAudio();
    e.preventDefault();
    const g = this.canvas.toGuitar(e.clientX, e.clientY);
    const hit = this.canvas.hitTest(g.x, g.y);
    const rec = { zone: hit.zone, x: g.x, y: g.y, t: performance.now(), downY: g.y, speed: 0 };
    this.pointers.set(e.pointerId, rec);
    try { this.canvas.canvas.setPointerCapture(e.pointerId); } catch { /* ignore */ }
    if (hit.zone === 'fretboard') {
      this.pressFinger(e.pointerId, hit.string, hit.fret, this.tapVelocity(e));
    } else if (hit.zone === 'open') {
      rec.string = hit.string;
      this.pluck(hit.string, { velocity: this.tapVelocity(e) });
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
    if (rec.zone === 'dead') return;
    const now = performance.now();
    const dt = Math.max(1, now - rec.t);
    const speed = Math.hypot(g.x - rec.x, g.y - rec.y) / dt; // px per ms
    const hit = this.stickyHit(e.pointerId, rec, g);
    if (rec.zone === 'none' && hit.zone !== 'none') {
      // A drag that started off the strings and reaches them starts playing.
      rec.zone = hit.zone;
      rec.downY = g.y;
      if (hit.zone === 'fretboard') this.pressFinger(e.pointerId, hit.string, hit.fret, this.sweepVelocity(speed));
      else { rec.string = hit.string; this.pluck(hit.string, { velocity: this.sweepVelocity(speed) }); }
    } else if (rec.zone === 'fretboard' && this.state.options.dragAcross === 'bend' && this.state.fingers.has(e.pointerId)) {
      this.bendFinger(e.pointerId, rec, g, speed);
    } else if (rec.zone === 'fretboard') {
      if (hit.zone === 'fretboard') this.moveFinger(e.pointerId, hit.string, hit.fret, speed);
      else if (hit.zone === 'open') {
        // Slid off the nut into the open zone: lift the finger, keep sweeping open strings.
        this.liftFinger(e.pointerId);
        rec.zone = 'open';
        rec.string = hit.string;
        this.pluck(hit.string, { velocity: this.sweepVelocity(speed) });
      }
    } else if (rec.zone === 'open') {
      if (hit.zone === 'open') {
        this.sweepOpen(rec, hit.string, speed);
      } else if (hit.zone === 'fretboard') {
        // Clearly past the nut onto the fretboard: start fretting from here.
        rec.zone = 'fretboard';
        rec.downY = g.y;
        this.pressFinger(e.pointerId, hit.string, hit.fret, this.sweepVelocity(speed));
      }
    }
    rec.x = g.x; rec.y = g.y; rec.t = now;
    if (e.pointerType === 'mouse') this.canvas.setHover(this.canvas.hitTest(g.x, g.y));
  }

  /**
   * Hit test with hysteresis so a resting finger never flickers between two
   * targets: it must move clearly past the midpoint to the next string, past a
   * fret wire to the next fret, and well clear of the nut to change between
   * open-string strumming and fretting.
   */
  stickyHit(pointerId, rec, g) {
    let hit = this.canvas.hitTest(g.x, g.y);
    if (hit.zone === 'none') return hit;
    const L = this.canvas.layout;
    const finger = this.state.fingers.get(pointerId);
    // Nut: stay in the current zone until the pointer is clearly on the other side.
    if (rec.zone === 'open' && hit.zone === 'fretboard') {
      const clear = Math.min(L.cellWidth(1) * 0.45, 40);
      if (g.x < L.nutX + clear) hit = { zone: 'open', string: hit.string, fret: 0 };
    } else if (rec.zone === 'fretboard' && hit.zone === 'open') {
      if (g.x > L.nutX - L.nutW - 6) hit = { zone: 'fretboard', string: hit.string, fret: 1 };
    }
    // Strings
    const current = finger ? finger.string : (rec.zone === 'open' ? rec.string : undefined);
    if (current !== undefined && hit.string !== current && Math.abs(g.y - L.stringY(current)) < L.spacing * 0.64) {
      hit = { ...hit, string: current };
    }
    // Frets
    if (finger && hit.zone === 'fretboard') hit = this.stickyFret(finger, hit, g);
    return hit;
  }

  /** Keep a held finger on its fret until the pointer is a few pixels past the wire. */
  stickyFret(finger, hit, g) {
    if (hit.zone !== 'fretboard' || hit.fret === finger.fret || Math.abs(hit.fret - finger.fret) !== 1) return hit;
    const L = this.canvas.layout;
    const wire = L.fretX(Math.min(hit.fret, finger.fret));
    const margin = clamp(L.cellWidth(Math.max(hit.fret, finger.fret)) * 0.16, 3, 8);
    return Math.abs(g.x - wire) < margin ? { ...hit, fret: finger.fret } : hit;
  }

  /** In the open zone: play every string between the last string and the new one (sweep/strum). */
  sweepOpen(rec, string, speed) {
    if (rec.string === undefined || rec.string === string) return;
    const dir = string > rec.string ? 1 : -1;
    const velocity = this.sweepVelocity(speed);
    const base = this.engine.now;
    let i = 0;
    for (let s = rec.string + dir; dir > 0 ? s <= string : s >= string; s += dir) {
      this.pluck(s, { velocity, when: base + i * 0.004 });
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
    if (!t || !t.tagName) return false;
    if (t.tagName === 'TEXTAREA' || t.isContentEditable) return true;
    // Checkboxes, sliders and menus do not take text: the playing keys keep working.
    return t.tagName === 'INPUT' && !['checkbox', 'radio', 'range', 'button'].includes(t.type);
  }

  /** Does the focused control itself use this key? */
  controlUsesKey(e) {
    const t = e.target;
    if (!t || typeof t.closest !== 'function') return false;
    const activate = e.code === 'Space' || e.key === 'Enter';
    const arrow = e.key.startsWith('Arrow');
    if (activate && t.closest('button, a, summary, select, input, [role="button"]')) return true;
    if (arrow && t.closest('[role="slider"], input[type="range"], select, input[type="radio"]')) return true;
    return false;
  }

  endMomentaryMute() {
    if (!this.momentaryMute) return;
    this.momentaryMute = false;
    this.engine.setPalmMute(this.state.options.palmMute);
  }

  onKeyDown(e) {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    if (document.querySelector('dialog[open]')) return; // a modal owns the keyboard
    if (this.isTyping(e) || this.controlUsesKey(e)) return;
    if (this.cursorActive && e.target === this.canvas.canvas && this.cursorKey(e)) return;
    // String keys by physical position (1 = high E … 6 = low E) on any keyboard layout.
    const digit = /^(?:Digit|Numpad)([1-6])$/.exec(e.code || '');
    if (digit) {
      e.preventDefault();
      if (e.repeat) return;
      this.ensureAudio();
      this.pluck(6 - Number(digit[1]), { velocity: e.shiftKey ? 1 : this.state.options.pickStrength });
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
      // Move along the neck when it is larger than the screen.
      if (this.canvas.pannable) {
        this.canvas.panBy((e.key === 'ArrowRight' ? 1 : -1) * this.canvas.viewLen * 0.35);
        e.preventDefault();
      }
    } else if (e.code === 'Space') {
      e.preventDefault();
      if (e.repeat) return;
      this.strum(e.shiftKey ? 'up' : 'down');
    } else if (e.key === 'Escape') {
      this.releaseEverything();
    } else if (e.code === 'KeyM') {
      if (!this.momentaryMute) {
        this.momentaryMute = true;
        this.engine.setPalmMute(true);
        for (let s = 0; s < STRING_COUNT; s++) if (this.isRinging(s)) this.engine.release(s, { amount: 0.75 });
      }
    }
  }

  onKeyUp(e) {
    if (e.code === 'KeyM') this.endMomentaryMute();
    if (e.key === 'Enter' && this.state.fingers.has(KEYBOARD_FINGER)) this.liftFinger(KEYBOARD_FINGER);
  }

  /** Let every bent string spring back (bend mode was switched off while a finger held a bend). */
  releaseBends() {
    for (const [id, finger] of this.state.fingers) {
      if (!(finger.bend > 0) && !finger.offset) continue;
      this.state.setFingerBend(id, 0, 0);
      this.applyPitch(finger.string, { glide: 0.02 });
      if (this.isRinging(finger.string)) this.state.setRinging(finger.string, this.state.noteOn(finger.string));
    }
  }

  /* ---------------- keyboard cursor ---------------- */

  showCursor(on) {
    this.cursorActive = on;
    if (!on && this.state.fingers.has(KEYBOARD_FINGER)) this.liftFinger(KEYBOARD_FINGER);
    this.canvas.setCursor(on ? this.cursor : null);
    if (on) this.announceCursor();
  }

  announceCursor() {
    const { string, fret } = this.cursor;
    const note = this.state.fretboard.noteAt(string, Math.max(fret, this.state.capo), { flats: this.state.options.flats });
    const status = document.getElementById('cursor-status');
    if (status) status.textContent = `String ${6 - string}, ${fret === 0 ? 'open' : `fret ${fret}`}: ${note.name}`;
  }

  /** Keys for the focused fretboard. Returns true when the key was used. */
  cursorKey(e) {
    const c = this.cursor;
    const vertical = this.canvas.orientation === 'vertical';
    const last = this.canvas.layout.N;
    let dString = 0, dFret = 0;
    // Directions follow the screen: on the horizontal neck the high E is on top and
    // frets run to the right; on the upright neck the low E is on the left and frets run down.
    if (e.key === 'ArrowUp') { if (vertical) dFret = -1; else dString = 1; }
    else if (e.key === 'ArrowDown') { if (vertical) dFret = 1; else dString = -1; }
    else if (e.key === 'ArrowLeft') { if (vertical) dString = -1; else dFret = -1; }
    else if (e.key === 'ArrowRight') { if (vertical) dString = 1; else dFret = 1; }
    else if (e.key === 'Home') dFret = -c.fret;
    else if (e.key === 'End') dFret = last - c.fret;
    else if (e.key === 'PageUp') dFret = -12;
    else if (e.key === 'PageDown') dFret = 12;
    else if (e.key === 'Enter') {
      e.preventDefault();
      if (e.repeat) return true;
      this.ensureAudio();
      if (c.fret === 0) this.pluck(c.string);
      else this.pressFinger(KEYBOARD_FINGER, c.string, c.fret);
      return true;
    } else return false;
    e.preventDefault();
    const string = clamp(c.string + dString, 0, STRING_COUNT - 1);
    const fret = clamp(c.fret + dFret, 0, last);
    if (string === c.string && fret === c.fret) return true;
    this.cursor = { string, fret };
    this.canvas.ensureFretsVisible(fret, fret);
    this.canvas.setCursor(this.cursor);
    this.announceCursor();
    // With Enter held the fretting finger follows the cursor: a slide along the string or a sweep across.
    if (this.state.fingers.has(KEYBOARD_FINGER)) {
      if (fret === 0) this.liftFinger(KEYBOARD_FINGER);
      else this.moveFinger(KEYBOARD_FINGER, string, fret, 1);
    }
    return true;
  }
}
