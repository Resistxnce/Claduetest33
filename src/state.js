/**
 * Observable application state: tuning, capo, fingers on the fretboard,
 * chord/scale overlays and display options. UI modules subscribe to events;
 * the Player (interaction.js) turns state changes into sound.
 */
import { Fretboard, vibratingLengthFraction } from './theory/fretboard.js';
import { getTuning, DEFAULT_TUNING_ID } from './theory/tunings.js';
import { describeNote } from './theory/notes.js';
import { chordVoicings } from './theory/chords.js';
import { getScale } from './theory/scales.js';

export const DEFAULT_OPTIONS = Object.freeze({
  noteNames: 'played', // 'off' | 'played' | 'all'
  fretNumbers: true,
  flats: false,
  tapToPlay: true,     // pressing a fret also picks the string
  releaseMutes: false, // lifting the last finger mutes the string (off: tapped notes ring out)
  holdFingers: false,  // fingers stay down after the touch lifts, to build chord shapes one touch at a time
  palmMute: false,
  dragAcross: 'strum',  // dragging a held finger across the strings: 'strum' them or 'bend' the string
  pickPosition: 0.14,  // where the pick hits: fraction of the scale length from the bridge (0.05 bright … 0.30 warm)
  pickStrength: 0.8,   // base picking intensity for taps (0.2 soft … 1 hard)
  view: 'auto',        // 'auto' | 'fit' | 'zoom' — how the 24-fret neck fills the screen
  orientation: 'auto', // 'auto' | 'horizontal' | 'vertical'
  scaleLabels: 'degrees', // 'degrees' | 'names'
});

export class AppState extends EventTarget {
  constructor() {
    super();
    this.tuning = getTuning(DEFAULT_TUNING_ID);
    this.fretboard = new Fretboard({ tuning: this.tuning, fretCount: 24 });
    this.capo = 0;
    /**
     * Fingers on the fretboard, by pointer id. A finger presses `string` at `fret`; one that was
     * dragged across the strings within a fret lies flat over every string between `from` (where
     * it started) and `string` — a barre. `held` fingers stay down without a touch (Hold mode).
     * @type {Map<number|string, {string:number, fret:number, from?:number, held?:boolean, bend?:number, offset?:number}>}
     */
    this.fingers = new Map();
    this.heldCount = 0;
    this.chord = null;      // { rootPc, quality, voicings, index }
    this.holdChord = false; // virtual fingers hold the selected chord
    this.scale = null;      // { rootPc, scaleId }
    this.highlightPc = null;
    this.options = { ...DEFAULT_OPTIONS };
    this.recent = [];       // recently played notes (newest last)
    /** note currently ringing on each string (null when silent/muted) */
    this.ringing = Array.from({ length: 6 }, () => null);
  }

  emit(type, detail = {}) {
    this.dispatchEvent(new CustomEvent(type, { detail }));
  }

  /* ---------------- tuning / capo ---------------- */

  setTuning(id) {
    this.tuning = getTuning(id);
    this.fretboard.setTuning(this.tuning);
    if (this.chord) this.setChord(this.chord.rootPc, this.chord.quality, 0);
    this.emit('tuning', { tuning: this.tuning });
  }

  setCapo(fret) {
    this.capo = Math.max(0, Math.min(12, fret | 0));
    // Chord shapes are relative to the capo, so the selected chord needs new shapes.
    if (this.chord) this.chord = this.buildChord(this.chord.rootPc, this.chord.quality, 0);
    this.emit('capo', { capo: this.capo });
    if (this.chord) this.emit('chord', { chord: this.chord });
  }

  /* ---------------- options ---------------- */

  setOption(key, value) {
    if (!(key in this.options)) throw new Error(`Unknown option ${key}`);
    this.options[key] = value;
    this.emit('option', { key, value });
  }

  /* ---------------- overlays ---------------- */

  /**
   * Voicings for a chord. With a capo the capo acts as the nut: shapes are
   * fingered relative to it (voicing fret 0 = the capo, fret n = capo + n), so
   * the chord named `rootPc` is played with the shape of the chord `capo`
   * semitones lower — exactly as on a real guitar.
   */
  buildChord(rootPc, quality, index = 0) {
    const voicings = chordVoicings(rootPc - this.capo, quality, this.fretboard.openMidi, { maxResults: 4 })
      .filter((v) => Math.max(0, ...v.frets) + this.capo <= this.fretboard.fretCount);
    return { rootPc, quality, voicings, capo: this.capo, index: Math.min(index, Math.max(0, voicings.length - 1)) };
  }

  setChord(rootPc, quality, index = 0) {
    this.chord = rootPc === null || rootPc === undefined ? null : this.buildChord(rootPc, quality, index);
    this.emit('chord', { chord: this.chord });
  }

  get chordVoicing() {
    return this.chord && this.chord.voicings.length ? this.chord.voicings[this.chord.index] : null;
  }

  setChordVoicing(index) {
    if (!this.chord) return;
    this.chord.index = Math.max(0, Math.min(this.chord.voicings.length - 1, index));
    this.emit('chord', { chord: this.chord });
  }

  setHoldChord(on) {
    this.holdChord = !!on;
    this.emit('chord', { chord: this.chord, hold: this.holdChord });
  }

  setScale(rootPc, scaleId) {
    this.scale = rootPc === null || rootPc === undefined ? null : { rootPc, scaleId, scale: getScale(scaleId) };
    this.emit('scale', { scale: this.scale });
  }

  setHighlight(pc) {
    this.highlightPc = pc === null || pc === undefined ? null : ((pc % 12) + 12) % 12;
    this.emit('highlight', { pitchClass: this.highlightPc });
  }

  /* ---------------- fingers ---------------- */

  /** Does this finger press the string? (A barre presses every string it lies across.) */
  covers(finger, string) {
    const from = finger.from === undefined ? finger.string : finger.from;
    return string >= Math.min(from, finger.string) && string <= Math.max(from, finger.string);
  }

  /** The strings a finger presses, low to high. */
  fingerStrings(finger) {
    const from = finger.from === undefined ? finger.string : finger.from;
    const out = [];
    for (let s = Math.min(from, finger.string); s <= Math.max(from, finger.string); s++) out.push(s);
    return out;
  }

  /** Highest fret held by a user finger on the string, or null. */
  fingerFret(string) {
    let best = null;
    for (const f of this.fingers.values()) if (this.covers(f, string) && (best === null || f.fret > best)) best = f.fret;
    return best;
  }

  /** A held (latched) finger pressing this string at this fret: `{ id, finger }` or null. */
  heldFingerAt(string, fret) {
    for (const [id, f] of this.fingers) if (f.held && f.fret === fret && this.covers(f, string)) return { id, finger: f };
    return null;
  }

  /** The fret that determines the sounding pitch: -1 = muted, 0 = open, n = fret. */
  soundingFret(string) {
    const finger = this.fingerFret(string);
    const voicing = this.holdChord ? this.chordVoicing : null;
    // Chord shapes are fingered relative to the capo; -1 = the chord mutes this string.
    const held = voicing ? this.chordFret(voicing.frets[string]) : null;
    // The highest fretted position on a string sets its pitch: an own finger behind a held chord's
    // finger changes nothing; an own finger on a string the chord mutes plays that string.
    // (A finger at or behind the capo presses a part of the string that does not sound.)
    if (finger !== null && finger > this.capo) return Math.max(finger, held === null ? 0 : held);
    if (held !== null) return held;
    return this.capo;
  }

  /** Absolute fret of a chord-voicing fret (-1 muted stays -1). */
  chordFret(f) {
    return f < 0 ? -1 : this.capo + f;
  }

  /** Bend (in semitones) applied by the finger that sets the string's pitch; 0 when not bent. */
  bendOn(string) {
    const fret = this.fingerFret(string);
    if (fret === null) return 0;
    let bend = 0;
    for (const f of this.fingers.values()) if (f.string === string && f.from === undefined && f.fret === fret && f.bend > bend) bend = f.bend;
    return bend;
  }

  /**
   * Describe the note currently selected on a string (null when muted).
   * `frequency` is the equal-tempered pitch of the fretted note; `playFrequency`
   * additionally includes any string bend.
   */
  noteOn(string) {
    const fret = this.soundingFret(string);
    if (fret < 0) return null;
    const midi = this.fretboard.midiAt(string, fret);
    const note = describeNote(midi, { flats: this.options.flats });
    const bend = this.bendOn(string);
    return { string, fret, lengthFraction: vibratingLengthFraction(fret), ...note, bend, playFrequency: note.frequency * Math.pow(2, bend / 12) };
  }

  pressFinger(pointerId, string, fret) {
    const previous = this.fingers.get(pointerId) || null;
    this.fingers.set(pointerId, { string, fret });
    this.emit('finger', { pointerId, string, fret, previous, action: previous ? 'move' : 'press' });
  }

  /**
   * Move a finger. Along its string it slides (a barre keeps its span). To another string it
   * either steps over (`barre` false: it leaves the strings it was on) or lies down across the
   * strings in between (`barre` true), back to a single string when it returns to where it began.
   */
  moveFinger(pointerId, string, fret, { barre = false } = {}) {
    const previous = this.fingers.get(pointerId);
    if (!previous) return this.pressFinger(pointerId, string, fret);
    if (previous.string === string && previous.fret === fret) return undefined;
    let next;
    if (previous.string === string) next = { ...previous, fret };
    else {
      next = { string, fret };
      const from = previous.from === undefined ? previous.string : previous.from;
      if (barre && from !== string) next.from = from;
      if (previous.held) next.held = true;
    }
    this.fingers.set(pointerId, next);
    this.emit('finger', { pointerId, string, fret, previous, action: 'move' });
    return undefined;
  }

  /** A barre stands up again: the finger keeps only the string it is on. */
  collapseFinger(pointerId) {
    const previous = this.fingers.get(pointerId);
    if (!previous || previous.from === undefined) return;
    const next = { ...previous };
    delete next.from;
    this.fingers.set(pointerId, next);
    this.emit('finger', { pointerId, string: next.string, fret: next.fret, previous, action: 'move' });
  }

  /** The touch lifts but the finger stays down (Hold mode). Returns the held finger's id. */
  holdFinger(pointerId) {
    const previous = this.fingers.get(pointerId);
    if (!previous) return null;
    this.fingers.delete(pointerId);
    const id = `held-${++this.heldCount}`;
    const finger = { string: previous.string, fret: previous.fret, held: true };
    if (previous.from !== undefined) finger.from = previous.from;
    this.fingers.set(id, finger);
    this.emit('finger', { pointerId: id, string: finger.string, fret: finger.fret, previous, action: 'hold' });
    return id;
  }

  /** Bend the string under a finger: `semitones` of pitch, `offset` px of sideways displacement (for drawing). */
  setFingerBend(pointerId, semitones, offset) {
    const finger = this.fingers.get(pointerId);
    if (!finger) return;
    finger.bend = Math.max(0, semitones);
    finger.offset = offset;
    this.emit('finger', { pointerId, string: finger.string, fret: finger.fret, previous: finger, action: 'bend' });
  }

  liftFinger(pointerId) {
    const previous = this.fingers.get(pointerId);
    if (!previous) return;
    this.fingers.delete(pointerId);
    this.emit('finger', { pointerId, string: previous.string, fret: previous.fret, previous, action: 'lift' });
  }

  /** Lift every finger that belongs to a touch; held fingers stay unless `held` is true. */
  liftAll({ held = false } = {}) {
    const all = [...this.fingers.entries()].filter(([, f]) => held || !f.held);
    for (const [pointerId] of all) this.fingers.delete(pointerId);
    for (const [pointerId, previous] of all) this.emit('finger', { pointerId, string: previous.string, fret: previous.fret, previous, action: 'lift' });
  }

  /* ---------------- played notes ---------------- */

  /** A pluck: recorded in the history and as the note now ringing on its string. */
  notePlayed(note, velocity) {
    const entry = { ...note, velocity, time: performance.now() };
    this.recent.push(entry);
    if (this.recent.length > 12) this.recent.shift();
    this.ringing[note.string] = entry;
    this.emit('played', { note: entry });
  }

  /**
   * The note ringing on a string changed without a pluck (slide, hammer-on,
   * pull-off, retune under a held finger) or stopped (null).
   */
  setRinging(string, note) {
    const previous = this.ringing[string];
    this.ringing[string] = note ? { ...note, velocity: previous ? previous.velocity : 0.5, time: performance.now() } : null;
    this.emit('ringing', { string, note: this.ringing[string] });
  }
}
