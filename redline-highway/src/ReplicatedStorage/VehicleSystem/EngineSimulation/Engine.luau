--[[
	Engine
	Full-throttle torque curve scaled by throttle, blended toward internal friction (engine
	braking) as the throttle closes, with an idle controller and a fuel-cut rev limiter with
	hysteresis.
	Engine speed is integrated by the vehicle simulation together with the clutch.
]]

local Units = require(script.Parent.Parent.Units)

local Engine = {}

function Engine.new(spec)
	return {
		spec = spec,
		omega = Units.rpmToRadPerSec(spec.idleRpm), -- rad/s
		throttle = 0, -- throttle plate position, 0 to 1
		limiterCut = false,
	}
end

function Engine.rpm(engine): number
	return Units.radPerSecToRpm(engine.omega)
end

-- Full-throttle torque at an rpm, interpolated from the curve (Nm).
function Engine.curveTorque(spec, rpm: number): number
	local curve = spec.torqueCurve
	if rpm <= curve[1][1] then
		return curve[1][2] * math.clamp(rpm / curve[1][1], 0, 1)
	end
	for i = 1, #curve - 1 do
		local a, b = curve[i], curve[i + 1]
		if rpm <= b[1] then
			return a[2] + (b[2] - a[2]) * (rpm - a[1]) / (b[1] - a[1])
		end
	end
	return curve[#curve][2]
end

-- Net crankshaft torque for this step (Nm). pedal: 0 to 1.
function Engine.netTorque(engine, pedal: number, dt: number): number
	local spec = engine.spec
	local rpm = Engine.rpm(engine)

	if rpm >= spec.limiterRpm then
		engine.limiterCut = true
	elseif rpm < spec.limiterRpm - spec.limiterHysteresisRpm then
		engine.limiterCut = false
	end

	local target = if engine.limiterCut then 0 else pedal
	if rpm < spec.idleRpm then
		-- idle control: open the throttle a little to hold idle speed
		target = math.max(target, math.clamp((spec.idleRpm - rpm) / 300, 0, 0.35))
	end
	engine.throttle += (target - engine.throttle) * math.clamp(spec.throttleResponse * dt, 0, 1)

	-- The torque curve is the engine's net output at full throttle, which already includes its
	-- internal friction. With the throttle closed, that friction becomes engine braking.
	local drive = Engine.curveTorque(spec, rpm) * engine.throttle
	local friction = if engine.omega > 0 then spec.friction.static + spec.friction.perRpm * rpm else 0
	return drive - friction * (1 - engine.throttle)
end

return Engine
