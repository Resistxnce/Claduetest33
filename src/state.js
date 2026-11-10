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
    /** @type {Map<number, {string:number, fret:number}>} pointerId -> finger */
    this.fingers = new Map();
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

  /** Highest fret held by a user finger on the string, or null. */
  fingerFret(string) {
    let best = null;
    for (const f of this.fingers.values()) if (f.string === string && (best === null || f.fret > best)) best = f.fret;
    return best;
  }

  /** The fret that determines the sounding pitch: -1 = muted, 0 = open, n = fret. */
  soundingFret(string) {
    const finger = this.fingerFret(string);
    if (finger !== null) return Math.max(finger, this.capo);
    const voicing = this.holdChord ? this.chordVoicing : null;
    if (voicing) {
      const f = voicing.frets[string];
      if (f < 0) return -1;
      return this.capo + f; // chord shapes are fingered relative to the capo
    }
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
    for (const f of this.fingers.values()) if (f.string === string && f.fret === fret && f.bend > bend) bend = f.bend;
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

  moveFinger(pointerId, string, fret) {
    const previous = this.fingers.get(pointerId);
    if (!previous) return this.pressFinger(pointerId, string, fret);
    if (previous.string === string && previous.fret === fret) return undefined;
    this.fingers.set(pointerId, previous.string === string ? { ...previous, fret } : { string, fret });
    this.emit('finger', { pointerId, string, fret, previous, action: 'move' });
    return undefined;
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

  liftAll() {
    const all = [...this.fingers.entries()];
    this.fingers.clear();
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
