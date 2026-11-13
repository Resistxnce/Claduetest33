# Ref720S: McLaren 720S coupe (2017-2023)

*Engineering reference only. In the game this car gets a fictional name, and no McLaren names, logos or designs are used.
The machine-readable version is [`Ref720S.json`](Ref720S.json). Compiled 2026-11-13.*

Tags: **[F]** McLaren figure, **[P]** published third-party spec, **[M]** measured test, **[E]** estimate (method given),
**[A]** assumption.

**Corrections to the starting facts.** The starting facts were all confirmed. Some details to add:
- Peak power is printed at 7,500 rpm in the 2017 press kit, but at 7,250 rpm in the 2021 coupe brochure table and in US data.
- Max revs are 8,100 rpm in 1st and 2nd gear and 8,200 rpm in the higher gears. The "8,500 rpm" quoted on Wikipedia comes from 12C (M838T) material.
- The rear differential is open, and McLaren uses Brake Steer to give a limited-slip effect.

## Main sources

- **[MCL21] McLaren 720S brochure, "Technical Highlights".** EU/UK specs as at 13 Oct 2021, in a third-party-hosted copy:
  <https://xr793.com/wp-content/uploads/2022/11/2021-McLaren-720S.pdf>. This is the best single source found.
- **[PR17] McLaren launch press release, March 2017,** as reproduced by netcarshow: <https://www.netcarshow.com/mclaren/2018-720s/>.
  McLaren's own copy at cars.mclaren.press/en-gb/releases/442 didn't load.
- Wikipedia: [McLaren 720S](https://en.wikipedia.org/wiki/McLaren_720S) and [M840T engine](https://en.wikipedia.org/wiki/McLaren_M840T_engine).
- The test and other sources are linked inline below. The full list is in the JSON.

## Identity

| Item | Value | Tag |
|---|---|---|
| Model | McLaren 720S Coupe (project code P14; Japan type code ABA-P14S) | F |
| Years | Coupe 2017-2023, Spider 2018-2023. Revealed in Geneva on 7 Mar 2017; replaced by the 750S | P |
| Body | 2-seat mid-engined coupe with dihedral doors and a carbon Monocage II tub (including the roof) | F |
| US vs EU | Same hardware. EU: 720 PS / 770 Nm. US: 710 hp / 568 lb-ft. DIN kerb weight 1,419 kg (90% fuel); US curb weight 1,424 kg (100% fuel) | F |

## Engine (M840T)

| Item | Value | Tag | Source |
|---|---|---|---|
| Layout | 90° V8, twin-turbo, dry sump, mid-mounted | P | Wikipedia, [evo](https://www.evo.co.uk/mclaren/720s/engine-gearbox-technical-highlights) |
| Crank | Flat-plane. The firing order below confirms it | P | Wikipedia |
| Displacement | 3,994 cc | F | MCL21 |
| Bore × stroke | 93.0 × 73.5 mm. Stroke is 3.6 mm longer than the M838T's; the bore is unchanged | P (F for the change) | Wikipedia, PR17 |
| Compression | 8.7:1. Low confidence: it is the M838T's figure, and one US listing gives 9.0 | P | CarExpert / encyCARpedia (search snippets) |
| Valvetrain | DOHC, 32 valves | P | Wikipedia |
| Fuel | Port injection, 16 injectors (2 per cylinder) | F | PR17 |
| Internals | Lighter pistons and rods; a stiffer, lighter crank; 41% of parts new versus the M838T | F | PR17 |
| Max power | 720 PS / 710 bhp / 530 kW at **7,500 rpm** (7,250 rpm on the 2021 coupe sheet) | F | PR17, MCL21 |
| Max torque | 770 Nm / 568 lb-ft at **5,500 rpm** | F | MCL21 |
| Max revs / limiter | **8,100 rpm in 1st-2nd, 8,200 rpm in 3rd-7th** | F | PR17 |
| Idle | about 800 rpm, not published | E | — |
| Launch-control rpm | about 3,500 rpm (likely 3,000-4,000), not published | E | — |
| Firing order | **1-8-3-6-4-5-2-7** | P | [M-Engineering](https://m-engineering.atlassian.net/wiki/spaces/MENGINEERI/pages/467730433/McLaren+Cylinder+Layout+Firing+Order) |
| Bank numbering | Cylinders 1-4 on bank 1 and 5-8 on bank 2. The firing order alternates between these groups, as a flat-plane V8 must. An owner-forum post says bank 1 is the right-hand bank. Cylinder 1 is assumed to be at the cabin (timing) end | P / A | M-Engineering, McLarenLife (snippet) |
| Per-bank pattern | Bank 1 fires 1-3-4-2 and bank 2 fires 8-6-5-7. Each bank fires every 180° like an inline-4, and the banks interleave every 90° | E (derived) | — |
| Firing frequency | f = rpm × 4 / 60. That gives 53 Hz at 800 rpm, 200 Hz at 3,000, 367 Hz at 5,500 and 547 Hz at 8,200. Each bank and turbo sees half that rate | E | — |

### Full-load torque curve: estimate [E], at the crank, net

No official chart or readable dyno sheet was found. The curve below is shaped through the factory points: 770 Nm at 5,500 rpm, and
530 kW at 7,500 rpm (675 Nm). Boost builds from about 2,000 rpm and the mid-range is progressive. evo describes a
"real build-up of boost through the mid-range", and the [Fabspeed tune](https://ffperformance.co/product/fabspeed-mclaren-720s-xpertune-performance-software/)
gains most at 3,700 rpm, which suggests the stock calibration holds mid-range torque back.

| rpm | 800 | 1000 | 1500 | 2000 | 2500 | 3000 | 3500 | 4000 | 4500 | 5000 | 5500 | 6000 | 6500 | 7000 | 7500 | 8000 | 8200 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Nm | 260 | 300 | 360 | 430 | 520 | 600 | 665 | 710 | 742 | 762 | **770** | 763 | 746 | 713 | **675** | 628 | 605 |
| kW | 22 | 31 | 57 | 90 | 136 | 188 | 244 | 297 | 350 | 399 | 443 | 479 | 508 | 523 | **530** | 526 | 520 |

**Measured at the wheels [M].** These figures are within 2-3% of the crank rating. That implies a real crank output of roughly
760-800 PS, and the 720S is widely reported to be under-rated:
- [BoostAddict, via Motor1/The Drive](https://www.motor1.com/news/176224/mclaren-720s-dyno-figures/) (Dynojet, Aug 2017): 694/696/698 whp and about 560 lb-ft. Power peaked at 6,500 rpm.
- [DragTimes, via Carscoops](https://www.carscoops.com/2017/10/mclaren-720s-lays-down-impressive-691) (Oct 2017): 691 whp and 547 lb-ft.
- Fabspeed's stock baseline: 689 whp and 556 lb-ft.

The game should stay on the factory figures.

## Forced induction

| Item | Value | Tag |
|---|---|---|
| Turbos | 2, one per bank. Twin-scroll and ultra-low-inertia, with titanium-aluminide turbines rated to 160,000 rpm | F (PR17) |
| Maker | MHI TD05H-06*20HF1T-12T. Wikipedia identifies these from labels on OEM turbos for resale | P |
| Wastegates | Electronically controlled wastegates, plus an electronically controlled dump valve | F (PR17) |
| Max boost | "over 1.3 bar" (uncited on Wikipedia). 1.3-1.5 bar is plausible | P / E |
| Boost onset / full boost | about 2,000 rpm / about 5,000 rpm | E |
| Twin-scroll pairing | Probably cylinders 1+4 and 2+3 on bank 1, and 5+8 and 6+7 on bank 2. Each scroll then gets pulses 360° apart | E |

## Transmission and drivetrain

| Item | Value | Tag |
|---|---|---|
| Gearbox | 7-speed + reverse SSG dual-clutch (Graziano). Ignition-cut shifts; Comfort/Sport/Track modes; launch control | F (P for Graziano) |
| Ratios 1-7 | **3.98, 2.61, 1.91, 1.48, 1.16, 0.91, 0.69** | P (US OEM data: [carspecs.us](https://www.carspecs.us/cars/2017/mclaren/720s/68778), Motor Matchup) |
| Reverse / final drive | **2.80 / 3.30** (the 750S's final drive is 15% shorter) | P |
| Speed at the limiter | 78 / 119 / 164 / 212 / 271 / 345 / 455 km/h. The 341 km/h top speed is reached at the end of 6th; 7th is an overdrive | E (rear rolling radius 0.335 m) |
| Shift time | about 0.05 s, not published | E |
| Differential | **Open**, with McLaren Brake Steer. Variable Drift Control sets how much slip is allowed | P (evo) / F |

## Mass

| Item | Value | Tag |
|---|---|---|
| Dry weight | 1,283 kg (lightest options) / 1,322 kg (base) | F (MCL21) |
| Kerb weight | **1,419 kg DIN** (fluids + 90% fuel); US curb 1,424 kg | F |
| Measured | Autocar 1,420 kg (fluids topped up); AMS 1,428 kg; C/D Lightning Lap 1,432 kg (3,158 lb) | M |
| Distribution | **41/59** front/rear (coupe table; the Spider table says 42/58) | F |
| Measured distribution | Autocar 42/58 on the MIRA weighbridge; AMS 41.5/58.5 | M |
| Other | 561 PS per tonne (dry); centre of gravity 3% lower than the 650S | F |
| Simulation | 1,494 kg (kerb + 75 kg driver) [A]; centre of mass 0.42 m high [E] and 1.575 m behind the front axle; static load per front wheel 3,005 N, per rear wheel 4,324 N | E |

## Dimensions (MCL21 unless marked)

| Item | Value |
|---|---|
| Length | 4,543 mm |
| Width | 1,930 mm body (P, [motor1.de](https://de.motor1.com/reviews/150663/test-mclaren-720s-besser-als-der-ferrari-488/)); 2,161 mm with mirrors; 2,059 mm with mirrors folded; 2,464 / 2,767 mm with one / both doors open |
| Height | 1,196 mm (1,953 mm with a door open) |
| Wheelbase | 2,670 mm |
| Track (contact-patch centres) | 1,674 mm front / 1,629 mm rear |
| Overhangs | 1,058 mm front / 816 mm rear |
| Ground clearance | 107 mm |
| Approach / breakover / departure | 8.3° (10.4° with nose lift) / 11.5° / 13.3° |
| Frontal area | about 1.85 m² [E]: 0.80 × width × height |
| Tank / luggage | 72 L / 150 L front + 210 L rear |

## Tyres, wheels, brakes

| Item | Value | Tag |
|---|---|---|
| Tyres | 245/35 ZR19 front, 305/30 ZR20 rear | F |
| Tyre radius | 0.327 m front unloaded; 0.3455 m rear unloaded, about 0.335 m rolling | E |
| Wheels | Forged aluminium, 19 × 9.0J front and 20 × 11.0J rear. Lighter forged options save up to 12.5 kg of unsprung mass | F |
| OE tyre | Pirelli P Zero. DragTimes' car was on "OEM P Zero" | P |
| Option tyre | P Zero Corsa: "six percent more mechanical grip" than the 650S. C/D's Lightning Lap car used Corsas | F |
| Trofeo R | **Not confirmed** as a 720S option. It is standard on the 765LT | A |
| Brakes | Carbon-ceramic: 390 mm front discs with 6-piston aluminium calipers; 380 mm rear discs with 4-piston calipers | F |
| Factory stopping | 100-0 km/h in 30 m. 200-0 km/h in 117 m and 4.6 s (2017 press release); the 2021 brochure says 122 m | F |
| Measured stopping | AMS: 100-0 km/h 33.2 m cold, 130-0 km/h 50.3 m warm, 200-0 km/h 115.3 m. Autocar: 70-0 mph 39.9 m ("under 40 m"). C/D Spider: 70-0 mph 141 ft. The C/D coupe figure wasn't found | M |
| Airbrake | The wing deploys fully in under 0.5 s under high-speed braking and moves the aero balance about 20% rearward | F |
| Simulation | 2,800 Nm per front wheel and 1,800 Nm per rear wheel (about 61% front) | E |

## Aerodynamics

McLaren publishes no Cd and no downforce in kilograms. What it does say [F, PR17]:
- **Downforce:** about 50% more than the 650S. Some outlets say 56%.
- **Efficiency:** downforce-to-drag ratio more than double the 650S's.
- **Rear wing:** full width and hydraulically actuated, with up to 30% more downforce than the 650S Coupe's wing. It has three modes:
  - **Driver Downforce:** 70-80% deployed, depending on speed.
  - **DRS:** 30% deployed on straights.
  - **High-Speed Braking:** 100% deployed as an airbrake.
- **Cooling:** the double-skinned dihedral doors duct air to the side radiators, so there are no side intakes. Cooling is 15% better than the 650S's.
- **Body:** the rear is 145 mm lower than the 650S's.

Estimates [E]:
- **CdA 0.85 m².** This is fitted so that rated power reaches 341 km/h in 7th: 92% driveline efficiency, Crr 0.012, 1,494 kg.
  - The fit is 0.91 m² if the top speed is reached in 6th.
  - With the wing stowed, Cd 0.36-0.40 (CdA about 0.70) would leave the top speed set by the 6th-gear limiter at about 345 km/h.
- **Downforce:** ClA about 0.20 front and 0.35 rear, roughly 1,600 N at 250 km/h. Tune this in testing.

## Suspension and steering

| Item | Value | Tag |
|---|---|---|
| Suspension | Aluminium double wishbones. **Proactive Chassis Control II**: adaptive dampers hydraulically interlinked at each corner, **no anti-roll bars** | F |
| PCC II sensors | 12 extra sensors: an accelerometer at each corner and 2 pressure sensors per damper. It reacts in 2 ms, and the system is 16 kg lighter than the 650S's | F |
| Ride height | 107 mm ground clearance. A nose lift exists, but its height in mm isn't published | F |
| Steering | Electro-hydraulic. **2.46 turns lock to lock**: the brochure prints "12.46", read as a typo, and Autocar measured 2.5. Turning circle 12.4 m | F |
| Steering ratio | about 14.5:1, from the lock angle implied by the turning circle | E |
| Simulation | Springs about 27,000 N/m front and 50,000 N/m rear (1.6 / 1.8 Hz). For roll, which PCC handles hydraulically, use anti-roll rates of about 25,000 N/m front and 18,000 N/m rear | E |

## Performance

| Source (date) | Results | Tag |
|---|---|---|
| McLaren | 0-100 km/h 2.9 s; 0-60 mph 2.8 s; 0-200 km/h 7.8 s; ¼ mile 10.3 s; top speed 341 km/h (212 mph). Spider: 0-200 km/h 7.9 s, 0-300 km/h 22.4 s. The coupe's 0-300 time isn't in the 2021 table | F |
| Motor Trend (2018 coupe) | 0-60 mph 2.5 s; ¼ mile 10.1 s at 141.5 mph | M, via [0-60specs](https://www.0-60specs.com/mclaren/720s-0-60-times) |
| Car and Driver (2018 coupe) | 0-60 mph 2.7 s; ¼ mile 10.2 s at 145 mph; 95 dBA at full throttle | M, via 0-60specs and [Motorbiscuit](https://www.motorbiscuit.com/dislike-neighbors-check-out-some-of-the-loudest-cars-stock-exhaust) |
| C/D Lightning Lap 2018 | VIR in 2:39.7; 171.7 mph on the straight; 3,158 lb; P Zero Corsa tyres | M, [Yahoo syndication](https://autos.yahoo.com/lightning-lap-2018-mclaren-720s-184600216.html) |
| C/D 2019 **Spider** | 0-60 mph 2.8 s; 0-100 mph 5.5 s; 0-130 mph 8.5 s; 5-60 mph 3.6 s; 30-50 mph 2.6 s; 50-70 mph 3.0 s; ¼ mile 10.3 s at 143 mph; 70-0 mph 141 ft; skidpad 1.09 g; 99 dBA at full throttle | M, via [0-60-time.com](https://0-60-time.com/0-60-times/mclaren/720s/2019/) |
| Road & Track (2018 coupe) | 0-60 mph 2.7 s; ¼ mile 9.9 s at 148.2 mph | M |
| Autocar (May 2017) | 0-60 mph 2.9 s (two people, full tank); 0-100 mph 5.6 s; ¼ mile 10.4 s; 70-0 mph 39.9 m; 1.24 g lateral (snippet only) | M, [mirror](https://autocar-prod.codeenigma.net/car-review/mclaren/720s) |
| auto motor und sport (2018, vs 911 GT2 RS) | 0-100 km/h 2.8 s; 0-200 km/h 7.4 s; 0-280 km/h 15.5 s; 18 m slalom 72.8 km/h; lane change 154.7 km/h | M, [forum transcription](https://www.germancarforum.com/threads/mclaren-720s-vs-911-gt2rs-ams.58232/page-5) |
| Autozeitung | 0-200 km/h 7.1 s | M (forum) |
| Motoring, South Africa (2017) | 0-100 km/h 2.85 s; 402 m in 10.29 s | M, [IOL](https://www.iol.co.za/motoring/road-tests/tested-mclaren-720s-rocks-our-quarter-mile-chart-13557256) |
| DragTimes, owner's stock car (Oct 2017) | 0-60 mph 2.5 s; 0-100 mph 5.2 s; ¼ mile 9.98 s at 141 mph | M, [The Drive](https://www.thedrive.com/article/15187/the-mclaren-720s-is-running-9-second-quarter-miles-from-the-factory) |

## Sound (for the audio engineer)

**Firing and crank.**
- Flat-plane V8, firing order **1-8-3-6-4-5-2-7**.
- Cylinders 1-4 are on bank 1 (said to be the right bank) and 5-8 on bank 2.
- Firings are evenly spaced, 90° apart, alternating banks. Each bank fires like an inline-4 (1-3-4-2), which gives the raspy,
  high-pitched character.

**Exhaust path.**
- Each bank's manifold feeds its own twin-scroll turbo.
- The catalysts follow the turbos. Aftermarket systems bolt on "after the factory converters".
- Then a rear silencer, and two large round tailpipes set **high in the centre of the rear valance**. They sit either side of the
  mesh panel with the McLaren lettering, above the diffuser. This was seen in [this CC BY 4.0 photo](https://commons.wikimedia.org/wiki/File:McLaren_720S_August_2024_006.jpg).
- An optional **Sports Exhaust** has its own tailpipe design and an "even louder and more emotive" sound [F].
- The valve hardware of either system isn't documented.

**Intake.** A cast-aluminium plenum sits on top of the engine under a mesh cover [F].

**Turbo character.**
- evo: "rushing whoosh of the turbochargers".
- Autocar: "more rasp, whoosh and fizz" than the 650S.
- The wastegates and dump valve are electronically controlled [F].
- No source read described wastegate chatter or flutter; judge that from recordings [A].

**Measured levels [M].**
- Car and Driver, at full throttle: **95 dBA** (coupe) and **99 dBA** (Spider).
- Idle **55 dBA** and 70 mph **75 dBA**. These come from a FastestLaps listing seen only as a search snippet, probably the C/D coupe test; unverified.
- auto motor und sport: 79 dB(A) at 130 km/h and 84 dB(A) at 180 km/h.

**EU stationary noise.** Not found.
- The UN R51 stationary test would run at 3,750 rpm (half of 7,500 rpm) [A; the rule is from memory, verify].
- Expect about 95-100 dB(A) [E].

**Limiter and overrun.**
- The limiter is gear-dependent: 8,100 rpm in 1st-2nd and 8,200 rpm above [F].
- The cut style isn't documented. Model it as an ignition cut with about 100-150 rpm of bounce [E].
- How the car crackles on overrun in each mode isn't documented. Reviews call the stock car muted. Assume light crackle in Sport
  and Track, little in Comfort, and more with the Sports Exhaust [A].

**Reviewer descriptions:**
- "the angry blare as the revs rise and rushing whoosh of the turbochargers" ([evo](https://www.evo.co.uk/mclaren/720s/engine-gearbox-technical-highlights)).
- At idle, "harsh and faintly gravely" (evo).
- "There's nothing rich, mellifluous or soulful here." (Autocar road test, 2017).
- "the 720S's exhaust sounds off like a railway gun at a military tattoo" (Autocar, Matt Saunders).
- "eher nach wepsigem Rennmotorrad als nach acht Zylindern", which means "more like a waspy racing motorbike than eight cylinders" ([motor1.de](https://de.motor1.com/reviews/150663/test-mclaren-720s-besser-als-der-ferrari-488/)).

**Reference videos (links only):**
- AutoMann, "Pure Exhaust Sound" (cold start, revs, acceleration): <https://www.youtube.com/watch?v=K_0jKeawP78>
- AutoMann, "Drive & Sound Overview": <https://www.youtube.com/watch?v=frcF1zktkbY>
- DragTimes, stock car, onboard launches and quarter-mile passes: <https://www.youtube.com/watch?v=eawOtLnMgo8>
- Fi Exhaust, aftermarket valved catback and catless downpipes: <https://www.youtube.com/watch?v=ijLY6Tl8ex0>
- Novitec race exhaust debut, aftermarket: <https://www.youtube.com/watch?v=XfgP-gX7KNg>
- Not found before the search budget ran out: a stock flyby, a dyno-pull video and a stock onboard run to the redline.

**Freely licensed recordings.** Wikimedia Commons has two **CC BY 3.0** audio files of this engine. Both licences are marked "not yet reviewed".
Both are **aftermarket exhausts**, so neither represents the stock sound. They are the audio from CC-BY YouTube videos:
- [File:McLaren 720S with Fi Exhaust - engine and exhaust sound (YouTube ijLY6Tl8ex0).opus](https://commons.wikimedia.org/wiki/File:McLaren_720S_with_Fi_Exhaust_-_engine_and_exhaust_sound_(YouTube_ijLY6Tl8ex0).opus).
  1 min 23 s; attribution "FiExhaust".
- [File:McLaren 720S with Novitec exhaust - engine and exhaust sound (YouTube XfgP-gX7KNg).opus](https://commons.wikimedia.org/wiki/File:McLaren_720S_with_Novitec_exhaust_-_engine_and_exhaust_sound_(YouTube_XfgP-gX7KNg).opus).
  2 min 0 s; attribution "Supercars67".

Download status: **not downloaded**. Commons refused every request with HTTP 429 (rate limit) during this session; the URLs and
licence notes are in `audio/Ref720S/LICENSE_NOTES.md`. A commercial option, which is not freely licensed, is the Sonniss
"McLaren 720S Spider SSG 2019" sound library.

**Starting audio settings [E]:** redline 8,200 rpm, with 8,100 rpm in 1st-2nd; idle 800 rpm; shift cut 0.05 s; crackles from
4,000 rpm.

## Visual blockout

These were judged from Commons photos. None is a true orthographic side view, so the fractions carry about ±0.03-0.04 error:
- [McLaren 720S August 2024](https://commons.wikimedia.org/wiki/File:McLaren_720S_August_2024.jpg) (CC BY 4.0)
- [August 2024 001](https://commons.wikimedia.org/wiki/File:McLaren_720S_August_2024_001.jpg) (CC BY 4.0)
- [2021 McLaren 720S 6](https://commons.wikimedia.org/wiki/File:2021_McLaren_720S_6.jpg) (CC BY-SA 4.0)
- [August 2024 006, rear](https://commons.wikimedia.org/wiki/File:McLaren_720S_August_2024_006.jpg) (CC BY 4.0)
- [McLaren 720S 9, rear](https://commons.wikimedia.org/wiki/File:McLaren_720S_9.jpg) (CC BY-SA 4.0)

| Item | Value (fraction of length from the nose) | Tag |
|---|---|---|
| Front axle | 0.233 (1,058 mm) | F |
| Rear axle | 0.821 | F |
| Windscreen base | about 0.31, roughly 0.35-0.45 m behind the front axle | E |
| Roof peak | about 0.52 (mid-wheelbase, over the seats); height 1,196 mm | E / F |
| Beltline | about 0.80 m high | E |

**Body shape.**
- **Nose:** low and pointed, "shark-like". Deep headlight "eye sockets" double as cooling intakes.
- **Sides:** smooth, with no side intakes. The double-skinned dihedral doors carry the air channels.
- **Canopy:** a teardrop glass canopy flows into a low engine cover.
- **Tail:** high and short. The full-width active wing forms the trailing edge, above slim LED light blades and an open mesh
  upper rear panel. Below are a deep diffuser and two round tailpipes high in the centre.

## Biggest gaps

1. **Torque curve.** There is no official chart or readable dyno sheet, so the curve above is an estimate.
2. **Gear ratios and final drive.** These are from US data feeds, not a McLaren document.
3. **Car and Driver coupe sheet.** The 0-100 mph time, 70-0 mph braking, skidpad and idle/cruise dBA are missing or unverified.
   The Motor Trend braking and handling numbers were also out of reach, because both sites block automated reading.
4. **Other unpublished values:**
   - EU stationary noise;
   - Cd and absolute downforce;
   - shift time, launch-control rpm, idle rpm and boost figures.
5. **Firing order and banks.** The firing order rests on one specialist source; which side each bank is on, and where cylinder 1
   is, are partly from a forum.
6. **Exhaust.** The valve hardware and the overrun behaviour by mode aren't documented.
7. **Trofeo R** is not confirmed as a 720S option.
8. **Recordings.** No freely licensed recording of a stock-exhaust 720S was found.
9. **Searching ended early.** The web search budget, which all agents share, ran out mid-task. A follow-up could chase the
   original C/D, MT and AMS pages and a stock dyno chart.
