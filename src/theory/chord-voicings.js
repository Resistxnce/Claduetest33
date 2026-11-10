/**
 * Curated chord voicings for standard tuning (E A D G B E).
 *
 * OPEN_VOICINGS: keyed by `${rootPitchClass}:${qualityId}` (C = 0 ... B = 11).
 *   Each entry: { frets:[6], fingers:[6], barre?: {fret, from, to} | [{fret, from, to}, ...], name }
 *   frets/fingers run from string 6 (low E, index 0) to string 1 (high E, index 5).
 *   -1 = muted string, 0 = open string. fingers: 0 = none, 1 index, 2 middle,
 *   3 ring, 4 pinky, 'T' thumb.
 *
 * MOVABLE_SHAPES: closed (barre / jazz) shapes that transpose to any root.
 *   { quality, rootString, frets (relative, -1 muted), fingers,
 *     barre?: {fret: relative, from, to} | [..], name }
 *   Frets are relative to the shape's lowest fretted fret (which is 0).
 *   frets[rootString] is where the root sits inside the shape: 0 for classic
 *   barre forms, > 0 when other strings are fretted below the root (e.g. the
 *   C9 grip x3233x is frets [-1, 1, 0, 1, 1, -1] with rootString 1).
 */

/*
 * Conventions used below:
 *   - Card order is decided by chordVoicings() (chords.js), not by this file
 *     alone: the OPEN_VOICINGS entries of a chord come first, in the order
 *     listed here (most common first); the MOVABLE_SHAPES instances follow,
 *     sorted by position (lowest base fret first, then lowest top fret).
 *     The order of MOVABLE_SHAPES only breaks ties between shapes that land
 *     on the same base fret and top fret.
 *   - The first card of every chord is strummable straight across: it has no
 *     muted string between two sounding strings. A grip that mutes an inner
 *     string (jazz forms with the A string damped, 3x0013, ...) is therefore
 *     never the first OPEN_VOICINGS entry, and as a movable shape it is only
 *     kept when a fully strummable shape always sorts before it (same base
 *     fret and top fret, listed earlier) or the roots where it would lead
 *     have an OPEN_VOICINGS entry.
 *   - One card per fret pattern: chordVoicings() drops any later voicing
 *     that repeats the frets of an earlier one, so each fret pattern is
 *     listed once, with its most conventional fingering.
 *   - A finger that presses more than one string is always declared in `barre`.
 *   - The bass (lowest sounding string) is the chord root unless the voicing
 *     carries `bass: <pitchClass>` (deliberate slash chord, e.g. C/G).
 *   - Pitch classes: C 0, C# 1, D 2, D# 3, E 4, F 5, F# 6, G 7, G# 8, A 9, A# 10, B 11.
 *   - Everything in OPEN_VOICINGS stays below fret 8. A closed voicing that a
 *     MOVABLE_SHAPE already produces for the same root (F barre = E shape at
 *     fret 1, Bm = Am shape at fret 2, C9 x32333 = the A-string 9th shape at
 *     fret 3, fretted power chords, ...) is NOT repeated here. Closed
 *     voicings appear here only when they need an open string (Dadd9
 *     x54230) or are the small four-string form that should lead a chord
 *     whose lowest shape is a jazz grip (F#maj7 xx4321).
 */
export const OPEN_VOICINGS = {
  /* ---------------------------------------------------------------- major */
  '0:maj': [ // C
    { frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0], name: 'Open C' },
    { frets: [3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0], bass: 7, name: 'C/G' },
  ],
  '9:maj': [ // A
    { frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0], name: 'Open A' },
  ],
  '7:maj': [ // G
    { frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, 0, 0, 0, 3], name: 'Open G' },
    { frets: [3, 2, 0, 0, 3, 3], fingers: [2, 1, 0, 0, 3, 4], name: 'Open G (four fingers)' },
  ],
  '4:maj': [ // E
    { frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0], name: 'Open E' },
  ],
  '2:maj': [ // D
    { frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2], name: 'Open D' },
    { frets: [-1, 5, 4, 2, 3, 2], fingers: [0, 4, 3, 1, 2, 1], barre: { fret: 2, from: 3, to: 5 }, name: 'D (five strings)' },
  ],
  '5:maj': [ // F  (the full F barre 133211 is the 'E shape' at fret 1)
    { frets: [-1, -1, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Small F' },
    { frets: [1, -1, 3, 2, 1, 1], fingers: ['T', 0, 3, 2, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'F (thumb bass)' },
  ],
  /* ---------------------------------------------------------------- minor */
  /* Bm x24432 is the 'Am shape' at fret 2 and is not repeated here. */
  '9:min': [ // Am
    { frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0], name: 'Open Am' },
  ],
  '4:min': [ // Em
    { frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0], name: 'Open Em' },
  ],
  '2:min': [ // Dm
    { frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1], name: 'Open Dm' },
  ],
  /* ---------------------------------------------------------- power chords */
  /* Fretted power chords (G5 355xxx, C5 x355xx, A5 577xxx, ...) come from the
   * movable '5' shapes; only forms with open strings live here. The open G5
   * 3x0033 mutes the A string between sounding strings and would be the
   * first G5 card, so G5 is left to the 355xxx shape. */
  '4:5': [ // E5
    { frets: [0, 2, 2, -1, -1, -1], fingers: [0, 1, 3, 0, 0, 0], name: 'E5' },
    { frets: [0, 2, -1, -1, -1, -1], fingers: [0, 1, 0, 0, 0, 0], name: 'E5 (two strings)' },
  ],
  '9:5': [ // A5
    { frets: [-1, 0, 2, 2, -1, -1], fingers: [0, 0, 1, 3, 0, 0], name: 'A5' },
  ],
  '2:5': [ // D5
    { frets: [-1, -1, 0, 2, 3, -1], fingers: [0, 0, 0, 1, 3, 0], name: 'D5' },
  ],
  /* ---------------------------------------------------------- dominant 7th */
  '4:7': [ // E7
    { frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0], name: 'Open E7' },
    { frets: [0, 2, 0, 1, 3, 0], fingers: [0, 2, 0, 1, 3, 0], name: 'Open E7 (D on B string)' },
    { frets: [0, 2, 2, 1, 3, 0], fingers: [0, 2, 3, 1, 4, 0], name: 'Open E7 (full)' },
  ],
  '9:7': [ // A7
    { frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 2, 0, 3, 0], name: 'Open A7' },
    { frets: [-1, 0, 2, 2, 2, 3], fingers: [0, 0, 1, 2, 3, 4], name: 'Open A7 (G on top)' },
  ],
  '2:7': [ // D7
    { frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3], name: 'Open D7' },
  ],
  '7:7': [ // G7
    { frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1], name: 'Open G7' },
  ],
  '0:7': [ // C7
    { frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0], name: 'Open C7' },
  ],
  '11:7': [ // B7
    { frets: [-1, 2, 1, 2, 0, 2], fingers: [0, 2, 1, 3, 0, 4], name: 'Open B7' },
  ],
  /* ------------------------------------------------------------- major 7th */
  '0:maj7': [ // Cmaj7
    { frets: [-1, 3, 2, 0, 0, 0], fingers: [0, 3, 2, 0, 0, 0], name: 'Open Cmaj7' },
  ],
  '9:maj7': [ // Amaj7
    { frets: [-1, 0, 2, 1, 2, 0], fingers: [0, 0, 2, 1, 3, 0], name: 'Open Amaj7' },
  ],
  '2:maj7': [ // Dmaj7
    { frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1], barre: { fret: 2, from: 3, to: 5 }, name: 'Open Dmaj7' },
  ],
  '4:maj7': [ // Emaj7
    { frets: [0, 2, 1, 1, 0, 0], fingers: [0, 3, 1, 2, 0, 0], name: 'Open Emaj7' },
  ],
  '5:maj7': [ // Fmaj7
    { frets: [-1, -1, 3, 2, 1, 0], fingers: [0, 0, 3, 2, 1, 0], name: 'Fmaj7' },
    { frets: [1, -1, 3, 2, 1, 0], fingers: ['T', 0, 3, 2, 1, 0], name: 'Fmaj7 (thumb bass)' },
  ],
  '7:maj7': [ // Gmaj7
    { frets: [3, 2, 0, 0, 0, 2], fingers: [3, 2, 0, 0, 0, 1], name: 'Open Gmaj7' },
    { frets: [-1, -1, 5, 4, 3, 2], fingers: [0, 0, 4, 3, 2, 1], name: 'Gmaj7 (four strings)' },
  ],
  /* The Fmaj7 form xx3210 one and three frets up. Listed per root (not as a
   * movable shape) so that it leads F#maj7 and G#maj7, whose lowest shape is
   * the jazz grip with the A string muted (2x332x). */
  '6:maj7': [ // F#maj7
    { frets: [-1, -1, 4, 3, 2, 1], fingers: [0, 0, 4, 3, 2, 1], name: 'F#maj7 (four strings)' },
  ],
  '8:maj7': [ // G#maj7
    { frets: [-1, -1, 6, 5, 4, 3], fingers: [0, 0, 4, 3, 2, 1], name: 'G#maj7 (four strings)' },
  ],
  /* ------------------------------------------------------------- minor 7th */
  '9:m7': [ // Am7
    { frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0], name: 'Open Am7' },
    { frets: [-1, 0, 2, 0, 1, 3], fingers: [0, 0, 2, 0, 1, 3], name: 'Open Am7 (G on top)' },
  ],
  '4:m7': [ // Em7
    { frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0], name: 'Open Em7' },
    { frets: [0, 2, 2, 0, 3, 0], fingers: [0, 2, 3, 0, 4, 0], name: 'Open Em7 (D on B string)' },
    { frets: [0, 2, 2, 0, 3, 3], fingers: [0, 1, 2, 0, 3, 4], name: 'Open Em7 (full)' },
  ],
  '2:m7': [ // Dm7
    { frets: [-1, -1, 0, 2, 1, 1], fingers: [0, 0, 0, 2, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Open Dm7' },
  ],
  '11:m7': [ // Bm7
    { frets: [-1, 2, 0, 2, 0, 2], fingers: [0, 1, 0, 2, 0, 3], name: 'Open Bm7' },
  ],
  /* -------------------------------------------------------------- sus2 */
  '9:sus2': [ // Asus2
    { frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0], name: 'Open Asus2' },
  ],
  '2:sus2': [ // Dsus2
    { frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 3, 0], name: 'Open Dsus2' },
  ],
  '4:sus2': [ // Esus2
    { frets: [0, 2, 4, 4, 0, 0], fingers: [0, 1, 3, 4, 0, 0], name: 'Open Esus2' },
  ],
  '7:sus2': [ // Gsus2
    { frets: [3, 0, 0, 0, 3, 3], fingers: [2, 0, 0, 0, 3, 4], name: 'Open Gsus2' },
  ],
  '0:sus2': [ // Csus2
    { frets: [-1, 3, 0, 0, 1, 3], fingers: [0, 2, 0, 0, 1, 3], name: 'Open Csus2' },
  ],
  '5:sus2': [ // Fsus2
    { frets: [-1, -1, 3, 0, 1, 1], fingers: [0, 0, 3, 0, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Open Fsus2' },
  ],
  /* -------------------------------------------------------------- sus4 */
  '9:sus4': [ // Asus4
    { frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 4, 0], name: 'Open Asus4' },
  ],
  '2:sus4': [ // Dsus4
    { frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 3, 4], name: 'Open Dsus4' },
  ],
  '4:sus4': [ // Esus4
    { frets: [0, 2, 2, 2, 0, 0], fingers: [0, 2, 3, 4, 0, 0], name: 'Open Esus4' },
  ],
  '7:sus4': [ // Gsus4
    { frets: [3, 3, 0, 0, 1, 3], fingers: [2, 3, 0, 0, 1, 4], name: 'Open Gsus4' },
    { frets: [3, -1, 0, 0, 1, 3], fingers: [2, 0, 0, 0, 1, 3], name: 'Open Gsus4 (A muted)' },
  ],
  '0:sus4': [ // Csus4
    { frets: [-1, 3, 3, 0, 1, 1], fingers: [0, 3, 4, 0, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Open Csus4' },
  ],
  '5:sus4': [ // Fsus4  (the full barre 133311 is the 'Esus4 shape' at fret 1)
    { frets: [-1, -1, 3, 3, 1, 1], fingers: [0, 0, 3, 4, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Small Fsus4' },
  ],
  /* -------------------------------------------------------------- 7sus4 */
  '4:7sus4': [ // E7sus4
    { frets: [0, 2, 0, 2, 0, 0], fingers: [0, 2, 0, 3, 0, 0], name: 'Open E7sus4' },
  ],
  '9:7sus4': [ // A7sus4
    { frets: [-1, 0, 2, 0, 3, 0], fingers: [0, 0, 2, 0, 3, 0], name: 'Open A7sus4' },
  ],
  '2:7sus4': [ // D7sus4
    { frets: [-1, -1, 0, 2, 1, 3], fingers: [0, 0, 0, 2, 1, 3], name: 'Open D7sus4' },
  ],
  '7:7sus4': [ // G7sus4
    { frets: [3, 3, 0, 0, 1, 1], fingers: [2, 3, 0, 0, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Open G7sus4' },
    { frets: [3, -1, 0, 0, 1, 1], fingers: [2, 0, 0, 0, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Open G7sus4 (A muted)' },
  ],
  /* -------------------------------------------------------------- add9 */
  '0:add9': [ // Cadd9
    { frets: [-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0], name: 'Open Cadd9' },
    { frets: [-1, 3, 2, 0, 3, 3], fingers: [0, 2, 1, 0, 3, 4], name: 'Open Cadd9 (G on top)' },
  ],
  '7:add9': [ // Gadd9
    { frets: [3, 2, 0, 2, 0, 3], fingers: [3, 1, 0, 2, 0, 4], name: 'Open Gadd9' },
    { frets: [3, -1, 0, 2, 0, 3], fingers: [2, 0, 0, 1, 0, 3], name: 'Open Gadd9 (A muted)' },
    { frets: [3, 0, 0, 2, 0, 3], fingers: [2, 0, 0, 1, 0, 3], name: 'Open Gadd9 (open A)' },
  ],
  '4:add9': [ // Eadd9
    { frets: [0, 2, 2, 1, 0, 2], fingers: [0, 2, 3, 1, 0, 4], name: 'Open Eadd9' },
  ],
  '9:add9': [ // Aadd9
    { frets: [-1, 0, 2, 4, 2, 0], fingers: [0, 0, 1, 3, 2, 0], name: 'Open Aadd9' },
  ],
  '2:add9': [ // Dadd9
    { frets: [-1, 5, 4, 2, 3, 0], fingers: [0, 4, 3, 1, 2, 0], name: 'Dadd9 (open E on top)' },
  ],
  /* -------------------------------------------------------------- 6th */
  '7:6': [ // G6
    { frets: [3, 2, 0, 0, 0, 0], fingers: [2, 1, 0, 0, 0, 0], name: 'Open G6' },
    { frets: [3, 2, 2, 0, 0, 0], fingers: [3, 1, 2, 0, 0, 0], name: 'Open G6 (E on D string)' },
  ],
  '9:6': [ // A6
    { frets: [-1, 0, 2, 2, 2, 2], fingers: [0, 0, 1, 1, 1, 1], barre: { fret: 2, from: 2, to: 5 }, name: 'Open A6' },
  ],
  '4:6': [ // E6
    { frets: [0, 2, 2, 1, 2, 0], fingers: [0, 2, 3, 1, 4, 0], name: 'Open E6' },
  ],
  '0:6': [ // C6
    { frets: [-1, 3, 2, 2, 1, 0], fingers: [0, 4, 2, 3, 1, 0], name: 'Open C6' },
  ],
  '2:6': [ // D6
    { frets: [-1, -1, 0, 2, 0, 2], fingers: [0, 0, 0, 1, 0, 2], name: 'Open D6' },
  ],
  /* -------------------------------------------------------------- m6 */
  '4:m6': [ // Em6
    { frets: [0, 2, 2, 0, 2, 0], fingers: [0, 1, 2, 0, 3, 0], name: 'Open Em6' },
  ],
  '9:m6': [ // Am6
    { frets: [-1, 0, 2, 2, 1, 2], fingers: [0, 0, 2, 3, 1, 4], name: 'Open Am6' },
  ],
  '2:m6': [ // Dm6
    { frets: [-1, -1, 0, 2, 0, 1], fingers: [0, 0, 0, 2, 0, 1], name: 'Open Dm6' },
  ],
  /* -------------------------------------------------------------- dim */
  '9:dim': [ // Adim
    { frets: [-1, 0, 1, 2, 1, -1], fingers: [0, 0, 1, 3, 2, 0], name: 'Open Adim' },
  ],
  '4:dim': [ // Edim  (xx2353 is the 'D-string root' shape at fret 2)
    { frets: [0, 1, 2, 0, -1, -1], fingers: [0, 1, 2, 0, 0, 0], name: 'Open Edim' },
  ],
  '2:dim': [ // Ddim
    { frets: [-1, -1, 0, 1, 3, 1], fingers: [0, 0, 0, 1, 3, 2], name: 'Open Ddim' },
  ],
  /* -------------------------------------------------------------- dim7 */
  '2:dim7': [ // Ddim7
    { frets: [-1, -1, 0, 1, 0, 1], fingers: [0, 0, 0, 1, 0, 2], name: 'Open Ddim7' },
  ],
  '4:dim7': [ // Edim7  (xx2323 is the 'D-string root' shape at fret 2)
    { frets: [0, 1, 2, 0, 2, 0], fingers: [0, 1, 2, 0, 3, 0], name: 'Open Edim7' },
  ],
  '9:dim7': [ // Adim7
    { frets: [-1, 0, 1, 2, 1, 2], fingers: [0, 0, 1, 3, 2, 4], name: 'Open Adim7' },
  ],
  '10:dim7': [ // A#dim7  (the A-string shape x2313x one fret down: its G string is open)
    { frets: [-1, 1, 2, 0, 2, 0], fingers: [0, 1, 2, 0, 3, 0], name: 'Open A#dim7' },
  ],
  /* -------------------------------------------------------------- m7b5 */
  '2:m7b5': [ // Dm7b5
    { frets: [-1, -1, 0, 1, 1, 1], fingers: [0, 0, 0, 1, 1, 1], barre: { fret: 1, from: 3, to: 5 }, name: 'Open Dm7♭5' },
  ],
  /* -------------------------------------------------------------- aug */
  '0:aug': [ // Caug
    { frets: [-1, 3, 2, 1, 1, 0], fingers: [0, 3, 2, 1, 1, 0], barre: { fret: 1, from: 3, to: 4 }, name: 'Open Caug' },
  ],
  '4:aug': [ // Eaug
    { frets: [0, 3, 2, 1, 1, 0], fingers: [0, 3, 2, 1, 1, 0], barre: { fret: 1, from: 3, to: 4 }, name: 'Open Eaug' },
  ],
  '9:aug': [ // Aaug
    { frets: [-1, 0, 3, 2, 2, 1], fingers: [0, 0, 4, 3, 2, 1], name: 'Open Aaug' },
  ],
  '2:aug': [ // Daug
    { frets: [-1, -1, 0, 3, 3, 2], fingers: [0, 0, 0, 2, 3, 1], name: 'Open Daug' },
  ],
  '7:aug': [ // Gaug
    { frets: [3, 2, 1, 0, 0, 3], fingers: [3, 2, 1, 0, 0, 4], name: 'Open Gaug' },
  ],
  /* -------------------------------------------------------------- 9th */
  /* C9 x32333, D9 x54555, B9 x21222 ... are the 'A-string root' shape and are
   * not repeated here. */
  '9:9': [ // A9
    { frets: [-1, 0, 2, 4, 2, 3], fingers: [0, 0, 1, 3, 1, 2], barre: { fret: 2, from: 2, to: 4 }, name: 'Open A9' },
  ],
  '4:9': [ // E9
    { frets: [0, 2, 0, 1, 0, 2], fingers: [0, 2, 0, 1, 0, 3], name: 'Open E9' },
  ],
  '7:9': [ // G9
    { frets: [3, 2, 0, 2, 0, 1], fingers: [4, 2, 0, 3, 0, 1], name: 'Open G9' },
  ],
  /* -------------------------------------------------------------- maj9 */
  '0:maj9': [ // Cmaj9
    { frets: [-1, 3, 2, 4, 3, 0], fingers: [0, 2, 1, 4, 3, 0], name: 'Open Cmaj9' },
    { frets: [-1, 3, 0, 0, 0, 0], fingers: [0, 1, 0, 0, 0, 0], name: 'Open Cmaj9 (one finger)' },
  ],
  '4:maj9': [ // Emaj9
    { frets: [0, 2, 1, 1, 0, 2], fingers: [0, 3, 1, 2, 0, 4], name: 'Open Emaj9' },
  ],
  '9:maj9': [ // Amaj9
    { frets: [-1, 0, 2, 4, 2, 4], fingers: [0, 0, 1, 3, 2, 4], name: 'Open Amaj9' },
  ],
  '5:maj9': [ // Fmaj9  (Am7 x02010 over an F bass)
    { frets: [1, 0, 2, 0, 1, 0], fingers: [1, 0, 3, 0, 2, 0], name: 'Open Fmaj9' },
  ],
  /* -------------------------------------------------------------- m9 */
  '4:m9': [ // Em9
    { frets: [0, 2, 2, 0, 3, 2], fingers: [0, 1, 2, 0, 4, 3], name: 'Open Em9' },
    { frets: [0, 2, 0, 0, 0, 2], fingers: [0, 2, 0, 0, 0, 3], name: 'Open Em9 (Em7 shape)' },
  ],
  '9:m9': [ // Am9
    { frets: [-1, 0, 2, 4, 1, 3], fingers: [0, 0, 2, 4, 1, 3], name: 'Open Am9' },
    { frets: [-1, 0, 5, 5, 0, 0], fingers: [0, 0, 1, 1, 0, 0], barre: { fret: 5, from: 2, to: 3 }, name: 'Am9 (open B and E)' },
  ],
  /* Cm9 x31333, Dm9 x53555 ... are the 'A-string root' shape; for B its D
   * string is open, which a closed shape cannot be. */
  '11:m9': [ // Bm9
    { frets: [-1, 2, 0, 2, 2, 2], fingers: [0, 1, 0, 2, 3, 4], name: 'Open Bm9' },
  ],
};

/*
 * Movable shapes. Relative frets: 0 = the lowest fretted fret of the shape,
 * n = n frets above it, -1 = muted. The root is at frets[rootString]: 0 for
 * the barre forms, more when another string is fretted below the root.
 * Names are unique within a quality (chordVoicings copies the name into each
 * instantiated voicing).
 *
 * chordVoicings() sorts the instances of a chord by position, so the order
 * below only decides ties (same base fret and same top fret). It matters in
 * one case: a grip that mutes an inner string must come AFTER a fully
 * strummable shape that lands on the same frets (m6, 6, aug), otherwise the
 * muted grip would be the first card.
 *
 * Interval (semitones above the root) of each string at the SAME fret as a
 * root on:
 *   string 0 (E): [0, 5, 10, 3, 7, 0]
 *   string 1 (A): [7, 0, 5, 10, 2, 7]
 *   string 2 (D): [2, 7, 0, 5, 9, 2]
 */
export const MOVABLE_SHAPES = [
  /* ---------------------------------------------------------------- major */
  { quality: 'maj', rootString: 0, frets: [0, 2, 2, 1, 0, 0], fingers: [1, 3, 4, 2, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'E shape' },
  { quality: 'maj', rootString: 1, frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 1, 3, 3, 3, 1], barre: [{ fret: 0, from: 1, to: 5 }, { fret: 2, from: 2, to: 4 }], name: 'A shape' },
  { quality: 'maj', rootString: 1, frets: [-1, 0, 2, 2, 2, -1], fingers: [0, 1, 2, 3, 4, 0], name: 'A shape (four strings)' },
  { quality: 'maj', rootString: 2, frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 1, 2, 4, 3], name: 'D shape' },
  /* ---------------------------------------------------------------- minor */
  { quality: 'min', rootString: 0, frets: [0, 2, 2, 0, 0, 0], fingers: [1, 3, 4, 1, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Em shape' },
  { quality: 'min', rootString: 1, frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 1, 3, 4, 2, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Am shape' },
  { quality: 'min', rootString: 2, frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 1, 3, 4, 2], name: 'Dm shape' },
  /* ---------------------------------------------------------- power chords */
  { quality: '5', rootString: 0, frets: [0, 2, 2, -1, -1, -1], fingers: [1, 3, 4, 0, 0, 0], name: 'E-string root' },
  { quality: '5', rootString: 0, frets: [0, 2, -1, -1, -1, -1], fingers: [1, 3, 0, 0, 0, 0], name: 'E-string root (two strings)' },
  { quality: '5', rootString: 1, frets: [-1, 0, 2, 2, -1, -1], fingers: [0, 1, 3, 4, 0, 0], name: 'A-string root' },
  { quality: '5', rootString: 1, frets: [-1, 0, 2, -1, -1, -1], fingers: [0, 1, 3, 0, 0, 0], name: 'A-string root (two strings)' },
  { quality: '5', rootString: 2, frets: [-1, -1, 0, 2, 3, -1], fingers: [0, 0, 1, 3, 4, 0], name: 'D-string root' },
  /* ---------------------------------------------------------- dominant 7th */
  { quality: '7', rootString: 0, frets: [0, 2, 0, 1, 0, 0], fingers: [1, 3, 1, 2, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'E7 shape' },
  { quality: '7', rootString: 0, frets: [0, 2, 0, 1, 3, 0], fingers: [1, 3, 1, 2, 4, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'E7 shape (7th on B string)' },
  { quality: '7', rootString: 1, frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 1, 3, 1, 4, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'A7 shape' },
  { quality: '7', rootString: 1, frets: [-1, 0, 2, 0, 2, -1], fingers: [0, 1, 3, 1, 4, 0], barre: { fret: 0, from: 1, to: 3 }, name: 'A7 shape (four strings)' },
  { quality: '7', rootString: 2, frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 1, 3, 2, 4], name: 'D7 shape' },
  /* ------------------------------------------------------------- major 7th */
  { quality: 'maj7', rootString: 0, frets: [0, -1, 1, 1, 0, -1], fingers: [1, 0, 3, 4, 2, 0], name: 'E-string root (jazz)' },
  { quality: 'maj7', rootString: 0, frets: [0, 2, 1, 1, 0, 0], fingers: [1, 4, 2, 3, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Emaj7 shape' },
  { quality: 'maj7', rootString: 1, frets: [-1, 0, 2, 1, 2, -1], fingers: [0, 1, 3, 2, 4, 0], name: 'A-string root (jazz)' },
  { quality: 'maj7', rootString: 1, frets: [-1, 0, 2, 1, 2, 0], fingers: [0, 1, 3, 2, 4, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Amaj7 shape' },
  { quality: 'maj7', rootString: 2, frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 1, 3, 3, 3], barre: { fret: 2, from: 3, to: 5 }, name: 'Dmaj7 shape' },
  /* ------------------------------------------------------------- minor 7th */
  /* The jazz grips with the A string muted (F7 1x121x, Fm7 1x111x) are not
   * offered for 7 and m7: they sit on the same base fret as the full barre
   * with a lower top fret, so they would be the first card for F, F#, G and
   * G#, and no open-string form exists to lead those chords instead. */
  { quality: 'm7', rootString: 0, frets: [0, 2, 0, 0, 0, 0], fingers: [1, 3, 1, 1, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Em7 shape' },
  { quality: 'm7', rootString: 1, frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 1, 3, 1, 2, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Am7 shape' },
  { quality: 'm7', rootString: 1, frets: [-1, 0, 2, 0, 1, -1], fingers: [0, 1, 3, 1, 2, 0], barre: { fret: 0, from: 1, to: 3 }, name: 'A-string root (jazz)' },
  { quality: 'm7', rootString: 2, frets: [-1, -1, 0, 2, 1, 1], fingers: [0, 0, 1, 3, 2, 2], barre: { fret: 1, from: 4, to: 5 }, name: 'Dm7 shape' },
  /* -------------------------------------------------------------- sus2 */
  /* The full Esus2 barre needs a four-fret stretch over an index barre. On a
   * tie (same base fret and top fret) the three-string form is listed first;
   * everything else is ordered by position at runtime. The Fsus2 shape is
   * the open xx3011 moved up (F#sus2 xx4122, G#sus2 xx6344). */
  { quality: 'sus2', rootString: 1, frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 1, 3, 4, 1, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Asus2 shape' },
  { quality: 'sus2', rootString: 0, frets: [0, 2, 4, -1, -1, -1], fingers: [1, 2, 4, 0, 0, 0], name: 'E-string root (three strings)' },
  { quality: 'sus2', rootString: 2, frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 1, 2, 3, 1], barre: { fret: 0, from: 2, to: 5 }, name: 'Dsus2 shape' },
  { quality: 'sus2', rootString: 2, frets: [-1, -1, 3, 0, 1, 1], fingers: [0, 0, 4, 1, 2, 3], name: 'Fsus2 shape' },
  { quality: 'sus2', rootString: 0, frets: [0, 2, 4, 4, 0, 0], fingers: [1, 2, 3, 4, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Esus2 shape' },
  /* -------------------------------------------------------------- sus4 */
  { quality: 'sus4', rootString: 0, frets: [0, 2, 2, 2, 0, 0], fingers: [1, 2, 3, 4, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Esus4 shape' },
  { quality: 'sus4', rootString: 1, frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 1, 2, 3, 4, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Asus4 shape' },
  { quality: 'sus4', rootString: 2, frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 1, 2, 3, 4], name: 'Dsus4 shape' },
  /* -------------------------------------------------------------- 7sus4 */
  { quality: '7sus4', rootString: 0, frets: [0, 2, 0, 2, 0, 0], fingers: [1, 3, 1, 4, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'E7sus4 shape' },
  { quality: '7sus4', rootString: 1, frets: [-1, 0, 2, 0, 3, 0], fingers: [0, 1, 3, 1, 4, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'A7sus4 shape' },
  { quality: '7sus4', rootString: 2, frets: [-1, -1, 0, 2, 1, 3], fingers: [0, 0, 1, 3, 2, 4], name: 'D7sus4 shape' },
  /* -------------------------------------------------------------- dim */
  { quality: 'dim', rootString: 0, frets: [0, 1, 2, 0, -1, -1], fingers: [1, 2, 3, 1, 0, 0], barre: { fret: 0, from: 0, to: 3 }, name: 'E-string root' },
  { quality: 'dim', rootString: 1, frets: [-1, 0, 1, 2, 1, -1], fingers: [0, 1, 2, 4, 3, 0], name: 'A-string root' },
  { quality: 'dim', rootString: 2, frets: [-1, -1, 0, 1, 3, 1], fingers: [0, 0, 1, 2, 4, 3], name: 'D-string root' },
  /* -------------------------------------------------------------- dim7 */
  { quality: 'dim7', rootString: 0, frets: [0, 1, 2, 0, 2, 0], fingers: [1, 2, 3, 1, 4, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'E-string root' },
  /* The usual A-string dim7 (Bdim7 x2313x, Cdim7 x3424x): the G string is one
   * fret below the root. The E-string jazz form (F#dim7 2x121x) mutes the A
   * string and would be the first card for F#, G and G#, so it is left out. */
  { quality: 'dim7', rootString: 1, frets: [-1, 1, 2, 0, 2, -1], fingers: [0, 2, 3, 1, 4, 0], name: 'A-string root' },
  { quality: 'dim7', rootString: 2, frets: [-1, -1, 0, 1, 0, 1], fingers: [0, 0, 1, 3, 2, 4], name: 'D-string root' },
  /* -------------------------------------------------------------- m7b5 */
  { quality: 'm7b5', rootString: 0, frets: [0, 1, 0, 0, -1, -1], fingers: [1, 2, 1, 1, 0, 0], barre: { fret: 0, from: 0, to: 3 }, name: 'E-string root' },
  { quality: 'm7b5', rootString: 0, frets: [0, 1, 0, 0, 3, -1], fingers: [1, 2, 1, 1, 4, 0], barre: { fret: 0, from: 0, to: 3 }, name: 'E-string root (five strings)' },
  { quality: 'm7b5', rootString: 1, frets: [-1, 0, 1, 0, 1, -1], fingers: [0, 1, 3, 2, 4, 0], name: 'A-string root' },
  { quality: 'm7b5', rootString: 2, frets: [-1, -1, 0, 1, 1, 1], fingers: [0, 0, 1, 3, 3, 3], barre: { fret: 1, from: 3, to: 5 }, name: 'D-string root' },
  /* -------------------------------------------------------------- aug */
  /* Faug shape = xx3221, Gaug shape = 32100x closed (G#aug 43211x), Caug
   * shape = x3211x, Daug shape = xx0332 closed (D#aug xx1443). The Faug shape
   * and the E-string jazz grip (1x322x) always share base and top fret, so
   * the fully strummable Faug shape is listed first. */
  { quality: 'aug', rootString: 2, frets: [-1, -1, 2, 1, 1, 0], fingers: [0, 0, 4, 2, 3, 1], name: 'Faug shape' },
  { quality: 'aug', rootString: 0, frets: [0, -1, 2, 1, 1, -1], fingers: [1, 0, 4, 2, 3, 0], name: 'E-string root' },
  { quality: 'aug', rootString: 0, frets: [0, 3, 2, 1, -1, -1], fingers: [1, 4, 3, 2, 0, 0], name: 'E-string root (low)' },
  { quality: 'aug', rootString: 0, frets: [3, 2, 1, 0, 0, -1], fingers: [4, 3, 2, 1, 1, 0], barre: { fret: 0, from: 3, to: 4 }, name: 'Gaug shape' },
  { quality: 'aug', rootString: 1, frets: [-1, 2, 1, 0, 0, -1], fingers: [0, 3, 2, 1, 1, 0], barre: { fret: 0, from: 3, to: 4 }, name: 'Caug shape' },
  { quality: 'aug', rootString: 1, frets: [-1, 0, 3, 2, 2, -1], fingers: [0, 1, 4, 2, 3, 0], name: 'A-string root' },
  { quality: 'aug', rootString: 2, frets: [-1, -1, 0, 3, 3, 2], fingers: [0, 0, 1, 3, 4, 2], name: 'Daug shape' },
  /* -------------------------------------------------------------- 6th */
  /* F6 shape = xx3231. It always shares base and top fret with the E-string
   * jazz grip (1x323x), so the fully strummable F6 shape is listed first;
   * likewise the A6 shape before the grip with the D string muted. */
  { quality: '6', rootString: 2, frets: [-1, -1, 2, 1, 2, 0], fingers: [0, 0, 3, 2, 4, 1], name: 'F6 shape' },
  { quality: '6', rootString: 0, frets: [0, -1, 2, 1, 2, -1], fingers: [1, 0, 3, 2, 4, 0], name: 'E-string root' },
  { quality: '6', rootString: 1, frets: [-1, 0, 2, 2, 2, 2], fingers: [0, 1, 3, 3, 3, 3], barre: { fret: 2, from: 2, to: 5 }, name: 'A6 shape' },
  { quality: '6', rootString: 1, frets: [-1, 0, -1, 2, 2, 2], fingers: [0, 1, 0, 2, 3, 4], name: 'A-string root (D muted)' },
  { quality: '6', rootString: 2, frets: [-1, -1, 0, 2, 0, 2], fingers: [0, 0, 1, 2, 1, 3], barre: { fret: 0, from: 2, to: 4 }, name: 'D6 shape' },
  /* -------------------------------------------------------------- m6 */
  /* Each barre form is listed before the jazz grip that shares its frets. */
  { quality: 'm6', rootString: 0, frets: [0, 2, 2, 0, 2, 0], fingers: [1, 2, 3, 1, 4, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Em6 shape' },
  { quality: 'm6', rootString: 0, frets: [0, -1, 2, 0, 2, -1], fingers: [1, 0, 3, 2, 4, 0], name: 'E-string root (jazz)' },
  { quality: 'm6', rootString: 1, frets: [-1, 0, 2, 2, 1, 2], fingers: [0, 1, 3, 3, 2, 4], barre: { fret: 2, from: 2, to: 3 }, name: 'Am6 shape' },
  { quality: 'm6', rootString: 1, frets: [-1, 0, -1, 2, 1, 2], fingers: [0, 1, 0, 3, 2, 4], name: 'A-string root (jazz)' },
  { quality: 'm6', rootString: 2, frets: [-1, -1, 0, 2, 0, 1], fingers: [0, 0, 1, 3, 1, 2], barre: { fret: 0, from: 2, to: 4 }, name: 'Dm6 shape' },
  /* -------------------------------------------------------------- add9 */
  /* Cadd9 shape = the open x3203x closed (C#add9 x4314x, Dadd9 x5425x). */
  { quality: 'add9', rootString: 0, frets: [0, 2, 2, 1, 0, 2], fingers: [1, 3, 3, 2, 1, 4], barre: [{ fret: 0, from: 0, to: 5 }, { fret: 2, from: 1, to: 2 }], name: 'Eadd9 shape' },
  { quality: 'add9', rootString: 1, frets: [-1, 3, 2, 0, 3, -1], fingers: [0, 3, 2, 1, 4, 0], name: 'Cadd9 shape' },
  { quality: 'add9', rootString: 1, frets: [-1, 0, 2, 4, 2, -1], fingers: [0, 1, 2, 4, 3, 0], name: 'A-string root' },
  { quality: 'add9', rootString: 1, frets: [-1, 0, 2, 4, 2, 0], fingers: [0, 1, 2, 4, 3, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'A-string root (five strings)' },
  /* -------------------------------------------------------------- 9th */
  /* The chord-book 9th has its 3rd one fret BELOW the root:
   *   A-string root: C9 x32333 (B9 x21222, D9 x54555), or x3233x without the 5th;
   *   E-string root: G9 32323x (root, 3rd, b7, 9th, 5th; index barres A to G).
   * The open A9 (x02423) only works because the open A frees the index to
   * barre the D and B strings; moved up the neck that barre would fall to the
   * middle finger, so the five-string A9 form is not offered as a shape. */
  { quality: '9', rootString: 0, frets: [0, 2, 0, 1, 0, 2], fingers: [1, 3, 1, 2, 1, 4], barre: { fret: 0, from: 0, to: 5 }, name: 'E9 shape' },
  { quality: '9', rootString: 0, frets: [1, 0, 1, 0, 1, -1], fingers: [2, 1, 3, 1, 4, 0], barre: { fret: 0, from: 1, to: 3 }, name: 'E-string root (five strings)' },
  { quality: '9', rootString: 1, frets: [-1, 1, 0, 1, 1, 1], fingers: [0, 2, 1, 3, 3, 3], barre: { fret: 1, from: 3, to: 5 }, name: 'A-string root' },
  { quality: '9', rootString: 1, frets: [-1, 1, 0, 1, 1, -1], fingers: [0, 2, 1, 3, 3, 0], barre: { fret: 1, from: 3, to: 4 }, name: 'A-string root (four strings)' },
  /* -------------------------------------------------------------- maj9 */
  /* A-string root: Cmaj9 x3243x, or x32433 with the 5th on top. E-string
   * root: Gmaj9 32423x (five strings) and the jazz grip 3x4435 with the A
   * string muted, which never leads: F and A have open forms, F#, G and G#
   * get the five-string shape first. */
  { quality: 'maj9', rootString: 0, frets: [1, 0, 2, 0, 1, -1], fingers: [2, 1, 4, 1, 3, 0], barre: { fret: 0, from: 1, to: 3 }, name: 'E-string root (five strings)' },
  { quality: 'maj9', rootString: 0, frets: [0, -1, 1, 1, 0, 2], fingers: [1, 0, 3, 3, 2, 4], barre: { fret: 1, from: 2, to: 3 }, name: 'E-string root (A muted)' },
  { quality: 'maj9', rootString: 1, frets: [-1, 1, 0, 2, 1, -1], fingers: [0, 2, 1, 4, 3, 0], name: 'A-string root' },
  { quality: 'maj9', rootString: 1, frets: [-1, 1, 0, 2, 1, 1], fingers: [0, 2, 1, 4, 3, 3], barre: { fret: 1, from: 4, to: 5 }, name: 'A-string root (five strings)' },
  /* -------------------------------------------------------------- m9 */
  /* A-string root: Cm9 x31333 (or x3133x). E-string root: the Em9 barre
   * (Fm9 131113) and the four-string 6465xx (A#m9: root, b3, b7, 9th). */
  { quality: 'm9', rootString: 0, frets: [0, 2, 0, 0, 0, 2], fingers: [1, 3, 1, 1, 1, 4], barre: { fret: 0, from: 0, to: 5 }, name: 'Em9 shape' },
  { quality: 'm9', rootString: 0, frets: [2, 0, 2, 1, -1, -1], fingers: [3, 1, 4, 2, 0, 0], name: 'E-string root (four strings)' },
  { quality: 'm9', rootString: 1, frets: [-1, 2, 0, 2, 2, 2], fingers: [0, 2, 1, 3, 3, 3], barre: { fret: 2, from: 3, to: 5 }, name: 'A-string root' },
  { quality: 'm9', rootString: 1, frets: [-1, 2, 0, 2, 2, -1], fingers: [0, 2, 1, 3, 3, 0], barre: { fret: 2, from: 3, to: 4 }, name: 'A-string root (four strings)' },
];
