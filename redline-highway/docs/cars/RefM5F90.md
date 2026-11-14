# Brandt Nordwind RS

*Internal ID `RefM5F90`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/RefM5F90.luau`.
Engine sound: `assets/audio/engines/RefM5F90.json`. Research: `research_notes/cars/RefM5F90.json` and `.md`.*

An original four-door super-saloon from the fictional German maker Brandt. Its engineering follows the
public figures for the BMW M5 Competition (F90), LCI (2021-2023), EU specification. No BMW names, logos,
body design or assets are used in the game. Real names appear only in the docs, as engineering references.

Default set-up: M xDrive in **4WD Sport**, the 8-speed torque-converter automatic in D with Drivelogic 2 shift
times, the M Driver's Package **305 km/h** limiter, and the exhaust and Active Sound Design in **SPORT**.

Tags used below and in the configuration:
- **[F]** factory figure (BMW AG or BMW of North America);
- **[P]** published third-party figure, or BMW material for the sister S63TU engine;
- **[M]** measured by a magazine or independent test;
- **[E]** simulation estimate (method given);
- **[A]** assumption.

## Published figures

| Item | Value | Tag |
|---|---|---|
| Engine | S63B44T4: 4,395 cc 90° V8, twin-turbo hot-V, bore 89.0 mm, stroke 88.3 mm, compression 10.0:1 | F (V angle, hot-V: P) |
| Max power | 460 kW / 625 PS / 617 hp at 6,000 rpm | F |
| Max torque | 750 Nm from 1,800 to 5,860 rpm (LCI; 5,800 pre-LCI) | F |
| Full-load curve | 400 Nm at 1,000 rpm, 480.5 at 1,244, 600 at 1,500, 750 from 1,791, 732.5 at 6,000, 647.4 at 6,600, 587 at 7,000, 564 at 7,198 rpm | F, read from BMW's chart |
| Redline / cut-off | 7,200 rpm | F (BMW NA, M5 CS) / P (S63TU manual) |
| Firing order | 1-5-4-8-6-3-7-2; cylinder 1 at the front of the right bank, right bank 1-4, left bank 5-8 | P (S63TU manual) |
| Exhaust manifolds | Cross-bank: cylinders 1/6 and 4/7 feed the twin-scroll turbo over the left bank; 2/8 and 3/5 feed the turbo over the right bank | P (S63TU manual; F90 keeps them, F) |
| Turbos | Two twin-scroll; no blow-off valve; 1.69 bar boost quoted for the base M5 | F / P / F |
| Gearbox | 8-speed M Steptronic (ZF 8HP): 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640; reverse 3.478; final drive 3.154 | F |
| Drive | M xDrive: rear-biased AWD with an electronically controlled multi-plate centre clutch (4WD / 4WD Sport / 2WD); Active M Differential at the rear | F |
| Weight | 1,895 kg DIN; 1,970 kg EU (with driver); US curb 4,345 lb (1,971 kg) | F |
| Weight distribution | 54.4 % front / 45.6 % rear | F (BMW NA) |
| Length × width × height | 4,983 × 1,903 × 1,469 mm | F |
| Wheelbase / track | 2,982 mm / 1,625 front, 1,594 rear | F |
| Overhangs | 888 mm front, 1,113 mm rear | F |
| Tyres | 275/35 ZR20 on 9.5J front, 285/35 ZR20 on 10.5J rear; Pirelli P Zero ★ on test cars | F / M |
| Brakes | M Compound: 395 × 36 mm front with 6-piston fixed calipers, 380 × 28 mm rear with 1-piston floating | F |
| Aero | CdA 0.77 m², Cd 0.31 | F |
| Steering | 14.3:1 overall; 12.6 m turning circle | F |
| 0-100 / 0-200 km/h | 3.3 s / 10.8 s | F |
| 0-60 mph | 3.1 s (BMW NA) | F |
| Top speed | 250 km/h, or 305 km/h with the M Driver's Package (BMW Ireland: 304) | F |
| Car and Driver, 2021 Competition | 0-60 mph 2.8 s; 0-100 mph 6.7 s; ¼ mile 10.9 s at 128 mph (all with a 1-ft rollout); 70-0 mph 139 ft; skidpad 1.00 g | M (second-hand) |
| Car and Driver comparison, 2021 | 0-60 mph 2.7 s; ¼ mile 10.8 s; skidpad 0.95 g | M (snippets) |
| The Citizen, 2021 LCI | 0-100 km/h 3.28 s; ¼ mile 11.22 s at 206.6 km/h; 60-100 km/h in 3rd 2.06 s; 80-120 km/h in 4th 2.38 s; 100-200 km/h 7.75 s | M |
| Cabin sound | C/D 2018 base M5: 74 dBA full throttle, 80 dBA peak in Sport, 66 dBA at 70 mph. auto motor und sport, LCI Competition: idle 48, max 81, 69 at 100 km/h, 71 at 130 km/h | M |
| Exterior sound | 86 dBA stationary; 71 dBA pass-by | F (via auto motor und sport) |

Sources: [BMW specifications 06/2020](https://press.bmwgroup.com/global/article/attachment/T0309233EN/452618),
[BMW specifications 09/2018](https://press.bmwgroup.com/global/article/attachment/T0286586EN/419604),
[BMW NA 2021 press kit](https://newsroom.bmwgroup.com/americas/the-new-2021-bmw-m5-sedan/),
[BMW S63TU training manual ST1202](https://archive.org/download/BMWTechnicalTrainingDocuments/ST1202%20S63TU%20Engine/S63TU-engine-manual.pdf),
[The Citizen test data](https://citizen.co.za/wp-content/uploads/2021/05/M5Compdata.pdf),
[Car and Driver 2018 test (forum repost)](https://www.bmwfanatics.co.za/threads/new-m5-performance-tested.84850/),
[Guys Gab, quoting C/D 2021](https://www.guysgab.com/review-2021-bmw-m5-competition/),
[auto motor und sport data](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m5-competition/technische-daten/).
The full list, with every figure's source, is in the research notes.

## Estimates and how they were made

| Item | Value | How |
|---|---|---|
| Simulated mass | 1,970 kg | DIN kerb weight plus a 75 kg driver [A]; equals BMW's EU figure |
| Centre of mass | 0.50 m high; 1.360 m behind the front axle | Height: research estimate for a large saloon with a high-mounted hot-V V8 and a CFRP roof. Position: from the 54.4/45.6 split |
| Rotational inertia | about 3,700 kg·m² yaw, 680 roll, 3,250 pitch | From a 1.85 × 0.85 × 4.37 m mass box. Yaw is the research's box estimate m(L²+W²)/12 = 4,660, scaled by 0.8 for mass between the axles |
| Full-boost torque curve | 750 Nm from 1,000 to 5,860 rpm, then BMW's chart. Below 1,000 rpm: 562 at 600 and 656 at 800. At 1,244 rpm: 763.5 | Built by the procedure in VEHICLE_CONFIG.md, so the game's steady curve passes through every chart node. The 1,244 rpm value makes the linear boost ramp hit the chart's 480.5 Nm. Below 1,000 rpm it gives the research's estimates of 300 and 350 Nm |
| Turbo | off-boost share 0.533; boost from 1,100 to 1,800 rpm; 1.75 bar; spool 0.6 s; dump 0.3 s | Share: chart, 400 Nm at 1,000 rpm / 750 [F]. Start and boost: research. Spool: "essentially no lag" in reviews. Slow dump: no blow-off valve |
| Idle / limiter | 600 rpm; cut at 7,200, fuel back 150 rpm lower | Idle: N63/S63 family. Hysteresis: research's 150-250 rpm bounce |
| Engine inertia | 0.25 kg·m² | Research estimate 0.30. Component sum about 0.21: crank and pistons 0.08, flexplate 0.025, converter primary side with oil 0.10. Middle value |
| Engine braking | 22 + 0.0095 × rpm Nm (31 at 1,000 rpm, 79 at 6,000) | Motoring friction (about 1.6 bar FMEP at 6,000 rpm), plus closed-throttle pumping (kept low by VALVETRONIC), plus accessories. Gives 0.10 g lifting off in 3rd at 120 km/h |
| Gearbox | 88 % efficient; 0.20 s upshifts and downshifts at 40 % torque reduction; downshift blip 0.3 | Efficiency: research, 0.85-0.90 with transfer case and two axle drives. Shifts: Drivelogic 2, research's 0.22 s |
| Converter and lock-up | stall 2,500 rpm, torque ratio 1.9, coupling 0.87; lock-up from 12 km/h in 1st, 0.4 s, 1,100 Nm | BMW: lock-up "fully engages once the car has pulled away" [F]. Stall: research's 2,500-3,000 rpm flare |
| Automatic shift points | up 1,700 rpm (light) to 7,050 (full); down 1,000 to 4,500 | Upshift at full throttle just before the 7,200 cut-off, as the real car does in D [P] |
| Centre coupling (4WD Sport) | base 5 % front, at most 35 %; 1.5 % slip threshold; 6,000 Nm per m/s | Max: research estimate for 4WD Sport (4WD about 50 %, 2WD 0 %). The game's coupling only reacts to slip, while M xDrive also acts ahead of it, so threshold small and coupling stiff. Up to about 10,000 Nm reaches the wheels in 1st. Above about 5,000 Nm per m/s the per-step transfer cap governs |
| Rear differential | limited slip: 100 Nm preload, 40 % power, 20 % coast lock | Approximation of the Active M Differential (0-100 % locking [F]) |
| Traction control | target slip 0.12, rate 15, recovery 4/s, headroom 1.3 | Target a little past the tyre's 0.10 peak, as launch control does. Faster recovery so one slip spike at a standing start doesn't hold the torque down for half a second |
| Springs | 61,000 N/m front, 60,700 rear | 1.7 Hz front, 1.85 Hz rear (research). The game carries the whole corner mass on the springs: 536 kg front, 449 kg rear |
| Dampers | bump / rebound 3,400 / 5,700 front, 3,100 / 5,200 rear (N·s/m) | Damping ratios of about 0.3 and 0.5 |
| Anti-roll bars, roll centres | 30,000 / 22,000 N/m; 0.07 / 0.11 m | Research (Competition: firmer rear bar [F]); double wishbone and five-link |
| Tyre (car compound `NordwindRoad`) | muLong 1.23, muLat 1.08; the rest as the shared Performance tyre | muLong fitted to C/D's 70-0 mph in 139 ft (about 1.18 g on 1,970 kg). muLat aimed at the 0.95-1.00 g skidpad once load transfer and load sensitivity take their share. Untested in Studio |
| Brakes | 4,200 Nm front, 2,200 Nm rear per wheel (66 % front); handbrake 2,200 | Research: enough to lock the wheels; ABS 12 % target slip |
| Aero | lift areas 0.05 front, 0.03 rear (about 240 N at 250 km/h) | Not published: road saloon with a boot-lid Gurney, slight net lift |
| Steering | 33° at the wheels when slow, 4.5° at 250 km/h | Mean road-wheel angle from the 12.6 m turning circle (inner 38°, outer 29°) |
| Speed at 7,200 rpm by gear | 61, 95, 142, 177, 232, 304, 370, 476 km/h | Game tyre radius 0.354 m (unloaded; the research's 0.343 m rolling radius gives 3 % less). 305 km/h comes in 7th at 5,940 rpm |
| Stand-in body | Marina Bay Blue approximation, RGB 30, 88, 170 [A] | Side profile from the research's measurement of BMW's LCI dimension drawing; roof peak = 1,469 mm |

## Validation

`tools/drivetrain_model.py RefM5F90`: a Python copy of the game's drivetrain, run at 60 frames per second
with a point-mass body. It times the better of a launch from park and a brake-torque launch, as the
factory figures use launch control.

US magazine figures use a 1-ft rollout. They are compared here with the model's time minus its own
rollout time (about 0.33 s); the tool's table compares them with a standing start.

The last column uses a scratch copy of the model with one shared-code bug fixed (see "Shared-code
problem").

| Test | Factory | Magazine | Model (shared code) | Model, double count fixed |
|---|---|---|---|---|
| 0-60 mph, standing start | 3.1 s | | 3.37 s (+0.27) | 3.18 s (+0.08) |
| 0-60 mph, 1-ft rollout | | 2.8 s C/D (2.7 s comparison test) | 3.03 s (+0.23) | 2.85 s (+0.05) |
| 0-100 km/h | 3.3 s | 3.28 s The Citizen | 3.55 s (+0.25) | 3.37 s (+0.07) |
| 0-100 mph, 1-ft rollout | | 6.7 s C/D | 7.05 s (+0.35) | 6.75 s (+0.05) |
| 0-200 km/h | 10.8 s | | 11.05 s (+0.25) | 10.70 s (-0.10) |
| ¼ mile, standing start | | 11.22 s at 206.6 km/h The Citizen | 11.47 s at 203.8 (+0.25) | 11.28 s at 205.4 (+0.06) |
| ¼ mile, 1-ft rollout | | 10.9 s at 206 km/h C/D | 11.13 s (+0.23) | 10.95 s (+0.05) |
| Top speed | 305 km/h, limited | | 302.7 km/h on the limiter, 7th, 5,960 rpm | same |
| 70-0 mph braking | | 42.4 m (139 ft) C/D | 42.1 m (-1 %) | 42.2 m |
| 100-0 km/h braking | | none (C/D scales to about 33.5 m) | 33.3 m | 33.3 m |
| 60-100 km/h in 3rd | | 2.06 s The Citizen | 2.18 s | 2.10 s |
| 80-120 km/h in 4th | | 2.38 s The Citizen | 2.65 s | 2.58 s |
| 100-200 km/h from 3rd | | 7.75 s The Citizen | 7.65 s | 7.47 s |

Other results (shared code):
- **Launch.** From park the converter flares to about 1,800-2,300 rpm while traction control holds the rear tyres
  near 11 % slip and the coupling sends 20-26 % forward. The lock-up closes at 26 km/h, 0.87 s in. Shifts
  come at 7,060-7,100 rpm and take 0.20-0.22 s.
- **Brake-torque launch.** The engine holds 1,890 rpm against the brake with full boost built.
- **Idle and creep.** Idle is 566-596 rpm in park; drive with the brake held, 565 rpm. Creep reaches 4.8 km/h.
- **Boost.** Floored in 3rd, 90 % boost comes after 0.83 s from 1,440 rpm and 0.50 s from 2,760 rpm.
- **Engine braking.** Lifting off in 3rd at 120 km/h gives 0.10 g.
- **Free rev in neutral.** The limiter is reached in 0.38 s; the engine then swings 7,034-7,479 rpm.
- **Held on the limiter in 2nd.** The engine swings 7,050-7,217 rpm. The cut flag is on 83-85 % of frames
  and its longest gap is 0.083 s, so the sound mixer's 0.3 s limiter hold never drops out.

**What the numbers say:**
- **With the shared code**, every acceleration figure is a uniform 0.23-0.35 s slow, outside ±0.15 s. The
  cause is the engine inertia being counted twice (next section). The gap can't be closed honestly with
  this car's estimates:
  - with the engine inertia at the research's 0.30 it gets worse;
  - grip, the coupling and traction control are already at believable limits;
  - more grip would break the braking match.
- **With the double count fixed**, the same configuration lands within 0.1 s of every factory and magazine
  acceleration figure.
- **Braking** matches C/D within 1 %.
- **Top speed** sits on the electronic limiter. The model settles 2.3 km/h under 305 because the limiter
  closes the throttle over its last 3 km/h.
- **The rolling 80-120 km/h** is 0.2 s slower than The Citizen measured. This is consistent with two things:
  - the game's unloaded tyre radius, which costs about 3 % of wheel force;
  - real M engines often making a little more than their brochure torque.

### Shared-code problem: engine inertia counted twice when the clutch or lock-up is closed

In `VehicleSimulation.luau`:
- The lock-up (or dual-clutch) torque already pays for the engine's own acceleration:
  `engine.omega += h * (engineTorque - engineLoad) / engineInertia`.
- The wheel update then adds `engineInertia × ratio²` to the driven wheels again while `locked`
  (lines 479 and 483). `tools/drivetrain_model.py` does the same (lines 657 and 659).

The effect: in 1st gear this car behaves as if it were about 520 kg heavier. With traction control off,
the model's 1st-gear pull at 34 km/h matches the twice-counted prediction, not the once-counted one:
- inertia 0.30: 0.924 g measured; 0.938 g predicted twice-counted, 1.124 g once;
- inertia 0.15: 1.113 g measured; 1.124 g predicted twice-counted, 1.248 g once.

**Proposed change:**
- **Luau, `VehicleSimulation.luau`:**
  - Replace lines 475-484 (the `if w.driven and automatic then ... end` block) with
    `if w.driven and automatic and not shifting then inertia += tr.turbineInertia * efficiency * ratio * ratio * w.share / 2 end`.
  - Delete `local locked = false` (line 387) and the two `locked = ...` assignments (lines 434 and 438).
  - `lock` (line 432) is then unused.
- **Python, `tools/drivetrain_model.py`:** make the same edit at lines 653-659 (`I += tr.turbine_inertia * eff * ratio *
  ratio * w.share / 2` in the automatic branch, `I = w.I` otherwise).

**Tested** in a scratch copy on all seven configurations:
- no instability; idle and free revs are unchanged;
- 0-100 km/h: RefM5F90 3.55 → 3.37 s, GT12 3.37 → 3.33 s, RefC8Stingray 4.20 → 4.08 s, RefM3G80 4.45 → 4.40 s.

## Sound design

The engine sheet is synthesized by `tools/synth_audio.py` from `assets/audio/engines/RefM5F90.json`. I
can't listen to audio, so everything below was checked by measurement.

**The definition.**
- **Firing order and crank.** Firing order 1-5-4-8-6-3-7-2 with BMW's numbering (right bank 1-4, left bank
  5-8) on a cross-plane crank. That gives even 90° firing. The per-bank gaps are the uneven 180-270-180-90
  (right) and 180-90-180-270 (left).
- **Exhaust manifolds.** Four scroll collectors: 1/6 and 4/7 into the turbo over the left bank, 2/8 and 3/5
  into the turbo over the right bank. `--check` and a direct calculation give each scroll a pulse every 360°.
  The left-bank turbo gets pulses at 0/180/360/540° and the right-bank turbo at 90/270/450/630°: even 180°
  trains, 90° apart.
- **Exhaust after the turbos.**
  - One branch per turbo, mirror images of 3.45 m, coupled weakly below about 250 Hz. This stands for the
    Helmholtz resonator between the rear silencers.
  - Valves are open under load (above 50 % load) and above 3,500 rpm: SPORT.
  - Twin-scroll turbines take 60 % of the sharp part out of the pulses.
  - The whistle is subdued, and there is **no blow-off valve**, so the sheet has no blow-off sounds.
- **Limiter.** A fuel cut at 7,200 rpm, with a baked bounce:
  - 14 Hz and 250 rpm when free revving;
  - 10 Hz and 150 rpm in gear.
- **Overrun.** A light burble, as in SPORT (EU particulate filter).
- **Loudness.** The research's estimate of Car and Driver-comparable cabin levels: idle 47 dBA, full throttle
  79 dBA, 67 dBA at 70 mph. auto motor und sport's measured 48 and 81 dBA corroborate it.

**Active Sound Design.** The measured cabin levels include BMW's speaker layer, which adds at most about 6 dB
at full throttle in SPORT [E]. The cockpit camera therefore plays the engine at its calibrated level with
the equaliser at +5 dB below 400 Hz (ASD's low engine orders), -2 dB to 4 kHz and -12 dB above (a
well-insulated cabin). In the cockpit render, the share of full-throttle energy below 400 Hz rises from 42 %
to 68 %, while the A-weighted level stays the same.

**Measured checks** (scripts in the build scratch area):

| Check | Result |
|---|---|
| Firing frequency | The order-4 peak sits at rpm/15 in every steady loop: 40.0 Hz at 600 rpm up to 480.0 Hz at 7,200 rpm |
| Engine orders, both branches heard (dB re order 4) | Order 8 from -15 to +6. Order 2 from -8 to -31 and order 6 from -3 to -29: weaker, as the research expects. Half orders (0.5-3.5) 12-30 dB under, strongest around 3,150-4,150 rpm |
| Cross-bank manifold, one tailpipe branch | Half orders 16-36 dB under the firing order, and order 2 +2 to +7 (each turbo like an inline-4). The same engine with classic per-bank manifolds: half orders -13 to +3 dB, the cross-plane burble |
| Unequal branches | Branches of 3.4 and 3.5 m let order 2 rise to +5 dB at 7,200 rpm, near the pipes' third resonance. Hence the mirror-image branches |
| Loop seams | Jump at the loop point / 99th-percentile step: 0.01-0.81 over 23 loops. The audio stored after each loop end matches its start exactly |
| Limiter loops | Bounce 14.0 Hz (free) and 10.0 Hz (in gear); firing-frequency track 7,030-7,220 rpm; 14.5 dB level swing between firing and cut |
| Relative loudness, engine only | Idle → full throttle at 6,450-6,860 rpm: +16.0 to +16.3 dB in game, against +16.2 to +16.5 from the measured 47 → 79 dBA at the game's 0.5 compression. Coasting at 5,370 rpm: +10.0 against +9.7. On the limiter the engine is about 1.5-2 dB under full throttle (cut phases) |
| Mixer | The limiter loops take over completely (mix 1.00) through the held free rev and the 2nd-gear hold. Over the drive: no blow-off, 4 shift cracks, 8 clunks, 1 light crackle |
| Turbo whistle | 16-18 dB under the rest of the mix on full boost |
| Spectrograms | Drive: idle; the free rev rising into flat limiter lines with bounce striping; the falling overrun; the upshift sawtooth led by the firing order; downshift steps under braking; the 2nd-gear hold; the faint whistle near 7.4 kHz on boost. Tunnel: reverb fill between the portals |

**Previews.** `assets/audio/preview/RefM5F90_drive_preview.mp3` and `RefM5F90_tunnel_preview.mp3`, each with a
spectrogram. In the drive preview:
- **0 s:** idle;
- **2 s:** free rev to the limiter, held;
- **6 s:** launch through five upshifts;
- **14.5 s:** lift-off;
- **16 s:** braking;
- **19 s:** 2nd gear held on the limiter.

The click near 5.5 s is the scripted drive selecting 1st while the engine is still spinning down at about
4,000 rpm, not part of the sound.

**Sound build.** The car is built alone: `python3 tools/synth_audio.py --car RefM5F90 --dev`. The sheet points
at `Dev_RefM5F90` until the coordinator builds `Engines_Pack1`.

## Gaps

- **Acceleration in the shared model.** 0.23-0.35 s slow, from the double-count bug above. On target once it
  is fixed.
- **Rolling acceleration.** 80-120 km/h is about 0.2 s slower than The Citizen measured (tyre radius, see above).
- **Not published, so estimated:**
  - converter stall;
  - xDrive split;
  - spring, damper and bar rates;
  - centre-of-gravity height;
  - downforce;
  - Competition boost;
  - idle rpm;
  - limiter cut style and bounce;
  - flap logic;
  - ASD's exact share;
  - primary pipe lengths.
- **The game can't switch modes.** Neither EFFICIENT / SPORT / SPORT+ nor 4WD / 4WD Sport / 2WD can be
  selected; each would be another configuration or sound build.
- **Launch control rpm.** The brake-torque launch holds about 1,890 rpm (traction control limits it). The
  real car is estimated at 2,500-3,500 rpm.
- **No recording calibration.** The CC BY Commons recording still returns HTTP 429 (tried again
  2026-11-13). Car and Driver's own Competition sound levels were not found.
- **Untested in Studio.** Handling, suspension, lateral grip and the stand-in model.
- **Stand-in body.** The lower body is one box up to the 0.94 m beltline. The nose therefore reads taller
  than the real 0.77 m leading edge, and the side glass a little taller than the real one.

## What to measure in Studio

- **Telemetry overlay (T).** It shows 0-60 mph, 0-100 and 0-200 km/h, the quarter mile and 100-0 km/h. The
  HUD labels every target "factory", including the magazine figures.
- **Static loads.** About 5,257 N on each front wheel and 4,406 N on each rear wheel at rest.
- **Sound.** The cockpit camera should sound fuller and quieter in the treble than the chase camera.
- **Limiter.** Holding a gear in manual (E/Q) should bounce on the limiter at 7,200 rpm.
