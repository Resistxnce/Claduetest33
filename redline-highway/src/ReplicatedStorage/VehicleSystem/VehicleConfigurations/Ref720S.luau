--[[
	Ashcombe AR-7 (internal ID: Ref720S)

	An original mid-engined two-seat coupe from the fictional British maker Ashcombe, built on the
	publicly documented engineering of the McLaren 720S coupe (2017-2023). No McLaren names, logos
	or designs are used in the game. Sources, estimates and validation: docs/cars/Ref720S.md; the
	research behind them: research_notes/cars/Ref720S.json and .md.

	Every value is tagged:
	  [F] factory figure (McLaren 2017 launch press release, 2021 brochure "Technical Highlights")
	  [P] published third-party figure (spec sheets, US OEM data feeds, Wikipedia, evo)
	  [M] measured in a magazine or independent test
	  [E] estimate made for the simulation (method given here or in the doc)
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.

	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	What the simulation can't represent, and how it is approximated (details in the doc):
	  * the real rev limit is 8,100 rpm in 1st and 2nd and 8,200 rpm above; the game has one limiter,
	    so it uses 8,200 (full-throttle automatic upshifts come at 8,050, below both);
	  * the rear differential is open and McLaren's Brake Steer brakes the spinning rear wheel; this
	    is approximated with a no-preload, power-only limited slip (drivetrain);
	  * the active rear wing (Driver Downforce, DRS and airbrake modes) is one fixed drag area and
	    one fixed downforce area per axle (aero);
	  * Proactive Chassis Control II has no anti-roll bars; its hydraulic roll stiffness is given as
	    anti-roll rates (suspension).
]]

return {
	id = "Ref720S",
	displayName = "Ashcombe AR-7",
	reference = "McLaren 720S (engineering reference only)",

	mass = {
		dryKg = 1322, -- [F] dry, base car (1,283 kg with the lightest options [F])
		kerbKg = 1419, -- [F] DIN kerb weight: fluids and 90% fuel (US curb 1,424 kg with a full tank [F])
		driverKg = 75, -- [A] the simulation carries one driver: 1,494 kg simulated
		frontShare = 0.41, -- [F] 41% front / 59% rear, coupe (Autocar weighed 42/58, AMS 41.5/58.5 [M])
		comHeight = 0.42, -- [E] not published; carbon tub, dry-sump V8 low behind the seats ("3% lower than the 650S" [F])
		-- [E] Box that carries the mass, sized for about 2,150 kg*m^2 in yaw, 460 in roll and 1,770 in
		-- pitch: a dynamic index k^2/(a*b) of about 0.85, typical of a compact mid-engined car (the mass
		-- sits between the axles, so the polar moment is lower than a front-engined GT's).
		inertiaBox = { width = 1.80, height = 0.70, length = 3.75 },
	},

	dimensions = {
		length = 4.543, -- [F]
		width = 1.930, -- [P] body without mirrors (motor1.de, CarExpert); 2,161 mm with mirrors [F]
		height = 1.196, -- [F]
		wheelbase = 2.670, -- [F]
		trackFront = 1.674, -- [F] contact-patch centres
		trackRear = 1.629, -- [F]
		frontOverhang = 1.058, -- [F] (1,058 + 2,670 + 816 mm rear overhang = 4,544 mm)
	},

	engine = {
		layout = "90-degree V8, flat-plane crank, twin-turbo, dry sump (M840T)", -- [F] code and turbos; [P] crank, bank angle
		displacementCc = 3994, -- [F] bore 93.0 mm, stroke 73.5 mm [P]
		aspiration = "Turbo", -- [F] two twin-scroll turbochargers, one per bank
		peakPowerKw = 530, -- [F] 720 PS
		peakPowerRpm = 7500, -- [F] 2017 press release (the 2021 coupe sheet prints 7,250 rpm)
		peakTorqueNm = 770, -- [F]
		peakTorqueRpm = 5500, -- [F]
		idleRpm = 800, -- [E] not published
		-- [F] max revs are 8,100 rpm in 1st and 2nd and 8,200 rpm in 3rd to 7th. One limiter per car in
		-- this simulation, so 8,200.
		limiterRpm = 8200,
		limiterHysteresisRpm = 150, -- [E] research: an ignition cut with about 100-150 rpm of bounce
		-- [E] kg*m^2: crank, flywheel and the dual-clutch's input side. "Stiffer, lighter crankshaft",
		-- lighter pistons and rods [F]: under the GT12's V12 (0.20). (0.13 was tried: 0.02 s quicker.)
		inertia = 0.15,
		-- Full-BOOST torque curve, {rpm, Nm} (docs/VEHICLE_CONFIG.md, "Turbo and supercharger torque
		-- curves"). With forcedInduction below, the steady full-throttle curve the game produces passes
		-- exactly through the research curve at every point listed: an estimate [E] shaped through
		-- McLaren's two figures, 770 Nm at 5,500 rpm and 530 kW at 7,500 rpm (675 Nm) [F]. Below
		-- 5,000 rpm each value is research / (0.39 + 0.61 x boost ceiling); the mid-range bulge (up to
		-- 863 Nm) is torque the calibration holds back by ramping boost through the mid-range (evo: "a
		-- real build-up of boost through the mid-range"; tuners gain most near 3,700 rpm).
		torqueCurve = {
			{ 800, 667 }, -- [E] x 0.390 = 260 Nm (no boost)
			{ 1000, 769 }, -- [E] x 0.390 = 300 Nm (no boost: sets offBoostTorqueShare)
			{ 1500, 772 }, -- [E] x 0.466 = 360 Nm
			{ 2000, 793 }, -- [E] x 0.543 = 430 Nm
			{ 2500, 840 }, -- [E] x 0.619 = 520 Nm
			{ 3000, 863 }, -- [E] x 0.695 = 600 Nm
			{ 3500, 862 }, -- [E] x 0.771 = 665 Nm
			{ 4000, 838 }, -- [E] x 0.848 = 710 Nm
			{ 4500, 803 }, -- [E] x 0.924 = 742 Nm
			{ 5000, 762 }, -- [E] full boost from here: steady = curve
			{ 5500, 770 }, -- [F] peak torque
			{ 6000, 763 }, -- [E]
			{ 6500, 746 }, -- [E]
			{ 7000, 713 }, -- [E]
			{ 7500, 675 }, -- [F] 530 kW peak power
			{ 8000, 628 }, -- [E]
			{ 8200, 605 }, -- [E] at the limiter (520 kW)
		},
		-- [E] Engine braking with the throttle shut: static + perRpm * rpm (Nm), about 24 Nm at 800 rpm
		-- and 90 Nm at 8,000 rpm (friction mean effective pressure of about 2.8 bar at 8,000 rpm on 4.0 L).
		friction = { static = 17, perRpm = 0.0091 },
		throttleResponse = 18, -- [E] 1/s, drive-by-wire throttle; the lag is in the turbos
		forcedInduction = {
			type = "Turbo", -- [F] two twin-scroll, low-inertia turbos (titanium-aluminide turbines)
			maxBoostBar = 1.3, -- [P] "over 1.3 bar" (Wikipedia, uncited); gauge and sound only
			-- [E] 300 Nm at 1,000 rpm with no boost / 770 Nm (the research curve at 1,000 rpm against the
			-- peak); 1 / (1 + 1.3 bar) = 0.43 by pressure ratio agrees roughly
			offBoostTorqueShare = 0.39,
			-- [E] The research curve is already 430 Nm (56% of peak) at 2,000 rpm, well above the ~300 Nm
			-- the engine makes with no boost, so in this model boost starts building above 1,000 rpm; the
			-- research's "boost onset about 2,000 rpm" is where the build becomes strong.
			boostStartRpm = 1000,
			fullBoostRpm = 5000, -- [E] research: full boost about 5,000 rpm, torque peak at 5,500
			-- [E] "Ultra-low-inertia" twin-scroll turbos [F]: the quick end of the 0.8-1.0 s starting range.
			-- Floored at 3,800 rpm in 3rd, 90% boost comes after about 1.3 s; at 6,600 rpm, 0.7 s.
			spoolTime = 0.8,
			dumpTime = 0.15, -- [E] electronically controlled dump valve [F] releases boost quickly
		},
	},

	transmission = {
		type = "DualClutch", -- [F] 7-speed Seamless Shift Gearbox (SSG), dual-clutch (Graziano [P])
		gearRatios = { 3.98, 2.61, 1.91, 1.48, 1.16, 0.91, 0.69 }, -- [P] US OEM data (carspecs.us, Motor Matchup)
		reverseRatio = 2.80, -- [P]
		finalDrive = 3.30, -- [P] (the 750S's is 15% shorter [P])
		efficiency = 0.92, -- [E] typical for a dual-clutch gearbox and final drive
		shiftTime = 0.05, -- [E] not published; ignition-cut shifts [F]
		-- [E] Share of clutch capacity kept during a shift. A seamless dual-clutch with ignition-cut
		-- upshifts pulls the engine down to the new gear's speed; it doesn't let it flare. At the GT12's
		-- 0.35 (400 Nm against this engine's 620-770 Nm) every full-throttle upshift flared about
		-- 300 rpm into the limiter, and the cut dumped half the boost (an artefact for a turbo engine).
		-- At 0.6 (690 Nm) the clutch holds the engine and boost is kept through the shift.
		shiftTorqueFraction = 0.6,
		clutchMaxTorque = 1150, -- [E] Nm, about 1.5 x peak torque
		clutchStiffness = 400, -- [E] Nm per rad/s of slip
		-- [E] engine speed the launch clutch holds, by pedal. Launch control [F]; its rpm isn't published
		-- (research: about 3,500, likely 3,000-4,000).
		launchRpm = { min = 2200, max = 3500 },
		-- [E] Full-throttle upshifts at 8,100 rpm: the real 1st-2nd limit, 100 rpm under the 8,200 limiter.
		-- 7th is an overdrive: the car tops out in 6th at about 7,970 rpm (research: 341 km/h at the end of
		-- 6th), so 8,100 leaves a margin against an upshift into 7th, where it would top out near 331 km/h.
		autoUpshiftRpm = { light = 3500, full = 8100 },
		autoDownshiftRpm = { light = 1500, full = 4900 }, -- [E]
		minShiftInterval = 0.25, -- [E] seconds between shifts
	},

	drivetrain = {
		layout = "RWD", -- [F]
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] The real car has an OPEN rear differential [P, evo]; McLaren's Brake Steer brakes the
		-- spinning or inside rear wheel to give a limited-slip effect [F]. The simulation has no brake-
		-- based torque vectoring, so the nearest honest stand-in is a clutch-type limited slip with no
		-- preload and no coast locking (Brake Steer acts only when a wheel spins under power) and a
		-- modest power lock. Unlike Brake Steer it wastes no energy as brake heat, and it can't add yaw
		-- on turn-in by braking the inside rear wheel as Brake Steer does.
		rearDifferential = { type = "LimitedSlip", preload = 0, powerLock = 0.25, coastLock = 0, stiffness = 150 },
		frontDifferential = { type = "Open" }, -- undriven
		-- [E] Traction control (ESC with Variable Drift Control [F]; launch control [F]). It caps engine
		-- and clutch torque at headroom times what the driven tyres can grip, and trims further while they
		-- slip more than targetSlip. rate and recovery are how fast that trim builds and fades (per second).
		-- headroom 1.3 tested best of 1.15-1.5 (the cap must also cover spinning up the engine and wheels
		-- in 1st). recovery 8 (the GT12 uses 2): the trim fades in about 0.12 s, like a modern launch and
		-- traction system; at 2 a single wheelspin spike at launch held the car back for half a second and
		-- 0-100 km/h swung between 3.0 and 3.3 s with small changes to grip or launch rpm.
		tractionControl = { enabled = true, targetSlip = 0.11, rate = 15, recovery = 8, headroom = 1.3 },
	},

	-- [E] Proactive Chassis Control II: adaptive dampers hydraulically interlinked at each corner and NO
	-- anti-roll bars [F]. Springs from ride frequencies of 1.6 Hz front and 1.8 Hz rear (research) with
	-- the game's whole corner mass on the springs (306 kg front, 441 kg rear); damping ratios of about
	-- 0.3 in bump and 0.5 in rebound; the anti-roll rates stand in for PCC II's hydraulic roll
	-- stiffness (research: about 25,000 and 18,000 N/m), about 1.2 degrees of roll per g.
	suspension = {
		front = {
			springRate = 31000, -- N/m at the wheel
			bumpDamping = 1850, -- N*s/m
			reboundDamping = 3100, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.08, -- from ride height
			droopTravel = 0.07, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 25000, -- N/m of left-right travel difference
			rollCenterHeight = 0.06, -- aluminium double wishbones [F]
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 56400,
			bumpDamping = 3000,
			reboundDamping = 5000,
			staticLength = 0.25,
			bumpTravel = 0.08,
			droopTravel = 0.07,
			bumpStopRate = 250000,
			antiRollRate = 18000,
			rollCenterHeight = 0.09, -- double wishbones [F]
			rideHeightOffset = 0,
		},
	},

	tires = {
		-- [E] The car's own compounds (engineering references only). AR7Road is the standard tyre, a
		-- McLaren-specific Pirelli P Zero in the real car [F/P]: a road performance tyre, with its
		-- braking/driving grip set to 1.42 so the launch matches McLaren's 0-100 km/h (1.40-1.45 tested).
		-- AR7Track is the optional P Zero Corsa class [F], which McLaren says gives "six percent more
		-- mechanical grip" than the 650S had: about 6% more grip here. Not fitted by default.
		compounds = {
			AR7Road = { base = "Performance", muLong = 1.42, muLat = 1.22 },
			AR7Track = { base = "Performance", muLong = 1.54, muLat = 1.29, peakSlipRatio = 0.095, peakSlipAngle = 7.0, relaxationLength = 0.22 },
		},
		front = { widthMm = 245, aspect = 35, rimInches = 19, compound = "AR7Road", inertia = 1.35 }, -- [F] 245/35 ZR19 on 19 x 9.0J forged; [E] inertia (kg*m^2)
		rear = { widthMm = 305, aspect = 30, rimInches = 20, compound = "AR7Road", inertia = 1.75 }, -- [F] 305/30 ZR20 on 20 x 11.0J forged; [E] inertia
	},

	brakes = {
		discs = "Carbon-ceramic, 390 mm front with 6-piston calipers, 380 mm rear with 4-piston calipers", -- [F]
		maxTorqueFront = 2800, -- [E] Nm per wheel, enough to lock the fronts at about 1.4 g (research)
		maxTorqueRear = 1800, -- [E] Nm per wheel (about 61% front)
		handbrakeTorque = 2200, -- [E] Nm per rear wheel
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		-- [E] CdA in m^2. McLaren publishes no Cd. Fitted so the car tops out at the factory 341 km/h in
		-- 6th, below the upshift point (7th is an overdrive), on the factory power: 341.4 km/h at
		-- 7,970 rpm. It lumps in the partly deployed rear wing and cooling drag (Cd about 0.47 on an
		-- estimated 1.85 m^2). The research's 0.85-0.91 used a 0.335 m rolling radius; the game uses the
		-- unloaded radius from the tyre size.
		dragArea = 0.875,
		-- [E] ClA in m^2. McLaren gives downforce only relative to the 650S: about 50% more [F]. The 675LT
		-- has 40% more than the 650S and the 675LT-based MSO HS makes 220 kg at 241 km/h [P], so the
		-- 650S makes at most about 157 kg there and the 720S at most about 235 kg (ClA 0.84). Taken as
		-- about 195 kg at 241 km/h (ClA 0.70), 36% on the front axle like the research's split.
		downforceAreaFront = 0.25,
		downforceAreaRear = 0.45,
	},

	steering = {
		maxAngleLowSpeed = 30, -- [E] mean road-wheel lock from the 12.4 m turning circle [F] (inner 34, outer 25.5)
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above
		highSpeedKmh = 250, -- [E]
		rate = 220, -- [E] degrees per second the road wheels can turn (2.46 turns lock to lock [F])
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made from the car's acoustic definition,
	-- assets/audio/engines/Ref720S.json (firing order 1-8-3-6-4-5-2-7, flat-plane crank, each bank into
	-- its own twin-scroll turbo, then catalysts and one silencer to two high centre tailpipes), by
	-- tools/synth_audio.py; see docs/AUDIO.md. Its per-loop gains follow the car's measured cabin level
	-- (Car and Driver: 95 dBA at full throttle [M]); engineVolume scales all of it. The rev limiter is
	-- heard through the sheet's baked limiter loops (ignition cut, 8,200 rpm). Tune by ear in testing.
	audio = {
		engineSheet = "Ref720S_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3,
		rpmCurve = 1.0,
		redlineRpm = 8200, -- [F] 3rd-7th (8,100 in 1st-2nd)
		offThrottleLevel = 0.55,
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the cut keeps coming back
		limiterHold = 0.3, -- s after the last cut (the simulation cuts about 4.5 times a second)
		limiterAttack = 40, -- 1/s, about 25 ms
		limiterRelease = 10,
		-- [E] Turbo whistle at full boost: louder than the GT12's default, for evo's "rushing whoosh of
		-- the turbochargers" and Autocar's "whoosh and fizz". Rises with boost (shaft speed).
		turboVolume = 0.42,
		-- [A] Lift-off flutter (the sheet's blow-off one-shots are the "flutter" kind): wastegate and
		-- dump-valve chatter when the throttle shuts on boost. Not described by the sources read.
		blowOffVolume = 0.5,
		blowOffMinBoost = 0.4, -- boost (0-1) needed for the flutter when the throttle shuts
		superchargerVolume = 0, -- no supercharger
		-- [E] Ignition-cut upshifts [F]: a short crack on full-throttle upshifts, as long as the shift.
		shiftCutTime = 0.05,
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.6,
		shiftClunkVolume = 0.2,
		-- [A] Overrun crackle: light, the stock car is described as muted (research: light crackle in
		-- Sport and Track, little in Comfort; crackles from about 4,000 rpm).
		crackleMinRpm = 4000,
		crackleDuration = 0.8,
		crackleRate = 8,
		crackleVolume = 0.3,
		bumpMinSpeed = 0.6, -- m/s into the bump stops before a knock is heard
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2,
		squealRange = 1.5,
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.05,
		whineTeeth = 10, -- [E] final drive pinion teeth (10:33 gives the 3.30 final drive [P]); sets the whine pitch
		-- [E] cockpit camera: the engine and its intake plenum sit right behind the cabin's rear glass,
		-- so more engine and less treble cut than the front-engined GT12
		interior = { engine = 0.9, wind = 0.4, road = 1.2, squeal = 0.7, lowGain = 3, midGain = 0, highGain = -9 },
	},

	performanceTargets = {
		zeroTo60Mph = 2.8, -- [F] McLaren (taken as from a standstill [A])
		zeroTo60MphRollout = 2.7, -- [M] Car and Driver and Road & Track, 2018 coupe, 1-ft rollout (Motor Trend 2.5 s)
		zeroTo100 = 2.9, -- [F] McLaren (AMS 2.8 s, Motoring SA 2.85 s [M])
		zeroTo100Mph = 5.6, -- [M] Autocar 2017, two people and a full tank (C/D Spider 5.5 s, DragTimes 5.2 s)
		zeroTo200 = 7.8, -- [F] McLaren (AMS 7.4 s, Autozeitung 7.1 s [M])
		quarterMile = 10.3, -- [F] McLaren (C/D 10.2 s, MT 10.1 s, R&T 9.9 s with rollout; Autocar 10.4 s [M])
		quarterMileKmh = 233.4, -- [M] Car and Driver 2018: 145 mph (MT 141.5 mph, R&T 148.2 mph)
		topSpeedKmh = 341, -- [F] 212 mph
		brake100To0 = 30, -- [F] McLaren (AMS 33.2 m from cold [M])
		brake70MphTo0 = 39.9, -- [M] Autocar 2017 (C/D 2019 Spider: 141 ft = 43.0 m)
	},

	visual = {
		bodyColor = Color3.fromRGB(230, 90, 20), -- [A] approximation of Azores, an orange launch colour
		driverSide = "Left", -- [A] left-hand drive (EU and US cars; right-hand drive was also built)
		-- [E] Side profile judged from near-profile photos (research, about +/-0.03 of length), placed on
		-- the published axles (0.233 and 0.821 of the length [F]). Highest point = published height.
		-- Cab forward: the windscreen starts just behind the front wheels and the roof peaks over the
		-- seats; the glass canopy sweeps down into a low engine cover ("the rear 145 mm lower than the
		-- 650S's" [F]), ending in a short tail with the wing as its trailing edge.
		blockout = {
			profile = {
				{ 0.000, 0.46 }, -- nose
				{ 0.030, 0.56 },
				{ 0.120, 0.63 },
				{ 0.233, 0.69 }, -- front axle: wing crowns
				{ 0.310, 0.84 }, -- windscreen base
				{ 0.400, 1.12 },
				{ 0.470, 1.185 },
				{ 0.520, 1.196 }, -- roof peak, over the seats: published height [F]
				{ 0.600, 1.15 },
				{ 0.700, 1.00 }, -- the glass canopy ends on the engine cover
				{ 0.821, 0.95 }, -- rear axle
				{ 0.940, 0.93 },
				{ 0.975, 0.98 }, -- wing lip
				{ 1.000, 0.92 },
			},
			greenhouse = { 0.31, 0.70 },
			-- The builder draws the lower body as one box up to the beltline, so the beltline is also the
			-- height of the nose and tail. The real window line is about 0.80 m (research); 0.62 keeps the
			-- nose low like the real car's (0.5-0.7 m), at the cost of side glass that looks taller.
			beltline = 0.62,
			cabinWidth = 0.68, -- narrow teardrop canopy on a 1.93 m body
			sill = 0.107, -- [F] ground clearance 107 mm
		},
	},
}
