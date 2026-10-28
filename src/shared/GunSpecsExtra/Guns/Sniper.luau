-- Sniper Rifle: a big black anti-materiel rifle with a skeleton stock, a scope on rings,
-- a heavy barrel with a muzzle brake and a monopod, based on the black sniper in the blocky gun picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(30, 31, 34), Accent = rgb(96, 100, 108) }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.05, -0.9),
	Muzzle = v3(0, 0.18, -3.73),
	Support = v3(-0.04, -0.15, -1.25),
	Parts = {
		-- Receiver
		box("Receiver", v3(0.3, 0.31, 1.22), v3(0, 0.135, -0.16), "Body"),
		box("LowerReceiver", v3(0.28, 0.21, 0.8), v3(0, -0.115, 0.04), "Body"),
		box("MagWell", v3(0.28, 0.12, 0.44), v3(0, -0.07, -0.56), "Body"),
		box("EjectionPort", v3(0.04, 0.09, 0.32), v3(0.141, 0.17, -0.3), "Dark"),
		box("BoltHandle", v3(0.12, 0.05, 0.05), v3(0.2, 0.17, 0.02), "Gunmetal"),
		ball("BoltKnob", 0.08, v3(0.26, 0.17, 0.02), "Gunmetal"),
		drum("PinFront", 0.31, 0.05, v3(0, 0.03, -0.62), "Metal"),
		drum("PinBack", 0.31, 0.05, v3(0, 0.03, 0.36), "Metal"),
		drum("Safety", 0.29, 0.06, v3(0, -0.1, 0.24), "Metal"),
		box("MagRelease", v3(0.04, 0.06, 0.06), v3(0.135, -0.12, -0.28), "Gunmetal"),

		-- Top rail
		box("Rail", v3(0.15, 0.04, 1.1), v3(0, 0.3, -0.25), "Gunmetal"),
		box("RailSlot1", v3(0.16, 0.04, 0.04), v3(0, 0.305, 0.2), "Dark"),
		box("RailSlot2", v3(0.16, 0.04, 0.04), v3(0, 0.305, 0.06), "Dark"),
		box("RailSlot3", v3(0.16, 0.04, 0.04), v3(0, 0.305, -0.08), "Dark"),
		box("RailSlot4", v3(0.16, 0.04, 0.04), v3(0, 0.305, -0.47), "Dark"),
		box("RailSlot5", v3(0.16, 0.04, 0.04), v3(0, 0.305, -0.76), "Dark"),

		-- Handguard
		box("Handguard", v3(0.28, 0.29, 1.34), v3(0, 0.125, -1.42), "Body"),
		box("VentLeft1", v3(0.04, 0.07, 0.16), v3(-0.131, 0.11, -0.9), "Dark"),
		box("VentLeft2", v3(0.04, 0.07, 0.16), v3(-0.131, 0.11, -1.15), "Dark"),
		box("VentLeft3", v3(0.04, 0.07, 0.16), v3(-0.131, 0.11, -1.4), "Dark"),
		box("VentLeft4", v3(0.04, 0.07, 0.16), v3(-0.131, 0.11, -1.65), "Dark"),
		box("VentRight1", v3(0.04, 0.07, 0.16), v3(0.131, 0.11, -0.9), "Dark"),
		box("VentRight2", v3(0.04, 0.07, 0.16), v3(0.131, 0.11, -1.15), "Dark"),
		box("VentRight3", v3(0.04, 0.07, 0.16), v3(0.131, 0.11, -1.4), "Dark"),
		box("VentRight4", v3(0.04, 0.07, 0.16), v3(0.131, 0.11, -1.65), "Dark"),
		box("FrontCap", v3(0.26, 0.27, 0.04), v3(0, 0.125, -2.1), "Gunmetal"),
		drum("SlingLoopFront", 0.04, 0.08, v3(0, -0.04, -1.72), "Metal"),

		-- Barrel
		box("BarrelKey", v3(0.16, 0.1, 0.08), v3(0, 0.07, -2.15), "Gunmetal"),
		tube("BarrelNut", 0.06, 0.2, v3(0, 0.18, -2.15), "Gunmetal"),
		tube("BarrelBase", 0.3, 0.16, v3(0, 0.18, -2.31), "Gunmetal"),
		tube("Barrel", 1, 0.14, v3(0, 0.18, -2.86), "Gunmetal"),

		-- Muzzle brake
		tube("BrakeCollar", 0.05, 0.17, v3(0, 0.18, -3.335), "Gunmetal"),
		box("BrakeCore", v3(0.17, 0.2, 0.38), v3(0, 0.18, -3.53), "Dark"),
		box("BrakeBaffle1", v3(0.22, 0.21, 0.065), v3(0, 0.18, -3.3925), "Gunmetal"),
		box("BrakeBaffle2", v3(0.22, 0.21, 0.065), v3(0, 0.18, -3.5025), "Gunmetal"),
		box("BrakeBaffle3", v3(0.22, 0.21, 0.065), v3(0, 0.18, -3.6125), "Gunmetal"),
		box("BrakeFront", v3(0.22, 0.21, 0.04), v3(0, 0.18, -3.705), "Gunmetal"),
		tube("Bore", 0.04, 0.09, v3(0, 0.18, -3.715), "Dark"),

		-- Scope
		tube("Eyecup", 0.08, 0.17, v3(0, 0.48, 0.03), "Rubber"),
		tube("RearLens", 0.04, 0.12, v3(0, 0.48, 0.065), "Lens"),
		tube("Eyepiece", 0.22, 0.15, v3(0, 0.48, -0.11), "Dark"),
		tube("EyepieceStep", 0.06, 0.135, v3(0, 0.48, -0.24), "Dark"),
		tube("DiopterRing", 0.04, 0.16, v3(0, 0.48, -0.06), "Gunmetal"),
		tube("ScopeTube", 0.62, 0.12, v3(0, 0.48, -0.5), "Dark"),
		tube("TurretHousing", 0.16, 0.15, v3(0, 0.48, -0.46), "Dark"),
		disc("ElevationTurret", 0.08, 0.1, v3(0, 0.585, -0.46), "Gunmetal"),
		disc("ElevationCap", 0.04, 0.07, v3(0, 0.63, -0.46), "Accent"),
		drum("WindageTurret", 0.08, 0.09, v3(0.1, 0.48, -0.46), "Gunmetal"),
		tube("ObjectiveStep", 0.06, 0.18, v3(0, 0.48, -0.77), "Dark"),
		tube("FocusRing", 0.04, 0.25, v3(0, 0.48, -0.86), "Gunmetal"),
		tube("Objective", 0.18, 0.24, v3(0, 0.48, -0.89), "Dark"),
		tube("FrontLens", 0.04, 0.19, v3(0, 0.48, -0.985), "Lens"),

		-- Scope rings
		tube("RingBack", 0.06, 0.165, v3(0, 0.48, -0.3), "Gunmetal"),
		tube("RingFront", 0.06, 0.165, v3(0, 0.48, -0.65), "Gunmetal"),
		box("RingBaseBack", v3(0.12, 0.09, 0.1), v3(0, 0.365, -0.3), "Gunmetal"),
		box("RingBaseFront", v3(0.12, 0.09, 0.1), v3(0, 0.365, -0.65), "Gunmetal"),
		drum("RingBoltBack", 0.16, 0.04, v3(0, 0.355, -0.3), "Metal"),
		drum("RingBoltFront", 0.16, 0.04, v3(0, 0.355, -0.65), "Metal"),

		-- Stock
		box("StockNeck", v3(0.24, 0.31, 0.26), v3(0, 0.135, 0.56), "Body"),
		box("Stock", v3(0.26, 0.355, 0.79), v3(0, 0.1225, 1.055), "Body"),
		box("CheekRiser", v3(0.26, 0.046, 0.75), v3(0, 0.313, 1.035), "Body"),
		wedge("StockRamp", v3(0.26, 0.046, 0.08), v3(0, 0.313, 0.62), "Body"),
		wedge("StockHeel", v3(0.26, 0.046, 0.04), v3(0, 0.313, 1.43), "Body", v3(0, 180, 0)),
		box("ButtPad", v3(0.27, 0.36, 0.05), v3(0, 0.125, 1.475), "Rubber"),
		box("StockCutLeft", v3(0.04, 0.16, 0.5), v3(-0.121, 0.12, 1.04), "Dark"),
		box("StockCutRight", v3(0.04, 0.16, 0.5), v3(0.121, 0.12, 1.04), "Dark"),
		box("StockBackLeg", v3(0.2, 0.4, 0.1), v3(0, -0.21, 1.35), "Body", v3(22, 0, 0)),
		box("HeelPad", v3(0.21, 0.24, 0.04), v3(0, -0.305, 1.371), "Rubber", v3(22, 0, 0)),
		box("StockBottom", v3(0.2, 0.09, 0.56), v3(0, -0.345, 1.06), "Body", v3(5, 0, 0)),
		box("StockFrontLeg", v3(0.2, 0.37, 0.12), v3(0, -0.19, 0.805), "Body", v3(-18, 0, 0)),
		drum("SlingLoopBack", 0.04, 0.08, v3(0, -0.41, 0.98), "Metal"),

		-- Grip and trigger
		box("Grip", v3(0.24, 0.5, 0.27), v3(0, -0.42, 0.295), "Grip", v3(-5, 0, 0)),
		box("GripPanelLeft", v3(0.04, 0.32, 0.18), v3(-0.115, -0.44, 0.297), "Rubber", v3(-5, 0, 0)),
		box("GripPanelRight", v3(0.04, 0.32, 0.18), v3(0.115, -0.44, 0.297), "Rubber", v3(-5, 0, 0)),
		box("GripBase", v3(0.26, 0.05, 0.3), v3(0, -0.659, 0.316), "Dark", v3(-5, 0, 0)),
		box("TriggerGuardBottom", v3(0.06, 0.04, 0.21), v3(0, -0.315, 0.065), "Gunmetal"),
		box("TriggerGuardFront", v3(0.06, 0.12, 0.04), v3(0, -0.275, -0.03), "Gunmetal"),
		box("Trigger", v3(0.04, 0.11, 0.05), v3(0, -0.26, 0.07), "Metal", v3(15, 0, 0)),

		-- Magazine
		box("Magazine", v3(0.2, 0.5, 0.34), v3(0, -0.33, -0.57), "Dark"),
		box("MagRibTop", v3(0.21, 0.04, 0.3), v3(0, -0.24, -0.57), "Gunmetal"),
		box("MagRibBottom", v3(0.21, 0.04, 0.3), v3(0, -0.44, -0.57), "Gunmetal"),
		box("MagBase", v3(0.22, 0.05, 0.37), v3(0, -0.595, -0.57), "Gunmetal"),

		-- Monopod
		box("MonopodMount", v3(0.18, 0.07, 0.16), v3(0, -0.045, -2.02), "Gunmetal"),
		wedge("MonopodMountRamp", v3(0.18, 0.07, 0.08), v3(0, -0.045, -1.9), "Gunmetal", v3(180, 0, 0)),
		drum("MonopodHinge", 0.2, 0.08, v3(0, -0.09, -1.97), "Metal"),
		disc("MonopodLeg", 0.3, 0.075, v3(0, -0.24, -1.97), "Gunmetal"),
		disc("MonopodCollar", 0.04, 0.1, v3(0, -0.38, -1.97), "Metal"),
		disc("MonopodLower", 0.08, 0.055, v3(0, -0.43, -1.97), "Chrome"),
		disc("MonopodFoot", 0.05, 0.17, v3(0, -0.47, -1.97), "Rubber"),
		disc("MonopodSpike", 0.1, 0.045, v3(0, -0.54, -1.97), "Chrome"),
		ball("MonopodTip", 0.05, v3(0, -0.6, -1.97), "Chrome"),

		-- Glow
		box("TrimLeft", v3(0.04, 0.035, 0.7), v3(-0.131, 0.215, -1.3), "Accent"),
		box("TrimRight", v3(0.04, 0.035, 0.7), v3(0.131, 0.215, -1.3), "Accent"),
	},
}
