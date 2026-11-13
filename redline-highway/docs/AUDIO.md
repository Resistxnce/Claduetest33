# Audio (Phase 2, milestone M7)

The car's sound system is built and wired in. It plays original **placeholder** sounds that were
synthesized in Python, not recorded. They exist so the system can be built, tested and tuned now. I
can't listen to audio, so I checked them by measurement (pitch, loop seams, levels, a spectrogram);
how they actually sound is for you to judge.

**Listen first:** `assets/audio/preview/GT12_drive_preview.mp3` is 24 seconds of the GT12 driven by the
Python drivetrain model and mixed by a Python copy of the game's mixer:
- 0–2 s: idle.
- 2–13 s: a full-throttle launch through six gears to 233 km/h.
- 13–16 s: a lift-off with exhaust crackles.
- 16–19 s: hard ABS braking with downshifts.
- 19–24 s: half throttle.

## Turning the sound on (two uploads)

Roblox limits how many sounds you can upload each month. A Roblox staff post (May 2024) gave 10 a
month without ID verification and 100 with it, and that limit may have changed since. To stay well
inside it, every sound is packed into two files, and the game plays each sound from its own slice of
a file:

| File | Contents |
|---|---|
| `assets/audio/GT12_Engine.flac` | 16 engine loops: 8 engine speeds, on and off throttle |
| `assets/audio/Driving_Effects.flac` | Tyre squeal, road noise, wind, gearbox whine, 6 exhaust crackles, shift crack, shift clunk, suspension knock |

1. Upload both files, either from the Creator Hub (create.roblox.com, your creations, Audio) or with
   Studio's Asset Manager import. Roblox accepts .mp3, .ogg, .wav and .flac, under 20 MB and up to 7
   minutes, at 48 kHz or lower. These files are well inside that. Uploads go through moderation, which
   can take a little while.
2. Copy each asset's ID.
3. In Studio, open **ReplicatedStorage > VehicleSystem > VehicleAudio > AudioAssets** and paste the IDs
   in. Edit the copy in `src/` too if you use Rojo.
   ```lua
   return {
   	GT12_Engine = "rbxassetid://1234567890",
   	Driving_Effects = "rbxassetid://1234567891",
   }
   ```
4. Press Play. While an ID is missing, the Output window shows a `[Redline] No sound asset ID ...`
   reminder and that file's sounds stay off; everything else works as before.

Audio you upload yourself can be used in your own experiences. If the game is later published under
a group, upload the sounds to that group, or give the group permission to use them.

## How it works

- **Engine.** Each loop was made at one steady engine speed. Every frame the mixer:
  - crossfades the two loops recorded either side of the current RPM;
  - pitches each loop by the current RPM divided by the RPM it was made at;
  - blends the on-throttle and off-throttle versions by engine load (the engine's torque as a share
    of its full-throttle torque at that RPM).

  So a car that is coasting sounds different from one pulling hard at the same RPM.
- **Rev limiter.** No extra sound is needed. The simulation cuts fuel at the limiter, so the load
  drops and the RPM bounces, and the mix follows.
- **Events:**
  - a short ignition-cut crack and a clunk on full-throttle upshifts;
  - a softer clunk on downshifts;
  - exhaust crackles for about a second after lifting off above 4,000 rpm;
  - a knock when the suspension hits its bump stops.
- **Driving sounds:**
  - tyre squeal: light near the grip limit, full volume only when sliding;
  - road noise and wind, which rise with speed;
  - gearbox whine, pitched by driveshaft speed.
- **Cockpit camera.** An equaliser muffles the engine, wind is quieter and road noise louder.
- **Code:**
  - `VehicleAudio/EngineMix` is the mixer: pure maths, also copied into `tools/audio_preview.py`.
  - The client's `VehicleAudio` script creates the Sounds and applies the mix every frame.
  - The settings are in the car's configuration (`Prototype812`, `audio = { ... }`).

## Tuning

Every level and threshold is in `audio = { ... }` in `VehicleConfigurations/Prototype812.luau`, with
comments. After changing settings, run `python3 tools/audio_preview.py` to hear the result outside
Roblox. That needs Python with numpy, and ffmpeg. To change the sounds themselves, edit and rerun
`tools/synth_audio.py`, then upload the new files and update the IDs.

## Replacing the placeholders with recordings

Recordings will sound far more real. What's needed:
- Steady-RPM loops at several engine speeds (6 to 10, closer together at low RPM), each recorded both
  on throttle (under load, ideally on a dyno) and off throttle, plus the one-shots.
- Only recordings you make yourself or have a licence to use in a Roblox game. Nothing ripped from
  other games or videos.

Each loop should hold a steady RPM and be trimmed so it repeats without a click. `tools/synth_audio.py`
already packs loops into sheets and writes the matching region tables; it can be adapted to pack
recorded loops once you have them.

## Not done yet

- **Other cars and traffic.** Positional sound for other players' cars and traffic, with Doppler, comes
  with traffic in Phase 4. Only your own car makes sound for now.
- **Untested in Roblox.** Nothing here has run in Roblox yet. In particular, how Roblox handles
  `PlaybackRegion` and `LoopRegion` timing needs a listen. Each loop is stored three times in a row and
  the middle copy is the one that loops, so a slightly late loop point still lands on matching audio.
