# Ashcombe AR-7

*Internal ID `Ref720S`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/Ref720S.luau`.
Engine sound: `assets/audio/engines/Ref720S.json` (sheet `VehicleAudio/Sheets/Ref720S_Engine.luau`).
Research: `research_notes/cars/Ref720S.json` and `.md`.*

An original mid-engined, two-seat carbon-tub coupe from the fictional British maker Ashcombe, built to the
publicly documented engineering of the **McLaren 720S coupe (2017-2023)**. The real name appears here only as
an engineering reference; no McLaren names, logos, body design or assets are used in the game.

Tags used below and in the configuration: **[F]** McLaren figure, **[P]** published third-party figure,
**[M]** measured in a magazine or independent test, **[E]** simulation estimate (method given),
**[A]** assumption.

## Published figures

| Item | Value | Tag | Source |
|---|---|---|---|
| Engine | M840T 3,994 cc 90° V8, flat-plane crank, dry sump, two twin-scroll turbos (one per bank), port injection | F (P for crank and bank angle) | [MCL21], [PR17], [Wikipedia M840T](https://en.wikipedia.org/wiki/McLaren_M840T_engine) |
| Max power | 530 kW / 720 PS at 7,500 rpm (the 2021 coupe sheet prints 7,250 rpm) | F | [PR17], [MCL21] |
| Max torque | 770 Nm at 5,500 rpm | F | [MCL21] |
| Max revs | 8,100 rpm in 1st-2nd, 8,200 rpm in 3rd-7th | F | [PR17] |
| Boost | "over 1.3 bar" | P (uncited) | Wikipedia |
| Firing order | 1-8-3-6-4-5-2-7; cylinders 1-4 on bank 1, 5-8 on bank 2 | P | [M-Engineering](https://m-engineering.atlassian.net/wiki/spaces/MENGINEERI/pages/467730433/McLaren+Cylinder+Layout+Firing+Order) |
| Gearbox | 7-speed SSG dual-clutch (Graziano), ignition-cut shifts, launch control | F (P for Graziano) | [PR17], [MCL21] |
| Ratios / reverse / final drive | 3.98, 2.61, 1.91, 1.48, 1.16, 0.91, 0.69 / 2.80 / 3.30 | P (US OEM data) | [carspecs.us](https://www.carspecs.us/cars/2017/mclaren/720s/68778), Motor Matchup |
| Differential | Open, with Brake Steer (brakes the inside rear wheel) | P / F | [evo](https://www.evo.co.uk/mclaren/720s/engine-gearbox-technical-highlights), [PR17] |
| Weight | 1,283 kg dry (lightest), 1,322 kg dry (base), 1,419 kg DIN kerb (90% fuel) | F | [MCL21] |
| Weight distribution | 41% front / 59% rear (Autocar weighed 42/58, AMS 41.5/58.5) | F (M) | [MCL21] |
| Length × width × height | 4,543 × 1,930 × 1,196 mm (width without mirrors: P) | F / P | [MCL21], [motor1.de](https://de.motor1.com/reviews/150663/test-mclaren-720s-besser-als-der-ferrari-488/) |
| Wheelbase, overhangs | 2,670 mm; 1,058 mm front, 816 mm rear | F | [MCL21] |
| Track (contact-patch centres) | 1,674 mm front / 1,629 mm rear | F | [MCL21] |
| Ground clearance | 107 mm | F | [MCL21] |
| Tyres / wheels | 245/35 ZR19 on 19 × 9.0J, 305/30 ZR20 on 20 × 11.0J, forged; P Zero, P Zero Corsa optional | F | [MCL21], [PR17] |
| Brakes | Carbon-ceramic: 390 mm front, 6-piston; 380 mm rear, 4-piston | F | [MCL21] |
| Suspension | Double wishbones, Proactive Chassis Control II (hydraulically interlinked dampers, no anti-roll bars) | F | [PR17] |
| Steering | Electro-hydraulic, 2.46 turns lock to lock, 12.4 m turning circle | F | [MCL21] |
| Aero | No Cd or kg published. About 50% more downforce than the 650S; active wing (Driver Downforce 70-80%, DRS 30%, airbrake 100% in under 0.5 s) | F | [PR17] |
| 0-100 km/h / 0-60 mph / 0-200 km/h / ¼ mile | 2.9 s / 2.8 s / 7.8 s / 10.3 s | F | [MCL21] |
| Top speed | 341 km/h (212 mph) | F | [MCL21] |
| Braking | 100-0 km/h 30 m; 200-0 km/h 117 m in 4.6 s (2017), 122 m (2021 brochure) | F | [PR17], [MCL21] |
| Cabin noise | 95 dBA at full throttle (C/D coupe); idle 55 / 70 mph 75 dBA (unverified snippet) | M | [Motorbiscuit relaying C/D](https://www.motorbiscuit.com/dislike-neighbors-check-out-some-of-the-loudest-cars-stock-exhaust) |

Magazine tests used below (all [M]): Car and Driver 2018 coupe (0-60 mph 2.7 s with rollout, ¼ mile 10.2 s at
145 mph); Motor Trend (2.5 s, 10.1 s at 141.5 mph); Road & Track (2.7 s, 9.9 s at 148.2 mph); Autocar 2017
(0-60 mph 2.9 s and 0-100 mph 5.6 s with two people and a full tank, ¼ mile 10.4 s, 70-0 mph 39.9 m);
auto motor und sport 2018 (0-100 km/h 2.8 s, 0-200 7.4 s, 0-280 15.5 s, 100-0 33.2 m cold, 200-0 115.3 m);
Autozeitung (0-200 7.1 s); Motoring SA (0-100 2.85 s, 402 m 10.29 s); C/D 2019 Spider (70-0 mph 141 ft =
43.0 m, 99 dBA). Links are in the research notes.

## Estimates and how they were made

| Item | Value | How |
|---|---|---|
| Simulated mass | 1,494 kg | DIN kerb [F] + 75 kg driver [A] |
| Centre of mass | 0.42 m high; 1.575 m behind the front axle | Height estimated (carbon tub, dry-sump V8, "3% lower than the 650S" [F]); position from 41/59 |
| Static wheel loads | 3,005 N per front wheel, 4,324 N per rear wheel | From the above |
| Rotational inertia | about 2,150 kg·m² yaw, 460 roll, 1,810 pitch | 1.80 × 0.70 × 3.75 m mass box: dynamic index k²/(a·b) ≈ 0.84, compact mid-engined car |
| Full-load torque curve | Research estimate, steady curve exact at every point: 300 Nm at 1,000 rpm, 430 at 2,000, 600 at 3,000, 710 at 4,000, 770 at 5,500 [F], 675 at 7,500 (530 kW [F]), 605 at 8,200 | `--curve` reproduces it. Full-boost curve = research ÷ (0.39 + 0.61 × boost ceiling) below 5,000 rpm; it bulges to 863 Nm at 3,000 rpm, torque the calibration holds back by ramping boost (evo; tuners gain most at 3,700 rpm) |
| Turbo model | no-boost share 0.39 (300/770 at 1,000 rpm; 1/(1+1.3) = 0.43 agrees roughly); boost ceiling rises from 1,000 to 5,000 rpm; spool 0.8 s; dump 0.15 s | Boost must already be building by 2,000 rpm (430 Nm there, against about 300 Nm with none), so the model's boost start is 1,000 rpm; full boost about 5,000 [E research]. Electronic dump valve [F] → quick dump. In 3rd at 3,800 rpm, 90% boost after 1.3 s; at 6,600 rpm, 0.7 s |
| Engine inertia, friction | 0.15 kg·m²; engine braking 17 + 0.0091 × rpm Nm (24 Nm at 800 rpm, 90 Nm at 8,000) | Light flat-plane crank and DCT input side; friction mean effective pressure about 2.8 bar at 8,000 rpm on 4.0 L |
| Idle, limiter hysteresis | 800 rpm; 150 rpm | Not published; research: ignition cut with 100-150 rpm of bounce |
| Speed at 8,200 rpm by gear | 81, 124, 170, 219, 279, 356, 469 km/h (80 and 123 at the real 8,100 in 1st-2nd) | Game tyre radius 0.3455 m (unloaded, from the size). The research's 78-455 km/h used a 0.335 m rolling radius |
| Gearbox | 92% efficient; 50 ms shifts at 35% clutch capacity; clutch 1,150 Nm; launch clutch holds 3,500 rpm at full pedal | Typical DCT; launch rpm per research (3,000-4,000) |
| Auto shifts | Up at 8,100 rpm at full pedal (3,500 light); down at 4,900 (1,500 light) | 8,100 = the real 1st-2nd limit; margin against a 6-7 upshift at top speed (see Validation) |
| Rear differential | Limited slip, preload 0, power lock 0.25, coast lock 0, stiffness 150 | Stand-in for the open diff + Brake Steer: locks only under power when a wheel spins. Unlike Brake Steer it wastes no energy and adds no yaw on turn-in |
| Traction control | Caps torque at 1.3 × what the rear tyres can take, trims past 11% slip, rate 15/s, **recovery 8/s** | See "What was tuned" |
| Springs, dampers | 31,000 / 56,400 N/m; bump/rebound 1,850/3,100 front, 3,000/5,000 rear (N·s/m) | Research ride frequencies 1.6 / 1.8 Hz, computed on the whole corner mass (306 / 441 kg) as the game's springs carry it (the research's 27,000 / 50,000 used sprung mass); damping ratios 0.3 / 0.5 |
| Roll stiffness | Anti-roll rates 25,000 front / 18,000 rear N/m; about 1.2° of roll per g | Stand-in for PCC II's hydraulic roll coupling (no bars on the real car) |
| Tyres | AR7Road: Performance base, μ 1.42 long / 1.22 lat; AR7Track (option, not fitted): μ 1.54 / 1.29, peak 9.5% / 7°; wheel+tyre inertia 1.35 / 1.75 kg·m² | P Zero class road tyre; Corsa class ≈ 6% more grip [F statement]; inertia from ~20 / 23 kg wheel+tyre and light carbon discs |
| Brakes | 2,800 Nm front, 1,800 Nm rear per wheel (61% front); handbrake 2,200; ABS 12% | Enough to lock both axles at about 1.4 g (research) |
| Drag | CdA 0.875 m² (Cd ≈ 0.47 on an estimated 1.85 m²) | Fitted: 341 km/h in 6th at about 7,970 rpm on 530 kW. Lumps in the partly deployed wing |
| Downforce | ClA 0.25 front + 0.45 rear = 0.70 m²: 196 kg at 241 km/h, 211 kg at 250, 392 kg at 341 | Bound: the 675LT has 40% more downforce than the 650S and the 675LT-based MSO HS makes 220 kg at 241 km/h ([Wikipedia 650S](https://en.wikipedia.org/wiki/McLaren_650S)), so the 650S makes ≤157 kg there and the 720S (+50% [F]) ≤236 kg (ClA ≤0.84). Taken a little under the bound; 36% front as in the research. The research's 0.55 is also inside the bound |
| Steering | 30° lock when slow (inner 34°, outer 25.5° from the 12.4 m circle [F]); 4.5° at 250 km/h; 220°/s | Keyboard-friendly at speed, as the GT12 |
| Stand-in body | Profile from the research's photo shares; roof 1.196 m at 0.52 [F]; glass 0.31-0.70; beltline 0.62; cabin width 0.68; sill 0.107 [F] | See "Stand-in body" |
| Colour | RGB (230, 90, 20) | Approximation of Azores, an orange launch colour [A] |

## What the simulation can't represent

- **Two rev limits.** The game has one limiter per car, so 8,200 rpm. Full-throttle automatic upshifts come at
  8,100 rpm, the real 1st-2nd limit, so in normal driving 1st and 2nd never go past 8,100. Held on the limiter in
  manual mode, 1st and 2nd reach 8,200 (about 1.3 km/h more than the real car).
- **Brake Steer.** The open differential with brake-based torque vectoring is a power-only limited slip (above).
- **Active aero.** One drag area and one downforce area. The real wing changes drag and balance by mode, and the
  airbrake moves the balance about 20% rearward when braking from speed.
- **PCC II.** Interlinked hydraulic roll control is approximated with anti-roll rates.
- **Launch control.** The game launches from idle with the pedal floored; it doesn't pre-rev the engine.
- **Rolling radius.** The game uses the unloaded tyre radius, so per-gear speeds are 3% higher than the real
  car's and the drag area is fitted to that.

## Validation

`python3 tools/drivetrain_model.py Ref720S`: a line-for-line Python copy of the game's drivetrain, as a point mass
at 60 fps. Two columns of model results:
- **current shared code**, as the tool runs today;
- **with the inertia fix**, from a scratch copy of the tool with the M5 builder's proposed fix (engine inertia
  counted once with the clutch closed; see `docs/cars/RefM5F90.md`). Rerun the tool when the fix lands.

| Test | Factory [F] | Magazines [M] | Model, current | Model, inertia fixed | Verdict (fixed vs factory) |
|---|---|---|---|---|---|
| 0-60 mph | 2.8 s | — | 2.98 s | 2.97 s | +0.17 s |
| 0-60 mph, 1-ft rollout | — | C/D 2.7, R&T 2.7, MT 2.5 | 2.58 s | 2.57 s | inside the magazine range |
| 0-100 km/h | 2.9 s | AMS 2.8, Motoring 2.85 | 3.10 s | 3.07 s | +0.17 s (pre-revved start: 2.93 s) |
| 0-100 mph | — | Autocar 5.6 (2 people), C/D Spider 5.5, DragTimes 5.2 | 5.58 s | 5.48 s | inside the magazine range |
| 0-200 km/h | 7.8 s | AMS 7.4, Autozeitung 7.1 | 7.93 s | 7.82 s | +0.02 s |
| Quarter mile | 10.3 s | C/D 10.2 @ 233 km/h, MT 10.1, R&T 9.9, Autocar 10.4 | 10.45 s @ 230.5 km/h | 10.40 s @ 231.7 km/h | +0.10 s; trap −1% vs C/D |
| Top speed | 341 km/h | — | 341.2 km/h, 6th, 7,966 rpm | 341.2 km/h | +0.1% |
| 100-0 km/h | 30 m | AMS 33.2 m (cold) | 27.9 m | 27.8 m | **−7%** (with a 0.15 s pressure build-up: 29.6 m, −1%) |
| 70-0 mph | — | Autocar 39.9 m, C/D Spider 43.0 m | 34.8 m | 34.7 m | **−13%** vs Autocar (with build-up: 36.7 m, −8%) |
| 200-0 km/h | 117 m (2017), 122 m (2021) | AMS 115.3 m | 103.3 m | 103.3 m | **−12%** (with build-up: 106.9 m, −9%) |
| 0-280 km/h | — | AMS 15.5 s | 16.65 s | 16.43 s | +0.9 s vs AMS |
| 0-300 km/h | Spider 22.4 s (coupe not in the 2021 table) | motor1.de 21.4 s (inconsistent text) | 20.80 s | 20.55 s | −1.9 s vs the Spider figure |

Other results (current tool): idle 789 rpm (767-803), no creep; free rev reaches the limiter in 0.37 s and
bounces 8,029-8,563 rpm, 4.5 cuts a second; 35% pedal holds 167 km/h in 5th; launch holds about 3,100-3,200 rpm
with the clutch slipping, pulls about 1.02 g in 1st; upshifts at 75, 119, 164, 212 and 272 km/h. The optional
AR7Track tyre (inertia fixed): 0-100 km/h 2.92 s, ¼ mile 10.27 s, 100-0 km/h 25.7 m.

**Robustness.** Over 135 runs with grip ±0.02, launch rpm ±200, spool 0.7-0.9 s and inertia 0.14-0.16, 0-100 km/h
stays within 2.97-3.12 s, 0-200 within a 0.16 s band, the quarter mile within 0.14 s (traction-control recovery
8/s; with the GT12's 2/s the launch swings 3.03-3.32 s, see below).

### What was tuned, and why

Only estimates were changed; no sourced value was. Each change was measured on its own.

| Value | Start | Final | Why |
|---|---|---|---|
| Road tyre grip (μ long) | 1.45 (shared Performance) | 1.42 | The model brakes harder than the real car (below). 1.42 gives back 0.6 m of 100-0 for about 0.05 s of 0-100. Not lowered further: 1.40 puts 0-100 near +0.2 s |
| Traction-control recovery | 2/s (GT12) | **8/s** | Outside the brief's list of tunables, so flagged. At 2/s one wheelspin spike at launch held the car back for half a second, and 0-100 swung between 3.03 and 3.32 s with 1% changes to grip or 200 rpm of launch rpm (inertia-fixed model). No setting of the listed values (headroom 1.1-1.6, launch 2,800-4,200 rpm, grip 1.40-1.44) brought the median under 3.12 s. At 8/s the trim fades in about 0.12 s, like a modern traction system, and the launch is consistent |
| Auto upshift at full pedal | 8,050 rpm | 8,100 rpm | Margin at top speed: 6th tops out at 7,970 rpm, and a 6-7 upshift would strand the car near 331 km/h in 7th, which the auto mode doesn't kick down from |
| Drag area | 0.85-0.91 (research) | 0.875 | Fitted to 341 km/h in 6th on the game's tyre radius |
| Downforce | 0.55 (research) | 0.70 | Estimate from the published relative figures (above); no effect on straight-line figures |
| Tried and left at their estimates | | | Engine inertia 0.15 (0.13 is 0.02 s quicker); spool 0.8 s (0.6-0.7 change nothing measurable); launch rpm 3,500 (3,000-4,000 within ±0.05 s); TC headroom 1.3 (best of 1.15-1.5) |
| Tried and reverted | | | Shift clutch share 0.35 → 0.6, which removes the shift flare below. It also made 0-200 0.33 s quicker than McLaren's figure once inertia is fixed; this is shared behaviour, so it is reported, not tuned around |

### Braking: the gap that isn't closed

The model stops 7% short of McLaren's 30 m from 100 km/h, and 12% short from 200 km/h. The cause is the model's
brakes, not the tyre:
- **Full pressure in the first frame.** Real stops include a pressure build-up of 0.1-0.2 s. With a 0.15 s
  build-up the model gives 29.6 m (−1%).
- **ABS holds about 98% of peak grip.** The model's ABS settles at about 15% slip; the magic-formula curve is
  flat there. Real ABS cycling averages about 90-95%. That is why 200-0 stays 9% short even with the build-up.
- **Grip can't close it alone.** The acceleration figures need about μ 1.42 at the rear; matching 30 m with
  instant pressure needs about 1.30-1.33 for all four tyres. One tyre can't do both.
- **The game measures like the tool.** The in-game timer starts at the 100 km/h crossing with the pedal already
  above 0.9, so it reads fully built braking too. The keyboard brake ramps in over 0.17 s before that.

A proposed shared change is below (shared-code problem 4).

### Shift flare: a shared artefact, visible on this car

- **What happens.** During a dual-clutch upshift the clutch carries 35% of its capacity: 400 Nm, against this
  engine's 620-770 Nm. So the engine flares about 200 rpm (to 8,213 rpm on the 1-2 shift) instead of being pulled
  down to the new gear.
- **The limiter.** The flare hits the 8,200 rpm limiter. The limiter cut closes the throttle, and the turbo
  model dumps half the boost (0.99 → 0.50), so each new gear starts by re-spooling.
- **The sound.** The mixer also switches to the limiter loops for about 0.3 s after each full-throttle upshift.
- **What a real shift does.** A real ignition-cut upshift pulls the engine down and keeps the boost.
- **Tested fix.** Trimming engine torque to the shift clutch's capacity during an upshift: no limiter cut, boost
  held at 0.99, and 0-100 3.05 s, 0-200 7.55 s, ¼ mile 10.28 s for this car (inertia fixed). That is 0.25 s
  quicker than McLaren's 0-200 figure and closer to AMS's 7.4 s. See shared-code problems 1-3.

## Sound

### Acoustic definition (`assets/audio/engines/Ref720S.json`)

Every number has a source or an [E]/[A] note in the file's `notes`. In short:
- **Firing.** Firing order 1-8-3-6-4-5-2-7 [P]; cylinders 1-4 on bank B1 and 5-8 on B2 [P/A]; 90° V with a
  flat-plane crank [P].
- **Exhaust path.**
  - Each bank feeds its own twin-scroll turbo [F]. The scroll pairing is the research's estimate: 1+4 and 2+3,
    5+8 and 6+7 [E]. These are four scroll collectors with 0.42 m primaries.
  - Then the catalysts and one rear silencer, modelled as an H-pipe-like 25% crossover below 350 Hz [E].
  - Two large tailpipes high in the centre [P]: 1.7 and 1.95 m long, 105 mm across, 0.05 m apart in distance to
    the listener [E].
  - Bypass valves assumed to open above 4,000 rpm or 60% load [A]: the valve hardware isn't documented.
- **Turbos.** `pulseDamping` 0.6 above 200 Hz [E]. Whistle 2.6-8 kHz by boost [E] (MHI turbos rated to
  160,000 rpm). Broadband whoosh 0.13 [E] (evo's "rushing whoosh", Autocar's "whoosh and fizz").
- **Lift-off.** A "flutter" one-shot stands in for wastegate and dump-valve chatter [A]. The car has electronic
  wastegates and dump valve [F], but no source read describes the sound.
- **Character.** Rasp 0.45 (Autocar: "more rasp"; motor1.de: "a waspy racing motorbike"). Idle roughness 0.09
  ("harsh and faintly gravelly", evo). Light overrun burble 0.08 [A]. Port injection, so no injector ticks [F].
  Intake 0.2: the plenum sits behind the cabin, but the compressors damp the induction pulses [E].
- **Limiter.** Ignition cut at 8,200 rpm [F/E]: free revving bounces 9 times a second by 250 rpm; in gear,
  7 times a second by 130 rpm (research: 100-150 rpm); light afterfire (5% of cut firings).
- **Loudness.** Car and Driver's 95 dBA at full throttle [M]; idle 55 dBA (unverified snippet).
- **Loops.** Ten engine speeds, 800-8,200 rpm.

`python3 tools/synth_audio.py --check Ref720S`:
```
firing gaps: 90-90-90-90-90-90-90-90
bank sequence: 1B1 8B2 3B1 6B2 4B1 5B2 2B1 7B2         (alternates banks: flat-plane, no warning)
bank B1 pulse gaps: 180-180-180-180  (fires 1-3-4-2 like an inline-4); bank B2 the same (8-6-5-7)
each scroll [1,4] [2,3] [5,8] [6,7]: 360-360 (even)
```
Built alone with `--car Ref720S --dev`: `assets/audio/dev/Dev_Ref720S.flac`, 32.3 s, 1.80 MB. It holds 20 engine
loops, 2 limiter loops, a whistle loop and 3 flutter one-shots.

### Checks by measurement (I can't listen; this is what was measured)

- **Firing frequency and orders.** Each loop was resampled to crank angle (the synthesizer's order analysis).
  - **Firing frequency.** Order 4 is the firing frequency: rpm × 4 / 60, so 53 Hz at idle and 547 Hz at 8,200.
  - **Half orders.** Orders 0.5, 1 and 1.5 sit 25-57 dB under order 4, as a flat-plane crank should.
  - **Order 2.** Order 2 is each bank's inline-4 pattern, which the banks carry to their own tailpipes. It is
    -25 to -32 dB at idle-2,000 rpm, where the shared silencer and the out-of-phase banks cancel it. It rises to
    about -10 to +6 dB from 3,600 rpm, as the crossover fades and the pipes' path difference stops cancelling it.
    That is the "waspy motorbike" edge.
  - **Harmonic-to-noise.** Order 4 stands 31-58 dB above the noise between harmonics.
- **Turbo damping of the high harmonics.** The same loops were rendered with and without the turbines' pulse
  damping (identical random draws).
  - Harmonics from about 270 Hz up lose 8-10 dB: at 4,700 rpm, 313-2,507 Hz all lose 8-9 dB.
  - Energy above 2 kHz falls 8.0 dB at 2,000, 4,700 and 8,200 rpm.
  - The low firing frequency at 2,000 rpm (133 Hz) loses only 2.5 dB.
  - So the turbos smooth the top end and leave the low pulse alone. That is less burble and more hiss, as
    expected for this layout.
- **Relative levels.**
  - **Loop gains.** -14.9 dB at idle on throttle to 0 dB at 8,200 rpm. The model maps that to 55 dBA at idle
    (load-blended) and 95 dBA at full throttle at the limiter (C/D). Off-throttle loops are 6 dB under
    on-throttle loops.
  - **Drive preview** (A-weighted):
    - Idle to full throttle spans 20.7 dB in game, about 41 dB real at the 0.5 compression.
    - The limiter hold is within 0.5 dB of full throttle.
    - The car is about 2.5 dB louder than the GT12 at full throttle (95 against its estimated 92 dBA).
  - **Whistle.** At `turboVolume` 0.42 it carried a fifth of the energy at full boost, only 3-7 dB under the
    engine. Reduced to 0.16: about 12-15 dB under, clearly there without screaming.
  - **Flutter.** At `blowOffVolume` 0.5 it was barely above coasting: its RMS is about 1/20 of its peak, being
    short chuffs. Raised to 0.85.
- **Spectrograms viewed:** `assets/audio/preview/Ref720S_drive_preview_spectrogram.png` and
  `Ref720S_tunnel_preview_spectrogram.png`, plus zooms of the free rev and the lift-off.
  - **Free rev.** Idle → limiter in 0.35 s, then a regular cut pattern of about 9 gaps a second.
  - **Launch.** The whistle climbs to 8 kHz and holds at full boost.
  - **Lift-off.** At the 14.5 s lift, a comb of 20-25 chuffs a second appears in the 1-5 kHz region and decays
    over about 0.4 s.
  - **2nd-gear limiter hold.** The cut pattern; the whistle drops out because the model's cut dumps boost
    (shared problem 3).
  - **Tunnel.** Low-mid build-up and reverb smear between the portals (3.7-9.1 s).
  - **Upshifts.** The whistle dips and re-spools at each one, and the limiter loop blips (the shift flare above).
- **Seams.**
  - **Joint high frequencies.** Every loop was played twice in a row, and the high-frequency (>4 kHz) energy
    at the joint compared with every 2 ms window of the loop: the worst joint sits at the 96.6th percentile.
    A click would sit at the 100th.
  - **Joint step.** The step at the joint is at most 0.49 of the loop's largest sample step.
  - **Synthesizer's seam ratio.** 0.00-0.79, except on_3600 at 1.26: a large ordinary step (0.49 of the
    largest), not a click.
  - **Stored rolls.** The pre-roll and post-roll match the loop's end and start.
- **Limiter loops.** Envelope peaks at 9.0 Hz (free) and 7.0 Hz (in gear), with a range of about 15 dB.
  - **Whistle loop.** A 4,569 Hz tone, pitched 2.6-8 kHz in game.
  - **Flutter shots.** 0.70 s each, chuffing 15.7, 20.0 and 24.3 times a second.

**Not checked:** how it actually sounds; no listening was possible. Calibration against a real 720S recording
wasn't possible either. Commons still answers HTTP 429 for the two CC BY 3.0 files, and both are aftermarket
exhausts anyway.

### Mixer settings (`audio` in the config)

- **Sheet.** `engineSheet = "Ref720S_Engine"`, `redlineRpm = 8200`.
- **Limiter.** Hold 0.3 s (the simulation cuts about 4.5 times a second), attack 40/s, release 10/s.
- **Turbo.** Whistle 0.16; flutter 0.85 from 40% boost.
- **Shifts.** Shift crack 0.6 for 0.05 s, the length of the shift (ignition-cut shifts [F]).
- **Overrun.** Light crackle (0.3 from 4,000 rpm, 8 a second) [A].
- **Gearbox whine.** Pitched by a 10-tooth pinion (10:33 = 3.30) [E].
- **Cockpit.** Engine 0.9 and a softer treble cut (-9 dB): the engine sits right behind the cabin glass.

Previews: `assets/audio/preview/Ref720S_drive_preview.mp3` and `Ref720S_tunnel_preview.mp3`. They were made
with `--only drive` and `--only tunnel` so the shared traffic preview wasn't rewritten. The dev sheet points at
`Dev_Ref720S`, which the game can't play until the coordinator packs `Engines_Pack1`.

## Stand-in body

- **Profile.** Placed on the published axles (0.233 and 0.821 of the length).
  - Low nose: 0.46 m at the tip, 0.69 m at the front axle.
  - Windscreen base just behind the front wheels (0.31).
  - Roof peak 1.196 m [F] over the seats (0.52).
  - The glass canopy ends at 0.70 on a lower engine cover (0.95 m at the rear axle), then a 0.98 m wing lip.
- **Beltline.** `VehicleModelBuilder` draws the lower body as one box up to the beltline, so the beltline is also
  the height of the nose and tail. The real window line is about 0.80 m. At 0.78 the stand-in read as a tall
  slab, so 0.62 keeps the nose low, at the cost of taller-looking side glass.
- **Rendered and viewed** with `tools/render_models.py` (lineup) and three-view scratch renders. It reads as a
  low, cab-forward mid-engined coupe next to the two C8 stand-ins. Its orange is distinct from the Z06's redder
  one.

## Gaps

- **Braking** is 7% short at 100 km/h and 12% at 200 km/h, from the model's instant pressure and near-ideal ABS
  (above).
- **0-100 km/h is +0.17 s** (inertia fixed), from the launch from idle; a pre-revved start gives 2.93 s.
- **0-300 km/h is 1.9 s quicker** than the Spider's figure. One fixed drag area can't follow the wing's
  speed-dependent deployment.
- **Torque curve, drag and downforce** are estimates [E]. The car is widely reported as under-rated (wheel dynos
  694-698 whp), and the game stays on McLaren's figures.
- **Ratios and final drive** come from US data feeds, not a McLaren document.
- **The limiter is 8,200 rpm in every gear** (8,100 in 1st-2nd on the real car).
- **Sound.**
  - The firing order rests on one specialist source.
  - Silencer internals, valves and the lift-off sound are undocumented [A].
  - No stock-exhaust recording exists to calibrate against.
  - Idle and cruise dBA are from a snippet.
- **Handling** (suspension, PCC II stand-in, Brake Steer stand-in, steering) is untested: it needs Studio.

## Shared-code problems (reported, not changed)

1. **Dual-clutch upshifts flare the engine into the limiter** (`CorePhysics/VehicleSimulation.luau`, and the
   dual-clutch branch of `tools/drivetrain_model.py`).
   - **The problem.** Engine torque isn't reduced while the clutch is held at `shiftTorqueFraction`. Any engine
     with more torque than that share of `clutchMaxTorque` accelerates during an upshift. That includes this car
     and the GT12.
   - **Proposed change.** In the dual-clutch branch, after the engine torque is computed, add (Luau):
     `if transmission is in an upshift (shift timer > 0, new gear > old gear >= 1) and engineTorque > clutchCapacity then engineTorque = clutchCapacity end`.
     That is the ignition-cut torque trim of a real dual-clutch upshift.
   - **Python, tested.** The same line in the model's dual-clutch branch:
     `if tr.timer > 0 and tr.gear > tr.from_gear >= 1 and Te > cap: Te = cap`.
     With it, this car has no limiter cut on upshifts and keeps its boost through them.
2. **The mixer plays the limiter loops on those flares** (`VehicleAudio/EngineMix.luau` line 240, and
   `tools/audio_preview.py` line 199).
   - **Proposed change.** Add `and not input.shifting` to `limiterTarget` (`and not inp["shifting"]` in the
     Python), so a cut during a shift doesn't bring in about 0.3 s of limiter loop at the old pitch.
3. **A limiter cut dumps turbo boost** (`EngineSimulation/Engine.luau` `netTorque`, and `Engine.net` in the model).
   - **The problem.** The cut sets the throttle target to 0, and the boost target follows the throttle. On the
     limiter the turbo empties, so the whistle stops, and lifting off the limiter plays no blow-off. An ignition
     cut leaves the throttle open.
   - **Proposed change.** Compute the boost demand from `pedal` instead of `engine.throttle`:
     `local demand = math.clamp((pedal - share) / (1 - share), 0, 1)`. Leave the torque request cut as now.
4. **Brakes are ideal** (`CorePhysics/Brakes.luau`, `brake_torque` in the model).
   - **The problem.** Full pressure acts in the first frame, and the ABS holds about 98% of peak grip. Measured
     stops are 7-12% longer for a tyre that matches the acceleration figures.
   - **Proposed change.** A brake-pressure rate limit of about 0.15 s from 0 to full in the simulation.
     Optionally, an ABS mean-efficiency factor of about 0.93 applied while ABS is active.
5. **The double-counted engine inertia**, already reported by the M5 builder. Validation above shows both states.
6. **`tools/audio_preview.py --car X` without `--only`** rewrites the shared `Traffic_driveby_preview.*`.
   - **Proposed change.** Render the drive-by only when `--only driveby` is given or `--car` is left at its
     default.
7. **`tools/synth_audio.py` TURBO defaults `whistleLevel` and `wastegateFlutter` are never read.** The whistle's
   level is the config's `turboVolume`, and flutter is `blowOff.type = "flutter"`.
   - **Proposed change.** Remove both keys, or document them as unused.
8. **The stand-in's lower body is one box up to the beltline** (`VehicleModelBuilder.luau`, `render_models.py`).
   - **The problem.** The nose and tail can't be lower than the window line. The headlight and taillight parts
     sit inside that box unless the profile clears it.
   - **Proposed change.** Draw the lower body in the same slices, with top = min(profile, beltline). Keep one
     full-length box only as the collision part.
9. **The dual-clutch auto mode will upshift into an overdrive top gear at top speed.** It shifts on rpm alone,
   so a car that tops out just below the upshift point in 6th can be stranded in 7th.
   - **Mitigated here.** Upshift at 8,100 rpm, 130 rpm above the top-speed rpm.
   - **Proposed change.** Skip an automatic upshift at full pedal when the next gear's wheel force at the same
     speed is below the drag at that speed.

## What to measure in Studio

- **Telemetry overlay (T).** Compare with the table above: 0-100, 0-200, ¼ mile, 100-0 and top speed.
- **Static wheel loads.** About 3,005 N per front wheel and 4,324 N per rear wheel.
- **Top speed.** It should be reached in 6th at about 7,970 rpm. If the car changes up to 7th near 340 km/h and
  settles about 10 km/h lower, report it (shared problem 9).
- **Upshifts.** Listen at full throttle for a limiter blip and the whistle re-spooling (shared problems 1-2).
- **Handling.** Roll (about 1.2° per g), turn-in and power-on behaviour with the Brake Steer stand-in, and
  high-speed stability with 36% of the downforce on the front.

## Sources

- [MCL21] McLaren 720S brochure, "Technical Highlights", EU/UK specs as at 13 Oct 2021 (third-party copy):
  <https://xr793.com/wp-content/uploads/2022/11/2021-McLaren-720S.pdf>
- [PR17] McLaren 720S launch press release, March 2017, as reproduced by netcarshow:
  <https://www.netcarshow.com/mclaren/2018-720s/>
- Wikipedia: [McLaren 720S](https://en.wikipedia.org/wiki/McLaren_720S),
  [M840T](https://en.wikipedia.org/wiki/McLaren_M840T_engine),
  [McLaren 650S](https://en.wikipedia.org/wiki/McLaren_650S) (675LT +40% downforce; MSO HS 220 kg at 241 km/h)
- [evo: engine, gearbox and technical highlights](https://www.evo.co.uk/mclaren/720s/engine-gearbox-technical-highlights)
- [M-Engineering: McLaren cylinder layout and firing order](https://m-engineering.atlassian.net/wiki/spaces/MENGINEERI/pages/467730433/McLaren+Cylinder+Layout+Firing+Order)
- [carspecs.us 720S](https://www.carspecs.us/cars/2017/mclaren/720s/68778) (ratios)
- [motor1.de test](https://de.motor1.com/reviews/150663/test-mclaren-720s-besser-als-der-ferrari-488/)
- Magazine figures via [0-60specs](https://www.0-60specs.com/mclaren/720s-0-60-times),
  [0-60-time.com (C/D Spider)](https://0-60-time.com/0-60-times/mclaren/720s/2019/),
  [GermanCarForum transcription of AMS](https://www.germancarforum.com/threads/mclaren-720s-vs-911-gt2rs-ams.58232/page-5),
  [IOL Motoring](https://www.iol.co.za/motoring/road-tests/tested-mclaren-720s-rocks-our-quarter-mile-chart-13557256),
  [The Drive (DragTimes)](https://www.thedrive.com/article/15187/the-mclaren-720s-is-running-9-second-quarter-miles-from-the-factory),
  [Autocar road test (mirror)](https://autocar-prod.codeenigma.net/car-review/mclaren/720s)
- Tailpipe position: [Commons, McLaren 720S August 2024 006](https://commons.wikimedia.org/wiki/File:McLaren_720S_August_2024_006.jpg) (CC BY 4.0)
- Full list: `research_notes/cars/Ref720S.json`, `sources`.
