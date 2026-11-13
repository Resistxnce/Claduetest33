# Prototype car: Valenza GT12

*Internal ID `Prototype812`. Configuration: `src/ReplicatedStorage/VehicleSystem/VehicleConfigurations/Prototype812.luau`.*

An original front-mid-engined V12 GT with fictional branding, built to the publicly documented
engineering of the Ferrari 812 Superfast. No Ferrari names, logos, body design or assets are used.

Tags used below and in the configuration file:
**[F]** Ferrari factory figure, **[P]** published third-party figure, **[E]** simulation estimate,
**[A]** assumption.

## Published figures

| Item | Value | Tag |
|---|---|---|
| Engine | 6,496 cc 65° V12, naturally aspirated | F |
| Max power | 588 kW / 800 CV at 8,500 rpm | F |
| Max torque | 718 Nm at 7,000 rpm; 80% of it from 3,500 rpm | F |
| Max revs | 8,900 rpm (812 GTS spec sheet, same engine) | P, verify |
| Weight | 1,525 kg dry; 1,630 kg kerb (DIN) | F |
| Weight distribution | 47% front / 53% rear | F |
| Length × width × height | 4,657 × 1,971 × 1,276 mm | P |
| Wheelbase | 2,720 mm | P |
| Track | 1,672 mm front / 1,645 mm rear | P |
| Tyres | 275/35 ZR20 front, 315/35 ZR20 rear | P |
| Brakes | carbon-ceramic, 398 mm front / 360 mm rear discs | P |
| Gearbox | 7-speed dual-clutch, rear-wheel drive | F |
| 0–100 / 0–200 km/h | 2.9 s / 7.9 s | F / P |
| Top speed | over 340 km/h | F |

Sources: [Ferrari press release](https://corporate.ferrari.com/en/ferrari-812-superfast-new-extreme-performance-v12-berlinetta),
[autotijd.be](https://autotijd.be/en/specs/ferrari/812-superfast),
[Ultimatecarpage](https://www.ultimatecarpage.com/spec/6773/Ferrari-812-Superfast.html),
[Wikipedia](https://www.wikipedia.com/wiki/Ferrari_812_GTS),
[evo](https://www.evo.co.uk/ferrari/812-superfast/engine-transmission-and-technical-highlights).
Ferrari's own pages didn't load for automated reading, so the dimensions, tyres, brakes and track
come from third-party sheets that agree with each other.

## Estimates and how they were made

| Item | Value | How |
|---|---|---|
| Simulated mass | 1,705 kg | Kerb weight plus a 75 kg driver [A] |
| Centre of mass | 0.45 m high; 1.442 m behind the front axle | Height estimated; position from the 47/53 split |
| Rotational inertia | about 2,600 kg·m² in yaw | From a 4.0 × 1.8 × 0.8 m mass box |
| Torque curve | 330 Nm at 1,000 rpm rising to 718 Nm at 7,000, 661 at 8,500, 625 at 8,900 | Shaped through the factory points, including 661 Nm = 588 kW at 8,500 rpm |
| Gear ratios | 2.980, 2.436, 1.992, 1.629, 1.331, 1.089, 0.890; final drive 4.00 | Fitted with a point-mass model to the factory 0–100, 0–200 and top speed |
| Speed at 8,900 rpm by gear | 103, 125, 153, 188, 229, 281, 343 km/h | From the ratios and the 0.364 m rear tyre radius |
| Gearbox | 92% efficient; 60 ms shifts at 35% clutch capacity | Typical dual-clutch behaviour |
| Engine inertia | 0.20 kg·m² | Typical large V12 with a light flywheel |
| Springs | 51,000 N/m front, 71,000 N/m rear | Ride frequencies of 1.8 Hz front, 2.0 Hz rear |
| Dampers | bump / rebound 2,700 / 4,500 front, 3,400 / 5,700 rear (N·s/m) | Damping ratios of about 0.3 in bump and 0.5 in rebound |
| Anti-roll bars | 32,000 N/m front, 20,000 N/m rear | For a slightly understeering balance |
| Tyre ("Performance" compound) | peak grip 1.45 braking/driving, 1.22 cornering; peak at 10% slip and 7.5° | Road performance tyre; tune in testing |
| Brakes | 3,800 Nm front and 2,000 Nm rear per wheel; about 66% front bias | Enough to lock the wheels; ABS targets 12% slip |
| Aero | CdA 0.70 m²; downforce areas 0.18 front, 0.27 rear (about 1,900 N at 300 km/h) | Not published by Ferrari; drag fitted to the top speed |
| Traction control | caps torque at 1.3 times the driven tyres' grip, trims past 11% slip | Modern traction systems |
| Steering | 30° at the wheels when slow, 4.5° at 250 km/h | Keyboard-friendly; tune in testing |

## Validation so far

`tools/drivetrain_model.py` is a line-for-line Python copy of the game's engine, clutch, gearbox,
differential, brake, traction-control and tyre code, run at 60 frames per second. It treats the body
as a point mass, so it checks the drivetrain, not suspension or Roblox's own physics.

| Test | Factory | Point-mass fit | Game drivetrain code |
|---|---|---|---|
| 0–100 km/h | 2.9 s | 3.09 s | 3.37 s |
| 0–200 km/h | 7.9 s | 7.94 s | 8.17 s |
| Top speed | over 340 km/h | 343 km/h | 339 km/h, on the rev limiter in 7th |
| 100–0 km/h braking | not published | n/a | 28.1 m |
| Launch | n/a | n/a | holds about 4,200 rpm, pulls about 0.94 g |
| Idle | n/a | n/a | steady 950–985 rpm, no creep |

Issues the model caught and that are now fixed: the launch clutch let the engine bog at about
2,600 rpm (0–100 took 4.0 s), engine friction was subtracted twice at full throttle, and traction
control oscillated at a standing start.

Remaining gaps:
- **0–100 km/h is 0.5 s slow.** Most of it comes from spinning the engine and wheels up in first gear
  (that inertia is worth about 210 kg of extra mass) and from cautious traction control. Tuning
  options: traction control headroom, tyre grip at launch, engine inertia, launch rpm.
- **Braking may be too short** for a road car on road tyres. No factory figure exists to check against.
- **Suspension, steering and handling are untested.** They need Studio.

## What to measure in Studio

The telemetry overlay (T) times 0–100, 0–200 and 100–0 km/h automatically and shows top speed.
Compare those against this table, and use the per-wheel loads to check the static balance: about
3,930 N on each front wheel and 4,430 N on each rear wheel at rest.
