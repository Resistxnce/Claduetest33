--[[
	EngineMix: turns the car's state into a volume and playback speed for every sound layer, plus
	the one-shot sounds to start this frame. Pure maths with no Roblox objects, so it can be checked
	outside the game: tools/audio_preview.py is a line-for-line Python copy that renders what a drive
	sounds like. Keep the two in step.

	The engine sheet (VehicleAudio/Sheets, made by tools/synth_audio.py from the car's acoustic
	definition in assets/audio/engines) holds:
	  * pairs of loops, on and off throttle, made at several steady engine speeds. Each frame the two
	    speeds either side of the current rpm are crossfaded with equal power in log-rpm (even in
	    pitch), each loop is pitched by rpm / its own rpm, and on and off are crossfaded by engine
	    load, smoothed so it doesn't flutter. Each loop carries a gain worked out from the real
	    car's measured sound levels, so loudness follows rpm and load;
	  * two limiter loops with the car's cut pattern baked in, one free-revving and one in gear.
	    While the engine is on the limiter the mix switches to them with a fast attack, so hitting
	    the limiter is unmistakable;
	  * forced-induction layers: a turbo whistle pitched by boost plus blow-off one-shots when the
	    throttle shuts on boost, or supercharger whine loops pitched by rpm and raised by boost.
	Upshifts at high load add an ignition-cut "crack"; lifting off at high rpm sets off exhaust
	crackles for a moment.

	Inputs each frame:
	  rpm, load (0-1), pedal (0-1), clutch (0-1 engagement), gear, shifting (bool), limiter (bool:
	  the fuel cut is active), boost (0-1), speed (m/s), slip (largest combined tyre slip, 1 = at the
	  grip peak), slideSpeed (fastest tyre sliding speed, m/s), shaftRpm (driveshaft), bump (bump-stop
	  impact speed, m/s), interior (bool, cockpit camera)
	Events: { name, volume, speed, sheet } where sheet is "engine" or "effects".
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
		points = {}, -- engine speeds of the on/off loop pairs, ascending
		onLoop = {}, -- index into engineSheet.loops of the on-throttle loop at each point
		offLoop = {},
		loopRpm = {}, -- engine speed each loop was made at
		loopGain = {}, -- playback gain of each loop (from the car's measured sound levels)
		hasGains = false,
		engineVolume = {}, -- per engine-sheet loop, indexed like engineSheet.loops
		engineSpeed = {},
		limiterFree = nil, -- index of the free-revving limiter loop
		limiterLoad = nil, -- and of the in-gear one
		turboLoop = nil,
		turboBaseHz = 1,
		turboMinHz = 1,
		turboMaxHz = 1,
		blowOffNames = {},
		whineLoops = {}, -- supercharger whine loops, ascending rpm
		whineRpm = {},
		whineBaseHz = {},
		whineWeights = {},
		whineHzPerRpm = 0, -- rotor pulses per second per crank rpm
		effects = {}, -- per effect loop name: { volume, speed }
		events = {}, -- one-shots to start this frame: { name, volume, speed, sheet }
		weights = {},
		load = 0,
		lastGear = 0,
		upshiftTimer = 0,
		sinceHighLoad = math.huge,
		crackleTime = 0,
		bumpCooldown = 0,
		crackleNames = {},
		whineHz = 1000,
		limiterSeen = math.huge, -- seconds since the fuel cut was last active
		limiterMix = 0, -- 0 = normal loops, 1 = limiter loops
		freeMix = 0, -- 0 = in-gear limiter loop, 1 = free-revving one
		limiterRpm = 0, -- smoothed rpm while on the limiter
		limiterRpmSheet = engineSheet.limiterRpm or math.huge, -- where the car's limiter is
		pedalPeak = 0,
		boostPeak = 0,
		blowOffCooldown = 0,
		random = random or Random.new(),
	}

	local byRpm = {}
	for i, loop in engineSheet.loops do
		self.loopRpm[i] = loop.rpm or 0
		self.loopGain[i] = loop.gain or 1
		self.hasGains = self.hasGains or loop.gain ~= nil
		self.engineVolume[i] = 0
		self.engineSpeed[i] = 1
		if loop.load == "on" or loop.load == "off" then
			local key = math.floor(loop.rpm + 0.5)
			local pair = byRpm[key]
			if not pair then
				pair = { rpm = loop.rpm }
				byRpm[key] = pair
				table.insert(self.points, pair)
			end
			pair[loop.load] = i
		elseif loop.load == "limiter" then
			if loop.kind == "free" then
				self.limiterFree = i
			else
				self.limiterLoad = i
			end
		elseif loop.layer == "turbo" then
			self.turboLoop = i
			self.turboBaseHz = loop.baseHz
		elseif loop.layer == "supercharger" then
			table.insert(self.whineLoops, i)
		end
	end
	table.sort(self.points, function(a, b)
		return a.rpm < b.rpm
	end)
	for k, pair in self.points do
		self.onLoop[k] = pair.on or pair.off
		self.offLoop[k] = pair.off or pair.on
		self.points[k] = pair.rpm
	end
	self.limiterFree = self.limiterFree or self.limiterLoad
	self.limiterLoad = self.limiterLoad or self.limiterFree
	if engineSheet.turbo then
		self.turboMinHz = engineSheet.turbo.minHz
		self.turboMaxHz = engineSheet.turbo.maxHz
	end
	for _, shot in engineSheet.oneShots or {} do
		if shot.layer == "blowoff" then
			table.insert(self.blowOffNames, shot.name)
		end
	end
	table.sort(self.whineLoops, function(a, b)
		return engineSheet.loops[a].rpm < engineSheet.loops[b].rpm
	end)
	for k, index in self.whineLoops do
		self.whineRpm[k] = engineSheet.loops[index].rpm
		self.whineBaseHz[k] = engineSheet.loops[index].baseHz
		self.whineWeights[k] = 0
	end
	if engineSheet.supercharger then
		self.whineHzPerRpm = engineSheet.supercharger.driveRatio * engineSheet.supercharger.pulsesPerRev / 60
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

local function event(self, name: string, volume: number, speed: number, sheet: string?)
	table.insert(self.events, { name = name, volume = volume, speed = speed, sheet = sheet or "effects" })
end

function EngineMix.update(self, dt: number, input)
	local spec = self.spec
	table.clear(self.events)
	local rpm = math.max(input.rpm, 1)
	local interior = spec.interior
	local engineGain = if input.interior then interior.engine else 1
	-- Sheets made from an acoustic definition carry per-loop gains for the loudness curve; older
	-- sheets without them use the configured curve.
	local loud = if self.hasGains
		then spec.engineVolume * engineGain
		else spec.engineVolume * engineGain
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

	-- the rev limiter: switch to the limiter loops while the fuel cut keeps coming back with the
	-- pedal down (a fast attack so the first cut is heard), and back when it stops
	if input.limiter then
		self.limiterSeen = 0
	else
		self.limiterSeen += dt
	end
	local nearLimit = rpm > 0.92 * self.limiterRpmSheet -- an upshift off the limiter releases it at once
	local limiterTarget = if self.limiterFree and self.limiterSeen < spec.limiterHold and input.pedal > 0.5 and nearLimit
		then 1
		else 0
	local limiterRate = if limiterTarget > self.limiterMix then spec.limiterAttack else spec.limiterRelease
	self.limiterMix += (limiterTarget - self.limiterMix) * math.clamp(limiterRate * dt, 0, 1)
	local freeTarget = if input.gear == 0 or input.clutch < 0.5 then 1 else 0
	self.freeMix += (freeTarget - self.freeMix) * math.clamp(8 * dt, 0, 1)
	self.limiterRpm += (rpm - self.limiterRpm) * math.clamp(3 * dt, 0, 1)
	local keep = 1 - self.limiterMix

	-- engine loops
	local on = math.sqrt(load)
	local off = math.sqrt(1 - load) * (if self.hasGains then 1 else spec.offThrottleLevel)
	EngineMix.rpmWeights(self.points, rpm, self.weights)
	for k, w in self.weights do
		local onIndex, offIndex = self.onLoop[k], self.offLoop[k]
		self.engineVolume[onIndex] = loud * w * on * keep * self.loopGain[onIndex]
		self.engineSpeed[onIndex] = math.clamp(rpm / self.loopRpm[onIndex], spec.minPitch, spec.maxPitch)
		if offIndex ~= onIndex then
			self.engineVolume[offIndex] = loud * w * off * keep * self.loopGain[offIndex]
			self.engineSpeed[offIndex] = math.clamp(rpm / self.loopRpm[offIndex], spec.minPitch, spec.maxPitch)
		end
	end
	if self.limiterFree then
		local free, inGear = self.limiterFree, self.limiterLoad
		local mix = self.limiterMix
		if free == inGear then
			self.engineVolume[free] = loud * mix * self.loopGain[free]
		else
			self.engineVolume[free] = loud * mix * math.sqrt(self.freeMix) * self.loopGain[free]
			self.engineVolume[inGear] = loud * mix * math.sqrt(1 - self.freeMix) * self.loopGain[inGear]
			self.engineSpeed[inGear] = math.clamp(self.limiterRpm / self.loopRpm[inGear], 0.97, 1.03)
		end
		self.engineSpeed[free] = math.clamp(self.limiterRpm / self.loopRpm[free], 0.97, 1.03)
	end

	-- forced induction: turbo whistle pitched by boost (shaft speed rises about as the square root
	-- of boost pressure), blow-off when the throttle shuts on boost, supercharger whine by rpm
	local boost = math.clamp(input.boost, 0, 1)
	if self.turboLoop then
		local hz = self.turboMinHz + (self.turboMaxHz - self.turboMinHz) * math.sqrt(boost)
		self.engineVolume[self.turboLoop] = spec.turboVolume * engineGain * boost ^ 1.2 * (0.35 + 0.65 * load)
		self.engineSpeed[self.turboLoop] = math.clamp(hz / self.turboBaseHz, 0.3, 3)
	end
	self.pedalPeak = math.max(input.pedal, self.pedalPeak - 3 * dt)
	self.boostPeak = math.max(boost, self.boostPeak - 2 * dt)
	self.blowOffCooldown = math.max(0, self.blowOffCooldown - dt)
	if #self.blowOffNames > 0 and input.pedal < 0.2 and self.pedalPeak > 0.6
		and self.boostPeak > spec.blowOffMinBoost and self.blowOffCooldown <= 0
	then
		self.blowOffCooldown = 1
		self.pedalPeak = 0
		local name = self.blowOffNames[self.random:NextInteger(1, #self.blowOffNames)]
		event(self, name, spec.blowOffVolume * engineGain * self.boostPeak, 0.95 + 0.1 * self.random:NextNumber(), "engine")
	end
	if #self.whineLoops > 0 then
		EngineMix.rpmWeights(self.whineRpm, rpm, self.whineWeights)
		-- optional shape settings (the defaults give the original shape): the share of the whine left
		-- with no boost, the engine speed where it reaches full level, and the share left at low rpm
		local idleShare = spec.superchargerIdleShare or 0.2
		local fullRpm = spec.superchargerFullRpm or 2500
		local rpmFloor = spec.superchargerRpmFloor or 0.3
		local level = spec.superchargerVolume * engineGain * (idleShare + (1 - idleShare) * boost)
			* math.clamp(rpm / fullRpm, rpmFloor, 1)
		for k, index in self.whineLoops do
			self.engineVolume[index] = level * self.whineWeights[k]
			self.engineSpeed[index] = math.clamp(rpm * self.whineHzPerRpm / self.whineBaseHz[k], 0.25, 4)
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
