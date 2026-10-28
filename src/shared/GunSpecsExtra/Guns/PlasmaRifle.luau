-- Plasma Rifle: a green sci-fi rifle with a carry handle, chrome barrel rails and
-- a forked emitter, fed by a red-and-white canister. Based on the green rifle in the blocky Roblox guns picture.
local Shapes = require(script.Parent.Parent.Shapes)

local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

local parts = {
	-- Receiver (the long back half of the body)
	box("Receiver", v3(0.3, 0.375, 1.345), v3(0, 0.1165, -0.2875), "Body"),
	tube("RibUpperLeft", 1.2, 0.045, v3(-0.15, 0.155, -0.27), "Body"),
	tube("RibUpperRight", 1.2, 0.045, v3(0.15, 0.155, -0.27), "Body"),
	tube("RibLowerLeft", 1.2, 0.045, v3(-0.15, 0.025, -0.27), "Body"),
	tube("RibLowerRight", 1.2, 0.045, v3(0.15, 0.025, -0.27), "Body"),
	drum("PinBack", 0.31, 0.055, v3(0, -0.035, 0.25), "Gunmetal"),
	drum("PinFront", 0.31, 0.055, v3(0, -0.035, -0.8), "Gunmetal"),
	box("Selector", v3(0.04, 0.05, 0.1), v3(-0.16, 0.09, 0.12), "Gunmetal"),
	box("BoltSlot", v3(0.03, 0.04, 0.5), v3(0.155, 0.235, -0.45), "Gunmetal"),
	box("BoltHandle", v3(0.06, 0.06, 0.1), v3(0.17, 0.235, -0.3), "Gunmetal"),

	-- Housing (the taller middle block the canister plugs into)
	box("Housing", v3(0.36, 0.545, 0.75), v3(0, 0.1195, -1.325), "Body"),
	box("HousingRear", v3(0.36, 0.375, 0.055), v3(0, 0.1195, -0.9235), "Body"),
	wedge("HousingRearTop", v3(0.36, 0.085, 0.055), v3(0, 0.3495, -0.9235), "Body", v3(0, 180, 0)),
	wedge("HousingRearBottom", v3(0.36, 0.085, 0.055), v3(0, -0.1105, -0.9235), "Body", v3(180, 0, 0)),
	box("HousingFront", v3(0.36, 0.447, 0.12), v3(0, 0.1685, -1.755), "Body"),
	wedge("HousingFrontBottom", v3(0.36, 0.1, 0.12), v3(0, -0.105, -1.755), "Body", v3(0, 0, 180)),
	box("CellFrame", v3(0.37, 0.12, 0.21), v3(0, -0.006, -1.285), "Gunmetal"),
	box("CellLight", v3(0.38, 0.07, 0.16), v3(0, -0.006, -1.285), "Red"),
	drum("HousingScrewBack", 0.37, 0.05, v3(0, 0.3, -1.0), "Gunmetal"),
	drum("HousingScrewFront", 0.37, 0.05, v3(0, 0.3, -1.75), "Gunmetal"),

	-- Carry handle
	box("HandleTop", v3(0.14, 0.071, 1.146), v3(0, 0.5525, -0.665), "Body"),
	box("HandleRearPost", v3(0.14, 0.26, 0.11), v3(0, 0.43, -0.147), "Body"),
	wedge("HandleRearSlope", v3(0.14, 0.288, 0.11), v3(0, 0.444, -0.0375), "Body", v3(0, 180, 0)),
	box("HandleFrontPost", v3(0.14, 0.17, 0.098), v3(0, 0.47, -1.187), "Body"),

	-- Pistol grip (slanted back, with a finger step on the front)
	box("Grip", v3(0.26, 0.84, 0.29), v3(0, -0.364, 0.344), "Body", v3(-25, 0, 0)),
	box("GripFront", v3(0.25, 0.51, 0.115), v3(0, -0.227, 0.057), "Body", v3(-25, 0, 0)),
	box("GripBase", v3(0.28, 0.07, 0.34), v3(0, -0.755, 0.51), "Body", v3(-25, 0, 0)),
	drum("GripScrew", 0.27, 0.05, v3(0, -0.364, 0.344), "Gunmetal"),

	-- Trigger guard and trigger
	box("GuardBottom", v3(0.05, 0.045, 0.37), v3(0, -0.25, -0.175), "Dark"),
	box("GuardFront", v3(0.05, 0.19, 0.045), v3(0, -0.16, -0.375), "Dark", v3(-10, 0, 0)),
	drum("GuardCorner", 0.05, 0.065, v3(0, -0.24, -0.355), "Dark"),
	box("Trigger", v3(0.04, 0.12, 0.045), v3(0, -0.14, -0.16), "Gunmetal", v3(12, 0, 0)),

	-- Barrel rails
	tube("BarrelCollar", 0.07, 0.28, v3(0, 0.245, -1.845), "Gunmetal"),
	tube("Barrel", 0.68, 0.22, v3(0, 0.245, -2.13), "Chrome"),
	tube("Rod", 0.66, 0.1, v3(0, -0.011, -2.13), "Chrome"),
	tube("RodCollar", 0.07, 0.15, v3(0, -0.011, -1.845), "Gunmetal"),
	box("Clamp", v3(0.3, 0.5, 0.09), v3(0, 0.125, -2.44), "Dark"),
	drum("ClampBoltTop", 0.32, 0.06, v3(0, 0.31, -2.44), "Chrome"),
	drum("ClampBoltBottom", 0.32, 0.06, v3(0, -0.06, -2.44), "Chrome"),

	-- Emitter head: upper prong (a dark block with a chrome crest and an eye bolt)
	box("UpperProng", v3(0.28, 0.243, 0.5), v3(0, 0.2665, -2.725), "Gunmetal"),
	box("UpperNose", v3(0.28, 0.158, 0.185), v3(0, 0.224, -3.065), "Gunmetal"),
	wedge("UpperSlope", v3(0.28, 0.085, 0.185), v3(0, 0.3455, -3.065), "Gunmetal"),
	wedge("CrestRamp", v3(0.2, 0.06, 0.14), v3(0, 0.418, -2.55), "Gunmetal", v3(0, 180, 0)),
	box("Crest", v3(0.2, 0.06, 0.16), v3(0, 0.418, -2.7), "Chrome"),
	wedge("CrestFront", v3(0.2, 0.06, 0.12), v3(0, 0.418, -2.84), "Gunmetal"),
	ball("SightDot", 0.05, v3(0, 0.455, -2.7), "Accent"),
	drum("EyeRing", 0.29, 0.13, v3(0, 0.3, -2.84), "Chrome"),
	drum("Eye", 0.3, 0.085, v3(0, 0.3, -2.84), "Dark"),

	-- Emitter head: lower jaw (a chrome claw angled up to the tip) and the glowing core in the mouth
	box("JawHinge", v3(0.26, 0.32, 0.15), v3(0, -0.01, -2.55), "Gunmetal"),
	box("Jaw", v3(0.22, 0.13, 0.62), v3(0, -0.061, -2.88), "Chrome", v3(16, 0, 0)),
	box("JawTip", v3(0.23, 0.14, 0.1), v3(0, 0.0134, -3.14), "Gunmetal", v3(16, 0, 0)),
	ball("Core", 0.1, v3(0, 0.05, -2.68), "Accent"),

	-- Canister (the ammo cell, plugged in under the housing)
	disc("CanSocket", 0.06, 0.46, v3(0, -0.183, -1.35), "Gunmetal"),
	disc("CanNeck", 0.1, 0.26, v3(0, -0.26, -1.35), "Gunmetal"),
	disc("CanShoulder", 0.05, 0.46, v3(0, -0.33, -1.35), "White"),
	disc("CanTop", 0.22, 0.54, v3(0, -0.465, -1.35), "White"),
	disc("CanBody", 0.675, 0.54, v3(0, -0.9125, -1.35), "Red"),
	disc("CanFoot", 0.05, 0.46, v3(0, -1.27, -1.35), "Red"),
	box("CanWindowFrameLeft", v3(0.04, 0.29, 0.1), v3(-0.258, -1.03, -1.35), "Gunmetal"),
	box("CanWindowFrameRight", v3(0.04, 0.29, 0.1), v3(0.258, -1.03, -1.35), "Gunmetal"),
	box("CanWindowLeft", v3(0.04, 0.22, 0.05), v3(-0.27, -1.03, -1.35), "Accent"),
	box("CanWindowRight", v3(0.04, 0.22, 0.05), v3(0.27, -1.03, -1.35), "Accent"),
}

-- Barrel ribs
for index = 0, 3 do
	table.insert(parts, tube("BarrelRib" .. index + 1, 0.04, 0.245, v3(0, 0.245, -1.98 - index * 0.11), "Gunmetal"))
end

-- White flame teeth around the canister: little diamonds whose lower points
-- stick down into the red
for index = 0, 7 do
	local angle = index * 45
	local radians = math.rad(angle)
	local side = if index % 2 == 0 then 0.2 else 0.15
	local height = if index % 2 == 0 then -0.625 else -0.6
	local position = v3(math.sin(radians) * 0.255, height, -1.35 + math.cos(radians) * 0.255)
	table.insert(parts, box("CanFlame" .. index + 1, v3(side, side, 0.05), position, "White", v3(0, angle, 45)))
end

return {
	Factory = { Body = rgb(58, 94, 44), Accent = rgb(120, 255, 90), Material = Enum.Material.SmoothPlastic },
	View = CFrame.new(0, 0, -0.95),
	Muzzle = v3(0, 0.105, -3.17),
	Support = v3(-0.03, -0.47, -1.35),
	Parts = parts,
}
