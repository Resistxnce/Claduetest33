-- Pistol: the starter gun, a modern striker-fired semi-auto (Glock style) with
-- a serrated slide, three-dot sights, an accessory rail and a raked grip.
local Shapes = require(script.Parent.Parent.Shapes)
local box, wedge, egg, tube, disc, drum, ball, v3, rgb =
	Shapes.box, Shapes.wedge, Shapes.egg, Shapes.tube, Shapes.disc, Shapes.drum, Shapes.ball, Shapes.v3, Shapes.rgb

-- The grip leans back 20 degrees around the hand position. Grip parts are
-- placed along it: x across, y up the grip, z toward the back of the grip.
local GRIP_TILT = v3(-20, 0, 0)
local GRIP = CFrame.new(0, -0.383, 0.283) * CFrame.Angles(math.rad(-20), 0, 0)
local function onGrip(x, y, z)
	return (GRIP * CFrame.new(x, y, z)).Position
end

return {
	Factory = { Body = rgb(34, 35, 38), Accent = rgb(255, 46, 99), Material = Enum.Material.SmoothPlastic },
	View = CFrame.new(0, 0, 0),
	Muzzle = v3(0, 0.22, -1.05),
	Support = v3(-0.12, -0.46, 0.16),
	Parts = {
		-- Slide
		box("Slide", v3(0.26, 0.19, 1.48), v3(0, 0.185, -0.26), "Body"),
		box("SlideTop", v3(0.16, 0.05, 1.43), v3(0, 0.305, -0.235), "Body"),
		wedge("SlideBevelL", v3(1.43, 0.05, 0.05), v3(-0.105, 0.305, -0.235), "Body", v3(0, 90, 0)),
		wedge("SlideBevelR", v3(1.43, 0.05, 0.05), v3(0.105, 0.305, -0.235), "Body", v3(0, -90, 0)),
		wedge("SlideNose", v3(0.2, 0.05, 0.05), v3(0, 0.305, -0.975), "Body"),
		box("SlideSeam", v3(0.245, 0.04, 1.44), v3(0, 0.09, -0.25), "Dark"),
		box("StrikerPlate", v3(0.14, 0.13, 0.04), v3(0, 0.19, 0.47), "Gunmetal"),

		-- Slide serrations, rear and front
		box("RearSerration1", v3(0.27, 0.15, 0.04), v3(0, 0.19, 0.43), "Dark"),
		box("RearSerration2", v3(0.27, 0.15, 0.04), v3(0, 0.19, 0.355), "Dark"),
		box("RearSerration3", v3(0.27, 0.15, 0.04), v3(0, 0.19, 0.28), "Dark"),
		box("RearSerration4", v3(0.27, 0.15, 0.04), v3(0, 0.19, 0.205), "Dark"),
		box("FrontSerration1", v3(0.27, 0.12, 0.04), v3(0, 0.2, -0.86), "Dark"),
		box("FrontSerration2", v3(0.27, 0.12, 0.04), v3(0, 0.2, -0.785), "Dark"),
		box("FrontSerration3", v3(0.27, 0.12, 0.04), v3(0, 0.2, -0.71), "Dark"),

		-- Ejection port (right side), the barrel hood showing through it, and the extractor
		box("PortSide", v3(0.04, 0.11, 0.3), v3(0.115, 0.225, -0.15), "Dark"),
		wedge("PortBevel", v3(0.3, 0.055, 0.055), v3(0.1075, 0.3075, -0.15), "Dark", v3(0, -90, 0)),
		box("PortTop", v3(0.085, 0.04, 0.3), v3(0.0425, 0.313, -0.15), "Dark"),
		box("HoodTop", v3(0.08, 0.04, 0.24), v3(0.04, 0.315, -0.17), "Gunmetal"),
		box("HoodSide", v3(0.04, 0.07, 0.22), v3(0.12, 0.23, -0.17), "Gunmetal"),
		box("Extractor", v3(0.04, 0.04, 0.12), v3(0.125, 0.25, 0.06), "Gunmetal"),

		-- Barrel and recoil spring rod at the front
		tube("Barrel", 0.12, 0.13, v3(0, 0.22, -0.99), "Gunmetal"),
		tube("Bore", 0.04, 0.07, v3(0, 0.22, -1.03), "Dark"),
		tube("GuideRod", 0.04, 0.07, v3(0, 0.12, -1.0), "Gunmetal"),

		-- Sights (three dots)
		box("FrontSight", v3(0.06, 0.08, 0.07), v3(0, 0.37, -0.9), "Dark"),
		box("FrontDot", v3(0.04, 0.04, 0.04), v3(0, 0.375, -0.87), "Accent"),
		box("RearSightBase", v3(0.2, 0.04, 0.09), v3(0, 0.35, 0.38), "Dark"),
		box("RearSightL", v3(0.06, 0.05, 0.09), v3(-0.07, 0.395, 0.38), "Dark"),
		box("RearSightR", v3(0.06, 0.05, 0.09), v3(0.07, 0.395, 0.38), "Dark"),
		box("RearDotL", v3(0.04, 0.04, 0.04), v3(-0.07, 0.395, 0.42), "Accent"),
		box("RearDotR", v3(0.04, 0.04, 0.04), v3(0.07, 0.395, 0.42), "Accent"),

		-- Frame, beavertail and rail
		box("Frame", v3(0.23, 0.17, 1.24), v3(0, 0.005, -0.26), "Body"),
		wedge("FrameNose", v3(0.23, 0.17, 0.05), v3(0, 0.005, -0.905), "Body", v3(0, 0, 180)),
		box("Beavertail", v3(0.21, 0.1, 0.22), v3(0, 0.044, 0.409), "Body", v3(-39, 0, 0)),
		drum("BeavertailTip", 0.21, 0.07, v3(0, 0.055, 0.5), "Body"),
		box("RailNeck", v3(0.13, 0.03, 0.38), v3(0, -0.09, -0.645), "Body"),
		box("Rail", v3(0.19, 0.04, 0.38), v3(0, -0.12, -0.645), "Body"),
		box("RailSlot1", v3(0.2, 0.04, 0.04), v3(0, -0.125, -0.77), "Dark"),
		box("RailSlot2", v3(0.2, 0.04, 0.04), v3(0, -0.125, -0.645), "Dark"),
		box("RailSlot3", v3(0.2, 0.04, 0.04), v3(0, -0.125, -0.52), "Dark"),

		-- Controls and pins
		box("TakedownLever", v3(0.25, 0.05, 0.06), v3(0, 0.03, -0.2), "Gunmetal"),
		box("SlideStop", v3(0.04, 0.05, 0.16), v3(-0.125, 0.06, -0.04), "Gunmetal"),
		drum("TriggerPin", 0.24, 0.045, v3(0, -0.03, -0.02), "Gunmetal"),
		drum("BlockPin", 0.24, 0.045, v3(0, -0.03, -0.3), "Gunmetal"),
		drum("HousingPin", 0.24, 0.045, v3(0, -0.02, 0.38), "Gunmetal"),
		box("MagRelease", v3(0.25, 0.06, 0.07), v3(0, -0.13, 0.06), "Gunmetal"),

		-- Trigger guard and trigger
		box("GuardFront", v3(0.11, 0.22, 0.05), v3(0, -0.2, -0.37), "Body"),
		box("GuardBottom", v3(0.11, 0.05, 0.46), v3(0, -0.285, -0.16), "Body"),
		box("GuardCorner", v3(0.11, 0.06, 0.06), v3(0, -0.27, -0.36), "Body", v3(45, 0, 0)),
		box("GuardGroove1", v3(0.1, 0.04, 0.04), v3(0, -0.15, -0.39), "Dark"),
		box("GuardGroove2", v3(0.1, 0.04, 0.04), v3(0, -0.21, -0.39), "Dark"),
		box("GuardRear", v3(0.22, 0.08, 0.14), v3(0, -0.1, 0.05), "Body"),
		box("TriggerBar", v3(0.05, 0.11, 0.045), v3(0, -0.13, -0.115), "Dark", v3(-6, 0, 0)),
		box("TriggerShoe", v3(0.05, 0.08, 0.045), v3(0, -0.21, -0.13), "Dark", v3(30, 0, 0)),
		box("TriggerSafety", v3(0.04, 0.06, 0.04), v3(0, -0.17, -0.13), "Gunmetal", v3(10, 0, 0)),

		-- Grip
		box("Grip", v3(0.23, 0.7, 0.34), onGrip(0, 0, 0), "Body", GRIP_TILT),
		box("GripPanel", v3(0.245, 0.39, 0.26), onGrip(0, -0.045, 0), "Rubber", GRIP_TILT),
		box("GripRib1", v3(0.255, 0.04, 0.24), onGrip(0, 0.11, 0), "Grip", GRIP_TILT),
		box("GripRib2", v3(0.255, 0.04, 0.24), onGrip(0, 0.035, 0), "Grip", GRIP_TILT),
		box("GripRib3", v3(0.255, 0.04, 0.24), onGrip(0, -0.04, 0), "Grip", GRIP_TILT),
		box("GripRib4", v3(0.255, 0.04, 0.24), onGrip(0, -0.115, 0), "Grip", GRIP_TILT),
		box("GripRib5", v3(0.255, 0.04, 0.24), onGrip(0, -0.19, 0), "Grip", GRIP_TILT),
		box("Backstrap", v3(0.2, 0.62, 0.06), onGrip(0, 0.02, 0.17), "Body", GRIP_TILT),
		box("FrontStrap", v3(0.2, 0.4, 0.04), onGrip(0, -0.08, -0.17), "Rubber", GRIP_TILT),
		box("MagwellFlare", v3(0.25, 0.08, 0.36), onGrip(0, -0.31, 0), "Body", GRIP_TILT),
		box("MagwellScoop", v3(0.255, 0.06, 0.06), onGrip(0, -0.32, -0.16), "Dark", GRIP_TILT),
		box("LanyardSlot", v3(0.1, 0.05, 0.04), onGrip(0, -0.32, 0.166), "Dark", GRIP_TILT),
		box("MagBase", v3(0.25, 0.07, 0.38), onGrip(0, -0.38, 0.005), "Dark", GRIP_TILT),
		box("MagBaseLip", v3(0.21, 0.05, 0.05), onGrip(0, -0.395, -0.2), "Dark", GRIP_TILT),
	},
}
