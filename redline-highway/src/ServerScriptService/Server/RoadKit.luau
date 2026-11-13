--[[
	RoadKit: building blocks for maps made from a RoadGeometry road: road surfaces and markings that
	follow its curves and grades, walls and barriers, supports under raised road, tunnels with walls,
	ceiling, lights and "TunnelZone" boxes, sign gantries, and part helpers. Used by TrackBuilder
	(the oval) and CityBuilder (the city).

	Sizes and positions are in metres and converted to studs when parts are made. Long features are
	made of straight boxes ("pieces") between points along the road, as long as possible while
	staying within a few centimetres of the true curve, so straights take few parts.

	TunnelZone boxes (for the tunnel sound, see docs/MAPS.md): invisible, non-colliding,
	non-queryable blocks covering each tunnel's inside from the road to the ceiling and wall to wall,
	ending exactly at the portals and overlapping by 1 m where they join, tagged "TunnelZone" with
	CollectionService, with attributes ReverbDecay (s), TunnelName and MapId.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local M = Units.METERS_PER_STUD

local RoadKit = {}

RoadKit.M = M
RoadKit.TUNNEL_TAG = "TunnelZone"
RoadKit.MAX_PIECE = 400 -- m, the longest box (parts can't exceed 2,048 studs)
RoadKit.SAG = 0.08 -- m, how far a box may stray from the curve it follows

RoadKit.COLORS = {
	asphalt = Color3.fromRGB(46, 48, 52),
	line = Color3.fromRGB(232, 232, 226),
	yellowLine = Color3.fromRGB(226, 178, 52),
	concrete = Color3.fromRGB(176, 174, 166),
	darkConcrete = Color3.fromRGB(120, 120, 116),
	pole = Color3.fromRGB(118, 122, 126),
	lamp = Color3.fromRGB(255, 244, 214),
	sodium = Color3.fromRGB(255, 150, 54),
	signGreen = Color3.fromRGB(22, 104, 66),
	signText = Color3.fromRGB(245, 245, 240),
	tunnelTile = Color3.fromRGB(196, 190, 170),
	steel = Color3.fromRGB(96, 100, 106),
}

-- An anchored part. sizeMeters in metres, cframe in studs. Parts that don't collide aren't
-- queryable either, so raycasts (suspension, camera) ignore markings and decorations.
function RoadKit.part(parent: Instance, name: string, sizeMeters: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, collide: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = sizeMeters / M
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.CanCollide = collide
	part.CanQuery = collide
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function RoadKit.folder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- A point (m) at distance s, sideways offset and height above the road surface.
function RoadKit.point(road, s: number, offset: number, height: number): Vector3
	local p = road:frame(s, offset, height)
	return p
end

-- A CFrame (studs) at a point on the road, looking along it (pitched with the grade).
function RoadKit.cframe(road, s: number, offset: number, height: number): CFrame
	local p, direction = road:frame(s, offset, height)
	return CFrame.lookAt(p / M, (p + direction) / M)
end

-- A level CFrame (studs) at a point on the road, looking along it: for upright things.
function RoadKit.levelCFrame(road, s: number, offset: number, height: number): CFrame
	local p, direction = road:frame(s, offset, height)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	return CFrame.lookAt(p / M, (p + flat) / M)
end

-- The sharpest plan curvature (1/m) and vertical curvature (rate of grade change, 1/m) between
-- distances a and b.
function RoadKit.bend(road, a: number, b: number): (number, number)
	local k = 0
	local pieces = road.pieces
	local i = road:pieceIndex(a % road.length)
	while i <= #pieces and pieces[i].s < b do
		k = math.max(k, math.abs(pieces[i].k))
		i += 1
	end
	local r = 0
	local profile = road.profile
	local j = 1
	while j < #profile and profile[j + 1].s <= a do
		j += 1
	end
	while j <= #profile and profile[j].s < b do
		r = math.max(r, math.abs(profile[j].rate))
		j += 1
	end
	return k, r
end

--[[
	Split [s0, s1] into pieces that straight boxes can follow: each piece is as long as maxLength
	allows while its chord stays within sag metres of the road, in plan and in elevation. Returns
	the points between pieces, s0 first and s1 last.
]]
function RoadKit.pieces(road, s0: number, s1: number, maxLength: number?, sag: number?): { number }
	local longest = maxLength or RoadKit.MAX_PIECE
	local tolerance = sag or RoadKit.SAG
	local points = { s0 }
	local s = s0
	while s1 - s > 1e-6 do
		local length = math.min(longest, s1 - s)
		for _ = 1, 4 do
			local k, r = RoadKit.bend(road, s, s + length)
			local limit = longest
			if k > 0 then
				limit = math.min(limit, math.sqrt(8 * tolerance / k))
			end
			if r > 0 then
				limit = math.min(limit, math.sqrt(8 * tolerance / r))
			end
			if limit >= length then
				break
			end
			length = limit
		end
		s = if s1 - (s + length) < 0.5 then s1 else s + length
		table.insert(points, s)
	end
	return points
end

--[[
	A box along the road from s0 to s1 at a sideways offset: width across, thickness deep, its top
	`top` metres above the road surface. extend lengthens it (m) to close gaps on curves.
]]
function RoadKit.strip(parent: Instance, road, name: string, s0: number, s1: number, offset: number, width: number,
	thickness: number, top: number, color: Color3, material: Enum.Material, collide: boolean, extend: number?): Part?
	local a = RoadKit.point(road, s0, offset, 0)
	local b = RoadKit.point(road, s1, offset, 0)
	local length = (b - a).Magnitude
	if length < 1e-3 then
		return nil
	end
	local centre = (a + b) / 2
	local cframe = CFrame.lookAt(centre / M, b / M) * CFrame.new(0, (top - thickness / 2) / M, 0)
	return RoadKit.part(parent, name, Vector3.new(width, thickness, length + (extend or 0)), cframe, color, material, collide)
end

-- How much a box of this width needs lengthening to close the wedge-shaped gaps between boxes
-- on the outside of a curve.
function RoadKit.overlap(road, s0: number, s1: number, width: number): number
	local k = RoadKit.bend(road, s0, s1)
	return 0.05 + width / 2 * k * (s1 - s0)
end

-- Dashed line at a sideways offset from s0 to s1: dash metres painted, gap metres bare.
function RoadKit.dashes(parent: Instance, road, s0: number, s1: number, offset: number, dash: number, gap: number, width: number, color: Color3)
	local s = s0
	while s + dash <= s1 do
		local line = RoadKit.strip(parent, road, "Dash", s, s + dash, offset, width, 0.02, 0.02, color, Enum.Material.SmoothPlastic, false)
		if line then
			line.CastShadow = false
		end
		s += dash + gap
	end
end

-- Solid line along [s0, s1] at a sideways offset, in pieces.
function RoadKit.solidLine(parent: Instance, road, points: { number }, offset: number, width: number, color: Color3)
	for i = 1, #points - 1 do
		local line = RoadKit.strip(parent, road, "Line", points[i], points[i + 1], offset, width, 0.02, 0.02, color,
			Enum.Material.SmoothPlastic, false, RoadKit.overlap(road, points[i], points[i + 1], width))
		if line then
			line.CastShadow = false
		end
	end
end

--[[
	TunnelZone boxes covering a tunnel from s0 to s1 (the portals): from just below the road to
	`height` above it, between the left and right walls' inner faces (sideways offsets, m). Long or
	curved tunnels get a chain of boxes overlapping by 1 m; the first and last end at the portals.
]]
function RoadKit.tunnelZones(parent: Instance, road, s0: number, s1: number, left: number, right: number, height: number, attributes: { [string]: any }): { Part }
	local zones = {}
	local sag = 0.5
	local points = RoadKit.pieces(road, s0, s1, RoadKit.MAX_PIECE, sag)
	local centre = (left + right) / 2
	local width = right - left + 2 * sag
	for i = 1, #points - 1 do
		local a = RoadKit.point(road, points[i], centre, -0.3)
		local b = RoadKit.point(road, points[i + 1], centre, -0.3)
		local axis = (b - a).Unit
		if i > 1 then
			a -= axis * 0.5
		end
		if i < #points - 1 then
			b += axis * 0.5
		end
		local length = (b - a).Magnitude
		local mid = (a + b) / 2
		local zoneHeight = height + 0.3
		local cframe = CFrame.lookAt(mid / M, b / M) * CFrame.new(0, zoneHeight / 2 / M, 0)
		local zone = RoadKit.part(parent, "TunnelZone", Vector3.new(width, zoneHeight, length), cframe,
			Color3.fromRGB(255, 160, 60), Enum.Material.SmoothPlastic, false)
		zone.Transparency = 1
		zone.CastShadow = false
		for key, value in attributes do
			zone:SetAttribute(key, value)
		end
		CollectionService:AddTag(zone, RoadKit.TUNNEL_TAG)
		table.insert(zones, zone)
	end
	return zones
end

-- A sign panel facing oncoming traffic, with lines of text that glow (they ignore lighting).
function RoadKit.sign(parent: Instance, name: string, sizeMeters: Vector3, cframe: CFrame, background: Color3, lines: { string }, textColor: Color3?): Part
	local panel = RoadKit.part(parent, name, sizeMeters, cframe, background, Enum.Material.SmoothPlastic, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = panel
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = background
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local count = #lines
	for i, text in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0.92, 0, 0.8 / count, 0)
		label.Position = UDim2.new(0.04, 0, 0.1 + 0.8 * (i - 1) / count, 0)
		label.Font = if i == 1 then Enum.Font.GothamBlack else Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = textColor or RoadKit.COLORS.signText
		label.Text = text
		label.Parent = frame
	end
	return panel
end

--[[
	An overhead sign gantry at distance s: posts just outside left and right (sideways offsets of
	the walls, m), a beam at clearance metres, and sign panels { offset, width, lines } facing
	approaching traffic.
]]
function RoadKit.gantry(parent: Instance, road, s: number, left: number, right: number, clearance: number, panels)
	local base = RoadKit.levelCFrame(road, s, 0, 0)
	local folder = RoadKit.folder(parent, "Gantry")
	local postHeight = clearance + 1.6
	for _, offset in { left - 0.6, right + 0.6 } do
		RoadKit.part(folder, "Post", Vector3.new(0.6, postHeight, 0.6), base * CFrame.new(offset / M, postHeight / 2 / M, 0),
			RoadKit.COLORS.steel, Enum.Material.Metal, true)
	end
	local span = right - left + 1.2
	RoadKit.part(folder, "Beam", Vector3.new(span, 0.5, 0.8), base * CFrame.new((left + right) / 2 / M, (clearance + 1.3) / M, 0),
		RoadKit.COLORS.steel, Enum.Material.Metal, false)
	for _, panel in panels do
		-- the panel's front face (-Z of its CFrame) looks back at approaching cars
		local cf = base * CFrame.new(panel.offset / M, (clearance + 1.2) / M, 0.5 / M) * CFrame.Angles(0, math.pi, 0)
		RoadKit.sign(folder, "Sign", Vector3.new(panel.width, 2.2, 0.15), cf, panel.color or RoadKit.COLORS.signGreen, panel.lines)
	end
end

-- Count the parts under an instance.
function RoadKit.countParts(root: Instance): number
	local count = 0
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

return RoadKit
