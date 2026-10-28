-- Preview scenes for the esports maps (src/server/Maps/Esports.luau): each
-- whole map, plus close-ups of a few signature spots. A close-up builds the
-- full map, then keeps only what stands inside a box around the spot, on a
-- floor cut to that size.
return function(World)
	local Kit = World.require("ServerScriptService.Server.Maps.Kit")
	local Maps = World.require("ServerScriptService.Server.Maps.Esports")

	local scenes = {}
	for _, id in { "EsportsArena", "LanCafe" } do
		local layout = Maps[id]
		if layout then
			table.insert(scenes, {
				Name = id,
				Kind = "map",
				Theme = layout.Theme,
				Map = { HalfX = layout.HalfX, HalfZ = layout.HalfZ },
				Build = function()
					local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
					layout.Build(ctx)
					return ctx.Model
				end,
			})
		end
	end

	-- The whole map turned around, so the ground view looks from the bots'
	-- end back toward the player's spawn. No Map field: the spawn checks only
	-- make sense the right way round.
	for _, id in { "EsportsArena", "LanCafe" } do
		local layout = Maps[id]
		if layout then
			table.insert(scenes, {
				Name = id .. "_FromBack",
				Kind = "map",
				Theme = layout.Theme,
				Views = { "ground" },
				Build = function()
					local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
					layout.Build(ctx)
					local pivot = ctx.Model:GetPivot()
					ctx.Model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.pi, 0))
					return ctx.Model
				end,
			})
		end
	end

	-- Everything whose middle is within half.X / half.Z of (x, z), lower than
	-- `top`, with the walls, ceiling and the big floor left out
	local function closeUp(name, id, x, z, halfX, halfZ, top, views)
		local layout = Maps[id]
		if not layout then
			return
		end
		table.insert(scenes, {
			Name = name,
			Kind = "prop",
			Theme = layout.Theme,
			Views = views,
			Build = function()
				local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
				layout.Build(ctx)
				for _, part in ctx.Model:GetDescendants() do
					if part:IsA("BasePart") then
						local spot = part.CFrame.Position
						local skip = part.Name == "Floor" or part.Name == "Ceiling" or part.Name == "Barrier" or part.Name == "Wall"
						if skip or math.abs(spot.X - x) > halfX or math.abs(spot.Z - z) > halfZ or spot.Y > top then
							part:Destroy()
						end
					end
				end
				Kit.part(ctx.Model, "Ground", Vector3.new(halfX * 2, 1, halfZ * 2), CFrame.new(x, -0.5, z), Color3.fromRGB(30, 30, 38), Enum.Material.SmoothPlastic)
				return ctx.Model
			end,
		})
	end

	closeUp("Arena_Stage", "EsportsArena", 0, 0, 30, 20, 26, { "front", "three_quarter", "top" })
	closeUp("Arena_CrowdFloor", "EsportsArena", -30, -28, 20, 16, 26, { "front", "three_quarter", "back" })
	closeUp("Arena_Backstage", "EsportsArena", -34, 40, 28, 18, 26, { "front", "three_quarter", "back" })
	closeUp("Cafe_Desks", "LanCafe", 0, 8, 14, 12, 14, { "front", "three_quarter", "left" })
	closeUp("Cafe_Lounge", "LanCafe", 44, -36, 14, 14, 14, { "three_quarter", "left", "top" })
	closeUp("Cafe_Corner", "LanCafe", 44, 38, 14, 14, 14, { "front", "three_quarter", "top" })
	closeUp("Cafe_SnackBar", "LanCafe", -46, -24, 12, 14, 14, { "three_quarter", "left", "top" })

	return scenes
end
