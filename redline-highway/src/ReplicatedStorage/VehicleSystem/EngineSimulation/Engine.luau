--[[
	Engine
	Full-throttle torque curve scaled by throttle, blended toward internal friction (engine
	braking) as the throttle closes, with an idle controller and a fuel-cut rev limiter with
	hysteresis.
	Engine speed is integrated by the vehicle simulation together with the clutch.

	Forced induction (optional, spec.forcedInduction; see docs/VEHICLE_CONFIG.md):
	  The torque curve is then the full-boost curve. With no boost the engine makes
	  offBoostTorqueShare of it, and boost adds the rest in proportion. The throttle is a torque
	  request: up to offBoostTorqueShare the engine needs no boost; above it, boost is asked for.
	  Boost can't pass a ceiling that rises from 0 at boostStartRpm to 1 at fullBoostRpm.
	  Turbo         boost builds toward the target at a rate that rises with rpm and engine load
	                (turbo lag), and dumps quickly when the throttle closes (blow-off).
	  Supercharger  positive displacement: boost follows engine speed and throttle with no lag.
]]

local Units = require(script.Parent.Parent.Units)

local Engine = {}

local MAX_VACUUM_BAR = 0.75 -- manifold vacuum the boost gauge shows with the throttle shut

function Engine.new(spec)
	local engine = {
		spec = spec,
		omega = Units.rpmToRadPerSec(spec.idleRpm), -- rad/s
		throttle = 0, -- throttle request, 0 to 1 (share of the full-throttle, full-boost torque)
		limiterCut = false,
		boost = 0, -- share of maximum boost, 0 to 1
		delivered = 0, -- share of the torque curve the engine is making now, 0 to 1
		spoolRate = 0, -- 1/s, turbo boost build rate at fullBoostRpm and full load
		dumpRate = 0, -- 1/s, turbo boost decay rate
	}
	local fi = spec.forcedInduction
	if fi and fi.type == "Turbo" then
		-- At full throttle and a steady rpm, the delivered share u = share + (1 - share) * boost
		-- follows the logistic du/dt = rate * u * (1 - u), so spoolTime (no boost to 90%) sets the rate.
		local share = math.clamp(fi.offBoostTorqueShare, 0.05, 0.95)
		local u90 = share + 0.9 * (1 - share)
		engine.spoolRate = math.log(((1 - share) / share) / ((1 - u90) / u90)) / fi.spoolTime
		engine.dumpRate = math.log(10) / fi.dumpTime -- boost falls to 10% in dumpTime
	end
	return engine
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

-- Forced induction: share of maximum boost the charger can make at this rpm (0 to 1).
function Engine.boostCeiling(fi, rpm: number): number
	return math.clamp((rpm - fi.boostStartRpm) / math.max(fi.fullBoostRpm - fi.boostStartRpm, 1), 0, 1)
end

-- Steady full-throttle torque at an rpm once boost has built (Nm). For an engine without forced
-- induction this is the torque curve itself. This is what a dyno would show.
function Engine.fullLoadTorque(spec, rpm: number): number
	local torque = Engine.curveTorque(spec, rpm)
	local fi = spec.forcedInduction
	if fi then
		local share = fi.offBoostTorqueShare
		torque *= share + (1 - share) * Engine.boostCeiling(fi, rpm)
	end
	return torque
end

-- Boost gauge reading in bar (gauge pressure). Negative under manifold vacuum at part throttle.
function Engine.boostBar(engine): number
	local fi = engine.spec.forcedInduction
	if not fi then
		return 0
	end
	local share = fi.offBoostTorqueShare
	if engine.delivered >= share then
		return (engine.delivered - share) / (1 - share) * fi.maxBoostBar
	end
	return (engine.delivered / share - 1) * MAX_VACUUM_BAR
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

	-- share of the torque curve delivered: the throttle request, limited by the boost available
	local delivered = engine.throttle
	local fi = spec.forcedInduction
	if fi then
		local share = fi.offBoostTorqueShare
		-- boost asked for: none until the request passes what the engine makes without boost
		local demand = math.clamp((engine.throttle - share) / (1 - share), 0, 1)
		local boostTarget = demand * Engine.boostCeiling(fi, rpm)
		if fi.type == "Supercharger" then
			engine.boost = boostTarget
		else
			local rate = engine.dumpRate
			if boostTarget > engine.boost then
				-- the turbo spools faster with more exhaust flow: higher rpm and more load
				local load = math.min(engine.throttle, share + (1 - share) * engine.boost)
				rate = engine.spoolRate * math.clamp(rpm / fi.fullBoostRpm, 0.1, 3) * load
			end
			engine.boost += (boostTarget - engine.boost) * math.clamp(rate * dt, 0, 1)
		end
		delivered = math.min(engine.throttle, share + (1 - share) * engine.boost)
	end
	engine.delivered = delivered

	-- The torque curve is the engine's net output at full throttle, which already includes its
	-- internal friction. With the throttle closed, that friction becomes engine braking.
	local drive = Engine.curveTorque(spec, rpm) * delivered
	local friction = if engine.omega > 0 then spec.friction.static + spec.friction.perRpm * rpm else 0
	return drive - friction * (1 - engine.throttle)
end

return Engine
