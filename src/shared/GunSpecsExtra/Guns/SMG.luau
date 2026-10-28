-- SMG: a new look for the game's SMG, built like the side-magazine submachine
-- gun in the Inspiration picture (a Sten-style tube gun with a holed barrel jacket).
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

-- A round hole through the barrel jacket: a dark rod running right through the
-- tube at an angle around Z, so it shows as a hole on both sides at once
local function hole(name, z, angle)
	return {
		Name = name,
		Size = v3(0.27, 0.065, 0.065),
		Offset = CFrame.new(0, 0, z) * CFrame.Angles(0, 0, math.rad(angle)),
		Role = "Dark",
		Shape = Enum.PartType.Cylinder,
	}
end

local parts = {
	-- Receiver tube and end cap
	tube("Receiver", 0.84, 0.26, v3(0, 0, -0.16), "Body"),
	tube("CapRing", 0.05, 0.34, v3(0, 0, 0.215), "Gunmetal"),
	tube("Flange", 0.06, 0.46, v3(0, 0, 0.27), "Dark"),
	ball("EndCap", 0.42, v3(0, 0, 0.37), "Chrome"),
	tube("CapButton", 0.05, 0.12, v3(0, 0, 0.6), "Gunmetal"),
	drum("SwivelRear", 0.04, 0.09, v3(-0.175, -0.05, 0.215), "Gunmetal"),

	-- Barrel jacket
	tube("BarrelNut", 0.07, 0.3, v3(0, 0, -0.58), "Gunmetal"),
	tube("Shroud", 1.06, 0.26, v3(0, 0, -1.12), "Body"),
	tube("MuzzleCollar", 0.06, 0.29, v3(0, 0, -1.66), "Gunmetal"),
	tube("Barrel", 0.08, 0.12, v3(0, 0, -1.71), "Metal"),
	tube("Bore", 0.04, 0.06, v3(0, 0, -1.735), "Dark"),
	drum("SwivelFront", 0.04, 0.09, v3(0.145, -0.05, -1.59), "Gunmetal"),

	-- Magazine housing on the left side
	box("MagHousing", v3(0.28, 0.2, 0.33), v3(-0.2, 0, -0.41), "Body"),
	box("HousingLip", v3(0.05, 0.23, 0.36), v3(-0.335, 0, -0.41), "Gunmetal"),
	box("MagCatch", v3(0.08, 0.06, 0.06), v3(-0.26, 0, -0.22), "Gunmetal"),
	box("HousingGlow", v3(0.2, 0.04, 0.04), v3(-0.2, 0.105, -0.41), "Accent"),

	-- Curved stick magazine
	box("MagStraight", v3(0.38, 0.12, 0.28), v3(-0.49, 0, -0.41), "Body"),
	box("MagBendA", v3(0.17, 0.12, 0.28), v3(-0.728, 0, -0.425), "Body", v3(0, -12, 0)),
	box("MagBendB", v3(0.17, 0.12, 0.28), v3(-0.86, 0, -0.47), "Body", v3(0, -26, 0)),
	box("MagBendC", v3(0.17, 0.12, 0.28), v3(-0.976, 0, -0.545), "Body", v3(0, -40, 0)),
	box("MagFloor", v3(0.05, 0.15, 0.31), v3(-1.041, 0, -0.601), "Gunmetal", v3(0, -44, 0)),
	box("MagRib", v3(0.34, 0.04, 0.06), v3(-0.5, 0.07, -0.41), "Gunmetal"),

	-- Cocking slot, handle and ejection port on the right side
	box("CockSlot", v3(0.04, 0.05, 0.46), v3(0.12, 0, -0.07), "Dark"),
	box("SafetyNotch", v3(0.04, 0.08, 0.05), v3(0.11, 0.04, 0.14), "Dark"),
	box("CockStem", v3(0.07, 0.04, 0.04), v3(0.16, 0, -0.26), "Metal"),
	drum("CockKnob", 0.1, 0.08, v3(0.23, 0, -0.26), "Metal"),
	box("EjectPort", v3(0.04, 0.12, 0.2), v3(0.115, 0, -0.42), "Dark"),

	-- Trigger housing, trigger and grip
	box("TriggerHousing", v3(0.16, 0.14, 0.42), v3(0, -0.16, 0.09), "Body"),
	wedge("HousingNose", v3(0.16, 0.14, 0.1), v3(0, -0.16, -0.17), "Body", v3(0, 0, 180)),
	drum("HousingPin", 0.18, 0.04, v3(0, -0.17, -0.06), "Metal"),
	drum("Selector", 0.2, 0.05, v3(0, -0.15, 0.2), "Gunmetal"),
	box("Trigger", v3(0.04, 0.12, 0.04), v3(0, -0.28, 0.03), "Metal", v3(-15, 0, 0)),
	box("GuardFront", v3(0.05, 0.16, 0.04), v3(0, -0.3, -0.1), "Metal"),
	box("GuardBottom", v3(0.05, 0.04, 0.28), v3(0, -0.38, 0.03), "Metal"),
	box("Grip", v3(0.18, 0.5, 0.24), v3(0, -0.42, 0.3), "Grip", v3(-14, 0, 0)),
	box("GripPanelLeft", v3(0.04, 0.34, 0.16), v3(-0.08, -0.44, 0.305), "Rubber", v3(-14, 0, 0)),
	box("GripPanelRight", v3(0.04, 0.34, 0.16), v3(0.08, -0.44, 0.305), "Rubber", v3(-14, 0, 0)),
	drum("GripScrew", 0.22, 0.05, v3(0, -0.44, 0.305), "Metal"),
	box("GripCap", v3(0.2, 0.05, 0.26), v3(0, -0.665, 0.36), "Dark", v3(-14, 0, 0)),

	-- Skeleton loop stock
	tube("StockTop", 0.54, 0.07, v3(0, 0, 0.87), "Metal"),
	tube("StockBottom", 0.7, 0.07, v3(0, -0.5, 0.79), "Metal"),
	disc("ButtBar", 0.62, 0.07, v3(0, -0.25, 1.13), "Metal"),
	ball("StockCornerTop", 0.1, v3(0, 0, 1.13), "Metal"),
	ball("StockCornerBottom", 0.1, v3(0, -0.5, 1.13), "Metal"),
	box("ButtPad", v3(0.1, 0.66, 0.05), v3(0, -0.25, 1.17), "Rubber"),

	-- Sights
	box("RearSightBase", v3(0.14, 0.05, 0.14), v3(0, 0.145, 0.1), "Body"),
	wedge("RearRamp", v3(0.14, 0.05, 0.08), v3(0, 0.145, -0.01), "Body"),
	box("RearEarLeft", v3(0.04, 0.08, 0.1), v3(-0.05, 0.21, 0.1), "Body"),
	box("RearEarRight", v3(0.04, 0.08, 0.1), v3(0.05, 0.21, 0.1), "Body"),
	box("RearDot", v3(0.04, 0.04, 0.04), v3(0, 0.19, 0.1), "Accent"),
	box("FrontSightBase", v3(0.08, 0.05, 0.07), v3(0, 0.15, -1.6), "Body"),
	wedge("FrontRamp", v3(0.08, 0.05, 0.08), v3(0, 0.15, -1.525), "Body", v3(0, 180, 0)),
	box("FrontBlade", v3(0.04, 0.1, 0.04), v3(0, 0.22, -1.6), "Body"),
	box("FrontDot", v3(0.04, 0.04, 0.04), v3(0, 0.28, -1.6), "Accent"),
}

-- Staggered rows of holes all round the jacket
for i = 0, 17 do
	local z = -0.665 - i * 0.05
	if i % 2 == 0 then
		table.insert(parts, hole(`HoleUp{i}`, z, 40))
		table.insert(parts, hole(`HoleDown{i}`, z, -40))
	else
		table.insert(parts, hole(`HoleSide{i}`, z, 0))
		table.insert(parts, hole(`HoleTop{i}`, z, 90))
	end
end

return {
	Factory = { Body = rgb(40, 41, 44), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0, -0.35),
	Muzzle = v3(0, 0, -1.75),
	Support = v3(-0.03, -0.14, -0.95),
	Parts = parts,
}
