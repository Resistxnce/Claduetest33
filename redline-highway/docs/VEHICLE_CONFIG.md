# Vehicle configuration reference

Every car in Redline Highway is one data file in
`src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/<Id>.luau`. The shared simulation reads
it; there is no per-car code. This page lists every field, so a car can be built without reading the
simulation. `Prototype812.luau` (the Valenza GT12, see `PROTOTYPE_GT12.md`) is the worked example.

- **Units:** metres, kilograms, newtons, seconds and rpm, unless a field's name says otherwise
  (`Kmh`, `Mm`, `Inches`, `Bar`, `Deg`).
- **Axes:** X to the right, Y up, -Z forward.
- **Tags:** tag every value in a comment.
  - `[F]` manufacturer figure
  - `[P]` published third-party figure
  - `[M]` measured in a magazine or independent test
  - `[E]` estimate made for the simulation
  - `[A]` assumption
- **Branding:** in-game names are fictional (`displayName`). Real car names go only in `reference`
  and the docs.
- **Checking a file:** `python3 tools/drivetrain_model.py <Id>` checks the file for missing or
  implausible fields, then drives the car (see "Checking a configuration" below).
  `--all` runs every configuration.

"Required" below means the game or the server errors without it. "Optional" fields have the
default shown. Fields marked "info" are for people and are not read by any script.

## Top level

| Field | Required | Meaning |
|---|---|---|
| `id` | yes | Internal id. Must equal the file name. The server stores it in the model's `VehicleConfig` attribute, and the client loads the config by it. |
| `displayName` | yes | Fictional in-game name, shown in the HUD. |
| `reference` | info | The real car the engineering comes from, e.g. `"BMW M3 Competition (G80), engineering reference only"`. |
| `mass`, `dimensions`, `engine`, `transmission`, `drivetrain`, `suspension`, `tires`, `brakes`, `aero`, `steering`, `visual` | yes | Sections below. |
| `performanceTargets` | optional | Published figures to compare against, below. |
| `audio` | optional | Sound set-up, owned by the audio system (see `docs/AUDIO.md`). Without it the car is silent. |

## mass

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `dryKg` | kg | info | | Dry weight, for reference. |
| `kerbKg` | kg | yes | 1,400-2,000 | Kerb weight without driver. Use the DIN or US curb figure and say which. |
| `driverKg` | kg | yes | 75 | Added to `kerbKg`. The simulated mass is `kerbKg + driverKg`. |
| `frontShare` | 0-1 | yes | 0.40-0.55 | Share of the weight on the front axle. It also places the centre of mass along the wheelbase. |
| `comHeight` | m | yes | 0.40-0.55 | Centre of mass above the ground at ride height. Sets load transfer. |
| `inertiaBox` | m | yes | 1.8 × 0.8 × 4.0 | `{ width, height, length }` of the invisible box that carries the mass. It sets rotational inertia (yaw inertia is about mass × (width² + length²) / 12). |

## dimensions

| Field | Unit | Required | Meaning |
|---|---|---|---|
| `length`, `width`, `height` | m | yes | Body size (the stand-in body and the close-pass scoring use these). |
| `wheelbase` | m | yes | Front to rear axle. |
| `trackFront`, `trackRear` | m | yes | Wheel centre to wheel centre, per axle. |
| `frontOverhang` | m | yes | Front axle to the nose. |

## engine

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `layout`, `displacementCc`, `aspiration`, `peakPowerKw`, `peakPowerRpm`, `peakTorqueNm`, `peakTorqueRpm` | | info | | Published figures, for reference. The simulation uses `torqueCurve`. |
| `idleRpm` | rpm | yes | 600-1,000 | Idle speed held by the idle controller. |
| `limiterRpm` | rpm | yes | 6,500-9,000 | Fuel-cut rev limiter: the cut starts here. |
| `limiterHysteresisRpm` | rpm | yes | 100-200 | Fuel returns this far below the limiter. With `inertia` and `throttleResponse` it sets the bounce: the GT12 swings 8,750-9,200 rpm in neutral, about 4 cuts a second. |
| `inertia` | kg·m² | yes | 0.12-0.30 | Crank, flywheel and clutch or converter housing. Lower revs up faster. |
| `torqueCurve` | {rpm, Nm} | yes | | Full-throttle crank torque, net, rising rpm, 6-15 points up to `limiterRpm`. Below the first point torque falls linearly to zero at 0 rpm; past the last it stays flat. **With forced induction this is the full-boost curve** (see "Turbo and supercharger torque curves"). |
| `friction` | | yes | `{ static = 20, perRpm = 0.0085 }` | Engine braking with the throttle shut: `static + perRpm × rpm` (Nm). The curve is net output, so friction isn't taken off at full throttle. |
| `throttleResponse` | 1/s | yes | 12-20 | How fast the throttle follows the pedal (first-order). |
| `speedLimitKmh` | km/h | optional, none | 250, 290, 305 | Electronic top-speed limiter. It closes the throttle over the last 3 km/h before this speed. Leave it out for cars that aren't limited. |
| `forcedInduction` | table | optional, none | | Turbo or supercharger, below. Leave it out for a naturally aspirated engine. |

### engine.forcedInduction

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `type` | | yes | `"Turbo"` / `"Supercharger"` | Turbo: boost builds with lag. Supercharger (positive displacement): boost follows rpm and throttle instantly. |
| `maxBoostBar` | bar gauge | yes | turbo 1.0-2.0, supercharger 0.5-1.0 | Boost at full boost. Only the gauge and the audio use it (`t.boostBar`); torque comes from the curve and the shares. |
| `offBoostTorqueShare` | 0-1 | yes | 0.35-0.55 turbo, 0.55-0.70 supercharger | Share of the full-boost curve the engine makes with no boost. Best fitted from the factory curve at about 1,000 rpm (S58: 245 of 650 Nm, about 0.38). Otherwise start from 1 / (1 + maxBoostBar). |
| `boostStartRpm` | rpm | yes | 1,000-2,000 | At full throttle, boost begins to build above this speed. |
| `fullBoostRpm` | rpm | yes | 1,800-5,000 | At full throttle, full boost is available from here (usually where the factory curve reaches its plateau). The boost ceiling rises linearly between the two. |
| `spoolTime` | s | turbo | 0.5-1.2 | Seconds from no boost to 90% boost when floored at `fullBoostRpm` in a steady gear. Spool rate scales with rpm (half the rpm, twice the time) and with engine load. |
| `dumpTime` | s | turbo | 0.15-0.3 | Seconds for boost to fall to 10% when the throttle shuts or the request drops (blow-off). |

How it works: the throttle is a torque request. Up to `offBoostTorqueShare` the engine needs no boost.
Above it, boost is asked for: target boost = (throttle - share) / (1 - share) × ceiling(rpm). Delivered
torque is curve(rpm) × min(throttle, share + (1 - share) × boost). Telemetry:
- `t.boost`: 0-1, the spooled boost; it lags on spool-up and dumps on lift.
- `t.boostBar`: gauge pressure. It is negative under manifold vacuum at part throttle (down to about -0.75 bar).
- `t.forcedInduction`: `"Turbo"`, `"Supercharger"` or nil.

## transmission

Gear numbers: -1 reverse, 0 neutral, 1 and up forward (1 to 10 gears).

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `type` | | yes | `"DualClutch"` / `"Automatic"` | Gearbox model, below. |
| `gearRatios` | | yes | | Forward ratios, falling gear to gear, 1 to 10 entries. |
| `reverseRatio` | | yes | 2.6-4.9 | |
| `finalDrive` | | yes | 2.8-5.6 | Final drive (include any transfer gear in it). Overall ratio = gear × final drive. |
| `efficiency` | 0-1 | yes | 0.88-0.93 | Share of torque reaching the wheels. |
| `shiftTime` | s | yes | DCT 0.05-0.10, automatic 0.12-0.30 | DCT: time at reduced clutch capacity. Automatic: planned length of an upshift's speed change. |
| `minShiftInterval` | s | yes | 0.25-0.35 | Shortest time between two shifts. |
| `autoUpshiftRpm` | rpm | yes | `{ light, full }` | In auto mode, upshift above this gearbox-input speed. Interpolated by pedal from `light` (0%) to `full` (100%). Keep `full` 50-200 rpm under `limiterRpm`. |
| `autoDownshiftRpm` | rpm | yes | `{ light, full }` | Downshift below this, by pedal. |

### Dual-clutch only (`type = "DualClutch"`)

| Field | Unit | Typical | Meaning |
|---|---|---|---|
| `shiftTorqueFraction` | 0-1 | 0.3-0.4 | Share of clutch capacity kept during a shift. |
| `clutchMaxTorque` | Nm | 1.4-1.6 × peak torque | Clutch capacity. |
| `clutchStiffness` | Nm per rad/s | 400 | How firmly an engaged clutch couples. |
| `launchRpm` | rpm | `{ min = 2200, max = 4500 }` | Engine speed the launch clutch holds when pulling away, by pedal. |

The DCT's automatic mode shifts one gear at a time and won't drop into a gear above
`autoUpshiftRpm.full - 400`. It can shift back and forth if `up / down` at some pedal is below the
largest ratio step; the check warns about that.

### Torque-converter automatic only (`type = "Automatic"`)

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `shiftTorqueReduction` | 0-1 | yes | 0.3-0.5 | Share of engine torque cut (ignition retard) during a power-on upshift. About 0.4 keeps wheel torque nearly flat through the shift. |
| `downshiftTime` | s | optional, = `shiftTime` | 0.15-0.30 | Planned length of a downshift. |
| `downshiftBlip` | 0-1 | optional, 0 | 0.25-0.4 | Throttle opened during a downshift to match revs, while the engine is below the new gear's speed. |
| `turbineInertia` | kg·m² | optional, 0.05 | 0.03-0.08 | Converter turbine and gearbox input. |
| `converter.stallRpm` | rpm | yes | 2,000-2,800 | Engine speed at which the converter, with the car held still, absorbs the engine's steady full-throttle torque (a "brake stall" test). It sets the converter's capacity. Higher is looser: more flare at launch, less creep. |
| `converter.torqueRatio` | | yes | 1.7-2.2 | Torque multiplication at stall. |
| `converter.couplingPoint` | 0-1 | yes | 0.85-0.90 | Turbine/engine speed ratio where multiplication ends. Above it the converter is a fluid coupling. |
| `converter.overrunCapacity` | 0-1 | optional, 0.6 | 0.5-0.7 | Converter strength when the wheels drive the engine (engine braking, lock-up open). |
| `lockup.minGear` | | yes | 1-2 | Lowest gear the lock-up clutch closes in. |
| `lockup.minSpeedKmh` | km/h | yes | 8-25 | It closes above this speed and opens 3 km/h below it. |
| `lockup.engageTime` | s | yes | 0.3-0.6 | Time to close fully. It opens four times faster. |
| `lockup.maxTorque` | Nm | yes | 1.3-1.6 × peak torque | Lock-up capacity. Below the engine's torque it slips at full throttle. |
| `lockup.stiffness` | Nm per rad/s | optional, 400 | 400 | As `clutchStiffness`. |

How the automatic behaves:
- **Park.** An automatic spawns in park (gear 0, the brakes holding the car, HUD shows "P"). The first pedal press selects drive.
- **Creep.** Off the brake, the converter creeps the car at 5-7 km/h. Holding the brake at a standstill pulls the idle down 30-60 rpm.
- **Launch.** At full throttle the converter lets the engine flare toward its stall speed and multiplies torque. Holding the brake first works like launch control: the engine runs up as far as traction control lets the tyres take.
- **Lock-up.** The lock-up clutch then closes, per `lockup`.
- **Shifts.** The converter turbine (gearbox input) is released from the wheels. The shift clutches carry it from the old gear's speed to the new one's in `shiftTime`, while `shiftTorqueReduction` trims the engine. Downshifts blip the throttle by `downshiftBlip`.
- **Shift choice.** The auto mode upshifts one gear past `autoUpshiftRpm`. Below `autoDownshiftRpm` it kicks down, skipping gears if needed, to the highest gear that lifts the engine clear of the downshift point. It never picks a gear within 250 rpm of the upshift point, so it can't hunt, whatever the number and spacing of the gears.
- **Telemetry.**
  - `t.clutch` is the lock-up engagement.
  - `t.lockup` and `t.converterSlip` (1 - turbine/engine) are set for automatics.
  - `t.transmissionType` is the gearbox type.

## drivetrain

| Field | Required | Typical | Meaning |
|---|---|---|---|
| `layout` | yes | `"RWD"`, `"FWD"`, `"AWD"` | Driven axles. |
| `frontTorqueShare` | AWD without a coupling | 0-1 | Fixed front share (a plain torque split). Ignored for RWD and FWD, and when `centreCoupling` is set. |
| `centreCoupling` | optional, AWD | | On-demand coupling, below. |
| `rearDifferential`, `frontDifferential` | yes | | `{ type = "Open" }`, `{ type = "Locked" }`, or `{ type = "LimitedSlip", preload, powerLock, coastLock, stiffness }`. The undriven axle's entry is ignored. |
| `tractionControl` | optional, off | `{ enabled = true, targetSlip = 0.11, rate = 15, recovery = 2, headroom = 1.3 }` | Caps engine (and clutch) torque at `headroom` × what the driven tyres can take, then trims while they slip past `targetSlip`. `rate` and `recovery` are how fast the trim builds and fades (1/s). V toggles it in game. |

Limited-slip fields:
- `preload`: Nm of locking with no drive torque.
- `powerLock` and `coastLock`: extra locking as a share of input torque, on and off power (0-1; typically 0.25-0.5 and 0.1-0.3).
- `stiffness`: Nm per rad/s of left-right speed difference, typically 150-250.

### drivetrain.centreCoupling (rear-biased on-demand all-wheel drive)

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `baseFrontShare` | 0-1 | yes | 0-0.2 | Share of drive torque that always goes forward. It also weights the gearbox speed between the axles. |
| `maxFrontShare` | 0-1 | yes | 0.35-0.5 | Most the coupling can send forward when the rear slips. |
| `slipThreshold` | share of road speed | yes | 0.02-0.05 | Rear-over-front tyre slip the coupling allows before it sends more forward. |
| `stiffness` | Nm per m/s | yes | 1,500-3,000 | Extra forward torque per m/s of slip past the threshold. The transfer is also capped so it can't reverse the axles' speed difference in one step. |
| `preload` | Nm | optional, 0 | 0-200 | Transfer allowed with no drive torque. |

The coupling compares the axles at the tyre surface (omega × radius), so different front and rear tyre
sizes don't count as slip. If the front turns faster than the rear, it takes torque back, but never more
than the base share plus preload. `t.frontTorqueShare` is the share actually sent forward. A drive-mode
switch (BMW's 4WD, 4WD Sport, 2WD) is one configuration per mode, or a future tuning option.

## suspension

`front` and `rear`, each required, with these fields:

| Field | Unit | Typical | Meaning |
|---|---|---|---|
| `springRate` | N/m | 40,000-90,000 | At the wheel. From a ride frequency f: k = corner mass × (2πf)². GT cars use 1.6-2.2 Hz. |
| `bumpDamping`, `reboundDamping` | N·s/m | 2,500-6,000 | Damping ratios of about 0.3 in bump and 0.5 in rebound: c = ratio × 2√(k × corner mass). |
| `staticLength` | m | 0.25 | Mount to wheel centre at ride height. |
| `bumpTravel`, `droopTravel` | m | 0.06-0.10 | Travel from ride height. |
| `bumpStopRate` | N/m | 250,000 | Past full bump. |
| `antiRollRate` | N/m | 15,000-40,000 | Per metre of left-right travel difference. A stiffer front gives more understeer. |
| `rollCenterHeight` | m | 0.03-0.12 | Lateral tyre force acts this high above the road. |
| `rideHeightOffset` | m | 0 | Positive raises the car. |

## tires

`front` and `rear` (required):

| Field | Unit | Meaning |
|---|---|---|
| `widthMm`, `aspect`, `rimInches` | | Size, e.g. 285/30 R20. The radius comes from it. |
| `compound` | | A compound name: one of `Compounds.luau` (`Street`, `Sport`, `Performance`, `SemiSlick`) or one of the car's own `compounds`. An unknown name warns and falls back to `Performance`. |
| `inertia` | kg·m² | Wheel and tyre, typically 1.4-2.2. |

`compounds` (optional) defines the car's own tyres, so `Compounds.luau` needn't change. Each entry names
its `base` (default `"Performance"`) and lists only the values that differ:

```lua
tires = {
	compounds = {
		-- [E] road tyre in the Michelin Pilot Sport 4S class (engineering reference only)
		RoadPerformance = { base = "Performance", muLong = 1.42, muLat = 1.20 },
		-- [E] track tyre in the Pilot Sport Cup 2 class
		TrackTyre = { base = "SemiSlick", muLong = 1.58, muLat = 1.34, rollingResistance = 0.012 },
	},
	front = { widthMm = 275, aspect = 35, rimInches = 19, compound = "RoadPerformance", inertia = 1.6 },
	rear = { widthMm = 285, aspect = 30, rimInches = 20, compound = "RoadPerformance", inertia = 1.9 },
},
```

Compound values (all estimates; the existing compounds are the reference points):

| Value | Performance | SemiSlick | Meaning |
|---|---|---|---|
| `muLong` / `muLat` | 1.45 / 1.22 | 1.62 / 1.38 | Peak friction at the nominal load (braking/driving, cornering). |
| `peakSlipRatio` | 0.10 | 0.09 | Slip ratio of the braking/driving peak. |
| `peakSlipAngle` | 7.5 | 6.5 | Degrees, cornering peak. |
| `shapeLong` / `shapeLat` | 1.35 / 1.45 | 1.40 / 1.55 | Magic-formula C; sliding grip settles at sin(C·π/2) of the peak. |
| `loadSensitivity` | 0.08 | 0.07 | Grip lost per 100% extra load. |
| `nominalLoad` | 4,400 | 4,600 | N, where mu applies as written. |
| `relaxationLength` | 0.25 | 0.20 | m of travel for slip angle to build. |
| `rollingResistance` | 0.012 | 0.011 | |

## brakes

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `discs` | | info | | e.g. `"Carbon-ceramic, 398 mm front, 360 mm rear"`. |
| `maxTorqueFront`, `maxTorqueRear` | Nm per wheel | yes | 2,500-4,500 / 1,500-2,500 | Full-pedal torque. Their ratio sets the bias (about 60-68% front). Make it enough to lock the wheels; ABS then holds peak slip. |
| `handbrakeTorque` | Nm per rear wheel | yes | 2,000-2,500 | |
| `abs` | | yes | `{ enabled = true, targetSlip = 0.12 }` | ABS releases pressure past `targetSlip`. B toggles it. |

## aero

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `dragArea` | m² | yes | 0.65-1.0 | CdA = Cd × frontal area. Fit it to the top speed when the top speed is drag-limited. |
| `downforceAreaFront`, `downforceAreaRear` | m² | yes | 0-0.4 | ClA per axle. Downforce = ½ρ·ClA·v². |

## steering

| Field | Unit | Required | Typical | Meaning |
|---|---|---|---|---|
| `maxAngleLowSpeed` | deg | yes | 30 | Road-wheel angle when slow. |
| `maxAngleHighSpeed` | deg | yes | 4-6 | At `highSpeedKmh` and above. |
| `highSpeedKmh` | km/h | yes | 250 | |
| `rate` | deg/s | yes | 200-250 | How fast the road wheels turn. |
| `ackermann` | 0-1 | yes | 0.6 | 0 parallel, 1 full Ackermann. |

## performanceTargets

Published figures, compared by the HUD's telemetry overlay (T) and by `tools/drivetrain_model.py`.
Every field is optional, and so is the table. Give the source tag and say whether a figure uses a
one-foot rollout (US magazines do; that makes it about 0.1-0.3 s quicker than a true start).

| Field | Unit | Meaning |
|---|---|---|
| `zeroTo60Mph` | s | From a true standstill. |
| `zeroTo60MphRollout` | s | With a one-foot rollout, as US magazines publish. |
| `zeroTo100` | s | 0-100 km/h. |
| `zeroTo100Mph` | s | |
| `zeroTo200` | s | 0-200 km/h. |
| `quarterMile`, `quarterMileKmh` | s, km/h | Time and speed at the line. |
| `topSpeedKmh` | km/h | |
| `brake100To0` | m | 100-0 km/h. |
| `brake60MphTo0`, `brake70MphTo0` | m | Convert feet to metres (× 0.3048). |

## visual

| Field | Required | Meaning |
|---|---|---|
| `bodyColor` | yes | `Color3.fromRGB(...)` for the stand-in body. |
| `driverSide` | yes | `"Left"` or `"Right"`. |
| `blockout` | optional | Side profile of the stand-in body (VehicleModelBuilder; without it, a long-bonnet GT shape). |

`blockout` fields:
- `profile`: `{ {share of length from the nose, top height m}, ... }`
- `greenhouse`: `{ from, to }` shares where the cabin glass is
- `beltline`: m, the window line
- `cabinWidth`: share of `width`
- `sill`: m, default 0.14

## Turbo and supercharger torque curves

The simulation needs the **full-boost** curve. Steady full-throttle torque at an rpm is then
curve(rpm) × (share + (1 - share) × ceiling(rpm)), with the ceiling rising linearly from
`boostStartRpm` to `fullBoostRpm`. To build it from a factory full-load curve:

1. From the rpm where the factory curve reaches full torque, copy it as it is.
2. Below that, use the full-boost torque, usually the plateau value, down to the first point. For the
   S58 that is 650 Nm from 1,000 to 5,500 rpm.
3. Set `offBoostTorqueShare` to the factory torque at about 1,000 rpm divided by the curve there
   (S58: 245 / 650 = 0.38).
4. Set `boostStartRpm` where the factory curve starts to climb and `fullBoostRpm` where it plateaus.
5. Run `python3 tools/drivetrain_model.py <Id> --curve` and compare the steady curve with the factory
   one. To match a point R exactly, set the full-boost curve there to
   factory(R) / (share + (1 - share) × ceiling(R)).

## Setting the new fields for the six cars

Starting values. Facts are from `research_notes/cars/<Id>.json` with their tags there. Everything marked
[E] is a simulation estimate to be tuned with the tool. The gear ratios, curves and masses are in the
research notes.

| Car (research id) | Engine fields | Gearbox fields | Drive and tyres |
|---|---|---|---|
| M3 Competition G80 (RefM3G80) | Turbo: `maxBoostBar` 1.7 [P]. Full-boost curve 650 Nm plateau [F] from 1,000 rpm. `offBoostTorqueShare` ≈ 0.38 (245/650 Nm [F]). `boostStartRpm` ≈ 1,500 [E], `fullBoostRpm` 2,750 [F]. `spoolTime` 0.6-0.8, `dumpTime` 0.2 [E]. `speedLimitKmh` 250 [F] (290 with the M Driver's Package [F]). | Automatic: 8 ratios 5.000-0.640, final 3.154 [F]. BMW: the lock-up is "fully engaged the moment the car has pulled away" [F], so `lockup.minGear` 1, `minSpeedKmh` about 10 [E]. `stallRpm` about 2,300, `torqueRatio` 1.9, `couplingPoint` 0.87 [E]. `shiftTime` 0.15-0.2, `shiftTorqueReduction` 0.4, `downshiftBlip` 0.3 [E]. | RWD, rear LSD. Tyres 275/35 R19 and 285/30 R20 [F]. A road compound in the Pilot Sport 4S class, and optionally a Cup 2-class one [E]. |
| M5 Competition F90 (RefM5F90) | Turbo: `maxBoostBar` ≈ 1.75 [E] (base M5 24.5 psi [F]). 750 Nm plateau [F]. `offBoostTorqueShare` ≈ 0.53 (400/750 at 1,000 rpm [F]). `boostStartRpm` ≈ 1,100 [E], `fullBoostRpm` 1,800 [F]. `spoolTime` 0.7 [E]. `speedLimitKmh` 250 [F] (305 with the M Driver's Package [F]). | Automatic: the same 8HP ratios and 3.154 final [F]. Lock-up as the M3 [F]. Shift times by Drivelogic 0.35 / 0.22 / 0.12 s [E]: use 0.15-0.2 for the default car. | AWD with `centreCoupling`. 4WD mode: `baseFrontShare` 0.05-0.1, `maxFrontShare` 0.5 [E, research]. 4WD Sport: max 0.35 [E]. `slipThreshold` 0.03, `stiffness` 2,000 [E]. Tyres 275/35 R20 and 285/35 R20 [F]. |
| Corvette Stingray Z51 C8 (RefC8Stingray) | Naturally aspirated: no `forcedInduction`. Limiter about 6,600 [P]. | DualClutch: 8 ratios 2.91-0.33, final 5.17 (Z51) [F]. `shiftTime` about 0.1 [F], otherwise as the GT12. | RWD with eLSD (approximate with `LimitedSlip`). Tyres 245/35 R19 and 305/30 R20, Pilot Sport 4S [F]: a road compound. |
| Corvette Z06 C8 (RefC8Z06) | Naturally aspirated, limiter 8,600 [F]. | DualClutch: the same ratios, final 5.56 [F]. | RWD. Pilot Sport 4S ZP, or Cup 2 R ZP on the Z07 package [F]: two car compounds, road and track [E]. |
| McLaren 720S (Ref720S) | Turbo: `maxBoostBar` 1.3 [P]. 770 Nm at 5,500 [F]; boost from about 2,000 to 5,000 [E]. `offBoostTorqueShare` ≈ 0.39 (300/770 at 1,000 rpm [E]). `spoolTime` 0.8-1.0 [E]. It has a dump valve [F], so `dumpTime` 0.15. Limiter 8,100 in 1st-2nd and 8,200 above [F]; use 8,200 (one limiter per car). | DualClutch: 7 ratios 3.98-0.69, final 3.3 [P]. `shiftTime` 0.05 [E]. | RWD. P Zero, or P Zero Corsa as an option [F]: two compounds [E]. |
| Camaro ZL1 (RefCamaroZL1) | Supercharger: `maxBoostBar` 0.65 (9.4 psi [P]). 881 Nm at 3,600 [F]. `offBoostTorqueShare` ≈ 0.62 [E]. `boostStartRpm` at idle, `fullBoostRpm` ≈ 2,800 [E] (847 Nm by 2,800 [P]). | Automatic: 10 ratios 4.70-0.64, final 2.85 [F]. `stallRpm` 2,600 [E, research]. 10L90 shifts are quicker than a PDK by GM's account [F]: `shiftTime` 0.12-0.15 [E]. Lock-up `minGear` 2 [E]. | RWD, eLSD. Tyres 285/30 R20 and 305/30 R20 [F]. |

## Checking a configuration

```
python3 tools/drivetrain_model.py <Id>            # or a path to a .luau file
python3 tools/drivetrain_model.py <Id> --curve    # also the steady full-load torque and power curve
python3 tools/drivetrain_model.py --all           # every car
```

It first checks the file: missing fields are errors. Gear order, curve order, shares, hunting risk,
lock-up capacity, unknown compounds and similar are reported as warnings or errors. It then drives
the car at 60 fps with a line-for-line Python copy of the drivetrain:
- **Launch.** Full-throttle launch to top speed; automatics also with the brake held first. Prints
  shifts, boost and converter slip.
- **Braking.** 100-0 km/h, 60-0 mph and 70-0 mph with ABS.
- **Idle.** Idle in park, idle in drive with the brake held, and idle creep.
- **Cruise.** A part-throttle cruise and coast-down.
- **Turbo response.** Boost response at two speeds (turbos).
- **Free rev.** A free rev in neutral against the limiter.

It ends with a validation table against `performanceTargets`, also showing 0-60 mph with a one-foot
rollout, the quarter mile and braking distances. The model treats the car as a point mass in a
straight line, so suspension, steering and Roblox's own physics are tested in Studio
(`docs/TEST_CHECKLIST_PHASE1.md`).

## Known limitations

- **One limiter per car.** A gear-dependent limiter (the 720S's 8,100 / 8,200 rpm) is not modelled.
- **DCT shifts one gear at a time.** The dual-clutch auto mode doesn't skip gears (the C8 skips on
  kickdown). The dual-clutch code is kept exactly as it was.
- **AWD with a large base split.** With `baseFrontShare` above about 0.3, braking with the lock-up
  closed can show a small, bounded wheel-speed ripple between simulation sub-steps (frame-averaged
  forces are unaffected). Rear-biased settings (0.0-0.2) are clean. The GT12 shows the same kind of
  sub-step ripple at low speed; it is a property of the explicit tyre update.
- **Launch control.** Held on the brake, an automatic's engine runs up only as far as traction control
  lets the tyres take. This matches launch-control behaviour, but with modest gains for RWD turbo cars.
  Real launch-control rpm targets are not published for these cars.
- **Drive modes.** M xDrive's 4WD, 4WD Sport and 2WD modes are separate configurations, or a later
  tuning option.
