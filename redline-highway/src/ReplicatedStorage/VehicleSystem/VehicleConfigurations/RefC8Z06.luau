--[[
	Ridgeway Halcyon Z (internal ID: RefC8Z06)

	An original mid-engine coupe from Ridgeway, a fictional American brand, built on the publicly
	documented engineering of the Chevrolet Corvette Z06 coupe (C8, model year 2023 onward), base car
	without the Z07 package. No Chevrolet names, logos or designs are used in the game.
	docs/cars/RefC8Z06.md has the sources, how each estimate was made and the validation;
	research_notes/cars/RefC8Z06.json has the research itself (source ids such as S02 refer to it).

	Every value is tagged:
	  [F] manufacturer figure (GM/Chevrolet)
	  [P] published third-party figure (spec sheets, Wikipedia, magazine spec boxes)
	  [M] measured in a magazine or independent test
	  [E] estimate made for the simulation (the doc says how)
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.
	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	Z07 package variant (Cup 2 R tyres, carbon-ceramic brakes, 734 lb of downforce, 189 mph): the
	TrackTyre compounds below are ready for it; docs/cars/RefC8Z06.md lists every value it changes.
]]

return {
	id = "RefC8Z06",
	displayName = "Ridgeway Halcyon Z",
	reference = "Chevrolet Corvette Z06 (C8) (engineering reference only)",

	mass = {
		dryKg = 1558, -- [P] GM dry weight as copied by spec sites, for a Z07 coupe with carbon wheels (S04, S05)
		kerbKg = 1680, -- [E] US curb weight, base coupe: C/D's measured Z07 coupe (1,663 kg [M]) plus iron brakes, minus Z07 aero, aluminium wheels
		driverKg = 75, -- [A] the simulation carries one driver
		frontShare = 0.40, -- [P] about 40% front / 60% rear (S26; the Stingray's official split is 39.4/60.6)
		comHeight = 0.44, -- [E] low mid-engine coupe with a dry-sump engine
		-- [E] Size of the invisible box that carries the car's mass (about 2,700 kg*m^2 in yaw).
		inertiaBox = { width = 1.85, height = 0.75, length = 3.90 },
	},

	dimensions = {
		length = 4.689, -- [P] 184.6 in (S04, S05, S06); 4.722 m with the Z07 splitter
		width = 2.024, -- [P] 79.7 in without mirrors, about 91 mm wider than the Stingray
		height = 1.234, -- [P] 48.6 in
		wheelbase = 2.723, -- [P] 107.2 in
		trackFront = 1.684, -- [P] 66.3 in
		trackRear = 1.679, -- [P] 66.1 in
		frontOverhang = 0.960, -- [E] measured from a side photo (S29a), scaled to the published length
	},

	engine = {
		layout = "90-degree V8, flat-plane crank, mid-mounted", -- [F] LT6, DOHC, 32 valves, dry sump
		displacementCc = 5463, -- [P] from the 104.25 x 80.0 mm bore and stroke (5.5 L nominal [F])
		aspiration = "NaturallyAspirated", -- [F]
		peakPowerKw = 500, -- [F] 670 hp SAE J1349 (US engine)
		peakPowerRpm = 8400, -- [F]
		peakTorqueNm = 624, -- [F] 460 lb-ft SAE J1349
		peakTorqueRpm = 6300, -- [F]
		idleRpm = 900, -- [E] not published; warm idle of a high-revving DOHC V8
		limiterRpm = 8600, -- [F] redline 8,600 rpm; fuel cut at 8,600 [P] (S19)
		limiterHysteresisRpm = 150, -- [E] typical fuel-cut bounce
		inertia = 0.14, -- [E] kg*m^2: crank, rods' share, damper and the dual-clutch drum
		-- [F] Full-throttle crank torque, {rpm, Nm}, read from GM's chart "US LT6 SAE Torque and
		-- Power" (S01) by pixel digitising, times 1.006 so it meets GM's own ratings (the chart reads
		-- about 1% under them; with the factor: 500 kW at 8,400 rpm, 622 Nm at 6,300). The chart's
		-- shape is kept: flat about 400-415 Nm to 3,000 rpm with a dip at 2,900, the intake-resonance
		-- step to 574 Nm by 3,500, a peak at 3,800, a dip at 4,200, the 605-611 Nm plateau, the peak
		-- at 6,300 and the gentle fall to 550 Nm at 8,600. The 1,000 and 1,500 rpm points are below
		-- the chart's start (1,800 rpm) and are estimates [E].
		torqueCurve = {
			{ 1000, 340 }, -- [E]
			{ 1500, 385 }, -- [E]
			{ 1800, 397 },
			{ 2000, 401 },
			{ 2500, 414 },
			{ 2600, 414 },
			{ 2900, 401 },
			{ 3000, 409 },
			{ 3500, 574 },
			{ 3800, 603 },
			{ 4000, 595 },
			{ 4200, 583 },
			{ 4500, 605 },
			{ 4600, 611 },
			{ 5000, 606 },
			{ 5500, 608 },
			{ 6000, 611 },
			{ 6300, 622 },
			{ 6500, 614 },
			{ 7000, 602 },
			{ 7500, 594 },
			{ 8000, 582 },
			{ 8400, 569 },
			{ 8500, 559 },
			{ 8600, 550 },
		},
		-- [E] Internal friction, felt as engine braking with the throttle closed: static + perRpm * rpm (Nm).
		friction = { static = 20, perRpm = 0.0085 },
		throttleResponse = 18, -- [E] 1/s, how quickly the throttle follows the pedal
	},

	transmission = {
		type = "DualClutch", -- [F] Tremec TR-9080 8-speed dual-clutch transaxle (GM M1L)
		gearRatios = { 2.91, 1.76, 1.22, 0.88, 0.65, 0.51, 0.40, 0.33 }, -- [P] the Stingray's ratios (S04, S05, S11)
		reverseRatio = 2.63, -- [P]
		finalDrive = 5.56, -- [F] (Stingray: 5.17 Z51, 4.89 base)
		efficiency = 0.90, -- [E] crank to wheel, from stock wheel dynos (600-611 whp from 670 hp, S25)
		shiftTime = 0.10, -- [P] about 100 ms clutch overlap (TR-9080, S10; no Z06 figure published)
		-- [E] Share of clutch capacity kept during a shift. The TR-9080 hands torque from clutch to
		-- clutch with no gap (S10), so the oncoming clutch keeps 0.7 x 940 = 658 Nm, above peak torque:
		-- it pulls the engine down to the new gear's speed instead of letting it flare into the limiter.
		shiftTorqueFraction = 0.70,
		clutchMaxTorque = 940, -- [E] Nm, 1.5 x peak torque
		clutchStiffness = 400, -- [E] Nm per rad/s of slip, how firmly an engaged clutch couples
		launchRpm = { min = 2000, max = 4500 }, -- [P] launch control holds 4,500 rpm by default (S23; driver-adjustable 3,500-5,000); min [E]
		-- full [P]: full-throttle upshifts complete at about 8,500 rpm (S19), just under the 8,600 cut.
		-- light [E]: a Sport-mode calibration. Lifting off holds the gear below 4,500 rpm, and braking
		-- downshifts one gear at a time at 2,200 rpm, the clutch spinning the engine up to match.
		autoUpshiftRpm = { light = 4500, full = 8500 },
		autoDownshiftRpm = { light = 2200, full = 4800 }, -- [E] by pedal position; up/down stays above 1.77 so it can't hunt
		minShiftInterval = 0.25, -- [E] seconds between shifts
	},

	drivetrain = {
		layout = "RWD", -- [F] mid-engine, rear-wheel drive
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] The real car has an electronic limited-slip differential (standard on every Z06 [F]);
		-- this is a clutch-type approximation: preload in Nm, lock factors as shares of input torque.
		rearDifferential = { type = "LimitedSlip", preload = 100, powerLock = 0.45, coastLock = 0.30, stiffness = 180 },
		frontDifferential = { type = "Open" },
		-- [E] Traction control (Performance Traction Management and launch control on the real car,
		-- which let the driver set the allowed tyre slip, S23). It caps engine and clutch torque at
		-- headroom times what the driven tyres can grip, and trims further while they slip more than
		-- targetSlip. The shared defaults, as the GT12. Not tuned while the shared engine-inertia fix
		-- is pending: before it, the launch hunted at 45-60 fps (docs/cars/RefC8Z06.md).
		tractionControl = { enabled = true, targetSlip = 0.11, rate = 15, recovery = 2, headroom = 1.3 },
	},

	-- [E] Springs and dampers from target ride frequencies of 1.9 Hz front and 2.1 Hz rear (magnetic
	-- dampers, base chassis; the Z07's FE7 setup is stiffer) with damping ratios of about 0.3 in bump
	-- and 0.5 in rebound, on corner masses of 351 kg front and 527 kg rear. Anti-roll bars put 57% of
	-- the roll stiffness at the front (52% of the lateral load transfer with the roll centres), for a
	-- mildly understeering limit on these tyres; roll is about 1.0 degree per g.
	suspension = {
		front = {
			springRate = 50000, -- N/m at the wheel
			bumpDamping = 2500, -- N*s/m
			reboundDamping = 4200, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.07, -- from ride height
			droopTravel = 0.07, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 50000, -- N/m of left-right travel difference
			rollCenterHeight = 0.05, -- lateral tyre force acts this high above the road
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 91700,
			bumpDamping = 4200,
			reboundDamping = 6900,
			staticLength = 0.25,
			bumpTravel = 0.07,
			droopTravel = 0.07,
			bumpStopRate = 250000,
			antiRollRate = 12000,
			rollCenterHeight = 0.08,
			rideHeightOffset = 0,
		},
	},

	tires = {
		-- [E] The car's own tyres (docs/cars/RefC8Z06.md). muLong is the research's estimate (1.40 road,
		-- 1.50 track); with the game's keyboard brake ramp the road tyre stops from 60 mph in MT's 29 m.
		-- muLat is set from the skidpad: about 1.11 g on the road tyre (tests 1.10-1.12 g) and 1.16 g on
		-- the track tyre (1.16 g), after the tyre model's load sensitivity. Nominal loads are the shared compounds'
		-- values scaled by tread width (275 and 345 mm, against 295 mm), so the wider rear tyre loses
		-- less grip to its heavier load.
		compounds = {
			-- road tyre in the Michelin Pilot Sport 4S ZP class (base car), 275/30 front
			RoadPerformance = { base = "Performance", muLong = 1.40, muLat = 1.14, nominalLoad = 4100 },
			-- the same tyre in the 345/25 rear size
			RoadPerformanceRear = { base = "RoadPerformance", nominalLoad = 5150 },
			-- track tyre in the Pilot Sport Cup 2 R ZP class (Z07 package), 275/30 front
			TrackTyre = { base = "SemiSlick", muLong = 1.50, muLat = 1.18, nominalLoad = 4300 },
			-- the same tyre in the 345/25 rear size
			TrackTyreRear = { base = "TrackTyre", nominalLoad = 5380 },
		},
		front = { widthMm = 275, aspect = 30, rimInches = 20, compound = "RoadPerformance", inertia = 1.5 }, -- [F] 275/30ZR20 on 20 x 10 in, [E] inertia (kg*m^2)
		rear = { widthMm = 345, aspect = 25, rimInches = 21, compound = "RoadPerformanceRear", inertia = 2.1 }, -- [F] 345/25ZR21 on 21 x 13 in, [E] inertia (kg*m^2)
	},

	brakes = {
		discs = "Iron, 370 x 34 mm front, 380 x 34 mm rear; 6-piston front, 4-piston rear monobloc calipers", -- [P] (S05, S06)
		maxTorqueFront = 3000, -- [E] Nm per wheel, enough to lock the wheels near 1.3 g
		maxTorqueRear = 2000, -- [E] Nm per wheel (60% front)
		handbrakeTorque = 2200, -- [E] Nm per rear wheel (electric parking brake on the rear calipers)
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		dragArea = 0.895, -- [E] CdA in m^2, fitted so the car tops out at 195 mph (314 km/h [F]) in 6th, about 6,760 rpm
		-- [P] 365 lb (1,624 N) of downforce at 186 mph (S19, S02): ClA 0.383 m^2 at the game's air
		-- density. Split 40% front / 60% rear [E], with the weight (the split isn't published).
		downforceAreaFront = 0.153, -- [E] ClA in m^2
		downforceAreaRear = 0.230, -- [E] ClA in m^2
	},

	steering = {
		maxAngleLowSpeed = 34, -- [E] mean road-wheel lock from the 11.6 m turning circle [P] (S06)
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above
		highSpeedKmh = 250, -- [E]
		rate = 220, -- [E] degrees per second the road wheels can turn
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made by tools/synth_audio.py from the car's acoustic definition,
	-- assets/audio/engines/RefC8Z06.json: firing order 1-4-3-8-7-6-5-2 on a flat-plane crank (each bank
	-- fires every 180 degrees, so a clean shriek and no cross-plane burble), 4-2-1 headers per bank,
	-- a valved exhaust with centre tips, the 8,600 rpm fuel cut and C/D's 94 dBA at full throttle. The
	-- loudness over rpm and load is in the sheet's per-loop gains; engineVolume scales all of it.
	-- docs/AUDIO.md explains every setting; docs/cars/RefC8Z06.md has the measurements.
	audio = {
		engineSheet = "RefC8Z06_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3,
		rpmCurve = 1.0,
		redlineRpm = 8600,
		offThrottleLevel = 0.55,
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back. In gear this
		-- car's simulated cut returns 3-4 times a second, up to 0.33 s apart (4th gear), so the hold
		-- is longer than the GT12's 0.3 s.
		limiterHold = 0.45,
		limiterAttack = 40, -- 1/s, how fast the limiter loops come in (about 25 ms)
		limiterRelease = 10, -- 1/s, and go out
		-- forced induction: not used by this naturally aspirated engine
		turboVolume = 0.35,
		blowOffVolume = 0.6,
		blowOffMinBoost = 0.35,
		superchargerVolume = 0.3,
		-- the dual-clutch hands torque over with no gap (S10): a short, soft dip on full-throttle
		-- upshifts rather than an ignition-cut crack
		shiftCutTime = 0.05,
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.15,
		shiftClunkVolume = 0.15,
		-- no source describes overrun pops: a light crackle at most, as in Sport and Track
		crackleMinRpm = 4500,
		crackleDuration = 0.8,
		crackleRate = 8,
		crackleVolume = 0.2,
		bumpMinSpeed = 0.6, -- m/s into the bump stops before a knock is heard
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2, -- tyres start to squeal past this multiple of their peak slip
		squealRange = 1.5,
		roadVolume = 0.4, -- run-flat 20/21-inch tyres are noisy (research estimate: 72 dBA at 70 mph)
		windVolume = 0.5,
		whineVolume = 0.06,
		-- ring-and-pinion mesh. The 5.56 final drive is a 1.566 transfer gear times a 3.55 ring and
		-- pinion (S11); 71/20 teeth assumed (not published), and the pinion turns at 3.55 / 5.56 of the
		-- shaft speed the mixer uses, so 20 x 0.639 = 12.8.
		whineTeeth = 12.8,
		-- cockpit camera: the engine and its twin throttle bodies sit right behind the seats and the tip
		-- bezels reflect sound up to the cabin (S24), so the engine stays at full level, mids are kept
		-- (the firing order is 60-573 Hz, its harmonics 120-1,150 Hz) and the highs are cut less than
		-- the front-engined GT12's
		interior = { engine = 1.0, wind = 0.45, road = 1.25, squeal = 0.7, lowGain = 2, midGain = 0, highGain = -7 },
	},

	-- [M] Published figures the telemetry timer and tools/drivetrain_model.py compare against.
	-- The magazine figures are for the Z07 coupe (the coupe tests on file; the base car is close)
	-- and use a one-foot rollout, as US magazines do. The game's timer starts from a true
	-- standstill, which adds about 0.2-0.3 s.
	performanceTargets = {
		zeroTo60MphRollout = 2.6, -- [M] C/D, Z07 coupe (S13); GM claims 2.6 s with the Z07 [F] (S02)
		zeroTo100Mph = 5.9, -- [M] C/D, one-foot rollout
		quarterMile = 10.5, -- [M] C/D, one-foot rollout; GM's preliminary figure is 10.6 s [F]
		quarterMileKmh = 210.8, -- [M] C/D, 131 mph
		topSpeedKmh = 314, -- [F] 195 mph for the base car (S17); 189 mph with the Z07
		brake60MphTo0 = 29.0, -- [M] MT, Z07 coupe: 95 ft (S16)
		brake70MphTo0 = 42.4, -- [M] C/D, Z07 coupe: 139 ft (S13)
	},

	visual = {
		bodyColor = Color3.fromRGB(208, 72, 22), -- [A] RGB approximation of the launch colour Amplify Orange, a deep metallic orange (redder than the AR-7's)
		driverSide = "Left", -- [F] left-hand drive (right-hand drive is built for export)
		-- [E] Stand-in body (VehicleModelBuilder), from the research's side-photo proportions (S29a,
		-- about +-3-5% of length): nose 0.45 m, front axle at 0.205 of the length (fender 0.71 m),
		-- windscreen base 0.27 (0.80 m), windscreen top 0.41 (1.20 m), roof peak 0.46 at the published
		-- 1.234 m height, roof end 0.57 (1.19 m), then the buttresses down to a long, nearly flat deck
		-- and the 1.05 m ducktail lip; rear axle at 0.785. The beltline is 0.64 m, not the real 0.81 m
		-- door line, because the builder fills everything below the beltline with one full-length box:
		-- at 0.81 the nose would be a 0.7 m wall. The narrow canopy (66% of the 2.02 m width) leaves the
		-- wide shoulders a mid-engine car reads by.
		blockout = {
			profile = {
				{ 0, 0.45 }, -- nose leading edge
				{ 0.05, 0.55 },
				{ 0.205, 0.71 }, -- front fender over the axle
				{ 0.27, 0.80 }, -- windscreen base (cowl)
				{ 0.41, 1.20 }, -- windscreen top
				{ 0.435, 1.228 },
				{ 0.46, 1.234 }, -- roof peak: the published height
				{ 0.51, 1.222 },
				{ 0.57, 1.19 }, -- roof rear end
				{ 0.64, 1.07 }, -- buttresses meet the deck
				{ 0.72, 1.02 },
				{ 0.90, 1.00 }, -- engine deck
				{ 0.97, 1.03 },
				{ 1, 1.05 }, -- ducktail lip
			},
			greenhouse = { 0.27, 0.62 }, -- windscreen base to the small rear window between the buttresses
			beltline = 0.64,
			cabinWidth = 0.66,
			sill = 0.12, -- about 0.10 m ground clearance (not published)
		},
	},
}
