--[[
	RoadGeometry: the proving-ground loop's shape, shared by the server (track building, traffic)
	and clients (drawing traffic). Distances are in metres; s is the distance around the loop from
	the start of the main straight, and offsets are sideways from the centre line, positive to the
	driver's right. Lanes are numbered from the left: lane 1 is the fast lane.

	The loop is two straights joined by two semicircles, and every lane runs the same way round.
]]

local RoadGeometry = {}

local STRAIGHT = 2200
local RADIUS = 650
local LANES = 4
local LANE_WIDTH = 3.75
local ARC = math.pi * RADIUS
local LAP = 2 * STRAIGHT + 2 * ARC

RoadGeometry.STRAIGHT = STRAIGHT
RoadGeometry.RADIUS = RADIUS
RoadGeometry.LANES = LANES
RoadGeometry.LANE_WIDTH = LANE_WIDTH
RoadGeometry.ARC = ARC
RoadGeometry.LAP = LAP

-- Centre of the road at distance s: position (m) and direction of travel.
function RoadGeometry.centerline(s: number): (Vector3, Vector3)
	s = s % LAP
	if s < STRAIGHT then
		return Vector3.new(-STRAIGHT / 2 + s, 0, -RADIUS), Vector3.xAxis
	end
	s -= STRAIGHT
	if s < ARC then
		local phi = -math.pi / 2 + s / RADIUS
		return Vector3.new(STRAIGHT / 2 + RADIUS * math.cos(phi), 0, RADIUS * math.sin(phi)),
			Vector3.new(-math.sin(phi), 0, math.cos(phi))
	end
	s -= ARC
	if s < STRAIGHT then
		return Vector3.new(STRAIGHT / 2 - s, 0, RADIUS), -Vector3.xAxis
	end
	s -= STRAIGHT
	local phi = math.pi / 2 + s / RADIUS
	return Vector3.new(-STRAIGHT / 2 + RADIUS * math.cos(phi), 0, RADIUS * math.sin(phi)),
		Vector3.new(-math.sin(phi), 0, math.cos(phi))
end

function RoadGeometry.rightOf(direction: Vector3): Vector3
	return direction:Cross(Vector3.yAxis)
end

-- The reverse of centerline: distance along the loop and sideways offset of a position (m).
-- Exact for this loop's straights and semicircles.
function RoadGeometry.project(position: Vector3): (number, number)
	local x, z = position.X, position.Z
	local half = STRAIGHT / 2
	if x >= -half and x <= half then
		if z < 0 then
			return x + half, z + RADIUS
		end
		return STRAIGHT + ARC + (half - x), RADIUS - z
	end
	if x > half then
		local dx = x - half
		local phi = math.atan2(z, dx)
		return STRAIGHT + (phi + math.pi / 2) * RADIUS, RADIUS - math.sqrt(dx * dx + z * z)
	end
	local dx = x + half
	local phi = math.atan2(z, dx)
	if phi < 0 then
		phi += 2 * math.pi
	end
	return 2 * STRAIGHT + ARC + (phi - math.pi / 2) * RADIUS, RADIUS - math.sqrt(dx * dx + z * z)
end

-- Lane position (1 = centre of the fast lane) from a sideways offset, and back.
function RoadGeometry.laneFromOffset(offset: number): number
	return offset / LANE_WIDTH + (LANES + 1) / 2
end

function RoadGeometry.offsetFromLane(lanePos: number): number
	return (lanePos - (LANES + 1) / 2) * LANE_WIDTH
end

-- Position (m) and direction at distance s and lane position lanePos, at height above the road.
function RoadGeometry.pointAt(s: number, lanePos: number, height: number): (Vector3, Vector3)
	local p, direction = RoadGeometry.centerline(s)
	return p + RoadGeometry.rightOf(direction) * RoadGeometry.offsetFromLane(lanePos) + Vector3.new(0, height, 0), direction
end

return RoadGeometry
