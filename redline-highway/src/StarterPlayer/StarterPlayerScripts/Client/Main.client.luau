--[[
	Client entry point: wires input to the active car, camera and HUD.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = script.Parent
local InputController = require(Client:WaitForChild("InputController"))
local VehicleController = require(Client:WaitForChild("VehicleController"))
local CameraController = require(Client:WaitForChild("CameraController"))
local HUD = require(Client:WaitForChild("HUD"))
local VehicleAudio = require(Client:WaitForChild("VehicleAudio"))
local SelfTest = require(Client:WaitForChild("SelfTest"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

InputController.init()
HUD.init()

local active = nil
local audio = nil

remotes:WaitForChild("VehicleSpawned").OnClientEvent:Connect(function(model: Model)
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
