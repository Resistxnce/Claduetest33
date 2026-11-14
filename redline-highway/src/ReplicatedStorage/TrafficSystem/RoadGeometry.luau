--[[
	RoadGeometry: the shape of a closed road, built from a map's data (TrafficSystem/Maps). Shared by
	the server (map building, traffic, spawning) and clients (drawing traffic, close-pass scoring).
	tools/road_geometry.py is a line-for-line Python copy with tests (closure, continuity, round
	trips, curve speeds, grades, speed). Keep the two in step.

	Coordinates are world metres (Y up). s is the distance along the road in plan view (a highway's
	chainage), from 0 at the map's origin to road.length, where the loop closes. offset is sideways
	from the centre line, positive to the driver's right. height is above the road surface. Lanes
	are numbered from the left: lane 1 is the fast lane. Every lane runs the same way round.

	Map data fields:
	  lanes, laneWidth            lane count and width (m)
	  shoulderLeft, shoulderRight paved width beyond the outer lanes (m)
	  origin, heading             where s = 0 is ({ x, base height, z }) and the direction of travel
	                              there, in degrees (0 = +X, 90 = +Z)
	  plan                        { "straight", length } and { "curve", radius, degrees, transition }:
	                              a curve turns by degrees (positive = right) on a circle, with a
	                              transition curve of the given length at each end whose curvature
	                              grows evenly from zero (a clothoid)
	  elevation                   points { s, height, vertical curve length }, joined by straight
	                              grades with a parabolic vertical curve centred on each point; it
	                              must start at s = 0 with no curve and be level at both ends
	  sections                    { kind = "tunnel", from, to, ... }: stretches the map builders treat
	                              specially

	Transition curves are stored as short arcs of stepped curvature, so every piece of the road is a
	straight or a circular arc, and positions, directions and projections are exact (to rounding).
	project() finds the pieces near a position through a grid, so it costs a few pieces per call.
]]

local RoadGeometry = {}
RoadGeometry.__index = RoadGeometry

local TAU = 2 * math.pi
local SPIRAL_STEP = 8 -- m: transition curves are split into arcs no longer than this
local BUCKET = 8 -- m: lookup buckets for finding the piece at a distance s
local CELL = 64 -- m: grid cells for finding the pieces near a position
local REACH = 40 -- m beyond the road's edges that the grid covers
local NEAR = 2 -- m: heights within this of 1 m above the road cost nothing when choosing a piece

local function wrapAngle(a: number): number
	return (a + math.pi) % TAU - math.pi
end

local function cellKey(cx: number, cz: number): number
	return (cx + 50000) * 100000 + (cz + 50000)
end

-- Position (x, z) and heading at distance t into a piece.
local function pointOnPiece(piece, t: number): (number, number, number)
	if piece.k == 0 then
		return piece.x + t * piece.cos, piece.z + t * piece.sin, piece.heading
	end
	local heading = piece.heading + piece.k * t
	return piece.cx + math.sin(heading) / piece.k, piece.cz - math.cos(heading) / piece.k, heading
end

-- Where a plan position (x, z) falls along a piece: distance t into it (not clamped: below 0 or
-- beyond its length means before or after it) and sideways offset from it.
local function projectOnPiece(piece, x: number, z: number): (number, number)
	if piece.k == 0 then
		local dx, dz = x - piece.x, z - piece.z
		return dx * piece.cos + dz * piece.sin, dz * piece.cos - dx * piece.sin
	end
	local dx, dz = x - piece.cx, z - piece.cz
	local distance = math.sqrt(dx * dx + dz * dz)
	local angle = if piece.k > 0 then math.atan2(dx, -dz) else math.atan2(-dx, dz)
	local middle = piece.heading + piece.k * piece.length / 2
	return piece.length / 2 + wrapAngle(angle - middle) / piece.k, 1 / piece.k - math.sign(piece.k) * distance
end

function RoadGeometry.new(data)
	local self = setmetatable({}, RoadGeometry)
	self.id = data.id
	self.data = data
	self.lanes = data.lanes
	self.laneWidth = data.laneWidth
	self.halfWidth = data.lanes * data.laneWidth / 2
	self.leftEdge = self.halfWidth + data.shoulderLeft
	self.rightEdge = self.halfWidth + data.shoulderRight
	self.base = data.origin[2]

	-- plan view: pieces of constant curvature (straights and arcs)
	local pieces = {}
	local x, z = data.origin[1], data.origin[3]
	local heading = math.rad(data.heading)
	local s = 0

	local function add(length: number, k: number)
		local piece = {
			s = s,
			length = length,
			x = x,
			z = z,
			heading = heading,
			k = k,
			cos = math.cos(heading),
			sin = math.sin(heading),
			cx = 0,
			cz = 0,
		}
		if k ~= 0 then
			piece.cx = x - piece.sin / k
			piece.cz = z + piece.cos / k
			heading += k * length
			x = piece.cx + math.sin(heading) / k
			z = piece.cz - math.cos(heading) / k
		else
			x += length * piece.cos
			z += length * piece.sin
		end
		s += length
		table.insert(pieces, piece)
	end

	for _, element in data.plan do
		if element[1] == "straight" then
			add(element[2], 0)
		else
			local radius, degrees = element[2], element[3]
			local spiral = element[4] or 0
			assert(degrees ~= 0, "a curve must turn")
			local k = math.sign(degrees) / radius
			local arc = math.rad(math.abs(degrees)) * radius - spiral
			assert(arc >= -1e-6, "transition curves longer than their curve in map " .. tostring(data.id))
			local n = math.ceil(spiral / SPIRAL_STEP)
			for i = 1, n do
				add(spiral / n, k * (i - 0.5) / n)
			end
			if arc > 1e-6 then
				add(arc, k)
			end
			for i = n, 1, -1 do
				add(spiral / n, k * (i - 0.5) / n)
			end
		end
	end
	self.pieces = pieces
	self.length = s
	self.closure = math.sqrt((x - data.origin[1]) ^ 2 + (z - data.origin[3]) ^ 2)
	self.headingError = wrapAngle(heading - math.rad(data.heading))
	if self.closure > 0.01 or math.abs(self.headingError) > 1e-4 then
		warn(string.format("[RoadGeometry] Map %s doesn't close: its end is %.3f m and %.4f degrees from its start",
			tostring(data.id), self.closure, math.deg(self.headingError)))
	end

	-- lookup buckets: the piece where each BUCKET-metre stretch starts
	local bucketCount = math.floor(self.length / BUCKET) + 1
	local buckets = table.create(bucketCount, 1)
	local index = 1
	for b = 1, bucketCount do
		local at = (b - 1) * BUCKET
		while index < #pieces and pieces[index + 1].s <= at do
			index += 1
		end
		buckets[b] = index
	end
	self.buckets = buckets

	-- elevation: pieces where height = y + grade * t + rate * t^2 / 2, t = s - start
	local points = data.elevation
	assert(points[1][1] == 0 and (points[1][3] or 0) == 0, "the elevation must start at s = 0 with no vertical curve")
	local count = #points
	local function pvi(i: number): (number, number, number)
		if i > count then
			return self.length, points[1][2], 0
		end
		local p = points[i]
		return p[1], p[2], p[3] or 0
	end
	local grades = {}
	for i = 1, count do
		local s0, y0 = pvi(i)
		local s1, y1 = pvi(i + 1)
		assert(s1 > s0, "elevation points out of order in map " .. tostring(data.id))
		grades[i] = (y1 - y0) / (s1 - s0)
	end
	local profile = { { s = 0, y = points[1][2], grade = grades[1], rate = 0 } }
	for i = 2, count do
		local si, yi, curve = pvi(i)
		if curve > 0 then
			table.insert(profile, { s = si - curve / 2, y = yi - grades[i - 1] * curve / 2, grade = grades[i - 1],
				rate = (grades[i] - grades[i - 1]) / curve })
			table.insert(profile, { s = si + curve / 2, y = yi + grades[i] * curve / 2, grade = grades[i], rate = 0 })
		else
			table.insert(profile, { s = si, y = yi, grade = grades[i], rate = 0 })
		end
	end
	for i = 2, #profile do
		assert(profile[i].s >= profile[i - 1].s, "vertical curves overlap in map " .. tostring(data.id))
	end
	assert(profile[#profile].s <= self.length, "the last vertical curve runs past the end of map " .. tostring(data.id))
	self.levelEnds = math.abs(grades[count] - grades[1]) < 1e-9
	if not self.levelEnds then
		warn("[RoadGeometry] Map " .. tostring(data.id) .. " isn't level where the loop closes")
	end
	self.profile = profile
	local profileBuckets = table.create(bucketCount, 1)
	index = 1
	for b = 1, bucketCount do
		local at = (b - 1) * BUCKET
		while index < #profile and profile[index + 1].s <= at do
			index += 1
		end
		profileBuckets[b] = index
	end
	self.profileBuckets = profileBuckets

	local sections = table.clone(data.sections or {})
	table.sort(sections, function(a, b)
		return a.from < b.from
	end)
	self.sections = sections

	-- grid of the pieces near each CELL x CELL square, for project()
	local grid = {}
	local reach = math.max(self.leftEdge, self.rightEdge) + REACH
	for i, piece in pieces do
		local steps = math.max(1, math.ceil(piece.length / 32))
		for j = 0, steps - 1 do
			local ax, az = pointOnPiece(piece, piece.length * j / steps)
			local bx, bz = pointOnPiece(piece, piece.length * (j + 1) / steps)
			for cx = math.floor((math.min(ax, bx) - reach) / CELL), math.floor((math.max(ax, bx) + reach) / CELL) do
				for cz = math.floor((math.min(az, bz) - reach) / CELL), math.floor((math.max(az, bz) + reach) / CELL) do
					local key = cellKey(cx, cz)
					local cell = grid[key]
					if cell == nil then
						cell = {}
						grid[key] = cell
					end
					if #cell == 0 or cell[#cell] ~= i then
						table.insert(cell, i)
					end
				end
			end
		end
	end
	self.grid = grid
	local all = table.create(#pieces, 0)
	for i = 1, #pieces do
		all[i] = i
	end
	self.all = all
	return self
end

-- Index of the piece containing distance s (0 <= s < length).
function RoadGeometry:pieceIndex(s: number): number
	local pieces = self.pieces
	local i = self.buckets[math.floor(s / BUCKET) + 1]
	while i < #pieces and pieces[i + 1].s <= s do
		i += 1
	end
	return i
end

-- Centre line in plan view at distance s: x, z (m), heading (radians, 0 = +X) and curvature
-- (1/m, positive turning right).
function RoadGeometry:planAt(s: number): (number, number, number, number)
	s %= self.length
	local piece = self.pieces[self:pieceIndex(s)]
	local x, z, heading = pointOnPiece(piece, s - piece.s)
	return x, z, heading, piece.k
end

-- Height of the road surface (m) and its grade (rise per metre) at distance s.
function RoadGeometry:heightAt(s: number): (number, number)
	s %= self.length
	local profile = self.profile
	local i = self.profileBuckets[math.floor(s / BUCKET) + 1]
	while i < #profile and profile[i + 1].s <= s do
		i += 1
	end
	local p = profile[i]
	local t = s - p.s
	return self.base + p.y + (p.grade + p.rate * t / 2) * t, p.grade + p.rate * t
end

function RoadGeometry:curvatureAt(s: number): number
	local _, _, _, k = self:planAt(s)
	return k
end

-- The section of a kind (or of any kind) that contains distance s, or nil.
function RoadGeometry:sectionAt(s: number, kind: string?)
	s %= self.length
	for _, section in self.sections do
		if (kind == nil or section.kind == kind) and s >= section.from and s < section.to then
			return section
		end
	end
	return nil
end

--[[
	Position (m) at distance s, sideways offset and height above the road surface, and the unit
	direction of travel there, which climbs with the grade. With no roll, a CFrame looking along
	that direction has the road's sideways direction as its RightVector.
]]
function RoadGeometry:frame(s: number, offset: number, height: number): (Vector3, Vector3)
	local x, z, heading = self:planAt(s)
	local y, grade = self:heightAt(s)
	local c, n = math.cos(heading), math.sin(heading)
	local scale = 1 / math.sqrt(1 + grade * grade)
	return Vector3.new(x - n * offset, y + height, z + c * offset), Vector3.new(c * scale, grade * scale, n * scale)
end

-- Centre of the road surface at distance s, and the direction of travel.
function RoadGeometry:centerline(s: number): (Vector3, Vector3)
	return self:frame(s, 0, 0)
end

-- Unit vector to the driver's right (level) at distance s.
function RoadGeometry:rightAt(s: number): Vector3
	local _, _, heading = self:planAt(s)
	return Vector3.new(-math.sin(heading), 0, math.cos(heading))
end

-- Lane position (1 = centre of the fast lane) from a sideways offset, and back.
function RoadGeometry:laneFromOffset(offset: number): number
	return offset / self.laneWidth + (self.lanes + 1) / 2
end

function RoadGeometry:offsetFromLane(lanePos: number): number
	return (lanePos - (self.lanes + 1) / 2) * self.laneWidth
end

-- Position and direction at distance s and lane position lanePos, at height above the road.
function RoadGeometry:pointAt(s: number, lanePos: number, height: number): (Vector3, Vector3)
	return self:frame(s, self:offsetFromLane(lanePos), height)
end

--[[
	The reverse of frame: road coordinates (s, offset, height above the road) of a world position
	(m). Where the road passes over itself, the level nearest the position wins. Exact on and near
	the road; for positions more than about 40 m off it, it searches every piece.
	planOnly ignores height (for placing scenery).
]]
function RoadGeometry:project(position: Vector3, planOnly: boolean?): (number, number, number)
	local x, y, z = position.X, position.Y, position.Z
	local candidates = self.grid[cellKey(math.floor(x / CELL), math.floor(z / CELL))] or self.all
	local bestScore, bestS, bestOffset, bestHeight = math.huge, 0, 0, 0
	for _, i in candidates do
		local piece = self.pieces[i]
		local t, offset = projectOnPiece(piece, x, z)
		local along = if t < 0 then -t elseif t > piece.length then t - piece.length else 0
		t = math.clamp(t, 0, piece.length)
		local s = piece.s + t
		local edge = if offset < 0 then self.leftEdge else self.rightEdge
		local outside = math.max(0, math.abs(offset) - edge)
		local score = outside * outside + along * along
		local height = 0
		if not planOnly then
			local surface = self:heightAt(s)
			height = y - surface
			local off = math.max(0, math.abs(height - 1) - NEAR)
			score += off * off
		end
		if score < bestScore then
			bestScore, bestS, bestOffset, bestHeight = score, s, offset, height
		end
	end
	return bestS % self.length, bestOffset, bestHeight
end

--[[
	Plan distance (m) from a position to the road's paved surface (0 on it), for placing scenery.
	Only road within about 40 m counts: farther returns math.huge. Road within skipRange metres of
	distance skipS is ignored, to ask about other parts of the loop than the one a point is beside.
]]
function RoadGeometry:distanceToRoad(position: Vector3, skipS: number?, skipRange: number?): number
	local x, z = position.X, position.Z
	local candidates = self.grid[cellKey(math.floor(x / CELL), math.floor(z / CELL))]
	if candidates == nil then
		return math.huge
	end
	local best = math.huge
	for _, i in candidates do
		local piece = self.pieces[i]
		local t, offset = projectOnPiece(piece, x, z)
		local along = if t < 0 then -t elseif t > piece.length then t - piece.length else 0
		local s = piece.s + math.clamp(t, 0, piece.length)
		if skipS == nil or math.abs(self:delta(skipS, s)) > (skipRange or 0) then
			local edge = if offset < 0 then self.leftEdge else self.rightEdge
			local outside = math.max(0, math.abs(offset) - edge)
			best = math.min(best, math.sqrt(outside * outside + along * along))
		end
	end
	return best
end

-- Signed shortest distance along the loop from sFrom to sTo.
function RoadGeometry:delta(sFrom: number, sTo: number): number
	return (sTo - sFrom + self.length / 2) % self.length - self.length / 2
end

--[[
	Highest speed (m/s) for each step-metre stretch of road, starting at s = 0: what keeps the
	innermost lane's sideways acceleration within lateral (m/s^2), lowered ahead of each curve so
	that slowing at decel (m/s^2) reaches the curve's speed in time. Never above top.
]]
function RoadGeometry:speedLimits(lateral: number, decel: number, step: number, top: number): { number }
	local n = math.ceil(self.length / step)
	local inner = self.halfWidth - self.laneWidth / 2 -- the innermost lane centre, from the centre line
	local limits = table.create(n, top)
	for _, piece in self.pieces do
		local k = math.abs(piece.k)
		if k > 0 then
			local kLane = k / (1 - k * inner)
			local v = math.min(top, math.sqrt(lateral / kLane))
			local first = math.floor(piece.s / step) + 1
			local last = math.min(n, math.floor((piece.s + piece.length) / step) + 1)
			for i = first, last do
				limits[i] = math.min(limits[i], v)
			end
		end
	end
	for _ = 1, 2 do -- twice round, so braking zones carry across the start line
		for i = n, 1, -1 do
			local following = limits[i % n + 1]
			limits[i] = math.min(limits[i], math.sqrt(following * following + 2 * decel * step))
		end
	end
	return limits
end

return RoadGeometry
