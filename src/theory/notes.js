/**
 * Core pitch mathematics.
 *
 * Everything in the simulator derives pitch from MIDI note numbers:
 *   - A4 = MIDI 69 = 440 Hz (equal temperament)
 *   - C4 (middle C) = MIDI 60
 *   - Octave numbers follow the scientific pitch notation convention
 *     used by MIDI: octave = floor(midi / 12) - 1, so E2 = MIDI 40.
 */

export const A4_MIDI = 69;
export const A4_FREQUENCY = 440;

export const SHARP_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
export const FLAT_NAMES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];

const PITCH_CLASS_BY_LETTER = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

/** Normalise any integer (including negatives) into the 0..11 pitch-class range. */
export function pitchClass(midi) {
  return ((Math.round(midi) % 12) + 12) % 12;
}

/** Octave number for a MIDI note (MIDI 60 -> 4, MIDI 40 -> 2). */
export function octaveOf(midi) {
  return Math.floor(Math.round(midi) / 12) - 1;
}

/** Frequency in Hz of a MIDI note in 12-tone equal temperament, A4 = 440 Hz. */
export function midiToFrequency(midi, a4 = A4_FREQUENCY) {
  return a4 * Math.pow(2, (midi - A4_MIDI) / 12);
}

/** Fractional MIDI number of a frequency (inverse of midiToFrequency). */
export function frequencyToMidi(frequency, a4 = A4_FREQUENCY) {
  return A4_MIDI + 12 * Math.log2(frequency / a4);
}

/** Cents offset between two frequencies. */
export function centsBetween(fromHz, toHz) {
  return 1200 * Math.log2(toHz / fromHz);
}

/** Pitch-class name only ("F#", or "Gb" when flats are preferred). */
export function pitchClassName(midiOrPc, { flats = false } = {}) {
  const names = flats ? FLAT_NAMES : SHARP_NAMES;
  return names[pitchClass(midiOrPc)];
}

/** Full note name with octave, e.g. midiToName(42) === "F#2". */
export function midiToName(midi, { flats = false } = {}) {
  return `${pitchClassName(midi, { flats })}${octaveOf(midi)}`;
}

/** Both spellings of a pitch class: ["C#", "Db"]. Naturals return a single entry. */
export function enharmonicNames(midiOrPc) {
  const pc = pitchClass(midiOrPc);
  const sharp = SHARP_NAMES[pc];
  const flat = FLAT_NAMES[pc];
  return sharp === flat ? [sharp] : [sharp, flat];
}

/** The alternative spelling of a note name ("C#" -> "Db", "Db" -> "C#", "E" -> "E"). */
export function enharmonicEquivalent(name) {
  const m = /^([A-Ga-g])([#b♯♭]?)(-?\d+)?$/.exec(name.trim());
  if (!m) throw new Error(`Invalid note name: ${name}`);
  const pc = pitchClass(parseNote(`${m[1]}${m[2]}4`));
  const octave = m[3] ?? '';
  const sharp = SHARP_NAMES[pc];
  const flat = FLAT_NAMES[pc];
  if (sharp === flat) return `${sharp}${octave}`;
  const current = `${m[1].toUpperCase()}${m[2].replace('♯', '#').replace('♭', 'b')}`;
  return `${current === sharp ? flat : sharp}${octave}`;
}

/**
 * Parse a note name into a MIDI number. Accepts "E2", "F#2", "Gb2", "C-1", "a4",
 * unicode accidentals (♯ ♭) and double accidentals ("C##4", "Dbb4").
 */
export function parseNote(name) {
  const m = /^\s*([A-Ga-g])((?:#|b|♯|♭|x){0,2})\s*(-?\d+)\s*$/.exec(name);
  if (!m) throw new Error(`Invalid note name: ${name}`);
  const letter = m[1].toUpperCase();
  let accidental = 0;
  for (const ch of m[2]) {
    if (ch === '#' || ch === '♯') accidental += 1;
    else if (ch === 'b' || ch === '♭') accidental -= 1;
    else if (ch === 'x') accidental += 2;
  }
  const octave = parseInt(m[3], 10);
  return (octave + 1) * 12 + PITCH_CLASS_BY_LETTER[letter] + accidental;
}

/** Parse a pitch-class name without octave ("F#", "Bb") into 0..11. */
export function parsePitchClass(name) {
  return pitchClass(parseNote(`${name.trim()}4`));
}

/** Transpose a MIDI note by a number of semitones. */
export function transpose(midi, semitones) {
  return midi + semitones;
}

/** A complete description of a pitch, handy for UI read-outs. */
export function describeNote(midi, { flats = false } = {}) {
  const pc = pitchClass(midi);
  return {
    midi,
    pitchClass: pc,
    name: midiToName(midi, { flats }),
    pitchClassName: pitchClassName(pc, { flats }),
    sharpName: midiToName(midi, { flats: false }),
    flatName: midiToName(midi, { flats: true }),
    enharmonics: enharmonicNames(pc),
    octave: octaveOf(midi),
    frequency: midiToFrequency(midi),
  };
}
