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
| `src/audio/string-processor.js` | AudioWorklet: extended Karplus-Strong / waveguide string (one node per string) |
| `src/audio/engine.js` | `GuitarAudioEngine`: context, six string nodes, sympathetic coupling, pickup EQ, amp (gain, distortion), tone, cabinet, chorus, delay, reverb, master, presets |
| `src/audio/effects.js` | Distortion curves, reverb impulse generation, helpers |
| `src/audio/presets.js` | Tone presets (clean, overdrive, distortion, acoustic) |
| `src/state.js` | Observable app state (tuning, capo, fingers, chord/scale overlays, options) |
| `src/ui/guitar-canvas.js` | Guitar layout (geometry in "guitar space"), rendering (static hardware layer + dynamic strings/fingers), hit-testing |
| `src/ui/interaction.js` | Pointer/multi-touch/keyboard → fret, slide, release, pluck, strum |
| `src/ui/knob.js` | Rotary knob component (pointer drag, wheel, keyboard, ARIA slider) |
| `src/ui/controls.js` | Control panel wiring (presets, knobs, pickup selector, tuning, options) |
| `src/ui/learning-panel.js` | Chord/scale/note libraries and the "now playing" read-out |
| `src/main.js` | Boots everything |

## Playing model

* Each string has a set of *fingers* (pointer id → fret). The **sounding fret** is
  the highest fretted finger, or the capo, or 0 (open). Chord mode adds virtual
  fingers; a chord's muted strings (`x`) mute that string.
* `pluck(string, velocity, pickPosition)` excites the string at its sounding pitch.
  Re-plucking a ringing string adds energy to the existing vibration (no voice
  stealing — a string is one voice, like the real thing).
* Changing the sounding fret while the string rings glides the pitch (slide /
  hammer-on / pull-off). Lifting the last finger mutes with a fret-hand release.
* Strumming = plucking strings in order with ~10–25 ms between them; velocity
  from pointer speed; pick position from pointer x in the strum zone.

## Audio signal flow

```
string[0..5] (AudioWorklet) ─┬─► stringMix ─► pickup EQ ─► preGain ─► waveshaper ─► postGain
                             │                                                     │
                             └◄── coupling (−40 dB sympathetic resonance) ◄────────┘ (from stringMix)
   … ─► tone (low-pass) ─► cabinet/body EQ ─► chorus ─► delay ─► reverb ─► master ─► limiter ─► output
```

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
