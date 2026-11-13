--[[
	Transmission
	Gear selection, automatic and manual modes, shift timing and clutch engagement for a
	dual-clutch gearbox. Gear numbers: -1 reverse, 0 neutral, 1 and up forward.

	The clutch is modelled as a stiff, torque-limited coupling solved implicitly (see
	Transmission.clutchTorque), which stays stable even though the wheel side has very little
	inertia once it is reflected through a low gear.
]]

local Units = require(script.Parent.Parent.Units)

local Transmission = {}

function Transmission.new(spec)
	return {
		spec = spec,
		gear = 1,
		auto = true,
		shiftTimer = 0, -- seconds left in the current shift
		sinceShift = 10, -- seconds since the last shift
	}
end

-- Overall ratio from engine to wheels, negative in reverse, 0 in neutral.
function Transmission.ratio(tr): number
	local spec = tr.spec
	if tr.gear == 0 then
		return 0
	elseif tr.gear < 0 then
		return -spec.reverseRatio * spec.finalDrive
	end
	return spec.gearRatios[tr.gear] * spec.finalDrive
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
	tr.gear = newGear
	tr.shiftTimer = spec.shiftTime
	tr.sinceShift = 0
	return true
end

function Transmission.isShifting(tr): boolean
	return tr.shiftTimer > 0
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
	if inputRpm > up and tr.gear < #spec.gearRatios then
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
function Transmission.clutchTorque(tr, omegaEngine: number, omegaInput: number, inertiaEngine: number, inertiaInput: number, engineTorque: number, loadTorque: number, capacity: number, dt: number): number
	if capacity <= 0 then
		return 0
	end
	local stiffness = tr.spec.clutchStiffness
	local predictedSlip = (omegaEngine - omegaInput) + dt * (engineTorque / inertiaEngine + loadTorque / inertiaInput)
	local torque = stiffness * predictedSlip / (1 + stiffness * dt * (1 / inertiaEngine + 1 / inertiaInput))
	return math.clamp(torque, -capacity, capacity)
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
