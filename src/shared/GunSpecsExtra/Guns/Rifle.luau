-- Assault Rifle: a black scoped rifle with a skeleton stock, a striped muzzle
-- device and a long round suppressor, built like the rifle on the gun wall picture.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

-- A thin ring tilted around X, so the muzzle stripes lean like a twist
local function ring(name, length, diameter, position, role, tilt)
	local part = tube(name, length, diameter, position, role)
	part.Offset = CFrame.new(position) * CFrame.Angles(math.rad(tilt), 0, 0) * CFrame.Angles(0, math.rad(90), 0)
	return part
end

local BORE = -0.08 -- height of the barrel line
local SCOPE = 0.215 -- height of the scope line

return {
	Factory = { Body = rgb(32, 33, 36), Accent = rgb(96, 100, 108) }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0, 0.1, -1),
	Muzzle = v3(0, BORE, -3.12),
	Support = v3(-0.04, -0.28, -1.12),
	Parts = {
		-- Receiver
		box("UpperReceiver", v3(0.27, 0.15, 1.3), v3(0, -0.005, -0.12), "Body"),
		box("LowerReceiver", v3(0.25, 0.14, 1.3), v3(0, -0.14, -0.12), "Body"),
		box("Rail", v3(0.16, 0.04, 1.3), v3(0, 0.085, -0.12), "Dark"),
		box("EjectionPort", v3(0.04, 0.07, 0.24), v3(0.12, 0, 0.02), "Dark"),
		box("BoltHandle", v3(0.08, 0.05, 0.06), v3(0.17, 0, 0.22), "Gunmetal"),
		drum("BoltKnob", 0.06, 0.08, v3(0.22, 0, 0.22), "Chrome"),
		drum("PinRear", 0.27, 0.045, v3(0, -0.15, 0.42), "Gunmetal"),
		drum("PinFront", 0.27, 0.045, v3(0, -0.15, -0.7), "Gunmetal"),
		wedge("Tang", v3(0.2, 0.05, 0.14), v3(0, 0.06, 0.6), "Body", v3(0, 180, 0)),
		drum("Safety", 0.27, 0.05, v3(0, -0.11, 0.25), "Gunmetal"),
		box("FluteLeft", v3(0.04, 0.04, 0.42), v3(-0.12, -0.04, -0.42), "Dark"),
		box("FluteRight", v3(0.04, 0.04, 0.42), v3(0.12, -0.04, -0.42), "Dark"),
		box("MagRelease", v3(0.04, 0.05, 0.05), v3(0.12, -0.24, -0.06), "Gunmetal"),

		-- Magazine
		box("MagWell", v3(0.24, 0.1, 0.7), v3(0, -0.245, -0.4), "Body"),
		box("Magazine", v3(0.18, 0.1, 0.64), v3(0, -0.325, -0.42), "Dark"),
		box("MagBase", v3(0.2, 0.04, 0.66), v3(0, -0.365, -0.42), "Gunmetal"),
		box("MagRibLeft", v3(0.04, 0.04, 0.5), v3(-0.08, -0.315, -0.42), "Gunmetal"),
		box("MagRibRight", v3(0.04, 0.04, 0.5), v3(0.08, -0.315, -0.42), "Gunmetal"),

		-- Grip and trigger
		box("Grip", v3(0.2, 0.46, 0.18), v3(0, -0.4, 0.32), "Grip", v3(-19, 0, 0)),
		box("TriggerGuard", v3(0.06, 0.045, 0.24), v3(0, -0.3, 0.06), "Dark"),
		box("TriggerGuardFront", v3(0.06, 0.12, 0.045), v3(0, -0.255, -0.055), "Dark"),
		box("Trigger", v3(0.04, 0.1, 0.04), v3(0, -0.255, 0.08), "Metal", v3(12, 0, 0)),

		-- Skeleton stock
		drum("Hinge", 0.22, 0.13, v3(0, -0.06, 0.54), "Gunmetal"),
		box("StockTop", v3(0.18, 0.18, 0.56), v3(0, -0.055, 0.8), "Body"),
		box("StockSlotLeft", v3(0.04, 0.06, 0.34), v3(-0.075, -0.055, 0.8), "Dark"),
		box("StockSlotRight", v3(0.04, 0.06, 0.34), v3(0.075, -0.055, 0.8), "Dark"),
		box("Butt", v3(0.22, 0.64, 0.17), v3(0, -0.265, 1.145), "Body"),
		box("ButtPad", v3(0.23, 0.6, 0.06), v3(0, -0.295, 1.25), "Rubber"),
		box("StockBottom", v3(0.17, 0.11, 0.74), v3(0, -0.503, 0.74), "Body", v3(-5.9, 0, 0)),
		box("FrameFoot", v3(0.21, 0.08, 0.28), v3(0, -0.59, 0.4), "Body"),
		wedge("GussetTop", v3(0.17, 0.07, 0.09), v3(0, -0.17, 1.02), "Body", v3(0, 0, 180)),
		wedge("GussetBottom", v3(0.17, 0.08, 0.1), v3(0, -0.39, 1.015), "Body"),
		drum("SlingCup", 0.24, 0.07, v3(0, -0.47, 1.12), "Gunmetal"),

		-- Handguard
		box("HandguardCollar", v3(0.27, 0.3, 0.22), v3(0, -0.085, -0.88), "Body"),
		box("Handguard", v3(0.25, 0.18, 0.5), v3(0, -0.09, -1.225), "Body"),
		wedge("HandguardTop", v3(0.25, 0.045, 0.5), v3(0, 0.0225, -1.225), "Body"),
		wedge("HandguardBelly", v3(0.25, 0.05, 0.5), v3(0, -0.205, -1.225), "Body", v3(0, 0, 180)),
		box("SlotLeft1", v3(0.04, 0.05, 0.09), v3(-0.11, -0.11, -1.08), "Dark"),
		box("SlotLeft2", v3(0.04, 0.05, 0.09), v3(-0.11, -0.11, -1.21), "Dark"),
		box("SlotLeft3", v3(0.04, 0.05, 0.09), v3(-0.11, -0.11, -1.34), "Dark"),
		box("SlotRight1", v3(0.04, 0.05, 0.09), v3(0.11, -0.11, -1.08), "Dark"),
		box("SlotRight2", v3(0.04, 0.05, 0.09), v3(0.11, -0.11, -1.21), "Dark"),
		box("SlotRight3", v3(0.04, 0.05, 0.09), v3(0.11, -0.11, -1.34), "Dark"),
		box("StripLeft", v3(0.04, 0.04, 0.4), v3(-0.11, -0.03, -1.22), "Accent"),
		box("StripRight", v3(0.04, 0.04, 0.4), v3(0.11, -0.03, -1.22), "Accent"),

		-- Barrel and striped muzzle device
		tube("Barrel", 0.82, 0.11, v3(0, BORE, -1.86), "Metal"),
		tube("MuzzleCore", 0.42, 0.2, v3(0, BORE, -1.69), "Dark"),
		tube("MuzzleCollar", 0.04, 0.19, v3(0, BORE, -1.905), "Gunmetal"),
		ring("Stripe1", 0.04, 0.21, v3(0, BORE, -1.515), "White", -14),
		ring("Stripe2", 0.04, 0.21, v3(0, BORE, -1.6), "White", -14),
		ring("Stripe3", 0.04, 0.21, v3(0, BORE, -1.685), "White", -14),
		ring("Stripe4", 0.04, 0.21, v3(0, BORE, -1.77), "White", -14),
		ring("Stripe5", 0.04, 0.21, v3(0, BORE, -1.855), "White", -14),

		-- Suppressor
		tube("SuppressorNeck1", 0.06, 0.15, v3(0, BORE, -2.05), "Dark"),
		tube("SuppressorNeck2", 0.06, 0.19, v3(0, BORE, -2.11), "Dark"),
		tube("SuppressorRear", 0.34, 0.24, v3(0, BORE, -2.31), "Dark"),
		tube("SuppressorBand", 0.04, 0.25, v3(0, BORE, -2.18), "Gunmetal"),
		tube("SuppressorMid", 0.18, 0.22, v3(0, BORE, -2.56), "Dark"),
		tube("SuppressorFront", 0.42, 0.2, v3(0, BORE, -2.85), "Dark"),
		tube("SuppressorFrontBand", 0.04, 0.21, v3(0, BORE, -2.98), "Gunmetal"),
		ball("SuppressorTip", 0.17, v3(0, BORE, -3.035), "Dark"),

		-- Scope
		tube("ScopeEyecup", 0.06, 0.18, v3(0, SCOPE, 0), "Rubber"),
		tube("ScopeEyeLens", 0.04, 0.12, v3(0, SCOPE, 0.02), "Lens"),
		tube("ScopeEyepiece", 0.13, 0.19, v3(0, SCOPE, -0.07), "Dark"),
		tube("ScopePowerRing", 0.04, 0.2, v3(0, SCOPE, -0.05), "Gunmetal"),
		tube("ScopeTube", 0.34, 0.145, v3(0, SCOPE, -0.27), "Dark"),
		tube("ScopeCone", 0.05, 0.18, v3(0, SCOPE, -0.455), "Dark"),
		tube("ScopeObjective", 0.38, 0.215, v3(0, SCOPE, -0.64), "Dark"),
		tube("ScopeGlow", 0.04, 0.222, v3(0, SCOPE, -0.77), "Accent"),
		tube("ScopeLens", 0.04, 0.18, v3(0, SCOPE, -0.835), "Lens"),
		disc("TurretTop", 0.04, 0.09, v3(0, SCOPE + 0.08, -0.27), "Gunmetal"),
		drum("TurretSide", 0.06, 0.09, v3(0.09, SCOPE, -0.27), "Gunmetal"),
		drum("TurretLeft", 0.06, 0.09, v3(-0.09, SCOPE, -0.27), "Gunmetal"),
		tube("MountRingRear", 0.06, 0.17, v3(0, SCOPE, -0.13), "Dark"),
		box("MountBaseRear", v3(0.12, 0.07, 0.08), v3(0, 0.125, -0.13), "Dark"),
		drum("MountBoltRear", 0.15, 0.045, v3(0, 0.125, -0.13), "Chrome"),
		tube("MountRingFront", 0.06, 0.17, v3(0, SCOPE, -0.33), "Dark"),
		box("MountBaseFront", v3(0.12, 0.07, 0.08), v3(0, 0.125, -0.33), "Dark"),
		drum("MountBoltFront", 0.15, 0.045, v3(0, 0.125, -0.33), "Chrome"),
	},
}
