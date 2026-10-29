-- Gun sounds, so each gun sounds like itself: a shot per weapon class
-- (pistol, SMG, rifle, shotgun, sniper, heavy, launcher, energy) built from
-- layers of Roblox's built-in sounds at different pitches, plus reload and
-- bolt/pump clacks, aim-down-sights cloth, the Minigun's spin whine and
-- layered hit feedback (a headshot ding and a heavy kill thump on top of the
-- HUD's hit tick). Every play gets a little pitch and volume variation so
-- fast guns don't sound robotic. Sounds are reused from small pools, one
-- per slot and layer, so a fast gun can never cut off a kill thump.
--
-- BETTER SOUNDS: paste Creator Store audio ids into GunSounds.CUSTOM below
-- (like "rbxassetid://1234567"). A custom id replaces that slot's built-in
-- stand-in layers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GunSounds = {}

GunSounds.VOLUME = 1 -- every gun sound, overall

-- Sounds that ship with Roblox, so they always load
local BOOM = "rbxasset://sounds/impact_explosion_03.mp3"
local THUD = "rbxasset://sounds/action_jump_land.mp3"
local RUSTLE = "rbxasset://sounds/action_get_up.mp3"
local TICK = "rbxasset://sounds/volume_slider.ogg"
local WHOOSH = "rbxasset://sounds/action_jump.mp3"
local WIND = "rbxasset://sounds/action_falling.mp3"
local SPLASH = "rbxasset://sounds/impact_water.mp3"

-- ===================== PASTE CREATOR STORE AUDIO IDS HERE =====================
-- Id = "rbxassetid://..." replaces the built-in layers for that slot.
-- Volume (0-1) and Speed (pitch, 1 = normal) are optional.
GunSounds.CUSTOM = {
	-- Shots
	PistolShot = { Id = "" }, -- Pistol
	RevolverShot = { Id = "" }, -- Revolver
	SMGShot = { Id = "" }, -- SMG, Micro SMG, Tommy Gun
	RifleShot = { Id = "" }, -- Assault Rifle, Marksman Rifle
	ShotgunShot = { Id = "" }, -- Pump Shotgun, Trench Gun
	SniperShot = { Id = "" }, -- Sniper, Bolt Rifle, Long Rifle
	HeavyShot = { Id = "" }, -- Minigun, Heavy Repeater
	CannonShot = { Id = "" }, -- Auto Cannon, Ban Cannon
	LauncherShot = { Id = "" }, -- Rocket Launcher
	ToxicShot = { Id = "" }, -- Toxic Launcher
	EnergyShot = { Id = "" }, -- Plasma Rifle
	PulseShot = { Id = "" }, -- Pulse Rifle
	RailShot = { Id = "" }, -- Railgun
	Explosion = { Id = "" }, -- your rockets and cannon shells landing
	-- Handling
	Equip = { Id = "" }, -- switching guns
	AimIn = { Id = "" }, -- right click to aim down sights
	AimOut = { Id = "" },
	ReloadStart = { Id = "" },
	MagOut = { Id = "" },
	MagIn = { Id = "" },
	Charge = { Id = "" }, -- charging handle / slide release at the end of a reload
	ShellIn = { Id = "" }, -- one shotgun shell or revolver round going in
	CylinderOpen = { Id = "" },
	CylinderClose = { Id = "" },
	BoltUp = { Id = "" },
	BoltBack = { Id = "" },
	BoltForward = { Id = "" },
	PumpBack = { Id = "" },
	PumpForward = { Id = "" },
	DryFire = { Id = "" }, -- trigger pulled while reloading
	ShellTink = { Id = "" }, -- a spent shell hitting the floor
	MinigunSpin = { Id = "" }, -- a LOOP: the barrels spinning
	-- Hit feedback (the HUD already plays its own hit tick)
	HitTick = { Id = "" },
	HeadshotDing = { Id = "" },
	KillConfirm = { Id = "" },
	KillHeadshot = { Id = "" },
}
-- ==============================================================================

-- Config.Sounds.Shot and Config.Sounds.Reload are what the gun played before
-- this module. If either holds a Creator Store id (anything that isn't a
-- built-in rbxasset:// sound), it's still used: Shot for every gun whose shot
-- slot above is empty, Reload for ReloadStart. Set false to ignore them.
GunSounds.USE_CONFIG_SOUNDS = true

-- The built-in stand-ins: each slot is a list of layers { Id, Volume, Speed }.
-- Stop cuts a layer short (seconds), for slices of longer sounds.
GunSounds.BUILTIN = {
	PistolShot = { { BOOM, 0.16, 3.3 }, { THUD, 0.22, 2.5 } },
	RevolverShot = { { BOOM, 0.3, 2.1 }, { BOOM, 0.12, 3.7 }, { THUD, 0.2, 1.5 } },
	SMGShot = { { BOOM, 0.11, 3.9 }, { THUD, 0.1, 3.1 } },
	RifleShot = { { BOOM, 0.15, 3 }, { BOOM, 0.06, 4.5 }, { THUD, 0.08, 2.2 } },
	ShotgunShot = { { BOOM, 0.32, 1.7 }, { BOOM, 0.12, 3.2 }, { THUD, 0.3, 1.1 } },
	SniperShot = { { BOOM, 0.32, 1.9 }, { BOOM, 0.16, 3.8 }, { THUD, 0.25, 0.9 } },
	HeavyShot = { { BOOM, 0.085, 4.2 }, { THUD, 0.07, 2.9 } },
	CannonShot = { { BOOM, 0.32, 1.3 }, { THUD, 0.32, 0.8 } },
	LauncherShot = { { BOOM, 0.22, 0.95 }, { WHOOSH, 0.5, 0.6 }, { THUD, 0.3, 0.7 } },
	ToxicShot = { { SPLASH, 0.35, 1.6 }, { BOOM, 0.1, 1.5 }, { WHOOSH, 0.3, 0.8 } },
	EnergyShot = { { TICK, 0.32, 2.8 }, { SPLASH, 0.1, 3.2 }, { BOOM, 0.05, 4.8 } },
	PulseShot = { { TICK, 0.28, 2.2 }, { TICK, 0.18, 3.3 }, { BOOM, 0.06, 4.2 } },
	RailShot = { { BOOM, 0.32, 1.5 }, { WIND, 0.5, 3.2, Stop = 0.45 }, { TICK, 0.4, 0.7 } },
	Explosion = { { BOOM, 0.55, 0.85 }, { THUD, 0.4, 0.5 } },

	Equip = { { WHOOSH, 0.16, 1.9 }, { THUD, 0.12, 2.7 } },
	AimIn = { { RUSTLE, 0.12, 2.4, Stop = 0.25 } },
	AimOut = { { RUSTLE, 0.07, 2.1, Stop = 0.2 } },
	ReloadStart = { { RUSTLE, 0.35, 1.4 } },
	MagOut = { { THUD, 0.22, 2.7 } },
	MagIn = { { THUD, 0.32, 2.1 }, { TICK, 0.22, 1.3 } },
	Charge = { { THUD, 0.25, 3 }, { TICK, 0.18, 2 } },
	ShellIn = { { THUD, 0.18, 3.2 } },
	CylinderOpen = { { TICK, 0.3, 0.9 } },
	CylinderClose = { { THUD, 0.3, 2.6 }, { TICK, 0.22, 1.1 } },
	BoltUp = { { TICK, 0.22, 1.6 } },
	BoltBack = { { THUD, 0.25, 2.3 } },
	BoltForward = { { THUD, 0.3, 2 }, { TICK, 0.2, 1.4 } },
	PumpBack = { { THUD, 0.3, 1.6 } },
	PumpForward = { { THUD, 0.32, 1.9 }, { TICK, 0.12, 1.2 } },
	DryFire = { { TICK, 0.3, 2 } },
	ShellTink = { { TICK, 0.07, 3.4 } },
	MinigunSpin = { { WIND, 0.3, 2.2 } },

	HitTick = { { TICK, 0.6, 1.6 } },
	HeadshotDing = { { TICK, 0.7, 2.4 }, { TICK, 0.25, 4 } }, -- STYLE's Headshot cue plus a sparkle
	KillConfirm = { { THUD, 0.55, 0.75 }, { BOOM, 0.12, 2.2 } },
	KillHeadshot = { { TICK, 0.45, 3.4 } },
}

-- Which shot slot each gun uses. Guns not listed use "<Class>Shot".
GunSounds.SHOT_BY_ID = {
	Revolver = "RevolverShot",
	AutoCannon = "CannonShot",
	BanCannon = "CannonShot",
	ToxicLauncher = "ToxicShot",
	PulseRifle = "PulseShot",
	Railgun = "RailShot",
}

-- The HUD's hitmarker already plays a hit tick; set true if it stops doing that
GunSounds.PLAY_HIT_TICK = false
-- Set false if the HUD's hitmarker plays STYLE's `Headshot` cue itself
GunSounds.PLAY_HEADSHOT_DING = true

local SHOT_VOICES = 6 -- copies of each shot layer, so quick shots can overlap
local VOICES = 3 -- copies of every other sound
local PITCH_VARIATION = 0.08 -- +-4%
local VOLUME_VARIATION = 0.2 -- +-10%

local folder
local pools = {} -- ["<slot>|<layer>"] = { Sounds, Next, Plays }; a slot never steals another slot's voices
local loop -- the Minigun spin sound

local function getFolder()
	if folder and folder.Parent then
		return folder
	end
	folder = Instance.new("Folder")
	folder.Name = "GunSounds"
	folder.Parent = SoundService
	table.clear(pools)
	loop = nil
	return folder
end

-- The next free copy of one layer of one slot (made the first time it plays)
local function voice(slot, layer, soundId)
	local parent = getFolder()
	local key = slot .. "|" .. layer
	local pool = pools[key]
	if not pool or pool.Id ~= soundId then
		if pool then
			for _, old in pool.Sounds do
				old:Destroy()
			end
		end
		local count = if string.find(slot, "Shot$") then SHOT_VOICES else VOICES
		pool = { Id = soundId, Sounds = {}, Next = 0, Plays = {}, Count = count }
		for index = 1, count do
			local sound = Instance.new("Sound")
			sound.Name = slot .. layer .. "_" .. index
			sound.SoundId = soundId
			sound.Parent = parent
			pool.Sounds[index] = sound
			pool.Plays[index] = 0
		end
		pools[key] = pool
	end
	pool.Next = pool.Next % pool.Count + 1
	pool.Plays[pool.Next] += 1
	return pool.Sounds[pool.Next], pool, pool.Next
end

local function playLayer(slot, layer, soundId, volume, speed, stopAfter)
	local sound, pool, index = voice(slot, layer, soundId)
	sound.Volume = volume * GunSounds.VOLUME * (1 + (math.random() - 0.5) * VOLUME_VARIATION)
	sound.PlaybackSpeed = speed * (1 + (math.random() - 0.5) * PITCH_VARIATION)
	sound.TimePosition = 0
	sound:Play()
	if stopAfter then
		local play = pool.Plays[index]
		task.delay(stopAfter, function()
			-- Only if this voice hasn't been reused since
			if pool.Plays[index] == play then
				sound:Stop()
			end
		end)
	end
end

-- A Config.Sounds entry that holds a Creator Store id, or nil
local function configSound(name)
	local spec = GunSounds.USE_CONFIG_SOUNDS and Config.Sounds and Config.Sounds[name]
	if spec and type(spec.Id) == "string" and spec.Id ~= "" and not string.find(spec.Id, "^rbxasset://") then
		return spec
	end
	return nil
end

-- Plays a slot. volumeScale and speedScale are optional multipliers.
function GunSounds.play(slot, volumeScale, speedScale)
	volumeScale = volumeScale or 1
	speedScale = speedScale or 1
	local custom = GunSounds.CUSTOM[slot]
	if not (custom and custom.Id ~= "") and slot == "ReloadStart" then
		custom = configSound("Reload")
	end
	if custom and custom.Id ~= "" then
		playLayer(slot, "c", custom.Id, (custom.Volume or 0.5) * volumeScale, (custom.Speed or 1) * speedScale)
		return
	end
	for index, layer in GunSounds.BUILTIN[slot] or {} do
		playLayer(slot, index, layer[1], layer[2] * volumeScale, layer[3] * speedScale, layer.Stop)
	end
end

-- The shot sound for a weapon
function GunSounds.shot(weapon, class)
	local slot = GunSounds.SHOT_BY_ID[weapon.Id] or (class .. "Shot")
	local custom = GunSounds.CUSTOM[slot]
	local fromConfig = configSound("Shot")
	if fromConfig and not (custom and custom.Id ~= "") then
		-- The id pasted into Config.Sounds.Shot before this module existed
		playLayer(slot, "c", fromConfig.Id, fromConfig.Volume or 0.5, fromConfig.Speed or 1)
		return
	end
	GunSounds.play(slot)
end

-- The Minigun's spinning barrels: amount 0 (still) to 1 (full speed)
function GunSounds.setSpin(amount)
	if amount <= 0.01 then
		if loop and loop.IsPlaying then
			loop:Stop()
		end
		return
	end
	if not loop or loop.Parent ~= getFolder() then
		local custom = GunSounds.CUSTOM.MinigunSpin
		local layer = GunSounds.BUILTIN.MinigunSpin[1]
		loop = Instance.new("Sound")
		loop.Name = "MinigunSpin"
		loop.Looped = true
		loop.SoundId = if custom.Id ~= "" then custom.Id else layer[1]
		loop:SetAttribute("BaseVolume", if custom.Id ~= "" then custom.Volume or 0.4 else layer[2])
		loop:SetAttribute("BaseSpeed", if custom.Id ~= "" then custom.Speed or 1 else layer[3])
		loop.Parent = getFolder()
	end
	loop.Volume = loop:GetAttribute("BaseVolume") * amount * GunSounds.VOLUME
	loop.PlaybackSpeed = loop:GetAttribute("BaseSpeed") * (0.45 + 0.55 * amount)
	if not loop.IsPlaying then
		loop:Play()
	end
end

return GunSounds
