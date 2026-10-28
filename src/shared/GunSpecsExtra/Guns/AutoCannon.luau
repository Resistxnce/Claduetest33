-- Auto Cannon: a heavy handheld cannon, based on the big rounded cannon in the
-- gun wall picture (brass shells on top, round drum housing, clamped barrels).
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(60, 62, 66), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0.15, -0.25, -0.85),
	Muzzle = v3(0, 0.3, -2.58),
	Support = v3(-0.02, -0.15, -0.6),
	Parts = {
		-- Receiver, with rounded long edges
		box("Receiver", v3(0.3, 0.815, 1.7), v3(0, 0.2675, 0.9), "Body"),
		box("ReceiverWide", v3(0.5, 0.615, 1.7), v3(0, 0.2675, 0.9), "Body"),
		tube("EdgeTopRight", 1.7, 0.2, v3(0.15, 0.575, 0.9), "Body"),
		tube("EdgeTopLeft", 1.7, 0.2, v3(-0.15, 0.575, 0.9), "Body"),
		tube("EdgeBottomRight", 1.7, 0.2, v3(0.15, -0.04, 0.9), "Body"),
		tube("EdgeBottomLeft", 1.7, 0.2, v3(-0.15, -0.04, 0.9), "Body"),
		box("SeamRight", v3(0.04, 0.04, 1.6), v3(0.24, 0, 1.15), "Dark"),
		box("SeamLeft", v3(0.04, 0.04, 1.6), v3(-0.24, 0, 1.15), "Dark"),

		-- Rear block with a rounded back and inset panels
		box("RearBlock", v3(0.5, 0.735, 0.35), v3(0, 0.2675, 1.925), "Body"),
		drum("RearTopRound", 0.5, 0.2, v3(0, 0.535, 2.1), "Body"),
		drum("RearBottomRound", 0.5, 0.2, v3(0, 0, 2.1), "Body"),
		box("RearFace", v3(0.5, 0.335, 0.1), v3(0, 0.2675, 2.15), "Body"),
		box("RearRecess", v3(0.32, 0.36, 0.04), v3(0, 0.28, 2.2), "Gunmetal"),
		box("RearSlot", v3(0.2, 0.22, 0.04), v3(0, 0.28, 2.215), "Dark"),
		box("RearPanelRight", v3(0.04, 0.44, 0.28), v3(0.24, 0.31, 1.99), "Dark"),
		box("RearPanelLeft", v3(0.04, 0.44, 0.28), v3(-0.24, 0.31, 1.99), "Dark"),
		box("RearPlateRight", v3(0.04, 0.36, 0.2), v3(0.25, 0.31, 1.99), "Body"),
		box("RearPlateLeft", v3(0.04, 0.36, 0.2), v3(-0.25, 0.31, 1.99), "Body"),
		drum("BoltRearTop", 0.54, 0.05, v3(0, 0.56, 1.8), "Metal"),
		drum("BoltRearLow", 0.54, 0.05, v3(0, 0.06, 1.8), "Metal"),

		-- Shells feeding in on top
		box("FeedWell", v3(0.51, 0.53, 0.7), v3(0, 0.415, 1.12), "Dark"),
		disc("ShellRight1", 0.46, 0.1, v3(0.235, 0.42, 0.88), "Brass"),
		disc("ShellRight2", 0.46, 0.1, v3(0.235, 0.42, 1), "Brass"),
		disc("ShellRight3", 0.46, 0.1, v3(0.235, 0.42, 1.12), "Brass"),
		disc("ShellRight4", 0.46, 0.1, v3(0.235, 0.42, 1.24), "Brass"),
		disc("ShellRight5", 0.46, 0.1, v3(0.235, 0.42, 1.36), "Brass"),
		disc("ShellLeft1", 0.46, 0.1, v3(-0.235, 0.42, 0.88), "Brass"),
		disc("ShellLeft2", 0.46, 0.1, v3(-0.235, 0.42, 1), "Brass"),
		disc("ShellLeft3", 0.46, 0.1, v3(-0.235, 0.42, 1.12), "Brass"),
		disc("ShellLeft4", 0.46, 0.1, v3(-0.235, 0.42, 1.24), "Brass"),
		disc("ShellLeft5", 0.46, 0.1, v3(-0.235, 0.42, 1.36), "Brass"),
		box("ShellBelt", v3(0.4, 0.07, 0.69), v3(0, 0.695, 1.345), "Brass"),
		box("BeltLink1", v3(0.42, 0.04, 0.05), v3(0, 0.72, 1.12), "Dark"),
		box("BeltLink2", v3(0.42, 0.04, 0.05), v3(0, 0.72, 1.36), "Dark"),
		box("BeltLink3", v3(0.42, 0.04, 0.05), v3(0, 0.72, 1.6), "Dark"),

		-- Drum housing
		drum("Drum", 0.5, 0.9, v3(0, 0.55, 0.5), "Body"),
		drum("DrumFront", 0.46, 0.8, v3(0, 0.55, 0.32), "Body"),
		drum("DrumGroove", 0.53, 0.78, v3(0, 0.56, 0.6), "Dark"),
		drum("DrumFace", 0.545, 0.7, v3(0, 0.56, 0.6), "Body"),
		drum("DrumHub", 0.58, 0.26, v3(0, 0.56, 0.6), "Metal"),
		drum("DrumLight", 0.6, 0.08, v3(0, 0.56, 0.6), "Accent"),
		drum("DrumBoltTop", 0.565, 0.05, v3(0, 0.81, 0.6), "Metal"),
		drum("DrumBoltBottom", 0.565, 0.05, v3(0, 0.31, 0.6), "Metal"),
		drum("DrumBoltFront", 0.565, 0.05, v3(0, 0.56, 0.35), "Metal"),
		drum("DrumBoltBack", 0.565, 0.05, v3(0, 0.56, 0.85), "Metal"),
		box("ChargingHandle", v3(0.06, 0.06, 0.22), v3(-0.27, 0.08, 0.5), "Metal"),
		drum("ChargingKnob", 0.08, 0.1, v3(-0.32, 0.08, 0.42), "Dark"),

		-- Front housing: rounded cowls stepping down to the barrels
		box("HousingBase", v3(0.52, 0.39, 0.85), v3(0, 0.105, -0.375), "Body"),
		wedge("HousingBaseNose", v3(0.52, 0.39, 0.15), v3(0, 0.105, -0.875), "Body"),
		egg("Rib1", v3(0.5, 0.8, 0.55), v3(0, 0.3, -0.125), "Body"),
		egg("Rib2", v3(0.48, 0.68, 0.7), v3(0, 0.3, -0.25), "Body"),
		egg("Rib3", v3(0.44, 0.56, 0.8), v3(0, 0.3, -0.4), "Body"),
		egg("Nose", v3(0.38, 0.44, 0.78), v3(0, 0.3, -0.59), "Body"),
		box("LowerPlate", v3(0.4, 0.14, 1), v3(0, -0.02, -0.45), "Body"),
		wedge("LowerPlateNose", v3(0.4, 0.14, 0.08), v3(0, -0.02, -0.99), "Body"),
		box("StripRight", v3(0.04, 0.04, 0.6), v3(0.27, -0.02, -0.4), "Accent"),
		box("StripLeft", v3(0.04, 0.04, 0.6), v3(-0.27, -0.02, -0.4), "Accent"),
		drum("BoltHousingBack", 0.56, 0.05, v3(0, 0.18, -0.12), "Metal"),
		drum("BoltHousingFront", 0.56, 0.05, v3(0, 0.18, -0.66), "Metal"),

		-- Barrels and clamp
		tube("BarrelTop", 0.8, 0.15, v3(0, 0.395, -1.2), "Metal"),
		tube("BarrelRight", 0.8, 0.17, v3(0.08, 0.22, -1.2), "Metal"),
		tube("BarrelLeft", 0.8, 0.17, v3(-0.08, 0.22, -1.2), "Metal"),
		box("BarrelWeb", v3(0.1, 0.2, 0.6), v3(0, 0.3, -1.1), "Dark"),
		egg("Clamp", v3(0.38, 0.46, 0.56), v3(0, 0.305, -1.49), "Body"),
		tube("ClampRing", 0.05, 0.3, v3(0, 0.305, -1.76), "Gunmetal"),
		box("ClampGroove", v3(0.39, 0.04, 0.5), v3(0, 0.3, -1.49), "Dark"),
		box("ClampLip", v3(0.14, 0.06, 0.1), v3(0, 0.47, -1.74), "Body"),
		tube("TipTop", 0.5, 0.09, v3(0, 0.36, -1.85), "Metal"),
		tube("TipLow", 0.25, 0.075, v3(0, 0.22, -1.835), "Metal"),

		-- Muzzle brake
		box("Brake", v3(0.36, 0.375, 0.42), v3(0, 0.22, -2.36), "Body"),
		box("BrakeBack", v3(0.32, 0.2, 0.17), v3(0, 0.305, -2.065), "Body"),
		wedge("BrakeBevel", v3(0.32, 0.17, 0.17), v3(0, 0.12, -2.065), "Body", v3(180, 0, 0)),
		wedge("BrakeHumpSlope", v3(0.3, 0.08, 0.18), v3(0, 0.445, -2.1), "Body", v3(0, 180, 0)),
		box("BrakeHump", v3(0.3, 0.08, 0.09), v3(0, 0.445, -2.235), "Body"),
		box("BrakeVentTop", v3(0.37, 0.05, 0.28), v3(0, 0.29, -2.37), "Dark"),
		box("BrakeVentLow", v3(0.37, 0.05, 0.28), v3(0, 0.15, -2.37), "Dark"),
		tube("Bore", 0.04, 0.16, v3(0, 0.3, -2.575), "Dark"),

		-- Grip
		box("GripMount", v3(0.28, 0.14, 0.42), v3(0, -0.2, 0.25), "Body"),
		wedge("GripFront", v3(0.28, 0.13, 0.18), v3(0, -0.335, 0.08), "Body", v3(180, 0, 0)),
		box("Grip", v3(0.28, 0.42, 0.48), v3(0, -0.43, 0.31), "Body", v3(-35, 0, 0)),
		box("TriggerWell", v3(0.3, 0.22, 0.12), v3(0, -0.495, 0.194), "Dark", v3(-35, 0, 0)),
		box("Trigger", v3(0.31, 0.12, 0.05), v3(0, -0.5, 0.2), "Wood", v3(-35, 0, 0)),
		box("GripPad", v3(0.3, 0.05, 0.5), v3(0, -0.622, 0.445), "Rubber", v3(-35, 0, 0)),
	},
}
