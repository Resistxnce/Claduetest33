# Brandt Kestrel RS

*Internal ID `RefM3G80`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/RefM3G80.luau`.
Engine sound: `assets/audio/engines/RefM3G80.json` → `VehicleAudio/Sheets/RefM3G80_Engine.luau`.*

An original four-door sports sedan from the fictional German maker Brandt, built to the publicly
documented engineering of the **BMW M3 Competition sedan (G80)**: rear-wheel drive, S58 twin-turbo
inline-6, 8-speed torque-converter automatic, with the M Driver's Package top speed. No BMW names,
logos or designs are used in the game. The research behind every number is
`research_notes/cars/RefM3G80.json` and `.md`; source ids below (BMW_SPEC_M3, CD_RWD, ...) refer to
it and are linked under [Sources](#sources).

Tags: **[F]** maker's figure, **[P]** published third-party figure, **[M]** measured by a magazine or
independent test, **[E]** estimate for the simulation, **[A]** assumption.

## Published figures

| Item | Value | Tag | Source |
|---|---|---|---|
| Engine | S58B30T0, 2,993 cc inline-6, 84.0 × 90.0 mm, 9.3:1; front, longitudinal | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| Turbochargers | Two MHI mono-scroll turbos, one per three cylinders (1-3 and 4-6); electric wastegates; air-to-water charge cooling | F | [BMW_PK][BMW_PK], [BMW_ST1926][BMW_ST1926] |
| Boost | 1.7 bar maximum | P | [AMS][AMS]; Car and Driver 24.7 psi |
| Power | 375 kW (510 PS / 503 hp) at 6,250 rpm; BMW's diagram holds 375 kW from 5,600 to 7,200 rpm | F | [BMW_SPEC_M3][BMW_SPEC_M3], [BMW_SPEC_M4][BMW_SPEC_M4] |
| Torque | 650 Nm from 2,750 to 5,500 rpm; full-load curve 245 Nm at 1,000, 295 at 1,500, 345 at 2,000, 460 at 2,500, 650 from 2,744 rpm | F | [BMW_SPEC_M4][BMW_SPEC_M4] (vector diagram) |
| Redline / limiter | 7,200 rpm / 7,250 rpm | F / P | [BMW_PK][BMW_PK] / [evo][EVO] |
| Firing order | 1-5-3-6-2-4, cylinder 1 at the front | P (A for the S58) | [FIRING][FIRING] |
| Gearbox | ZF 8HP76 8-speed torque-converter automatic: 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640; reverse 3.478; final drive 3.154 | F | [BMW_SPEC_M3][BMW_SPEC_M3], [BMW_US21][BMW_US21] |
| Lock-up | "fully engaged the moment the car has pulled away" | F | [BMW_PK][BMW_PK] |
| Differential | Active M Differential, electronically controlled multi-plate, 0-100% locking | F | [BMW_PK][BMW_PK] |
| Mass | 1,730 kg DIN; 1,805 kg EU (with 75 kg driver); US curb 3,890 lb | F | [BMW_SPEC_M3][BMW_SPEC_M3], [BMW_US21][BMW_US21] |
| Weight distribution | 53.1 / 46.9 % (MotorTrend measured 53/47) | F (M) | [BMW_US21][BMW_US21], [MT_FT][MT_FT] |
| Length × width × height | 4,794 × 1,903 × 1,433 mm; wheelbase 2,857 mm; track 1,617 / 1,605 mm; front overhang 860 mm | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| Drag | Cd 0.33 × 2.34 m² = 0.772 m² | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| Tyres | 275/35 ZR19 front, 285/30 ZR20 rear (optional on RWD, fitted to every test car; standard 275/40 R18 and 285/35 R19); Michelin Pilot Sport 4S on the test cars | F / P | [BMW_PK][BMW_PK], [CD_RWD][CD_RWD] |
| Brakes | M Compound: 380 × 36 mm front with 6-piston fixed calipers, 370 × 24 mm rear, single piston; test cars had carbon-ceramics | F / P | [BMW_PK][BMW_PK], [DISC_PARTS][DISC_PARTS] |
| Steering | 15:1 variable ratio; turning circle 12.2 m | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| 0-100 / 0-200 km/h | 3.9 s / 12.5 s | F | [BMW_SPEC_M3][BMW_SPEC_M3], [BMW_PK][BMW_PK] |
| 0-60 mph | 3.8 s | F | [BMW_US21][BMW_US21] |
| 80-120 km/h | 2.6 s in 4th, 3.4 s in 5th | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| Top speed | 250 km/h limited; **290 km/h with the M Driver's Package** (used here) | F | [BMW_SPEC_M3][BMW_SPEC_M3] |
| Cabin sound | idle 45, full throttle 82, 100 km/h 70, 130 km/h 73 dB(A) (AMS); 84 dBA full throttle, 72 dBA at 70 mph (C/D) | M | [AMS][AMS], [CD_RWD][CD_RWD] |
| Active Sound Design | engine orders added through the speakers; reduced by M Sound Control or switched off in a menu | F | [BMW_ST1926][BMW_ST1926], [CD_RWD][CD_RWD] |

Magazine performance figures are in the validation table.

## Estimates and how they were made

| Item | Value | How |
|---|---|---|
| Simulated mass | 1,805 kg | DIN 1,730 kg [F] + 75 kg driver [A] = BMW's EU figure |
| Centre of mass | 0.49 m high; 1.340 m behind the front axle | Height: research estimate. Position from 53.1/46.9 |
| Rotational inertia | about 3,270 kg·m² in yaw | 4.30 × 1.80 × 0.80 m mass box (dynamic index about 0.9, usual for a front-engined sedan) |
| Full-boost torque curve below 2,744 rpm | 650, 783, 647, 543, 605 Nm at 1,000, 1,500, 2,000, 2,500, 2,651 rpm | BMW's torque at each vertex divided by the boost factor there (VEHICLE_CONFIG.md step 5), so the **steady** full-throttle torque equals BMW's diagram at every vertex (checked with `--curve`: 245, 295, 345, 460, 650 ... 511 Nm). BMW's boost rise is convex (slow, then steep near 2,500 rpm) and the model's ramp is linear, so the shape has to go into these points |
| Above 7,198 rpm | 494 Nm at 7,250 | 375 kW held to the limiter |
| Off-boost share | 0.377 | 245 Nm at 1,000 rpm / 650 Nm, which is also 1 / (1 + 1.7 bar) |
| Boost ramp | 1,750 → 2,744 rpm | 2,744 rpm is where BMW's curve reaches 650 Nm [F]. The start puts the steady boost gauge at 0.43 bar at 2,000 rpm, the pressure BMW's 345 Nm implies there |
| Spool / dump | 0.7 s / 0.2 s | Middle of the shared starting range; checked (not fitted) against the in-gear times below. Electric wastegates, no blow-off valve |
| Engine inertia | 0.20 kg·m² | Research estimate: crank (21.2 kg [F]), rods, pistons, damper, flexplate, converter impeller |
| Friction | 25 + 0.0072 × rpm Nm | FMEP about 1.1 bar at 3,000 rpm and 2.3 bar at 7,000, plus about 0.9 bar of closed-throttle pumping, for 2,993 cc |
| Idle | 700 rpm | Research: B58/S58 automatics idle at 650-750 rpm |
| Limiter | 100 rpm hysteresis, throttle response 20 /s | A tight cut: the free rev bounces 7,140-7,470 rpm about 4.5 times a second, 7,150-7,270 rpm in gear |
| Converter | stall 3,100 rpm, torque ratio 1.9, coupling point 0.87 | Launch control holds about 2,700 rpm [P, BMAG_LC] with about 1.0 bar of boost [M, CITIZEN_ART; CD_XD "above 15.0 psi"]. That is about 480 Nm absorbed at 2,700 rpm, a converter that takes the full 650 Nm at 3,100 rpm. (With BMW's steep torque rise, any `stallRpm` of 2,400-2,744 settles at about 2,950 rpm at full boost anyway, so the research's 2,400-2,800 estimate and this agree) |
| Lock-up | from 1st, above 10 km/h, 0.3 s, 910 Nm | BMW's "fully engaged the moment the car has pulled away" [F]; capacity 1.4 × peak torque |
| Shifts | 0.15 s up, 0.20 s down with a 0.3 throttle blip, 40% torque cut | Research: 0.10-0.15 s torque dip in the sportiest Drivelogic setting; automatic rev-matching [F] |
| Shift points | upshift 1,700-7,050 rpm, downshift 900-4,200 rpm by pedal | Full throttle shifts 200 rpm under the limiter, so the car meets the 290 km/h limiter in 7th; a steady 100 km/h holds 8th at 1,577 rpm (MotorTrend measured 1,500 rpm at 60 mph in 8th) |
| Gearbox efficiency | 0.89 | Rear-drive automatic with the lock-up closed |
| Differential | clutch-type: preload 80 Nm, 45% on power, 25% on coast | Research estimate for the Active M Differential |
| Traction control | 11% target slip, rate 15, recovery 2, headroom 1.3 | The shared starting values (see Validation for why they were not changed) |
| Tyre ("RoadPerformance") | grip 1.25 braking/driving, 1.08 cornering, on the shared Performance base | Pilot Sport 4S class. muLong sits between the measured braking (MT 60-0 mph: 1.18 g mean; C/D 70-0: 1.09 g, both including brake build-up, which the model doesn't have) and the traction-limited launch (MT 0-50 mph about 0.73 g including the 1-2 shift). muLat for the 1.03 g skidpad (C/D, MT) after load transfer |
| Track tyre ("TrackTyre", not fitted) | 1.40 / 1.21 | Pilot Sport Cup 2 class option, about 12% more grip |
| Springs | 48,400 N/m front, 54,100 N/m rear | Research ride frequencies 1.6 / 1.8 Hz on the game's full corner masses (479 / 423 kg; the game has no unsprung mass). The research's 43,000 / 48,000 are for the real car's sprung mass |
| Dampers | 2,900 bump / 4,800 rebound N·s/m | About 0.3 and 0.5 of critical |
| Anti-roll bars | 32,000 / 18,000 N/m | About 56% of the roll stiffness at the front (front weight 53%): mild understeer; about 1.6° of roll per g |
| Roll centres | 0.06 m front, 0.10 m rear | BMW: lowered front roll centre [F] |
| Brakes | 3,600 / 1,700 Nm per wheel, 68% front | Enough to lock the wheels at 1.2 g (about 2,600 / 950 Nm needed) |
| Aero | CdA 0.772 [F]; lift areas 0.06 front, 0.08 rear | BMW gives only Cd × A; research suggests near-zero lift |
| Steering | 32° when slow, 4.5° at 250 km/h | 32° average road-wheel angle gives the 12.2 m turning circle on this wheelbase |
| Speed at 7,250 rpm by gear | 58.8, 91.9, 137.3, 171.0, 224.1, 294.2, 357.5, 459.7 km/h | Ratios [F] and the game's unloaded 0.3395 m rear radius (the research's loaded 0.335 m gives about 1.3% less) |
| Paint | RGB (18, 84, 62) | [A] approximation of the launch colour, a deep metallic green |

## Validation

`python3 tools/drivetrain_model.py RefM3G80` drives the configuration with the Python copy of the
game's drivetrain, at 60 frames a second. In-gear times use the same model with the gear held
(scratch scripts in the build folder).

**A shared bug** (found by the M5 builder, being fixed by the drivetrain engineer when this was written)
counts engine inertia twice whenever the lock-up is closed. The table shows the tool as it is now,
and the same run with the proposed fix applied in memory (a scratch preview, not shared code).
US magazines time from a one-foot rollout; the model gives both.

| Test | Factory [F] | Magazine [M] | Model now | Model with the inertia fix |
|---|---|---|---|---|
| 0-60 mph (true start) | 3.8 s | n/a | 4.82 s | 4.43 s |
| 0-60 mph, 1-ft rollout | n/a | 3.5 s (C/D, MT) | 4.43 s | 4.05 s |
| 0-100 km/h | 3.9 s | 3.64 s (The Citizen) | 4.98 s | 4.60 s |
| 0-100 mph, 1-ft rollout | n/a | 7.6 s (C/D), 7.5 s (MT) | 8.82 s | 8.32 s |
| 0-200 km/h | 12.5 s | about 11.7 s (The Citizen, 3.64 + 8.01 from 100) | 13.35 s | 12.78 s |
| 100-200 km/h | 8.6 s implied | 8.01 s (The Citizen, from 3rd) | 8.37 s | 8.18 s |
| Quarter mile, 1-ft rollout | n/a | 11.6 s at 199.6 km/h (C/D), 11.6 s at 202.1 km/h (MT); The Citizen 11.58 s at 201.2 km/h | 12.40 s at 195.5 km/h | 12.07 s at 197.3 km/h |
| 80-120 km/h, 4th held | 2.6 s | 2.67 s (The Citizen) | 2.77 s | 2.72 s |
| 80-120 km/h, 5th held | 3.4 s | 4.02 s (The Citizen) | 3.65 s | 3.60 s |
| 60-100 km/h, 3rd / 4th held | n/a | 2.21 / 2.95 s (The Citizen) | 2.28 / 2.82 s | 2.22 / 2.77 s |
| Top speed | 290 km/h (limited) | 293 km/h GPS (search extract) | 287.6 km/h in 7th, on the limiter | same |
| 60-0 mph braking | n/a | 31.1 m (MT) | 30.1 m (-3%) | same |
| 70-0 mph braking | n/a | 45.7 m (C/D) | 40.8 m (-11%) | same |
| 100-0 mph braking | n/a | 90.5 m (C/D) | 82.3 m (-9%) | same |
| 100-0 km/h braking | n/a | none; research estimate 34 m | 32.3 m | same |

Other results (model now): idle 681 rpm (658-692) in park, 661 rpm in drive on the brake, creep 5.4 km/h;
a steady 100 km/h holds 8th at 1,577 rpm; 35% pedal reaches 117 km/h in 6th, then coasting drops to
8th; boost reaches 90% 1.3 s after flooring at 2,100 rpm in 3rd and 0.5 s at 4,100 rpm; the free rev
reaches the limiter in 0.45 s.

**What matches.**
- **Top speed sits on the electronic limiter.** The road load at 290 km/h needs 264 kW at the wheels,
  against 334 kW available. The model settles 2.4 km/h under 290 because the limiter closes the throttle
  over its last 3 km/h.
- **The in-gear times are within about 0.1 s of the measured ones** (60-100 km/h in 4th is 0.18 s
  quicker than The Citizen's), and 80-120 km/h in 5th falls between BMW's figure and The Citizen's.
  These start at 2,500-3,400 rpm, so they test the torque curve, boost build and gearing without the
  launch.
- **Above 100 km/h the model is on the published figures:** 100-200 km/h takes 8.2-8.4 s, between
  BMW's implied 8.6 s and The Citizen's 8.01 s.
- **MotorTrend's 60-0 mph stop is within 3%.**

**What doesn't, and why.**
- **The start is 0.4-0.7 s slow** (0-100 km/h 4.60 s with the fix, against 3.9 s). All of it is in the
  first 100 km/h:
  - BMW's 3.9 s and the magazines' 3.5 s use launch control, which holds the engine near 2,700 rpm on
    the brakes while about 1 bar of boost builds, and pulls away in **2nd gear** on the rear-drive car
    (The Citizen).
  - The game's brake-held launch is capped by traction control at about 1,600 rpm with no boost (the
    known limitation in VEHICLE_CONFIG.md). So the start is a plain full-throttle start in D.
  - In D, the engine sits off boost at 1,700-2,400 rpm for about half a second while the lock-up
    closes. There BMW's own curve gives only 345-460 Nm, and the car pulls 0.4-0.5 g instead of about
    0.7 g.
  - The 1-2 upshift then spins the tyres (slip 0.36). Traction control's slow recovery (2 /s) costs
    another 0.1-0.15 s.
  - A scratch emulation of launch control alone (engine started at 2,700 rpm with boost built) did not
    help. Released at stall, the converter spins the rear tyres. Traction control (its cap, divided by
    the converter's torque multiplication, and its slip cut) then drags the engine back to about
    1,500 rpm within 0.12 s, and the boost dumps.
- **The magazines' cars are a little quicker everywhere power matters** (quarter-mile trap 197 km/h
  against 200-202 measured). That fits the research's note that the 375 kW rating is conservative:
  ARM Motorsports' Mustang dyno measured 335 kW at the wheels of a stock xDrive car, which implies
  385-400 kW at the crank. The configuration keeps BMW's figure.
- **Car and Driver's stops are 9-11% longer than the model's.** Their 70-0 mph (150 ft) is 8% longer
  than MotorTrend's 60-0 scaled up (139 ft), on the same tyres. The model also applies full brakes
  instantly, while real tests include 0.1-0.2 s of pressure build-up, about 2 m at these speeds. One
  grip value can't meet both magazines within 5%. 1.25 meets MotorTrend's and stays within 5% of the
  research's 34 m estimate for 100-0 km/h.

**Tuning: what was changed, what was tried and put back.**
- **Set from evidence, not to hit times:**
  - tyre grip (from braking, launch traction and skidpad together; this made acceleration slower than
    the first draft's 1.30);
  - converter stall (launch-control boost data);
  - boost ramp start (boost gauge);
  - limiter hysteresis and throttle response (limiter bounce);
  - shift points (top-speed gear and cruise gear).
- **Tried and reverted** after the coordinator reported the inertia bug (don't tune estimates to make
  up acceleration time):
  - traction-control headroom 1.6, rate 30, recovery 6;
  - lock-up from 20 km/h;
  - spool time 0.5 s.

  The headroom change only compensated for the bug: with the fix, 1st gear reaches the tyres' peak at
  1.3.
- **Options left open:**
  - BMW says its ECU-based slip control "acts up to 10 times more often" [F]. That would support rate 30
    and recovery 6, which on the fixed model take 0-100 km/h to 4.45 s and the 1-2 shift spike to slip
    0.27.
  - Lock-up from 20 km/h gains only 0.03 s and contradicts BMW's statement, so it isn't recommended.

**Shared-code observations** (reported, not changed):
- **Launch control for automatics.** Proposed:
  - while the brake holds the car at a standstill, skip the traction-control cap and hold the engine at
    a configured `transmission.launchRpm` (BMW: about 2,700);
  - after release, start the cap from the measured slip rather than dividing the feed-forward cap by
    the converter's torque ratio;
  - optionally add a `launchGear` (2 for this car).

  Without it, no automatic turbo car can reach its launch-control figures.
- **Rev limiter overshoot.**
  - The problem: the fuel cut only sets the throttle target to 0 (`Engine.luau` `Engine.netTorque`,
    lines 107-112; `drivetrain_model.Engine.net`), and the throttle decays at `throttleResponse`. So this
    light, torquey engine overshoots its first free-rev hit to the model's 7,650 rpm clamp (limiter +
    400) before settling into a 7,140-7,470 rpm bounce.
  - Proposed: a fuel cut removes combustion torque at once. In `Engine.netTorque`,
    `local drive = if engine.limiterCut then 0 else Engine.curveTorque(spec, rpm) * delivered`, and the
    same in Python (`drive = 0 if s.cut else curve_torque_of(spec, r) * delivered`).
  - Tested in memory: this car's first free-rev peak falls from 7,650 to 7,265 rpm, then it bounces at
    7,146-7,264 rpm 15 times a second. The GT12 (which also hits its 9,300 rpm clamp now) peaks at
    8,924 rpm and bounces 13.5 times a second.
  - This changes every car's limiter bounce, so the GT12's validated figures would need rechecking.
- **Speed limiter.**
  - The problem: it closes the throttle over the last 3 km/h (`VehicleSimulation.luau` line 249,
    `drivetrain_model.run`), so limited cars settle 2-3 km/h under their limit.
  - Proposed: dividing by 1 instead of 3 holds within about 1 km/h.
- **HUD labels.** Every target is labelled "factory", including magazine figures such as `quarterMile`.
  Proposed: in `HUD.luau` line 99, `"factory "` becomes `"target "`.
- **Boost ceiling.** A linear ceiling can't follow a convex factory boost rise. An optional
  `forcedInduction.boostCeiling = { {rpm, share}, ... }` table in `Engine.boostCeiling` and
  `drivetrain_model.boost_ceiling` would let the full-boost curve stay a flat 650 Nm. For the S58 that
  table is 0 at 1,000 rpm, 0.12 at 1,500, 0.25 at 2,000, 0.53 at 2,500, 0.80 at 2,651 and 1 at 2,744.

## Sound design

The engine is synthesized from `assets/audio/engines/RefM3G80.json` (every number has its source in
`notes`):

- **Firing.** Firing order 1-5-3-6-2-4 [P], one firing every 120° (firing frequency rpm / 20: 35 Hz at
  idle, 362 Hz at the limiter).
- **Exhaust branches.**
  - Cylinders 1-3 and 4-6 each feed a mono-scroll turbo [F] through short cast manifolds, so each branch
    carries even 240° pulses (order 1.5), the two branches 120° apart. `--check` confirms 240-240-240 on
    both.
  - The two branches meet in a large rear silencer whose four tailpipes are interconnected [F], modelled
    as a full merge (`y`) with equal 3.5 m branches.
- **Flaps.** Two exhaust flaps open under load or above 3,500 rpm (SPORT) [F/E].
- **Filters.** A treble cut for the EU particulate filters, which evo blames for the "muted tone".
- **Limiter.** Fuel-cut limiter at 7,250 rpm [P], baked at 9 bounces a second free-revving and 7 in
  gear.
- **Turbo.** A faint turbo whistle and a quiet recirculating lift-off whoosh (no blow-off valve is
  documented, and no tester mentions turbo noise).
- **Overrun.** A mild lift-off burble [E].
- **Loudness.** The sheet's gains come from auto motor und sport's cabin levels:
  - idle 45 dB(A); full throttle 82 dB(A), minus the 3 dB that Active Sound Design adds under load
    (research estimate: about half of the cabin engine sound under load comes from the speakers);
  - so outside cameras hear the engine itself. The cockpit camera puts the speakers back:
    `audio.interior.engine = 1.19`, +3 dB at the game's 0.5 dB-per-dB compression. Its equaliser lifts
    the low orders.

**Checks** (measured: I can't listen):

- **Engine orders.**
  - Loops from 700 to 7,250 rpm are dominated by the firing order and its multiples (3, 6, 9, 12).
  - In the rendered drive, the strongest peak at idle is 34 Hz = order 3.02 at 681 rpm. On the limiter
    in 2nd it is 360 Hz = order 3.00 at 7,207 rpm, with 720 and 1,081 Hz next. The 706 Hz peak is a
    sideband of the 7 Hz cut pattern.
- **Against a real recording.** I compared with the research's freely licensed G80 recording
  (aftermarket Fi Exhaust, so orders only; steady stretches at 2,200 and 2,650 rpm, `--analyze`). Its
  half orders 4.5 and 7.5 sit 30-42 dB under the firing order. The first draft (separate unequal
  branches) had them 18-31 dB too strong. The full merge brings them to -20 to -30 dB, and the mean
  order error falls from 7.9 to 6.5 dB at 2,650 rpm.
- **Remaining difference with the recording.** It has order 6 at +8 to +13 dB over order 3, where the
  synthesis has -7 to +1. Turbo damping and primary length change that by only 1-3 dB. The rest is
  probably the aftermarket system and a camera microphone; the shared calibration against a V8 recording
  shows the same direction.
- **Loudness**, relative to idle, in the preview's mix (chase / cockpit):

  | | 100 km/h, 8th, 1,577 rpm | 130 km/h, 8th, 2,060 rpm | Full throttle, 5,500-7,100 rpm |
  |---|---|---|---|
  | Chase camera | +10.2 dB | +13.2 dB | +16.8 dB |
  | Cockpit | +11.5 dB | +14.4 dB | +17.0 dB |
  | Measured (AMS), halved | +12.5 dB | +14.0 dB | +18.5 dB (+17.0 for the engine alone, without the speakers) |

  - The cockpit is 1.5 dB over the chase camera at both idle and full throttle (the speaker gain).
  - Active Sound Design matters mostly under load, but the game's cockpit gain is flat, so the cockpit
    idle is about 1.5 dB (3 dB real) louder than measured.
  - The preview doesn't apply the cockpit equaliser.
- **Turbo whistle.** At full boost, the band within 3% of its pitch holds 1.3% of the A-weighted energy
  (-18.9 dB).
- **Spectrogram** (`assets/audio/preview/RefM3G80_drive_preview_spectrogram.png`, viewed):
  - the idle;
  - the free rev to the limiter, with the striated cut pattern from 2.4 s;
  - the launch, with the upshift sawtooth and shift cracks;
  - the whistle sweeping down at lift-off;
  - rev-matched downshifts;
  - the 2nd-gear limiter hold from 20.2 to 24.5 s.

  The tunnel preview shows the low-mid build-up from 3.9 to 10.2 s.
- **Loop seams.**
  - The tool's seam figures are 0.00-0.92, inside the 0.01-1.2 range.
  - Played back to back, the high-frequency energy at every junction is at most 1.06 times the loop's
    own 99th percentile, so there are no clicks.
- **Limiter switch.** The simulation cuts 4.5 times a second free-revving and 2.7-3.8 times in 2nd-4th,
  never more than 0.15 s apart. `limiterHold` is 0.4 s, which also covers 5th, where the engine needs
  about 0.35 s to climb back.

Files: `assets/audio/dev/Dev_RefM3G80.flac` (31.7 s, 1.73 MB; dev build), the sheet, and
`assets/audio/preview/RefM3G80_drive_preview.mp3` and `_tunnel_preview.mp3` with spectrograms.
The car is silent in game until `Engines_Pack1` is packed and uploaded.

## Stand-in body

The blockout follows the research's trace of BMW's side drawing (heights normalised to the 1,433 mm
roof [F]; peak 1,433 mm at 0.59 of the length).
- **Glass.** It runs from the windscreen base (0.31) to just above the boot lid (0.86), so a short
  painted strip marks the notchback's boot step.
- **Beltline.** It is 0.92 m. The real window sill is about 1.0 m, but the builder draws everything below
  the beltline as one box, and 0.92 keeps the high shoulder while still showing the bonnet's rise to the
  windscreen. The nose is accordingly tall and blunt, as on the real car.
- **Profile points.** Two of the research's profile points (0.81 and 0.87, both within 11 mm of the line)
  are left out so the rear screen stays one glass plane.
- **Render.** `tools/render_models.py` shows a four-door notchback sedan with a long bonnet, the cabin
  set back and a short boot.

## Gaps

- **Unpublished values.** No turbo model, boost curve, converter stall, shift times, differential
  locking, spring, damper or roll-bar rates, centre of mass, lift or engine inertia are published. All
  are estimates, listed above.
- **Launch control.** Not modelled for automatics (see the shared-code observations), so the start is
  0.4-0.7 s slower than the published figures.
- **Power rating.** BMW's 375 kW rating looks conservative; the configuration keeps it.
- **Braking.** No European instrumented 100-0 km/h stop, and no verified top-speed run (only a search
  extract of 293 km/h).
- **Sound sources.** No freely licensed recording of a stock car: the only one is an aftermarket
  exhaust. The share of the cabin sound from Active Sound Design is an estimate, and overrun pops by
  drive mode are undocumented.
- **Firing order.** The BMW inline-six standard, not seen in an S58-specific document.
- **Body.** No pure side-profile photo; BMW's drawing was used.
- **Drive modes.** Comfort, Sport and Sport+ (shift speed, flaps, Active Sound Design level) are one
  setting here: Sport.

## What to measure in Studio

- **Telemetry overlay (T).** Compare 0-100 km/h, 0-200 km/h, the quarter mile and 100-0 km/h with the
  table above.
- **Static loads.** About 4,700 N on each front wheel and 4,150 N on each rear wheel at rest.
- **Top speed.** It should settle at about 287-290 km/h in 7th.
- **Limiter.** In manual mode, full throttle in 2nd should hold the limiter loop without dropping out.
- **Cockpit.** The cockpit camera should be noticeably richer in low engine orders than the chase camera.

## Sources

Full list with dates in `research_notes/cars/RefM3G80.md`.

- [BMW_PK] BMW Group PressClub, M3/M4 press kit (2020-09)
- [BMW_SPEC_M3] BMW Group PressClub, M3 / M3 Competition specifications
- [BMW_SPEC_M4] BMW Group PressClub, M4 Competition specifications (375 kW / 650 Nm full-load diagram)
- [BMW_US21] BMW of North America, 2021 M3 and M4 release with US specifications
- [BMW_ST1926] BMW technical training manual ST1926, S58 engine
- [CD_RWD] Car and Driver, "Tested: 2021 BMW M3 Competition" (2021-08-12)
- [MT_FT] MotorTrend, 2021 M3 first test (2021-04-20); [MT_COMP] MotorTrend comparison (2021-06-29)
- [AMS] auto motor und sport, M3 Competition test data (04/2021)
- [CITIZEN_SHEET] The Citizen (South Africa), road-test data sheet (2021-04-14); [CITIZEN_ART] article
- [EVO] evo, M3 Competition review (2021-06-18)
- [ARM_DYNO] ARM Motorsports, S58 stock dyno results
- [BMAG_LC] Bimmer Mag, BMW launch control (secondary source for the 2,700 rpm launch)
- [FIRING] BMW inline-six firing order, BMW training document ST501
- [DISC_PARTS] replacement-disc listings (380 × 36 and 370 × 24 mm)
- [MOTOR1_VMAX] Motor1, AutoTopNL top-speed run (search extract)
- [COMMONS_AUDIO] Wikimedia Commons, "BMW M3 (G80) Competition with Fi Exhaust" (FiExhaust, CC BY 3.0),
  used for measurement only

[BMW_PK]: https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf
[BMW_SPEC_M3]: https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf
[BMW_SPEC_M4]: https://newsroom.bmwgroup.com/emea/download/f92f5ad6-e9e9-4ac9-9191-0855eec11dfe/20260909073605409-124.pdf
[BMW_US21]: https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf
[BMW_ST1926]: https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf
[CD_RWD]: https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/
[MT_FT]: https://www.motortrend.com/cars/bmw/m3/2021/2021-bmw-m3-sedan-first-test-drive-review
[MT_COMP]: https://www.motortrend.com/reviews/2021-bmw-m3-competition-vs-alfa-romeo-giulia-quadrifoglio-comparison-test-review
[AMS]: https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/
[CITIZEN_SHEET]: https://media.citizen.co.za/wp-content/uploads/2021/04/M3data.pdf
[CITIZEN_ART]: https://citizen.co.za/motoring/bmw-m3-competition-lives-up-to-the-hype
[EVO]: https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon
[ARM_DYNO]: https://armmotorsports.com/blogs/news/s58-stock-dyno-results
[BMAG_LC]: https://www.bimmer-mag.com/?p=2655
[FIRING]: https://archive.org/download/BMWTechnicalTrainingDocuments/ST501%20New%20Engine%20Technology/02_Engine%20Diagnosis.pdf
[DISC_PARTS]: https://azcarparts.co.uk/products/for-bmw-m3-g80-g81-m4-g82-g83-competition-rear-left-right-brake-discs-pair-370mm
[MOTOR1_VMAX]: https://www.motor1.com/news/497131/g80-m3-competition-top-speed-run/
[COMMONS_AUDIO]: https://commons.wikimedia.org/wiki/File:BMW_M3_(G80)_Competition_with_Fi_Exhaust_-_engine_and_exhaust_sound_(YouTube_qv_a5bJeFPg).opus
