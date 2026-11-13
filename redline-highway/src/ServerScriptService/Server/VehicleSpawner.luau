--[[
	VehicleSpawner
	Gives each player a car on the start grid when their character spawns, seats them in it and
	hands them network ownership so their own client simulates it. Handles reset requests
	(rate-limited) by respawning the car on the nearest lane.

	Phase 7 adds server-side checks on speed and position; for now the server trusts nothing
	that matters (there is no money or racing yet).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local VehicleModelBuilder = require(script.Parent.VehicleModelBuilder)
local TrackBuilder = require(script.Parent.TrackBuilder)

local DEFAULT_VEHICLE = "Prototype812"
local RESPAWN_COOLDOWN = 2 -- seconds

local VehicleSpawner = {}

local remotes: Folder
local vehiclesFolder: Folder
local vehicles: { [Player]: Model } = {}
local slots: { [Player]: number } = {}
local lastRespawn: { [Player]: number } = {}

local function loadConfig()
	return require(VehicleSystem.VehicleConfigurations[DEFAULT_VEHICLE])
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

function VehicleSpawner.spawn(player: Player, cframe: CFrame)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	VehicleSpawner.remove(player)

	local config = loadConfig()
	local model = VehicleModelBuilder.build(config, player)
	model:PivotTo(cframe)
	model.Parent = vehiclesFolder
	vehicles[player] = model

	local seat = model:FindFirstChild("DriverSeat") :: Seat
	seat:Sit(humanoid)
	-- the driver's mass is already in the configuration, so the avatar itself adds none
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
		end
	end

	local ok, err = pcall(function()
		model.PrimaryPart:SetNetworkOwner(player)
	end)
	if not ok then
		warn("[VehicleSpawner] Could not give network ownership to " .. player.Name .. ": " .. tostring(err))
	end
	remotes.VehicleSpawned:FireClient(player, model)
end

function VehicleSpawner.respawn(player: Player)
	local now = os.clock()
	if lastRespawn[player] and now - lastRespawn[player] < RESPAWN_COOLDOWN then
		return
	end
	lastRespawn[player] = now
	local comHeight = loadConfig().mass.comHeight
	local current = vehicles[player]
	local cframe
	if current and current.PrimaryPart then
		cframe = TrackBuilder.nearestCFrame(current.PrimaryPart.Position, comHeight)
	else
		cframe = TrackBuilder.gridCFrame(slots[player] or 1, comHeight)
	end
	VehicleSpawner.spawn(player, cframe)
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	task.wait(0.5)
	if player.Parent and player.Character == character then
		VehicleSpawner.spawn(player, TrackBuilder.gridCFrame(slots[player], loadConfig().mass.comHeight))
	end
end

local function onPlayerAdded(player: Player)
	slots[player] = freeSlot()
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
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		VehicleSpawner.remove(player)
		slots[player] = nil
		lastRespawn[player] = nil
	end)
end

return VehicleSpawner
