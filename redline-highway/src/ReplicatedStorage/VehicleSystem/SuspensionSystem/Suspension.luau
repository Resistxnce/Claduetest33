--[[
	Suspension
	One corner's spring, damper and bump stop, plus the anti-roll bar maths for an axle.

	Ride height is its own setting: the spring's free length is worked out from the corner's
	static load, so changing spring rate doesn't change ride height (like adjusting spring perches).
]]

local Suspension = {}

-- spec: one axle's suspension settings. cornerLoad: static load on one wheel (N).
function Suspension.new(spec, cornerLoad: number)
	local rideLength = spec.staticLength + spec.rideHeightOffset
	return {
		springRate = spec.springRate,
		bumpDamping = spec.bumpDamping,
		reboundDamping = spec.reboundDamping,
		rideLength = rideLength, -- mount to wheel centre at ride height, after the offset
		freeLength = rideLength + cornerLoad / spec.springRate,
		minLength = rideLength - spec.bumpTravel,
		maxLength = rideLength + spec.droopTravel,
		bumpStopRate = spec.bumpStopRate,
		antiRollRate = spec.antiRollRate,
		rollCenterHeight = spec.rollCenterHeight,
	}
end

--[[
	Spring, damper and bump stop force pushing the car up (N).
	  length    current mount to wheel centre length (m)
	  velocity  rate of change of length (m/s); negative while compressing
]]
function Suspension.force(s, length: number, velocity: number): number
	local compression = s.freeLength - length
	if compression <= 0 then
		return 0
	end
	local force = s.springRate * compression
	if velocity < 0 then
		force -= s.bumpDamping * velocity
	else
		force -= s.reboundDamping * velocity
	end
	if length < s.minLength then
		force += s.bumpStopRate * (s.minLength - length)
	end
	return math.max(force, 0)
end

--[[
	Anti-roll bar force for an axle. Returns the force to add to the left and right wheels.
	It pushes up harder on the more compressed side and eases off the other, resisting roll.
	Only wheels touching the road can take load, so an airborne wheel gets nothing.
]]
function Suspension.antiRoll(s, lengthLeft: number, lengthRight: number, leftContact: boolean, rightContact: boolean)
	if not (leftContact and rightContact) then
		return 0, 0
	end
	local difference = lengthRight - lengthLeft -- positive when the left side is more compressed
	local force = s.antiRollRate * difference
	return force, -force
end

return Suspension
