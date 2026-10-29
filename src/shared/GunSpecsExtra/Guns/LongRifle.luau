-- Long Rifle: a very long bolt-action rifle with a fishtail stock, a full-length fore-end,
-- a small scope and a sling ring by the muzzle, based on the long black rifle in the gun wall picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

return {
	Factory = { Body = rgb(40, 41, 44), Accent = rgb(96, 100, 108) }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.12, -0.95),
	Muzzle = v3(0, -0.27, -4.33),
	Support = v3(-0.03, -0.37, -1.55),
	Parts = {
		-- Fishtail stock
		box("StockWrist", v3(0.2, 0.228, 0.679), v3(0, -0.388, 0.262), "Body", v3(19.5, 0, 0)),
		box("StockComb", v3(0.22, 0.18, 0.55), v3(0, -0.426, 0.675), "Body"),
		wedge("StockHorn", v3(0.24, 0.422, 0.432), v3(0, -0.192, 0.955), "Body", v3(15.8, 0, 0)),
		egg("HornTip", v3(0.24, 0.1, 0.2), v3(0, -0.067, 1.15), "Body"),
		box("ButtCenter", v3(0.24, 0.265, 0.335), v3(0, -0.453, 0.967), "Body"),
		box("StockBelly", v3(0.24, 0.24, 0.69), v3(0, -0.717, 0.865), "Body", v3(37.6, 0, 0)),
		box("StockToe", v3(0.24, 0.18, 0.474), v3(0, -0.808, 1.119), "Body", v3(72.8, 0, 0)),

		-- Receiver
		box("StockMid", v3(0.22, 0.148, 1.34), v3(0, -0.374, -0.65), "Body"),
		box("Receiver", v3(0.18, 0.09, 1.28), v3(0, -0.255, -0.66), "Gunmetal"),
		egg("BoltShroud", v3(0.19, 0.14, 0.5), v3(0, -0.225, -0.2), "Gunmetal"),
		tube("ReceiverRing", 0.14, 0.14, v3(0, -0.27, -1.25), "Gunmetal"),
		box("EjectionPort", v3(0.04, 0.05, 0.22), v3(0.08, -0.235, -0.45), "Dark"),
		box("BoltHandle", v3(0.13, 0.04, 0.045), v3(0.143, -0.277, -0.08), "Gunmetal", v3(0, 0, -35)),
		ball("BoltKnob", 0.08, v3(0.2, -0.32, -0.08), "Gunmetal"),
		drum("PinRear", 0.235, 0.05, v3(0, -0.4, -0.25), "Metal"),
		drum("PinFront", 0.235, 0.05, v3(0, -0.4, -1.2), "Metal"),

		-- Trigger and guard
		box("TriggerPlate", v3(0.08, 0.04, 0.46), v3(0, -0.455, -0.008), "Gunmetal"),
		box("GuardFront", v3(0.05, 0.263, 0.045), v3(0, -0.579, -0.207), "Chrome"),
		box("GuardBack", v3(0.05, 0.236, 0.045), v3(0, -0.593, 0.191), "Chrome"),
		box("GuardBottom", v3(0.05, 0.045, 0.443), v3(0, -0.695, -0.009), "Chrome"),
		box("TriggerTop", v3(0.04, 0.09, 0.05), v3(0, -0.49, -0.01), "Dark"),
		box("TriggerBlade", v3(0.04, 0.1, 0.05), v3(0, -0.57, -0.005), "Dark", v3(20, 0, 0)),

		-- Fore-end
		box("ForeEndRear", v3(0.2, 0.156, 0.5), v3(0, -0.328, -1.55), "Body"),
		wedge("ForeEndTaper", v3(0.2, 0.15, 0.042), v3(0, -0.385, -1.875), "Body", v3(-90, 0, 0)),
		box("Forestock", v3(0.16, 0.114, 2.13), v3(0, -0.307, -2.865), "Body"),
		box("BandRear", v3(0.22, 0.2, 0.05), v3(0, -0.315, -1.642), "Gunmetal"),
		box("BandMiddle", v3(0.18, 0.16, 0.045), v3(0, -0.295, -2.056), "Gunmetal"),
		box("BandFront", v3(0.18, 0.16, 0.045), v3(0, -0.295, -2.703), "Gunmetal"),
		box("BandNose", v3(0.18, 0.16, 0.045), v3(0, -0.295, -3.616), "Gunmetal"),
		box("NoseCap", v3(0.17, 0.125, 0.07), v3(0, -0.305, -3.905), "Gunmetal"),
		box("TrimLeft", v3(0.04, 0.04, 0.5), v3(-0.1, -0.33, -1.53), "Accent"),
		box("TrimRight", v3(0.04, 0.04, 0.5), v3(0.1, -0.33, -1.53), "Accent"),

		-- Barrel
		tube("Barrel", 3.1, 0.09, v3(0, -0.27, -2.75), "Gunmetal"),
		tube("MuzzleRing", 0.06, 0.11, v3(0, -0.27, -4.3), "Gunmetal"),
		box("FrontSight", v3(0.04, 0.04, 0.07), v3(0, -0.215, -4.24), "Gunmetal"),
		box("SightDot", v3(0.04, 0.04, 0.04), v3(0, -0.185, -4.24), "Accent"),

		-- Sling ring
		box("SlingStud", v3(0.05, 0.06, 0.06), v3(0, -0.335, -4.201), "Gunmetal"),
		box("SlingRingBack", v3(0.04, 0.04, 0.24), v3(0, -0.391, -4.103), "Gunmetal", v3(35.8, 0, 0)),
		box("SlingRingLow", v3(0.04, 0.04, 0.176), v3(0, -0.442, -4.091), "Gunmetal", v3(-167.2, 0, 0)),
		box("SlingRingFront", v3(0.04, 0.04, 0.104), v3(0, -0.371, -4.189), "Gunmetal", v3(-103, 0, 0)),

		-- Scope
		tube("ScopeEyecup", 0.07, 0.08, v3(0, -0.122, -0.53), "Dark"),
		tube("ScopeTube", 0.32, 0.06, v3(0, -0.122, -0.7), "Gunmetal"),
		disc("ScopeTurret", 0.05, 0.05, v3(0, -0.075, -0.78), "Gunmetal"),
		drum("ScopeWindage", 0.05, 0.045, v3(0.045, -0.122, -0.78), "Gunmetal"),
		tube("ScopeCollar", 0.05, 0.105, v3(0, -0.122, -0.835), "Dark"),
		tube("ScopeBody", 0.43, 0.1, v3(0, -0.122, -1.035), "Gunmetal"),
		tube("ScopeRing", 0.04, 0.108, v3(0, -0.122, -1.18), "Accent"),
		tube("ScopeBell", 0.05, 0.11, v3(0, -0.122, -1.245), "Dark"),
		tube("ScopeLens", 0.04, 0.08, v3(0, -0.122, -1.255), "Lens"),
		box("MountRear", v3(0.06, 0.05, 0.07), v3(0, -0.19, -0.6), "Gunmetal"),
		tube("MountRingRear", 0.05, 0.08, v3(0, -0.122, -0.6), "Dark"),
		box("MountFront", v3(0.06, 0.05, 0.07), v3(0, -0.19, -1), "Gunmetal"),
		tube("MountRingFront", 0.05, 0.12, v3(0, -0.122, -1), "Dark"),
	},
}
