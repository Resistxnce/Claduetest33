-- Marksman Rifle: a tan semi-auto rifle with a tall stock, a scope on two rings, a vented
-- handguard, a folded bipod and a muzzle brake, based on the tan scoped rifle in the blocky gun picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(196, 178, 140), Accent = rgb(96, 100, 108) }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.05, -1),
	Muzzle = v3(0, 0.2, -3.0),
	Support = v3(-0.04, -0.1, -1.15),
	Parts = {
		-- Receiver
		box("UpperReceiver", v3(0.3, 0.225, 1.2), v3(0, 0.1875, 0), "Body"),
		box("LowerReceiver", v3(0.28, 0.225, 0.68), v3(0, -0.0375, 0.24), "Body"),
		box("MagWell", v3(0.3, 0.365, 0.52), v3(0, -0.1075, -0.33), "Body"),
		box("MagWellLip", v3(0.32, 0.05, 0.54), v3(0, -0.265, -0.33), "Body"),
		box("EjectionPort", v3(0.04, 0.08, 0.26), v3(0.145, 0.18, -0.06), "Gunmetal"),
		wedge("BrassDeflector", v3(0.06, 0.1, 0.1), v3(0.16, 0.2, 0.15), "Body", v3(0, 180, 0)),
		tube("ForwardAssist", 0.14, 0.08, v3(0.16, 0.19, 0.28), "Body"),
		box("BoltRelease", v3(0.04, 0.12, 0.06), v3(-0.145, -0.01, -0.03), "Dark"),
		drum("Selector", 0.3, 0.08, v3(0, -0.06, 0.44), "Dark"),
		drum("MagRelease", 0.04, 0.07, v3(0.15, -0.06, -0.02), "Dark"),
		drum("PinRear", 0.31, 0.05, v3(0, 0.02, 0.52), "Metal"),
		drum("PinFront", 0.31, 0.05, v3(0, 0.02, -0.52), "Metal"),
		drum("TriggerPin", 0.29, 0.05, v3(0, -0.07, 0.2), "Metal"),
		box("ChamberLight", v3(0.31, 0.04, 0.14), v3(0, 0.25, 0.42), "Accent"),

		-- Top rail
		box("Rail", v3(0.16, 0.05, 1.18), v3(0, 0.325, 0.02), "Dark"),
		box("RailTooth1", v3(0.17, 0.04, 0.06), v3(0, 0.365, 0.55), "Dark"),
		box("RailTooth2", v3(0.17, 0.04, 0.06), v3(0, 0.365, 0.4), "Dark"),
		box("RailTooth3", v3(0.17, 0.04, 0.06), v3(0, 0.365, 0.25), "Dark"),
		box("RailTooth4", v3(0.17, 0.04, 0.06), v3(0, 0.365, 0.1), "Dark"),
		box("RailTooth5", v3(0.17, 0.04, 0.06), v3(0, 0.365, -0.05), "Dark"),
		box("RailTooth6", v3(0.17, 0.04, 0.06), v3(0, 0.365, -0.2), "Dark"),
		box("RailTooth7", v3(0.17, 0.04, 0.06), v3(0, 0.365, -0.35), "Dark"),
		box("RailTooth8", v3(0.17, 0.04, 0.06), v3(0, 0.365, -0.5), "Dark"),

		-- Scope
		tube("ScopeTube", 0.5, 0.17, v3(0, 0.52, -0.28), "Body"),
		tube("Eyepiece", 0.2, 0.19, v3(0, 0.52, 0.05), "Dark"),
		tube("EyeRingBack", 0.04, 0.2, v3(0, 0.52, 0.1), "Body"),
		tube("EyeRingFront", 0.04, 0.2, v3(0, 0.52, 0.0), "Body"),
		tube("EyeCup", 0.06, 0.17, v3(0, 0.52, 0.175), "Rubber"),
		tube("EyeLens", 0.04, 0.12, v3(0, 0.52, 0.19), "Lens"),
		tube("PowerRing", 0.06, 0.18, v3(0, 0.52, -0.08), "Dark"),
		tube("BellNeck", 0.1, 0.21, v3(0, 0.52, -0.55), "Body"),
		tube("Bell", 0.2, 0.25, v3(0, 0.52, -0.69), "Body"),
		tube("BellRing", 0.04, 0.255, v3(0, 0.52, -0.8), "Dark"),
		tube("FrontLens", 0.04, 0.2, v3(0, 0.52, -0.805), "Lens"),
		disc("Turret", 0.07, 0.1, v3(0, 0.625, -0.27), "Body"),
		disc("TurretCap", 0.04, 0.06, v3(0, 0.66, -0.27), "Accent"),
		drum("WindageKnob", 0.07, 0.09, v3(0.11, 0.52, -0.27), "Body"),
		tube("RingRear", 0.06, 0.2, v3(0, 0.52, -0.1), "Dark"),
		tube("RingFront", 0.06, 0.2, v3(0, 0.52, -0.41), "Dark"),
		box("RingBaseRear", v3(0.12, 0.06, 0.08), v3(0, 0.41, -0.1), "Dark"),
		box("RingBaseFront", v3(0.12, 0.06, 0.08), v3(0, 0.41, -0.41), "Dark"),

		-- Handguard
		box("Handguard", v3(0.3, 0.26, 1.15), v3(0, 0.17, -1.175), "Body"),
		box("HandguardBelly", v3(0.22, 0.06, 1.15), v3(0, 0.025, -1.175), "Body"),
		drum("Vent1", 0.31, 0.075, v3(0, 0.18, -0.71), "Dark"),
		drum("Vent2", 0.31, 0.075, v3(0, 0.18, -0.857), "Dark"),
		drum("Vent3", 0.31, 0.075, v3(0, 0.18, -1.004), "Dark"),
		drum("Vent4", 0.31, 0.075, v3(0, 0.18, -1.151), "Dark"),
		drum("Vent5", 0.31, 0.075, v3(0, 0.18, -1.298), "Dark"),
		drum("Vent6", 0.31, 0.075, v3(0, 0.18, -1.445), "Dark"),
		drum("Vent7", 0.31, 0.075, v3(0, 0.18, -1.592), "Dark"),
		box("Rib1", v3(0.33, 0.21, 0.045), v3(0, 0.17, -0.7835), "Body", v3(-25, 0, 0)),
		box("Rib2", v3(0.33, 0.21, 0.045), v3(0, 0.17, -0.9305), "Body", v3(-25, 0, 0)),
		box("Rib3", v3(0.33, 0.21, 0.045), v3(0, 0.17, -1.0775), "Body", v3(-25, 0, 0)),
		box("Rib4", v3(0.33, 0.21, 0.045), v3(0, 0.17, -1.2245), "Body", v3(-25, 0, 0)),
		box("Rib5", v3(0.33, 0.21, 0.045), v3(0, 0.17, -1.3715), "Body", v3(-25, 0, 0)),
		box("Rib6", v3(0.33, 0.21, 0.045), v3(0, 0.17, -1.5185), "Body", v3(-25, 0, 0)),
		box("HandguardCap", v3(0.28, 0.24, 0.04), v3(0, 0.17, -1.76), "Dark"),

		-- Barrel and muzzle brake
		tube("BarrelBase", 0.16, 0.14, v3(0, 0.2, -1.84), "Body"),
		tube("Barrel", 0.8, 0.1, v3(0, 0.2, -2.3), "Body"),
		tube("BrakeCollar", 0.04, 0.14, v3(0, 0.2, -2.7), "Dark"),
		tube("Brake", 0.17, 0.18, v3(0, 0.2, -2.805), "Body"),
		box("BrakePort1", v3(0.19, 0.07, 0.04), v3(0, 0.2, -2.76), "Dark"),
		box("BrakePort2", v3(0.19, 0.07, 0.04), v3(0, 0.2, -2.84), "Dark"),
		tube("BrakeTip", 0.13, 0.19, v3(0, 0.2, -2.935), "Dark"),

		-- Folded bipod
		box("BipodClamp", v3(0.14, 0.22, 0.06), v3(0, 0.14, -2.07), "Dark"),
		drum("BipodHinge", 0.2, 0.06, v3(0, 0.05, -2.07), "Gunmetal"),
		tube("BipodLegLeft", 0.29, 0.055, v3(-0.06, 0.05, -1.925), "Gunmetal"),
		tube("BipodLegRight", 0.29, 0.055, v3(0.06, 0.05, -1.925), "Gunmetal"),
		ball("BipodFootLeft", 0.1, v3(-0.06, 0.04, -1.78), "Rubber"),
		ball("BipodFootRight", 0.1, v3(0.06, 0.04, -1.78), "Rubber"),
		box("BipodArm", v3(0.05, 0.04, 0.14), v3(0, 0.05, -2.14), "Gunmetal"),
		box("BipodLever", v3(0.05, 0.16, 0.05), v3(0, -0.03, -2.2), "Dark"),
		box("BipodLeverFoot", v3(0.12, 0.05, 0.08), v3(0, -0.12, -2.2), "Rubber"),

		-- Stock
		box("Stock", v3(0.26, 0.34, 1.0), v3(0, 0.11, 1.08), "Body"),
		wedge("StockToe", v3(0.26, 0.414, 0.885), v3(0, -0.267, 1.1325), "Body", v3(0, 0, 180)),
		box("CheekRest", v3(0.27, 0.13, 0.74), v3(0, 0.235, 1.12), "Body"),
		box("ButtPad", v3(0.27, 0.77, 0.07), v3(0, -0.1, 1.605), "Rubber"),
		drum("SlingCupLeft", 0.04, 0.08, v3(-0.12, -0.26, 1.42), "Dark"),
		drum("SlingCupRight", 0.04, 0.08, v3(0.12, -0.26, 1.42), "Dark"),
		box("StockLatch", v3(0.27, 0.08, 0.06), v3(0, 0.0, 0.65), "Dark"),

		-- Grip and trigger
		box("Grip", v3(0.24, 0.6, 0.27), v3(0, -0.42, 0.31), "Grip", v3(-11, 0, 0)),
		ball("FingerRest", 0.1, v3(0, -0.43, 0.165), "Grip"),
		box("GripCap", v3(0.26, 0.05, 0.3), v3(0, -0.715, 0.37), "Grip", v3(-11, 0, 0)),
		box("TriggerGuard", v3(0.06, 0.04, 0.26), v3(0, -0.25, 0.06), "Body"),
		box("Trigger", v3(0.05, 0.12, 0.04), v3(0, -0.19, 0.07), "Dark", v3(12, 0, 0)),

		-- Magazine
		box("Magazine", v3(0.2, 0.46, 0.44), v3(0, -0.52, -0.33), "Dark"),
		box("MagRib1", v3(0.21, 0.38, 0.04), v3(0, -0.52, -0.22), "Gunmetal"),
		box("MagRib2", v3(0.21, 0.38, 0.04), v3(0, -0.52, -0.33), "Gunmetal"),
		box("MagRib3", v3(0.21, 0.38, 0.04), v3(0, -0.52, -0.44), "Gunmetal"),
		box("MagBase", v3(0.22, 0.05, 0.46), v3(0, -0.75, -0.33), "Dark"),
	},
}
