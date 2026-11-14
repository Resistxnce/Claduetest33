# RefM5F90: BMW M5 Competition (F90), engineering reference

*Research notes for the builder and the audio engineer. In the game this car gets a fictional
name; BMW names, logos and body design appear only here, as references. The machine-readable copy
of everything below is `RefM5F90.json` in this folder. Compiled 2026-11-13.*

Tags: **[F]** manufacturer figure, **[P]** published third-party spec (or BMW material for the sister
S63TU engine, as stated), **[M]** magazine or independent measurement, **[E]** estimate (method given),
**[A]** assumption.

The default target is the **LCI M5 Competition** (production 07/2020 to 06/2023, US MY2021-2023).
Pre-LCI Competition values (2018-2020) are listed where they differ.

## Checks on the brief

| Claim in the brief | Verdict |
|---|---|
| S63B44T4, 4.4 L twin-turbo hot-V V8, 617 hp / 625 PS | **Confirmed.** BMW NA lists "S63B44T4". 4,395 cc; 460 kW = 625 PS = 617 hp. The base M5 has 441 kW / 600 PS. |
| 8-speed M Steptronic torque-converter automatic | **Confirmed.** It is a ZF 8HP: GA8HP75Z pre-LCI (BMW parts catalogue, via Wikipedia) and "M8HP76" for the LCI (BMW NA). Ratios are the same. |
| M xDrive with 4WD / 4WD Sport / 2WD, Active M Differential | **Confirmed, with nuance.** There are five configurations. With DSC on the car is in 4WD. MDM uses 4WD Sport. With DSC off you can pick 4WD, 4WD Sport or 2WD, and 2WD only exists with DSC off. |
| (not in the brief) | **Corrections:** <br>• Compression is **10.0:1**, not 10.5. <br>• Final drive is **3.154**. auto motor und sport prints 2.93, which is wrong. <br>• Wikipedia's "0-100 in 3.1 s" is really BMW's US 0-60 mph claim; BMW's 0-100 km/h is **3.3 s**. <br>• Reverse ratio differs between BMW sheets: 3.478 (EU), 3.38 (US 2021), 4.172 (US 2017). |

## Identity

| Item | Value | Tag |
|---|---|---|
| Make / model / chassis | BMW (BMW M GmbH) M5 Competition, F90 (G30-based, CLAR) | F |
| Body / layout | 4-door, 5-seat saloon; front longitudinal V8, rear-biased AWD with selectable 2WD | F |
| Plant | Dingolfing, Germany | P |
| Competition launch | Revealed May 2018, press release 6 Aug 2018, US MY2019 | F |
| LCI | Revealed June 2020; production from 07/2020 (ADAC); market launch Aug 2020; US MY2021-2023; end 06/2023 (ams) | F/P |

**US vs EU differences:**
- **Power label:** 617 hp (US) vs 625 PS (EU). Same engine.
- **Top speed:** 155 mph, or 190 mph with the M Driver's Package (US) vs 250 / 305 km/h (EU).
- **Acceleration claim:** 0-60 mph in 3.1 s (US) vs 0-100 km/h in 3.3 s (EU).
- **Mass:** US curb weight 4,345 lb (1,971 kg) vs EU DIN 1,895 kg.
- **Particulate filter:** EU cars have one. US material doesn't mention one [A].
- **Data only BMW NA publishes:** a 54.4/45.6 weight distribution and Cd 0.31.

**What the LCI (2020) changed:**
- **Engine:** the torque plateau now ends at 5,860 rpm instead of 5,800.
- **Chassis:** new dampers and recalibrated damper control, carried over from the M8 Competition Gran Coupé.
- **Size and weight:** length 4,983 mm (was 4,966); DIN/EU weight 1,895/1,970 kg (was 1,865/1,940); CdA 0.77 m² (was 0.758).
- **Gearbox designation:** M8HP76 (was GA8HP75Z).
- **Controls and display:** M Mode button with ROAD/SPORT/TRACK (TRACK mutes the audio), a Setup button and a 12.3-inch display.
- **Styling:** new headlights, tail lamps and aprons; red calipers as standard; thinner black-chrome tips.
- **Emissions:** Euro 6d-TEMP-EVAP-ISC with a gasoline particulate filter.

Sources: [BMW spec 06/2020](https://press.bmwgroup.com/global/article/attachment/T0309233EN/452618),
[BMW spec 09/2018](https://press.bmwgroup.com/global/article/attachment/T0286586EN/419604),
[BMW M5 Competition release 2018](https://www.press.bmwgroup.com/global/article/attachment/T0280678EN/412670),
[BMW Ireland LCI release](https://www.press.bmwgroup.com/ireland/article/detail/T0309430EN/the-new-bmw-m5-competition),
[BMW NA 2021 press kit](https://newsroom.bmwgroup.com/americas/the-new-2021-bmw-m5-sedan/),
[ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/bmw/5er-reihe/g30-g31-f90-facelift/313219),
[Wikipedia BMW M5](https://en.wikipedia.org/wiki/BMW_M5).

## Engine

| Item | Value | Tag |
|---|---|---|
| Code | S63B44T4 (S63TU4) | F |
| Layout | 90° V8, hot-V (turbos and exhaust manifolds inside the V) | P |
| Crank | Cross-plane, forged steel, 5 main bearings, 6 counterweights (S63TU data, assumed carried over) | P |
| Displacement / bore / stroke | 4,395 cm³ / 89.0 mm / 88.3 mm | F |
| Compression | 10.0:1 | F |
| Valvetrain | DOHC, 4 valves, chain drive, VALVETRONIC variable lift, Double-VANOS | F |
| Injection | Direct, max 350 bar | F |
| Max power | 460 kW / 625 PS / 617 hp at 6,000 rpm | F |
| Max torque | 750 Nm / 553 lb-ft at 1,800-5,860 rpm (LCI); 1,800-5,800 (pre-LCI) | F |
| Redline / cut-off | 7,200 rpm (BMW NA, same engine in the M5 CS). BMW's chart ends at 7,200. The S63TU manual says "cutoff speed 7200 rpm". | F/P |
| Idle | about 600 rpm warm, 1,000-1,300 cold (not published) | E |
| Launch control | about 3,000 rpm, plausible range 2,500-3,500 (not published) | E |
| Engine mounts | 900 N/mm (Competition) vs about 580 N/mm (M5) | F |
| Oil | 10.0 L; small front sump chamber, map-controlled variable pump | F |
| Drive modes | EFFICIENT / SPORT / SPORT+ (throttle mapping and exhaust flaps) | F |

### Full-load torque curve (crank, read from BMW's chart)

BMW's 06/2020 "Output and torque diagrams" page in the specifications PDF is vector art. I took the
curve vertices from the drawing paths and mapped them to the grid. The power curve on the same
chart matches torque × rpm to within 0.5 kW, which confirms the reading.

| rpm | 1,000 | 1,500 | 2,000-5,500 | 6,000 | 6,500 | 7,000 | 7,200 |
|---|---|---|---|---|---|---|---|
| Torque, Nm | 400 | 600 | 750 | 732 | 662 | 587 | 564 |
| Power, kW | 42 | 94 | 157 → 432 | 460 | 450 | 430 | 425 |

- **Chart nodes:** 1,000/400, 1,244/480, 1,500/600, 1,791/749, 5,859/749, 6,000/732, 6,600/647, 7,000/587, 7,198/564.
- **Plateau end:** the chart's printed label says "1800-5800", but the plotted plateau ends at 5,859 rpm, which matches the LCI's 5,860.
- **Below 1,000 rpm (not on the chart):** about 300 Nm at 600 rpm and 350 Nm at 800 rpm [E].

### Firing order and cylinder numbering

These come from BMW's S63TU (F10 M5) training manual. The F90's cross-bank manifold depends on this
order, so they are near-certain carry-overs.

- **BMW numbering:** cylinder 1 is at the **front of the right bank** (right = passenger side of a
  left-hand-drive car, looking forward). The right bank is 1-2-3-4 front to rear; the left bank is
  5-6-7-8 front to rear.
- **Firing order:** **1-5-4-8-6-3-7-2**, evenly every 90°: 1 at 0°, 5 at 90°, 4 at 180°, 8 at 270°,
  6 at 360°, 3 at 450°, 7 at 540°, 2 at 630°.
- **Per-bank intervals are uneven (cross-plane):** 180-270-180-90° on the right bank and
  180-90-180-270° on the left.
- **Firing frequency:** rpm/60 × 4, i.e. 40 Hz at 600 rpm, 400 Hz at 6,000 and 480 Hz at 7,200.

## Forced induction

| Item | Value | Tag |
|---|---|---|
| Turbos | 2, twin-scroll ("M TwinScroll TwinTurbo"); new for the F90 | F |
| Maker / model | **Not found** | gap |
| Placement | In the V, one over each bank, turbines feeding close-coupled catalysts | P |
| Boost | 24.46 psi (1.69 bar) gauge, quoted for the 600 hp M5. The Competition is probably about 1.7-1.8 bar. | F / E |
| Boost onset / full boost | Onset about 1,000-1,200 rpm (400 Nm at 1,000 is about naturally-aspirated level). Full 750 Nm from 1,800 rpm. Tapered above 5,860 rpm. | E / F |
| Wastegate | One per turbo. Vacuum-actuated on the S63TU; the TU4's actuation is unconfirmed. | P |
| Blow-off valve | **None.** BMW: "does not use a blow-off valve. The use of Valvetronic and special tuning rendered it unnecessary." | P |
| Intercooling | Indirect water-to-air, about 20 % smaller than before | F |

**Cross-bank manifold** ([BMW S63TU manual](https://archive.org/download/BMWTechnicalTrainingDocuments/ST1202%20S63TU%20Engine/S63TU-engine-manual.pdf); the F90 keeps it, per BMW's spec sheets):
- **Turbo over the left bank:** fed by cylinders **1, 4, 6, 7**, with scrolls 1/6 (front) and 4/7 (rear).
  It gets pulses at 0, 180, 360 and 540°.
- **Turbo over the right bank:** fed by cylinders **2, 3, 5, 8**, with scrolls 2/8 (front) and 3/5 (rear).
  It gets pulses at 90, 270, 450 and 630°.
- **Result:** each turbo sees an even pulse every 180°, like an inline-4, and each scroll every 360°.
  BMW: "a spacing of 360° of crankshaft angle between the two exhaust cycles within the exhaust flute."

## Transmission and drivetrain

| Item | Value | Tag |
|---|---|---|
| Gearbox | ZF 8HP torque-converter automatic with Drivelogic (1 efficient, 2 sporty, 3 track), paddles, oil cooler | F/P |
| Ratios 1-8 | 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640 | F |
| Reverse | 3.478 (EU; US sheets 3.38 / 4.172) | F |
| Final drive | 3.154 (3.15 in BMW NA sheets and parts listings) | F |
| Transfer case | No reduction (1:1). Front tyres are about 1 % smaller than the rears. | A |
| Speed at 7,200 rpm | 59 / 92 / 138 / 172 / 225 / 295 / 359 / 461 km/h. 305 km/h comes in 7th at about 6,100 rpm. | E |
| Converter | Lock-up clutch "fully engages once the car has pulled away". Stall speed not published. | F |
| Shift behaviour | Multiple downshifts allowed; in manual there is **no auto-upshift at the limiter** | F |
| Shift time | About 0.35 / 0.22 / 0.12 s for Drivelogic 1 / 2 / 3 | E |
| M xDrive | Rear-biased. Electronically controlled multi-plate centre clutch; front axle used only when the rear can't take more torque. | F |
| Split by mode | Not published. Estimate: in 4WD the front gets 0-10 % cruising and up to about 50 % with rear slip; in 4WD Sport up to about 35 %; 2WD is 0 %. | E |
| Rear diff | Active M Differential: electronic multi-plate, 0-100 % locking | F |
| Front diff | Open | A |

Sources: [BMW M xDrive release 2017](https://www.press.bmwgroup.com/global/article/attachment/T0270907EN/386135),
[BMW NA 2018 release](https://www.press.bmwgroup.com/usa/article/detail/T0273727EN_US/the-all-new-2018-bmw-m5-the-quintessential-high-performance-sedan).

## Mass, dimensions, tyres, brakes, aero

| Item | Value | Tag |
|---|---|---|
| Unladen DIN / EU (LCI) | 1,895 / 1,970 kg (EU = DIN + 75 kg driver) | F |
| Unladen DIN / EU (pre-LCI) | 1,865 / 1,940 kg | F |
| US curb | 4,345 lb (2021); 4,370 lb (2018 preliminary) | F |
| Measured | 4,288 lb, C/D 2018 base M5; 1,904 kg, Competition per FastestLaps (source unclear) | M |
| Weight distribution | 54.4 / 45.6 % front/rear (BMW NA). No scale test found. | F |
| CoG height / yaw inertia | 0.50 m / about 3,700 kg·m² | E |
| L × W × H | 4,983 (pre-LCI 4,966) × 1,903 (2,126 with mirrors) × 1,469 mm | F |
| Wheelbase / track | 2,982 / 1,625 front, 1,594 rear | F |
| Overhangs (LCI) | 888 front / 1,113 rear | F |
| Ground clearance / turning circle | 128 mm / 12.6 m | F |
| Frontal area | about 2.45 m². CdA/Cd gives 2.45-2.48; integrating BMW's front drawing gives 2.40-2.44. | E |
| Tyres | 275/35 ZR20 102Y XL front, 285/35 ZR20 104Y XL rear, on 9.5J / 10.5J × 20 forged | F |
| OE tyre | Pirelli P Zero ★ (ams test cars 2019 and 2021, Citizen 2021). Other approvals unverified. | M |
| Standard brakes | M Compound: 395 × 36 mm front with 6-piston fixed calipers; 380 × 28 mm rear with single-piston floating calipers | F |
| Carbon-ceramic | 400 × 38 front (6-piston), 380 × 28 rear (1-piston), gold, 23 kg lighter | F |
| Braking | 70-0 mph: 147 ft (C/D 2018 M5), **139 ft** (C/D 2021 Competition). 100-0 km/h about 33.5 m. | M / E |
| CdA | 0.758 m² pre-LCI; **0.77 m²** LCI Competition (0.75 for the LCI M5) | F |
| Cd | **0.31** (Competition), 0.32 (M5) per BMW NA 2021 | F |
| Downforce | Not published. Spoiler and trunk-lid Gurney; assume slight net lift. | E |

## Suspension and steering

| Item | Value | Tag |
|---|---|---|
| Front / rear | Aluminium double wishbone / aluminium five-link; strut braces; rear X-brace | F |
| Dampers | Variable Damper Control: COMFORT / SPORT / SPORT+ (new on the LCI Competition) | F |
| Competition vs M5 | 7 mm lower; springs +10 %; shorter helper springs; more front negative camber; rear toe links on ball joints; firmer rear anti-roll bar | F |
| Rates | Not published. Estimate: 55 / 53 kN/m wheel rate (1.7 / 1.85 Hz); anti-roll bars 30 / 22 kN/m | E |
| Steering | EPS with M Servotronic and variable sport ratio; overall **14.3:1** | F |
| Lock-to-lock / wheel angle | About 2.6 turns; inner 38°, outer 29° (from the 12.6 m circle) | E |

## Performance

**Factory figures [F]:**
- **0-100 km/h:** 3.3 s.
- **0-200 km/h:** 10.8 s.
- **US 0-60 mph:** 3.1 s.
- **Top speed:** 250 km/h, or **305 km/h** with the M Driver's Package (US: 155 / 190 mph).
- **Unlimited top speed [E]:** about 330 km/h in 7th. The 305 km/h limit is reached in 7th at about 6,100 rpm.

**Magazine tests [M]:**

| Test | Results |
|---|---|
| Car and Driver, 2018 M5 (base), Feb 2018 (via forum repost) | 0-60 2.8 s; 0-100 mph 6.6 s; 0-130 11.1 s; 0-150 15.9 s; ¼ mile 10.9 s @ 129 mph; 5-60 3.7 s; 30-50 2.2 s; 50-70 2.4 s; 70-0 147 ft; skidpad 0.98 g; 4,288 lb |
| Car and Driver, 2021 M5 Competition (via Guys Gab) | 0-60 2.8 s; 0-100 mph 6.7 s; ¼ mile 10.9 s @ 128 mph; skidpad 1.00 g; 70-0 139 ft |
| Car and Driver comparison, late 2021 (snippets) | 0-60 2.7 s; ¼ mile 10.8 s; skidpad 0.95 g |
| C/D Lightning Lap 2019, VIR | 2:54.0 (1.2 s quicker than the M5) |
| sport auto, Nordschleife | 7:35.90 (Competition); 7:38.92 (M5) |
| The Citizen (SA), 12 Apr 2021, LCI | 0-100 km/h 3.28 s; ¼ mile 11.22 s @ 206.6 km/h; 100-200 km/h 7.75 s; 60-100 km/h 2.06 s (3rd); 80-120 km/h 2.38 s (4th) |
| Unverified snippets | FastestLaps: 0-60 2.7 s, ¼ mile 10.8 s @ 127.7 mph, 0-100-0 mph 11.0 s. 5series.net reprint (MotorTrend or evo): 0-60 3.14 s, 0-100 mph 6.58 s, ¼ mile 10.9 s @ 127 mph. |

The C&D pages themselves couldn't be fetched, so treat the reposted numbers as second-hand.

## Sound (for the audio engineer)

### Exhaust path
1. **Manifolds:** exhaust ports face into the V and feed two cross-bank 4-into-2 manifolds.
2. **Turbos:** two twin-scroll turbines. Each sends an even 180° pulse train, and the two are 90° apart.
3. **Catalysts:** one close-coupled catalyst per turbine (S63TU had double-walled ones; assumed the same).
4. **Particulate filter (EU only):** a gasoline particulate filter (BMW 2018; ADAC). Position and count not published.
5. **Pipes:** **dual-branch** M Sport exhaust with a Helmholtz resonator between the two rear silencers.
6. **Flaps:** electrically actuated, following EFFICIENT / SPORT / SPORT+. The **M Sound Control** button
   forces the quiet setting.
7. **Tips:** **four tips**, two per side, in black chrome.

### What this means for the sound [E]
The cross-bank manifold removes most of the uneven per-bank "burble" of a cross-plane V8 before the
turbines. What's left is a smooth, even note: engine order 4 (firing) and 8 dominate, with order 2 in
each branch. Uneven character survives mainly at idle and on overrun.

There is **no blow-off valve**, so no "pssh" on lift. Turbo lag is described as "nonexistent", and
whistle is subdued.

### Measured levels
| Source | Idle | Full throttle | Cruise |
|---|---|---|---|
| Car and Driver, 2018 base M5 | not reported | 74 dB(A); **80 dB(A) peak in Sport** (speaker-enhanced) | 66 dB(A) at 70 mph |
| auto motor und sport, LCI Competition, 11/2021 | 48 dB(A) | max 81 dB(A) | 68 at 80 km/h, 69 at 100, 71 at 130, 74 at 160, 75 at 180 |
| FastestLaps, base M5 (source unclear) | 45 dB | n/a | 63 dB at 100 km/h |

- **C&D figures for the Competition: gap.** Estimate: idle 47, full throttle 79, 70 mph cruise 67 dB(A) [E].
- **EU stationary noise:** 86 dB(A) (BMW figure quoted by ams). Test speed is probably 3,750 rpm under
  the UN R51.03 rule for engines rated at 5,000-7,500 rpm [E, verify].
- **EU pass-by:** 71 dB(A) (ams; ADAC lists 72).

### Active Sound Design
The F90 has an Active Sound Design (ASD) control unit. Car and Driver: "Switch to Sport mode and the
audio system plays an enhanced version of the engine's soundtrack."

BMW's M5 ASD description dates from the F10 launch: it synthesises the sound from the firing sequence
and the exhaust's frequency range, adapts it to the engine mode, and spreads it to all five seats.
The LCI's TRACK mode mutes the audio system.

BMW doesn't publish how much of the cabin sound comes from the speakers. The 74 → 80 dB(A) jump in
Sport also includes the flaps opening, so ASD adds **at most about 6 dB** at full throttle [E].

For the game, use a clean low-order layer (orders 2, 4 and 8):
- louder in SPORT and SPORT+;
- off in TRACK.

### Limiter and overrun
- **Limiter:** cut at about 7,200 rpm. In manual mode the car bounces on the limiter instead of
  upshifting. Suggested bounce: 10-15 Hz, 150-250 rpm [E].
- **Overrun pops:**
  - EFFICIENT or M Sound Control: almost none.
  - SPORT: light burble.
  - SPORT+: the most. A reviewer gets "booms and snaps" by holding 2nd and lifting.
  - EU cars with the particulate filter crackle less sharply [E].
- **Upshifts:** smooth torque-converter shifts with a short torque dip, firmer in Drivelogic 3 and
  launch. There's no dual-clutch "bark".

### Reviewer descriptions
- "Press the red start button, and the S63 wakes up with a sharp rumble." ([Machines With Souls, 2022](https://machineswithsouls.com/bmw-m5-review/))
- "the M5 settles into a quiet idle that's perhaps a bit too quiet from the inside." (same)
- "Put the transmission into Sport +, hold it in second, then let off the gas for a very yummy burble." (same)
- "that insanely menacing exhaust note lets people know that this is no ordinary BMW." ([Guys Gab, 2021](https://www.guysgab.com/review-2021-bmw-m5-competition/))
- "The exhaust is mellow (at least from inside the cabin)." (same)
- "At speed, the V8 sounds throaty with an aggressive crackle that brings to mind a phlegm-congested dragon." ([The Drive, 2021](https://www.thedrive.com/new-cars/42106/2021-bmw-m5-competition-review-the-worlds-fastest-honda-accord); that car had the optional titanium exhaust)
- "This version of the twin-pipe, flap-controlled exhaust generates a strikingly prominent soundtrack." (BMW, 2018)

### Reference videos (links only)
- [AutoMann: 2018 M5 F90 Pure Exhaust Sound Test](https://www.youtube.com/watch?v=aeFiDvXGNRA): cold start, idle, revs, full throttle, pops.
- [AutoMann: 2018 M5 Drive & Sound Experience](https://www.youtube.com/watch?v=jAq2ckKSqvU).
- [mjrk.39: M5 F90 start-up sound](https://www.youtube.com/watch?v=GMtRzIc0tP4). This is the source of the CC BY audio file on Commons.
- **Not found:** onboard-at-limiter, dyno and flyby references. The shared web-search budget ran out.

### Freely licensed recording
[Wikimedia Commons: "BMW M5 F90 - engine and exhaust sound (YouTube GMtRzIc0tP4).opus"](https://commons.wikimedia.org/wiki/File:BMW_M5_F90_-_engine_and_exhaust_sound_(YouTube_GMtRzIc0tP4).opus)
- **Content:** 38 s of start-up and revving.
- **Licence:** CC BY 3.0, attribution to mjrk.39. Commons licence review is still pending.
- **Unknown:** whether the car's exhaust is stock.
- **Local copy: not downloaded.** upload.wikimedia.org returned HTTP 429 (robot-policy rate limit)
  to every attempt for about 12 minutes. `audio/RefM5F90/LICENSE_AND_ATTRIBUTION.txt` has the direct
  URL, the licence and the attribution line, ready for a manual download.

## Visual blockout

I measured the profile on BMW's LCI side-view dimension drawing (06/2020 spec PDF, page 6),
scaled by the 4,983 mm length. It is for measurement only and must not be traced.

| Landmark | Fraction of length from nose | Height |
|---|---|---|
| Front axle / rear axle | 0.178 / 0.777 | n/a |
| Bonnet | 0.10 / 0.20 | 0.90 / 0.97 m |
| Windscreen base (cowl) | **0.305** | 1.00 m |
| Windscreen header | 0.47 | 1.42 m |
| Roof peak | **0.59** | **1.47 m** |
| Rear window top / base | 0.70 / 0.885 | 1.46 / about 1.10 m |
| Boot lip spoiler | 0.975 | 1.045 m |

- **Nose:** blunt and near-vertical, about 0.77 m high, with the splitter at about 0.16 m.
- **Tail:** short notchback. The rear window slopes about 20°; tall bumper with a diffuser and four tips.
- **Other:** windscreen rake about 27°; sills about 0.175 m off the ground.

**Freely licensed photos I viewed:**
- [M5_F90_Side.jpg](https://commons.wikimedia.org/wiki/File:M5_F90_Side.jpg) (CC BY-SA 4.0, MrWalkr).
  Front three-quarter view through a showroom window, so not usable for measuring.
- [BMW_M5_(F90)_-_side_view_-_Netherlands.jpg](https://commons.wikimedia.org/wiki/File:BMW_M5_(F90)_-_side_view_-_Netherlands.jpg)
  (CC BY-SA 4.0, Sebastiaan Broekhoven). Near-profile view of a pre-LCI car. It agrees with the drawing
  within about 0.01-0.02 of length:
  - windscreen base 0.31;
  - header 0.46;
  - roof peak 0.60;
  - boot deck 0.89.

  Its wide-angle perspective stretches the wheelbase, so take the axle positions from the drawing.

## Gaps
- **Not found:**
  - turbocharger maker and model;
  - the Competition's boost figure;
  - the TU4's wastegate actuation;
  - converter stall speed;
  - xDrive split percentages;
  - spring, damper and anti-roll-bar rates;
  - centre-of-gravity height;
  - downforce figures;
  - Car and Driver's interior dB(A) for the Competition.
- **Estimated:** idle, launch and limiter details; lock-to-lock turns.
- **Second-hand only:** several magazine numbers come from reposts or snippets because C&D,
  MotorTrend and FastestLaps pages couldn't be fetched. No 100-0 km/h braking figure was found.
- **Not looked up:** onboard, dyno and flyby reference videos, because the search budget ran out.
- **Pre-LCI overhangs:** unknown.
- **Commons recording:** not downloaded (HTTP 429); see the audio folder note.

## Sources
- BMW Group PressClub:
  - [Specifications of the BMW M5, valid from 09/2018](https://press.bmwgroup.com/global/article/attachment/T0286586EN/419604) ([PDF](https://newsroom.bmwgroup.com/global/download/525d1fbc-3144-4c4a-869d-c3d98da1b94b/20260722124132002-95.pdf)), 2018-11-05.
  - [The new BMW M5 Competition](https://www.press.bmwgroup.com/global/article/attachment/T0280678EN/412670), 2018-08-06.
  - [The new BMW M5 and M5 Competition, Specifications 06/2020](https://press.bmwgroup.com/global/article/attachment/T0309233EN/452618) ([PDF](https://newsroom.bmwgroup.com/global/download/b3cc0d7f-5447-48d2-9c89-265cc3700727/20260722141130077-693.pdf)).
  - [BMW Ireland, The new BMW M5 Competition](https://www.press.bmwgroup.com/ireland/article/detail/T0309430EN/the-new-bmw-m5-competition), 2020-06.
  - [The new BMW M5 with M xDrive](https://www.press.bmwgroup.com/global/article/attachment/T0270907EN/386135), 2017-05-17.
  - [BMW Ireland, The New BMW M5](https://press.bmwgroup.com/ireland/article/attachment/T0273806EN/392695), 2017-08-21.
- BMW of North America:
  - [The all-new 2018 BMW M5](https://www.press.bmwgroup.com/usa/article/detail/T0273727EN_US/the-all-new-2018-bmw-m5-the-quintessential-high-performance-sedan) and its [US spec PDF](https://newsroom.bmwgroup.com/americas/download/2456617c-0526-4f01-8f39-af563677fa2e/20260728132504252-221.pdf), 2017-08-21.
  - [The new 2021 BMW M5 Sedan](https://newsroom.bmwgroup.com/americas/the-new-2021-bmw-m5-sedan/) ([PDF](https://newsroom.bmwgroup.com/americas/download/6155bba1-36d9-41e1-bcb9-6a82f95f6cec/20260728141627017-921.pdf)), 2020-06.
  - [The new BMW M5 CS](https://newsroom.bmwgroup.com/americas/the-new-bmw-m5-cs/), 2021-01.
- [BMW technical training ST1202, S63TU Engine](https://archive.org/download/BMWTechnicalTrainingDocuments/ST1202%20S63TU%20Engine/S63TU-engine-manual.pdf) (Internet Archive mirror).
- Wikipedia: [BMW M5](https://en.wikipedia.org/wiki/BMW_M5), [BMW N63 / S63](https://en.wikipedia.org/wiki/BMW_N63#S63).
- [ADAC Autokatalog, M5 Competition 07/20-09/20](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/bmw/5er-reihe/g30-g31-f90-facelift/313219).
- auto motor und sport data pages:
  - [Kosten und Realverbrauch, 11/2021](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m5-competition/technische-daten/);
  - [vs AMG E 63 S, 07/2021](https://www.auto-motor-und-sport.de/test/bmw-m5-competition-mercedes-amg-e-63-s-4matic/technische-daten/);
  - [vs RS 7 and GT 63 S, 12/2019](https://www.auto-motor-und-sport.de/test/audi-rs-7-sportback-bmw-m5-competition-mercedes-amg-gt-63-s/technische-daten/).
- Car and Driver:
  - [2018 BMW M5 Test Review](https://www.caranddriver.com/reviews/a17804645/2018-bmw-m5-test-review/), read through a [forum repost](https://www.bmwfanatics.co.za/threads/new-m5-performance-tested.84850/);
  - 2021 Competition figures through [Guys Gab](https://www.guysgab.com/review-2021-bmw-m5-competition/);
  - comparison test through [Yahoo](https://autos.yahoo.com/comparison-test-2022-cadillac-ct5-110000587.html) and [BimmerLife](https://bimmerlife.com/2021/10/30/f90-m5-lci-tested-and-compared/);
  - [Lightning Lap through BMWBLOG](https://www.bmwblog.com/2019/10/11/video-bmw-m5-competition-at-car-and-drivers-lightning-lap/).
- [The Citizen road test data](https://citizen.co.za/wp-content/uploads/2021/05/M5Compdata.pdf), 2021-04-12.
- Reviews:
  - [The Drive](https://www.thedrive.com/new-cars/42106/2021-bmw-m5-competition-review-the-worlds-fastest-honda-accord), 2021-10-08;
  - [Machines With Souls](https://machineswithsouls.com/bmw-m5-review/), 2022-08-22;
  - [Motor1 Pro/Con](https://www.motor1.com/reviews/527898/2021-bmw-m5-pro-con/), 2021-08-20.
- [Bimmerfile, Active Sound Design (F10)](https://www.bimmerfile.com/?p=15607), 2011.
- [AutoMann pure sound](https://automann.tv/blog/2018-bmw-m5-f90-600hp-pure-sound) and [drive and sound](https://automann.tv/blog/2018-bmw-m5-f90-600hp-drive-sound).
- FastestLaps [comparison](https://fastestlaps.com/comparisons/ascr01fa1jvf) and [model page](https://fastestlaps.com/models/bmw-m5-g30); [5series.net](https://5series.net/?p=16545). Search snippets only.
