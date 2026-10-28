-- Preview scenes for the anti-cheat maps (src/server/Maps/AntiCheat.luau):
-- each whole map from the top, from above at an angle and from the spawn,
-- plus close-ups of their signature spots, cut out of the built map.
--
--   tools/preview/preview.sh <this file> <outDir> [nameFilter]
return function(World)
	local Maps = World.require("ServerScriptService.Server.Maps.AntiCheat")

	local function buildMap(id)
		local layout = Maps[id]
		local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
		layout.Build(ctx)
		return ctx.Model
	end

	-- Builds a map, then keeps only the parts whose middle is inside a box
	-- (minX, maxX, minZ, maxZ, below maxY), for a close look at one corner.
	-- The floor, ceiling and outer walls go too, so nothing blocks the view.
	local OUTER = { Floor = true, Barrier = true, Ceiling = true, WallBand = true, CeilingBeam = true }
	local function closeUp(id, minX, maxX, minZ, maxZ, maxY)
		local model = buildMap(id)
		for _, part in World.baseParts(model) do
			local p = part.CFrame.Position
			local outerWall = part.Name == "Wall" and math.max(part.Size.X, part.Size.Z) > 100
			if p.X < minX or p.X > maxX or p.Z < minZ or p.Z > maxZ or p.Y > maxY or OUTER[part.Name] or outerWall then
				part.Parent = nil
			end
		end
		return model
	end

	local scenes = {}
	for _, id in { "AntiCheatHQ", "BanCourt" } do
		local layout = Maps[id]
		table.insert(scenes, {
			Name = id,
			Kind = "map",
			Theme = layout.Theme,
			Map = { HalfX = layout.HalfX, HalfZ = layout.HalfZ },
			Views = { "top", "overview", "ground" },
			Build = function()
				return buildMap(id)
			end,
		})
	end

	-- Anti-Cheat HQ: the security gates and the ban hammer behind them
	table.insert(scenes, {
		Name = "AntiCheatHQ_Lobby",
		Kind = "prop",
		Theme = "AntiCheatHQ",
		Views = { "three_quarter", "front", "back" },
		Build = function()
			return closeUp("AntiCheatHQ", -40, 40, -42, 16, 21)
		end,
	})
	-- Anti-Cheat HQ: the watch room and its wall of camera feeds
	table.insert(scenes, {
		Name = "AntiCheatHQ_WatchRoom",
		Kind = "prop",
		Theme = "AntiCheatHQ",
		Views = { "three_quarter", "left", "top" },
		Build = function()
			return closeUp("AntiCheatHQ", 38, 70, -24, 38, 21)
		end,
	})
	-- Anti-Cheat HQ: the server room wall with the logo and wanted posters
	table.insert(scenes, {
		Name = "AntiCheatHQ_ServerWall",
		Kind = "prop",
		Theme = "AntiCheatHQ",
		Views = { "front", "three_quarter", "top" },
		Build = function()
			return closeUp("AntiCheatHQ", -36, 36, 26, 60, 21)
		end,
	})
	-- Ban Court: the judge's stage, witness stand, jury box and BANNED screen
	table.insert(scenes, {
		Name = "BanCourt_Bench",
		Kind = "prop",
		Theme = "BanCourt",
		Views = { "front", "three_quarter", "back" },
		Build = function()
			return closeUp("BanCourt", -48, 30, 6, 66, 29)
		end,
	})
	-- Ban Court: pews, the bar and a balcony with its ramp
	table.insert(scenes, {
		Name = "BanCourt_Gallery",
		Kind = "prop",
		Theme = "BanCourt",
		Views = { "three_quarter", "front", "top" },
		Build = function()
			return closeUp("BanCourt", 0, 60, -66, 12, 29)
		end,
	})
	return scenes
end
