--[[
	Differential
	Splits an axle's drive torque between its left and right wheels.

	  Open         equal torque to both sides
	  LimitedSlip  clutch-type: moves torque from the faster wheel to the slower one, up to
	               preload + lock factor * input torque (separate lock factors on and off power)
	  Locked       a very stiff limited-slip

	The transfer is capped so it can never reverse the speed difference within one step,
	which keeps stiff settings stable.

	Differential.centre splits the drive between the axles of an on-demand all-wheel-drive car.
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

--[[
	Centre coupling for on-demand, rear-biased all-wheel drive (drivetrain.centreCoupling).
	baseFrontShare of the drive torque always goes to the front axle. Once the rear axle's tyres turn
	faster than the front's by more than slipThreshold of the road speed (the rear wheels spinning),
	a clutch sends more forward, stiffness Nm per m/s of the extra slip, up to maxFrontShare of the
	torque plus preload. If the front turns faster instead, it takes torque back, but never more than
	the base share plus preload, so the front is never driven backwards under power.
	Speeds are compared at the tyre surface (omega * radius), so different tyre sizes front and rear
	don't count as slip. The transfer is capped so it can't reverse the speed difference within one
	step, like Differential.split.
	  torqueIn  drive torque at the wheels, both axles together (Nm)
	  omegaFront, omegaRear  mean wheel speed of each axle (rad/s)
	  radiusFront, radiusRear  tyre radii (m); inertiaFront, inertiaRear  one wheel's inertia (kg*m^2)
	Returns the torque to the front axle and to the rear axle.
]]
function Differential.centre(spec, torqueIn: number, omegaFront: number, omegaRear: number, radiusFront: number, radiusRear: number, inertiaFront: number, inertiaRear: number, dt: number): (number, number)
	local base = spec.baseFrontShare
	local front = torqueIn * base
	local frontSpeed = omegaFront * radiusFront
	local difference = omegaRear * radiusRear - frontSpeed -- m/s, positive while the rear slips more
	local deadband = spec.slipThreshold * math.max(math.abs(frontSpeed), 3)
	local excess = math.max(math.abs(difference) - deadband, 0)
	if difference < 0 then
		excess = -excess
	end
	local preload = spec.preload or 0
	local maxForward = preload + (spec.maxFrontShare - base) * math.abs(torqueIn)
	local maxBack = preload + base * math.abs(torqueIn)
	-- transfer that would just bring the axles' speeds back inside the dead band within one step
	local equalising = math.abs(excess) / (dt * (radiusFront / (2 * inertiaFront) + radiusRear / (2 * inertiaRear)))
	local transfer = math.clamp(spec.stiffness * excess, -maxBack, maxForward)
	transfer = math.clamp(transfer, -equalising, equalising)
	front += transfer
	return front, torqueIn - front
end

return Differential
