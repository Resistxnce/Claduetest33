--[[
	Valenza GT12 prototype (internal ID: Prototype812)

	An original car built on the publicly documented engineering of the Ferrari 812 Superfast.
	No Ferrari names, logos or designs are used in the game. See docs/PROTOTYPE_GT12.md for
	sources and for how each estimate was made.

	Every value is tagged:
	  [F] factory figure published by Ferrari
	  [P] published figure from third-party spec sheets
	  [E] estimate made for the simulation
	  [A] assumption
	Units: metres, kilograms, newtons, seconds and rpm unless a name says otherwise.

	Positions use the car's own axes: X to the right, Y up, -Z forward (Roblox LookVector).

	docs/VEHICLE_CONFIG.md describes every field, including the optional ones this naturally aspirated,
	dual-clutch, rear-drive car doesn't use (forcedInduction, the automatic's converter and lock-up,
	drivetrain.centreCoupling, tires.compounds, engine.speedLimitKmh).
]]

return {
	id = "Prototype812",
	displayName = "Valenza GT12",
	reference = "Ferrari 812 Superfast (engineering reference only)",

	mass = {
		dryKg = 1525, -- [F]
		kerbKg = 1630, -- [F] DIN kerb weight
		driverKg = 75, -- [A] the simulation carries one driver
		frontShare = 0.47, -- [F] 47% front / 53% rear
		comHeight = 0.45, -- [E] centre of mass above the ground at ride height
		-- [E] Size of the invisible box that carries the car's mass. It sets the rotational
		-- inertia (about 2,600 kg*m^2 in yaw), so it should roughly match where the mass sits.
		inertiaBox = { width = 1.80, height = 0.80, length = 4.00 },
	},

	dimensions = {
		length = 4.657, -- [P]
		width = 1.971, -- [P]
		height = 1.276, -- [P]
		wheelbase = 2.720, -- [P]
		trackFront = 1.672, -- [P]
		trackRear = 1.645, -- [P]
		frontOverhang = 1.000, -- [E] front axle to the nose
	},

	engine = {
		layout = "65-degree V12", -- [F]
		displacementCc = 6496, -- [F]
		aspiration = "NaturallyAspirated", -- [F]
		peakPowerKw = 588, -- [F] 800 CV
		peakPowerRpm = 8500, -- [F]
		peakTorqueNm = 718, -- [F]
		peakTorqueRpm = 7000, -- [F]
		idleRpm = 1000, -- [E]
		limiterRpm = 8900, -- [P] max revs on the 812 GTS spec sheet (same engine)
		limiterHysteresisRpm = 150, -- [E]
		inertia = 0.20, -- [E] kg*m^2 for crank, flywheel and clutch
		-- [E] Full-throttle torque curve, {rpm, Nm}. Anchored to the factory figures:
		-- 718 Nm at 7,000 rpm, 661 Nm at 8,500 rpm (= 588 kW), and Ferrari's claim of
		-- 80% of peak torque available at 3,500 rpm.
		torqueCurve = {
			{ 1000, 330 },
			{ 2000, 450 },
			{ 3000, 540 },
			{ 3500, 574 },
			{ 4500, 620 },
			{ 5500, 665 },
			{ 6500, 705 },
			{ 7000, 718 },
			{ 7500, 712 },
			{ 8000, 690 },
			{ 8500, 661 },
			{ 8900, 625 },
		},
		-- [E] Internal friction, felt as engine braking with the throttle closed: static + perRpm * rpm (Nm).
		-- The torque curve above is net output, so friction isn't subtracted at full throttle.
		friction = { static = 20, perRpm = 0.0085 },
		throttleResponse = 18, -- [E] 1/s, how quickly the throttle follows the pedal
	},

	transmission = {
		type = "DualClutch", -- [F] 7-speed dual-clutch
		-- [E] Ratios fitted so the model reaches the factory 0-100, 0-200 and top speed figures.
		gearRatios = { 2.980, 2.436, 1.992, 1.629, 1.331, 1.089, 0.890 },
		reverseRatio = 2.80, -- [E]
		finalDrive = 4.00, -- [E]
		efficiency = 0.92, -- [E] typical for a dual-clutch gearbox and final drive
		shiftTime = 0.06, -- [E] seconds of reduced torque during a shift
		shiftTorqueFraction = 0.35, -- [E] share of clutch capacity kept during a shift
		clutchMaxTorque = 1100, -- [E] Nm
		clutchStiffness = 400, -- [E] Nm per rad/s of slip, how firmly an engaged clutch couples
		launchRpm = { min = 2200, max = 4500 }, -- [E] engine speed the launch clutch holds, by pedal
		autoUpshiftRpm = { light = 6200, full = 8750 }, -- [E] by pedal position
		autoDownshiftRpm = { light = 2600, full = 5200 }, -- [E] by pedal position
		minShiftInterval = 0.25, -- [E] seconds between shifts
	},

	drivetrain = {
		layout = "RWD", -- [F]
		frontTorqueShare = 0, -- used by AWD layouts (0 to 1)
		-- [E] The real car has an electronic limited-slip differential; this is a clutch-type
		-- approximation: preload in Nm, lock factors as shares of input torque.
		rearDifferential = { type = "LimitedSlip", preload = 120, powerLock = 0.35, coastLock = 0.20, stiffness = 180 },
		frontDifferential = { type = "Open" },
		-- [E] Traction control (the real car has one). It caps engine and clutch torque at headroom
		-- times what the driven tyres can grip, and trims further while they slip more than
		-- targetSlip. rate and recovery are how fast that trim builds and fades (per second).
		tractionControl = { enabled = true, targetSlip = 0.11, rate = 15, recovery = 2, headroom = 1.3 },
	},

	-- [E] Springs and dampers are estimated from target ride frequencies of 1.8 Hz front and
	-- 2.0 Hz rear with damping ratios of about 0.3 in bump and 0.5 in rebound.
	suspension = {
		front = {
			springRate = 51000, -- N/m at the wheel
			bumpDamping = 2700, -- N*s/m
			reboundDamping = 4500, -- N*s/m
			staticLength = 0.25, -- mount to wheel centre at ride height
			bumpTravel = 0.08, -- from ride height
			droopTravel = 0.07, -- from ride height
			bumpStopRate = 250000, -- N/m
			antiRollRate = 32000, -- N/m of left-right travel difference
			rollCenterHeight = 0.06, -- lateral tyre force acts this high above the road
			rideHeightOffset = 0, -- positive raises the car
		},
		rear = {
			springRate = 71000,
			bumpDamping = 3400,
			reboundDamping = 5700,
			staticLength = 0.25,
			bumpTravel = 0.08,
			droopTravel = 0.07,
			bumpStopRate = 250000,
			antiRollRate = 20000,
			rollCenterHeight = 0.10,
			rideHeightOffset = 0,
		},
	},

	tires = {
		front = { widthMm = 275, aspect = 35, rimInches = 20, compound = "Performance", inertia = 1.6 }, -- [P] size, [E] inertia (kg*m^2)
		rear = { widthMm = 315, aspect = 35, rimInches = 20, compound = "Performance", inertia = 2.0 }, -- [P] size, [E] inertia (kg*m^2)
	},

	brakes = {
		discs = "Carbon-ceramic, 398 mm front, 360 mm rear", -- [P]
		maxTorqueFront = 3800, -- [E] Nm per wheel
		maxTorqueRear = 2000, -- [E] Nm per wheel
		handbrakeTorque = 2500, -- [E] Nm per rear wheel
		abs = { enabled = true, targetSlip = 0.12 }, -- [E]
	},

	aero = {
		dragArea = 0.70, -- [E] CdA in m^2, fitted so the car tops out near 340 km/h on its gearing
		downforceAreaFront = 0.18, -- [E] ClA in m^2
		downforceAreaRear = 0.27, -- [E] ClA in m^2
	},

	steering = {
		maxAngleLowSpeed = 30, -- [E] road-wheel degrees when slow
		maxAngleHighSpeed = 4.5, -- [E] road-wheel degrees at highSpeedKmh and above
		highSpeedKmh = 250, -- [E]
		rate = 220, -- [E] degrees per second the road wheels can turn
		ackermann = 0.6, -- [E] 0 = parallel steering, 1 = full Ackermann
	},

	-- [E] Sound. The engine sheet is made from the car's acoustic definition,
	-- assets/audio/engines/Prototype812.json, by tools/synth_audio.py; sheets are regions of packed
	-- sound files (VehicleAudio/Sheets, see docs/AUDIO.md). Volumes are Roblox Sound volumes. The
	-- engine's loudness curve over rpm and load comes from the sheet's per-loop gains (from the
	-- real car's measured sound levels); engineVolume scales all of it. Tuned by ear in testing.
	audio = {
		engineSheet = "GT12_Engine",
		effectsSheet = "Driving_Effects",
		engineVolume = 1.0, -- overall engine level (1 = the sheet's calibrated gains)
		-- used only with a sheet that has no per-loop gains:
		idleLevel = 0.3, -- loudness at idle as a share of engineVolume
		rpmCurve = 1.0, -- how loudness rises with rpm (1 = in proportion)
		redlineRpm = 8900,
		offThrottleLevel = 0.55, -- off-throttle loops relative to on-throttle
		loadAttack = 25, -- 1/s, how fast the mix follows the throttle opening
		loadRelease = 12, -- 1/s, and closing
		minPitch = 0.5,
		maxPitch = 2.0,
		-- rev limiter: the limiter loops take over while the fuel cut keeps coming back
		limiterHold = 0.3, -- s after the last cut before the normal loops return (cuts come about 4 times a second)
		limiterAttack = 40, -- 1/s, how fast the limiter loops come in (about 25 ms)
		limiterRelease = 10, -- 1/s, and go out
		-- forced induction (only used by turbo or supercharged engine sheets)
		turboVolume = 0.35, -- whistle at full boost
		blowOffVolume = 0.6,
		blowOffMinBoost = 0.35, -- boost (0-1) needed for a blow-off when the throttle shuts
		superchargerVolume = 0.3, -- whine at full boost
		shiftCutTime = 0.08, -- seconds of ignition cut heard on a full-throttle upshift
		shiftCutMinRpm = 4500,
		shiftCutVolume = 0.6,
		shiftClunkVolume = 0.25,
		crackleMinRpm = 4000, -- exhaust crackles after lifting off above this
		crackleDuration = 1.2,
		crackleRate = 14, -- crackles per second at first, fading out
		crackleVolume = 0.5,
		bumpMinSpeed = 0.6, -- m/s into the bump stops before a knock is heard
		bumpVolume = 0.5,
		squealVolume = 0.5,
		squealStart = 1.2, -- tyres start to squeal past this multiple of their peak slip
		squealRange = 1.5, -- and reach full volume this much further past it
		roadVolume = 0.35,
		windVolume = 0.5,
		whineVolume = 0.06,
		whineTeeth = 31, -- final drive pinion teeth, sets the gearbox whine pitch
		-- cockpit camera: level changes and an equaliser (dB) for the cabin
		interior = { engine = 0.8, wind = 0.45, road = 1.25, squeal = 0.7, lowGain = 3, midGain = -2, highGain = -12 },
	},

	-- [F] Factory figures the telemetry timer compares against.
	performanceTargets = { zeroTo100 = 2.9, zeroTo200 = 7.9, topSpeedKmh = 340 },

	visual = {
		bodyColor = Color3.fromRGB(150, 12, 18),
		driverSide = "Left", -- [F] left-hand drive
	},
}
