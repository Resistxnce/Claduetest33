--[[
	TrafficRenderer: draws the traffic the server sends (see TrafficService for the snapshot format).

	Each traffic car is a simple stand-in (a body box and a darker cabin, or one tall box for a truck)
	taken from a pool. Every frame it moves forward at its own speed, so it doesn't stutter between
	the server's 10 snapshots a second, and eases toward each new snapshot. All cars move together
	with Workspace:BulkMoveTo. The cars are anchored and solid on this computer, so your car can hit
	them; the crash physics of the traffic car itself comes later.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TrafficSystem = ReplicatedStorage:WaitForChild("TrafficSystem")
local RoadGeometry = require(TrafficSystem:WaitForChild("RoadGeometry"))
local DriverProfiles = require(TrafficSystem:WaitForChild("DriverProfiles"))
local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local M = Units.METERS_PER_STUD
local RECORD_BYTES = 12
local FORGET_AFTER = 0.6 -- s without an update before a car is put away
local CORRECTION_RATE = 4 -- 1/s, how quickly a car eases onto the server's position
local LAP = RoadGeometry.LAP

local PAINT = {
	Color3.fromRGB(235, 235, 232), Color3.fromRGB(30, 30, 34), Color3.fromRGB(120, 124, 130),
	Color3.fromRGB(170, 172, 176), Color3.fromRGB(28, 52, 110), Color3.fromRGB(122, 18, 24),
	Color3.fromRGB(46, 70, 52), Color3.fromRGB(196, 170, 120), Color3.fromRGB(60, 90, 140),
}

local TrafficRenderer = {}

local folder: Folder
local cars = {} -- id -> car
local pool = {} -- profile index -> spare cars
local parts: { BasePart } = {}
local frames: { CFrame } = {}

local function newPart(name: string, size: Vector3, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeCar(profileIndex: number)
	local name = DriverProfiles.order[profileIndex] or "normal"
	local p = DriverProfiles.profiles[name]
	local truck = name == "truck"
	local height = if truck then 3.8 else 1.15
	local model = Instance.new("Model")
	model.Name = "Traffic_" .. name
	local paint = PAINT[math.random(1, #PAINT)]
	local body = newPart("Body", Vector3.new(p.width, height, p.length) / M, paint, Enum.Material.SmoothPlastic, model)
	local car = {
		model = model,
		body = body,
		bodyLift = (0.18 + height / 2) / M,
		profileIndex = profileIndex,
		s = 0,
		lanePos = 1,
		v = 0,
		targetS = 0,
		targetLane = 1,
		stamp = 0,
		seen = 0,
	}
	if not truck then
		car.cabin = newPart("Cabin", Vector3.new(p.width * 0.86, 0.5, p.length * 0.48) / M,
			Color3.fromRGB(20, 24, 30), Enum.Material.Glass, model)
		car.cabinLift = (0.18 + height + 0.25) / M
	end
	model.Parent = folder
	return car
end

local function take(profileIndex: number)
	local spare = pool[profileIndex]
	if spare and #spare > 0 then
		local car = table.remove(spare)
		car.model.Parent = folder
		return car
	end
	return makeCar(profileIndex)
end

local function putAway(id: number)
	local car = cars[id]
	cars[id] = nil
	car.model.Parent = nil
	pool[car.profileIndex] = pool[car.profileIndex] or {}
	table.insert(pool[car.profileIndex], car)
end

local function onSnapshot(serverTime: number, data: buffer)
	local now = Workspace:GetServerTimeNow()
	local age = math.clamp(now - serverTime, 0, 0.5)
	local count = buffer.len(data) // RECORD_BYTES
	for i = 0, count - 1 do
		local o = i * RECORD_BYTES
		local id = buffer.readu16(data, o)
		local s = buffer.readf32(data, o + 2)
		local lanePos = buffer.readu16(data, o + 6) / 1000
		local v = buffer.readu16(data, o + 8) / 100
		local profileIndex = buffer.readu8(data, o + 10)
		local car = cars[id]
		if car and car.profileIndex ~= profileIndex then
			putAway(id) -- the id was reused for a different kind of car
			car = nil
		end
		if not car then
			car = take(profileIndex)
			cars[id] = car
			car.s = (s + v * age) % LAP
			car.lanePos = lanePos
		end
		car.targetS = s
		car.targetLane = lanePos
		car.v = v
		car.stamp = serverTime
		car.seen = os.clock()
	end
end

local function render(dt: number)
	local clock = os.clock()
	local now = Workspace:GetServerTimeNow()
	table.clear(parts)
	table.clear(frames)
	for id, car in cars do
		if clock - car.seen > FORGET_AFTER then
			putAway(id)
			continue
		end
		-- where the server's car is now, extrapolated from its last snapshot
		local target = car.targetS + car.v * math.clamp(now - car.stamp, 0, 0.5)
		car.s = (car.s + car.v * dt) % LAP
		local drift = (target - car.s + LAP / 2) % LAP - LAP / 2
		if math.abs(drift) > 30 then
			car.s = target % LAP -- too far off (a long stall): jump
		else
			car.s = (car.s + drift * math.clamp(dt * CORRECTION_RATE, 0, 1)) % LAP
		end
		car.lanePos += (car.targetLane - car.lanePos) * math.clamp(dt * CORRECTION_RATE, 0, 1)

		local p, direction = RoadGeometry.pointAt(car.s, car.lanePos, 0)
		local base = CFrame.lookAt(p / M, (p + direction) / M)
		table.insert(parts, car.body)
		table.insert(frames, base + Vector3.new(0, car.bodyLift, 0))
		if car.cabin then
			table.insert(parts, car.cabin)
			table.insert(frames, base * CFrame.new(0, car.cabinLift, 0.15 / M))
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- The cars being drawn: id -> { s, lanePos, v, profileIndex, ... }. Other modules only read it.
function TrafficRenderer.cars()
	return cars
end

function TrafficRenderer.init(remotes: Folder)
	folder = Instance.new("Folder")
	folder.Name = "Traffic"
	folder.Parent = Workspace
	remotes:WaitForChild("TrafficState").OnClientEvent:Connect(onSnapshot)
	RunService.PreRender:Connect(render)
end

return TrafficRenderer
