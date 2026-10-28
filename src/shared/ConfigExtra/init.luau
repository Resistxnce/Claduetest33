-- Balance numbers for the extra guns, bot types and maps, kept apart from
-- Config.luau so they can be dropped in as one folder. Config.luau calls
-- ConfigExtra.apply(Config) just before it returns (see INSTALL.md).
--
-- Nothing already in Config is changed: an id or name that already exists
-- is skipped, so it's safe to apply even after some of these get copied in.
local ConfigExtra = {}

local function hasId(list, id)
	for _, entry in list do
		if entry.Id == id then
			return true
		end
	end
	return false
end

-- Guns tab order follows cost, so each new gun slots in by price
local function insertByCost(weapons, weapon)
	for index, other in weapons do
		if (other.Cost or 0) > weapon.Cost then
			table.insert(weapons, index, weapon)
			return
		end
	end
	table.insert(weapons, weapon)
end

function ConfigExtra.apply(Config)
	-- One file per new gun in Weapons/, each returning its Config.Weapons entry
	local weapons = script:FindFirstChild("Weapons")
	if weapons then
		for _, module in weapons:GetChildren() do
			local weapon = module:IsA("ModuleScript") and require(module)
			if weapon and not hasId(Config.Weapons, weapon.Id) then
				insertByCost(Config.Weapons, weapon)
			end
		end
	end

	local bots = require(script.BotTypes)
	for name, botType in bots.Types do
		if not Config.BotTypes[name] then
			Config.BotTypes[name] = botType
		end
	end
	-- Extra waves at the end of a rank's round, so the new bots show up
	for _, arena in Config.Arenas do
		for _, wave in bots.ArenaWaves[arena.Id] or {} do
			table.insert(arena.Waves, wave)
		end
	end

	for _, moduleName in { "MapsEsports", "MapsAntiCheat", "MapsHangouts", "MapsStudio" } do
		local module = script:FindFirstChild(moduleName)
		local maps = if module then require(module) else { Themes = {}, MapPool = {} }
		for name, theme in maps.Themes do
			if not Config.Themes[name] then
				Config.Themes[name] = theme
			end
		end
		for _, mapId in maps.MapPool do
			if not table.find(Config.MapPool, mapId) then
				table.insert(Config.MapPool, mapId)
			end
		end
	end
end

return ConfigExtra
