/**
 * Chord formulas, chord naming/detection, and voicing generation.
 *
 * A "voicing" describes how a chord is played on the six strings:
 *   frets:   six entries, low string (index 0) to high string (index 5);
 *            -1 = muted ('x'), 0 = open, n = fret number.
 *   fingers: six entries, 0 = open/muted, 1..4 = index..pinky, 'T' = thumb.
 *   barre:   optional { fret, from, to } (string indices, inclusive), or an
 *            array of such objects when two fingers each barre several strings.
 *   name:    optional human description, e.g. "Open C" or "E shape barre".
 *
 * Pitch content is always derived from the active tuning, never hard-coded.
 */
import { pitchClass, pitchClassName } from './notes.js';
import { OPEN_VOICINGS, MOVABLE_SHAPES } from './chord-voicings.js';

export const CHORD_QUALITIES = Object.freeze([
  { id: 'maj', name: 'Major', symbol: '', intervals: [0, 4, 7], optional: [] },
  { id: 'min', name: 'Minor', symbol: 'm', intervals: [0, 3, 7], optional: [] },
  { id: '5', name: 'Power chord', symbol: '5', intervals: [0, 7], optional: [] },
  { id: '7', name: 'Dominant 7th', symbol: '7', intervals: [0, 4, 7, 10], optional: [7] },
  { id: 'maj7', name: 'Major 7th', symbol: 'maj7', intervals: [0, 4, 7, 11], optional: [7] },
  { id: 'm7', name: 'Minor 7th', symbol: 'm7', intervals: [0, 3, 7, 10], optional: [7] },
  { id: 'sus2', name: 'Suspended 2nd', symbol: 'sus2', intervals: [0, 2, 7], optional: [] },
  { id: 'sus4', name: 'Suspended 4th', symbol: 'sus4', intervals: [0, 5, 7], optional: [] },
  { id: '7sus4', name: 'Dominant 7th sus4', symbol: '7sus4', intervals: [0, 5, 7, 10], optional: [7] },
  { id: 'dim', name: 'Diminished', symbol: 'dim', intervals: [0, 3, 6], optional: [] },
  { id: 'dim7', name: 'Diminished 7th', symbol: 'dim7', intervals: [0, 3, 6, 9], optional: [] },
  { id: 'm7b5', name: 'Half-diminished', symbol: 'm7♭5', intervals: [0, 3, 6, 10], optional: [] },
  { id: 'aug', name: 'Augmented', symbol: 'aug', intervals: [0, 4, 8], optional: [] },
  { id: '6', name: 'Major 6th', symbol: '6', intervals: [0, 4, 7, 9], optional: [7] },
  { id: 'm6', name: 'Minor 6th', symbol: 'm6', intervals: [0, 3, 7, 9], optional: [7] },
  { id: 'add9', name: 'Added 9th', symbol: 'add9', intervals: [0, 4, 7, 2], optional: [7] },
  { id: '9', name: 'Dominant 9th', symbol: '9', intervals: [0, 4, 7, 10, 2], optional: [7] },
  { id: 'maj9', name: 'Major 9th', symbol: 'maj9', intervals: [0, 4, 7, 11, 2], optional: [7] },
  { id: 'm9', name: 'Minor 9th', symbol: 'm9', intervals: [0, 3, 7, 10, 2], optional: [7] },
].map(Object.freeze));

export function getQuality(id) {
  const q = CHORD_QUALITIES.find((x) => x.id === id);
  if (!q) throw new Error(`Unknown chord quality: ${id}`);
  return q;
}

/** Display name of a chord: chordName(7, 'min') === "Gm". */
export function chordName(rootPc, qualityId, { flats = false } = {}) {
  return `${pitchClassName(rootPc, { flats })}${getQuality(qualityId).symbol}`;
}

/** Pitch classes of a chord. */
export function chordPitchClasses(rootPc, qualityId) {
  return new Set(getQuality(qualityId).intervals.map((i) => pitchClass(rootPc + i)));
}

/** Pitch classes sounding in a voicing under a given tuning (open-string MIDI list). */
export function voicingPitchClasses(voicing, openMidi) {
  const out = new Set();
  voicing.frets.forEach((f, s) => { if (f >= 0) out.add(pitchClass(openMidi[s] + f)); });
  return out;
}

/** MIDI notes sounding in a voicing, low string to high. */
export function voicingMidiNotes(voicing, openMidi) {
  const out = [];
  voicing.frets.forEach((f, s) => { if (f >= 0) out.push(openMidi[s] + f); });
  return out;
}

/**
 * Validate a voicing against a chord: every sounding note must belong to the
 * chord, and every non-optional chord tone must be present. Returns a list of
 * problems (empty when valid).
 */
export function validateVoicing(voicing, rootPc, qualityId, openMidi) {
  const problems = [];
  const q = getQuality(qualityId);
  if (!Array.isArray(voicing.frets) || voicing.frets.length !== 6) problems.push('frets must have six entries');
  const chordSet = chordPitchClasses(rootPc, qualityId);
  const sounding = voicingPitchClasses(voicing, openMidi);
  for (const pc of sounding) {
    if (!chordSet.has(pc)) problems.push(`note ${pitchClassName(pc)} is not in the chord`);
  }
  for (const interval of q.intervals) {
    if (q.optional.includes(interval)) continue;
    const pc = pitchClass(rootPc + interval);
    if (!sounding.has(pc)) problems.push(`chord tone ${pitchClassName(pc)} is missing`);
  }
  const fretted = voicing.frets.filter((f) => f > 0);
  if (fretted.length) {
    const span = Math.max(...fretted) - Math.min(...fretted);
    if (span > 4) problems.push(`fret span ${span} is not playable`);
  }
  if (voicing.frets.every((f) => f < 0)) problems.push('voicing has no sounding strings');
  return problems;
}

/**
 * Identify a chord from a set of pitch classes (e.g. the notes currently
 * ringing). Returns the best match { rootPc, quality, name, inversion } or
 * null. Exact matches are preferred; otherwise partial matches with all
 * required tones present are accepted.
 */
export function detectChord(pitchClasses, { bassPc = null, flats = false } = {}) {
  const set = new Set([...pitchClasses].map(pitchClass));
  if (set.size < 2) return null;
  let best = null;
  for (let root = 0; root < 12; root++) {
    for (const q of CHORD_QUALITIES) {
      const chordSet = new Set(q.intervals.map((i) => pitchClass(root + i)));
      let extra = 0;
      for (const pc of set) if (!chordSet.has(pc)) extra++;
      if (extra > 0) continue;
      let missingRequired = 0;
      let missingOptional = 0;
      for (const i of q.intervals) {
        if (!set.has(pitchClass(root + i))) {
          if (q.optional.includes(i)) missingOptional++; else missingRequired++;
        }
      }
      if (missingRequired > 0) continue;
      // Score: prefer exact matches, more notes explained, root in the bass.
      let score = 100 - missingOptional * 10 + q.intervals.length;
      if (bassPc !== null) score += pitchClass(bassPc) === root ? 15 : 0;
      if (!best || score > best.score) {
        best = { score, rootPc: root, quality: q.id, name: chordName(root, q.id, { flats }), inversion: bassPc !== null && pitchClass(bassPc) !== root };
      }
    }
  }
  if (!best) return null;
  const { score, ...result } = best;
  if (result.inversion && bassPc !== null) result.name += `/${pitchClassName(bassPc, { flats })}`;
  return result;
}

/* -------------------------------------------------------------------------- */
/* Voicing library                                                            */
/* -------------------------------------------------------------------------- */

const STANDARD_OPEN_MIDI = [40, 45, 50, 55, 59, 64];

function sameTuning(openMidi, ref) {
  return openMidi.length === ref.length && openMidi.every((m, i) => m === ref[i]);
}

/** Highest fret used by a voicing (0 for all-open chords). */
export function voicingMaxFret(voicing) {
  return Math.max(0, ...voicing.frets);
}

/** Lowest fretted fret of a voicing (used to position chord diagrams). */
export function voicingBaseFret(voicing) {
  const fretted = voicing.frets.filter((f) => f > 0);
  if (!fretted.length) return 1;
  const min = Math.min(...fretted);
  const max = Math.max(...fretted);
  return max <= 4 ? 1 : min;
}

/** Instantiate a movable shape for a chord root. */
function shapeToVoicing(shape, rootPc, openMidi) {
  const rootOpen = openMidi[shape.rootString];
  let rootFret = pitchClass(rootPc - rootOpen);
  const minRel = Math.min(...shape.frets.filter((f) => f >= 0));
  // Shapes are stored relative to the root fret; frets below the root are negative.
  if (rootFret + minRel < 1) rootFret += 12;
  const frets = shape.frets.map((f) => (f < 0 ? -1 : f + rootFret));
  if (Math.max(...frets) > 22) return null;
  const voicing = {
    frets,
    fingers: [...shape.fingers],
    name: `${shape.name} (fret ${rootFret})`,
    shape: shape.name,
  };
  if (shape.barre) {
    voicing.barre = voicingBarres(shape).map((b) => ({ fret: b.fret + rootFret, from: b.from, to: b.to }));
    if (voicing.barre.length === 1) voicing.barre = voicing.barre[0];
  }
  return voicing;
}

/** Barres of a voicing as an array (the `barre` field may be one object, an array, or absent). */
export function voicingBarres(voicing) {
  if (!voicing.barre) return [];
  return Array.isArray(voicing.barre) ? voicing.barre : [voicing.barre];
}

/**
 * Algorithmic voicing search for any tuning. Looks for chords within a
 * four-fret window that use at most four fingers (a barre counts as one),
 * contain every required chord tone and place the root in the bass.
 */
export function generateVoicings(rootPc, qualityId, openMidi, { maxResults = 4, allowInversions = false } = {}) {
  const q = getQuality(qualityId);
  const chordSet = chordPitchClasses(rootPc, qualityId);
  const required = q.intervals.filter((i) => !q.optional.includes(i)).map((i) => pitchClass(rootPc + i));
  const results = [];
  const seen = new Set();

  for (let base = 0; base <= 12; base++) {
    const window = 3; // frets base .. base+window, plus open strings
    const options = openMidi.map((open) => {
      const opts = [-1];
      if (chordSet.has(pitchClass(open))) opts.push(0);
      for (let f = Math.max(1, base); f <= base + window; f++) {
        if (chordSet.has(pitchClass(open + f))) opts.push(f);
      }
      return opts;
    });

    const combo = new Array(6).fill(-1);
    const recurse = (s) => {
      if (s === 6) {
        evaluate(combo);
        return;
      }
      for (const f of options[s]) {
        combo[s] = f;
        recurse(s + 1);
      }
    };

    const evaluate = (frets) => {
      const sounding = frets.map((f, s) => (f >= 0 ? openMidi[s] + f : null)).filter((x) => x !== null);
      if (sounding.length < Math.max(3, Math.min(required.length, 4))) return;
      // Muted strings should be only at the outside edges, not in the middle.
      let firstSounding = frets.findIndex((f) => f >= 0);
      let lastSounding = 5 - [...frets].reverse().findIndex((f) => f >= 0);
      for (let s = firstSounding; s <= lastSounding; s++) if (frets[s] < 0) return;
      const pcs = new Set(sounding.map(pitchClass));
      for (const r of required) if (!pcs.has(r)) return;
      const bass = sounding[0];
      const rootInBass = pitchClass(bass) === pitchClass(rootPc);
      if (!rootInBass && !allowInversions) return;
      const fretted = frets.filter((f) => f > 0);
      const minF = fretted.length ? Math.min(...fretted) : 0;
      const maxF = fretted.length ? Math.max(...fretted) : 0;
      if (maxF - minF > window) return;
      const fingering = assignFingers(frets);
      if (!fingering) return;
      const key = frets.join(',');
      if (seen.has(key)) return;
      seen.add(key);
      // Open strings trapped between fretted strings are awkward to let ring
      // once the hand is away from the nut.
      let sandwichedOpen = 0;
      for (let s = firstSounding + 1; s < lastSounding; s++) if (frets[s] === 0 && maxF > 4) sandwichedOpen++;
      let score = 0;
      score += sounding.length * 3;
      score -= fingering.count * 2.5;
      score -= minF * 1.2;
      score -= (maxF - minF) * 1.5;
      score -= sandwichedOpen * 3;
      score += rootInBass ? 6 : 0;
      score += pcs.size === chordSet.size ? 4 : 0;
      results.push({ frets: [...frets], fingers: fingering.fingers, barre: fingering.barre, name: fingering.barre ? `Barre (fret ${fingering.barre.fret})` : (maxF <= 4 ? 'Open position' : `Position ${minF}`), score });
    };

    recurse(0);
  }
  results.sort((a, b) => b.score - a.score);
  return results.slice(0, maxResults).map(({ score, ...v }) => v);
}

/**
 * Assign fingers (1..4) to a fret pattern. Detects a barre when two or more
 * strings share the lowest fretted fret and no string between them is lower.
 * Returns null when more than four fingers would be needed.
 */
export function assignFingers(frets) {
  const fingers = new Array(6).fill(0);
  const fretted = frets.map((f, s) => ({ f, s })).filter((x) => x.f > 0);
  if (!fretted.length) return { fingers, count: 0, barre: null };
  const minF = Math.min(...fretted.map((x) => x.f));
  const atMin = fretted.filter((x) => x.f === minF);
  let barre = null;
  let remaining = fretted;
  if (atMin.length >= 2) {
    const from = Math.min(...atMin.map((x) => x.s));
    const to = Math.max(...atMin.map((x) => x.s));
    // A barre is only possible if every string between `from` and `to` is at
    // the barre fret or higher (open strings inside a barre are impossible).
    let ok = true;
    for (let s = from; s <= to; s++) if (frets[s] >= 0 && frets[s] < minF) ok = false;
    if (ok) {
      barre = { fret: minF, from, to };
      for (let s = from; s <= to; s++) if (frets[s] === minF) fingers[s] = 1;
      remaining = fretted.filter((x) => !(x.f === minF && x.s >= from && x.s <= to));
    }
  }
  // Remaining notes: assign fingers in order of fret, then string (low to high).
  remaining.sort((a, b) => a.f - b.f || a.s - b.s);
  let next = barre ? 2 : 1;
  const byFret = new Map();
  for (const x of remaining) {
    // Two strings at the same fret with no barre: separate fingers.
    if (next > 4) return null;
    fingers[x.s] = next++;
    byFret.set(x.f, (byFret.get(x.f) || 0) + 1);
  }
  const count = (barre ? 1 : 0) + remaining.length;
  if (count > 4) return null;
  return { fingers, count, barre };
}

/**
 * Voicings for a chord in the given tuning. Curated shapes are used for
 * standard tuning; other tunings fall back to the generator so every chord
 * is always musically correct for the active tuning.
 */
export function chordVoicings(rootPc, qualityId, openMidi, { maxResults = 4 } = {}) {
  const out = [];
  if (sameTuning(openMidi, STANDARD_OPEN_MIDI)) {
    const key = `${pitchClass(rootPc)}:${qualityId}`;
    for (const v of OPEN_VOICINGS[key] || []) out.push({ ...v, frets: [...v.frets], fingers: [...v.fingers], curated: true });
    // Movable shapes: lowest position first (the familiar 2nd-fret Bm before the 7th-fret one).
    const shapes = [];
    for (const shape of MOVABLE_SHAPES.filter((s) => s.quality === qualityId)) {
      const v = shapeToVoicing(shape, rootPc, openMidi);
      if (v) shapes.push({ ...v, curated: true });
    }
    shapes.sort((a, b) => voicingBaseFret(a) - voicingBaseFret(b) || voicingMaxFret(a) - voicingMaxFret(b));
    out.push(...shapes);
  }
  const seen = new Set(out.map((v) => v.frets.join(',')));
  const valid = out.filter((v) => validateVoicing(v, rootPc, qualityId, openMidi).length === 0);
  if (valid.length < maxResults) {
    for (const v of generateVoicings(rootPc, qualityId, openMidi, { maxResults: maxResults * 2 })) {
      const key = v.frets.join(',');
      if (seen.has(key)) continue;
      seen.add(key);
      valid.push({ ...v, curated: false });
      if (valid.length >= maxResults) break;
    }
  }
  return valid.slice(0, Math.max(maxResults, valid.filter((v) => v.curated).length));
}
