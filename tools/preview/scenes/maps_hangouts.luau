-- Preview scenes for the hangout maps (src/server/Maps/Hangouts.luau): each
-- whole map, plus close-ups of their signature spots cut out of the built map.
return function(World)
	local Maps = World.require("ServerScriptService.Server.Maps.Hangouts")

	local function buildMap(id)
		local layout = Maps[id]
		local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
		layout.Build(ctx)
		return ctx.Model
	end

	-- Keeps only the parts whose middle is inside a box of the map (and drops
	-- the room shell), so one corner can be looked at up close
	local function closeUp(id, low, high)
		local model = buildMap(id)
		for _, part in World.baseParts(model) do
			local position = part.CFrame.Position
			local inside = position.X >= low.X and position.X <= high.X and position.Y >= low.Y and position.Y <= high.Y and position.Z >= low.Z and position.Z <= high.Z
			if not inside or math.max(part.Size.X, part.Size.Y, part.Size.Z) > 60 then
				part.Parent = nil
			end
		end
		return model
	end

	local scenes = {}
	for _, id in { "GamerBedroom", "StreamerHouse" } do
		local layout = Maps[id]
		if layout then
			table.insert(scenes, {
				Name = id,
				Kind = "map",
				Theme = layout.Theme,
				Map = { HalfX = layout.HalfX, HalfZ = layout.HalfZ },
				Build = function()
					return buildMap(id)
				end,
			})
		end
	end

	local V = World.Vector3.new
	for _, spec in {
		{ "Bedroom_DeskRamp", "GamerBedroom", V(-72, -0.5, -45), V(-28, 48, 36), { "side", "overview", "front" } },
		{ "Bedroom_Bed", "GamerBedroom", V(28, -0.5, 4), V(72, 48, 62), { "left", "three_quarter", "front" } },
		{ "Bedroom_Floor", "GamerBedroom", V(-30, -0.5, -45), V(46, 14, 44), { "three_quarter", "front", "overview" } },
		{ "Bedroom_BackWall", "GamerBedroom", V(-50, -0.5, 44), V(46, 48, 62), { "front", "three_quarter", "overview" } },
		{ "House_Stream", "StreamerHouse", V(-72, -0.5, 40), V(16, 25, 62), { "front", "three_quarter", "overview" } },
		{ "House_Hallway", "StreamerHouse", V(-72, -0.5, -46), V(-46, 25, 45), { "side", "three_quarter", "overview" } },
		{ "House_Plaques", "StreamerHouse", V(-72, 4, -46), V(-66, 20, 45), { "side" } },
		{ "House_Lounge", "StreamerHouse", V(-50, -0.5, -6), V(-12, 25, 40), { "left", "three_quarter", "overview" } },
		{ "House_Pool", "StreamerHouse", V(20, -0.5, 0), V(72, 25, 62), { "front", "three_quarter", "overview" } },
		{ "House_Kitchen", "StreamerHouse", V(20, -0.5, -62), V(72, 25, 0), { "back", "left", "overview" } },
		{ "House_Middle", "StreamerHouse", V(-18, -0.5, -40), V(20, 25, 40), { "front", "three_quarter", "overview" } },
	} do
		if Maps[spec[2]] then
			table.insert(scenes, {
				Name = spec[1],
				Kind = "prop",
				Views = spec[5],
				Build = function()
					return closeUp(spec[2], spec[3], spec[4])
				end,
			})
		end
	end

	return scenes
end
