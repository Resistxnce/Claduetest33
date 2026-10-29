-- Bolt Rifle: a scoped bolt-action with a big wooden fishtail stock and a long barrel,
-- based on the brown wooden rifle in the gun wall picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(46, 48, 54), Accent = rgb(96, 100, 108), Material = Enum.Material.Metal }, -- blued steel, steel trim
	View = CFrame.new(0, 0.05, -0.95),
	Muzzle = v3(0, -0.26, -3.58),
	Support = v3(-0.03, -0.47, -1.02),
	Parts = {
		-- Fishtail stock
		box("ButtUpper", v3(0.26, 0.49, 0.165), v3(0, -0.375, 0.8425), "Wood"),
		box("ButtLower", v3(0.256, 0.348, 0.17), v3(0, -0.742, 0.899), "Wood", v3(-18.4, 0, 0)),
		egg("HeelTip", v3(0.26, 0.11, 0.23), v3(0, -0.125, 0.825), "Wood"),
		egg("ToeTip", v3(0.256, 0.1, 0.18), v3(0, -0.9, 0.96), "Wood"),
		wedge("HornSlope", v3(0.26, 0.24, 0.207), v3(0, -0.2, 0.6524), "Wood"),
		wedge("HornFillet", v3(0.258, 0.06, 0.13), v3(0, -0.295, 0.535), "Wood"),
		box("ButtCore", v3(0.244, 0.28, 0.33), v3(0, -0.46, 0.635), "Wood"),
		wedge("BellyWedge", v3(0.252, 0.39, 0.49), v3(0, -0.742, 0.645), "Wood", v3(0, 0, 180)),
		box("Wrist", v3(0.2, 0.175, 0.35), v3(0, -0.4125, 0.345), "Wood"),
		wedge("WristBelly", v3(0.2, 0.105, 0.24), v3(0, -0.5525, 0.34), "Wood", v3(0, 0, 180)),
		wedge("Comb", v3(0.196, 0.085, 0.4), v3(0, -0.2875, 0.2), "Wood", v3(0, 180, 0)),
		box("TriggerWood", v3(0.22, 0.145, 0.17), v3(0, -0.3725, 0.085), "Wood"),
		box("StockBody", v3(0.23, 0.2, 0.39), v3(0, -0.345, -0.195), "Wood"),

		-- Forend
		box("Forend", v3(0.21, 0.198, 0.96), v3(0, -0.328, -0.85), "Wood"),
		box("ForendNose", v3(0.21, 0.146, 0.14), v3(0, -0.302, -1.4), "Wood"),
		wedge("NoseChamfer", v3(0.21, 0.052, 0.14), v3(0, -0.401, -1.4), "Wood", v3(0, 0, 180)),
		box("BandRear", v3(0.225, 0.215, 0.06), v3(0, -0.3285, -0.75), "Gunmetal"),
		box("BandFront", v3(0.225, 0.215, 0.06), v3(0, -0.3285, -1.28), "Gunmetal"),
		box("NoseCap", v3(0.17, 0.15, 0.12), v3(0, -0.3, -1.53), "Body"),

		-- Receiver and bolt
		tube("Receiver", 0.3, 0.14, v3(0, -0.26, -0.17), "Body"),
		wedge("ReceiverTang", v3(0.12, 0.09, 0.18), v3(0, -0.235, 0.07), "Body", v3(0, 180, 0)),
		wedge("ReceiverNose", v3(0.13, 0.07, 0.12), v3(0, -0.225, -0.38), "Body"),
		egg("BoltShroud", v3(0.08, 0.07, 0.14), v3(0, -0.265, 0.12), "Gunmetal"),
		box("EjectionPort", v3(0.03, 0.06, 0.2), v3(0.058, -0.225, -0.17), "Dark"),
		box("BoltFace", v3(0.03, 0.035, 0.15), v3(0.065, -0.222, -0.17), "Chrome"),
		box("BoltRoot", v3(0.06, 0.05, 0.05), v3(0.075, -0.235, 0.04), "Gunmetal"),
		box("BoltHandle", v3(0.16, 0.04, 0.04), v3(0.155, -0.285, 0.04), "Gunmetal", v3(0, 0, -35)),
		ball("BoltKnob", 0.08, v3(0.235, -0.34, 0.04), "Accent"),
		drum("CrossBolt", 0.245, 0.05, v3(0, -0.38, -0.33), "Gunmetal"),

		-- Trigger and guard
		box("TriggerPlate", v3(0.07, 0.04, 0.3), v3(0, -0.455, 0.0175), "Gunmetal"),
		box("GuardBack", v3(0.05, 0.2, 0.045), v3(0, -0.555, 0.165), "Body"),
		box("GuardFront", v3(0.05, 0.2, 0.045), v3(0, -0.55, -0.13), "Body"),
		box("GuardBottom", v3(0.05, 0.045, 0.34), v3(0, -0.645, 0.0175), "Body"),
		box("TriggerTop", v3(0.04, 0.06, 0.045), v3(0, -0.48, 0.035), "Gunmetal"),
		box("TriggerBlade", v3(0.04, 0.09, 0.045), v3(0, -0.535, 0.045), "Gunmetal", v3(-20, 0, 0)),

		-- Sling swivel
		box("SlingStud", v3(0.05, 0.07, 0.05), v3(0, -0.6, 0.385), "Gunmetal"),
		box("SlingLoopUpper", v3(0.04, 0.04, 0.135), v3(0, -0.62, 0.45), "Gunmetal", v3(42, 0, 0)),
		box("SlingLoopLower", v3(0.04, 0.04, 0.1), v3(0, -0.665, 0.41), "Gunmetal", v3(42, 0, 0)),
		box("SlingLoopEnd", v3(0.04, 0.04, 0.07), v3(0, -0.6815, 0.4735), "Gunmetal", v3(148, 0, 0)),

		-- Barrel
		tube("Barrel", 1.24, 0.105, v3(0, -0.26, -1.05), "Body"),
		tube("BarrelMid", 1.05, 0.095, v3(0, -0.26, -2.195), "Body"),
		tube("BarrelFront", 0.8, 0.085, v3(0, -0.26, -3.12), "Body"),
		tube("MuzzleCrown", 0.055, 0.1, v3(0, -0.26, -3.5475), "Gunmetal"),
		tube("Bore", 0.04, 0.045, v3(0, -0.26, -3.56), "Dark"),
		box("RearSightBase", v3(0.06, 0.04, 0.1), v3(0, -0.2, -2.16), "Gunmetal"),
		wedge("RearSightLeaf", v3(0.08, 0.05, 0.04), v3(0, -0.155, -2.15), "Gunmetal"),
		wedge("SightRamp", v3(0.05, 0.05, 0.12), v3(0, -0.195, -3.42), "Body", v3(0, 180, 0)),
		box("SightPost", v3(0.04, 0.05, 0.04), v3(0, -0.15, -3.465), "Gunmetal"),
		box("SightBead", v3(0.04, 0.04, 0.04), v3(0, -0.11, -3.465), "Accent"),

		-- Scope
		tube("EyeLens", 0.04, 0.08, v3(0, -0.13, -0.515), "Lens"),
		tube("Eyecup", 0.06, 0.11, v3(0, -0.13, -0.53), "Rubber"),
		tube("Eyepiece", 0.12, 0.128, v3(0, -0.13, -0.62), "Body"),
		tube("EyepieceTrim", 0.04, 0.135, v3(0, -0.13, -0.655), "Accent"),
		tube("EyepieceNeck", 0.04, 0.115, v3(0, -0.13, -0.7), "Dark"),
		tube("TubeRear", 0.34, 0.105, v3(0, -0.13, -0.87), "Body"),
		tube("RingRear", 0.07, 0.13, v3(0, -0.13, -0.75), "Gunmetal"),
		box("BaseRear", v3(0.07, 0.06, 0.06), v3(0, -0.205, -0.75), "Gunmetal"),
		drum("RingScrewRear", 0.15, 0.04, v3(0, -0.13, -0.75), "Chrome"),
		box("Saddle", v3(0.125, 0.125, 0.17), v3(0, -0.13, -1.12), "Body"),
		disc("TurretTop", 0.04, 0.08, v3(0, -0.0475, -1.12), "Gunmetal"),
		disc("TurretTopCap", 0.04, 0.09, v3(0, -0.0125, -1.12), "Gunmetal"),
		drum("TurretSide", 0.05, 0.08, v3(0.0875, -0.13, -1.12), "Gunmetal"),
		drum("TurretSideCap", 0.04, 0.09, v3(0.13, -0.13, -1.12), "Gunmetal"),
		drum("TurretLeft", 0.05, 0.07, v3(-0.0875, -0.13, -1.12), "Gunmetal"),
		tube("TubeFront", 0.5, 0.105, v3(0, -0.13, -1.45), "Body"),
		tube("RingFront", 0.07, 0.13, v3(0, -0.13, -1.28), "Gunmetal"),
		box("BaseFront", v3(0.07, 0.06, 0.06), v3(0, -0.205, -1.28), "Gunmetal"),
		drum("RingScrewFront", 0.15, 0.04, v3(0, -0.13, -1.28), "Chrome"),
		tube("ObjectiveNeck", 0.06, 0.13, v3(0, -0.13, -1.72), "Body"),
		tube("ObjectiveBell", 0.2, 0.165, v3(0, -0.13, -1.85), "Body"),
		tube("ObjectiveTrim", 0.04, 0.177, v3(0, -0.13, -1.92), "Accent"),
		tube("ObjectiveLens", 0.04, 0.14, v3(0, -0.13, -1.935), "Lens"),
	},
}
