-- Revolver: a polished silver double-action revolver with a long round barrel, a fluted
-- cylinder and a pearl grip, based on the silver revolver in the blocky Roblox guns picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

-- Cylinder center, and the six flutes cut between its chambers (added after the parts below)
local CYL_Y, CYL_Z = 0.114, -0.2
local flutes = {}
for i = 0, 5 do
	local angle = i * 60
	local r = 0.152
	table.insert(
		flutes,
		box(
			"Flute" .. (i + 1),
			v3(0.05, 0.065, 0.2),
			v3(r * math.cos(math.rad(angle)), CYL_Y + r * math.sin(math.rad(angle)), CYL_Z),
			"Gunmetal",
			v3(0, 0, angle)
		)
	)
end

-- The grip curves, so its pieces follow sloped lines in the side view. Points are
-- given as (z, y). backOf puts a block in front of the line (the line is its back
-- face); frontOf puts it behind the line (the line is its front face).
local function along(name, width, depth, top, bottom, role, side)
	local dz, dy = bottom[1] - top[1], top[2] - bottom[2]
	local tilt = math.atan2(dz, dy)
	local z = (top[1] + bottom[1]) / 2 + side * math.cos(tilt) * depth / 2
	local y = (top[2] + bottom[2]) / 2 + side * math.sin(tilt) * depth / 2
	return box(name, v3(width, math.sqrt(dz * dz + dy * dy), depth), v3(0, y, z), role, v3(-math.deg(tilt), 0, 0))
end
local function backOf(name, width, depth, top, bottom, role)
	return along(name, width, depth, top, bottom, role, -1)
end
local function frontOf(name, width, depth, top, bottom, role)
	return along(name, width, depth, top, bottom, role, 1)
end

-- The grip's back edge (a smooth arc sweeping back and down) and its front edge
local B0, B1, B2, B3, B4 = { 0.34, -0.095 }, { 0.405, -0.245 }, { 0.468, -0.395 }, { 0.525, -0.55 }, { 0.56, -0.688 }
local F0, F1, F2, F3 = { 0.104, -0.18 }, { 0.14, -0.3 }, { 0.163, -0.47 }, { 0.166, -0.69 }

local parts = {
	-- Barrel
	tube("Barrel", 0.935, 0.13, v3(0, 0.213, -1.0475), "Body"),
	tube("BarrelCollar", 0.06, 0.155, v3(0, 0.213, -0.63), "Body"),
	tube("MuzzleCrown", 0.04, 0.138, v3(0, 0.213, -1.495), "Body"),
	tube("Bore", 0.04, 0.06, v3(0, 0.213, -1.497), "Dark"),

	-- Front sight
	box("FrontSightBlade", v3(0.05, 0.07, 0.07), v3(0, 0.305, -1.335), "Body"),
	wedge("FrontSightRamp", v3(0.05, 0.07, 0.08), v3(0, 0.305, -1.41), "Body"),
	box("FrontSightGlow", v3(0.054, 0.035, 0.03), v3(0, 0.318, -1.3), "Accent"),

	-- Ejector rod under the barrel
	tube("EjectorRod", 0.76, 0.06, v3(0, 0.148, -0.98), "Body"),
	tube("EjectorHead", 0.07, 0.075, v3(0, 0.148, -1.395), "Gunmetal"),
	tube("EjectorKnurl", 0.04, 0.082, v3(0, 0.148, -1.395), "Gunmetal"),
	box("EjectorLug", v3(0.06, 0.08, 0.07), v3(0, 0.16, -1.465), "Body"),

	-- Frame
	box("TopStrap", v3(0.2, 0.045, 0.6), v3(0, 0.2975, -0.32), "Body"),
	box("RearSightLeft", v3(0.05, 0.04, 0.06), v3(-0.045, 0.325, -0.07), "Body"),
	box("RearSightRight", v3(0.05, 0.04, 0.06), v3(0.045, 0.325, -0.07), "Body"),
	box("FrameFront", v3(0.26, 0.18, 0.23), v3(0, 0.19, -0.485), "Body"),
	box("FrameFrontTop", v3(0.22, 0.04, 0.15), v3(0, 0.3, -0.445), "Body"),
	wedge("FrameFrontTopSlope", v3(0.2, 0.04, 0.1), v3(0, 0.3, -0.57), "Body"),
	box("FrameFrontLow", v3(0.26, 0.22, 0.11), v3(0, -0.005, -0.425), "Body"),
	wedge("FrameFrontSlope", v3(0.26, 0.09, 0.12), v3(0, 0.065, -0.54), "Body", v3(0, 0, 180)),
	box("CraneSeam", v3(0.272, 0.19, 0.04), v3(0, 0.0, -0.44), "Dark"),
	box("FrameBottom", v3(0.24, 0.07, 0.52), v3(0, -0.08, -0.21), "Body"),
	box("FrameRear", v3(0.26, 0.365, 0.11), v3(0, 0.0675, -0.005), "Body"),
	wedge("FrameRearSlope", v3(0.22, 0.06, 0.11), v3(0, 0.28, -0.005), "Body", v3(0, 180, 0)),

	-- Cylinder
	tube("Cylinder", 0.27, 0.35, v3(0, CYL_Y, CYL_Z), "Body"),
	tube("CylinderFront", 0.035, 0.31, v3(0, CYL_Y, -0.35), "Body"),
	tube("CylinderBack", 0.03, 0.3, v3(0, CYL_Y, -0.055), "Gunmetal"),

	-- Hammer and the dark grip frame behind the cylinder
	box("HammerBody", v3(0.12, 0.28, 0.12), v3(0, 0.095, 0.11), "Gunmetal"),
	drum("HammerTop", 0.12, 0.18, v3(0, 0.145, 0.14), "Gunmetal"),
	box("HammerBack", v3(0.1, 0.11, 0.13), v3(0, 0.085, 0.235), "Gunmetal"),
	box("HammerSpur", v3(0.07, 0.05, 0.22), v3(0, 0.135, 0.32), "Gunmetal", v3(-6, 0, 0)),
	box("BackStrapTop", v3(0.22, 0.26, 0.2), v3(0, -0.072, 0.2387), "Gunmetal", v3(-15.6, 0, 0)),
	box("FrameLowerRear", v3(0.2, 0.18, 0.17), v3(0, -0.12, 0.085), "Gunmetal"),
	wedge("GripFrontCurve", v3(0.2, 0.08, 0.12), v3(0, -0.25, 0.09), "Gunmetal", v3(0, 0, 180)),

	-- Trigger and guard
	box("TriggerTop", v3(0.05, 0.08, 0.045), v3(0, -0.15, -0.07), "Gunmetal", v3(-5, 0, 0)),
	box("TriggerBottom", v3(0.05, 0.08, 0.045), v3(0, -0.215, -0.05), "Gunmetal", v3(-35, 0, 0)),
	box("GuardFront", v3(0.06, 0.14, 0.04), v3(0, -0.19, -0.275), "Gunmetal", v3(-22, 0, 0)),
	box("GuardFrontCorner", v3(0.06, 0.07, 0.04), v3(0, -0.268, -0.235), "Gunmetal", v3(-55, 0, 0)),
	box("GuardBottom", v3(0.06, 0.04, 0.2), v3(0, -0.29, -0.11), "Gunmetal"),
	box("GuardRearCorner", v3(0.06, 0.07, 0.04), v3(0, -0.27, 0.0), "Gunmetal", v3(50, 0, 0)),
	box("GuardRear", v3(0.06, 0.08, 0.04), v3(0, -0.215, 0.03), "Gunmetal", v3(15, 0, 0)),

	-- Pins and screws
	drum("HammerPin", 0.04, 0.045, v3(0.115, 0.0, 0.2), "Chrome"),
	drum("TriggerPin", 0.04, 0.04, v3(0.125, -0.08, -0.06), "Chrome"),
	drum("SideplateScrewTop", 0.04, 0.045, v3(0.13, 0.17, -0.005), "Chrome"),
	drum("SideplateScrewLow", 0.04, 0.045, v3(0.13, -0.04, -0.005), "Chrome"),
	drum("CraneScrew", 0.04, 0.04, v3(0.13, -0.07, -0.41), "Chrome"),
	box("CylinderLatch", v3(0.04, 0.06, 0.1), v3(-0.14, 0.16, 0.0), "Gunmetal"),

	-- Pearl grip: narrow under the hammer, sweeping back and down to a flared base
	backOf("GripTop", 0.234, 0.23, B0, B1, "Bone"),
	backOf("GripUpper", 0.232, 0.27, B1, B2, "Bone"),
	backOf("GripLower", 0.244, 0.3, B2, B3, "Bone"),
	backOf("GripHeel", 0.254, 0.18, B3, B4, "Bone"),
	frontOf("GripFrontUpper", 0.232, 0.12, F0, F1, "Bone"),
	frontOf("GripFrontMid", 0.24, 0.2, F1, F2, "Bone"),
	frontOf("GripFrontLow", 0.25, 0.24, F2, F3, "Bone"),
	box("GripBase", v3(0.258, 0.07, 0.38), v3(0, -0.655, 0.355), "Bone"),

	-- Grip frame straps, butt cap and grip screw
	frontOf("FrontStrapUpper", 0.12, 0.05, { 0.088, -0.2 }, { 0.127, -0.3 }, "Gunmetal"),
	frontOf("FrontStrapMid", 0.12, 0.05, { 0.127, -0.3 }, { 0.15, -0.47 }, "Gunmetal"),
	frontOf("FrontStrapLow", 0.12, 0.05, { 0.15, -0.47 }, { 0.153, -0.69 }, "Gunmetal"),
	box("ButtCap", v3(0.272, 0.045, 0.43), v3(0, -0.712, 0.36), "Gunmetal"),
	egg("ButtCapHeel", v3(0.272, 0.07, 0.09), v3(0, -0.706, 0.567), "Gunmetal"),
	drum("GripScrewLeft", 0.04, 0.05, v3(-0.12, -0.42, 0.33), "Chrome"),
	drum("GripScrewRight", 0.04, 0.05, v3(0.12, -0.42, 0.33), "Chrome"),
}

for _, flute in flutes do
	table.insert(parts, flute)
end

return {
	Factory = { Body = rgb(185, 188, 195), Accent = rgb(96, 100, 108), Material = Enum.Material.Metal }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0, -0.1),
	Muzzle = v3(0, 0.213, -1.515),
	Support = v3(-0.12, -0.48, 0.22),
	Parts = parts,
}
