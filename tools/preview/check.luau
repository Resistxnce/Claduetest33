-- Checks the extra content against what the game's code expects, with the
-- INSTALL.md hooks in place (EARNESP_SRC must point at a hooked copy).
--
--   lune run tools/preview/check.luau [guns|bots|maps|props]
--
-- Prints one line per problem and exits 1 if there are any.
local process = require("@lune/process")

local World = require("./world")

local only = process.args[1]
local problems = {}
local notes = {}

local function problem(text)
	table.insert(problems, text)
end

local function note(text)
	table.insert(notes, text)
end

local function isA(value, typeName)
	return typeof(value) == typeName
end

local Config = World.require("ReplicatedStorage.Shared.Config")
local Shared = World.game:GetService("ReplicatedStorage").Shared

-- Guns -----------------------------------------------------------------------------

local WEAPON_FIELDS = {
	Id = "string", Name = "string", Cost = "number", Damage = "number", FireInterval = "number",
	Magazine = "number", Reload = "number", Recoil = "number", Spread = "table", Description = "string",
}
local WEAPON_OPTIONAL = {
	Pellets = "number", Range = "number", Scope = "number", Walk = "number", SpinUp = "number", Splash = "number",
}

local function checkGuns()
	local GunModels = World.require("ReplicatedStorage.Shared.GunModels")
	local Extra = World.require("ReplicatedStorage.Shared.GunSpecsExtra")
	local roles = { Body = true, Accent = true, Dark = true, Metal = true, Wood = true, Grip = true, Warhead = true }
	for name in Extra.Roles do
		roles[name] = true
	end
	local extraIds = {}
	for _, moduleName in { "WeaponsClassic", "WeaponsSciFi" } do
		for _, weapon in World.require("ReplicatedStorage.Shared.ConfigExtra." .. moduleName) do
			table.insert(extraIds, weapon.Id)
			for field, kind in WEAPON_FIELDS do
				if type(weapon[field]) ~= kind then
					problem(`weapon {weapon.Id}: {field} should be a {kind}`)
				end
			end
			for field, value in weapon do
				if not WEAPON_FIELDS[field] and not WEAPON_OPTIONAL[field] then
					problem(`weapon {weapon.Id}: {field} isn't a field the game reads`)
				elseif WEAPON_OPTIONAL[field] and type(value) ~= WEAPON_OPTIONAL[field] then
					problem(`weapon {weapon.Id}: {field} should be a {WEAPON_OPTIONAL[field]}`)
				end
			end
			if type(weapon.Spread) == "table" then
				for _, key in { "Base", "PerShot", "Max", "Moving" } do
					if type(weapon.Spread[key]) ~= "number" then
						problem(`weapon {weapon.Id}: Spread.{key} should be a number`)
					end
				end
			end
			if Config.getWeapon(weapon.Id).Id ~= weapon.Id then
				problem(`weapon {weapon.Id} didn't make it into Config.Weapons`)
			end
			local spec = Extra.Specs[weapon.Id]
			if not spec then
				problem(`weapon {weapon.Id} has stats but no model in GunSpecsExtra`)
			end
		end
	end
	for id, spec in Extra.Specs do
		if not table.find(extraIds, id) then
			problem(`model {id} has no stats in ConfigExtra`)
		end
		if GunModels.spec(id) ~= spec then
			problem(`model {id} wasn't merged into GunModels (is the hook in?)`)
		end
		if not isA(spec.Muzzle, "Vector3") then
			problem(`model {id}: Muzzle should be a Vector3`)
		end
		if not isA(spec.Support, "Vector3") then
			problem(`model {id}: Support should be a Vector3`)
		end
		if spec.View ~= nil and not isA(spec.View, "CFrame") then
			problem(`model {id}: View should be a CFrame`)
		end
		local count = #spec.Parts + #(spec.Spinning or {})
		if count > 34 then
			problem(`model {id} has {count} parts; keep guns at 34 or fewer (every player and bot carries one)`)
		end
		local names = {}
		local minZ, maxZ = math.huge, -math.huge
		for _, entry in spec.Parts do
			if not roles[entry.Role] then
				problem(`model {id}: part {entry.Name} has unknown Role {entry.Role}`)
			end
			if names[entry.Name] then
				problem(`model {id}: two parts are named {entry.Name}`)
			end
			names[entry.Name] = true
			local reach = math.max(entry.Size.X, entry.Size.Y, entry.Size.Z) / 2
			minZ = math.min(minZ, entry.Offset.Position.Z - reach)
			maxZ = math.max(maxZ, entry.Offset.Position.Z + reach)
		end
		if spec.Spinning then
			for _, entry in spec.Spinning do
				if math.abs(entry.Offset.Position.X) > 0.6 or math.abs(entry.Offset.Position.Y) > 0.6 then
					problem(`model {id}: spinning part {entry.Name} must sit around the gun's center line (it spins around Z)`)
				end
			end
		end
		if isA(spec.Muzzle, "Vector3") and spec.Muzzle.Z > minZ + 0.35 then
			problem(`model {id}: Muzzle (z={spec.Muzzle.Z}) should be at the front tip (front of the gun is z={minZ})`)
		end
		local length = maxZ - minZ
		if length < 1 or length > 7.5 then
			problem(`model {id} is {length} studs long; guns here are 1.6 (Pistol) to 5.1 (Sniper)`)
		end
		-- Every skin must build, including Rainbow
		for _, skin in Config.Skins do
			local ok, result = pcall(GunModels.makeParts, id, skin.Id)
			if not ok then
				problem(`model {id} fails with skin {skin.Id}: {result}`)
				break
			end
		end
		note(`gun {id}: {count} parts, {math.floor(length * 100) / 100} studs long`)
	end
end

-- Bots -----------------------------------------------------------------------------

local BOT_FIELDS = {
	Health = "number", WalkSpeed = "number", FireInterval = "number", HitChance = "number", Damage = "number",
	Range = "number", Reaction = "number", Credits = "number", Colors = "table",
}
local BOT_OPTIONAL = {
	Strafe = "boolean", Jumps = "boolean", UsesCover = "boolean", Tag = "string", Boss = "boolean", Name = "string",
	Scale = "number", Decoy = "boolean", Jams = "number", Disarm = "number", Lag = "number", TeleportEvery = "number",
	Spin = "table", Hammer = "table", Summons = "table", Gun = "string", Skin = "string",
}

local function checkBots()
	local extra = World.require("ReplicatedStorage.Shared.ConfigExtra.BotTypes")
	local BotOutfits = World.require("ServerScriptService.Server.BotOutfits")
	for name, botType in extra.Types do
		for field, kind in BOT_FIELDS do
			if type(botType[field]) ~= kind then
				problem(`bot {name}: {field} should be a {kind}`)
			end
		end
		for field, value in botType do
			if not BOT_FIELDS[field] and not BOT_OPTIONAL[field] then
				problem(`bot {name}: {field} isn't a field Bots.luau reads`)
			elseif BOT_OPTIONAL[field] and type(value) ~= BOT_OPTIONAL[field] then
				problem(`bot {name}: {field} should be a {BOT_OPTIONAL[field]}`)
			end
		end
		if type(botType.Colors) == "table" then
			if not isA(botType.Colors.Torso, "Color3") or not isA(botType.Colors.Legs, "Color3") then
				problem(`bot {name}: Colors needs Torso and Legs Color3s`)
			end
		end
		if botType.Boss and not botType.Name then
			problem(`boss {name} needs a Name (its gamertag)`)
		end
		if botType.Boss and not BotOutfits.BossLines[name] then
			problem(`boss {name} has no BossLines`)
		end
		if botType.Gun and Config.getWeapon(botType.Gun).Id ~= botType.Gun then
			problem(`bot {name}: Gun {botType.Gun} isn't a weapon id`)
		end
		if botType.Skin and Config.getSkin(botType.Skin).Id ~= botType.Skin then
			problem(`bot {name}: Skin {botType.Skin} isn't a skin id`)
		end
		if botType.Summons and not Config.BotTypes[botType.Summons.Type] then
			problem(`bot {name}: summons unknown type {botType.Summons.Type}`)
		end
		if Config.BotTypes[name] ~= botType then
			problem(`bot {name} didn't make it into Config.BotTypes`)
		end
		-- dress() must handle the type on a real-shaped rig
		local rig = World.rig(botType.Colors or {}, botType.Scale)
		local ok, handled = pcall(BotOutfits.dress, rig, name, World.gear)
		if not ok then
			problem(`BotOutfits.dress fails for {name}: {handled}`)
		elseif handled ~= true then
			problem(`BotOutfits.dress doesn't dress {name} (should return true)`)
		end
	end
	local rig = World.rig({ Torso = World.Color3.new(), Legs = World.Color3.new() })
	local ok, handled = pcall(BotOutfits.dress, rig, "Noob", World.gear)
	if not ok or handled ~= false then
		problem("BotOutfits.dress must return false for the game's own bot types so Bots.luau dresses them")
	end
	for arenaId, waves in extra.ArenaWaves do
		local found = false
		for _, arena in Config.Arenas do
			if arena.Id == arenaId then
				found = true
			end
		end
		if not found then
			problem(`ArenaWaves: no rank called {arenaId}`)
		end
		for _, wave in waves do
			for _, group in wave do
				if not Config.BotTypes[group[1]] or type(group[2]) ~= "number" then
					problem(`ArenaWaves.{arenaId}: bad group {tostring(group[1])} x {tostring(group[2])}`)
				end
			end
		end
	end
	local LobbyNpcs = World.require("ServerScriptService.Server.LobbyNpcs")
	if type(LobbyNpcs.start) ~= "function" then
		problem("LobbyNpcs.start is missing")
	end
end

-- Maps -----------------------------------------------------------------------------

local THEME_FIELDS = {
	ClockTime = "number", Brightness = "number", Ambient = "Color3", OutdoorAmbient = "Color3",
	Atmosphere = "table", Tint = "Color3", Contrast = "number", Saturation = "number", Bloom = "number",
}

local function checkMaps()
	for _, pair in { { "Esports", "MapsEsports" }, { "AntiCheat", "MapsAntiCheat" } } do
		local layouts = World.require("ServerScriptService.Server.Maps." .. pair[1])
		local extra = World.require("ReplicatedStorage.Shared.ConfigExtra." .. pair[2])
		for name, theme in extra.Themes do
			for field, kind in THEME_FIELDS do
				if typeof(theme[field]) ~= kind then
					problem(`theme {name}: {field} should be a {kind}`)
				end
			end
		end
		for id, layout in layouts do
			for _, field in { "Name", "Theme", "HalfX", "HalfZ", "Build" } do
				if layout[field] == nil then
					problem(`map {id}: missing {field}`)
				end
			end
			if not Config.Themes[layout.Theme] then
				problem(`map {id}: theme {tostring(layout.Theme)} isn't in Config.Themes`)
			end
			if not table.find(Config.MapPool, id) then
				problem(`map {id} isn't in the MapPool`)
			end
			note(`map {id}: {layout.Name}, {layout.HalfX * 2} x {layout.HalfZ * 2}, theme {layout.Theme}`)
		end
		for _, id in extra.MapPool do
			if not layouts[id] then
				problem(`MapPool has {id} but {pair[1]}.luau has no such layout`)
			end
		end
	end
end

local function checkProps()
	local Props = World.require("ServerScriptService.Server.Maps.Props")
	local count = 0
	for name, value in Props do
		if type(value) == "function" then
			count += 1
		end
	end
	note(`Props has {count} functions`)
	if count == 0 then
		problem("Props.luau has no prop functions yet")
	end
end

local sections = { guns = checkGuns, bots = checkBots, maps = checkMaps, props = checkProps }
for name, run in sections do
	if not only or only == name then
		local ok, err = pcall(run)
		if not ok then
			problem(`{name} check crashed: {err}`)
		end
	end
end
for _, text in notes do
	print("  " .. text)
end
for _, text in problems do
	print("PROBLEM " .. text)
end
print(if #problems == 0 then "all checks passed" else `{#problems} problems`)
process.exit(if #problems == 0 then 0 else 1)
