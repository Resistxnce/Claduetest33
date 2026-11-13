--[[
	Ridgeway Halcyon S (internal ID: RefC8Stingray)

	An original mid-engined American sports coupe from the fictional maker Ridgeway, built to the
	publicly documented engineering of the Chevrolet Corvette Stingray coupe (C8, 2020-2026, LT2 engine)
	with the Z51 Performance Package. No Chevrolet or Corvette names, badges or body design are used in
	the game; real names appear only in this header, `reference` and the docs, as engineering
	references. Spec sheet, sources and validation: docs/cars/RefC8Stingray.md. Research notes:
	research_notes/cars/RefC8Stingray.json and .md (source ids S01-S41 below refer to them).

	Every value is tagged:
	  [F] manufacturer figure (GM, Tremec)
	  [P] published third-party figure (spec sheets, magazines' data pages, engineering articles)
	  [M] measured in a magazine or independent test, or read from GM's published chart
	  [E] estimate made for the simulation (method in the comment or the spec sheet)
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.
	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	Not used by this naturally aspirated, dual-clutch, rear-drive car: engine.forcedInduction,
	engine.speedLimitKmh (the Z51 car is drag-limited at 184 mph), the automatic's converter and
	lock-up, drivetrain.centreCoupling.
]]

return {
	id = "RefC8Stingray",
	displayName = "Ridgeway Halcyon S",
	reference = "Chevrolet Corvette Stingray Z51 (C8) (engineering reference only)",

	mass = {
		dryKg = 1530, -- [F] GM dry weight, no fluids (S01)
		kerbKg = 1654, -- [M] Car and Driver's Z51 3LT test car with Magnetic Ride, US curb (full fluids, no driver), Oct 2019 (S13); GM's 1LT coupe without Z51 is 1,603 kg [P] (S31)
		driverKg = 75, -- [A] the simulation carries one driver
		frontShare = 0.394, -- [M] 39.4 / 60.6 measured by Car and Driver on the same car (S13); 40 / 60 in a leaked GM document [P] (S32)
		comHeight = 0.44, -- [E] not published; about 0.36 of the 1.234 m roof, as the GT12's estimate, with the dry-sump V8 mounted low (crank below the half-shafts, S07)
		-- [E] Size of the invisible box that carries the mass. It sets rotational inertia: about 2,550 kg*m^2
		-- in yaw, a radius of gyration of 1.21 m, 0.83 of front-axle-to-CoM times CoM-to-rear-axle (a
		-- mid-engine car's mass sits nearer the middle than the GT12's front-mid V12, 2,700 kg*m^2).
		inertiaBox = { width = 1.80, height = 0.70, length = 3.80 },
	},

	dimensions = {
		length = 4.630, -- [F] 182.3 in (S01); EU sheets 4,634 mm
		width = 1.934, -- [F] without mirrors (S01); 2,025 mm with mirrors
		height = 1.234, -- [F] 48.6 in (S01)
		wheelbase = 2.722, -- [F] 107.2 in (S01)
		trackFront = 1.648, -- [F] (S01)
		trackRear = 1.586, -- [F] (S01)
		frontOverhang = 0.850, -- [E] front axle to the nose, from two 3/4 photos averaged, +/-0.08 m (S36); leaves a 1.058 m rear overhang
	},

	engine = {
		layout = "90-degree V8, cross-plane crank, pushrod, 2 valves per cylinder, dry sump", -- [F] GM LT2 (S01, S07)
		displacementCc = 6162, -- [F] 6.2 L, 103.25 mm bore x 92.0 mm stroke (S01, S19)
		aspiration = "NaturallyAspirated", -- [F]
		peakPowerKw = 369, -- [F] 495 hp SAE J1349 with the Z51's NPP performance exhaust (S03)
		peakPowerRpm = 6450, -- [F] (S01, S03)
		peakTorqueNm = 637, -- [F] 470 lb-ft with NPP (S01)
		peakTorqueRpm = 5150, -- [F] (S01)
		idleRpm = 600, -- [E] not published; typical Gen V warm idle 550-650 rpm (research note)
		limiterRpm = 6600, -- [P] fuel-cut "Engine Overspeed Protection" at about 6,600 rpm in manual mode (S27); GM's torque chart ends at about 6,620 rpm (S12)
		limiterHysteresisRpm = 120, -- [E] the cut's bounce depth is undocumented; the research suggests a hard cut with a 100-150 rpm bounce
		inertia = 0.18, -- [E] kg*m^2: forged steel crank (about 0.045), damper (0.015), flexplate and torsional damper (0.05), the DCT's outer clutch drum (0.05), rods and pistons (0.015)
		-- [M] Full-throttle crank torque, {rpm, Nm}: GM's published LT2 chart (S12) read by pixel
		-- extraction, +/-4 Nm, SAE-rated with the NPP exhaust. The 5,150 and 6,450 rpm points are pinned
		-- to GM's 637 Nm and 495 hp (546 Nm = 369 kW) [F]. GM's chart ends at the 6,600 rpm cut.
		torqueCurve = {
			{ 1000, 433 }, -- [M] 319 lb-ft
			{ 1500, 491 }, -- [M] 362 lb-ft
			{ 2000, 530 }, -- [M] 391 lb-ft
			{ 2500, 545 }, -- [M] 402 lb-ft
			{ 3000, 553 }, -- [M] 408 lb-ft
			{ 3500, 567 }, -- [M] 418 lb-ft
			{ 4000, 599 }, -- [M] 442 lb-ft
			{ 4500, 624 }, -- [M] 460 lb-ft
			{ 5000, 630 }, -- [M] 465 lb-ft
			{ 5150, 637 }, -- [F] peak torque, 470 lb-ft
			{ 5500, 616 }, -- [M] 454 lb-ft
			{ 6000, 580 }, -- [M] 428 lb-ft
			{ 6450, 546 }, -- [F] peak power, 495 hp
			{ 6500, 538 }, -- [M] 397 lb-ft
			{ 6600, 525 }, -- [M] 387 lb-ft, end of GM's chart
		},
		-- [E] Closed-throttle engine braking, static + perRpm * rpm (Nm): a 6.2 L two-valve V8's friction
		-- (about 1.5-2 bar FMEP) plus pumping against a shut throttle, about 60 Nm at 3,000 rpm and 100 Nm
		-- at 6,000. The torque curve is net output, so friction isn't subtracted at full throttle.
		friction = { static = 25, perRpm = 0.0125 },
		throttleResponse = 16, -- [E] 1/s: one 87 mm drive-by-wire throttle feeding a plenum (S07, S08)
	},

	transmission = {
		type = "DualClutch", -- [F] Tremec TR-9080 (GM RPO M1L) 8-speed dual-clutch transaxle (S04)
		gearRatios = { 2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33 }, -- [F] (S02, S05, S06)
		reverseRatio = 2.63, -- [F] (S02)
		finalDrive = 5.17, -- [F] Z51 with eLSD: 1.4545 transfer gear x 3.55 ring and pinion (S04); 4.89 without Z51
		efficiency = 0.88, -- [E] DCT transaxle with a transfer gear; stock Z51 cars read 424-429 whp on wheel dynos, 86-87% of 495 hp including tyre losses (S28, S39)
		shiftTime = 0.10, -- [F] upshift clutch overlap "lasts 100 milliseconds" with no torque interruption (S04)
		-- [E] share of clutch capacity kept during a shift. GM/Tremec: the oncoming clutch takes over with
		-- "no interruption of torque delivery" [F] (S04), so it keeps about the engine's full torque
		-- (0.65 x 950 Nm = 620 Nm). The GT12's 0.35 lets the engine flare into the fuel cut on every
		-- full-throttle upshift (6,690 rpm on this car), which the real gearbox doesn't do.
		shiftTorqueFraction = 0.65,
		clutchMaxTorque = 950, -- [E] Nm, about 1.5 x peak torque; the gearbox's 800 Nm input rating [F] (S04) is a design rating, not the clutch's slip capacity
		clutchStiffness = 400, -- [E] Nm per rad/s of slip, how firmly an engaged clutch couples
		launchRpm = { min = 1600, max = 3500 }, -- [F] max: launch control holds 3,500 rpm (S03, S04); [E] min: a light-pedal pull-away
		autoUpshiftRpm = { light = 2000, full = 6450 }, -- [E] by pedal: early shifts in Tour (70 mph in 8th is about 1,500 rpm); full throttle at peak power
		autoDownshiftRpm = { light = 1100, full = 3600 }, -- [E] by pedal
		minShiftInterval = 0.25, -- [E] seconds between shifts
	},

	drivetrain = {
		layout = "RWD", -- [F] mid-engine, rear-wheel drive (S10)
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] The Z51's electronic limited-slip differential (a clutch pack modulated from open to locked,
		-- S04) as a clutch-type LSD; GM's calibration isn't published. Values from the research note.
		rearDifferential = { type = "LimitedSlip", preload = 100, powerLock = 0.45, coastLock = 0.30, stiffness = 180 },
		frontDifferential = { type = "Open" },
		-- [E] Traction control (the real car has Performance Traction Management): caps engine and clutch
		-- torque at headroom times what the driven tyres can grip, and trims while they slip past targetSlip.
		-- headroom: 1.3 to 2.0 were tried; launch times moved by under 0.05 s (spec sheet), so it stays at 1.3.
		tractionControl = { enabled = true, targetSlip = 0.11, rate = 15, recovery = 2, headroom = 1.3 },
	},

	-- [E] Not published. Springs from ride frequencies of 1.7 Hz front and 1.9 Hz rear (Z51 springs are
	-- stiffer than the base car's, S10; reviewers praise the ride), at corner masses of 341 and 524 kg.
	-- Dampers at about 0.3 of critical in bump and 0.5 in rebound. Anti-roll bars give the front axle about
	-- 52% of the roll stiffness against its 39% of the weight, for a stable, slightly understeering balance
	-- (about 1.4 degrees of roll per g). The real car has SLA double wishbones and 46 mm monotube coil-overs
	-- at both ends [F] (S01).
	suspension = {
		front = {
			springRate = 38900, -- [E] N/m at the wheel, 1.7 Hz
			bumpDamping = 2200, -- [E] N*s/m
			reboundDamping = 3640, -- [E] N*s/m
			staticLength = 0.25, -- [E] mount to wheel centre at ride height
			bumpTravel = 0.07, -- [E] from ride height (the real car offers a front lift for kerbs, S10)
			droopTravel = 0.07, -- [E]
			bumpStopRate = 250000, -- [E] N/m
			antiRollRate = 30000, -- [E] N/m of left-right travel difference
			rollCenterHeight = 0.05, -- [E] SLA double wishbone
			rideHeightOffset = 0, -- [E] positive raises the car
		},
		rear = {
			springRate = 74700, -- [E] 1.9 Hz
			bumpDamping = 3750, -- [E]
			reboundDamping = 6250, -- [E]
			staticLength = 0.25, -- [E]
			bumpTravel = 0.08, -- [E]
			droopTravel = 0.07, -- [E]
			bumpStopRate = 250000, -- [E]
			antiRollRate = 12000, -- [E]
			rollCenterHeight = 0.09, -- [E]
			rideHeightOffset = 0, -- [E]
		},
	},

	tires = {
		compounds = {
			-- [E] The Z51's tyre: a max-performance summer road tyre in the Michelin Pilot Sport 4S class,
			-- GM "TPC" spec [F] (S01, S19), ZP run-flat per Car and Driver's data panel [P] (engineering
			-- reference only). muLong 1.25 [E, tuned]: the model then matches Motor Trend's 97 ft 60-0 mph
			-- (S18) and Car and Driver's 3.5 s rolling 5-60 mph; Car and Driver's 149 ft 70-0 mph would need
			-- 1.10 (spec sheet). muLat 1.06 [E, tuned]: a steady 1.036 g on a skidpad, against the measured
			-- 1.03 g (S13) and 1.04 g (S18).
			-- nominalLoad [E] scales with each size's load index, 89 and 99 (580 and 775 kg, Car and Driver's
			-- data panel): the game's tyre has no width, and this is what makes the wide rear tyre carry its
			-- 61% of the weight without letting go first (neutral balance at the limit).
			RoadPerformance = { base = "Performance", muLong = 1.25, muLat = 1.06, nominalLoad = 3770 },
			RoadPerformanceRear = { base = "RoadPerformance", nominalLoad = 5030 },
		},
		front = { widthMm = 245, aspect = 35, rimInches = 19, compound = "RoadPerformance", inertia = 1.5 }, -- [F] 245/35ZR19 on 19 x 8.5 (S01); [E] inertia, wheel, tyre and 345 mm iron disc (kg*m^2)
		rear = { widthMm = 305, aspect = 30, rimInches = 20, compound = "RoadPerformanceRear", inertia = 2.1 }, -- [F] 305/30ZR20 on 20 x 11 (S01); [E] inertia, wheel, tyre and 350 mm iron disc
	},

	brakes = {
		discs = "Iron, ventilated: 345 x 30 mm front, 350 x 27 mm rear; Brembo 4-piston monobloc calipers; eBoost electric booster", -- [F] Z51 (S01, S29)
		maxTorqueFront = 3000, -- [E] Nm per wheel, about 1.5 x what locks a front wheel at 1.25 g
		maxTorqueRear = 2100, -- [E] Nm per wheel; 59% front bias, near the 57% ideal for a 39/61 car
		handbrakeTorque = 2000, -- [E] Nm per rear wheel (electric parking brake)
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		dragArea = 0.88, -- [E, tuned] CdA in m^2, fitted so the car's drag-limited top speed is the factory 296 km/h (184 mph), in 6th at 6,060 rpm; GM publishes no Cd (a forum 0.322 is unverified, S30)
		-- [E] ClA in m^2: the Z51 splitter and spoiler add 400 lb (1,779 N) of downforce [F] (S22), taken
		-- at 184 mph, split 40 / 60 with the weight; the base car's own lift is taken as zero [A].
		downforceAreaFront = 0.175, -- [E]
		downforceAreaRear = 0.263, -- [E]
	},

	steering = {
		maxAngleLowSpeed = 30, -- [E] road-wheel degrees when slow; with ackermann 0.6 this gives about the factory 11.6 m turning circle [F] (S01)
		maxAngleHighSpeed = 4.5, -- [E] at highSpeedKmh and above, keyboard-friendly as the GT12
		highSpeedKmh = 250, -- [E]
		rate = 220, -- [E] degrees per second the road wheels can turn
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- Sound. The engine sheet is made from the car's acoustic definition,
	-- assets/audio/engines/RefC8Stingray.json, by tools/synth_audio.py (docs/AUDIO.md). The loudness
	-- over rpm and load comes from the sheet's per-loop gains, calibrated to Car and Driver's measured
	-- 47 / 92 dBA (idle / full throttle). Values are [E] unless tagged, tuned from the research notes.
	audio = {
		engineSheet = "RefC8Stingray_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3,
		rpmCurve = 1.0,
		redlineRpm = 6600, -- [P] fuel cut (S27)
		offThrottleLevel = 0.55,
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back
		limiterHold = 0.3, -- s after the last cut before the normal loops return
		limiterAttack = 40, -- 1/s, about 25 ms
		limiterRelease = 10, -- 1/s
		-- forced induction: not used by this naturally aspirated engine
		turboVolume = 0,
		blowOffVolume = 0,
		blowOffMinBoost = 0.35,
		superchargerVolume = 0,
		-- DCT upshifts hand torque over with no interruption (S04), so the shift cut is short and soft
		shiftCutTime = 0.05,
		shiftCutMinRpm = 4000,
		shiftCutVolume = 0.35,
		shiftClunkVolume = 0.2,
		-- overrun: no factory crackle map; owners call the stock NPP exhaust "not very aggressive even in
		-- Track" (S26), so a few short, quiet pops after a high-rpm lift
		crackleMinRpm = 3500,
		crackleDuration = 0.5,
		crackleRate = 6,
		crackleVolume = 0.3,
		bumpMinSpeed = 0.6, -- m/s into the bump stops before a knock is heard
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2, -- tyres start to squeal past this multiple of their peak slip
		squealRange = 1.5,
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.05,
		-- ring-and-pinion mesh: 32 ring teeth per wheel turn (3.555 = 32 / 9, S03, S04) is 6.19 teeth per
		-- turn of the shaft the game measures (wheel speed x 5.17); GM publishes no tooth counts [E]
		whineTeeth = 6.19,
		-- cockpit camera: level changes and an equaliser (dB). The engine sits right behind the seats
		-- (mid-engine, rear-facing intake, S07), so the cabin hears more engine and less treble cut.
		interior = { engine = 0.9, wind = 0.45, road = 1.25, squeal = 0.7, lowGain = 4, midGain = -1, highGain = -9 },
	},

	-- Published figures the telemetry overlay and tools/drivetrain_model.py compare against. US figures
	-- for 0-60 mph and the quarter mile are timed after a one-foot rollout (drag-strip style) where
	-- stated; the game times from a true standstill (see the spec sheet).
	performanceTargets = {
		zeroTo60Mph = 2.9, -- [F] GM, Z51 with launch control (S03); GM doesn't say whether it uses a one-foot rollout
		zeroTo60MphRollout = 2.8, -- [M] Car and Driver (S14) and Motor Trend (S18), Oct 2019, one-foot rollout
		quarterMile = 11.2, -- [F] GM 11.2 s (S03); [M] Car and Driver 11.2 s, Motor Trend 11.1 s
		quarterMileKmh = 194.7, -- [F] 121 mph (S03); [M] Car and Driver 122 mph, Motor Trend 123.2 mph
		topSpeedKmh = 296, -- [F] 184 mph with Z51 (S22); 194 mph without Z51's aero
		brake70MphTo0 = 45.4, -- [M] 149 ft, Car and Driver, Oct 2019 (S13); 154 ft in its Sept 2020 test (S15)
		brake60MphTo0 = 29.6, -- [M] 97 ft, Motor Trend, Oct 2019 (S18)
	},

	visual = {
		bodyColor = Color3.fromRGB(20, 84, 168), -- [A] an RGB approximation of Rapid Blue, a 2020 launch colour
		driverSide = "Left", -- [F] left-hand drive (US)
		-- [E] Stand-in body side profile from photos (S36): mid-engine, cab-forward proportions. Research
		-- shares of the length from the nose: front axle 0.18, windscreen base 0.29, header 0.42, roof
		-- peak 0.50, roof end and engine cover 0.59, rear axle 0.77, spoiler lip 0.98 (+/-0.05); heights
		-- +/-10% except the roof, the factory 1.234 m [F]. The builder draws everything below the beltline
		-- as one full-length box, so the nose shows at the beltline (the real one is lower: about 0.45 m at
		-- the leading edge, 0.68 m at the bonnet's front). The glass runs on over the slope behind the
		-- roof, as the real car's rear glass and glass engine cover do, so the cabin stands apart from the
		-- engine deck; the deck sits at the low end of the research's 1.10 m (+/-10%) for the same reason.
		-- Chosen from renders of seven variants (docs/cars/RefC8Stingray.md).
		blockout = {
			profile = {
				{ 0, 0.76 }, -- nose (hidden in the box below the beltline)
				{ 0.08, 0.78 }, -- front of the bonnet
				{ 0.18, 0.81 }, -- front axle
				{ 0.28, 0.89 }, -- windscreen base
				{ 0.42, 1.20 }, -- windscreen header
				{ 0.50, 1.234 }, -- roof peak, the factory height [F]
				{ 0.56, 1.21 }, -- roof end
				{ 0.64, 1.05 }, -- foot of the rear glass, start of the engine deck
				{ 0.95, 1.01 }, -- engine deck over and behind the rear axle
				{ 0.98, 1.05 }, -- ducktail spoiler lip
				{ 1, 0.97 }, -- tail
			},
			greenhouse = { 0.28, 0.64 }, -- [E] cabin glass, windscreen base to the foot of the rear glass
			beltline = 0.76, -- [E] side window sill, m
			cabinWidth = 0.68, -- [E] greenhouse width as a share of body width
			sill = 0.12, -- [E] bottom of the body sides, m
		},
	},
}
