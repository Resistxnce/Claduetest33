--[[
	ClosePassController: feeds the player's car and the traffic around it (in the road coordinates of
	the map the player is on) to the close-pass scorer every frame, and shows the result on the
	ScoreHUD. Scoring runs on this computer for now; the server checks scores once there is anything
	to win (Phase 7). The banked score carries over between maps; a new car or a new map ends the
	current combo without banking it.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ClosePass = require(ReplicatedStorage:WaitForChild("Gameplay"):WaitForChild("ClosePass"))
local TrafficSystem = ReplicatedStorage:WaitForChild("TrafficSystem")
local DriverProfiles = require(TrafficSystem:WaitForChild("DriverProfiles"))
local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local Client = script.Parent
local TrafficRenderer = require(Client:WaitForChild("TrafficRenderer"))
local ScoreHUD = require(Client:WaitForChild("ScoreHUD"))

local M = Units.METERS_PER_STUD

local ClosePassController = {}

local scorer = nil
local connection: RBXScriptConnection? = nil
local player = { s = 0, offset = 0, v = 0, length = 4.7, width = 1.9 }
local cars = {} -- id -> { s, offset, v, length, width }, reused between frames

-- controller: the VehicleController of the player's car. map: the map it's on (MapRegistry).
function ClosePassController.start(controller, map)
	ClosePassController.stop()
	local road = map.road
	local dims = controller.config.dimensions
	player.length = dims.length
	player.width = dims.width
	if scorer then
		-- a new car (respawn, car change or map change) ends the current combo without banking it,
		-- and forgets cars that were alongside the old one
		table.clear(scorer.tracks)
		scorer.combo = 0
		scorer.multiplier = 1
		scorer.timer = 0
		scorer.lap = road.length
	else
		scorer = ClosePass.new(ClosePass.DEFAULTS, road.length)
	end
	table.clear(cars)
	ScoreHUD.set(scorer)
	connection = RunService.PostSimulation:Connect(function(dt)
		if controller.stopped then
			ClosePassController.stop()
			return
		end
		local root: BasePart = controller.root
		local s, offset = road:project(root.Position * M)
		local _, direction = road:centerline(s)
		player.s = s
		player.offset = offset
		player.v = (root.AssemblyLinearVelocity * M):Dot(direction)

		-- only traffic drawn for this map counts
		local live = if TrafficRenderer.mapId() == map.id then TrafficRenderer.cars() else {}
		for id in cars do
			if live[id] == nil then
				cars[id] = nil
			end
		end
		for id, car in live do
			local entry = cars[id]
			if entry == nil then
				local profile = DriverProfiles.profiles[DriverProfiles.order[car.profileIndex] or "normal"]
				entry = { s = 0, offset = 0, v = 0, length = profile.length, width = profile.width }
				cars[id] = entry
			end
			entry.s = car.s
			entry.offset = road:offsetFromLane(car.lanePos)
			entry.v = car.v
		end
		scorer:update(dt, player, cars)
		ScoreHUD.update(dt, scorer)
	end)
end

function ClosePassController.stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

return ClosePassController
