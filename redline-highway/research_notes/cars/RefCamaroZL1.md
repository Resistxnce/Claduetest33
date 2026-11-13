# Reference car: Chevrolet Camaro ZL1 coupe (6th generation, 2017-2024)

*Config id `RefCamaroZL1`. Machine-readable version: `RefCamaroZL1.json` in this folder. Researched 2026-11-13.*

Engineering reference only. In the game this car gets a fictional name; no Chevrolet names, logos or
body design are used.

Tags: **F** GM figure (press material, product guide or GM service bulletin), **P** published by a third
party, **M** measured in a test, **E** estimate made here (the note says how), **A** assumption.

**How this was sourced.** The best primary source turned out to be GM's own documents: the *2019 Camaro
ZL1 product guide* (Chevrolet press kit, PDF) and three GM service bulletins hosted by NHTSA. Car and
Driver and Motor Trend block this research agent, so their figures come only from search snippets and
an aggregator. GM's media site, Autoblog and some others returned 403. The session's web-search budget
ran out near the end; the gaps list says what is still open.

## Corrections to the starting facts

- **Supercharger confirmed:** Eaton R1740 TVS (1.74 L, two 4-lobe rotors, 160° twist).
- **Torque in Nm:** 650 lb-ft is **881 Nm**. GM's product guide prints 868 Nm, which is the 640 lb-ft
  pre-certification figure.
- **Lubrication:** the Camaro's LT4 is **wet-sump**. Only the Corvette Z06 LT4 is dry-sump.
- **Manual gearbox:** the TR-6060 in the ZL1 is the close-ratio **MH3**: first gear is 2.29, not the
  2.66 of the old ZL1. That is why it reaches 60 mph in first.

## Identity

| Item | Value | Tag | Source |
|---|---|---|---|
| Car | Chevrolet Camaro ZL1, 2-door 2+2 fastback coupe (convertible also sold) | F | [GM product guide][pg] |
| Years | 2017-2024; 6th-gen production ended 14 Dec 2023 | P | [Wikipedia][wiki] |
| Layout | Front engine, longitudinal, rear-wheel drive, left-hand drive | F | [pg] |
| Rating history | Announced at an estimated 640 hp / 640 lb-ft; SAE-certified at 650 / 650 in Aug 2016 | P | [GM Authority][gma], [wiki] |
| Model-year changes | 2018: ZL1 1LE added (manual only). 2019: new rear fascia and taillamps, length 190.2 in (was 188.3), 1LE gets the 10-speed from Feb 2019. 2024: last year, Garage 56 Edition (56 cars). 2020-23 changes are small and weren't researched. | F/P | [pg], [19-NA-038][b19], [wiki] |
| Convertible | 4,113 lb manual / 4,148 lb auto. Reported to use a 2.77 final drive (auto) and to have no eLSD; that part comes only from an Autoblog snippet. | F/P | [pg], [Autoblog][ab] |

**ZL1 1LE variant (2018-2024).** Multimatic DSSV spool-valve dampers (23 lb lighter than Magnetic Ride,
hard-mounted), springs about 4× stiffer, solid subframe mounts, camber plates, threaded front spring
perch (±10 mm ride height), 3-position rear anti-roll bar (+15 % / −10 %), 19×11 / 19×12 wheels with
Goodyear Eagle F1 Supercar 3R 305/30ZR19 / 325/30ZR19, carbon wing making 300 lb (1,334 N) at 150 mph,
about 60 lb lighter (3,820 lb est.), 1.10 g. Manual only for 2018; 10L90 from February 2019.
Nürburgring 7:16.04 in 2017, 13.6 s quicker than the standard ZL1. Sources: [17-NA-251][b17],
[19-NA-038][b19], [pg], [wiki].

## Engine: LT4 supercharged 6.2 V8

| Item | Value | Tag | Source |
|---|---|---|---|
| Type | Gen V small-block, 90° V8, OHV pushrod, 2 valves/cyl, dual-equal VVT, direct injection | F | [pg], [Corvette Action Center][cac] |
| Crank | Forged steel, **cross-plane** | E | [EngineLabs][el] (forged); cross-plane deduced from the firing order |
| Displacement | 6,162 cc (376 cu in) | F | [GM Powered Solutions][gmps], [el] |
| Bore × stroke | 103.25 × 92.0 mm (4.06 × 3.62 in); bore spacing 4.400 in | F/P | [pg], [cac] |
| Compression | 10.0 : 1 (ignore the 11.5:1 in some databases; that's the LT1) | F | [gmps], [cac], [el] |
| Valves, cam | 54 mm Ti intake, 40.4 mm sodium exhaust, rocker 1.8; lift 0.492/0.551 in, 189/223° at 0.050 in, LSA 120° | P | [cac], Z06 data assumed shared |
| Oiling | Wet sump in the Camaro | F | [17-NA-251][b17] |
| Max power | **485 kW (650 hp) at 6,400 rpm**, SAE certified | F | [pg] |
| Max torque | **881 Nm (650 lb-ft) at 3,600 rpm** | F | [b17] |
| Torque landmarks | 457 lb-ft (620 Nm) just off idle; 625 lb-ft (847 Nm) by 2,800 rpm; ≥ 90 % of peak from 2,500 to 5,400 rpm | P | [el], quoting GM |
| Redline | 6,500 rpm (tachometer) | P | [WhichCar][wc] |
| Max engine speed | 6,600 rpm (GM crate-engine page) | P | [Chevrolet Performance][crate], via snippet |
| Rev limiter | ~6,600 rpm fuel cut, 100-150 rpm hysteresis | E | not documented |
| Idle | ~650 rpm warm; ~1,000-1,200 rpm cold-start flare | E | not found |
| Launch control | Driver-set rpm, slip target 5-15 %, surface type; 1LE auto bulletin: down to 800 rpm, GM recommends ≥ 1,200 rpm. Default not published; suggest holding ~2,500-3,000 rpm (auto) or ~3,500-4,000 (manual) in the sim | F / E | [b17], [b19] |
| Cooling | 11 heat exchangers | F | [pg] |

### Full-load torque curves

**Measured at the rear wheels** [M]. *Read from a chart:* the blue "stock" trace on
[K&N's Dynojet sheet][kn] for a stock 2017 ZL1 (8,620 miles, 4th gear, SAE correction 1.02, run on
21 Feb 2017). Digitised by pixel colour; the power trace agrees with torque × rpm / 5252 to within 1 %.
The sheet doesn't say whether the car was manual or automatic.

| rpm | 2,250 | 2,500 | 3,000 | 3,500 | 4,000 | 4,500 | 5,000 | 5,500 | 6,000 | 6,500 |
|---|---|---|---|---|---|---|---|---|---|---|
| Nm (wheels) | 672 | 729 | 748 | 762 | 746 | 716 | 696 | 656 | 643 | 534 |

Peak about 762 Nm at 3,300-3,500 rpm and about 546 whp at 6,100 rpm. The fall above 6,100 rpm conflicts
with GM's 650 hp at 6,400, so it is probably heat soak or calibration on the dyno.

**Estimated at the crank** [E]. Drawn through GM's points (881 Nm at 3,600; 723 Nm at 6,400 = 485 kW;
620 Nm "just off idle", placed at 1,000 rpm; 847 Nm by 2,800; ≥ 793 Nm from 2,500 to 5,400), with the
mid-range shape from the wheel curve. The wheel/crank ratio comes out 0.82-0.90 between 2,500 and
6,000 rpm. **Use this curve for the simulation.**

| rpm | 1,000 | 1,500 | 2,000 | 2,500 | 3,000 | 3,500 | 3,600 | 4,000 | 4,500 | 5,000 | 5,500 | 6,000 | 6,400 | 6,500 | 6,600 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Nm | 620 | 705 | 770 | 813 | 861 | 879 | 881 | 872 | 851 | 830 | 800 | 762 | 723 | 708 | 685 |
| kW | 65 | 111 | 161 | 213 | 270 | 322 | 332 | 365 | 401 | 434 | 461 | 479 | 484 | 482 | 473 |

### Firing order and cylinder numbering

- **Firing order 1-8-7-2-6-5-4-3** [P] ([rerev][fo], [Summit][sum]; same as LS and other LT V8s).
- **GM numbering** [P] ([Summit][sum]): cylinders are numbered front to back, odd **1-3-5-7 on the
  left (driver's) bank** and even **2-4-6-8 on the right bank**. No. 1 is the front cylinder of the left bank.
- **Per-bank pattern** [E]: the whole engine fires every 90°. Each bank on its own fires at uneven
  180-270-180-90° intervals (left bank 1-7-5-3, right bank 8-2-6-4). That uneven per-bank pulse train is
  the classic cross-plane V8 burble.
- **Firing frequency** = rpm / 15: 43 Hz at 650 rpm, 200 Hz at 3,000 rpm, 433 Hz at 6,500 rpm.

## Supercharger

| Item | Value | Tag | Source |
|---|---|---|---|
| Model | **Eaton R1740 TVS** (confirmed) | P | [el], [cac] |
| Displacement | 1.74 L per rotor revolution (quoted as 1.7 L) | P | [el] |
| Rotors | Twin-rotor Roots type, 4 lobes per rotor, 160° helical twist | P | [el], [cac] |
| Drive ratio | 3.10 × crank speed | P | [el] |
| Max rotor speed | 20,150 rpm (= 6,500 engine rpm × 3.10); CAC rounds it to 20,000 | P | [el], [cac] |
| Max boost | 9.4 psi (65 kPa); CAC says 9.71 psi (0.67 bar) | P | [el], [cac] |
| Intercooler | Air-to-liquid, two bricks inside the supercharger case, own low-temperature coolant loop with pump and front heat exchanger, up to 60 °C charge cooling. Camaro-specific lid lifts the bricks for better airflow. | P / F | [cac], [b17] |

### Whine pitch for the audio engineer [E]

A twin-rotor Roots blower gives 2 × lobes pulses per rotor revolution, so 8 here (a 2-lobe blower gives
4). Fundamental **f = 0.4133 × engine rpm Hz**: engine order 24.8, or **6.2 × the firing frequency**.
Because that ratio isn't a whole number, the whine never locks onto the engine's harmonics, which is why
it stands out. A weaker line at half that frequency (single-rotor lobe pass) and a timing-gear mesh
whine (tooth count unknown) may also be present.

| Engine rpm | 650 | 1,000 | 2,000 | 3,000 | 4,000 | 5,000 | 6,000 | 6,500 |
|---|---|---|---|---|---|---|---|---|
| Rotor rpm | 2,015 | 3,100 | 6,200 | 9,300 | 12,400 | 15,500 | 18,600 | 20,150 |
| Whine, 8 per rev (Hz) | 269 | 413 | 827 | 1,240 | 1,653 | 2,067 | 2,480 | 2,687 |
| Lobe pass, 4 per rev (Hz) | 134 | 207 | 413 | 620 | 827 | 1,033 | 1,240 | 1,343 |

Character [P]: the whine is clearest at low revs and part throttle. The exhaust covers it at high revs,
and so does wind with the convertible roof down above about 75 mph ([Motor1][m1], [MotorWeek][mw],
review snippets).

## Transmission

**Main spec: Hydra-Matic 10L90 10-speed automatic with paddles** [F] ([GM 10-speed release][t10], [pg]).
GM bulletins use RPO MGL; one secondary source says MX0.

| Gear | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | R |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ratio [F] | 4.70 | 2.99 | 2.15 | 1.80 | 1.52 | 1.28 | 1.00 | 0.85 | 0.69 | 0.64 | 4.87 |
| km/h at 6,500 rpm [E] | 61 | 96 | 134 | 160 | 190 | 225 | 288 | 339* | 418* | 450* | |

\*Drag-limited. Speeds use a 0.335 m rear rolling radius (E). Cross-checks: about 1,860 rpm at 80 mph in
10th (C/D: "less than 1900 rpm"); 198 mph is reached in 8th at about 6,100 rpm (The Drive: the car never
needs more than 8th); 0-60 mph takes one upshift, since 2nd ends at 60-61 mph.

| Item | Value | Tag | Source |
|---|---|---|---|
| Final drive | **2.85** coupe auto; 2.77 convertible auto | F / P | [pg], [ab] |
| Torque converter | 260 mm, integral turbine clutch, lock-up with ECCC slip control | F | [t10] |
| Stall speed | ~2,600 rpm | E | not published |
| Clutches | 6 (4 rotating, 2 brakes), incl. a triple-clutch pack | F | [t10] |
| Shift times | GM: upshifts 1-2 36 %, 2-3 27 %, 3-4 26 % quicker than Porsche's PDK. No absolute times; use 0.10 s in the sim (E). | F / E | [t10] |
| Shift logic | Sport/Track: holds gears when driven hard, holds after a sudden lift until near redline, downshifts under braking keeping above ~3,000 rpm. 1LE auto Track pattern rev-matches every downshift. | F | [b19] |

**Variant: TREMEC TR-6060 6-speed manual, RPO MH3, with Active Rev Match** [F] ([17-NA-251][b17]).
Rated for 881 Nm. Final drive **3.73**.

| Gear | 1 | 2 | 3 | 4 | 5 | 6 | R |
|---|---|---|---|---|---|---|---|
| Ratio [F] | 2.29 | 1.61 | 1.21 | 1.00 | 0.82 | 0.68 | 3.11 |
| km/h at 6,500 rpm [E] | 96 | 137 | 182 | 220 | 269 | 324* | |

The bulletin is for the 2018 ZL1 1LE. The same ratios fit the 2017 ZL1 manual: "60 mph in first"
([The Drive][d1st]) and about 100 km/h in first at 6,500 rpm ([WhichCar][wc]) both match 2.29 × 3.73.

## Drivetrain

- **eLSD** [F] ([17-NA-251][b17], [pg]): 226 mm ring gear, hydraulically actuated clutch pack, variable
  from 0 to 200 Nm "breakaway torque" between the rear wheels, fully engaged within 0.150 s. Four modes
  tied to the traction settings: stability (default), TCS+StabiliTrak off, PTM, and TCS off with
  StabiliTrak on.
- **Performance Traction Management** [F]: Wet, Dry, Sport 1, Sport 2, Race. Also Competitive Driving
  Mode and Line Lock.
- **Suggested sim approximation** [E]: LimitedSlip, preload ~100 Nm, power lock 0.35, coast lock 0.20.

## Mass

| Item | Value | Tag | Source |
|---|---|---|---|
| Curb, coupe automatic | **1,789 kg (3,944 lb)**, GM curb weight (full fluids, no driver) | F | [pg] |
| Curb, coupe manual | 1,761 kg (3,883 lb) | F | [pg] |
| Curb, convertible auto / manual | 1,882 / 1,866 kg | F | [pg] |
| Curb, ZL1 1LE | 1,732 kg (3,820 lb), GM estimate | F | [pg] |
| C/D test car (auto coupe) | 1,784 kg (3,933 lb) | M | [C/D][cda], via search snippet |
| Weight distribution | ~53 / 47 front/rear | E | **not found**; supercharger and coolers sit up front |
| Sim mass | 1,864 kg (auto coupe + 75 kg driver) | A | as for the GT12 |

## Dimensions

| Item | Value | Tag | Source |
|---|---|---|---|
| Length | 4,812 mm (190.2 in) for 2019+; 4,783 mm (188.3 in) for 2017-18 | F / P | [pg], [wiki] |
| Width | 1,897 mm (74.7 in) | F | [pg] |
| Height | 1,330 mm (52.4 in) | F | [pg] |
| Wheelbase | 2,811 mm (110.7 in) | F | [pg] |
| Track front / rear | 1,610 / 1,591 mm (63.4 / 62.6 in) | F | [pg] |
| Overhangs front / rear | ~925 / ~1,075 mm | E | photo ratio applied to length − wheelbase |
| Ground clearance | ~115 mm at the splitter, ~130 mm at the sills | E | photo, scaled by wheel size |
| Frontal area | ~2.14 m² (0.85 × width × height); a lap-sim site uses 2.07 m² | E | |
| Turning circle | 11.7 m (38.4 ft) | F | [pg] |

## Tyres and wheels

| Item | Value | Tag | Source |
|---|---|---|---|
| Front | **285/30ZR20 Goodyear Eagle F1 Supercar 3**, Camaro-specific compound; 20 × 10 in forged; 679 mm diameter | F | [pg] |
| Rear | **305/30ZR20 Goodyear Eagle F1 Supercar 3**; 20 × 11 in forged; 691 mm diameter | F | [pg] |
| 1LE | 305/30ZR19 / 325/30ZR19 **Eagle F1 Supercar 3R** on 19 × 11 / 19 × 12; footprint about 10 % larger | F | [b17], [pg] |
| Track pressures (1LE) | Cold 26 psi, hot target 32-35 psi; 44 psi for sustained high speed (also used in the 198 mph run) | F | [b17], [The Drive][d198] |

## Brakes

| Item | Value | Tag | Source |
|---|---|---|---|
| Front | Brembo 6-piston monobloc fixed calipers, **390 × 36 mm** two-piece vented rotors | F | [pg], [b17] |
| Rear | Brembo 4-piston fixed calipers, **365 × 28 mm** vented rotors | F | [pg], [b17] |
| GM 60-0 mph | 107 ft (32.6 m); GM's guide misprints this as 35 m | F | [pg] |
| C/D 70-0 mph | 143 ft (43.6 m), auto coupe, Mar 2017 | M | [cda], via snippet |
| MT 60-0 mph | 91 ft (27.7 m), ZL1 1LE, 2017 Best Driver's Car | M | [MT via mirror][mt] |

## Aerodynamics

| Item | Value | Tag | Source |
|---|---|---|---|
| Cd | **Not published by GM.** A lap-simulation site uses 0.364 × 2.07 m² = 0.75 m². | E | |
| CdA fitted to top speed | **~0.90 m²**. 650 hp gives 198 mph in 8th at ~6,100 rpm (~480 kW) with 85-90 % driveline efficiency, Crr 0.012-0.016 and air at 1.20-1.225 kg/m³, giving 0.90-0.99. The 0.75 figure would let the car reach about 210 mph. | E | [d198], [pg] |
| Standard ZL1 lift | GM says the package reduces lift with no significant drag penalty (pedestal spoiler, auxiliary transmission cooler), but gives no numbers. Suggest near-zero net lift. | F / E | [d198] |
| 1LE downforce | 300 lb (1,334 N) at 150 mph from the wing, i.e. ClA ≈ 0.48 m² at the rear | F / E | [b17] |

## Suspension and steering

| Item | Value | Tag | Source |
|---|---|---|---|
| Front | MacPherson-type strut with dual lower ball joints, monotube struts, direct-acting anti-roll bar | F | [pg] |
| Rear | Independent five-link, monotube shocks, direct-acting anti-roll bar | F | [pg] |
| Dampers | **Magnetic Ride Control**, ZL1-specific calibration | F | [pg] |
| Track alignment | Front camber −2.7°, caster 7.9°, toe 0.1° total; rear camber −2.0°, toe 0.1° total | F | [b17] |
| Springs, bars, ride height | **Not published** | | gap |
| Steering | ZF rack-mounted electric power steering, variable ratio | F | [pg] |
| Ratio, lock-to-lock | **Not found**; about 12-14:1 and about 2.4 turns would be typical | E | gap |
| Max road-wheel angle | ~29.5° outer / ~40° inner (~34° single-track equivalent), from the 11.7 m turning circle | E | [pg] |

## Performance

**Factory** [F]: 0-60 mph **3.5 s** (10-speed coupe); quarter mile **11.4 s at 127 mph**; top speed
**198 mph (319 km/h)** ([pg], [d198]); 1.02 g; 60-0 mph 107 ft. The top speed is a two-way average at
Papenburg, Germany, in a stock 10-speed car with 44 psi tyres: 202.3 mph with the wind, 193.3 mph
against it. GM gives no 0-100 km/h; ~3.65 s (E). Nürburgring: ZL1 about 7:29.6, 1LE 7:16.04.

**Magazine and independent tests** [M]:

| Outlet, date | Car | 0-60 mph | Quarter mile | Other | How read |
|---|---|---|---|---|---|
| Car and Driver, Mar 2017 | 2017 ZL1, 10-speed | 3.4 s | 11.5 s @ 125 mph | 70-0 143 ft; skidpad 1.04 g; top-gear 50-70 2.1 s; 3,933 lb | [aggregator][agg] + [C/D][cda] snippets |
| Car and Driver, 2017 | 2017 ZL1, manual | 3.7 s | 12.0 s @ 122 mph | 0.3 s slower to 60 than the auto | [C/D manual][cdm] snippet |
| Motor Trend, 2017 | 2017 ZL1, 10-speed | 3.5 s | 11.5 s @ 125.0 mph | | [agg] |
| Motor Trend, 2017 | 2017 ZL1, manual | 3.8 s | 11.8 s @ 123.9 mph | | [agg] |
| MotorWeek, 2017 | 2017 ZL1, 10-speed | 3.5 s | 11.5 s @ 127 mph | | [mw], read directly |
| Hennessey video, Apr 2017 | 2017 ZL1, 10-speed, stock | 3.6 s | | 0-100 mph 7.6 s; 0-179.8 mph 26.2 s | [The Drive][dhenn] |
| Car and Driver, 2018 | ZL1 1LE, manual | 3.5 s | 11.7 s @ 124 mph | | [agg] |
| Road & Track, 2018 | ZL1 1LE, manual | 3.5 s | 11.7 s @ 124 mph | | [agg] |
| Motor Trend BDC 2017 | ZL1 1LE, manual | 3.6 s | 11.7 s @ 123.0 mph | 60-0 91 ft; figure eight 23.0 s @ 0.93 g | [agg], [mt] |
| Car and Driver, 2019 | ZL1 1LE, 10-speed | 3.4 s | 11.5 s @ 124 mph | | [agg] |

**Sim targets:** 0-60 mph 3.5 s, quarter mile 11.4 s, 0-100 mph ~7.6 s, top speed 319 km/h in 8th.

## Sound (for the audio engineer)

**Exhaust layout**

| Item | Value | Tag | Source |
|---|---|---|---|
| Manifolds | **Tri-Y** exhaust manifolds, which GM says improve "torque production and sound quality". The Z06 LT4's are cast stainless. | F / P | [b17], [cac] |
| Catalysts | Close-coupled (stated for the Z06 LT4; assumed for the Camaro) | A | [cac] |
| Crossover | **X-pipe, H-pipe or none: not confirmed** | | gap |
| Mufflers and valves | Dual-mode "NPP" exhaust: electronically actuated butterfly valves let exhaust bypass the rear mufflers; open on demand and always in Track. The 1LE gets larger bell-shaped tips. | P / F | snippets, [b17] |
| Tips | **Quad tips**: two at each outer corner of the rear diffuser (split rear exit) | P | [photo][pgold] |
| Modes | Stealth (quietest), Tour, Sport, Track (valves open). GM documents confirm Sport and Track; the exact valve map per mode wasn't found. | P | snippets, [17-NA-078][b078] |

**Behaviour**

- **WOT pops** [F]: GM bulletin [17-NA-078][b078] (March 2017, LT4 Camaro and Corvette) says a "pop"
  or "backfire" during wide-open-throttle manoeuvres in **Sport or Track** is normal and goes away in
  other modes. Reviewers also mention "exhaust blatting on the overrun". In the game: pops on lift-off
  and upshifts in Sport/Track only.
- **Limiter** [E]: not documented. Assume a fuel-cut bounce at ~6,600 rpm.
- **Launch** [F]: GM warns that a launch setting below 1,200 rpm "will produce an unpleasant sound" ([b19]).
- **Shifts** [F]: very quick 10-speed upshifts; the 1LE auto rev-matches every downshift.

**Measured levels**

- **Car and Driver interior dBA (idle / full throttle / 70 mph): NOT OBTAINED.** C/D blocks this agent.
- Proxy [M], previous-generation 2013 ZL1 convertible (supercharged LSA 6.2), [Edmunds][ed], Sept 2012:
  idle 53.6, full throttle 81.9, 70 mph 69.9, 70 mph roof open 77.3 (labelled "Db").
- Estimate for the 2017+ coupe [E]: idle ~54 dBA, full throttle ~85 dBA, 70 mph ~70 dBA.
- No exterior or pass-by figures were found.

**Reviewer descriptions** (each under 25 words)

- "Crank it up, and it sounds hellacious, giving you an auditory taste of the performance potential that lies within." ([MotorWeek][mw])
- "some insanely-sweet supercharger wine [sic]" ([MotorWeek][mw])
- "sounds ferocious at times"; "characterful supercharger whine"; "it also does a good job of shutting up when you want it to." ([Motor1][m1], 1 Mar 2017)
- "It's so loud you can't even hear the supercharger whine." (convertible, roof down, above ~75 mph; [Motor1][m1])
- "it's the whine of the supercharger that dominates at low revs" (review snippet; outlet not confirmed)
- "the angry, hard-edged growl of the 6.2-litre V8" (review snippet; outlet not confirmed)
- "just a bit of burble reaching your ears, as well as a faint whine from the supercharger" (quiet mode; review snippet; outlet not confirmed)

**Reference videos** (links only, not downloaded; stock status from titles and descriptions)

- Acceleration 0-180 mph, stock 10-speed (Hennessey): https://www.youtube.com/watch?v=cFsK4qgeg70
- Onboard POV, 2017 ZL1 10-speed: https://www.youtube.com/watch?v=SS7QG3wdn3I
- Onboard POV, ZL1 10-speed: https://www.youtube.com/watch?v=IHm2q30D7ZA
- Onboard POV, hard pulls and supercharger sound: https://www.youtube.com/watch?v=ugDW6_VmlmA
- Onboard POV review, 2022 ZL1 1LE 10-speed: https://www.youtube.com/watch?v=bQB11vHo6Hg
- Flyby, stock exhaust, full and partial throttle (2018 ZL1): https://www.youtube.com/watch?v=aoYfStHWqBY
- Cold start and revs with burbles (2018 ZL1): https://www.youtube.com/watch?v=E1g3qeTzEMM
- Cold start and acceleration, stock (2023 ZL1): https://www.youtube.com/watch?v=L2bNhACnxOU
- Dyno, stock 2023 ZL1 1LE: https://www.youtube.com/watch?v=Ar6Ie2rOPKc
- Dyno, stock 2019 ZL1 vs modified 1LE: https://www.youtube.com/watch?v=WA0NlUQpeaQ
- Dyno, 2020 ZL1 1LE baseline: https://www.youtube.com/watch?v=PbSkse26Jaw

**Freely licensed recordings** (downloaded to `audio/RefCamaroZL1/`; licences in `LICENSES.txt` there)

1. `Commons_Cadillac_CT5-V_Blackwing_LT4_engine_and_exhaust_sound.opus`: an **LT4** in a Cadillac
   CT5-V Blackwing with an **aftermarket** AWE SwitchPath exhaust. 301 s. CC BY 3.0.
   [Commons page](https://commons.wikimedia.org/wiki/File:Cadillac_CT5-V_Blackwing_-_engine_and_exhaust_sound_(YouTube_Dgo5_38A-S0).opus)
2. `Commons_Chevrolet_Corvette_C6_ZR1_LS9_recorded2010.ogg`: Corvette C6 ZR1 (supercharged LS9 6.2,
   Eaton TVS with 4-lobe rotors) at Goodwood 2010. 12 s. CC BY-SA 3.0, Ed Pond.
   [Commons page](https://commons.wikimedia.org/wiki/File:Chevrolet_Corvette_C6_ZR1_recorded2010.ogg)

No freely licensed recording of a Camaro ZL1 itself was found. The archive.org items found were
unlicensed YouTube copies.

## Visual blockout [E]

Judged from freely licensed Commons photos:
[near-side view, 2020 ZL1 convertible, modified][p01] (Oleg Yunakov, CC BY-SA 4.0);
[front three-quarter, elevated][pdc] (OWS Photography, CC BY 4.0);
[front three-quarter, 2017-18][pgreen] and [rear three-quarter, 2020-24 1LE, quad tips][pgold]
(Xnatedawgx, CC BY-SA 4.0); [1LE front three-quarter][pprevot] (Alexandre Prevot, CC BY-SA 4.0).

- **Body:** long-hood, short-deck 2+2 fastback; high beltline with a low, narrow ("gun-slit") greenhouse;
  wide vented front fenders; big lower grille, carbon hood vent and splitter; integrated rear spoiler.
  Front-engined, with much of the V8 behind the front axle line (A).
- **Stations along the length, measured from the nose** (fractions of 4,812 mm): front axle 0.19;
  windscreen base (cowl at the body side) **0.34**; windscreen top 0.48; **roof peak ~0.57** (0.55-0.60);
  rear-window base 0.83; rear axle 0.78.
- **Heights:** roof 1,330 mm (F); beltline and hood at the cowl ~930 mm; hood leading edge ~770 mm;
  spoiler lip ~1,040 mm; side-window daylight only ~370 mm tall; splitter ~110-125 mm off the ground.
- **Nose:** blunt, near-vertical fascia; the hood falls ~160 mm from cowl to nose.
- **Tail:** short, high deck and near-vertical tail panel with wide horizontal lamps; diffuser with two
  pairs of tips at the corners.
- **Caveat:** no clean, freely licensed coupe side profile was found. The main photo is a modified
  convertible with the top up. Perspective shortens the car's ends, so positions were scaled from the
  wheelbase and the published length, not from the photo's end points.

## Gaps

1. **Car and Driver interior sound levels** (idle, full throttle, 70 mph) and its full data box; Motor
   Trend's primary pages too. Both sites block this agent.
2. **GM crank torque chart.** The crank curve is an estimate; the measured curve is at the wheels.
3. **Exhaust crossover** (X, H or none), pipe diameters, catalyst count and position, muffler type.
4. **Exact limiter rpm and behaviour, warm idle, default launch rpm.**
5. **10L90 converter stall speed and absolute shift times.**
6. **Weight distribution** (53/47 is an estimate).
7. **Cd and frontal area** (GM never published them); standard-ZL1 lift/downforce numbers.
8. **Steering ratio, lock-to-lock, ground clearance, ride height, spring and anti-roll bar rates, damper data.**
9. **Supercharger timing-gear tooth count** (a second whine order).
10. **Exterior (pass-by) sound levels.**
11. **Convertible:** the 2.77 final drive and missing eLSD come only from an Autoblog snippet.
12. **Whether the Camaro LT4 uses cylinder deactivation.**
13. **A clean, freely licensed coupe side-profile photo.**
14. **A freely licensed recording of a real ZL1.**
15. The session's web-search budget ran out before steering, ground clearance and the convertible
    details could be searched further.

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
[mt]: https://1onebestof1.blogspot.com/2017/09/chevrolet-camaro-zl1-1le-4th-place-2017.html
[ed]: https://www.edmunds.com/car-reviews/track-tests/2013-chevrolet-camaro-zl1-convertible-track-test.html
[wc]: https://www.whichcar.com.au/reviews/chevrolet-camaro-zl1-manual-review
[ab]: https://www.autoblog.com/2016/12/16/2017-chevrolet-camaro-zl1-first-drive-review/
[p01]: https://commons.wikimedia.org/wiki/File:2020_Chevrolet_Camaro_ZL1_-_01.jpg
[pdc]: https://commons.wikimedia.org/wiki/File:Chevrolet_Camaro_ZL1_(Mk_VI)_Washington_DC_Metro_Area,_USA.jpg
[pgreen]: https://commons.wikimedia.org/wiki/File:2017%E2%80%932018_Chevrolet_Camaro_ZL1,_green,_Golden_Super_Cruise_2026-09-05.jpg
[pgold]: https://commons.wikimedia.org/wiki/File:2020-2024_Chevrolet_Camaro_ZL1,_Golden_Super_Cruise_2026-10-03.jpg
[pprevot]: https://commons.wikimedia.org/wiki/File:Chevrolet_Camaro_ZL1_Sixth_generation_(54865460423).jpg
