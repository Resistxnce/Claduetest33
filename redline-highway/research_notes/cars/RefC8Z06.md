# RefC8Z06: Chevrolet Corvette Z06 coupe (C8, 2023 onward)

*Engineering reference only. The game car gets a fictional name. Machine-readable twin:
`research_notes/cars/RefC8Z06.json`. Researched 2026-11-13.*

Tags: **F** manufacturer, **P** published third-party spec, **M** measured test, **E** estimate (method
given), **A** assumption. Source ids such as [S01] are listed at the end.

**Main spec:** base Z06 coupe, US market, without the Z07 package. **Variant:** the Z07 package.

## Was the brief right?

| Belief | Verdict |
|---|---|
| LT6, 5.5 L naturally aspirated DOHC flat-plane V8, 670 hp at 8,400 rpm, redline 8,600 | **Confirmed.** 670 hp (500 kW) at 8,400 and 460 lb-ft (624 Nm) at 6,300 are US SAE J1349 ratings [F, S01, S02]. Some spec pages wrongly print "6.2 L" or put peak power at 8,600. Export cars are rated 475 kW (646 PS) at 8,550 rpm. |
| Tremec 8-speed dual-clutch with a shorter final drive than the Stingray | **Confirmed.** Tremec TR-9080. The eight ratios are the Stingray's. Final drive is 5.56, against 5.17 on the Stingray Z51 (eLSD) and 4.89 on the base Stingray (mechanical LSD) [S02, S10]. |
| Base Z06 as the main spec, Z07 as a variant | **Adopted.** The base car has Pilot Sport 4S ZP tyres, iron Brembos and standard aero. The Z07 adds Cup 2 R ZP tyres, carbon-ceramic brakes, 734 lb of downforce at 186 mph and the FE7 chassis, and its top speed drops to 189 mph. |

## Identity

| Item | Value | Tag | Source |
|---|---|---|---|
| Model | Corvette Z06, C8 (eighth generation), mid-engine | F | S02 |
| Bodies | Coupe with removable roof panel (main spec); hardtop convertible | F | S02 |
| Trims | 1LZ, 2LZ, 3LZ (equipment only) | F | S02 |
| Options | Z07 package; Carbon Aero package; carbon-fibre wheels; carbon-ceramic brakes; front lift | P | S02, S06, S16 |
| Revealed / years | 2021-10-26; model year 2023 onward, built from 2022 | F/P | S02 |
| Plant | Bowling Green, Kentucky; engines hand-built there | P | S02, S07 |
| Base price | $105,300 (MY2023), $108,100 (MY2024); Z07 about +$8,995 | P | S02, S31 |
| US/Canada rating | 670 hp at 8,400 rpm; 460 lb-ft at 6,300 rpm (SAE J1349) | F | S01, S02 |
| Export rating (EU, UK, Japan, AU, NZ) | 475 kW (646 PS) at 8,550 rpm; 595 Nm at 6,300 rpm (Japan's catalogue says 623 Nm) | P | S20, S21, S22 |
| Right-hand drive | Built for UK, Japan, Australia and New Zealand | P | S20, S22 |

## Engine (LT6)

| Item | Value | Tag | Source |
|---|---|---|---|
| Layout | 90° V8, longitudinal, mid-mounted ahead of the transaxle | F | S02 |
| Crank | Flat-plane (180°) forged steel; four-bolt mains; fluid damper; no balance shafts | P | S07 |
| Displacement | 5.5 L nominal; 5,463 cc computed from bore and stroke | F/P | S02, S07 |
| Bore × stroke | 104.25 × 80.0 mm (4.104 × 3.150 in); bore/stroke 1.30; bore spacing 4.40 in | P | S07, S06, S02 |
| Compression | 12.5:1; 58.8 cc combustion chamber | P | S07 |
| Valvetrain | DOHC, 32 valves; finger followers on solid lifters with robot-selected shims; nested dual springs | P | S07 |
| Valves | 42 mm titanium intake; 35 mm sodium-filled exhaust | P | S07 |
| Cam phasing | About 55° intake and 25° exhaust; no variable lift | P | S07 |
| Rods / pistons | Forged titanium rods; forged aluminium pistons with oil squirters | P | S02, S07 |
| Fuel | Direct injection up to 350 bar; premium fuel | P | S06 |
| Intake | Two moulded-nylon plenums of 5.5 L each, one 87 mm throttle body per plenum, three "communicator" valves between the plenums (two paired, one independent) tuning Helmholtz resonance. Motor1 (citing SAE): two valves closed until 2,000 rpm, the third opens at 5,800 rpm. | P | S08, S09 |
| Lubrication | Six-stage dry sump scavenging each crank bay; about 10 qt (another source says 8 qt); 5W-50 | P | S02, S06 |
| Max power | 500 kW (670 hp) at 8,400 rpm | F | S01, S02 |
| Max torque | 624 Nm (460 lb-ft) at 6,300 rpm | F | S01, S02 |
| Redline | 8,600 rpm, also shown on the tachometer in Chevrolet's teaser | F | S02, S33 |
| Limiter | Fuel cut at 8,600 rpm; full-throttle upshifts complete at about 8,500 | P | S19 |
| Limiter bounce | About 150 rpm | E | typical fuel-cut behaviour |
| Idle | About 900 rpm warm, about 1,500 rpm cold-start flare | E | not published; reviewers call the idle "ragged" |
| Launch control | Default 4,500 rpm, driver-adjustable from 3,500 to 5,000 rpm, with adjustable slip | P | S23 |
| Engine inertia | 0.14 kg·m² | E | light flat-plane V8 (the V12 prototype uses 0.20) |

### Firing order, bank numbering and the flat-plane crank

- **Firing order: 1-4-3-8-7-6-5-2** [P, S12, S06]. Firing-order references and a Corvette spec guide
  agree on this order. It was not seen in a GM document.
- **Numbering (GM convention) [A].**
  - Odd cylinders **1-3-5-7** are on the **left bank**, numbered front to rear. That is the driver's
    side of a left-hand-drive car, which GM calls "bank 1".
  - Even cylinders **2-4-6-8** are on the **right bank**.
  - In the C8 the engine's front (accessory drive) faces forward toward the cabin. So cylinder 1 is
    the left-bank cylinder nearest the cabin, and 7 and 8 sit next to the transaxle.
  - Applying GM's front-engine convention to the mid-mounted LT6 is the assumption here.
- **Bank sequence [E, derived]:** 1L, 4R, 3L, 8R, 7L, 6R, 5L, 2R.
  - The banks strictly alternate, one firing every 90° of crank rotation.
  - The left bank fires 1-3-7-5 and the right bank 4-8-6-2. Both follow the inline-four pattern
    1-2-4-3 by position, **one firing every 180° on each bank**.
  - A cross-plane V8 instead gives each bank uneven 90/180/270° gaps, which produces its burble.
- **Crank throws [E].** Each of the four throws carries one left and one right rod (1+2, 3+4, 5+6,
  7+8). Throws 1 and 4 are in phase, and throws 2 and 3 are at 180°. A timing check with a 90° V
  reproduces 1-4-3-8-7-6-5-2 exactly.
- **Frequencies [E].** Firing frequency is rpm ÷ 60 × 4: 60 Hz at a 900 rpm idle, 300 Hz at
  4,500 rpm, 560 Hz at 8,400 and 573 Hz at 8,600. Each bank carries half of that.

### Full-load torque curve (crank, SAE J1349 net, US engine)

**Read from a chart.** These values come from GM's slide "US LT6 SAE Torque and Power" [F, S01]
by pixel digitisation of the torque trace.
- The chart's own power trace, recomputed from torque, matches within 1-2 hp everywhere.
- The chart peaks read about 1% under the ratings (456 lb-ft vs 460; 666 hp vs 670). Multiply by
  1.006 to match the ratings.
- The chart begins at about 1,800 rpm. Values below that are estimates.

| rpm | Nm | lb-ft | kW | hp |
|---|---|---|---|---|
| 1,000 | ~340 (E) | | | |
| 1,500 | ~385 (E) | | | |
| 1,800 | 395 | 291 | 74 | 100 |
| 2,000 | 399 | 294 | 84 | 112 |
| 2,500 | 412 | 304 | 108 | 145 |
| 3,000 | 407 | 300 | 128 | 171 |
| 3,500 | 571 | 421 | 209 | 280 |
| 4,000 | 592 | 436 | 248 | 332 |
| 4,500 | 601 | 443 | 283 | 380 |
| 5,000 | 602 | 444 | 315 | 423 |
| 5,500 | 605 | 446 | 348 | 467 |
| 6,000 | 608 | 448 | 382 | 512 |
| 6,300 | 618 | 456 | 408 | 547 |
| 6,500 | 610 | 450 | 415 | 557 |
| 7,000 | 598 | 441 | 439 | 588 |
| 7,500 | 590 | 435 | 464 | 622 |
| 8,000 | 578 | 427 | 485 | 650 |
| 8,400 | 565 | 417 | 497 | 667 |
| 8,500 | 556 | 410 | 495 | 664 |
| 8,600 | 547 | 403 | 492 | 660 |

**Shape of the curve:**
- It is nearly flat at about 400-410 Nm up to 3,000 rpm, with a small dip at 2,800-3,000.
- It jumps by about 165 Nm between 3,000 and 3,600 rpm. This is the intake resonance step.
- There is a local peak at 3,800 (600 Nm), a dip at 4,200 (580 Nm), then a plateau of about
  600-608 Nm from 4,500 to 6,000.
- It peaks at 6,300-6,400 and falls gently to 547 Nm at 8,600.

**Wheel dyno [M, S25]:** Hennessey's stock car made 600.4 whp at 8,340 rpm and 406.6 lb-ft at
6,730 rpm. Other stock runs made 597-611 whp. That implies about 90% driveline efficiency.

## Transmission and drivetrain

| Item | Value | Tag | Source |
|---|---|---|---|
| Gearbox | Tremec TR-9080 8-speed dual-clutch transaxle (GM M1L). Concentric wet clutches (5 plates odd, 6 plates even); 5 triple-cone synchros | F/P | S02, S10 |
| Ratios 1-8 | 2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33 | P | S04, S05, S11 |
| Reverse | 2.63 | P | S04, S05 |
| Final drive | 5.56 | F | S02, S04 |
| Final drive build-up | About 1.566 transfer × 3.55 ring and pinion (Tremec's common ring and pinion); tooth counts unknown | E | S11 |
| Overall ratios | 16.18, 9.79, 6.78, 4.89, 3.61, 2.84, 2.22, 1.84; reverse 14.62 | E | arithmetic |
| Speed at 8,600 rpm | 69, 114, 165, 229, 310 km/h in gears 1-5 (43, 71, 102, 142, 192 mph); 6-8 are taller than top speed | E | 0.345 m rear rolling radius |
| Owner's manual limits | 1st up to 41 mph; 2nd 9-69 mph; 5th from 29 mph; 6→5 downshift up to 188 mph | P | S18 |
| 70 mph in 8th | About 1,590 rpm (7th: about 1,930) | E | arithmetic |
| Shift time | About 100 ms clutch overlap, no torque gap (Stingray unit; Z06 figure not published) | P | S10 |
| Torque rating | 800 Nm input to 7,500 rpm for the original unit; Z06 changes for 8,600 rpm not published | P | S10 |
| Efficiency | 0.90 crank-to-wheel | E | from the dyno (S25) |
| Differential | Electronic limited-slip, standard on every Z06 | F | S02 |
| Game diff approximation | Preload 100 Nm, power lock 0.45, coast lock 0.30 | E | tune in testing |

**Cross-checks on the ratios:**
- 2.91 ÷ 0.33 gives the published 8.8:1 spread.
- The owner's-manual downshift limits sit at about 8,200-8,400 rpm on these ratios.
- 5th runs out at about 192 mph, and the top speed (195 mph) comes in 6th at about 6,850 rpm.

## Mass

| Item | Value | Tag | Source |
|---|---|---|---|
| GM dry weight, Z07 coupe with carbon wheels | 1,558 kg (3,434 lb); Driven NZ prints 1,561 kg; another guide prints 3,500 lb | P | S04, S05, S22 |
| C/D measured, Z07 coupe | 1,663 kg (3,666 lb) | M | S13 |
| C/D measured, convertible | 1,723 kg (3,799 lb) | M | S13 |
| MT: coupe vs convertible | Coupe 88 lb (40 kg) lighter | M | S16 |
| Japan catalogue, 3LZ coupe | 1,720 kg | P | S20 |
| **Base coupe curb (game)** | **1,680 kg** (range 1,665-1,695) | E | C/D Z07 car, plus iron brakes, minus Z07 aero, plus aluminium wheels if the test car had carbon ones |
| **Simulated mass** | **1,755 kg** (with 75 kg driver) | E | prototype convention |
| Weight distribution | About 40% front / 60% rear | P | S26 (Stingray official: 39.4/60.6, S05) |
| Centre of mass height | 0.44 m | E | low mid-engine coupe |

## Dimensions (base coupe)

| Item | Value | Tag | Source |
|---|---|---|---|
| Length | 4,689 mm (184.6 in). Japan: 4,685 mm. With carbon ground effects or the Z07 splitter: 4,722 mm | P | S04, S05, S06, S20 |
| Width | 2,024 mm without mirrors (79.7 in), about 91 mm wider than the Stingray | P | S04, S05 |
| Height | 1,234 mm (48.6 in). Japan: 1,225 mm | P | S04, S20 |
| Wheelbase | 2,723 mm (107.2 in) | P | S02, S04 |
| Track front / rear | 1,684 / 1,679 mm (66.3 / 66.1 in). Stingray: 1,648 / 1,585 mm | P | S04, S05, S06 |
| Overhangs front / rear | About 960 / 1,006 mm | E | measured from photo S29a |
| Ground clearance | About 100 mm; front lift about +50 mm | E/A | not published |
| Frontal area | About 2.10 m² | E | 2.024 × 1.234 × 0.84 |
| Fuel tank | 70 L (18.5 gal) | P | S04, S20 |

## Tyres and wheels

| Item | Base Z06 | Z07 | Tag | Source |
|---|---|---|---|---|
| Front | 275/30ZR20 on 20×10 in | same | F/P | S02, S06 |
| Rear | 345/25ZR21 on 21×13 in | same | F/P | S02, S06 |
| Tyre | Michelin Pilot Sport 4S ZP (run-flat) | Michelin Pilot Sport Cup 2 R ZP | P/F | S06, S16, S02 |
| Wheels | Forged aluminium, 5×120 mm; optional Carbon Revolution carbon, −41 lb total | often carbon | P | S02, S06 |
| Diameter | 673 mm front, 706 mm rear | | E | computed |
| Rolling radius | 0.330 m front, 0.345 m rear | | E | |
| Grip for the game | 1.40 longitudinal / 1.18 lateral | 1.50 / 1.25 | E | tests: 1.10-1.12 g (PS4S), 1.16 g (Cup 2 R) |

## Brakes

| Item | Value | Tag | Source |
|---|---|---|---|
| Base system | Brembo iron discs; 6-piston monobloc front, 4-piston monobloc rear; eBoost booster | P | S05, S06 |
| Base discs | 370 × 34 mm front, 380 × 34 mm rear (the rear disc is larger) | P | S05, S06 |
| Carbon-ceramic (standard with Z07) | 398 × 38 mm front, 390 × 34 mm rear | P | S04, S05 |
| C/D, Z07 coupe | 70-0 mph 139 ft (42.4 m, 1.18 g average); 100-0 mph 274 ft (83.5 m, 1.22 g) | M | S13 |
| C/D, convertible | 70-0 144 ft (43.9 m); 100-0 282 ft (86.0 m) | M | S13 |
| MT, Z07 coupe | 60-0 mph 95 ft (29.0 m, 1.27 g) | M | S16 |
| Game torque | 3,000 Nm front and 2,000 Nm rear per wheel; about 60% front | E | locks the wheels near 1.3 g |

Spec-site errors: the inch sizes agree across sources. One table calls the base discs carbon-ceramic,
and another prints wrong millimetre conversions.

## Aero

| Item | Base Z06 | Z07 | Tag | Source |
|---|---|---|---|---|
| Downforce at 186 mph (300 km/h) | 365 lb / 1,624 N (362 lb in one wicker setup) | 734 lb / 3,265 N | P / F | S19, S02 |
| Lift area ClA | 0.39 m² | 0.78 m² | E | from the figures above |
| Drag area CdA | **0.92 m²** | **0.99 m²** | E | fitted to the top speeds (below) |
| Cd | Not published; about 0.44 implied (low confidence) | | E | |
| Aero balance | About 40% front | | E | not published |
| Parts | Splitter, stall Gurneys, spoiler with removable wicker | Bigger splitter, dive planes, strakes, pedestal wing | P | S02, S06 |

**How CdA was fitted.**
- Inputs: 195 mph reached in 6th at about 6,840 rpm, where GM's curve gives 577 hp; 0.90
  driveline efficiency; rolling resistance 0.013; air density 1.204 kg/m³; 1,755 kg. This gives a
  CdA of 0.92 m².
- The same method at 189 mph gives 0.99 m² for the Z07.
- GM's only drag statement compares the Z06 with the C7 ZR1: 6% more downforce at 8% less drag.

## Suspension and steering

| Item | Value | Tag | Source |
|---|---|---|---|
| Front / rear | Short/long-arm double wishbone, coil-over (A), 46 mm monotube dampers | P | S04, S06 |
| Dampers | Magnetic Selective Ride Control 4.0, standard | F | S02 |
| Z07 | FE7 calibration: stiffer springs, retuned dampers | P | S02, S06 |
| Front lift | Optional, about +50 mm | A | |
| Ride frequencies | Base 1.9 Hz front / 2.1 Hz rear; Z07 2.2 / 2.4 Hz | E | tune in testing |
| Steering | Variable-ratio electric rack, 15.7:1 | P | S04, S06 |
| Lock-to-lock | About 2.6 turns | E | from turning circle and ratio |
| Turning circle | 11.6 m (38 ft) | P | S06 |
| Max road-wheel angle | About 29° outer, 40° inner | E | geometry |

## Performance

**Factory claims [F]:**
- 0-60 mph in **2.6 s** with Z07 [S02].
- Quarter mile in **10.6 s**, GM preliminary [S04].
- Top speed **195 mph (314 km/h)** for the base car, per Tadge Juechter [S17].
- Top speed **189 mph (304 km/h)** with Z07, per Josh Holder [S17].
- 1.22 g lateral in track configuration [S02].
- Nürburgring lap of 7:11.826 [P, S02; not checked].

**Magazine tests [M]:**

| Test | C/D Z07 coupe (Nov 2022) [S13] | C/D convertible [S13] | MT Z07 coupe (2022-11-18) [S16] | MT convertible, PS4S [S16] |
|---|---|---|---|---|
| Weight | 3,666 lb | 3,799 lb | coupe 88 lb lighter than convertible | |
| 0-60 mph | 2.6 s | 2.7 s | not obtained | about 0.2 s quicker than coupe in the quarter |
| 0-100 / 0-150 mph | 5.9 / 15.2 s | 6.1 / 16.3 s | | |
| ¼ mile | 10.5 s @ 131 mph | 10.7 s @ 129 mph | | trap 3.4 mph faster than coupe |
| Rolling 5-60 mph | 3.1 s | 3.1 s | | |
| Top gear 30-50 / 50-70 mph | 2.0 / 2.2 s | 2.0 / 2.2 s | | |
| Braking | 70-0: 139 ft; 100-0: 274 ft | 144 / 282 ft | 60-0: 95 ft | about 99 ft (derived) |
| Skidpad | 1.16 g (300 ft) | 1.12 g | 1.16 g (200 ft) | 1.10 g |
| Figure eight | | | 21.85 s @ 0.99 g | 22.70 s @ 0.93 g |
| Interior sound, full throttle | 94 dBA | 96 dBA | | |

Other measured figures:
- C/D 0-150-0 mph: 22.5 s [S06].
- Hennessey wheel dyno: 600 whp [S25].

**Suggested game targets [E]:** 0-100 km/h about 2.8 s, quarter mile 10.6 s, top speed 314 km/h
in 6th.

## Sound (for the audio engineer)

**Character.**
- On the flat-plane crank, each bank fires every 180°, an even pulse train like an inline-four. The
  banks alternate every 90°.
- The result is a clean, high-pitched shriek with little low-order burble.
- The dominant pitch is firing frequency (order 4): 60 Hz at idle, 300 Hz at 4,500 rpm and
  573 Hz at the limiter.
- Induction noise is strong because the twin 87 mm throttle bodies and split plenum sit right
  behind the cabin.

### Exhaust layout

| Part | What is known | Tag | Source |
|---|---|---|---|
| Headers | Stainless 4-2-1 headers per bank, chosen with the flat-plane layout for high-rpm scavenging | F | S02, S07 |
| Header pairing | Likely 1+7 and 3+5 on the left, 2+8 and 4+6 on the right. Each secondary pairs cylinders 360° apart, so each bank collector sees one pulse every 180° | E | standard practice; not published |
| Bank crossover | Not published. Aftermarket cat-backs advertise adding an X-pipe, which hints that the factory system has none | E | S24 |
| Catalysts | Not published; assumed one per bank after the collectors | A | |
| Mufflers and valves | Valved active exhaust; valves move in 2° steps. Four modes: Weather (quietest), Tour, Sport, Track (all valves open). Intake manifold valves also change the sound | F | S24 |
| Tips | Centre exit: four round tips in one horizontal row inside a single bezel in the diffuser. Chevrolet says the bezels reflect sound up to the cockpit; The Drive mentions reverse-trumpet shapes to raise cabin exhaust noise | P | S24, S29b, S07 |

### Measured levels

| Measurement | Value | Tag | Source |
|---|---|---|---|
| C/D interior, full throttle, coupe | **94 dBA** | M | S14 |
| C/D interior, full throttle, convertible | **96 dBA** | M | S14 |
| C/D interior, idle | not obtained; estimate about 58 dBA (55-62) | E | gap |
| C/D interior, 70 mph | not obtained; estimate about 72 dBA on PS4S, 75 dBA on Cup 2 R (C/D notes heavy Cup 2 R road noise) | E | gap |
| Owner measurement, stock exhaust | 92 dBA inside, 102 dBA outside; method unknown | M (low confidence) | S28 |
| Stationary or pass-by test | none found | | gap |

### Limiter, shifts and overrun

- **Limiter [P/E].**
  - Hard fuel cut at 8,600 rpm [S19].
  - At full throttle the gearbox completes upshifts at about 8,500, so the limiter is mostly heard
    in manual mode.
  - Expect a fast bounce of about 150 rpm (E).
- **Upshifts [E].** About 100 ms clutch overlap with no torque gap, heard as a brief dip in the
  note rather than an ignition-cut crack.
- **Downshifts [P].** Rev-matched blips: "Whumm, whumm, whumm!!!" (Motor Authority) [S19].
- **Overrun [E].** No source describes pops or crackles. Expect clean overrun with a light crackle
  at most in Sport/Track.

### Reviewer descriptions

- "Wide open, it sounds like a Ferrari 458 Italia that hit puberty." (Car and Driver, Z06
  convertible test) [S15]
- "The intake sound reminds us of the sounds of our youth and draws in our adult selves like a
  siren song." (KC Colwell, Car and Driver, as quoted in a review roundup) [S27]
- "...it can sound rather ordinary when it's not in the zone" (evo) [S27]
- "an incredible, wailing soundtrack" (David Linklater, Driven NZ, Feb 2025) [S22]
- "the flat-plane crank V8 doesn't sound that great at low speed" (same review) [S22]
- "perfectly timed pulses of exhaust gasses" (Rob Stumpf, Popular Science, Oct 2021) [S27]
- "has its own unique tone, especially as it reaches its 8,600 rpm redline" (The Drive) [S32]

### Reference videos (links only)

- Chevrolet "Corvette Academy" exhaust valves and modes explainer: https://youtu.be/MoCSoUsbPnU
- Chevrolet reveal teaser, with the tachometer to 8,600 rpm: https://www.youtube.com/watch?v=0I2EiacT0qQ
- Hennessey stock dyno pulls to the limiter (exterior): https://www.youtube.com/watch?v=wjT01oF9P94
- Onboard lap at Laguna Seca (via The Drive): https://www.youtube.com/watch?v=_MQjow-dJZE
- Start-up, long idle, blips and pull-away of a Z07 coupe: https://www.youtube.com/watch?v=_ptTKhdNgXw
- Chevrolet B-roll at Pitt Raceway, with pull-aways and passes: https://www.youtube.com/watch?v=A4MrwpXmKbE
- SavageGeese review, with driving sound: https://www.youtube.com/watch?v=hJP6oXfZkFo

Not found: a clean exterior track fly-by of a stock car, and the anechoic-chamber dyno clip that was
posted on social media before the reveal.

### Freely licensed recordings

- **No LT6 recording** is on Wikimedia Commons. The Commons "Corvette Z06" sound file is a 2011 C6
  with the LS7 cross-plane engine, which is useful only as a contrast.
- **Flat-plane analogues are listed with licences and URLs** in
  `research_notes/cars/audio/RefC8Z06/LICENCES.txt`:
  - Shelby GT350 Voodoo 5.2 (closest analogue), CC BY 3.0
  - Ferrari 458 Italia, CC BY-SA 3.0
  - Ferrari F430 Spider, CC BY 3.0
  - Ferrari 458 Speciale with aftermarket exhaust, CC BY 3.0
- **None were downloaded.** Wikimedia answered HTTP 429 for every original-file download from this
  session.

## Visual blockout

**Photos used (all freely licensed, viewed):**
- [S29a] White Z06 coupe in near-side profile, by Xnatedawgx, CC BY-SA 4.0:
  https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Z06_C8,_white,_Golden_Super_Cruise_2026-07-04.jpg
- [S29c] White Z06 with the roof open in side profile, used as a cross-check. By Charles from Port
  Chester, CC0:
  https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_Z06_Coup%C3%A9_(C8,_2023)_(54802404220).jpg
- [S29b] Orange Z06 with the Z07 wing, rear three-quarter view, showing the tips. By John Bauld,
  CC BY 2.0: https://commons.wikimedia.org/wiki/File:Corvette_Z06_(52695148134).jpg

**Method.**
- The side photo was measured in pixels, with the scale taken from the wheelbase between the wheel
  centres.
- The overhangs were scaled to the published length, because the photo's perspective shrinks the
  ends.
- Accuracy is about ±3-5% of length.

| Feature | Fraction of length from the nose (E) | Height (E) |
|---|---|---|
| Nose leading edge | 0.00 | about 0.45 m; splitter lip about 0.10 m |
| Front axle | 0.205 | front fender top about 0.71 m |
| Windscreen base (cowl) | 0.27 | about 0.80 m |
| Windscreen top / roof front | 0.41 | about 1.20 m |
| Roof peak | 0.46 | 1.234 m (published height) |
| Roof rear end | 0.57 | about 1.19 m |
| Side intake (start to end) | 0.51-0.66 | |
| Rear axle | 0.785 | |
| Tail | 1.00 | spoiler lip about 1.05 m; Z07 wing top about 1.20 m |

Beltline at the door is about 0.81 m.

**Shapes.**
- **Nose:** a low, sharp wedge with a pointed centre and a wide splitter. The Z06 fascia has large
  outboard intakes. A short bonnet rises steeply to the cowl.
- **Cabin:** cab-forward, with a steeply raked windscreen, a short flat roof, and flying-buttress
  sail panels running back to the deck.
- **Rear:** a small upright window between the buttresses over the engine, then a long, nearly
  flat deck. The tail is high and square-cut, with thin horizontal lamps and an integrated ducktail
  (or the Z07's tall pedestal wing). The big diffuser carries the centre quad tips.
- **Sides:** a deep scoop runs from the door into a large intake ahead of the rear wheel, with
  strong rear haunches. The body is about 91 mm wider than the Stingray's.

## Variants

| Item | Base Z06 (main) | Z07 package | Convertible |
|---|---|---|---|
| Tyres | Pilot Sport 4S ZP | Pilot Sport Cup 2 R ZP | as fitted |
| Brakes | Iron, 370 / 380 mm | Carbon-ceramic, 398 / 390 mm | as fitted |
| Downforce at 186 mph | 365 lb | 734 lb | |
| CdA (E) | 0.92 m² | 0.99 m² | |
| Chassis | Magnetic Ride | FE7 calibration | |
| Top speed | 195 mph / 314 km/h | 189 mph / 304 km/h | |
| Mass | 1,680 kg (E) | C/D measured 1,663 kg | +40 kg vs coupe (MT) |
| Interior full throttle | | 94 dBA (coupe) | 96 dBA |

**Export spec:** 475 kW (646 PS) at 8,550 rpm and 595 Nm at 6,300 rpm. The Japanese catalogue
says 623 Nm.

## Gaps

1. GM press-kit pages (media.gm.com, news.gm.com) returned HTTP 403. GM figures came from Wikipedia
   and spec-site copies of GM's sheet; the copy errors are noted above.
2. Car and Driver's interior dBA at idle and at a 70-mph cruise were not obtained; there are
   estimates above. There is no exterior or pass-by figure beyond one owner's reading.
3. Cd and frontal area are unpublished. The fitted CdA is low-confidence. The front/rear downforce
   split is also unpublished.
4. There is no GM curb weight for the base coupe, and no measured Z06 weight split (40/60 is
   approximate).
5. Not published:
   - ground clearance and front-lift height;
   - lock-to-lock turns;
   - idle rpm;
   - Z06-specific shift times and the gearbox changes for 8,600 rpm;
   - ring-and-pinion tooth counts.
6. Exhaust details are unpublished: catalysts, crossover, mufflers and header pairing. Overrun and
   limiter sound behaviour is not described anywhere.
7. The intake valve schedule is only partly published and doesn't obviously match the torque steps.
8. Motor Trend's 0-60 and quarter-mile figures were not obtained.
9. Export torque conflicts: 595 Nm vs 623 Nm.
10. No freely licensed LT6 recording exists on Commons, and the analogue downloads were rate-limited.
11. The team's shared web-search budget ran out before the remaining checks.
12. MY2027 changes were not researched.

## Sources

- [S01] Chevrolet LT6 SAE torque and power chart (Feb 2022), via Corvette Blogger:
  https://www.corvetteblogger.com/2022/02/18/pic-first-look-at-the-torque-and-power-of-the-2023-corvette-z06s-lt6-v8-engine/
  (chart image https://www.corvetteblogger.com/images/content/2022/021722_7.jpg)
- [S02] Wikipedia, Chevrolet Corvette (C8), which cites GM's 2021-10-26 release:
  https://en.wikipedia.org/wiki/Chevrolet_Corvette_(C8)
- [S03] GM press release (403 to automated reading):
  https://news.gm.com/home.detail.html/Pages/news/us/en/2021/oct/1026-corvette-z06.html
- [S04] Corvsport, 2023 Z06 specifications: https://www.corvsport.com/2023-corvette-z06-specifications/
- [S05] Corvettestory, 2024 specs: https://corvettestory.com/specs/2024-Corvette-specs-options.php
- [S06] Corvsport, 2025 Z06 in-depth guide: https://www.corvsport.com/2025-corvette-z06-in-depth-guide/
- [S07] The Drive, LT6 deep dive:
  https://www.thedrive.com/news/42901/2023-corvette-z06s-lt6-v8-everything-you-ever-wanted-to-know
- [S08] LSX Magazine, intake manifold design: https://www.lsxmag.com/?p=25093
- [S09] Motor1, LT6 intake: https://www.motor1.com/news/566963/chevy-corvette-z06-dohc-intake/
- [S10] SAE Mobility Engineering, Tremec DCT:
  https://www.mobilityengineeringtech.com/component/content/article/40895-sae-ma-00017
- [S11] Tremec TR-9080 data via search summary; see also
  https://www.autoevolution.com/news/a-look-at-the-corvette-c8-s-tremec-tr-9080-dct-transmission-and-how-it-works-152380.html
- [S12] Firing order: https://rerev.com/firing-orders/chevrolet/5-5l-lt6/ and
  https://www.aa1car.com/library/chevy_firing_orders.htm
- [S13] C/D test data, forum repost:
  https://canadiancorvetteforums.com/threads/car-and-driver-review-of-the-c8-z06-october-26-2022-best-corvette-ever.60646/latest
  (original https://www.caranddriver.com/reviews/a41411338/2023-chevrolet-corvette-z06-by-the-numbers/)
- [S14] C/D Z06 test, Yahoo syndication: https://autos.yahoo.com/tested-2023-corvette-z06-american-040000360.html
- [S15] C/D Z06 convertible test: https://autos.yahoo.com/tested-2023-chevrolet-corvette-z06-110000549.html
- [S16] Motor Trend first test, reposted by Tremec: https://tremec.com/?p=261
- [S17] Motor Authority, top speed: https://www.motorauthority.com/news/1137037_2023-chevrolet-corvette-z06-top-speed
- [S18] Corvette Blogger, owner's manual shift speeds:
  https://www.corvetteblogger.com/2022/05/17/2023-corvette-owners-manual-appears-to-confirm-that-the-z06-will-be-a-200-mph-super-car/
- [S19] Motor Authority review:
  https://www.motorauthority.com/news/1137351_review-2023-chevrolet-corvette-z06-heaps-exotic-sound-and-fury-on-an-exotic-design ;
  Motor1 first drive: https://www.motor1.com/reviews/613965/2023-chevrolet-corvette-z06-first-drive/
- [S20] Japanese catalogue: https://221616.com/catalog/chevrolet/chevroletcorvette/202001_299912/10155730/
- [S21] Chevrolet Europe: https://www.chevroleteurope.com/eu-en/corvette/z06
- [S22] Driven NZ review: https://www.drivencarguide.co.nz/reviews/chevrolet-corvette-z06-review-flat-chat/
- [S23] Corvette Blogger, launch control:
  https://www.corvetteblogger.com/2022/04/29/video-2023-corvette-z06-allows-drivers-to-customize-launch-control-rpm
- [S24] Motor1, exhaust explainer: https://www.motor1.com/news/593811/2023-corvette-z06-exhaust-note-video/ ;
  aftermarket X-pipe: https://fabspeed.com/fabspeed-chevrolet-corvette-c8-z06-valvetronic-cat-back-exhaust-system-2023
- [S25] Hennessey dyno:
  https://www.corvetteblogger.com/2023/10/18/video-watch-hennessey-dyno-its-stock-c8-corvette-z06-before-the-mods-begin/ ;
  https://www.motor1.com/news/692511/chevrolet-corvette-z06-dyno-results-hennessey/
- [S26] Weight split: https://www2.motorauthority.com/news/1137351_2023-chevrolet-corvette-z06-test-drive-review ;
  https://www.corvette-mag.com/issues/174/articles/driven-2024-z06
- [S27] Popular Science: https://www.popsci.com/technology/chevrolet-corvette-z06-review/ ;
  evo: https://www.evo.co.uk/corvette/z06
- [S28] Corvette Club UK owner measurement:
  https://www.corvetteclub.org.uk/threads/just-how-loud-is-a-c8-z06-exhaust.4339/
- [S29a, S29b, S29c] Wikimedia Commons photos (links above)
- [S31] Corvette Blogger, Laguna Seca, Z07 price:
  https://www.corvetteblogger.com/2022/08/31/video-more-2023-corvette-z06-on-track-action-from-laguna-seca/
- [S32] The Drive, Laguna Seca onboard:
  https://www.thedrive.com/news/ride-inside-a-2023-chevy-corvette-z06-as-it-rips-around-laguna-seca
- [S33] Corvette Blogger, Chevrolet teaser:
  https://www.corvetteblogger.com/2021/10/20/video-chevy-teases-the-2023-corvette-z06-reveal-tune-in/
- [S34] Corvette Blogger, idle video:
  https://www.corvetteblogger.com/2022/08/09/spied-nice-idle-sound-from-2023-corvette-z06-with-z07-in-amplify-orange/
- [S35] Corvette Blogger, Pitt Raceway B-roll:
  https://www.corvetteblogger.com/2022/10/04/video-b-roll-footage-of-the-2023-corvette-z06-at-pitt-raceway/

Several facts (S11, S14, S17-S19, S21, S23, S26, S27) were read through search-result summaries
because the pages themselves blocked automated reading (HTTP 403). Verify them before relying on
the exact wording.
