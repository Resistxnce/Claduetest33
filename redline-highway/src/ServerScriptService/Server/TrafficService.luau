--[[
	TrafficService: runs highway traffic on the server and streams it to players.

	The simulation (TrafficSystem/TrafficSimulation: IDM car following, MOBIL lane changes) runs 20
	times a second on the server, which owns it. Each player's car is fed in as an obstacle, so
	traffic follows it, yields to it and won't pull out in front of it unsafely. Ten times a second,
	each player is sent the traffic within SEND_RANGE of their car, packed into a buffer, and their
	client draws it (TrafficRenderer). Traffic cars aren't physical objects on the server.

	Snapshot layout (little-endian), sent with Workspace:GetServerTimeNow() at the time of the step:
	  per car, 12 bytes: id u16, s f32 (m), lanePos u16 (lanes * 1000), speed u16 (cm/s),
	  profile u8 (index in DriverProfiles.order), unused u8
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TrafficSystem = ReplicatedStorage:WaitForChild("TrafficSystem")
local TrafficSimulation = require(TrafficSystem:WaitForChild("TrafficSimulation"))
local RoadGeometry = require(TrafficSystem:WaitForChild("RoadGeometry"))
local DriverProfiles = require(TrafficSystem:WaitForChild("DriverProfiles"))
local Units = require(ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("Units"))

local STEP = 1 / 20 -- simulation step, s
local SEND_INTERVAL = 0.1 -- s between snapshots
local SEND_RANGE = 1200 -- m ahead of and behind each player
local DENSITY = 5 -- cars per km per lane: light traffic for the proving ground
local GRID_CLEARANCE = 200 -- m kept clear of traffic around the start grid when the server starts
local GRID_S = 112 -- m, where the start grid is (TrackBuilder.gridCFrame)
local OFF_ROAD = RoadGeometry.LANES * RoadGeometry.LANE_WIDTH / 2 + 4 -- m from the centre line
local RECORD_BYTES = 12

local TrafficService = {}

local sim
local remote: RemoteEvent
local accumulator, sendTimer, stepTime = 0, 0, 0
local profileIndex = {}
for i, name in DriverProfiles.order do
	profileIndex[name] = i
end

-- Players' cars become obstacles in road coordinates.
local function updateObstacles()
	table.clear(sim.obstacles)
	local folder = Workspace:FindFirstChild("Vehicles")
	if not folder then
		return
	end
	for _, model in folder:GetChildren() do
		local root = model:IsA("Model") and model.PrimaryPart
		if root then
			local position = root.Position * Units.METERS_PER_STUD
			local s, offset = RoadGeometry.project(position)
			if math.abs(offset) <= OFF_ROAD then
				local _, direction = RoadGeometry.centerline(s)
				local velocity = root.AssemblyLinearVelocity * Units.METERS_PER_STUD
				table.insert(sim.obstacles, {
					s = s,
					lane = RoadGeometry.laneFromOffset(offset),
					v = math.max(0, velocity:Dot(direction)),
					length = 4.7,
					owner = model:GetAttribute("OwnerUserId"),
				})
			end
		end
	end
end

local function pack(centre: number): buffer
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

local function send()
	for _, player in Players:GetPlayers() do
		local centre = nil
		for _, ob in sim.obstacles do
			if ob.owner == player.UserId then
				centre = ob.s
			end
		end
		if centre == nil then
			-- not on the road: send what's near the character, if any
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				centre = RoadGeometry.project(rootPart.Position * Units.METERS_PER_STUD)
			end
		end
		if centre then
			remote:FireClient(player, stepTime, pack(centre))
		end
	end
end

function TrafficService.init(remotes: Folder)
	remote = Instance.new("RemoteEvent")
	remote.Name = "TrafficState"
	remote.Parent = remotes

	sim = TrafficSimulation.new(RoadGeometry.LAP, RoadGeometry.LANES, true, 812)
	sim:populate(DENSITY)
	for i = #sim.vehicles, 1, -1 do
		local v = sim.vehicles[i]
		if math.min(sim:ahead(GRID_S, v.s), sim:ahead(v.s, GRID_S)) < GRID_CLEARANCE then
			table.remove(sim.vehicles, i)
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		accumulator = math.min(accumulator + dt, 0.25)
		while accumulator >= STEP do
			accumulator -= STEP
			updateObstacles()
			sim:step(STEP)
			stepTime = Workspace:GetServerTimeNow()
		end
		sendTimer += dt
		if sendTimer >= SEND_INTERVAL then
			sendTimer = 0
			send()
		end
	end)
	print(string.format("[Redline] Traffic: %d cars on %.1f km of %d-lane road", #sim.vehicles,
		RoadGeometry.LAP / 1000, RoadGeometry.LANES))
end

return TrafficService
