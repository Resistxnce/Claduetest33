# Electric Guitar Simulator — Architecture

A dependency-free browser application (ES modules, Web Audio API, Canvas 2D).
No build step: `npm start` serves the folder, `index.html` loads `src/main.js`.

## Conventions

* **String indices** are `0..5` from the thickest string (string 6, low E in
  standard tuning) to the thinnest (string 1, high E). `stringNumber(i) = 6 - i`.
* **Pitch** is always a MIDI number. `midi(string, fret) = tuning.midi[string] + fret`.
  Names, octaves and frequencies are derived (`src/theory/notes.js`); nothing is
  hard-coded per fret. A4 = 69 = 440 Hz, C4 = 60, E2 = 40.
* **Voicings** (`src/theory/chords.js`): `{ frets:[6], fingers:[6], barre?, name }`,
  low string first, `-1` = muted, `0` = open; fingers `0` none, `1..4`, `'T'`.

## Modules

| Path | Responsibility |
| --- | --- |
| `src/theory/notes.js` | MIDI ⇄ frequency/name/octave, enharmonics, parsing |
| `src/theory/tunings.js` | Tuning definitions (standard, drop D, ½ down, whole down, open G/D, DADGAD, …) |
| `src/theory/fretboard.js` | `Fretboard` model (note lookup per string/fret, positions of a pitch class), fret geometry (`1 - 2^(-n/12)`), gauges, markers |
| `src/theory/scales.js` | Scale formulas and fretboard positions |
| `src/theory/chords.js` | Chord formulas, naming, detection, voicing validation + generator for any tuning, curated-library access |
| `src/theory/chord-voicings.js` | Curated standard-tuning voicings: `OPEN_VOICINGS` (keyed `${rootPc}:${quality}`) and `MOVABLE_SHAPES` |
| `src/audio/string-processor.js` | AudioWorklet: six extended Karplus-Strong / waveguide strings in one processor, coupled through a passive bridge |
| `src/audio/engine.js` | `GuitarAudioEngine`: context, strings worklet, pickup EQ, amp (gain, distortion), tone, cabinet, chorus, delay, reverb, master, soft limiter, presets |
| `src/audio/effects.js` | Distortion curves, reverb impulse generation, helpers |
| `src/audio/presets.js` | Tone presets (clean, overdrive, distortion, acoustic) |
| `src/state.js` | Observable app state (tuning, capo, fingers, chord/scale overlays, options) |
| `src/ui/guitar-canvas.js` | 24-fret fretboard: layout (geometry in "guitar space"), rendering (cached wood/frets/inlays layer + dynamic strings, note dots, overlays), hit-testing, panning; `NeckNavigator` minimap |
| `src/ui/interaction.js` | Pointer/multi-touch/keyboard → tap-to-play, slide, hammer-on/pull-off, sweep strums, release |
| `src/ui/knob.js` | Rotary knob component (pointer drag, wheel, keyboard, ARIA slider) |
| `src/ui/controls.js` | Control panel wiring (presets, knobs, pickup selector, tuning, options) |
| `src/ui/learning-panel.js` | Chord/scale/note libraries and the "now playing" read-out |
| `src/main.js` | Boots everything |

## Fretboard view

* Guitar space: x along the neck (open-string zone, nut, frets 1–24), y across
  the strings with the high E at the top and the low E at the bottom
  (tablature orientation). Portrait phones rotate it: nut at the top, low E on
  the left (chord-diagram orientation).
* All 24 frets always exist. If the viewport is shorter than ~900 px along the
  neck, the neck is laid out larger than the viewport and `scroll` pans it
  (minimap drag, ←/→, shift+wheel; chord selection auto-reveals the shape).

## Playing model

* Each string has a set of *fingers* (pointer id → fret). The **sounding fret** is
  the highest fretted finger, or the capo, or 0 (open). Chord mode adds virtual
  fingers; a chord's muted strings (`x`) mute that string. Chord shapes are
  fingered relative to the capo (the capo acts as the nut), so a chord keeps
  its name and pitch content at any capo position.
* Tapping a string at a fret presses it and plucks it; tapping before the nut
  plucks the open string. `pluck(string, velocity)` excites the string at its
  sounding pitch. Re-plucking a ringing string adds energy to the existing
  vibration (no voice stealing — a string is one voice, like the real thing).
* Changing the sounding fret while the string rings glides the pitch (slide /
  hammer-on / pull-off). Lifting the last finger lets the note ring out at its
  own pitch (default) or mutes it ("Lifting a finger mutes the string").
  `state.ringing[string]` always records the note actually sounding (plucks,
  slides, hammer-ons, pull-offs, bends, retunes); the read-out and the ring
  markers are driven from it, and `engine.isAudible(string)` bounds how long a
  note counts as ringing by that string's decay time.
* Pointer hit-testing has hysteresis on all three boundaries (string to string,
  fret to fret, open zone to fretboard) so a resting finger never flickers.
* Sweeping a pointer across strings plucks each string it reaches (a strum);
  velocity comes from pointer speed. Keyboard/buttons strum all six strings
  ~14 ms apart.

## Audio signal flow

```
strings (one AudioWorklet, six waveguide voices + passive bridge coupling) ─► pickup EQ ─► body EQ
  ─► preGain ─► waveshaper (4× oversampled only when driven hard) ─► postGain ─► DC filter
  ─► tone (low-pass) ─► cabinet ─► chorus ─► delay ─► reverb ─► master ─► soft limiter ─► output
```

The graph is a straight chain: sympathetic resonance is computed inside the
worklet (each sample the bridge takes a small, low-passed fraction of the summed
string motion out of every string's reflection), so there is no feedback cycle
in the node graph and the coupling can never add energy. The clean path adds no
latency beyond the device's own; the limiter is linear below 0.8 of full scale.

## Testing

* `npm test` — `node --test` unit tests: `tests/theory.test.js` (note math,
  tunings, fretboard, scales, chords), `tests/spec-theory.test.js` (an
  independent suite derived from the specification, with its own expectation
  helpers) and `tests/chords.test.js` (curated voicing library validation).
* `npm run test:e2e` — `tests/e2e/run.mjs` runs `ui.mjs` (Playwright drives the
  real page: power on, fret + slide, strum, keyboard, multi-touch, tuning,
  chord hold, presets, phone layouts, screenshots in `tests/e2e/output/`) and
  `audio-pitch.mjs` (renders every string/fret through the real engine in an
  `OfflineAudioContext` via `audio-harness.html` and measures the synthesized
  fundamental, release, dynamics, slides and per-preset levels).
* `.github/workflows/ci.yml` runs both on every push and pull request.
