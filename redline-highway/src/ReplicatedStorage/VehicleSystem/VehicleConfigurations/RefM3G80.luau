--[[
	Brandt Kestrel RS (internal ID: RefM3G80)

	An original four-door sports sedan from the fictional German maker Brandt, built on the publicly
	documented engineering of the BMW M3 Competition sedan (G80): rear-wheel drive, 8-speed
	torque-converter automatic. No BMW names, logos or designs are used in the game. Sources, the
	estimates and how each was made are in docs/cars/RefM3G80.md; the research behind them is
	research_notes/cars/RefM3G80.json (source ids such as BMW_SPEC_M3 below refer to it).

	Every value is tagged:
	  [F] factory figure published by the maker
	  [P] published figure from a third party (spec sheet, parts catalogue)
	  [M] measured in a magazine or independent test
	  [E] estimate made for the simulation (method given)
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.

	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).
	docs/VEHICLE_CONFIG.md describes every field.
]]

return {
	id = "RefM3G80",
	displayName = "Brandt Kestrel RS",
	reference = "BMW M3 Competition (G80) (engineering reference only)",

	mass = {
		dryKg = 1660, -- [E] not published: DIN kerb minus 40 kg of fuel (59 L x 90%) and about 30 kg of oil, coolant and ATF
		kerbKg = 1730, -- [F] DIN kerb weight, 90% fuel, no driver (BMW_SPEC_M3); US curb 3,890 lb = 1,764 kg with full fuel
		driverKg = 75, -- [A] one driver; 1,730 + 75 = 1,805 kg, BMW's EU unladen weight [F]
		frontShare = 0.531, -- [F] 53.1% front / 46.9% rear (BMW US spec, BMW_US21); MotorTrend measured 53/47 [M]
		comHeight = 0.49, -- [E] not published; typical lowered sedan with a carbon roof (research estimate)
		-- [E] Box that carries the mass, sized for a yaw inertia of about 3,300 kg*m^2 (dynamic index about
		-- 0.9 for a 2,857 mm wheelbase and 53/47 split, usual for a front-engined sedan). Roll inertia
		-- comes out near 580 kg*m^2 and pitch near 2,900 kg*m^2.
		inertiaBox = { width = 1.80, height = 0.80, length = 4.30 },
	},

	dimensions = {
		length = 4.794, -- [F] BMW_SPEC_M3
		width = 1.903, -- [F] without mirrors (2,068 mm with)
		height = 1.433, -- [F] unladen
		wheelbase = 2.857, -- [F]
		trackFront = 1.617, -- [F]
		trackRear = 1.605, -- [F]
		frontOverhang = 0.860, -- [F] BMW's dimension drawing (rear overhang 1,077 mm)
	},

	engine = {
		layout = "Inline-6, front, longitudinal", -- [F] S58B30T0
		displacementCc = 2993, -- [F] 84.0 mm bore x 90.0 mm stroke, 9.3:1 compression
		aspiration = "Turbocharged", -- [F] two mono-scroll turbochargers, one per three cylinders (1-3 and 4-6)
		peakPowerKw = 375, -- [F] 510 PS / 503 hp; BMW's diagram holds 375 kW from 5,600 to 7,200 rpm
		peakPowerRpm = 6250, -- [F]
		peakTorqueNm = 650, -- [F] from 2,750 to 5,500 rpm
		peakTorqueRpm = 2750, -- [F] start of the 650 Nm plateau
		idleRpm = 700, -- [E] not published; warm idle of BMW's B58/S58 automatics is about 650-750 rpm
		limiterRpm = 7250, -- [P] evo: "the limiter coming in at 7250rpm"; redline 7,200 rpm [F]
		-- [E] fuel returns 100 rpm below the limiter: a tight, quick cut. With inertia and throttleResponse the
		-- free rev bounces 7,140-7,470 rpm about 4.5 times a second, and 7,150-7,270 rpm in gear.
		limiterHysteresisRpm = 100,
		inertia = 0.20, -- [E] kg*m^2: crank (21.2 kg forged [F]), rods, pistons, damper, flexplate and converter impeller
		-- Full-throttle torque at FULL BOOST, {rpm, Nm} (see "Turbo and supercharger torque curves" in
		-- docs/VEHICLE_CONFIG.md). From 2,744 rpm it is BMW's full-load diagram exactly [F] (the vertices of
		-- the vector drawing in BMW_SPEC_M4, the same 375 kW / 650 Nm engine): 650 Nm to 5,500 rpm, then
		-- constant 375 kW to 7,198 rpm. Below 2,744 rpm the points are [E]: each is BMW's torque at that rpm
		-- divided by the boost factor there (offBoostTorqueShare + (1 - share) x boost ceiling), so the
		-- steady full-throttle torque the game makes equals BMW's diagram at every vertex: 245 Nm at
		-- 1,000, 295 at 1,500, 345 at 2,000, 460 at 2,500, 570 at 2,651, 650 at 2,744 rpm.
		torqueCurve = {
			{ 1000, 650.0 }, -- [E] steady 245 Nm [F]
			{ 1500, 782.7 }, -- [E] steady 295 Nm [F] (no boost yet here, so this value is only reached part-throttle)
			{ 2000, 646.5 }, -- [E] steady 345 Nm [F]
			{ 2500, 543.1 }, -- [E] steady 460 Nm [F]
			{ 2651, 605.3 }, -- [E] steady 570 Nm [F]
			{ 2744, 650 }, -- [F] start of the 650 Nm plateau
			{ 5500, 650 }, -- [F] end of the plateau
			{ 5593, 639 }, -- [F] constant 375 kW from here
			{ 6000, 597 }, -- [F]
			{ 6500, 551 }, -- [F]
			{ 7000, 511 }, -- [F]
			{ 7198, 497 }, -- [F] end of BMW's curve
			{ 7250, 494 }, -- [E] 375 kW held to the limiter
		},
		-- [E] Engine braking with the throttle shut: static + perRpm * rpm (Nm). From a friction mean
		-- effective pressure of about 1.1 bar at 3,000 rpm and 2.3 bar at 7,000 rpm, plus about 0.9 bar
		-- of closed-throttle pumping loss, for 2,993 cc: about 47 Nm at 3,000 rpm and 75 Nm at 7,000.
		friction = { static = 25, perRpm = 0.0072 },
		throttleResponse = 20, -- [E] 1/s, electronic throttle with VALVETRONIC [F] (turbo lag is modelled separately)
		speedLimitKmh = 290, -- [F] with the M Driver's Package (BMW_SPEC_M3); the standard car is limited to 250 km/h [F]
		forcedInduction = {
			type = "Turbo", -- [F] twin mono-scroll MHI turbochargers, electric wastegates, air-to-water charge cooling
			maxBoostBar = 1.7, -- [P] auto motor und sport "max. Ladedruck 1,7 bar"; Car and Driver 24.7 psi
			-- [E] 245 Nm at 1,000 rpm [F] / 650 Nm = 0.377, which is also 1 / (1 + 1.7 bar): torque in
			-- proportion to manifold pressure
			offBoostTorqueShare = 0.377,
			-- [E] Boost starts here, so steady full throttle at 2,000 rpm shows 0.43 bar: the pressure that
			-- BMW's 345 Nm implies there (345 / 245 x 1 bar absolute). The real rise is convex (slow, then
			-- steep near 2,500 rpm); a linear ramp can't follow it, so the curve points above carry the shape.
			boostStartRpm = 1750,
			fullBoostRpm = 2744, -- [F] BMW's diagram reaches 650 Nm here (spec sheet: 2,750 rpm)
			-- [E] s to 90% boost when floored at 2,744 rpm in a held gear. Fitted to the in-gear times: 80-120 km/h
			-- 2.73 s in 4th (BMW 2.6, The Citizen 2.67) and 3.58 s in 5th (BMW 3.4, The Citizen 4.02)
			spoolTime = 0.5,
			dumpTime = 0.2, -- [E] electric wastegates, no blow-off valve documented (recirculation is internal)
		},
	},

	transmission = {
		type = "Automatic", -- [F] 8-speed M Steptronic with Drivelogic, ZF 8HP76 torque-converter automatic
		gearRatios = { 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640 }, -- [F] BMW_SPEC_M3
		reverseRatio = 3.478, -- [F]
		finalDrive = 3.154, -- [F]
		efficiency = 0.89, -- [E] rear-drive automatic with lock-up closed, final drive and clutch-pack differential
		shiftTime = 0.15, -- [E] s; research: 0.10-0.15 s torque dip in the sportiest Drivelogic setting, 0.3-0.4 s in comfort
		downshiftTime = 0.20, -- [E]
		downshiftBlip = 0.3, -- [E] BMW: automatic rev-matching on downshifts [F]
		shiftTorqueReduction = 0.4, -- [E] ignition retard during a power-on upshift
		turbineInertia = 0.05, -- [E] kg*m^2, converter turbine and gearbox input
		minShiftInterval = 0.3, -- [E] s
		-- [E] gearbox input rpm. Full throttle upshifts 200 rpm under the limiter (BMW's power plateau runs to
		-- 7,200 rpm); light throttle reaches 8th gear by about 90 km/h.
		autoUpshiftRpm = { light = 1900, full = 7050 },
		autoDownshiftRpm = { light = 1100, full = 4800 }, -- [E] kickdown keeps the engine near the power plateau
		converter = {
			-- [E] not published. Launch control holds about 2,700 rpm [P] with about 1.0 bar of boost [M], so the
			-- converter absorbs about 480 Nm at 2,700 rpm; the same converter takes the full 650 Nm at 3,100 rpm.
			stallRpm = 3100,
			torqueRatio = 1.9, -- [E] typical for a sports converter
			couplingPoint = 0.87, -- [E]
			overrunCapacity = 0.6, -- [E]
		},
		lockup = {
			minGear = 1, -- [F] BMW: the lock-up clutch is "fully engaged the moment the car has pulled away"
			minSpeedKmh = 20, -- [E] closes after the engine reaches its boost range in 1st (2,744 rpm = 22 km/h)
			engageTime = 0.3, -- [E] s
			maxTorque = 910, -- [E] Nm, 1.4 x peak engine torque
		},
	},

	drivetrain = {
		layout = "RWD", -- [F]
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] Active M Differential: an electronically controlled multi-plate limited-slip differential,
		-- 0-100% locking [F]. BMW publishes no preload or lock values; this clutch-type approximation uses
		-- the research estimate of a light preload, with strong locking on power.
		rearDifferential = { type = "LimitedSlip", preload = 80, powerLock = 0.45, coastLock = 0.25, stiffness = 200 },
		frontDifferential = { type = "Open" },
		-- [E] DSC with slip control in the engine ECU [F] (M Traction Control, 10 stages). Caps engine torque at
		-- headroom x what the rear tyres can grip and trims while they slip past targetSlip.
		-- headroom 1.6: the cap ignores the engine's own inertia, which in 1st gear (15.8:1 overall) is worth about
		-- 480 kg; at 1.3 the rear tyres reached only 86% of their grip. rate 30 and recovery 6 (twice and three
		-- times the GT12's): BMW says the ECU-based slip control acts up to 10 times more often [F].
		tractionControl = { enabled = true, targetSlip = 0.11, rate = 30, recovery = 6, headroom = 1.6 },
	},

	-- [E] Spring and damper rates are not published. Springs from the research's ride frequencies of
	-- 1.6 Hz front and 1.8 Hz rear on the game's corner masses (the game has no separate unsprung mass:
	-- 479 kg front, 423 kg rear per corner): k = corner mass x (2 pi f)^2. Dampers at about 0.3 of
	-- critical in bump and 0.5 in rebound (adaptive M dampers in Sport). Anti-roll bars give about 56%
	-- of the roll stiffness at the front (front weight 53%) for mild understeer, and a roll gradient
	-- near 1.6 degrees per g.
	suspension = {
		front = {
			springRate = 48400, -- N/m at the wheel (research: 43,000 on the real car's sprung mass)
			bumpDamping = 2900, -- N*s/m
			reboundDamping = 4800, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.08, -- from ride height
			droopTravel = 0.08, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 32000, -- N/m of left-right travel difference
			rollCenterHeight = 0.06, -- [E] BMW: double-joint strut axle with a lowered roll centre [F]
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 54100, -- research: 48,000 on the real car's sprung mass
			bumpDamping = 2900,
			reboundDamping = 4800,
			staticLength = 0.25,
			bumpTravel = 0.08,
			droopTravel = 0.08,
			bumpStopRate = 250000,
			antiRollRate = 18000,
			rollCenterHeight = 0.10, -- [E] five-link rear axle [F]
			rideHeightOffset = 0,
		},
	},

	tires = {
		compounds = {
			-- [E] Road tyre in the class of the Michelin Pilot Sport 4S fitted to every test car (engineering
			-- reference only). muLong fitted between the measured braking (MotorTrend 60-0 mph 1.18 g, Car and
			-- Driver 70-0 mph 1.09 g mean, both including brake build-up) and the traction-limited launch (about
			-- 0.77 g to 50 mph); muLat for the 1.03 g skidpad (Car and Driver, MotorTrend). See docs/cars/RefM3G80.md.
			RoadPerformance = { base = "Performance", muLong = 1.25, muLat = 1.08 },
			-- [E] Track tyre in the class of the optional Pilot Sport Cup 2, about 12% more grip (not fitted by default).
			TrackTyre = { base = "SemiSlick", muLong = 1.40, muLat = 1.21, rollingResistance = 0.012 },
		},
		-- [F] 275/35 ZR19 front, 285/30 ZR20 rear on forged wheels: optional on the RWD car, and fitted to every
		-- magazine test car (standard is 275/40 ZR18 and 285/35 ZR19). [E] inertia: wheel, tyre and brake disc.
		front = { widthMm = 275, aspect = 35, rimInches = 19, compound = "RoadPerformance", inertia = 1.7 },
		rear = { widthMm = 285, aspect = 30, rimInches = 20, compound = "RoadPerformance", inertia = 1.95 },
	},

	brakes = {
		-- [F] M Compound brakes; magazine test cars had the M Carbon ceramic option (400 mm front, 380 mm rear)
		discs = "M Compound, 380 x 36 mm front with 6-piston fixed calipers, 370 x 24 mm rear with single-piston floating calipers",
		maxTorqueFront = 3600, -- [E] Nm per wheel; about 2,600 Nm locks a front wheel at 1.2 g
		maxTorqueRear = 1700, -- [E] Nm per wheel; about 68% front bias for a 53/47 car
		handbrakeTorque = 2000, -- [E] Nm per rear wheel (electric parking brake in the rear calipers [F])
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		dragArea = 0.772, -- [F] BMW's "cd x A": Cd 0.33 x 2.34 m^2
		-- [E] Lift is not published. BMW says the sills and aprons add underbody downforce; the research
		-- suggests near-zero net lift, 0.05-0.10 m^2 per axle (about 240 N front, 320 N rear at 290 km/h).
		downforceAreaFront = 0.06,
		downforceAreaRear = 0.08,
	},

	steering = {
		-- [E] 32 degrees average road-wheel angle reproduces the 12.2 m turning circle [F] on the 2,857 mm
		-- wheelbase. The 15:1 centre ratio [F] is variable (quicker toward lock), so 2.0 turns lock to lock [M].
		maxAngleLowSpeed = 32,
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above
		highSpeedKmh = 250, -- [E]
		rate = 220, -- [E] degrees per second the road wheels can turn
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made from the car's acoustic definition,
	-- assets/audio/engines/RefM3G80.json (firing order 1-5-3-6-2-4, turbo branches 1-3 and 4-6, valved
	-- dual-branch exhaust, 7,250 rpm fuel-cut limiter), by tools/synth_audio.py; see docs/AUDIO.md. Its
	-- per-loop gains come from the measured cabin levels (auto motor und sport: idle 45, full throttle
	-- 82 dB(A)) with the Active Sound Design share taken out, so outside cameras hear the engine itself.
	-- Volumes are Roblox Sound volumes; tune by ear in testing.
	audio = {
		engineSheet = "RefM3G80_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3, -- loudness at idle as a share of engineVolume
		rpmCurve = 1.0, -- how loudness rises with rpm (1 = in proportion)
		redlineRpm = 7250, -- [P] the limiter
		offThrottleLevel = 0.55, -- off-throttle loops relative to on-throttle
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back. This car's
		-- simulation cuts 4.5 times a second free-revving and 3.2-3.5 times in gear (gaps up to 0.31 s),
		-- so the hold is longer than the GT12's 0.3 s.
		limiterHold = 0.4,
		limiterAttack = 40, -- 1/s, how fast the limiter loops come in (about 25 ms)
		limiterRelease = 10, -- 1/s, and go out
		-- forced induction: no tester describes a turbo whistle (they note lag below 2,750 rpm), and there
		-- is no atmospheric blow-off valve [E], so both layers are kept quiet
		turboVolume = 0.15, -- whistle at full boost
		blowOffVolume = 0.2, -- internal recirculation whoosh
		blowOffMinBoost = 0.35, -- boost (0-1) needed for a blow-off when the throttle shuts
		superchargerVolume = 0.3, -- not used (turbo engine)
		-- the torque-converter automatic retards the ignition on upshifts: a milder crack than a dual-clutch's
		shiftCutTime = 0.08, -- seconds of ignition cut heard on a full-throttle upshift
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.4,
		shiftClunkVolume = 0.15,
		-- mild lift-off burble (SPORT; muted by the EU particulate filters), research estimate
		crackleMinRpm = 4000, -- exhaust crackles after lifting off above this
		crackleDuration = 0.8,
		crackleRate = 8, -- crackles per second at first, fading out
		crackleVolume = 0.25,
		bumpMinSpeed = 0.6, -- m/s into the bump stops before a knock is heard
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2, -- tyres start to squeal past this multiple of their peak slip
		squealRange = 1.5, -- and reach full volume this much further past it
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.04, -- quiet: ZF automatic and a clutch-pack differential
		whineTeeth = 13, -- [E] final drive 3.154 = 41:13, so a 13-tooth pinion sets the whine pitch
		-- cockpit camera. Active Sound Design plays engine orders through the speakers [F]: about half of the
		-- cabin engine sound under load (research estimate), +3 dB, which is +1.5 dB at the game's 0.5 level
		-- compression, so engine = 1.19. The equaliser lifts the low orders the speakers add and cuts the
		-- treble the cabin keeps out.
		interior = { engine = 1.19, wind = 0.45, road = 1.1, squeal = 0.7, lowGain = 4, midGain = -1, highGain = -12 },
	},

	-- [F] Factory figures (zeroTo60Mph, zeroTo100, zeroTo200, topSpeedKmh) and [M] magazine figures. US
	-- magazines time from a one-foot rollout (about 0.2-0.3 s quicker than a true standstill).
	performanceTargets = {
		zeroTo60Mph = 3.8, -- [F] BMW USA (BMW_US21)
		zeroTo100 = 3.9, -- [F] BMW_SPEC_M3
		zeroTo200 = 12.5, -- [F] BMW_PK
		topSpeedKmh = 290, -- [F] with the M Driver's Package (250 km/h without)
		zeroTo60MphRollout = 3.5, -- [M] Car and Driver and MotorTrend, both 3.5 s with a one-foot rollout
		zeroTo100Mph = 7.6, -- [M] Car and Driver, one-foot rollout (MotorTrend 7.5 s)
		quarterMile = 11.6, -- [M] Car and Driver and MotorTrend 11.6 s (one-foot rollout); The Citizen 11.58 s
		quarterMileKmh = 200.0, -- [M] Car and Driver 124 mph; MotorTrend 125.6 mph; The Citizen 201.2 km/h
		brake60MphTo0 = 31.1, -- [M] MotorTrend 102 ft
		brake70MphTo0 = 45.7, -- [M] Car and Driver 150 ft
	},

	visual = {
		bodyColor = Color3.fromRGB(18, 84, 62), -- [A] RGB approximation of the launch colour, a deep metallic green
		driverSide = "Left", -- [A] left-hand drive (EU and US cars)
		-- [E] Stand-in body. Profile: the research's trace of BMW's side drawing (heights normalised to the
		-- 1,433 mm roof [F]; front axle at 0.179 and rear axle at 0.775 of the length [F]). Its 0.81 and 0.87
		-- points are left out (both within 11 mm of the line) so the rear screen stays one glass plane.
		blockout = {
			profile = {
				{ 0.00, 0.640 }, { 0.03, 0.771 }, { 0.06, 0.833 }, { 0.09, 0.880 }, { 0.12, 0.912 }, { 0.16, 0.935 },
				{ 0.19, 0.949 }, { 0.22, 0.963 }, { 0.25, 0.971 }, { 0.28, 0.982 }, { 0.31, 0.993 }, { 0.34, 1.087 },
				{ 0.37, 1.174 }, { 0.40, 1.254 }, { 0.43, 1.327 }, { 0.46, 1.378 }, { 0.50, 1.403 }, { 0.53, 1.418 },
				{ 0.56, 1.426 }, { 0.59, 1.433 }, { 0.62, 1.429 }, { 0.65, 1.426 }, { 0.68, 1.414 }, { 0.74, 1.389 },
				{ 0.77, 1.320 }, { 0.84, 1.200 }, { 0.90, 1.076 }, { 0.93, 1.051 }, { 0.96, 1.037 }, { 0.99, 0.600 },
			},
			-- windscreen base (0.31) to just above the boot lid, so a painted strip marks the notchback's boot step
			greenhouse = { 0.31, 0.86 },
			-- the real side-window sill is about 1.0 m (cowl 0.99 m); 0.92 keeps the high shoulder and still shows
			-- the bonnet rising to the windscreen (the builder draws everything below the beltline as one box)
			beltline = 0.92,
			cabinWidth = 0.76, -- about 1.45 m of glasshouse inside the 1,903 mm flared body
			sill = 0.15, -- side sills; 120 mm ground clearance [F] is at the lowest point underneath
		},
	},
}
