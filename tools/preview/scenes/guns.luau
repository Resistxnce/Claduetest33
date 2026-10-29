-- Preview scenes for every gun in GunSpecsExtra/Guns: each one in its own
-- Factory colors (side, three-quarter and top views), the same gun in the Gold
-- skin, and a rack of all of them side by side.
--
--   tools/preview/preview.sh tools/preview/scenes/guns.luau <outDir> [nameFilter]
return function(World)
	local Extra = World.require("ReplicatedStorage.Shared.GunSpecsExtra")
	local ids = {}
	for id in Extra.Specs do
		table.insert(ids, id)
	end
	table.sort(ids)

	local scenes = {}
	for _, id in ids do
		table.insert(scenes, {
			Name = id,
			Kind = "gun",
			Build = function()
				return World.gun(id, "Default")
			end,
		})
		table.insert(scenes, {
			Name = id .. "_Gold",
			Kind = "gun",
			Views = { "three_quarter" },
			Build = function()
				return World.gun(id, "Gold")
			end,
		})
	end

	-- Every gun hanging on one rack, two columns, like a gun wall
	table.insert(scenes, {
		Name = "GunRack",
		Kind = "gun",
		Views = { "side" },
		Build = function()
			local rack = World.Instance.new("Model")
			rack.Name = "GunRack"
			local rows = math.ceil(#ids / 2)
			for index, id in ids do
				local gun = World.gun(id, "Default")
				local column = (index - 1) // rows
				local row = (index - 1) % rows
				gun:PivotTo(World.CFrame.new(0, -row * 2, -column * 7))
				gun.Parent = rack
			end
			return rack
		end,
	})
	return scenes
end
