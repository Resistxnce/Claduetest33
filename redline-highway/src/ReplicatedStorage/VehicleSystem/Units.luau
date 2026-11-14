--[[
	Units
	Converts between SI units (used by all vehicle maths) and Roblox units.

	Roblox Creator Hub, "Roblox units": 1 stud = 0.28 m and 1 RMU (Roblox mass unit) = 21.952 kg.
	The physics engine itself is unit-free, so these conversions only matter at the edges:
	positions and velocities coming in from Roblox, and forces going back out.
]]

local Units = {}

Units.METERS_PER_STUD = 0.28
Units.KG_PER_RMU = 21.952
Units.GRAVITY = 9.81 -- m/s^2
Units.AIR_DENSITY = 1.225 -- kg/m^3, sea level at 15 C

-- Real-world gravity expressed in studs/s^2. The Roblox default of 196.2 is far stronger.
Units.REALISTIC_GRAVITY = Units.GRAVITY / Units.METERS_PER_STUD

-- Roblox force units per newton (RMU * stud / s^2).
Units.FORCE_PER_NEWTON = 1 / (Units.KG_PER_RMU * Units.METERS_PER_STUD)

function Units.studsToMeters(studs: number): number
	return studs * Units.METERS_PER_STUD
end

function Units.metersToStuds(meters: number): number
	return meters / Units.METERS_PER_STUD
end

function Units.kgToRmu(kg: number): number
	return kg / Units.KG_PER_RMU
end

function Units.mpsToKmh(mps: number): number
	return mps * 3.6
end

function Units.rpmToRadPerSec(rpm: number): number
	return rpm * math.pi / 30
end

function Units.radPerSecToRpm(radPerSec: number): number
	return radPerSec * 30 / math.pi
end

return Units
