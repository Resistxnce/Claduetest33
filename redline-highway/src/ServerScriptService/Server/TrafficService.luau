--[[
	TrafficService: runs highway traffic on the server, one simulation per map, and streams each
	map's traffic to the players on that map.

	Each simulation (TrafficSystem/TrafficSimulation: IDM car following, MOBIL lane changes, slowing
	for curves) runs 20 times a second on the server, which owns it. Players' cars on that map are fed
	in as obstacles, so traffic follows them, yields to them and won't pull out in front of them
	unsafely. Ten times a second, each player is sent the traffic of their own map within SEND_RANGE
	of their car, packed into a buffer, and their client draws it (TrafficRenderer). Traffic cars
	aren't physical objects on the server. Car ids are unique across maps (each map's traffic starts
	at its own idBase).

	Snapshot (RemoteEvent "TrafficState"): FireClient(player, mapId, serverTime, buffer), where
	serverTime is Workspace:GetServerTimeNow() at the step, and the buffer holds, little-endian,
	  per car, 12 bytes: id u16, s f32 (m), lanePos u16 (lanes * 1000), speed u16 (cm/s),
	  profile u8 (index in DriverProfiles.order), unused u8
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TrafficSystem = ReplicatedStorage:WaitForChild("TrafficSystem")
local TrafficSimulation = require(TrafficSystem:WaitForChild("TrafficSimulation"))
local DriverProfiles = require(TrafficSystem:WaitForChild("DriverProfiles"))
local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local STEP = 1 / 20 -- simulation step, s
local SEND_INTERVAL = 0.1 -- s between snapshots
local SEND_RANGE = 1200 -- m ahead of and behind each player
local ROAD_MARGIN = 1 -- m beyond the road's edges where a player's car still counts as on it
local ROAD_HEIGHT = 4 -- m above or below the road surface where a player's car still counts as on it
local RECORD_BYTES = 12

local TrafficService = {}
TrafficService.__index = TrafficService

local services = {} -- map id -> service
local remote: RemoteEvent
local mapOf: (Player) -> string
local profileIndex = {}
for i, name in DriverProfiles.order do
	profileIndex[name] = i
end

-- Each profile's curve speed limits on a road (also made this way by tools/traffic_model.py).
function TrafficService.speedLimits(road)
	local limits = {}
	for name, p in DriverProfiles.profiles do
		limits[name] = road:speedLimits(p.lateral, DriverProfiles.CURVE_DECEL, DriverProfiles.LIMIT_STEP, p.speed[2] / 3.6)
	end
	return limits
end

-- Players' cars on this map become obstacles in road coordinates.
function TrafficService:updateObstacles()
	local sim, road = self.sim, self.road
	table.clear(sim.obstacles)
	local folder = Workspace:FindFirstChild("Vehicles")
	if not folder then
		return
	end
	for _, model in folder:GetChildren() do
		local root = model:IsA("Model") and model.PrimaryPart
		if root and model:GetAttribute("MapId") == self.map.id then
			local s, offset, height = road:project(root.Position * Units.METERS_PER_STUD)
			local onRoad = offset >= -(road.leftEdge + ROAD_MARGIN) and offset <= road.rightEdge + ROAD_MARGIN
			if onRoad and math.abs(height) <= ROAD_HEIGHT then
				local _, direction = road:centerline(s)
				local velocity = root.AssemblyLinearVelocity * Units.METERS_PER_STUD
				table.insert(sim.obstacles, {
					s = s,
					lane = road:laneFromOffset(offset),
					v = math.max(0, velocity:Dot(direction)),
					length = model:GetAttribute("LengthM") or 4.7,
					owner = model:GetAttribute("OwnerUserId"),
				})
			end
		end
	end
end

function TrafficService:pack(centre: number): buffer
	local sim = self.sim
	local nearby = {}
	for _, v in sim.vehicles do
		local d = math.min(sim:ahead(centre, v.s), sim:ahead(v.s, centre))
		if d <= SEND_RANGE then
			table.insert(nearby, v)
		end
	end
	local b = buffer.create(#nearby * RECORD_BYTES)
	for i, v in nearby do
		local o = (i - 1) * RECORD_BYTES
		buffer.writeu16(b, o, v.id % 65536)
		buffer.writef32(b, o + 2, v.s)
		buffer.writeu16(b, o + 6, math.clamp(math.floor(v.lanePos * 1000 + 0.5), 0, 65535))
		buffer.writeu16(b, o + 8, math.clamp(math.floor(v.v * 100 + 0.5), 0, 65535))
		buffer.writeu8(b, o + 10, profileIndex[v.profileName] or 2)
		buffer.writeu8(b, o + 11, 0)
	end
	return b
end

function TrafficService:send()
	for _, player in Players:GetPlayers() do
		if mapOf(player) == self.map.id then
			local centre = nil
			for _, ob in self.sim.obstacles do
				if ob.owner == player.UserId then
					centre = ob.s
				end
			end
			if centre == nil then
				-- not on the road: send what's near the character, if any
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if rootPart then
					centre = self.road:project(rootPart.Position * Units.METERS_PER_STUD)
				end
			end
			if centre then
				remote:FireClient(player, self.map.id, self.stepTime, self:pack(centre))
			end
		end
	end
end

function TrafficService:update(dt: number)
	self.accumulator = math.min(self.accumulator + dt, 0.25)
	while self.accumulator >= STEP do
		self.accumulator -= STEP
		self:updateObstacles()
		self.sim:step(STEP)
		self.stepTime = Workspace:GetServerTimeNow()
	end
	self.sendTimer += dt
	if self.sendTimer >= SEND_INTERVAL then
		self.sendTimer = 0
		self:send()
	end
end

-- Create the snapshot remote and start stepping. mapOfPlayer tells which map a player is on.
function TrafficService.init(remotes: Folder, mapOfPlayer: (Player) -> string)
	remote = Instance.new("RemoteEvent")
	remote.Name = "TrafficState"
	remote.Parent = remotes
	mapOf = mapOfPlayer
	RunService.Heartbeat:Connect(function(dt)
		for _, service in services do
			service:update(dt)
		end
	end)
end

-- Start traffic on a map (from MapRegistry), using the map's traffic settings.
function TrafficService.start(map)
	local road = map.road
	local settings = map.data.traffic
	local sim = TrafficSimulation.new(road.length, road.lanes, true, settings.seed)
	sim.nextId = settings.idBase + 1
	sim:setSpeedLimits(TrafficService.speedLimits(road), DriverProfiles.LIMIT_STEP)
	sim:populate(settings.density)
	-- keep the start grid clear when the server starts (the grid is just behind the start line)
	for i = #sim.vehicles, 1, -1 do
		if math.abs(road:delta(map.data.start, sim.vehicles[i].s)) < settings.clearance then
			table.remove(sim.vehicles, i)
		end
	end
	local self = setmetatable({
		map = map,
		road = road,
		sim = sim,
		accumulator = 0,
		sendTimer = 0,
		stepTime = 0,
	}, TrafficService)
	services[map.id] = self
	print(string.format("[Redline] Traffic on %s: %d cars on %.1f km of %d-lane road", map.id, #sim.vehicles, road.length / 1000, road.lanes))
	return self
end

return TrafficService
