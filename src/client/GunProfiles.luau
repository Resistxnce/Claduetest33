-- How each gun feels. Every gun has a class (Pistol, SMG, Rifle, Shotgun,
-- Sniper, Heavy, Launcher or Energy) that sets how hard its recoil kicks,
-- how it aims down sights, its muzzle flash and the shells it throws out;
-- BY_ID tweaks single guns. It also reads each gun's part names in
-- GunModels to find its sights, its magazine and the parts that move when it
-- cycles (bolt, pump, slide, charging handle). Like Config is for balance,
-- every number here is a feel knob: tweak freely.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GunModels = require(Shared:WaitForChild("GunModels"))
local GunEffects = require(Shared:WaitForChild("GunEffects"))

local GunProfiles = {}

local PALETTE = GunEffects.PALETTE

-- Per class:
--   Kick      camera kick per shot, times the gun's Config Recoil (degrees)
--   Recover   how much of each kick drifts back (0-1). Automatics keep some, so they climb
--   Drift     how much the kick wanders sideways
--   Shake     extra camera shake per shot (degrees), Punch a field-of-view punch
--   ViewKick  first-person gun kick: Back (studs), Pitch and Roll (degrees) at Ref recoil
--   Aim       aiming down sights with right click: Time to raise (seconds), Fov scale,
--             Spread scale, Distance from your eye to the rear sight. false = can't
--   Flash     muzzle flash Size and Color (warm by default, see STYLE section 6)
--   Shell     what flies out when it fires: "Brass", "Shell", "Big" or false
--   Tracer    "Bullet", "Pellet", "Sniper", "Energy" or "Rail"
GunProfiles.CLASSES = {
	Pistol = {
		Kick = 1, Recover = 0.8, Drift = 0.3, Shake = 0, Punch = 0,
		ViewKick = { Back = 0.07, Pitch = 3.5, Roll = 1.5, Ref = 1.2 },
		Aim = { Time = 0.12, Fov = 0.86, Spread = 0.7, Distance = 1.25 },
		Flash = { Size = 0.8, Color = PALETTE.Flash }, Shell = "Brass", Tracer = "Bullet",
	},
	SMG = {
		Kick = 0.7, Recover = 0.5, Drift = 0.5, Shake = 0, Punch = 0,
		ViewKick = { Back = 0.045, Pitch = 2, Roll = 2, Ref = 0.55 },
		Aim = { Time = 0.13, Fov = 0.86, Spread = 0.75, Distance = 1.1 },
		Flash = { Size = 0.7, Color = PALETTE.Flash }, Shell = "Brass", Tracer = "Bullet",
	},
	Rifle = {
		Kick = 0.8, Recover = 0.55, Drift = 0.35, Shake = 0, Punch = 0,
		ViewKick = { Back = 0.055, Pitch = 2.4, Roll = 1.5, Ref = 0.8 },
		Aim = { Time = 0.16, Fov = 0.84, Spread = 0.7, Distance = 1.15 },
		Flash = { Size = 0.95, Color = PALETTE.Flash }, Shell = "Brass", Tracer = "Bullet",
	},
	Shotgun = {
		Kick = 0.9, Recover = 0.75, Drift = 0.2, Shake = 0.35, Punch = 2.5,
		ViewKick = { Back = 0.22, Pitch = 11, Roll = 3, Ref = 4.5 },
		Aim = { Time = 0.18, Fov = 0.9, Spread = 0.85, Distance = 1.1 },
		Flash = { Size = 1.45, Color = PALETTE.Flash }, Shell = "Shell", Tracer = "Pellet",
	},
	Sniper = {
		Kick = 0.9, Recover = 0.82, Drift = 0.2, Shake = 0.3, Punch = 2,
		ViewKick = { Back = 0.26, Pitch = 12, Roll = 2, Ref = 7 },
		Aim = { Time = 0.2, Fov = 0.85, Spread = 0.7, Distance = 1.15 },
		Flash = { Size = 1.3, Color = PALETTE.Flash }, Shell = "Brass", Tracer = "Sniper",
	},
	Heavy = {
		Kick = 0.8, Recover = 0.55, Drift = 0.6, Shake = 0.05, Punch = 0,
		ViewKick = { Back = 0.035, Pitch = 1.2, Roll = 2.2, Ref = 0.6 },
		Aim = false,
		Flash = { Size = 1.05, Color = PALETTE.Flash }, Shell = "Brass", Tracer = "Bullet",
	},
	Launcher = {
		Kick = 0.8, Recover = 0.75, Drift = 0.2, Shake = 0.6, Punch = 3,
		ViewKick = { Back = 0.3, Pitch = 13, Roll = 3, Ref = 6 },
		Aim = { Time = 0.22, Fov = 0.9, Spread = 0.9, Distance = 1.15 },
		Flash = { Size = 1.6, Color = PALETTE.Flash }, Shell = false, Tracer = "Bullet",
	},
	Energy = {
		Kick = 0.85, Recover = 0.6, Drift = 0.25, Shake = 0, Punch = 0,
		ViewKick = { Back = 0.05, Pitch = 2, Roll = 1, Ref = 0.6 },
		Aim = { Time = 0.15, Fov = 0.85, Spread = 0.7, Distance = 1.1 },
		Flash = { Size = 0.9, Color = PALETTE.Violet }, Shell = false, Tracer = "Energy",
	},
}

-- Which class each gun is. Guns not listed get one from their stats (classOf).
GunProfiles.CLASS_BY_ID = {
	Pistol = "Pistol", Revolver = "Pistol",
	SMG = "SMG", MicroSMG = "SMG", TommyGun = "SMG",
	Rifle = "Rifle", DMR = "Rifle",
	Shotgun = "Shotgun", TrenchGun = "Shotgun",
	Sniper = "Sniper", BoltRifle = "Sniper", LongRifle = "Sniper",
	Minigun = "Heavy", HeavyRepeater = "Heavy", AutoCannon = "Heavy",
	Rocket = "Launcher", ToxicLauncher = "Launcher", BanCannon = "Launcher",
	PlasmaRifle = "Energy", PulseRifle = "Energy", Railgun = "Energy",
}

-- Tweaks for single guns, laid over their class
GunProfiles.BY_ID = {
	Revolver = { Shake = 0.25, Punch = 1.5, Shell = false, Flash = { Size = 1.15, Color = PALETTE.Flash } },
	DMR = { Shake = 0.12, Punch = 0.8 },
	AutoCannon = { Shake = 0.22, Punch = 1, Shell = "Big", ViewKick = { Back = 0.14, Pitch = 6, Roll = 2.5, Ref = 3 } },
	ToxicLauncher = { Flash = { Size = 1.2, Color = PALETTE.Mint }, Tracer = "Energy" },
	BanCannon = { Shake = 0.8, Punch = 4, Flash = { Size = 1.9, Color = PALETTE.Red } },
	PulseRifle = { Flash = { Size = 0.85, Color = PALETTE.Blue } },
	Railgun = {
		Kick = 0.8, Recover = 0.85, Shake = 0.5, Punch = 3, Tracer = "Rail",
		ViewKick = { Back = 0.28, Pitch = 12, Roll = 2, Ref = 9 },
		Flash = { Size = 1.5, Color = PALETTE.Blue },
	},
}

-- Moving parts. Kind:
--   Slide     blows back on every shot and locks back when empty (pistols)
--   Bolt      lift, pull, push, lower between shots (bolt-action rifles)
--   Pump      slides back and forward between shots; the left hand follows
--   Cylinder  turns a sixth per shot and spins on reload (revolvers)
--   Charge    pulled back at the end of a reload (charging handles)
-- Parts are Lua patterns matched against part names; Skip leaves some out.
GunProfiles.ACTIONS = {
	Pistol = {
		Kind = "Slide", Travel = 0.2,
		Parts = { "^Slide", "^StrikerPlate", "Serration", "^Port", "^Hood", "^Extractor", "^FrontSight", "^FrontDot", "^RearSight", "^RearDot", "^SightDot" },
		Skip = { "^SlideStop" },
	},
	Revolver = { Kind = "Cylinder", Parts = { "^Cylinder$", "^CylinderFront", "^CylinderBack", "^CylinderRing", "^Flute" }, Pivot = "Cylinder" },
	Shotgun = { Kind = "Pump", Travel = 0.42, Parts = { "^Pump", "^ActionBar" } },
	TrenchGun = { Kind = "Pump", Travel = 0.42, Parts = { "^Pump", "^ActionBar", "^Slide$" } },
	BoltRifle = { Kind = "Bolt", Travel = 0.3, Parts = { "^Bolt" } },
	Sniper = { Kind = "Bolt", Travel = 0.3, Parts = { "^Bolt" } },
	LongRifle = { Kind = "Bolt", Travel = 0.32, Parts = { "^Bolt" } },
	Rifle = { Kind = "Charge", Travel = 0.16, Parts = { "^BoltHandle", "^BoltKnob", "^Charg" } },
	SMG = { Kind = "Charge", Travel = 0.2, Parts = { "^Cock" } },
	MicroSMG = { Kind = "Charge", Travel = 0.16, Parts = { "^Cocking", "^Bolt$" }, Skip = { "^CockingSlot" } },
	TommyGun = { Kind = "Charge", Travel = 0.18, Parts = { "^Bolt$", "^Knob" } },
	PlasmaRifle = { Kind = "Charge", Travel = 0.16, Parts = { "^BoltHandle" } },
}
-- Guns not listed above: any charging handle or cocking knob gets pulled on reload
GunProfiles.DEFAULT_ACTION = { Kind = "Charge", Travel = 0.15, Parts = { "^Charg", "^Cock" }, Skip = { "Slot$" } }

-- Magazine parts drop out on reload and a new one comes in. Patterns are
-- matched against part names; Skip keeps mag wells and releases on the gun.
GunProfiles.MAG = {
	Parts = { "^Mag", "^Drum", "^Ammo", "^Can%u", "^Shell%u", "^BeltLink" },
	Skip = { "^Mag[Ww]ell", "^MagRelease", "^MagCatch", "^MagHousing", "^MagTube", "^MagCap", "^MagCollar", "^CanSocket" },
	Wells = { "^Mag[Ww]ell", "^MagHousing", "^FeedWell", "^CanSocket" },
}
-- Guns that reload another way. Front: the round slides in from the muzzle
-- and is hidden while empty (rocket launchers).
GunProfiles.RELOAD_BY_ID = {
	Shotgun = { Style = "Shells" },
	TrenchGun = { Style = "Shells" },
	Revolver = { Style = "Cylinder" },
	Rocket = { Style = "Front", Parts = { "^Warhead", "^Probe" }, HideWhenEmpty = true },
}

-- When things happen during a reload, as a share of the reload time. The
-- first-person animation and the reload sounds both follow these.
GunProfiles.RELOAD_TIMING = {
	Mag = { MagOut = 0.22, MagIn = 0.64, Charge = 0.78 },
	Shells = { First = 0.16, Last = 0.7, Pump = 0.8 },
	Cylinder = { Open = 0.14, Dump = 0.26, First = 0.36, Last = 0.64, Close = 0.76 },
	Front = { MagIn = 0.62 },
	Generic = { MagOut = 0.25, MagIn = 0.6 },
}

-- Sight overrides, gun space: Rear and Front points of the sight line (Optic
-- = true fades what's in the way). Only needed where the sights found from
-- part names aren't the ones to use. false = aim from the shoulder instead:
-- the gun comes up closer to the middle and you aim with the crosshair.
GunProfiles.SIGHTS = {
	-- Looking through the Rocket's side scope put the open end of its tube
	-- right beside the crosshair, so it's shouldered instead. (The scope line
	-- was Rear = Vector3.new(-0.18, 0.12, 0.55), Front = Vector3.new(-0.18, 0.12, 0.03), Optic = true.)
	Rocket = false,
}

local function merge(base, over)
	local result = table.clone(base)
	for key, value in over do
		result[key] = value
	end
	return result
end

local profileCache = {}

-- The class name for a weapon from Config.Weapons
function GunProfiles.classOf(weapon)
	local listed = GunProfiles.CLASS_BY_ID[weapon.Id]
	if listed then
		return listed
	end
	if weapon.Pellets then
		return "Shotgun"
	elseif weapon.Splash then
		return if weapon.FireInterval < 0.5 then "Heavy" else "Launcher"
	elseif weapon.Scope then
		return "Sniper"
	elseif weapon.SpinUp or (weapon.FireInterval < 0.1 and weapon.Magazine >= 80) then
		return "Heavy"
	elseif weapon.FireInterval < 0.1 then
		return "SMG"
	elseif weapon.FireInterval < 0.2 then
		return "Rifle"
	end
	return "Pistol"
end

-- The feel profile for a weapon: its class settings with BY_ID on top
function GunProfiles.get(weapon)
	local cached = profileCache[weapon.Id]
	if cached then
		return cached
	end
	local class = GunProfiles.classOf(weapon)
	local profile = merge(GunProfiles.CLASSES[class], GunProfiles.BY_ID[weapon.Id] or {})
	profile.Class = class
	profileCache[weapon.Id] = profile
	return profile
end

local function matchesAny(name, patterns)
	for _, pattern in patterns or {} do
		if string.find(name, pattern) then
			return true
		end
	end
	return false
end

local function picks(name, rule)
	return matchesAny(name, rule.Parts) and not matchesAny(name, rule.Skip)
end
GunProfiles.picks = picks

local function allEntries(spec)
	local list = {}
	for _, entry in spec.Parts do
		table.insert(list, entry)
	end
	return list
end

local function centerOf(entries)
	local sum = Vector3.zero
	for _, entry in entries do
		sum += entry.Offset.Position
	end
	return if #entries > 0 then sum / #entries else nil
end

-- How far a part reaches from its center along a gun axis ("Y" or "Z"), turned parts included
local function reach(entry, axis)
	local offset, size = entry.Offset, entry.Size
	return math.abs(offset.XVector[axis]) * size.X / 2 + math.abs(offset.YVector[axis]) * size.Y / 2 + math.abs(offset.ZVector[axis]) * size.Z / 2
end

local function topOf(entry)
	return entry.Offset.Position.Y + reach(entry, "Y")
end

local SIGHT_WORDS = { "Sight", "Bead", "Dot", "Notch", "Aperture" }
local OPTIC_WORDS = { "Optic", "Scope", "Lens", "Eyecup", "Eyepiece", "Holo", "Reflex" }
local OPTIC_SKIP = { "Bracket", "Mount", "Knob", "Turret", "Windage", "Rail", "Base", "Bolt", "Screw", "Glow" }

local function hasWord(name, words)
	for _, word in words do
		if string.find(name, word, 1, true) then
			return true
		end
	end
	return false
end

local sightCache = {}

-- The sight line of a gun in gun space: { Rear, Front } points, or false if
-- it has no sights on its center line. Optics give a level line through the
-- optic; iron sights go from the top of the rear sight to the top of the
-- front sight.
function GunProfiles.sightFor(weaponId)
	if sightCache[weaponId] ~= nil then
		return sightCache[weaponId]
	end
	local override = GunProfiles.SIGHTS[weaponId]
	if override ~= nil then
		sightCache[weaponId] = override
		return override
	end
	local spec = GunModels.spec(weaponId)
	local optics, irons = {}, {}
	for _, entry in allEntries(spec) do
		local position = entry.Offset.Position
		if math.abs(position.X) <= 0.05 and hasWord(entry.Name, OPTIC_WORDS) and not hasWord(entry.Name, OPTIC_SKIP) then
			table.insert(optics, entry)
		elseif math.abs(position.X) <= 0.1 and hasWord(entry.Name, SIGHT_WORDS) then
			table.insert(irons, entry)
		end
	end

	local result = false
	if #optics >= 2 then
		-- The optic's middle height, from its back to its front
		local heights = {}
		local back, front = -math.huge, math.huge
		for _, entry in optics do
			table.insert(heights, entry.Offset.Position.Y)
			back = math.max(back, entry.Offset.Position.Z + reach(entry, "Z"))
			front = math.min(front, entry.Offset.Position.Z)
		end
		table.sort(heights)
		local y = heights[math.ceil(#heights / 2)]
		result = { Rear = Vector3.new(0, y, back), Front = Vector3.new(0, y, front), Optic = true }
	elseif #irons > 0 then
		local frontZ, backZ = math.huge, -math.huge
		for _, entry in irons do
			frontZ = math.min(frontZ, entry.Offset.Position.Z)
			backZ = math.max(backZ, entry.Offset.Position.Z)
		end
		local frontY, rearY = -math.huge, -math.huge
		for _, entry in irons do
			local z = entry.Offset.Position.Z
			if z <= frontZ + 0.3 then
				frontY = math.max(frontY, topOf(entry))
			end
			if z >= backZ - 0.3 then
				rearY = math.max(rearY, topOf(entry))
			end
		end
		local bead = backZ - frontZ < 0.4
		if bead then
			-- Only one sight (a bead): a level line from above the grip to it
			backZ = GunProfiles.gripFor(weaponId).Z
			rearY = frontY
		end
		result = { Rear = Vector3.new(0, rearY, backZ), Front = Vector3.new(0, frontY, frontZ), Optic = false, Bead = bead }
	end
	sightCache[weaponId] = result
	return result
end

local reloadCache = {}

-- How a gun reloads and which parts take part:
-- { Style, Mag = { entries }, Direction, Center, HideWhenEmpty }
function GunProfiles.reloadFor(weaponId)
	if reloadCache[weaponId] then
		return reloadCache[weaponId]
	end
	local spec = GunModels.spec(weaponId)
	local special = GunProfiles.RELOAD_BY_ID[weaponId]
	local rule = if special and special.Parts then { Parts = special.Parts } else GunProfiles.MAG
	local mag, wells = {}, {}
	for _, entry in allEntries(spec) do
		if picks(entry.Name, rule) then
			table.insert(mag, entry)
		elseif matchesAny(entry.Name, GunProfiles.MAG.Wells) then
			table.insert(wells, entry)
		end
	end
	local style = if special then special.Style elseif #mag > 0 then "Mag" else "Generic"
	local center = centerOf(mag)
	local direction = Vector3.new(0, -1, 0)
	if style == "Front" then
		direction = Vector3.new(0, 0, -1)
	elseif center then
		local well = centerOf(wells)
		if well and (center - well).Magnitude > 0.05 then
			-- Out of the well, and always a bit downward so it falls
			direction = ((center - well).Unit + Vector3.new(0, -0.6, 0)).Unit
		end
	end
	local result = {
		Style = style,
		Mag = mag,
		Center = center,
		Direction = direction,
		HideWhenEmpty = special ~= nil and special.HideWhenEmpty == true,
	}
	reloadCache[weaponId] = result
	return result
end

-- The moving-parts rule for a gun (see ACTIONS)
function GunProfiles.actionFor(weaponId)
	return GunProfiles.ACTIONS[weaponId] or GunProfiles.DEFAULT_ACTION
end

-- Where spent shells come out, in gun space
function GunProfiles.ejectFor(weaponId)
	local spec = GunModels.spec(weaponId)
	for _, entry in allEntries(spec) do
		if string.find(entry.Name, "^Eject") then
			local position = entry.Offset.Position
			return Vector3.new(math.max(position.X, 0) + 0.06, position.Y, position.Z)
		end
	end
	return Vector3.new(0.17, spec.Muzzle.Y - 0.02, -0.15)
end

-- The grip, where kicks and raises pivot from
function GunProfiles.gripFor(weaponId)
	local spec = GunModels.spec(weaponId)
	for _, entry in allEntries(spec) do
		if entry.Name == "Grip" then
			return entry.Offset.Position
		end
	end
	return Vector3.new(0, -0.35, 0.2)
end

return GunProfiles
