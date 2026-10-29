-- The part helpers GunModels uses, plus a few more, so gun files are written
-- the same way as the game's guns. Each gun points along -Z with its middle at
-- the origin and the grip just below and behind it.
--
-- Roles decide a part's color: Body and Accent come from the gun skin (with
-- the Factory skin, from the gun's own Factory colors; Accent always glows).
-- The rest stay the same on every skin. GunModels has Dark, Metal, Wood, Grip
-- and Warhead; the ones below are added for the new guns.
local Shapes = {}

local rgb = Color3.fromRGB
local M = Enum.Material

Shapes.ROLES = {
	Gunmetal = { Color = rgb(52, 55, 62), Material = M.Metal }, -- dark steel, lighter than Dark
	Chrome = { Color = rgb(175, 180, 190), Material = M.Metal }, -- bright polished steel
	Brass = { Color = rgb(200, 160, 72), Material = M.Metal }, -- shells and rounds
	Hazard = { Color = rgb(245, 190, 30), Material = M.SmoothPlastic }, -- warning-stripe yellow
	Orange = { Color = rgb(222, 112, 32), Material = M.SmoothPlastic },
	Red = { Color = rgb(180, 30, 32), Material = M.SmoothPlastic },
	Green = { Color = rgb(70, 160, 50), Material = M.SmoothPlastic },
	White = { Color = rgb(225, 228, 232), Material = M.SmoothPlastic },
	Tan = { Color = rgb(196, 176, 140), Material = M.SmoothPlastic },
	Bone = { Color = rgb(222, 214, 196), Material = M.Marble }, -- pearl grips
	Lens = { Color = rgb(30, 60, 90), Material = M.Glass }, -- scope glass
	Rubber = { Color = rgb(18, 18, 20), Material = M.Fabric }, -- pads and grips
}

local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

local function turn(position, angles)
	local offset = CFrame.new(position)
	if angles then
		offset *= CFrame.Angles(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
	end
	return offset
end

-- A block. Angles are degrees around X, Y and Z.
function Shapes.box(name, size, position, role, angles)
	return { Name = name, Size = size, Offset = turn(position, angles), Role = role }
end

-- A wedge: a full bottom and a full back (+Z) face, sloping down to a sharp
-- edge along the front (-Z) bottom. Turn it with angles to aim the slope:
-- e.g. Vector3.new(0, 180, 0) puts the tall side at the front, and
-- Vector3.new(180, 0, 0) flips it upside down.
function Shapes.wedge(name, size, position, role, angles)
	return { Name = name, Size = size, Offset = turn(position, angles), Role = role, Class = "WedgePart" }
end

-- A rounded egg shape that fills size (smooth stocks, scope bells, rocket noses)
function Shapes.egg(name, size, position, role, angles)
	return { Name = name, Size = size, Offset = turn(position, angles), Role = role, Mesh = Enum.MeshType.Sphere }
end

-- A cylinder lying along Z (barrels, scopes, tubes)
function Shapes.tube(name, length, diameter, position, role)
	return {
		Name = name,
		Size = Vector3.new(length, diameter, diameter),
		Offset = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0),
		Role = role,
		Shape = CYLINDER,
	}
end

-- A cylinder standing upright, with its round faces pointing up and down
function Shapes.disc(name, height, diameter, position, role)
	return {
		Name = name,
		Size = Vector3.new(height, diameter, diameter),
		Offset = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		Role = role,
		Shape = CYLINDER,
	}
end

-- A cylinder whose round faces point left and right (along X), like a drum
-- magazine or a wheel
function Shapes.drum(name, width, diameter, position, role)
	return {
		Name = name,
		Size = Vector3.new(width, diameter, diameter),
		Offset = CFrame.new(position),
		Role = role,
		Shape = CYLINDER,
	}
end

function Shapes.ball(name, diameter, position, role)
	return {
		Name = name,
		Size = Vector3.new(diameter, diameter, diameter),
		Offset = CFrame.new(position),
		Role = role,
		Shape = BALL,
	}
end

Shapes.v3 = Vector3.new
Shapes.rgb = rgb

return Shapes
