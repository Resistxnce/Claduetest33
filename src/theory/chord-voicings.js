/**
 * Curated chord voicings for standard tuning (E A D G B E).
 *
 * OPEN_VOICINGS: keyed by `${rootPitchClass}:${qualityId}` (C = 0 ... B = 11).
 *   Each entry: { frets:[6], fingers:[6], barre?: {fret, from, to} | [{fret, from, to}, ...], name }
 *   frets/fingers run from string 6 (low E, index 0) to string 1 (high E, index 5).
 *   -1 = muted string, 0 = open string. fingers: 0 = none, 1 index, 2 middle,
 *   3 ring, 4 pinky, 'T' thumb.
 *
 * MOVABLE_SHAPES: barre/closed shapes relative to the root fret.
 *   { quality, rootString, frets (relative to root fret, -1 muted), fingers,
 *     barre?: {fret: relative, from, to} | [..], name }
 *   The root string's relative fret is 0; the shape is placed so that string
 *   sounds the chord root. Relative frets below 0 are not allowed.
 *
 * This file is validated by tests/chords.test.js against the chord formulas.
 */

/*
 * Conventions used below:
 *   - Voicings are listed most common first.
 *   - A finger that presses more than one string is always declared in `barre`.
 *   - The bass (lowest sounding string) is the chord root unless the voicing
 *     carries `bass: <pitchClass>` (deliberate slash chord, e.g. C/G).
 *   - Pitch classes: C 0, C# 1, D 2, D# 3, E 4, F 5, F# 6, G 7, G# 8, A 9, A# 10, B 11.
 */
export const OPEN_VOICINGS = {
  /* ---------------------------------------------------------------- major */
  '0:maj': [ // C
    { frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0], name: 'Open C' },
    { frets: [3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0], bass: 7, name: 'C/G' },
  ],
  '9:maj': [ // A
    { frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0], name: 'Open A' },
    { frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 1, 1, 0], barre: { fret: 2, from: 2, to: 4 }, name: 'Open A (index barre)' },
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
  '5:maj': [ // F
    { frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: { fret: 1, from: 0, to: 5 }, name: 'F barre' },
    { frets: [-1, -1, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'Small F' },
    { frets: [1, -1, 3, 2, 1, 1], fingers: ['T', 0, 3, 2, 1, 1], barre: { fret: 1, from: 4, to: 5 }, name: 'F (thumb bass)' },
  ],
  /* ---------------------------------------------------------------- minor */
  '9:min': [ // Am
    { frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0], name: 'Open Am' },
  ],
  '4:min': [ // Em
    { frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0], name: 'Open Em' },
    { frets: [0, 2, 2, 0, 0, 0], fingers: [0, 1, 2, 0, 0, 0], name: 'Open Em (index/middle)' },
  ],
  '2:min': [ // Dm
    { frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1], name: 'Open Dm' },
  ],
  '11:min': [ // Bm
    { frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: { fret: 2, from: 1, to: 5 }, name: 'Bm barre' },
  ],
  /* ---------------------------------------------------------- power chords */
  '4:5': [ // E5
    { frets: [0, 2, 2, -1, -1, -1], fingers: [0, 1, 3, 0, 0, 0], name: 'E5' },
    { frets: [0, 2, -1, -1, -1, -1], fingers: [0, 1, 0, 0, 0, 0], name: 'E5 (two strings)' },
  ],
  '9:5': [ // A5
    { frets: [-1, 0, 2, 2, -1, -1], fingers: [0, 0, 1, 3, 0, 0], name: 'A5' },
    { frets: [5, 7, 7, -1, -1, -1], fingers: [1, 3, 4, 0, 0, 0], name: 'A5 (fret 5)' },
  ],
  '2:5': [ // D5
    { frets: [-1, -1, 0, 2, 3, -1], fingers: [0, 0, 0, 1, 3, 0], name: 'D5' },
    { frets: [-1, 5, 7, 7, -1, -1], fingers: [0, 1, 3, 4, 0, 0], name: 'D5 (fret 5)' },
  ],
  '7:5': [ // G5
    { frets: [3, 5, 5, -1, -1, -1], fingers: [1, 3, 4, 0, 0, 0], name: 'G5' },
    { frets: [3, -1, 0, 0, 3, 3], fingers: [2, 0, 0, 0, 3, 4], name: 'G5 (open)' },
  ],
  '0:5': [ // C5
    { frets: [-1, 3, 5, 5, -1, -1], fingers: [0, 1, 3, 4, 0, 0], name: 'C5' },
    { frets: [-1, 3, 5, -1, -1, -1], fingers: [0, 1, 3, 0, 0, 0], name: 'C5 (two strings)' },
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
    { frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 1, 1], barre: { fret: 2, from: 3, to: 5 }, name: 'Open Dmaj7 (barre)' },
    { frets: [-1, -1, 0, 2, 2, 2], fingers: [0, 0, 0, 1, 2, 3], name: 'Open Dmaj7 (three fingers)' },
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
  /* -------------------------------------------------------------- sus2 */
  '9:sus2': [ // Asus2
    { frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 2, 3, 0, 0], name: 'Open Asus2' },
    { frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0], name: 'Open Asus2 (index/middle)' },
  ],
  '2:sus2': [ // Dsus2
    { frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 3, 0], name: 'Open Dsus2' },
  ],
  '4:sus2': [ // Esus2
    { frets: [0, 2, 4, 4, 0, 0], fingers: [0, 1, 3, 4, 0, 0], name: 'Open Esus2' },
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
  /* -------------------------------------------------------------- add9 */
  '0:add9': [ // Cadd9
    { frets: [-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0], name: 'Open Cadd9' },
    { frets: [-1, 3, 2, 0, 3, 3], fingers: [0, 2, 1, 0, 3, 4], name: 'Open Cadd9 (G on top)' },
  ],
  '7:add9': [ // Gadd9
    { frets: [3, -1, 0, 2, 0, 3], fingers: [2, 0, 0, 1, 0, 3], name: 'Open Gadd9' },
    { frets: [3, 0, 0, 2, 0, 3], fingers: [2, 0, 0, 1, 0, 3], name: 'Open Gadd9 (open A)' },
  ],
  '4:add9': [ // Eadd9
    { frets: [0, 2, 2, 1, 0, 2], fingers: [0, 2, 3, 1, 0, 4], name: 'Open Eadd9' },
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
  '4:dim': [ // Edim
    { frets: [0, 1, 2, 0, -1, -1], fingers: [0, 1, 2, 0, 0, 0], name: 'Open Edim' },
    { frets: [-1, -1, 2, 3, 5, 3], fingers: [0, 0, 1, 2, 4, 3], name: 'Edim (four strings)' },
  ],
  /* -------------------------------------------------------------- dim7 */
  '2:dim7': [ // Ddim7
    { frets: [-1, -1, 0, 1, 0, 1], fingers: [0, 0, 0, 1, 0, 2], name: 'Open Ddim7' },
  ],
  '4:dim7': [ // Edim7
    { frets: [0, 1, 2, 0, 2, 0], fingers: [0, 1, 2, 0, 3, 0], name: 'Open Edim7' },
    { frets: [-1, -1, 2, 3, 2, 3], fingers: [0, 0, 1, 3, 2, 4], name: 'Edim7 (four strings)' },
  ],
  '9:dim7': [ // Adim7
    { frets: [-1, 0, 1, 2, 1, 2], fingers: [0, 0, 1, 3, 2, 4], name: 'Open Adim7' },
  ],
  /* -------------------------------------------------------------- 9th */
  '9:9': [ // A9
    { frets: [-1, 0, 2, 4, 2, 3], fingers: [0, 0, 1, 3, 1, 2], barre: { fret: 2, from: 2, to: 4 }, name: 'Open A9' },
  ],
  '4:9': [ // E9
    { frets: [0, 2, 0, 1, 0, 2], fingers: [0, 2, 0, 1, 0, 3], name: 'Open E9' },
  ],
  '4:m9': [ // Em9
    { frets: [0, 2, 2, 0, 3, 2], fingers: [0, 1, 2, 0, 4, 3], name: 'Open Em9' },
    { frets: [0, 2, 0, 0, 0, 2], fingers: [0, 2, 0, 0, 0, 3], name: 'Open Em9 (Em7 shape)' },
  ],
};

/*
 * Movable shapes. Relative frets: 0 = the root fret, n = n frets above it,
 * -1 = muted. Names are unique within a quality (the voicing generator copies
 * the name into each instantiated voicing).
 *
 * Interval offsets of each string relative to a root on:
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
  { quality: '7', rootString: 0, frets: [0, -1, 0, 1, 0, -1], fingers: [1, 0, 2, 4, 3, 0], name: 'E-string root (four strings)' },
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
  { quality: 'm7', rootString: 0, frets: [0, 2, 0, 0, 0, 0], fingers: [1, 3, 1, 1, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Em7 shape' },
  { quality: 'm7', rootString: 0, frets: [0, -1, 0, 0, 0, -1], fingers: [1, 0, 3, 3, 3, 0], barre: { fret: 0, from: 2, to: 4 }, name: 'E-string root (jazz)' },
  { quality: 'm7', rootString: 1, frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 1, 3, 1, 2, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Am7 shape' },
  { quality: 'm7', rootString: 1, frets: [-1, 0, 2, 0, 1, -1], fingers: [0, 1, 3, 1, 2, 0], barre: { fret: 0, from: 1, to: 3 }, name: 'A-string root (jazz)' },
  { quality: 'm7', rootString: 2, frets: [-1, -1, 0, 2, 1, 1], fingers: [0, 0, 1, 3, 2, 2], barre: { fret: 1, from: 4, to: 5 }, name: 'Dm7 shape' },
  /* -------------------------------------------------------------- sus2 */
  { quality: 'sus2', rootString: 0, frets: [0, 2, 4, 4, 0, 0], fingers: [1, 2, 3, 4, 1, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Esus2 shape' },
  { quality: 'sus2', rootString: 0, frets: [0, 2, 4, -1, -1, -1], fingers: [1, 2, 4, 0, 0, 0], name: 'E-string root (three strings)' },
  { quality: 'sus2', rootString: 1, frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 1, 3, 4, 1, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'Asus2 shape' },
  { quality: 'sus2', rootString: 2, frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 1, 2, 3, 1], barre: { fret: 0, from: 2, to: 5 }, name: 'Dsus2 shape' },
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
  { quality: 'dim7', rootString: 1, frets: [-1, 0, 1, -1, 1, 2], fingers: [0, 1, 2, 0, 3, 4], name: 'A-string root (G muted)' },
  { quality: 'dim7', rootString: 2, frets: [-1, -1, 0, 1, 0, 1], fingers: [0, 0, 1, 3, 2, 4], name: 'D-string root' },
  /* -------------------------------------------------------------- m7b5 */
  { quality: 'm7b5', rootString: 0, frets: [0, 1, 0, 0, -1, -1], fingers: [1, 2, 1, 1, 0, 0], barre: { fret: 0, from: 0, to: 3 }, name: 'E-string root' },
  { quality: 'm7b5', rootString: 0, frets: [0, 1, 0, 0, 3, -1], fingers: [1, 2, 1, 1, 4, 0], barre: { fret: 0, from: 0, to: 3 }, name: 'E-string root (five strings)' },
  { quality: 'm7b5', rootString: 1, frets: [-1, 0, 1, 0, 1, -1], fingers: [0, 1, 3, 2, 4, 0], name: 'A-string root' },
  { quality: 'm7b5', rootString: 2, frets: [-1, -1, 0, 1, 1, 1], fingers: [0, 0, 1, 3, 3, 3], barre: { fret: 1, from: 3, to: 5 }, name: 'D-string root' },
  /* -------------------------------------------------------------- aug */
  { quality: 'aug', rootString: 0, frets: [0, -1, 2, 1, 1, -1], fingers: [1, 0, 4, 2, 3, 0], name: 'E-string root' },
  { quality: 'aug', rootString: 0, frets: [0, 3, 2, 1, -1, -1], fingers: [1, 4, 3, 2, 0, 0], name: 'E-string root (low)' },
  { quality: 'aug', rootString: 1, frets: [-1, 0, 3, 2, 2, -1], fingers: [0, 1, 4, 2, 3, 0], name: 'A-string root' },
  /* -------------------------------------------------------------- 6th */
  { quality: '6', rootString: 0, frets: [0, -1, 2, 1, 2, -1], fingers: [1, 0, 3, 2, 4, 0], name: 'E-string root' },
  { quality: '6', rootString: 1, frets: [-1, 0, 2, 2, 2, 2], fingers: [0, 1, 3, 3, 3, 3], barre: { fret: 2, from: 2, to: 5 }, name: 'A6 shape' },
  { quality: '6', rootString: 1, frets: [-1, 0, -1, 2, 2, 2], fingers: [0, 1, 0, 2, 3, 4], name: 'A-string root (D muted)' },
  { quality: '6', rootString: 2, frets: [-1, -1, 0, 2, 0, 2], fingers: [0, 0, 1, 2, 1, 3], barre: { fret: 0, from: 2, to: 4 }, name: 'D6 shape' },
  /* -------------------------------------------------------------- m6 */
  { quality: 'm6', rootString: 0, frets: [0, 2, 2, 0, 2, 0], fingers: [1, 2, 3, 1, 4, 1], barre: { fret: 0, from: 0, to: 5 }, name: 'Em6 shape' },
  { quality: 'm6', rootString: 0, frets: [0, -1, 2, 0, 2, -1], fingers: [1, 0, 3, 2, 4, 0], name: 'E-string root (jazz)' },
  { quality: 'm6', rootString: 1, frets: [-1, 0, 2, 2, 1, 2], fingers: [0, 1, 3, 3, 2, 4], barre: { fret: 2, from: 2, to: 3 }, name: 'Am6 shape' },
  { quality: 'm6', rootString: 1, frets: [-1, 0, -1, 2, 1, 2], fingers: [0, 1, 0, 3, 2, 4], name: 'A-string root (jazz)' },
  { quality: 'm6', rootString: 2, frets: [-1, -1, 0, 2, 0, 1], fingers: [0, 0, 1, 3, 1, 2], barre: { fret: 0, from: 2, to: 4 }, name: 'Dm6 shape' },
  /* -------------------------------------------------------------- add9 */
  { quality: 'add9', rootString: 0, frets: [0, 2, 2, 1, 0, 2], fingers: [1, 3, 3, 2, 1, 4], barre: [{ fret: 0, from: 0, to: 5 }, { fret: 2, from: 1, to: 2 }], name: 'Eadd9 shape' },
  { quality: 'add9', rootString: 0, frets: [0, -1, -1, 1, 0, 2], fingers: [1, 0, 0, 3, 2, 4], name: 'E-string root (spread)' },
  { quality: 'add9', rootString: 1, frets: [-1, 0, 2, 4, 2, -1], fingers: [0, 1, 2, 4, 3, 0], name: 'A-string root' },
  { quality: 'add9', rootString: 1, frets: [-1, 0, 2, 4, 2, 0], fingers: [0, 1, 2, 4, 3, 1], barre: { fret: 0, from: 1, to: 5 }, name: 'A-string root (five strings)' },
  /* -------------------------------------------------------------- 9th */
  { quality: '9', rootString: 0, frets: [0, 2, 0, 1, 0, 2], fingers: [1, 3, 1, 2, 1, 4], barre: { fret: 0, from: 0, to: 5 }, name: 'E9 shape' },
  { quality: '9', rootString: 1, frets: [-1, 0, 2, 4, 2, 3], fingers: [0, 1, 2, 4, 2, 3], barre: { fret: 2, from: 2, to: 4 }, name: 'A9 shape' },
  { quality: '9', rootString: 1, frets: [-1, 0, -1, 4, 2, 3], fingers: [0, 1, 0, 4, 2, 3], name: 'A-string root (D muted)' },
  /* -------------------------------------------------------------- maj9 */
  { quality: 'maj9', rootString: 0, frets: [0, -1, 1, 1, 0, 2], fingers: [1, 0, 3, 3, 2, 4], barre: { fret: 1, from: 2, to: 3 }, name: 'E-string root' },
  { quality: 'maj9', rootString: 0, frets: [0, 2, 1, 1, 0, 2], fingers: [1, 3, 2, 2, 1, 4], barre: [{ fret: 0, from: 0, to: 5 }, { fret: 1, from: 2, to: 3 }], name: 'Emaj9 shape' },
  { quality: 'maj9', rootString: 1, frets: [-1, 0, -1, 4, 2, 4], fingers: [0, 1, 0, 3, 2, 4], name: 'A-string root (D muted)' },
  { quality: 'maj9', rootString: 1, frets: [-1, 0, 2, 4, 2, 4], fingers: [0, 1, 2, 3, 2, 4], barre: { fret: 2, from: 2, to: 4 }, name: 'A-string root (five strings)' },
  /* -------------------------------------------------------------- m9 */
  { quality: 'm9', rootString: 0, frets: [0, 2, 0, 0, 0, 2], fingers: [1, 3, 1, 1, 1, 4], barre: { fret: 0, from: 0, to: 5 }, name: 'Em9 shape' },
  { quality: 'm9', rootString: 1, frets: [-1, 0, -1, 4, 1, 3], fingers: [0, 1, 0, 4, 2, 3], name: 'A-string root (D muted)' },
];
