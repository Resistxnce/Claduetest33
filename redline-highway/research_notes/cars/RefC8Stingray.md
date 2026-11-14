# RefC8Stingray: Chevrolet Corvette Stingray coupe, Z51 (C8, 2020 onward)

*Engineering reference only. In the game this car gets a fictional name; no Chevrolet or Corvette
names, badges or body design are used. Machine-readable version: `RefC8Stingray.json` (same facts,
with source ids). Compiled 13 Nov 2026.*

Tags: **F** manufacturer, **P** published third-party spec, **M** measured test, **E** estimate
(method given), **A** assumption. Source ids (S01...) are listed at the end.

## Corrections to the brief

| Brief said | Finding |
|---|---|
| LT2, 6.2 L NA pushrod V8, 495 hp with the Z51 exhaust | **Confirmed.** 495 hp (369 kW) @ 6,450 rpm and 470 lb-ft (637 Nm) @ 5,150 rpm with the NPP performance exhaust, which comes with Z51. 490 hp / 465 lb-ft without it. [F] |
| Tremec 8-speed DCT (TR-9080) | **Confirmed.** GM RPO M1L, a transaxle mounted behind the engine. [F] |
| Mid-engine RWD, eLSD on Z51 | **Confirmed.** The base car has a mechanical clutch LSD. The final drive also differs: **5.17:1 on Z51** and 4.89:1 on the base car. [F] |
| "C8, 2020 onward" uses the LT2 | **Only through MY2026.** The **2027 Stingray gets the 6.7 L LS6** (535 hp). This config should stay on the LT2 (2020–2026). |
| Weight distribution about 40/60 | **Confirmed:** 40/60 from a leaked GM document, and 39.4/60.6 measured by Car and Driver. |
| The EU car had a different exhaust and power | **Confirmed:** 482 PS (354 kW) @ 6,450 and 613 Nm @ **4,500** rpm, with gasoline particulate filters. Z51 is standard in Europe. |

## Identity

- **Car:** Chevrolet Corvette Stingray, C8, the first mid-engine Corvette. Built at Bowling Green, Kentucky. Production began 3 Feb 2020. [P, S10]
- **Body:** 2-seat coupe with a removable roof panel that stows in the rear trunk, so it is targa-style. A convertible also exists. Left-hand drive in the US. Factory right-hand drive for the UK, Japan, Australia and New Zealand. [F/P, S10]
- **Trims:** 1LT, 2LT and 3LT, plus the **Z51 Performance Package**. Z51 adds:
  - the NPP dual-mode exhaust (+5 hp);
  - the eLSD and the 5.17 final drive;
  - 345/350 mm brakes with monobloc calipers;
  - a front splitter and rear spoiler (+400 lb downforce);
  - a third radiator for oil and transmission cooling;
  - stiffer suspension with threaded spring seats;
  - Michelin Pilot Sport 4S tyres (the base car has Pilot Sport ALS all-season tyres).

  Common Z51 options: FE4 Magnetic Ride ($1,895) and E60 front lift ($1,495 in 2020, $1,995 in 2021). The Z51 package cost $5,000 in 2020 and $5,995 in 2021. [F/P, S01, S02, S03, S10, S13]
- **US vs EU:**

  | | US (Z51, NPP) | EU / UK |
  |---|---|---|
  | Power | 495 hp / 502 PS @ 6,450 | 482 PS / 354 kW @ 6,450 |
  | Torque | 637 Nm @ 5,150 | 613 Nm @ 4,500 |
  | Exhaust | NPP valved, no particulate filter | particulate filters (Otto-Partikelfilter), Euro 6e |
  | Top speed | 184 mph (Z51) | 296 km/h (the same figure) |
  | 0–60 mph / 0–100 km/h | 2.9 s (60 mph) | 3.5 s (100 km/h, maker) |
  | Weight | 3,535 lb curb (1LT) | 1,730 kg EU kerb (with a 75 kg driver) |
  | Noise | – | stationary 95 dB(A), pass-by 73 dB(A) (72 from 12/2024) |

  Sources: S19, S20, S21.

## Engine (LT2)

| Item | Value | Tag | Source |
|---|---|---|---|
| Type | GM Gen V small-block, 90° V8, naturally aspirated | F | S01, S02 |
| Crank | **Cross-plane**, forged steel (S38 alloy) | P | S10, S07 |
| Displacement | 6,162 cc (6.2 L) | F | S19, S20 |
| Bore × stroke | 103.25 × 92.0 mm (4.06 × 3.62 in); bore spacing 4.40 in | F | S01 |
| Compression | 11.5:1; 59 cc chambers | F | S01 |
| Valvetrain | cam-in-block, pushrods, 2 valves/cyl, dual-equal VVT (up to 62°), chain drive. Valves: 54 mm hollow intake, 40.4 mm sodium-filled exhaust. Lift 14 mm intake and exhaust. | F/P | S01, S07 |
| Block / heads | A319-T7 aluminium; cast-in iron liners; 4-bolt nodular main caps | F | S01, S07 |
| Induction | rear-facing manifold, 8 equal runners about 210 mm long, 87 mm throttle | P | S07, S08 |
| Fuel | direct injection, 150 bar (2,175 psi); pump and injectors upgraded for MY2022 | F | S01, S10 |
| Cylinder deactivation | AFM, V8 to V4; cylinders 1-7-6-4 stay active | F | S01 |
| Max power | **495 hp (369 kW) @ 6,450 rpm**, SAE J1349, with NPP | F | S03 |
| Max torque | **637 Nm (470 lb-ft) @ 5,150 rpm**, with NPP | F | S01 |
| Redline | 6,500 rpm on the GM-based spec page; 6,600 rpm in Corvette Magazine and EngineLabs | P (conflict) | S02, S07, S08 |
| Fuel-cut limiter | about **6,600 rpm** ("Engine Overspeed Protection", fuel cutoff, in manual mode). GM's torque chart ends at about 6,620. | P | S27, S12 |
| Idle | **not published**. About 600 rpm warm. Cold start about 1,200–1,500 rpm for 5–15 s. | E | S26 |
| Launch control | **3,500 rpm** hold (GM procedure, and the SAE article) | F | S03, S04 |
| Park/neutral rev limit | not found | – | – |
| Firing order | **1-8-7-2-6-5-4-3** (V4 mode: 1-7-6-4) | F | S01, S11 |
| Dry sump | details below | P | S07, S08, S09 |
| Oil | 7.5 qt (7.1 L) with filter, Dexos2 0W-40; only about 1 qt circulating | F/P | S01, S07 |

The **dry sump** in detail:
- three scavenge pumps: two crank-driven in the shallow pan and one cam-driven in the sealed valley;
- a two-stage pressure pump, at full output above about 5,500 rpm;
- the crank nose drives three of the four pumps;
- a plastic remote tank on the **left-front corner** of the block;
- piston oil jets, and an oil cooler 25% larger than before;
- designed for more than 1 g in any direction.

**Cylinder numbering (GM convention) [P convention, E orientation]:**
- Odd cylinders **1-3-5-7 are on the left bank**, which is the driver's side on a US car. Even cylinders **2-4-6-8 are on the right bank**.
- Cylinder 1 is at the front (accessory end) of the left bank.
- In the C8 the accessory and dry-sump end faces **forward, toward the cabin**, and the flywheel faces the transaxle at the rear. So cylinder 1 is the left-bank cylinder nearest the seats.
- I inferred this orientation from the layout (the transaxle sits behind the engine, and the dry-sump tank is on the left-front of the block), not from a GM drawing.
- Firing by bank: L R L R R L R L. The left bank fires at 0/180/450/630° (gaps 180-270-180-90); the right bank at 90/270/360/540°. Each bank on its own is uneven, which is where the cross-plane burble comes from.

### Full-load torque curve (crank) [M: read from GM's chart]

I pixel-extracted the LT2 line from GM's slide "LT2 vs LS6 engine performance comparison" (March 2026, the
2027 LS6 presentation; [image](https://images-stag.jazelc.com/uploads/theautopian-m2en/ls6-performance-e1774532266852.png)).
- The chart's peak reads 469 lb-ft at about 5,120 rpm, and its power line reads about 493 hp at 6,470 rpm. Both are within about 1% of GM's figures, so the scale is right.
- Points at 5,150 and 6,450 rpm are pinned to the factory figures.
- Reading accuracy is about ±4 Nm.
- These are **crank** figures, SAE-rated, with the NPP exhaust.

| rpm | 1000 | 1500 | 2000 | 2500 | 3000 | 3500 | 4000 | 4500 | 5000 | 5150 | 5500 | 6000 | 6450 | 6500 | 6600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| lb-ft | 319 | 362 | 391 | 402 | 408 | 418 | 442 | 460 | 465 | 470 | 454 | 428 | 403 | 397 | 387 |
| Nm | 433 | 491 | 530 | 545 | 553 | 567 | 599 | 624 | 630 | 637 | 616 | 580 | 546 | 538 | 525 |

Wheel-dyno cross-checks [M]:
- stock Z51 owners' Dynojet average: about 429 whp / 410 lb-ft;
- Paragon (2026, SAE) stock Stingray: 424 whp / 410 lb-ft;
- that implies about 11–15% driveline loss (S28, S39);
- Motor Trend's 2019 dyno result of 558 whp was set up wrongly and withdrawn.

## Transmission

| Item | Value | Tag | Source |
|---|---|---|---|
| Model | Tremec TR-9080 (RPO M1L) 8-speed DCT transaxle | F | S04 |
| Clutches | two concentric wet clutches, normally open: outer (5 plates) for odd gears, inner (6 plates) for even | P | S04 |
| Capacity | 800 Nm (590 lb-ft) input, up to 7,500 rpm | F | S04 |
| Ratios 1–8 | **2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33** (spread 8.82) | F | S02, S05, S06 |
| Reverse | 2.63 | F | S02 |
| Final drive | **5.17 (Z51 eLSD)**, which GM rounds to 5.2 (≈1.46 transfer × 3.55 ring and pinion). Base mLSD: 4.89 (≈1.38 × 3.55). | F | S04, S03 |
| Shift time | **100 ms** clutch overlap on upshifts, with no torque interruption. Skip downshifts at full throttle (7-4, 6-3, 5-2). | F | S04 |
| Fluid | 11 L Pentosin FFL-4 | F | S04 |

auto motor und sport's ratio list (4.23, 2.57, 1.78, 1.28, 0.95, 0.74, 0.58, 0.48; R 3.84) is the same
gears **multiplied by the 1.4545 transfer gear**. Don't also multiply it by 5.17.

Derived values [E], using a rear dynamic radius of 0.339 m:
- Overall ratios: 15.04, 9.10, 6.31, 4.55, 3.36, 2.64, 2.07, 1.71.
- Speed at 6,600 rpm in each gear: **56, 93, 134, 185, 251, 320, 407, 494 km/h**. So 0–60 mph takes two upshifts.
- The Z51 top speed (184 mph) comes in **6th at about 6,100 rpm**.
- 70 mph in 8th is about 1,500 rpm.
- Drive modes: Tour, Sport, Track. Pulling both paddles declutches; holding "−" drops to the lowest available gear; there is a burnout mode. [F, S03]

## Drivetrain

- RWD transaxle. The Z51 eLSD is an electronically modulated clutch pack inside the transaxle. It varies continuously from open to locked and works with Performance Traction Management and stability control (it replaces some brake-based intervention). GM tunes it per model. [P, S04]
- Lock torques and ramp rates were not found.
- Suggested game approximation [E]: preload 100 Nm, power lock 0.45, coast lock 0.30.

## Mass

| Item | Value | Tag | Source |
|---|---|---|---|
| Dry weight | 1,530 kg (3,366 lb) | F | S01 |
| Curb weight, 1LT coupe | 1,603 kg (3,535 lb), US curb weight with no driver | P | S31 |
| Measured, Z51 3LT with MRC | **1,654 kg (3,647 lb)** (C/D, Oct 2019); 1,650 kg (3,638 lb) (C/D, Sept 2020) | M | S13, S15 |
| EU kerb weight | 1,730 kg (with a 75 kg driver) | F | S20 |
| Distribution | 40/60 (leaked GM document); **39.4/60.6 measured** (C/D) | P / M | S32, S13 |
| Static wheel loads | about 3,200 N per front wheel and 4,920 N per rear wheel (1,654 kg, no driver) | E | – |
| MY2027 LS6 Z51 (magazine figure) | 1,679 kg (3,702 lb) | M | S17 |

## Dimensions

| Item | Value | Tag | Source |
|---|---|---|---|
| L × W × H | 4,630 × 1,934 × 1,234 mm (EU sheets: 4,634 × 1,934 × 1,235); 2,025 mm wide with mirrors | F | S01, S20 |
| Wheelbase | 2,722 mm | F | S01 |
| Track F / R | 1,648 / 1,586 mm (AMS: 1,648 / 1,585) | F | S01, S19 |
| Ground clearance | 81 mm on the EU listing (probably the splitter). The front lift adds about 2 in (40–50 mm) below about 25 mph. | P | S20, S10 |
| Frontal area | about 1.95 m² (0.82 × W × H) | E | – |
| Overhangs | about 0.85 m front and 1.06 m rear, from photos (±0.08 m) | E | S36 |
| Fuel / cargo | 70 L (18.5 gal); 357 L in the two trunks | F | S02, S19 |

## Tyres and wheels

- **Sizes:** 245/35ZR19 front and 305/30ZR20 rear, Y-rated. Unloaded diameters are about 654 and 691 mm. [F, S01, S19]
- **Wheels:** 19 × 8.5 front and 20 × 11 rear, 5 × 120 bolt pattern. Offsets were not found.
- **Original-equipment tyres:**
  - Z51 cars: **Michelin Pilot Sport 4S**, in GM's "TPC" spec (AMS);
  - base cars: Pilot Sport ALS all-season.
- **Run-flat (ZP) status:** **not confirmed.** From memory and unverified, the C8 does not use run-flats and carries a sealant/inflator kit. [A]

## Brakes

- **Z51:**
  - Brembo 4-piston monobloc calipers front and rear;
  - **345 × 30 mm front and 350 × 27 mm rear** ventilated iron discs;
  - eBoost electric booster. [F, S01]

  GM's sheet prints "13.3 in" next to 345 mm for the front disc. 345 mm is 13.6 in, and Z51 replacement rotors are sold as 345 × 30 mm (S29), so the inch figure looks wrong.
- **Base car:** 321 × 30 mm front and 339 × 26 mm rear.
- **Measured stops [M]:**

  | Test | Distance | Source and date |
  |---|---|---|
  | 70–0 mph | **149 ft (45.4 m)** | C/D, Oct 2019 |
  | 70–0 mph | 154 ft | C/D, Sept 2020 |
  | 60–0 mph | 97 ft (29.6 m) | Motor Trend, Oct 2019 |
  | 100–0 mph | 301 ft | 2027 comparison, secondary |

  Game target for 100–0 km/h [E]: about 35 m.

## Aero

- **Drag coefficient:** **not published by GM.** A forum figure of 0.322 is unverified (for comparison, the C7 was 0.30). [A, S30]
- **Z51 downforce:** the front splitter and rear spoiler add **400 lb (1,779 N)** versus the base car, at an unstated speed. They also cut top speed from 194 to 184 mph. [F, S22]
- **Drag area fitted to top speed [E]:**
  - Method: the LT2 curve above, 6th gear, 88% driveline efficiency, Crr 0.013, 1,729 kg and air at 1.20 kg/m³.
  - Results: **0.77 m² for the base car (194 mph)** and **0.91 m² for Z51 (184 mph)**.
  - The Z51 increment (about 0.14 m²) matches 400 lb of downforce at a lift/drag ratio of about 3.
  - Cd 0.32 × 1.95 m² would predict more than 205 mph, so use the fitted CdA, as was done for the GT12 prototype.
- **Downforce coefficient [E]:** Z51 extra ClA of about 0.44 m², assuming the 400 lb figure is quoted at 184 mph. Split it about 40% front / 60% rear. Assume about zero lift on the base car.

## Suspension and steering

- **Front and rear:** SLA double wishbones with aluminium arms, 46 mm monotube coil-over dampers and anti-roll bars (the rear bar is direct-acting). [F, S01]
- **Z51:** higher spring rates and firmer dampers, plus threaded spring seats. [P, S10]
- **Magnetic Ride:** Magnetic Selective Ride Control 4.0 (FE4) is optional. On Z51 cars it adds PTM. From 2021 it is available without Z51. [F]
- **Front lift:** about 2 in, below about 25 mph, with GPS memory. [P]
- **Steering:** variable-ratio electric rack, **15.7:1** (GM and AMS). Lock-to-lock was **not found**; estimate about 2.5 turns [E].
- **Turning circle:** 11.6 m (38.0 ft); 11.1 m with MRC. AMS measured 12.2 m left / 12.1 m right.

## Performance

**Factory [F]:**
- **Z51:**
  - 0–60 mph **2.9 s**;
  - ¼ mile **11.2 s @ 121 mph**;
  - top speed **184 mph (296 km/h)**.
- **Base car:** 0–60 3.0 s; ¼ mile 11.2 s @ 123 mph; top speed **194 mph** (flying-mile average at Papenburg).
- **EU:** 0–100 km/h 3.5 s.
- Sources: S03, S22, S20.

**Magazine tests [M]:**

| Outlet, date | 0–60 | ¼ mile | Braking | Grip | Weight | Interior sound |
|---|---|---|---|---|---|---|
| Car and Driver, 15 Oct 2019 (Z51 3LT, MRC) [S13, S14, S16] | **2.8 s** | **11.2 s @ 122 mph** | 70–0: 149 ft | 1.03 g | 3,647 lb, 60.6% rear | **47 / 92 / 74 dBA** (idle / WOT / 70 mph) |
| Car and Driver vs Cayman GT4, 2 Sept 2020 [S15] | 3.0 s | 11.3 s | 70–0: 154 ft | 1.03 g | 3,638 lb | about 73 dBA at 70 mph |
| Motor Trend, 15 Oct 2019 [S18] | 2.8 s | 11.1 s @ 123.2 mph | 60–0: 97 ft | 1.04 g | – | – |
| auto motor und sport, EU car, test 08/2020 [S19] | – | – | – | – | – | 48 idle; 69/72/76/79/81 at 80/100/130/160/180 km/h; 89 max dB(A) |
| Johnny Bohmer Proving Grounds, 2023 [S41] | – | – | – | – | – | top speed 191.7 mph (Z51, 2.3-mile run) |

Notes on these tests:
- The C/D 2020 comparison also recorded a Grattan lap of 1:26.4.
- The C/D sound figures are the Dec 2019 issue as quoted on a forum, and agree with a 2027 comparison. caranddriver.com itself couldn't be fetched.

**Game timer targets [E]:** 0–100 km/h about 3.0 s; 0–160 km/h about 7.2 s; 0–200 km/h about 11.6 s; top speed 296 km/h.

## Sound (for the audio engineer)

**The basics**
- 6.2 L cross-plane pushrod V8 with 2 valves per cylinder. The note is deep and bass-heavy.
- **Firing frequency = rpm / 15 Hz:**

  | rpm | Situation | Firing frequency |
  |---|---|---|
  | 600 | idle | 40 Hz |
  | 3,500 | launch hold | 233 Hz |
  | 6,450 | peak power | 430 Hz |
  | 6,600 | limiter | 440 Hz |

- Engine order 4 dominates. Each bank fires unevenly on its own, and the banks are piped separately up to the muffler, so strong half-order and 2nd-order content gives the burble. [E]
- In **V4 mode** (cylinders 1-7-6-4) the firing is even every 180°, so order 2 dominates. GM closes the AFM valves then to hide the change. [E/P]

**Exhaust layout**
1. **Headers:** upswept 4-into-1 stainless tubular headers with tapered collectors, one per bank. [P, S07, S23]
   - Conflict: EngineLabs says base cars have iron 4-2-1 manifolds and only performance-exhaust cars get stainless equal-length headers. Unresolved.
2. **Catalysts:** two round close-coupled cats, one per bank, between the engine and the frame rails or trunk wall. [P]
3. **Cold end:** Tenneco, from the cats to the tips. It has 18 heat shields and one large, shielded muffler. [P, S23, S24]
4. **Valves:**
   - Standard car: two AFM/flow valves, one per bank. They close in V4 mode, manage back pressure and warm the cats.
   - **NPP** adds two tailpipe valves in the low-restriction path of the dual-outlet muffler near the tips, for up to four valves in total.
   - Owners describe the NPP muffler with the valves open as nearly straight-through with an **internal X-pipe**. I found no separate crossover pipe. [P, S25]
5. **Tips:** quad tips, as **two pairs, one at each outer rear corner**, low in the fascia (seen in photos). A centre exhaust arrives only with the 2027 LS6.
6. **Pipe diameter:** stock size not found; aftermarket systems use 3 in.
7. **NPP rating:** +5 hp / +5 lb-ft. One SAE test is said to show only about 1.2 hp. [F, S03, S35]

**Modes [P, S25, S26]**

| Mode | Tailpipe valves |
|---|---|
| Stealth | closed whenever the engine runs (default in Weather mode) |
| Tour | mostly closed: "barely a murmur" |
| Sport | open at idle and in most driving |
| Track | always open |

The mode can be customised in MyMode and Z-mode.

**Cold start [P, S26]:** loud. The engine runs rich at a raised idle with the NPP valves fully open for about 5–15 s to heat the cats.

**Measured levels**
- C/D interior: **47 dBA at idle, 92 dBA at full throttle, 74 dBA at 70 mph** (73 in the 2020 comparison). [M]
- AMS (EU car): 48 at idle, 89 maximum, 72 at 100 km/h, 76 at 130 km/h. [M]
- EU stationary noise: **95 dB(A)**. The test rpm was not found.
  - Estimate [E]: **3,750 rpm**, the UN R51.03 rule for engines rated between 5,000 and 7,500 rpm.
  - Older 3/4-of-rated-speed practice would give 4,838 rpm. Check this against a certificate of conformity.
- EU pass-by noise: **73 dB(A)** (72 dB(A) from 12/2024). [F]

**Limiter [P/E]:** fuel cut at about 6,600 rpm in manual mode. In automatic mode the DCT upshifts before the limiter. How the cut sounds is undocumented; model it as a hard cut with a bounce of about 100–150 rpm.

**Overrun [E]:** no factory crackle map is documented, and owners call the stock NPP "not very aggressive even in Track". Suggested modelling:
- mild burble and light pops, plus rev-match blips on downshifts, only in Sport/Track with the valves open;
- almost nothing in Tour/Stealth;
- short crackles, about 0.5 s.

**Reviewer descriptions** (each under 25 words)
- "thunders like a NASCAR engine" at full throttle out of corners. (C/D, Ceppos, Oct 2019)
- In Tour mode, "an engine note that's barely a murmur". (C/D, Oct 2019)
- "We sometimes wished the new Stingray felt a little louder and brasher." (C/D, Oct 2019)
- A low point: "where's the V-8 roar?". GM "toned down a lot for the C8". (C/D, Colwell, Sept 2020)
- Track-mode idle is "like an old school pre cat muscle car"; it is louder outside than inside. (Corvette Forum owner)

**Reference videos (links only)**
- Standard vs NPP exhaust, same camera and mic: https://www.youtube.com/watch?v=4YYRgP9ud40
- Stock NPP sound levels: https://www.youtube.com/watch?v=nXO9J77yhBw
- Cold starts:
  - https://www.youtube.com/watch?v=RNDHE3RRD4w
  - https://www.youtube.com/watch?v=3OZfMV_1Gxc (2023 Z51)
  - https://www.youtube.com/watch?v=OX6mwVF-TKQ
  - https://www.youtube.com/watch?v=vzLPx9rzvic (2022 2LT with GM performance exhaust)
- Stock Z51 vs AWE Track (cold start, idle, dB, revs, flybys; use only the stock parts):
  - https://www.youtube.com/watch?v=TQtjwFX2CkA
  - https://www.youtube.com/watch?v=RxedeWO4Ju4
- Onboard:
  - https://www.youtube.com/watch?v=osEwus5R2s8 (2020 3LT Z51 POV)
  - https://www.youtube.com/watch?v=2ii_VqU3gXs (stock Z51, 0–182 mph)
  - https://www.youtube.com/watch?v=jI21SSlc5jA (launch control)
- Dyno:
  - https://www.youtube.com/watch?v=4zK7yAnEtK0 (stock pull)
  - https://www.youtube.com/watch?v=_ODE8Jfs-FM (stock C8 real-world hp)
  - https://www.youtube.com/watch?v=PqnHvsYAAzs (LT2 on an engine dyno)
- I found no verified flyby of a fully stock car apart from the stock segments in the AWE comparisons.

**Freely licensed recordings (none downloaded)**

`upload.wikimedia.org` returned HTTP 429 to this network every time, so
`research_notes/cars/audio/RefC8Stingray/` was not created. Retry later, and keep the attribution with any use.

| Recording | Car | Licence and attribution | Status |
|---|---|---|---|
| [Commons: Chevrolet Corvette Stingray – engine and exhaust sound (YouTube TiObDdbrbOs).opus](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Stingray_-_engine_and_exhaust_sound_(YouTube_TiObDdbrbOs).opus) | 2023 C8 Z51 LT2 with an **MBRP aftermarket** cat-back, 1 min 23 s | CC BY 3.0, Gripforce Clutches | Commons licence review pending |
| [Commons: Chevrolet Corvette Z06 – engine and exhaust sound (YouTube 8kg9FOz-zR8).opus](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Z06_-_engine_and_exhaust_sound_(YouTube_8kg9FOz-zR8).opus) | 2011 C6 Z06, LS7 dry-sump V8, factory exhaust, 4 min 6 s | CC BY 3.0, O'Donnell Chevrolet | Commons licence review pending |
| archive.org "corvette-c8" | C8 promo shoot | "Public Domain Mark", claimed by the uploader | **Not used.** It is a re-upload of a YouTube video "content managed by ContentSafe", so the licence claim is doubtful. |

## Visual blockout [E, from photos]

**Photos viewed**

All CC BY-SA 4.0 unless noted. None is a true orthographic side view.
- [Chevrolet_Corvette_Stingray_(C8).jpg](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Stingray_(C8).jpg) by Ghostofakina: yellow Z51, left side from the rear quarter.
- [..._Montpelier_VT_May_2022_side.jpg](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_C8_State_Street_Bridge_downtown_Montpelier_VT_May_2022_side.jpg) by Artaxerxes: right side from the front quarter.
- [..._Z51_Torch_Red_02.jpg](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_C8_Stingray_3LT_Coupe_Z51_Torch_Red_02.jpg) by Ethan Llamas: rear 3/4, showing the quad tips and high wing.
- Torch Red 01 (by Ethan Llamas) and 2020_Chevrolet_Corvette_Stingray_Coupe.jpg, both front 3/4. Their licences were not checked.

**Body**
- Low, wide, cab-forward two-seater.
- Short, pointed wedge nose between slim angular headlamps. Z51 adds a black splitter.
- Large side intakes behind the doors.
- Glass engine cover over a long rear deck.
- Tall, nearly vertical tail with a full-width ducktail lip (Z51). A high wing is optional.
- Mesh corner vents, and quad tips in two pairs.

**Fractions of length from the nose**

| Point | Fraction |
|---|---|
| Front axle | 0.18 |
| Windscreen base (centre) | 0.29 |
| Windscreen header | 0.42 |
| **Roof peak** | **0.50** (roof 1.234 m [F]) |
| Roof end / engine-cover start | 0.59 |
| Rear axle | 0.77 |
| Spoiler lip | 0.98 |

- Uncertainty: ±0.03 for the axles, ±0.05 for the glass and roof points.
- Check: the wheelbase fraction comes out at 0.595 against a true 0.588.
- Method: points read from the two 3/4 photos and averaged, so their opposite perspective errors partly cancel.

**Heights [E, ±10%]:** nose leading edge about 0.45 m; hood front edge about 0.68 m; side-intake top about 0.85 m; rear deck at the spoiler about 1.10 m.

## Model-year changes

| Year | Change |
|---|---|
| 2020 | Launch. |
| 2021 | Magnetic Ride available without Z51; Z51 rises to $5,995. |
| 2022 | LT2 fuel pump and injectors upgraded; GTLM edition. Borla labels the valves AFM for 2020–21 and DFM for 2022–27 (unconfirmed). |
| 2023 | 70th Anniversary package. |
| 2024 | High wing available on the Stingray; EU cars with particulate filters. |
| 2025 | Price and colour changes. |
| 2026 | New interior (14 in cluster, 12.7 in centre screen). |
| **2027** | **LS6 6.7 L replaces the LT2**: 535 hp @ 6,100 rpm, 520 lb-ft (705 Nm) @ 4,600 rpm, 13.0:1, 100 mm stroke, 95 mm throttle, Tri-Y manifolds, optional centre exhaust, redline reported at 6,600 rpm. Magazine test: 3,702 lb, 0–60 2.7 s, ¼ mile 11.0 s @ 124 mph, 53 / 96 / 73 dBA. |

Sources: S10, S33, S34, S17. The LS6 curve from the same GM chart is in the JSON.

## Gaps

- **Aero:** GM's Cd and frontal area are unknown; the game uses a CdA fitted to top speed.
- **eLSD:** calibration not found.
- **Engine speeds:**
  - idle rpm (warm and cold);
  - park/neutral rev limit;
  - limiter bounce;
  - the EU stationary-test rpm (estimated at 3,750).
- **Chassis details:**
  - lock-to-lock turns;
  - lift time;
  - wheel offsets;
  - GM ground clearance;
  - run-flat status.
- **Exhaust:** stock pipe sizes; whether base cars have iron manifolds.
- **Unread test sheets:**
  - C/D's own sheet (0–100, 0–130, 100–0, sound) could not be read directly;
  - Motor Trend's figure-eight, 0–100 and weight were not obtained.
- **Photos and audio:** no orthographic side drawing; no recording downloaded (HTTP 429).
- **Access problems:**
  - GM media sites returned 403, so GM figures come from faithful reproductions;
  - caranddriver.com is blocked for the fetch tool;
  - the web-search budget ran out at the end, so the Australian noise recall and further reviewer quotes were not gathered.

## Sources

- S01 GM preliminary specs, reproduced by Corvette Story: https://mobile.corvettestory.com/2020-Corvette-C8-mid-engine-specs.php
- S02 Corvsport 2020 specifications: https://www.corvsport.com/2020-corvette-specifications/
- S03 GM release "Chevrolet Confirms 2020 Stingray Quickest in its History", via CorvetteBlogger, 6 Nov 2019: https://www.corvetteblogger.com/2019/11/06/official-the-2020-corvette-stingray-goes-0-60-mph-in-2-9-seconds-runs-quarter-mile-in-11-2-121-mph/
- S04 SAE Mobility Engineering, "Inside Tremec's Corvette DCT": https://www.mobilityengineeringtech.com/component/content/article/40895-sae-ma-00017
- S05 Corvette Magazine, "Two Clutches, No Waiting": https://www.corvette-mag.com/issues/135/articles/two-clutches-no-waiting
- S06 Tremec/GM TR-9080 release (Corvette Action Center; seen via search summary): https://corvetteactioncenter.com/specs/c8-corvette/2020-corvette/press-release-2020-corvette-tremec-8-speed-dual-clutch-transmission.html
- S07 Corvette Magazine, "Inside the LT2": https://corvette-mag.com/issues/134/articles/inside-the-lt2
- S08 EngineLabs, LT2: https://www.enginelabs.com/engine-tech/the-new-2020-corvette-lt2-engine-more-of-the-same-but-different/
- S09 LSX Mag, "411 on LT2": https://www.lsxmag.com/news/411-on-lt2-everything-you-want-to-know-about-c8s-powerhouse/
- S10 Wikipedia, Chevrolet Corvette (C8): https://en.wikipedia.org/wiki/Chevrolet_Corvette_(C8)
- S11 Wikipedia, GM small-block engine: https://en.wikipedia.org/wiki/General_Motors_small-block_engine
- S12 GM slide "LT2 vs LS6 engine performance comparison" (via The Autopian): https://images-stag.jazelc.com/uploads/theautopian-m2en/ls6-performance-e1774532266852.png ; article: https://www.theautopian.com/chevy-is-bringing-back-the-ls-v8-and-this-time-its-a-6-7-liter-lump-of-american-muscle/
- S13 Car and Driver, Ceppos, 15 Oct 2019: https://uk.news.yahoo.com/2020-chevrolet-corvette-more-best-143100266.html
- S14 Car and Driver, Mortimer, 15 Oct 2019: https://uk.news.yahoo.com/2020-chevy-corvette-hits-60-203000416.html
- S15 Car and Driver, Colwell, 2 Sept 2020: https://uk.news.yahoo.com/tested-2020-chevrolet-corvette-z51-163800417.html
- S16 MidEngineCorvetteForum (C/D Dec 2019 sound levels): https://www.midenginecorvetteforum.com/forum/me-discussion-photos-videos/97277-noise-level
- S17 SSBCrack, 2027 vs 2020 comparison: https://news.ssbcrack.com/2027-chevrolet-corvette-stingray-performance-review-and-comparison-with-2020-model/
- S18 Motor Trend test, via CorvetteBlogger: https://www.corvetteblogger.com/2019/10/15/motor-trend-2020-corvette-stingray-z51-runs-0-60-in-2-8-seconds-quarter-mile-in-11-1-123-2-mph/
- S19 auto motor und sport technical data: https://www.auto-motor-und-sport.de/test/chevrolet-corvette-stingray-unterwegs-im-495-ps-starken-v8/technische-daten/
- S20 ADAC Autokatalog: https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/chevrolet/corvette/c8/341293/
- S21 Chevrolet Europe launch (Motorsactu): https://motorsactu.com/la-chevrolet-corvette-stingray-enfin-prete-pour-leurope
- S22 Top speed and Z51 downforce (Motor Authority): https://www.motorauthority.com/news/1124601_2020-chevy-corvette-stingray-s-top-speed-is-194-mph-but-z51-is-slower
- S23 SAE Mobility Engineering, "An Exhaust Symphony in the Key of C8": https://www.mobilityengineeringtech.com/component/content/article/44640-sae-ma-03960
- S24 CorvetteBlogger, Tenneco exhaust: https://www.corvetteblogger.com/2020/03/16/tennecos-c8-corvette-exhaust-system-detailed/
- S25 Corvette Forum, AFM and NPP valves: https://www.corvetteforum.com/forums/c8-tech-performance/4953174-afm-and-npp-valves.html
- S26 Corvette Forum, NPP usage and cold start: https://www.corvetteforum.com/forums/c8-stingray-general-discussion/4605453-npp-usage.html
- S27 Corvette Forum, limiter: https://www.corvetteforum.com/forums/c8-tech-performance/4681888-limiter.html
- S28 Corvette Forum, stock dyno numbers: https://www.corvetteforum.com/forums/c8-tech-performance/4614246-dyno-numbers-are-in.html
- S29 Z51 front rotor 345 × 30 mm (Paragon/EBC): https://www.paragonperf.com/ebc-c8-corvette-stingray-z51-front-2pc-rotors.html
- S30 Corvette Forum, drag coefficients: https://www.corvetteforum.com/forums/c8-tech-performance/4338961-drag-coefficients.html
- S31 Autoblog, 1LT coupe specs: https://www.autoblog.com/buy/2020-Chevrolet-Corvette-Stingray_w_1LT__2dr_Coupe/specs
- S32 GM Authority, leaked GM document: https://gmauthority.com/blog/2019/08/2020-corvette-stingray-performance-figures-leaked-from-alleged-gm-document/
- S33 Chevrolet newsroom, 2027 V8 deep dive: https://news.chevrolet.com/newsroom.detail.html/Pages/topic/us/en/2026/mar/0326-Deep-dive-2027-Chevrolet-Corvettes-next-generation-V8.html
- S34 The Drive, LS6: https://www.thedrive.com/news/chevys-new-ls6-gives-2027-corvette-more-torque-than-any-factory-na-v8-ever
- S35 CorvetteBlogger, exhaust comparison video: https://www.corvetteblogger.com/2020/07/10/video-comparison-of-the-2020-corvettes-two-different-exhaust-systems/
- S36 Wikimedia Commons C8 category (photos above): https://commons.wikimedia.org/wiki/Category:Chevrolet_Corvette_C8
- S37 Commons audio search: https://commons.wikimedia.org/w/index.php?search=corvette+filetype%3Aaudio&title=Special:MediaSearch&type=audio
- S38 YouTube videos listed above
- S39 Paragon dyno, LS6 vs stock Stingray: https://www.corvsport.com/video-paragon-performance-tests-the-2026-corvette-grand-sports-new-6-7l-ls6-v8/
- S40 Borla C8 exhaust notes: https://www.borla.com/chevrolet-corvette-stingray-c8-exhaust-systems
- S41 Z51 at 191.7 mph (CorvetteBlogger, 22 Mar 2023): https://www.corvetteblogger.com/2023/03/22/video-c8-corvette-stingray-with-z51-runs-top-speed-of-191-7-mph-on-the-space-shuttles-runway/
