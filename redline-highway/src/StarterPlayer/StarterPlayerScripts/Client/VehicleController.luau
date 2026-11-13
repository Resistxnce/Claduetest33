--[[
	VehicleController
	Runs the player's car on their own machine (they own it on the network). Every frame, before
	Roblox's physics step (RunService.PreSimulation), it:
	  1. reads input and updates steering,
	  2. raycasts each suspension and measures the contact patch velocity in each wheel's frame,
	  3. runs the shared VehicleSimulation,
	  4. applies wheel, drag and downforce forces through the car's VectorForce objects,
	  5. moves the visual wheels and feeds the telemetry.
	All simulation maths is in metres and newtons; this script converts at the edges.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local Units = require(VehicleSystem:WaitForChild("Units"))
local VehicleSimulation = require(VehicleSystem:WaitForChild("CorePhysics"):WaitForChild("VehicleSimulation"))
local Telemetry = require(VehicleSystem:WaitForChild("VehicleTelemetry"):WaitForChild("Telemetry"))
local InputController = require(script.Parent.InputController)

local M = Units.METERS_PER_STUD
local FORCE = Units.FORCE_PER_NEWTON
local WHEEL_IDS = VehicleSimulation.WHEEL_IDS

-- Grip multiplier for each surface material (1 = dry asphalt). Estimates, to tune in testing.
local SURFACE_GRIP: { [Enum.Material]: number } = {
	[Enum.Material.Asphalt] = 1.0,
	[Enum.Material.Pavement] = 0.98,
	[Enum.Material.Concrete] = 0.95,
	[Enum.Material.Slate] = 0.9,
	[Enum.Material.Basalt] = 0.9,
	[Enum.Material.Brick] = 0.85,
	[Enum.Material.Cobblestone] = 0.8,
	[Enum.Material.Rock] = 0.8,
	[Enum.Material.SmoothPlastic] = 0.85,
	[Enum.Material.Plastic] = 0.85,
	[Enum.Material.DiamondPlate] = 0.75,
	[Enum.Material.Metal] = 0.7,
	[Enum.Material.Wood] = 0.7,
	[Enum.Material.WoodPlanks] = 0.7,
	[Enum.Material.Ground] = 0.6,
	[Enum.Material.Grass] = 0.55,
	[Enum.Material.LeafyGrass] = 0.5,
	[Enum.Material.Sand] = 0.45,
	[Enum.Material.Mud] = 0.4,
	[Enum.Material.Snow] = 0.3,
	[Enum.Material.Ice] = 0.12,
	[Enum.Material.Glacier] = 0.12,
}

local VehicleController = {}
VehicleController.__index = VehicleController

function VehicleController.start(model: Model)
	local root = model:WaitForChild("MassBox", 10) :: BasePart?
	if not root then
		warn("[VehicleController] The car has no MassBox; it may not have streamed in")
		return nil
	end
	local configName = model:GetAttribute("VehicleConfig") or "Prototype812"
	local configModule = VehicleSystem.VehicleConfigurations:FindFirstChild(configName)
	if not configModule then
		warn("[VehicleController] Unknown vehicle configuration " .. tostring(configName))
		return nil
	end

	local self = setmetatable({}, VehicleController)
	self.model = model
	self.root = root
	self.config = require(configModule)
	self.sim = VehicleSimulation.new(self.config)

	self.rayParams = RaycastParams.new()
	self.rayParams.FilterType = Enum.RaycastFilterType.Exclude
	self.filterTimer = 0
	self:_updateRayFilter()

	self.forcePoints = {}
	self.wheelForces = {}
	self.wheelJoints = {}
	self.contacts = {}
	for _, id in WHEEL_IDS do
		self.forcePoints[id] = root:WaitForChild("ForcePoint_" .. id)
		self.wheelForces[id] = root:WaitForChild("WheelForce_" .. id)
		self.wheelJoints[id] = root:WaitForChild("WheelJoint_" .. id)
		self.contacts[id] = { hit = false, distance = 0, vLong = 0, vLat = 0, grip = 1, point = root.Position, forward = Vector3.zero, right = Vector3.zero }
	end
	self.dragForce = root:WaitForChild("DragForce")
	self.aeroFront = root:WaitForChild("AeroFrontForce")
	self.aeroRear = root:WaitForChild("AeroRearForce")

	-- the character's own controls would walk it and jump out of the seat with Space
	local ok, controls = pcall(function()
		local playerModule = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
		return require(playerModule):GetControls()
	end)
	if ok and controls then
		controls:Disable()
		self.controls = controls
	end

	self.previousVelocity = Vector3.zero
	self.gForce = Vector2.zero
	Telemetry.reset()
	Telemetry.sim = self.sim

	self.connection = RunService.PreSimulation:Connect(function(dt)
		self:step(dt)
	end)
	self.ancestryConnection = model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			self:stop()
		end
	end)
	return self
end

-- The suspension rays ignore the car itself, the driver and the traffic cars (a ray landing on a
-- traffic car in a crash would launch the car). The traffic folder can appear later or be replaced
-- on a map switch, so step() checks again about once a second.
function VehicleController:_updateRayFilter()
	local traffic = Workspace:FindFirstChild("Traffic")
	local character = Players.LocalPlayer.Character
	if self.filterReady and traffic == self.filterTraffic and character == self.filterCharacter then
		return
	end
	self.filterReady = true
	self.filterTraffic = traffic
	self.filterCharacter = character
	local exclude: { Instance } = { self.model }
	if character then
		table.insert(exclude, character)
	end
	if traffic then
		table.insert(exclude, traffic)
	end
	self.rayParams.FilterDescendantsInstances = exclude
end

function VehicleController:step(dt: number)
	local root = self.root
	if not root.Parent then
		return
	end
	dt = math.clamp(dt, 1 / 240, 1 / 20)
	local sim = self.sim
	self.filterTimer += dt
	if self.filterTimer > 1 then
		self.filterTimer = 0
		self:_updateRayFilter()
	end

	InputController.update(dt)
	local input = InputController.state

	local cf = root.CFrame
	local up = cf.UpVector
	local velocity = root.AssemblyLinearVelocity * M -- m/s
	local forwardSpeed = velocity:Dot(cf.LookVector)
	local speed = velocity.Magnitude

	local steerLeft, steerRight = sim:updateSteering(dt, input.steer, forwardSpeed)

	for _, id in WHEEL_IDS do
		local wheel = sim.wheels[id]
		local contact = self.contacts[id]
		local mountWorld = cf:PointToWorldSpace(wheel.mount / M)
		local rayLength = wheel.rayLength / M
		local result = Workspace:Raycast(mountWorld, -up * rayLength, self.rayParams)

		local steer = if id == "FL" then steerLeft elseif id == "FR" then steerRight else 0
		local wheelFrame = cf * CFrame.Angles(0, -steer, 0)
		local forward, right = wheelFrame.LookVector, wheelFrame.RightVector
		if result then
			local normal = result.Normal
			forward = (forward - normal * forward:Dot(normal)).Unit
			right = (right - normal * right:Dot(normal)).Unit
			contact.hit = true
			contact.distance = (mountWorld - result.Position):Dot(up) * M
			contact.point = result.Position
			contact.grip = SURFACE_GRIP[result.Material] or 0.9
		else
			contact.hit = false
			contact.point = mountWorld - up * rayLength
		end
		local pointVelocity = root:GetVelocityAtPosition(contact.point) * M
		contact.vLong = pointVelocity:Dot(forward)
		contact.vLat = pointVelocity:Dot(right)
		contact.forward = forward
		contact.right = right
	end

	local aero = sim:step(dt, input, self.contacts, forwardSpeed, speed)

	for _, id in WHEEL_IDS do
		local wheel = sim.wheels[id]
		local contact = self.contacts[id]
		local force = self.wheelForces[id]
		if wheel.contact then
			local newtons = up * wheel.load + contact.forward * wheel.fx + contact.right * wheel.fy
			-- lateral force acts at the roll centre height above the contact patch
			local applyAt = contact.point + up * (wheel.suspension.rollCenterHeight / M)
			self.forcePoints[id].Position = cf:PointToObjectSpace(applyAt)
			force.Force = newtons * FORCE
		else
			force.Force = Vector3.zero
		end
		-- visual wheel: suspension travel, steering and spin
		local drop = (wheel.length - wheel.staticLength) / M
		self.wheelJoints[id].Transform = CFrame.new(0, -drop, 0) * CFrame.Angles(0, -wheel.steer, 0) * CFrame.Angles(-wheel.spin, 0, 0)
	end

	if speed > 0.5 then
		self.dragForce.Force = -velocity.Unit * aero.drag * FORCE
	else
		self.dragForce.Force = Vector3.zero
	end
	self.aeroFront.Force = -up * aero.downFront * FORCE
	self.aeroRear.Force = -up * aero.downRear * FORCE

	local acceleration = (velocity - self.previousVelocity) / dt
	self.previousVelocity = velocity
	local longG = acceleration:Dot(cf.LookVector) / Units.GRAVITY
	local latG = acceleration:Dot(cf.RightVector) / Units.GRAVITY
	self.gForce = self.gForce:Lerp(Vector2.new(latG, longG), math.clamp(dt * 8, 0, 1))
	Telemetry.frame.latG = self.gForce.X
	Telemetry.frame.longG = self.gForce.Y
	Telemetry.frame.fps = 1 / dt
	Telemetry.updateTimers(os.clock(), speed * 3.6, sim.telemetry.brake, root.Position * M)
end

function VehicleController:stop()
	if self.stopped then
		return
	end
	self.stopped = true
	if self.connection then
		self.connection:Disconnect()
	end
	if self.ancestryConnection then
		self.ancestryConnection:Disconnect()
	end
	if self.controls then
		self.controls:Enable()
	end
	if Telemetry.sim == self.sim then
		Telemetry.sim = nil
	end
end

return VehicleController
