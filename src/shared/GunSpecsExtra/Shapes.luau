-- The part helpers GunModels uses, so extra guns are written the same way.
-- Each gun points along -Z with its middle at the origin and the grip just
-- below and behind it.
--
-- Roles decide a part's color: Body and Accent come from the gun skin
-- (Accent always glows), the rest stay the same. GunModels has Dark, Metal,
-- Wood, Grip and Warhead; the ones below are added for the extra guns.
local Shapes = {}

local rgb = Color3.fromRGB

Shapes.ROLES = {
	Hazard = { Color = rgb(245, 190, 30), Material = Enum.Material.SmoothPlastic },
	Brass = { Color = rgb(200, 160, 72), Material = Enum.Material.Metal },
	Chrome = { Color = rgb(170, 175, 185), Material = Enum.Material.Metal },
}

local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball

-- A block. Angles are degrees around X, Y and Z.
function Shapes.box(name, size, position, role, angles)
	local offset = CFrame.new(position)
	if angles then
		offset *= CFrame.Angles(math.rad(angles.X), math.rad(angles.Y), math.rad(angles.Z))
	end
	return { Name = name, Size = size, Offset = offset, Role = role }
end

-- A cylinder lying along Z
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

return Shapes
