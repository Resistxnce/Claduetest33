/**
 * Fretboard model: maps (string, fret) to pitch, and computes the physical
 * geometry of the frets along the scale length.
 *
 * Pitch rule: every fret raises the open-string pitch by exactly one semitone,
 * so midi(string, fret) = openMidi(string) + fret. Nothing is hard-coded.
 *
 * Geometry rule ("rule of 18", exact form): the distance from the nut to fret n
 * is  L - L / 2^(n/12)  where L is the scale length. The 12th fret therefore
 * sits exactly at L/2 and sounds the octave.
 */
import { describeNote, midiToFrequency, midiToName, pitchClass } from './notes.js';
import { getTuning } from './tunings.js';

export const STRING_COUNT = 6;
export const DEFAULT_FRET_COUNT = 22;
/** Fender-style scale length in inches (25.5"). Only ratios matter for drawing. */
export const DEFAULT_SCALE_LENGTH_INCHES = 25.5;

/** Distance from the nut to fret `n` as a fraction of the scale length. */
export function fretDistanceFraction(n) {
  if (n <= 0) return 0;
  return 1 - Math.pow(2, -n / 12);
}

/** Vibrating string length (as a fraction of scale length) when fretted at `n`. */
export function vibratingLengthFraction(n) {
  return Math.pow(2, -Math.max(0, n) / 12);
}

/** Fret positions (fraction of scale length) for frets 0..count. */
export function fretPositions(count = DEFAULT_FRET_COUNT) {
  const out = new Array(count + 1);
  for (let i = 0; i <= count; i++) out[i] = fretDistanceFraction(i);
  return out;
}

/** Standard single-dot inlay positions, plus the double-dot octave at 12 and 24. */
export const SINGLE_MARKER_FRETS = Object.freeze([3, 5, 7, 9, 15, 17, 19, 21]);
export const DOUBLE_MARKER_FRETS = Object.freeze([12, 24]);

export function isMarkerFret(fret) {
  return SINGLE_MARKER_FRETS.includes(fret) || DOUBLE_MARKER_FRETS.includes(fret);
}

/** Gauge of a typical .010–.046 electric set, in inches, low to high. */
export const STRING_GAUGES_INCHES = Object.freeze([0.046, 0.036, 0.026, 0.017, 0.013, 0.010]);
/** Which strings are wound (affects timbre and the drawn texture). */
export const STRING_WOUND = Object.freeze([true, true, true, false, false, false]);

export class Fretboard {
  /**
   * @param {object} [options]
   * @param {object} [options.tuning] a tuning object from tunings.js
   * @param {number} [options.fretCount]
   */
  constructor({ tuning = getTuning('standard'), fretCount = DEFAULT_FRET_COUNT } = {}) {
    this.fretCount = fretCount;
    this.setTuning(tuning);
  }

  setTuning(tuning) {
    if (!tuning || !Array.isArray(tuning.midi) || tuning.midi.length !== STRING_COUNT) {
      throw new Error('Tuning must provide six open-string MIDI numbers');
    }
    this.tuning = tuning;
    this.openMidi = [...tuning.midi];
  }

  assertPosition(stringIdx, fret) {
    if (!Number.isInteger(stringIdx) || stringIdx < 0 || stringIdx >= STRING_COUNT) {
      throw new RangeError(`String index out of range: ${stringIdx}`);
    }
    if (!Number.isInteger(fret) || fret < 0 || fret > this.fretCount) {
      throw new RangeError(`Fret out of range: ${fret}`);
    }
  }

  /** MIDI number sounding at a string/fret position. */
  midiAt(stringIdx, fret) {
    this.assertPosition(stringIdx, fret);
    return this.openMidi[stringIdx] + fret;
  }

  frequencyAt(stringIdx, fret) {
    return midiToFrequency(this.midiAt(stringIdx, fret));
  }

  noteNameAt(stringIdx, fret, opts) {
    return midiToName(this.midiAt(stringIdx, fret), opts);
  }

  /** Full note description including names, octave, MIDI and frequency. */
  noteAt(stringIdx, fret, opts) {
    return { string: stringIdx, fret, ...describeNote(this.midiAt(stringIdx, fret), opts) };
  }

  /** Every position (string, fret) on the board whose pitch class matches. */
  positionsOfPitchClass(pc) {
    const target = pitchClass(pc);
    const out = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      for (let f = 0; f <= this.fretCount; f++) {
        if (pitchClass(this.openMidi[s] + f) === target) out.push({ string: s, fret: f });
      }
    }
    return out;
  }

  /** Every position sounding exactly this MIDI note (same octave). */
  positionsOfMidi(midi) {
    const out = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      const f = midi - this.openMidi[s];
      if (f >= 0 && f <= this.fretCount) out.push({ string: s, fret: f });
    }
    return out;
  }

  /** Lowest and highest MIDI notes available on the board. */
  range() {
    return { min: Math.min(...this.openMidi), max: Math.max(...this.openMidi) + this.fretCount };
  }

  /** Full table of notes, [string][fret]. */
  table(opts) {
    const rows = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      const row = [];
      for (let f = 0; f <= this.fretCount; f++) row.push(this.noteAt(s, f, opts));
      rows.push(row);
    }
    return rows;
  }
}
