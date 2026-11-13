--[[
	VehicleSpawner
	Gives each player a car when their character spawns, on the start grid of the map they're on,
	seats them in it and hands them network ownership so their own client simulates it. Handles
	three requests from clients, each rate-limited and checked, since the server trusts nothing a
	client sends:
	  RequestRespawn               put the car back on the nearest lane of the current map (R)
	  RequestMapSwitch(mapId)      move to another map's start grid (N); mapId must name a map
	  RequestVehicle(configId)     change car (G); configId must name a ModuleScript in
	                               VehicleSystem.VehicleConfigurations that loads as a car
	A player's map and car choice are remembered until they leave. Spawn positions come from the
	car's own configuration (centre-of-mass height), so cars of any size spawn correctly.

	Each car gets attributes: OwnerUserId and VehicleConfig (VehicleModelBuilder), MapId, and
	LengthM and WidthM (its body size in metres, for traffic). The client is told about a new car
	with VehicleSpawned(model, mapId).

	Phase 7 adds server-side checks on speed and position; for now the server trusts nothing
	that matters (there is no money or racing yet).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local MapRegistry = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("MapRegistry"))
local VehicleModelBuilder = require(script.Parent.VehicleModelBuilder)
local MapService = require(script.Parent.MapService)

local DEFAULT_VEHICLE = "Prototype812"
local RESPAWN_COOLDOWN = 2 -- seconds between respawns
local SWITCH_COOLDOWN = 4 -- seconds between map switches
local VEHICLE_COOLDOWN = 3 -- seconds between car changes
local FAR = 200 -- studs: a driver further than this from the new seat is moved next to it first

local VehicleSpawner = {}

local remotes: Folder
local vehiclesFolder: Folder
local vehicles: { [Player]: Model } = {}
local slots: { [Player]: number } = {}
local choices: { [Player]: string } = {}
local lastAction: { [Player]: { [string]: number } } = {}
local masslessConnections: { [Player]: RBXScriptConnection } = {}

-- True if the player may do this action now (and starts its cooldown).
local function allowed(player: Player, action: string, cooldown: number): boolean
	local now = os.clock()
	local times = lastAction[player]
	if times == nil then
		times = {}
		lastAction[player] = times
	end
	if times[action] ~= nil and now - times[action] < cooldown then
		return false
	end
	times[action] = now
	return true
end

-- The configuration module for an id, if the id names one.
local function configModule(id: any): ModuleScript?
	if type(id) ~= "string" or #id == 0 or #id > 64 then
		return nil
	end
	local module = VehicleSystem.VehicleConfigurations:FindFirstChild(id)
	if module and module:IsA("ModuleScript") then
		return module
	end
	return nil
end

-- A car configuration, or nil if it doesn't load or lacks what spawning needs.
local function loadConfig(id: any)
	local module = configModule(id)
	if module == nil then
		return nil
	end
	local ok, config = pcall(require, module)
	if not ok or type(config) ~= "table" or type(config.mass) ~= "table" or type(config.dimensions) ~= "table"
		or type(config.mass.comHeight) ~= "number" then
		warn("[VehicleSpawner] Vehicle configuration " .. module.Name .. " didn't load: " .. tostring(if ok then "missing fields" else config))
		return nil
	end
	return config
end

-- The configuration of the player's chosen car (the default car if the choice won't load).
local function configFor(player: Player)
	return loadConfig(choices[player] or DEFAULT_VEHICLE) or loadConfig(DEFAULT_VEHICLE)
end

local function freeSlot(): number
	local used = {}
	for _, slot in slots do
		used[slot] = true
	end
	local slot = 1
	while used[slot] do
		slot += 1
	end
	return slot
end

function VehicleSpawner.remove(player: Player)
	local model = vehicles[player]
	if model then
		model:Destroy()
		vehicles[player] = nil
	end
end

function VehicleSpawner.spawn(player: Player, cframe: CFrame, config)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	VehicleSpawner.remove(player)

	local mapId = MapService.mapOf(player)
	local model = VehicleModelBuilder.build(config, player)
	model:SetAttribute("MapId", mapId)
	model:SetAttribute("LengthM", config.dimensions.length)
	model:SetAttribute("WidthM", config.dimensions.width)
	model:PivotTo(cframe)
	model.Parent = vehiclesFolder
	vehicles[player] = model

	local seat = model:FindFirstChild("DriverSeat") :: Seat
	-- after a map switch the driver is kilometres away: bring them next to the seat first
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if rootPart and (rootPart.Position - seat.Position).Magnitude > FAR then
		character:PivotTo(seat.CFrame + Vector3.new(0, 4, 0))
	end
	seat:Sit(humanoid)
	-- On a respawn the humanoid may still count as seated in the old, destroyed seat, and Sit can be
	-- refused. Check shortly after and try again.
	task.spawn(function()
		for _ = 1, 3 do
			task.wait(0.25)
			if vehicles[player] ~= model or seat.Occupant == humanoid or humanoid.Health <= 0 then
				return
			end
			humanoid.Sit = false
			task.wait()
			seat:Sit(humanoid)
		end
	end)
	-- the driver's mass is already in the configuration, so the avatar itself adds none,
	-- including accessories and body parts that finish loading later
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
		end
	end
	if masslessConnections[player] then
		masslessConnections[player]:Disconnect()
	end
	masslessConnections[player] = character.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			part.Massless = true
		end
	end)

	local ok, err = pcall(function()
		model.PrimaryPart:SetNetworkOwner(player)
	end)
	if not ok then
		warn("[VehicleSpawner] Could not give network ownership to " .. player.Name .. ": " .. tostring(err))
	end
	remotes.VehicleSpawned:FireClient(player, model, mapId)
end

-- A new car for the player on the start grid of their current map.
local function spawnOnGrid(player: Player)
	local config = configFor(player)
	VehicleSpawner.spawn(player, MapService.gridCFrame(MapService.mapOf(player), slots[player] or 1, config.mass.comHeight), config)
end

-- A new car on the nearest lane of the current map (or the grid if there's no car yet).
local function spawnNearby(player: Player)
	local config = configFor(player)
	local current = vehicles[player]
	if current and current.PrimaryPart then
		VehicleSpawner.spawn(player, MapService.nearestCFrame(MapService.mapOf(player), current.PrimaryPart.Position, config.mass.comHeight), config)
	else
		spawnOnGrid(player)
	end
end

function VehicleSpawner.respawn(player: Player)
	if allowed(player, "respawn", RESPAWN_COOLDOWN) then
		spawnNearby(player)
	end
end

-- Move a player to another map's start grid. mapId comes from the client: it must name a map.
function VehicleSpawner.switchMap(player: Player, mapId: any)
	if not MapRegistry.isMap(mapId) or mapId == MapService.mapOf(player) then
		return
	end
	if not allowed(player, "map", SWITCH_COOLDOWN) then
		return
	end
	MapService.setMap(player, mapId)
	spawnOnGrid(player)
end

-- Change a player's car. configId comes from the client: it must name a car that loads.
function VehicleSpawner.chooseVehicle(player: Player, configId: any)
	if configModule(configId) == nil or configId == (choices[player] or DEFAULT_VEHICLE) then
		return
	end
	if not allowed(player, "vehicle", VEHICLE_COOLDOWN) then
		return
	end
	if loadConfig(configId) == nil then
		return
	end
	choices[player] = configId
	spawnNearby(player)
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	character:WaitForChild("HumanoidRootPart")
	-- a reset or death takes the car away with the driver; a new one comes with the next character
	humanoid.Died:Once(function()
		if player.Character == character then
			VehicleSpawner.remove(player)
		end
	end)
	task.wait(0.5)
	if player.Parent and player.Character == character then
		spawnOnGrid(player)
	end
end

local function onPlayerAdded(player: Player)
	slots[player] = freeSlot()
	MapService.setMap(player, MapService.mapOf(player))
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function VehicleSpawner.init(remoteFolder: Folder)
	remotes = remoteFolder
	vehiclesFolder = Instance.new("Folder")
	vehiclesFolder.Name = "Vehicles"
	vehiclesFolder.Parent = Workspace

	remotes.RequestRespawn.OnServerEvent:Connect(function(player)
		VehicleSpawner.respawn(player)
	end)
	remotes.RequestMapSwitch.OnServerEvent:Connect(function(player, mapId)
		VehicleSpawner.switchMap(player, mapId)
	end)
	remotes.RequestVehicle.OnServerEvent:Connect(function(player, configId)
		VehicleSpawner.chooseVehicle(player, configId)
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		VehicleSpawner.remove(player)
		slots[player] = nil
		choices[player] = nil
		lastAction[player] = nil
		MapService.forget(player)
		if masslessConnections[player] then
			masslessConnections[player]:Disconnect()
			masslessConnections[player] = nil
		end
	end)
end

return VehicleSpawner
