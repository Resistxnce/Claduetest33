-- A pretend Roblox for previewing models outside Studio. It loads the game's
-- modules (from EARNESP_SRC) with this repo's src/ laid over the top, the
-- same way Rojo would sync them, so `require(script.Parent.Kit)` and
-- `game:GetService("ReplicatedStorage").Shared.Config` work like in game.
--
-- Only what model building needs is faked: services, remotes, tags and a
-- stand-in R15 rig. Physics, rendering and networking don't exist here.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local Enum = roblox.Enum

local World = {}

-- MODELS_SRC can list several folders split by ":"; later ones win
local MODEL_SRCS = string.split(process.env.MODELS_SRC or "src", ":")
local GAME_SRC = process.env.EARNESP_SRC
	or error("Set EARNESP_SRC to the game's src folder (the one with shared/, server/ and client/)")

-- Methods Lune's Instances don't have ---------------------------------------

local function boundsOf(parts)
	local minV, maxV
	for _, part in parts do
		local half = part.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
					minV = if minV then minV:Min(corner) else corner
					maxV = if maxV then maxV:Max(corner) else corner
				end
			end
		end
	end
	return minV, maxV
end
World.boundsOf = boundsOf

local function baseParts(root)
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(list, item)
		end
	end
	return list
end
World.baseParts = baseParts

local function getPivot(model)
	if model.PrimaryPart then
		return model.PrimaryPart.CFrame
	end
	local minV, maxV = boundsOf(baseParts(model))
	if not minV then
		return CFrame.new()
	end
	return CFrame.new((minV + maxV) / 2)
end

roblox.implementMethod("Model", "GetPivot", getPivot)
roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * getPivot(model):Inverse()
	for _, part in baseParts(model) do
		part.CFrame = delta * part.CFrame
	end
end)
roblox.implementMethod("Model", "GetBoundingBox", function(model)
	local minV, maxV = boundsOf(baseParts(model))
	return CFrame.new((minV + maxV) / 2), maxV - minV
end)
roblox.implementMethod("Model", "GetExtentsSize", function(model)
	local minV, maxV = boundsOf(baseParts(model))
	return maxV - minV
end)
roblox.implementMethod("Model", "SetPrimaryPartCFrame", function(model, target)
	local delta = target * getPivot(model):Inverse()
	for _, part in baseParts(model) do
		part.CFrame = delta * part.CFrame
	end
end)
for _, className in { "Part", "WedgePart", "CornerWedgePart", "TrussPart", "MeshPart", "Seat", "SpawnLocation", "VehicleSeat" } do
	roblox.implementMethod(className, "GetPivot", function(part)
		return part.CFrame
	end)
	roblox.implementMethod(className, "PivotTo", function(part, target)
		part.CFrame = target
	end)
	roblox.implementMethod(className, "GetMass", function(part)
		return part.Size.X * part.Size.Y * part.Size.Z * 0.7
	end)
	-- Lune keeps a part's placement only in CFrame
	roblox.implementProperty(className, "Position", function(part)
		return part.CFrame.Position
	end, function(part, value)
		part.CFrame = part.CFrame.Rotation + value
	end)
	roblox.implementProperty(className, "Orientation", function(part)
		local x, y, z = part.CFrame:ToOrientation()
		return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
	end, function(part, value)
		part.CFrame = CFrame.new(part.CFrame.Position) * CFrame.fromOrientation(math.rad(value.X), math.rad(value.Y), math.rad(value.Z))
	end)
end

-- Lune can set a text object's Font but not read it back
local fonts = setmetatable({}, { __mode = "k" })
for _, className in { "TextLabel", "TextButton", "TextBox" } do
	roblox.implementProperty(className, "Font", function(self)
		return fonts[self] or Enum.Font.Legacy
	end, function(self, value)
		fonts[self] = value
	end)
end

-- Fake services ---------------------------------------------------------------

local function signal()
	return {
		Connect = function()
			return { Disconnect = function() end, Connected = true }
		end,
		Once = function()
			return { Disconnect = function() end, Connected = true }
		end,
		Wait = function() end,
	}
end

local function remote(name)
	return setmetatable({ Name = name }, {
		__index = function(_, key)
			if key == "OnServerEvent" or key == "OnClientEvent" or key == "Event" then
				return signal()
			end
			return function() end
		end,
		__newindex = function() end,
	})
end

local tags = {}
World.tags = tags

local CollectionService = {
	AddTag = function(_, instance, tag)
		instance:AddTag(tag)
		tags[tag] = tags[tag] or {}
		table.insert(tags[tag], instance)
	end,
	RemoveTag = function(_, instance, tag)
		instance:RemoveTag(tag)
	end,
	HasTag = function(_, instance, tag)
		return instance:HasTag(tag)
	end,
	GetTagged = function(_, tag)
		return tags[tag] or {}
	end,
	GetInstanceAddedSignal = signal,
	GetInstanceRemovedSignal = signal,
}

-- R15 part sizes and resting heights for a stand-in rig (feet on y = 0)
local R15 = {
	{ "HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3.91, 0) },
	{ "Head", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 5.31, 0) },
	{ "UpperTorso", Vector3.new(2, 1.6, 1), Vector3.new(0, 3.91, 0) },
	{ "LowerTorso", Vector3.new(2, 0.4, 1), Vector3.new(0, 2.91, 0) },
	{ "LeftUpperArm", Vector3.new(1, 1.17, 1), Vector3.new(-1.5, 4.125, 0) },
	{ "LeftLowerArm", Vector3.new(1, 1.05, 1), Vector3.new(-1.5, 3.015, 0) },
	{ "LeftHand", Vector3.new(1, 0.3, 1), Vector3.new(-1.5, 2.34, 0) },
	{ "RightUpperArm", Vector3.new(1, 1.17, 1), Vector3.new(1.5, 4.125, 0) },
	{ "RightLowerArm", Vector3.new(1, 1.05, 1), Vector3.new(1.5, 3.015, 0) },
	{ "RightHand", Vector3.new(1, 0.3, 1), Vector3.new(1.5, 2.34, 0) },
	{ "LeftUpperLeg", Vector3.new(1, 1.22, 1), Vector3.new(-0.5, 2.1, 0) },
	{ "LeftLowerLeg", Vector3.new(1, 1.19, 1), Vector3.new(-0.5, 0.895, 0) },
	{ "LeftFoot", Vector3.new(1, 0.3, 1), Vector3.new(-0.5, 0.15, 0) },
	{ "RightUpperLeg", Vector3.new(1, 1.22, 1), Vector3.new(0.5, 2.1, 0) },
	{ "RightLowerLeg", Vector3.new(1, 1.19, 1), Vector3.new(0.5, 0.895, 0) },
	{ "RightFoot", Vector3.new(1, 0.3, 1), Vector3.new(0.5, 0.15, 0) },
}

local PART_COLOR = {
	Head = "HeadColor",
	UpperTorso = "TorsoColor",
	LowerTorso = "TorsoColor",
	LeftUpperArm = "LeftArmColor",
	LeftLowerArm = "LeftArmColor",
	LeftHand = "LeftArmColor",
	RightUpperArm = "RightArmColor",
	RightLowerArm = "RightArmColor",
	RightHand = "RightArmColor",
	LeftUpperLeg = "LeftLegColor",
	LeftLowerLeg = "LeftLegColor",
	LeftFoot = "LeftLegColor",
	RightUpperLeg = "RightLegColor",
	RightLowerLeg = "RightLegColor",
	RightFoot = "RightLegColor",
}

-- Joints the real rig has (named like Roblox's), so code that looks them up
-- finds them. Only the names and attachments matter here.
local JOINTS = {
	{ "Neck", "UpperTorso", "Head" },
	{ "Waist", "LowerTorso", "UpperTorso" },
	{ "Root", "HumanoidRootPart", "LowerTorso" },
	{ "LeftShoulder", "UpperTorso", "LeftUpperArm" },
	{ "LeftElbow", "LeftUpperArm", "LeftLowerArm" },
	{ "LeftWrist", "LeftLowerArm", "LeftHand" },
	{ "RightShoulder", "UpperTorso", "RightUpperArm" },
	{ "RightElbow", "RightUpperArm", "RightLowerArm" },
	{ "RightWrist", "RightLowerArm", "RightHand" },
	{ "LeftHip", "LowerTorso", "LeftUpperLeg" },
	{ "LeftKnee", "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftAnkle", "LeftLowerLeg", "LeftFoot" },
	{ "RightHip", "LowerTorso", "RightUpperLeg" },
	{ "RightKnee", "RightUpperLeg", "RightLowerLeg" },
	{ "RightAnkle", "RightLowerLeg", "RightFoot" },
}

-- Builds the stand-in for Players:CreateHumanoidModelFromDescription
local function makeRig(description)
	local model = Instance.new("Model")
	model.Name = "Rig"
	local height = description.HeightScale
	local width = description.WidthScale
	local depth = description.DepthScale
	local headScale = description.HeadScale
	local parts = {}
	for _, spec in R15 do
		local name, size, position = spec[1], spec[2], spec[3]
		local part = Instance.new("Part")
		part.Name = name
		local scale = if name == "Head" then Vector3.new(headScale, headScale, headScale) else Vector3.new(width, height, depth)
		part.Size = size * scale
		local y = position.Y * height
		if name == "Head" then
			-- the head sits on top of the scaled torso
			y = (4.71 * height) + part.Size.Y / 2
		end
		part.CFrame = CFrame.new(position.X * width, y, position.Z * depth)
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.SmoothPlastic
		local colorKey = PART_COLOR[name]
		if colorKey then
			part.Color = description[colorKey]
		end
		if name == "HumanoidRootPart" then
			part.Transparency = 1
		end
		if name == "Head" then
			part:SetAttribute("PreviewShape", "Head")
			local face = Instance.new("Decal")
			face.Name = "face"
			face.Face = Enum.NormalId.Front
			face.Parent = part
		end
		part.Parent = model
		parts[name] = part
	end
	for _, joint in JOINTS do
		local name, part0, part1 = joint[1], parts[joint[2]], parts[joint[3]]
		local a0 = Instance.new("Attachment")
		a0.Name = name .. "RigAttachment"
		a0.CFrame = part0.CFrame:ToObjectSpace(part1.CFrame)
		a0.Parent = part0
		local a1 = Instance.new("Attachment")
		a1.Name = name .. "RigAttachment"
		a1.Parent = part1
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = a0.CFrame
		motor.Parent = part1
	end
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = model
	model.PrimaryPart = parts.HumanoidRootPart
	return model
end
World.makeRig = makeRig

local Players = {
	CreateHumanoidModelFromDescription = function(_, description)
		return makeRig(description)
	end,
	GetPlayers = function()
		return {}
	end,
	PlayerAdded = signal(),
	PlayerRemoving = signal(),
	LocalPlayer = nil,
}

local function stubService(name)
	return setmetatable({ Name = name }, {
		__index = function(_, key)
			if key:match("^[A-Z]") and (key:find("Added") or key:find("Removing") or key:find("Changed") or key == "Heartbeat" or key == "Stepped" or key == "RenderStepped") then
				return signal()
			end
			return function() end
		end,
	})
end

-- Folders of source modules -----------------------------------------------------

local datamodel = Instance.new("DataModel")
local workspaceInstance = datamodel:GetService("Workspace")
local arenas = Instance.new("Folder")
arenas.Name = "Arenas"
arenas.Parent = workspaceInstance
World.workspace = workspaceInstance

local moduleCache = {}
local makeNode

local function stripExtension(name)
	if name:match("%.server%.luau$") or name:match("%.client%.luau$") or name:match("%.server%.lua$") or name:match("%.client%.lua$") then
		return nil
	end
	return name:match("^(.+)%.luau$") or name:match("^(.+)%.lua$")
end

-- A node stands for a folder or ModuleScript made from one or more
-- directories laid over each other (later ones win, like this repo over the game)
local nodeMeta = {}

local function children(node)
	local known = rawget(node, "Children")
	if known then
		return known
	end
	local list = {}
	for _, dir in rawget(node, "Dirs") do
		if fs.isDir(dir) then
			for _, entry in fs.readDir(dir) do
				local full = dir .. "/" .. entry
				if fs.isDir(full) then
					local existing = list[entry]
					local dirs = if existing then existing.Dirs else {}
					table.insert(dirs, full)
					list[entry] = { Dirs = dirs }
				else
					local name = stripExtension(entry)
					if name and name ~= "init" then
						local existing = list[name]
						list[name] = { Dirs = if existing then existing.Dirs else {}, File = full }
					end
				end
			end
		end
	end
	local made = {}
	for name, info in list do
		made[name] = makeNode(name, node, info.Dirs, info.File)
	end
	rawset(node, "Children", made)
	return made
end

function makeNode(name, parent, dirs, file)
	local node = { Name = name, ParentNode = parent, Dirs = dirs, File = file }
	if not file then
		for _, dir in dirs do
			for _, init in { "init.luau", "init.lua" } do
				if fs.isFile(dir .. "/" .. init) then
					node.File = dir .. "/" .. init
				end
			end
		end
	end
	setmetatable(node, nodeMeta)
	-- Read the whole folder tree now: Lune's file calls can't run inside the
	-- metamethods that look children up later
	if #dirs > 0 then
		children(node)
	end
	return node
end

local NODE_METHODS = {
	WaitForChild = function(self, name)
		local child = children(self)[name]
		if not child then
			error(`Infinite yield: {self.Name} has no child named {name}`)
		end
		return child
	end,
	FindFirstChild = function(self, name)
		return children(self)[name]
	end,
	GetChildren = function(self)
		local list = {}
		for _, child in children(self) do
			table.insert(list, child)
		end
		return list
	end,
	IsA = function(self, className)
		return className == (if rawget(self, "File") then "ModuleScript" else "Folder") or className == "Instance"
	end,
	GetFullName = function(self)
		local names = {}
		local node = self
		while node do
			table.insert(names, 1, node.Name)
			node = rawget(node, "ParentNode")
		end
		return table.concat(names, ".")
	end,
}

nodeMeta.__index = function(self, key)
	if key == "Parent" then
		return rawget(self, "ParentNode")
	elseif key == "ClassName" then
		return if rawget(self, "File") then "ModuleScript" else "Folder"
	elseif NODE_METHODS[key] then
		return NODE_METHODS[key]
	end
	local child = children(self)[key]
	if child then
		return child
	end
	local extra = rawget(self, "Extra")
	if extra and extra[key] then
		return extra[key]
	end
	error(`{key} is not a valid member of {self.Name}`)
end
nodeMeta.__tostring = function(self)
	return self.Name
end

local remotes = setmetatable({}, {
	__index = function(self, name)
		local made = remote(name)
		rawset(self, name, made)
		return made
	end,
})

-- The game's folder first, then each models folder laid over it
local function overlay(folder)
	local dirs = { GAME_SRC .. "/" .. folder }
	for _, root in MODEL_SRCS do
		if root ~= "" then
			table.insert(dirs, root .. "/" .. folder)
		end
	end
	return dirs
end

local replicatedStorage = makeNode("ReplicatedStorage", nil, {})
replicatedStorage.Children = {
	Shared = makeNode("Shared", replicatedStorage, overlay("shared")),
	Remotes = setmetatable({ Name = "Remotes" }, {
		__index = function(_, key)
			if key == "WaitForChild" or key == "FindFirstChild" then
				return function(_, name)
					return remotes[name]
				end
			end
			return remotes[key]
		end,
	}),
}
local serverScriptService = makeNode("ServerScriptService", nil, {})
serverScriptService.Children = {
	Server = makeNode("Server", serverScriptService, overlay("server")),
}

local services = {
	ReplicatedStorage = replicatedStorage,
	ServerScriptService = serverScriptService,
	Workspace = workspaceInstance,
	Lighting = datamodel:GetService("Lighting"),
	ServerStorage = datamodel:GetService("ServerStorage"),
	CollectionService = CollectionService,
	Players = Players,
}

local game = setmetatable({}, {
	__index = function(_, key)
		if key == "GetService" or key == "FindService" then
			return function(_, name)
				services[name] = services[name] or stubService(name)
				return services[name]
			end
		elseif key == "Workspace" then
			return workspaceInstance
		elseif services[key] then
			return services[key]
		end
		return datamodel[key]
	end,
})
World.game = game

-- Running modules ---------------------------------------------------------------

local taskLib = {
	spawn = function(fn, ...)
		if type(fn) == "function" then
			local thread = coroutine.create(fn)
			coroutine.resume(thread, ...)
			return thread
		end
		return fn
	end,
	defer = function(fn, ...)
		return nil
	end,
	delay = function()
		return nil
	end,
	wait = function()
		return 0
	end,
	cancel = function() end,
	desynchronize = function() end,
	synchronize = function() end,
}

local requireNode
local makeEnvironment

-- Globals for a scenes file: the Roblox types, plus World itself
function World.sceneEnvironment()
	local env = makeEnvironment(nil)
	env.World = World
	return env
end

function makeEnvironment(node)
	return {
		game = game,
		workspace = workspaceInstance,
		script = node,
		require = function(target)
			if type(target) == "table" and getmetatable(target) == nodeMeta then
				return requireNode(target)
			end
			error("require() here only takes modules found through script or game:GetService")
		end,
		Instance = Instance,
		Vector3 = Vector3,
		Vector2 = roblox.Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		BrickColor = roblox.BrickColor,
		UDim = roblox.UDim,
		UDim2 = roblox.UDim2,
		Rect = roblox.Rect,
		Ray = roblox.Ray,
		Enum = Enum,
		Font = roblox.Font,
		NumberRange = roblox.NumberRange,
		NumberSequence = roblox.NumberSequence,
		NumberSequenceKeypoint = roblox.NumberSequenceKeypoint,
		ColorSequence = roblox.ColorSequence,
		ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
		PhysicalProperties = roblox.PhysicalProperties,
		Region3 = roblox.Region3,
		Faces = roblox.Faces,
		Axes = roblox.Axes,
		TweenInfo = { new = function(...)
			return { ... }
		end },
		Random = { new = function()
			return {
				NextNumber = function(_, a, b)
					a = a or 0
					b = b or 1
					return a + math.random() * (b - a)
				end,
				NextInteger = function(_, a, b)
					return math.random(a, b)
				end,
			}
		end },
		task = taskLib,
		tick = os.clock,
		time = os.clock,
		wait = taskLib.wait,
		delay = taskLib.delay,
		spawn = taskLib.spawn,
		warn = function(...)
			print("[warn]", ...)
		end,
		shared = {},
	}
end

function requireNode(node)
	local file = rawget(node, "File")
	if not file then
		error(`{node:GetFullName()} is a folder, not a module`)
	end
	if moduleCache[file] ~= nil then
		return moduleCache[file]
	end
	local source = fs.readFile(file)
	local chunk = luau.load(source, { debugName = file, environment = makeEnvironment(node) })
	local result = chunk()
	moduleCache[file] = result
	return result
end

-- Finds a module by its path in the game, like "ReplicatedStorage.Shared.Config"
function World.require(path)
	local parts = string.split(path, ".")
	local node = services[parts[1]] or error("Unknown service " .. parts[1])
	for index = 2, #parts do
		node = node[parts[index]]
	end
	return requireNode(node)
end

-- Helpers for scenes ---------------------------------------------------------------

-- An empty arena context, like Map.buildArena makes, centered on origin
function World.ctx(halfX, halfZ, mapId, theme)
	local model = Instance.new("Model")
	model.Name = mapId or "Preview"
	local ctx = {
		Model = model,
		Center = Vector3.new(0, 0, 0),
		HalfX = halfX or 40,
		HalfZ = halfZ or 40,
		MapId = mapId or "Preview",
		MapName = mapId or "Preview",
		Theme = theme or "Day",
	}
	for _, folderName in { "Structure", "Decor", "Bots" } do
		local folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = model
		ctx[folderName] = folder
	end
	model.Parent = arenas
	return ctx
end

-- Builds a gun the way the viewmodel does: every part placed at its offset
function World.gun(weaponId, skinId)
	local GunModels = World.require("ReplicatedStorage.Shared.GunModels")
	local model = Instance.new("Model")
	model.Name = weaponId
	for _, item in GunModels.makeParts(weaponId, skinId or "Default") do
		item.Part.CFrame = item.Offset
		item.Part.Anchored = true
		item.Part.Parent = model
	end
	return model
end

-- A stand-in R15 rig colored like a bot type
function World.rig(colors, scale)
	local description = Instance.new("HumanoidDescription")
	local skin = colors.Head or Color3.fromRGB(234, 184, 146)
	description.HeadColor = skin
	description.TorsoColor = colors.Torso
	description.LeftArmColor = colors.Arms or skin
	description.RightArmColor = colors.Arms or skin
	description.LeftLegColor = colors.Legs
	description.RightLegColor = colors.Legs
	if scale then
		description.HeightScale = scale
		description.WidthScale = scale
		description.DepthScale = scale
		description.HeadScale = scale
	end
	return makeRig(description)
end

-- The same gear helper Bots.luau uses: a welded, massless, unshootable part
function World.gear(rig, attachTo, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = attachTo.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = attachTo
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	part.Parent = rig
	return part
end

World.roblox = roblox
World.Vector3 = Vector3
World.CFrame = CFrame
World.Color3 = Color3
World.Enum = Enum
World.Instance = Instance

return World
