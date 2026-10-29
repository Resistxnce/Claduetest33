-- Pump Shotgun: a black pump-action shotgun with a pistol grip, based on the
-- black pump shotgun in the blocky Roblox guns picture.
local Shapes = require(script.Parent.Parent.Shapes)

local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

local parts = {
	-- Receiver (long, with a rounded top)
	box("Receiver", v3(0.28, 0.38, 1.35), v3(0, -0.02, -0.675), "Body"),
	tube("RoofLeft", 1.35, 0.12, v3(-0.08, 0.17, -0.675), "Body"),
	tube("RoofRight", 1.35, 0.12, v3(0.08, 0.17, -0.675), "Body"),
	box("RoofMiddle", v3(0.16, 0.07, 1.35), v3(0, 0.195, -0.675), "Body"),
	box("EjectionPort", v3(0.04, 0.12, 0.4), v3(0.125, 0.07, -0.9), "Dark"),
	box("Bolt", v3(0.04, 0.07, 0.24), v3(0.13, 0.07, -0.86), "Gunmetal"),
	box("LoadingPort", v3(0.18, 0.04, 0.5), v3(0, -0.2, -0.75), "Dark"),
	drum("PinFront", 0.3, 0.05, v3(0, -0.14, -0.36), "Gunmetal"),
	drum("PinBack", 0.3, 0.05, v3(0, -0.14, -0.08), "Gunmetal"),
	box("Safety", v3(0.05, 0.04, 0.07), v3(0, 0.215, -0.1), "Accent"),
	box("ActionRelease", v3(0.04, 0.05, 0.09), v3(-0.15, -0.17, -0.3), "Gunmetal"),

	-- Comb (the smooth hump that runs from the receiver down into the grip)
	egg("Comb", v3(0.276, 0.32, 0.76), v3(0, 0.045, 0.11), "Body", v3(15, 0, 0)),
	box("CombBody", v3(0.24, 0.21, 0.3), v3(0, -0.105, 0.13), "Body"),
	wedge("CombUnder", v3(0.2, 0.13, 0.13), v3(0, -0.14, 0.37), "Body", v3(180, 0, 0)),

	-- Pistol grip
	box("Grip", v3(0.22, 0.47, 0.18), v3(0, -0.344, 0.251), "Body", v3(-23, 0, 0)),
	egg("GripFront", v3(0.22, 0.5, 0.1), v3(0, -0.375, 0.177), "Body", v3(-23, 0, 0)),
	egg("GripBack", v3(0.22, 0.5, 0.1), v3(0, -0.313, 0.325), "Body", v3(-23, 0, 0)),
	box("GripPanelLeft", v3(0.04, 0.3, 0.19), v3(-0.1, -0.43, 0.29), "Rubber", v3(-23, 0, 0)),
	box("GripPanelRight", v3(0.04, 0.3, 0.19), v3(0.1, -0.43, 0.29), "Rubber", v3(-23, 0, 0)),
	drum("GripScrew", 0.26, 0.045, v3(0, -0.43, 0.29), "Gunmetal"),
	box("GripBase", v3(0.235, 0.09, 0.26), v3(0, -0.555, 0.34), "Body", v3(-10, 0, 0)),

	-- Trigger guard and trigger
	box("GuardBottom", v3(0.05, 0.045, 0.32), v3(0, -0.33, -0.05), "Chrome"),
	box("GuardFront", v3(0.05, 0.14, 0.045), v3(0, -0.27, -0.235), "Chrome", v3(-25, 0, 0)),
	drum("GuardCorner", 0.05, 0.065, v3(0, -0.32, -0.2), "Chrome"),
	box("Trigger", v3(0.04, 0.1, 0.04), v3(0, -0.255, -0.05), "Chrome", v3(15, 0, 0)),

	-- Barrel
	tube("Barrel", 2.12, 0.15, v3(0, 0.102, -2.34), "Dark"),
	tube("BarrelCollar", 0.1, 0.185, v3(0, 0.102, -1.4), "Dark"),
	tube("Crown", 0.04, 0.13, v3(0, 0.102, -3.41), "Gunmetal"),
	box("SightBlade", v3(0.06, 0.07, 0.1), v3(0, 0.205, -3.355), "Dark"),
	wedge("SightRamp", v3(0.06, 0.06, 0.07), v3(0, 0.2, -3.27), "Dark", v3(0, 180, 0)),
	ball("Bead", 0.055, v3(0, 0.25, -3.38), "Accent"),

	-- Magazine tube
	tube("MagTube", 1.85, 0.105, v3(0, -0.095, -2.225), "Dark"),
	tube("MagCollar", 0.08, 0.135, v3(0, -0.095, -1.39), "Dark"),
	tube("MagCap", 0.06, 0.125, v3(0, -0.095, -3.15), "Gunmetal"),
	egg("MagCapEnd", v3(0.115, 0.115, 0.07), v3(0, -0.095, -3.18), "Gunmetal"),
	box("BarrelBand", v3(0.06, 0.13, 0.07), v3(0, 0, -3.09), "Gunmetal"),
	tube("BandRing", 0.07, 0.13, v3(0, -0.095, -3.09), "Gunmetal"),

	-- Action bars (from the pump back into the receiver)
	box("ActionBarLeft", v3(0.04, 0.04, 0.5), v3(-0.065, -0.095, -1.55), "Gunmetal"),
	box("ActionBarRight", v3(0.04, 0.04, 0.5), v3(0.065, -0.095, -1.55), "Gunmetal"),

	-- Pump (ribbed slide on the magazine tube)
	tube("Pump", 0.86, 0.22, v3(0, -0.095, -2.21), "Rubber"),
	egg("PumpBack", v3(0.22, 0.22, 0.14), v3(0, -0.095, -1.78), "Rubber"),
	egg("PumpFront", v3(0.22, 0.22, 0.14), v3(0, -0.095, -2.64), "Rubber"),
}

-- Pump ribs
for index = 0, 10 do
	table.insert(parts, tube("PumpRib" .. index + 1, 0.045, 0.245, v3(0, -0.095, -1.88 - index * 0.07), "Dark"))
end

return {
	Factory = { Body = rgb(30, 31, 34), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.05, -0.6),
	Muzzle = v3(0, 0.102, -3.43),
	Support = v3(0, -0.21, -2.21),
	Parts = parts,
}
