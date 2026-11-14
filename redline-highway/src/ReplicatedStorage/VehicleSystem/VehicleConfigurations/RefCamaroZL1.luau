--[[
	Ridgeway Ironside SC (internal ID: RefCamaroZL1)

	An original front-engined, supercharged V8 muscle coupe from the fictional American brand
	Ridgeway, built on the publicly documented engineering of the Chevrolet Camaro ZL1 coupe
	(6th generation, 2017-2024) with the 10-speed automatic. No Chevrolet names, logos or designs are
	used in the game. docs/cars/RefCamaroZL1.md has the sources, how each estimate was made and the
	validation; research_notes/cars/RefCamaroZL1.json has the research behind every figure.

	Every value is tagged:
	  [F] manufacturer figure (GM product guide, press material or GM service bulletin)
	  [P] published third-party figure
	  [M] measured in a magazine or independent test
	  [E] estimate made for the simulation
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.

	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	docs/VEHICLE_CONFIG.md describes every field. This car uses the supercharger, the torque-converter
	automatic and its own tyre compound; it doesn't use drivetrain.centreCoupling or
	engine.speedLimitKmh (the real car is drag-limited at 198 mph, not electronically limited).
]]

return {
	id = "RefCamaroZL1",
	displayName = "Ridgeway Ironside SC",
	reference = "Chevrolet Camaro ZL1 (engineering reference only)",

	mass = {
		kerbKg = 1789, -- [F] GM curb weight, coupe with the 10-speed automatic (US convention: full fluids, no driver). Manual coupe 1,761 kg [F]; C/D's test car weighed 1,784 kg [M]
		driverKg = 75, -- [A] the simulation carries one driver
		frontShare = 0.53, -- [E] not published: supercharger, intercooler and 11 heat exchangers sit up front; the Camaro SS is quoted near 52/48
		comHeight = 0.49, -- [E] centre of mass above the ground at ride height: tall V8 and blower, 1,330 mm roof
		-- [E] Size of the invisible box that carries the car's mass. It sets the rotational
		-- inertia: about 3,300 kg*m^2 in yaw (radius of gyration 1.33 m, near half the wheelbase).
		inertiaBox = { width = 1.75, height = 0.80, length = 4.25 },
	},

	dimensions = {
		length = 4.812, -- [F] 190.2 in, 2019-on (2017-18 cars: 4.783 m [P])
		width = 1.897, -- [F] 74.7 in, without mirrors
		height = 1.330, -- [F] 52.4 in
		wheelbase = 2.811, -- [F] 110.7 in
		trackFront = 1.610, -- [F] 63.4 in
		trackRear = 1.591, -- [F] 62.6 in
		frontOverhang = 0.925, -- [E] front axle to the nose: side-photo overhang ratio applied to length minus wheelbase (rear overhang about 1.075 m)
	},

	engine = {
		layout = "90-degree V8, OHV pushrod, 2 valves per cylinder, direct injection, wet sump", -- [F] LT4 (Gen V small-block)
		displacementCc = 6162, -- [F] 376 cu in; bore x stroke 103.25 x 92.0 mm [F]; compression 10.0:1 [F]
		aspiration = "Supercharged", -- [P] Eaton R1740 TVS twin-rotor (Roots-type) blower with an air-to-liquid intercooler
		peakPowerKw = 485, -- [F] 650 hp (SAE certified)
		peakPowerRpm = 6400, -- [F]
		peakTorqueNm = 881, -- [F] 650 lb-ft (SAE certified); GM's 868 Nm is the older 640 lb-ft rating
		peakTorqueRpm = 3600, -- [F]
		idleRpm = 650, -- [E] warm idle; not published (Gen V LT V8s idle at about 600-700 rpm)
		limiterRpm = 6600, -- [P] GM's 6,600 rpm maximum engine speed for the LT4; the tachometer redline is 6,500 rpm [P]. Fuel-cut limiter there [E]
		limiterHysteresisRpm = 120, -- [E] research estimate 100-150 rpm
		inertia = 0.28, -- [E] kg*m^2: forged crank, flexplate, converter cover and impeller, plus the blower rotors (3.10 x crank speed, about 0.05 seen at the crank)
		-- [E] Full-BOOST torque curve, {rpm, Nm} (see docs/VEHICLE_CONFIG.md, "Turbo and supercharger
		-- torque curves"). The steady full-throttle torque the simulation makes is this curve times
		-- (0.68 + 0.32 x boost ceiling), the ceiling rising from 0 at 650 rpm to 1 at 2,800 rpm. Below
		-- 2,800 rpm the points are set so that product equals the research's crank estimate exactly:
		--   1,000: 620   1,500: 705   2,000: 770   2,500: 813   2,800: 847 Nm
		-- (620 Nm "just off idle" [P], 847 Nm by 2,800 rpm [P], at least 793 Nm from 2,500 to 5,400 [P]).
		-- From 2,800 rpm the curve is the crank estimate as it is: 881 Nm at 3,600 [F] and 723 Nm at
		-- 6,400 rpm (= 485 kW) [F], shaped between them like the K&N wheel-dyno curve [M].
		torqueCurve = {
			{ 1000, 847 },
			{ 1500, 874 },
			{ 2000, 874 },
			{ 2500, 851 },
			{ 2800, 847 },
			{ 3000, 861 },
			{ 3500, 879 },
			{ 3600, 881 },
			{ 4000, 872 },
			{ 4500, 851 },
			{ 5000, 830 },
			{ 5500, 800 },
			{ 6000, 762 },
			{ 6400, 723 },
			{ 6500, 708 },
			{ 6600, 685 },
		},
		-- [E] Internal friction, felt as engine braking with the throttle closed: static + perRpm * rpm (Nm).
		-- A 6.2-litre pushrod V8 with a blower that still turns (bypass valve open). The torque curve
		-- is net output, so friction isn't subtracted at full throttle.
		friction = { static = 25, perRpm = 0.012 },
		throttleResponse = 20, -- [E] 1/s, how quickly the throttle follows the pedal (87 mm electronic throttle [P]); with the hysteresis it gives about 4 limiter cuts a second
		-- [P]/[E] Eaton R1740 TVS: 1.74 L per rotor revolution, two 4-lobe rotors with 160-degree twist,
		-- driven at 3.10 x crank speed (20,150 rotor rpm at 6,500) [P]. A positive-displacement blower:
		-- boost follows rpm and throttle with no lag.
		forcedInduction = {
			type = "Supercharger", -- [P]
			maxBoostBar = 0.65, -- [P] 9.4 psi (EngineLabs, GM's launch figure; Corvette Action Center gives 9.7 psi)
			-- [E] share of the full-boost curve made with no boost (bypass valve open): about 580-600 Nm,
			-- between the naturally aspirated LT1's 630 Nm at 11.5:1 and what 10.0:1 and the blower in the
			-- intake path allow. The pressure ratio alone (1 / 1.65 = 0.61) ignores the hotter boosted
			-- charge and the blower's drive power, which both raise the share.
			offBoostTorqueShare = 0.68,
			boostStartRpm = 650, -- [E] at idle: a Roots blower starts building boost as soon as the bypass closes
			fullBoostRpm = 2800, -- [E] where GM's torque reaches 847 Nm (96% of peak) [P]
		},
	},

	transmission = {
		type = "Automatic", -- [F] Hydra-Matic 10L90 10-speed automatic with paddles (RPO MGL)
		gearRatios = { 4.70, 2.99, 2.15, 1.80, 1.52, 1.28, 1.00, 0.85, 0.69, 0.64 }, -- [F] GM
		reverseRatio = 4.87, -- [F]
		finalDrive = 2.85, -- [F] automatic coupe (the automatic convertible uses 2.77 [P])
		efficiency = 0.88, -- [E] ten-speed planetary gearbox with the lock-up closed, plus the final drive
		shiftTime = 0.12, -- [E] upshift speed change. GM: 1-2 upshifts 36% quicker than Porsche's PDK [F]; no absolute times published
		downshiftTime = 0.20, -- [E]
		shiftTorqueReduction = 0.40, -- [E] spark retard during power-on upshifts
		downshiftBlip = 0.35, -- [E] the 1LE automatic's Track mode rev-matches every downshift [F]
		turbineInertia = 0.06, -- [E] kg*m^2, 260 mm converter's turbine and the gearbox input
		minShiftInterval = 0.25, -- [E]
		-- GM's Track shift pattern for the 1LE automatic (bulletin 19-NA-038 [F]), applied to this car [A]:
		-- in normal driving it upshifts at about 3,000 rpm and downshifts at about 2,000; driven hard it
		-- holds gears to near the redline. (It cruises at 70 mph in 6th at about 3,150 rpm; Tour mode would
		-- be 10th at about 1,600.)
		autoUpshiftRpm = { light = 3000, full = 6450 }, -- [F]/[A] light; [E] full, just under the 6,500 rpm redline [P]
		autoDownshiftRpm = { light = 2000, full = 4000 }, -- [F]/[A] light; [E] full: the kickdown target
		converter = {
			stallRpm = 2600, -- [E] research estimate for a 260 mm converter [F] behind 881 Nm; not published
			torqueRatio = 1.9, -- [E]
			couplingPoint = 0.87, -- [E]
			overrunCapacity = 0.6, -- [E]
		},
		lockup = {
			minGear = 2, -- [E]
			minSpeedKmh = 20, -- [E]
			engageTime = 0.4, -- [E] electronically controlled capacity clutch (ECCC) [F]
			maxTorque = 1300, -- [E] Nm, about 1.5 x peak torque
		},
	},

	drivetrain = {
		layout = "RWD", -- [F]
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] The real car has an electronic limited-slip differential: a hydraulic clutch pack giving
		-- 0-200 Nm of "breakaway torque" between the rear wheels, fully engaged in 0.15 s [F]. This is
		-- a clutch-type approximation: preload in Nm, lock factors as shares of input torque.
		rearDifferential = { type = "LimitedSlip", preload = 100, powerLock = 0.35, coastLock = 0.20, stiffness = 180 },
		frontDifferential = { type = "Open" },
		-- [E] Traction control. The real car's Performance Traction Management and launch control hold
		-- a wheel-slip target of 5-15% [F]. It caps engine torque at headroom times what the rear tyres
		-- can grip, and trims further while they slip more than targetSlip. rate and recovery are how
		-- fast that trim builds and fades (per second).
		-- recovery is quick (the cut fades in about 0.08 s), so a launch doesn't bog after the first slip.
		tractionControl = { enabled = true, targetSlip = 0.10, rate = 15, recovery = 12, headroom = 1.3 },
	},

	-- [E] Not published (gap): Magnetic Ride Control dampers, MacPherson-type front strut and five-link
	-- rear [F]. Springs from target ride frequencies of 1.6 Hz front and 1.8 Hz rear (k = corner
	-- mass x (2 pi f)^2), dampers from damping ratios of about 0.3 in bump and 0.5 in rebound.
	suspension = {
		front = {
			springRate = 50000, -- N/m at the wheel
			bumpDamping = 3000, -- N*s/m
			reboundDamping = 5000, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.08, -- from ride height
			droopTravel = 0.07, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 36000, -- N/m of left-right travel difference (front takes about 57% of the roll stiffness)
			rollCenterHeight = 0.06, -- strut front: low roll centre
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 56000,
			bumpDamping = 3000,
			reboundDamping = 4950,
			staticLength = 0.25,
			bumpTravel = 0.08,
			droopTravel = 0.07,
			bumpStopRate = 250000,
			antiRollRate = 18000,
			rollCenterHeight = 0.10, -- five-link rear
			rideHeightOffset = 0,
		},
	},

	tires = {
		-- [E] Road tyres in the Goodyear Eagle F1 Supercar 3 class (summer tyres with a Camaro-specific
		-- compound [F]; engineering reference only). Lateral grip is the same front and rear: about 1.03 g
		-- on a 300 ft skidpad by a steady-state estimate (GM 1.02 g [F], C/D 1.04 g [M]). Longitudinal
		-- grip is fitted per axle, because the straight-line tests load the axles differently: the rear
		-- tyres alone drive the car, so theirs is fitted to GM's 0-60 mph and quarter mile; the front
		-- tyres do about 73% of a hard stop and none of the driving, so theirs is fitted to the 60-0 and
		-- 70-0 mph stops. With one value for both, the model either stops 9% short or launches 0.3 s slow:
		-- it brakes instantly with near-ideal ABS, while real stops include pedal build-up and ABS cycling.
		compounds = {
			MaxSummerFront = { base = "Performance", muLong = 1.16, muLat = 1.10 },
			MaxSummerRear = { base = "Performance", muLong = 1.30, muLat = 1.10 },
		},
		front = { widthMm = 285, aspect = 30, rimInches = 20, compound = "MaxSummerFront", inertia = 1.7 }, -- [F] 285/30ZR20 on 20 x 10 forged wheels, [E] inertia (kg*m^2, with the 390 mm rotor)
		rear = { widthMm = 305, aspect = 30, rimInches = 20, compound = "MaxSummerRear", inertia = 1.9 }, -- [F] 305/30ZR20 on 20 x 11 forged wheels, [E] inertia (kg*m^2, with rotor and half-shaft)
	},

	brakes = {
		discs = "Brembo: 6-piston monobloc front calipers on 390 x 36 mm two-piece vented rotors; 4-piston rear calipers on 365 x 28 mm vented rotors", -- [F]
		maxTorqueFront = 4200, -- [E] Nm per wheel: enough to lock the front tyres
		maxTorqueRear = 2200, -- [E] Nm per wheel (about 66% front bias)
		handbrakeTorque = 2200, -- [E] Nm per rear wheel
		abs = { enabled = true, targetSlip = 0.12 }, -- [E] four-channel ABS [F]
	},

	aero = {
		-- [E] CdA in m^2. GM never published a Cd. Fitted so 650 hp gives the 198 mph top speed in 8th
		-- (research: 0.90-0.99 for 85-90% driveline efficiency). A lap-sim's 0.364 x 2.07 m^2 = 0.75
		-- would let the car reach about 210 mph.
		dragArea = 0.92,
		-- [E] GM: the ZL1's splitter and pedestal spoiler "reduce lift" with no significant drag penalty
		-- [F], no figures. Near-zero net lift.
		downforceAreaFront = 0.0,
		downforceAreaRear = 0.05,
	},

	steering = {
		maxAngleLowSpeed = 34, -- [E] mean road-wheel angle that gives GM's 11.7 m turning circle [F]
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above (keyboard-friendly)
		highSpeedKmh = 250, -- [E]
		rate = 210, -- [E] degrees per second the road wheels can turn (ZF electric rack [F], ratio not published)
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made from the car's acoustic definition,
	-- assets/audio/engines/RefCamaroZL1.json (firing order 1-8-7-2-6-5-4-3 with GM bank numbering,
	-- cross-plane crank, valved dual exhaust, the Eaton blower's whine at 3.10 x crank speed and 8
	-- pulses per rotor turn, the fuel-cut limiter at 6,600 rpm and the estimated cabin levels, each
	-- with its source), by tools/synth_audio.py; docs/AUDIO.md explains sheets and the mixer. Volumes
	-- are Roblox Sound volumes; the loudness over rpm and load comes from the sheet's per-loop gains.
	-- Set by measurement (docs/cars/RefCamaroZL1.md); tune by ear in testing.
	audio = {
		engineSheet = "RefCamaroZL1_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3,
		rpmCurve = 1.0,
		redlineRpm = 6500, -- [P] tachometer redline
		offThrottleLevel = 0.55,
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back
		limiterHold = 0.3, -- s after the last cut before the normal loops return (the model cuts about 4 times a second, cut active most of the time)
		limiterAttack = 40, -- 1/s (about 25 ms)
		limiterRelease = 10, -- 1/s
		-- forced induction: no turbo, so the turbo and blow-off settings are unused
		turboVolume = 0.35,
		blowOffVolume = 0.6,
		blowOffMinBoost = 0.35,
		-- [E] Supercharger whine (0.4133 x rpm Hz, plus a weaker line at half that pitch from the sheet).
		-- Reviewers hear it most at low revs and part throttle, faintly at a quiet idle, and covered by the
		-- exhaust at high revs [P]. Level = superchargerVolume x (idleShare + (1 - idleShare) x boost) x
		-- clamp(rpm / fullRpm, rpmFloor, 1). Measured against the rest of the mix: about 11-13 dB(A) under
		-- in full-throttle pulls from 1,500 to 4,500 rpm, 15-17 under at part throttle, 16 under at full
		-- throttle above 4,500 rpm and 21 under at idle.
		superchargerVolume = 0.06,
		superchargerIdleShare = 0.4, -- the rotors still sweep their pockets with the bypass valve open
		superchargerFullRpm = 1500,
		superchargerRpmFloor = 0.5,
		-- 10-speed upshifts at full throttle: a short torque cut; GM says pops during wide-open-throttle
		-- manoeuvres in Sport or Track are normal [F]
		shiftCutTime = 0.06,
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.5,
		shiftClunkVolume = 0.15, -- smooth planetary automatic: a soft clunk
		crackleMinRpm = 3500, -- overrun pops after lifting off above this ("exhaust blatting on the overrun" [P])
		crackleDuration = 1.0,
		crackleRate = 10,
		crackleVolume = 0.45,
		bumpMinSpeed = 0.6,
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2,
		squealRange = 1.5,
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.05,
		whineTeeth = 13, -- [E] rear-axle pinion: a 37:13 ring and pinion gives the 2.85 final drive
		-- cockpit camera: level changes and an equaliser (dB) for the cabin
		interior = { engine = 0.85, wind = 0.45, road = 1.0, squeal = 0.7, lowGain = 3, midGain = -1, highGain = -10 },
	},

	-- Published figures the telemetry timer and tools/drivetrain_model.py compare against. US figures
	-- (GM's included) are taken with a one-foot rollout, as SAE J1491 and the drag strip do; the
	-- in-game timer starts from a true standstill, so it reads about 0.3 s more (0.32-0.36 s in the model).
	performanceTargets = {
		zeroTo60MphRollout = 3.5, -- [F] GM, 10-speed coupe, OE tyres on a non-prepped surface. Tests [M]: C/D 3.4 s, Motor Trend 3.5 s, MotorWeek 3.5 s, Hennessey 3.6 s
		zeroTo100Mph = 7.6, -- [M] Hennessey's stock 10-speed baseline run
		quarterMile = 11.4, -- [F] GM (with rollout). Tests [M]: C/D and Motor Trend 11.5 s at 125 mph, MotorWeek 11.5 s at 127 mph
		quarterMileKmh = 204.4, -- [F] 127 mph
		topSpeedKmh = 319, -- [F] 198 mph, two-way average at Papenburg (202.3 / 193.3 mph), stock 10-speed car
		brake60MphTo0 = 32.6, -- [F] 107 ft (GM's guide misprints the metric figure as 35 m)
		brake70MphTo0 = 43.6, -- [M] Car and Driver, 143 ft, automatic coupe, March 2017
	},

	visual = {
		bodyColor = Color3.fromRGB(196, 22, 28), -- [A] approximation of the launch-year solid red ("Red Hot")
		driverSide = "Left", -- [F] left-hand drive
		-- [E] Stand-in body (VehicleModelBuilder). Long-hood, short-deck 2+2 fastback with a high
		-- beltline and a low, narrow ("gun-slit") greenhouse, judged from freely licensed photos (research
		-- notes, "Visual blockout"): front axle at 0.19 of the length, windscreen base 0.34, windscreen
		-- header 0.48, roof peak 0.57 at the published 1,330 mm [F], rear window base 0.83, rear axle 0.78;
		-- cowl about 0.93 m, hood leading edge about 0.77 m, spoiler lip about 1.04 m.
		-- The builder's lower body is one box up to the beltline, so the real window line (about 0.93 m)
		-- would bury the hood's rise to the cowl; the beltline sits at 0.85 m so the hood reads, and the
		-- side glass is then about 0.41 m tall (real daylight opening about 0.37 m). The side glass stops
		-- at 0.76, leaving the thick C-pillar sail painted down to the deck.
		blockout = {
			profile = {
				{ 0, 0.72 }, -- front fascia top (below the beltline: the nose shows at 0.85 m)
				{ 0.03, 0.79 }, -- hood leading edge
				{ 0.19, 0.87 }, -- over the front axle
				{ 0.34, 0.93 }, -- cowl, windscreen base
				{ 0.48, 1.30 }, -- windscreen header
				{ 0.57, 1.33 }, -- roof peak, the published height [F]
				{ 0.66, 1.29 }, -- rear edge of the roof
				{ 0.76, 1.11 }, -- end of the side glass; C-pillar sail behind it
				{ 0.83, 1.01 }, -- rear window base, short high deck
				{ 0.97, 1.04 }, -- spoiler lip
				{ 1, 0.97 }, -- tail panel top
			},
			greenhouse = { 0.34, 0.76 },
			beltline = 0.85,
			cabinWidth = 0.70, -- narrow greenhouse on a wide body
			sill = 0.13, -- about 130 mm at the sills [E]
		},
	},
}
