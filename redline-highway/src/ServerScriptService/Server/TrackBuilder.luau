--[[
	TrackBuilder
	Builds the Redline Proving Ground, the oval map (TrafficSystem/Maps/Oval): a flat 4-lane highway
	loop with two 2.4 km straights joined by 650 m radius curves with transition curves (9.3 km per
	lap). It has lane markings, concrete barriers, light poles, sign gantries, two overpasses, a
	300 m covered gallery on the back straight (with lights and a TunnelZone for tunnel sound),
	distance boards on the main straight for acceleration and braking tests, trees, grass and
	distant buildings for a sense of speed, and the paddock where players spawn.

	The shape comes from the map's data through RoadGeometry; RoadKit makes the parts. Sizes are in
	metres and converted to studs when parts are made. The lap runs along +X on the main straight;
	every curve turns right, so the infield is on the right.
]]

local Workspace = game:GetService("Workspace")

local RoadKit = require(script.Parent.RoadKit)

local M = RoadKit.M
local C = RoadKit.COLORS

local TrackBuilder = {}

local ROAD_THICKNESS = 1.0
local DASH, GAP = 3, 9
local LINE_WIDTH = 0.15
local EDGE_LINE_WIDTH = 0.2
local BARRIER_HEIGHT, BARRIER_WIDTH = 0.9, 0.5
local POLE_SPACING = 60
local GALLERY_HEIGHT = 6.0 -- m, clear height under the gallery roof
local OVERPASSES = { 1900, 6600 } -- s of the two bridges across the road
local TREES = 260

local COLORS = {
	grass = Color3.fromRGB(76, 102, 56),
	board = Color3.fromRGB(240, 240, 238),
	pad = Color3.fromRGB(120, 120, 118),
	trunk = Color3.fromRGB(92, 72, 52),
	leaves = { Color3.fromRGB(64, 92, 52), Color3.fromRGB(80, 104, 58), Color3.fromRGB(58, 82, 50) },
}

local function inGallery(map, s: number): boolean
	return map.road:sectionAt(s, "tunnel") ~= nil
end

local function nearOverpass(s: number, margin: number): boolean
	for _, at in OVERPASSES do
		if math.abs(s - at) < margin then
			return true
		end
	end
	return false
end

local function buildRoad(folder: Folder, map, points: { number })
	local road = map.road
	local surface = RoadKit.folder(folder, "Road")
	local width = road.leftEdge + road.rightEdge
	local centre = (road.rightEdge - road.leftEdge) / 2
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		RoadKit.strip(surface, road, "Asphalt", a, b, centre, width, ROAD_THICKNESS, 0, C.asphalt, Enum.Material.Asphalt, true,
			RoadKit.overlap(road, a, b, width))
	end
end

local function buildMarkings(folder: Folder, map, points: { number })
	local road = map.road
	local markings = RoadKit.folder(folder, "Markings")
	for k = 1, road.lanes - 1 do
		RoadKit.dashes(markings, road, 0, road.length, (k - road.lanes / 2) * road.laneWidth, DASH, GAP, LINE_WIDTH, C.line)
	end
	for _, side in { -1, 1 } do
		RoadKit.solidLine(markings, road, points, side * road.halfWidth, EDGE_LINE_WIDTH, C.line)
	end
	local start = map.data.start
	RoadKit.strip(markings, road, "StartLine", start, start + 0.6, 0, road.lanes * road.laneWidth, 0.02, 0.02, C.line,
		Enum.Material.SmoothPlastic, false)
end

local function buildBarriers(folder: Folder, map, points: { number })
	local road = map.road
	local barriers = RoadKit.folder(folder, "Barriers")
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		-- the gallery's outer wall replaces the left barrier there
		if not inGallery(map, (a + b) / 2) then
			RoadKit.strip(barriers, road, "Barrier", a, b, -(road.leftEdge + BARRIER_WIDTH / 2), BARRIER_WIDTH, BARRIER_HEIGHT,
				BARRIER_HEIGHT, C.concrete, Enum.Material.Concrete, true, RoadKit.overlap(road, a, b, BARRIER_WIDTH))
		end
		RoadKit.strip(barriers, road, "Barrier", a, b, road.rightEdge + BARRIER_WIDTH / 2, BARRIER_WIDTH, BARRIER_HEIGHT,
			BARRIER_HEIGHT, C.concrete, Enum.Material.Concrete, true, RoadKit.overlap(road, a, b, BARRIER_WIDTH))
	end
end

-- Light poles on the outside of the lap, with their lamps reaching over the road.
local function buildPoles(folder: Folder, map)
	local road = map.road
	local poles = RoadKit.folder(folder, "LightPoles")
	local poleHeight = 11
	local offset = -(road.leftEdge + 2)
	local s = 0
	while s < road.length do
		if not inGallery(map, s) and not nearOverpass(s, 20) then
			local base = RoadKit.levelCFrame(road, s, offset, 0)
			local pole = RoadKit.part(poles, "LightPole", Vector3.new(poleHeight, 0.3, 0.3),
				base * CFrame.new(0, poleHeight / 2 / M, 0) * CFrame.Angles(0, 0, math.rad(90)), C.pole, Enum.Material.Metal, true)
			pole.Shape = Enum.PartType.Cylinder
			-- the arm reaches toward the road (to the right of the travel direction)
			RoadKit.part(poles, "LightArm", Vector3.new(3, 0.15, 0.15), base * CFrame.new(1.5 / M, poleHeight / M, 0), C.pole,
				Enum.Material.Metal, false)
			local lamp = RoadKit.part(poles, "Lamp", Vector3.new(0.9, 0.12, 0.5), base * CFrame.new(2.9 / M, (poleHeight - 0.12) / M, 0),
				C.lamp, Enum.Material.Neon, false)
			lamp.CastShadow = false
		end
		s += POLE_SPACING
	end
end

-- Distance boards beside the main straight, every 100 m from the start line.
local function buildBoards(folder: Folder, map)
	local road = map.road
	local boards = RoadKit.folder(folder, "DistanceBoards")
	local start = map.data.start
	for k = 1, 20 do
		local s = start + k * 100
		-- the board's front face points back toward approaching cars
		local cf = RoadKit.levelCFrame(road, s, road.rightEdge + 3, 1.8) * CFrame.Angles(0, math.pi, 0)
		local board = RoadKit.part(boards, "DistanceBoard", Vector3.new(2.4, 1.4, 0.1), cf, COLORS.board, Enum.Material.SmoothPlastic, true)
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
		RoadKit.part(boards, "BoardPost", Vector3.new(0.12, 1.1, 0.12), cf * CFrame.new(0, -1.25 / M, 0), C.pole, Enum.Material.Metal, false)
	end
end

--[[
	The covered gallery: a concrete roof over the road, a solid wall on the outside, open columns on
	the infield side, lamps under the roof, earth over the top, and TunnelZone boxes inside.
]]
local function buildGallery(folder: Folder, map, section)
	local road = map.road
	local gallery = RoadKit.folder(folder, "Gallery")
	local s0, s1 = section.from, section.to
	local points = RoadKit.pieces(road, s0, s1)
	local wall = 0.8
	local outer = -(road.leftEdge + wall / 2)
	-- the roof spans from the outer wall to just past the columns on the infield side
	local roofLeft, roofRight = -(road.leftEdge + wall), road.rightEdge + BARRIER_WIDTH + 1.2
	local width = roofRight - roofLeft
	local centre = (roofLeft + roofRight) / 2
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		RoadKit.strip(gallery, road, "Roof", a, b, centre, width, 0.8, GALLERY_HEIGHT + 0.8, C.darkConcrete, Enum.Material.Concrete, true)
		RoadKit.strip(gallery, road, "OuterWall", a, b, outer, wall, GALLERY_HEIGHT, GALLERY_HEIGHT, C.concrete, Enum.Material.Concrete, true)
		RoadKit.strip(gallery, road, "Earth", a, b, centre - 2, width + 4, 0.6, GALLERY_HEIGHT + 1.4, COLORS.grass, Enum.Material.Grass, true)
		-- an earth bank sloping away from the outer wall
		local length = (RoadKit.point(road, b, 0, 0) - RoadKit.point(road, a, 0, 0)).Magnitude
		local bankWidth = 12
		local bank = Instance.new("WedgePart")
		bank.Name = "EarthBank"
		bank.Anchored = true
		bank.Size = Vector3.new(length, GALLERY_HEIGHT + 1.4, bankWidth) / M
		-- the wedge's tall face (+Z) leans on the wall; its slope runs down and away from the road
		bank.CFrame = RoadKit.levelCFrame(road, (a + b) / 2, -(road.leftEdge + wall + bankWidth / 2), (GALLERY_HEIGHT + 1.4) / 2)
			* CFrame.Angles(0, math.pi / 2, 0)
		bank.Color = COLORS.grass
		bank.Material = Enum.Material.Grass
		bank.CanTouch = false
		bank.Parent = gallery
	end
	-- columns on the infield side, lamps and lights under the roof
	local s = s0 + 5
	local n = 0
	while s < s1 - 2 do
		local base = RoadKit.levelCFrame(road, s, road.rightEdge + BARRIER_WIDTH + 0.6, 0)
		RoadKit.part(gallery, "Column", Vector3.new(0.8, GALLERY_HEIGHT, 0.8), base * CFrame.new(0, GALLERY_HEIGHT / 2 / M, 0), C.concrete,
			Enum.Material.Concrete, true)
		local lamp = RoadKit.part(gallery, "Lamp", Vector3.new(0.4, 0.12, 1.6), RoadKit.levelCFrame(road, s, 0, GALLERY_HEIGHT - 0.06),
			C.lamp, Enum.Material.Neon, false)
		lamp.CastShadow = false
		if n % 2 == 0 then
			local light = Instance.new("PointLight")
			light.Brightness = 1.6
			light.Range = 42
			light.Color = Color3.fromRGB(255, 232, 196)
			light.Shadows = false
			light.Parent = lamp
		end
		n += 1
		s += 10
	end
	RoadKit.tunnelZones(gallery, road, s0, s1, -road.leftEdge, road.rightEdge, GALLERY_HEIGHT, {
		ReverbDecay = section.reverb or 0.8,
		TunnelName = section.name or "Gallery",
		MapId = map.id,
	})
end

-- A bridge across the road at distance s: deck, parapets, columns beside the road and abutments.
local function buildOverpass(folder: Folder, map, s: number)
	local road = map.road
	local bridge = RoadKit.folder(folder, "Overpass")
	local base = RoadKit.levelCFrame(road, s, 0, 0)
	local span = road.leftEdge + road.rightEdge + 30
	local clearance = 6.5
	local deck = 1.2
	-- the deck runs across the road (along the base's X axis)
	RoadKit.part(bridge, "Deck", Vector3.new(span, deck, 9), base * CFrame.new(0, (clearance + deck / 2) / M, 0), C.concrete, Enum.Material.Concrete, true)
	for _, side in { -1, 1 } do
		RoadKit.part(bridge, "Parapet", Vector3.new(span, 1.0, 0.3), base * CFrame.new(0, (clearance + deck + 0.5) / M, side * 4.35 / M),
			C.concrete, Enum.Material.Concrete, true)
		local columnX = side * (road.rightEdge + 4)
		for _, z in { -2.5, 2.5 } do
			RoadKit.part(bridge, "Column", Vector3.new(1.0, clearance, 1.0), base * CFrame.new(columnX / M, clearance / 2 / M, z / M),
				C.concrete, Enum.Material.Concrete, true)
		end
		local abutmentX = side * (span / 2 + 6)
		RoadKit.part(bridge, "Abutment", Vector3.new(12, clearance + deck, 11), base * CFrame.new(abutmentX / M, (clearance + deck) / 2 / M, 0),
			COLORS.grass, Enum.Material.Grass, true)
	end
end

local GANTRIES = {
	{ s = 700, lines = { "REDLINE PROVING GROUND", "Lap 9.3 km   4 lanes" } },
	{ s = 2250, lines = { "CURVE 1   R 650 m", "Keep right except to pass" } },
	{ s = 5000, lines = { "GALLERY 600 m", "Back straight 2.4 km" } },
	{ s = 6950, lines = { "START / FINISH 2.5 km", "Paddock: keep right" } },
}

local function buildGantries(folder: Folder, map)
	local road = map.road
	local gantries = RoadKit.folder(folder, "Gantries")
	for _, g in GANTRIES do
		RoadKit.gantry(gantries, road, g.s, -road.leftEdge - BARRIER_WIDTH, road.rightEdge + BARRIER_WIDTH, 6.0, {
			{ offset = 0, width = road.lanes * road.laneWidth * 0.8, lines = g.lines },
		})
	end
end

local function buildTrees(folder: Folder, map, random: Random)
	local road = map.road
	local trees = RoadKit.folder(folder, "Trees")
	local start = map.data.start
	local placed = 0
	local tries = 0
	while placed < TREES and tries < TREES * 4 do
		tries += 1
		local s = random:NextNumber(0, road.length)
		local outside = random:NextNumber() < 0.6
		local offset = if outside then -(road.leftEdge + random:NextNumber(10, 70)) else road.rightEdge + random:NextNumber(10, 45)
		local clear = not inGallery(map, s) and not inGallery(map, s + 30) and not inGallery(map, s - 30) and not nearOverpass(s, 40)
		-- keep the paddock and the distance boards' sight lines open
		if not outside and (math.abs(road:delta(start, s)) < 120 or (s > start and s < start + 2100)) then
			clear = false
		end
		if clear then
			local height = random:NextNumber(5, 9)
			local base = RoadKit.levelCFrame(road, s, offset, 0)
			RoadKit.part(trees, "Trunk", Vector3.new(0.5, height * 0.5, 0.5), base * CFrame.new(0, height * 0.25 / M, 0), COLORS.trunk,
				Enum.Material.Wood, true)
			local size = random:NextNumber(3.5, 6)
			local crown = RoadKit.part(trees, "Crown", Vector3.new(size, size, size), base * CFrame.new(0, (height * 0.5 + size * 0.35) / M, 0),
				COLORS.leaves[random:NextInteger(1, #COLORS.leaves)], Enum.Material.LeafyGrass, false)
			crown.Shape = Enum.PartType.Ball
			placed += 1
		end
	end
end

local function buildSurroundings(folder: Folder, map, random: Random)
	local road = map.road
	local surroundings = RoadKit.folder(folder, "Surroundings")

	-- grass over the whole area, tiled because parts are limited to 2,048 studs a side
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for s = 0, road.length, 25 do
		local x, z = road:planAt(s)
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
	end
	minX, maxX, minZ, maxZ = minX - 700, maxX + 700, minZ - 700, maxZ + 700
	local tile = 2000 * M
	local x = minX
	while x < maxX do
		local z = minZ
		while z < maxZ do
			local sizeX = math.min(tile, maxX - x)
			local sizeZ = math.min(tile, maxZ - z)
			local centre = Vector3.new(x + sizeX / 2, road.base - 0.55, z + sizeZ / 2)
			RoadKit.part(surroundings, "Grass", Vector3.new(sizeX, 1, sizeZ), CFrame.new(centre / M), COLORS.grass, Enum.Material.Grass, true)
			z += tile
		end
		x += tile
	end

	-- distant buildings outside the lap give the eye something to measure speed against
	local palette = { Color3.fromRGB(150, 154, 160), Color3.fromRGB(110, 118, 128), Color3.fromRGB(176, 170, 160), Color3.fromRGB(86, 96, 110) }
	for _ = 1, 70 do
		local s = random:NextNumber(0, road.length)
		local offset = -(road.leftEdge + random:NextNumber(120, 520))
		local height = random:NextNumber(25, 180)
		local size = Vector3.new(random:NextNumber(20, 60), height, random:NextNumber(20, 60))
		local centre = RoadKit.point(road, s, offset, height / 2)
		local material = if random:NextNumber() < 0.4 then Enum.Material.Glass else Enum.Material.Concrete
		RoadKit.part(surroundings, "Building", size, CFrame.new(centre / M) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0),
			palette[random:NextInteger(1, #palette)], material, true)
	end

	-- infield pad with the player spawn point, beside the start line
	local padPosition = RoadKit.point(road, map.data.start - 40, road.rightEdge + 30, 0)
	RoadKit.part(surroundings, "Paddock", Vector3.new(60, 0.4, 30), CFrame.new((padPosition - Vector3.new(0, 0.15, 0)) / M), COLORS.pad,
		Enum.Material.Concrete, true)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PaddockSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(4, 0.2, 4) / M
	spawn.CFrame = CFrame.new((padPosition + Vector3.new(0, 0.15, 0)) / M)
	spawn.Color = Color3.fromRGB(70, 70, 74)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = surroundings
end

-- Build the oval into Workspace.Maps. Returns the number of parts made.
function TrackBuilder.build(map): number
	local maps = Workspace:FindFirstChild("Maps") or Instance.new("Folder")
	maps.Name = "Maps"
	maps.Parent = Workspace
	local existing = maps:FindFirstChild(map.id)
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = map.id
	local road = map.road
	local random = Random.new(42)
	local points = RoadKit.loopPieces(road, OVERPASSES)
	buildRoad(folder, map, points)
	buildMarkings(folder, map, points)
	buildBarriers(folder, map, points)
	buildPoles(folder, map)
	buildBoards(folder, map)
	for _, section in road.sections do
		if section.kind == "tunnel" then
			buildGallery(folder, map, section)
		end
	end
	for _, s in OVERPASSES do
		buildOverpass(folder, map, s)
	end
	buildGantries(folder, map)
	buildTrees(folder, map, random)
	buildSurroundings(folder, map, random)
	folder.Parent = maps
	return RoadKit.countParts(folder)
end

return TrackBuilder
