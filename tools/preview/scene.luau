-- Builds preview scenes and writes each one out as JSON for render.mjs.
--
--   lune run tools/preview/scene.luau <scenes.luau> <outDir> [nameFilter]
--
-- A scenes file returns function(World) -> list of scenes, where a scene is
-- { Name = "TommyGun", Kind = "gun" | "prop" | "npc" | "map", Build = function() return instance end }
-- plus optional Views (see render.mjs) and Map = { HalfX, HalfZ } for maps.
-- Besides the parts, it records quick checks (sizes, anchoring, open floor
-- space on maps) so mistakes show up without opening Studio.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")

local World = require("./world")

local Vector3 = World.Vector3

local args = process.args
local scenesPath, outDir, filter = args[1], args[2], args[3]
if not scenesPath or not outDir then
	print("usage: lune run tools/preview/scene.luau <scenes.luau> <outDir> [nameFilter]")
	process.exit(2)
end
fs.writeDir(outDir)

local DEFAULT_VIEWS = {
	gun = { "side", "three_quarter", "top" },
	prop = { "three_quarter", "front", "back" },
	npc = { "front", "three_quarter", "back" },
	map = { "top", "overview", "ground" },
}

local function round(value)
	return math.floor(value * 1000 + 0.5) / 1000
end

local function color(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local function udim2(u)
	return { u.X.Scale, u.X.Offset, u.Y.Scale, u.Y.Offset }
end

local function enumName(item)
	return if item then item.Name else nil
end

local function guiOf(part)
	local list = {}
	for _, gui in part:GetChildren() do
		if gui:IsA("SurfaceGui") then
			local items = {}
			for _, item in gui:GetDescendants() do
				if item:IsA("TextLabel") or item:IsA("TextButton") then
					table.insert(items, {
						type = "text",
						text = item.Text,
						color = color(item.TextColor3),
						bg = color(item.BackgroundColor3),
						bgT = item.BackgroundTransparency,
						pos = udim2(item.Position),
						size = udim2(item.Size),
						font = enumName(item.Font),
						align = enumName(item.TextXAlignment),
						rot = item.Rotation,
					})
				elseif item:IsA("Frame") or item:IsA("ImageLabel") then
					table.insert(items, {
						type = "frame",
						bg = color(item.BackgroundColor3),
						bgT = item.BackgroundTransparency,
						pos = udim2(item.Position),
						size = udim2(item.Size),
					})
				end
			end
			table.insert(list, { face = enumName(gui.Face), items = items })
		elseif gui:IsA("Decal") or gui:IsA("Texture") then
			table.insert(list, { face = enumName(gui.Face), decal = gui.Name, color = color(gui.Color3), t = gui.Transparency })
		end
	end
	return list
end

local function lightsOf(part)
	local list = {}
	for _, light in part:GetChildren() do
		if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
			table.insert(list, {
				kind = light.ClassName,
				color = color(light.Color),
				range = light.Range,
				brightness = light.Brightness,
				face = if light:IsA("PointLight") then nil else enumName(light.Face),
			})
		end
	end
	return list
end

local function particlesOf(part)
	local list = {}
	for _, item in part:GetChildren() do
		if item:IsA("ParticleEmitter") or item:IsA("Fire") or item:IsA("Smoke") or item:IsA("Sparkles") then
			table.insert(list, item.ClassName)
		end
	end
	return list
end

local function shapeOf(part)
	if part:IsA("Part") then
		return part.Shape.Name
	end
	return part.ClassName
end

local function folderOf(part, root)
	local node = part.Parent
	while node and node ~= root do
		if node:IsA("Folder") then
			return node.Name
		end
		node = node.Parent
	end
	return nil
end

-- The lighting theme from Config.Themes, so dark maps render dark
local function themeData(name)
	if not name then
		return nil
	end
	local ok, Config = pcall(World.require, "ReplicatedStorage.Shared.Config")
	local theme = ok and Config.Themes and Config.Themes[name]
	if not theme then
		return nil
	end
	return {
		ClockTime = theme.ClockTime,
		Brightness = theme.Brightness,
		Ambient = if theme.Ambient then color(theme.Ambient) else nil,
		OutdoorAmbient = if theme.OutdoorAmbient then color(theme.OutdoorAmbient) else nil,
	}
end

local function exportScene(scene, root)
	local parts = {}
	local warnings = {}
	local function warn(text)
		if #warnings < 60 then
			table.insert(warnings, text)
		end
	end
	local all = World.baseParts(root)
	for _, part in all do
		local size = part.Size
		if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
			warn(`{part:GetFullName()} has a zero or negative size {size}`)
		end
		if size.X > 2048 or size.Y > 2048 or size.Z > 2048 then
			warn(`{part:GetFullName()} is bigger than Roblox allows (2048): {size}`)
		end
		local components = { part.CFrame:GetComponents() }
		for _, value in components do
			if value ~= value then
				warn(`{part:GetFullName()} has a NaN CFrame`)
				break
			end
		end
		local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
		local entry = {
			n = part.Name,
			cls = part.ClassName,
			shape = shapeOf(part),
			s = { round(size.X), round(size.Y), round(size.Z) },
			cf = {},
			c = color(part.Color),
			m = enumName(part.Material),
			t = part.Transparency,
			r = part.Reflectance,
			role = part:GetAttribute("Role"),
			head = part:GetAttribute("PreviewShape") == "Head" or nil,
			mesh = if mesh then { type = enumName(mesh.MeshType), scale = { mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z } } else nil,
			folder = folderOf(part, root),
			anchored = part.Anchored,
			collide = part.CanCollide,
			gui = guiOf(part),
			lights = lightsOf(part),
			fx = particlesOf(part),
		}
		for index, value in components do
			entry.cf[index] = round(value)
		end
		if #entry.gui == 0 then
			entry.gui = nil
		end
		if #entry.lights == 0 then
			entry.lights = nil
		end
		if #entry.fx == 0 then
			entry.fx = nil
		end
		table.insert(parts, entry)
	end

	local minV, maxV = World.boundsOf(all)
	minV = minV or Vector3.zero
	maxV = maxV or Vector3.zero
	local stats = {
		parts = #all,
		size = { round(maxV.X - minV.X), round(maxV.Y - minV.Y), round(maxV.Z - minV.Z) },
		min = { round(minV.X), round(minV.Y), round(minV.Z) },
		max = { round(maxV.X), round(maxV.Y), round(maxV.Z) },
	}

	if scene.Kind == "gun" then
		for _, part in all do
			if part.CanCollide then
				warn(`gun part {part.Name} can collide`)
			end
			if not part:GetAttribute("Role") then
				warn(`gun part {part.Name} has no Role`)
			end
		end
	elseif scene.Kind == "npc" then
		for _, part in all do
			local weld = part:FindFirstChildWhichIsA("Weld")
			if weld then
				if part.CanCollide or not part.Massless or part.CanQuery then
					warn(`gear {part.Name} should be CanCollide/CanQuery false and Massless`)
				end
				if weld.Part0 and (part.CFrame.Position - weld.Part0.CFrame.Position).Magnitude > 4 then
					warn(`gear {part.Name} sits {math.floor((part.CFrame.Position - weld.Part0.CFrame.Position).Magnitude)} studs from {weld.Part0.Name}`)
				end
			end
		end
	elseif scene.Kind == "map" or scene.Kind == "prop" then
		local structure = 0
		for _, part in all do
			if not part.Anchored then
				warn(`{part:GetFullName()} is not anchored`)
			end
			if part.CFrame.Position.Y < -8 then
				warn(`{part:GetFullName()} is below the floor at y={round(part.CFrame.Position.Y)}`)
			end
			if folderOf(part, root) == "Structure" then
				structure += 1
			end
		end
		stats.structure = structure
	end

	if scene.Kind == "map" and scene.Map then
		-- The same test Map.findSpawns uses: a spot is free when a 4.5 x 5.5 x 4.5
		-- box standing on the floor (y = 0) touches no CanCollide part. The player
		-- spawns near (0, -HalfZ + 8); bots need 10 free spots 8 studs apart in the
		-- far part of the arena (z from -HalfZ * 0.1 to HalfZ - 6).
		local solids = {}
		for _, part in all do
			if part.CanCollide then
				local low, high = World.boundsOf({ part })
				table.insert(solids, { low, high })
			end
		end
		local function isFree(x, z)
			local low = Vector3.new(x - 2.25, 0.45, z - 2.25)
			local high = Vector3.new(x + 2.25, 5.95, z + 2.25)
			for _, box in solids do
				if box[1].X < high.X and box[2].X > low.X and box[1].Y < high.Y and box[2].Y > low.Y and box[1].Z < high.Z and box[2].Z > low.Z then
					return false
				end
			end
			return true
		end
		local hx, hz = scene.Map.HalfX, scene.Map.HalfZ
		local playerFree = false
		for radius = 0, 36, 3 do
			local steps = if radius == 0 then 1 else 12
			for step = 1, steps do
				local angle = step / steps * math.pi * 2
				if isFree(math.cos(angle) * radius, -hz + 8 + math.sin(angle) * radius) then
					playerFree = true
					break
				end
			end
			if playerFree then
				break
			end
		end
		if not playerFree then
			warn("no free spot for the player within 36 studs of (0, -HalfZ + 8)")
		end
		local spawns, open, total = {}, 0, 0
		for x = -hx + 6, hx - 6, 4 do
			for z = math.floor(-hz * 0.1), hz - 6, 4 do
				total += 1
				if isFree(x, z) then
					open += 1
					local apart = true
					for _, other in spawns do
						if (other - Vector3.new(x, 0, z)).Magnitude < 8 then
							apart = false
							break
						end
					end
					if apart then
						table.insert(spawns, Vector3.new(x, 0, z))
					end
				end
			end
		end
		stats.enemySpawnSpots = #spawns
		stats.openFloor = open
		stats.floorSamples = total
		if #spawns < 10 then
			warn(`only {#spawns} free bot spawn spots 8 studs apart; Map.findSpawns needs 10`)
		end
		if open > total * 0.92 then
			warn(`{open}/{total} floor samples are open; the map may have too little cover`)
		end
	end

	return {
		name = scene.Name,
		kind = scene.Kind,
		views = scene.Views or DEFAULT_VIEWS[scene.Kind] or { "three_quarter" },
		theme = scene.Theme,
		themeData = themeData(scene.Theme),
		parts = parts,
		stats = stats,
		warnings = warnings,
	}
end

local loadScenes = luau.load(fs.readFile(scenesPath), { debugName = scenesPath, environment = World.sceneEnvironment() })()
local scenes = loadScenes(World)
local failures = 0
local built = 0
for _, scene in scenes do
	if not filter or string.find(scene.Name, filter, 1, true) then
		math.randomseed(7)
		local ok, result = xpcall(scene.Build, debug.traceback)
		if ok and result then
			local data = exportScene(scene, result)
			fs.writeFile(outDir .. "/" .. scene.Name .. ".json", serde.encode("json", data))
			built += 1
			local note = if #data.warnings > 0 then ` ({#data.warnings} warnings)` else ""
			print(`ok   {scene.Name}: {data.stats.parts} parts, {data.stats.size[1]}x{data.stats.size[2]}x{data.stats.size[3]} studs{note}`)
			for _, text in data.warnings do
				print("     ! " .. text)
			end
			result.Parent = nil
		else
			failures += 1
			print(`FAIL {scene.Name}: {result or "Build returned nothing"}`)
		end
	end
end
print(`{built} built, {failures} failed`)
process.exit(if failures > 0 then 1 else 0)
