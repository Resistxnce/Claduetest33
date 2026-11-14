--[[
	Brakes
	Brake torque per wheel from the pedal, with per-axle maximums (which set the front/rear bias),
	an ABS that releases pressure as a wheel starts to lock, and a rear handbrake.
]]

local Brakes = {}

--[[
	Returns brake torque magnitude (Nm) for one wheel.
	  isFront    front axle wheel
	  pedal      brake pedal 0 to 1
	  handbrake  0 to 1 (rear wheels only)
	  slipRatio  current slip ratio (negative when the wheel turns slower than the road)
	  absOn      whether ABS is active
]]
function Brakes.torque(spec, isFront: boolean, pedal: number, handbrake: number, slipRatio: number, absOn: boolean): number
	local torque = (if isFront then spec.maxTorqueFront else spec.maxTorqueRear) * pedal
	local handbrakeTorque = if isFront then 0 else spec.handbrakeTorque * handbrake

	if absOn and pedal > 0 and handbrakeTorque == 0 then
		local target = spec.abs.targetSlip
		if slipRatio < -target then
			local excess = (-slipRatio - target) / target
			torque *= math.clamp(1 - excess, 0.15, 1)
		end
	end
	return math.max(torque, handbrakeTorque)
end

return Brakes
