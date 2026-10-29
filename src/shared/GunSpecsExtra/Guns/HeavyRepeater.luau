-- Heavy Repeater: a handheld twin-barrel heavy gun, based on the mounted heavy
-- gun in the gun wall picture (boxy receiver, stacked barrels, ammo box on an arm).
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(56, 58, 62), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0.15, -0.3, -0.85),
	Muzzle = v3(0, 0.54, -2.85),
	Support = v3(-0.03, -0.02, -1.45),
	Parts = {
		-- Receiver
		box("Receiver", v3(0.42, 0.76, 0.86), v3(0, 0.3, -0.35), "Body"),
		box("ReceiverFront", v3(0.42, 0.46, 0.16), v3(0, 0.13, -0.85), "Body"),
		box("Trunnion", v3(0.38, 0.24, 0.24), v3(0, 0.48, -0.89), "Body"),
		wedge("TrunnionSlope", v3(0.38, 0.09, 0.32), v3(0, 0.645, -0.85), "Body"),
		box("TopCover", v3(0.38, 0.045, 0.72), v3(0, 0.69, -0.32), "Gunmetal"),
		box("RearPlate", v3(0.43, 0.78, 0.06), v3(0, 0.3, 0.06), "Gunmetal"),
		box("BottomLip", v3(0.45, 0.04, 1.0), v3(0, -0.085, -0.42), "Gunmetal"),
		box("SidePlate", v3(0.44, 0.36, 0.36), v3(0, 0.1, -0.76), "Metal"),
		box("Groove1", v3(0.44, 0.04, 0.44), v3(0, 0.45, -0.56), "Dark"),
		box("Groove2", v3(0.44, 0.04, 0.44), v3(0, 0.515, -0.56), "Dark"),
		box("Groove3", v3(0.44, 0.04, 0.44), v3(0, 0.58, -0.56), "Dark"),
		box("Groove4", v3(0.44, 0.04, 0.44), v3(0, 0.645, -0.56), "Dark"),
		drum("RivetTop", 0.46, 0.05, v3(0, 0.24, -0.88), "Chrome"),
		drum("RivetBottom", 0.46, 0.05, v3(0, -0.03, -0.88), "Chrome"),

		-- Rear sight
		wedge("SightRamp", v3(0.22, 0.09, 0.32), v3(0, 0.755, -0.5), "Dark"),
		box("SightLeaf", v3(0.24, 0.1, 0.05), v3(0, 0.76, -0.34), "Dark"),
		box("SightDot", v3(0.05, 0.05, 0.04), v3(0, 0.785, -0.31), "Accent"),

		-- Upper barrel
		tube("UpperBarrel", 1.62, 0.14, v3(0, 0.54, -1.8), "Gunmetal"),
		tube("UpperCollar", 0.18, 0.17, v3(0, 0.54, -1.08), "Metal"),
		wedge("UpperRib", v3(0.05, 0.05, 0.26), v3(0, 0.625, -2.47), "Gunmetal", v3(0, 180, 0)),
		tube("UpperRing", 0.04, 0.17, v3(0, 0.54, -2.6), "Metal"),
		tube("UpperBell1", 0.0625, 0.15, v3(0, 0.54, -2.631), "Gunmetal"),
		tube("UpperBell2", 0.0625, 0.165, v3(0, 0.54, -2.694), "Gunmetal"),
		tube("UpperBell3", 0.0625, 0.18, v3(0, 0.54, -2.756), "Gunmetal"),
		tube("UpperBell4", 0.0625, 0.2, v3(0, 0.54, -2.819), "Gunmetal"),
		tube("UpperBore", 0.04, 0.12, v3(0, 0.54, -2.832), "Dark"),

		-- Lower barrel
		tube("LowerBarrel", 1.62, 0.14, v3(0, 0.16, -1.8), "Gunmetal"),
		tube("LowerCollar", 0.22, 0.18, v3(0, 0.16, -1.04), "Metal"),
		wedge("LowerRib", v3(0.05, 0.05, 0.26), v3(0, 0.245, -2.47), "Gunmetal", v3(0, 180, 0)),
		tube("LowerRing", 0.04, 0.17, v3(0, 0.16, -2.6), "Metal"),
		tube("LowerBell1", 0.0625, 0.15, v3(0, 0.16, -2.631), "Gunmetal"),
		tube("LowerBell2", 0.0625, 0.165, v3(0, 0.16, -2.694), "Gunmetal"),
		tube("LowerBell3", 0.0625, 0.18, v3(0, 0.16, -2.756), "Gunmetal"),
		tube("LowerBell4", 0.0625, 0.2, v3(0, 0.16, -2.819), "Gunmetal"),
		tube("LowerBore", 0.04, 0.12, v3(0, 0.16, -2.832), "Dark"),

		-- Carry loop between the barrels
		box("Loop1", v3(0.05, 0.05, 0.09), v3(0, 0.155, -1.029), "Metal", v3(-165, 0, 0)),
		box("Loop2", v3(0.05, 0.05, 0.09), v3(0, 0.194, -1.096), "Metal", v3(-135, 0, 0)),
		box("Loop3", v3(0.05, 0.05, 0.09), v3(0, 0.261, -1.135), "Metal", v3(-105, 0, 0)),
		box("Loop4", v3(0.05, 0.05, 0.09), v3(0, 0.339, -1.135), "Metal", v3(-75, 0, 0)),
		box("Loop5", v3(0.05, 0.05, 0.09), v3(0, 0.406, -1.096), "Metal", v3(-45, 0, 0)),
		box("Loop6", v3(0.05, 0.05, 0.09), v3(0, 0.445, -1.029), "Metal", v3(-15, 0, 0)),

		-- Folding legs under the barrels
		tube("LegClamp", 0.12, 0.2, v3(0, 0.16, -1.45), "Metal"),
		box("LegHinge", v3(0.22, 0.07, 0.14), v3(0, 0.05, -1.45), "Dark"),
		box("LegLeft", v3(0.05, 0.05, 0.6), v3(-0.07, 0.04, -1.77), "Metal"),
		box("LegRight", v3(0.05, 0.05, 0.6), v3(0.07, 0.04, -1.77), "Metal"),
		box("FootLeft", v3(0.08, 0.06, 0.07), v3(-0.07, 0.04, -2.08), "Rubber"),
		box("FootRight", v3(0.08, 0.06, 0.07), v3(0.07, 0.04, -2.08), "Rubber"),

		-- Grip: a round hooked neck off the back of the receiver, then a big pistol grip
		box("GripNeck", v3(0.26, 0.26, 0.18), v3(0, 0.03, 0.15), "Grip"),
		box("Curl1", v3(0.26, 0.16, 0.12), v3(0, 0.156, 0.1), "Grip", v3(11.25, 0, 0)),
		box("Curl2", v3(0.26, 0.16, 0.12), v3(0, 0.128, 0.169), "Grip", v3(33.75, 0, 0)),
		box("Curl3", v3(0.26, 0.16, 0.12), v3(0, 0.076, 0.221), "Grip", v3(56.25, 0, 0)),
		box("Curl4", v3(0.26, 0.16, 0.12), v3(0, 0.007, 0.249), "Grip", v3(78.75, 0, 0)),
		box("Grip", v3(0.24, 0.58, 0.18), v3(0, -0.38, 0.313), "Grip", v3(-6.4, 0, 0)),
		box("GripPanel", v3(0.26, 0.4, 0.13), v3(0, -0.41, 0.316), "Rubber", v3(-6.4, 0, 0)),
		drum("Finger1", 0.22, 0.07, v3(0, -0.271, 0.21), "Grip"),
		drum("Finger2", 0.22, 0.07, v3(0, -0.39, 0.224), "Grip"),
		drum("Finger3", 0.22, 0.07, v3(0, -0.509, 0.237), "Grip"),
		box("GripBase", v3(0.26, 0.06, 0.24), v3(0, -0.655, 0.34), "Dark", v3(-6.4, 0, 0)),
		box("Trigger", v3(0.05, 0.12, 0.05), v3(0, -0.16, 0.12), "Metal", v3(15, 0, 0)),

		-- Ammo box
		box("AmmoBox", v3(0.44, 1.16, 0.72), v3(-0.32, -0.155, 1.38), "Body"),
		box("AmmoLid", v3(0.47, 0.06, 0.76), v3(-0.32, 0.45, 1.38), "Gunmetal"),
		box("AmmoFront", v3(0.46, 1.08, 0.05), v3(-0.32, -0.165, 1.01), "Gunmetal"),
		box("AmmoFin1", v3(0.4, 0.04, 0.06), v3(-0.32, 0.105, 1.76), "Dark"),
		box("AmmoFin2", v3(0.4, 0.04, 0.06), v3(-0.32, 0.015, 1.76), "Dark"),
		box("AmmoFin3", v3(0.4, 0.04, 0.06), v3(-0.32, -0.075, 1.76), "Dark"),
		box("AmmoFin4", v3(0.4, 0.04, 0.06), v3(-0.32, -0.165, 1.76), "Dark"),
		box("AmmoFin5", v3(0.4, 0.04, 0.06), v3(-0.32, -0.255, 1.76), "Dark"),
		box("AmmoFin6", v3(0.4, 0.04, 0.06), v3(-0.32, -0.345, 1.76), "Dark"),
		box("AmmoRearBlock", v3(0.04, 0.25, 0.24), v3(-0.09, 0.255, 1.62), "Dark"),
		drum("AmmoCapRing", 0.05, 0.21, v3(-0.085, 0.185, 1.37), "Metal"),
		drum("AmmoCap", 0.07, 0.12, v3(-0.08, 0.185, 1.37), "Dark"),
		box("AmmoWindow", v3(0.04, 0.05, 0.32), v3(-0.085, -0.015, 1.31), "Accent"),
		box("AmmoPanel", v3(0.04, 0.36, 0.34), v3(-0.09, -0.245, 1.31), "Metal"),
		box("AmmoSlot1", v3(0.04, 0.2, 0.04), v3(-0.085, -0.575, 1.42), "Dark"),
		box("AmmoSlot2", v3(0.04, 0.2, 0.04), v3(-0.085, -0.575, 1.32), "Dark"),
		box("AmmoSlot3", v3(0.04, 0.2, 0.04), v3(-0.085, -0.575, 1.22), "Dark"),
		box("AmmoLowerPlate", v3(0.04, 0.42, 0.22), v3(-0.09, -0.495, 1.63), "Gunmetal"),
		box("AmmoHandlePostFront", v3(0.09, 0.05, 0.05), v3(-0.585, 0.22, 1.235), "Dark"),
		box("AmmoHandlePostBack", v3(0.09, 0.05, 0.05), v3(-0.585, 0.22, 1.525), "Dark"),
		box("AmmoHandle", v3(0.05, 0.05, 0.34), v3(-0.63, 0.22, 1.38), "Rubber"),
		box("AmmoSidePanel", v3(0.04, 0.46, 0.5), v3(-0.55, -0.33, 1.38), "Metal"),
		box("AmmoGlowLeft", v3(0.04, 0.05, 0.4), v3(-0.55, 0, 1.38), "Accent"),
		box("RollerBracket", v3(0.36, 0.1, 0.12), v3(-0.32, -0.76, 1.33), "Dark"),
		drum("Roller", 0.3, 0.25, v3(-0.32, -0.85, 1.33), "Rubber"),
		drum("RollerHub", 0.36, 0.1, v3(-0.32, -0.85, 1.33), "Metal"),

		-- Feed arm from the ammo box over to the receiver
		box("ArmMount", v3(0.14, 0.06, 0.14), v3(-0.32, 0.5, 1.12), "Dark"),
		ball("ArmBase", 0.14, v3(-0.32, 0.545, 1.12), "Metal"),
		box("ArmLower", v3(0.09, 0.09, 0.644), v3(-0.32, 0.805, 0.93), "Dark", v3(53.84, 0, 0)),
		ball("ArmElbow", 0.15, v3(-0.32, 1.065, 0.74), "Metal"),
		box("ArmUpper", v3(0.09, 0.09, 1.017), v3(-0.06, 0.927, 0.325), "Dark", v3(-18.33, -30.74, 0)),
		box("JointBlock", v3(0.12, 0.08, 0.12), v3(0.2, 0.74, -0.09), "Dark"),
		ball("ArmJoint", 0.13, v3(0.2, 0.79, -0.09), "Metal"),
		box("ArmRod", v3(0.05, 0.74, 0.05), v3(0.235, 0.42, -0.09), "Metal"),
		drum("Knob", 0.06, 0.17, v3(0.24, 0, -0.1), "Metal"),
		drum("KnobCap", 0.1, 0.08, v3(0.25, 0, -0.1), "Dark"),
	},
}
