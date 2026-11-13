--[[
	MapRegistry: the game's maps, in the order the map key (N) cycles through them. Each map is a
	data module in TrafficSystem/Maps; its road (RoadGeometry) is built the first time it's asked for,
	on the server and on each client.

	A map: { id, displayName, data, road }. Both maps live in the same place, far apart: the oval at
	the world's origin and the city about 9 km away (see each map's origin).
]]

local RoadGeometry = require(script.Parent:WaitForChild("RoadGeometry"))
local Maps = script.Parent:WaitForChild("Maps")

local MapRegistry = {}

MapRegistry.order = { "Oval", "City" }
MapRegistry.default = "Oval"

local DATA = {
	Oval = require(Maps:WaitForChild("Oval")),
	City = require(Maps:WaitForChild("City")),
}

local built = {}

-- True if id names a map (for checking values that come from clients).
function MapRegistry.isMap(id: any): boolean
	return type(id) == "string" and DATA[id] ~= nil
end

function MapRegistry.get(id: string)
	local map = built[id]
	if map == nil then
		local data = DATA[id]
		assert(data ~= nil, "unknown map " .. tostring(id))
		map = { id = id, displayName = data.displayName, data = data, road = RoadGeometry.new(data) }
		built[id] = map
	end
	return map
end

-- The map after id in the cycle.
function MapRegistry.next(id: string): string
	for i, name in MapRegistry.order do
		if name == id then
			return MapRegistry.order[i % #MapRegistry.order + 1]
		end
	end
	return MapRegistry.default
end

return MapRegistry
