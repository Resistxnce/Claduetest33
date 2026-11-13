# Ridgeway Ironside SC

*Internal ID `RefCamaroZL1`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/RefCamaroZL1.luau`.
Engine sound: `assets/audio/engines/RefCamaroZL1.json`. Research: `research_notes/cars/RefCamaroZL1.json` and `.md`.*

An original front-engined, supercharged V8 muscle coupe from the fictional American brand Ridgeway. It is
built to the published engineering of the **Chevrolet Camaro ZL1 coupe (6th generation, 2017-2024) with the
10-speed automatic**. Real names appear only here, as engineering references; the game uses no Chevrolet
names, logos, body design or assets.

Tags used here and in the configuration:
- **[F]** GM figure (product guide, press material or GM service bulletin)
- **[P]** published by a third party
- **[M]** measured in a magazine or independent test
- **[E]** estimate made for the simulation
- **[A]** assumption

## Published figures

| Item | Value | Tag | Source |
|---|---|---|---|
| Body, layout | 2-door 2+2 fastback coupe; front engine, rear-wheel drive, left-hand drive | F | [GM product guide][pg] |
| Engine | LT4 (Gen V small-block): 90° V8, pushrod OHV, 2 valves per cylinder, direct injection, wet sump | F | [pg], [17-NA-251][b17] |
| Displacement, bore × stroke, compression | 6,162 cc; 103.25 × 92.0 mm; 10.0:1 | F | [pg], [GM Powered Solutions][gmps] |
| Max power | 485 kW (650 hp, SAE) at 6,400 rpm | F | [pg] |
| Max torque | 881 Nm (650 lb-ft, SAE) at 3,600 rpm. GM's 868 Nm is the older 640 lb-ft rating. | F | [b17] |
| Torque landmarks | 620 Nm just off idle; 847 Nm by 2,800 rpm; at least 793 Nm (90%) from 2,500 to 5,400 rpm | P | [EngineLabs][el], quoting GM |
| Redline; maximum engine speed | 6,500 rpm (tachometer); 6,600 rpm | P | [WhichCar][wc]; [Chevrolet Performance][crate] |
| Supercharger | Eaton R1740 TVS: 1.74 L per rotor turn, two 4-lobe rotors with 160° twist, 3.10 × crank speed (20,150 rotor rpm at 6,500), 9.4 psi (0.65 bar); air-to-liquid intercooler | P | [el], [Corvette Action Center][cac] |
| Firing order, numbering | 1-8-7-2-6-5-4-3. Cylinders are numbered front to back: odd numbers on the left (driver's) bank, even on the right. | P | [rerev][fo], [Summit][sum] |
| Gearbox | Hydra-Matic 10L90 10-speed automatic. Ratios 4.70, 2.99, 2.15, 1.80, 1.52, 1.28, 1.00, 0.85, 0.69, 0.64; reverse 4.87. 260 mm converter with an electronically controlled lock-up clutch. | F | [GM 10-speed release][t10] |
| Final drive | 2.85 (automatic coupe) | F | [pg] |
| Differential | Electronic LSD: 0-200 Nm between the rear wheels, fully engaged in 0.15 s | F | [b17] |
| Curb weight | 1,789 kg (automatic coupe; US convention, no driver). C/D's test car weighed 1,784 kg [M]. | F | [pg], [C/D][cda] |
| Length × width × height | 4,812 × 1,897 × 1,330 mm (2019 on; 4,783 mm long for 2017-18) | F | [pg], [Wikipedia][wiki] |
| Wheelbase; track front / rear | 2,811 mm; 1,610 / 1,591 mm | F | [pg] |
| Tyres | 285/30ZR20 front, 305/30ZR20 rear, Goodyear Eagle F1 Supercar 3 (Camaro-specific compound), 20 × 10 / 20 × 11 forged wheels | F | [pg] |
| Brakes | Brembo: 6-piston monobloc front calipers on 390 × 36 mm two-piece rotors; 4-piston rear calipers on 365 × 28 mm rotors | F | [pg], [b17] |
| Turning circle | 11.7 m | F | [pg] |
| 0-60 mph; quarter mile | 3.5 s; 11.4 s at 127 mph (204 km/h). 10-speed coupe on OE tyres, non-prepped surface. | F | [pg], [GM Authority][gma] |
| Top speed | 198 mph (319 km/h), two-way average at Papenburg (202.3 / 193.3 mph), stock 10-speed car with 44 psi tyres; reached in 8th | F | [The Drive][d198] |
| 60-0 mph braking; lateral grip | 107 ft (32.6 m); 1.02 g | F | [pg] |
| Car and Driver, Mar 2017 (10-speed) | 0-60 mph 3.4 s; quarter mile 11.5 s at 125 mph; 70-0 mph 143 ft (43.6 m); skidpad 1.04 g; 50-70 mph 2.1 s | M | [cda], [0-60specs][agg] |
| Motor Trend 2017 (10-speed) | 0-60 mph 3.5 s; quarter mile 11.5 s at 125.0 mph | M | [agg] |
| MotorWeek 2017 (10-speed) | 0-60 mph 3.5 s; quarter mile 11.5 s at 127 mph | M | [MotorWeek][mw] |
| Hennessey baseline video, Apr 2017 (stock 10-speed) | 0-60 mph 3.6 s; 0-100 mph 7.6 s | M | [The Drive][dhenn] |

## Estimates and how they were made

| Item | Value | How |
|---|---|---|
| Simulated mass | 1,864 kg | Curb weight plus a 75 kg driver [A] |
| Weight distribution | 53% front | Not published. Supercharger, intercooler and 11 heat exchangers sit up front; the Camaro SS is quoted near 52/48. |
| Centre of mass | 0.49 m high; 1.321 m behind the front axle | Height estimated for a tall V8 with the blower on top; position from the 53/47 split |
| Rotational inertia | about 3,300 kg·m² in yaw | From a 4.25 × 1.75 × 0.80 m mass box (radius of gyration 1.33 m, near half the wheelbase) |
| Front overhang | 0.925 m (rear 1.075 m) | Side-photo overhang ratio applied to length minus wheelbase |
| Crank torque curve | 620 Nm at 1,000 rpm, 847 at 2,800, 881 at 3,600, 723 at 6,400 (485 kW), 685 at 6,600 | The research's estimate through GM's points, shaped like the K&N wheel-dyno curve. Wheel/crank ratio 0.82-0.90 from 2,500 to 6,000 rpm. |
| Supercharger model | No boost at 650 rpm, full boost from 2,800; off-boost share 0.68 | The model scales a full-boost curve by 0.68 + 0.32 × boost ceiling, with the ceiling rising linearly over that range. Below 2,800 rpm the full-boost points are set so the steady full-throttle torque equals the research curve exactly (check: `drivetrain_model.py RefCamaroZL1 --curve`). 0.68 means about 580-600 Nm with no boost (bypass valve open). That sits between the naturally aspirated LT1's 630 Nm and what the LT4's 10.0:1 and blower allow. It also keeps the full-boost curve under the 881 Nm peak. The pressure ratio alone would give 0.61, but that ignores the hotter boosted charge and the blower's drive power. |
| Engine inertia | 0.28 kg·m² | Forged crank, flexplate, converter cover and impeller, plus about 0.05 for the blower rotors seen at the crank (two rotors at 3.10 × crank speed) |
| Engine braking | 25 + 0.012 × rpm Nm | 6.2 L pushrod V8 with the blower still turning |
| Idle; limiter | 650 rpm; fuel cut at 6,600 rpm, back on 120 rpm lower | Idle not published (Gen V V8s idle at 600-700). Limiter at GM's maximum engine speed; hysteresis inside the research's 100-150 rpm. |
| Throttle response | 20/s | With the hysteresis, gives about 4 limiter cuts a second in neutral |
| Gearbox efficiency | 0.88 | Ten-speed planetary gearbox with the lock-up closed, plus the final drive |
| Shifts | upshift 0.12 s with 40% torque cut; downshift 0.20 s with a 35% blip | GM gives only relative times (1-2 upshift 36% quicker than a PDK). The 1LE automatic's Track mode rev-matches every downshift [F]. |
| Shift schedule | light throttle: up about 3,000 rpm, down about 2,000; full throttle: up at 6,450, kickdown target 4,000 | GM's Track pattern for the 1LE automatic (bulletin 19-NA-038 [F]), applied to this car [A] |
| Torque converter | stall 2,600 rpm, torque ratio 1.9, coupling point 0.87; lock-up from 2nd gear above 20 km/h, 1,300 Nm, 0.4 s | Research estimate for a 260 mm converter behind 881 Nm; not published |
| Differential | clutch-type LSD: preload 100 Nm, power lock 0.35, coast lock 0.20 | Approximation of the 0-200 Nm eLSD (research suggestion) |
| Traction control | target slip 0.10, headroom 1.3, rate 15/s, recovery 12/s | GM's launch control holds 5-15% slip [F]. The quick recovery is tuned (below). |
| Springs, dampers | 50,000 / 56,000 N/m; bump/rebound 3,000/5,000 front, 3,000/4,950 rear (N·s/m) | Not published (gap). Ride frequencies 1.6 Hz front and 1.8 Hz rear; damping ratios about 0.3 in bump, 0.5 in rebound. |
| Anti-roll bars, roll centres | 36,000 / 18,000 N/m; 0.06 / 0.10 m | About 57% of the roll stiffness at the front, for mild understeer; strut front and five-link rear |
| Tyres | lateral grip 1.10 (both axles); longitudinal grip 1.16 front, 1.30 rear | Fitted (see "Tuning"). Steady-state skidpad estimate with the model's tyre law: 1.03 g (GM 1.02 g [F], C/D 1.04 g [M]). |
| Wheel inertia | 1.7 front, 1.9 rear kg·m² | Forged 20-inch wheels and 30-series tyres, with rotors |
| Brake torque, ABS | 4,200 / 2,200 Nm per wheel (66% front); ABS target slip 0.12 | Enough to lock every wheel; ABS holds the peak |
| Drag area | 0.92 m² | GM never published a Cd. Fitted so 485 kW gives the 198 mph top speed in 8th; the research range for 85-90% driveline efficiency is 0.90-0.99. A lap-sim's 0.75 m² would give about 210 mph. |
| Downforce areas | 0.00 front, 0.05 rear m² | GM: the ZL1's aero "reduces lift" with no significant drag penalty [F], no figures. Near-zero net lift. |
| Steering | 34° when slow, 4.5° at 250 km/h, 210°/s | 34° is the mean road-wheel angle for GM's 11.7 m turning circle. Steering ratio not published. |
| Paint | RGB 196, 22, 28 | Approximation of the launch-year solid red ("Red Hot") [A] |

**Stand-in body.** The long hood and short, high deck put the front axle at 0.19 of the length and the windscreen base at 0.34. The roof peak is at 0.57, at the published 1,330 mm, and the rear window base at 0.83. The builder's lower body is one box up to the beltline, so the real window line (about 0.93 m) would bury the hood's rise to the cowl. The beltline is at 0.85 m instead, which leaves the side glass about 0.41 m tall (the real daylight opening is about 0.37 m). The side glass stops at 0.76, leaving the thick C-pillar painted down to the deck. The stand-in was rendered and checked from the side and from both three-quarter views.

## Validation

`tools/drivetrain_model.py RefCamaroZL1` runs the game's drivetrain code at 60 frames per second, with the car as a point mass. US figures, GM's included, use a one-foot rollout, as the drag strip and SAE J1491 do. GM doesn't state its method; its 3.5 s matches the magazines' rollout times. The model is timed from a true standstill, and a one-foot rollout is subtracted from that run for comparison (`drivetrain_model.py` prints this for 0-60; the rest were worked out in the same way from the same run). The in-game timer also starts from a standstill, so it will read about 0.3 s more than the factory 0-60 mph and quarter-mile figures.

| Test | GM [F] | Magazines [M] | Model |
|---|---|---|---|
| 0-60 mph, one-foot rollout | 3.5 s | C/D 3.4, MT 3.5, MotorWeek 3.5, Hennessey 3.6 s | **3.49 s** (3.81-3.85 s from a standstill) |
| Quarter mile, one-foot rollout | 11.4 s at 204 km/h | C/D 11.5 s at 201, MT 11.5 s at 201, MotorWeek 11.5 s at 204 km/h | **11.39 s at 207.5 km/h** (11.70-11.75 s from a standstill) |
| 0-100 mph | | Hennessey 7.6 s (method not stated) | 7.50-7.55 s from a standstill, 7.19 s with rollout |
| 0-100 km/h | not published | | 3.98-4.02 s from a standstill |
| Top speed | 319 km/h in 8th | | **318.2 km/h** in 8th at 6,010 rpm (−0.3%) |
| 60-0 mph | 32.6 m | | **31.4 m** (−3.7%) |
| 70-0 mph | | C/D 43.6 m | **42.7 m** (−2.1%) |
| 100-0 km/h | not published | | 33.7 m |
| 50-70 mph, kickdown in D | | C/D 2.1 s | 1.64 s (4th to 2nd); the model's kickdown has no decision delay |
| Skidpad | 1.02 g | C/D 1.04 g | about 1.03 g (steady-state estimate, not a model run) |

**Pending rerun.** These figures predate the shared fix for engine inertia being counted twice while the lock-up is closed. A scratch copy of the model without the double count gives:
- 0-60 mph: unchanged (3.52 s with rollout), because the launch is grip-limited in 1st with the lock-up open;
- 0-100 mph: 0.10 s quicker;
- quarter mile: 0.03 s quicker, at 208.6 km/h;
- top speed and braking: unchanged.

The grip fit therefore doesn't depend on the bug. The table is updated once the fix lands.

The model takes the better of two launches: from idle, and with the brake held first. The brake-held launch holds the engine at 1,357 rpm, because traction control caps it at what the tyres can take (a known limitation, see `VEHICLE_CONFIG.md`).

Other model checks:
- **Idle and creep.** Idle in park is 633 rpm (612-643); in drive with the brake held it is 608 rpm. Off the brake the car creeps at 6.0 km/h.
- **Free rev in neutral.** It reaches the limiter in 0.28 s, then bounces between 6,467 and 6,828 rpm about 4 times a second.
- **Launch shifts.** The full-throttle shifts are at 6,450-6,540 rpm. The 1-2 shift takes 0.18 s and drops 2,245 rpm; the later upshifts take 0.13-0.15 s. The lock-up closes at 68 km/h in 2nd.
- **Cruise and coast.** At 35% pedal the car settles at 143 km/h in 6th. After 15 s of coasting it is at 110 km/h in 8th.
- **Luau checker.** `tools/luau_check.py` passes for the configuration and the sheet.

**Tuning.** Only [E] and [A] values were changed, and no sourced value was moved.
1. **Traction-control recovery: 2/s to 12/s.** At 2/s the first wheelspin left a deep torque cut that took 0.3 s to fade, so the car bogged at 0.4-0.5 g in the first second. At 12/s the cut fades in about 0.08 s. Headroom stayed at 1.3: values from 1.1 to 1.8 were all slower.
2. **Tyre longitudinal grip, split by axle (front 1.16, rear 1.30).** This is the main fit. Only the rear tyres drive the car, and 0-60 mph is grip-limited up to and through 2nd gear at 0.74 g. Matching GM's 3.5 s and 11.4 s needs a rear grip of 1.30. The front tyres do about 73% of a hard stop and none of the driving, and the stops need about 1.16. With one value for both axles, the model either stops 9% short (at 1.30) or launches 0.3 s slow (at 1.18). The reason is the test, not the tyre: the model applies the brakes instantly and its ABS holds 98% of peak grip, while a real stop includes pedal build-up and ABS cycling. Lateral grip is the same front and rear.
3. **Throttle response, 16/s to 20/s.** This sets the limiter rhythm to about 4 cuts a second; it doesn't change the acceleration.
4. **Drag area 0.92 m².** Fitted to the top speed, inside the research's 0.90-0.99 range.

Engine inertia (0.24-0.32), converter stall (2,400-3,000 rpm) and torque ratio (1.8-2.0) were swept. They change 0-60 mph by 0.03 s or less, because the launch is grip-limited, so the research values were kept.

## Sound

The engine sheet is synthesized by `tools/synth_audio.py` from `assets/audio/engines/RefCamaroZL1.json`, built with `--dev` into `assets/audio/dev/Dev_RefCamaroZL1.flac`, and mixed by the game with the config's `audio` table. The previews are `assets/audio/preview/RefCamaroZL1_drive_preview.mp3` and `RefCamaroZL1_tunnel_preview.mp3`, each with a spectrogram.

**Acoustic definition.** Every number has its source in the file's `notes`.

| Part | Setting | Basis |
|---|---|---|
| Firing | 1-8-7-2-6-5-4-3, GM bank numbering (odd left, even right), 90° V, cross-plane crank. Every 90° overall; each bank 180-270-180-90°: the burble. | P / E (`--check` confirms the pattern with no warnings) |
| Exhaust | Tri-Y manifolds [F] modelled as one 0.45 m collector per bank. X-pipe crossover 0.35 [E]: X, H or none is unconfirmed. Two 3.0 / 3.1 m pipes to quad tips [P]. | P / F / E |
| Valves | Dual-mode exhaust, modelled as Sport: valves shut at light load below 3,500 rpm, open on throttle or above it | P / E |
| Supercharger | Roots type, two 4-lobe rotors, 3.10 × crank speed, 8 pulses per rotor turn. Whine = 0.4133 × rpm Hz (engine order 24.8, 6.2 × the firing frequency). A weaker single-rotor line at half that pitch (0.207 × rpm), 0.2 of the main line (about 14 dB under) [E]. Whine loops are made at 1,200 and 4,000 rpm, so playback stays within 0.54-1.65 × from idle to the limiter. | P / E |
| Limiter | Fuel cut at 6,600 rpm. Free revving bounces at 8 Hz and drops 350 rpm; in gear it bounces at 10 Hz and drops 150 rpm. | E (behaviour not documented) |
| Overrun | Burble 0.4, plus crackles after high-rpm lift-offs and a crack on full-throttle upshifts. GM's bulletin 17-NA-078 says WOT pops in Sport and Track are normal. | F / E |
| Loudness | Cabin estimates: idle 54 dBA, full throttle 85, 70 mph 70. These come from Edmunds' previous-generation ZL1 (53.6 / 81.9 / 69.9), adjusted for the coupe; C/D's figures could not be read. | E |

**Checks by measurement.** I can't listen to audio, so everything below was measured.
- **Firing frequency.** In every loop (650-6,600 rpm), the strongest component between orders 3.25 and 4.75 is exactly order 4. That is rpm/15: 43.3 Hz at idle, 203.3 Hz at 3,050, 440 Hz at 6,600.
- **Burble (half orders), from the loops.** At idle and off throttle up to 5,100 rpm they sit 26-38 dB under the firing order on average. On throttle from 1,800 to 5,100 rpm they are 22-27 dB under on average (the strongest 7-14 dB under). At 6,600 rpm, with the overrun pops, they rise to 13-18 dB under on average.
- **Burble, in the drive preview.** The launch measures 10-25 dB under the firing order, the in-gear limiter hold 10-24 dB, and idle 26-38 dB. The free rev on the limiter measures 7-13 dB under: skipped firings break the even pulse train, as a real fuel cut does.
- **Reference recordings.** The freely licensed LT4 recording (a CT5-V Blackwing, aftermarket exhaust, microphone behind the car) measures 23-36 dB at its cold fast idle, 9-28 dB revving and 21-41 dB driving away. The supercharged LS9 Corvette ZR1 clip measures 8-19 dB.
- **Outlet offset.** The first build had the far outlet 0.25 m farther from the listener. That put half orders up to 7 dB above the firing order on throttle (14 dB on the limiter), far burblier than either recording. Two tailpipes heard from behind sum almost in phase, so the offset is now 0 and the 0.1 m pipe-length difference keeps some burble.
- **Supercharger whine, pitch.** In the drive preview, the order spectrum (resampled with the model's rpm) shows a line at order 24.8 at full boost. It sits 14-18 dB under the firing-order line and 18-27 dB above the floor around it. The whine-only signal (the preview rendered with and without the whine) peaks at 261.6 Hz at 633 rpm, which is 0.4133 × rpm. The baked loops measure 496.7 Hz at 1,200 rpm and 1,653.3 Hz at 4,000.
- **Whine on the spectrogram.** In a spectrogram of the launch with 0.4133 × rpm marked, the line follows the marks through 1st to 5th and steps down at each upshift (`whine_overlay_launch.png` in the build scratch folder).
- **Supercharger whine, level.** Reviewers hear the whine most at low revs and part throttle, faintly at a quiet idle, and covered by the exhaust at high revs. The config's whine shape is set to match: volume 0.06, idle share 0.4, full level from 1,500 rpm, floor 0.5. Measured with the whine-only signal (the mix rendered with and without the whine), against the rest of the mix:
  - 11-13 dB(A) under in full-throttle pulls from 1,500 to 4,500 rpm;
  - 15-17 dB(A) under at part throttle (2,000-4,500 rpm);
  - 16 dB(A) under at full throttle above 4,500 rpm;
  - 21 dB(A) under at idle.

  With the mixer's original shape these were 11.6-17, 22-24, 15.7 and 31 dB(A). Neither reference recording shows a whine line above its noise floor (tailpipe microphones), so the levels remain estimates.
- **Single-rotor line.** In the whine loops the half-pitch line measures 14 dB under the main line, with its third harmonic 24-25 dB under. In the drive preview's order spectrum it shows at order 12.4, 5-12 dB above the floor around it during the launch. On the spectrogram it is close to engine order 12, so it is hard to pick out by eye.
- **Relative levels.** The mixer compresses real levels by half, so the research estimates mean full throttle should be +15.5 dB over idle and a 70 mph cruise +8.0. In the cockpit the model gives +14.5 dB at full throttle (5,800-6,600 rpm) and +9.1 at 70 mph in 10th. The exterior view gives +14.5 and +8.7. With the Track shift pattern the car cruises at 70 mph in 6th at 3,160 rpm, which is +10.5 dB in the cockpit.
- **Spectrograms viewed.** Both preview spectrograms were checked, plus zoomed views. They show the free rev hitting the limiter, with its bounce as vertical striations about 8 a second. They show the launch's rising harmonic fans and upshift steps, the blipped downshifts under braking, and the 2nd-gear limiter hold, flat with striations about 10 a second.
- **Limiter switching.** The limiter loops take over fully during the free rev (the free-revving loop) and the 2nd-gear hold (the in-gear loop, mean mix 0.99). The longest cut-free spell is 0.10 s, under the 0.3 s hold, so there are no dropouts. The loops' envelopes repeat at 7.9 and 9.9 Hz.
- **Seams.** From the decoded FLAC, every loop's jump at the loop point is 0.00-0.77 of an ordinary sample step (worst 0.77; the doc's range is 0.01-1.2). The stored post-roll matches each loop's start exactly.
- **Events.** The preview has a crack on each of the 4 full-throttle upshifts and 3 pops after the high-rpm lift-off.

**Not checked.** How it sounds to a person, and how Roblox plays the loops: the regions, and playback speeds up to 1.65 × for the whine. The sheet points at the dev build until the coordinator packs `Engines_Pack1`.

## Variant: 6-speed manual (TREMEC TR-6060, RPO MH3, with Active Rev Match)

| Item | Value | Tag | Source |
|---|---|---|---|
| Ratios | 2.29, 1.61, 1.21, 1.00, 0.82, 0.68; reverse 3.11 | F | [b17] (2018 ZL1 1LE bulletin; also fits the 2017 ZL1: "60 mph in first" [d1st]) |
| Final drive | 3.73 | F | [pg], [b17] |
| Torque capacity | 881 Nm | F | [b17] |
| Curb weight | 1,761 kg (coupe) | F | [pg] |
| Speed at 6,500 rpm | 96, 137, 182, 220, 269, 324 km/h (0.335 m rolling radius); 6th is drag-limited | E | research |
| Tests | C/D 0-60 mph 3.7 s, quarter mile 12.0 s at 122 mph; MT 3.8 s, 11.8 s at 123.9 mph | M | [C/D manual][cdm], [agg] |

**Recipe** (not a file yet). Copy the configuration with:
- `id = "RefCamaroZL1Manual"` and `kerbKg = 1761` [F];
- a `transmission` of `type = "DualClutch"`, with the ratios above, `reverseRatio = 3.11` and `finalDrive = 3.73` [F];
- `efficiency = 0.90`, `shiftTime = 0.25` and `shiftTorqueFraction = 0` (a manual has no drive during the shift), `clutchMaxTorque = 1150`, `clutchStiffness = 400` [E];
- `launchRpm = { min = 2000, max = 3800 }` [E] (research suggests 3,500-4,000 for the manual);
- `autoUpshiftRpm = { light = 3000, full = 6450 }`, `autoDownshiftRpm = { light = 1500, full = 3800 }` and `minShiftInterval = 0.35` [E].

In the model this gives 0-60 mph in 3.77 s with rollout (C/D 3.7, MT 3.8). The quarter mile is 11.63 s at 203.7 km/h with rollout (MT 11.8, C/D 12.0), and the top speed 322 km/h in 6th. The model has no manual-clutch gearbox, so Active Rev Match's downshift blip isn't modelled; the clutch type has no `downshiftBlip`.

## Gaps

1. **Car and Driver's interior sound levels.** Not obtained, so the cabin levels are an estimate from the previous-generation car.
2. **No freely licensed recording of a ZL1.** The calibration used an LT4 with an aftermarket exhaust and an LS9 ZR1 clip. Neither shows the whine above its noise, so the whine level is an estimate.
3. **Exhaust crossover.** X-pipe, H-pipe or none is unconfirmed, as are pipe diameters, catalysts and mufflers.
4. **The rev limiter.** Its exact rpm and behaviour, and GM's park/neutral rev limit for automatics, are not documented. The game uses one limiter, at 6,600 rpm.
5. **Torque curve and the supercharger's other lines.** GM's crank torque chart wasn't found: the curve is an estimate, checked against a wheel-dyno shape. The blower's timing-gear tooth count is unknown, so there is no gear-mesh line, and the single-rotor line's level is an estimate.
6. **Gearbox and drive.** Converter stall and absolute shift times are not published. Weight distribution, centre-of-mass height, the Cd and lift figures, springs, bars, dampers, steering ratio and ride height are all estimates.
7. **Handling is untested.** The lateral grip and anti-roll split are design estimates for Studio testing.
8. **0-100 mph.** Hennessey doesn't say whether its 7.6 s uses rollout. The model gives 7.55 s from a standstill and 7.19 s with rollout.

## Shared-code observations (reported, not changed)

- **The fuel cut acts through the throttle filter** (`Engine.luau`; `Engine.net` in the Python copy). A fast free rev overshoots the limiter: this car's first hit reaches the 7,000 rpm clamp. In gear, the blower's boost collapses on the limiter, so the whine fades, although a real fuel cut leaves the throttle open.
- **Automatic mode upshifts under braking.** Pedal 0 uses the light upshift point, so hard braking from speed upshifts first. GM's Sport mode downshifts under braking.
- **Resolved:** the supercharger whine shape (`superchargerIdleShare`, `superchargerFullRpm`, `superchargerRpmFloor`) and the single-rotor line (`singleRotorLevel`) are now settings, and this car uses both.

## Sources

[pg]: https://www.automobilrevue.cz/priloha/5c52e04a77969/2019-chevrolet-camaro-zl1-product-guide-071618-5c7513e929f7f.pdf
[b17]: https://static.nhtsa.gov/odi/tsbs/2017/MC-10126120-9999.pdf
[b19]: https://static.nhtsa.gov/odi/tsbs/2019/MC-10155023-9999.pdf
[b078]: https://static.nhtsa.gov/odi/tsbs/2017/MC-10138065-9999.pdf
[t10]: https://www.automotiveworld.com/news-releases/holy-shift-look-inside-gms-new-10-speed-automatic/
[gmps]: https://poweredsolutions.gm.com/products/engines/lt4-engine
[crate]: https://www.chevrolet.com/performance-parts/crate-engines/lt-engines/lt4-engine
[gma]: https://gmauthority.com/blog/2016/08/2017-chevrolet-camaro-zl1-full-performance-specs-revealed/
[wiki]: https://en.wikipedia.org/wiki/Chevrolet_Camaro_(sixth_generation)
[el]: https://www.enginelabs.com/engine-tech/high-revving-supercharger-key-lt4s-impressive-power-curve/
[cac]: https://www.corvetteactioncenter.com/specs/c7-corvette/2015-c7-corvette/2015-c7-corvette-z06-lt4-engine-overview.html
[fo]: https://rerev.com/firing-orders/chevrolet/6-2l-lt4/
[sum]: https://help.summitracing.com/knowledgebase/article/HE-04970/en-us
[kn]: https://sdda.semadata.org/Standard/KN%20Engineering%20Inc/63-3099_dyno.pdf
[d198]: https://www.thedrive.com/new-cars/7756/2017-chevy-camaro-zl1-nails-an-official-198-mph-top-speed
[dhenn]: https://www.thedrive.com/watch-this/9369/watch-the-650-hp-chevy-camaro-zl1-10-speed-accelerate-to-180-mph
[d1st]: https://www.thedrive.com/muscle-cars/4976/the-2017-chevrolet-camaro-zl1-will-hit-60-mph-in-1st-gear
[mw]: https://www.motorweek.org/reviews/road_tests/2017-chevrolet-camaro-zl1
[m1]: https://www.motor1.com/reviews/137467/2017-chevy-camaro-zl1-coupe-first-drive/
[cda]: https://autos.yahoo.com/2017-chevrolet-camaro-zl1-165500450.html
[cdm]: https://autos.yahoo.com/2017-chevrolet-camaro-zl1-manual-190100380.html
[agg]: https://www.0-60specs.com/chevrolet/camaro-0-60-times
[ed]: https://www.edmunds.com/car-reviews/track-tests/2013-chevrolet-camaro-zl1-convertible-track-test.html
[wc]: https://www.whichcar.com.au/reviews/chevrolet-camaro-zl1-manual-review

- GM: [2019 Camaro ZL1 product guide][pg]; service bulletins [17-NA-251][b17] (ZL1 1LE features), [19-NA-038][b19] (1LE 10-speed, shift patterns, launch control) and [17-NA-078][b078] (WOT pops in Sport/Track); [10-speed press release][t10]; [Powered Solutions LT4][gmps]; [Chevrolet Performance LT4][crate].
- Engine and blower: [EngineLabs][el], [Corvette Action Center][cac], [rerev firing order][fo], [Summit numbering][sum], [K&N dyno sheet][kn].
- Performance: [The Drive, 198 mph][d198], [The Drive, Hennessey run][dhenn], [The Drive, 60 mph in first][d1st], [MotorWeek][mw], [Motor1][m1], [Car and Driver, automatic][cda], [Car and Driver, manual][cdm], [0-60specs][agg], [GM Authority][gma], [Wikipedia][wiki], [WhichCar][wc].
- Sound levels (proxy): [Edmunds, 2013 ZL1 convertible][ed].
- Recordings used only for measurement: Wikimedia Commons, "Cadillac CT5-V Blackwing engine and exhaust sound" (CC BY 3.0) and "Chevrolet Corvette C6 ZR1 recorded 2010" by Ed Pond (CC BY-SA 3.0). Details are in `research_notes/cars/audio/RefCamaroZL1/LICENSES.txt`; neither is in the game.
