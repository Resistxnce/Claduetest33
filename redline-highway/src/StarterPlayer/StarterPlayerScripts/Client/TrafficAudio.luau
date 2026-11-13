--[[
	TrafficAudio: positional engine and tyre sound for the traffic nearest the camera.

	The nearest cars (up to VOICES.car) and trucks (up to VOICES.truck) each get a voice: an
	Attachment in Workspace.Terrain that follows the car, carrying looping Sounds (engine on and off
	throttle from the traffic engine sheets, and tyre roar from the effects sheet). Roblox places
	the Sounds in 3D and applies distance roll-off. Every frame TrafficMix adds engine speed from
	road speed, Doppler from the relative speed of car and camera, and air absorption (a treble cut
	growing with distance) through an equaliser on each Sound. Voices fade between cars as the
	nearest set changes. The group gets tunnel reverb from AudioEnvironment.

	Doppler is applied here, so SoundService.DopplerScale is set to 0 (Roblox would otherwise add
	its own shift from the parts' and listener's motion, which for these anchored parts is wrong).

	Traffic cars come from TrafficRenderer.cars(): id -> { s, lanePos, v, profileIndex, body }. A car
	is gone when its id leaves that table or its body is no longer in the Workspace.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local AudioFolder = ReplicatedStorage:WaitForChild("VehicleSystem"):WaitForChild("VehicleAudio")
local AudioAssets = require(AudioFolder:WaitForChild("AudioAssets"))
local TrafficMix = require(AudioFolder:WaitForChild("TrafficMix"))
local DriverProfiles = require(ReplicatedStorage:WaitForChild("TrafficSystem"):WaitForChild("DriverProfiles"))
local AudioEnvironment = require(script.Parent:WaitForChild("AudioEnvironment"))

local METERS_PER_STUD = 0.28
local VOICES = { car = 5, truck = 2 }
local SHEETS = { car = "TrafficCar_Engine", truck = "TrafficTruck_Engine" }
local MAX_DISTANCE_M = 320
local FADE_RATE = 6 -- 1/s

local TrafficAudio = {}

local renderer
local group: SoundGroup
local voices = {}
local listenerVel = Vector3.zero
local lastListener: Vector3? = nil
local checkTimer = 0

local function newLoop(name: string, id: string, region, parent: Instance): (Sound, EqualizerSoundEffect)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Looped = true
	sound.PlaybackRegionsEnabled = true
	sound.PlaybackRegion = NumberRange.new(region.start, region.stop)
	sound.LoopRegion = NumberRange.new(region.loopStart, region.loopEnd)
	sound.Volume = 0
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = TrafficMix.ROLLOFF_MIN_M / METERS_PER_STUD
	sound.RollOffMaxDistance = TrafficMix.ROLLOFF_MAX_M / METERS_PER_STUD
	sound.SoundGroup = group
	local eq = Instance.new("EqualizerSoundEffect")
	eq.Name = "AirAbsorption"
	eq.LowGain = 0
	eq.MidGain = 0
	eq.HighGain = 0
	eq.Parent = sound
	sound.Parent = parent
	return sound, eq
end

-- The on- and off-throttle loops at the sheet's engine speed nearest the middle of its range.
local function pickLoops(sheet)
	local best, bestOn, bestOff = math.huge, nil, nil
	local byRpm = {}
	for _, loop in sheet.loops do
		if loop.load == "on" or loop.load == "off" then
			local key = math.floor(loop.rpm + 0.5)
			byRpm[key] = byRpm[key] or {}
			byRpm[key][loop.load] = loop
		end
	end
	local mid = (sheet.idleRpm or 800) * 2.5
	for key, pair in byRpm do
		local d = math.abs(math.log(key / mid))
		if d < best and pair.on then
			best, bestOn, bestOff = d, pair.on, pair.off or pair.on
		end
	end
	return bestOn, bestOff
end

local function makeVoice(kind: string, engineSheet, engineId: string, tyreRegion, effectsId: string, index: number)
	local attachment = Instance.new("Attachment")
	attachment.Name = string.format("TrafficVoice_%s%d", kind, index)
	attachment.Parent = Workspace.Terrain
	local onLoop, offLoop = pickLoops(engineSheet)
	local voice = {
		kind = kind,
		profile = TrafficMix.PROFILES[kind],
		attachment = attachment,
		carId = nil,
		fade = 0,
		target = 0,
		lastV = nil,
		accel = 0,
		load = 0.3,
		onRpm = onLoop.rpm,
		offRpm = offLoop.rpm,
		onGain = onLoop.gain or 1,
		offGain = offLoop.gain or 1,
	}
	local onEq, offEq, tyreEq
	voice.on, onEq = newLoop("EngineOn", engineId, onLoop, attachment)
	voice.off, offEq = newLoop("EngineOff", engineId, offLoop, attachment)
	voice.tyre, tyreEq = newLoop("Tyres", effectsId, tyreRegion, attachment)
	voice.sounds = { voice.on, voice.off, voice.tyre }
	voice.eqs = { onEq, offEq, tyreEq }
	return voice
end

local function silence(voice)
	for _, sound in voice.sounds do
		sound.Volume = 0
	end
end

local function kindOf(car): string
	return if DriverProfiles.order[car.profileIndex] == "truck" then "truck" else "car"
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera or dt <= 0 then
		return
	end
	local listener = camera.CFrame.Position
	if lastListener then
		local step = (listener - lastListener) * METERS_PER_STUD
		if step.Magnitude < 40 then -- ignore camera cuts
			listenerVel = listenerVel:Lerp(step / dt, math.clamp(8 * dt, 0, 1))
		end
	end
	lastListener = listener

	-- the nearest cars of each kind
	local cars = renderer.cars()
	local nearest = { car = {}, truck = {} }
	for id, car in cars do
		local body = car.body
		if body and body:IsDescendantOf(Workspace) then
			local d = (body.Position - listener).Magnitude * METERS_PER_STUD
			if d < MAX_DISTANCE_M then
				local list = nearest[kindOf(car)]
				table.insert(list, { id = id, d = d })
			end
		end
	end
	local wanted = {}
	for kind, list in nearest do
		table.sort(list, function(a, b)
			return a.d < b.d
		end)
		for i = 1, math.min(#list, VOICES[kind]) do
			wanted[list[i].id] = kind
		end
	end

	-- keep voices on cars that are still near, fade out the others, give free voices to new cars
	local served = {}
	for _, voice in voices do
		if voice.carId and wanted[voice.carId] == voice.kind and cars[voice.carId] then
			voice.target = 1
			served[voice.carId] = true
		else
			voice.target = 0
		end
	end
	for id, kind in wanted do
		if not served[id] then
			for _, voice in voices do
				if voice.kind == kind and (voice.carId == nil or (voice.target == 0 and voice.fade <= 0.01)) then
					voice.carId = id
					voice.target = 1
					voice.fade = 0
					voice.lastV = nil
					served[id] = true
					break
				end
			end
		end
	end

	for _, voice in voices do
		voice.fade += (voice.target - voice.fade) * math.clamp(FADE_RATE * dt, 0, 1)
		local car = voice.carId and cars[voice.carId]
		if not car or not car.body or not car.body:IsDescendantOf(Workspace) then
			voice.carId = nil
			voice.fade = 0
			silence(voice)
			continue
		end
		if voice.target == 0 and voice.fade < 0.01 then
			voice.carId = nil
			silence(voice)
			continue
		end
		local body = car.body
		local position = body.Position
		voice.attachment.WorldPosition = position
		local v = car.v
		local accel = if voice.lastV then (v - voice.lastV) / dt else 0
		voice.lastV = v
		voice.accel += (math.clamp(accel, -8, 8) - voice.accel) * math.clamp(3 * dt, 0, 1)
		voice.load += (TrafficMix.load(voice.accel) - voice.load) * math.clamp(4 * dt, 0, 1)
		local profile = voice.profile
		local rpm = TrafficMix.engineRpm(profile, v, voice.load)
		local offset = (position - listener) * METERS_PER_STUD
		local doppler = TrafficMix.doppler(offset, body.CFrame.LookVector * v, listenerVel)
		local engine, tyre = TrafficMix.levels(profile, v, voice.load, rpm)
		local mid, high = TrafficMix.airAbsorption(offset.Magnitude)
		voice.on.Volume = voice.fade * engine * math.sqrt(voice.load) * voice.onGain
		voice.off.Volume = voice.fade * engine * math.sqrt(1 - voice.load) * voice.offGain
		voice.on.PlaybackSpeed = math.clamp(rpm / voice.onRpm, 0.4, 2.5) * doppler
		voice.off.PlaybackSpeed = math.clamp(rpm / voice.offRpm, 0.4, 2.5) * doppler
		voice.tyre.Volume = voice.fade * tyre
		voice.tyre.PlaybackSpeed = (0.8 + 0.4 * math.clamp(v / 40, 0, 1)) * doppler
		for _, eq in voice.eqs do
			eq.MidGain = mid
			eq.HighGain = high
		end
	end

	-- start any loop that wasn't playing yet (its sound may still have been loading)
	checkTimer -= dt
	if checkTimer <= 0 then
		checkTimer = 1
		for _, voice in voices do
			for _, sound in voice.sounds do
				if sound.IsLoaded and not sound.IsPlaying then
					sound:Play()
				end
			end
		end
	end
end

-- trafficRenderer: the TrafficRenderer module.
function TrafficAudio.init(trafficRenderer)
	renderer = trafficRenderer
	local effectsId = AudioAssets.Driving_Effects
	if type(effectsId) ~= "string" or effectsId == "" then
		return -- VehicleAudio already reminds about the missing upload
	end
	local sheets = AudioFolder:WaitForChild("Sheets")
	local effects = require(sheets:WaitForChild("Driving_Effects"))
	local tyreRegion = nil
	for _, loop in effects.loops do
		if loop.name == "tyre_roll" then
			tyreRegion = loop
		end
	end
	if not tyreRegion then
		return
	end
	SoundService.DopplerScale = 0
	group = Instance.new("SoundGroup")
	group.Name = "TrafficAudio"
	group.Volume = 1
	group.Parent = SoundService
	AudioEnvironment.attach(group)
	for kind, count in VOICES do
		local module = sheets:FindFirstChild(SHEETS[kind])
		if module and module:IsA("ModuleScript") then
			local sheet = require(module)
			local id = AudioAssets[sheet.asset]
			if type(id) == "string" and id ~= "" then
				for i = 1, count do
					table.insert(voices, makeVoice(kind, sheet, id, tyreRegion, effectsId, i))
				end
			end
		end
	end
	for _, voice in voices do
		for _, sound in voice.sounds do
			sound:Play()
		end
	end
	RunService.Heartbeat:Connect(update)
end

return TrafficAudio
