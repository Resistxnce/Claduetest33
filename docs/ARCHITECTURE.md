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
| `src/audio/string-processor.js` | `StringBank`: six extended Karplus-Strong / waveguide strings coupled through a passive bridge. Platform independent (unit-tested in Node); registers the AudioWorklet processor when loaded as a worklet module |
| `src/audio/engine.js` | `GuitarAudioEngine`: context (with iOS unlock), string backend (`'worklet'` or the `'script'` fallback running the same `StringBank` in a ScriptProcessorNode when AudioWorklet is unavailable, e.g. plain http on a LAN), pickup EQ, amp (gain, distortion), tone, cabinet, chorus, delay, reverb, master, soft limiter, presets |
| `src/audio/effects.js` | Distortion curves, reverb impulse generation, helpers |
| `src/audio/presets.js` | Tone presets (clean, overdrive, distortion, acoustic, chorus clean, lead) |
| `src/state.js` | Observable app state (tuning, capo, fingers, chord/scale overlays, options) |
| `src/ui/guitar-canvas.js` | 24-fret fretboard: layout (geometry in "guitar space"), rendering (cached wood/frets/inlays layer + dynamic strings, note dots, overlays), hit-testing, panning; `NeckNavigator` minimap |
| `src/ui/interaction.js` | Pointer/multi-touch/keyboard → tap-to-play, slide, hammer-on/pull-off, sweep strums, release |
| `src/ui/knob.js` | Rotary knob component (pointer drag, wheel, keyboard, ARIA slider) |
| `src/ui/controls.js` | Control panel wiring (presets, knobs, pickup selector, tuning, options) |
| `src/ui/learning-panel.js` | Chord/scale/note libraries and the "now playing" read-out |
| `src/ui/qr.js` | Dependency-free QR encoder (byte mode, level L, versions 1–5) for the device address: terminal and canvas renderers |
| `src/main.js` | Boots everything; stage toolbar, full-screen play mode, service-worker registration |
| `manifest.webmanifest`, `sw.js`, `icons/` | Installable web app: home-screen icon, standalone display, network-first offline cache |
| `tools/serve.mjs`, `tools/lan.mjs` | Static server: binds all interfaces, prints the LAN address with a QR code (most likely Wi-Fi/Ethernet address first), `/__lan.json`, optional `--https` with a self-signed certificate |

## Fretboard view

* Guitar space: x along the neck (open-string zone, nut, frets 1–24), y across
  the strings with the high E at the top and the low E at the bottom
  (tablature orientation). Portrait phones rotate it: nut at the top, low E on
  the left (chord-diagram orientation).
* All 24 frets always exist. When the main pointer is a finger
  (`pointer: coarse`) the neck is laid out at least 1700 px long, so the 24th
  fret is ~31 px wide; with a mouse it is zoomed only if the viewport is
  shorter than ~900 px along the neck. A neck larger than the viewport is
  panned by `scroll` (minimap drag, ←/→, shift+wheel; chord selection
  auto-reveals the shape).
* The canvas re-lays itself out on window resizes and, through a
  ResizeObserver, whenever page layout changes its box; pointer coordinates
  are mapped through the drawn scale.

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
* A finger is one entry in `state.fingers` (`{string, fret}`), keyed by pointer
  id. Dragged across the strings inside one fret it gains `from` and presses
  every string between `from` and `string` — a barre (`state.covers`,
  `state.fingerStrings`); the pitch rule stays "highest fretted position on a
  string wins". Along the neck the whole span slides; a diagonal move stands
  the finger up again and it leaves the earlier strings. In Hold mode a lifted
  touch re-keys its finger as `held-N` (`held: true`): it stays until tapped,
  or until Hold is switched off. "Mute" lifts touches but not held fingers.
* The strum strip (`zone: 'pick'`) is pinned to the bridge-side end of the
  view (`canvas.pickX`, `pickW`); the layout reserves a tail past the 24th
  fret so the last frets are never underneath it. Like the open zone it picks
  strings at their sounding fret without fretting them. A pointer that began
  on the fretboard passes underneath it.
* Pointer hit-testing has hysteresis on all three boundaries (string to string,
  fret to fret, open zone to fretboard) so a resting finger never flickers.
* Sweeping a pointer across strings plucks each string it reaches (a strum);
  velocity comes from pointer speed. Keyboard/buttons strum all six strings
  ~14 ms apart.
* Messages for one string reach the string model in the order they were sent,
  even when some are scheduled ahead (a strum) and others are immediate (a
  mute, a retune): an immediate message waits for anything already queued for
  its string. "Mute everything" cancels what is still queued.
* The focused fretboard has a keyboard cursor (arrows, Home/End, Enter); the
  key acts as one more finger (`'keyboard'` in `state.fingers`), so slides and
  sweeps work exactly as with a pointer.

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

## Touch devices

* The page is laid out for coarse pointers (taller stage, larger controls,
  safe-area insets, no text selection / callouts / pinch zoom while playing).
* Play mode (`body.play-mode`) makes the stage fill the viewport; the neck then
  runs along the longer screen side and never gets wider than 470 px across
  the strings — spare space shows the sounding notes and chord. The Fullscreen
  API is used as well where the browser has it (not on iPhone).
* Audio is started synchronously inside the first tap (`unlockAudio`), declared
  as media playback so the iPhone silent switch does not mute it, and resumed
  on the next touch after an interruption.

## Testing

* `npm test` — `node --test` unit tests: `tests/theory.test.js` (note math,
  tunings, fretboard, scales, chords), `tests/spec-theory.test.js` (an
  independent suite derived from the specification, with its own expectation
  helpers), `tests/chords.test.js` (curated voicing library validation),
  `tests/state.test.js` (capo, held chords, ringing notes, bends) and
  `tests/dsp.test.js` (the string model itself: pitch at three sample rates,
  identical output at worklet and fallback block sizes, decay, muting,
  coupling stability, garbage input).
* `npm run test:e2e` — `tests/e2e/run.mjs` runs `mobile.mjs` (emulated iPad and
  phone, both orientations, touch input: fallback audio backend, sound output,
  multi-touch, play mode, target sizes, manifest/service worker), `ui.mjs`
  (Playwright drives the
  real page: power on, fret + slide, strum, keyboard, multi-touch, tuning,
  chord hold, presets, phone layouts, screenshots in `tests/e2e/output/`) and
  `audio-pitch.mjs` (renders every string/fret through the real engine in an
  `OfflineAudioContext` via `audio-harness.html` and measures the synthesized
  fundamental, release, dynamics, slides and per-preset levels).
* `.github/workflows/ci.yml` runs both on every push and pull request.
