import { test } from 'node:test';
import assert from 'node:assert/strict';
import { AppState } from '../src/state.js';
import { pitchClass } from '../src/theory/notes.js';
import { chordPitchClasses, detectChord, validateVoicing, assignFingers, generateVoicings, chordVoicings } from '../src/theory/chords.js';
import { getScale, degreeLabel } from '../src/theory/scales.js';
import { TUNINGS } from '../src/theory/tunings.js';

const names = (state) => [0, 1, 2, 3, 4, 5].map((s) => { const n = state.noteOn(s); return n ? n.name : 'x'; });

test('sounding fret: highest finger wins, capo is the floor, 24 frets available', () => {
  const st = new AppState();
  assert.deepEqual(names(st), ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']);
  st.pressFinger(1, 0, 3);
  st.pressFinger(2, 0, 5);
  assert.equal(st.noteOn(0).name, 'A2');
  st.liftFinger(2);
  assert.equal(st.noteOn(0).name, 'G2');
  st.liftAll();
  st.setCapo(2);
  assert.deepEqual(names(st), ['F#2', 'B2', 'E3', 'A3', 'C#4', 'F#4']);
  st.pressFinger(3, 1, 1); // a finger behind the capo cannot lower the pitch
  assert.equal(st.noteOn(1).name, 'B2');
  st.liftAll();
  st.setCapo(0);
  st.pressFinger(4, 5, 24);
  assert.equal(st.noteOn(5).name, 'E6');
  assert.ok(Math.abs(st.noteOn(5).frequency - 1318.51) < 0.01);
});

test('held chords sound the named chord with and without a capo, in every tuning that has a voicing', () => {
  for (const tuning of TUNINGS) {
    for (const capo of [0, 1, 2, 5, 7]) {
      const st = new AppState();
      st.setTuning(tuning.id);
      st.setCapo(capo);
      for (const [root, quality] of [[0, 'maj'], [2, 'maj'], [9, 'min'], [7, '7'], [4, 'min'], [5, 'maj7']]) {
        st.setChord(root, quality);
        if (!st.chordVoicing) continue;
        st.setHoldChord(true);
        const expected = chordPitchClasses(root, quality);
        const sounding = [];
        for (let s = 0; s < 6; s++) {
          const n = st.noteOn(s);
          if (!n) continue;
          assert.ok(n.fret >= capo, `${tuning.id} capo ${capo}: fret ${n.fret} is behind the capo`);
          assert.ok(expected.has(pitchClass(n.midi)), `${tuning.id} capo ${capo} chord ${root}:${quality} sounds ${n.name}`);
          sounding.push(pitchClass(n.midi));
        }
        assert.ok(sounding.includes(pitchClass(root)), `${tuning.id} capo ${capo} chord ${root}:${quality} has its root`);
        assert.ok(sounding.length >= 3);
        st.setHoldChord(false);
      }
    }
  }
});

test('with a capo on fret 2, C major uses the shape two semitones lower and still sounds C E G', () => {
  const st = new AppState();
  st.setCapo(2);
  st.setChord(0, 'maj');
  st.setHoldChord(true);
  const pcs = new Set([0, 1, 2, 3, 4, 5].map((s) => st.noteOn(s)).filter(Boolean).map((n) => pitchClass(n.midi)));
  assert.deepEqual([...pcs].sort((a, b) => a - b), [0, 4, 7]);
  // user fingers still take priority over the held shape
  st.pressFinger(9, 5, 12);
  assert.equal(st.noteOn(5).name, 'E5');
});

test('a user finger overrides a muted chord string', () => {
  const st = new AppState();
  st.setChord(2, 'maj'); // open D: x x 0 2 3 2
  st.setHoldChord(true);
  assert.equal(st.noteOn(0), null);
  st.pressFinger(1, 0, 2);
  assert.equal(st.noteOn(0).name, 'F#2');
});

test('ringing notes are tracked per string and cleared', () => {
  const st = new AppState();
  st.notePlayed(st.noteOn(3), 0.8);
  assert.equal(st.ringing[3].name, 'G3');
  st.pressFinger(1, 3, 2);
  st.setRinging(3, st.noteOn(3));
  assert.equal(st.ringing[3].name, 'A3');
  assert.equal(st.ringing[3].velocity, 0.8);
  st.setRinging(3, null);
  assert.equal(st.ringing[3], null);
  assert.equal(st.recent.length, 1);
});

test('bends raise the played frequency but not the note identity', () => {
  const st = new AppState();
  st.pressFinger(1, 2, 7);
  st.setFingerBend(1, 2, 30);
  const n = st.noteOn(2);
  assert.equal(n.name, 'A3');
  assert.ok(Math.abs(n.playFrequency - 220 * 2 ** (2 / 12)) < 1e-9);
  assert.ok(Math.abs(n.frequency - 220) < 1e-9);
});

test('chord detection prefers exact matches over richer partial ones', () => {
  assert.equal(detectChord([9, 0, 4], { bassPc: 0 }).name, 'Am/C');
  assert.equal(detectChord([4, 7, 11], { bassPc: 7 }).name, 'Em/G');
  assert.equal(detectChord([0, 4, 7], { bassPc: 0 }).name, 'C');
  assert.equal(detectChord([0, 4, 7, 9], { bassPc: 0 }).name, 'C6');
  assert.equal(detectChord([0, 4, 10], { bassPc: 0 }).name, 'C7'); // 5th omitted
});

test('scale degrees use the scale\'s own spelling', () => {
  assert.equal(degreeLabel(getScale('lydian'), 0, 6), '#4');
  assert.equal(degreeLabel(getScale('whole-tone'), 0, 8), '#5');
  assert.equal(degreeLabel(getScale('blues'), 0, 6), 'b5');
  assert.equal(degreeLabel(getScale('major'), 0, 1), null);
});

test('voicing generator: bass is the lowest pitch and barres never cross open strings', () => {
  // x02220-type shapes: three strings on one fret with an open string above → separate fingers, no barre
  const a = assignFingers([-1, 0, 2, 2, 2, 0]);
  assert.equal(a.barre, null);
  assert.deepEqual(a.fingers, [0, 0, 1, 2, 3, 0]);
  for (const tuning of TUNINGS) {
    for (let root = 0; root < 12; root++) {
      for (const q of ['maj', 'min', '7']) {
        for (const v of generateVoicings(root, q, tuning.midi, { maxResults: 4 })) {
          const sounding = v.frets.map((f, s) => (f >= 0 ? tuning.midi[s] + f : null)).filter((x) => x !== null);
          assert.equal(pitchClass(Math.min(...sounding)), root, `${tuning.id} ${root}:${q} ${v.frets} lowest pitch must be the root`);
          for (const b of (v.barre ? [v.barre] : [])) {
            for (let s = b.to + 1; s < 6; s++) assert.notEqual(v.frets[s], 0, `${tuning.id} ${root}:${q} ${v.frets} open string under a barre`);
          }
          assert.deepEqual(validateVoicing(v, root, q, tuning.midi), []);
        }
      }
    }
  }
});

test('every chord quality gets at least one voicing in every tuning for the natural roots (inversions as a last resort)', () => {
  let missing = 0;
  for (const tuning of TUNINGS) {
    for (const root of [0, 2, 4, 5, 7, 9, 11]) {
      for (const q of ['maj', 'min', '7', 'm7', 'maj7', 'sus4', '5']) {
        const vs = chordVoicings(root, q, tuning.midi, { maxResults: 3 });
        if (!vs.length) missing++;
        for (const v of vs) assert.deepEqual(validateVoicing(v, root, q, tuning.midi), []);
      }
    }
  }
  assert.equal(missing, 0);
});

test('with a chord held, the highest fretted position on a string still wins', () => {
  const st = new AppState();
  st.setChord(5, 'maj', 0); // F major
  const barre = st.chord.voicings.findIndex((v) => v.frets.join() === '1,3,3,2,1,1');
  assert.ok(barre >= 0, 'F major has the E-shape barre at fret 1');
  st.setChordVoicing(barre);
  st.setHoldChord(true);
  assert.deepEqual(names(st), ['F2', 'C3', 'F3', 'A3', 'C4', 'F4']);
  // an own finger behind the chord's finger changes nothing (the chord's finger is nearer the bridge)
  st.pressFinger(1, 1, 2); // A string, fret 2, behind the chord's fret 3
  assert.equal(st.noteOn(1).name, 'C3');
  // an own finger in front of it takes over
  st.pressFinger(2, 1, 5);
  assert.equal(st.noteOn(1).name, 'D3');
  st.liftAll();
  // behind the capo too
  st.setCapo(3);
  st.setChord(0, 'maj', 0);
  st.setHoldChord(true);
  const before = names(st);
  for (let s = 0; s < 6; s++) st.pressFinger(10 + s, s, 1);
  assert.deepEqual(names(st), before, 'fingers behind the capo do not change a held chord');
});

test('a finger dragged across strings in one fret is a barre; held fingers stay until released', () => {
  const st = new AppState();
  st.pressFinger(1, 0, 1);                       // low E, fret 1
  for (let s = 1; s <= 5; s++) st.moveFinger(1, s, 1, { barre: true });
  const finger = st.fingers.get(1);
  assert.deepEqual([finger.string, finger.fret, finger.from], [5, 1, 0]);
  assert.deepEqual(st.fingerStrings(finger), [0, 1, 2, 3, 4, 5]);
  assert.deepEqual(names(st), ['F2', 'A#2', 'D#3', 'G#3', 'C4', 'F4'], 'every string is fretted at 1');
  // other fingers in front of the barre: F major, E shape
  st.pressFinger(2, 3, 2); st.pressFinger(3, 1, 3); st.pressFinger(4, 2, 3);
  assert.deepEqual(names(st), ['F2', 'C3', 'F3', 'A3', 'C4', 'F4']);
  // the barre slides as one
  st.moveFinger(1, 5, 3);
  assert.equal(st.fingers.get(1).from, 0, 'sliding keeps the span');
  assert.deepEqual(names(st), ['G2', 'C3', 'F3', 'A#3', 'D4', 'G4']);
  // dragging back toward where it began uncovers strings; back at the start it is one fingertip again
  st.moveFinger(1, 2, 3, { barre: true });
  assert.deepEqual(st.fingerStrings(st.fingers.get(1)), [0, 1, 2]);
  assert.equal(st.noteOn(5).name, 'E4');
  st.moveFinger(1, 0, 3, { barre: true });
  assert.equal(st.fingers.get(1).from, undefined);
  // a step to another string without barre leaves the old strings
  st.moveFinger(1, 1, 4);
  assert.deepEqual(st.fingerStrings(st.fingers.get(1)), [1]);
  // partial barre from the A string (A shape), then hold it
  st.liftAll();
  st.pressFinger(7, 1, 2);
  st.moveFinger(7, 5, 2, { barre: true });
  const id = st.holdFinger(7);
  assert.ok(!st.fingers.has(7) && st.fingers.get(id).held, 'the touch is gone, the finger stays');
  assert.deepEqual(names(st), ['E2', 'B2', 'E3', 'A3', 'C#4', 'F#4']);
  assert.equal(st.heldFingerAt(3, 2).id, id, 'found under any string it covers');
  assert.equal(st.heldFingerAt(0, 2), null);
  assert.equal(st.heldFingerAt(3, 3), null);
  st.pressFinger(8, 4, 3);
  st.liftAll();
  assert.equal(st.fingers.size, 1, 'liftAll lifts touches, not held fingers');
  st.liftAll({ held: true });
  assert.equal(st.fingers.size, 0);
  // bends belong to single fingertips only
  st.pressFinger(9, 2, 7); st.setFingerBend(9, 1, 10);
  assert.equal(st.bendOn(2), 1);
  st.moveFinger(9, 3, 7, { barre: true });
  assert.equal(st.bendOn(2), 0); assert.equal(st.bendOn(3), 0);
});
