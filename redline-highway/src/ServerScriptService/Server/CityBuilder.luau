--[[
	CityBuilder
	Builds Sekirei Bay Loop, the city map (TrafficSystem/Maps/City): a fictional night-time urban
	expressway. The road is a concrete viaduct with tight parapet walls on T-shaped piers, dropping
	onto embankments and into two sodium-lit box tunnels under built-over decks ("podiums"), with
	lamps on the parapets, sign gantries, noise screens through the S-bends, two decorative viaducts
	across the bay, a dense backdrop of buildings with lit windows and billboards, the bay and a far
	shore.

	The road's shape comes from the map's data through RoadGeometry; RoadKit makes the parts. Sizes
	are in metres. The street level is the map's base height (0 m); the bay is south of the shore.
	Part counts are kept down by using long boxes where the road is straight and lighting only
	every other lamp; the builder prints how many parts it made.
]]

local Workspace = game:GetService("Workspace")

local RoadKit = require(script.Parent.RoadKit)

local M = RoadKit.M
local C = RoadKit.COLORS

local CityBuilder = {}

-- cross-section
local SLAB = 0.6 -- m, the road deck
local GIRDER = 1.8 -- m, the box girder under raised road
local WALL_WIDTH = 0.5
local WALL_HEIGHT = 1.1 -- parapet above the road
local PIER_MIN = 6 -- m: road at least this high stands on piers; lower, on a solid embankment
local GRADE = 0.8 -- m: road lower than this sits on the street
local PIER_SPACING = 34 -- m
local DASH, GAP = 8, 12 -- lane lines: metres painted and bare, expressway style
local LAMP_SPACING = 40 -- m between lamps, alternating sides
-- tunnels
local TUNNEL_HEIGHT = 6.4 -- m, road to ceiling
local TUNNEL_WALL = 0.8
local ROOF = 1.0
local PODIUM = 22 -- m of built-over deck beside each tunnel wall
local TUNNEL_LAMP_SPACING = 12 -- m between lamps on each wall
-- the bay
local SEA_LEVEL = -1.2 -- m below the street
local SEA_BED = -8
local NOISE_SCREENS = { { 3380, 5000 } } -- s ranges with tall glass screens on both parapets

local COLORS = {
	ground = Color3.fromRGB(38, 40, 44),
	water = Color3.fromRGB(14, 28, 44),
	farShore = Color3.fromRGB(30, 32, 34),
	deck = Color3.fromRGB(150, 150, 146),
	girder = Color3.fromRGB(112, 114, 112),
	podium = Color3.fromRGB(96, 98, 100),
	park = Color3.fromRGB(34, 58, 38),
	screen = Color3.fromRGB(150, 190, 200),
	exitSign = Color3.fromRGB(40, 220, 110),
	lampLed = Color3.fromRGB(255, 238, 210),
	aviation = Color3.fromRGB(255, 40, 30),
	buildings = {
		Color3.fromRGB(58, 62, 70), Color3.fromRGB(72, 76, 84), Color3.fromRGB(44, 48, 56), Color3.fromRGB(88, 90, 96),
		Color3.fromRGB(66, 60, 56), Color3.fromRGB(52, 58, 66), Color3.fromRGB(96, 92, 86),
	},
	windows = {
		Color3.fromRGB(235, 196, 128), Color3.fromRGB(190, 210, 240), Color3.fromRGB(226, 226, 214),
		Color3.fromRGB(240, 180, 110), Color3.fromRGB(170, 230, 220),
	},
	neonSigns = { Color3.fromRGB(255, 70, 120), Color3.fromRGB(60, 200, 255), Color3.fromRGB(255, 190, 40), Color3.fromRGB(150, 90, 255) },
}

local GANTRIES = {
	{ s = 500, lines = { "KIRAMEKI JCT  2 km", "Seaside Straight" } },
	{ s = 2350, lines = { "KIRAMEKI JCT", "Ward S-bends ahead" } },
	{ s = 4600, lines = { "KAGEROU TUNNEL  2.5 km", "Lights on   Keep your distance" } },
	{ s = 8000, lines = { "TSUKIMI JCT", "Loop ahead   60 km/h" } },
	{ s = 10560, lines = { "HOTARU TUNNEL", "Umikaze JCT  1 km" } },
	{ s = 12450, lines = { "SEASIDE STRAIGHT", "Kirameki JCT  3 km" } },
}

local BILLBOARDS = {
	"HOSHIMI COFFEE", "SEKIREI DENKI", "KAZE RAMEN", "MIDNIGHT FM 88.1", "AOZORA BEER", "REDLINE MOTORS",
	"BLUE LINE BANK", "TSUBAME TYRES", "NEON TONIGHT", "KITE CAMERA", "SHINKAI HOTEL", "TOKAI DRINKS",
}

local function heightAbove(road, s: number): number
	local y = road:heightAt(s)
	return y - road.base
end

local function inTunnel(road, s: number)
	return road:sectionAt(s, "tunnel")
end

-- Points where the road's support changes (pier, embankment, street), found every metre.
local function supportBreaks(road): { number }
	local breaks = {}
	local function kind(s: number): number
		local h = heightAbove(road, s)
		return if h >= PIER_MIN then 2 elseif h >= GRADE then 1 else 0
	end
	local previous = kind(0)
	for s = 1, math.floor(road.length) do
		local k = kind(s)
		if k ~= previous then
			table.insert(breaks, s)
			previous = k
		end
	end
	for _, range in NOISE_SCREENS do
		table.insert(breaks, range[1])
		table.insert(breaks, range[2])
	end
	return breaks
end

local function screened(s: number): boolean
	for _, range in NOISE_SCREENS do
		if s >= range[1] and s < range[2] then
			return true
		end
	end
	return false
end

--[[
	The road deck all round: asphalt, parapets (or tunnel walls), edge lines, and what holds it up:
	a box girder where it's raised, a solid embankment where it's low.
]]
local function buildDeck(folder: Folder, road, points: { number })
	local deck = RoadKit.folder(folder, "Road")
	local walls = RoadKit.folder(folder, "Walls")
	local structure = RoadKit.folder(folder, "Structure")
	local markings = RoadKit.folder(folder, "Markings")
	local width = road.leftEdge + road.rightEdge
	local centre = (road.rightEdge - road.leftEdge) / 2
	local leftWall = -(road.leftEdge + WALL_WIDTH / 2)
	local rightWall = road.rightEdge + WALL_WIDTH / 2
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local mid = (a + b) / 2
		local extend = RoadKit.overlap(road, a, b, width + 2 * WALL_WIDTH)
		RoadKit.strip(deck, road, "Asphalt", a, b, centre, width, SLAB, 0, C.asphalt, Enum.Material.Asphalt, true, extend)
		local ha, hb = heightAbove(road, a), heightAbove(road, b)
		local low, high = math.min(ha, hb), math.max(ha, hb)
		if not inTunnel(road, mid) then
			local depth = WALL_HEIGHT + SLAB + (if low >= PIER_MIN then GIRDER * 0.4 else 0)
			for _, offset in { leftWall, rightWall } do
				RoadKit.strip(walls, road, "Parapet", a, b, offset, WALL_WIDTH, depth, WALL_HEIGHT, COLORS.deck, Enum.Material.Concrete,
					true, RoadKit.overlap(road, a, b, WALL_WIDTH))
				if screened(mid) then
					local screen = RoadKit.strip(walls, road, "NoiseScreen", a, b, offset, 0.12, 2.6, WALL_HEIGHT + 2.6, COLORS.screen,
						Enum.Material.Glass, true, RoadKit.overlap(road, a, b, 0.12))
					if screen then
						screen.Transparency = 0.55
						screen.CastShadow = false
					end
				end
			end
			if low >= PIER_MIN then
				RoadKit.strip(structure, road, "Girder", a, b, centre, width * 0.55, GIRDER, -SLAB, COLORS.girder, Enum.Material.Concrete,
					true, RoadKit.overlap(road, a, b, width * 0.55))
			elseif high >= GRADE then
				-- a solid embankment with concrete sides, reaching below the street
				RoadKit.strip(structure, road, "Embankment", a, b, centre, width + 2 * WALL_WIDTH, high + 1, -SLAB, COLORS.girder,
					Enum.Material.Concrete, true, extend)
			end
		end
	end
	RoadKit.solidLine(markings, road, points, -road.halfWidth, 0.15, C.line)
	RoadKit.solidLine(markings, road, points, road.halfWidth, 0.15, C.line)
	for k = 1, road.lanes - 1 do
		RoadKit.dashes(markings, road, 0, road.length, (k - road.lanes / 2) * road.laneWidth, DASH, GAP, 0.15, C.line)
	end
	RoadKit.strip(markings, road, "StartLine", road.data.start, road.data.start + 0.6, 0, road.lanes * road.laneWidth, 0.02, 0.02,
		C.line, Enum.Material.SmoothPlastic, false)
end

-- Distances along the loop near which piers must not stand (where a viaduct passes under the road).
local function pierExclusions(map): { number }
	local out = {}
	for _, flyover in map.data.decor.flyovers do
		if flyover.top < heightAbove(map.road, flyover.s) then
			table.insert(out, flyover.s)
		end
	end
	return out
end

-- T-shaped piers under raised road: a square column and a cap beam across the deck.
local function buildPiers(folder: Folder, map)
	local road = map.road
	local piers = RoadKit.folder(folder, "Piers")
	local shore = map.data.decor.shore
	local exclusions = pierExclusions(map)
	local width = road.leftEdge + road.rightEdge
	local centre = (road.rightEdge - road.leftEdge) / 2
	local s = PIER_SPACING / 2
	while s < road.length do
		local h = heightAbove(road, s)
		local clear = h >= PIER_MIN and heightAbove(road, s - 3) >= PIER_MIN and heightAbove(road, s + 3) >= PIER_MIN and not inTunnel(road, s)
		for _, at in exclusions do
			if math.abs(road:delta(at, s)) < 22 then
				clear = false
			end
		end
		local foot = RoadKit.point(road, s, centre, 0)
		-- never stand on another part of the loop
		if clear and road:distanceToRoad(foot, s, 80) < 4 then
			clear = false
		end
		if clear then
			local underside = h - SLAB - GIRDER
			local bottom = if foot.Z > shore then SEA_BED else -0.5
			local capDepth = 1.4
			local columnHeight = underside - capDepth - bottom
			local base = RoadKit.levelCFrame(road, s, centre, -h)
			RoadKit.part(piers, "Column", Vector3.new(2.6, columnHeight, 2.6), base * CFrame.new(0, (bottom + columnHeight / 2) / M, 0),
				COLORS.deck, Enum.Material.Concrete, true)
			RoadKit.part(piers, "Cap", Vector3.new(width * 0.85, capDepth, 2.6), base * CFrame.new(0, (underside - capDepth / 2) / M, 0),
				COLORS.deck, Enum.Material.Concrete, true)
		end
		s += PIER_SPACING
	end
end

-- Lamps on the parapets, alternating sides, reaching over the road; every other one lights it.
-- None where a viaduct passes low overhead.
local function buildLamps(folder: Folder, map)
	local road = map.road
	local lamps = RoadKit.folder(folder, "Lamps")
	local overhead = {}
	for _, flyover in map.data.decor.flyovers do
		if flyover.top > heightAbove(road, flyover.s) then
			table.insert(overhead, flyover.s)
		end
	end
	local s = 10
	local n = 0
	while s < road.length do
		local clear = not inTunnel(road, s) and not inTunnel(road, s + 15) and not inTunnel(road, s - 15)
		for _, at in overhead do
			if math.abs(road:delta(at, s)) < 25 then
				clear = false
			end
		end
		local side = if n % 2 == 0 then -1 else 1
		local offset = if side < 0 then -(road.leftEdge + WALL_WIDTH / 2) else road.rightEdge + WALL_WIDTH / 2
		-- nor under another part of the loop (where it passes over itself)
		if clear and road:distanceToRoad(RoadKit.point(road, s, offset, 0), s, 80) < 6 then
			clear = false
		end
		if clear then
			local base = RoadKit.levelCFrame(road, s, offset, WALL_HEIGHT)
			local poleHeight = 8
			RoadKit.part(lamps, "Pole", Vector3.new(0.25, poleHeight, 0.25), base * CFrame.new(0, poleHeight / 2 / M, 0), C.steel,
				Enum.Material.Metal, false)
			-- the arm reaches toward the road's centre (-side along the base's X axis)
			RoadKit.part(lamps, "Arm", Vector3.new(2.6, 0.15, 0.15), base * CFrame.new(-side * 1.3 / M, poleHeight / M, 0), C.steel,
				Enum.Material.Metal, false)
			local head = RoadKit.part(lamps, "Lamp", Vector3.new(1.2, 0.22, 0.5), base * CFrame.new(-side * 2.5 / M, (poleHeight - 0.15) / M, 0),
				COLORS.lampLed, Enum.Material.Neon, false)
			head.CastShadow = false
			if n % 2 == 0 then
				local light = Instance.new("SpotLight")
				light.Face = Enum.NormalId.Bottom
				light.Angle = 110
				light.Range = 60
				light.Brightness = 3
				light.Color = COLORS.lampLed
				light.Shadows = false
				light.Parent = head
			end
		end
		n += 1
		s += LAMP_SPACING
	end
end

--[[
	A box tunnel from section.from to section.to: tiled walls, the roof, a built-over deck beside it
	(the podium) for buildings or a park on top, headwalls with the tunnel's name at the portals,
	sodium lamps on both walls, emergency signs, jet fans, and the TunnelZone boxes.
]]
local function buildTunnel(folder: Folder, map, section)
	local road = map.road
	local tunnel = RoadKit.folder(folder, section.name or "Tunnel")
	local s0, s1 = section.from, section.to
	local points = RoadKit.pieces(road, s0, s1)
	local leftFace, rightFace = -road.leftEdge, road.rightEdge
	local outerLeft, outerRight = leftFace - TUNNEL_WALL, rightFace + TUNNEL_WALL
	local podiumLeft, podiumRight = outerLeft - PODIUM, outerRight + PODIUM
	local podiumCentre = (podiumLeft + podiumRight) / 2
	local podiumWidth = podiumRight - podiumLeft
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local high = math.max(heightAbove(road, a), heightAbove(road, b))
		local extend = RoadKit.overlap(road, a, b, podiumWidth)
		for _, offset in { leftFace - TUNNEL_WALL / 2, rightFace + TUNNEL_WALL / 2 } do
			RoadKit.strip(tunnel, road, "TunnelWall", a, b, offset, TUNNEL_WALL, TUNNEL_HEIGHT + SLAB, TUNNEL_HEIGHT, C.tunnelTile,
				Enum.Material.SmoothPlastic, true, RoadKit.overlap(road, a, b, TUNNEL_WALL))
		end
		RoadKit.strip(tunnel, road, "Roof", a, b, podiumCentre, podiumWidth, ROOF, TUNNEL_HEIGHT + ROOF, COLORS.podium,
			Enum.Material.Concrete, true, extend)
		-- the podium's solid sides, from the street up to the roof
		for _, offset in { (podiumLeft + outerLeft) / 2, (outerRight + podiumRight) / 2 } do
			RoadKit.strip(tunnel, road, "Podium", a, b, offset, PODIUM, TUNNEL_HEIGHT + high + 1, TUNNEL_HEIGHT, COLORS.podium,
				Enum.Material.Concrete, true, RoadKit.overlap(road, a, b, PODIUM))
		end
	end
	-- headwalls above the portals, with the tunnel's name facing approaching cars at the entrance
	for _, at in { s0, s1 } do
		local base = RoadKit.levelCFrame(road, at, podiumCentre, TUNNEL_HEIGHT + ROOF)
		RoadKit.part(tunnel, "Headwall", Vector3.new(podiumWidth, 2.4, 1.0), base * CFrame.new(0, 1.2 / M, 0), COLORS.podium,
			Enum.Material.Concrete, true)
	end
	local nameCFrame = RoadKit.levelCFrame(road, s0 - 0.6, 0, TUNNEL_HEIGHT + 1.5) * CFrame.Angles(0, math.pi, 0)
	local length = s1 - s0
	RoadKit.sign(tunnel, "TunnelName", Vector3.new(14, 1.8, 0.2), nameCFrame, Color3.fromRGB(16, 20, 28),
		{ string.upper(section.name or "Tunnel") .. string.format("   %.1f km", length / 1000) }, Color3.fromRGB(255, 255, 255))

	-- sodium lamps on both walls, staggered; one in four lights the tunnel, alternating walls
	local lamps = RoadKit.folder(tunnel, "Lamps")
	local n = 0
	local s = s0 + TUNNEL_LAMP_SPACING / 2
	while s < s1 - 2 do
		local onLeft = n % 2 == 0
		local offset = if onLeft then leftFace + 0.2 else rightFace - 0.2
		local fixture = RoadKit.part(lamps, "SodiumLamp", Vector3.new(0.35, 0.3, 1.6), RoadKit.cframe(road, s, offset, TUNNEL_HEIGHT - 1.2),
			C.sodium, Enum.Material.Neon, false)
		fixture.CastShadow = false
		if n % 8 == 0 or n % 8 == 5 then
			local light = Instance.new("PointLight")
			light.Range = 50
			light.Brightness = 2.4
			light.Color = C.sodium
			light.Shadows = false
			light.Parent = fixture
		end
		n += 1
		s += TUNNEL_LAMP_SPACING / 2
	end
	-- emergency exit signs and jet fans
	s = s0 + 75
	while s < s1 - 20 do
		local sign = RoadKit.part(tunnel, "ExitSign", Vector3.new(0.15, 0.45, 0.9), RoadKit.cframe(road, s, leftFace + 0.1, 2.4),
			COLORS.exitSign, Enum.Material.Neon, false)
		sign.CastShadow = false
		s += 150
	end
	s = s0 + 160
	while s < s1 - 100 do
		for _, offset in { -2.6, 2.6 } do
			local fan = RoadKit.part(tunnel, "JetFan", Vector3.new(4, 1.2, 1.2), RoadKit.cframe(road, s, offset, TUNNEL_HEIGHT - 0.9)
				* CFrame.Angles(0, math.pi / 2, 0), C.steel, Enum.Material.Metal, false)
			fan.Shape = Enum.PartType.Cylinder
		end
		s += 350
	end
	RoadKit.tunnelZones(tunnel, road, s0, s1, leftFace, rightFace, TUNNEL_HEIGHT, {
		ReverbDecay = section.reverb or 1.6,
		TunnelName = section.name or "Tunnel",
		MapId = map.id,
	})
	return podiumLeft, podiumRight
end

local function buildGantries(folder: Folder, map)
	local road = map.road
	local gantries = RoadKit.folder(folder, "Gantries")
	for _, g in GANTRIES do
		-- the posts stand on the parapets
		RoadKit.gantry(gantries, road, g.s, -(road.leftEdge + WALL_WIDTH / 2) + 0.6, road.rightEdge + WALL_WIDTH / 2 - 0.6, 5.6, {
			{ offset = 0, width = road.lanes * road.laneWidth * 0.85, lines = g.lines },
		})
	end
end

-- The plan-view centre line of a decorative viaduct: start point, direction and length.
local function flyoverLine(road, flyover): (Vector3, Vector3, number)
	local x, z, heading = road:planAt(flyover.s)
	local angle = heading + math.rad(flyover.angle)
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local start = Vector3.new(x, 0, z) - direction * flyover.back
	return start, direction, flyover.back + flyover.ahead
end

local function distanceToSegment(p: Vector3, a: Vector3, direction: Vector3, length: number): number
	local d = p - a
	local t = math.clamp(d.X * direction.X + d.Z * direction.Z, 0, length)
	local q = a + direction * t
	return math.sqrt((p.X - q.X) ^ 2 + (p.Z - q.Z) ^ 2)
end

-- Decorative viaducts: level deck at the junction, ramps down to the ground at both ends, piers
-- that keep off the loop, dotted lights along both edges, and suspension towers if asked.
local function buildFlyover(folder: Folder, map, flyover)
	local road = map.road
	local viaduct = RoadKit.folder(folder, flyover.name or "Viaduct")
	local start, direction, length = flyoverLine(road, flyover)
	local shore = map.data.decor.shore
	local farShore = map.data.decor.farShore
	local deckWidth, deckDepth = 12, 1.6
	local top = flyover.top
	local ramp = flyover.ramp
	local function topAt(t: number): number
		return top * math.clamp(math.min(t, length - t) / ramp, 0, 1)
	end
	local function ground(p: Vector3): number
		return if p.Z > shore and p.Z < farShore then SEA_BED else -0.5
	end
	local right = Vector3.new(-direction.Z, 0, direction.X)
	-- deck in three straight boxes per side of the junction: ramp, level, level, ramp
	local cuts = { 0, ramp, length / 2, length - ramp, length }
	for i = 1, #cuts - 1 do
		local t0, t1 = cuts[i], cuts[i + 1]
		local piece = math.ceil((t1 - t0) / 380)
		for j = 0, piece - 1 do
			local a0 = t0 + (t1 - t0) * j / piece
			local a1 = t0 + (t1 - t0) * (j + 1) / piece
			local pa = start + direction * a0 + Vector3.new(0, topAt(a0), 0)
			local pb = start + direction * a1 + Vector3.new(0, topAt(a1), 0)
			local mid = (pa + pb) / 2
			local axis = CFrame.lookAt(mid / M, pb / M)
			local span = (pb - pa).Magnitude
			RoadKit.part(viaduct, "Deck", Vector3.new(deckWidth, deckDepth, span + 0.3), axis * CFrame.new(0, -deckDepth / 2 / M, 0),
				COLORS.deck, Enum.Material.Concrete, true)
			for _, side in { -1, 1 } do
				RoadKit.part(viaduct, "Parapet", Vector3.new(0.4, 1.1, span + 0.3), axis * CFrame.new(side * (deckWidth / 2 - 0.2) / M, 0.55 / M, 0),
					COLORS.deck, Enum.Material.Concrete, true)
			end
		end
	end
	-- piers and edge lights
	local t = 20
	while t < length - 20 do
		local h = topAt(t)
		local foot = start + direction * t
		if h > 5 and road:distanceToRoad(foot) > 3 then
			local bottom = ground(foot)
			local height = h - deckDepth - bottom
			RoadKit.part(viaduct, "Pier", Vector3.new(2.2, height, 2.2), CFrame.new((foot + Vector3.new(0, bottom + height / 2, 0)) / M),
				COLORS.deck, Enum.Material.Concrete, true)
		end
		if h > 2 then
			for _, side in { -1, 1 } do
				local p = foot + right * side * (deckWidth / 2 - 0.2) + Vector3.new(0, h + 1.2, 0)
				local dot = RoadKit.part(viaduct, "EdgeLight", Vector3.new(0.3, 0.3, 0.3), CFrame.new(p / M), COLORS.lampLed, Enum.Material.Neon, false)
				dot.CastShadow = false
			end
		end
		t += 45
	end
	if flyover.towers then
		-- two suspension towers over the water, with lit cables between them
		local over = {}
		t = 0
		while t < length do
			local p = start + direction * t
			if p.Z > shore + 300 and p.Z < farShore - 300 then
				table.insert(over, t)
			end
			t += 10
		end
		if #over > 2 then
			local first, last = over[1], over[#over]
			local towers = { first + (last - first) * 0.3, first + (last - first) * 0.7 }
			local towerHeight = top + 90
			for _, at in towers do
				local foot = start + direction * at
				for _, side in { -1, 1 } do
					local p = foot + right * side * (deckWidth / 2 + 1.5)
					RoadKit.part(viaduct, "Tower", Vector3.new(3, towerHeight - SEA_BED, 3), CFrame.new((p + Vector3.new(0, (towerHeight + SEA_BED) / 2, 0)) / M),
						COLORS.deck, Enum.Material.Concrete, true)
					local beacon = RoadKit.part(viaduct, "Beacon", Vector3.new(1.2, 1.2, 1.2), CFrame.new((p + Vector3.new(0, towerHeight + 0.6, 0)) / M),
						COLORS.aviation, Enum.Material.Neon, false)
					beacon.CastShadow = false
				end
				RoadKit.part(viaduct, "TowerBeam", Vector3.new(deckWidth + 6, 3, 3),
					CFrame.lookAt((foot + Vector3.new(0, towerHeight - 8, 0)) / M, (foot + Vector3.new(0, towerHeight - 8, 0) + right) / M)
						* CFrame.Angles(0, math.pi / 2, 0), COLORS.deck, Enum.Material.Concrete, false)
			end
			-- main cables: sagging between the towers, straight down to the deck beyond them
			for _, side in { -1, 1 } do
				local function cablePoint(u: number): Vector3
					local tAt = towers[1] + (towers[2] - towers[1]) * u
					local sag = 4 * u * (1 - u)
					local p = start + direction * tAt + right * side * (deckWidth / 2 + 1.5)
					return p + Vector3.new(0, towerHeight - 2 - (towerHeight - top - 6) * sag, 0)
				end
				local segments = 10
				for k = 0, segments - 1 do
					local pa, pb = cablePoint(k / segments), cablePoint((k + 1) / segments)
					local cable = RoadKit.part(viaduct, "Cable", Vector3.new(0.35, 0.35, (pb - pa).Magnitude), CFrame.lookAt(((pa + pb) / 2) / M, pb / M),
						COLORS.lampLed, Enum.Material.Neon, false)
					cable.CastShadow = false
				end
				for index, at in { towers[1], towers[2] } do
					local outward = if index == 1 then -1 else 1
					local pa = start + direction * at + right * side * (deckWidth / 2 + 1.5) + Vector3.new(0, towerHeight - 2, 0)
					local pb = start + direction * (at + outward * 300) + right * side * (deckWidth / 2) + Vector3.new(0, top + 1, 0)
					local cable = RoadKit.part(viaduct, "Cable", Vector3.new(0.35, 0.35, (pb - pa).Magnitude), CFrame.lookAt(((pa + pb) / 2) / M, pb / M),
						COLORS.lampLed, Enum.Material.Neon, false)
					cable.CastShadow = false
				end
			end
		end
	end
	return start, direction, length
end

-- The street, the bay, the sea wall and the far shore.
local function buildGround(folder: Folder, map): (number, number, number, number)
	local road = map.road
	local ground = RoadKit.folder(folder, "Ground")
	local shore = map.data.decor.shore
	local farShore = map.data.decor.farShore
	local minX, maxX, minZ = math.huge, -math.huge, math.huge
	for s = 0, road.length, 25 do
		local x, z = road:planAt(s)
		minX, maxX, minZ = math.min(minX, x), math.max(maxX, x), math.min(minZ, z)
	end
	minX, maxX, minZ = minX - 900, maxX + 900, minZ - 900
	local tile = 2000 * M
	local function tiles(name: string, x0: number, x1: number, z0: number, z1: number, top: number, color: Color3, material: Enum.Material)
		local x = x0
		while x < x1 do
			local z = z0
			while z < z1 do
				local sizeX, sizeZ = math.min(tile, x1 - x), math.min(tile, z1 - z)
				RoadKit.part(ground, name, Vector3.new(sizeX, 2, sizeZ), CFrame.new(Vector3.new(x + sizeX / 2, road.base + top - 1, z + sizeZ / 2) / M),
					color, material, true)
				z += tile
			end
			x += tile
		end
	end
	tiles("Street", minX, maxX, minZ, shore, 0, COLORS.ground, Enum.Material.Asphalt)
	tiles("Bay", minX, maxX, shore, farShore, SEA_LEVEL, COLORS.water, Enum.Material.Glass)
	tiles("FarShore", minX, maxX, farShore, farShore + 1100, 0, COLORS.farShore, Enum.Material.Concrete)
	for _, part in ground:GetChildren() do
		if part.Name == "Bay" then
			(part :: BasePart).Reflectance = 0.12
		end
	end
	-- sea walls along both shores
	local x = minX
	while x < maxX do
		local sizeX = math.min(tile, maxX - x)
		for _, z in { shore, farShore } do
			RoadKit.part(ground, "SeaWall", Vector3.new(sizeX, 2.2, 1.5), CFrame.new(Vector3.new(x + sizeX / 2, road.base - 0.6, z) / M),
				COLORS.girder, Enum.Material.Concrete, true)
		end
		x += tile
	end
	return minX, maxX, minZ, shore
end

type Footprint = { centre: Vector3, right: Vector3, forward: Vector3, width: number, depth: number }

local function footprintPoints(f: Footprint): { Vector3 }
	local points = {}
	for _, u in { -0.5, 0, 0.5 } do
		for _, v in { -0.5, 0, 0.5 } do
			table.insert(points, f.centre + f.right * (u * f.width) + f.forward * (v * f.depth))
		end
	end
	return points
end

--[[
	A building: a box with bands of lit windows on the face toward the road (night), and a red light
	on the roof of tall ones. base is the height (m) it stands on.
]]
local function building(parent: Instance, random: Random, f: Footprint, base: number, height: number, towardRoad: Vector3)
	local cf = CFrame.fromMatrix(Vector3.zero, f.right, Vector3.yAxis, -f.forward)
	local position = f.centre + Vector3.new(0, base + height / 2, 0)
	local color = COLORS.buildings[random:NextInteger(1, #COLORS.buildings)]
	local material = if random:NextNumber() < 0.35 then Enum.Material.Glass else Enum.Material.Concrete
	RoadKit.part(parent, "Building", Vector3.new(f.width, height, f.depth), (cf + position / M), color, material, true)
	-- window bands on the face toward the road
	local faceAcross = math.abs(towardRoad:Dot(f.forward)) > math.abs(towardRoad:Dot(f.right))
	local faceNormal = if faceAcross then f.forward * math.sign(towardRoad:Dot(f.forward)) else f.right * math.sign(towardRoad:Dot(f.right))
	local faceWidth = if faceAcross then f.width else f.depth
	local faceDistance = if faceAcross then f.depth / 2 else f.width / 2
	local bands = random:NextInteger(1, math.clamp(math.floor(height / 12), 1, 3))
	local windowColor = COLORS.windows[random:NextInteger(1, #COLORS.windows)]
	for _ = 1, bands do
		local y = base + random:NextNumber(4, math.max(4.5, height - 3))
		local bandHeight = random:NextNumber(0.5, 1.6)
		local centre = f.centre + faceNormal * (faceDistance + 0.12) + Vector3.new(0, y, 0)
		local band = RoadKit.part(parent, "Windows", Vector3.new(faceWidth * random:NextNumber(0.5, 0.9), bandHeight, 0.2),
			CFrame.lookAt(centre / M, (centre + faceNormal) / M), windowColor, Enum.Material.Neon, false)
		band.CastShadow = false
	end
	if height > 70 then
		local beacon = RoadKit.part(parent, "Beacon", Vector3.new(0.8, 0.8, 0.8), CFrame.new((f.centre + Vector3.new(0, base + height + 0.4, 0)) / M),
			COLORS.aviation, Enum.Material.Neon, false)
		beacon.CastShadow = false
	end
end

local function billboard(parent: Instance, random: Random, f: Footprint, base: number, height: number, towardRoad: Vector3, text: string)
	local width = math.min(f.width, 18)
	local centre = f.centre + Vector3.new(0, base + height + 3.2, 0)
	local cf = CFrame.lookAt(centre / M, (centre + Vector3.new(towardRoad.X, 0, towardRoad.Z)) / M)
	RoadKit.sign(parent, "Billboard", Vector3.new(width, 5, 0.4), cf, Color3.fromRGB(12, 12, 16), { text },
		COLORS.neonSigns[random:NextInteger(1, #COLORS.neonSigns)])
	RoadKit.part(parent, "BillboardFrame", Vector3.new(width * 0.6, 1.2, 0.6), cf * CFrame.new(0, -3 / M, 0.4 / M), C.steel, Enum.Material.Metal, false)
end

--[[
	The city: buildings along both sides of the loop in a near band (facing the road, 6 to 30 m from
	its edge) and a far band (the skyline), on the podiums over the tunnels, and low lit sheds on the
	far shore. Every footprint keeps clear of the road (all of it, including where the loop doubles
	back), the viaducts, the podiums and the water.
]]
local function buildCity(folder: Folder, map, random: Random, flyovers, podiums)
	local road = map.road
	local city = RoadKit.folder(folder, "City")
	local shore = map.data.decor.shore
	local farShore = map.data.decor.farShore
	local billboardIndex = 0

	local function clear(f: Footprint, roadMargin: number): boolean
		for _, p in footprintPoints(f) do
			if p.Z > shore - 10 then
				return false
			end
			local distance = road:distanceToRoad(p)
			if distance < roadMargin then
				return false
			end
			-- beside a tunnel, keep off its podium too
			if distance < PODIUM + TUNNEL_WALL + 4 and inTunnel(road, road:project(p, true)) then
				return false
			end
			for _, line in flyovers do
				if distanceToSegment(p, line[1], line[2], line[3]) < 6 + 6 then
					return false
				end
			end
		end
		return true
	end

	local function place(s: number, side: number, near: boolean)
		local x, z, heading = road:planAt(s)
		local forward = Vector3.new(math.cos(heading), 0, math.sin(heading))
		local right = Vector3.new(-forward.Z, 0, forward.X)
		local width = random:NextNumber(14, if near then 40 else 60)
		local depth = random:NextNumber(14, if near then 34 else 60)
		local edge = if side < 0 then road.leftEdge else road.rightEdge
		local distance = if near then edge + random:NextNumber(6, 30) + depth / 2 else edge + random:NextNumber(70, 420)
		local centre = Vector3.new(x, 0, z) + right * side * distance
		-- the near band faces the road; the far band is turned a little at random
		local turn = if near then 0 else random:NextNumber(-0.5, 0.5)
		local f: Footprint = {
			centre = centre,
			forward = (forward * math.cos(turn) + right * math.sin(turn)).Unit,
			right = (right * math.cos(turn) - forward * math.sin(turn)).Unit,
			width = depth,
			depth = width,
		}
		if not clear(f, 6) then
			return
		end
		local height
		if near then
			height = random:NextNumber(14, 55) * (if random:NextNumber() < 0.12 then 2.2 else 1)
		else
			height = random:NextNumber(30, 150)
		end
		local towardRoad = right * -side
		building(city, random, f, road.base, height, towardRoad)
		if near and height < 45 and random:NextNumber() < 0.06 then
			billboardIndex = billboardIndex % #BILLBOARDS + 1
			billboard(city, random, f, road.base, height, towardRoad, BILLBOARDS[billboardIndex])
		end
	end

	local s = 0
	while s < road.length do
		for _, side in { -1, 1 } do
			if random:NextNumber() < 0.72 then
				place(s + random:NextNumber(-6, 6), side, true)
			end
		end
		s += 21
	end
	s = 0
	while s < road.length do
		for _, side in { -1, 1 } do
			if random:NextNumber() < 0.6 then
				place(s, side, false)
			end
		end
		s += 55
	end

	-- buildings on the tunnel podiums (a park with trees on the short tunnel)
	for _, podium in podiums do
		local section, left, right = podium[1], podium[2], podium[3]
		local isPark = (section.to - section.from) < 1000
		local at = section.from + 25
		while at < section.to - 25 do
			local x, z, heading = road:planAt(at)
			local y = road:heightAt(at) + TUNNEL_HEIGHT + ROOF
			local forward = Vector3.new(math.cos(heading), 0, math.sin(heading))
			local sideways = Vector3.new(-forward.Z, 0, forward.X)
			if isPark then
				for _, offset in { left + 6, right - 6, (left + right) / 2 } do
					if random:NextNumber() < 0.7 then
						local p = Vector3.new(x, y, z) + sideways * (offset + random:NextNumber(-3, 3))
						local trunk = 3
						RoadKit.part(city, "Trunk", Vector3.new(0.4, trunk, 0.4), CFrame.new((p + Vector3.new(0, trunk / 2, 0)) / M),
							Color3.fromRGB(60, 46, 36), Enum.Material.Wood, false)
						local size = random:NextNumber(3, 5)
						local crown = RoadKit.part(city, "Crown", Vector3.new(size, size, size), CFrame.new((p + Vector3.new(0, trunk + size * 0.35, 0)) / M),
							COLORS.park, Enum.Material.LeafyGrass, false)
						crown.Shape = Enum.PartType.Ball
					end
				end
			else
				for _, lane in { { left + 9, 14 }, { (left + right) / 2, 12 }, { right - 9, 14 } } do
					if random:NextNumber() < 0.65 then
						local f: Footprint = {
							centre = Vector3.new(x, 0, z) + sideways * lane[1],
							forward = forward,
							right = sideways,
							width = lane[2] + random:NextNumber(0, 4),
							depth = random:NextNumber(18, 34),
						}
						local height = random:NextNumber(18, 85)
						building(city, random, f, y, height, sideways * -math.sign(lane[1] + 0.001))
					end
				end
			end
			at += if isPark then 30 else 42
		end
		if isPark then
			local points = RoadKit.pieces(road, section.from, section.to)
			for i = 1, #points - 1 do
				RoadKit.strip(city, road, "Park", points[i], points[i + 1], (left + right) / 2, right - left, 0.3, TUNNEL_HEIGHT + ROOF + 0.3,
					COLORS.park, Enum.Material.Grass, true, RoadKit.overlap(road, points[i], points[i + 1], right - left))
			end
		end
	end

	-- the far shore: low warehouses with a few lights
	for _ = 1, 45 do
		local x = random:NextNumber(-3400, 3400)
		local z = random:NextNumber(farShore + 60, farShore + 700)
		local f: Footprint = { centre = Vector3.new(x, 0, z), forward = Vector3.zAxis, right = Vector3.xAxis,
			width = random:NextNumber(30, 90), depth = random:NextNumber(20, 60) }
		local clearOfViaducts = true
		for _, line in flyovers do
			for _, p in footprintPoints(f) do
				if distanceToSegment(p, line[1], line[2], line[3]) < 14 then
					clearOfViaducts = false
				end
			end
		end
		if clearOfViaducts then
			building(city, random, f, road.base, random:NextNumber(8, 24), -Vector3.zAxis)
		end
	end
end

-- Build the city into Workspace.Maps. Returns the number of parts made.
function CityBuilder.build(map): number
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
	local random = Random.new(2611)

	local points = RoadKit.loopPieces(road, supportBreaks(road))
	buildDeck(folder, road, points)
	buildPiers(folder, map)
	buildLamps(folder, map)
	local podiums = {}
	for _, section in road.sections do
		if section.kind == "tunnel" then
			local left, right = buildTunnel(folder, map, section)
			table.insert(podiums, { section, left, right })
		end
	end
	buildGantries(folder, map)
	local flyovers = {}
	local decor = RoadKit.folder(folder, "Viaducts")
	for _, flyover in map.data.decor.flyovers do
		local start, direction, length = buildFlyover(decor, map, flyover)
		table.insert(flyovers, { start, direction, length })
	end
	buildGround(folder, map)
	buildCity(folder, map, random, flyovers, podiums)
	folder.Parent = maps
	return RoadKit.countParts(folder)
end

return CityBuilder
