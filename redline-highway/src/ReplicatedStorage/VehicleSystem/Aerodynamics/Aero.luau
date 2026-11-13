--[[
	Aero
	Drag and downforce, both rising with the square of speed: F = 0.5 * rho * area * v^2.
	Downforce is split between the front and rear axles so aero parts change balance too.
]]

local Units = require(script.Parent.Parent.Units)

local Aero = {}

-- speed in m/s. Returns drag, front downforce and rear downforce in newtons.
function Aero.forces(spec, speed: number): (number, number, number)
	local q = 0.5 * Units.AIR_DENSITY * speed * speed
	return q * spec.dragArea, q * spec.downforceAreaFront, q * spec.downforceAreaRear
end

return Aero
