--[[
	TrackBuilder
	Builds the Phase 1 proving ground: a flat 4-lane oval with two 2.2 km straights joined by
	650 m radius curves (about 8.5 km per lap). It has lane markings, barriers, light poles,
	distance boards on the main straight for acceleration and braking tests, grass, and distant
	buildings for a sense of speed.

	Layout constants are in metres and converted to studs when parts are made. The lap runs along
	+X on the main straight; every curve turns right.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))
local RoadGeometry = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("RoadGeometry"))

local M = Units.METERS_PER_STUD

local TrackBuilder = {}

-- the loop's shape is shared with the traffic system (TrafficSystem/RoadGeometry)
local STRAIGHT = RoadGeometry.STRAIGHT
local RADIUS = RoadGeometry.RADIUS
local LANES = RoadGeometry.LANES
local LANE_WIDTH = RoadGeometry.LANE_WIDTH
local SHOULDER = 3.0
local ROAD_WIDTH = LANES * LANE_WIDTH + 2 * SHOULDER -- 21 m
local ROAD_THICKNESS = 1.0
local STRAIGHT_PIECE = 500 -- road piece length on the straights
local CURVE_PIECE = 7 -- road piece length on the curves
local PIECE_OVERLAP = 0.3
local DASH, GAP = 3, 9
local LINE_WIDTH = 0.15
local EDGE_PIECE = 14
local BARRIER_HEIGHT, BARRIER_WIDTH = 0.9, 0.5
local POLE_SPACING = 60
local START_S = 120 -- start line, metres along the main straight
local ARC = RoadGeometry.ARC
local LAP = RoadGeometry.LAP

TrackBuilder.LAP_LENGTH = LAP
TrackBuilder.LANES = LANES
TrackBuilder.LANE_WIDTH = LANE_WIDTH

local COLORS = {
	asphalt = Color3.fromRGB(46, 48, 52),
	line = Color3.fromRGB(232, 232, 226),
	barrier = Color3.fromRGB(176, 174, 166),
	grass = Color3.fromRGB(76, 102, 56),
	pole = Color3.fromRGB(118, 122, 126),
	lamp = Color3.fromRGB(255, 244, 214),
	board = Color3.fromRGB(240, 240, 238),
	pad = Color3.fromRGB(120, 120, 118),
}

local function studs(v: Vector3): Vector3
	return v / M
end

-- Centre of the road at distance s (metres) around the lap: position (metres) and direction.
TrackBuilder.centerline = RoadGeometry.centerline

local rightOf = RoadGeometry.rightOf

local function newPart(parent: Instance, name: string, sizeMeters: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, collide: boolean, query: boolean): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = studs(sizeMeters)
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.CanCollide = collide
	part.CanQuery = query
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A strip from s0 to s1 at a sideways offset (positive = right of travel). topHeight in metres.
local function strip(parent: Instance, name: string, s0: number, s1: number, offset: number, width: number, thickness: number, topHeight: number, color: Color3, material: Enum.Material, collide: boolean, query: boolean, overlap: number)
	local p0, d0 = TrackBuilder.centerline(s0)
	local p1, d1 = TrackBuilder.centerline(s1)
	local a = p0 + rightOf(d0) * offset
	local b = p1 + rightOf(d1) * offset
	local length = (b - a).Magnitude
	if length < 1e-3 then
		return nil
	end
	local centre = (a + b) / 2 + Vector3.new(0, topHeight - thickness / 2, 0)
	local cframe = CFrame.lookAt(studs(centre), studs(centre + (b - a)))
	return newPart(parent, name, Vector3.new(width, thickness, length + overlap), cframe, color, material, collide, query)
end

-- Frame on the track at distance s and sideways offset, raised by height (metres), facing along the lap.
local function frameAt(s: number, offset: number, height: number): CFrame
	local position, direction = TrackBuilder.centerline(s)
	local p = position + rightOf(direction) * offset + Vector3.new(0, height, 0)
	return CFrame.lookAt(studs(p), studs(p + direction))
end

local function buildRoad(folder: Folder)
	local road = Instance.new("Folder")
	road.Name = "Road"
	road.Parent = folder
	local sections = {
		{ start = 0, length = STRAIGHT, piece = STRAIGHT_PIECE },
		{ start = STRAIGHT, length = ARC, piece = CURVE_PIECE },
		{ start = STRAIGHT + ARC, length = STRAIGHT, piece = STRAIGHT_PIECE },
		{ start = 2 * STRAIGHT + ARC, length = ARC, piece = CURVE_PIECE },
	}
	for _, section in sections do
		local count = math.ceil(section.length / section.piece)
		local step = section.length / count
		for i = 0, count - 1 do
			local s0 = section.start + i * step
			strip(road, "Asphalt", s0, s0 + step, 0, ROAD_WIDTH + PIECE_OVERLAP, ROAD_THICKNESS, 0, COLORS.asphalt, Enum.Material.Asphalt, true, true, PIECE_OVERLAP)
		end
	end
end

local function buildMarkings(folder: Folder)
	local markings = Instance.new("Folder")
	markings.Name = "Markings"
	markings.Parent = folder
	-- dashed lines between lanes
	for k = 1, LANES - 1 do
		local offset = (k - LANES / 2) * LANE_WIDTH
		local s = 0
		while s < LAP do
			local line = strip(markings, "Dash", s, s + DASH, offset, LINE_WIDTH, 0.02, 0.02, COLORS.line, Enum.Material.SmoothPlastic, false, false, 0)
			if line then
				line.CastShadow = false
			end
			s += DASH + GAP
		end
	end
	-- solid edge lines
	for _, side in { -1, 1 } do
		local offset = side * LANES * LANE_WIDTH / 2
		local s = 0
		while s < LAP do
			local line = strip(markings, "EdgeLine", s, math.min(s + EDGE_PIECE, LAP), offset, 0.2, 0.02, 0.02, COLORS.line, Enum.Material.SmoothPlastic, false, false, 0.05)
			if line then
				line.CastShadow = false
			end
			s += EDGE_PIECE
		end
	end
	-- start line
	strip(markings, "StartLine", START_S, START_S + 0.6, 0, LANES * LANE_WIDTH, 0.02, 0.02, COLORS.line, Enum.Material.SmoothPlastic, false, false, 0)
end

local function buildRoadside(folder: Folder)
	local roadside = Instance.new("Folder")
	roadside.Name = "Roadside"
	roadside.Parent = folder

	for _, side in { -1, 1 } do
		local offset = side * (ROAD_WIDTH / 2 + BARRIER_WIDTH / 2)
		local s = 0
		while s < LAP do
			strip(roadside, "Barrier", s, math.min(s + EDGE_PIECE, LAP), offset, BARRIER_WIDTH, BARRIER_HEIGHT, BARRIER_HEIGHT, COLORS.barrier, Enum.Material.Concrete, true, true, 0.05)
			s += EDGE_PIECE
		end
	end

	-- light poles on the outside of the lap
	local s = 0
	while s < LAP do
		local base = frameAt(s, -(ROAD_WIDTH / 2 + 2), 0)
		local position, direction = TrackBuilder.centerline(s)
		local right = rightOf(direction)
		local poleHeight = 11
		local pole = newPart(roadside, "LightPole", Vector3.new(poleHeight, 0.3, 0.3), CFrame.new(base.Position + Vector3.new(0, poleHeight / 2 / M, 0)) * CFrame.Angles(0, 0, math.rad(90)), COLORS.pole, Enum.Material.Metal, true, true)
		pole.Shape = Enum.PartType.Cylinder
		local top = position + right * -(ROAD_WIDTH / 2 + 2) + Vector3.new(0, poleHeight, 0)
		local armCentre = top + right * 1.5
		newPart(roadside, "LightArm", Vector3.new(0.15, 0.15, 3), CFrame.lookAt(studs(armCentre), studs(armCentre + right)), COLORS.pole, Enum.Material.Metal, false, false)
		local lampCentre = top + right * 2.9 - Vector3.new(0, 0.12, 0)
		local lamp = newPart(roadside, "Lamp", Vector3.new(0.5, 0.12, 0.9), CFrame.lookAt(studs(lampCentre), studs(lampCentre + right)), COLORS.lamp, Enum.Material.Neon, false, false)
		lamp.CastShadow = false
		s += POLE_SPACING
	end

	-- distance boards beside the main straight, every 100 m from the start line
	for k = 1, 20 do
		local sBoard = START_S + k * 100
		local position, direction = TrackBuilder.centerline(sBoard)
		local spot = position + rightOf(direction) * (ROAD_WIDTH / 2 + 3) + Vector3.new(0, 1.8, 0)
		-- the board's front face points back toward approaching cars
		local board = newPart(roadside, "DistanceBoard", Vector3.new(2.4, 1.4, 0.1), CFrame.lookAt(studs(spot), studs(spot - direction)), COLORS.board, Enum.Material.SmoothPlastic, true, false)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(240, 140)
		gui.Parent = board
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(20, 20, 22)
		text.Text = string.format("%d m", k * 100)
		text.Parent = gui
		newPart(roadside, "BoardPost", Vector3.new(0.12, 1.1, 0.12), CFrame.new(studs(spot - Vector3.new(0, 1.25, 0))), COLORS.pole, Enum.Material.Metal, false, false)
	end
end

local function buildSurroundings(folder: Folder)
	local surroundings = Instance.new("Folder")
	surroundings.Name = "Surroundings"
	surroundings.Parent = folder

	-- grass covering the whole area, tiled because parts are limited to 2,048 studs a side
	local halfX = STRAIGHT / 2 + RADIUS + 700
	local halfZ = RADIUS + 700
	local tile = 2000 * M
	local x = -halfX
	while x < halfX do
		local z = -halfZ
		while z < halfZ do
			local sizeX = math.min(tile, halfX - x)
			local sizeZ = math.min(tile, halfZ - z)
			local centre = Vector3.new(x + sizeX / 2, -0.55, z + sizeZ / 2)
			newPart(surroundings, "Grass", Vector3.new(sizeX, 1, sizeZ), CFrame.new(studs(centre)), COLORS.grass, Enum.Material.Grass, true, true)
			z += tile
		end
		x += tile
	end

	-- distant buildings outside the lap give the eye something to measure speed against
	local random = Random.new(42)
	local palette = { Color3.fromRGB(150, 154, 160), Color3.fromRGB(110, 118, 128), Color3.fromRGB(176, 170, 160), Color3.fromRGB(86, 96, 110) }
	for _ = 1, 70 do
		local s = random:NextNumber(0, LAP)
		local position, direction = TrackBuilder.centerline(s)
		local offset = ROAD_WIDTH / 2 + random:NextNumber(120, 520)
		local height = random:NextNumber(25, 180)
		local size = Vector3.new(random:NextNumber(20, 60), height, random:NextNumber(20, 60))
		local centre = position - rightOf(direction) * offset + Vector3.new(0, height / 2, 0)
		local material = if random:NextNumber() < 0.4 then Enum.Material.Glass else Enum.Material.Concrete
		newPart(surroundings, "Building", size, CFrame.new(studs(centre)) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), palette[random:NextInteger(1, #palette)], material, true, true)
	end

	-- infield pad with the player spawn point, beside the start line
	local padPosition = TrackBuilder.centerline(START_S - 40) + Vector3.new(0, 0, ROAD_WIDTH / 2 + 30)
	newPart(surroundings, "Paddock", Vector3.new(60, 0.4, 30), CFrame.new(studs(padPosition + Vector3.new(0, -0.15, 0))), COLORS.pad, Enum.Material.Concrete, true, true)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PaddockSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = studs(Vector3.new(4, 0.2, 4))
	spawn.CFrame = CFrame.new(studs(padPosition + Vector3.new(0, 0.15, 0)))
	spawn.Color = Color3.fromRGB(70, 70, 74)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = surroundings
end

function TrackBuilder.build()
	local existing = Workspace:FindFirstChild("ProvingGround")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "ProvingGround"
	buildRoad(folder)
	buildMarkings(folder)
	buildRoadside(folder)
	buildSurroundings(folder)
	folder.Parent = Workspace
end

-- Where to place a car's centre of mass for grid slot n (1-based), as a CFrame in studs.
function TrackBuilder.gridCFrame(slot: number, comHeight: number): CFrame
	local lane = (slot - 1) % LANES + 1
	local row = math.floor((slot - 1) / LANES)
	local s = START_S - 8 - row * 10
	local offset = (lane - (LANES + 1) / 2) * LANE_WIDTH
	return frameAt(s, offset, comHeight + 0.05)
end

-- The nearest lane centre to a position (studs), as a CFrame facing along the lap.
function TrackBuilder.nearestCFrame(positionStuds: Vector3, comHeight: number): CFrame
	local position = positionStuds * M
	local bestS, bestDistance = 0, math.huge
	local s = 0
	while s < LAP do
		local p = TrackBuilder.centerline(s)
		local distance = (Vector3.new(position.X, 0, position.Z) - p).Magnitude
		if distance < bestDistance then
			bestS, bestDistance = s, distance
		end
		s += 4
	end
	local p, direction = TrackBuilder.centerline(bestS)
	local sideways = (Vector3.new(position.X, 0, position.Z) - p):Dot(rightOf(direction))
	local lane = math.clamp(math.floor(sideways / LANE_WIDTH + LANES / 2) + 1, 1, LANES)
	local offset = (lane - (LANES + 1) / 2) * LANE_WIDTH
	return frameAt(bestS, offset, comHeight + 0.05)
end

return TrackBuilder
