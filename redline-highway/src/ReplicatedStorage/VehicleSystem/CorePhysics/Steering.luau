--[[
	Steering
	Turns steering input into left and right road-wheel angles.
	  - The maximum angle shrinks with speed so keyboard players stay in control at 300 km/h.
	  - The wheels turn at a limited rate.
	  - Ackermann geometry turns the inside wheel more than the outside one.
	Positive angles steer to the right.
]]

local Steering = {}

function Steering.new(spec)
	return { spec = spec, angle = 0 } -- angle: average road-wheel angle, radians
end

function Steering.maxAngle(spec, speedKmh: number): number
	local t = math.clamp(speedKmh / spec.highSpeedKmh, 0, 1) ^ 0.7
	return math.rad(spec.maxAngleLowSpeed + (spec.maxAngleHighSpeed - spec.maxAngleLowSpeed) * t)
end

--[[
	input: -1 (full left) to 1 (full right). Returns left and right wheel angles (radians).
]]
function Steering.update(st, input: number, speedKmh: number, dt: number, wheelbase: number, track: number): (number, number)
	local spec = st.spec
	local target = input * Steering.maxAngle(spec, speedKmh)
	local maxStep = math.rad(spec.rate) * dt
	st.angle += math.clamp(target - st.angle, -maxStep, maxStep)

	local a = st.angle
	local magnitude = math.abs(a)
	if magnitude < 1e-4 then
		return a, a
	end
	local radius = wheelbase / math.tan(magnitude)
	local inner = math.atan(wheelbase / math.max(radius - track / 2, 0.1))
	local outer = math.atan(wheelbase / (radius + track / 2))
	local k = spec.ackermann
	local innerAngle = magnitude + (inner - magnitude) * k
	local outerAngle = magnitude + (outer - magnitude) * k
	if a > 0 then
		return outerAngle, innerAngle -- turning right: the right wheel is on the inside
	end
	return -innerAngle, -outerAngle
end

return Steering
