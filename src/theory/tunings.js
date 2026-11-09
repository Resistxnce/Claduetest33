/**
 * Guitar tunings. Each tuning lists the open-string MIDI notes from the
 * thickest string (string 6) to the thinnest (string 1), which is also the
 * order used for string indices throughout the code base:
 *
 *   index 0 -> string 6 (low E in standard tuning)
 *   index 5 -> string 1 (high E in standard tuning)
 */
import { midiToName, parseNote } from './notes.js';

function tuning(id, name, notes, description) {
  return Object.freeze({
    id,
    name,
    description,
    notes: Object.freeze([...notes]),
    midi: Object.freeze(notes.map(parseNote)),
  });
}

export const TUNINGS = Object.freeze([
  tuning('standard', 'Standard', ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'], 'E A D G B E — the default tuning.'),
  tuning('drop-d', 'Drop D', ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'], 'Low string dropped a whole step to D.'),
  tuning('half-step-down', 'Half-step down (E♭)', ['Eb2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4'], 'Every string lowered one semitone.'),
  tuning('whole-step-down', 'Whole-step down (D)', ['D2', 'G2', 'C3', 'F3', 'A3', 'D4'], 'Every string lowered two semitones.'),
  tuning('open-g', 'Open G', ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'], 'Strumming the open strings gives a G major chord.'),
  tuning('open-d', 'Open D', ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4'], 'Strumming the open strings gives a D major chord.'),
  tuning('dadgad', 'DADGAD', ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'], 'Celtic / modal tuning — Dsus4 when strummed open.'),
  tuning('drop-c', 'Drop C', ['C2', 'G2', 'C3', 'F3', 'A3', 'D4'], 'Whole-step down with the low string dropped to C.'),
  tuning('open-e', 'Open E', ['E2', 'B2', 'E3', 'G#3', 'B3', 'E4'], 'Strumming the open strings gives an E major chord.'),
  tuning('open-a', 'Open A', ['E2', 'A2', 'E3', 'A3', 'C#4', 'E4'], 'Strumming the open strings gives an A major chord.'),
]);

export const DEFAULT_TUNING_ID = 'standard';

export function getTuning(id) {
  const t = TUNINGS.find((x) => x.id === id);
  if (!t) throw new Error(`Unknown tuning: ${id}`);
  return t;
}

/** Build a custom tuning from six note names (low to high). */
export function customTuning(notes, name = 'Custom') {
  if (notes.length !== 6) throw new Error('A guitar tuning needs exactly six notes');
  return tuning('custom', name, notes, 'User defined tuning.');
}

/** "E A D G B E" style label, low to high. */
export function tuningLabel(t, { flats = false } = {}) {
  return t.midi.map((m) => midiToName(m, { flats }).replace(/-?\d+$/, '')).join(' ');
}

/** Guitar string number (6..1) for a string index (0..5). */
export function stringNumber(index) {
  return 6 - index;
}

/** String index (0..5) for a guitar string number (6..1). */
export function stringIndex(number) {
  return 6 - number;
}
