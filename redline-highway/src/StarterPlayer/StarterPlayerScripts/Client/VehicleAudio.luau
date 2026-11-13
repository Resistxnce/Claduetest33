--[[
	VehicleAudio: plays the player's car sounds.

	Each sound layer is a Sound that plays one region of a sound pack (a packed sound file, see
	docs/AUDIO.md): PlaybackRegion bounds it and LoopRegion loops it. Every frame, after the
	simulation step, EngineMix works out each layer's volume and playback speed from the car's
	state: engine loops, the limiter loops, turbo whistle or supercharger whine. One-shots (shift
	cracks, exhaust crackles, suspension knocks, turbo blow-off) play on small pools of Sounds.

	The player's own car plays non-positionally (the Sounds live in SoundService), the way a driver
	hears their own car. The cockpit camera switches on an equaliser that muffles the cabin, and
	AudioEnvironment adds tunnel reverb when the camera is inside a tunnel. Traffic has its own
	positional sound (TrafficAudio).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local AudioFolder = VehicleSystem:WaitForChild("VehicleAudio")
local AudioAssets = require(AudioFolder:WaitForChild("AudioAssets"))
local EngineMix = require(AudioFolder:WaitForChild("EngineMix"))
local Engine = require(VehicleSystem:WaitForChild("EngineSimulation"):WaitForChild("Engine"))
local VehicleSimulation = require(VehicleSystem:WaitForChild("CorePhysics"):WaitForChild("VehicleSimulation"))
local AudioEnvironment = require(script.Parent:WaitForChild("AudioEnvironment"))

local ONE_SHOT_VOICES = 6
local ENGINE_SHOT_VOICES = 2
local RPM_PER_RAD_S = 30 / math.pi

local VehicleAudio = {}
VehicleAudio.__index = VehicleAudio

local warned = {}

local function assetId(sheet): string?
	local id = AudioAssets[sheet.asset]
	if type(id) ~= "string" or id == "" then
		if not warned[sheet.asset] then
			warned[sheet.asset] = true
			warn(string.format(
				"[Redline] No sound asset ID for %s, so those sounds are off. Upload assets/audio/%s.flac and "
					.. "paste its ID into ReplicatedStorage.VehicleSystem.VehicleAudio.AudioAssets (see docs/AUDIO.md).",
				sheet.asset,
				sheet.asset
			))
		end
		return nil
	end
	return id
end

local function newSound(name: string, id: string, region, looped: boolean, group: SoundGroup, parent: Instance): Sound
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = looped
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(region.start, region.stop)
	if looped then
		sound.LoopRegion = NumberRange.new(region.loopStart, region.loopEnd)
	end
	sound.Volume = 0
	sound.SoundGroup = group
	sound.Parent = parent
	return sound
end

-- controller: a running VehicleController. cameraMode: returns the camera mode's name.
function VehicleAudio.start(controller, cameraMode: () -> string)
	local config = controller.config
	local spec = config.audio
	if not spec then
		return nil
	end
	local sheets = AudioFolder:WaitForChild("Sheets")
	local engineSheet = require(sheets:WaitForChild(spec.engineSheet))
	local effectsSheet = require(sheets:WaitForChild(spec.effectsSheet))
	local engineId = assetId(engineSheet)
	local effectsId = assetId(effectsSheet)
	if not engineId and not effectsId then
		return nil
	end

	local self = setmetatable({}, VehicleAudio)
	self.controller = controller
	self.config = config
	self.spec = spec
	self.cameraMode = cameraMode
	self.mix = EngineMix.new(spec, engineSheet, if effectsId then effectsSheet else nil)
	self.inputs = {
		rpm = 0,
		load = 0,
		pedal = 0,
		clutch = 1,
		gear = 0,
		shifting = false,
		limiter = false,
		boost = 0,
		speed = 0,
		slip = 0,
		slideSpeed = 0,
		shaftRpm = 0,
		bump = 0,
		interior = false,
	}
	self.interior = false
	self.checkTimer = 0

	self.group = Instance.new("SoundGroup")
	self.group.Name = "VehicleAudio"
	self.group.Volume = 1
	self.equalizer = Instance.new("EqualizerSoundEffect")
	self.equalizer.LowGain = 0
	self.equalizer.MidGain = 0
	self.equalizer.HighGain = 0
	self.equalizer.Parent = self.group
	self.group.Parent = SoundService
	self.folder = Instance.new("Folder")
	self.folder.Name = "VehicleAudioSounds"
	self.folder.Parent = SoundService

	self.engineSounds = {}
	-- one-shot pools: the effects sheet (crackles, shifts, knocks) and the engine sheet (blow-off)
	self.pools = {
		effects = { shots = {}, voices = {}, next = 1 },
		engine = { shots = {}, voices = {}, next = 1 },
	}
	if engineId then
		for i, loop in engineSheet.loops do
			self.engineSounds[i] = newSound(loop.name, engineId, loop, true, self.group, self.folder)
		end
		local shots = engineSheet.oneShots or {}
		for _, shot in shots do
			self.pools.engine.shots[shot.name] = shot
		end
		if #shots > 0 then
			for v = 1, ENGINE_SHOT_VOICES do
				self.pools.engine.voices[v] = newSound("EngineShot" .. v, engineId, shots[1], false, self.group, self.folder)
			end
		end
	end
	self.effectSounds = {}
	if effectsId then
		local wanted = {}
		for _, name in EngineMix.EFFECT_LOOPS do
			wanted[name] = true
		end
		for _, loop in effectsSheet.loops do
			if wanted[loop.name] then
				self.effectSounds[loop.name] = newSound(loop.name, effectsId, loop, true, self.group, self.folder)
			end
		end
		for _, shot in effectsSheet.oneShots do
			self.pools.effects.shots[shot.name] = shot
		end
		for v = 1, ONE_SHOT_VOICES do
			self.pools.effects.voices[v] = newSound("OneShot" .. v, effectsId, effectsSheet.oneShots[1], false, self.group, self.folder)
		end
	end
	AudioEnvironment.attach(self.group)
	for _, child in self.folder:GetChildren() do
		if child:IsA("Sound") and child.Looped then
			child:Play()
		end
	end

	self.connection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)
	return self
end

function VehicleAudio:update(dt: number)
	local controller = self.controller
	if controller.stopped then
		self:stop()
		return
	end
	local sim = controller.sim
	local t = sim.telemetry
	if t.rpm == nil then
		return -- the simulation hasn't run a step yet
	end

	local input = self.inputs
	input.rpm = t.rpm
	-- Load: torque as a share of full-throttle torque, or the throttle opening if that is more, so a
	-- turbo car still off boost counts as on throttle. A fuel cut or closed throttle reads as off.
	local torqueShare = t.engineTorque / math.max(Engine.curveTorque(self.config.engine, t.rpm), 1)
	input.load = math.clamp(math.max(torqueShare, t.throttle or 0), 0, 1)
	input.pedal = t.pedal or 0
	input.clutch = t.clutch or 1
	input.gear = t.gearNumber
	input.shifting = t.shifting
	input.limiter = t.limiter
	input.boost = t.boost or 0
	input.speed = t.speedKmh / 3.6

	local slip, slide, bump, shaft, driven = 0, 0, 0, 0, 0
	for _, id in VehicleSimulation.WHEEL_IDS do
		local w = sim.wheels[id]
		if w.contact then
			local sx = w.slipRatio / w.tire.compound.peakSlipRatio
			local sy = w.slipAngle / w.tire.peakSlipAngle
			slip = math.max(slip, math.sqrt(sx * sx + sy * sy))
			local slideLong = w.omega * w.tire.radius - w.vLong
			slide = math.max(slide, math.sqrt(slideLong * slideLong + w.vLat * w.vLat))
			if w.length <= w.suspension.minLength + 0.002 then
				bump = math.max(bump, -w.lengthVelocity)
			end
		end
		if w.driven then
			shaft += w.omega
			driven += 1
		end
	end
	input.slip = slip
	input.slideSpeed = slide
	input.bump = bump
	input.shaftRpm = if driven > 0
		then shaft / driven * self.config.transmission.finalDrive * RPM_PER_RAD_S
		else 0

	local interior = self.cameraMode() == "Cockpit"
	input.interior = interior
	if interior ~= self.interior then
		self.interior = interior
		local cabin = self.spec.interior
		self.equalizer.LowGain = if interior then cabin.lowGain else 0
		self.equalizer.MidGain = if interior then cabin.midGain else 0
		self.equalizer.HighGain = if interior then cabin.highGain else 0
	end

	local mix = self.mix
	EngineMix.update(mix, dt, input)
	for i, sound in self.engineSounds do
		sound.Volume = mix.engineVolume[i]
		sound.PlaybackSpeed = mix.engineSpeed[i]
	end
	for name, sound in self.effectSounds do
		local layer = mix.effects[name]
		if layer then
			sound.Volume = layer.volume
			sound.PlaybackSpeed = layer.speed
		end
	end
	for _, e in mix.events do
		self:playOneShot(e.sheet, e.name, e.volume, e.speed)
	end

	-- start any loop that wasn't playing yet (for example, its sound was still loading)
	self.checkTimer -= dt
	if self.checkTimer <= 0 then
		self.checkTimer = 1
		for _, child in self.folder:GetChildren() do
			if child:IsA("Sound") and child.Looped and child.IsLoaded and not child.IsPlaying then
				child:Play()
			end
		end
	end
end

function VehicleAudio:playOneShot(sheet: string, name: string, volume: number, speed: number)
	local pool = self.pools[sheet]
	local shot = pool and pool.shots[name]
	if not shot or #pool.voices == 0 then
		return
	end
	local voice = pool.voices[pool.next]
	pool.next = pool.next % #pool.voices + 1
	voice:Stop()
	voice.PlaybackRegion = NumberRange.new(shot.start, shot.stop)
	voice.TimePosition = shot.start
	voice.Volume = volume
	voice.PlaybackSpeed = speed
	voice:Play()
end

function VehicleAudio:stop()
	if self.stopped then
		return
	end
	self.stopped = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	AudioEnvironment.detach(self.group)
	self.folder:Destroy()
	self.group:Destroy()
end

return VehicleAudio
