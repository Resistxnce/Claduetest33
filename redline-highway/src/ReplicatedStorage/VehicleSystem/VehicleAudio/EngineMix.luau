--[[
	EngineMix: turns the car's state into a volume and playback speed for every sound layer, plus
	the one-shot sounds to start this frame. Pure maths with no Roblox objects, so it can be checked
	outside the game: tools/audio_preview.py is a line-for-line Python copy that renders what a drive
	sounds like. Keep the two in step.

	Engine loops come in pairs (on and off throttle) recorded at several engine speeds. Each frame:
	  * the two recorded engine speeds either side of the current rpm are crossfaded with equal
	    power, measured in log-rpm so the blend is even in pitch, and each loop is pitched by
	    rpm / the rpm it was recorded at;
	  * on- and off-throttle loops are crossfaded by engine load (torque as a share of the
	    full-throttle torque at this rpm), smoothed so it doesn't flutter;
	  * loudness rises with rpm.
	The rev limiter needs no special sound: the simulation cuts fuel, so the load drops and the rpm
	bounces, and the mix follows. Upshifts at high load add an ignition-cut "crack"; lifting off at
	high rpm sets off exhaust crackles for a moment.

	Inputs each frame (all numbers):
	  rpm, load (0-1), gear, shifting (bool), limiter (bool), speed (m/s), slip (largest combined
	  tyre slip, 1 = at the grip peak), slideSpeed (fastest tyre sliding speed, m/s), shaftRpm
	  (driveshaft), bump (bump-stop impact speed, m/s), interior (bool, cockpit camera)
]]

local EngineMix = {}

local HALF_PI = math.pi / 2

-- Equal-power crossfade weights over the recorded engine speeds (ascending), in log-rpm.
function EngineMix.rpmWeights(points: { number }, rpm: number, out: { number }): { number }
	local n = #points
	for i = 1, n do
		out[i] = 0
	end
	if rpm <= points[1] then
		out[1] = 1
		return out
	end
	if rpm >= points[n] then
		out[n] = 1
		return out
	end
	for i = 1, n - 1 do
		local a, b = points[i], points[i + 1]
		if rpm <= b then
			local t = math.log(rpm / a) / math.log(b / a)
			out[i] = math.cos(t * HALF_PI)
			out[i + 1] = math.sin(t * HALF_PI)
			break
		end
	end
	return out
end

local EFFECT_LOOPS = { "squeal", "road", "wind", "whine" }
EngineMix.EFFECT_LOOPS = EFFECT_LOOPS

--[[
	spec: the car configuration's audio table. engineSheet and effectsSheet: the sheet tables in
	VehicleAudio/Sheets. random: a Random object (optional).
]]
function EngineMix.new(spec, engineSheet, effectsSheet, random: Random?)
	local self = {
		spec = spec,
		points = {}, -- recorded engine speeds, ascending
		onLoop = {}, -- index into engineSheet.loops of the on-throttle loop at each point
		offLoop = {},
		loopRpm = {}, -- recorded engine speed of each loop
		engineVolume = {}, -- per engine loop, indexed like engineSheet.loops
		engineSpeed = {},
		effects = {}, -- per effect loop name: { volume, speed }
		events = {}, -- one-shots to start this frame: { name, volume, speed }
		weights = {},
		load = 0,
		lastGear = 0,
		upshiftTimer = 0,
		sinceHighLoad = math.huge,
		crackleTime = 0,
		bumpCooldown = 0,
		crackleNames = {},
		whineHz = 1000,
		random = random or Random.new(),
	}

	local byRpm = {}
	for i, loop in engineSheet.loops do
		self.loopRpm[i] = loop.rpm
		self.engineVolume[i] = 0
		self.engineSpeed[i] = 1
		local key = math.floor(loop.rpm + 0.5)
		local pair = byRpm[key]
		if not pair then
			pair = { rpm = loop.rpm }
			byRpm[key] = pair
			table.insert(self.points, pair)
		end
		pair[loop.load] = i
	end
	table.sort(self.points, function(a, b)
		return a.rpm < b.rpm
	end)
	for k, pair in self.points do
		self.onLoop[k] = pair.on or pair.off
		self.offLoop[k] = pair.off or pair.on
		self.points[k] = pair.rpm
	end

	for _, name in EFFECT_LOOPS do
		self.effects[name] = { volume = 0, speed = 1 }
	end
	if effectsSheet then
		for _, loop in effectsSheet.loops do
			if loop.name == "whine" and loop.baseHz then
				self.whineHz = loop.baseHz
			end
		end
		for _, shot in effectsSheet.oneShots do
			if string.sub(shot.name, 1, 8) == "crackle_" then
				table.insert(self.crackleNames, shot.name)
			end
		end
	end
	return self
end

local function event(self, name: string, volume: number, speed: number)
	table.insert(self.events, { name = name, volume = volume, speed = speed })
end

function EngineMix.update(self, dt: number, input)
	local spec = self.spec
	table.clear(self.events)
	local rpm = math.max(input.rpm, 1)
	local interior = spec.interior
	local engineGain = if input.interior then interior.engine else 1
	local loud = spec.engineVolume * engineGain
		* (spec.idleLevel + (1 - spec.idleLevel) * math.clamp(rpm / spec.redlineRpm, 0, 1.1) ^ spec.rpmCurve)

	-- gear changes: an ignition-cut crack on full-throttle upshifts, a clunk on every shift
	local gear = input.gear
	if gear ~= self.lastGear then
		if gear > self.lastGear and self.lastGear >= 1 then
			if self.load > 0.5 and input.load > 0.5 and rpm > spec.shiftCutMinRpm then
				self.upshiftTimer = spec.shiftCutTime
				event(self, "shift_cut", spec.shiftCutVolume * loud, 1)
			end
			event(self, "shift_clunk", spec.shiftClunkVolume * engineGain, 1)
		elseif self.lastGear ~= 0 and gear ~= 0 then
			event(self, "shift_clunk", spec.shiftClunkVolume * 0.7 * engineGain, 0.9)
		end
		self.lastGear = gear
	end
	self.upshiftTimer = math.max(0, self.upshiftTimer - dt)

	-- smoothed engine load
	local target = math.clamp(input.load, 0, 1)
	if self.upshiftTimer > 0 then
		target *= 0.3
	end
	local rate = if target > self.load then spec.loadAttack else spec.loadRelease
	self.load += (target - self.load) * math.clamp(rate * dt, 0, 1)
	local load = self.load

	-- engine loops
	local on = math.sqrt(load)
	local off = math.sqrt(1 - load) * spec.offThrottleLevel
	EngineMix.rpmWeights(self.points, rpm, self.weights)
	for k, w in self.weights do
		local onIndex, offIndex = self.onLoop[k], self.offLoop[k]
		self.engineVolume[onIndex] = loud * w * on
		self.engineSpeed[onIndex] = math.clamp(rpm / self.loopRpm[onIndex], spec.minPitch, spec.maxPitch)
		if offIndex ~= onIndex then
			self.engineVolume[offIndex] = loud * w * off
			self.engineSpeed[offIndex] = math.clamp(rpm / self.loopRpm[offIndex], spec.minPitch, spec.maxPitch)
		end
	end

	-- exhaust crackles after lifting off at high rpm
	if load > 0.6 then
		self.sinceHighLoad = 0
	else
		self.sinceHighLoad += dt
	end
	if self.crackleTime <= 0 and input.load < 0.1 and self.sinceHighLoad < 0.3 and rpm > spec.crackleMinRpm
		and not input.limiter and #self.crackleNames > 0
	then
		self.crackleTime = spec.crackleDuration
	end
	if self.crackleTime > 0 then
		self.crackleTime -= dt
		if input.load > 0.3 then
			self.crackleTime = 0
		end
		local remaining = math.clamp(self.crackleTime / spec.crackleDuration, 0, 1)
		local rpmShare = math.clamp(rpm / 7000, 0.4, 1)
		local chance = spec.crackleRate * remaining * remaining * rpmShare * dt
		if self.random:NextNumber() < chance then
			local name = self.crackleNames[self.random:NextInteger(1, #self.crackleNames)]
			local volume = spec.crackleVolume * engineGain * (0.4 + 0.6 * self.random:NextNumber()) * rpmShare
			event(self, name, volume, 0.85 + 0.35 * self.random:NextNumber())
		end
	end

	-- suspension hitting its bump stops
	self.bumpCooldown = math.max(0, self.bumpCooldown - dt)
	if input.bump > spec.bumpMinSpeed and self.bumpCooldown <= 0 then
		self.bumpCooldown = 0.15
		event(self, "bump_knock", spec.bumpVolume * math.clamp(input.bump / 2, 0.3, 1), 1)
	end

	-- tyres, road, wind and gearbox
	local speed = input.speed
	local fx = self.effects
	local slipOver = input.slip - spec.squealStart
	local squeal = math.clamp(slipOver / spec.squealRange, 0, 1) * math.clamp(input.slideSpeed / 1.5, 0, 1)
	fx.squeal.volume = spec.squealVolume * squeal ^ 1.5 * (if input.interior then interior.squeal else 1)
	fx.squeal.speed = 0.92 + 0.18 * math.clamp(slipOver, 0, 1)

	fx.road.volume = spec.roadVolume * math.clamp(speed / 45, 0, 1) ^ 1.2 * (if input.interior then interior.road else 1)
	fx.road.speed = 0.75 + 0.5 * math.clamp(speed / 80, 0, 1)

	local wind = math.clamp(speed / 95, 0, 1.15)
	fx.wind.volume = spec.windVolume * wind * wind * (if input.interior then interior.wind else 1)
	fx.wind.speed = 0.7 + 0.6 * math.clamp(speed / 95, 0, 1)

	local shaftRpm = math.abs(input.shaftRpm)
	fx.whine.volume = if gear ~= 0
		then spec.whineVolume * engineGain * math.clamp(shaftRpm / 7000, 0, 1) * (0.4 + 0.6 * load)
		else 0
	fx.whine.speed = math.clamp(shaftRpm / 60 * spec.whineTeeth / self.whineHz, 0.2, 3)
end

return EngineMix
