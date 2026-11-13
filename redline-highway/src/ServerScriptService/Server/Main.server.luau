--[[
	Server entry point: sets realistic gravity and the default (afternoon) lighting, creates the
	remotes, builds both maps (the oval proving ground and the city expressway, far apart in the same
	place), starts spawning cars and runs each map's traffic.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))
local MapRegistry = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("MapRegistry"))
local MapLighting = require(ReplicatedStorage:WaitForChild("Gameplay"):WaitForChild("MapLighting"))
local MapService = require(script.Parent.MapService)
local VehicleSpawner = require(script.Parent.VehicleSpawner)
local TrafficService = require(script.Parent.TrafficService)

-- 9.81 m/s^2 at 0.28 m per stud. Character jumps feel lower than default Roblox; cars feel right.
Workspace.Gravity = Units.REALISTIC_GRAVITY

-- Late-afternoon light, the oval's look. Each client switches to its own map's look (the city is at
-- night). For the best look, also set Lighting.Technology to Future in Studio (scripts can't).
MapLighting.apply("Afternoon")

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "VehicleSpawned", "RequestRespawn", "RequestMapSwitch", "RequestVehicle" } do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local started = os.clock()
MapService.build()
print(string.format("[Redline] Maps built in %.2f s", os.clock() - started))

VehicleSpawner.init(remotes)
TrafficService.init(remotes, MapService.mapOf)
for _, id in MapRegistry.order do
	TrafficService.start(MapRegistry.get(id))
end
