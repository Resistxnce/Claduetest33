--[[
	Server entry point: sets realistic gravity and lighting, creates the remotes, builds the
	proving ground and starts spawning cars.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))
local TrackBuilder = require(script.Parent.TrackBuilder)
local VehicleSpawner = require(script.Parent.VehicleSpawner)
local TrafficService = require(script.Parent.TrafficService)

-- 9.81 m/s^2 at 0.28 m per stud. Character jumps feel lower than default Roblox; cars feel right.
Workspace.Gravity = Units.REALISTIC_GRAVITY

-- Late-afternoon light. For the best look, also set Lighting.Technology to Future in Studio
-- (that property can't be changed by scripts).
Lighting.ClockTime = 16.4
Lighting.Brightness = 3
Lighting.GeographicLatitude = 38
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.15

local function ensure(className: string, properties: { [string]: any })
	local object = Lighting:FindFirstChildOfClass(className) or Instance.new(className)
	for key, value in properties do
		(object :: any)[key] = value
	end
	object.Parent = Lighting
end

ensure("Atmosphere", { Density = 0.28, Offset = 0.2, Color = Color3.fromRGB(205, 186, 160), Decay = Color3.fromRGB(110, 115, 128), Glare = 0.35, Haze = 1.4 })
ensure("BloomEffect", { Intensity = 0.3, Size = 28, Threshold = 1.5 })
ensure("ColorCorrectionEffect", { Contrast = 0.06, Saturation = 0.06 })
ensure("SunRaysEffect", { Intensity = 0.04, Spread = 0.55 })

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "VehicleSpawned", "RequestRespawn" } do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local started = os.clock()
TrackBuilder.build()
print(string.format("[Redline] Proving ground built in %.2f s (lap %.0f m)", os.clock() - started, TrackBuilder.LAP_LENGTH))

VehicleSpawner.init(remotes)
TrafficService.init(remotes)
