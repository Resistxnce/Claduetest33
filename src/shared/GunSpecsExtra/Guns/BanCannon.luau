-- Ban Cannon: the game's ultimate gun, a heavy red-and-black cannon. Built like the
-- red-and-black striped heavy gun (with the curved top magazine) in the blocky Roblox guns picture.
local Shapes = require(script.Parent.Parent.Shapes)

local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

local parts = {
	-- Receiver: red lower block, dark upper core with the back top corner cut off
	box("Receiver", v3(0.42, 0.375, 1.29), v3(0, 0.0625, -0.035), "Body"),
	box("ReceiverTop", v3(0.4, 0.41, 0.66), v3(0, 0.445, -0.35), "Dark"),
	box("ReceiverSlope", v3(0.4, 0.36, 0.752), v3(0, 0.298, 0.192), "Dark", v3(32.6, 0, 0)),
	box("ButtPlate", v3(0.44, 0.4, 0.05), v3(0, 0.07, 0.625), "Rubber"),
	box("SlingPoint", v3(0.08, 0.08, 0.12), v3(0, -0.15, 0.5), "Gunmetal"),

	-- Red armor blocks bolted on each side, split by a dark seam
	wedge("ArmorRearLeft", v3(0.075, 0.39, 0.59), v3(-0.2375, 0.405, 0.265), "Body", v3(0, 180, 0)),
	wedge("ArmorRearRight", v3(0.075, 0.39, 0.59), v3(0.2375, 0.405, 0.265), "Body", v3(0, 180, 0)),
	box("ArmorFrontLeft", v3(0.075, 0.39, 0.57), v3(-0.2375, 0.405, -0.355), "Body"),
	box("ArmorFrontRight", v3(0.075, 0.39, 0.57), v3(0.2375, 0.405, -0.355), "Body"),
	drum("PinRear", 0.58, 0.06, v3(0, 0.3, 0.3), "Gunmetal"),
	drum("PinRearHigh", 0.58, 0.06, v3(0, 0.49, 0.06), "Gunmetal"),
	drum("PinBack", 0.58, 0.06, v3(0, 0.53, -0.16), "Gunmetal"),
	drum("PinFront", 0.58, 0.06, v3(0, 0.53, -0.56), "Gunmetal"),
	drum("PinLow", 0.58, 0.06, v3(0, 0.31, -0.56), "Gunmetal"),
	box("ChargingSlot", v3(0.04, 0.07, 0.36), v3(-0.29, 0.42, -0.36), "Dark"),
	box("ChargingHandle", v3(0.1, 0.06, 0.07), v3(-0.325, 0.42, -0.24), "Chrome"),

	-- Rear sight on the dark top deck, just behind the mag well
	box("RearSightBase", v3(0.2, 0.06, 0.12), v3(0, 0.675, 0), "Gunmetal"),
	box("RearSightLeft", v3(0.05, 0.1, 0.08), v3(-0.06, 0.75, 0), "Gunmetal"),
	box("RearSightRight", v3(0.05, 0.1, 0.08), v3(0.06, 0.75, 0), "Gunmetal"),

	-- Front collar where the barrels come out
	box("Collar", v3(0.54, 0.76, 0.2), v3(0, 0.29, -0.76), "Dark"),
	box("CollarRing", v3(0.46, 0.72, 0.05), v3(0, 0.29, -0.88), "Metal"),

	-- Magazine well and the curved top magazine
	box("MagWell", v3(0.36, 0.22, 0.76), v3(0, 0.75, -0.44), "Gunmetal"),
	box("MagWellLip", v3(0.38, 0.05, 0.78), v3(0, 0.85, -0.44), "Dark"),
	box("MagRelease", v3(0.04, 0.08, 0.1), v3(0.19, 0.74, -0.16), "Gunmetal"),
	-- Banana magazine: five short blocks, each tilted further forward, so it curves
	box("Mag1", v3(0.24, 0.2, 0.618), v3(0, 0.94, -0.425), "Dark", v3(-6.2, 0, 0)),
	box("Mag2", v3(0.24, 0.2, 0.604), v3(0, 1.066, -0.459), "Dark", v3(-18.5, 0, 0)),
	box("Mag3", v3(0.24, 0.2, 0.59), v3(0, 1.18, -0.519), "Dark", v3(-30.8, 0, 0)),
	box("Mag4", v3(0.24, 0.2, 0.576), v3(0, 1.277, -0.601), "Dark", v3(-43.1, 0, 0)),
	box("Mag5", v3(0.24, 0.2, 0.562), v3(0, 1.353, -0.7), "Dark", v3(-55.4, 0, 0)),
	box("MagBasePlate", v3(0.28, 0.05, 0.595), v3(0, 1.393, -0.773), "Rubber", v3(-61.6, 0, 0)),

	-- Two stacked barrels with rings
	tube("UpperBarrel", 0.88, 0.31, v3(0, 0.445, -1.3), "Dark"),
	tube("LowerBarrel", 0.88, 0.31, v3(0, 0.125, -1.3), "Dark"),
	tube("UpperRingBack", 0.06, 0.35, v3(0, 0.445, -0.95), "Gunmetal"),
	tube("LowerRingBack", 0.06, 0.35, v3(0, 0.125, -0.95), "Gunmetal"),
	tube("UpperRingMiddle", 0.06, 0.35, v3(0, 0.445, -1.3), "Gunmetal"),
	tube("LowerRingMiddle", 0.06, 0.35, v3(0, 0.125, -1.3), "Gunmetal"),
	tube("UpperRingFront", 0.06, 0.35, v3(0, 0.445, -1.66), "Gunmetal"),
	tube("LowerRingFront", 0.06, 0.35, v3(0, 0.125, -1.66), "Gunmetal"),
	tube("UpperNeck", 0.2, 0.24, v3(0, 0.445, -1.78), "Dark"),
	tube("LowerNeck", 0.2, 0.26, v3(0, 0.15, -1.78), "Dark"),

	-- Red front shroud
	box("Shroud", v3(0.52, 0.72, 0.74), v3(0, 0.3, -2.215), "Body"),
	box("ShroudFootBack", v3(0.52, 0.09, 0.13), v3(0, -0.085, -1.91), "Body"),
	box("ShroudFootFront", v3(0.52, 0.09, 0.17), v3(0, -0.085, -2.46), "Body"),
	box("ShroudFace", v3(0.48, 0.66, 0.06), v3(0, 0.31, -2.6), "Dark"),
	tube("BarrelExitRing", 0.08, 0.3, v3(0, 0.445, -2.66), "Gunmetal"),
	drum("BoltTopBack", 0.54, 0.06, v3(0, 0.58, -1.93), "Gunmetal"),
	drum("BoltTopFront", 0.54, 0.06, v3(0, 0.58, -2.48), "Gunmetal"),
	drum("BoltLowBack", 0.54, 0.06, v3(0, 0.03, -1.93), "Gunmetal"),
	drum("BoltLowFront", 0.54, 0.06, v3(0, 0.03, -2.48), "Gunmetal"),
	box("GlowVent", v3(0.44, 0.04, 0.38), v3(0, -0.075, -2.185), "Accent"),
	box("GlowTop", v3(0.08, 0.04, 0.36), v3(0, 0.67, -2.215), "Accent"),

	-- Front barrels: the big one on top, a cluster below, a clamp and the muzzle
	tube("Barrel", 0.92, 0.22, v3(0, 0.445, -3.05), "Dark"),
	box("FrontSight", v3(0.05, 0.09, 0.07), v3(0, 0.59, -3.32), "Dark"),
	tube("LowBarrelLeft", 0.9, 0.12, v3(-0.065, 0.245, -3.03), "Dark"),
	tube("LowBarrelRight", 0.9, 0.12, v3(0.065, 0.245, -3.03), "Dark"),
	tube("LowBarrelBottom", 0.92, 0.16, v3(0, 0.1, -3.04), "Dark"),
	box("BarrelClamp", v3(0.2, 0.4, 0.3), v3(0, 0.2, -3.15), "Dark"),
	box("MuzzleBlock", v3(0.26, 0.2, 0.17), v3(0, 0.43, -3.505), "Dark"),
	wedge("MuzzleBevel", v3(0.26, 0.05, 0.17), v3(0, 0.555, -3.505), "Dark"),
	tube("MuzzleRing", 0.04, 0.17, v3(0, 0.43, -3.6), "Gunmetal"),
	tube("MuzzleBore", 0.04, 0.1, v3(0, 0.43, -3.61), "Rubber"),

	-- Pistol grip, trigger and guard
	box("GripTang", v3(0.28, 0.08, 0.36), v3(0, -0.15, 0.18), "Dark"),
	box("Grip", v3(0.24, 0.7, 0.32), v3(0, -0.43, 0.28), "Grip", v3(-20, 0, 0)),
	wedge("GripFlare", v3(0.24, 0.35, 0.07), v3(0, -0.529, 0.518), "Grip", v3(-20, 180, 0)),
	box("GripCap", v3(0.26, 0.05, 0.4), v3(0, -0.758, 0.431), "Dark", v3(-20, 0, 0)),
	box("GripPanelLeft", v3(0.04, 0.48, 0.24), v3(-0.12, -0.449, 0.287), "Rubber", v3(-20, 0, 0)),
	box("GripPanelRight", v3(0.04, 0.48, 0.24), v3(0.12, -0.449, 0.287), "Rubber", v3(-20, 0, 0)),
	drum("GripScrew", 0.3, 0.06, v3(0, -0.449, 0.287), "Gunmetal"),
	drum("FingerRidgeTop", 0.22, 0.08, v3(0, -0.41, 0.102), "Grip"),
	drum("FingerRidgeLow", 0.22, 0.08, v3(0, -0.579, 0.164), "Grip"),
	box("GuardBottom", v3(0.06, 0.06, 0.4), v3(0, -0.29, -0.11), "Chrome"),
	box("GuardFront", v3(0.06, 0.18, 0.06), v3(0, -0.2, -0.33), "Chrome"),
	box("GuardCorner", v3(0.06, 0.06, 0.1), v3(0, -0.27, -0.3), "Chrome", v3(45, 0, 0)),
	box("Trigger", v3(0.05, 0.13, 0.05), v3(0, -0.18, -0.1), "Gunmetal", v3(15, 0, 0)),
}

-- Hazard panel on each side of the lower receiver: five slanted yellow bars on
-- black, framed by trim that hides the bars' corners
for _, side in { -1, 1 } do
	local name = if side < 0 then "Left" else "Right"
	local trimX = side * 0.2375
	local function add(part)
		table.insert(parts, part)
	end
	add(box("HazardPanel" .. name, v3(0.04, 0.33, 1.27), v3(side * 0.22, 0.045, -0.035), "Dark"))
	add(box("HazardTrimTop" .. name, v3(0.075, 0.05, 1.28), v3(trimX, 0.19, -0.03), "Body"))
	add(box("HazardTrimBottom" .. name, v3(0.075, 0.05, 1.28), v3(trimX, -0.105, -0.03), "Dark"))
	add(box("HazardTrimBack" .. name, v3(0.075, 0.35, 0.055), v3(trimX, 0.045, 0.5875), "Dark"))
	for index = 1, 5 do
		local z = 0.47 - (index - 1) * 0.255
		add(box("Hazard" .. name .. index, v3(0.04, 0.3, 0.115), v3(side * 0.245, 0.045, z), "Hazard", v3(-27, 0, 0)))
	end
end

return {
	Factory = { Body = rgb(150, 20, 24), Accent = rgb(255, 40, 50) },
	View = CFrame.new(0.25, -0.35, -0.6),
	Muzzle = v3(0, 0.43, -3.63),
	Support = v3(-0.05, -0.12, -1.3),
	Parts = parts,
}
