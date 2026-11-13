--[[
	Tire
	Combined-slip tyre model in the style of Pacejka's magic formula.

	Slip ratio and slip angle are each divided by the slip where that direction peaks, then
	combined into one slip value. The magic formula shape turns that into the share of available
	grip in use, and the force is split between the two directions in proportion to their slips.
	The result behaves like a friction ellipse: a tyre braking hard has less grip left for cornering.

	Low-speed handling: slip ratio uses at least 3 m/s as its reference speed, and the slip angle
	builds up over a relaxation length, so a parked or crawling car doesn't jitter.
]]

local Compounds = require(script.Parent.Compounds)

local Tire = {}

-- Radius in metres from a tyre size such as 275/35 R20.
function Tire.radiusFromSize(widthMm: number, aspect: number, rimInches: number): number
	return (rimInches * 25.4 + 2 * widthMm * aspect / 100) / 2000
end

-- Normalised magic formula: 0 at s = 0, peak of 1 at s = 1, settles toward sin(c * pi / 2).
local function shape(s: number, c: number): number
	local b = math.tan(math.pi / (2 * c))
	return math.sin(c * math.atan(b * s))
end

function Tire.new(spec)
	local compound = Compounds[spec.compound] or Compounds.Performance
	return {
		radius = Tire.radiusFromSize(spec.widthMm, spec.aspect, spec.rimInches),
		inertia = spec.inertia,
		compound = compound,
		peakSlipAngle = math.rad(compound.peakSlipAngle),
		slipAngle = 0, -- relaxed slip angle, radians
	}
end

--[[
	Forces on one tyre, in newtons.
	  load       normal load (N)
	  vLong      contact patch speed along the wheel's heading (m/s, forward positive)
	  vLat       contact patch speed to the wheel's right (m/s)
	  wheelSpeed wheel angular speed times radius (m/s)
	  grip       surface multiplier (1 = dry asphalt)
	  dt         time step (s)
	Returns longitudinal force (forward positive), lateral force (right positive),
	slip ratio and slip angle (radians).
]]
function Tire.forces(tire, load: number, vLong: number, vLat: number, wheelSpeed: number, grip: number, dt: number)
	if load <= 0 then
		tire.slipAngle = 0
		return 0, 0, 0, 0
	end
	local c = tire.compound

	local slipRatio = (wheelSpeed - vLong) / math.max(math.abs(vLong), 3)

	local targetAngle = math.atan2(vLat, math.max(math.abs(vLong), 0.5))
	local blend = math.clamp(math.abs(vLong) * dt / c.relaxationLength, 0.05, 1)
	tire.slipAngle += (targetAngle - tire.slipAngle) * blend

	local loadFactor = math.clamp(1 - c.loadSensitivity * (load / c.nominalLoad - 1), 0.7, 1.15)
	local muLong = c.muLong * grip * loadFactor
	local muLat = c.muLat * grip * loadFactor

	local sx = slipRatio / c.peakSlipRatio
	local sy = tire.slipAngle / tire.peakSlipAngle
	local s = math.sqrt(sx * sx + sy * sy)
	if s < 1e-6 then
		return 0, 0, slipRatio, tire.slipAngle
	end

	local fx = muLong * load * shape(s, c.shapeLong) * (sx / s)
	local fy = -muLat * load * shape(s, c.shapeLat) * (sy / s)
	return fx, fy, slipRatio, tire.slipAngle
end

-- Peak grip available right now, used to cap the parking hold force.
function Tire.peakForce(tire, load: number, grip: number): number
	return tire.compound.muLong * grip * math.max(load, 0)
end

return Tire
