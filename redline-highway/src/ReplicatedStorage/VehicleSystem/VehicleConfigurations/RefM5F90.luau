--[[
	Brandt Nordwind RS (internal ID: RefM5F90)

	An original four-door super-saloon from the fictional German maker Brandt, built on the publicly
	documented engineering of the BMW M5 Competition (F90), LCI (2021-2023) EU specification. No BMW
	names, logos or designs are used in the game. Sources, estimates and validation:
	docs/cars/RefM5F90.md; the research behind them: research_notes/cars/RefM5F90.json and .md.

	Every value is tagged:
	  [F] factory figure (BMW AG or BMW of North America press kits and specification sheets)
	  [P] published third-party figure, or BMW material for the sister S63TU engine
	  [M] measured in a magazine or independent test
	  [E] estimate made for the simulation (method given)
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.

	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	Default drive set-up: M xDrive in "4WD Sport" (drivetrain.centreCoupling), the 8-speed torque-
	converter automatic in D with sporty shift times, the M Driver's Package 305 km/h limiter, and
	the exhaust and Active Sound Design in SPORT (see audio).
]]

return {
	id = "RefM5F90",
	displayName = "Brandt Nordwind RS",
	reference = "BMW M5 Competition (F90) (engineering reference only)",

	mass = {
		-- BMW publishes no dry weight for the F90.
		kerbKg = 1895, -- [F] DIN kerb weight, LCI (BMW 06/2020): fuel, no driver. US curb 4,345 lb = 1,971 kg [F]
		driverKg = 75, -- [A] one driver: 1,970 kg simulated = BMW's EU kerb mass (DIN + 75 kg) [F]
		frontShare = 0.544, -- [F] 54.4 % front / 45.6 % rear (BMW NA 2021)
		comHeight = 0.50, -- [E] not published; large saloon, V8 high in the hot-V, CFRP roof: 0.48-0.53 m
		-- [E] Box that carries the mass, sized for about 3,700 kg*m^2 in yaw (research: uniform-box value
		-- m(L^2+W^2)/12 = 4,660 scaled by 0.8 for mass between the axles), about 680 in roll, 3,250 in pitch.
		inertiaBox = { width = 1.85, height = 0.85, length = 4.37 },
	},

	dimensions = {
		length = 4.983, -- [F] LCI (pre-LCI 4.966)
		width = 1.903, -- [F] without mirrors (2.126 with)
		height = 1.469, -- [F] Competition, 7 mm lower than the M5
		wheelbase = 2.982, -- [F]
		trackFront = 1.625, -- [F] Competition (more negative camber)
		trackRear = 1.594, -- [F]
		frontOverhang = 0.888, -- [F] LCI dimension drawing (888 + 2,982 + 1,113 = 4,983 mm)
	},

	engine = {
		layout = "90-degree V8, twin-turbo hot-V (S63B44T4)", -- [F] code and turbos; [P] hot-V layout
		displacementCc = 4395, -- [F] bore 89.0 mm, stroke 88.3 mm, compression 10.0:1
		aspiration = "Turbo", -- [F] two twin-scroll turbos, cross-bank exhaust manifolds
		peakPowerKw = 460, -- [F] 625 PS / 617 hp
		peakPowerRpm = 6000, -- [F] (flat 460 kW from about 5,860 rpm on BMW's chart)
		peakTorqueNm = 750, -- [F]
		peakTorqueRpm = 1800, -- [F] start of the 750 Nm plateau, which runs to 5,860 rpm (LCI)
		idleRpm = 600, -- [E] not published; warm idle of the N63/S63 family 550-650 rpm
		limiterRpm = 7200, -- [F] BMW NA: redline 7,200 rpm (M5 CS, same engine); [P] S63TU manual: cut-off 7,200
		limiterHysteresisRpm = 150, -- [E] research suggests a 150-250 rpm bounce
		-- [E] kg*m^2: crank, flexplate and the converter's cover and impeller. Research estimate 0.30; a
		-- component sum (crank and pistons about 0.08, flexplate 0.025, converter primary side with oil
		-- about 0.10) gives about 0.21. Middle value.
		inertia = 0.25,
		-- Full-BOOST torque curve, {rpm, Nm} (docs/VEHICLE_CONFIG.md, "Turbo and supercharger torque
		-- curves"). With forcedInduction below, the steady full-throttle curve the game produces passes
		-- through BMW's 06/2020 chart: 400 Nm at 1,000 rpm, 480.5 at 1,244, 600 at 1,500, 750 from 1,800
		-- to 5,860, 732.5 at 6,000 (= 460 kW), 647.4 at 6,600, 587 at 7,000, 564 at 7,200 (all [F], read
		-- from the chart's vector paths; its power curve agrees within 0.5 kW).
		torqueCurve = {
			{ 600, 562 }, -- [E] gives the research's estimate of 300 Nm at 600 rpm (x 0.533 off boost)
			{ 800, 656 }, -- [E] gives 350 Nm at 800 rpm
			{ 1000, 750 }, -- [F] gives 400 Nm at 1,000 rpm
			{ 1244, 763.5 }, -- [E] full-boost value chosen so the steady curve gives the chart's 480.5 Nm
			{ 1500, 750 }, -- [F] gives 600 Nm at 1,500 rpm
			{ 1800, 750 }, -- [F] 750 Nm plateau from 1,800 rpm
			{ 5860, 750 }, -- [F] to 5,860 rpm (LCI; the chart's plotted plateau ends at 5,859)
			{ 6000, 732.5 }, -- [F] chart: 460 kW
			{ 6600, 647.4 }, -- [F] chart
			{ 7000, 587 }, -- [F] chart
			{ 7200, 564 }, -- [F] chart, where BMW's curve ends (cut-off)
		},
		-- [E] Engine braking with the throttle shut: static + perRpm * rpm (Nm): about 31 Nm at 1,000 rpm,
		-- 79 at 6,000 and 90 at 7,200. Motoring friction of a 4.4 L V8 (about 1.6 bar FMEP at 6,000 rpm, 55 Nm)
		-- plus closed-throttle pumping, which VALVETRONIC keeps low (about 0.5 bar), plus accessories.
		friction = { static = 22, perRpm = 0.0095 },
		throttleResponse = 16, -- [E] 1/s
		speedLimitKmh = 305, -- [F] M Driver's Package limit (BMW Ireland's LCI release says 304). Without it: 250 [F]
		forcedInduction = {
			type = "Turbo", -- [F] two twin-scroll turbochargers inside the V
			maxBoostBar = 1.75, -- [E] base M5 24.46 psi = 1.69 bar [F]; Competition estimated 1.7-1.8 bar
			offBoostTorqueShare = 0.533, -- derived from the [F] chart: 400 Nm at 1,000 rpm / 750 Nm
			boostStartRpm = 1100, -- [E] chart: torque starts climbing from naturally-aspirated level at 1,000-1,200 rpm
			fullBoostRpm = 1800, -- [F] full 750 Nm from 1,800 rpm
			spoolTime = 0.6, -- [E] twin-scroll turbos close to the ports; reviewers report essentially no lag
			dumpTime = 0.3, -- [E] no blow-off valve [P]: boost bleeds off through the engine and wastegates
		},
	},

	transmission = {
		type = "Automatic", -- [F] 8-speed M Steptronic torque-converter automatic (ZF 8HP: M8HP76 / GA8HP75Z)
		gearRatios = { 5.000, 3.200, 2.143, 1.720, 1.313, 1.000, 0.823, 0.640 }, -- [F]
		reverseRatio = 3.478, -- [F] EU sheet (BMW NA prints 3.38)
		finalDrive = 3.154, -- [F] (front and rear axle drives; transfer case 1:1 [A])
		efficiency = 0.88, -- [E] locked converter, transfer case and two axle drives: 0.85-0.90
		shiftTime = 0.2, -- [E] upshift speed change, Drivelogic 2 (research: about 0.35 / 0.22 / 0.12 s in Drivelogic 1 / 2 / 3)
		downshiftTime = 0.2, -- [E]
		shiftTorqueReduction = 0.4, -- [E] ignition retard during power-on upshifts
		downshiftBlip = 0.3, -- [E] rev-matching blip on downshifts
		turbineInertia = 0.05, -- [E] converter turbine and gearbox input
		converter = {
			stallRpm = 2500, -- [E] not published; research: converter flares to 2,500-3,000 rpm at full throttle from rest
			torqueRatio = 1.9, -- [E]
			couplingPoint = 0.87, -- [E]
		},
		lockup = {
			minGear = 1, -- [F] BMW: the lock-up clutch "fully engages once the car has pulled away"
			minSpeedKmh = 12, -- [E]
			engageTime = 0.4, -- [E]
			maxTorque = 1100, -- [E] about 1.5 x peak torque
		},
		autoUpshiftRpm = { light = 1700, full = 7050 }, -- [E] in D at full throttle it upshifts just before the cut-off [P]
		autoDownshiftRpm = { light = 1000, full = 4500 }, -- [E]
		minShiftInterval = 0.3, -- [E]
	},

	drivetrain = {
		layout = "AWD", -- [F] M xDrive: rear-biased all-wheel drive, 2WD selectable with DSC off
		-- [E] The electronically controlled multi-plate centre clutch in "4WD Sport" (M Dynamic Mode or DSC
		-- off): the rear axle is always driven and the front is brought in only when the rear can't take more
		-- torque [F]. BMW publishes no split; research estimate: up to about 35 % to the front in 4WD Sport
		-- (about 50 % in 4WD, 0 % in 2WD).
		-- The game's coupling only reacts to slip, while M xDrive also acts ahead of it, so the threshold is
		-- small (1.5 %) and the coupling stiff: this car puts up to about 10,000 Nm through the wheels in 1st.
		centreCoupling = { baseFrontShare = 0.05, maxFrontShare = 0.35, slipThreshold = 0.015, stiffness = 6000, preload = 0 },
		-- [E] Active M Differential: electronically controlled multi-plate rear differential, 0-100 % locking
		-- [F]. Approximated with a clutch-type limited slip.
		rearDifferential = { type = "LimitedSlip", preload = 100, powerLock = 0.40, coastLock = 0.20, stiffness = 200 },
		frontDifferential = { type = "Open" }, -- [A] no front limited slip in any BMW material
		-- [E] DSC with M xDrive and launch control [F/P]; automatic launches rely on it. The target sits a
		-- little past the tyre's peak slip (0.10), as launch control does; recovery 4/s so one slip spike at
		-- a standing start doesn't hold the torque down for half a second.
		tractionControl = { enabled = true, targetSlip = 0.12, rate = 15, recovery = 4, headroom = 1.3 },
	},

	-- [E] Not published. Ride frequencies of 1.7 Hz front and 1.85 Hz rear (research) with the game's whole
	-- corner mass on the springs (536 kg front, 449 kg rear), damping ratios of about 0.3 in bump and 0.5 in
	-- rebound, and the research's anti-roll-bar estimates (Competition: firmer rear bar [F]).
	suspension = {
		front = {
			springRate = 61000, -- N/m at the wheel
			bumpDamping = 3400, -- N*s/m
			reboundDamping = 5700, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.09, -- from ride height
			droopTravel = 0.08, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 30000, -- N/m of left-right travel difference
			rollCenterHeight = 0.07, -- double wishbone [F]
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 60700,
			bumpDamping = 3100,
			reboundDamping = 5200,
			staticLength = 0.25,
			bumpTravel = 0.09,
			droopTravel = 0.08,
			bumpStopRate = 250000,
			antiRollRate = 22000,
			rollCenterHeight = 0.11, -- five-link [F]
			rideHeightOffset = 0,
		},
	},

	tires = {
		-- [E] The OE tyre is the Pirelli P Zero (star) [M] (engineering reference only), a road performance
		-- tyre. muLong is fitted to Car and Driver's 70-0 mph stop in 139 ft (42.4 m, about 1.18 g mean on a
		-- 1,970 kg car); muLat aims at C/D's 0.95-1.00 g skidpad once load transfer and load sensitivity take
		-- their share (untested: needs Studio). The rest is the shared Performance compound.
		compounds = {
			NordwindRoad = { base = "Performance", muLong = 1.23, muLat = 1.08 },
		},
		front = { widthMm = 275, aspect = 35, rimInches = 20, compound = "NordwindRoad", inertia = 1.7 }, -- [F] 275/35 ZR20 on 9.5J; [E] inertia (kg*m^2)
		rear = { widthMm = 285, aspect = 35, rimInches = 20, compound = "NordwindRoad", inertia = 1.9 }, -- [F] 285/35 ZR20 on 10.5J; [E] inertia
	},

	brakes = {
		discs = "M Compound, 395 x 36 mm front with 6-piston fixed calipers, 380 x 28 mm rear with 1-piston floating calipers", -- [F]
		maxTorqueFront = 4200, -- [E] Nm per wheel, enough to lock the wheels (research)
		maxTorqueRear = 2200, -- [E] Nm per wheel (about 66 % front)
		handbrakeTorque = 2200, -- [E] Nm per rear wheel (electric parking brake in the rear calipers [F])
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		dragArea = 0.77, -- [F] CdA, LCI M5 Competition (BMW 06/2020); Cd 0.31 [F] (BMW NA)
		-- [E] Not published; road saloon with a boot-lid Gurney: slight net lift, about 240 N at 250 km/h
		-- (negative = lift).
		downforceAreaFront = -0.05,
		downforceAreaRear = -0.03,
	},

	steering = {
		maxAngleLowSpeed = 33, -- [E] mean road-wheel angle from the 12.6 m turning circle [F] (inner 38, outer 29)
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above
		highSpeedKmh = 250, -- [E]
		rate = 200, -- [E] degrees per second the road wheels can turn
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made from the car's acoustic definition, assets/audio/engines/RefM5F90.json
	-- (firing order 1-5-4-8-6-3-7-2, cross-plane crank, hot-V cross-bank manifolds giving each twin-scroll
	-- turbo an even 180-degree pulse train, valved dual-branch exhaust, fuel-cut limiter at 7,200 rpm), by
	-- tools/synth_audio.py; see docs/AUDIO.md and docs/cars/RefM5F90.md. The exhaust and Active Sound Design
	-- are in SPORT. Loudness over rpm and load comes from the sheet's per-loop gains (research estimate of
	-- the cabin levels: idle 47, full throttle 79 dBA); engineVolume scales all of it. Volumes are Roblox
	-- Sound volumes. To be tuned by ear in testing.
	audio = {
		engineSheet = "RefM5F90_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3,
		rpmCurve = 1.0,
		redlineRpm = 7200, -- [F]
		offThrottleLevel = 0.55,
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back. In the simulation the
		-- cut flag is on about 88 % of the time at the limiter, with gaps of at most 0.09 s, inside the hold.
		limiterHold = 0.3,
		limiterAttack = 40,
		limiterRelease = 10,
		-- forced induction: a subdued whistle (research), about 11 dB under the engine at 3,000 rpm on full
		-- boost; no blow-off valve [P], so no blow-off sound (the sheet has none either)
		turboVolume = 0.05,
		blowOffVolume = 0,
		blowOffMinBoost = 0.35,
		superchargerVolume = 0,
		-- torque-converter upshifts: a short torque dip, no dual-clutch "bark" (research)
		shiftCutTime = 0.08,
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.12,
		shiftClunkVolume = 0.15,
		-- SPORT: occasional light burble on lift-off; the EU particulate filter softens it
		crackleMinRpm = 3500,
		crackleDuration = 1.0,
		crackleRate = 5,
		crackleVolume = 0.25,
		bumpMinSpeed = 0.6,
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2,
		squealRange = 1.5,
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.04,
		whineTeeth = 13, -- [E] final drive 41:13 = 3.1538, which matches the published 3.154 [F]
		-- cockpit camera: the engine at its calibrated cabin level (the measured cabin levels include Active
		-- Sound Design), a low-frequency lift for ASD's speaker layer of low engine orders (at most about 6 dB
		-- at full throttle in SPORT [E]), and a well-insulated cabin ("mellow from inside", a quiet idle)
		interior = { engine = 1.0, wind = 0.4, road = 1.0, squeal = 0.7, lowGain = 5, midGain = -2, highGain = -12 },
	},

	performanceTargets = {
		zeroTo60Mph = 3.1, -- [F] BMW NA 2021 (taken as from a standstill [A])
		zeroTo60MphRollout = 2.8, -- [M] Car and Driver, 2021 M5 Competition, with a 1-ft rollout
		zeroTo100 = 3.3, -- [F] BMW 06/2020 (The Citizen measured 3.28 s [M])
		zeroTo100Mph = 6.7, -- [M] Car and Driver 2021, with a 1-ft rollout
		zeroTo200 = 10.8, -- [F] BMW 06/2020
		quarterMile = 11.22, -- [M] The Citizen 2021, LCI, from a standstill [A]; C/D: 10.9 s with a 1-ft rollout
		quarterMileKmh = 206.6, -- [M] The Citizen; C/D 128 mph = 206 km/h
		topSpeedKmh = 305, -- [F] with the M Driver's Package (250 without)
		brake70MphTo0 = 42.4, -- [M] Car and Driver 2021: 139 ft
		-- no 100-0 km/h figure is published; C/D's 70-0 mph scales to about 33.5 m [E]
	},

	visual = {
		bodyColor = Color3.fromRGB(30, 88, 170), -- [A] approximation of Marina Bay Blue, a launch colour
		driverSide = "Left", -- [F] left-hand drive (EU reference car)
		-- [E] Side profile measured by the research on BMW's LCI side-view dimension drawing (06/2020, page 6),
		-- scaled by the 4,983 mm length (measurement only; nothing traced), +/- 0.01 of length. A Commons
		-- near-profile photo agrees within 0.01-0.02. The highest point is the published height [F].
		blockout = {
			profile = {
				{ 0.000, 0.62 }, -- nose: near-vertical face (sets the headlight height)
				{ 0.025, 0.77 }, -- bonnet leading edge
				{ 0.050, 0.83 },
				{ 0.100, 0.90 },
				{ 0.200, 0.97 },
				{ 0.305, 1.00 }, -- windscreen base (cowl)
				{ 0.350, 1.15 },
				{ 0.400, 1.29 }, -- windscreen rake about 27 degrees
				{ 0.470, 1.42 }, -- windscreen header
				{ 0.590, 1.469 }, -- roof peak = published height 1,469 mm [F]
				{ 0.700, 1.455 }, -- rear window top
				{ 0.800, 1.30 },
				{ 0.885, 1.10 }, -- rear window base, start of the boot deck
				{ 0.950, 1.06 },
				{ 0.975, 1.045 }, -- boot-lid spoiler lip
				{ 1.000, 0.95 }, -- tail
			},
			greenhouse = { 0.305, 0.885 }, -- cowl to rear-window base
			-- The stand-in's lower body is a box up to the beltline over the whole length, so this sits
			-- between the real side-window sill (about 1.0 m) and the bonnet's leading edge (0.77 m).
			beltline = 0.94,
			cabinWidth = 0.76,
			sill = 0.17, -- research: sills about 0.175 m off the ground (ground clearance 128 mm [F])
		},
	},
}
