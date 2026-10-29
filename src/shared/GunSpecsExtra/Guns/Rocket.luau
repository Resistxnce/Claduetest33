-- Rocket Launcher, built like the RPG in the blocky guns picture: flared exhaust bell, orange
-- heat shield, two pistol grips, an optical sight on the left and an olive warhead in the muzzle.
local Shapes = require(script.Parent.Parent.Shapes)

local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

-- Height of the launch tube's center line
local Y = 0.02

return {
	Factory = { Body = rgb(30, 30, 32), Accent = rgb(96, 100, 108) }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0.2, -0.08, -0.9),
	Muzzle = v3(0, Y, -1.34),
	Support = v3(-0.02, -0.33, 0.88),
	Parts = {
		-- Exhaust bell
		tube("BellBack", 0.04, 0.54, v3(0, Y, 2.685), "Body"),
		tube("BellMouth", 0.25, 0.57, v3(0, Y, 2.545), "Body"),
		tube("BellLipFront", 0.04, 0.52, v3(0, Y, 2.405), "Body"),
		tube("Venturi", 0.04, 0.48, v3(0, Y, 2.69), "Gunmetal"),
		tube("ExhaustHole", 0.04, 0.34, v3(0, Y, 2.7), "Dark"),
		tube("Cone1", 0.065, 0.415, v3(0, Y, 2.4), "Body"),
		tube("Cone2", 0.065, 0.38, v3(0, Y, 2.34), "Body"),
		tube("Cone3", 0.065, 0.35, v3(0, Y, 2.28), "Body"),
		tube("Cone4", 0.065, 0.315, v3(0, Y, 2.22), "Body"),
		tube("Cone5", 0.065, 0.28, v3(0, Y, 2.16), "Body"),
		tube("Cone6", 0.065, 0.25, v3(0, Y, 2.1), "Body"),
		tube("Cone7", 0.065, 0.225, v3(0, Y, 2.04), "Body"),
		tube("BellNeck", 0.12, 0.22, v3(0, Y, 1.99), "Body"),

		-- Rear collar
		tube("RearCollar", 0.13, 0.34, v3(0, Y, 1.912), "Body"),
		tube("RearCollarLip", 0.17, 0.3, v3(0, Y, 1.912), "Metal"),
		drum("RearCollarScrewR", 0.04, 0.06, v3(0.165, Y, 1.912), "Metal"),
		drum("RearCollarScrewL", 0.04, 0.06, v3(-0.165, Y, 1.912), "Metal"),

		-- Heat shield
		tube("HeatShield", 0.68, 0.265, v3(0, Y, 1.512), "Orange"),

		-- Front collar
		tube("FrontCollar", 0.143, 0.34, v3(0, Y, 1.1), "Body"),
		tube("FrontCollarLip", 0.18, 0.3, v3(0, Y, 1.1), "Metal"),
		drum("FrontCollarScrewR", 0.04, 0.06, v3(0.165, Y, 1.1), "Metal"),
		drum("FrontCollarScrewL", 0.04, 0.06, v3(-0.165, Y, 1.1), "Metal"),

		-- Front tube and muzzle
		tube("FrontTube", 1.25, 0.225, v3(0, Y, 0.41), "Body"),
		tube("MuzzleRing", 0.12, 0.265, v3(0, Y, -0.15), "Body"),
		tube("MuzzleLip", 0.04, 0.255, v3(0, Y, -0.205), "Metal"),

		-- Iron sights on top
		box("TopRib", v3(0.08, 0.04, 0.5), v3(0, Y + 0.12, 0.16), "Dark"),
		box("RearSightBase", v3(0.12, 0.04, 0.1), v3(0, Y + 0.13, 0.37), "Dark"),
		box("RearSightLeaf", v3(0.1, 0.04, 0.04), v3(0, Y + 0.165, 0.39), "Metal"),
		box("RearSightDot", v3(0.04, 0.04, 0.04), v3(0, Y + 0.17, 0.42), "Accent"),
		box("SightMount", v3(0.1, 0.05, 0.12), v3(0, Y + 0.13, 0.13), "Dark"),
		box("FrontSightBase", v3(0.08, 0.04, 0.07), v3(0, Y + 0.14, -0.15), "Dark"),
		box("FrontSightPost", v3(0.04, 0.04, 0.04), v3(0, Y + 0.175, -0.15), "Metal"),

		-- Optical sight on the left
		box("ScopeBracket", v3(0.08, 0.07, 0.18), v3(-0.11, Y + 0.06, 0.25), "Dark"),
		box("ScopeBody", v3(0.1, 0.1, 0.28), v3(-0.18, Y + 0.1, 0.25), "Dark"),
		tube("ScopeHood", 0.1, 0.1, v3(-0.18, Y + 0.1, 0.065), "Dark"),
		tube("ScopeLens", 0.04, 0.08, v3(-0.18, Y + 0.1, 0.03), "Lens"),
		tube("ScopeEyepiece", 0.08, 0.08, v3(-0.18, Y + 0.1, 0.425), "Dark"),
		tube("ScopeEyecup", 0.07, 0.105, v3(-0.18, Y + 0.1, 0.5), "Rubber"),
		drum("ScopeKnob", 0.04, 0.05, v3(-0.245, Y + 0.1, 0.18), "Metal"),
		box("ScopeGlow", v3(0.04, 0.04, 0.07), v3(-0.235, Y + 0.1, 0.31), "Accent"),

		-- Trigger group
		box("TriggerHousing", v3(0.18, 0.15, 0.37), v3(0, Y - 0.135, 0.325), "Body"),
		box("HousingFront", v3(0.17, 0.09, 0.2), v3(0, Y - 0.095, 0.045), "Body"),
		box("GripFrame", v3(0.19, 0.08, 0.32), v3(0, Y - 0.24, 0.33), "Dark"),
		box("GuardBottom", v3(0.04, 0.04, 0.18), v3(0, Y - 0.272, 0.09), "Gunmetal"),
		box("GuardFront", v3(0.04, 0.15, 0.04), v3(0, Y - 0.21, 0), "Gunmetal"),
		drum("GuardCorner", 0.04, 0.06, v3(0, Y - 0.26, 0.012), "Gunmetal"),
		box("Trigger", v3(0.04, 0.09, 0.04), v3(0, Y - 0.185, 0.1), "Chrome", v3(15, 0, 0)),
		drum("HousingPin", 0.19, 0.04, v3(0, Y - 0.17, 0.25), "Metal"),
		box("Hammer", v3(0.04, 0.04, 0.08), v3(0.1, Y - 0.15, 0.4), "Metal"),
		box("Safety", v3(0.04, 0.04, 0.07), v3(-0.1, Y - 0.17, 0.33), "Metal"),
		box("ArmedLight", v3(0.04, 0.04, 0.04), v3(-0.1, Y - 0.11, 0.44), "Accent"),

		-- Trigger grip
		box("TriggerGrip", v3(0.19, 0.43, 0.234), v3(0, -0.445, 0.3), "Metal"),
		box("TriggerGripBottom", v3(0.19, 0.04, 0.154), v3(0, -0.68, 0.3), "Metal"),
		drum("TriggerGripHeel", 0.19, 0.08, v3(0, -0.66, 0.377), "Metal"),
		drum("TriggerGripToe", 0.19, 0.08, v3(0, -0.66, 0.223), "Metal"),
		box("TriggerGripPanelR", v3(0.04, 0.3, 0.17), v3(0.09, -0.44, 0.3), "Gunmetal"),
		box("TriggerGripPanelL", v3(0.04, 0.3, 0.17), v3(-0.09, -0.44, 0.3), "Gunmetal"),
		drum("TriggerGripScrewR", 0.04, 0.045, v3(0.11, -0.44, 0.3), "Metal"),
		drum("TriggerGripScrewL", 0.04, 0.045, v3(-0.11, -0.44, 0.3), "Metal"),

		-- Rear grip
		box("RearGripMount", v3(0.16, 0.06, 0.26), v3(0, Y - 0.12, 0.88), "Body"),
		box("RearGrip", v3(0.19, 0.39, 0.24), v3(0, -0.315, 0.88), "Metal"),
		box("RearGripBottom", v3(0.19, 0.04, 0.16), v3(0, -0.53, 0.88), "Metal"),
		drum("RearGripHeel", 0.19, 0.08, v3(0, -0.51, 0.96), "Metal"),
		drum("RearGripToe", 0.19, 0.08, v3(0, -0.51, 0.8), "Metal"),
		box("RearGripPanelR", v3(0.04, 0.26, 0.17), v3(0.09, -0.32, 0.88), "Gunmetal"),
		box("RearGripPanelL", v3(0.04, 0.26, 0.17), v3(-0.09, -0.32, 0.88), "Gunmetal"),
		drum("RearGripScrewR", 0.04, 0.045, v3(0.11, -0.32, 0.88), "Metal"),
		drum("RearGripScrewL", 0.04, 0.045, v3(-0.11, -0.32, 0.88), "Metal"),

		-- Warhead (the rocket loaded in the muzzle)
		tube("WarheadNeck", 0.2, 0.24, v3(0, Y, -0.29), "Warhead"),
		tube("WarheadBack1", 0.05, 0.26, v3(0, Y, -0.4125), "Warhead"),
		tube("WarheadBack2", 0.05, 0.28, v3(0, Y, -0.4575), "Warhead"),
		tube("WarheadBack3", 0.05, 0.305, v3(0, Y, -0.5025), "Warhead"),
		tube("WarheadBack4", 0.05, 0.33, v3(0, Y, -0.5475), "Warhead"),
		tube("WarheadBack5", 0.05, 0.35, v3(0, Y, -0.5925), "Warhead"),
		tube("WarheadBack6", 0.05, 0.375, v3(0, Y, -0.6375), "Warhead"),
		tube("WarheadBack7", 0.05, 0.395, v3(0, Y, -0.6825), "Warhead"),
		tube("WarheadBack8", 0.05, 0.415, v3(0, Y, -0.7275), "Warhead"),
		tube("WarheadBelly", 0.09, 0.425, v3(0, Y, -0.79), "Warhead"),
		tube("WarheadCone1", 0.048, 0.39, v3(0, Y, -0.857), "Warhead"),
		tube("WarheadCone2", 0.048, 0.35, v3(0, Y, -0.901), "Warhead"),
		tube("WarheadCone3", 0.048, 0.305, v3(0, Y, -0.945), "Warhead"),
		tube("WarheadCone4", 0.048, 0.265, v3(0, Y, -0.989), "Warhead"),
		tube("WarheadCone5", 0.048, 0.22, v3(0, Y, -1.033), "Warhead"),
		tube("WarheadCone6", 0.048, 0.18, v3(0, Y, -1.077), "Warhead"),
		tube("WarheadCone7", 0.048, 0.14, v3(0, Y, -1.121), "Warhead"),
		tube("ProbeCollar", 0.04, 0.12, v3(0, Y, -1.15), "Warhead"),
		tube("Probe", 0.18, 0.09, v3(0, Y, -1.225), "Warhead"),
		ball("ProbeTip", 0.09, v3(0, Y, -1.3), "Warhead"),
	},
}
