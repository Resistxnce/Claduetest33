# Reference car RefM3G80: BMW M3 Competition sedan (G80, RWD)

*Engineering reference for a fictional car in Redline Highway. Real names stay in docs only.*
*Machine-readable twin: `research_notes/cars/RefM3G80.json` (same facts, same source ids). Researched 2026-11-13.*

Tags: **F** manufacturer figure, **P** published third-party spec, **M** measured in a magazine or independent test, **E** estimate (method in the note), **A** assumption.

## Key numbers

| Item | Value | Tag |
|---|---|---|
| Engine | S58B30T0, 2,993 cc inline-6, 84.0 x 90.0 mm, 9.3:1, twin mono-scroll MHI turbos, 1.7 bar max boost | F/P |
| Power | 375 kW / 510 PS / 503 hp at 6,250 rpm (BMW diagram: flat 5,600-7,200 rpm) | F |
| Torque | 650 Nm / 479 lb-ft from 2,750 to 5,500 rpm | F |
| Redline / limiter | 7,200 rpm / about 7,250 rpm | F / P |
| Gearbox | ZF 8HP76 (M8HP76) 8-speed torque-converter automatic: 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640; R 3.478; final drive 3.154 | F |
| Differential | Active M Differential (electronically controlled multi-plate LSD) | F |
| Mass | 1,730 kg DIN / 1,805 kg EU / 3,890 lb US; measured 3,745 lb (MT) and 3,820 lb (C/D) | F / M |
| Weight distribution | 53.1/46.9 factory (US); 53/47 measured | F / M |
| Cd x A | 0.33 x 2.34 m^2 = 0.772 m^2 | F |
| 0-100 km/h / 0-200 km/h | 3.9 s / 12.5 s factory; measured 0-100 km/h 3.64 s, 0-60 mph 3.5 s | F / M |
| Top speed | 250 km/h limited; 290 km/h with M Driver's Package | F |
| Firing order | 1-5-3-6-2-4, cylinder 1 at the front; turbo 1 = cyl 1-3, turbo 2 = cyl 4-6 | P / F |
| Cabin sound | C/D 72 dBA at 70 mph, 84 dBA full throttle; AMS 45 dB(A) idle, 82 dB(A) max | M |
| Active Sound Design | Yes, engine sound augmented through the speakers; reducible/switchable | F |

## Identity

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| make | BMW |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| model | M3 Competition Sedan |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| chassis code | G80 |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | G81 = Touring, G82/G83 = M4 Coupe/Convertible share the drivetrain. |
| type codes | 31AY (RWD), 32AY (M xDrive) |  | P | [LEEBMANN_TC](https://www.leebmann24.com/cz/en/product/bmw-repair-kit-torque-converter-10129714) | Fitment table lists 31AY and 32AY as G80 M3 Competition (11/2020-06/2024); a Japanese homologation photo title '3BA-32AY30 M3 Competition M xDrive' on Commons suggests 32AY = M xDrive. |
| engine code | S58B30T0 |  | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | T0 = Competition output; base M3 is S58B30O0. ADAC lists S58B30A for the 07/22-05/24 car. |
| production and years | Launch March 2021; M xDrive from summer 2021 (US MY2022); running update 07/2022; LCI from 07/2024 |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | 07/2022 and 07/2024 dates from ADAC catalogue periods. LCI raised the M xDrive to 390 kW/530 PS; RWD Competition stayed at 375 kW/510 PS (ADAC, Wikipedia). |
| body | 4-door, 5-seat notchback sedan with standard CFRP roof |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| trim researched | M3 Competition Sedan, rear-wheel drive, 8-speed M Steptronic with Drivelogic |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| us vs eu power | Identical engine: 375 kW = 510 PS (EU) = 503 hp SAE (US). Only the units differ. |  | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | 375 kW x 1.341 = 503 hp; 650 Nm = 479 lb-ft. |
| us vs eu mass | EU DIN 1,730 kg (no driver, 90% fuel); EU 1,805 kg (DIN + 75 kg driver/luggage); US curb 3,890 lb = 1,764 kg (full fuel, no driver) |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US figure from BMW_US21. |
| us vs eu other | EU/RoW cars carry gasoline particulate filters (OPF) in the exhaust; US cars do not. 2021 US spec lists 18/19-inch wheels as standard and 19/20-inch optional; most test cars ran 19/20. |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | OPF note: ST1926 marks the underbody catalytic converter/particulate filter 'Not for the US' (F97 manual, same S58 exhaust concept); vendors confirm for G80 (OPF_VENDORS). |
| m xdrive differences | Transfer case with electronically controlled multi-plate clutch, rear-only in normal driving; modes 4WD, 4WD Sport, 2WD (DSC off). +50 kg DIN (about +100 lb US). Steering ratio 14.6:1 vs 15.0:1. Standard 19/20-inch wheels. 0-100 km/h 3.5 s (vs 3.9), 0-60 mph 3.4 s (vs 3.8). From 07/2024 (LCI) 390 kW/530 PS. |  | F | [BMW_US22XD](https://newsroom.bmwgroup.com/americas/download/5c120393-bb1b-4ec4-8785-8d41e50a4f6f/20260728141746562-334.pdf) | Mass delta from BMW regional pages (1,780 kg DIN xDrive) and US curb 3,990 vs 3,890 lb. |

## Engine

### Full-load curves (500 rpm steps)

Crank figures are BMW's nominal full-load diagram for the 375 kW engine, extracted from the vector drawing in the M4 Competition spec sheet ([BMW_SPEC_M4](https://newsroom.bmwgroup.com/emea/download/f92f5ad6-e9e9-4ac9-9191-0855eec11dfe/20260909073605409-124.pdf)); same engine and tune as the M3 Competition. Wheel figures are a stock 2022 M4 Competition xDrive on a Mustang dynamometer ([ARM_DYNO](https://armmotorsports.com/blogs/news/s58-stock-dyno-results)), read from the chart image by pixel digitising (tag M). Wheel and crank are not directly comparable: the dyno car is AWD and Mustang dynos read low.

| rpm | Crank torque Nm (F) | Crank power kW (F) | Wheel torque Nm (M) | Wheel power kW (M) |
|---|---|---|---|---|
| 1000 | 245 | 25.7 |  |  |
| 1500 | 295 | 46.2 |  |  |
| 2000 | 345 | 71.9 |  |  |
| 2500 | 460 | 120.0 |  |  |
| 2550 |  |  | 458 | 122 |
| 3000 | 650 | 204.1 | 597 | 187 |
| 3500 | 650 | 238.1 | 597 | 218 |
| 4000 | 650 | 272.1 | 596 | 249 |
| 4500 | 650 | 306.1 | 589 | 277 |
| 5000 | 650 | 340.1 | 582 | 304 |
| 5500 | 650 | 374.2 | 569 | 327 |
| 6000 | 597 | 374.8 | 530 | 332 |
| 6500 | 551 | 374.8 | 484 | 329 |
| 6950 |  |  | 446 | 324 |
| 7000 | 511 | 374.8 |  |  |
| 7200 | 497 | 374.8 |  |  |

Exact vertices of BMW's torque line (rpm: Nm): 1000: 245, 1500: 295, 2000: 345, 2500: 460, 2651: 570, 2744: 650, 3000: 650, 3500: 650, 4000: 650, 4500: 650, 5000: 650, 5500: 650, 5593: 639, 6000: 597, 6151: 581, 6244: 573, 6349: 564, 6500: 551, 7000: 511, 7198: 497.

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| layout | Inline-6, front-mounted, longitudinal |  | F | [AMS](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) | 'vorne / laengs' in AMS data; BMW: in-line 6. |
| block | Aluminium closed-deck crankcase without liners; wire-arc-sprayed iron bore coating |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| head | Aluminium; 3D-printed sand core for coolant passages |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| crankshaft | Forged lightweight steel crank (42CrMoS4 mod, nitrocarburised), approx. 21.2 kg | kg | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Throw layout for an even-firing inline-6 is 120 deg (A). |
| pistons | Forged Mahle slipper-skirt pistons, 84 mm |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) |  |
| displacement | 2993 | cc | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| bore | 84 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| stroke | 90 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| compression ratio | 9.3 | :1 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| valvetrain | DOHC, 4 valves/cylinder, chain-driven cams, VALVETRONIC fully variable valve lift, Double-VANOS |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Chain drive from AMS ('Kette'). |
| fuel system | High Precision direct injection, 350 bar max | bar | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| fuel | RON 98 (min. RON 91) |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| oil capacity | 7 | L | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Oil change with filter. |
| max power | 375 | kW | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | 510 PS / 503 hp SAE. |
| max power rpm | 6250 | rpm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | BMW's own output diagram shows a flat 375 kW plateau from 5,600 to 7,200 rpm (BMW_SPEC_M4), so treat 6,250 as a point on that plateau. |
| max torque | 650 | Nm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | 479 lb-ft. |
| max torque rpm range | 2750, 5500 | rpm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| underrating note | Measured wheel power (335 kW at the wheels on a conservative Mustang dyno, AWD) implies roughly 385-400 kW at the crank with 13-16% losses, i.e. the 375 kW rating is conservative. |  | E | [ARM_DYNO](https://armmotorsports.com/blogs/news/s58-stock-dyno-results) | Supporting: MotorTrend says 'BMW historically has underrated its beefier engines' (MT_XD); a base manual M3 dynoed at about 496 hp vs 473 rated (BMWBLOG_DYNO). Loss assumption is an estimate. |
| redline | 7200 | rpm | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| limiter rpm | 7250 | rpm | P | [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon) | evo: 'the limiter coming in at 7250rpm'. In M (manual) mode the gearbox does not upshift at the limiter (BMW_PK). |
| design rated speed | 7500 | rpm | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Training manual: pistons and Valvetronic designed for a rated engine speed of 7,500 rpm. Not the road-car limiter. |
| idle rpm | 700 | rpm | E | CALC | Not found. Typical warm idle for BMW B58/S58 automatics is about 650-750 rpm; cold-start flare about 1,200-1,500 rpm for a few seconds (BMW_ST1926 notes a catalyst-heating mode for ~30 s after start). Verify against a video. |
| launch control rpm | 2700 | rpm | P | [BMAG_LC](https://www.bimmer-mag.com/?p=2655) | Secondary, generic source: 'M Steptronic holds engine revolutions around 2,700 rpm'. The Citizen: launch flag appears after about 2 s of building boost to around 1.0 bar, and the RWD car launches in 2nd gear (CITIZEN_ART). C/D xDrive: 'boost holding above 15.0 psi' at launch (CD_XD). Treat 2,500-3,000 rpm as the plausible range. |
| engine mass | not published | kg | E | CALC | Not published. Wikipedia gives 139 kg dry for the single-turbo B58 (uncited). The S58 adds a second turbo/manifold, forged internals and a larger oil system: estimate 160-175 kg dry, about 190 kg with fluids, turbos and ancillaries. |
| rotating inertia | 0.2 | kg*m^2 | E | CALC | Not published. Estimate for crank, rods, pistons, damper, flexplate plus torque-converter impeller side. Crank alone 21.2 kg (F). |
| firing order | 1-5-3-6-2-4 |  | P | [FIRING](https://archive.org/download/BMWTechnicalTrainingDocuments/ST501%20New%20Engine%20Technology/02_Engine%20Diagnosis.pdf) | Standard for BMW inline-sixes (M20 through N55/S54 in BMW training material). Not stated in any S58-specific document I opened; strongly expected (A). |
| cylinder numbering | Cylinder 1 at the front (belt/pulley end), cylinder 6 at the rear (gearbox end). Front turbo/manifold serves cylinders 1-3, rear turbo serves 4-6. |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Bank grouping is F (BMW_PK, BMW_ST1926); 1-at-front is the BMW convention (FIRING). |
| firing interval and frequency | 120 deg crank between firings; firing frequency = rpm / 20 Hz (35 Hz at 700 rpm, 125 Hz at 2,500, 360 Hz at 7,200). With 1-5-3-6-2-4, each turbo/exhaust branch receives evenly spaced pulses every 240 deg (1.5th order per branch). | Hz | E | CALC | Arithmetic for a 4-stroke inline-6: 3 firings per revolution. |

## Forced induction

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| type | Twin-turbo, two mono-scroll (single-scroll) turbochargers, one per 3-cylinder bank |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Press kit: 'two mono-scroll turbochargers, which supply compressed air to cylinders 1-3 and 4-6 respectively'. |
| count | 2 |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| maker | MHI (Mitsubishi Heavy Industries) |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | 'The system supplier for the mono-scroll turbocharger assembly on the S58 engine is the MHI Group.' Retailers sell OEM Mitsubishi units, BMW part nos. 11658469097 (bank 1) and 11658469098 (bank 2) (TURNER_TURBO). |
| model | not published |  | E | CALC | Turbo frame/model and wheel sizes not published. Gap. |
| twin scroll | no |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Mono-scroll; each turbine housing is cast together with its 3-into-1 exhaust manifold. |
| max boost | 1.7 | bar (gauge) | P | [AMS](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) | AMS lists 'max. Ladedruck 1,7 bar'. C/D: 24.7 psi (1.70 bar) for Competition vs 18.9 psi (1.30 bar) for the base M3 (CD_RWD). Both read as gauge pressure. |
| boost build rpm | Torque climbs from 345 Nm at 2,000 rpm to 460 Nm at 2,500 and reaches 650 Nm at about 2,750 rpm | rpm | F | [BMW_SPEC_M4](https://newsroom.bmwgroup.com/emea/download/f92f5ad6-e9e9-4ac9-9191-0855eec11dfe/20260909073605409-124.pdf) | Measured wheel dyno: plateau from about 2,900-3,000 rpm (ARM_DYNO). Reviewers note noticeable lag below that (CD_COMP, CITIZEN_ART). |
| peak torque start rpm | 2750 | rpm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| wastegate | Electric wastegate actuator per turbo, PWM-controlled by the DME; fast closing for response, can open fully to heat the catalysts |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) |  |
| blow off behaviour | No atmospheric blow-off valve is documented; stock cars make no audible 'pssh'. Any compressor recirculation is internal. |  | E | CALC | Assumption based on absence in BMW documents and on BMW practice; a faint turbo whoosh/flutter on lift-off is plausible but unverified. |
| intercooling | Indirect (air-to-liquid) charge-air cooling in the intake plenum, low-temperature circuit with electric pump |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) |  |

## Transmission

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| type | 8-speed M Steptronic with Drivelogic, torque-converter automatic |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| model | ZF 8HP76 (BMW designation M8HP76; GA8HP76Z) |  | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | US spec table names 'M8HP76'; parts sellers list 8HP76 for G80 M3 Competition (TURNER_8HP76, LEEBMANN_TC). C/D and MT call it ZF-sourced. |
| gear ratios | 5.0, 3.2, 2.143, 1.72, 1.313, 1.0, 0.823, 0.64 | :1 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| reverse ratio | 3.478 | :1 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| final drive | 3.154 | :1 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US sheet rounds to 3.15. Overall top gear 2.02:1 (MT_COMP). |
| speed at 7200rpm by gear | 57.7, 90.1, 134.5, 167.6, 219.6, 288.3, 350.3, 450.5 | km/h | E | CALC | Rolling radius 0.335 m (285/30 ZR20 or 285/35 ZR19, about 0.34 m unloaded). Check: 60 mph in 8th gives 1,543 rpm vs MotorTrend's measured 1,500 rpm. |
| rpm at 100kmh 8th | 1598 | rpm | E | CALC | Same radius. |
| shift times | not published | s | E | CALC | Not published. C/D: upshifts range 'from luxury-car mushy to rifle-bolt quick with almost no torque interruption' depending on Drivelogic. Suggest about 0.10-0.15 s torque dip at Drivelogic 3 (Sport+), 0.3-0.4 s in comfort. |
| torque converter lockup | Lock-up clutch fully engaged the moment the car has pulled away |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| torque converter stall rpm | not published | rpm | E | CALC | Not published. Launch holds about 2,700 rpm (BMAG_LC), so a full-throttle stall around 2,400-2,800 rpm is a reasonable estimate. |
| drivelogic | 3 shift programmes in D and 3 in M; paddles; holding left paddle with throttle drops to lowest possible gear; auto rev-matching on downshifts; in M mode no auto-upshift at the limiter |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| transmission oil cooler | Separate transmission oil cooler on Competition models |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| manual alternative | Base M3 only: 6-speed manual (4.111/2.315/1.542/1.179/1.000/0.846, R 3.727, FD 3.462), about 25 kg lighter |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |

## Drivetrain

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| layout | Front-engine, rear-wheel drive |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| differential | Active M Differential: electronically controlled multi-plate limited-slip differential, variable 0-100% locking, networked with DSC |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | BMW does not publish preload or lock values. Electric-motor-actuated clutch pack is assumed from the previous F80 system (A). |
| lock behaviour estimate | Model as a controlled clutch LSD: low preload (about 50-100 Nm) cruising, ramping toward full lock on power exit and under DSC-off drifting, partial lock on corner entry for stability |  | E | CALC |  |
| traction control | DSC with M Dynamic Mode; slip control moved into the engine ECU (acts up to 10x more often); M Traction Control with 10 stages (with M Drive Professional) |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| m xdrive | Electronically controlled multi-plate clutch in the transfer case; rear-only until rear grip limit; 4WD / 4WD Sport / 2WD (DSC off) |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |

## Mass

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| kerb DIN | 1730 | kg | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | DIN: 90% fuel, no driver. |
| kerb EU | 1805 | kg | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | EU: DIN + 75 kg driver/luggage. ADAC repeats 1,805 kg (EU). |
| kerb US | 3890 | lb | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | 1,764 kg. |
| kerb measured MT | 3745 | lb | M | [MT_FT](https://www.motortrend.com/cars/bmw/m3/2021/2021-bmw-m3-sedan-first-test-drive-review) | 1,699 kg; car had carbon-ceramic brakes. |
| kerb measured CD | 3820 | lb | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | 1,733 kg; car had carbon-ceramic brakes and M Driver's Package. |
| licensing mass ZA | 1690 | kg | P | [CITIZEN_SHEET](https://media.citizen.co.za/wp-content/uploads/2021/04/M3data.pdf) | South African licensing (tare) mass on the test sheet. |
| dry weight | not published | kg | E | CALC | Not published. DIN minus fuel (59 L x 0.9 x 0.745 = 40 kg) gives about 1,690 kg; minus oil, coolant and ATF roughly 1,660 kg. |
| max permissible | 2210 | kg | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Max axle loads 1,080 kg front / 1,180 kg rear. |
| weight distribution factory | 53.1, 46.9 | % front/rear | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | US spec table. The press kit's 'virtually 50:50' is marketing; factory and measured figures agree on 53/47. |
| weight distribution measured | 53, 47 | % front/rear | M | [MT_FT](https://www.motortrend.com/cars/bmw/m3/2021/2021-bmw-m3-sedan-first-test-drive-review) | MotorTrend scales, 3,745 lb. |
| weight distribution measured xdrive | 54, 46 | % front/rear | M | [MT_XD](https://www.motortrend.com/news/2022-bmw-m3-competition-pvoty-review) | 3,899 lb. |
| xdrive masses | DIN kg = 1780; EU kg = 1855; US curb lb = 3990; MT measured lb = 3899; CD measured lb = 3929 |  | P | [BMW_US22XD](https://newsroom.bmwgroup.com/americas/download/5c120393-bb1b-4ec4-8785-8d41e50a4f6f/20260728141746562-334.pdf) | US curb is F (BMW_US22XD); DIN/EU figures from BMW regional pages via search extracts (not opened); measured from MT_XD and CD_XD (Edition 50 Jahre with carbon buckets and CCB). |
| weight savers | M Race Track Package about -25 kg; M Carbon bucket seats save 21 lb (9.5 kg); CFRP roof standard |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Seat saving from BMW_US21. |

## Dimensions

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| length | 4794 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| width | 1903 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| width with mirrors | 2068 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | From the dimension drawing; US 81.4 in. |
| height | 1433 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Unladen; the drawing shows 1,437. |
| wheelbase | 2857 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| track front | 1617 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US 63.7 in. |
| track rear | 1605 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US 63.2 in. |
| front overhang | 860 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | From the dimension drawing. |
| rear overhang | 1077 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | From the dimension drawing. |
| ground clearance | 120 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US 4.7 in. |
| frontal area | 2.34 | m^2 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| turning circle | 12.2 | m | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Measured 12.1 m (AMS), 40.0 ft = 12.2 m (MT_COMP). |
| fuel tank | 59 | L | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| luggage | 480 | L | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |

## Tyres and wheels

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| standard EU RWD | front = 275/40 ZR18 103Y XL on 9.5J x 18; rear = 285/35 ZR19 103Y XL on 10.5J x 19 |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Forged M light-alloy wheels. US 2021 sheet lists the same as standard. |
| optional and xdrive standard | front = 275/35 ZR19 (100Y) on 9.5J x 19; rear = 285/30 ZR20 (99Y) on 10.5J x 20 |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Standard on M xDrive and in Canada; fitted to every magazine test car found. Load indices from CD_RWD. |
| oe tyre models | Michelin Pilot Sport 4S (star-marked), Pirelli P Zero PZ4 (star-marked), Michelin Pilot Sport Cup 2 (track option, not offered in the US at launch) |  | P | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | PS4S on C/D, MT, AMS and Citizen cars; P Zero PZ4 on the C/D xDrive car (CD_XD); Cup 2 option per BMW_CA and MT_FT. |
| tyre diameter rear 20in | 679 | mm | E | CALC | 285/30 R20 geometry: 508 + 2 x 85.5. |

## Brakes

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| standard | M Compound: front 380 mm vented discs, 6-piston fixed calipers; rear 370 mm vented discs, single-piston floating calipers with integrated parking brake |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Calipers blue as standard. |
| standard disc thickness | front mm = 36; rear mm = 24 | mm | P | [DISC_PARTS](https://azcarparts.co.uk/products/for-bmw-m3-g80-g81-m4-g82-g83-competition-rear-left-right-brake-discs-pair-370mm) | 380 x 36 and 370 x 24 from replacement-part listings. |
| carbon ceramic option | M Carbon ceramic: 400 mm front, 380 mm rear, gold calipers |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Front 400 x 38 mm per Turner note (P, indirect). C/D lists 15.7-in/15.0-in cross-drilled carbon-ceramic discs on its test cars. |
| brake system | Integrated braking system (brake-by-wire module, electric actuator) with Comfort/Sport pedal-feel settings |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| braking 70 0 mph | 150 | ft | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | 45.7 m, carbon-ceramic brakes, PS4S. xDrive: 153 ft (CD_XD). |
| braking 100 0 mph | 297 | ft | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | 90.5 m. xDrive: 297 ft. |
| braking 60 0 mph | 102 | ft | M | [MT_FT](https://www.motortrend.com/cars/bmw/m3/2021/2021-bmw-m3-sedan-first-test-drive-review) | 31.1 m. xDrive: 105 ft (MT_XD). |
| braking 100 0 kmh | 34 | m | E | CALC | No European measurement found. Scaling MT's 60-0 (v^2) gives 33.3 m; scaling C/D's 70-0 gives 36.0 m. Mean decelerations 1.18 g (MT) and 1.09 g (C/D). |

## Aerodynamics

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| drag coefficient | 0.33 |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | US Cx 0.33 (M4 0.34). |
| frontal area | 2.34 | m^2 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| CdA | 0.772 | m^2 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | 0.33 x 2.34 from BMW's 'cd x A' entry. |
| downforce | not published | N | E | CALC | Not published. BMW says the extended sills/aprons 'increase downforce in the underbody area' and the lip, Air Curtain flics and roof fins optimise aero balance (BMW_PK). For simulation assume near-zero net lift (small ClA, about 0.05-0.10 m^2 per axle). |
| active aero | None documented |  | A | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | No moving aero devices are mentioned in the press kit. |
| drag force at 250kmh | 2234 | N | E | CALC | 0.5 x 1.2 kg/m^3 x (69.4 m/s)^2 x 0.772; about 155 kW. |

## Suspension and steering

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| front | Double-joint spring-strut axle, aluminium wishbones and torque arm, forged swivel bearing; large castor and kingpin angles; lowered roll centre |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| rear | Five-link axle in aluminium/steel, rear subframe rigidly bolted to the body |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| anti roll bars | Front and rear |  | M | [AMS](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) |  |
| dampers | Adaptive M suspension: electronically controlled dampers, electromagnetic valves per wheel, Comfort / Sport / Sport Plus |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| spring rates | front N per m at wheel = 43000; rear N per m at wheel = 48000 | N/m | E | CALC | Not published. From ride frequencies 1.6 Hz front / 1.8 Hz rear, EU mass 1,805 kg at 53.1/46.9, about 50 kg unsprung per corner. |
| ride height | Ground clearance 120 mm | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| cog height | 0.49 | m | E | CALC | Not published. Typical for a lowered sedan with CFRP roof. |
| steering | Electric power steering with M Servotronic and variable sport ratio; Comfort/Sport modes |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| steering ratio | 15 | :1 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | M xDrive 14.6:1 (BMW_US22XD). |
| lock to lock turns | 2 | turns | M | [MT_COMP](https://www.motortrend.com/reviews/2021-bmw-m3-competition-vs-alfa-romeo-giulia-quadrifoglio-comparison-test-review) | AMS measured 2.25 turns; 370 mm wheel diameter (AMS). |
| turning circle | 12.2 | m | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |

## Performance

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| factory 0 100 kmh | 3.9 | s | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | M xDrive 3.5 s. |
| factory 0 60 mph | 3.8 | s | F | [BMW_US21](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) | M xDrive 3.4 s (BMW_US22XD). |
| factory 0 200 kmh | 12.5 | s | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |  |
| factory 80 120 kmh | 4th = 2.6; 5th = 3.4 | s | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| top speed | 250 | km/h | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Electronically limited (155 mph). |
| top speed m drivers package | 290 | km/h | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | 180 mph. |
| top speed measured gps | 293 | km/h | M | [MOTOR1_VMAX](https://www.motor1.com/news/497131/g80-m3-competition-top-speed-run/) | AutoTopNL GPS run with M Driver's Package (182 mph); from a search extract, page not loaded. |
| top speed unrestricted estimate | 315 | km/h | E | CALC | Power balance: 330 kW at the wheels vs CdA 0.772 m^2 and 1.2% rolling resistance; would sit near 6,500 rpm in 7th. |
| CD RWD 2021 | 0 60 mph = 3.5; 0 100 mph = 7.6; quarter mile = 11.6 s @ 124 mph; 0 130 mph = 12.8; 0 150 mph = 18.3; rolling 5 60 = 4.5; top gear 30 50 = 2.4; top gear 50 70 = 2.7; braking 70 0 ft = 150; braking 100 0 mph ft = 297; skidpad g = 1.03; curb lb = 3820 | s unless stated | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | Results omit 1-ft rollout (0.2 s). Michelin PS4S, carbon-ceramic brakes. |
| MT RWD 2021 | 0 30 mph = 1.6; 0 40 = 2.2; 0 50 = 2.8; 0 60 = 3.5; 0 70 = 4.4; 0 80 = 5.3; 0 90 = 6.4; 0 100 mph = 7.5; quarter mile = 11.6 s @ 125.6 mph; passing 45 65 = 1.4; braking 60 0 ft = 102; lateral g avg = 1.03; figure eight = 23.8 s @ 0.85 g; 0 100 0 mph = 11.3; curb lb = 3745 | s unless stated | M | [MT_COMP](https://www.motortrend.com/reviews/2021-bmw-m3-competition-vs-alfa-romeo-giulia-quadrifoglio-comparison-test-review) | First published 2021-04-20 (MT_FT). |
| CITIZEN 2021 | 0 100 kmh = 3.64; quarter mile = 11.58 s @ 201.21 km/h; half mile = 18.06 s @ 243.29 km/h; 1 km = 20.75 s @ 256.46 km/h; 60 100 kmh = 2.21 s (3rd) / 2.95 s (4th); 80 120 kmh = 2.67 s (4th) / 4.02 s (5th); 100 200 kmh = 8.01 s (from 3rd) | s | M | [CITIZEN_SHEET](https://media.citizen.co.za/wp-content/uploads/2021/04/M3data.pdf) | South Africa, 14 April 2021, 15 deg C, Michelin PS4S 275/35 R19 / 285/30 R20. Test altitude not stated. |
| estimated 0 200 kmh measured basis | 11.7 | s | E | CALC | Citizen 0-100 (3.64) + 100-200 (8.01) plus about 0.1 s for the shift overlap; quicker than BMW's 12.5 s, consistent with an underrated engine. |
| CD XDRIVE 2023 | 0 30 mph = 1.0; 0 60 mph = 2.8; 0 100 mph = 7.0; quarter mile = 11.0 s @ 124 mph; 0 130 mph = 12.3; 0 150 mph = 18.2; rolling 5 60 = 4.2; braking 70 0 ft = 153; braking 100 0 mph ft = 297; skidpad g = 1.03; curb lb = 3929 | s unless stated | M | [CD_XD](https://www.caranddriver.com/reviews/a43389602/2023-bmw-m3-competition-xdrive-edition-50-jahre-by-the-numbers/) | M xDrive, for comparison only. |
| MT XDRIVE 2022 | 0 60 mph = 3.0; 0 100 mph = 7.2; quarter mile = 11.1 s @ 124.7 mph; braking 60 0 ft = 105; lateral g avg = 1.03; figure eight = 23.3 s @ 0.89 g; curb lb = 3899; dist = 54/46 | s unless stated | M | [MT_XD](https://www.motortrend.com/news/2022-bmw-m3-competition-pvoty-review) | M xDrive, for comparison only. |

## Sound

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| exhaust layout | Per bank: 3-into-1 manifold cast into the turbine housing -> mono-scroll turbo -> close-coupled ceramic-monolith catalyst (one per bank) -> [EU/RoW only] underbody catalyst + gasoline particulate filter per branch -> centre silencer -> large rear silencer with two electric flaps in the outer tailpipes -> 4 tailpipes in two twin pairs, 100 mm each (Black Chrome on Competition). Dual-branch (cylinders 1-3 / 4-6) 'cylinder-dependent twin-pipe design'; the tailpipes are internally interconnected so gas always exits all four. |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Component order from the S58 training manual (F97/F98, same engine family); dual-branch, rear silencer, quad 100 mm tips and flaps for G80 from BMW_PK. G80-specific centre-silencer details not seen. |
| flap logic | Flaps are binary (fully open or closed, PWM 10% open / 90% closed). Closed at low rpm/low load for comfort and urban pass-by noise; open at high rpm/high load. SPORT / SPORT+ change timbre and intensity; the M Sound Control button keeps the flaps closed as long as possible and reduces ASD, overriding the drive mode. |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | Behaviour documented for S58 in F97/F98; G80 press kit describes the same SPORT/SPORT+/M Sound Control logic (BMW_PK). |
| turbo sound character | Two mono-scroll turbos with even 240-deg pulse spacing per branch; electric wastegates; no documented blow-off valve. Reviewers mainly note lag below about 2,750 rpm rather than turbo noise. |  | E | CALC | No published description of turbo whistle found. Gap. |
| cd interior 70mph | 72 | dBA | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) | Steady 70 mph; four dB quieter than the previous M3 Competition. |
| cd interior full throttle | 84 | dBA | M | [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) |  |
| cd interior idle | not published | dBA | M | [CD_COMP](https://www.caranddriver.com/reviews/comparison-test/a37179788/2021-alfa-romeo-giulia-quadrifoglio-vs-2021-bmw-m3-competition-compared/) | Not printed in the text; the comparison says the M3 was quieter than the Alfa at idle and 70 mph. Gap. AMS idle figure below. |
| ams interior | idle = 45; max full throttle = 82; 80 kmh = 68; 100 kmh = 70; 130 kmh = 73; 160 kmh = 76; 180 kmh = 78 | dB(A) | M | [AMS](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) | Test date 04/2021, automatic, PS4S 19/20-inch. |
| eu stationary noise | 89 | dB(A) at 3,750 rpm | P | [BMW_WEB_NOISE](https://www.bmw.com.mt/en/all-models/m-series/bmw-3-series-m-models/bmw-m3-sedan-technical-data.html) | From search extracts of BMW Malta/Malaysia technical-data pages for the M3 Competition (model year not visible). The 2024 G80 pages (Ireland/UK) show 91 dB(A) at 3,750 rpm. Low confidence: not read from a homologation document. |
| eu pass by noise | 73 | dB(A) | P | [ADAC](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/bmw/3er-reihe/g20-g21-g80-g81-facelift/325314) | ADAC 'Fahrgeraeusch' for M3 Competition Steptronic 07/22-05/24 (UN R51.03). BMW Malta/Malaysia extracts show 72 dB(A); 2024 Irish/UK extracts show 69 dB(A) for M xDrive. |
| active sound design | Fitted: engine orders are added through the audio system (ASD in the passenger compartment). It can be reduced with the M Sound Control button or switched off in a menu. |  | F | [BMW_ST1926](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) | C/D: 'At least you can turn off the auto-tune effect via a menu on the touchscreen' (CD_RWD). evo: 'augmented through the speakers' (EVO). |
| asd share estimate | About half of the in-cabin engine sound under load in SPORT/SPORT+ is speaker-generated; less in COMFORT or with M Sound Control active |  | E | CALC | No published figure. Estimate from reviewer comments (C/D wanting more natural sound; evo calling it augmented but authentic). Use as a mixing guide only. |
| limiter behaviour | Redline 7,200 rpm, limiter at about 7,250 rpm; in M mode the car holds the limiter rather than upshifting; expect a fast fuel/ignition-cut bounce. |  | P | [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon) | Bounce character is E. |
| overrun pops by mode | Not documented by BMW. Stock EU cars sound muted outside (OPF). Expected: COMFORT/EFFICIENT - flaps mostly closed, little or no crackle; SPORT - light burble on lift-off from mid rpm; SPORT+ - most frequent burbles, still mild. M Sound Control suppresses them. |  | E | CALC | evo: 'fires with a satisfying burble' (start-up); a G80 owner reports the sound button 'cancels the burbles' (ASD_FORUM, anecdotal). |
| audio engineer notes | Fundamental firing frequency = rpm/20 Hz (3rd engine order); each exhaust branch carries the 1.5th order, so slight bank-to-bank differences add 1.5-order content. Rev range for loops: about 700 (idle) to 7,250 (limiter). Strong torque plateau 2,750-5,500 rpm means load-dependent timbre should change most around 2,000-3,000 rpm (boost onset). |  | E | CALC |  |

### Reviewer descriptions (quotes under 25 words)

- "The S58 motor fires with a satisfying burble." (evo, 2021-06-18, [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon))
- "It may be augmented through the speakers, but it's as authentic a sound as you could hope for." (evo, 2021-06-18, [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon))
- "the latest emission filters stuffed into the system result in a rather muted tone" (evo, 2021-06-18, [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon))
- "it has a certain timbre and hollow resonance that suits its brutish appearance." (evo, 2021-06-18, [EVO](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon))
- "Maximum thrust results in 84 decibels of silky inline-six growl" (Car and Driver, 2021-08-12, [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/))
- "we still wish BMW would let more of the engine's natural song into the cabin instead of boosting it through the audio system." (Car and Driver, 2021-08-12, [CD_RWD](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/))
- "it suffers from the on-off nature of turbo lag" (Car and Driver, 2021-08-05, [CD_COMP](https://www.caranddriver.com/reviews/comparison-test/a37179788/2021-alfa-romeo-giulia-quadrifoglio-vs-2021-bmw-m3-competition-compared/))
- "it isn't an indisputably wonderful straight-six." (PistonHeads, 2021-03-10, [PH](https://www.pistonheads.com/news/ph-driven/2021-bmw-m3-competition-g80-ph-review/43852))
- "a deep cold start roar" (Machines With Souls, 2021-02-20, [MWS](https://machineswithsouls.com/the-bmw-g80-m3-review/))

### Reference videos (links only)

- [Launch control on a G80 M3 Competition (onboard, shows procedure and launch revs)](https://www.youtube.com/watch?v=IPx546s2jYI) (found via [article](https://www.bmwblog.com/2021/07/07/video-how-to-activate-launch-control-on-the-new-bmw-m3-competition/))
- [Stock vs Milltek exhaust, G80 M3 Competition (useful stock reference; verify which segments are stock)](https://www.youtube.com/watch?v=TykrxACLwSk) (found via [article](https://www.bmwblog.com/2021/11/30/g80-bmw-m3-competition-milltek))
- [G82 M4 vs F82 M4 vs E92 M3 sound and exhaust comparison (stock S58 coupe)](https://www.youtube.com/watch?v=brCVctt293g) (found via [article](https://www.bmwblog.com/2021/02/21/g82-m4-vs-f82-m4-vs-e92-m3-sound-exhaust))
- [Second video embedded in the same comparison article](https://www.youtube.com/watch?v=gsi6K9gfzyQ) (found via [article](https://www.bmwblog.com/2021/02/21/g82-m4-vs-f82-m4-vs-e92-m3-sound-exhaust))
- [Fi Exhaust on a G80 M3 Competition (aftermarket, much louder than stock)](https://www.youtube.com/watch?v=qv_a5bJeFPg) (found via [COMMONS_AUDIO](https://commons.wikimedia.org/wiki/File:BMW_M3_(G80)_Competition_with_Fi_Exhaust_-_engine_and_exhaust_sound_(YouTube_qv_a5bJeFPg).opus))
- [Fi Exhaust G80 M3 (aftermarket)](https://www.youtube.com/watch?v=_8_PyKTz2a0) (found via [article](https://www.bmwblog.com/2021/10/15/video-the-fi-exhaust-system-for-the-g80-bmw-m3-sounds-crazy))
- [Dyno run, base manual G80 M3 (AutoTopNL)](https://www.youtube.com/watch?v=oScJr9s78QU) (found via [BMWBLOG_DYNO](https://www.bmwblog.com/2021/04/10/zanzibar-bmw-m3-dyno/))
- [Dyno run, M4 Competition with Akrapovic exhaust (S58 Competition)](https://www.youtube.com/watch?v=WYyuGe_-Frg) (found via [article](https://www.bmwblog.com/2021/12/04/2021-bmw-m4-competition-akrapovic-dyno))

Links only, nothing downloaded from YouTube. IDs were taken from embeds in the listed articles; titles were not checked on YouTube. No stock flyby or autobahn onboard link could be confirmed before the search budget ran out.

### Freely licensed recordings downloaded

- `research_notes/cars/audio/RefM3G80/G80_M3_Competition_FiExhaust_CC-BY-3.0_FiExhaust.opus`: start-up, revving or acceleration, 80.7 s, Ogg Opus, 48 kHz stereo, 120 kb/s. Licence: CC BY 3.0 (YouTube Creative Commons option; Commons licence review still pending). Attribution: FiExhaust (YouTube), via Wikimedia Commons. [Commons page](https://commons.wikimedia.org/wiki/File:BMW_M3_(G80)_Competition_with_Fi_Exhaust_-_engine_and_exhaust_sound_(YouTube_qv_a5bJeFPg).opus). **Caveat:** Aftermarket Fi Exhaust, not the stock system. Reference for engine orders and rev behaviour only, not for stock loudness or timbre. Confirm the licence review before any in-game use.

## Visual blockout

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| body style | Four-door notchback sports sedan; long bonnet, cab set back, short boot with integrated lip spoiler |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| engine position | Front, longitudinal inline-6 roughly over and behind the front axle line |  | A | [AMS](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) |  |
| method | Proportions measured on BMW's orthographic side drawing (pixel scale 3.71 mm/px, heights normalised to the 1,433 mm roof); cross-checked by eye against a CC BY-SA 4.0 Commons photo (front three-quarter, not a pure profile; no pure profile was found among 40 sampled Commons files) |  | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Photo: COMMONS_PHOTO; category: COMMONS_CAT. |
| front axle fraction of length | 0.179 | fraction from front | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | 860 / 4,794. |
| rear axle fraction of length | 0.775 | fraction from front | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | (860 + 2,857) / 4,794. |
| windscreen base fraction | 0.31 | fraction from front | E | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | About 1.50 m from the nose, height about 0.99 m (cowl). |
| windscreen top fraction | 0.49 | fraction from front | E | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Roof header about 2.35 m from the nose at about 1.40 m. |
| roof peak fraction | 0.59 | fraction from front | E | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | About 2.82 m from the nose, near the B-pillar. Roof stays within 10 mm of peak from 0.53 to 0.68. |
| roof height | 1433 | mm | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | A small shark-fin antenna sits at about 0.71 L. |
| rear screen fractions | 0.74, 0.9 | fraction from front | E | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Rear screen runs from the roof end (about 1.39 m high) down to the boot lid (about 1.07 m). |
| nose shape | Tall, blunt, near-vertical front face dominated by a very large vertical twin-kidney grille; bonnet top about 0.64 m at the nose rising to about 0.99 m at the cowl; deep front apron with outer vertical air-curtain intakes |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Heights E from the drawing. |
| tail shape | Short notchback deck ending in a body-colour or gloss-black lip spoiler at about 1.04 m; near-vertical tail face; black diffuser with four 100 mm tips in two pairs |  | F | [BMW_PK](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) | Height E from the drawing. |
| wheel size visual | Tyre outer diameter about 0.68 m front and rear | m | E | CALC |  |

### Upper silhouette for a stand-in model

Fraction of overall length from the nose (0 = front bumper, 1 = rear bumper) against top-of-body height. Front axle at 0.179, rear axle at 0.775.

| x / L | height mm |
|---|---|
| 0.00 | 640 |
| 0.03 | 771 |
| 0.06 | 833 |
| 0.09 | 880 |
| 0.12 | 912 |
| 0.16 | 935 |
| 0.19 | 949 |
| 0.22 | 963 |
| 0.25 | 971 |
| 0.28 | 982 |
| 0.31 | 993 |
| 0.34 | 1087 |
| 0.37 | 1174 |
| 0.40 | 1254 |
| 0.43 | 1327 |
| 0.46 | 1378 |
| 0.50 | 1403 |
| 0.53 | 1418 |
| 0.56 | 1426 |
| 0.59 | 1433 |
| 0.62 | 1429 |
| 0.65 | 1426 |
| 0.68 | 1414 |
| 0.74 | 1389 |
| 0.77 | 1320 |
| 0.81 | 1262 |
| 0.84 | 1200 |
| 0.87 | 1135 |
| 0.90 | 1076 |
| 0.93 | 1051 |
| 0.96 | 1037 |
| 0.99 | 600 |

Photo checked: [COMMONS_PHOTO](https://commons.wikimedia.org/wiki/File:BMW_G80_M3_Competition_M_xDrive_Black_Sapphire_Metallic_(3).jpg) (CC BY-SA 4.0, Damian B Oh). Category sampled: [COMMONS_CAT](https://commons.wikimedia.org/wiki/Category:BMW_M3_Competition_(G80)).

## Derived values for the builder

| Item | Value | Unit | Tag | Source | Note |
|---|---|---|---|---|---|
| simulated mass with driver | 1805 | kg | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | EU unladen weight already includes 75 kg driver/luggage; equals DIN 1,730 + 75. |
| static wheel loads | front each N = 4700; rear each N = 4150 | N | E | CALC | 1,805 kg x 9.81 x 53.1% / 2 and x 46.9% / 2. |
| drag area for sim | 0.772 | m^2 | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |  |
| performance targets | zeroTo100 = 3.9; zeroTo200 = 12.5; topSpeedKmh = 250; topSpeedKmh MDriversPackage = 290 | s / km/h | F | [BMW_SPEC_M3](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) | Magazine tests run about 0.3 s quicker to 100 km/h (Citizen 3.64 s). |

## Gaps

- Turbo model/frame size and compressor maps (only maker MHI and part numbers known).
- Boost-versus-rpm curve (only the 1.7 bar maximum is published).
- Idle rpm, cold-start idle and exact launch-control rpm (only a secondary 2,700 rpm figure).
- Engine mass and rotating inertia.
- Gearbox shift times and torque-converter stall speed.
- Active M Differential preload/lock values.
- Spring, damper and anti-roll-bar rates, CoG height, roll centres, alignment.
- Downforce or lift coefficients (BMW gives only Cd x A).
- Car and Driver idle dBA (not in the article text); AMS idle 45 dB(A) used instead.
- EU stationary and pass-by noise for the exact pre-LCI RWD car from a homologation document (CoC); current values come from search extracts of JavaScript pages and ADAC.
- Share of cabin sound produced by Active Sound Design.
- Overrun pop/crackle behaviour by drive mode (undocumented; estimated).
- European instrumented 100-0 km/h braking and 0-200 km/h (behind the AMS paywall).
- A verified top-speed run (only a search extract of 293 km/h).
- A freely licensed recording of a stock car, and stock flyby/onboard video links (search budget ran out).
- A freely licensed pure side-profile photo (BMW's press drawing used instead).
- Firing order is the BMW inline-six standard; not seen in an S58-specific document.
- Exact 2024 LCI changes for the RWD car.

## Sources

| Id | Title | Publisher | Date | Link |
|---|---|---|---|---|
| BMW_PK | The new BMW M3 Sedan and BMW M3 Competition Sedan. The new BMW M4 Coupe and BMW M4 Competition Coupe (full press kit, 32 pp.) | BMW Group PressClub | 2020-09 | [link 1](https://newsroom.bmwgroup.com/emea/download/7e3ab005-7810-4dfa-aee4-b1447be7ca79/20260909073602947-257.pdf) |
| BMW_SPEC_M3 | Specifications. The BMW M3 Sedan / M3 Competition Sedan (spec tables, output diagram, dimension drawing) | BMW Group PressClub | 2020-09 | [link 1](https://newsroom.bmwgroup.com/emea/download/76ac3089-d57b-44fb-9ea4-92409ea2fc4c/20260909073603867-778.pdf) |
| BMW_SPEC_M4 | Specifications. The BMW M4 Coupe / M4 Competition Coupe (contains the 375 kW / 650 Nm Competition output and torque diagram) | BMW Group PressClub | 2020-09 | [link 1](https://newsroom.bmwgroup.com/emea/download/f92f5ad6-e9e9-4ac9-9191-0855eec11dfe/20260909073605409-124.pdf) |
| BMW_PR_ARTICLE | Press article page for the kit above (South Africa mirror of T0316649EN) | BMW Group PressClub | 2020-09 | [link 1](https://www.press.bmwgroup.com/south-africa/article/attachment/T0317466EN/461004) |
| BMW_US21 | The New 2021 BMW M3 Sedan and M4 Coupe (US press release with US specification table) | BMW of North America (BMW Group PressClub USA) | 2020-09 | [link 1](https://newsroom.bmwgroup.com/americas/download/08e69a09-1c81-4afb-abe8-91c294b68f37/20260728141634340-734.pdf) |
| BMW_US22XD | The new 2022 BMW M3 Competition xDrive Sedan and M4 Competition xDrive Coupe (US release with spec table) | BMW of North America (BMW Group PressClub USA) | 2021 | [link 1](https://newsroom.bmwgroup.com/americas/download/5c120393-bb1b-4ec4-8785-8d41e50a4f6f/20260728141746562-334.pdf) |
| BMW_CA | The New 2021 BMW M3 Sedan and M4 Coupe (Canada media information) | BMW Group Canada | 2020-09-22 | [link 1](https://newsroom.bmwgroup.com/americas/download/4c998b86-b012-4206-afb6-697faed51e93/20260731091652557-379.pdf) |
| BMW_ST1926 | Technical training manual ST1926 'S58 Engine' (written for F97 X3 M / F98 X4 M; same S58 family) | BMW of North America (bmwtechinfo); copy read from BimmerPost mirror | 2019 | [link 1](https://bmwtechinfo.bmwgroup.com/tech_training_manual/ST1926%20S58%20Engine.pdf) |
| BMW_ST1926_MIRROR | Mirror of ST1926 used for reading | BimmerPost | 2019 | [link 1](https://www.bimmerpost.com/goodiesforyou/docs/ST1926-S58-Engine.pdf) |
| CD_RWD | Tested: 2021 BMW M3 Competition Is a Quicker M3 (Mike Sutton) | Car and Driver | 2021-08-12 | [link 1](https://www.caranddriver.com/reviews/a37286079/2021-bmw-m3-competition-by-the-numbers/) |
| CD_COMP | 2021 Alfa Romeo Giulia Quadrifoglio vs. 2021 BMW M3 Competition (K.C. Colwell) | Car and Driver | 2021-08-05 | [link 1](https://www.caranddriver.com/reviews/comparison-test/a37179788/2021-alfa-romeo-giulia-quadrifoglio-vs-2021-bmw-m3-competition-compared/) |
| CD_XD | 2023 BMW M3 Competition xDrive Edition 50 Jahre tested (David Beard) | Car and Driver | 2023-03-30 | [link 1](https://www.caranddriver.com/reviews/a43389602/2023-bmw-m3-competition-xdrive-edition-50-jahre-by-the-numbers/) |
| MT_FT | 2021 BMW M3 Sedan First Test Review: Does the Face Ruin the Fun? (Jonny Lieberman; car is an M3 Competition) | MotorTrend | 2021-04-20 | [link 1](https://www.motortrend.com/cars/bmw/m3/2021/2021-bmw-m3-sedan-first-test-drive-review) |
| MT_COMP | 2021 BMW M3 Competition vs. Alfa Romeo Giulia Quadrifoglio Comparison Test: Four-Door Fire | MotorTrend | 2021-06-29 | [link 1](https://www.motortrend.com/reviews/2021-bmw-m3-competition-vs-alfa-romeo-giulia-quadrifoglio-comparison-test-review) |
| MT_XD | 2022 BMW M3 Competition PVOTY Review: Underrated In More Ways Than One (xDrive car) | MotorTrend | 2022-02-10 | [link 1](https://www.motortrend.com/news/2022-bmw-m3-competition-pvoty-review) |
| MT_XD_COMP | 2022 BMW M3 Competition vs. Cadillac CT4-V Blackwing: Last in Line (xDrive car) | MotorTrend | 2022-01-12 | [link 1](https://www.motortrend.com/reviews/2022-bmw-m3-competition-vs-cadillac-ct4-v-blackwing-comparison-test-review) |
| AMS | Kosten und Realverbrauch: BMW M3 Competition - Technische Daten (test car, test date 04/2021) | auto motor und sport | 2021-04 | [link 1](https://www.auto-motor-und-sport.de/test/kosten-realverbrauch-bmw-m3-competition/technische-daten/) |
| CITIZEN_SHEET | BMW M3 Competition road-test data sheet (test date 14 April 2021, 15 deg C) | The Citizen (South Africa) | 2021-04-14 | [link 1](https://media.citizen.co.za/wp-content/uploads/2021/04/M3data.pdf) |
| CITIZEN_ART | BMW M3 Competition lives up to the hype | The Citizen (South Africa) | 2021-04-24 | [link 1](https://citizen.co.za/motoring/bmw-m3-competition-lives-up-to-the-hype) |
| ADAC | Autokatalog: BMW M3 Competition Steptronic (07/22 - 05/24) | ADAC | accessed 2026-11-13 | [link 1](https://www.adac.de/rund-ums-fahrzeug/autokatalog/marken-modelle/bmw/3er-reihe/g20-g21-g80-g81-facelift/325314) |
| BMW_WEB_NOISE | BMW market technical-data pages (Malta, Malaysia; Ireland/UK 2024 G80). Pages render with JavaScript and would not load; values come from search-result extracts of those pages | BMW (regional websites) | accessed 2026-11-13 | [link 1](https://www.bmw.com.mt/en/all-models/m-series/bmw-3-series-m-models/bmw-m3-sedan-technical-data.html) ; [link 2](https://www.bmw.com.my/en/all-models/m-series/bmw-3-series-m-models/bmw-m3-sedan-technical-data.html) ; [link 3](https://www.bmw.ie/en/all-models/m-series/m3-series/m3-series-saloon-2024-g80-technical-data.html) |
| EVO | BMW M3 Competition 2021 review - still the benchmark performance saloon (Yousuf Ashraf; page updated since) | evo | 2021-06-18 | [link 1](https://www.evo.co.uk/bmw/m3-saloon/203950/bmw-m3-competition-2021-review-still-the-benchmark-performance-saloon) |
| PH | 2021 BMW M3 Competition (G80) / PH Review (Matt Bird) | PistonHeads | 2021-03-10 | [link 1](https://www.pistonheads.com/news/ph-driven/2021-bmw-m3-competition-g80-ph-review/43852) |
| MWS | Get past the nose - I love the new G80 M3 | Machines With Souls | 2021-02-20 | [link 1](https://machineswithsouls.com/the-bmw-g80-m3-review/) |
| ARM_DYNO | S58 Stock Dyno Results (stock 2022 G82 M4 Competition xDrive, Mustang dynamometer, 93 octane) | ARM Motorsports | page dated 2026-06-02 | [link 1](https://armmotorsports.com/blogs/news/s58-stock-dyno-results) |
| ARM_DYNO_IMG | Dyno chart image used for digitising | ARM Motorsports | 2026 | [link 1](https://cdn.shopify.com/s/files/1/0082/6687/4995/files/S58_Stock_Dyno_957b04d7-71f8-400c-a3d3-7ca18013f327.jpg) |
| BMWBLOG_DYNO | VIDEO: AutoTopNL's Zanzibar Metallic BMW M3 Goes on a Dyno (base manual M3) | BMWBlog | 2021-04-10 | [link 1](https://www.bmwblog.com/2021/04/10/zanzibar-bmw-m3-dyno/) |
| TURNER_TURBO | OEM Mitsubishi turbocharger + exhaust manifold replacement set, BMW S58 (part nos. 11658469097 / 11658469098) | Turner Motorsport | accessed 2026-11-13 | [link 1](https://www.turnermotorsport.com/p-53290951-oem-mitsubishi-turbocharger-exhaust-manifold-replacement-set-bmw-s58-30l/) |
| TURNER_8HP76 | Automatic Transmission Service Kit - 8HP76 - BMW G87 M2, G80 M3 Comp, G82/83 M4 Comp | Turner Motorsport | accessed 2026-11-13 | [link 1](https://www.turnermotorsport.com/p-31125611-automatic-transmission-service-kit-8hp76/) |
| LEEBMANN_TC | BMW repair kit torque converter GA8HP76 (fitment G80 M3 Competition, type codes 31AY/32AY) | Leebmann24 | accessed 2026-11-13 | [link 1](https://www.leebmann24.com/cz/en/product/bmw-repair-kit-torque-converter-10129714) |
| DISC_PARTS | Replacement disc listings for G80/G82 Competition: front 380 x 36 mm, rear 370 x 24 mm; Turner note on 400 x 38 mm carbon-ceramic | azcarparts / Turner Motorsport (parts retailers) | accessed 2026-11-13 | [link 1](https://azcarparts.co.uk/products/for-bmw-m3-g80-g81-m4-g82-g83-competition-rear-left-right-brake-discs-pair-370mm) ; [link 2](https://www.turnermotorsport.com/p-38419088-front-2-piece-carbon-ceramic-brake-rotors-pair-380x36mm/) |
| WIKI_B58 | BMW B58 (S58 section) | Wikipedia | accessed 2026-11-13 | [link 1](https://en.wikipedia.org/wiki/BMW_B58) |
| FIRING | BMW inline-six firing order 1-5-3-6-2-4 (BMW training document ST501 'Engine Diagnosis' via archive.org; GT Spark Plugs BMW inline-6 page; seen as search-result extracts, not opened) | BMW NA training (archive.org) / gtsparkplugs.com | various | [link 1](https://archive.org/download/BMWTechnicalTrainingDocuments/ST501%20New%20Engine%20Technology/02_Engine%20Diagnosis.pdf) ; [link 2](https://gtsparkplugs.com/firing-order-bmw-inline-6.html) |
| OPF_VENDORS | G80 exhaust guides noting EU cars carry an OPF/GPF and US cars generally do not | CenCal Motorsport / JD Customs (vendors) | accessed 2026-11-13 | [link 1](https://cencalmotorsport.com/blogs/cc-paddock/bmw-g80-m3-exhaust-guide-catback-downpipes-and-everything-that-changes-the-sound) ; [link 2](https://jdcustomsusa.com/collections/bmw-g80-m3-exhaust-manifold) |
| BMAG_LC | BMW Launch Control - How It Works and Which Models Have It | Bimmer Mag | 2025-05-09 | [link 1](https://www.bimmer-mag.com/?p=2655) |
| ASD_FORUM | G80 owner forum thread on M Sound / Active Sound Design and burbles (anecdotal) | G80.Bimmerpost | 2021-10-11 | [link 1](https://g80.bimmerpost.com/forums/showthread.php?p=28140991) |
| MOTOR1_VMAX | 2021 BMW M3 Competition Impresses In Top Speed Run (AutoTopNL GPS run; page did not load, figure from search extract) | Motor1 | 2021 | [link 1](https://www.motor1.com/news/497131/g80-m3-competition-top-speed-run/) |
| COMMONS_PHOTO | File:BMW G80 M3 Competition M xDrive Black Sapphire Metallic (3).jpg (Damian B Oh, CC BY-SA 4.0, taken 2024-06-29) | Wikimedia Commons | 2024-06-29 | [link 1](https://commons.wikimedia.org/wiki/File:BMW_G80_M3_Competition_M_xDrive_Black_Sapphire_Metallic_(3).jpg) |
| COMMONS_CAT | Category:BMW M3 Competition (G80) (40 photos sampled; no pure side profile found) | Wikimedia Commons | accessed 2026-11-13 | [link 1](https://commons.wikimedia.org/wiki/Category:BMW_M3_Competition_(G80)) |
| COMMONS_AUDIO | File:BMW M3 (G80) Competition with Fi Exhaust - engine and exhaust sound (YouTube qv a5bJeFPg).opus (FiExhaust, CC BY 3.0, licence review pending) | Wikimedia Commons | 2021-11-28 (original) | [link 1](https://commons.wikimedia.org/wiki/File:BMW_M3_(G80)_Competition_with_Fi_Exhaust_-_engine_and_exhaust_sound_(YouTube_qv_a5bJeFPg).opus) |
| VIDEO_EMBEDS | YouTube video IDs taken from embeds in BMWBlog articles (article URL given per video) | BMWBlog / YouTube | 2021 | [link 1](https://www.bmwblog.com/) |
| CALC | Calculation in this file from the cited inputs (method in each note) | this research | 2026-11-13 | n/a |

*Research limits: The team's shared web-search budget ran out near the end of this session, so the video list and a few gaps could not be searched further.*
