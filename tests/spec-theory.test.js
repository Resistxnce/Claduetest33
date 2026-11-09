// Independent, specification-derived verification suite for the music-theory core.
//
// Every expectation in this file is derived from the product specification and from
// first principles using the reference helpers defined below (own letter -> semitone
// table, own 440 * 2^((m - 69) / 12) formula, own octave = floor(m / 12) - 1, own
// tuning tables, own scale formulas). Nothing here is copied from the implementation;
// only the public API of src/theory/* is exercised.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

import {
  midiToFrequency,
  midiToName,
  parseNote,
  pitchClass,
  octaveOf,
  enharmonicNames,
  enharmonicEquivalent,
  describeNote,
  frequencyToMidi,
  pitchClassName,
} from '../src/theory/notes.js';
import { TUNINGS, getTuning, tuningLabel } from '../src/theory/tunings.js';
import {
  Fretboard,
  fretDistanceFraction,
  fretPositions,
  vibratingLengthFraction,
  STRING_COUNT,
} from '../src/theory/fretboard.js';
import { SCALES, getScale, scalePitchClasses, scaleNoteNames } from '../src/theory/scales.js';

// ---------------------------------------------------------------------------
// Reference helpers — independent derivation (do not import from src/)
// ---------------------------------------------------------------------------

const SHARP_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const FLAT_NAMES = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];
const LETTER_SEMITONES = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
const A4_MIDI = 69;
const A4_HZ = 440;
const SEMITONE_RATIO = 2 ** (1 / 12);

const refPc = (m) => ((m % 12) + 12) % 12;
const refOctave = (m) => Math.floor(m / 12) - 1;
const refName = (m, flats = false) => (flats ? FLAT_NAMES : SHARP_NAMES)[refPc(m)] + refOctave(m);
const refFreq = (m) => A4_HZ * 2 ** ((m - A4_MIDI) / 12);
const refEnharmonics = (pc) =>
  SHARP_NAMES[pc] === FLAT_NAMES[pc] ? [SHARP_NAMES[pc]] : [SHARP_NAMES[pc], FLAT_NAMES[pc]];

/** Parse "<letter><accidental?><octave>" into a MIDI number from first principles. */
function refParse(str) {
  const m = /^\s*([A-Ga-g])([#♯]|[b♭])?(-?\d+)\s*$/.exec(str);
  if (!m) throw new Error(`refParse: invalid note "${str}"`);
  const letter = m[1].toUpperCase();
  const accidental = m[2] === undefined ? 0 : m[2] === '#' || m[2] === '♯' ? 1 : -1;
  const octave = Number(m[3]);
  return (octave + 1) * 12 + LETTER_SEMITONES[letter] + accidental;
}

function assertClose(actual, expected, relTol, msg = '') {
  const tol = Math.abs(expected) * relTol;
  assert.ok(
    Number.isFinite(actual) && Math.abs(actual - expected) <= tol,
    `${msg} expected ${expected} (±${tol}), got ${actual}`,
  );
}

const posKey = (p) => `${p.string}:${p.fret}`;
const sortedKeys = (positions) => positions.map(posKey).sort();

/** Brute-force positions of a predicate over an open-string MIDI array. */
function refPositions(openMidi, fretCount, predicate) {
  const out = [];
  for (let s = 0; s < openMidi.length; s++) {
    for (let f = 0; f <= fretCount; f++) {
      if (predicate(openMidi[s] + f)) out.push({ string: s, fret: f });
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Specification constants (own tables)
// ---------------------------------------------------------------------------

const STANDARD_OPEN_MIDI = [40, 45, 50, 55, 59, 64]; // E2 A2 D3 G3 B3 E4

// Spec: alternative tunings, low -> high (string index 0 = thickest).
const SPEC_TUNINGS = {
  standard: { notes: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4'], midi: [40, 45, 50, 55, 59, 64] },
  'drop-d': { notes: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'], midi: [38, 45, 50, 55, 59, 64] },
  'half-step-down': { notes: ['Eb2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4'], midi: [39, 44, 49, 54, 58, 63] },
  'whole-step-down': { notes: ['D2', 'G2', 'C3', 'F3', 'A3', 'D4'], midi: [38, 43, 48, 53, 57, 62] },
  'open-g': { notes: ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'], midi: [38, 43, 50, 55, 59, 62] },
  'open-d': { notes: ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4'], midi: [38, 45, 50, 54, 57, 62] },
  dadgad: { notes: ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'], midi: [38, 45, 50, 55, 57, 62] },
};

// Spec frequency anchors (Hz).
const FREQUENCY_ANCHORS = [
  ['E2', 40, 82.4069],
  ['A2', 45, 110],
  ['D3', 50, 146.832],
  ['G3', 55, 195.998],
  ['B3', 59, 246.942],
  ['E4', 64, 329.628],
  ['A4', 69, 440],
  ['C4', 60, 261.626],
  ['E5', 76, 659.255],
  ['E6', 88, 1318.51],
];

// Scale formulas (semitones from the root), from standard music theory.
const SPEC_SCALES = {
  major: [0, 2, 4, 5, 7, 9, 11],
  'natural-minor': [0, 2, 3, 5, 7, 8, 10],
  'harmonic-minor': [0, 2, 3, 5, 7, 8, 11],
  'melodic-minor': [0, 2, 3, 5, 7, 9, 11],
  'major-pentatonic': [0, 2, 4, 7, 9],
  'minor-pentatonic': [0, 3, 5, 7, 10],
  blues: [0, 3, 5, 6, 7, 10],
  dorian: [0, 2, 3, 5, 7, 9, 10],
  phrygian: [0, 1, 3, 5, 7, 8, 10],
  lydian: [0, 2, 4, 6, 7, 9, 11],
  mixolydian: [0, 2, 4, 5, 7, 9, 10],
  locrian: [0, 1, 3, 5, 6, 8, 10],
  chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
};

const MIDI_LO = 24;
const MIDI_HI = 100;
const FRET_COUNTS = [22, 24];

// ---------------------------------------------------------------------------
// 0. Sanity of the reference helpers themselves (so failures below are meaningful)
// ---------------------------------------------------------------------------

describe('0. reference helpers are self-consistent', () => {
  test('anchor names, octaves and frequencies', () => {
    assert.equal(refName(60), 'C4');
    assert.equal(refName(40), 'E2');
    assert.equal(refName(69), 'A4');
    assert.equal(refName(42), 'F#2');
    assert.equal(refName(42, true), 'Gb2');
    assert.equal(refOctave(0), -1);
    assert.equal(refFreq(69), 440);
    assert.equal(refFreq(57), 220);
    assert.equal(refFreq(81), 880);
    assert.equal(refParse('F#2'), 42);
    assert.equal(refParse('Gb2'), 42);
    assert.equal(refParse('C♯4'), 61);
    assert.equal(refParse('a4'), 69);
  });

  test('spec tuning tables: note spellings and MIDI numbers agree', () => {
    for (const [id, { notes, midi }] of Object.entries(SPEC_TUNINGS)) {
      assert.deepEqual(notes.map(refParse), midi, `spec table for ${id}`);
    }
    assert.deepEqual(SPEC_TUNINGS.standard.midi, STANDARD_OPEN_MIDI);
  });
});

// ---------------------------------------------------------------------------
// 1. Reference table of note names for MIDI 24..100 and parseNote round trips
// ---------------------------------------------------------------------------

describe('1. note names and parsing (MIDI 24..100)', () => {
  test('midiToName matches reference table in sharp spelling (default and explicit)', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assert.equal(midiToName(m), refName(m), `midiToName(${m})`);
      assert.equal(midiToName(m, { flats: false }), refName(m), `midiToName(${m}, sharps)`);
    }
  });

  test('midiToName matches reference table in flat spelling', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assert.equal(midiToName(m, { flats: true }), refName(m, true), `midiToName(${m}, flats)`);
    }
  });

  test('octave numbering follows octave = floor(midi / 12) - 1 (C4 = 60, E2 = 40, A4 = 69)', () => {
    assert.equal(midiToName(60), 'C4');
    assert.equal(midiToName(40), 'E2');
    assert.equal(midiToName(69), 'A4');
    assert.equal(midiToName(59), 'B3');
    assert.equal(midiToName(0), 'C-1');
    assert.equal(midiToName(127), 'G9');
    for (let m = 0; m <= 127; m++) {
      assert.equal(octaveOf(m), refOctave(m), `octaveOf(${m})`);
      assert.equal(pitchClass(m), refPc(m), `pitchClass(${m})`);
      assert.ok(midiToName(m).endsWith(String(refOctave(m))), `octave suffix of midiToName(${m})`);
    }
  });

  test('parseNote round-trips every sharp and flat name for MIDI 24..100', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assert.equal(parseNote(refName(m)), m, `parseNote(${refName(m)})`);
      assert.equal(parseNote(refName(m, true)), m, `parseNote(${refName(m, true)})`);
      assert.equal(parseNote(midiToName(m)), m, `parseNote(midiToName(${m}))`);
      assert.equal(parseNote(midiToName(m, { flats: true })), m, `parseNote(midiToName(${m}, flats))`);
    }
  });

  test('parseNote accepts lower-case letters and unicode accidentals', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      const sharp = refName(m);
      const flat = refName(m, true);
      assert.equal(parseNote(sharp.toLowerCase()), m, `lower-case ${sharp}`);
      assert.equal(parseNote(flat[0].toLowerCase() + flat.slice(1)), m, `lower-case letter ${flat}`);
      assert.equal(parseNote(sharp.replace('#', '♯')), m, `unicode sharp ${sharp}`);
      assert.equal(parseNote(flat.replace(/^([A-G])b/, '$1♭')), m, `unicode flat ${flat}`);
    }
  });

  test('parseNote: explicit spec examples', () => {
    assert.equal(parseNote('F#2'), 42);
    assert.equal(parseNote('Gb2'), 42);
    assert.equal(parseNote('C♯4'), 61);
    assert.equal(parseNote('a4'), 69);
    assert.equal(parseNote('E2'), 40);
    assert.equal(parseNote('C4'), 60);
    assert.equal(parseNote('A4'), 69);
    assert.equal(parseNote('C-1'), 0);
    assert.equal(parseNote('G9'), 127);
  });

  test('parseNote handles letter + accidental arithmetic across octave boundaries', () => {
    // These follow directly from letter semitone + accidental offset.
    assert.equal(parseNote('Cb4'), 59); // = B3
    assert.equal(parseNote('B#3'), 60); // = C4
    assert.equal(parseNote('E#4'), 65); // = F4
    assert.equal(parseNote('Fb4'), 64); // = E4
  });

  test('parseNote throws on malformed input', () => {
    const invalid = ['H2', '', 'xyz', '#4', 'C#', 'E', '4', 'C 4 5', 'Cq4', 'C#4#', 'C4b', 'C4.5'];
    const accepted = [];
    for (const s of invalid) {
      let result;
      try {
        result = parseNote(s);
      } catch {
        continue;
      }
      accepted.push(`${JSON.stringify(s)} -> ${result}`);
    }
    assert.deepEqual(accepted, [], `parseNote accepted invalid input: ${accepted.join(', ')}`);
  });

  test('parseNote rejects contradictory accidental sequences (flat+sharp, sharp+double-sharp)', () => {
    // "Cb#4", "C#b4" and "C#x4" are not note names under any notation convention
    // (a single accidental, or a double sharp/flat, is the most a name can carry).
    const invalid = ['Cb#4', 'C#b4', 'C#x4', 'Cx#4', 'Cbx4'];
    const accepted = [];
    for (const s of invalid) {
      let result;
      try {
        result = parseNote(s);
      } catch {
        continue;
      }
      accepted.push(`${JSON.stringify(s)} -> ${result}`);
    }
    assert.deepEqual(accepted, [], `parseNote accepted contradictory accidentals: ${accepted.join(', ')}`);
  });
});

// ---------------------------------------------------------------------------
// 2. Frequencies (equal temperament, A4 = 440 Hz)
// ---------------------------------------------------------------------------

describe('2. frequencies', () => {
  test('A4 = MIDI 69 = 440 Hz exactly', () => {
    assert.equal(midiToFrequency(69), 440);
  });

  test('midiToFrequency matches 440 * 2^((m - 69) / 12) for MIDI 24..100 (1e-6 relative)', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assertClose(midiToFrequency(m), refFreq(m), 1e-6, `midiToFrequency(${m})`);
    }
  });

  test('well-known frequency anchors', () => {
    for (const [name, midi, hz] of FREQUENCY_ANCHORS) {
      assert.equal(parseNote(name), midi, `anchor ${name} midi`);
      assertClose(midiToFrequency(midi), hz, 5e-6, `frequency of ${name}`);
      assertClose(midiToFrequency(parseNote(name)), hz, 5e-6, `frequency of parsed ${name}`);
    }
  });

  test('octaves double, semitones multiply by 2^(1/12)', () => {
    for (let m = MIDI_LO; m < MIDI_HI; m++) {
      assertClose(midiToFrequency(m + 1) / midiToFrequency(m), SEMITONE_RATIO, 1e-9, `ratio ${m}->${m + 1}`);
      if (m + 12 <= MIDI_HI) {
        assertClose(midiToFrequency(m + 12), 2 * midiToFrequency(m), 1e-9, `octave ${m}`);
      }
    }
    assert.equal(midiToFrequency(57), 220);
    assert.equal(midiToFrequency(81), 880);
    assertClose(midiToFrequency(45), 110, 1e-12, 'A2');
  });

  test('frequencyToMidi inverts midiToFrequency and yields fractional values', () => {
    assert.equal(frequencyToMidi(440), 69);
    assertClose(frequencyToMidi(220), 57, 1e-12, 'A3');
    assertClose(frequencyToMidi(880), 81, 1e-12, 'A5');
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assertClose(frequencyToMidi(refFreq(m)), m, 1e-9, `frequencyToMidi(refFreq(${m}))`);
      assertClose(frequencyToMidi(midiToFrequency(m)), m, 1e-9, `round trip ${m}`);
    }
    // Quarter tone above A4 (440 * 2^(0.5/12)) is MIDI 69.5.
    assertClose(frequencyToMidi(440 * 2 ** (0.5 / 12)), 69.5, 1e-9, 'quarter tone');
    // 50 cents below A4.
    assertClose(frequencyToMidi(440 * 2 ** (-0.5 / 12)), 68.5, 1e-9, 'quarter tone down');
  });
});

// ---------------------------------------------------------------------------
// Pitch-class names and describeNote
// ---------------------------------------------------------------------------

describe('pitch classes and describeNote', () => {
  test('pitchClassName for pitch classes 0..11 and for MIDI 24..100', () => {
    for (let pc = 0; pc < 12; pc++) {
      assert.equal(pitchClassName(pc), SHARP_NAMES[pc], `pitchClassName(${pc})`);
      assert.equal(pitchClassName(pc, { flats: true }), FLAT_NAMES[pc], `pitchClassName(${pc}, flats)`);
      assert.equal(pitchClassName(pc, { flats: false }), SHARP_NAMES[pc], `pitchClassName(${pc}, sharps)`);
    }
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      assert.equal(pitchClassName(m), SHARP_NAMES[refPc(m)], `pitchClassName(${m})`);
      assert.equal(pitchClassName(m, { flats: true }), FLAT_NAMES[refPc(m)], `pitchClassName(${m}, flats)`);
    }
    assert.equal(pitchClassName(66), 'F#');
    assert.equal(pitchClassName(6), 'F#');
    assert.equal(pitchClassName(66, { flats: true }), 'Gb');
  });

  test('describeNote returns the full, internally consistent description', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      for (const flats of [false, true]) {
        const d = describeNote(m, { flats });
        const pc = refPc(m);
        assert.equal(d.midi, m, `describeNote(${m}).midi`);
        assert.equal(d.pitchClass, pc, `describeNote(${m}).pitchClass`);
        assert.equal(d.octave, refOctave(m), `describeNote(${m}).octave`);
        assert.equal(d.name, refName(m, flats), `describeNote(${m}, flats=${flats}).name`);
        assert.equal(d.pitchClassName, (flats ? FLAT_NAMES : SHARP_NAMES)[pc], `describeNote(${m}).pitchClassName`);
        assert.equal(d.sharpName, refName(m, false), `describeNote(${m}).sharpName`);
        assert.equal(d.flatName, refName(m, true), `describeNote(${m}).flatName`);
        assert.deepEqual(d.enharmonics, refEnharmonics(pc), `describeNote(${m}).enharmonics`);
        assertClose(d.frequency, refFreq(m), 1e-9, `describeNote(${m}).frequency`);
        assert.equal(d.name, d.pitchClassName + d.octave, `name = pitchClassName + octave for ${m}`);
      }
      // Default spelling is sharps.
      assert.equal(describeNote(m).name, refName(m), `describeNote(${m}) default spelling`);
    }
  });
});

// ---------------------------------------------------------------------------
// 3. Every tuning x every string x every fret (22- and 24-fret boards)
// ---------------------------------------------------------------------------

describe('3. fretboard: exhaustive pitch mapping for every tuning', () => {
  test('STRING_COUNT is six', () => {
    assert.equal(STRING_COUNT, 6);
  });

  test('TUNINGS entries are well formed and internally consistent', () => {
    assert.ok(Array.isArray(TUNINGS) && TUNINGS.length >= 7, 'TUNINGS is an array of at least 7 tunings');
    const ids = new Set();
    for (const t of TUNINGS) {
      assert.equal(typeof t.id, 'string', 'tuning id');
      assert.ok(t.id.length > 0, 'non-empty id');
      assert.ok(!ids.has(t.id), `duplicate tuning id ${t.id}`);
      ids.add(t.id);
      assert.equal(typeof t.name, 'string', `${t.id} name`);
      assert.ok(Array.isArray(t.notes) && t.notes.length === 6, `${t.id} has six note names`);
      assert.ok(Array.isArray(t.midi) && t.midi.length === 6, `${t.id} has six MIDI numbers`);
      for (let s = 0; s < 6; s++) {
        assert.ok(Number.isInteger(t.midi[s]), `${t.id} midi[${s}] is an integer`);
        assert.equal(t.midi[s], refParse(t.notes[s]), `${t.id}: notes[${s}] (${t.notes[s]}) must equal midi[${s}]`);
        assert.equal(parseNote(t.notes[s]), t.midi[s], `${t.id}: parseNote(notes[${s}])`);
      }
      assert.equal(getTuning(t.id), t, `getTuning(${t.id}) returns the tuning`);
    }
    for (const id of Object.keys(SPEC_TUNINGS)) {
      assert.ok(ids.has(id), `required tuning ${id} present`);
    }
  });

  for (const tuning of TUNINGS) {
    for (const fretCount of FRET_COUNTS) {
      test(`${tuning.id} / ${fretCount} frets: midi, frequency, names, table, semitone steps`, () => {
        const fb = new Fretboard({ tuning, fretCount });
        const open = tuning.notes.map(refParse); // own derivation of open-string MIDI
        const table = fb.table();
        assert.ok(Array.isArray(table) && table.length === 6, 'table has six string rows');

        for (let s = 0; s < 6; s++) {
          assert.ok(Array.isArray(table[s]) && table[s].length === fretCount + 1, `table row ${s} has ${fretCount + 1} cells`);
          for (let f = 0; f <= fretCount; f++) {
            const midi = open[s] + f;
            const label = `${tuning.id} s${s} f${f}`;

            assert.equal(fb.midiAt(s, f), midi, `${label} midiAt`);
            assertClose(fb.frequencyAt(s, f), refFreq(midi), 1e-9, `${label} frequencyAt`);
            assert.equal(fb.noteNameAt(s, f), refName(midi), `${label} noteNameAt (sharps)`);
            assert.equal(fb.noteNameAt(s, f, { flats: true }), refName(midi, true), `${label} noteNameAt (flats)`);
            assert.equal(fb.noteNameAt(s, f, { flats: false }), refName(midi), `${label} noteNameAt (explicit sharps)`);

            const n = fb.noteAt(s, f);
            assert.equal(n.string, s, `${label} noteAt.string`);
            assert.equal(n.fret, f, `${label} noteAt.fret`);
            assert.equal(n.midi, midi, `${label} noteAt.midi`);
            assert.equal(n.name, refName(midi), `${label} noteAt.name`);
            assert.equal(n.sharpName, refName(midi), `${label} noteAt.sharpName`);
            assert.equal(n.flatName, refName(midi, true), `${label} noteAt.flatName`);
            assert.equal(n.pitchClass, refPc(midi), `${label} noteAt.pitchClass`);
            assert.equal(n.octave, refOctave(midi), `${label} noteAt.octave`);
            assertClose(n.frequency, refFreq(midi), 1e-9, `${label} noteAt.frequency`);
            assert.deepEqual(n, { ...describeNote(midi), string: s, fret: f }, `${label} noteAt = describeNote + {string, fret}`);

            const cell = table[s][f];
            const cellMidi = typeof cell === 'number' ? cell : cell.midi;
            assert.equal(cellMidi, midi, `${label} table cell midi`);
            if (typeof cell === 'object') {
              assert.equal(cell.string, s, `${label} table cell string`);
              assert.equal(cell.fret, f, `${label} table cell fret`);
              assert.equal(cell.name, refName(midi), `${label} table cell name`);
            }

            if (f < fretCount) {
              assert.equal(fb.midiAt(s, f + 1) - fb.midiAt(s, f), 1, `${label} next fret is one semitone up`);
              assertClose(fb.frequencyAt(s, f + 1) / fb.frequencyAt(s, f), SEMITONE_RATIO, 1e-9, `${label} semitone ratio`);
            }
          }
          // The 12th fret is the octave: double the open frequency, same pitch class.
          assertClose(fb.frequencyAt(s, 12), 2 * fb.frequencyAt(s, 0), 1e-9, `${tuning.id} s${s} 12th fret doubles`);
          assert.equal(fb.midiAt(s, 12), open[s] + 12, `${tuning.id} s${s} 12th fret midi`);
          assert.equal(pitchClass(fb.midiAt(s, 12)), pitchClass(fb.midiAt(s, 0)), `${tuning.id} s${s} 12th fret pitch class`);
          if (fretCount >= 24) {
            assertClose(fb.frequencyAt(s, 24), 4 * fb.frequencyAt(s, 0), 1e-9, `${tuning.id} s${s} 24th fret quadruples`);
          }
          // Physical cross-check: frequency ratio = 1 / vibrating length fraction.
          for (let f = 0; f <= fretCount; f++) {
            assertClose(fb.frequencyAt(s, f) / fb.frequencyAt(s, 0), 1 / vibratingLengthFraction(f), 1e-9, `${tuning.id} s${s} f${f} vibrating length`);
          }
        }

        // range()
        const r = fb.range();
        assert.equal(r.min, Math.min(...open), `${tuning.id} range.min`);
        assert.equal(r.max, Math.max(...open) + fretCount, `${tuning.id} range.max`);
        assert.equal(fb.fretCount, fretCount, 'fretCount property');
      });
    }
  }

  test('default Fretboard is standard tuning with 22 frets', () => {
    const fb = new Fretboard();
    for (let s = 0; s < 6; s++) {
      assert.equal(fb.midiAt(s, 0), STANDARD_OPEN_MIDI[s], `default open string ${s}`);
      assert.equal(fb.midiAt(s, 22), STANDARD_OPEN_MIDI[s] + 22, `default 22nd fret string ${s}`);
    }
    assert.deepEqual(fb.range(), { min: 40, max: 86 });
    assert.equal(fb.table().length, 6);
    assert.equal(fb.table()[0].length, 23);
  });

  test('fretCount alone defaults the tuning to standard; tuning alone defaults to 22 frets', () => {
    const fb24 = new Fretboard({ fretCount: 24 });
    assert.deepEqual(fb24.range(), { min: 40, max: 88 });
    assert.equal(fb24.midiAt(5, 24), 88);
    assert.equal(fb24.table()[0].length, 25);
    const fbDropD = new Fretboard({ tuning: getTuning('drop-d') });
    assert.deepEqual(fbDropD.range(), { min: 38, max: 86 });
    assert.equal(fbDropD.table()[0].length, 23);
  });
});

// ---------------------------------------------------------------------------
// 4. Explicit specification examples
// ---------------------------------------------------------------------------

describe('4. explicit spec examples (standard tuning)', () => {
  const fb = new Fretboard();

  test('low E string: open E2, 1st F2, 2nd F#2, 3rd G2, 12th E3', () => {
    assert.equal(fb.noteNameAt(0, 0), 'E2');
    assert.equal(fb.noteNameAt(0, 1), 'F2');
    assert.equal(fb.noteNameAt(0, 2), 'F#2');
    assert.equal(fb.noteNameAt(0, 2, { flats: true }), 'Gb2');
    assert.equal(fb.noteNameAt(0, 3), 'G2');
    assert.equal(fb.noteNameAt(0, 12), 'E3');
    assert.deepEqual([0, 1, 2, 3, 12].map((f) => fb.midiAt(0, f)), [40, 41, 42, 43, 52]);
    assertClose(fb.frequencyAt(0, 0), 82.4069, 5e-6, 'E2');
    assertClose(fb.frequencyAt(0, 12), 164.814, 5e-6, 'E3');
  });

  test('open strings are E2 A2 D3 G3 B3 E4 (string 6 .. string 1)', () => {
    assert.deepEqual([0, 1, 2, 3, 4, 5].map((s) => fb.noteNameAt(s, 0)), ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']);
    assert.deepEqual([0, 1, 2, 3, 4, 5].map((s) => fb.midiAt(s, 0)), STANDARD_OPEN_MIDI);
    const openHz = [82.4069, 110, 146.832, 195.998, 246.942, 329.628];
    openHz.forEach((hz, s) => assertClose(fb.frequencyAt(s, 0), hz, 5e-6, `open string ${s}`));
  });

  test('A4 at string 1 (thinnest, index 5) fret 5 = MIDI 69 = 440 Hz', () => {
    assert.equal(fb.midiAt(5, 5), 69);
    assert.equal(fb.noteNameAt(5, 5), 'A4');
    assert.equal(fb.frequencyAt(5, 5), 440);
  });

  test('5th-fret (and 4th-fret G->B) unisons between adjacent strings', () => {
    assert.equal(fb.midiAt(0, 5), fb.midiAt(1, 0)); // A2
    assert.equal(fb.midiAt(1, 5), fb.midiAt(2, 0)); // D3
    assert.equal(fb.midiAt(2, 5), fb.midiAt(3, 0)); // G3
    assert.equal(fb.midiAt(3, 4), fb.midiAt(4, 0)); // B3
    assert.equal(fb.midiAt(4, 5), fb.midiAt(5, 0)); // E4
    assert.equal(fb.frequencyAt(0, 5), fb.frequencyAt(1, 0));
    assert.equal(fb.frequencyAt(1, 5), fb.frequencyAt(2, 0));
    assert.equal(fb.frequencyAt(2, 5), fb.frequencyAt(3, 0));
    assert.equal(fb.frequencyAt(3, 4), fb.frequencyAt(4, 0));
    assert.equal(fb.frequencyAt(4, 5), fb.frequencyAt(5, 0));
    assert.equal(fb.noteNameAt(3, 4), 'B3');
    // Low and high E are exactly two octaves apart.
    assert.equal(fb.midiAt(5, 0) - fb.midiAt(0, 0), 24);
    assertClose(fb.frequencyAt(5, 0), 4 * fb.frequencyAt(0, 0), 1e-12, 'two octaves');
  });

  test('a handful of well-known fretted notes', () => {
    assert.equal(fb.noteNameAt(1, 3), 'C3');
    assert.equal(fb.noteNameAt(2, 2), 'E3');
    assert.equal(fb.noteNameAt(4, 1), 'C4');
    assert.equal(fb.midiAt(4, 1), 60);
    assertClose(fb.frequencyAt(4, 1), 261.626, 5e-6, 'middle C');
    assert.equal(fb.noteNameAt(5, 12), 'E5');
    assertClose(fb.frequencyAt(5, 12), 659.255, 5e-6, 'E5');
    assert.equal(fb.noteNameAt(5, 22), 'D6');
    assert.equal(fb.noteNameAt(0, 22), 'D4');
  });
});

// ---------------------------------------------------------------------------
// 5. Required alternative tunings
// ---------------------------------------------------------------------------

describe('5. alternative tunings', () => {
  for (const [id, spec] of Object.entries(SPEC_TUNINGS)) {
    test(`${id}: open notes (sharp and flat spelling), MIDI and frequencies`, () => {
      const tuning = getTuning(id);
      assert.ok(tuning, `getTuning(${id}) exists`);
      assert.equal(tuning.id, id);
      assert.deepEqual(tuning.midi, spec.midi, `${id} open-string MIDI`);
      assert.deepEqual(tuning.notes.map(parseNote), spec.midi, `${id} open-string names parse to spec pitches`);

      const fb = new Fretboard({ tuning });
      const sharpNames = spec.midi.map((m) => refName(m, false));
      const flatNames = spec.midi.map((m) => refName(m, true));
      for (let s = 0; s < 6; s++) {
        assert.equal(fb.midiAt(s, 0), spec.midi[s], `${id} string ${s} open midi`);
        assert.equal(fb.noteNameAt(s, 0), sharpNames[s], `${id} string ${s} sharp spelling`);
        assert.equal(fb.noteNameAt(s, 0, { flats: true }), flatNames[s], `${id} string ${s} flat spelling`);
        assert.equal(midiToName(tuning.midi[s]), sharpNames[s]);
        assert.equal(midiToName(tuning.midi[s], { flats: true }), flatNames[s]);
        assertClose(fb.frequencyAt(s, 0), refFreq(spec.midi[s]), 1e-9, `${id} string ${s} open frequency`);
        // The spec spells each open note one way; whichever spelling it used must be reproducible.
        assert.ok(
          spec.notes[s] === sharpNames[s] || spec.notes[s] === flatNames[s],
          `${id} string ${s}: spec spelling ${spec.notes[s]} is one of ${sharpNames[s]}/${flatNames[s]}`,
        );
      }
    });
  }

  test('half-step down is exactly one semitone below standard on every string', () => {
    const std = getTuning('standard');
    const half = getTuning('half-step-down');
    const fbStd = new Fretboard({ tuning: std });
    const fbHalf = new Fretboard({ tuning: half });
    for (let s = 0; s < 6; s++) {
      assert.equal(half.midi[s], std.midi[s] - 1, `string ${s}`);
      for (let f = 0; f <= 22; f++) {
        assert.equal(fbHalf.midiAt(s, f), fbStd.midiAt(s, f) - 1, `s${s} f${f}`);
        assertClose(fbHalf.frequencyAt(s, f) * SEMITONE_RATIO, fbStd.frequencyAt(s, f), 1e-9, `s${s} f${f} frequency`);
      }
    }
    assert.deepEqual(half.midi.map((m) => midiToName(m, { flats: true })), ['Eb2', 'Ab2', 'Db3', 'Gb3', 'Bb3', 'Eb4']);
    assert.deepEqual(half.midi.map((m) => midiToName(m)), ['D#2', 'G#2', 'C#3', 'F#3', 'A#3', 'D#4']);
  });

  test('whole-step down is exactly two semitones below standard on every string', () => {
    const std = getTuning('standard');
    const whole = getTuning('whole-step-down');
    const fbStd = new Fretboard({ tuning: std });
    const fbWhole = new Fretboard({ tuning: whole });
    for (let s = 0; s < 6; s++) {
      assert.equal(whole.midi[s], std.midi[s] - 2, `string ${s}`);
      for (let f = 0; f <= 22; f++) {
        assert.equal(fbWhole.midiAt(s, f), fbStd.midiAt(s, f) - 2, `s${s} f${f}`);
        assertClose(fbWhole.frequencyAt(s, f) * SEMITONE_RATIO ** 2, fbStd.frequencyAt(s, f), 1e-9, `s${s} f${f} frequency`);
      }
      // A whole-step-down string at fret 2 sounds the standard open string.
      assert.equal(fbWhole.midiAt(s, 2), fbStd.midiAt(s, 0));
    }
    assert.deepEqual(whole.midi.map((m) => midiToName(m)), ['D2', 'G2', 'C3', 'F3', 'A3', 'D4']);
  });

  test('drop D, open G, open D and DADGAD differ from standard only where the spec says', () => {
    const std = SPEC_TUNINGS.standard.midi;
    const diff = (id) => SPEC_TUNINGS[id].midi.map((m, i) => m - std[i]);
    assert.deepEqual(diff('drop-d'), [-2, 0, 0, 0, 0, 0]);
    assert.deepEqual(diff('open-g'), [-2, -2, 0, 0, 0, -2]);
    assert.deepEqual(diff('open-d'), [-2, 0, 0, -1, -2, -2]);
    assert.deepEqual(diff('dadgad'), [-2, 0, 0, 0, -2, -2]);
    for (const id of ['drop-d', 'open-g', 'open-d', 'dadgad']) {
      assert.deepEqual(getTuning(id).midi.map((m, i) => m - std[i]), diff(id), `${id} offsets from standard`);
    }
  });

  test('changing tuning updates every label, pitch and frequency on the board', () => {
    const fbStd = new Fretboard();
    for (const id of Object.keys(SPEC_TUNINGS)) {
      const fb = new Fretboard({ tuning: getTuning(id) });
      const offsets = SPEC_TUNINGS[id].midi.map((m, i) => m - STANDARD_OPEN_MIDI[i]);
      for (let s = 0; s < 6; s++) {
        for (let f = 0; f <= 22; f++) {
          const expectedMidi = fbStd.midiAt(s, f) + offsets[s];
          assert.equal(fb.midiAt(s, f), expectedMidi, `${id} s${s} f${f} midi`);
          assert.equal(fb.noteNameAt(s, f), refName(expectedMidi), `${id} s${s} f${f} label`);
          assertClose(fb.frequencyAt(s, f), fbStd.frequencyAt(s, f) * 2 ** (offsets[s] / 12), 1e-9, `${id} s${s} f${f} frequency`);
        }
      }
    }
  });

  test('tuningLabel names the open strings in order (either spelling)', () => {
    for (const tuning of TUNINGS) {
      const label = tuningLabel(tuning);
      assert.equal(typeof label, 'string', `${tuning.id} label is a string`);
      assert.ok(label.trim().length > 0, `${tuning.id} label is non-empty`);
      const normalized = label.replace(/♯/g, '#').replace(/♭/g, 'b');
      const pattern = tuning.midi
        .map((m) => {
          const pc = refPc(m);
          const alternatives = [...new Set([SHARP_NAMES[pc], FLAT_NAMES[pc]])].join('|');
          return `(?:${alternatives})(?![#bA-Za-z])`;
        })
        .join('.*?');
      assert.match(normalized, new RegExp(pattern), `${tuning.id} label "${label}" lists the open strings in order`);
    }
  });
});

// ---------------------------------------------------------------------------
// 6. Enharmonics
// ---------------------------------------------------------------------------

describe('6. enharmonics', () => {
  test('enharmonicNames for all 12 pitch classes', () => {
    const expected = [
      ['C'], ['C#', 'Db'], ['D'], ['D#', 'Eb'], ['E'], ['F'],
      ['F#', 'Gb'], ['G'], ['G#', 'Ab'], ['A'], ['A#', 'Bb'], ['B'],
    ];
    for (let pc = 0; pc < 12; pc++) {
      assert.deepEqual(enharmonicNames(pc), expected[pc], `enharmonicNames(${pc})`);
      assert.deepEqual(enharmonicNames(pc), refEnharmonics(pc), `enharmonicNames(${pc}) vs reference`);
      for (const name of enharmonicNames(pc)) {
        assert.equal(parseNote(`${name}4`), 60 + pc, `${name}4 parses back to pitch class ${pc}`);
      }
    }
  });

  test('the five black-key pairs are equivalent in both directions', () => {
    const pairs = [['C#', 'Db'], ['D#', 'Eb'], ['F#', 'Gb'], ['G#', 'Ab'], ['A#', 'Bb']];
    for (const [sharp, flat] of pairs) {
      assert.equal(enharmonicEquivalent(sharp), flat);
      assert.equal(enharmonicEquivalent(flat), sharp);
      for (let oct = 0; oct <= 8; oct++) {
        assert.equal(enharmonicEquivalent(`${sharp}${oct}`), `${flat}${oct}`, `${sharp}${oct}`);
        assert.equal(enharmonicEquivalent(`${flat}${oct}`), `${sharp}${oct}`, `${flat}${oct}`);
        assert.equal(parseNote(`${sharp}${oct}`), parseNote(`${flat}${oct}`), `${sharp}${oct} == ${flat}${oct}`);
      }
    }
  });

  test('explicit cases: C#, Db, E, F#3, Bb2', () => {
    assert.equal(enharmonicEquivalent('C#'), 'Db');
    assert.equal(enharmonicEquivalent('Db'), 'C#');
    assert.equal(enharmonicEquivalent('E'), 'E'); // natural notes have no simple equivalent
    assert.equal(enharmonicEquivalent('F#3'), 'Gb3');
    assert.equal(enharmonicEquivalent('Bb2'), 'A#2');
  });

  test('natural notes map to themselves (with and without octave)', () => {
    for (const n of ['C', 'D', 'E', 'F', 'G', 'A', 'B']) {
      assert.equal(enharmonicEquivalent(n), n);
      assert.equal(enharmonicEquivalent(`${n}3`), `${n}3`);
    }
  });

  test('sharp and flat spellings of the same MIDI number are enharmonic', () => {
    for (let m = MIDI_LO; m <= MIDI_HI; m++) {
      const sharp = midiToName(m);
      const flat = midiToName(m, { flats: true });
      assert.equal(enharmonicEquivalent(sharp), flat, `enharmonicEquivalent(${sharp})`);
      assert.equal(enharmonicEquivalent(flat), sharp, `enharmonicEquivalent(${flat})`);
      assert.equal(midiToFrequency(parseNote(sharp)), midiToFrequency(parseNote(flat)));
    }
  });
});

// ---------------------------------------------------------------------------
// 7. Positions of pitch classes / MIDI numbers, range
// ---------------------------------------------------------------------------

describe('7. positions and range', () => {
  for (const tuning of TUNINGS) {
    for (const fretCount of FRET_COUNTS) {
      test(`${tuning.id} / ${fretCount} frets: positionsOfPitchClass and positionsOfMidi are complete`, () => {
        const fb = new Fretboard({ tuning, fretCount });
        const open = tuning.notes.map(refParse);

        let total = 0;
        for (let pc = 0; pc < 12; pc++) {
          const actual = fb.positionsOfPitchClass(pc);
          const expected = refPositions(open, fretCount, (m) => refPc(m) === pc);
          assert.ok(Array.isArray(actual), 'positionsOfPitchClass returns an array');
          for (const p of actual) {
            assert.ok(Number.isInteger(p.string) && p.string >= 0 && p.string < 6, `${tuning.id} pc ${pc}: string ${p.string} in range`);
            assert.ok(Number.isInteger(p.fret) && p.fret >= 0 && p.fret <= fretCount, `${tuning.id} pc ${pc}: fret ${p.fret} in range`);
            assert.equal(refPc(open[p.string] + p.fret), pc, `${tuning.id} pc ${pc}: ${posKey(p)} really sounds pitch class ${pc}`);
          }
          assert.deepEqual(sortedKeys(actual), sortedKeys(expected), `${tuning.id} positionsOfPitchClass(${pc})`);
          assert.equal(new Set(sortedKeys(actual)).size, actual.length, `${tuning.id} pc ${pc}: no duplicates`);
          total += actual.length;
        }
        // Every fret of every string belongs to exactly one pitch class.
        assert.equal(total, 6 * (fretCount + 1), `${tuning.id}: pitch classes partition the board`);

        const { min, max } = fb.range();
        for (let midi = min - 3; midi <= max + 3; midi++) {
          const actual = fb.positionsOfMidi(midi);
          const expected = refPositions(open, fretCount, (m) => m === midi);
          assert.deepEqual(sortedKeys(actual), sortedKeys(expected), `${tuning.id} positionsOfMidi(${midi})`);
          for (const p of actual) {
            assert.equal(fb.midiAt(p.string, p.fret), midi, `${tuning.id} positionsOfMidi(${midi}) ${posKey(p)} sounds ${midi}`);
          }
          if (midi < min || midi > max) assert.deepEqual(actual, [], `${tuning.id}: ${midi} is outside the range`);
        }
        // Each in-range MIDI number has at least one position.
        for (let midi = min; midi <= max; midi++) {
          assert.ok(fb.positionsOfMidi(midi).length >= 1, `${tuning.id}: MIDI ${midi} is playable`);
        }
      });
    }
  }

  test('standard tuning, 22 frets: concrete positions', () => {
    const fb = new Fretboard();
    // E (pc 4): every string has one or two Es.
    assert.deepEqual(sortedKeys(fb.positionsOfPitchClass(4)), sortedKeys([
      { string: 0, fret: 0 }, { string: 0, fret: 12 },
      { string: 1, fret: 7 }, { string: 1, fret: 19 },
      { string: 2, fret: 2 }, { string: 2, fret: 14 },
      { string: 3, fret: 9 }, { string: 3, fret: 21 },
      { string: 4, fret: 5 }, { string: 4, fret: 17 },
      { string: 5, fret: 0 }, { string: 5, fret: 12 },
    ]));
    // E4 (64): high E open, B 5, G 9, D 14, A 19 (low E would need fret 24).
    assert.deepEqual(sortedKeys(fb.positionsOfMidi(64)), sortedKeys([
      { string: 1, fret: 19 }, { string: 2, fret: 14 }, { string: 3, fret: 9 }, { string: 4, fret: 5 }, { string: 5, fret: 0 },
    ]));
    // A4 (69): A 24 is out of reach; D 19, G 14, B 10, E 5.
    assert.deepEqual(sortedKeys(fb.positionsOfMidi(69)), sortedKeys([
      { string: 2, fret: 19 }, { string: 3, fret: 14 }, { string: 4, fret: 10 }, { string: 5, fret: 5 },
    ]));
    assert.deepEqual(fb.positionsOfMidi(40), [{ string: 0, fret: 0 }]);
    assert.deepEqual(fb.positionsOfMidi(86), [{ string: 5, fret: 22 }]);
    assert.deepEqual(fb.positionsOfMidi(39), []);
    assert.deepEqual(fb.positionsOfMidi(87), []);
    assert.deepEqual(fb.range(), { min: 40, max: 86 });
  });

  test('range() for each required tuning (22 and 24 frets)', () => {
    const expected22 = {
      standard: { min: 40, max: 86 },
      'drop-d': { min: 38, max: 86 },
      'half-step-down': { min: 39, max: 85 },
      'whole-step-down': { min: 38, max: 84 },
      'open-g': { min: 38, max: 84 },
      'open-d': { min: 38, max: 84 },
      dadgad: { min: 38, max: 84 },
    };
    for (const [id, r] of Object.entries(expected22)) {
      assert.deepEqual(new Fretboard({ tuning: getTuning(id) }).range(), r, `${id} 22 frets`);
      assert.deepEqual(new Fretboard({ tuning: getTuning(id), fretCount: 24 }).range(), { min: r.min, max: r.max + 2 }, `${id} 24 frets`);
    }
  });
});

// ---------------------------------------------------------------------------
// 8. Fret geometry
// ---------------------------------------------------------------------------

describe('8. fret geometry', () => {
  test('fretDistanceFraction anchors: 0 at the nut, 1/2 at fret 12, 3/4 at fret 24', () => {
    assert.equal(fretDistanceFraction(0), 0);
    assertClose(fretDistanceFraction(12), 0.5, 1e-12, 'fret 12');
    assertClose(fretDistanceFraction(24), 0.75, 1e-12, 'fret 24');
    assertClose(fretDistanceFraction(36), 0.875, 1e-12, 'fret 36');
  });

  test('fretDistanceFraction(n) = 1 - 2^(-n/12) and vibratingLengthFraction(n) = 2^(-n/12)', () => {
    for (let n = 0; n <= 36; n++) {
      assertClose(fretDistanceFraction(n), 1 - 2 ** (-n / 12), 1e-12, `fretDistanceFraction(${n})`);
      assertClose(vibratingLengthFraction(n), 2 ** (-n / 12), 1e-12, `vibratingLengthFraction(${n})`);
      assertClose(fretDistanceFraction(n) + vibratingLengthFraction(n), 1, 1e-12, `complement at ${n}`);
    }
    assert.equal(vibratingLengthFraction(0), 1);
    assertClose(vibratingLengthFraction(12), 0.5, 1e-12, 'half length at the octave');
  });

  test('fret distances increase monotonically while the spacing shrinks by 2^(-1/12) each fret', () => {
    let previousGap = Infinity;
    for (let n = 1; n <= 36; n++) {
      const gap = fretDistanceFraction(n) - fretDistanceFraction(n - 1);
      assert.ok(gap > 0, `fret ${n} is further from the nut than fret ${n - 1}`);
      assert.ok(gap < previousGap, `spacing between frets ${n - 1} and ${n} is narrower than the previous one`);
      if (n > 1) assertClose(gap / previousGap, 2 ** (-1 / 12), 1e-9, `spacing ratio at fret ${n}`);
      previousGap = gap;
    }
    // Rule of 18 (really 17.817): each fret sits 1/17.817 of the remaining length further on.
    for (let n = 1; n <= 24; n++) {
      const remaining = 1 - fretDistanceFraction(n - 1);
      const gap = fretDistanceFraction(n) - fretDistanceFraction(n - 1);
      assertClose(remaining / gap, 17.817, 1e-3, `rule of 17.817 at fret ${n}`);
    }
  });

  test('fretPositions(count) lists count + 1 positions from the nut, agreeing with fretDistanceFraction', () => {
    for (const count of [12, 22, 24]) {
      const positions = fretPositions(count);
      assert.ok(Array.isArray(positions), 'array');
      assert.equal(positions.length, count + 1, `fretPositions(${count}).length`);
      assert.equal(positions[0], 0, 'nut at 0');
      for (let n = 0; n <= count; n++) {
        assertClose(positions[n], 1 - 2 ** (-n / 12), 1e-12, `fretPositions(${count})[${n}]`);
        assert.equal(positions[n], fretDistanceFraction(n), `fretPositions(${count})[${n}] == fretDistanceFraction(${n})`);
        if (n > 0) assert.ok(positions[n] > positions[n - 1], 'strictly increasing');
      }
      assertClose(positions[12], 0.5, 1e-12, 'octave fret at half the scale');
      assert.ok(positions[count] < 1, 'all frets lie before the bridge');
    }
  });

  test('25.5" scale: fret 1 at ~1.431", fret 12 at 12.75", fret 24 at 19.125"', () => {
    const scale = 25.5;
    assert.ok(Math.abs(scale * fretDistanceFraction(1) - 1.431) < 0.001, `fret 1 = ${scale * fretDistanceFraction(1)}`);
    assertClose(scale * fretDistanceFraction(12), 12.75, 1e-12, 'fret 12');
    assertClose(scale * fretDistanceFraction(24), 19.125, 1e-12, 'fret 24');
    assert.ok(Math.abs(scale * fretDistanceFraction(2) - 2.782) < 0.001, `fret 2 = ${scale * fretDistanceFraction(2)}`);
    assert.ok(Math.abs(scale * fretDistanceFraction(5) - 6.397) < 0.002, `fret 5 = ${scale * fretDistanceFraction(5)}`);
    // A 24.75" (Gibson-style) scale puts fret 12 at 12.375".
    assertClose(24.75 * fretDistanceFraction(12), 12.375, 1e-12, 'Gibson 12th fret');
  });
});

// ---------------------------------------------------------------------------
// 9. Scales
// ---------------------------------------------------------------------------

describe('9. scales', () => {
  test('SCALES is well formed and every required scale exists with the right formula', () => {
    assert.ok(Array.isArray(SCALES) && SCALES.length >= Object.keys(SPEC_SCALES).length);
    const ids = new Set();
    for (const sc of SCALES) {
      assert.equal(typeof sc.id, 'string');
      assert.ok(!ids.has(sc.id), `duplicate scale id ${sc.id}`);
      ids.add(sc.id);
      assert.equal(typeof sc.name, 'string', `${sc.id} has a name`);
      assert.ok(Array.isArray(sc.intervals), `${sc.id} has intervals`);
      assert.equal(getScale(sc.id), sc, `getScale(${sc.id})`);
    }
    for (const [id, intervals] of Object.entries(SPEC_SCALES)) {
      assert.ok(ids.has(id), `scale ${id} exists`);
      assert.deepEqual(getScale(id).intervals, intervals, `${id} intervals`);
    }
  });

  test('every scale starts at 0 with unique, strictly ascending intervals below 12', () => {
    for (const sc of SCALES) {
      const iv = sc.intervals;
      assert.ok(iv.length >= 2, `${sc.id} has at least two notes`);
      assert.equal(iv[0], 0, `${sc.id} starts on the root`);
      for (let i = 0; i < iv.length; i++) {
        assert.ok(Number.isInteger(iv[i]) && iv[i] >= 0 && iv[i] < 12, `${sc.id} interval ${iv[i]} in 0..11`);
        if (i > 0) assert.ok(iv[i] > iv[i - 1], `${sc.id} intervals strictly ascending at ${i}`);
      }
      assert.equal(new Set(iv).size, iv.length, `${sc.id} intervals unique`);
    }
  });

  test('chromatic scale has 12 notes; pentatonics 5; diatonic scales 7; blues 6', () => {
    assert.equal(getScale('chromatic').intervals.length, 12);
    assert.deepEqual(getScale('chromatic').intervals, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    assert.equal(scaleNoteNames(getScale('chromatic'), 0).length, 12);
    assert.deepEqual(scaleNoteNames(getScale('chromatic'), 0), SHARP_NAMES);
    assert.deepEqual(scaleNoteNames(getScale('chromatic'), 0, { flats: true }), FLAT_NAMES);
    assert.equal(getScale('major-pentatonic').intervals.length, 5);
    assert.equal(getScale('minor-pentatonic').intervals.length, 5);
    assert.equal(getScale('blues').intervals.length, 6);
    for (const id of ['major', 'natural-minor', 'harmonic-minor', 'melodic-minor', 'dorian', 'phrygian', 'lydian', 'mixolydian', 'locrian']) {
      assert.equal(getScale(id).intervals.length, 7, `${id} is heptatonic`);
    }
  });

  test('scaleNoteNames: C major, A natural minor, A harmonic minor, E minor pentatonic, G major pentatonic, A blues', () => {
    assert.deepEqual(scaleNoteNames(getScale('major'), 0), ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
    assert.deepEqual(scaleNoteNames(getScale('major'), 0, { flats: true }), ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
    assert.deepEqual(scaleNoteNames(getScale('natural-minor'), 9), ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
    assert.deepEqual(scaleNoteNames(getScale('harmonic-minor'), 9), ['A', 'B', 'C', 'D', 'E', 'F', 'G#']);
    assert.deepEqual(scaleNoteNames(getScale('harmonic-minor'), 9, { flats: false }), ['A', 'B', 'C', 'D', 'E', 'F', 'G#']);
    assert.deepEqual(scaleNoteNames(getScale('minor-pentatonic'), 4), ['E', 'G', 'A', 'B', 'D']);
    assert.deepEqual(scaleNoteNames(getScale('major-pentatonic'), 7), ['G', 'A', 'B', 'D', 'E']);

    const bluesDefault = scaleNoteNames(getScale('blues'), 9);
    assert.ok(
      JSON.stringify(bluesDefault) === JSON.stringify(['A', 'C', 'D', 'D#', 'E', 'G']) ||
        JSON.stringify(bluesDefault) === JSON.stringify(['A', 'C', 'D', 'Eb', 'E', 'G']),
      `A blues default spelling ${JSON.stringify(bluesDefault)}`,
    );
    assert.deepEqual(scaleNoteNames(getScale('blues'), 9, { flats: false }), ['A', 'C', 'D', 'D#', 'E', 'G']);
    assert.deepEqual(scaleNoteNames(getScale('blues'), 9, { flats: true }), ['A', 'C', 'D', 'Eb', 'E', 'G']);
  });

  test('scaleNoteNames for every scale and every root matches own formula in both spellings', () => {
    for (const [id, intervals] of Object.entries(SPEC_SCALES)) {
      const sc = getScale(id);
      for (let root = 0; root < 12; root++) {
        for (const flats of [false, true]) {
          const expected = intervals.map((i) => (flats ? FLAT_NAMES : SHARP_NAMES)[(root + i) % 12]);
          assert.deepEqual(scaleNoteNames(sc, root, { flats }), expected, `${id} root ${root} flats=${flats}`);
        }
        const names = scaleNoteNames(sc, root);
        assert.equal(names.length, intervals.length, `${id} root ${root} length`);
        assert.equal(names[0], SHARP_NAMES[root], `${id} root ${root} starts on the root`);
      }
    }
  });

  test('scalePitchClasses matches own formula for every scale and root', () => {
    for (const [id, intervals] of Object.entries(SPEC_SCALES)) {
      const sc = getScale(id);
      for (let root = 0; root < 12; root++) {
        const result = scalePitchClasses(sc, root);
        const pcs = Array.from(result);
        const expected = intervals.map((i) => (root + i) % 12);
        assert.equal(pcs.length, expected.length, `${id} root ${root} size`);
        assert.deepEqual([...pcs].sort((a, b) => a - b), [...expected].sort((a, b) => a - b), `${id} root ${root} pitch classes`);
        assert.ok(pcs.includes(root), `${id} root ${root} contains the root`);
        // Membership check against the public API, used the way a fretboard overlay would.
        for (let pc = 0; pc < 12; pc++) {
          const inScale = expected.includes(pc);
          const has = result instanceof Set ? result.has(pc) : pcs.includes(pc);
          assert.equal(has, inScale, `${id} root ${root}: pc ${pc} membership`);
        }
      }
    }
    // Concrete anchors.
    assert.deepEqual(Array.from(scalePitchClasses(getScale('major'), 0)).sort((a, b) => a - b), [0, 2, 4, 5, 7, 9, 11]);
    assert.deepEqual(Array.from(scalePitchClasses(getScale('minor-pentatonic'), 4)).sort((a, b) => a - b), [2, 4, 7, 9, 11]);
    assert.deepEqual(Array.from(scalePitchClasses(getScale('blues'), 9)).sort((a, b) => a - b), [0, 2, 3, 4, 7, 9]);
  });

  test('relative major/minor and modes share pitch-class sets', () => {
    const pcs = (id, root) => Array.from(scalePitchClasses(getScale(id), root)).sort((a, b) => a - b);
    assert.deepEqual(pcs('natural-minor', 9), pcs('major', 0)); // A minor = C major
    assert.deepEqual(pcs('dorian', 2), pcs('major', 0)); // D dorian
    assert.deepEqual(pcs('phrygian', 4), pcs('major', 0)); // E phrygian
    assert.deepEqual(pcs('lydian', 5), pcs('major', 0)); // F lydian
    assert.deepEqual(pcs('mixolydian', 7), pcs('major', 0)); // G mixolydian
    assert.deepEqual(pcs('locrian', 11), pcs('major', 0)); // B locrian
    assert.deepEqual(pcs('minor-pentatonic', 9), pcs('major-pentatonic', 0)); // A minor pent = C major pent
    assert.deepEqual(pcs('minor-pentatonic', 4), pcs('major-pentatonic', 7)); // E minor pent = G major pent
  });
});
