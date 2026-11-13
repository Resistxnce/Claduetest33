--[[
	MapService: the server's side of the maps. Builds every map at startup (TrackBuilder for the
	oval, CityBuilder for the city), remembers which map each player is on (also published as the
	Player attribute "MapId" for clients), and gives spawn and respawn positions on a map's road.
	VehicleSpawner handles the switch request itself (it respawns the car).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapRegistry = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("MapRegistry"))
local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))
local TrackBuilder = require(script.Parent.TrackBuilder)
local CityBuilder = require(script.Parent.CityBuilder)

local M = Units.METERS_PER_STUD
local GRID_BACK = 10 -- m from the start line back to the first grid row
local GRID_ROW = 12 -- m between rows: room for any car up to about 8 m long
local SPAWN_LIFT = 0.12 -- m above ride height, so a new car settles onto its suspension (road boxes
-- follow the road to within 8 cm, so on a crest the surface can be a little above its exact height)

local MapService = {}

local BUILDERS = {
	Oval = TrackBuilder,
	City = CityBuilder,
}

local playerMaps: { [Player]: string } = {}

-- Build every map. Prints what each took.
function MapService.build()
	for _, id in MapRegistry.order do
		local started = os.clock()
		local map = MapRegistry.get(id)
		local parts = BUILDERS[id].build(map)
		print(string.format("[Redline] Map %s (%s) built in %.2f s: %.1f km, %d lanes, %d parts", id, map.displayName,
			os.clock() - started, map.road.length / 1000, map.road.lanes, parts))
	end
end

function MapService.mapOf(player: Player): string
	return playerMaps[player] or MapRegistry.default
end

function MapService.setMap(player: Player, id: string)
	playerMaps[player] = id
	player:SetAttribute("MapId", id)
end

function MapService.forget(player: Player)
	playerMaps[player] = nil
end

-- A CFrame (studs) at distance s and sideways offset on a map's road, raised by height (m), facing
-- along the road and pitched with its grade.
local function roadCFrame(map, s: number, offset: number, height: number): CFrame
	local p, direction = map.road:frame(s, offset, height)
	return CFrame.lookAt(p / M, (p + direction) / M)
end

-- Where to place a car's centre of mass for grid slot n (1-based) on a map. comHeight: the car's
-- centre of mass above the ground at ride height (m), from its configuration.
function MapService.gridCFrame(mapId: string, slot: number, comHeight: number): CFrame
	local map = MapRegistry.get(mapId)
	local road = map.road
	local lane = (slot - 1) % road.lanes + 1
	local row = math.floor((slot - 1) / road.lanes)
	local s = map.data.start - GRID_BACK - row * GRID_ROW
	return roadCFrame(map, s, road:offsetFromLane(lane), comHeight + SPAWN_LIFT)
end

-- The nearest lane centre on a map's road to a position (studs), as a CFrame facing along the road.
function MapService.nearestCFrame(mapId: string, positionStuds: Vector3, comHeight: number): CFrame
	local map = MapRegistry.get(mapId)
	local road = map.road
	local s, offset = road:project(positionStuds * M)
	local lane = math.clamp(math.floor(road:laneFromOffset(offset) + 0.5), 1, road.lanes)
	return roadCFrame(map, s, road:offsetFromLane(lane), comHeight + SPAWN_LIFT)
end

return MapService
