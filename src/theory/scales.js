/**
 * Scale definitions as semitone intervals from the root.
 */
import { pitchClass, pitchClassName } from './notes.js';

export const SCALES = Object.freeze([
  { id: 'major', name: 'Major (Ionian)', intervals: [0, 2, 4, 5, 7, 9, 11] },
  { id: 'natural-minor', name: 'Natural minor (Aeolian)', intervals: [0, 2, 3, 5, 7, 8, 10] },
  { id: 'harmonic-minor', name: 'Harmonic minor', intervals: [0, 2, 3, 5, 7, 8, 11] },
  { id: 'melodic-minor', name: 'Melodic minor', intervals: [0, 2, 3, 5, 7, 9, 11] },
  { id: 'major-pentatonic', name: 'Major pentatonic', intervals: [0, 2, 4, 7, 9] },
  { id: 'minor-pentatonic', name: 'Minor pentatonic', intervals: [0, 3, 5, 7, 10] },
  { id: 'blues', name: 'Blues', intervals: [0, 3, 5, 6, 7, 10] },
  { id: 'dorian', name: 'Dorian', intervals: [0, 2, 3, 5, 7, 9, 10] },
  { id: 'phrygian', name: 'Phrygian', intervals: [0, 1, 3, 5, 7, 8, 10] },
  { id: 'lydian', name: 'Lydian', intervals: [0, 2, 4, 6, 7, 9, 11], degrees: ['1', '2', '3', '#4', '5', '6', '7'] },
  { id: 'mixolydian', name: 'Mixolydian', intervals: [0, 2, 4, 5, 7, 9, 10] },
  { id: 'locrian', name: 'Locrian', intervals: [0, 1, 3, 5, 6, 8, 10] },
  { id: 'whole-tone', name: 'Whole tone', intervals: [0, 2, 4, 6, 8, 10], degrees: ['1', '2', '3', '#4', '#5', 'b7'] },
  { id: 'chromatic', name: 'Chromatic', intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] },
].map(Object.freeze));

export function getScale(id) {
  const s = SCALES.find((x) => x.id === id);
  if (!s) throw new Error(`Unknown scale: ${id}`);
  return s;
}

/** Degree labels used by the fretboard overlay ("1", "b3", "5"...). */
const DEGREE_LABELS = ['1', 'b2', '2', 'b3', '3', '4', 'b5', '5', 'b6', '6', 'b7', '7'];

/** Set of pitch classes for a scale starting on `rootPc`. */
export function scalePitchClasses(scale, rootPc) {
  return new Set(scale.intervals.map((i) => pitchClass(rootPc + i)));
}

/** Note names of the scale, in order from the root. */
export function scaleNoteNames(scale, rootPc, { flats = false } = {}) {
  return scale.intervals.map((i) => pitchClassName(rootPc + i, { flats }));
}

/** Scale degree label for a pitch class relative to the root, or null if not in scale. */
export function degreeLabel(scale, rootPc, pc) {
  const interval = pitchClass(pc - rootPc);
  const index = scale.intervals.indexOf(interval);
  if (index < 0) return null;
  // Scales may spell their own degrees (Lydian's raised 4th is "#4", not "b5").
  return scale.degrees ? scale.degrees[index] : DEGREE_LABELS[interval];
}

/** All fretboard positions in the scale, each tagged with its degree label. */
export function scalePositions(fretboard, scale, rootPc) {
  const set = scalePitchClasses(scale, rootPc);
  const out = [];
  for (let s = 0; s < fretboard.openMidi.length; s++) {
    for (let f = 0; f <= fretboard.fretCount; f++) {
      const midi = fretboard.openMidi[s] + f;
      const pc = pitchClass(midi);
      if (set.has(pc)) {
        out.push({ string: s, fret: f, midi, pitchClass: pc, isRoot: pc === pitchClass(rootPc), degree: degreeLabel(scale, rootPc, pc) });
      }
    }
  }
  return out;
}
