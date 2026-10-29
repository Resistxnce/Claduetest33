-- Pulse Rifle: the white-and-silver sci-fi rifle from the gun wall picture, with
-- a folding stock, a long top beam scope and a big round muzzle shroud.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(215, 218, 222), Accent = rgb(60, 230, 255), Material = Enum.Material.SmoothPlastic },
	View = CFrame.new(0, 0.05, -0.9),
	Muzzle = v3(0, -0.1025, -2.685),
	Support = v3(-0.04, -0.27, -1.3),
	Parts = {
		-- Butt, tilted back a little like the picture
		box("ButtPad", v3(0.27, 0.6, 0.21), v3(0, -0.09, 1.44), "Rubber", v3(-5, 0, 0)),
		wedge("ButtTop", v3(0.27, 0.05, 0.21), v3(0, 0.234, 1.412), "Rubber", v3(-5, 180, 0)),
		box("ButtFrame", v3(0.25, 0.44, 0.14), v3(0, 0, 1.29), "Metal", v3(-5, 0, 0)),
		box("ButtTab", v3(0.14, 0.09, 0.1), v3(0, 0.25, 1.27), "Metal"),
		drum("HingeBolt", 0.18, 0.05, v3(0, 0.25, 1.27), "Chrome"),
		drum("FrameBolt", 0.27, 0.045, v3(0, -0.12, 1.29), "Chrome"),
		box("ButtToe", v3(0.1, 0.05, 0.08), v3(0, -0.205, 1.24), "Gunmetal"),

		-- Folding stock arm
		tube("StockRod", 0.34, 0.14, v3(0, -0.025, 1.08), "Body"),
		tube("StockTube", 0.46, 0.17, v3(0, -0.023, 0.71), "Body"),
		tube("StockCollar", 0.05, 0.19, v3(0, -0.023, 0.94), "Gunmetal"),
		box("StrutLeft", v3(0.05, 0.32, 0.12), v3(-0.1, 0.03, 0.84), "Metal", v3(-15, 0, 0)),
		box("StrutRight", v3(0.05, 0.32, 0.12), v3(0.1, 0.03, 0.84), "Metal", v3(-15, 0, 0)),
		box("StrutHead", v3(0.25, 0.1, 0.2), v3(0, 0.215, 0.77), "Metal"),
		drum("HingePin", 0.28, 0.05, v3(0, -0.06, 0.865), "Chrome"),
		tube("RearRod", 0.24, 0.06, v3(0, 0.215, 0.56), "Body"),

		-- Receiver
		box("Receiver", v3(0.3, 0.215, 1.57), v3(0, -0.0425, -0.285), "Metal"),
		box("ReceiverTop", v3(0.28, 0.035, 1.2), v3(0, 0.08, -0.12), "Metal"),
		wedge("ReceiverTopRamp", v3(0.28, 0.035, 0.1), v3(0, 0.08, -0.77), "Metal"),
		box("Rail", v3(0.15, 0.04, 0.82), v3(0, 0.11, 0.04), "Gunmetal"),
		box("SidePanelRear", v3(0.31, 0.11, 0.42), v3(0, -0.03, 0.2), "Gunmetal"),
		box("SidePanelFront", v3(0.31, 0.13, 0.3), v3(0, -0.06, -0.86), "Gunmetal"),
		box("LowerReceiver", v3(0.26, 0.065, 0.64), v3(0, -0.1425, 0.38), "Metal"),
		wedge("LowerFrontRamp", v3(0.28, 0.1, 0.06), v3(0, -0.19, -0.105), "Metal", v3(180, 0, 0)),
		box("LowerFront", v3(0.28, 0.12, 0.24), v3(0, -0.196, -0.255), "Metal"),
		box("Magwell", v3(0.28, 0.17, 0.69), v3(0, -0.22, -0.715), "Metal"),
		box("MagwellLip", v3(0.3, 0.04, 0.45), v3(0, -0.315, -0.605), "Gunmetal"),
		box("FrontSightBlock", v3(0.12, 0.06, 0.14), v3(0, 0.08, -1.13), "Gunmetal"),
		box("EjectionPort", v3(0.04, 0.07, 0.28), v3(0.14, 0.01, -0.4), "Dark"),
		box("ChargingHandle", v3(0.06, 0.05, 0.12), v3(0.17, 0.03, 0.4), "Gunmetal"),
		box("Selector", v3(0.32, 0.04, 0.09), v3(0, -0.12, 0.12), "Gunmetal", v3(30, 0, 0)),
		drum("MagRelease", 0.3, 0.05, v3(0, -0.2, -0.3), "Chrome"),
		drum("Screw1", 0.32, 0.045, v3(0, -0.035, 0.43), "Chrome"),
		drum("Screw2", 0.32, 0.045, v3(0, -0.035, 0.3), "Chrome"),
		drum("Screw3", 0.32, 0.045, v3(0, -0.035, -0.13), "Chrome"),
		drum("Screw4", 0.32, 0.045, v3(0, -0.03, -0.72), "Chrome"),
		drum("Screw5", 0.32, 0.045, v3(0, -0.12, -0.74), "Chrome"),
		drum("Screw6", 0.3, 0.045, v3(0, -0.25, -0.98), "Chrome"),
		drum("Screw7", 0.32, 0.045, v3(0, -0.06, -0.99), "Chrome"),

		-- Top beam and scope
		tube("ScopeTube", 1.76, 0.08, v3(0, 0.21, -0.42), "Gunmetal"),
		tube("ScopeBody", 0.56, 0.16, v3(0, 0.235, -0.08), "Metal"),
		tube("EyeRing", 0.04, 0.175, v3(0, 0.235, 0.2), "Gunmetal"),
		tube("ObjectiveRing", 0.04, 0.175, v3(0, 0.235, -0.36), "Gunmetal"),
		tube("ScopeEyeLens", 0.03, 0.07, v3(0, 0.27, 0.225), "Lens"),
		drum("ScopeKnob", 0.22, 0.07, v3(0, 0.235, -0.08), "Gunmetal"),
		box("ScopeMount", v3(0.14, 0.09, 0.5), v3(0, 0.14, -0.09), "Metal"),
		box("MountPost", v3(0.1, 0.09, 0.08), v3(0, 0.14, 0.36), "Metal"),
		tube("ScopeRing1", 0.04, 0.095, v3(0, 0.21, -0.6), "Gunmetal"),
		tube("ScopeRing2", 0.04, 0.095, v3(0, 0.21, -0.92), "Chrome"),
		tube("ScopeEnd", 0.05, 0.1, v3(0, 0.21, -1.29), "Gunmetal"),
		tube("FrontRod", 0.52, 0.07, v3(0, 0.21, -1.54), "Body"),
		box("BracketHead", v3(0.12, 0.08, 0.24), v3(0, 0.21, -1.88), "Metal"),
		egg("BracketNose", v3(0.12, 0.08, 0.1), v3(0, 0.21, -2), "Metal"),
		box("BracketArm", v3(0.12, 0.32, 0.1), v3(0, 0.06, -1.74), "Metal", v3(-15, 0, 0)),
		drum("BracketPin", 0.16, 0.045, v3(0, 0.21, -1.84), "Chrome"),

		-- Handguard
		box("HandguardUpper", v3(0.3, 0.125, 0.59), v3(0, -0.0125, -1.365), "Body"),
		box("HandguardLower", v3(0.29, 0.17, 0.49), v3(0, -0.16, -1.315), "Body"),
		box("HandguardRib", v3(0.305, 0.04, 0.4), v3(0, -0.13, -1.31), "White"),
		box("VentSlot", v3(0.31, 0.04, 0.08), v3(0, -0.02, -1.215), "Accent"),
		box("Vent1", v3(0.3, 0.04, 0.05), v3(0, -0.19, -1.2), "Dark"),
		box("Vent2", v3(0.3, 0.04, 0.05), v3(0, -0.19, -1.29), "Dark"),
		box("Vent3", v3(0.3, 0.04, 0.05), v3(0, -0.19, -1.38), "Dark"),
		box("Clamp", v3(0.28, 0.18, 0.16), v3(0, -0.165, -1.65), "Gunmetal"),
		drum("ClampBolt1", 0.3, 0.045, v3(0, -0.12, -1.65), "Chrome"),
		drum("ClampBolt2", 0.3, 0.045, v3(0, -0.21, -1.65), "Chrome"),

		-- Muzzle shroud
		tube("Shroud", 0.71, 0.31, v3(0, -0.115, -2.025), "Metal"),
		tube("ShroudFront", 0.25, 0.285, v3(0, -0.1025, -2.505), "Metal"),
		tube("ShroudRing", 0.04, 0.32, v3(0, -0.115, -2.37), "Gunmetal"),
		box("ShroudCover", v3(0.33, 0.115, 0.42), v3(0, -0.0175, -1.98), "Body"),
		box("CoverLip", v3(0.33, 0.05, 0.07), v3(0, -0.095, -2.145), "Body"),
		box("ShroudVent1", v3(0.295, 0.05, 0.08), v3(0, -0.1025, -2.44), "Dark"),
		box("ShroudVent2", v3(0.295, 0.05, 0.08), v3(0, -0.1025, -2.5), "Dark"),
		box("ShroudVent3", v3(0.295, 0.05, 0.08), v3(0, -0.1025, -2.56), "Dark"),
		tube("MuzzleCap", 0.04, 0.255, v3(0, -0.1025, -2.645), "Gunmetal"),
		tube("MuzzleBore", 0.04, 0.16, v3(0, -0.1025, -2.655), "Dark"),
		tube("MuzzleCore", 0.04, 0.08, v3(0, -0.1025, -2.66), "Accent"),

		-- Grip and trigger
		box("Grip", v3(0.24, 0.51, 0.26), v3(0, -0.395, 0.342), "Gunmetal", v3(-17, 0, 0)),
		box("GripPanel", v3(0.25, 0.32, 0.18), v3(0, -0.42, 0.355), "Rubber", v3(-17, 0, 0)),
		box("GripBase", v3(0.26, 0.08, 0.27), v3(0, -0.64, 0.415), "Gunmetal"),
		box("Trigger", v3(0.05, 0.24, 0.045), v3(0, -0.31, 0.13), "Dark", v3(12, 0, 0)),
		box("GuardFront", v3(0.06, 0.29, 0.07), v3(0, -0.275, 0.01), "Gunmetal"),
		box("GuardMid", v3(0.06, 0.19, 0.07), v3(0, -0.47, 0.065), "Gunmetal", v3(-41, 0, 0)),
		box("GuardLow", v3(0.06, 0.2, 0.07), v3(0, -0.594, 0.19), "Gunmetal", v3(-49, 0, 0)),

		-- Magazine
		box("Magazine", v3(0.2, 0.42, 0.25), v3(0, -0.495, -0.68), "Gunmetal", v3(-4, 0, 0)),
		box("MagBase", v3(0.22, 0.04, 0.27), v3(0, -0.69, -0.666), "Dark", v3(-4, 0, 0)),
		box("MagCell", v3(0.21, 0.04, 0.16), v3(0, -0.6, -0.672), "Accent", v3(-4, 0, 0)),
	},
}
