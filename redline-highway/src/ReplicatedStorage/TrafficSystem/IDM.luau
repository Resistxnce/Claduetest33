--[[
	Intelligent Driver Model (Treiber, Hennecke and Helbing, 2000): a car-following model that gives
	a driver's acceleration from their speed, the gap to the car ahead and how fast they are closing
	on it. It keeps a safe time gap, brakes smoothly and doesn't crash in normal traffic.
]]

local DriverProfiles = require(script.Parent.DriverProfiles)

local IDM = {}

--[[
	p: profile (accel, decel, gap, minGap). v: speed (m/s). v0: desired speed (m/s).
	gap: bumper-to-bumper distance to the leader (m), or nil on a free road.
	dv: closing speed, v minus the leader's speed (m/s).
	Returns acceleration in m/s^2, never below -MAX_DECEL.
]]
function IDM.acceleration(p, v: number, v0: number, gap: number?, dv: number): number
	local free = if v0 > 0 then 1 - (v / v0) ^ 4 else -1
	if gap == nil then
		return math.max(p.accel * free, -DriverProfiles.MAX_DECEL)
	end
	local desiredGap = p.minGap + math.max(0, v * p.gap + v * dv / (2 * math.sqrt(p.accel * p.decel)))
	local ratio = desiredGap / math.max(gap, 0.1)
	return math.max(p.accel * (free - ratio * ratio), -DriverProfiles.MAX_DECEL)
end

return IDM
