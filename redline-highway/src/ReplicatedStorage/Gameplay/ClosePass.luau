--[[
	ClosePass: close-pass scoring, a fictional arcade layer on top of the realistic driving. Pure maths
	with no Roblox objects; tools/close_pass_model.py is a line-for-line Python copy with tests. Keep
	the two in step.

	A pass counts when the player overtakes a traffic car at speed, faster than it by a margin, with a
	small gap between the two cars' sides while they are alongside. Closer and faster passes score
	more. Passes within a few seconds of each other build a combo multiplier; the combo is banked when
	the chain ends, and lost if the player hits a car first.

	Positions are road coordinates: s along the road (m), offset sideways (m), v along the road (m/s).
]]

local ClosePass = {}
ClosePass.__index = ClosePass

ClosePass.DEFAULTS = {
	minSpeedKmh = 120, -- the player must be at least this fast
	minRelativeKmh = 30, -- and this much faster than the car being passed
	maxGap = 2.0, -- m between the cars' sides for a pass to count
	closeGap = 1.0, -- m, "close pass"
	insaneGap = 0.5, -- m, "insane pass"
	basePoints = 100,
	closenessPoints = 400, -- added at the closest gaps
	speedRef = 200, -- km/h where the speed factor is 1
	speedExponent = 1.5,
	comboWindow = 4.0, -- s to make the next pass and keep the combo going
	comboStep = 0.5, -- added to the multiplier for each chained pass
	comboMax = 5.0,
}

function ClosePass.new(settings, lap: number)
	local self = setmetatable({}, ClosePass)
	self.settings = settings or ClosePass.DEFAULTS
	self.lap = lap
	self.tracks = {} -- cars alongside the player right now
	self.total = 0 -- banked points
	self.combo = 0 -- points in the current, unbanked combo
	self.multiplier = 1
	self.timer = 0 -- time left to chain the next pass
	self.passes = 0
	self.events = {}
	return self
end

function ClosePass:wrap(d: number): number
	return (d + self.lap / 2) % self.lap - self.lap / 2
end

-- player and each car: { s, offset, v, length, width }. cars: id -> car.
function ClosePass:update(dt: number, player, cars)
	table.clear(self.events)
	if self.timer > 0 then
		self.timer -= dt
		if self.timer <= 0 then
			self.timer = 0
			if self.combo > 0 then
				self.total += self.combo
				table.insert(self.events, { kind = "banked", points = self.combo, total = self.total })
			end
			self.combo = 0
			self.multiplier = 1
		end
	end

	for id, car in cars do
		local ds = self:wrap(car.s - player.s) -- positive: the car is ahead
		local alongside = math.abs(ds) < (player.length + car.length) / 2
		local gap = math.abs(car.offset - player.offset) - (player.width + car.width) / 2
		local track = self.tracks[id]
		if alongside then
			if track == nil then
				track = { minGap = gap, startedBehind = ds > 0, crashed = false }
				self.tracks[id] = track
			else
				track.minGap = math.min(track.minGap, gap)
			end
			if gap < 0 and not track.crashed then
				track.crashed = true
				table.insert(self.events, { kind = "crash", lost = self.combo })
				self.combo = 0
				self.multiplier = 1
				self.timer = 0
			end
		elseif track ~= nil then
			self.tracks[id] = nil
			if track.startedBehind and ds < 0 and not track.crashed then
				self:score(player, car, track.minGap)
			end
		end
	end

	for id in self.tracks do
		if cars[id] == nil then
			self.tracks[id] = nil
		end
	end
end

function ClosePass:score(player, car, gap: number)
	local st = self.settings
	local speed = player.v * 3.6
	local relative = (player.v - car.v) * 3.6
	if speed < st.minSpeedKmh or relative < st.minRelativeKmh or gap > st.maxGap then
		return
	end
	local closeness = math.clamp((st.maxGap - gap) / (st.maxGap - st.insaneGap), 0, 1)
	local points = (st.basePoints + st.closenessPoints * closeness ^ 1.5) * (speed / st.speedRef) ^ st.speedExponent
	if self.timer > 0 then
		self.multiplier = math.min(st.comboMax, self.multiplier + st.comboStep)
	else
		self.multiplier = 1
	end
	local gained = math.floor(points * self.multiplier + 0.5)
	self.combo += gained
	self.timer = st.comboWindow
	self.passes += 1
	local label = if gap <= st.insaneGap then "INSANE PASS" elseif gap <= st.closeGap then "CLOSE PASS" else "NEAR MISS"
	table.insert(self.events, {
		kind = "pass",
		points = gained,
		label = label,
		gap = gap,
		multiplier = self.multiplier,
		combo = self.combo,
	})
end

return ClosePass
