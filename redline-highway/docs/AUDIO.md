# Audio

Every car's engine sound is now built from a description of that specific engine: its firing order,
which cylinders sit on which bank, its crank, how its exhaust is routed, its turbos or supercharger,
its rev limiter and its measured loudness. A Python synthesizer turns that description into sound
loops; the game mixes them by rpm, load, boost and the limiter. Tunnels add reverb, and traffic has its
own positional sound with distance, air absorption and Doppler.

The sounds are still **synthesized**, not recorded. I can't listen to audio, so I judged them by
measurement: engine-order spectra, band levels, loop seams and spectrograms. The synthesis was
calibrated against real, freely licensed recordings (see [Calibration](#calibration-against-real-recordings)).
How it actually sounds is for you to judge. Nothing here has run in Roblox yet.

## Listen first

In `assets/audio/preview/` (each has a spectrogram picture beside it; ticks along its top edge mark
the events):

| File | What it is |
|---|---|
| `GT12_drive_preview.mp3` (30 s) | **0 s** idle in neutral. **2 s** a free rev to the limiter, held about 1.6 s. **4 s** lift. **6 s** launch, full-throttle upshifts through five gears to 203 km/h. **14.5 s** lift-off (exhaust crackles). **16 s** braking with downshifts. **19 s** full throttle in 2nd, held on the limiter. **24.5 s** lift-off. **26 s** braking to a stop. |
| `GT12_tunnel_preview.mp3` (12 s) | Flat out in 3rd and 4th through a 320 m tunnel. Inside from about 3.6 s to 9 s. |
| `Traffic_driveby_preview.mp3` (28 s, stereo) | Heard from the roadside: a car passing at 110 km/h 6 m away, then a truck at 85 km/h. |

They are made by `tools/audio_preview.py`. It drives the car with the drivetrain model and runs Python
copies of the game's mixer, tunnel and traffic code on every frame.

## Turning the sound on (uploads)

Roblox limits how many sounds you can upload each month. A Roblox staff post (May 2024) gave 10 a month
without ID verification and 100 with it, and that limit may have changed since. So sounds are packed
into a few files ("packs"), and the game plays each sound from its own slice of a pack. One pack can
hold several cars. `assets/audio/packs.json` lists which cars go in which pack.

| File | Contents | Upload now? |
|---|---|---|
| `assets/audio/GT12_Engine.flac` (24 s, 1.3 MB) | The GT12: 16 engine loops (8 engine speeds, on and off throttle) and 2 limiter loops | Yes |
| `assets/audio/Driving_Effects.flac` (15 s, 0.8 MB) | Tyre squeal, road noise, wind, gearbox whine, tyre roar for traffic, 6 exhaust crackles, shift crack and clunk, suspension knock, and the traffic car and truck engines | Yes |
| `assets/audio/Engines_Pack1.flac` | The next six cars' engines, once their sound definitions are final. It holds drafts now. | Not yet: upload once when the cars are done |

1. Upload the files, either from the Creator Hub (create.roblox.com, your creations, Audio) or with
   Studio's Asset Manager import. Roblox accepts .mp3, .ogg, .wav and .flac, under 20 MB and up to
   7 minutes, at 48 kHz or lower. These files are well inside that. Uploads go through moderation,
   which can take a little while.
2. Copy each asset's ID.
3. In Studio, open **ReplicatedStorage > VehicleSystem > VehicleAudio > AudioAssets** and paste the IDs
   in. Edit the copy in `src/` too if you use Rojo.
   ```lua
   return {
   	GT12_Engine = "rbxassetid://1234567890",
   	Driving_Effects = "rbxassetid://1234567891",
   	Engines_Pack1 = "",
   }
   ```
4. Press Play. While an ID is missing, the Output window shows a `[Redline] No sound asset ID ...`
   reminder and that file's sounds stay off; everything else works as before. Traffic is silent until
   `Driving_Effects` has an ID.

Audio you upload yourself can be used in your own experiences. If the game is later published under a
group, upload the sounds to that group, or give the group permission to use them.

**Packing.** A car's loops take about 25-30 s of audio (about 1.5-1.7 MB as FLAC), so one pack holds a dozen
cars inside the limits that `packs.json` sets (400 s and 19 MB, leaving margin under Roblox's 7 minutes
and 20 MB). Re-uploading a changed pack costs one upload and gives it a new ID. So:
- finish a batch of cars;
- build their pack once;
- upload it once.

Each loop is stored once, with 0.02 s of its end before it and 0.25 s of its start after it. The Sound
starts exactly at the loop start, so a loop point that Roblox handles a little late, or a restart from
the playback start, still lands on matching audio. The previous version stored every loop three times;
this saves about 60% of the space.

## How it works

```
assets/audio/engines/<ConfigId>.json  --tools/synth_audio.py-->  assets/audio/<pack>.flac
   (the engine's acoustic definition)                           + VehicleAudio/Sheets/<sheet>.luau (regions, gains)
                                                                        |
car config audio = {...}  ->  VehicleAudio/EngineMix (mixer, pure maths)  ->  Client/VehicleAudio (Sounds)
                                                                        Client/AudioEnvironment (tunnels)
traffic: VehicleAudio/TrafficMix (maths)  ->  Client/TrafficAudio (positional Sounds)
```

### The synthesizer (`tools/synth_audio.py`)

For each car it builds the engine from its definition:

1. **Firing events.** The firing order, the bank of each cylinder, the bank angle and the crank give
   the crank angle of every firing. Even-firing cranks (cross-plane and flat-plane V8, inline-6, 60°
   V12) fire every 720/cylinders degrees. A common-pin V (the GT12's 65° V12) pairs the cylinders that
   share a crankpin, so the second fires one bank angle after the first: the GT12's gaps alternate 65°
   and 55°.
2. **Which pulses reach which pipe.** Each firing sends a blowdown pulse down its cylinder's primary
   pipe to a collector. The definition says which collector each cylinder feeds. `--check` prints the
   result. This is what makes engines with the same gaps sound different:
   ```
   cross-plane V8 (GM 1-8-7-2-6-5-4-3), each bank:  pulse gaps 180-270-180-90  (uneven: the burble)
   flat-plane V8, each bank:                          180-180-180-180          (even: the scream)
   hot-V V8, cross-bank manifold, each turbo:         180-180-180-180          (even pulses to each turbo)
   inline-6, two 3-cylinder manifolds:                240-240-240
   65-degree V12, each bank:                          120-120-120-120-120-120
   ```
   With the same exhaust, the synthesized cross-plane V8 has its half orders (1.5, 2.5, 5.5, 6.5) only
   4-7 dB under the firing order, while a flat-plane V8's are more than 28 dB under. Its order 2 (each
   bank firing every 180°) stands out instead.
3. **The exhaust.**
   - Pulses are shaped by blowdown rise and decay (crank degrees, so they scale with rpm).
   - Each pulse is a little early or late and a little quicker or slower than the last, and turbulent
     flow noise rides on it.
   - Strong full-load pulses sharpen ("rasp").
   - Collectors merge as the definition says: separate banks, an X-pipe or H-pipe (a share of each
     bank crosses over, mostly at low frequencies), a Y into one pipe, or hot-V cross-bank collectors.
   - Turbos take the sharp part out of each pulse.
   - Pipe lengths give resonances. Silencers with valves open or closed (or opening above an rpm or
     load) filter the sound, and the tailpipes radiate it.
4. **Intake, mechanical and idle.**
   - Induction pulses pass through runners, an airbox resonance, the snorkel and the air filter.
   - Combustion noise is radiated by the block, plus valvetrain and injector ticks, heard through the
     engine bay.
   - Idle roughness and cam lope.
   - Overrun: above about 1.5x idle the fuel is cut, so the cylinders only pump air, with optional
     burble pops.
5. **Loops.**
   - On- and off-throttle loops at engine speeds from idle to the limiter.
   - Two limiter loops with the cut pattern baked in: free revving (faster, deeper bounce) and in gear.
     Fuel cut, ignition cut (with afterfire pops) or soft cut.
   - Forced induction:
     - a turbo whistle loop (pitched by boost in game) and blow-off one-shots (atmospheric "pssh",
       recirculating whoosh, or compressor-surge flutter);
     - for a supercharger, whine loops at two crank speeds (rotor lobes x drive ratio).
   - Every loop is a whole number of engine cycles (limiter loops a whole number of bounces), and all
     filtering is circular, so loops repeat without a click. The build prints a seam check: the jump at
     the loop point divided by the loop's 99th-percentile sample step. Every loop is between 0.01 and
     1.2, an ordinary step.
6. **Loudness.** Every loop is stored at the same A-weighted level and carries a `gain` in its sheet
   table. The gain comes from the real car's measured levels; see [Loudness](#loudness-calibration).

### The mixer (`VehicleAudio/EngineMix`, copied in `tools/audio_preview.py`)

Every frame:
- the two loops either side of the current rpm are crossfaded with equal power (in log-rpm), each
  pitched by rpm / its own rpm;
- on- and off-throttle loops are crossfaded by load, with each loop's gain.

  Load is engine torque as a share of full-throttle torque, or the throttle opening if that is more,
  so a turbo car still off boost counts as on throttle.
- **Rev limiter.** While the fuel cut keeps coming back (the cut flag seen within `limiterHold`,
  pedal down, rpm within 8% of the limiter), the mix switches to the limiter loops with a 25 ms attack.
  It uses the free-revving loop in neutral or with the clutch open, the in-gear loop otherwise. An
  upshift off the limiter drops the rpm below the band and releases it at once.
- **Turbo.**
  - The whistle's volume follows boost (`t.boost`).
  - Its pitch follows the turbo's shaft speed, which rises about as the square root of boost
    pressure, between the definition's low and high whistle pitch.
  - A blow-off plays when the pedal comes off (it was above 0.6 within the last moment, now below
    0.2) while boost was above `blowOffMinBoost`.
- **Supercharger.** The whine is pitched by rpm (crank to rotor ratio, rotor pulses per turn) and grows
  with boost.
- **Events and driving sounds.** These are unchanged:
  - the shift crack and clunk;
  - crackles after a high-rpm lift-off;
  - the bump knock;
  - tyre squeal, road, wind and gearbox whine;
  - the cockpit equaliser.

`Client/VehicleAudio` plays the result: one looping Sound per loop (the player's own car is not
positional), with small voice pools for one-shots from the effects sheet and from the engine sheet
(blow-off).

### Tunnels (`Client/AudioEnvironment`)

The maps mark the inside of every tunnel with invisible box parts tagged **`TunnelZone`**
(CollectionService). Long or curved tunnels are chains of boxes that overlap at the joints. When the
camera is inside one, every attached SoundGroup gets:
- reverb (ReverbSoundEffect), with its decay from the zone's `ReverbDecay` attribute;
- a slap echo between the walls (EchoSoundEffect), with its delay from the box's width;
- a low-mid build-up (EqualizerSoundEffect: +5 dB below 400 Hz, +1.5 dB to 4 kHz, -2 dB above);
- a +2 dB level rise.

The effect starts 12 m before a portal (at 40% of full) and eases in over about 15 m inside. The ease
is scaled by the camera's speed, so it takes the same distance at any speed. It eases out the same way.

| Zone attribute | Meaning | Default | Built values |
|---|---|---|---|
| `ReverbDecay` | Reverb decay, seconds | 1.6 | Kagerou Tunnel 2.2, Hotaru Tunnel 1.6, the oval's gallery 0.8 |
| `ReverbWet` | Reverb level, dB | -4 | |

**To test without a tunnel:** during Play, select SoundService and add a boolean attribute
`ForceTunnel` = true.

Both the player's car and the traffic get the effect. Roblox's reverb can't be copied exactly, so
`tools/audio_preview.py` approximates it with a synthetic impulse response of the same decay. Treat
the tunnel preview as a guide, not a match.

### Traffic (`Client/TrafficAudio`, maths in `VehicleAudio/TrafficMix`)

- **Voices.** The 5 nearest cars and 2 nearest trucks within 320 m each get a voice: an Attachment in
  `Workspace.Terrain` that follows the car, carrying engine (on and off throttle) and tyre-roar
  Sounds.
- **Spatialization.** Roblox places them in 3D and rolls them off with distance (InverseTapered: full
  volume within 6 m, silent at 450 m).
- **Every frame**, TrafficMix adds:
  - engine speed from road speed through a simple automatic gearbox, and load from acceleration;
  - Doppler: pitch x (c + listener speed toward the car) / (c - car speed toward the listener),
    c = 343 m/s;
  - air absorption: an equaliser cuts treble with distance, 0.06 dB/m above 4 kHz and 0.012 dB/m from
    400 Hz to 4 kHz. These are estimates, stronger than ISO 9613-1's roughly 5 dB/km at 1 kHz and
    20-80 dB/km at 4-8 kHz, so distance reads in a game.
- **Doppler setting.** TrafficAudio sets `SoundService.DopplerScale = 0`. Otherwise Roblox would add
  its own Doppler from the camera's motion on top. Traffic parts are anchored, so Roblox can't see
  their speed anyway.
- **Engine sounds.** Traffic engines are two generic definitions (`TrafficCar`: a 2.0 L inline-4;
  `TrafficTruck`: a 12 L turbo-diesel inline-6), built into the effects pack.
- **Gone cars.** A car is gone when its id leaves `TrafficRenderer.cars()`.

## Adding a car's sound (for car builders)

Needs Python 3 with numpy, and ffmpeg.

1. **Write the definition.** Copy the existing definition closest to your engine in
   `assets/audio/engines/` and save it as `<ConfigId>.json`:
   - `Prototype812.json`: a common-pin V12;
   - `RefC8Stingray.json`: a cross-plane V8 with an X-pipe and valves;
   - `RefM5F90.json`: a hot-V twin-turbo V8;
   - `RefM3G80.json`: a twin-turbo inline-6;
   - `RefCamaroZL1.json`: a supercharged V8.

   The `Ref*` files are drafts written to test each layout. Replace their numbers with the research
   notes. Fill it in from `research_notes/cars/<ConfigId>`, and give every number a source or an
   estimate label in `notes` (see the reference below).
2. **Check the firing pattern.** Run `python3 tools/synth_audio.py --check <ConfigId>`. It prints the
   firing gaps, each bank's and each collector's pulse gaps, and warnings: for example, a "flat-plane"
   whose firing order doesn't alternate banks means the cylinder numbering is wrong.
3. **Put the car in a pack.** List the id under a pack's `engines` in `assets/audio/packs.json`.
   `Engines_Pack1` already lists the six new cars.
4. **Build it alone.** Run `python3 tools/synth_audio.py --car <ConfigId> --dev`.
   - It builds just that car into `assets/audio/dev/Dev_<ConfigId>.flac` and writes
     `VehicleAudio/Sheets/<ConfigId>_Engine.luau`.
   - It prints every loop's gain, peak, A-weighted level and seam check.
   - It leaves the shared pack and the other cars' sheets alone, so several cars can be worked on at
     once.
   - A dev-built car is silent in game, because its pack isn't uploaded. The previews work.
5. **Hook up the config.** In the car's config, copy the GT12's `audio = { ... }` table and set
   `engineSheet = "<ConfigId>_Engine"` and `redlineRpm`. The other settings are explained in the
   GT12's table.
6. **Listen.** Run `python3 tools/audio_preview.py --car <ConfigId>`. This writes
   `<ConfigId>_drive_preview.mp3` and `<ConfigId>_tunnel_preview.mp3` with spectrograms.
7. **Optional: calibrate against a recording.** Run
   `python3 tools/synth_audio.py --analyze REC --car <ConfigId> --start S --end E`. It tracks the
   rpm, prints the recording's engine-order spectrum next to the synthesized loop at that rpm, and
   shows harmonic-to-noise ratios. It works best on steady revs with little wind.
8. **Pack (once, when a batch of cars is final).** Run `python3 tools/synth_audio.py --pack Engines_Pack1`,
   then delete `assets/audio/dev`.
   - This rebuilds the pack with all its cars and points their sheets at it.
   - It warns if the pack is over its limits or its key is missing from `AudioAssets`.
   - Then upload the pack once. Running `python3 tools/synth_audio.py` with no options rebuilds every
     pack; `--car <ConfigId>` without `--dev` rebuilds the pack that holds the car.

## The engine acoustic definition

`assets/audio/engines/<ConfigId>.json`. Anything left out takes the default in `DEFAULTS` at the top
of `tools/synth_audio.py`. Units: metres, Kelvin, rpm, crank degrees, Hz, dB.

**Top level**

| Field | Meaning |
|---|---|
| `id` | The car's config id. |
| `displayName`, `reference` | For people only. Real names appear only here, as engineering references. |
| `sheet` | Sheet table name. Default `<id>_Engine`; the GT12 keeps `GT12_Engine`. |
| `seed` | Random seed. Default: from the id, so rebuilds are identical. |
| `notes` | Field path to its source, as `"[F]"` factory, `"[P]"` published, `"[E]"` estimate, `"[A]"` assumption, with the source. |

**`engine`**

| Field | Meaning |
|---|---|
| `cylinders`, `firingOrder` | The firing order, cylinders numbered as the maker does. |
| `layout`, `bankAngleDeg` | `"V"`, `"inline"` or `"flat"`. |
| `banks` | Bank name to its cylinders, front to back: `{"L": [1,3,5,7], "R": [2,4,6,8]}`. |
| `crank` | `"crossplane"`, `"flatplane"`, `"even"` or `"inline"` (even gaps of 720/cylinders), or `"commonPin"` (a V with two cylinders per crankpin; gaps alternate bank angle and pin spacing minus bank angle). |
| `firingIntervalsDeg` | An explicit cycle of gaps that overrides `crank`, for odd engines. |
| `idleRpm`, `limiterRpm`, `aspiration` | As in the car config. |
| `cylinderSpread` | How much cylinders differ (0.06). This puts the half orders in the sound. |

**`exhaust`**

| Field | Meaning |
|---|---|
| `collectors` | `{name, cylinders, primaryLengthM, lengthSpreadM}`. Default: one per bank. For a hot-V cross-bank manifold, list the cylinders each turbo gets. |
| `merge` | `{type, crossover, crossoverHz, pathM}`. `type` is one of:<br>• `"separate"`: banks stay apart to their outlets;<br>• `"xpipe"`: a strong crossover, about 0.3-0.5;<br>• `"hpipe"`: a balance pipe, about 0.1-0.2;<br>• `"y"`: all into one.<br>`crossover` is the share that crosses at low frequency, falling above `crossoverHz`. |
| `outlets` | `{collectors, pipeLengthM, tailLengthM, diameterM, offsetM, gain}`. Pipe lengths set the resonances; `offsetM` is how much farther from the listener the outlet is. |
| `muffler` | `valves` is `"open"`, `"closed"` or `"auto"`. Auto opens at `openAboveRpm` or `openAboveLoad`, per loop. Also `openLowpassHz`, `closedLowpassHz`, `closedCutDb`, `chamberAreaRatio`, `chamberLengthM`. |
| `evoDeg` | Exhaust valve opening after firing (130). |
| `pulseRiseDeg`, `pulseDecayDeg` | Blowdown pulse shape (4, 30). |
| `offPulseSoftening`, `minRiseMs` | Pulse softening off throttle, and the shortest rise. |
| `gasTempK`, `pipeTempK` | Gas temperatures (they set the speed of sound in the pipes). |
| `primaryReflection`, `pipeReflection` | Resonance strength. |
| `rasp` | 0-1: how much full-load pulses sharpen. |
| `timingJitterDeg`, `shapeSpread` | Pulse-to-pulse variation (0.8, 0.25). |
| `flowNoise`, `flowNoiseHz` | Turbulent noise on the pulses (0.6 at 600 Hz). |
| `radiationHz` | The tailpipe's treble tilt (500, calibrated). |
| `level` | Overall exhaust level. |

**Other sections**

| Section | Fields |
|---|---|
| `intake` | `level` (relative to the exhaust at full load), `intakeDeg`, `runnerLengthM`, `airboxHz`, `snorkelLengthM`, `mouthDiameterM`, `filterLowpassHz`. Mid-engine cars, where the intake is near the cabin, want a higher level. |
| `mechanical` | `combustion`, `valvetrain`, `injectors` (0 for port injection), `blockHz`, `bayLowpassHz`. |
| `idle` | `roughness` (cycle-to-cycle variation), `lope` (0-1, big-cam lope). |
| `overrun` | `pulseLevel` (off-throttle pulse strength), `burble` (0-1, overrun pops). |
| `forcedInduction`, turbo | `{"type": "Turbo", count, pulseDamping (0-1), dampingHz, whistleHz: [low, high], blowOff: {type: "atmospheric" \| "recirculating" \| "flutter", level, variants}}` |
| `forcedInduction`, supercharger | `{"type": "Supercharger", kind: "roots", rotorLobes, driveRatio, pulsesPerRev (default 2 x lobes), whineRpm: [low, high]}` |
| `limiter` | `type`: `"fuelCut"`, `"ignitionCut"` (afterfire pops, `popChance`) or `"softCut"`.<br>`free` and `load`: `{bounceHz, dropRpm, cutShare}` for free revving and in gear.<br>`cutLevel`: pulse strength of a cut cylinder. |
| `loops` | `rpmPoints` (default: idle to limiter, about 1.33x apart), `seconds` (1.0), `limiterSeconds` (1.25), `offThrottle` and `limiter` (false to skip, as traffic does). |
| `loudness` | `interior: {idleDbA, fullThrottleDbA, cruiseDbA, source}` from magazine tests, `exterior: {stationaryDbA, atRpm, source}`, `loadRangeDb`. |

## Loudness calibration

Each loop is stored at the same A-weighted level; its sheet `gain` sets how loud it plays. The level
model goes through the car's measured interior idle and full-throttle levels:

```
level(rpm, load) = idle dBA + slope * log10(rpm / idle rpm) + loadRangeDb * (load - 0.15)
slope            = (full throttle dBA - idle dBA - 0.85 * loadRangeDb) / log10(limiter / idle)
gain             = 10 ^ (0.5 * (level - 95) / 20)
```

- **Compression (0.5, an assumption).** Each real decibel becomes 0.5 dB in game, so idle is still
  heard next to full throttle (a real 30 dB range becomes 15 dB).
- **Reference (95 dBA).** Every car uses the same reference, so a car measured louder plays louder.
- **`loadRangeDb` (12, an estimate).** The difference between closed and full throttle at the same rpm.
- **Missing data.** When a car has no measured levels, the defaults (58 and 88 dBA) are estimates.
  Say so in `notes`.
- **The GT12.** Its 61 and 92 dBA are estimates: no magazine measurement of the 812 Superfast is on
  file yet.

## Calibration against real recordings

Only freely licensed recordings were downloaded, into the working scratch area. They were used only to
measure, and they aren't in the game or the repository.

| Recording | Engine | Licence | Used for |
|---|---|---|---|
| "2008 BMW M3 E92 s65 V8 Exhaust Sound Recordings (Raw WAV Files)" by Nate Lee, archive.org item `2008-bmw-m3-e92-s65-exhaust-sound-recordings`: `IDLE` (91 s) and a drive (11 min) | BMW S65 4.0 L NA cross-plane V8 | CC BY 4.0 | Engine orders at idle, and band balance at idle and under acceleration |
| Wikimedia Commons: "BMW M3 (G80) Competition with Fi Exhaust", "BMW M4 Competition", "BMW M5 Competition with Fi Exhaust" (engine and exhaust sound; audio tracks of videos by FiExhaust and LA VLOGS) | BMW twin-turbo inline-6 and S63 V8, two with aftermarket exhausts | CC BY 3.0 | Qualitative only: rev blips with wind and crowd noise, too unsteady to track rpm |

**Method.**
- **Engine orders.** The engine speed of a steady stretch is found from its harmonic comb (half-order
  spacing). Each half order's level is then read relative to the firing order, with its
  harmonic-to-noise ratio.
- **Band balance.** 1/3-octave levels from 50 Hz to 8 kHz, relative to the total, compared with the
  synthesized loop at the same rpm and load, using the same engine layout (BMW S65: firing order
  1-5-4-8-6-3-7-2, cylinders 1-4 and 5-8 on separate banks, cross-plane).
- **What was tuned.** These became the defaults for every car:
  - pulse sharpness (rise 4°, decay 30°, no extra softening off throttle);
  - pulse-to-pulse variation (timing 0.8°, duration ±25%);
  - turbulent flow noise (0.6, centred at 600 Hz);
  - cylinder spread (6%);
  - mechanical noise levels (combustion 0.05, valvetrain 0.008, injectors 0.006, heard through a
    2.5 kHz engine-bay low-pass);
  - an air-filter low-pass (2.2 kHz);
  - the tailpipe radiation tilt (corner 500 Hz).

**Results.**

| Measure | Before | After |
|---|---|---|
| Band-level error, S65 idle 783 rpm (RMS, 100 Hz-5 kHz) | 7.6 dB | 4.6 dB |
| Band-level error, S65 accelerating about 3,500 rpm | 6.8 dB | 4.4 dB |

Engine orders at idle (dB relative to the firing order, 4):

| Order | 3 | 4.5 | 5 | 5.5 | 6 | 6.5 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Recording | -26 | -28 | -15 | -14 | -19 | -19 | -21 | +3 | -23 | -23 | -20 | -18 |
| Synthesis | -23 | -23 | -23 | -22 | -36 | -11 | -18 | -1 | -25 | -47 | -28 | -4 |

**What matched.**
- The firing order and its second harmonic dominate. Order 8 is within 4 dB.
- The half orders sit in the same -11 to -23 dB range.
- Orders 3, 7 and 9 are within 3 dB.
- The broad shape: a peak at the firing frequency, a plateau from 200 Hz to 1.3 kHz, and a fall above
  1.6 kHz.
- The real exhaust's sound above about 500 Hz is mostly noise between the harmonics, not clean
  harmonics. The first synthesis was far too tonal there, which is why the flow noise and
  pulse-to-pulse variation were added.

**What didn't match.**
- **Individual orders.** Order 12 is 14 dB too strong and orders 6 and 10 are 17-24 dB too weak. That
  is the resonance pattern of that particular exhaust, which can't be modelled without its pipe
  lengths.
- **Two recordings disagree.** The idle recording wants more treble than the acceleration recording.
  The 500 Hz radiation corner splits the difference. The drive recording has wind rumble on its
  clip-on microphone below about 300 Hz, which makes the synthesis look 8-10 dB short there.
- **The exhaust merge.** The S65's half orders show a strongly merged exhaust (an X-pipe crossover
  about 0.5, versus +3 to +5 dB half orders with separate banks). The definitions use 0.3-0.5 for
  cross-plane cars with X-pipes.
- **No V12, flat-plane or turbo calibration.**
  - The V12 and flat-plane recordings found on Commons (Ferrari 812 Superfast, 599, F12; McLaren 765LT
    and 720S; Shelby GT350) couldn't be downloaded: Commons' file server kept refusing this connection
    for over an hour (HTTP 429, retry after 10 minutes).
  - The BMW turbo clips were too noisy to measure.
  - The GT12's V12 uses the cross-plane-calibrated defaults plus its own derived firing pattern.
  - A V12 recording run through `--analyze` is the obvious next calibration.

## Tuning (`audio = { ... }` in the car config)

| Setting | Meaning |
|---|---|
| `engineVolume` | Scales all engine loops (1 = the sheet's calibrated gains). |
| `loadAttack`, `loadRelease` | How quickly the on/off blend follows the throttle. |
| `minPitch`, `maxPitch` | Playback-speed limits. |
| `limiterHold` (0.3 s), `limiterAttack` (40/s, about 25 ms), `limiterRelease` (10/s) | The limiter switch. The simulation cuts fuel about 4 times a second on the limiter, so the hold must bridge the gaps. |
| `turboVolume`, `blowOffVolume`, `blowOffMinBoost`, `superchargerVolume` | Forced-induction layers. Only turbo or supercharged engine sheets use them. |
| `shiftCut*`, `shiftClunkVolume`, `crackle*`, `bump*`, `squeal*`, `roadVolume`, `windVolume`, `whine*` | As before. |
| `interior` | Cockpit-camera levels and equaliser. |
| `idleLevel`, `rpmCurve`, `redlineRpm`, `offThrottleLevel` | Only for an old-style sheet without gains. |

After changing settings, run `python3 tools/audio_preview.py` to hear the result.

## Real recordings in the game later

Recorded loops would still sound more real than any synthesis. The pipeline can take them: the packs,
sheets, gains, limiter loops and mixer don't care where a loop came from. What's needed:
- steady-rpm loops at 6-10 engine speeds, on throttle (under load, ideally on a dyno) and off throttle;
- limiter recordings, free and in gear;
- the one-shots.

Use only recordings you make yourself or have a licence to use in a Roblox game. Nothing ripped from
games or videos. The recordings used for calibration here are for measurement only; they aren't in
the game.

## Not done yet

- **Untested in Roblox.** In particular:
  - how Roblox times `PlaybackRegion` and `LoopRegion` (loops now start exactly at their loop start,
    with 0.25 s of matching audio after the end);
  - how its reverb and echo sound against the preview's approximation;
  - whether playback speeds up to 4 (the supercharger whine at high rpm) are honoured.
- **The six new cars' definitions are drafts.** `RefM3G80`, `RefM5F90`, `RefC8Stingray` and
  `RefCamaroZL1` exist only to test the format on each layout. `RefC8Z06` and `Ref720S` are not written:
  their firing orders and cylinder numbering must come from the research notes. Then `Engines_Pack1`
  is built once and uploaded once.
- **Interior sound.** It is the exterior sound through an equaliser. Mid-engine cars would want their
  own intake-heavy cabin mix.
- **Other players' cars** make no sound yet. TrafficMix's Doppler and distance code is ready to reuse
  for them.
