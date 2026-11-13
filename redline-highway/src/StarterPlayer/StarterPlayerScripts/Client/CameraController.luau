--[[
	CameraController
	Chase, hood and cockpit cameras for the player's car.

	The chase camera follows the car's position exactly and only smooths its direction, so it
	never falls behind at 300 km/h. Field of view widens a little with speed. A very small
	high-speed vibration can be switched off with CameraController.settings.shake. In tunnels and
	beside walls, the chase camera moves in rather than through the wall or ceiling (one raycast a
	frame against the maps' solid parts, Workspace.Maps).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local M = Units.METERS_PER_STUD
local MODES = { "Chase", "Hood", "Cockpit" }

local CameraController = {}

CameraController.settings = {
	shake = true,
	chaseDistance = 6.2, -- metres behind the centre of mass
	chaseHeight = 1.7, -- metres above it
	chaseFov = 68,
	hoodFov = 72,
	cockpitFov = 70,
	speedFovGain = 10, -- extra degrees of field of view at 320 km/h
}

local modeIndex = 1
local root: BasePart? = nil
local smoothedLook = Vector3.new(0, 0, -1)
local CLEARANCE = 0.4 -- m kept between the chase camera and a wall or ceiling
local mapParams = RaycastParams.new()
mapParams.FilterType = Enum.RaycastFilterType.Include
local mapsFolder: Instance? = nil

-- Where the chase camera can be: its wanted position, pulled in front of any map geometry between
-- the car and there.
local function unblocked(from: Vector3, wanted: Vector3): Vector3
	if mapsFolder == nil or mapsFolder.Parent == nil then
		mapsFolder = Workspace:FindFirstChild("Maps")
		if mapsFolder == nil then
			return wanted
		end
		mapParams.FilterDescendantsInstances = { mapsFolder }
	end
	local hit = Workspace:Raycast(from, wanted - from, mapParams)
	if hit == nil then
		return wanted
	end
	local back = from - hit.Position
	if back.Magnitude < CLEARANCE / M then
		return from
	end
	return hit.Position + back.Unit * (CLEARANCE / M)
end

local function setHeadHidden(hidden: boolean)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "Head" or part:FindFirstAncestorOfClass("Accessory")) then
			part.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

local function update(dt: number)
	if not root then
		return
	end
	if not root.Parent then
		CameraController.stop() -- the car is gone (reset, death or respawn): hand the camera back
		return
	end
	local camera = Workspace.CurrentCamera
	local settings = CameraController.settings
	local cf = root.CFrame
	local speedKmh = root.AssemblyLinearVelocity.Magnitude * M * 3.6
	local speedShare = math.clamp(speedKmh / 320, 0, 1)
	local mode = MODES[modeIndex]

	if mode == "Chase" then
		local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
		if flat.Magnitude > 0.1 then
			smoothedLook = smoothedLook:Lerp(flat.Unit, 1 - math.exp(-dt * 6)).Unit
		end
		local position = cf.Position - smoothedLook * (settings.chaseDistance / M) + Vector3.yAxis * (settings.chaseHeight / M)
		local focus = cf.Position + smoothedLook * (2 / M) + Vector3.yAxis * (0.7 / M)
		position = unblocked(cf.Position + Vector3.yAxis * (0.7 / M), position)
		camera.CFrame = CFrame.lookAt(position, focus)
		camera.FieldOfView = settings.chaseFov + settings.speedFovGain * speedShare
	elseif mode == "Hood" then
		local mount = root:FindFirstChild("HoodCam") :: Attachment?
		camera.CFrame = if mount then mount.WorldCFrame else cf
		camera.FieldOfView = settings.hoodFov + settings.speedFovGain * 0.6 * speedShare
	else
		local mount = root:FindFirstChild("CockpitCam") :: Attachment?
		camera.CFrame = if mount then mount.WorldCFrame else cf
		camera.FieldOfView = settings.cockpitFov + settings.speedFovGain * 0.4 * speedShare
	end

	-- With a Scriptable camera, Roblox doesn't move Focus; lighting detail is centred on it.
	camera.Focus = CFrame.new(cf.Position)

	if settings.shake and speedKmh > 120 then
		local amount = math.rad(0.05) * math.clamp((speedKmh - 120) / 200, 0, 1)
		local t = os.clock() * 25
		camera.CFrame *= CFrame.Angles(math.noise(t, 1.3) * amount, math.noise(t, 7.1) * amount, 0)
	end
end

function CameraController.start(vehicle: Model)
	root = vehicle:WaitForChild("MassBox", 10) :: BasePart?
	if not root then
		return
	end
	smoothedLook = root.CFrame.LookVector
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	RunService:UnbindFromRenderStep("VehicleCamera")
	RunService:BindToRenderStep("VehicleCamera", Enum.RenderPriority.Camera.Value + 1, update)
	setHeadHidden(MODES[modeIndex] == "Cockpit")
end

function CameraController.stop()
	RunService:UnbindFromRenderStep("VehicleCamera")
	root = nil
	setHeadHidden(false)
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

function CameraController.cycle()
	modeIndex = modeIndex % #MODES + 1
	setHeadHidden(MODES[modeIndex] == "Cockpit")
end

function CameraController.mode(): string
	return MODES[modeIndex]
end

return CameraController
