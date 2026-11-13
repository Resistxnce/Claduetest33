--[[
	Transmission
	Gear selection, automatic and manual modes, shift timing and the coupling between engine and
	gearbox. Gear numbers: -1 reverse, 0 neutral, 1 and up forward (up to 10). Two kinds (spec.type):

	DualClutch  The clutch is a stiff, torque-limited coupling solved implicitly (see
	            Transmission.clutchTorque), which stays stable even though the wheel side has very
	            little inertia once it is reflected through a low gear. It slips to launch the car
	            and runs at reduced capacity for shiftTime during a shift.
	Automatic   A torque converter with a lock-up clutch (Transmission.converter and
	            Transmission.automaticTorque). The converter slips and multiplies torque at low
	            speed, which gives the launch and idle creep. The lock-up clutch closes above a set
	            speed in the higher gears. In a shift, the gearbox's own shift clutches carry the
	            gearbox input from the old gear's speed to the new gear's over shiftTime while the
	            engine's torque is cut back, the way modern 8- and 10-speed automatics shift.
]]

local Units = require(script.Parent.Parent.Units)

local Transmission = {}

local DEFAULT_TURBINE_INERTIA = 0.05 -- kg*m^2, converter turbine and gearbox input
local DEFAULT_LOCKUP_STIFFNESS = 400 -- Nm per rad/s of slip, as for the dual-clutch's clutch
local AUTO_SHIFT_MARGIN_RPM = 250 -- automatic: keeps a new gear clear of the next shift point

function Transmission.new(spec)
	return {
		spec = spec,
		gear = 1,
		auto = true,
		shiftTimer = 0, -- seconds left in the current shift
		sinceShift = 10, -- seconds since the last shift
		automatic = spec.type == "Automatic",
		fromGear = 1, -- the gear the last shift left
		-- automatic gearboxes only
		shiftDuration = 0, -- length of the current shift's speed change (s)
		shiftElapsed = 0, -- time into it (s)
		lockup = 0, -- lock-up clutch engagement, 0 to 1
		converterK = 0, -- converter capacity factor, Nm per (rad/s)^2 (VehicleSimulation sets it)
		turbineInertia = spec.turbineInertia or DEFAULT_TURBINE_INERTIA,
	}
end

-- Overall ratio from engine to wheels in a given gear, negative in reverse, 0 in neutral.
function Transmission.gearRatio(tr, gear: number): number
	local spec = tr.spec
	if gear == 0 then
		return 0
	elseif gear < 0 then
		return -spec.reverseRatio * spec.finalDrive
	end
	return spec.gearRatios[gear] * spec.finalDrive
end

-- Overall ratio in the current gear.
function Transmission.ratio(tr): number
	return Transmission.gearRatio(tr, tr.gear)
end

function Transmission.gearCount(tr): number
	return #tr.spec.gearRatios
end

-- Request a gear. Returns true if the shift started.
function Transmission.shift(tr, newGear: number): boolean
	local spec = tr.spec
	newGear = math.clamp(newGear, -1, #spec.gearRatios)
	if newGear == tr.gear or tr.sinceShift < spec.minShiftInterval then
		return false
	end
	if tr.automatic and tr.shiftElapsed < tr.shiftDuration then
		return false -- an automatic finishes one shift before it starts the next
	end
	tr.fromGear = tr.gear
	tr.gear = newGear
	tr.shiftTimer = spec.shiftTime
	tr.sinceShift = 0
	if tr.automatic then
		-- only a change between forward gears needs the shift clutches to change the input speed
		local time = if newGear < tr.fromGear then spec.downshiftTime or spec.shiftTime else spec.shiftTime
		tr.shiftDuration = if newGear >= 1 and tr.fromGear >= 1 then time else 0
		tr.shiftElapsed = 0
		tr.shiftTimer = tr.shiftDuration
	end
	return true
end

function Transmission.isShifting(tr): boolean
	if tr.automatic then
		return tr.shiftElapsed < tr.shiftDuration
	end
	return tr.shiftTimer > 0
end

-- Automatic gearboxes: 1 during an upshift, -1 during a downshift, 0 otherwise.
function Transmission.shiftDirection(tr): number
	if not tr.automatic or tr.shiftElapsed >= tr.shiftDuration then
		return 0
	end
	return if tr.gear > tr.fromGear then 1 else -1
end

-- Automatic gearboxes: move the current shift on by one simulation step.
function Transmission.advanceShift(tr, dt: number)
	if tr.shiftElapsed < tr.shiftDuration then
		tr.shiftElapsed = math.min(tr.shiftElapsed + dt, tr.shiftDuration)
	end
end

--[[
	Automatic gearboxes: one gear up past the upshift point. Below the downshift point, down to the
	highest gear that lifts the engine clear of the downshift point, skipping gears if needed (a
	kickdown), but never into a gear that would put the engine within AUTO_SHIFT_MARGIN_RPM of the
	upshift point, so it can't hunt between gears whatever their number and spacing.
]]
local function chooseAutomaticGear(tr, inputRpm: number, up: number, down: number)
	local ratios = tr.spec.gearRatios
	if inputRpm > up then
		if tr.gear < #ratios then
			Transmission.shift(tr, tr.gear + 1)
		end
		return
	end
	if inputRpm >= down then
		return
	end
	local target = tr.gear
	for gear = tr.gear - 1, 1, -1 do
		local rpm = inputRpm * ratios[gear] / ratios[tr.gear]
		if rpm > up - AUTO_SHIFT_MARGIN_RPM then
			break
		end
		target = gear
		if rpm >= down + AUTO_SHIFT_MARGIN_RPM then
			break
		end
	end
	if target ~= tr.gear then
		Transmission.shift(tr, target)
	end
end

-- Automatic gear choice. inputRpm: gearbox input speed implied by the wheels. pedal: 0 to 1.
function Transmission.updateAuto(tr, dt: number, inputRpm: number, pedal: number)
	tr.sinceShift += dt
	tr.shiftTimer = math.max(0, tr.shiftTimer - dt)
	if not tr.auto or tr.gear <= 0 then
		return
	end
	local spec = tr.spec
	local up = spec.autoUpshiftRpm.light + (spec.autoUpshiftRpm.full - spec.autoUpshiftRpm.light) * pedal
	local down = spec.autoDownshiftRpm.light + (spec.autoDownshiftRpm.full - spec.autoDownshiftRpm.light) * pedal
	if tr.automatic then
		chooseAutomaticGear(tr, inputRpm, up, down)
	elseif inputRpm > up and tr.gear < #spec.gearRatios then
		Transmission.shift(tr, tr.gear + 1)
	elseif inputRpm < down and tr.gear > 1 then
		-- don't drop into a gear that would over-rev the engine
		local lowerRpm = inputRpm * spec.gearRatios[tr.gear - 1] / spec.gearRatios[tr.gear]
		if lowerRpm < spec.autoUpshiftRpm.full - 400 then
			Transmission.shift(tr, tr.gear - 1)
		end
	end
end

--[[
	Automatic gearboxes: the lock-up clutch closes over lockup.engageTime in gear lockup.minGear and
	up once the car passes lockup.minSpeedKmh. It opens four times as fast below that speed (less
	3 km/h, so it doesn't chatter), in neutral and reverse, or if the engine is dragged toward a stall.
]]
function Transmission.updateLockup(tr, dt: number, speedKmh: number, engineRpm: number, idleRpm: number)
	local lockup = tr.spec.lockup
	local threshold = if tr.lockup > 0 then lockup.minSpeedKmh - 3 else lockup.minSpeedKmh
	local step = dt / lockup.engageTime
	if tr.gear >= lockup.minGear and speedKmh > threshold and engineRpm > idleRpm - 150 then
		tr.lockup = math.min(1, tr.lockup + step)
	else
		tr.lockup = math.max(0, tr.lockup - 4 * step)
	end
end

--[[
	Clutch engagement from 0 (open) to 1 (fully engaged).
	  engineRpm  current engine speed
	  inputRpm   gearbox input speed implied by the wheels (absolute value)
	  pedal      accelerator for the current direction of travel, 0 to 1
	  idleRpm    engine idle speed
]]
function Transmission.engagement(tr, engineRpm: number, inputRpm: number, pedal: number, idleRpm: number): number
	local spec = tr.spec
	if tr.gear == 0 then
		return 0
	end
	local engagement = 1
	if math.abs(tr.gear) == 1 and inputRpm < engineRpm - 150 then
		-- launching: the clutch bites over the last 600 rpm below the launch speed, so the engine
		-- holds close to that speed while the car pulls away
		local launchTarget = spec.launchRpm.min + (spec.launchRpm.max - spec.launchRpm.min) * pedal
		engagement = math.clamp((engineRpm - (launchTarget - 600)) / 600, 0, 1)
	end
	if engineRpm < idleRpm - 150 then
		-- anti-stall: open the clutch as the engine is dragged below idle
		engagement = math.min(engagement, math.clamp((engineRpm - 600) / (idleRpm - 750), 0, 1))
	end
	if tr.shiftTimer > 0 then
		engagement = math.min(engagement, spec.shiftTorqueFraction)
	end
	return engagement
end

--[[
	Torque passed through the clutch (Nm, from the engine to the gearbox input), solved implicitly
	so a stiff coupling stays stable at any time step, then limited to the clutch's capacity.
	  omegaEngine, omegaInput  rad/s
	  inertiaEngine, inertiaInput  kg*m^2 (wheel-side inertia reflected to the input shaft)
	  engineTorque  net engine torque (Nm)
	  loadTorque    torque the wheels push back on the input shaft (Nm)
	  capacity      clutch torque capacity now (Nm)
]]
local function couplingTorque(stiffness: number, omegaEngine: number, omegaInput: number, inertiaEngine: number, inertiaInput: number, engineTorque: number, loadTorque: number, capacity: number, dt: number): number
	local predictedSlip = (omegaEngine - omegaInput) + dt * (engineTorque / inertiaEngine + loadTorque / inertiaInput)
	local torque = stiffness * predictedSlip / (1 + stiffness * dt * (1 / inertiaEngine + 1 / inertiaInput))
	return math.clamp(torque, -capacity, capacity)
end

function Transmission.clutchTorque(tr, omegaEngine: number, omegaInput: number, inertiaEngine: number, inertiaInput: number, engineTorque: number, loadTorque: number, capacity: number, dt: number): number
	if capacity <= 0 then
		return 0
	end
	return couplingTorque(tr.spec.clutchStiffness, omegaEngine, omegaInput, inertiaEngine, inertiaInput, engineTorque, loadTorque, capacity, dt)
end

--[[
	Torque converter (automatic gearboxes): a fluid coupling between the engine (impeller) and the
	gearbox input (turbine) that multiplies torque while it slips.
	  speed ratio s = turbine speed / impeller speed
	  Below the coupling point the impeller absorbs K * impeller speed^2. K comes from the stall
	  speed: the engine speed at which the converter, with the turbine held still, absorbs the
	  engine's steady full-throttle torque.
	  Turbine torque = torque ratio * impeller torque. The ratio falls in a straight line from
	  converter.torqueRatio at s = 0 to 1 at converter.couplingPoint.
	Past the coupling point it is a plain fluid coupling whose torque falls to zero at s = 1. When the
	turbine overruns the impeller (engine braking) the turbine pumps instead, at
	converter.overrunCapacity of the forward strength.
	Returns impeller and turbine torque (Nm), then the derivatives of each with respect to the
	impeller and turbine speeds, for the implicit solve.
]]
function Transmission.converter(tr, omegaImpeller: number, omegaTurbine: number): (number, number, number, number, number, number)
	local spec = tr.spec.converter
	local k = tr.converterK
	local a, b = omegaImpeller, omegaTurbine
	local stallRatio = spec.torqueRatio
	local coupling = spec.couplingPoint
	local s = b / a
	if s <= 0 then
		local impeller = k * a * a
		return impeller, stallRatio * impeller, 2 * k * a, 0, 2 * stallRatio * k * a, 0
	elseif s < coupling then
		local m = (stallRatio - 1) / coupling
		return k * a * a, k * (stallRatio * a * a - m * a * b), 2 * k * a, 0, k * (2 * stallRatio * a - m * b), -k * m * a
	elseif s <= 1 then
		local kc = k / (1 - coupling)
		local torque = kc * a * (a - b)
		return torque, torque, kc * (2 * a - b), -kc * a, kc * (2 * a - b), -kc * a
	end
	local ko = k / (1 - coupling) * (spec.overrunCapacity or 0.6)
	local torque = -ko * b * (b - a)
	return torque, torque, ko * b, -ko * (2 * b - a), ko * b, -ko * (2 * b - a)
end

-- Converter torque multiplication at these speeds (1 once it couples).
function Transmission.torqueRatio(tr, omegaImpeller: number, omegaTurbine: number): number
	local spec = tr.spec.converter
	local s = math.max(omegaTurbine / omegaImpeller, 0)
	if s >= spec.couplingPoint then
		return 1
	end
	return spec.torqueRatio - (spec.torqueRatio - 1) * s / spec.couplingPoint
end

--[[
	Automatic gearboxes: torque through the converter and its lock-up clutch for one step. The
	converter's torques are linearised and solved implicitly together with the engine and gearbox
	input speeds, like clutchTorque, so the light gearbox side stays stable. The lock-up clutch is
	then solved on top as a stiff coupling with lockupCapacity.
	  omegaEngine, omegaTurbine  rad/s now
	  turbineNext  during a shift, the turbine speed at the end of this step, which the shift
	               clutches control. Otherwise nil, and the turbine moves with the wheels
	               (inertiaInput, loadTorque).
	  the rest as for clutchTorque
	Returns the torque taken from the engine, the torque passed into the gearbox (in a shift, what
	the shift clutches pass on after changing the turbine's own speed), and the lock-up clutch's part.
]]
function Transmission.automaticTorque(tr, omegaEngine: number, omegaTurbine: number, turbineNext: number?, inertiaEngine: number, inertiaInput: number, engineTorque: number, loadTorque: number, lockupCapacity: number, dt: number): (number, number, number)
	local impeller, turbine, pa, pb, qa, qb = Transmission.converter(tr, omegaEngine, omegaTurbine)
	local alpha = dt / inertiaEngine
	local da, db
	if turbineNext then
		db = turbineNext - omegaTurbine
		da = alpha * (engineTorque - impeller - pb * db) / (1 + alpha * pa)
	else
		-- [1 + alpha*pa, alpha*pb; -beta*qa, 1 - beta*qb] [da; db] = [alpha*(Te - impeller); beta*(turbine - load)]
		local beta = dt / inertiaInput
		local m11, m12, m21, m22 = 1 + alpha * pa, alpha * pb, -beta * qa, 1 - beta * qb
		local r1, r2 = alpha * (engineTorque - impeller), beta * (turbine - loadTorque)
		local det = m11 * m22 - m12 * m21 -- at least 1 for this converter model
		da = (r1 * m22 - m12 * r2) / det
		db = (m11 * r2 - m21 * r1) / det
	end
	impeller += pa * da + pb * db
	turbine += qa * da + qb * db

	local lock = 0
	if lockupCapacity > 0 then
		local stiffness = tr.spec.lockup.stiffness or DEFAULT_LOCKUP_STIFFNESS
		if turbineNext then
			lock = couplingTorque(stiffness, omegaEngine, turbineNext, inertiaEngine, math.huge, engineTorque - impeller, 0, lockupCapacity, dt)
		else
			lock = couplingTorque(stiffness, omegaEngine, omegaTurbine, inertiaEngine, inertiaInput, engineTorque - impeller, loadTorque - turbine, lockupCapacity, dt)
		end
	end
	local delivered = turbine + lock
	if turbineNext then
		delivered -= tr.turbineInertia * (turbineNext - omegaTurbine) / dt
	end
	return impeller + lock, delivered, lock
end

function Transmission.gearLabel(tr): string
	if tr.gear == 0 then
		return "N"
	elseif tr.gear < 0 then
		return "R"
	end
	return tostring(tr.gear)
end

Transmission.rpmToRadPerSec = Units.rpmToRadPerSec

return Transmission
