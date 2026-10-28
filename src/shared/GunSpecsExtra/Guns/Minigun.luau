-- Minigun: a new look for the game's Minigun, based on the blocky Roblox minigun
-- in the reference picture (round motor housing, carry handle, rear grip, six barrels).
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

local spec = {
	Factory = { Body = rgb(28, 29, 32), Accent = rgb(96, 100, 108), Material = Enum.Material.Metal }, -- steel trim instead of a glow, like the picture
	View = CFrame.new(0.15, -0.18, -0.5),
	Muzzle = v3(0, 0, -2.62),
	Support = v3(0, 0.76, 0.26),
	Parts = {
		-- Motor housing
		box("BodyTop", v3(0.4, 0.28, 0.85), v3(0, 0.1, 0.175), "Body"),
		wedge("SlopeRight", v3(0.8, 0.2, 0.08), v3(0.24, 0.14, 0.2), "Body", v3(0, -90, 0)),
		wedge("SlopeLeft", v3(0.8, 0.2, 0.08), v3(-0.24, 0.14, 0.2), "Body", v3(0, 90, 0)),
		tube("BodyDrum", 0.85, 0.52, v3(0, -0.015, 0.175), "Body"),
		egg("BodyBack", v3(0.52, 0.5, 0.2), v3(0, -0.02, 0.57), "Body"),
		box("BodyLip", v3(0.46, 0.05, 0.78), v3(0, 0.245, 0.2), "Gunmetal"),
		box("RidgeRight", v3(0.04, 0.04, 0.78), v3(0.27, 0.04, 0.2), "Gunmetal"),
		box("RidgeLeft", v3(0.04, 0.04, 0.78), v3(-0.27, 0.04, 0.2), "Gunmetal"),
		box("PanelRight", v3(0.04, 0.2, 0.46), v3(0.25, -0.1, 0.26), "Gunmetal"),
		box("PanelLeft", v3(0.04, 0.2, 0.46), v3(-0.25, -0.1, 0.26), "Gunmetal"),
		box("VentRight1", v3(0.04, 0.12, 0.04), v3(0.27, -0.1, 0.13), "Dark"),
		box("VentRight2", v3(0.04, 0.12, 0.04), v3(0.27, -0.1, 0.21), "Dark"),
		box("VentRight3", v3(0.04, 0.12, 0.04), v3(0.27, -0.1, 0.29), "Dark"),
		box("VentLeft1", v3(0.04, 0.12, 0.04), v3(-0.27, -0.1, 0.13), "Dark"),
		box("VentLeft2", v3(0.04, 0.12, 0.04), v3(-0.27, -0.1, 0.21), "Dark"),
		box("VentLeft3", v3(0.04, 0.12, 0.04), v3(-0.27, -0.1, 0.29), "Dark"),
		drum("ScrewRight", 0.04, 0.05, v3(0.275, -0.1, 0.4), "Chrome"),
		drum("ScrewLeft", 0.04, 0.05, v3(-0.275, -0.1, 0.4), "Chrome"),

		-- Upper motor
		tube("Motor", 0.67, 0.33, v3(0, 0.38, 0.06), "Body"),
		tube("MotorBackCap", 0.05, 0.35, v3(0, 0.38, 0.39), "Gunmetal"),
		egg("MotorBackDome", v3(0.28, 0.28, 0.1), v3(0, 0.38, 0.41), "Body"),
		tube("MotorRib1", 0.04, 0.35, v3(0, 0.38, 0.22), "Gunmetal"),
		tube("MotorRib2", 0.04, 0.35, v3(0, 0.38, 0.15), "Gunmetal"),
		tube("MotorRib3", 0.04, 0.35, v3(0, 0.38, -0.12), "Gunmetal"),

		-- Carry handle, leaning back
		box("HandleFront", v3(0.09, 0.3, 0.08), v3(0, 0.6, 0.02), "Body", v3(-22, 0, 0)),
		box("HandleBack", v3(0.09, 0.3, 0.08), v3(0, 0.6, 0.4), "Body", v3(-22, 0, 0)),
		box("HandleWeb", v3(0.05, 0.22, 0.34), v3(0, 0.6, 0.21), "Dark", v3(-22, 0, 0)),
		box("HandleBar", v3(0.11, 0.08, 0.52), v3(0, 0.74, 0.27), "Rubber"),

		-- Rear block and knob
		box("RearBlock", v3(0.3, 0.2, 0.26), v3(0, 0.24, 0.65), "Body"),
		wedge("RearBlockSlope", v3(0.3, 0.06, 0.26), v3(0, 0.37, 0.65), "Body", v3(0, 180, 0)),
		box("RearStep", v3(0.22, 0.2, 0.12), v3(0, 0.06, 0.76), "Body"),
		wedge("RearStepSlope", v3(0.22, 0.12, 0.12), v3(0, -0.1, 0.76), "Body", v3(180, 0, 0)),
		tube("RearKnob", 0.08, 0.1, v3(0, 0.24, 0.8), "Dark"),
		tube("RearKnobCap", 0.05, 0.14, v3(0, 0.24, 0.825), "Gunmetal"),
		box("RearLight", v3(0.04, 0.06, 0.1), v3(-0.15, 0.26, 0.66), "Accent"),

		-- Rear grip
		box("GripMount", v3(0.28, 0.1, 0.5), v3(0, -0.28, 0.3), "Body"),
		box("Grip", v3(0.24, 0.4, 0.3), v3(0, -0.44, 0.31), "Grip", v3(-12, 0, 0)),
		box("GripPanelRight", v3(0.04, 0.26, 0.2), v3(0.12, -0.45, 0.32), "Rubber", v3(-12, 0, 0)),
		box("GripPanelLeft", v3(0.04, 0.26, 0.2), v3(-0.12, -0.45, 0.32), "Rubber", v3(-12, 0, 0)),
		box("GripFoot", v3(0.28, 0.07, 0.38), v3(0, -0.63, 0.36), "Gunmetal", v3(-12, 0, 0)),
		box("TriggerGuard", v3(0.06, 0.05, 0.24), v3(0, -0.55, 0.06), "Dark"),
		box("TriggerGuardFront", v3(0.06, 0.3, 0.05), v3(0, -0.41, -0.07), "Dark"),
		box("Trigger", v3(0.05, 0.13, 0.05), v3(0, -0.39, 0.09), "Metal", v3(-15, 0, 0)),

		-- Front collar and dome
		tube("Collar", 0.17, 0.56, v3(0, -0.01, -0.27), "Gunmetal"),
		box("CollarTop", v3(0.36, 0.16, 0.17), v3(0, 0.33, -0.27), "Gunmetal"),
		wedge("CollarTopFront", v3(0.36, 0.16, 0.08), v3(0, 0.33, -0.395), "Gunmetal"),
		box("CollarBoltRight", v3(0.04, 0.08, 0.06), v3(0.285, -0.06, -0.27), "Chrome"),
		box("CollarBoltLeft", v3(0.04, 0.08, 0.06), v3(-0.285, -0.06, -0.27), "Chrome"),
		tube("DomeRing", 0.12, 0.52, v3(0, 0, -0.41), "Body"),
		tube("DomeSeam", 0.04, 0.535, v3(0, 0, -0.375), "Accent"),
		egg("Dome", v3(0.52, 0.52, 0.16), v3(0, 0, -0.46), "Body"),

		-- Axle cap on the front clamp: it stays still while the barrels turn,
		-- and keeps the front of the gun in Parts so the skin preview fits it
		tube("AxleCap", 0.06, 0.16, v3(0, 0, -2.6), "Gunmetal"),
	},
	Spinning = {
		-- Clamp ring hub
		tube("Hub", 0.15, 0.6, v3(0, 0, -1.31), "Body"),
		tube("HubLipBack", 0.04, 0.62, v3(0, 0, -1.245), "Gunmetal"),
		tube("HubLipFront", 0.04, 0.62, v3(0, 0, -1.375), "Gunmetal"),

		-- Clamps
		tube("ClampOne", 0.06, 0.58, v3(0, 0, -1.912), "Body"),
		tube("ClampTwo", 0.06, 0.58, v3(0, 0, -2.21), "Body"),
		tube("ClampThree", 0.07, 0.58, v3(0, 0, -2.55), "Body"),
	},
}

-- Six barrels around the center line, one on top, each with a muzzle ring,
-- and a bolt on the hub between each pair
for index = 0, 5 do
	local angle = math.rad(90 + index * 60)
	local x, y = math.cos(angle) * 0.19, math.sin(angle) * 0.19
	table.insert(spec.Spinning, tube("Barrel" .. index + 1, 2.166, 0.085, v3(x, y, -1.533), "Gunmetal"))
	table.insert(spec.Spinning, tube("MuzzleRing" .. index + 1, 0.06, 0.11, v3(x, y, -2.59), "Metal"))
	local boltAngle = angle + math.rad(30)
	table.insert(spec.Spinning, tube("HubBolt" .. index + 1, 0.22, 0.05, v3(math.cos(boltAngle) * 0.25, math.sin(boltAngle) * 0.25, -1.31), "Chrome"))
end

return spec
