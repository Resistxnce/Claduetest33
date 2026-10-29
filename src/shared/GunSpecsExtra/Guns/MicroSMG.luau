-- Micro SMG: a boxy machine pistol (Micro Uzi style) with a square receiver,
-- top cocking knob, eared front sight and a long magazine through the grip.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(30, 31, 34), Accent = rgb(96, 100, 108), Material = Enum.Material.SmoothPlastic }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0, -0.15),
	Muzzle = v3(0, 0.205, -0.895),
	Support = v3(-0.04, -0.06, -0.46),
	Parts = {
		-- Receiver: upper body, top cover with beveled edges, narrower lower body
		box("UpperReceiver", v3(0.3, 0.18, 1.36), v3(0, 0.3, 0.11), "Body"),
		box("TopCover", v3(0.2, 0.05, 1.32), v3(0, 0.41, 0.1), "Body"),
		wedge("TopBevelL", v3(1.32, 0.05, 0.05), v3(-0.125, 0.41, 0.1), "Body", v3(0, 90, 0)),
		wedge("TopBevelR", v3(1.32, 0.05, 0.05), v3(0.125, 0.41, 0.1), "Body", v3(0, -90, 0)),
		box("TopLatch", v3(0.12, 0.04, 0.06), v3(0, 0.44, 0.72), "Gunmetal"),
		box("LowerReceiver", v3(0.27, 0.17, 1.14), v3(0, 0.135, -0.005), "Body"),
		box("RearLower", v3(0.27, 0.1, 0.26), v3(0, 0.18, 0.67), "Body"),
		box("Seam", v3(0.312, 0.04, 1.3), v3(0, 0.215, 0.1), "Dark"),
		box("SidePanel", v3(0.282, 0.09, 0.84), v3(0, 0.14, 0.13), "Dark"),
		box("SideRib", v3(0.29, 0.04, 1.08), v3(0, 0.075, 0), "Body"),
		box("StripL", v3(0.04, 0.04, 0.5), v3(-0.155, 0.33, 0.34), "Accent"),
		box("StripR", v3(0.04, 0.04, 0.5), v3(0.155, 0.33, 0.34), "Accent"),
		drum("RivetFront", 0.31, 0.045, v3(0, 0.27, -0.45), "Gunmetal"),
		drum("RivetRear", 0.31, 0.045, v3(0, 0.27, 0.68), "Gunmetal"),
		drum("FrontSling", 0.05, 0.09, v3(-0.165, 0.3, -0.48), "Gunmetal"),

		-- Rear cap and folded-stock hinge
		box("RearCap", v3(0.31, 0.3, 0.23), v3(0, 0.29, 0.9), "Body"),
		box("RearSeam", v3(0.32, 0.26, 0.04), v3(0, 0.3, 0.79), "Dark"),
		drum("HingePin", 0.34, 0.08, v3(0, 0.18, 0.97), "Gunmetal"),
		drum("StockButton", 0.04, 0.08, v3(-0.165, 0.3, 0.88), "Gunmetal"),
		drum("SlingSwivel", 0.05, 0.1, v3(0.17, 0.3, 0.92), "Gunmetal"),

		-- Rear sight with ears and a chamfered back
		box("RearSightBase", v3(0.26, 0.05, 0.24), v3(0, 0.455, 0.885), "Body"),
		box("RearEarL", v3(0.05, 0.08, 0.18), v3(-0.105, 0.515, 0.86), "Body"),
		box("RearEarR", v3(0.05, 0.08, 0.18), v3(0.105, 0.515, 0.86), "Body"),
		wedge("RearRampL", v3(0.05, 0.08, 0.06), v3(-0.105, 0.515, 0.98), "Body", v3(0, 180, 0)),
		wedge("RearRampR", v3(0.05, 0.08, 0.06), v3(0.105, 0.515, 0.98), "Body", v3(0, 180, 0)),
		box("RearAperture", v3(0.08, 0.06, 0.06), v3(0, 0.505, 0.86), "Dark"),

		-- Cocking knob on the top cover, riding in its slot
		box("CockingSlot", v3(0.06, 0.04, 0.55), v3(0, 0.42, 0.1), "Dark"),
		box("CockingBase", v3(0.09, 0.04, 0.12), v3(0, 0.445, -0.115), "Gunmetal"),
		box("CockingPost", v3(0.06, 0.1, 0.08), v3(0, 0.5, -0.115), "Gunmetal"),
		disc("CockingKnob", 0.04, 0.09, v3(0, 0.555, -0.115), "Gunmetal"),

		-- Front sight with protective ears
		box("FrontSightBase", v3(0.26, 0.05, 0.19), v3(0, 0.455, -0.475), "Body"),
		box("FrontEarL", v3(0.05, 0.12, 0.1), v3(-0.105, 0.49, -0.517), "Body"),
		box("FrontEarR", v3(0.05, 0.12, 0.1), v3(0.105, 0.49, -0.517), "Body"),
		wedge("FrontRampL", v3(0.05, 0.12, 0.09), v3(-0.105, 0.49, -0.425), "Body", v3(0, 180, 0)),
		wedge("FrontRampR", v3(0.05, 0.12, 0.09), v3(0.105, 0.49, -0.425), "Body", v3(0, 180, 0)),
		box("FrontPost", v3(0.04, 0.06, 0.04), v3(0, 0.49, -0.52), "Dark"),
		box("FrontDot", v3(0.04, 0.04, 0.04), v3(0, 0.53, -0.52), "Accent"),

		-- Barrel nut and short barrel
		box("FrontPlate", v3(0.24, 0.24, 0.03), v3(0, 0.205, -0.585), "Gunmetal"),
		tube("BarrelNut", 0.1, 0.16, v3(0, 0.205, -0.63), "Gunmetal"),
		tube("NutRing1", 0.04, 0.17, v3(0, 0.205, -0.61), "Dark"),
		tube("NutRing2", 0.04, 0.17, v3(0, 0.205, -0.66), "Dark"),
		box("BarrelLatch", v3(0.05, 0.05, 0.06), v3(0, 0.29, -0.6), "Gunmetal"),
		tube("Barrel", 0.18, 0.11, v3(0, 0.205, -0.76), "Gunmetal"),
		tube("MuzzleCap", 0.06, 0.125, v3(0, 0.205, -0.86), "Gunmetal"),
		tube("Bore", 0.04, 0.06, v3(0, 0.205, -0.877), "Dark"),

		-- Ejection port with the bolt showing (right side)
		box("EjectionPort", v3(0.04, 0.09, 0.26), v3(0.145, 0.3, -0.17), "Dark"),
		box("Bolt", v3(0.04, 0.05, 0.18), v3(0.152, 0.3, -0.17), "Gunmetal"),

		-- Lower frame, trigger housing and the sloped belly behind the grip
		box("LowerFrame", v3(0.24, 0.15, 0.89), v3(0, 0.03, 0.115), "Body"),
		wedge("RearSlope", v3(0.26, 0.19, 0.32), v3(0, 0.045, 0.712), "Body", v3(180, 0, 0)),
		drum("FramePinFront", 0.29, 0.05, v3(0, 0.1, -0.45), "Gunmetal"),
		drum("FramePinRear", 0.29, 0.05, v3(0, 0.15, 0.68), "Gunmetal"),
		drum("Selector", 0.04, 0.09, v3(-0.13, 0.02, 0.36), "Gunmetal"),
		box("SelectorLever", v3(0.04, 0.04, 0.12), v3(-0.135, 0.02, 0.3), "Gunmetal", v3(20, 0, 0)),

		-- Trigger guard loop and trigger
		box("GuardFront", v3(0.06, 0.18, 0.05), v3(0, -0.12, -0.305), "Body"),
		box("GuardCorner", v3(0.06, 0.05, 0.13), v3(0, -0.245, -0.262), "Body", v3(45, 0, 0)),
		box("GuardBottom", v3(0.06, 0.045, 0.24), v3(0, -0.272, -0.12), "Body"),
		box("GuardRise", v3(0.06, 0.045, 0.13), v3(0, -0.25, 0.03), "Body", v3(-25, 0, 0)),
		drum("TriggerPin", 0.25, 0.045, v3(0, 0, 0.03), "Gunmetal"),
		box("TriggerTop", v3(0.05, 0.1, 0.045), v3(0, -0.09, 0), "Dark", v3(-10, 0, 0)),
		box("TriggerShoe", v3(0.05, 0.08, 0.045), v3(0, -0.17, -0.015), "Dark", v3(25, 0, 0)),

		-- Grip with ribbed panels, back tang and grip safety
		box("GripFrame", v3(0.22, 0.68, 0.43), v3(0, -0.375, 0.285), "Body"),
		box("GripPanelL", v3(0.03, 0.6, 0.36), v3(-0.12, -0.42, 0.27), "Grip"),
		box("GripPanelR", v3(0.03, 0.6, 0.36), v3(0.12, -0.42, 0.27), "Grip"),
		box("GripRibL1", v3(0.04, 0.5, 0.04), v3(-0.135, -0.42, 0.13), "Rubber"),
		box("GripRibL2", v3(0.04, 0.5, 0.04), v3(-0.135, -0.42, 0.2), "Rubber"),
		box("GripRibL3", v3(0.04, 0.5, 0.04), v3(-0.135, -0.42, 0.27), "Rubber"),
		box("GripRibR1", v3(0.04, 0.5, 0.04), v3(0.135, -0.42, 0.13), "Rubber"),
		box("GripRibR2", v3(0.04, 0.5, 0.04), v3(0.135, -0.42, 0.2), "Rubber"),
		box("GripRibR3", v3(0.04, 0.5, 0.04), v3(0.135, -0.42, 0.27), "Rubber"),
		drum("GripScrew", 0.28, 0.05, v3(0, -0.42, 0.38), "Gunmetal"),
		box("BackTang", v3(0.2, 0.25, 0.04), v3(0, -0.17, 0.515), "Body"),
		box("GripSafety", v3(0.16, 0.22, 0.04), v3(0, -0.6, 0.515), "Gunmetal"),
		box("GripBase", v3(0.24, 0.05, 0.325), v3(0, -0.74, 0.2275), "Dark"),
		wedge("GripHeel", v3(0.24, 0.05, 0.11), v3(0, -0.74, 0.445), "Dark", v3(180, 0, 0)),
		box("MagRelease", v3(0.04, 0.06, 0.08), v3(-0.125, -0.69, 0.44), "Gunmetal"),

		-- Long magazine sticking out of the grip
		box("Magazine", v3(0.15, 1.1, 0.23), v3(0, -1.24, 0.24), "Dark"),
		box("MagRibL", v3(0.04, 0.85, 0.06), v3(-0.08, -1.3, 0.24), "Grip"),
		box("MagRibR", v3(0.04, 0.85, 0.06), v3(0.08, -1.3, 0.24), "Grip"),
		box("MagBase", v3(0.17, 0.05, 0.25), v3(0, -1.795, 0.24), "Gunmetal"),
	},
}
