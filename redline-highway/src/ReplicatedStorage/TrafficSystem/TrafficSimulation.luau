--[[
	TrafficSimulation: traffic on a multi-lane road, in road coordinates. Pure maths with no Roblox
	objects; tools/traffic_model.py is a line-for-line Python copy with tests (no collisions in light
	and heavy traffic, realistic flow, keeping right, safe lane changes around fast, slow and stopped
	players). Keep the two in step.

	Positions: s is the distance along the road (m); lanes are numbered from the left, 1 = fast lane;
	lanePos is the lateral position in lanes (2.5 = halfway between lanes 2 and 3).
	Car following: IDM. Lane changes: MOBIL with a keep-right bias and a safety limit on how hard the
	new follower would have to brake. Curves: with speed limits set (setSpeedLimits, made from the
	road's curvature by RoadGeometry:speedLimits), each driver slows ahead of a curve to keep their
	sideways acceleration comfortable. Players' cars are "obstacles": the simulation doesn't move them,
	but traffic follows them, yields to them and won't pull out in front of them unsafely.
]]

local DriverProfiles = require(script.Parent.DriverProfiles)
local IDM = require(script.Parent.IDM)

local PROFILES = DriverProfiles.profiles
local LANE_CHANGE_TIME = DriverProfiles.LANE_CHANGE_TIME
local MIN_TIME_IN_LANE = DriverProfiles.MIN_TIME_IN_LANE
local DECISION = DriverProfiles.DECISION_INTERVAL
local CURVE_LOOKAHEAD = DriverProfiles.CURVE_LOOKAHEAD
local CURVE_RESPONSE = DriverProfiles.CURVE_RESPONSE

local TrafficSimulation = {}
TrafficSimulation.__index = TrafficSimulation

local function vehicleLength(x): number
	return if x.profile then x.profile.length else (x.length or 4.7)
end

local function params(x)
	return x.profile or DriverProfiles.PLAYER
end

local function desiredSpeed(x): number
	return x.v0 or math.max(x.v, 1)
end

-- index of the first key greater than s (1-based; #keys + 1 if none)
local function upperBound(keys: { number }, s: number): number
	local lo, hi = 1, #keys + 1
	while lo < hi do
		local mid = (lo + hi) // 2
		if keys[mid] <= s then
			lo = mid + 1
		else
			hi = mid
		end
	end
	return lo
end

--[[
	length: road length (m). lanes: lane count. loop: true if the road joins itself (a ring).
	seed: random seed (optional).
]]
function TrafficSimulation.new(length: number, lanes: number, loop: boolean, seed: number?)
	local self = setmetatable({}, TrafficSimulation)
	self.length = length
	self.lanes = lanes
	self.loop = loop
	self.vehicles = {}
	self.obstacles = {} -- players: { s, lane (lanePos), v, length }
	self.random = Random.new(seed or 1)
	self.time = 0
	self.nextId = 1
	self.laneChanges = 0
	self.order = {}
	self.keys = {}
	self.limits = nil -- profile name -> speed limit (m/s) for each limitStep metres of road
	self.limitStep = DriverProfiles.LIMIT_STEP
	return self
end

-- limits: profile name -> { speed limit (m/s) for each step metres of road, from s = 0 }
function TrafficSimulation:setSpeedLimits(limits, step: number)
	self.limits = limits
	self.limitStep = step
end

-- The speed limit for a profile at distance s, or nil without limits.
function TrafficSimulation:limitAt(s: number, profileName: string): number?
	local limit = self.limits and self.limits[profileName]
	if limit == nil then
		return nil
	end
	if self.loop then
		s %= self.length
	end
	return limit[math.clamp(math.floor(s / self.limitStep) + 1, 1, #limit)]
end

-- The leftmost lane a profile may use (trucks keep to the lanes on the right).
function TrafficSimulation:laneMin(p): number
	return if p.rightLanes then math.max(1, self.lanes - p.rightLanes + 1) else 1
end

function TrafficSimulation:pickProfile(): string
	local r, total = self.random:NextNumber(), 0
	for _, name in DriverProfiles.order do
		total += PROFILES[name].share
		if r <= total then
			return name
		end
	end
	return "normal"
end

function TrafficSimulation:add(s: number, lane: number, profileName: string, v: number?)
	local p = PROFILES[profileName]
	local v0 = self.random:NextNumber(p.speed[1], p.speed[2]) / 3.6
	if v == nil then
		v = math.min(v0 * 0.85, self:limitAt(s, profileName) or math.huge)
	end
	local vehicle = {
		id = self.nextId,
		s = s % self.length,
		v = v,
		a = 0,
		lane = lane,
		lanePos = lane,
		fromLane = lane,
		change = 0,
		profile = p,
		profileName = profileName,
		v0 = v0,
		decision = self.random:NextNumber(DECISION[1], DECISION[2]),
		sinceChange = MIN_TIME_IN_LANE,
	}
	self.nextId += 1
	table.insert(self.vehicles, vehicle)
	return vehicle
end

-- Fill the road with perKmPerLane cars per kilometre in every lane.
function TrafficSimulation:populate(perKmPerLane: number)
	for lane = 1, self.lanes do
		local count = math.floor(perKmPerLane * self.length / 1000)
		local spacing = self.length / math.max(count, 1)
		for k = 0, count - 1 do
			local name = self:pickProfile()
			if self:laneMin(PROFILES[name]) > lane then
				name = "normal"
			end
			self:add(k * spacing + self.random:NextNumber(0, spacing * 0.4), lane, name)
		end
	end
end

function TrafficSimulation:ahead(sFrom: number, sTo: number): number
	local d = sTo - sFrom
	if self.loop then
		d %= self.length
	end
	return d
end

-- Per lane, everything occupying it (cars and players), sorted by position.
function TrafficSimulation:buildOrder()
	local order = {}
	for lane = 1, self.lanes do
		order[lane] = {}
	end
	for _, v in self.vehicles do
		table.insert(order[v.lane], v)
		if v.change > 0 and v.fromLane ~= v.lane then
			table.insert(order[v.fromLane], v) -- a car changing lanes blocks both
		end
	end
	for _, ob in self.obstacles do
		local base = math.floor(ob.lane + 0.5)
		local frac = ob.lane - base
		local extra = if frac > 0.2 then base + 1 elseif frac < -0.2 then base - 1 else nil
		for _, lane in { base, extra } do
			if lane and lane >= 1 and lane <= self.lanes then
				table.insert(order[lane], ob)
			end
		end
	end
	local keys = {}
	for lane = 1, self.lanes do
		table.sort(order[lane], function(a, b)
			return a.s < b.s
		end)
		local k = {}
		for i, x in order[lane] do
			k[i] = x.s
		end
		keys[lane] = k
	end
	self.order = order
	self.keys = keys
end

-- Leader, gap to it, follower, gap to it, in a lane, ignoring x itself. Gaps are bumper to bumper.
function TrafficSimulation:neighbours(x, lane: number)
	local items = self.order[lane]
	if not items or #items == 0 then
		return nil, nil, nil, nil
	end
	local n = #items
	local k = upperBound(self.keys[lane], x.s) -- first item ahead of x
	local lead = nil
	for j = 0, n - 1 do
		local idx = k + j
		if idx > n then
			if not self.loop then
				break
			end
			idx = (idx - 1) % n + 1
		end
		if items[idx] ~= x then
			lead = items[idx]
			break
		end
	end
	local follow = nil
	for j = 1, n do
		local idx = k - j
		if idx < 1 then
			if not self.loop then
				break
			end
			idx = (idx - 1) % n + 1
		end
		if items[idx] ~= x and items[idx] ~= lead then
			follow = items[idx]
			break
		end
	end
	local leadGap = if lead then self:ahead(x.s, lead.s) - (vehicleLength(x) + vehicleLength(lead)) / 2 else nil
	local followGap = if follow then self:ahead(follow.s, x.s) - (vehicleLength(x) + vehicleLength(follow)) / 2 else nil
	return lead, leadGap, follow, followGap
end

function TrafficSimulation:accel(x, leader, gap: number?): number
	local v = x.v
	return IDM.acceleration(params(x), v, desiredSpeed(x), gap, if leader then v - leader.v else 0)
end

-- MOBIL: should car v move to lane target?
function TrafficSimulation:wantsChange(v, target: number): boolean
	local p = v.profile
	if target < self:laneMin(p) or target > self.lanes then
		return false
	end
	local leadOld, gapOld, followOld, gapFollowOld = self:neighbours(v, v.lane)
	local leadNew, gapNew, followNew, gapFollowNew = self:neighbours(v, target)
	if gapNew ~= nil and gapNew < p.minGap then
		return false
	end
	if gapFollowNew ~= nil and gapFollowNew < params(followNew).minGap then
		return false
	end
	local aC = self:accel(v, leadOld, gapOld)
	local aCNew = self:accel(v, leadNew, gapNew)
	local aN, aNNew = 0, 0
	if followNew then
		local gapN = if gapNew ~= nil then gapFollowNew + gapNew + vehicleLength(v) else nil
		aN = self:accel(followNew, leadNew, gapN)
		aNNew = self:accel(followNew, v, gapFollowNew)
		if aNNew < -DriverProfiles.SAFE_DECEL then
			return false
		end
	end
	local aO, aONew = 0, 0
	if followOld and followOld.profile then
		local gapO = if gapOld ~= nil then gapFollowOld + gapOld + vehicleLength(v) else nil
		aO = self:accel(followOld, v, gapFollowOld)
		aONew = self:accel(followOld, leadOld, gapO)
	end
	local incentive = aCNew - aC + p.politeness * ((aNNew - aN) + (aONew - aO))
	local bias = if target > v.lane then DriverProfiles.KEEP_RIGHT_BIAS else -DriverProfiles.KEEP_RIGHT_BIAS
	return incentive + bias > p.threshold
end

function TrafficSimulation:step(dt: number)
	self:buildOrder()
	for _, v in self.vehicles do
		local lead, gap = self:neighbours(v, v.lane)
		local a = self:accel(v, lead, gap)
		if v.change > 0 and v.fromLane ~= v.lane then
			local lead2, gap2 = self:neighbours(v, v.fromLane)
			a = math.min(a, self:accel(v, lead2, gap2))
		end
		local limit = self:limitAt(v.s + v.v * CURVE_LOOKAHEAD, v.profileName)
		if limit then
			-- slow for the curve ahead
			a = math.min(a, math.max((limit - v.v) / CURVE_RESPONSE, -DriverProfiles.MAX_DECEL))
		end
		v.a = a
		v.decision -= dt
		v.sinceChange += dt
		if v.decision <= 0 and v.change <= 0 and v.sinceChange >= MIN_TIME_IN_LANE then
			v.decision = self.random:NextNumber(DECISION[1], DECISION[2])
			for _, target in { v.lane - 1, v.lane + 1 } do
				if self:wantsChange(v, target) then
					v.fromLane, v.lane = v.lane, target
					v.change, v.sinceChange = LANE_CHANGE_TIME, 0
					self.laneChanges += 1
					-- occupy the new lane at once, so nobody else picks the same gap this step
					local k = upperBound(self.keys[target], v.s)
					table.insert(self.keys[target], k, v.s)
					table.insert(self.order[target], k, v)
					break
				end
			end
		end
	end
	for _, v in self.vehicles do
		local speed = math.max(0, v.v + v.a * dt)
		local s = v.s + (v.v + speed) / 2 * dt
		v.s = if self.loop then s % self.length else s
		v.v = speed
		if v.change > 0 then
			v.change = math.max(0, v.change - dt)
			local t = 1 - v.change / LANE_CHANGE_TIME
			local smooth = t * t * (3 - 2 * t)
			v.lanePos = v.fromLane + (v.lane - v.fromLane) * smooth
			if v.change == 0 then
				v.fromLane = v.lane
			end
		else
			v.lanePos = v.lane
		end
	end
	self.time += dt
end

return TrafficSimulation
