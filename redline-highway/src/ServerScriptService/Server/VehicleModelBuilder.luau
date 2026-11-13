--[[
	VehicleModelBuilder
	Builds a car model from a vehicle configuration.

	Physics comes from one invisible part, MassBox, placed at the centre of mass and sized like
	the car's mass distribution, with its density set so it weighs exactly the configured mass.
	Everything else is massless, so mass, centre of mass and rotational inertia are all correct.

	The visible body here is a stand-in (blockout) built to the real dimensions. Its side profile
	comes from the config's visual.blockout table (the top line of the body from nose to tail, where
	the cabin glass is, the window sill height and the cabin width); configs without one get a long-
	bonnet GT shape. The body is drawn as slices along the car, painted outside the cabin and glass
	inside it. The Phase 2 Blender model replaces the "Body" model and the Wheel_* parts and must keep
	these names:
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

-- Default stand-in shape: a front-engined GT with a long bonnet and a fastback.
local DEFAULT_BLOCKOUT = {
	profile = { { 0, 0.5 }, { 0.03, 0.66 }, { 0.42, 0.86 }, { 0.56, 1.25 }, { 0.63, 1.276 }, { 0.8, 1.02 }, { 0.95, 0.93 }, { 1, 0.9 } },
	greenhouse = { 0.42, 0.8 },
	beltline = 0.86,
	cabinWidth = 0.72,
	sill = 0.14,
}
local SLICES = 24

-- Height of the body's top line at a share of the length from the nose (linear between points).
local function profileHeight(profile, share: number): number
	if share <= profile[1][1] then
		return profile[1][2]
	end
	for i = 1, #profile - 1 do
		local a, b = profile[i], profile[i + 1]
		if share <= b[1] then
			local t = if b[1] > a[1] then (share - a[1]) / (b[1] - a[1]) else 0
			return a[2] + (b[2] - a[2]) * t
		end
	end
	return profile[#profile][2]
end
VehicleModelBuilder.profileHeight = profileHeight
VehicleModelBuilder.DEFAULT_BLOCKOUT = DEFAULT_BLOCKOUT

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
	local shape = config.visual.blockout or DEFAULT_BLOCKOUT
	local profile = shape.profile
	local glassFrom, glassTo = shape.greenhouse[1], shape.greenhouse[2]
	local beltline = shape.beltline
	local sill = shape.sill or 0.14
	-- where things sit along the car, as z in the car's frame
	local function zAt(share: number): number
		return nose + dims.length * share
	end
	local driverShare = glassFrom + 0.4 * (glassTo - glassFrom)
	local cabinZ = zAt(driverShare)
	local eyeHeight = profileHeight(profile, driverShare) - 0.2

	local paint = config.visual.bodyColor
	local carbon = Color3.fromRGB(28, 28, 30)
	local dark = Color3.fromRGB(18, 18, 20)
	local glass = Color3.fromRGB(18, 24, 30)
	local chrome = Color3.fromRGB(200, 202, 206)

	local body = Instance.new("Model")
	body.Name = "Body"
	body.Parent = model

	-- the lower body (sill to window line) is also the car's collision shape
	visual(body, root, "LowerBody", Vector3.new(dims.width - 0.03, beltline - sill, dims.length - 0.1), Vector3.new(0, ground + (sill + beltline) / 2, midZ), paint, Enum.Material.SmoothPlastic, { collide = true })

	-- upper body as slices along the car: painted bonnet and deck, glass cabin with a painted roof
	local sliceLength = dims.length / SLICES
	for i = 0, SLICES - 1 do
		local share = (i + 0.5) / SLICES
		local top = profileHeight(profile, share)
		local z = zAt(share)
		if share > glassFrom and share < glassTo then
			if top - 0.07 > beltline then
				visual(body, root, "Glass", Vector3.new(dims.width * shape.cabinWidth, top - 0.07 - beltline, sliceLength + 0.01), Vector3.new(0, ground + (beltline + top - 0.07) / 2, z), glass, Enum.Material.Glass, { transparency = 0.3 })
			end
		elseif top > beltline then
			visual(body, root, "Panel", Vector3.new(dims.width - 0.12, top - beltline, sliceLength + 0.01), Vector3.new(0, ground + (beltline + top) / 2, z), paint, Enum.Material.SmoothPlastic)
		end
	end

	-- smooth cabin top: a tilted plate along each piece of the profile inside the greenhouse,
	-- glass where it's steep (windscreen, rear window), painted where it's flat (roof)
	local points = { { glassFrom, profileHeight(profile, glassFrom) } }
	for _, point in profile do
		if point[1] > glassFrom and point[1] < glassTo then
			table.insert(points, point)
		end
	end
	table.insert(points, { glassTo, profileHeight(profile, glassTo) })
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local dz, dy = (b[1] - a[1]) * dims.length, b[2] - a[2]
		local length = math.sqrt(dz * dz + dy * dy)
		if length > 0.02 then
			local steep = math.abs(dy) > 0.35 * dz
			visual(body, root, if steep then "Screen" else "Roof", Vector3.new(dims.width * shape.cabinWidth, 0.04, length + 0.02),
				Vector3.new(0, ground + (a[2] + b[2]) / 2 - 0.02, zAt((a[1] + b[1]) / 2)),
				if steep then glass else paint, if steep then Enum.Material.Glass else Enum.Material.SmoothPlastic,
				{ rotation = CFrame.Angles(-math.atan2(dy, dz), 0, 0), transparency = if steep then 0.25 else nil })
		end
	end

	local noseTop = profileHeight(profile, 0.02)
	local tailTop = profileHeight(profile, 0.98)
	visual(body, root, "FrontIntake", Vector3.new(1.5, 0.22, 0.12), Vector3.new(0, ground + 0.3, nose + 0.04), dark, Enum.Material.SmoothPlastic)
	visual(body, root, "Splitter", Vector3.new(dims.width - 0.2, 0.03, 0.3), Vector3.new(0, ground + 0.135, nose + 0.15), carbon, Enum.Material.SmoothPlastic)
	visual(body, root, "Diffuser", Vector3.new(1.5, 0.16, 0.3), Vector3.new(0, ground + 0.22, tail - 0.12), carbon, Enum.Material.SmoothPlastic)
	for _, side in { -1, 1 } do
		local headlight = visual(body, root, "Headlight", Vector3.new(0.38, 0.07, 0.12), Vector3.new(side * 0.68, ground + noseTop - 0.08, nose + 0.12), Color3.fromRGB(240, 244, 255), Enum.Material.Neon)
		local beam = Instance.new("SpotLight")
		beam.Face = Enum.NormalId.Front
		beam.Brightness = 3
		beam.Range = 60
		beam.Angle = 50
		beam.Parent = headlight
		visual(body, root, "Taillight", Vector3.new(0.3, 0.08, 0.04), Vector3.new(side * 0.62, ground + tailTop - 0.12, tail), Color3.fromRGB(255, 30, 30), Enum.Material.Neon)
		visual(body, root, "Mirror", Vector3.new(0.22, 0.1, 0.12), Vector3.new(side * (dims.width / 2 + 0.05), ground + beltline + 0.08, zAt(glassFrom) + 0.15), paint, Enum.Material.SmoothPlastic)
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
	attachment(root, "HoodCam", Vector3.new(0, ground + profileHeight(profile, glassFrom - 0.06) + 0.12, zAt(glassFrom - 0.06)))
	attachment(root, "CockpitCam", Vector3.new(driverX, ground + eyeHeight, cabinZ + 0.15))

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
