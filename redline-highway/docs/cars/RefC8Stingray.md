# Ridgeway Halcyon S

*Internal ID `RefC8Stingray`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/RefC8Stingray.luau`.
Engine sound: `assets/audio/engines/RefC8Stingray.json` (sheet `RefC8Stingray_Engine`). Research:
`research_notes/cars/RefC8Stingray.json` and `.md`.*

An original mid-engine sports coupe from Ridgeway, a fictional American brand. It is built to the published
engineering of the **Chevrolet Corvette Stingray coupe with the Z51 Performance Package (C8, model years
2020-2026, LT2 engine)**, US specification. Real names appear only here and in the config's `reference`, as
engineering references; the game uses no Chevrolet or Corvette names, logos, body design or assets.

Tags used here and in the configuration:
- **[F]** GM or Tremec figure (sometimes read through a faithful copy of GM's spec sheet)
- **[P]** published by a third party (spec pages, engineering articles, forums quoting the service manual)
- **[M]** measured in a magazine or independent test, or read from GM's published chart
- **[E]** estimate made for the simulation (the method is given)
- **[A]** assumption

Source ids [S01]-[S41] are the research's; [S42] is a copy of Car and Driver's data panel found for this
build. Links are at the end.

## Published figures

| Item | Value | Tag | Source |
|---|---|---|---|
| Layout | Two-seat coupe with a removable roof panel; 90° V8 mounted behind the seats, transaxle behind the engine; rear-wheel drive; left-hand drive (US) | F | S01, S10 |
| Engine | LT2 Gen V small-block: 6,162 cc (103.25 × 92.0 mm), 11.5:1, pushrods, 2 valves per cylinder, dual-equal VVT, direct injection at 150 bar, dry sump with three scavenge pumps | F / P | S01, S07, S08 |
| Crank | Cross-plane, forged steel | P | S07, S10 |
| Intake | Rear-facing manifold, 8 equal runners about 210 mm long, one 87 mm throttle | P | S07, S08 |
| Max power | 369 kW (495 hp SAE J1349) at 6,450 rpm with the Z51's NPP exhaust (490 hp without) | F | S03 |
| Max torque | 637 Nm (470 lb-ft) at 5,150 rpm with NPP | F | S01 |
| Full-load curve | GM's "LT2 vs LS6" chart read by pixel extraction (±4 Nm): 433 Nm at 1,000 rpm, 530 at 2,000, a shelf to 567 at 3,500, 637 peak at 5,150, 546 at 6,450, 525 at 6,600 (15 points in the config) | M (F anchors) | S12 |
| Fuel cut | About 6,600 rpm ("Engine Overspeed Protection", fuel cut, manual mode); redline 6,500 or 6,600 depending on the source | P | S27, S02, S07 |
| Idle | Not published | – | – |
| Launch control | Holds 3,500 rpm against the brake before the first-gear clutch engages | F | S03, S04 |
| Firing order | 1-8-7-2-6-5-4-3 (V4 mode: 1-7-6-4) | F | S01, S11 |
| Cylinder numbering | GM convention: odd cylinders on the left (driver's) bank, even on the right, cylinder 1 at the accessory end, which faces the cabin in the C8 | P (orientation E) | S11, S07 |
| Exhaust | Upswept 4-into-1 stainless headers, one close-coupled cat per bank, Tenneco cold end with one large muffler; NPP adds two tailpipe valves (up to four valves); owners describe an internal X-pipe; quad tips in two pairs at the outer corners | P | S07, S23-S25, S36 |
| Gearbox | Tremec TR-9080 8-speed DCT: 2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33; reverse 2.63; 100 ms upshift overlap "with no interruption of torque"; 800 Nm input rating | F | S02, S04-S06 |
| Final drive | 5.17 with Z51 (1.4545 transfer × 3.55 ring and pinion); 4.89 base | F | S04 |
| Differential | Z51 electronic LSD (clutch pack, open to locked under ECU control); calibration not published | F / P | S04 |
| Weight | GM dry 1,530 kg; 1LT coupe (no Z51) 1,603 kg US curb [P]; **Car and Driver's Z51 3LT test car 1,654 kg** [M] | F / P / M | S01, S31, S13 |
| Weight distribution | 39.4 / 60.6 measured (C/D); 40 / 60 in a leaked GM document | M / P | S13, S32 |
| Length × width × height | 4,630 × 1,934 × 1,234 mm | F | S01 |
| Wheelbase; track front / rear | 2,722 mm; 1,648 / 1,586 mm | F | S01 |
| Tyres | 245/35ZR19 front, 305/30ZR20 rear, Michelin Pilot Sport 4S, GM "TPC" spec; C/D's data panel lists them as **PS4S ZP** (run-flat), load index 89Y / 99Y | F / P | S01, S19, S42 |
| Wheels | 19 × 8.5 front, 20 × 11 rear | F | S01 |
| Brakes (Z51) | Brembo 4-piston monobloc calipers; iron discs 345 × 30 mm front, 350 × 27 mm rear; eBoost electric booster | F | S01, S29 |
| Aero | No Cd published (a forum 0.322 is unverified); Z51 splitter and spoiler add 400 lb (1,779 N) of downforce and cut top speed from 194 to 184 mph | F / A | S22, S30 |
| Steering; turning circle | 15.7:1 variable-ratio electric rack; 11.6 m (11.1 m with Magnetic Ride) | F | S01 |
| Suspension | SLA double wishbones front and rear, 46 mm monotube coil-overs; Z51 stiffer springs and dampers; Magnetic Ride optional | F / P | S01, S10 |
| Factory performance (Z51) | 0-60 mph 2.9 s (rollout not stated); ¼ mile 11.2 s at 121 mph; top speed 184 mph (296 km/h) | F | S03, S22 |
| Car and Driver, Oct 2019 | 0-60 mph 2.8 s (1-ft rollout, 0.2 s); 0-100 mph 7.2 s; 0-130 13.2 s; 0-150 19.4 s; rolling 5-60 mph 3.5 s; ¼ mile 11.2 s at 122 mph; 70-0 mph 149 ft (45.4 m); 1.03 g skidpad | M | S13, S14, S42 |
| Motor Trend, Oct 2019 | 0-60 mph 2.8 s; ¼ mile 11.1 s at 123.2 mph; 60-0 mph 97 ft (29.6 m); 1.04 g | M | S18 |
| Other tests | C/D Sept 2020: 3.0 s, 11.3 s, 70-0 in 154 ft. 191.7 mph Z51 top-speed run (2023) | M | S15, S41 |
| Cabin sound (C/D) | 47 dBA idle, 92 dBA full throttle, 74 dBA at 70 mph (73 in Sept 2020) | M | S16, S17, S15 |
| Cabin sound (AMS, EU car) | 48 idle; 69 / 72 / 76 / 79 / 81 dBA at 80 / 100 / 130 / 160 / 180 km/h; 89 max | M | S19 |
| EU noise | 95 dB(A) stationary (test rpm not found), 73 dB(A) pass-by | F | S19 |

## Estimates and how they were made

| Item | Value | Tag | How |
|---|---|---|---|
| Simulated mass | 1,729 kg | M + A | C/D's measured Z51 3LT (1,654 kg, US curb: fluids, no driver) plus a 75 kg driver. It is the car behind the measured figures; GM's 1,603 kg is a 1LT without Z51 |
| Weight split | 39.4% front | M | Measured on the same car; puts the CoM 1.649 m behind the front axle. Static loads 3,341 N per front wheel and 5,139 N per rear wheel |
| CoM height | 0.44 m | E | Not published. About 0.36 of the roof height, the same ratio as the GT12's estimate; the dry-sump V8 sits with its crank below the half-shafts (S07) |
| Rotational inertia | Yaw about 2,550 kg·m² | E | Mass box 1.80 × 0.70 × 3.80 m: radius of gyration 1.21 m, 0.83 of (front axle to CoM × CoM to rear axle), a mid-engine car's concentrated mass |
| Front overhang | 0.85 m | E | From two 3/4 photos averaged (±0.08 m, S36); leaves 1.058 m behind the rear axle |
| Idle | 600 rpm | E | Typical Gen V warm idle (550-650). The model's idle controller settles at 565 rpm |
| Limiter hysteresis | 120 rpm | E | The research suggests a hard cut with a 100-150 rpm bounce; in gear the model bounces 6,480-6,608 rpm |
| Engine inertia | 0.18 kg·m² | E | Forged crank about 0.045, damper 0.015, flexplate and torsional damper 0.05, the DCT's outer clutch drum 0.05, rods and pistons 0.015 |
| Engine braking | 25 + 0.0125 × rpm Nm | E | A 6.2 L two-valve V8's friction (1.5-2 bar FMEP) plus pumping against a shut throttle: about 60 Nm at 3,000 rpm, 100 at 6,000 |
| Throttle response | 16 /s | E | One 87 mm drive-by-wire throttle feeding a plenum |
| Driveline efficiency | 0.88 | E | DCT transaxle with a transfer gear; stock cars read 424-429 whp on Dynojets (86-87% of 495 hp, tyre losses included, S28, S39); also the research's CdA fit used 0.88 |
| Shift | 0.10 s at 65% of clutch capacity | F / E | 0.10 s is Tremec's 100 ms overlap [F]. 0.65 × 950 Nm = 620 Nm, about the engine's full torque, models "no interruption of torque". The GT12's 0.35 lets every full-throttle upshift flare into the fuel cut (to 6,690 rpm here), which also switched the sound to the limiter loops; with 0.65 the peak is 6,457 rpm |
| Clutch capacity | 950 Nm | E | About 1.5 × peak torque. The gearbox's 800 Nm is its input rating, not the clutch's slip capacity |
| Launch rpm | 1,600-3,500 rpm by pedal | F / E | 3,500 is the launch-control hold [F]. In the model the clutch is fully closed at 3,500 and the engine holds about 3,200 rpm while it slips |
| Auto shift points | Up 2,000-6,450, down 1,100-3,600 rpm by pedal | E | Full-throttle upshifts at peak power; early shifts at light pedal (70 mph in 8th is 1,476 rpm). Ratios checked against the largest step (1st to 2nd, 1.65) |
| Rear differential | Preload 100 Nm, power 0.45, coast 0.30 | E | The research's clutch-LSD approximation of the eLSD |
| Traction control | Target slip 0.11, headroom 1.3 | E | The project's defaults. Headroom 1.3 to 2.0 was tried: launch times moved by under 0.05 s, so it was left alone |
| Springs | 38,900 / 74,700 N/m | E | Ride frequencies 1.7 Hz front and 1.9 Hz rear (Z51 stiffer than base, S10; reviewers praise the ride) at corner masses of 341 / 524 kg |
| Dampers | Bump / rebound 2,200 / 3,640 front, 3,750 / 6,250 rear (N·s/m) | E | About 0.3 and 0.5 of critical |
| Anti-roll bars | 30,000 / 12,000 N/m | E | Front axle 52% of the roll stiffness against 39% of the weight; about 1.4° of roll per g |
| Tyre compound | muLong 1.25, muLat 1.06 | E (tuned) | See "Tuned values". Other values are the shared Performance compound's |
| Tyre nominal load | 3,770 N front, 5,030 N rear | E | In proportion to the load indices 89 and 99 (580 / 775 kg). The game's tyre has no width, and this is what lets the 305 mm rear carry 61% of the weight without letting go first: the steady skidpad limit is then neutral (front 1.036 g, rear 1.037 g); with one nominal load the rear lets go 3% earlier |
| Tyre inertia | 1.5 / 2.1 kg·m² | E | 19 in and 20 in wheel and tyre plus the iron discs |
| Brake torque | 3,000 / 2,100 Nm per wheel | E | About 1.5 × the torque that locks each wheel at 1.25 g; 59% front, near the 57% ideal for a 39 / 61 car |
| Drag area | 0.88 m² | E (tuned) | Fitted so the drag-limited top speed is 296 km/h, in 6th at 6,060 rpm. Consistent with the research's 0.91 m² at 1.20 kg/m³ (ρ·CdA within 1.3%). Cd 0.32 × 1.95 m² = 0.63 m² would give over 205 mph |
| Downforce areas | 0.175 / 0.263 m² | E | The Z51's 400 lb taken at 184 mph, split 40 / 60 with the weight; the base car's own lift taken as zero [A] |
| Steering lock | 31° | E | With Ackermann 0.6 the outer front tyre traces 11.6 m kerb to kerb, the factory turning circle (30° gives 12.0 m) |
| Body colour | RGB 20, 84, 168 | A | An approximation of Rapid Blue, a 2020 launch colour |

### Stand-in model (`visual.blockout`)

The research's shares of length from the nose: front axle 0.18, windscreen base 0.29, header 0.42, roof
peak 0.50, roof end 0.59, rear axle 0.77, spoiler lip 0.98; heights ±10% except the roof (1.234 m [F]).

```
profile = { {0, 0.76}, {0.08, 0.78}, {0.18, 0.81}, {0.28, 0.89}, {0.42, 1.20}, {0.50, 1.234},
            {0.56, 1.21}, {0.64, 1.05}, {0.95, 1.01}, {0.98, 1.05}, {1, 0.97} }
greenhouse = {0.28, 0.64}, beltline = 0.76, cabinWidth = 0.68, sill = 0.12
```

Chosen from renders of seven variants (`tools/render_models.py` plus side and rear views drawn with the same
code). What made it read as a mid-engine car:
- a short, low bonnet;
- the glass carried on over the slope behind the roof, as the real rear glass and glass engine cover are, so
  the cabin stands apart from the engine deck;
- the deck at 1.01-1.05 m, the low end of the research's 1.10 m (±10%). A deck at 1.10-1.17 m with painted
  buttresses read as a pickup with a tonneau cover.

The builder draws everything below the beltline as one box, so the nose shows at 0.76 m (the real one is
about 0.45 m at the leading edge and 0.68 m at the bonnet's front edge), the sides have no wheel arches or
intakes, and the builder puts the four exhaust tips near the centre (the real quad tips are at the outer
corners).

## Tuned values

Only these were changed to meet published figures.

| Value | Set to | Why | Effect |
|---|---|---|---|
| `muLong` | 1.25 | The model then reproduces Motor Trend's 60-0 mph (29.8 m against 29.6 m) and C/D's rolling-start 5-60 mph (3.50 s against 3.5 s, a traction-limited first gear without launch control). Car and Driver's 70-0 mph (45.4 m) would need 1.10. The two magazines' stops are 13% apart at the same speed; the model's ABS holds the tyre's peak exactly, while a real ABS gives up some of it | 70-0 mph is 11% short of C/D |
| `muLat` | 1.06 | A steady-state skidpad estimate with this suspension's load transfer and the game's load sensitivity gives 1.036 g, against C/D's 1.03 g and MT's 1.04 g | (not tested by the drivetrain model) |
| `dragArea` | 0.88 m² | Drag-limited top speed 295.8 km/h; GM: 296 km/h | Within 1% |

Allowed but not changed: engine inertia (0.18 is the component estimate; 0.18-0.22 moved launch times by
under 0.05 s), launch rpm (3,500 is GM's figure) and traction-control headroom (1.3-2.0 made no material
difference). `shiftTorqueFraction` (0.65) and the tyre nominal loads are modelling choices made for the
reasons above, not to meet a target. The shift fraction does also take about 0.13 s off 0-60 mph, by
removing the flare into the fuel cut.

## Validation

`python3 tools/drivetrain_model.py RefC8Stingray` (game drivetrain code at 60 fps), plus scratch runs of the
same code. "Rollout" times start once the car has moved one foot, as US magazines and drag strips time.

| Test | Published | Model at 60 fps | Model at 66-144 fps | Against target |
|---|---|---|---|---|
| 0-60 mph, standing start | 2.9 s [F] (GM; rollout not stated) | 4.00 s | 3.74 s | +1.10 / +0.84 s |
| 0-60 mph, 1-ft rollout | 2.8 s [M] (C/D, MT) | 3.52 s | 3.27 s | +0.72 / +0.47 s |
| Rolling start, 5-60 mph | 3.5 s [M] (C/D) | 3.50 s | – | 0.0 s |
| 0-100 mph, rollout | 7.2 s [M] (C/D) | 8.05 s | 7.80 s | +0.85 / +0.60 s |
| 60-100 / 100-130 / 130-150 mph | 4.4 / 6.0 / 6.2 s [M] (C/D) | 4.53 / 5.88 / 6.14 s | – | +3% / −2% / −1% |
| ¼ mile, rollout | 11.2 s [F/M] (GM, C/D; MT 11.1 s) | 11.77 s (standing 12.25 s) | 11.54 s | +0.57 / +0.34 s |
| ¼ mile trap speed | 121 mph [F] (GM); 122 [M] (C/D); 123.2 [M] (MT) | 120.8 mph (194.5 km/h) | 120.9 mph | −0.2% against GM; −1% against C/D |
| Top speed | 296 km/h [F] (184 mph) | 294.0 km/h in the tool's 70 s run, in 6th at 6,019 rpm | 295.8 km/h after 240 s | −0.7% / −0.1% |
| 70-0 mph braking | 45.4 m [M] (C/D, 149 ft) | 40.4 m | – | −11% |
| 60-0 mph braking | 29.6 m [M] (MT, 97 ft) | 29.8 m | – | +0.7% |
| 100-0 km/h braking | none (C/D scaled: 35.8 m; MT scaled: 31.7 m) | 32.0 m | – | – |
| Skidpad | 1.03 g [M] (C/D), 1.04 g (MT) | steady-state estimate 1.036 g | – | – |
| Launch | 3,500 rpm hold [F] | Engine holds 3,200 rpm while the clutch slips; peak 0.90 g in 1st | – | – |
| Shifts at full throttle | no torque interruption [F] | 1-2 at 54 km/h, 2-3 at 90, 3-4 at 131, 4-5 at 182, 5-6 at 248; none reaches the fuel cut | – | – |
| Idle, free rev | – | Idle 565 rpm (530-581); free rev reaches the cut in 0.28 s, then bounces 6,454-6,836 rpm, about 5 cuts a second | – | – |
| In-gear limiter (2nd) | about 100-150 rpm bounce [E] | 6,480-6,608 rpm, a cut every 0.25-0.27 s | – | – |

Against the brief's tolerances: top speed (±2%) and Motor Trend's braking (±5%) pass. Car and Driver's
braking is 11% short. The acceleration times are outside ±0.15 s, for reasons that are in the shared model,
not in this car's numbers:
- **Launch control isn't modelled for the dual-clutch.** The real car pre-revs to 3,500 rpm and drops the
  clutch with its launch control and Performance Traction Management. The model's launch behaves like
  Car and Driver's rolling start, which it matches exactly (3.50 s against 3.5 s). C/D's own gap between the
  two, 2.8 s against 3.5 s, is about the model's gap to 60 mph. From 60 mph up, the model is within 3% of
  every measured interval, so power, gearing, drag and efficiency are right.
- **A traction-control limit cycle below 3 m/s.** At 48, 50 and 60 fps the rear wheels oscillate from one
  sub-step to the next, and traction control holds a cut of about 52% until the car passes 11 km/h. That
  costs 0.25-0.5 s. At 66 fps and above it doesn't happen (the right-hand column). See "Shared-code
  problems".
- **Engine inertia counted twice** whenever the clutch is closed (found by the M5 builder; the coordinator
  puts it at about 0.12 s of 0-100 km/h on this car). A fix is in progress; this validation should be re-run
  once it lands.

## Sound

The definition is `assets/audio/engines/RefC8Stingray.json`; every number's source or estimate is in its
`notes`. The dev build is `assets/audio/dev/Dev_RefC8Stingray.flac` (29.0 s, 1.58 MB), with 22 loops:
on and off throttle at 600, 800, 1,050, 1,400, 1,850, 2,450, 3,250, 4,300, 5,450 and 6,600 rpm, plus free
and in-gear limiter loops. The previews are `assets/audio/preview/RefC8Stingray_drive_preview.mp3` and
`_tunnel_preview.mp3`, with spectrograms.

**What the definition says**
- Firing order 1-8-7-2-6-5-4-3 [F]. GM numbering: left bank 1-3-5-7, right bank 2-4-6-8. Cross-plane crank,
  90° V.
- `--check` output: firing gaps 90° throughout; bank sequence L R L R R L R L; left-bank pulse gaps
  180-270-180-90, right bank 180-90-180-270 (both uneven, which is the burble). No warnings.
- Headers: 4-into-1 per bank. X-pipe crossover 0.4 below 500 Hz (the reported internal X). Two outlets of
  1.9-1.95 m (76 mm pipe assumed); valves open.
- Valves open stands for Sport and Track (open at idle and in most driving). Tour, Stealth and V4 (AFM)
  cruising are not modelled.
- Intake level 0.3: a mid-engine car hears its intake. At 0.35 the evenly spaced intake pulses masked the
  exhaust's idle burble.
- Direct-injection tick 0.01, a slight cam lope (0.1), and mild overrun burble (0.12, about 0.7 pops a
  second): the stock NPP is "not very aggressive even in Track".
- Fuel cut at 6,600 rpm [P]. Free-revving loop bounces at 9 Hz with a 250 rpm drop; the in-gear loop at
  7 Hz with a 120 rpm drop, inside the research's 100-150 rpm.
- Loudness from C/D: 47 dBA idle and 92 dBA full throttle. The 74 dBA at 70 mph and the EU 95 dB(A)
  stationary figure are recorded, but the gain model doesn't use them.

**What was checked, by measurement** (I can't listen to audio; how it sounds is for the owner to judge)

1. **Firing frequency.** In every loop the strongest line up to order 4.5 is the firing order, at rpm/15 Hz:
   40.0 Hz at 600 rpm, 163.3 Hz at 2,450, 440.0 Hz at 6,600. The one exception is 3,250 rpm, where half order
   2.5 (135 Hz) is stronger. In the preview the idle lines sit at 37.7 Hz and multiples, because the model
   idles at 565 rpm.
2. **Orders and the burble's half orders.** Loops are whole engine cycles, so exact FFT bins were used.
   Half-order energy against integer-order energy, 50-500 Hz:

   | rpm | 600 on / off | 1,050 | 1,850 | 2,450 | 3,250 | 4,300 | 5,450 | 6,600 |
   |---|---|---|---|---|---|---|---|---|
   | Half orders vs integer orders | −3.9 / −3.8 dB | −4.3 | −0.8 | +3.7 | +2.0 | −2.1 | −2.9 | −0.5 |

   A flat-plane V8's half orders are more than 28 dB down (docs/AUDIO.md), so the cross-plane signature is
   strong at every speed.
   - The lowest half orders at idle (1.5-6.5, i.e. 15-65 Hz) are 20-39 dB under the firing order. At those
     wavelengths the two banks reach a centred listener almost in phase, so their uneven parts cancel.
     That's why the X-pipe crossover makes little difference there (separate banks measured the same).
   - On the limiter, half orders 2.5 (275 Hz) and 6.5 (715 Hz) are as strong as the firing order. They sit
     on the estimated outlet pipes' resonances.
3. **Relative levels.**
   - Loop gains follow the measured levels: idle on throttle −18.9 dB, off −24.9 dB; full throttle at 6,600
     rpm −1.5 dB.
   - In the drive preview, idle measures −41.1 dB(A) and full throttle −20.2 dB(A): a 20.9 dB range against
     the 22.5 dB intended (half of the measured 45 dB).
   - At 70 mph in 8th (1,465 rpm) the engine's modelled share is about 63 dBA against the measured 74 dBA in
     the cabin. So in the cockpit, tyre and wind noise should lead the engine by about 5.5 dB at the game's
     compression. The GT12's settings gave 0.8 dB; with `interior.road = 2.2` it measures 5.7 dB.
   - The level's rise with speed is about 1 dB steeper than auto motor und sport's 80-180 km/h series. That
     slope comes from the shared road-noise curve, whatever the volumes.
4. **Limiter.**
   - The free loop's loudness envelope repeats every 110 ms (9.1 Hz); the in-gear loop's spectrum peaks at
     7.0 Hz. Both swing about 12 dB between cut and fuel-on.
   - In the drivetrain model the cuts come every 0.20-0.28 s in neutral and 0.25-0.27 s in 2nd, so
     `limiterHold` is 0.35 s (the GT12's 0.3 left only 0.03 s of margin).
5. **Seams.** Re-measured from the decoded FLAC: every loop's jump at the loop point is 0.01-0.57 of its
   99th-percentile sample step, the same as the build's report, and inside docs/AUDIO.md's 0.01-1.2.
6. **Spectrograms viewed**: the drive and tunnel previews, plus a zoomed linear plot of the idle, the free
   rev and the 2nd-gear limiter hold.
   - The drive preview shows the event structure: idle; the free rev with the cut's vertical striations;
     rising harmonic sweeps through the upshifts; shift events; the 2nd-gear limiter hold from 21.3 s; the
     lifts. Its brightest band at the limiter reads about 430-445 Hz, the firing frequency.
   - The tunnel preview's harmonics smear with reverb between the portal marks (3.9-10.2 s).

**Config audio table**: shift cut 0.05 s at 0.35 volume (the DCT has no torque gap); crackles from
3,500 rpm, 0.5 s, 6 a second, 0.3 volume (mild stock NPP); gearbox whine at the ring-and-pinion mesh
(`whineTeeth` 6.19, 32 ring teeth per wheel turn, inferred from 3.555 = 32 / 9); cockpit equaliser with
less treble cut than the GT12 (the engine sits right behind the seats).

**Not modelled.** Drive modes (one exhaust state: open), the cold-start flare (1,200-1,500 rpm for 5-15 s
with the valves open), V4 (AFM) firing at light load (orders 2-dominant), and a lower park/neutral rev limit
(not found). The free-rev overshoot in the model is drawn by the engine model, not the sound: the audible
bounce is the baked loop's.

## Gaps

- **Acceleration to 60 mph and the quarter mile** are 0.3-0.7 s slow, for the three reasons above.
- **Braking against Car and Driver** is 11% short. Matching it would leave Motor Trend 12% long and slow
  the traction-limited launch further.
- **Not published, so estimated:**
  - Cd and frontal area (the drag area is fitted);
  - the eLSD calibration;
  - idle rpm;
  - CoM height and inertia;
  - spring, damper and anti-roll rates;
  - brake torques;
  - pipe lengths and diameters;
  - limiter bounce depth and rate;
  - the park/neutral rev limit;
  - the drive mode of C/D's idle level.
- **Run-flat status** now has one secondary source: C/D's panel as copied on a blog [S42], which lists PS4S
  ZP. It was not checked against C/D's own page.
- **Blockout** fractions come from perspective photos, ±0.05 of the length.
- **No recording was analysed.** The two Commons candidates in the research weren't downloaded (HTTP 429),
  and one has an aftermarket cat-back.

## Shared-code problems found

1. **Anti-stall with idles at or below 750 rpm** (`TransmissionSimulation/Transmission.luau`,
   `Transmission.engagement`, and `Trans.engagement` in `tools/drivetrain_model.py`).
   - The bug: `clamp((engineRpm - 600) / (idleRpm - 750), 0, 1)` never opens the clutch when idle ≤ 750 rpm.
   - On this car (idle 600) ordinary braking to a stop, at 15-30% pedal, leaves it creeping at 2.3-2.9 km/h
     with the engine dragged to its 330 rpm floor and the clutch closed. Holding a gear manually does the
     same. The model's full-pedal tests happen to stop.
   - Proposed change (identical to today's for a 1,000 rpm idle, so the GT12 is unchanged bit for bit; tested
     in scratch):
     ```lua
     if engineRpm < 0.85 * idleRpm then
     	-- anti-stall: open the clutch as the engine is dragged below idle (fully open at 60% of idle)
     	engagement = math.min(engagement, math.clamp((engineRpm - 0.6 * idleRpm) / (0.25 * idleRpm), 0, 1))
     end
     ```
     ```python
     if erpm < 0.85 * idle: e = min(e, clamp((erpm - 0.6 * idle) / (0.25 * idle), 0, 1))
     ```
   - With it, every braking case stops and the engine returns to 565 rpm. One edge case remains: holding 2nd
     manually at a standstill settles at 366 rpm with the clutch 4% engaged.
   - Stopgap if it can't land before testing: set this car's `idleRpm` to 800. That was tested to stop
     cleanly, but it raises the idle sound by a third.
2. **Low-speed tyre slip floor** (`TireSimulation/Tire.luau` line 85, and `drivetrain_model.py` line 402).
   - The tyre measures slip against `math.max(math.abs(vLong), 3)`, while traction control uses 6 m/s.
   - Below 3 m/s the stiff tyre makes the explicit sub-steps oscillate, and traction control reacts to the
     spikes. At 60 fps this car's 0-60 mph varies from 3.74 to 4.29 s with frame rate; the GT12 does the same
     at 48-54 fps.
   - Proposed change: `/ math.max(math.abs(vLong), 6)` in both files.
   - Tested in scratch: this car then runs 3.69-3.71 s at every frame rate from 48 to 144 fps, and the GT12's
     60 fps 0-60 goes from 3.25 to 3.20 s. 100-0 km/h braking changes by 0.2 m or less.
   - It changes low-speed tyre behaviour for every car, so it needs a Studio check.
3. **Dual-clutch upshift flare** (data, not code). With `shiftTorqueFraction × clutchMaxTorque` below the
   engine's torque, the engine flares during each shift. The GT12's full-throttle upshifts reach its fuel cut
   (8,928 and 8,959 rpm in the model), which also brings in its limiter loops on every shift. A fraction near
   peak torque / clutch capacity avoids it.
4. **No dual-clutch launch control.** Holding the brake builds about 3,200 rpm against a half-closed clutch;
   there is no pre-rev and clutch drop. This is the main acceleration gap for this car (see Validation).
5. **Fuel cut through the throttle's lag** (`Engine.luau`): the free rev overshoots the cut by about
   250 rpm (the first hit reaches the 7,000 rpm clamp), where a real fuel cut is instant. It is
   visible on the tachometer only.
6. **Model builder** (suggestion): exhaust tips are fixed near the centre, and the body below the beltline is
   one box. A `visual.exhaustTips` list would let this car show its corner tips.

## What to check in Studio

- **Stops.** Brake gently to a stop and hold the brake. The car should stop and idle near 565-600 rpm. If it
  creeps at 2-3 km/h, that is problem 1.
- **Launch.** Full throttle from a standstill: the HUD's 0-60 mph should read about 3.7-4.0 s (the factory
  figure shown is 2.9 s; see Validation).
- **Speeds.** The quarter mile should read about 12.0-12.3 s at about 194 km/h; top speed about 294-296 km/h,
  in 6th.
- **Braking.** 100-0 km/h should be about 32 m.
- **Limiter.**
  - In neutral or in 2nd at full throttle, the limiter loops should hold steadily.
  - The HUD's LIMIT flag flickers about 4-5 times a second.
  - Full-throttle upshifts should not light LIMIT.
- **Cockpit at 110 km/h in 8th.** Tyre noise should be clearly above the engine.
- **Handling.** At the limit the car should be close to neutral.

## Sources

- [S01] GM preliminary specs (Corvette Story copy): https://mobile.corvettestory.com/2020-Corvette-C8-mid-engine-specs.php
- [S02] Corvsport 2020 specifications: https://www.corvsport.com/2020-corvette-specifications/
- [S03] GM release, 0-60 2.9 s and ¼ mile 11.2 s at 121 mph (CorvetteBlogger, 6 Nov 2019): https://www.corvetteblogger.com/2019/11/06/official-the-2020-corvette-stingray-goes-0-60-mph-in-2-9-seconds-runs-quarter-mile-in-11-2-121-mph/
- [S04] SAE Mobility Engineering, inside Tremec's Corvette DCT: https://www.mobilityengineeringtech.com/component/content/article/40895-sae-ma-00017
- [S05] Corvette Magazine, "Two Clutches, No Waiting": https://www.corvette-mag.com/issues/135/articles/two-clutches-no-waiting
- [S06] Tremec / GM TR-9080 release (Corvette Action Center): https://corvetteactioncenter.com/specs/c8-corvette/2020-corvette/press-release-2020-corvette-tremec-8-speed-dual-clutch-transmission.html
- [S07] Corvette Magazine, "Inside the LT2": https://corvette-mag.com/issues/134/articles/inside-the-lt2
- [S08] EngineLabs, the LT2: https://www.enginelabs.com/engine-tech/the-new-2020-corvette-lt2-engine-more-of-the-same-but-different/
- [S10] Wikipedia, Chevrolet Corvette (C8): https://en.wikipedia.org/wiki/Chevrolet_Corvette_(C8)
- [S11] Wikipedia, GM small-block engine: https://en.wikipedia.org/wiki/General_Motors_small-block_engine
- [S12] GM chart "LT2 vs LS6 engine performance comparison": https://images-stag.jazelc.com/uploads/theautopian-m2en/ls6-performance-e1774532266852.png
- [S13] Car and Driver test, Oct 2019 (Yahoo copy): https://uk.news.yahoo.com/2020-chevrolet-corvette-more-best-143100266.html
- [S14] Car and Driver, 2.8 s to 60 mph: https://uk.news.yahoo.com/2020-chevy-corvette-hits-60-203000416.html
- [S15] Car and Driver, Z51 vs Cayman GT4, Sept 2020: https://uk.news.yahoo.com/tested-2020-chevrolet-corvette-z51-163800417.html
- [S16] C/D sound levels quoted on MidEngineCorvetteForum: https://www.midenginecorvetteforum.com/forum/me-discussion-photos-videos/97277-noise-level
- [S17] 2027 vs 2020 comparison (SSBCrack, secondary): https://news.ssbcrack.com/2027-chevrolet-corvette-stingray-performance-review-and-comparison-with-2020-model/
- [S18] Motor Trend test (CorvetteBlogger): https://www.corvetteblogger.com/2019/10/15/motor-trend-2020-corvette-stingray-z51-runs-0-60-in-2-8-seconds-quarter-mile-in-11-1-123-2-mph/
- [S19] auto motor und sport technical data and measurements: https://www.auto-motor-und-sport.de/test/chevrolet-corvette-stingray-unterwegs-im-495-ps-starken-v8/technische-daten/
- [S20] ADAC Autokatalog: https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/chevrolet/corvette/c8/341293/
- [S22] Top speed and Z51 downforce (Motor Authority): https://www.motorauthority.com/news/1124601_2020-chevy-corvette-stingray-s-top-speed-is-194-mph-but-z51-is-slower
- [S23] SAE Mobility Engineering, "An Exhaust Symphony in the Key of C8": https://www.mobilityengineeringtech.com/component/content/article/44640-sae-ma-03960
- [S24] CorvetteBlogger, Tenneco's C8 exhaust: https://www.corvetteblogger.com/2020/03/16/tennecos-c8-corvette-exhaust-system-detailed/
- [S25] Corvette Forum, AFM and NPP valves: https://www.corvetteforum.com/forums/c8-tech-performance/4953174-afm-and-npp-valves.html
- [S26] Corvette Forum, NPP usage and cold start: https://www.corvetteforum.com/forums/c8-stingray-general-discussion/4605453-npp-usage.html
- [S27] Corvette Forum, limiter: https://www.corvetteforum.com/forums/c8-tech-performance/4681888-limiter.html
- [S28] Corvette Forum, stock dyno numbers: https://www.corvetteforum.com/forums/c8-tech-performance/4614246-dyno-numbers-are-in.html
- [S29] Z51 front rotors 345 × 30 mm (Paragon): https://www.paragonperf.com/ebc-c8-corvette-stingray-z51-front-2pc-rotors.html
- [S30] Corvette Forum, drag coefficients: https://www.corvetteforum.com/forums/c8-tech-performance/4338961-drag-coefficients.html
- [S31] Autoblog, 1LT coupe specs: https://www.autoblog.com/buy/2020-Chevrolet-Corvette-Stingray_w_1LT__2dr_Coupe/specs
- [S32] GM Authority, leaked GM document: https://gmauthority.com/blog/2019/08/2020-corvette-stingray-performance-figures-leaked-from-alleged-gm-document/
- [S36] Wikimedia Commons C8 photos: https://commons.wikimedia.org/wiki/Category:Chevrolet_Corvette_C8
- [S39] Paragon dyno, stock Stingray: https://www.corvsport.com/video-paragon-performance-tests-the-2026-corvette-grand-sports-new-6-7l-ls6-v8/
- [S41] Z51 at 191.7 mph (CorvetteBlogger): https://www.corvetteblogger.com/2023/03/22/video-c8-corvette-stingray-with-z51-runs-top-speed-of-191-7-mph-on-the-space-shuttles-runway/
- [S42] Car and Driver's data panel for the 2020 Z51, as copied on a blog (secondary; its 2.8 s, 11.2 s at 122 mph, 149 ft, 1.03 g and 3,647 lb agree with S13 and S14): https://m4store.blogspot.com/2021/02/corvetee-2020.html
