-- Trench Gun: a long wooden pump shotgun with an exposed hammer, based on the
-- wooden pump shotgun (and its ribbed pump) in the blocky Roblox guns picture.
local Shapes = require(script.Parent.Parent.Shapes)

local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

local parts = {
	-- Wrist: a slim neck right behind the receiver (the right hand holds it)
	box("Wrist", v3(0.2, 0.2, 0.74), v3(0, -0.436, 0.36), "Wood", v3(14, 0, 0)),
	wedge("WristSwell", v3(0.2, 0.18, 0.24), v3(0, -0.59, 0.38), "Wood", v3(0, 0, 180)),
	box("GripHeel", v3(0.22, 0.15, 0.175), v3(0, -0.605, 0.5775), "Wood"),
	wedge("CombNose", v3(0.22, 0.08, 0.26), v3(0, -0.365, 0.5), "Wood"),

	-- Stock: the comb slopes down gently, the belly drops steeply to the butt
	wedge("StockComb", v3(0.26, 0.155, 1.105), v3(0, -0.4025, 1.1825), "Wood", v3(0, 180, 0)),
	box("StockBody", v3(0.26, 0.22, 1.105), v3(0, -0.58, 1.1825), "Wood"),
	wedge("StockBelly", v3(0.26, 0.395, 1.105), v3(0, -0.8775, 1.1825), "Wood", v3(0, 0, 180)),
	box("ButtPlate", v3(0.27, 0.615, 0.045), v3(0, -0.7725, 1.7575), "Gunmetal"),

	-- Tangs and the screw through the wrist
	box("TangTop", v3(0.08, 0.04, 0.22), v3(0, -0.262, 0.14), "Gunmetal", v3(15, 0, 0)),
	box("TangBottom", v3(0.08, 0.04, 0.16), v3(0, -0.509, 0.26), "Gunmetal", v3(15, 0, 0)),
	drum("TangScrew", 0.24, 0.045, v3(0, -0.36, 0.2), "Chrome"),

	-- Receiver
	box("ReceiverLower", v3(0.28, 0.211, 0.66), v3(0, -0.3455, -0.28), "Body"),
	box("ReceiverUpper", v3(0.26, 0.126, 0.575), v3(0, -0.177, -0.3225), "Body"),
	wedge("ReceiverSlope", v3(0.26, 0.126, 0.09), v3(0, -0.177, 0.01), "Body", v3(0, 180, 0)),
	box("Slide", v3(0.16, 0.04, 0.42), v3(0, -0.12, -0.34), "Gunmetal"),
	box("SightGroove", v3(0.04, 0.04, 0.36), v3(0, -0.115, -0.34), "Dark"),
	box("LoadingPort", v3(0.18, 0.04, 0.3), v3(0, -0.44, -0.4), "Dark"),
	box("EjectionPort", v3(0.04, 0.1, 0.28), v3(0.125, -0.175, -0.3), "Dark"),
	box("Bolt", v3(0.04, 0.06, 0.12), v3(0.13, -0.175, -0.25), "Metal"),
	drum("ScrewFront", 0.3, 0.045, v3(0, -0.36, -0.52), "Chrome"),
	drum("ScrewBack", 0.3, 0.045, v3(0, -0.36, -0.06), "Chrome"),
	box("TrimLeft", v3(0.04, 0.04, 0.26), v3(-0.145, -0.425, -0.3), "Accent"),
	box("TrimRight", v3(0.04, 0.04, 0.26), v3(0.145, -0.425, -0.3), "Accent"),
	tube("BarrelCollar", 0.06, 0.15, v3(0, -0.194, -0.63), "Body"),
	tube("TubeCollar", 0.06, 0.13, v3(0, -0.345, -0.63), "Gunmetal"),

	-- Hammer
	box("HammerBody", v3(0.07, 0.13, 0.05), v3(0, -0.175, 0.065), "Gunmetal", v3(22, 0, 0)),
	box("HammerSpur", v3(0.07, 0.045, 0.09), v3(0, -0.125, 0.125), "Gunmetal", v3(-20, 0, 0)),
	box("HammerTip", v3(0.07, 0.05, 0.04), v3(0, -0.12, 0.165), "Gunmetal"),

	-- Trigger guard and trigger
	box("GuardFront", v3(0.05, 0.12, 0.045), v3(0, -0.5, -0.005), "Chrome"),
	box("GuardCornerFront", v3(0.05, 0.045, 0.07), v3(0, -0.57, 0.015), "Chrome", v3(45, 0, 0)),
	box("GuardBottom", v3(0.05, 0.045, 0.1), v3(0, -0.5875, 0.085), "Chrome"),
	box("GuardCornerBack", v3(0.05, 0.045, 0.07), v3(0, -0.565, 0.152), "Chrome", v3(-45, 0, 0)),
	box("GuardBack", v3(0.05, 0.09, 0.045), v3(0, -0.51, 0.18), "Chrome", v3(15, 0, 0)),
	box("TriggerTop", v3(0.04, 0.06, 0.04), v3(0, -0.475, 0.07), "Chrome"),
	box("TriggerBottom", v3(0.04, 0.06, 0.04), v3(0, -0.53, 0.08), "Chrome", v3(20, 0, 0)),

	-- Barrel
	tube("Barrel", 2.03, 0.13, v3(0, -0.194, -1.565), "Body"),
	tube("Sleeve", 0.505, 0.16, v3(0, -0.2, -2.3925), "Body"),
	tube("Bore", 0.03, 0.08, v3(0, -0.194, -2.64), "Dark"),
	ball("Bead", 0.05, v3(0, -0.105, -2.6), "Accent"),
	box("BayonetLug", v3(0.08, 0.06, 0.13), v3(0, -0.3, -2.56), "Gunmetal"),
	egg("BayonetLugEnd", v3(0.08, 0.08, 0.14), v3(0, -0.34, -2.565), "Gunmetal"),

	-- Magazine tube and its front bracket
	tube("MagTube", 1.55, 0.105, v3(0, -0.345, -1.385), "Gunmetal"),
	box("Bracket", v3(0.1, 0.2, 0.1), v3(0, -0.33, -2.19), "Gunmetal"),
	box("BracketLug", v3(0.07, 0.1, 0.07), v3(0, -0.45, -2.195), "Gunmetal"),
	egg("BracketFoot", v3(0.08, 0.06, 0.1), v3(0, -0.495, -2.18), "Gunmetal"),

	-- Pump (wooden, ribbed)
	tube("Pump", 0.8, 0.19, v3(0, -0.35, -1.425), "Wood"),
	egg("PumpBack", v3(0.2, 0.2, 0.08), v3(0, -0.35, -1.025), "Wood"),
	egg("PumpFront", v3(0.2, 0.2, 0.08), v3(0, -0.35, -1.825), "Wood"),
	box("ActionBar", v3(0.04, 0.05, 0.44), v3(0.065, -0.315, -0.81), "Metal"),
}

-- Ribs around the pump, with grooves between them
for index = 1, 8 do
	table.insert(parts, tube("PumpRib" .. index, 0.07, 0.215, v3(0, -0.35, -1.075 - (index - 1) * 0.1), "Wood"))
end

return {
	Factory = { Body = rgb(46, 48, 55), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.12, -0.95),
	Muzzle = v3(0, -0.194, -2.655),
	Support = v3(-0.02, -0.485, -1.42),
	Parts = parts,
}
