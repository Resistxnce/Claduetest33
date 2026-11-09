/**
 * Curated chord voicings for standard tuning (E A D G B E).
 *
 * OPEN_VOICINGS: keyed by `${rootPitchClass}:${qualityId}` (C = 0 ... B = 11).
 *   Each entry: { frets:[6], fingers:[6], barre?: {fret, from, to}, name }
 *   frets/fingers run from string 6 (low E, index 0) to string 1 (high E, index 5).
 *   -1 = muted string, 0 = open string. fingers: 0 = none, 1 index, 2 middle,
 *   3 ring, 4 pinky, 'T' thumb.
 *
 * MOVABLE_SHAPES: barre/closed shapes relative to the root fret.
 *   { quality, rootString, frets (relative to root fret, -1 muted), fingers, barre?: {fret: relative, from, to}, name }
 *
 * This file is validated by tests/chords.test.js against the chord formulas.
 */
export const OPEN_VOICINGS = {};

export const MOVABLE_SHAPES = [];
