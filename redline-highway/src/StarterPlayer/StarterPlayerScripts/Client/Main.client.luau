--[[
	Client entry point: wires input to the active car, camera and HUD.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Client = script.Parent
local InputController = require(Client:WaitForChild("InputController"))
local VehicleController = require(Client:WaitForChild("VehicleController"))
local CameraController = require(Client:WaitForChild("CameraController"))
local HUD = require(Client:WaitForChild("HUD"))
local VehicleAudio = require(Client:WaitForChild("VehicleAudio"))
local SelfTest = require(Client:WaitForChild("SelfTest"))
local TrafficRenderer = require(Client:WaitForChild("TrafficRenderer"))
local ScoreHUD = require(Client:WaitForChild("ScoreHUD"))
local ClosePassController = require(Client:WaitForChild("ClosePassController"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

InputController.init()
HUD.init()
TrafficRenderer.init(remotes)
ScoreHUD.init()

local active = nil
local audio = nil

-- If the place streams instances in, the car can arrive after the event that announces it, and the
-- event then carries nil. Find our own car by its owner attribute instead.
local function findOwnCar(timeout: number): Model?
	local folder = Workspace:WaitForChild("Vehicles", timeout)
	local deadline = os.clock() + timeout
	while folder and os.clock() < deadline do
		for _, child in folder:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
				return child
			end
		end
		task.wait(0.2)
	end
	return nil
end

remotes:WaitForChild("VehicleSpawned").OnClientEvent:Connect(function(model: Model?)
	if not model then
		model = findOwnCar(10)
		if not model then
			warn("[Redline] The car didn't arrive on this computer; press R to try again")
			return
		end
	end
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
		CameraController.start(model)
		HUD.setVehicle(active.config)
		audio = VehicleAudio.start(active, CameraController.mode)
		SelfTest.run(active)
		ClosePassController.start(active)
	end
end)

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
