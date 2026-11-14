--[[
	Client entry point: wires input to the active car, camera and HUD, follows the player from map
	to map (lighting, traffic, close-pass scoring), and sends map and car changes to the server.

	Keys: N (gamepad D-pad right) changes map, G (D-pad left) changes car; the buttons at the top
	right do the same. The server checks and rate-limits both; the client waits the same time between
	requests and says so if a key is pressed too soon.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VehicleConfigurations = ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("VehicleConfigurations")
local MapRegistry = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("MapRegistry"))
local MapLighting = require(ReplicatedStorage:WaitForChild("Gameplay"):WaitForChild("MapLighting"))

local Client = script.Parent
local InputController = require(Client:WaitForChild("InputController"))
local VehicleController = require(Client:WaitForChild("VehicleController"))
local CameraController = require(Client:WaitForChild("CameraController"))
local HUD = require(Client:WaitForChild("HUD"))
local VehicleAudio = require(Client:WaitForChild("VehicleAudio"))
local SelfTest = require(Client:WaitForChild("SelfTest"))
local TrafficRenderer = require(Client:WaitForChild("TrafficRenderer"))
local TrafficAudio = require(Client:WaitForChild("TrafficAudio"))
local ScoreHUD = require(Client:WaitForChild("ScoreHUD"))
local ClosePassController = require(Client:WaitForChild("ClosePassController"))

local MAP_COOLDOWN = 4.2 -- s, a little over the server's
local CAR_COOLDOWN = 3.2

local localPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

InputController.init()
HUD.init()
TrafficRenderer.init(remotes)
TrafficAudio.init(TrafficRenderer)
ScoreHUD.init()

local active = nil
local audio = nil
local currentMap: string? = nil
local lastCar: string? = nil
local lastMapRequest, lastCarRequest = -math.huge, -math.huge

-- Follow the player onto a map: its lighting (this computer only), and its name on screen.
local function enterMap(id: any)
	if not MapRegistry.isMap(id) or id == currentMap then
		return
	end
	currentMap = id
	local map = MapRegistry.get(id)
	MapLighting.apply(map.data.lighting)
	ScoreHUD.setMapName(map.displayName)
	ScoreHUD.notice(string.upper(map.displayName), 3)
end

-- If the place streams instances in, the car can arrive after the event that announces it, and the
-- event then carries nil. Find our own car by its owner attribute instead.
local function findOwnCar(timeout: number): Model?
	local folder = Workspace:WaitForChild("Vehicles", timeout)
	local deadline = os.clock() + timeout
	while folder and os.clock() < deadline do
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("OwnerUserId") == localPlayer.UserId then
				return child
			end
		end
		task.wait(0.2)
	end
	return nil
end

remotes:WaitForChild("VehicleSpawned").OnClientEvent:Connect(function(model: Model?, mapId: string?)
	if not model then
		model = findOwnCar(10)
		if not model then
			warn("[Redline] The car didn't arrive on this computer; press R to try again")
			return
		end
	end
	enterMap(mapId or (model :: Model):GetAttribute("MapId"))
	if audio then
		audio:stop()
		audio = nil
	end
	if active then
		active:stop()
		active = nil
	end
	active = VehicleController.start(model)
	if active then
		local map = MapRegistry.get(currentMap or MapRegistry.default)
		CameraController.start(model)
		HUD.setVehicle(active.config)
		audio = VehicleAudio.start(active, CameraController.mode)
		SelfTest.run(active, map)
		ClosePassController.start(active, map)
		local carId = active.config.id
		if lastCar ~= nil and carId ~= lastCar then
			ScoreHUD.notice(string.upper(active.config.displayName or carId), 2.5)
		end
		lastCar = carId
	end
end)

enterMap(localPlayer:GetAttribute("MapId") or MapRegistry.default)
localPlayer:GetAttributeChangedSignal("MapId"):Connect(function()
	enterMap(localPlayer:GetAttribute("MapId"))
end)

-- The cars to choose from: every configuration module, in sorted order.
local function carIds(): { string }
	local ids = {}
	for _, child in VehicleConfigurations:GetChildren() do
		if child:IsA("ModuleScript") then
			table.insert(ids, child.Name)
		end
	end
	table.sort(ids)
	return ids
end

local function nextMap()
	if os.clock() - lastMapRequest < MAP_COOLDOWN then
		ScoreHUD.notice("One moment...", 1.2)
		return
	end
	lastMapRequest = os.clock()
	local target = MapRegistry.next(currentMap or MapRegistry.default)
	ScoreHUD.notice("TO " .. string.upper(MapRegistry.get(target).displayName), 2)
	remotes.RequestMapSwitch:FireServer(target)
end

local function nextCar()
	local ids = carIds()
	local current = if active then active.config.id else lastCar
	local index = table.find(ids, current or "") or 0
	local target = ids[index % math.max(#ids, 1) + 1]
	if target == nil or target == current then
		ScoreHUD.notice("No other cars yet", 1.5)
		return
	end
	if os.clock() - lastCarRequest < CAR_COOLDOWN then
		ScoreHUD.notice("One moment...", 1.2)
		return
	end
	lastCarRequest = os.clock()
	remotes.RequestVehicle:FireServer(target)
end

ScoreHUD.menu(nextMap, nextCar)
if currentMap then
	ScoreHUD.setMapName(MapRegistry.get(currentMap).displayName)
end

InputController.on("nextMap", nextMap)
InputController.on("nextCar", nextCar)
InputController.on("reset", function()
	remotes.RequestRespawn:FireServer()
end)
InputController.on("camera", CameraController.cycle)
InputController.on("telemetry", HUD.toggleTelemetry)
InputController.on("help", HUD.toggleHelp)
InputController.on("shiftUp", function()
	if active then
		active.sim:shiftUp()
	end
end)
InputController.on("shiftDown", function()
	if active then
		active.sim:shiftDown()
	end
end)
InputController.on("toggleAuto", function()
	if active then
		active.sim:toggleAutomatic()
	end
end)
InputController.on("toggleAbs", function()
	if active then
		active.sim:toggleAbs()
	end
end)
InputController.on("toggleTc", function()
	if active then
		active.sim:toggleTractionControl()
	end
end)
