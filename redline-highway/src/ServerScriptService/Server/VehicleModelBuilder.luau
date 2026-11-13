--[[
	VehicleModelBuilder
	Builds a car model from a vehicle configuration.

	Physics comes from one invisible part, MassBox, placed at the centre of mass and sized like
	the car's mass distribution, with its density set so it weighs exactly the configured mass.
	Everything else is massless, so mass, centre of mass and rotational inertia are all correct.

	The visible body here is a stand-in (graybox) built to the real dimensions. The Phase 2 Blender
	model replaces the "Body" model and the Wheel_* parts and must keep these names:
	  MassBox                          the physics root (keep as is)
	  Body                             a Model of visual parts, welded to MassBox
	  Wheel_FL, Wheel_FR, Wheel_RL, Wheel_RR   visual wheels, moved by Motor6Ds WheelJoint_*
	  DriverSeat                       a Seat where the driver sits
	  ChaseCamTarget, HoodCam, CockpitCam      camera attachments on MassBox
	  ForcePoint_*, WheelForce_*, CenterPoint, DragForce, AeroFront*, AeroRear*   physics (keep as is)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local Units = require(VehicleSystem:WaitForChild("Units"))
local Tire = require(VehicleSystem:WaitForChild("TireSimulation"):WaitForChild("Tire"))

local M = Units.METERS_PER_STUD
local WHEEL_IDS = { "FL", "FR", "RL", "RR" }

local VehicleModelBuilder = {}

local function studs(v: Vector3): Vector3
	return v / M
end

local function weld(part0: BasePart, part1: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = part0
	constraint.Part1 = part1
	constraint.Parent = part1
end

local function attachment(root: BasePart, name: string, positionMeters: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	a.Position = studs(positionMeters)
	a.Parent = root
	return a
end

local function vectorForce(root: BasePart, name: string, at: Attachment, atCentreOfMass: boolean): VectorForce
	local force = Instance.new("VectorForce")
	force.Name = name
	force.Attachment0 = at
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = atCentreOfMass
	force.Force = Vector3.zero
	force.Parent = root
	return force
end

-- A massless visual part, positioned in the car's frame (metres) and welded to the root.
local function visual(parent: Instance, root: BasePart, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material, options: { [string]: any }?): Part
	local part = Instance.new("Part")
	part.Name = name
	if options and options.shape then
		part.Shape = options.shape
	end
	part.Size = studs(size)
	part.CFrame = CFrame.new(studs(position)) * (if options and options.rotation then options.rotation else CFrame.identity)
	part.Color = color
	part.Material = material
	part.Massless = true
	part.CanCollide = options ~= nil and options.collide == true
	part.CanQuery = false
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if options and options.transparency then
		part.Transparency = options.transparency
	end
	part.Parent = parent
	weld(root, part)
	return part
end

function VehicleModelBuilder.build(config, owner: Player): Model
	local mass = config.mass
	local dims = config.dimensions

	local model = Instance.new("Model")
	model.Name = config.id .. "_" .. owner.Name
	model:SetAttribute("VehicleConfig", config.id)
	model:SetAttribute("OwnerUserId", owner.UserId)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	-- physics root at the centre of mass (the model's origin)
	local totalKg = mass.kerbKg + mass.driverKg
	local box = mass.inertiaBox
	local root = Instance.new("Part")
	root.Name = "MassBox"
	root.Size = studs(Vector3.new(box.width, box.height, box.length))
	root.CFrame = CFrame.identity
	local volume = root.Size.X * root.Size.Y * root.Size.Z
	root.CustomPhysicalProperties = PhysicalProperties.new(Units.kgToRmu(totalKg) / volume, 0.3, 0, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.RootPriority = 127
	root.Parent = model
	model.PrimaryPart = root

	-- key positions in the car's frame (metres; forward is -Z, ground at ride height is y = -comHeight)
	local frontZ = -dims.wheelbase * (1 - mass.frontShare)
	local rearZ = dims.wheelbase * mass.frontShare
	local ground = -mass.comHeight
	local nose = frontZ - dims.frontOverhang
	local tail = nose + dims.length
	local midZ = (nose + tail) / 2
	local cabinZ = frontZ + 2.05

	local paint = config.visual.bodyColor
	local carbon = Color3.fromRGB(28, 28, 30)
	local dark = Color3.fromRGB(18, 18, 20)
	local glass = Color3.fromRGB(18, 24, 30)
	local chrome = Color3.fromRGB(200, 202, 206)

	local body = Instance.new("Model")
	body.Name = "Body"
	body.Parent = model

	-- the lower body is also the car's collision shape
	visual(body, root, "LowerBody", Vector3.new(dims.width - 0.03, 0.52, dims.length - 0.1), Vector3.new(0, ground + 0.39, midZ), paint, Enum.Material.SmoothPlastic, { collide = true })
	visual(body, root, "Bonnet", Vector3.new(dims.width - 0.2, 0.16, 1.95), Vector3.new(0, ground + 0.73, nose + 1.3), paint, Enum.Material.SmoothPlastic)
	visual(body, root, "Cabin", Vector3.new(1.45, 0.58, 1.55), Vector3.new(0, ground + 0.94, cabinZ), glass, Enum.Material.Glass, { transparency = 0.35 })
	visual(body, root, "Roof", Vector3.new(1.38, 0.05, 1.15), Vector3.new(0, ground + 1.25, cabinZ + 0.1), paint, Enum.Material.SmoothPlastic)
	visual(body, root, "RearDeck", Vector3.new(dims.width - 0.2, 0.14, 1.0), Vector3.new(0, ground + 0.72, tail - 0.6), paint, Enum.Material.SmoothPlastic)
	visual(body, root, "FrontIntake", Vector3.new(1.5, 0.22, 0.12), Vector3.new(0, ground + 0.3, nose + 0.04), dark, Enum.Material.SmoothPlastic)
	visual(body, root, "Splitter", Vector3.new(dims.width - 0.2, 0.03, 0.3), Vector3.new(0, ground + 0.135, nose + 0.15), carbon, Enum.Material.SmoothPlastic)
	visual(body, root, "Diffuser", Vector3.new(1.5, 0.16, 0.3), Vector3.new(0, ground + 0.22, tail - 0.12), carbon, Enum.Material.SmoothPlastic)
	visual(body, root, "SpoilerLip", Vector3.new(1.55, 0.04, 0.22), Vector3.new(0, ground + 0.82, tail - 0.15), paint, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		local headlight = visual(body, root, "Headlight", Vector3.new(0.38, 0.07, 0.12), Vector3.new(side * 0.68, ground + 0.62, nose + 0.12), Color3.fromRGB(240, 244, 255), Enum.Material.Neon)
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Front
		beam.Brightness = 3
		beam.Range = 60
		beam.Angle = 50
		beam.Parent = headlight
		visual(body, root, "Taillight", Vector3.new(0.3, 0.08, 0.04), Vector3.new(side * 0.62, ground + 0.68, tail), Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
		visual(body, root, "Mirror", Vector3.new(0.22, 0.1, 0.12), Vector3.new(side * (dims.width / 2 + 0.05), ground + 0.92, cabinZ - 0.75), paint, Enum.Material.SmoothPlastic)
		for _, x in { 0.2, 0.32 } do
			visual(body, root, "ExhaustTip", Vector3.new(0.12, 0.09, 0.09), Vector3.new(side * x, ground + 0.26, tail - 0.02), chrome, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, rotation = CFrame.Angles(0, math.rad(90), 0) })
		end
	end

	local seat = Instance.new("Seat")
	seat.Name = "DriverSeat"
	seat.Size = studs(Vector3.new(0.45, 0.1, 0.45))
	local driverX = if config.visual.driverSide == "Right" then 0.38 else -0.38
	seat.CFrame = CFrame.new(studs(Vector3.new(driverX, ground + 0.18, cabinZ + 0.25)))
	seat.Transparency = 1
	seat.Massless = true
	seat.CanCollide = false
	seat.CanQuery = false
	seat.Parent = model
	weld(root, seat)

	attachment(root, "ChaseCamTarget", Vector3.new(0, 0.5, 0))
	attachment(root, "HoodCam", Vector3.new(0, ground + 0.92, cabinZ - 0.95))
	attachment(root, "CockpitCam", Vector3.new(driverX, ground + 1.08, cabinZ + 0.15))

	-- wheels: visual only. Their position, steering and spin come from the client controller.
	for _, id in WHEEL_IDS do
		local isFront = string.sub(id, 1, 1) == "F"
		local isLeft = string.sub(id, 2, 2) == "L"
		local spec = if isFront then config.tires.front else config.tires.rear
		local radius = Tire.radiusFromSize(spec.widthMm, spec.aspect, spec.rimInches)
		local track = if isFront then dims.trackFront else dims.trackRear
		local width = spec.widthMm / 1000
		local rimDiameter = spec.rimInches * 0.0254
		local centre = Vector3.new((if isLeft then -1 else 1) * track / 2, ground + radius, if isFront then frontZ else rearZ)

		local tire = Instance.new("Part")
		tire.Name = "Wheel_" .. id
		tire.Shape = Enum.PartType.Cylinder
		tire.Size = studs(Vector3.new(width, radius * 2, radius * 2))
		tire.CFrame = CFrame.new(studs(centre))
		tire.Color = Color3.fromRGB(16, 16, 16)
		tire.Material = Enum.Material.SmoothPlastic
		tire.Massless = true
		tire.CanCollide = false
		tire.CanQuery = false
		tire.CanTouch = false
		tire.Parent = model

		local rim = Instance.new("Part")
		rim.Name = "Rim"
		rim.Shape = Enum.PartType.Cylinder
		rim.Size = studs(Vector3.new(width + 0.012, rimDiameter, rimDiameter))
		rim.CFrame = tire.CFrame
		rim.Color = Color3.fromRGB(168, 170, 174)
		rim.Material = Enum.Material.Metal
		rim.Massless = true
		rim.CanCollide = false
		rim.CanQuery = false
		rim.CanTouch = false
		rim.Parent = tire
		weld(tire, rim)

		-- a dark bar across the rim so wheel spin is visible
		local spoke = Instance.new("Part")
		spoke.Name = "Spoke"
		spoke.Size = studs(Vector3.new(width + 0.02, rimDiameter * 0.9, 0.06))
		spoke.CFrame = tire.CFrame
		spoke.Color = dark
		spoke.Material = Enum.Material.SmoothPlastic
		spoke.Massless = true
		spoke.CanCollide = false
		spoke.CanQuery = false
		spoke.CanTouch = false
		spoke.Parent = tire
		weld(tire, spoke)

		local joint = Instance.new("Motor6D")
		joint.Name = "WheelJoint_" .. id
		joint.Part0 = root
		joint.Part1 = tire
		joint.C0 = CFrame.new(studs(centre))
		joint.C1 = CFrame.identity
		joint.Parent = root

		local point = attachment(root, "ForcePoint_" .. id, Vector3.new(centre.X, ground, centre.Z))
		vectorForce(root, "WheelForce_" .. id, point, false)
	end

	local centrePoint = attachment(root, "CenterPoint", Vector3.zero)
	vectorForce(root, "DragForce", centrePoint, true)
	vectorForce(root, "AeroFrontForce", attachment(root, "AeroFrontPoint", Vector3.new(0, 0, frontZ)), false)
	vectorForce(root, "AeroRearForce", attachment(root, "AeroRearPoint", Vector3.new(0, 0, rearZ)), false)

	return model
end

return VehicleModelBuilder
