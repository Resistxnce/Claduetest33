-- Preview scenes for the studio maps (src/server/Maps/Studio.luau): one map
-- scene per map, plus close-ups of their signature spots. A close-up builds
-- the whole map, then keeps only the parts inside a box around the spot and
-- puts a small floor under them.
return function(World)
	local Maps = World.require("ServerScriptService.Server.Maps.Studio")
	local Kit = World.require("ServerScriptService.Server.Maps.Kit")

	local scenes = {}

	for _, id in { "DevStudio", "ClassicPlace" } do
		local layout = Maps[id]
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

	-- Keeps the parts whose middle is inside x1..x2, z1..z2 and below maxY,
	-- leaving out anything long enough to stretch past the box (the floor,
	-- outer walls and grid lines). Rendered as a "map" with no Map box, so it
	-- gets the map's lighting but no spawn checks.
	local function closeUp(name, id, x1, x2, z1, z2, maxY, views)
		local layout = Maps[id]
		local reach = math.max(x2 - x1, z2 - z1) + 2
		table.insert(scenes, {
			Name = name,
			Kind = "map",
			Theme = layout.Theme,
			Views = views,
			Build = function()
				local ctx = World.ctx(layout.HalfX, layout.HalfZ, id, layout.Theme)
				layout.Build(ctx)
				for _, item in ctx.Model:GetDescendants() do
					if item:IsA("BasePart") then
						local p = item.CFrame.Position
						local long = math.max(item.Size.X, item.Size.Z) > reach
						if long or p.X < x1 or p.X > x2 or p.Z < z1 or p.Z > z2 or p.Y > maxY then
							item.Parent = nil
						end
					end
				end
				Kit.part(ctx.Model, "Ground", Vector3.new(x2 - x1, 1, z2 - z1), CFrame.new((x1 + x2) / 2, -0.5, (z1 + z2) / 2), if id == "ClassicPlace" then Kit.rgb(72, 148, 70) else Kit.rgb(214, 178, 134), Kit.M.Plastic)
				return ctx.Model
			end,
		})
	end

	closeUp("Studio_Desks", "DevStudio", -50, -20, -26, -9, 17, { "three_quarter", "front", "back" })
	closeUp("Studio_NorthWall", "DevStudio", -36, 32, 24, 58.5, 17.5, { "front", "three_quarter" })
	closeUp("Studio_Lounge", "DevStudio", -14, 14, -32, 18, 17.5, { "front", "three_quarter", "back" })
	closeUp("Studio_MeetingRoom", "DevStudio", -68.5, -40, 30, 58.5, 17, { "three_quarter", "front" })
	closeUp("Studio_Closet", "DevStudio", 44, 68.5, 30, 58.5, 17, { "front", "three_quarter" })
	closeUp("Studio_Coffee", "DevStudio", -68.5, -48, -58.5, -28, 17, { "three_quarter", "side" })
	closeUp("Studio_Merch", "DevStudio", 38, 68.5, -58.5, -28, 17, { "three_quarter", "front" })
	closeUp("Classic_Spawn", "ClassicPlace", -26, 26, -60, 10, 40, { "three_quarter", "front", "top" })
	closeUp("Classic_House", "ClassicPlace", -16, 16, 26, 52, 40, { "front", "three_quarter", "back" })
	closeUp("Classic_Statue", "ClassicPlace", -50, -30, -4, 16, 40, { "front", "three_quarter" })
	closeUp("Classic_Lookout", "ClassicPlace", -56, -36, 26, 48, 40, { "front", "three_quarter" })
	closeUp("Classic_Tower", "ClassicPlace", 18, 46, -10, 16, 40, { "front", "three_quarter", "left" })
	closeUp("Classic_Pond", "ClassicPlace", 26, 60, -54, -26, 40, { "three_quarter", "front" })
	closeUp("Studio_Pods", "DevStudio", -68.5, -30, -26, 30, 17, { "side", "three_quarter" })
	closeUp("Studio_EastBack", "DevStudio", 20, 68.5, -6, 37, 17, { "three_quarter", "front", "left" })

	return scenes
end
