import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OPEN_VOICINGS, MOVABLE_SHAPES } from '../src/theory/chord-voicings.js';
import {
  CHORD_QUALITIES, chordName, chordVoicings, validateVoicing, voicingBarres, voicingBaseFret, voicingMaxFret,
  voicingPitchClasses,
} from '../src/theory/chords.js';
import { pitchClass, pitchClassName } from '../src/theory/notes.js';

/* Standard tuning, low E to high E. */
const STD = [40, 45, 50, 55, 59, 64];
const QUALITY_IDS = CHORD_QUALITIES.map((q) => q.id);
const VALID_FINGERS = [1, 2, 3, 4, 'T'];

const show = (v) => v.frets.map((f) => (f < 0 ? 'x' : f)).join(',');
/**
 * Identity of a voicing as the user sees it: its fret pattern. The panel shows
 * one card per fret pattern, so two fingerings of the same frets are one voicing.
 */
const fretKey = (v) => v.frets.join(',');

/** Indices of the muted strings that lie between two sounding strings. */
function innerMutedStrings(frets) {
  const first = frets.findIndex((f) => f >= 0);
  const last = frets.length - 1 - [...frets].reverse().findIndex((f) => f >= 0);
  return frets.map((f, s) => (f < 0 && s > first && s < last ? s : -1)).filter((s) => s >= 0);
}

/**
 * Independent placement of a movable shape (not the library's own code): the
 * lowest position whose lowest fretted fret is at or above fret 1 and whose
 * root string sounds the requested root. Shape frets are relative to the
 * shape's lowest fretted fret.
 */
function instantiate(shape, rootPc) {
  for (let base = 1; base <= 12; base++) {
    if (pitchClass(STD[shape.rootString] + base + shape.frets[shape.rootString]) === rootPc) {
      return shape.frets.map((f) => (f < 0 ? -1 : f + base));
    }
  }
  throw new Error(`no position for ${shape.name}`);
}

/**
 * Where a chord diagram starts (independent of voicingBaseFret): fret 1 when
 * the whole voicing fits in the first four frets, else its lowest fretted fret.
 */
function diagramBaseFret(frets) {
  const fretted = frets.filter((f) => f > 0);
  if (!fretted.length || Math.max(...fretted) <= 4) return 1;
  return Math.min(...fretted);
}

/** Pitch class of the lowest sounding string. */
function bassPitchClass(voicing, openMidi = STD) {
  const s = voicing.frets.findIndex((f) => f >= 0);
  return pitchClass(openMidi[s] + voicing.frets[s]);
}

/**
 * Physical sanity of a fingering. Returns a list of problems (empty = fine):
 *  - six frets / six fingers; finger 0 exactly on open or muted strings;
 *  - fretted strings use 1..4 or 'T';
 *  - a finger that presses two or more strings is declared as a barre at that
 *    fret spanning those strings; every string inside a barre range that sits
 *    at the barre fret uses the barre finger; nothing inside a barre range is
 *    open, muted or below the barre fret;
 *  - a lower fret never uses a higher-numbered finger than a higher fret;
 *  - the thumb only reaches over the neck onto the low E string, and it is
 *    never at a higher fret than the fingers (it wraps at or behind them);
 *  - at most four distinct fingers.
 */
function fingeringProblems(voicing) {
  const problems = [];
  const { frets, fingers } = voicing;
  if (!Array.isArray(frets) || frets.length !== 6) problems.push('frets must have six entries');
  if (!Array.isArray(fingers) || fingers.length !== 6) problems.push('fingers must have six entries');
  if (problems.length) return problems;

  for (let s = 0; s < 6; s++) {
    if (!Number.isInteger(frets[s]) || frets[s] < -1 || frets[s] > 22) problems.push(`string ${s}: fret ${frets[s]} out of range`);
    if (frets[s] <= 0 && fingers[s] !== 0) problems.push(`string ${s}: open/muted string must have finger 0`);
    if (frets[s] > 0 && !VALID_FINGERS.includes(fingers[s])) problems.push(`string ${s}: finger ${fingers[s]} is not 1..4 or 'T'`);
    if (fingers[s] === 'T' && s !== 0) problems.push(`string ${s}: the thumb only reaches the low E string`);
  }
  if (fingers[0] === 'T') {
    const fingerFrets = frets.filter((f, s) => f > 0 && s !== 0 && fingers[s] !== 'T');
    if (fingerFrets.length && frets[0] > Math.min(...fingerFrets)) {
      problems.push(`thumb at fret ${frets[0]} is above the lowest finger fret ${Math.min(...fingerFrets)}`);
    }
  }

  // Barres: declared ranges must be coherent and each one maps to one finger.
  const barreByFinger = new Map();
  for (const b of voicingBarres(voicing)) {
    if (!Number.isInteger(b.fret) || b.fret < 1) problems.push(`barre at fret ${b.fret} is impossible`);
    if (!Number.isInteger(b.from) || !Number.isInteger(b.to) || b.from < 0 || b.to > 5 || b.from >= b.to) {
      problems.push(`barre range ${b.from}..${b.to} is invalid`);
      continue;
    }
    let finger = null;
    for (let s = b.from; s <= b.to; s++) {
      if (frets[s] < b.fret) problems.push(`string ${s} is open/muted/below the barre at fret ${b.fret}`);
      if (frets[s] === b.fret) {
        if (finger === null) finger = fingers[s];
        else if (fingers[s] !== finger) problems.push(`strings at barre fret ${b.fret} use different fingers`);
      }
    }
    if (finger === null) problems.push(`barre at fret ${b.fret} covers no string at that fret`);
    else if (barreByFinger.has(finger)) problems.push(`finger ${finger} is declared in two barres`);
    else barreByFinger.set(finger, b);
  }

  // Every finger on 2+ strings must be a declared barre, and a barre finger
  // must not appear outside its range or at another fret.
  const stringsByFinger = new Map();
  fingers.forEach((f, s) => { if (f !== 0) stringsByFinger.set(f, [...(stringsByFinger.get(f) || []), s]); });
  for (const [finger, strings] of stringsByFinger) {
    const barre = barreByFinger.get(finger);
    if (strings.length > 1 && !barre) problems.push(`finger ${finger} presses strings ${strings.join(',')} without a declared barre`);
    if (barre) {
      for (const s of strings) {
        if (s < barre.from || s > barre.to || frets[s] !== barre.fret) problems.push(`finger ${finger} is used on string ${s} outside its barre`);
      }
    }
  }

  // Finger ordering: lower fret => lower (or equal) finger number.
  for (let a = 0; a < 6; a++) {
    for (let b = 0; b < 6; b++) {
      if (frets[a] <= 0 || frets[b] <= 0 || fingers[a] === 'T' || fingers[b] === 'T') continue;
      if (frets[a] < frets[b] && fingers[a] > fingers[b]) {
        problems.push(`finger ${fingers[a]} at fret ${frets[a]} but finger ${fingers[b]} at fret ${frets[b]}`);
      }
    }
  }

  if (stringsByFinger.size > 4) problems.push(`${stringsByFinger.size} fingers used`);
  return problems;
}

const openEntries = Object.entries(OPEN_VOICINGS);

test('the open voicing library is non-empty and keyed by "<pitchClass>:<quality>"', () => {
  assert.ok(openEntries.length >= 40, 'expected a substantial open-chord library');
  for (const [key, list] of openEntries) {
    const m = /^(\d{1,2}):(.+)$/.exec(key);
    assert.ok(m, `key ${key} is not "<pc>:<quality>"`);
    const pc = Number(m[1]);
    assert.ok(Number.isInteger(pc) && pc >= 0 && pc <= 11, `key ${key}: pitch class out of range`);
    assert.ok(QUALITY_IDS.includes(m[2]), `key ${key}: unknown quality ${m[2]}`);
    // chordVoicings() shows at least four cards per chord; a key with more
    // curated entries than that would crowd out the rest of the panel.
    assert.ok(Array.isArray(list) && list.length >= 1 && list.length <= 4, `key ${key}: 1-4 voicings expected`);
    const names = new Set();
    const patterns = new Set();
    for (const v of list) {
      assert.equal(typeof v.name, 'string');
      assert.ok(v.name.length > 0, `key ${key}: voicing needs a name`);
      assert.ok(!names.has(v.name), `key ${key}: duplicate voicing name ${v.name}`);
      names.add(v.name);
      // One entry per fret pattern: chordVoicings() shows a single card per
      // pattern, so a second fingering of the same frets would never be seen.
      assert.ok(!patterns.has(fretKey(v)), `key ${key}: fret pattern ${show(v)} listed twice (${v.name})`);
      patterns.add(fretKey(v));
    }
  }
});

test('open voicings never repeat a voicing that a movable shape already produces', () => {
  // chordVoicings() keeps one card per fret pattern (the first one wins), so an
  // open entry identical to a shape instance would silently hide that shape.
  // The shapes are placed here independently of chordVoicings().
  for (const [key, list] of openEntries) {
    const [pc, quality] = key.split(':');
    const fromShapes = MOVABLE_SHAPES.filter((s) => s.quality === quality)
      .map((s) => ({ shape: s.name, frets: instantiate(s, Number(pc)) }));
    for (const v of list) {
      const twin = fromShapes.find((s) => fretKey(s) === fretKey(v));
      assert.ok(!twin, `${key} ${show(v)} (${v.name}) duplicates movable shape "${twin?.shape}"`);
    }
  }
});

test('every open voicing reaches the user: chordVoicings lists them first, in library order', () => {
  for (const [key, list] of openEntries) {
    const [pc, quality] = key.split(':');
    const cards = chordVoicings(Number(pc), quality, STD);
    assert.deepEqual(cards.slice(0, list.length).map(show), list.map(show), `${key}: open voicings must lead the cards in library order`);
    list.forEach((v, i) => {
      assert.equal(cards[i].name, v.name, `${key} ${show(v)}`);
      assert.deepEqual(cards[i].fingers, v.fingers, `${key} ${show(v)}: fingering`);
      assert.deepEqual(voicingBarres(cards[i]), voicingBarres(v), `${key} ${show(v)}: barre`);
      assert.equal(cards[i].curated, true);
    });
  }
});

test('every open voicing sounds exactly the chord tones (validateVoicing)', () => {
  for (const [key, list] of openEntries) {
    const [pc, quality] = key.split(':');
    for (const v of list) {
      const problems = validateVoicing(v, Number(pc), quality, STD);
      assert.deepEqual(problems, [], `${chordName(Number(pc), quality)} ${show(v)} (${v.name}): ${problems.join('; ')}`);
      const sounding = voicingPitchClasses(v, STD);
      for (const s of sounding) {
        assert.ok(CHORD_QUALITIES.find((q) => q.id === quality).intervals.map((i) => pitchClass(Number(pc) + i)).includes(s),
          `${key} ${show(v)} sounds ${pitchClassName(s)}`);
      }
    }
  }
});

test('open voicings keep the root in the bass unless a slash bass is declared', () => {
  for (const [key, list] of openEntries) {
    const [pc] = key.split(':');
    for (const v of list) {
      const bass = bassPitchClass(v);
      if (v.bass !== undefined) {
        assert.ok(Number.isInteger(v.bass) && v.bass >= 0 && v.bass <= 11, `${key} ${show(v)}: bass must be a pitch class`);
        assert.notEqual(v.bass, Number(pc), `${key} ${show(v)}: bass property equals the root (drop it)`);
        assert.equal(bass, v.bass, `${key} ${show(v)}: bass is ${pitchClassName(bass)}, declared ${pitchClassName(v.bass)}`);
      } else {
        assert.equal(bass, Number(pc), `${key} ${show(v)} (${v.name}): bass is ${pitchClassName(bass)}, not the root`);
      }
    }
  }
});

test('open voicing fingerings are physically sane (fingers, barres, ordering)', () => {
  for (const [key, list] of openEntries) {
    for (const v of list) {
      assert.equal(v.frets.length, 6, `${key} ${show(v)}: six frets`);
      assert.equal(v.fingers.length, 6, `${key} ${show(v)}: six fingers`);
      v.frets.forEach((f, s) => {
        assert.equal(v.fingers[s] === 0, f <= 0, `${key} ${show(v)}: finger ${v.fingers[s]} on string ${s} (fret ${f})`);
      });
      const problems = fingeringProblems(v);
      assert.deepEqual(problems, [], `${key} ${show(v)} fingers ${v.fingers.join(',')} (${v.name}): ${problems.join('; ')}`);
      assert.ok(Math.max(...v.frets) <= 7, `${key} ${show(v)}: open-position library should stay in the low frets`);
      // A muted string between sounding strings has to be damped by a
      // neighbouring finger: one is a normal grip (3x0013), two cannot be strummed.
      const inner = innerMutedStrings(v.frets);
      assert.ok(inner.length <= 1, `${key} ${show(v)} (${v.name}): mutes ${inner.length} strings between sounding strings`);
    }
    // The first entry of a key is the first card the user sees: it must be
    // strummable straight across.
    assert.deepEqual(innerMutedStrings(list[0].frets), [], `${key}: first voicing ${show(list[0])} (${list[0].name}) mutes an inner string`);
  }
});

test('the curated library covers the standard chords with their conventional fingerings', () => {
  // Open-position chords must be in OPEN_VOICINGS itself ...
  const expect = (key, frets, fingers) => {
    const list = OPEN_VOICINGS[key] || [];
    const hit = list.find((v) => v.frets.join(',') === frets.join(','));
    assert.ok(hit, `${key}: expected a voicing ${frets.join(',')}; have ${list.map(show).join(' | ')}`);
    if (fingers) assert.deepEqual(hit.fingers, fingers, `${key} ${frets.join(',')}: fingering`);
    return hit;
  };
  // ... while closed voicings (barre and fretted power chords) are produced by
  // the movable shapes; either way they must reach the user through chordVoicings.
  const expectCurated = (root, quality, frets, fingers) => {
    const list = chordVoicings(root, quality, STD).filter((v) => v.curated);
    const hit = list.find((v) => v.frets.join(',') === frets.join(','));
    assert.ok(hit, `${chordName(root, quality)}: expected a curated voicing ${frets.join(',')}; have ${list.map(show).join(' | ')}`);
    if (fingers) assert.deepEqual(hit.fingers, fingers, `${chordName(root, quality)} ${frets.join(',')}: fingering`);
    return hit;
  };
  // Majors
  expect('0:maj', [-1, 3, 2, 0, 1, 0], [0, 3, 2, 0, 1, 0]);       // C
  expect('9:maj', [-1, 0, 2, 2, 2, 0]);                              // A
  expect('7:maj', [3, 2, 0, 0, 0, 3], [2, 1, 0, 0, 0, 3]);          // G
  expect('4:maj', [0, 2, 2, 1, 0, 0], [0, 2, 3, 1, 0, 0]);          // E
  expect('2:maj', [-1, -1, 0, 2, 3, 2], [0, 0, 0, 1, 3, 2]);        // D
  const f = expectCurated(5, 'maj', [1, 3, 3, 2, 1, 1], [1, 3, 4, 2, 1, 1]); // F barre (E shape, fret 1)
  assert.deepEqual(voicingBarres(f), [{ fret: 1, from: 0, to: 5 }]);
  assert.ok(OPEN_VOICINGS['5:maj'].some((v) => ['-1,-1,3,2,1,1', '1,-1,3,2,1,1'].includes(v.frets.join(','))), 'small F form');
  expectCurated(10, 'maj', [-1, 1, 3, 3, 3, 1]);                      // Bb (A shape, fret 1)
  // Minors
  expect('9:min', [-1, 0, 2, 2, 1, 0], [0, 0, 2, 3, 1, 0]);         // Am
  expect('4:min', [0, 2, 2, 0, 0, 0]);                               // Em
  expect('2:min', [-1, -1, 0, 2, 3, 1], [0, 0, 0, 2, 3, 1]);        // Dm
  const bm = expectCurated(11, 'min', [-1, 2, 4, 4, 3, 2], [0, 1, 3, 4, 2, 1]); // Bm (Am shape, fret 2)
  assert.deepEqual(voicingBarres(bm), [{ fret: 2, from: 1, to: 5 }]);
  expectCurated(5, 'min', [1, 3, 3, 1, 1, 1], [1, 3, 4, 1, 1, 1]);  // Fm (Em shape, fret 1)
  // Sevenths
  expect('4:7', [0, 2, 0, 1, 0, 0], [0, 2, 0, 1, 0, 0]);            // E7
  expect('9:7', [-1, 0, 2, 0, 2, 0], [0, 0, 2, 0, 3, 0]);           // A7
  expect('2:7', [-1, -1, 0, 2, 1, 2], [0, 0, 0, 2, 1, 3]);          // D7
  expect('7:7', [3, 2, 0, 0, 0, 1], [3, 2, 0, 0, 0, 1]);            // G7
  expect('0:7', [-1, 3, 2, 3, 1, 0], [0, 3, 2, 4, 1, 0]);           // C7
  expect('11:7', [-1, 2, 1, 2, 0, 2], [0, 2, 1, 3, 0, 4]);          // B7
  expect('0:maj7', [-1, 3, 2, 0, 0, 0]);                             // Cmaj7
  expect('9:maj7', [-1, 0, 2, 1, 2, 0]);                             // Amaj7
  expect('2:maj7', [-1, -1, 0, 2, 2, 2]);                            // Dmaj7
  expect('4:maj7', [0, 2, 1, 1, 0, 0]);                              // Emaj7
  expect('5:maj7', [-1, -1, 3, 2, 1, 0], [0, 0, 3, 2, 1, 0]);       // Fmaj7
  expect('7:maj7', [3, 2, 0, 0, 0, 2]);                              // Gmaj7
  expect('6:maj7', [-1, -1, 4, 3, 2, 1], [0, 0, 4, 3, 2, 1]);       // F#maj7 (four strings)
  expect('8:maj7', [-1, -1, 6, 5, 4, 3], [0, 0, 4, 3, 2, 1]);       // G#maj7 (four strings)
  expectCurated(6, 'maj7', [2, 4, 3, 3, 2, 2], [1, 4, 2, 3, 1, 1]); // F#maj7 (Emaj7 shape)
  expect('9:m7', [-1, 0, 2, 0, 1, 0], [0, 0, 2, 0, 1, 0]);          // Am7
  expect('4:m7', [0, 2, 0, 0, 0, 0]);                                // Em7
  expect('4:m7', [0, 2, 2, 0, 3, 0]);                                // Em7 (second form)
  expect('2:m7', [-1, -1, 0, 2, 1, 1]);                              // Dm7
  expect('11:m7', [-1, 2, 0, 2, 0, 2], [0, 1, 0, 2, 0, 3]);         // Bm7
  // Suspended / added / sixth
  expect('9:sus2', [-1, 0, 2, 2, 0, 0]);
  expect('2:sus2', [-1, -1, 0, 2, 3, 0]);
  expect('7:sus2', [3, 0, 0, 0, 3, 3], [2, 0, 0, 0, 3, 4]);         // Gsus2
  expect('0:sus2', [-1, 3, 0, 0, 1, 3], [0, 2, 0, 0, 1, 3]);        // Csus2
  const fsus2 = expect('5:sus2', [-1, -1, 3, 0, 1, 1], [0, 0, 3, 0, 1, 1]); // Fsus2
  assert.deepEqual(voicingBarres(fsus2), [{ fret: 1, from: 4, to: 5 }]);
  expectCurated(6, 'sus2', [-1, -1, 4, 1, 2, 2]);                    // F#sus2 (Fsus2 shape)
  expectCurated(8, 'sus2', [-1, -1, 6, 3, 4, 4]);                    // G#sus2 (Fsus2 shape)
  expect('9:sus4', [-1, 0, 2, 2, 3, 0]);
  expect('2:sus4', [-1, -1, 0, 2, 3, 3]);
  expect('4:sus4', [0, 2, 2, 2, 0, 0]);
  expect('7:sus4', [3, 3, 0, 0, 1, 3]);
  const csus4 = expect('0:sus4', [-1, 3, 3, 0, 1, 1], [0, 3, 4, 0, 1, 1]); // Csus4
  assert.deepEqual(voicingBarres(csus4), [{ fret: 1, from: 4, to: 5 }]);
  expect('5:sus4', [-1, -1, 3, 3, 1, 1], [0, 0, 3, 4, 1, 1]);       // Fsus4
  expect('4:7sus4', [0, 2, 0, 2, 0, 0]);                             // E7sus4
  expect('9:7sus4', [-1, 0, 2, 0, 3, 0]);                            // A7sus4
  expect('2:7sus4', [-1, -1, 0, 2, 1, 3]);                           // D7sus4
  expect('7:7sus4', [3, 3, 0, 0, 1, 1], [2, 3, 0, 0, 1, 1]);        // G7sus4
  expect('7:7sus4', [3, -1, 0, 0, 1, 1]);                            // G7sus4 (A muted)
  expect('0:add9', [-1, 3, 2, 0, 3, 0], [0, 2, 1, 0, 3, 0]);        // Cadd9
  expect('9:add9', [-1, 0, 2, 4, 2, 0], [0, 0, 1, 3, 2, 0]);        // Aadd9
  expect('2:add9', [-1, 5, 4, 2, 3, 0]);                             // Dadd9
  expect('7:add9', [3, 2, 0, 2, 0, 3], [3, 1, 0, 2, 0, 4]);         // Gadd9
  expectCurated(1, 'add9', [-1, 4, 3, 1, 4, -1], [0, 3, 2, 1, 4, 0]); // C#add9 (Cadd9 shape)
  expectCurated(3, 'add9', [-1, 6, 5, 3, 6, -1]);                    // D#add9
  expect('9:6', [-1, 0, 2, 2, 2, 2]);                                // A6
  expect('4:6', [0, 2, 2, 1, 2, 0]);                                 // E6
  expect('7:6', [3, 2, 0, 0, 0, 0]);                                 // G6
  // Diminished / half-diminished / augmented
  expect('2:dim', [-1, -1, 0, 1, 3, 1], [0, 0, 0, 1, 3, 2]);        // Ddim
  expect('2:dim7', [-1, -1, 0, 1, 0, 1]);                            // Ddim7
  expect('10:dim7', [-1, 1, 2, 0, 2, 0], [0, 1, 2, 0, 3, 0]);       // A#dim7
  expectCurated(11, 'dim7', [-1, 2, 3, 1, 3, -1], [0, 2, 3, 1, 4, 0]); // Bdim7 (A-string root)
  expectCurated(0, 'dim7', [-1, 3, 4, 2, 4, -1], [0, 2, 3, 1, 4, 0]);  // Cdim7
  expectCurated(1, 'dim7', [-1, 4, 5, 3, 5, -1]);                    // C#dim7
  expectCurated(5, 'dim7', [1, 2, 3, 1, 3, 1], [1, 2, 3, 1, 4, 1]); // Fdim7 (E-string root)
  expectCurated(3, 'dim7', [-1, -1, 1, 2, 1, 2]);                    // D#dim7 (D-string root)
  const dm7b5 = expect('2:m7b5', [-1, -1, 0, 1, 1, 1], [0, 0, 0, 1, 1, 1]); // Dm7b5
  assert.deepEqual(voicingBarres(dm7b5), [{ fret: 1, from: 3, to: 5 }]);
  expect('0:aug', [-1, 3, 2, 1, 1, 0], [0, 3, 2, 1, 1, 0]);         // Caug
  expect('4:aug', [0, 3, 2, 1, 1, 0]);                               // Eaug
  expect('9:aug', [-1, 0, 3, 2, 2, 1], [0, 0, 4, 3, 2, 1]);         // Aaug
  expect('2:aug', [-1, -1, 0, 3, 3, 2]);                             // Daug
  expectCurated(5, 'aug', [-1, -1, 3, 2, 2, 1], [0, 0, 4, 2, 3, 1]); // Faug (xx3221)
  expectCurated(3, 'aug', [-1, -1, 1, 4, 4, 3], [0, 0, 1, 3, 4, 2]); // D#aug (Daug shape)
  const cSharpAug = expectCurated(1, 'aug', [-1, 4, 3, 2, 2, -1], [0, 3, 2, 1, 1, 0]); // C#aug (Caug shape)
  assert.deepEqual(voicingBarres(cSharpAug), [{ fret: 2, from: 3, to: 4 }]);
  expectCurated(8, 'aug', [4, 3, 2, 1, 1, -1], [4, 3, 2, 1, 1, 0]); // G#aug (Gaug shape)
  expectCurated(5, '6', [-1, -1, 3, 2, 3, 1], [0, 0, 3, 2, 4, 1]);  // F6 (xx3231)
  // Power chords: open forms in the library, fretted forms from the shapes.
  expect('4:5', [0, 2, 2, -1, -1, -1]);                              // E5
  expect('9:5', [-1, 0, 2, 2, -1, -1]);                              // A5
  expect('2:5', [-1, -1, 0, 2, 3, -1]);                              // D5
  expectCurated(7, '5', [3, 5, 5, -1, -1, -1], [1, 3, 4, 0, 0, 0]);  // G5
  expectCurated(0, '5', [-1, 3, 5, 5, -1, -1], [0, 1, 3, 4, 0, 0]);  // C5
  expectCurated(9, '5', [5, 7, 7, -1, -1, -1], [1, 3, 4, 0, 0, 0]);  // A5 (fret 5)
  // Ninths: the chord-book grips (3rd one fret below the root) come from the
  // movable shapes; forms with open strings are in the library.
  expect('9:9', [-1, 0, 2, 4, 2, 3]);                                // A9
  expect('4:9', [0, 2, 0, 1, 0, 2]);                                 // E9
  const c9 = expectCurated(0, '9', [-1, 3, 2, 3, 3, 3], [0, 2, 1, 3, 3, 3]); // C9
  assert.deepEqual(voicingBarres(c9), [{ fret: 3, from: 3, to: 5 }]);
  expectCurated(0, '9', [-1, 3, 2, 3, 3, -1], [0, 2, 1, 3, 3, 0]);  // C9 (four strings)
  expectCurated(2, '9', [-1, 5, 4, 5, 5, 5]);                        // D9
  expectCurated(11, '9', [-1, 2, 1, 2, 2, 2], [0, 2, 1, 3, 3, 3]);  // B9
  expectCurated(1, '9', [-1, 4, 3, 4, 4, 4]);                        // C#9
  expectCurated(3, '9', [-1, 6, 5, 6, 6, 6]);                        // D#9
  expectCurated(5, '9', [1, 3, 1, 2, 1, 3], [1, 3, 1, 2, 1, 4]);    // F9 (E9 shape)
  const bb9 = expectCurated(10, '9', [6, 5, 6, 5, 6, -1], [2, 1, 3, 1, 4, 0]); // A#9 (E-string root)
  assert.deepEqual(voicingBarres(bb9), [{ fret: 5, from: 1, to: 3 }]);
  expect('7:9', [3, 2, 0, 2, 0, 1]);                                 // G9
  expect('0:maj9', [-1, 3, 2, 4, 3, 0]);                             // Cmaj9
  expect('4:maj9', [0, 2, 1, 1, 0, 2], [0, 3, 1, 2, 0, 4]);         // Emaj9
  expect('9:maj9', [-1, 0, 2, 4, 2, 4]);                             // Amaj9
  expect('5:maj9', [1, 0, 2, 0, 1, 0]);                              // Fmaj9
  expectCurated(0, 'maj9', [-1, 3, 2, 4, 3, -1], [0, 2, 1, 4, 3, 0]); // Cmaj9 (A-string root)
  expectCurated(11, 'maj9', [-1, 2, 1, 3, 2, -1]);                   // Bmaj9
  expectCurated(11, 'maj9', [-1, 2, 1, 3, 2, 2], [0, 2, 1, 4, 3, 3]); // Bmaj9 (five strings)
  expectCurated(1, 'maj9', [-1, 4, 3, 5, 4, -1]);                    // C#maj9
  expectCurated(2, 'maj9', [-1, 5, 4, 6, 5, -1]);                    // Dmaj9
  expectCurated(3, 'maj9', [-1, 6, 5, 7, 6, -1]);                    // D#maj9
  expectCurated(7, 'maj9', [3, 2, 4, 2, 3, -1], [2, 1, 4, 1, 3, 0]); // Gmaj9 (E-string root)
  expect('9:m9', [-1, 0, 2, 4, 1, 3], [0, 0, 2, 4, 1, 3]);          // Am9
  expect('4:m9', [0, 2, 2, 0, 3, 2]);                                // Em9
  expect('11:m9', [-1, 2, 0, 2, 2, 2]);                              // Bm9
  const cm9 = expectCurated(0, 'm9', [-1, 3, 1, 3, 3, 3], [0, 2, 1, 3, 3, 3]); // Cm9
  assert.deepEqual(voicingBarres(cm9), [{ fret: 3, from: 3, to: 5 }]);
  expectCurated(2, 'm9', [-1, 5, 3, 5, 5, 5]);                       // Dm9
  expectCurated(1, 'm9', [-1, 4, 2, 4, 4, 4]);                       // C#m9
  expectCurated(3, 'm9', [-1, 6, 4, 6, 6, 6]);                       // D#m9
  expectCurated(5, 'm9', [1, 3, 1, 1, 1, 3], [1, 3, 1, 1, 1, 4]);   // Fm9 (Em9 shape)
  expect('10:m9', [6, 4, 6, 5, -1, -1], [3, 1, 4, 2, 0, 0]);        // A#m9 (four strings, the only form below fret 8)
  expectCurated(7, 'm9', [3, 5, 3, 3, 3, 5], [1, 3, 1, 1, 1, 4]);   // Gm9 (Em9 shape)
  for (const key of ['9:dim', '4:dim', '4:dim7', '7:add9', '7:aug']) assert.ok(OPEN_VOICINGS[key]?.length, `${key} present`);
  // Slash voicing: C/G declares its bass.
  const cg = OPEN_VOICINGS['0:maj'].find((v) => v.frets.join(',') === '3,3,2,0,1,0');
  assert.ok(cg && cg.bass === 7, 'C/G declares bass G');
});

test('movable shapes are well formed', () => {
  assert.ok(MOVABLE_SHAPES.length >= 40);
  const seen = new Set();
  const seenFrets = new Set();
  for (const shape of MOVABLE_SHAPES) {
    const label = `${shape.quality} [${shape.frets.join(',')}] ${shape.name}`;
    assert.ok(QUALITY_IDS.includes(shape.quality), `${label}: unknown quality`);
    assert.ok(Number.isInteger(shape.rootString) && shape.rootString >= 0 && shape.rootString <= 5, `${label}: rootString`);
    assert.equal(shape.frets.length, 6, `${label}: six frets`);
    assert.equal(shape.fingers.length, 6, `${label}: six fingers`);
    // Frets are relative to the shape's lowest fretted fret: the lowest
    // sounding string of a shape is at 0, and the root string is fretted
    // (at 0 for the barre forms, higher when a string sits below the root).
    for (const f of shape.frets) assert.ok(Number.isInteger(f) && f >= -1 && f <= 4, `${label}: relative fret ${f}`);
    assert.equal(Math.min(...shape.frets.filter((f) => f >= 0)), 0, `${label}: the lowest fretted string must be at relative fret 0`);
    assert.ok(shape.frets[shape.rootString] >= 0, `${label}: the root string must be fretted`);
    for (let s = 0; s < shape.rootString; s++) assert.equal(shape.frets[s], -1, `${label}: strings below the root string must be muted`);
    assert.equal(typeof shape.name, 'string');
    const nameKey = `${shape.quality}:${shape.name}`;
    assert.ok(!seen.has(nameKey), `${label}: shape names must be unique within a quality`);
    seen.add(nameKey);
    // Two shapes of one quality with the same root string and frets would
    // instantiate to the same voicing for every root.
    const fretKey = `${shape.quality}:${shape.rootString}:${shape.frets.join(',')}`;
    assert.ok(!seenFrets.has(fretKey), `${label}: a shape with these frets already exists for this quality`);
    seenFrets.add(fretKey);
    // Muted strings between sounding strings must be damped by a fingertip;
    // one is standard (jazz grips mute the A string under the index), two
    // cannot be strummed at all.
    const innerMuted = innerMutedStrings(shape.frets);
    assert.ok(innerMuted.length <= 1, `${label}: mutes ${innerMuted.length} strings between sounding strings`);
    // Fingering sanity is checked on the shape itself, shifted to fret 1.
    const shifted = {
      frets: shape.frets.map((f) => (f < 0 ? -1 : f + 1)),
      fingers: shape.fingers,
      barre: shape.barre ? voicingBarres(shape).map((b) => ({ ...b, fret: b.fret + 1 })) : undefined,
    };
    const problems = fingeringProblems(shifted);
    assert.deepEqual(problems, [], `${label}: ${problems.join('; ')}`);
  }
});

test('every movable shape instantiates to a valid root-position voicing for all 12 roots', () => {
  for (const shape of MOVABLE_SHAPES) {
    for (let root = 0; root < 12; root++) {
      const instances = chordVoicings(root, shape.quality, STD).filter((v) => v.curated && v.shape === shape.name);
      assert.equal(instances.length, 1, `${chordName(root, shape.quality)}: shape "${shape.name}" should instantiate exactly once`);
      const [v] = instances;
      const problems = validateVoicing(v, root, shape.quality, STD);
      assert.deepEqual(problems, [], `${chordName(root, shape.quality)} ${show(v)} (${shape.name}): ${problems.join('; ')}`);
      assert.equal(bassPitchClass(v), root, `${chordName(root, shape.quality)} ${show(v)} (${shape.name}): root must be in the bass`);
      // The root string must sound the root. The shape is closed (no open
      // strings) and sits at its lowest position: its lowest fretted fret is
      // between 1 and 12, and the root is where the shape says it is.
      assert.equal(pitchClass(STD[shape.rootString] + v.frets[shape.rootString]), root);
      const fretted = v.frets.filter((f) => f >= 0);
      const lowest = Math.min(...fretted);
      assert.ok(lowest >= 1 && lowest <= 12, `${chordName(root, shape.quality)} ${show(v)} (${shape.name}): lowest fret ${lowest}`);
      assert.equal(v.frets[shape.rootString], lowest + shape.frets[shape.rootString]);
      assert.deepEqual(v.frets, instantiate(shape, root), `${chordName(root, shape.quality)} (${shape.name}): placement`);
      assert.deepEqual(v.fingers, shape.fingers, `${chordName(root, shape.quality)} (${shape.name}): fingers are the shape's`);
      assert.deepEqual(voicingBarres(v), voicingBarres(shape).map((b) => ({ ...b, fret: b.fret + lowest })),
        `${chordName(root, shape.quality)} (${shape.name}): barres move with the shape`);
      const fp = fingeringProblems(v);
      assert.deepEqual(fp, [], `${chordName(root, shape.quality)} ${show(v)} (${shape.name}): ${fp.join('; ')}`);
    }
  }
});

test('movable shapes cover E-string and A-string roots for every quality (plus D-string roots for most)', () => {
  for (const q of QUALITY_IDS) {
    const roots = new Set(MOVABLE_SHAPES.filter((s) => s.quality === q).map((s) => s.rootString));
    assert.ok(roots.has(0), `${q}: needs a shape rooted on the low E string`);
    assert.ok(roots.has(1), `${q}: needs a shape rooted on the A string`);
  }
  for (const q of ['maj', 'min', '5', '7', 'maj7', 'm7', 'sus2', 'sus4', '7sus4', 'dim', 'dim7', 'm7b5', 'aug', '6', 'm6']) {
    assert.ok(MOVABLE_SHAPES.some((s) => s.quality === q && s.rootString === 2), `${q}: needs a D-string-root shape`);
  }
  // The chord-book grips whose root is not the lowest fret of the shape.
  const hasShape = (quality, rootString, frets) => MOVABLE_SHAPES.some((s) => s.quality === quality
    && s.rootString === rootString && s.frets.join(',') === frets.join(','));
  assert.ok(hasShape('9', 1, [-1, 1, 0, 1, 1, 1]), '9: x32333 shape');
  assert.ok(hasShape('9', 1, [-1, 1, 0, 1, 1, -1]), '9: x3233x shape');
  assert.ok(hasShape('maj9', 1, [-1, 1, 0, 2, 1, -1]), 'maj9: x3243x shape');
  assert.ok(hasShape('m9', 1, [-1, 2, 0, 2, 2, 2]), 'm9: x31333 shape');
  assert.ok(hasShape('dim7', 1, [-1, 1, 2, 0, 2, -1]), 'dim7: x2313x shape');
  assert.ok(hasShape('aug', 1, [-1, 2, 1, 0, 0, -1]), 'aug: x3211x shape');
  assert.ok(hasShape('aug', 2, [-1, -1, 0, 3, 3, 2]), 'aug: xx0332-type shape');
  const eShape = MOVABLE_SHAPES.find((s) => s.quality === 'maj' && s.rootString === 0);
  assert.deepEqual(eShape.frets, [0, 2, 2, 1, 0, 0]);
  const aShape = MOVABLE_SHAPES.find((s) => s.quality === 'maj' && s.rootString === 1);
  assert.deepEqual(aShape.frets, [-1, 0, 2, 2, 2, 0]);
  // F major from the E shape lands on fret 1; Bb from the A shape on fret 1.
  assert.ok(chordVoicings(5, 'maj', STD).some((v) => v.frets.join(',') === '1,3,3,2,1,1'));
  assert.ok(chordVoicings(10, 'maj', STD).some((v) => v.frets.join(',') === '-1,1,3,3,3,1'));
});

test('chordVoicings offers at least two distinct, playable curated voicings for all 12 roots of every quality', () => {
  for (let root = 0; root < 12; root++) {
    for (const q of QUALITY_IDS) {
      const voicings = chordVoicings(root, q, STD);
      assert.ok(voicings.length >= 2, `${chordName(root, q)}: only ${voicings.length} voicing(s)`);
      for (const v of voicings) {
        const problems = validateVoicing(v, root, q, STD);
        assert.deepEqual(problems, [], `${chordName(root, q)} ${show(v)}: ${problems.join('; ')}`);
        assert.equal(v.frets.length, 6);
        assert.equal(v.fingers.length, 6);
      }
      // No two cards may show the same fret pattern (the panel renders every
      // entry; a second fingering of the same frets is not a second voicing).
      const keys = voicings.map(fretKey);
      assert.equal(new Set(keys).size, keys.length,
        `${chordName(root, q)}: duplicate voicings ${voicings.filter((v, i) => keys.indexOf(keys[i]) !== i).map(show).join(' | ')}`);
      // The curated library itself (not the generator fallback) must offer two
      // different voicings.
      const curated = voicings.filter((v) => v.curated);
      assert.ok(curated.length >= 1, `${chordName(root, q)}: expected curated voicings`);
      const curatedFrets = new Set(curated.map(fretKey));
      assert.ok(curatedFrets.size >= 2, `${chordName(root, q)}: curated library should offer two distinct voicings, has ${[...curatedFrets].join(' | ')}`);
      // One of them is in the low position (the open-library ceiling, fret 7)
      // and strummable straight across. There are no exceptions: all 12 roots
      // of all 19 qualities have such a voicing.
      assert.ok(curated.some((v) => voicingMaxFret(v) <= 7),
        `${chordName(root, q)}: no curated voicing at or below fret 7 (${curated.map(show).join(' | ')})`);
      assert.ok(curated.some((v) => voicingMaxFret(v) <= 7 && innerMutedStrings(v.frets).length === 0),
        `${chordName(root, q)}: no fully strummable curated voicing at or below fret 7 (${curated.map(show).join(' | ')})`);
      for (const v of curated) {
        const fp = fingeringProblems(v);
        assert.deepEqual(fp, [], `${chordName(root, q)} ${show(v)} (${v.name}): ${fp.join('; ')}`);
      }
      // Curated voicings come first and are copies (mutating them must not touch the library).
      assert.deepEqual(voicings.slice(0, curated.length).map((v) => v.curated), curated.map(() => true));
      curated[0].frets[0] = 99;
      assert.ok(!MOVABLE_SHAPES.some((s) => s.frets[0] === 99));
      assert.ok(!Object.values(OPEN_VOICINGS).flat().some((v) => v.frets[0] === 99));
    }
  }
});

test('common chords without an open form lead with a playable shape, not the hardest one', () => {
  // The first card is what a learner tries first: it must not be a full barre
  // plus a stretch of three or more frets above the barre when a simpler
  // curated voicing exists for the same chord.
  for (let root = 0; root < 12; root++) {
    for (const q of QUALITY_IDS) {
      const [first, ...rest] = chordVoicings(root, q, STD).filter((v) => v.curated);
      const stretch = (v) => {
        const fretted = v.frets.filter((f) => f > 0);
        return Math.max(...fretted) - Math.min(...fretted);
      };
      const fullBarre = voicingBarres(first).some((b) => b.to - b.from >= 4);
      if (fullBarre && stretch(first) >= 4) {
        assert.ok(!rest.some((v) => stretch(v) <= 3), `${chordName(root, q)}: leads with ${show(first)} (${first.name}) although an easier voicing exists`);
      }
    }
  }
});

test('the first card of every chord is strummable: no muted string between two sounding strings', () => {
  for (let root = 0; root < 12; root++) {
    for (const q of QUALITY_IDS) {
      const [first] = chordVoicings(root, q, STD);
      assert.equal(first.curated, true, `${chordName(root, q)}: the first card must come from the curated library`);
      assert.deepEqual(innerMutedStrings(first.frets), [],
        `${chordName(root, q)}: first card ${show(first)} (${first.name}) mutes a string between sounding strings`);
      // The first card is a root-position voicing (slash voicings such as C/G come later).
      assert.equal(first.bass, undefined, `${chordName(root, q)}: first card ${show(first)} is a slash voicing`);
      assert.equal(bassPitchClass(first), root, `${chordName(root, q)}: first card ${show(first)} (${first.name}) does not have the root in the bass`);
    }
  }
});

test('cards are ordered: open voicings in library order, then every movable shape by position', () => {
  for (let root = 0; root < 12; root++) {
    for (const q of QUALITY_IDS) {
      const label = chordName(root, q);
      const curated = chordVoicings(root, q, STD).filter((v) => v.curated);
      const open = OPEN_VOICINGS[`${root}:${q}`] || [];
      assert.deepEqual(curated.slice(0, open.length).map(show), open.map(show), `${label}: open voicings first, in library order`);
      const shapes = curated.slice(open.length);
      const qualityShapes = MOVABLE_SHAPES.filter((s) => s.quality === q);
      assert.deepEqual(shapes.map((v) => v.shape).sort(), qualityShapes.map((s) => s.name).sort(), `${label}: every shape of the quality appears exactly once`);
      // Position = (diagram base fret, highest fret); shapes that tie keep
      // their order in MOVABLE_SHAPES.
      const position = (v) => [diagramBaseFret(v.frets), Math.max(...v.frets), qualityShapes.findIndex((s) => s.name === v.shape)];
      for (const v of shapes) {
        assert.equal(voicingBaseFret(v), diagramBaseFret(v.frets), `${label} ${show(v)}: base fret`);
        assert.equal(voicingMaxFret(v), Math.max(...v.frets), `${label} ${show(v)}: highest fret`);
      }
      for (let i = 1; i < shapes.length; i++) {
        const a = position(shapes[i - 1]);
        const b = position(shapes[i]);
        const cmp = a[0] - b[0] || a[1] - b[1] || a[2] - b[2];
        assert.ok(cmp < 0, `${label}: ${show(shapes[i - 1])} (${shapes[i - 1].name}) must not come before ${show(shapes[i])} (${shapes[i].name})`);
      }
    }
  }
  // The familiar low forms lead, not the same shape family higher up the neck.
  const lead = (root, q) => show(chordVoicings(root, q, STD)[0]);
  assert.equal(lead(11, 'min'), 'x,2,4,4,3,2');     // Bm: Am shape at fret 2, not the Em shape at fret 7
  assert.equal(lead(10, 'maj'), 'x,1,3,3,3,1');     // Bb: A shape at fret 1, not the E shape at fret 6
  assert.equal(lead(5, 'maj'), 'x,x,3,2,1,1');      // F: the small open-position F, then the barre
  assert.equal(show(chordVoicings(5, 'maj', STD)[2]), '1,3,3,2,1,1');
  assert.equal(lead(6, 'min'), '2,4,4,2,2,2');      // F#m
  assert.equal(lead(4, 'm7b5'), 'x,x,2,3,3,3');     // Em7b5: D-string root at fret 2, not the fret-12 form
  assert.equal(lead(11, '9'), 'x,2,1,2,2,2');       // B9
  assert.equal(lead(0, '9'), 'x,3,2,3,3,3');        // C9
  assert.equal(lead(0, 'm9'), 'x,3,1,3,3,3');       // Cm9
  assert.equal(lead(11, 'dim7'), 'x,2,3,1,3,x');    // Bdim7
  assert.equal(lead(0, 'dim7'), 'x,3,4,2,4,x');     // Cdim7
  assert.equal(lead(0, 'sus4'), 'x,3,3,0,1,1');     // Csus4
  assert.equal(lead(5, 'sus2'), 'x,x,3,0,1,1');     // Fsus2
  // A fully strummable shape leads where a jazz grip shares its position.
  assert.equal(lead(5, '7'), '1,3,1,2,1,1');        // F7: the barre
  assert.equal(lead(5, 'm7'), '1,3,1,1,1,1');       // Fm7: the barre
  assert.equal(lead(5, '6'), 'x,x,3,2,3,1');        // F6 before 1x323x
  assert.equal(lead(5, 'm6'), '1,3,3,1,3,1');       // Fm6 barre before 1x313x
  assert.equal(lead(5, 'aug'), 'x,x,3,2,2,1');      // Faug before 1x322x
  assert.equal(lead(6, 'maj7'), 'x,x,4,3,2,1');     // F#maj7 before 2x332x
  assert.equal(lead(6, 'maj9'), '2,1,3,1,2,x');     // F#maj9 before 2x3324
  assert.equal(lead(7, 'm9'), '3,5,3,3,3,5');       // Gm9: the Em9 barre
});
