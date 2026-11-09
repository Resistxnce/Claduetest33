# Electric Guitar Simulator

A playable, musically accurate six-string electric guitar that runs entirely in
the browser. Press the frets, pick or strum over the pickups, slide, hammer on,
switch pickups, dial in the amp, change tunings, and learn chords and scales —
with real string physics instead of beeps.

No build step and no dependencies: plain ES modules, Web Audio API and Canvas 2D.

```sh
npm start            # serves the app at http://localhost:8080/
npm test             # music-theory + chord-library unit tests (node:test)
npm run test:e2e     # Playwright: real UI interactions + offline audio pitch verification
```

Open `index.html` through any static server (modules need http://, not file://).

## What it does

**The instrument**
- Stratocaster-style body, 22-fret rosewood neck with correct fret spacing
  (`1 − 2^(−n/12)` of the 25.5" scale), inlays at 3/5/7/9/12/15/17/19/21, six
  strings of realistic gauge, six-in-line tuners, three pickups, bridge, and
  working volume / tone knobs and 5-way pickup switch on the body.
- Horizontal (nut left, low E at the bottom) on desktop; rotates to a vertical
  chord-diagram orientation on phones. Fret range adapts to the screen
  (whole guitar, frets 1–15 or 1–12) and can be forced.

**Playing**
- Mouse, touch and **multi-touch**: hold several strings with several fingers.
- Tap a fret to fret *and* pick it (optional), slide along a string, hammer on
  and pull off, lift to mute (or let ring).
- Strum zone over the pickups: tap a string to pick it, drag across the strings
  to strum. Drag speed sets the picking intensity, position sets the pick
  position (bridge = bright, neck = warm).
- Keyboard: `1`–`6` pick strings (1 = high E), `Space` strum down,
  `Shift+Space` strum up, hold `M` for palm mute, `Esc` mutes everything.
- Capo (frets 1–7).

**Sound** (`src/audio/`)
- Each string is a digital-waveguide / extended Karplus-Strong voice running in
  an `AudioWorklet`: deterministic pluck excitation with velocity-dependent
  brightness, pick-position comb filter, frequency-dependent loop damping,
  dispersion (string stiffness), tension-modulation pitch bend on hard plucks,
  pitch glides for slides, fret-noise bursts, pick click, release/mute damping.
- The loop length is compensated analytically for the loop filters' phase
  delay, so every note is synthesized at its exact equal-temperament frequency
  (verified to < 1 cent across all strings and frets by the e2e suite).
- Pickup position is modelled physically (two-tap read-out at the pickup
  position along the vibrating length, so fretting changes the comb like on a
  real guitar), plus a resonant pickup EQ per selector position.
- Amp chain: gain → asymmetric wave-shaper (4× oversampled) → tone → cabinet,
  then stereo chorus, feedback delay (selectable times), convolution reverb,
  master volume and a safety limiter. Sympathetic resonance couples the strings.
- Presets: Clean, Overdrive, Distortion, Acoustic (resonant body model instead
  of pickups), Chorus Clean, Lead. Every knob stays live.

**Music theory** (`src/theory/`)
- Nothing is hard-coded per fret: `midi(string, fret) = openMidi + fret`,
  names/octaves/frequencies derive from MIDI (A4 = 69 = 440 Hz, C4 = 60).
- Sharps or flats for every label; enharmonic equivalents available everywhere.
- Tunings: Standard, Drop D, Half-step down, Whole-step down, Open G, Open D,
  DADGAD, Drop C, Open E, Open A. Changing tuning retunes every string, label,
  chord voicing and overlay.
- Chord library: curated open and movable shapes with conventional fingerings
  for standard tuning, validated against the chord formulas; an algorithmic
  voicing generator provides correct voicings in every other tuning.
  "Hold chord" presses the shape for you so you can strum it.
- Scales: major, natural/harmonic/melodic minor, pentatonics, blues, modes,
  whole tone, chromatic — shown on the fretboard with degrees or note names.
- Highlight every position of a note; live read-out of the note played
  (name, enharmonic, MIDI, Hz, string/fret) with chord detection.

## Project layout

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for modules, conventions and
the signal flow.

```
index.html, styles.css        page + dark studio theme
src/main.js                   bootstrap
src/state.js                  observable app state
src/theory/                   notes, tunings, fretboard, scales, chords, voicings
src/audio/                    worklet string model, engine, effects, presets
src/ui/                       canvas renderer, interaction, knobs, panels
tests/*.test.js               unit tests (node --test)
tests/e2e/                    Playwright UI test + offline audio analysis
tools/serve.mjs               tiny static server
```

## Testing

- `npm test` runs the theory tests (every string × every fret × every tuning,
  spec examples, enharmonics, geometry, scales, chord detection), an
  independent specification-derived suite, and the chord-library validation
  (pitch content, bass note, barre/finger consistency, coverage).
- `npm run test:e2e` starts the server and drives Chromium (Playwright with its
  bundled Chromium): powers the amp on, frets and slides with the mouse, strums,
  holds two strings with simulated multi-touch, changes tuning, uses the chord
  library and presets, checks phone layouts, and renders every string/fret
  through the real audio engine offline, measuring the synthesized fundamental
  against equal temperament, release behaviour, dynamics and slides.

## Browser support

Chrome, Edge, Firefox and Safari (desktop and mobile) with AudioWorklet
support. Sound starts after the first tap/click, as browsers require.
Headphones recommended.
