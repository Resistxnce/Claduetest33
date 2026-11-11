import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  midiToFrequency, frequencyToMidi, midiToName, parseNote, pitchClass, octaveOf,
  enharmonicNames, enharmonicEquivalent, describeNote, pitchClassName,
} from '../src/theory/notes.js';
import { TUNINGS, getTuning, tuningLabel, stringNumber } from '../src/theory/tunings.js';
import { Fretboard, fretDistanceFraction, fretPositions, vibratingLengthFraction } from '../src/theory/fretboard.js';
import { SCALES, getScale, scalePitchClasses, scaleNoteNames, scalePositions } from '../src/theory/scales.js';
import { CHORD_QUALITIES, chordName, chordPitchClasses, detectChord, generateVoicings, validateVoicing, assignFingers } from '../src/theory/chords.js';

const close = (a, b, tol = 1e-9) => assert.ok(Math.abs(a - b) <= tol, `${a} != ${b}`);

test('A4 is MIDI 69 at 440 Hz and octaves double', () => {
  close(midiToFrequency(69), 440);
  close(midiToFrequency(81), 880);
  close(midiToFrequency(57), 220);
  close(midiToFrequency(60), 261.6255653005986, 1e-9);
  close(frequencyToMidi(440), 69);
});

test('note names and octaves follow scientific pitch notation', () => {
  assert.equal(midiToName(40), 'E2');
  assert.equal(midiToName(60), 'C4');
  assert.equal(midiToName(69), 'A4');
  assert.equal(midiToName(42), 'F#2');
  assert.equal(midiToName(42, { flats: true }), 'Gb2');
  assert.equal(midiToName(59), 'B3');
  assert.equal(midiToName(0), 'C-1');
  assert.equal(octaveOf(59), 3);
  assert.equal(octaveOf(60), 4);
});

test('parseNote handles accidentals and round-trips', () => {
  assert.equal(parseNote('E2'), 40);
  assert.equal(parseNote('F#2'), 42);
  assert.equal(parseNote('Gb2'), 42);
  assert.equal(parseNote('Eb2'), 39);
  assert.equal(parseNote('C4'), 60);
  assert.equal(parseNote('B3'), 59);
  assert.equal(parseNote('a4'), 69);
  assert.equal(parseNote('C♯4'), 61);
  assert.equal(parseNote('C-1'), 0);
  for (let m = 0; m < 128; m++) {
    assert.equal(parseNote(midiToName(m)), m);
    assert.equal(parseNote(midiToName(m, { flats: true })), m);
  }
  assert.throws(() => parseNote('H2'));
});

test('enharmonic equivalents', () => {
  assert.deepEqual(enharmonicNames(1), ['C#', 'Db']);
  assert.deepEqual(enharmonicNames(4), ['E']);
  assert.equal(enharmonicEquivalent('C#'), 'Db');
  assert.equal(enharmonicEquivalent('Db4'), 'C#4');
  assert.equal(enharmonicEquivalent('E'), 'E');
  assert.equal(pitchClass(-1), 11);
  assert.equal(pitchClassName(13), 'C#');
  const d = describeNote(42);
  assert.equal(d.name, 'F#2');
  assert.equal(d.flatName, 'Gb2');
  close(d.frequency, 92.4986056779086, 1e-9);
});

test('standard tuning open strings', () => {
  const t = getTuning('standard');
  assert.deepEqual([...t.midi], [40, 45, 50, 55, 59, 64]);
  assert.deepEqual([...t.notes], ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']);
  assert.equal(tuningLabel(t), 'E A D G B E');
  assert.equal(stringNumber(0), 6);
  assert.equal(stringNumber(5), 1);
});

test('alternative tunings are as specified', () => {
  const expect = {
    'drop-d': ['D2', 'A2', 'D3', 'G3', 'B3', 'E4'],
    'half-step-down': ['D#2', 'G#2', 'C#3', 'F#3', 'A#3', 'D#4'],
    'whole-step-down': ['D2', 'G2', 'C3', 'F3', 'A3', 'D4'],
    'open-g': ['D2', 'G2', 'D3', 'G3', 'B3', 'D4'],
    'open-d': ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4'],
    dadgad: ['D2', 'A2', 'D3', 'G3', 'A3', 'D4'],
  };
  for (const [id, notes] of Object.entries(expect)) {
    const t = getTuning(id);
    assert.deepEqual(t.midi.map((m) => midiToName(m)), notes, id);
  }
  // half-step down is exactly one semitone below standard on every string
  const std = getTuning('standard').midi;
  getTuning('half-step-down').midi.forEach((m, i) => assert.equal(m, std[i] - 1));
  getTuning('whole-step-down').midi.forEach((m, i) => assert.equal(m, std[i] - 2));
  for (const t of TUNINGS) assert.equal(t.midi.length, 6);
});

test('every fret on every string is one semitone higher than the previous', () => {
  for (const t of TUNINGS) {
    const fb = new Fretboard({ tuning: t, fretCount: 24 });
    for (let s = 0; s < 6; s++) {
      assert.equal(fb.midiAt(s, 0), t.midi[s]);
      for (let f = 1; f <= 24; f++) {
        assert.equal(fb.midiAt(s, f), fb.midiAt(s, f - 1) + 1);
        close(fb.frequencyAt(s, f) / fb.frequencyAt(s, f - 1), Math.pow(2, 1 / 12), 1e-12);
      }
      assert.equal(fb.midiAt(s, 12), t.midi[s] + 12);
      close(fb.frequencyAt(s, 12), 2 * fb.frequencyAt(s, 0), 1e-9);
    }
  }
});

test('low E string examples from the specification', () => {
  const fb = new Fretboard();
  assert.equal(fb.noteNameAt(0, 0), 'E2');
  assert.equal(fb.noteNameAt(0, 1), 'F2');
  assert.equal(fb.noteNameAt(0, 2), 'F#2');
  assert.equal(fb.noteNameAt(0, 3), 'G2');
  assert.equal(fb.noteNameAt(0, 12), 'E3');
  assert.equal(fb.noteNameAt(5, 5), 'A4');
  close(fb.frequencyAt(5, 5), 440);
  assert.equal(fb.noteNameAt(1, 3), 'C3');
  assert.equal(fb.noteNameAt(2, 2), 'E3');
  assert.equal(fb.noteNameAt(3, 1), 'G#3');
  assert.equal(fb.noteNameAt(4, 1), 'C4');
  assert.equal(fb.noteNameAt(5, 12), 'E5');
  // Unison positions: 5th fret of each string = next open string (except G->B)
  assert.equal(fb.midiAt(0, 5), fb.midiAt(1, 0));
  assert.equal(fb.midiAt(1, 5), fb.midiAt(2, 0));
  assert.equal(fb.midiAt(2, 5), fb.midiAt(3, 0));
  assert.equal(fb.midiAt(3, 4), fb.midiAt(4, 0));
  assert.equal(fb.midiAt(4, 5), fb.midiAt(5, 0));
  assert.throws(() => fb.midiAt(6, 0));
  assert.throws(() => fb.midiAt(0, 23));
});

test('fretboard lookups', () => {
  const fb = new Fretboard();
  const e = fb.positionsOfPitchClass(4); // E
  assert.ok(e.some((p) => p.string === 0 && p.fret === 0));
  assert.ok(e.some((p) => p.string === 5 && p.fret === 12));
  assert.ok(e.every((p) => pitchClass(fb.midiAt(p.string, p.fret)) === 4));
  assert.deepEqual(fb.positionsOfMidi(64), [
    { string: 1, fret: 19 }, { string: 2, fret: 14 }, { string: 3, fret: 9 }, { string: 4, fret: 5 }, { string: 5, fret: 0 },
  ]);
  assert.deepEqual(fb.range(), { min: 40, max: 86 });
  const table = fb.table();
  assert.equal(table.length, 6);
  assert.equal(table[0].length, 23);
  assert.equal(table[5][22].name, 'D6');
});

test('fret geometry follows the 12th-root-of-two rule', () => {
  close(fretDistanceFraction(0), 0);
  close(fretDistanceFraction(12), 0.5);
  close(fretDistanceFraction(24), 0.75);
  close(fretDistanceFraction(1), 1 - Math.pow(2, -1 / 12));
  const pos = fretPositions(22);
  assert.equal(pos.length, 23);
  for (let i = 1; i < pos.length; i++) {
    assert.ok(pos[i] > pos[i - 1]);
    if (i > 1) assert.ok(pos[i] - pos[i - 1] < pos[i - 1] - pos[i - 2], 'frets get closer together');
  }
  close(vibratingLengthFraction(12), 0.5);
  // The 25.5" scale puts the first fret 1.431" from the nut.
  close(25.5 * fretDistanceFraction(1), 1.4312, 1e-3);
});

test('scales', () => {
  const major = getScale('major');
  assert.deepEqual(scaleNoteNames(major, 0), ['C', 'D', 'E', 'F', 'G', 'A', 'B']);
  assert.deepEqual(scaleNoteNames(getScale('natural-minor'), 9), ['A', 'B', 'C', 'D', 'E', 'F', 'G']);
  assert.deepEqual(scaleNoteNames(getScale('minor-pentatonic'), 4), ['E', 'G', 'A', 'B', 'D']);
  assert.deepEqual(scaleNoteNames(getScale('major-pentatonic'), 7), ['G', 'A', 'B', 'D', 'E']);
  assert.deepEqual(scaleNoteNames(getScale('blues'), 9), ['A', 'C', 'D', 'D#', 'E', 'G']);
  assert.equal(scalePitchClasses(getScale('chromatic'), 0).size, 12);
  for (const s of SCALES) assert.ok(s.intervals[0] === 0 && new Set(s.intervals).size === s.intervals.length);
  const fb = new Fretboard();
  const positions = scalePositions(fb, getScale('major'), 0);
  assert.ok(positions.every((p) => [0, 2, 4, 5, 7, 9, 11].includes(p.pitchClass)));
  assert.ok(positions.some((p) => p.isRoot && p.degree === '1'));
  assert.ok(positions.length > 70 && positions.length < 90);
});

test('chord formulas, names and detection', () => {
  assert.equal(chordName(0, 'maj'), 'C');
  assert.equal(chordName(9, 'min'), 'Am');
  assert.equal(chordName(7, '7'), 'G7');
  assert.equal(chordName(1, 'maj7', { flats: true }), 'Dbmaj7');
  assert.deepEqual([...chordPitchClasses(0, 'maj')].sort((a, b) => a - b), [0, 4, 7]);
  assert.deepEqual([...chordPitchClasses(9, 'min')].sort((a, b) => a - b), [0, 4, 9]);
  for (const q of CHORD_QUALITIES) assert.ok(q.intervals.includes(0));
  assert.equal(detectChord([0, 4, 7], { bassPc: 0 }).name, 'C');
  assert.equal(detectChord([9, 0, 4], { bassPc: 9 }).name, 'Am');
  assert.equal(detectChord([7, 11, 2, 5], { bassPc: 7 }).name, 'G7');
  assert.equal(detectChord([2, 9], { bassPc: 2 }).name, 'D5');
  assert.equal(detectChord([0, 4, 7], { bassPc: 4 }).name, 'C/E');
  assert.equal(detectChord([0], {}), null);
});

test('generated voicings are always musically valid in every tuning', () => {
  for (const t of TUNINGS) {
    for (const root of [0, 2, 4, 5, 7, 9, 11]) {
      for (const q of ['maj', 'min', '7', 'sus4', '5']) {
        const voicings = generateVoicings(root, q, t.midi, { maxResults: 3 });
        assert.ok(voicings.length > 0, `${t.id} ${root} ${q} has voicings`);
        for (const v of voicings) {
          assert.deepEqual(validateVoicing(v, root, q, t.midi), [], `${t.id} ${chordName(root, q)} ${v.frets}`);
          assert.equal(v.fingers.length, 6);
        }
      }
    }
  }
  const std = getTuning('standard').midi;
  assert.equal(generateVoicings(9, 'min', std, { maxResults: 1 })[0].frets.join(','), '-1,0,2,2,1,0');
  assert.equal(generateVoicings(4, 'min', std, { maxResults: 1 })[0].frets.join(','), '0,2,2,0,0,0');
  assert.equal(generateVoicings(7, 'maj', std, { maxResults: 1 })[0].frets.join(','), '3,2,0,0,0,3');
  assert.equal(generateVoicings(0, 'maj', std, { maxResults: 1 })[0].frets.join(','), '-1,3,2,0,1,0');
});

test('finger assignment detects barres', () => {
  const f = assignFingers([1, 3, 3, 2, 1, 1]);
  assert.deepEqual(f.barre, { fret: 1, from: 0, to: 5 });
  assert.deepEqual(f.fingers, [1, 3, 4, 2, 1, 1]);
  assert.equal(f.count, 4);
  assert.equal(assignFingers([1, 2, 3, 4, 5, 6]), null);
  assert.deepEqual(assignFingers([0, 0, 0, 0, 0, 0]).fingers, [0, 0, 0, 0, 0, 0]);
});
