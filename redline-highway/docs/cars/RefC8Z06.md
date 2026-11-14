# Ridgeway Halcyon Z

*Internal ID `RefC8Z06`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/RefC8Z06.luau`.
Engine sound: `assets/audio/engines/RefC8Z06.json`. Research: `research_notes/cars/RefC8Z06.json` and `.md`.*

An original mid-engine coupe from Ridgeway, a fictional American brand. It is built to the published
engineering of the **Chevrolet Corvette Z06 coupe (C8, model year 2023 onward), the base car without the
Z07 package**, US specification. Real names appear only here, as engineering references; the game uses
no Chevrolet names, logos, body design or assets.

Tags used here and in the configuration:
- **[F]** GM / Chevrolet figure (sometimes read through a copy of GM's spec sheet)
- **[P]** published by a third party (spec site, Wikipedia, magazine spec box)
- **[M]** measured in a magazine or independent test
- **[E]** estimate made for the simulation (the method is given)
- **[A]** assumption

Source ids [S01]-[S35] are the research's; links are at the end.

## Published figures

| Item | Value | Tag | Source |
|---|---|---|---|
| Layout | Two-seat coupe with removable roof panel; 90° V8 mid-mounted ahead of the transaxle; rear-wheel drive; left-hand drive (right-hand drive built for export) | F | S02, S20 |
| Engine | LT6: 5.5 L (5,463 cc from 104.25 × 80.0 mm), naturally aspirated, DOHC 32 valves (finger followers, solid lifters), 12.5:1, direct injection to 350 bar, six-stage dry sump | F / P | S02, S06, S07 |
| Crank | Flat-plane (180°) forged steel, four-bolt mains, no balance shafts | P | S07 |
| Intake | Two 5.5 L moulded plenums, one 87 mm throttle body each, three "communicator" valves tuning the Helmholtz resonance | P | S08, S09 |
| Max power | 500 kW (670 hp SAE J1349) at 8,400 rpm. Export: 475 kW (646 PS) at 8,550 | F / P | S01, S02, S20-S22 |
| Max torque | 624 Nm (460 lb-ft) at 6,300 rpm | F | S01, S02 |
| Full-load curve | GM chart "US LT6 SAE Torque and Power", digitised: 395 Nm at 1,800 rpm, about 400-412 Nm to 3,000, a step to 571 Nm by 3,500, 601-608 Nm from 4,500 to 6,000, 618 Nm peak at 6,300, 547 Nm at 8,600. The chart reads about 1% under the ratings | F | S01 |
| Redline and limiter | 8,600 rpm; hard fuel cut at 8,600; full-throttle upshifts complete at about 8,500 | F / P | S02, S33, S19 |
| Launch control | Default 4,500 rpm, adjustable 3,500-5,000 rpm, with adjustable tyre slip | P | S23 |
| Firing order | 1-4-3-8-7-6-5-2 | P | S12, S06 |
| Cylinder numbering | GM convention: odd cylinders 1-3-5-7 on the left bank, even on the right, front to back (the engine's front faces the cabin in the C8) | A | S12 |
| Headers and exhaust | Stainless 4-2-1 headers per bank; valved active exhaust, four modes (Weather, Tour, Sport, Track: all valves open); four round centre tips in one bezel | F / P | S02, S07, S24, S29b |
| Gearbox | Tremec TR-9080 8-speed dual-clutch transaxle: 2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33; reverse 2.63; about 100 ms clutch overlap, no torque gap (Stingray unit) | F / P | S02, S04, S05, S10, S11 |
| Final drive | 5.56 (Stingray: 5.17 Z51, 4.89 base); about 1.566 transfer × 3.55 ring and pinion | F / E | S02, S04, S11 |
| Differential | Electronic limited-slip, standard | F | S02 |
| Weight | GM dry 1,558 kg (Z07 with carbon wheels, as copied by spec sites); C/D measured 1,663 kg (Z07 coupe) and 1,723 kg (convertible); no GM curb weight for the base coupe | P / M | S04, S05, S13 |
| Weight distribution | About 40% front / 60% rear (Stingray official 39.4/60.6) | P | S26, S05 |
| Length × width × height | 4,689 × 2,024 × 1,234 mm (4,722 mm long with the Z07 splitter) | P | S04, S05, S06 |
| Wheelbase; track front / rear | 2,723 mm; 1,684 / 1,679 mm | P | S02, S04 |
| Tyres and wheels | 275/30ZR20 on 20 × 10 front, 345/25ZR21 on 21 × 13 rear; Michelin Pilot Sport 4S ZP (base), Pilot Sport Cup 2 R ZP (Z07) | F / P | S02, S06, S16 |
| Brakes | Brembo iron 370 × 34 mm front (6-piston), 380 × 34 mm rear (4-piston); Z07 carbon-ceramic 398 × 38 / 390 × 34 mm | P | S04, S05, S06 |
| Downforce at 186 mph | 365 lb (1,624 N) base; 734 lb (3,265 N) Z07 | P / F | S19, S02 |
| Steering | Variable-ratio electric rack, 15.7:1; turning circle 11.6 m | P | S04, S06 |
| Factory performance | 0-60 mph 2.6 s with Z07; quarter mile 10.6 s (preliminary); top speed 195 mph (314 km/h) base, 189 mph (304 km/h) Z07; 1.22 g in track configuration | F | S02, S04, S17 |
| C/D, Z07 coupe (1-ft rollout) | 0-60 2.6 s; 0-100 mph 5.9 s; 0-150 mph 15.2 s; ¼ mile 10.5 s at 131 mph; rolling 5-60 3.1 s; 70-0 139 ft; 100-0 274 ft; skidpad 1.16 g; 94 dBA at full throttle | M | S13, S14 |
| C/D, convertible | 0-60 2.7 s; ¼ mile 10.7 s at 129 mph; 70-0 144 ft; 1.12 g; 96 dBA | M | S13, S14 |
| MT, Z07 coupe / PS4S convertible | 60-0 95 ft; 1.16 g / 1.10 g; the PS4S convertible was about 0.2 s quicker through the quarter | M | S16 |
| Wheel dyno, stock car | 600 whp at 8,340 rpm (other runs 597-611 whp): about 90% crank to wheel | M | S25 |

GM's own press pages refused automated reading (HTTP 403), so the GM figures come through Wikipedia and
spec-site copies of GM's sheet. The research notes the copy errors it found.

## How the game car is set up

Everything below is in the configuration with its tag. **Estimates and how they were made:**

| Item | Value | How |
|---|---|---|
| Kerb weight | 1,680 kg (US curb, no driver) [E] | C/D's measured Z07 coupe (1,663 kg), plus iron brakes, minus the Z07 aero, plus aluminium wheels (research, range 1,665-1,695) |
| Simulated mass | 1,755 kg | Kerb plus a 75 kg driver [A] |
| Centre of mass | 0.44 m high [E]; 1.634 m behind the front axle | Height for a low dry-sump mid-engine car; position from the 40/60 split |
| Static wheel loads | 3,443 N each front, 5,165 N each rear | For the HUD's wheel-load check in Studio |
| Rotational inertia | About 2,700 kg·m² in yaw [E] | 3.90 × 1.85 × 0.75 m mass box (research) |
| Torque curve | GM's chart × 1.006 [F] | The research's correction so the curve meets GM's ratings: 500 kW at 8,400 rpm, 622 Nm at 6,300. The chart's shape is kept, including the dip at 2,900, the step to 574 Nm by 3,500, the 3,800 peak and the 4,200 dip. 340 and 385 Nm at 1,000 and 1,500 rpm are below the chart [E] |
| Engine | Idle 900 rpm, limiter 8,600 [F], hysteresis 150 rpm, inertia 0.14 kg·m², friction 20 + 0.0085 × rpm Nm, throttle 18/s [E] | Research estimates; friction and throttle as the GT12 |
| Driveline efficiency | 0.90 [E] | The stock wheel dynos (S25) |
| Shift time | 0.10 s [P] | TR-9080 clutch overlap (S10) |
| Shift torque fraction | 0.70 [E] | The TR-9080 hands torque over with no gap, so the oncoming clutch keeps 658 Nm, above peak torque, and pulls the engine down to the new gear's speed. At the GT12's 0.35 the engine flares to about 8,740 rpm into the fuel cut on every full-throttle upshift, which also brings the limiter sound in for a moment |
| Clutch capacity | 940 Nm [E] | 1.5 × peak torque |
| Launch | Holds 4,500 rpm at full pedal [P], 2,000 at light pedal [E] | Launch control's default (S23) |
| Automatic shift points | Full throttle up at 8,500 [P]; light-pedal up 4,500, down 2,200 to 4,800 [E] | A Sport-mode calibration: lifting off holds the gear, braking downshifts one gear at a time. Up/down stays above 1.77, the largest gear step × 1.05, so it can't hunt |
| Differential | Preload 100 Nm, power lock 0.45, coast lock 0.30, stiffness 180 [E] | Clutch-type approximation of the eLSD (research) |
| Traction control | targetSlip 0.11, rate 15, recovery 2, headroom 1.3 [E] | The shared defaults. Not tuned while the shared engine-inertia fix is pending (see Validation) |
| Springs | 50,000 N/m front, 91,700 N/m rear [E] | 1.9 Hz front, 2.1 Hz rear (research, base magnetic-ride chassis), k = corner mass × (2πf)² |
| Dampers | 2,500 / 4,200 front, 4,200 / 6,900 rear N·s/m, bump / rebound [E] | Damping ratios 0.3 bump, 0.5 rebound |
| Anti-roll bars | 50,000 N/m front, 12,000 rear [E]; roll centres 0.05 / 0.08 m | 57% of the roll stiffness at the front, 52% of the lateral load transfer with the roll centres. With the tyre model's load sensitivity this gives a mildly understeering limit (front grip 0.8% short of the rear at 1.1 g); roll about 1.0° per g |
| Road tyre (PS4S class) | muLong 1.40 [E], muLat 1.14 [E], otherwise the shared Performance compound | muLong is the research's value. muLat gives about 1.11 g at the limit after load sensitivity and the understeer balance (tests: 1.10-1.12 g on PS4S) |
| Track tyre (Cup 2 R class, Z07) | muLong 1.50 [E], muLat 1.18 [E], on the SemiSlick compound | Research muLong; muLat for about 1.16 g (C/D and MT skidpads) |
| Tyre nominal loads | Road 4,100 N front, 5,150 N rear; track 4,300 / 5,380 N [E] | The shared compounds' values scaled by tread width (275 and 345 mm against 295 mm), so the wider rear tyre loses less grip to its heavier load |
| Wheel and tyre inertia | 1.5 front, 2.1 rear kg·m² [E] | Forged aluminium wheels (research) |
| Brakes | 3,000 Nm front, 2,000 Nm rear per wheel (61% front by force); handbrake 2,200 Nm; ABS target slip 0.12 [E] | Enough to lock all four wheels at about 1.4 g, so ABS sets the stop (research) |
| Drag area | CdA 0.895 m² [E] | Fitted with `tools/drivetrain_model.py` so the car settles at 195 mph in 6th (313.8 km/h, 6,760 rpm). Cd about 0.43 on an estimated 2.10 m² frontal area |
| Downforce | ClA 0.153 front + 0.230 rear = 0.383 m² | 365 lb at 186 mph [P] at the game's air density (1.225 kg/m³); 40/60 split [E], unpublished |
| Steering | 34° lock, 4.5° at 250 km/h, 220°/s, Ackermann 0.6 [E] | Lock from the 11.6 m turning circle (research: about 29° outside, 40° inside) |
| Body colour | RGB 208, 72, 22 [A] | An approximation of the launch colour Amplify Orange, kept redder than the AR-7's orange |

**Gear speeds in the game.** The game rolls each tyre on its unloaded radius (0.3365 m front, 0.3529 m
rear), not the research's loaded 0.345 m, so every gear is about 2.3% longer than the real car's:

| Gear | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Overall ratio | 16.18 | 9.79 | 6.78 | 4.89 | 3.61 | 2.84 | 2.22 | 1.84 |
| km/h at 8,600 rpm (game) | 71 | 117 | 169 | 234 | 317 | 404 | 515 | 624 |
| km/h at 8,600 rpm (real, 0.345 m) | 69 | 114 | 165 | 229 | 310 | 394 | 503 | 610 |

At 120 km/h, 4th runs at 4,410 rpm and 8th at 1,690 rpm.

**Stand-in body** (`visual.blockout`). It follows the research's side-photo proportions (S29a, ±3-5% of
length): nose 0.45 m, front axle at 0.205 of the length, windscreen base 0.27 (0.80 m), windscreen top 0.41
(1.20 m), roof peak 0.46 at the published 1.234 m, roof end 0.57 (1.19 m), buttresses down to a long deck
(1.00-1.07 m) and a 1.05 m ducktail lip; rear axle 0.785. The profile's highest point is 1.234 m; the
rendered roof plates overhang their ends by 1 cm and reach 1.2345 m.
- **Beltline.** The beltline is 0.64 m, not the real 0.81 m door line. The builder fills everything below
  the beltline with one full-length box, so at 0.81 m the nose was a 0.7 m wall that read as a muscle car.
- **Canopy.** It is 66% of the width, which leaves the wide shoulders.
- **Checked.** I rendered `tools/render_models.py` and looked at four views, then the lineup. It reads as
  a wide, cab-forward mid-engine car: low wedge nose, narrow canopy, high deck, square tail and the
  builder's centre quad tips.

## Validation

`python3 tools/drivetrain_model.py RefC8Z06` drives the game's own drivetrain code (a line-for-line copy) at
60 fps. The car is a point mass, so suspension, steering and Roblox's physics are tested in Studio.

**Status: run before the shared engine-inertia fix.** The coordinator reported that engine inertia is
counted twice while the clutch is closed, which slows acceleration. The drivetrain engineer is fixing it.
The acceleration rows below will change and must be re-run then; the top-speed fit is steady-state and the
braking rows are grip-limited.

Like-for-like comparisons:
- **Rollout.** US magazines time from a one-foot rollout. The tool and the game's HUD time from a true
  standstill, so the rollout figures below are computed from the same runs (the time from the first foot,
  and 1 ft to 1,321 ft for the quarter mile).
- **Car.** The magazine coupe figures are for the Z07 coupe. The base car has less grip but less drag, and
  MT's PS4S car was quicker through the quarter.

| Test | Published | Model (before the fix) | Difference |
|---|---|---|---|
| 0-60 mph, 1-ft rollout | 2.6 s [M] C/D Z07 coupe; GM 2.6 s with Z07 [F] | 3.00 s (3.48 s from a standstill) | +0.40 s |
| 0-100 mph, rollout | 5.9 s [M] | 6.33 s | +0.43 s |
| Quarter mile, rollout | 10.5 s at 131 mph [M] (GM preliminary 10.6 s [F]) | 10.88 s at 132.4 mph (11.37 s from a standstill) | +0.38 s, +1.4 mph |
| Rolling 5-60 mph | 3.1 s [M] | 3.07 s | -0.03 s |
| Top speed | 195 mph, 314 km/h [F] | 313.8 km/h (195.0 mph) in 6th at 6,760 rpm (313.4 km/h within the tool's 70 s) | -0.1% |
| 60-0 mph | 95 ft, 29.0 m [M] MT Z07; about 99 ft on PS4S (MT convertible, derived) | 27.2 m with an instant full pedal; 29.2 m with the game's keyboard brake ramp | -6%; +1% |
| 70-0 mph | 139 ft, 42.4 m [M] C/D Z07 | 36.2 m instant; 38.6 m with the ramp | -15%; -9% |
| 100-0 mph | 274 ft, 83.5 m [M] C/D Z07 | 72.0 m instant; 75.3 m with the ramp | -14%; -10% |
| 100-0 km/h (HUD) | not published | 28.7 m | |
| Skidpad | 1.10-1.12 g PS4S (convertibles), 1.16 g Z07 coupe [M] | About 1.11 g / 1.16 g by a steady-state calculation (not simulated) | Studio |
| Idle | | 842-890 rpm, steady (target 900) | |
| Free rev in neutral | | Limiter after 0.28 s; 8,430-8,930 rpm, 5 cuts/s | |
| Limiter in gear (2nd / 4th) | | 8,450-8,610 rpm, 3.9 / 3.0 cuts/s, gaps up to 0.27 / 0.33 s | |

**Acceleration (pending the fix).** Two things slow the launch at 60 fps.
- **Traction control hunting.** With the shared TC defaults it limit-cycles while the launch clutch
  slips: about 0.65 g for the first second. The result depends on frame rate: 0-60 with rollout was 3.47 s
  at 45 fps, 3.02 s at 60 fps and 2.64 s at 90-144 fps (measured with 1.45 grip).
- **The double-counted inertia.** It slows the locked-clutch phases, after the launch clutch closes.
- **Tried before the fix was reported, not kept.** These recorded settings reached 0-60 2.67 s, 0-100 mph
  6.00 s and quarter mile 10.58 s at 132.6 mph, all within 0.1 s of C/D:
  - targetSlip 0.15, rate 10, recovery 4, headroom 1.4, which varied under 0.07 s from 45 to 144 fps;
  - muLong 1.45.

  Per the coordinator, grip, inertia and traction control are not tuned to make up time until the fix
  lands. After it: re-run, then re-check the TC's frame-rate robustness on its own merits.
- **Launch rpm.** With the steady TC, 4,000 and 5,000 rpm were within 0.01 s of 4,500, so the published
  4,500 stays.

**Braking.**
- **The tool's test.** It applies the full pedal instantly, and the shared ABS holds the tyres at their
  peak almost perfectly.
- **The magazines.** They time from the moment the pedal is pressed, which includes the brakes building up.
- **The game's keyboard.** It ramps the brake to full in 0.17 s (6/s in `InputController`). With that ramp
  the model is within 1% of MT's 60-0.
- **C/D's stops.** They are relatively longer: 139 ft from 70 mph is 7% longer than MT's 95 ft from 60 mph
  scaled by speed squared, so no single grip value meets both. The GT12 shows the same pattern: 26.2 m,
  28.2 m ramped.
- **Grip value.** muLong stays at the research's 1.40 rather than being tuned down to match C/D.

**High speed.** C/D's Z07 took 15.2 s to 150 mph. The base car in the model takes 14.6 s with rollout,
before the fix. The Z07's extra drag and downforce, about 8% more CdA, cost time above 100 mph, so the
Z07's 0-150 isn't a target for the base car.

## Engine sound

**Definition** (`assets/audio/engines/RefC8Z06.json`, every value tagged in its `notes`):
- **Firing.** Firing order 1-4-3-8-7-6-5-2 on a flat-plane crank with GM's bank numbering. `--check`
  prints:
  - firing gaps 90° throughout;
  - bank sequence 1L 4R 3L 8R 7L 6R 5L 2R;
  - each bank 180-180-180-180.
- **Headers.** 4-2-1 per bank, modelled as four secondaries (1+7, 3+5, 2+8, 4+6, cylinders 360° apart);
  each gets an even 360-360 pulse train.
- **Exhaust.** Separate banks (no crossover, unpublished), two per bank of the centre tips at equal
  distance. Valves in Sport: shut at idle and light low-rpm load, open above 3,500 rpm or half throttle.
- **Intake.** Level 0.40 (default 0.25): the throttle bodies sit behind the seats. Plenum resonance 120 Hz,
  computed from one 5.5 L plenum and its 87 mm throttle-body neck. That matches the torque curve's
  3,500 rpm step.
- **Limiter.** Fuel cut at 8,600 rpm. Baked limiter loops bounce 12 times a second, 250 rpm deep, when
  free revving, and 8 times a second, 150 rpm deep, in gear.
- **Loudness.** C/D's 94 dBA at full throttle [M]; idle 58 dBA and cruise 72 dBA are estimates [E].

**Built** with `python3 tools/synth_audio.py --car RefC8Z06 --dev`:
- 10 engine speeds from 900 to 8,600 rpm, on and off throttle, plus two limiter loops: 28.9 s, 1.52 MB.
- Sheet `VehicleAudio/Sheets/RefC8Z06_Engine.luau`. It points at the dev pack until the coordinator packs
  `Engines_Pack1`.

**Measured.** I can't listen to audio; these are the checks, run on the decoded pack and on the
synthesizer.
- **Firing frequency and orders.** Each loop is a whole number of engine cycles, so the order bins are
  exact; the noise floor between bins was subtracted. Levels are energy relative to the firing orders
  (4, 8, 12, 16).
  - **The car as built**, heard on the centreline:
    - Order 4 sits at rpm ÷ 15: 60 Hz at idle, 573 Hz at 8,600.
    - Order 8 is between -16 and +12 dB of order 4 (pipe resonances move it).
    - Each bank's own rhythm (orders 2, 6, 10, 14) is 10-41 dB down, because the banks interleave 90°
      apart.
    - Odd orders (1, 3, 5, 7, 9) are 24-55 dB down; half orders (0.5 ... 7.5) are 19-35 dB down.
  - **Each bank alone** shows its inline-four pattern: even orders 2, 4, 6, 8 dominant. Its half orders
    are 18-28 dB down and its odd orders 19-30 dB down.
  - **Burble contrast.** The same engine and exhaust with a cross-plane crank (GM's 1-8-7-2-6-5-4-3, 4-1
    headers):
    - per bank, half orders are +2 to -13 dB;
    - heard 0.3 m off-centre, they are +1 to -0.2 dB at 3,000-8,600 rpm, against -18 to -30 dB for this
      flat-plane car.

    So no burble: the cross-plane signature is 20 dB or more stronger.
- **Levels.**
  - **Gains.** The sheet gains follow the loudness model exactly: 94 dBA at 8,600 rpm full throttle maps
    to -0.5 dB, and idle to full throttle spans 18 dB in game.
  - **Against the GT12.** On the preview's raw mixer output the Halcyon Z is 1.3 dB quieter at idle and
    0.8-1.0 dB louder at full throttle and on the limiter (expected 1.5 and 1.0).
  - **Within the drive preview.** Full throttle is +17.1 dB over idle and the limiter holds +15-16 dB;
    lift-off and braking are +9-12 dB.
- **Limiter loops.** Their amplitude envelopes repeat at exactly 12.0 Hz (free) and 8.0 Hz (in gear).
  They are 1.7-2.1 dB quieter than full-throttle loops at the same gain (the cut phases).
- **Loop seams.**
  - The worst jump at a loop point is 0.67 of the loop's 99th-percentile sample step (docs' normal range
    0.01-1.2).
  - The second difference at every seam is below the loop's own 99.5th percentile, so there are no clicks.
- **Spectrograms.** I viewed `assets/audio/preview/RefC8Z06_drive_preview_spectrogram.png`, and an
  order-tracked version with the simulated rpm overlaid.
  - The brightest line follows order 4 everywhere: idle, the free rev to the limiter, the launch's
    saw-tooth, the downshifts and the 2nd-gear limiter hold. The second line follows order 8 (1.15 kHz at
    the limiter).
  - Nothing follows order 2 or the half orders.
  - The limiter phases show the stutter as vertical bands.

**Previews.**
- `assets/audio/preview/RefC8Z06_drive_preview.mp3` (30 s): a free rev to the limiter held from 2 s, a
  launch from 6 s, and 2nd gear held on the limiter from 19 s.
- `RefC8Z06_tunnel_preview.mp3` (12 s).
- They were rendered with `--only drive` and `--only tunnel`, so the shared traffic preview is untouched.

**Mixer settings** (`audio` in the configuration):
- **Limiter hold.** 0.45 s, because in gear this car's fuel cut returns up to 0.33 s apart (4th gear).
- **Upshifts.** A short, soft dip (0.05 s, volume 0.15) instead of an ignition-cut crack: the dual-clutch
  has no torque gap.
- **Overrun.** A light crackle only (0.2): no source describes pops.
- **Road noise.** 0.4, for run-flat tyres.
- **Whine.** Tooth count 12.8: a 71/20 ring and pinion is assumed (unpublished), behind the 1.566 transfer
  gear.
- **Cockpit.** Engine at full level, mids kept, highs -7 dB: the engine sits right behind the seats and
  the tip bezels reflect sound into the cabin.

**Not verified, or simplified.**
- **How it sounds.** It needs a listen.
- **Calibration.** No freely licensed LT6 recording exists to calibrate against. The flat-plane analogues
  listed in `research_notes/cars/audio/RefC8Z06/LICENCES.txt` could not be downloaded.
- **Valves.** The progressive valves are modelled as Sport-mode open or shut per loop.
- **Downshifts.** The game rev-matches dual-clutch downshifts through the clutch, not with a throttle
  blip, so MT's "whumm, whumm" blips are a rising note on the overrun loops.

## Z07 package variant

C/D's and MT's coupe tests were of Z07 cars, so the performance targets apply to it directly. To make the
variant, copy the configuration and change:

| Field | Base (this file) | Z07 | Tag, how |
|---|---|---|---|
| `tires.front.compound`, `tires.rear.compound` | RoadPerformance, RoadPerformanceRear | TrackTyre, TrackTyreRear (already defined) | [F] Cup 2 R ZP tyres; [E] grip |
| `aero.downforceAreaFront`, `downforceAreaRear` | 0.153, 0.230 | 0.308, 0.463 | [F] 734 lb at 186 mph = ClA 0.771 m² at game density; 40/60 [E] |
| `aero.dragArea` | 0.895 | about 0.98 | [E] fitted: settles at 304.8 km/h (189.4 mph) in 6th; GM: 189 mph [F]. It touches 310 km/h in 5th before the 8,500 rpm upshift |
| `mass.kerbKg` | 1,680 | 1,663 | [M] C/D's Z07 coupe |
| `dimensions.length` | 4.689 | 4.722 | [P] with the Z07 splitter |
| `brakes.discs` | iron 370 / 380 mm | carbon-ceramic 398 × 38 / 390 × 34 mm | [P]; torques unchanged: both lock the wheels in a single stop |
| Springs, FE7 chassis | 1.9 / 2.1 Hz | 2.2 / 2.4 Hz: 67,000 and 120,000 N/m; dampers 2,900 / 4,850 front, 4,770 / 7,950 rear | [E] research ride frequencies, same method |
| Wheel inertia | 1.5 / 2.1 | 1.35 / 1.9 with carbon wheels | [E] about 10% less (41 lb lighter in total, S02) |
| `performanceTargets.topSpeedKmh` | 314 | 304 | [F] 189 mph |

Expect the variant to brake about 4% shorter (MT: 95 ft against about 99 ft on PS4S). It should also
corner at about 1.16 g, and lose a little top-end acceleration to drag.

## Gaps

1. **Acceleration validation awaits the shared engine-inertia fix** (see Validation).
2. **Braking runs short of the magazines with an instant pedal** (-6% to -15%). The tool's test and the
   shared ABS are idealised; with the game's keyboard brake ramp the gap to MT closes, but C/D's stops
   stay 9-10% longer.
3. **No GM curb weight for the base coupe.** The 1,680 kg is estimated from C/D's Z07 (±15 kg).
4. **Unpublished: Cd, frontal area and the downforce split.** CdA is fitted to the top speed and the split
   is set at 40/60.
5. **Unpublished: idle rpm, launch rpm at light pedal, exhaust details and DCT shift time.**
   - exhaust: header pairing and lengths, crossover, catalysts, mufflers;
   - the Z06's own dual-clutch shift time;
   - ring-and-pinion teeth;
   - the limiter's bounce character.

   All are estimates, tagged in the files.
6. **No LT6 recording to calibrate the synthesis against.** Interior idle and cruise levels are estimates;
   only C/D's full-throttle 94 dBA is measured.
7. **Not testable here: suspension, handling balance and the skidpad.** They need Studio. The
   understeering balance comes from a steady-state calculation of load transfer and load sensitivity.
8. **Shared limitations that affect this car.**
   - Unloaded tyre radius as rolling radius: about 2.3% long gearing.
   - The fuel cut acts through the throttle lag, so a free rev overshoots to about 8,930 rpm before
     falling back (the GT12 does the same).
   - Dual-clutch downshifts have no throttle blip.
   - The stand-in body can't show the side intakes, the haunches or the Z07 wing.

## What to measure in Studio

- **Timer.** The telemetry overlay (T) times 0-60 mph, the quarter mile and 100-0 km/h from a standstill:
  - expect about 0.45 s more than the rollout figures above;
  - re-check after the inertia fix.
- **Top speed.** It should settle near 314 km/h in 6th on a long straight.
- **Wheel loads at rest.** About 3,440 N on each front wheel and 5,170 N on each rear.
- **Steady cornering.** About 1.1 g, with the front washing out first.
- **Limiter.** In manual (E to upshift, hold W in 2nd), the limiter sound should hold steadily, not
  flicker.
- **Sound.** Not playable in game until the coordinator builds and uploads `Engines_Pack1`. Listen to
  `assets/audio/preview/RefC8Z06_drive_preview.mp3` meanwhile.

## Sources

- [S01] GM "US LT6 SAE Torque and Power" chart, via Corvette Blogger: https://www.corvetteblogger.com/2022/02/18/pic-first-look-at-the-torque-and-power-of-the-2023-corvette-z06s-lt6-v8-engine/
- [S02] Wikipedia, Chevrolet Corvette (C8), citing GM's 2021-10-26 release: https://en.wikipedia.org/wiki/Chevrolet_Corvette_(C8)
- [S04] Corvsport, 2023 Z06 specifications: https://www.corvsport.com/2023-corvette-z06-specifications/
- [S05] Corvettestory, 2024 specs: https://corvettestory.com/specs/2024-Corvette-specs-options.php
- [S06] Corvsport, 2025 Z06 guide: https://www.corvsport.com/2025-corvette-z06-in-depth-guide/
- [S07] The Drive, LT6 deep dive: https://www.thedrive.com/news/42901/2023-corvette-z06s-lt6-v8-everything-you-ever-wanted-to-know
- [S08] LSX Magazine, intake manifold: https://www.lsxmag.com/?p=25093
- [S09] Motor1, LT6 intake: https://www.motor1.com/news/566963/chevy-corvette-z06-dohc-intake/
- [S10] SAE Mobility Engineering, Tremec DCT: https://www.mobilityengineeringtech.com/component/content/article/40895-sae-ma-00017
- [S11] TR-9080 overview: https://www.autoevolution.com/news/a-look-at-the-corvette-c8-s-tremec-tr-9080-dct-transmission-and-how-it-works-152380.html
- [S12] Firing order: https://rerev.com/firing-orders/chevrolet/5-5l-lt6/ and https://www.aa1car.com/library/chevy_firing_orders.htm
- [S13] Car and Driver test data (forum repost): https://canadiancorvetteforums.com/threads/car-and-driver-review-of-the-c8-z06-october-26-2022-best-corvette-ever.60646/latest (original https://www.caranddriver.com/reviews/a41411338/2023-chevrolet-corvette-z06-by-the-numbers/)
- [S14] Car and Driver Z06 test (Yahoo): https://autos.yahoo.com/tested-2023-corvette-z06-american-040000360.html
- [S15] Car and Driver Z06 convertible test: https://autos.yahoo.com/tested-2023-chevrolet-corvette-z06-110000549.html
- [S16] Motor Trend first test (Tremec repost): https://tremec.com/?p=261
- [S17] Motor Authority, top speed: https://www.motorauthority.com/news/1137037_2023-chevrolet-corvette-z06-top-speed
- [S19] Motor Authority review: https://www.motorauthority.com/news/1137351_review-2023-chevrolet-corvette-z06-heaps-exotic-sound-and-fury-on-an-exotic-design
- [S20] Japanese catalogue: https://221616.com/catalog/chevrolet/chevroletcorvette/202001_299912/10155730/
- [S22] Driven NZ review: https://www.drivencarguide.co.nz/reviews/chevrolet-corvette-z06-review-flat-chat/
- [S23] Corvette Blogger, launch control: https://www.corvetteblogger.com/2022/04/29/video-2023-corvette-z06-allows-drivers-to-customize-launch-control-rpm
- [S24] Motor1, exhaust: https://www.motor1.com/news/593811/2023-corvette-z06-exhaust-note-video/
- [S25] Hennessey dyno: https://www.motor1.com/news/692511/chevrolet-corvette-z06-dyno-results-hennessey/
- [S26] Weight split: https://www.corvette-mag.com/issues/174/articles/driven-2024-z06
- [S27] Popular Science review: https://www.popsci.com/technology/chevrolet-corvette-z06-review/
- [S29a, S29b] Wikimedia Commons photos: https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Z06_C8,_white,_Golden_Super_Cruise_2026-07-04.jpg (CC BY-SA 4.0, Xnatedawgx) and https://commons.wikimedia.org/wiki/File:Corvette_Z06_(52695148134).jpg (CC BY 2.0, John Bauld)
- [S33] Corvette Blogger, reveal teaser: https://www.corvetteblogger.com/2021/10/20/video-chevy-teases-the-2023-corvette-z06-reveal-tune-in/

Several pages (S11, S14, S17-S19, S21, S23, S26, S27) were read by the research through search summaries
because they blocked automated reading; check them before quoting exact wording.
