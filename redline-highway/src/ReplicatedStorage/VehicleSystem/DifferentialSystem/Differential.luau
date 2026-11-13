--[[
	Differential
	Splits an axle's drive torque between its left and right wheels.

	  Open         equal torque to both sides
	  LimitedSlip  clutch-type: moves torque from the faster wheel to the slower one, up to
	               preload + lock factor * input torque (separate lock factors on and off power)
	  Locked       a very stiff limited-slip

	The transfer is capped so it can never reverse the speed difference within one step,
	which keeps stiff settings stable.
]]

local Differential = {}

--[[
	torqueIn: torque into the differential (Nm)
	omegaLeft, omegaRight: wheel speeds (rad/s)
	inertia: one wheel's inertia (kg*m^2); dt: time step (s)
	Returns torque to the left wheel and to the right wheel.
]]
function Differential.split(spec, torqueIn: number, omegaLeft: number, omegaRight: number, inertia: number, dt: number): (number, number)
	local kind = spec and spec.type or "Open"
	if kind == "Open" then
		return torqueIn / 2, torqueIn / 2
	end

	local stiffness, maxTransfer
	if kind == "Locked" then
		stiffness = 5000
		maxTransfer = math.huge
	else
		local lock = if torqueIn >= 0 then spec.powerLock else spec.coastLock
		stiffness = spec.stiffness
		maxTransfer = spec.preload + lock * math.abs(torqueIn)
	end

	local difference = omegaLeft - omegaRight
	local equalising = math.abs(difference) * inertia / dt -- transfer that would just equalise the speeds
	local transfer = math.clamp(stiffness * difference, -maxTransfer, maxTransfer)
	transfer = math.clamp(transfer, -equalising, equalising)
	return torqueIn / 2 - transfer / 2, torqueIn / 2 + transfer / 2
end

return Differential
