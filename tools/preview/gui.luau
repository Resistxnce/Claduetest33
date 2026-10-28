-- Runs the game's client UI code in the pretend client (client.luau) and
-- writes every visible ScreenGui out as JSON for gui_render.mjs to draw.
--
--   lune run tools/preview/gui.luau <screens.luau> <outDir> [nameFilter]
--
-- A screens file returns function(Client) -> list of screens, where a screen is
--   { Name = "Lobby", Build = function() ... end }
-- plus optional settings:
--   Viewport = { 1280, 720 }   screen size in pixels (the camera's ViewportSize)
--   Inset = 58                 Roblox topbar height: 58 for today's topbar (what the game's
--                              screenshots show), 36 for the old one
--   Topbar = "new"             the Roblox buttons drawn on top: "new", "classic" (36px inset)
--                              or false; Roblox's health bar shows top right when hurt
--   Backdrop = "sky"           what's behind the UI: "sky", "lobby", "dark", "gradient",
--                              "none", a "#rrggbb" color, an image path (relative to the
--                              screens file) or { Image = path, Crop = { x, y, w, h }, Blur = 6, Dim = 0.15 }
--   Frames = 30                frames (60 per second) to run after Build, so RenderStepped
--                              code updates text and visibility
--   Touch = false              true pretends to be a phone (TouchEnabled)
-- The game's own BlurEffect and ColorCorrectionEffect (in Lighting or the
-- camera) are applied to the backdrop, like the menu blur in game. Screens
-- files see the Roblox types (Instance, UDim2, Enum, ...), Client and World.
-- Build runs in a fresh client each time (new player, PlayerGui and modules).
-- It requires client modules with Client.require, sets attributes, clicks
-- buttons and so on (see client.luau), then returns what to capture: a
-- ScreenGui, a list of them, or nothing for the whole PlayerGui.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local serde = require("@lune/serde")

local Client = require("./client")
local roblox = Client.roblox
local Enum = roblox.Enum

local args = process.args
local screensPath, outDir, filter = args[1], args[2], args[3]
if not screensPath or not outDir then
	print("usage: lune run tools/preview/gui.luau <screens.luau> <outDir> [nameFilter]")
	process.exit(2)
end
fs.writeDir(outDir)

local function num(value)
	if value ~= value then
		return 0
	end
	if value == math.huge or value > 1e9 then
		return 1e9
	elseif value == -math.huge or value < -1e9 then
		return -1e9
	end
	return math.floor(value * 10000 + 0.5) / 10000
end

local function color(c)
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

local function udim(u)
	return { num(u.Scale), num(u.Offset) }
end

local function udim2(u)
	return { num(u.X.Scale), num(u.X.Offset), num(u.Y.Scale), num(u.Y.Offset) }
end

local function vec2(v)
	return { num(v.X), num(v.Y) }
end

-- Some properties can't be read in Lune until they're set; those come back nil
local function read(item, key)
	local ok, value = pcall(function()
		return item[key]
	end)
	if ok then
		return value
	end
	return nil
end

local function enumName(value, default)
	if typeof(value) == "EnumItem" then
		return value.Name
	end
	return default
end

local function familyName(family)
	-- "rbxasset://fonts/families/GothamSSm.json" -> "GothamSSm"
	return string.match(family or "", "([^/]+)%.json$") or family or "LegacyArial"
end

local DEFAULT_FACE = "rbxasset://fonts/families/LegacyArial.json"

local function fontOf(item)
	local face = read(item, "FontFace")
	local enum = read(item, "Font")
	local enumLabel = enumName(enum)
	-- A FontFace that isn't the default was set on purpose; otherwise use Font
	if not face or face.Family == DEFAULT_FACE then
		if enum then
			local ok, converted = pcall(roblox.Font.fromEnum, enum)
			face = if ok then converted else face
		end
	end
	if not face then
		return { Family = "LegacyArial", Weight = 400, Italic = false, Enum = enumLabel or "Legacy" }
	end
	local weight = read(face, "Weight")
	return {
		Family = familyName(face.Family),
		Weight = if weight then weight.Value else 400,
		Italic = enumName(read(face, "Style")) == "Italic",
		Enum = enumLabel,
	}
end

local function sequenceColors(sequence)
	local list = {}
	for _, point in sequence.Keypoints do
		local c = color(point.Value)
		table.insert(list, { num(point.Time), c[1], c[2], c[3] })
	end
	return list
end

local function sequenceNumbers(sequence)
	local list = {}
	for _, point in sequence.Keypoints do
		table.insert(list, { num(point.Time), num(point.Value) })
	end
	return list
end

local function exportGradient(item)
	return {
		Enabled = read(item, "Enabled") ~= false,
		Color = sequenceColors(item.Color),
		Transparency = sequenceNumbers(item.Transparency),
		Rotation = num(item.Rotation),
		Offset = vec2(item.Offset),
	}
end

-- Constraint and layout objects become "mods" on their parent
local MODS = {
	UICorner = function(item)
		return { CornerRadius = udim(read(item, "CornerRadius") or roblox.UDim.new(0, 8)) }
	end,
	UIStroke = function(item)
		local gradient = item:FindFirstChildWhichIsA("UIGradient")
		return {
			Enabled = read(item, "Enabled") ~= false,
			Color = color(item.Color),
			Thickness = num(item.Thickness),
			Transparency = num(item.Transparency),
			ApplyStrokeMode = enumName(item.ApplyStrokeMode, "Contextual"),
			LineJoinMode = enumName(item.LineJoinMode, "Round"),
			Position = enumName(read(item, "BorderStrokePosition"), "Outer"),
			Gradient = if gradient then exportGradient(gradient) else nil,
		}
	end,
	UIGradient = exportGradient,
	UIPadding = function(item)
		return {
			Top = udim(item.PaddingTop),
			Bottom = udim(item.PaddingBottom),
			Left = udim(item.PaddingLeft),
			Right = udim(item.PaddingRight),
		}
	end,
	UIListLayout = function(item)
		return {
			FillDirection = enumName(item.FillDirection),
			Padding = udim(item.Padding),
			HorizontalAlignment = enumName(item.HorizontalAlignment),
			VerticalAlignment = enumName(item.VerticalAlignment),
			SortOrder = enumName(item.SortOrder),
			Wraps = read(item, "Wraps") == true,
			HorizontalFlex = enumName(read(item, "HorizontalFlex"), "None"),
			VerticalFlex = enumName(read(item, "VerticalFlex"), "None"),
			ItemLineAlignment = enumName(read(item, "ItemLineAlignment"), "Automatic"),
		}
	end,
	UIGridLayout = function(item)
		return {
			CellSize = udim2(item.CellSize),
			CellPadding = udim2(item.CellPadding),
			FillDirection = enumName(item.FillDirection),
			FillDirectionMaxCells = item.FillDirectionMaxCells,
			StartCorner = enumName(item.StartCorner),
			HorizontalAlignment = enumName(item.HorizontalAlignment),
			VerticalAlignment = enumName(item.VerticalAlignment),
			SortOrder = enumName(item.SortOrder),
		}
	end,
	UIPageLayout = function(item)
		return {
			FillDirection = enumName(item.FillDirection),
			Padding = udim(item.Padding),
			HorizontalAlignment = enumName(item.HorizontalAlignment),
			VerticalAlignment = enumName(item.VerticalAlignment),
			SortOrder = enumName(item.SortOrder),
		}
	end,
	UITableLayout = function(item)
		return {
			FillDirection = "Vertical",
			Padding = { num(item.Padding.Y.Scale), num(item.Padding.Y.Offset) },
			HorizontalAlignment = enumName(item.HorizontalAlignment),
			VerticalAlignment = enumName(item.VerticalAlignment),
			SortOrder = enumName(item.SortOrder),
		}
	end,
	UIAspectRatioConstraint = function(item)
		return {
			AspectRatio = num(item.AspectRatio),
			AspectType = enumName(item.AspectType),
			DominantAxis = enumName(item.DominantAxis),
		}
	end,
	UISizeConstraint = function(item)
		return { MinSize = vec2(item.MinSize), MaxSize = vec2(item.MaxSize) }
	end,
	UITextSizeConstraint = function(item)
		return { MinTextSize = item.MinTextSize, MaxTextSize = item.MaxTextSize }
	end,
	UIScale = function(item)
		return { Scale = num(item.Scale) }
	end,
	UIFlexItem = function(item)
		return {
			FlexMode = enumName(read(item, "FlexMode"), "None"),
			GrowRatio = num(read(item, "GrowRatio") or 0),
			ShrinkRatio = num(read(item, "ShrinkRatio") or 0),
		}
	end,
}
-- Where a layout lives on the parent's mods
local MOD_SLOT = { UITableLayout = "UIListLayout" }

local exportObject

-- GuiObjects inside a Folder still draw, as children of the folder's parent
local function exportChildren(item, path, stats, kids, mods)
	for _, child in item:GetChildren() do
		local className = child.ClassName
		if child:IsA("GuiObject") then
			local node = exportObject(child, path .. "." .. child.Name, stats)
			if node then
				table.insert(kids, node)
			end
		elseif MODS[className] then
			local enabled = read(child, "Enabled")
			if enabled ~= false or className == "UIGradient" or className == "UIStroke" then
				local slot = MOD_SLOT[className] or className
				if not mods[slot] then
					local ok, value = pcall(MODS[className], child)
					if ok then
						mods[slot] = value
						if className == "UITableLayout" then
							stats.warnings[#stats.warnings + 1] = path .. ": UITableLayout is drawn as a plain list"
						end
					else
						stats.warnings[#stats.warnings + 1] = `{path}.{child.Name}: couldn't read {className}: {value}`
					end
				end
			end
		elseif className == "Folder" or className == "Configuration" then
			exportChildren(child, path, stats, kids, mods)
		end
	end
end

local TEXT_CLASSES = { TextLabel = true, TextButton = true, TextBox = true }
local IMAGE_CLASSES = { ImageLabel = true, ImageButton = true }

function exportObject(item, path, stats)
	if read(item, "Visible") == false then
		stats.hidden += 1
		return nil
	end
	stats.objects += 1
	local className = item.ClassName
	local node = {
		Class = className,
		Name = item.Name,
		Path = path,
		Position = udim2(item.Position),
		Size = udim2(item.Size),
		AnchorPoint = vec2(item.AnchorPoint),
		Rotation = num(item.Rotation),
		ZIndex = item.ZIndex,
		LayoutOrder = item.LayoutOrder,
		BackgroundColor3 = color(item.BackgroundColor3),
		BackgroundTransparency = num(item.BackgroundTransparency),
		BorderSizePixel = item.BorderSizePixel,
		BorderColor3 = color(item.BorderColor3),
		BorderMode = enumName(read(item, "BorderMode"), "Outline"),
		ClipsDescendants = item.ClipsDescendants,
		AutomaticSize = enumName(item.AutomaticSize, "None"),
	}
	if TEXT_CLASSES[className] then
		node.Text = item.Text
		node.Font = fontOf(item)
		node.TextSize = num(item.TextSize)
		node.TextScaled = item.TextScaled
		node.TextWrapped = item.TextWrapped
		node.TextColor3 = color(item.TextColor3)
		node.TextTransparency = num(item.TextTransparency)
		node.TextStrokeColor3 = color(item.TextStrokeColor3)
		node.TextStrokeTransparency = num(item.TextStrokeTransparency)
		node.TextXAlignment = enumName(item.TextXAlignment, "Center")
		node.TextYAlignment = enumName(item.TextYAlignment, "Center")
		node.RichText = item.RichText
		node.TextTruncate = enumName(read(item, "TextTruncate"), "None")
		node.LineHeight = num(read(item, "LineHeight") or 1)
		node.MaxVisibleGraphemes = read(item, "MaxVisibleGraphemes") or -1
		if className == "TextBox" then
			node.PlaceholderText = read(item, "PlaceholderText") or ""
			node.PlaceholderColor3 = color(read(item, "PlaceholderColor3") or roblox.Color3.new(0.7, 0.7, 0.7))
		end
	elseif IMAGE_CLASSES[className] then
		node.Image = read(item, "Image") or ""
		node.ImageColor3 = color(item.ImageColor3)
		node.ImageTransparency = num(item.ImageTransparency)
		node.ScaleType = enumName(item.ScaleType, "Stretch")
	elseif className == "ScrollingFrame" then
		node.CanvasSize = udim2(item.CanvasSize)
		node.CanvasPosition = vec2(item.CanvasPosition)
		node.AutomaticCanvasSize = enumName(item.AutomaticCanvasSize, "None")
		node.ScrollBarThickness = item.ScrollBarThickness
		node.ScrollBarImageColor3 = color(item.ScrollBarImageColor3)
		node.ScrollBarImageTransparency = num(item.ScrollBarImageTransparency)
		node.ScrollingDirection = enumName(item.ScrollingDirection, "XY")
		node.VerticalScrollBarInset = enumName(item.VerticalScrollBarInset, "None")
		node.HorizontalScrollBarInset = enumName(item.HorizontalScrollBarInset, "None")
		node.VerticalScrollBarPosition = enumName(read(item, "VerticalScrollBarPosition"), "Right")
	elseif className == "CanvasGroup" then
		node.GroupTransparency = num(item.GroupTransparency)
		node.GroupColor3 = color(item.GroupColor3)
	elseif className == "ViewportFrame" or className == "VideoFrame" then
		local parts = 0
		for _, child in item:GetDescendants() do
			if child:IsA("BasePart") then
				parts += 1
			end
		end
		node.Parts = parts
		node.ImageColor3 = color(read(item, "ImageColor3") or roblox.Color3.new(1, 1, 1))
		node.ImageTransparency = num(read(item, "ImageTransparency") or 0)
	end
	local kids, mods = {}, {}
	exportChildren(item, path, stats, kids, mods)
	if next(mods) then
		node.Mods = mods
	end
	if #kids > 0 then
		node.Children = kids
	end
	return node
end

local function exportScreenGui(gui, stats)
	local kids, mods = {}, {}
	exportChildren(gui, gui.Name, stats, kids, mods)
	return {
		Name = gui.Name,
		Class = gui.ClassName,
		Enabled = read(gui, "Enabled") ~= false,
		DisplayOrder = read(gui, "DisplayOrder") or 0,
		IgnoreGuiInset = read(gui, "IgnoreGuiInset") == true,
		ZIndexBehavior = enumName(read(gui, "ZIndexBehavior"), "Sibling"),
		Children = if #kids > 0 then kids else nil,
		Mods = if next(mods) then mods else nil,
	}
end

-- What Build returned -> the ScreenGuis to draw
local function rootsOf(result)
	local roots = {}
	local function add(item)
		if typeof(item) ~= "Instance" then
			return
		end
		if item:IsA("LayerCollector") then
			if item:IsA("ScreenGui") then
				table.insert(roots, { Gui = item })
			end
		elseif item:IsA("GuiObject") then
			-- A single frame: drawn inside its own ScreenGui's settings
			local gui = item:FindFirstAncestorWhichIsA("ScreenGui")
			table.insert(roots, { Gui = gui, Only = item })
		else
			for _, child in item:GetChildren() do
				add(child)
			end
		end
	end
	if result == nil then
		add(Client.playerGui)
	elseif type(result) == "table" then
		for _, item in result do
			add(item)
		end
	else
		add(result)
	end
	return roots
end

local screensDir = string.match(screensPath, "^(.*)/[^/]*$") or "."

local function resolvePath(path)
	if string.sub(path, 1, 1) == "/" then
		return path
	end
	return screensDir .. "/" .. path
end

local function backdropOf(screen)
	local backdrop = screen.Backdrop or "sky"
	if type(backdrop) == "string" then
		if
			backdrop:match("%.[%a]+$")
			and (backdrop:find("/") or backdrop:match("%.png$") or backdrop:match("%.jpe?g$"))
		then
			backdrop = { Image = backdrop }
		else
			return { Kind = backdrop }
		end
	end
	local result = table.clone(backdrop)
	if result.Image then
		result.Image = resolvePath(result.Image)
		if not fs.isFile(result.Image) then
			print(`     ! backdrop image {result.Image} not found; using "sky"`)
			return { Kind = "sky" }
		end
		result.Kind = "image"
	end
	return result
end

-- Post effects on the 3D world (the menu blur, color correction), so the
-- backdrop behind the UI changes like the game world would
local function worldEffects()
	local effects = { Blur = 0, Brightness = 0, Contrast = 0, Saturation = 0, Tint = { 255, 255, 255 } }
	for _, root in { Client.lighting, Client.camera } do
		for _, item in root:GetChildren() do
			if read(item, "Enabled") ~= false then
				if item:IsA("BlurEffect") then
					effects.Blur += read(item, "Size") or 0
				elseif item:IsA("ColorCorrectionEffect") then
					effects.Brightness += read(item, "Brightness") or 0
					effects.Contrast += read(item, "Contrast") or 0
					effects.Saturation += read(item, "Saturation") or 0
					local tint = read(item, "TintColor")
					if tint then
						local c = color(tint)
						for index = 1, 3 do
							effects.Tint[index] = math.floor(effects.Tint[index] * c[index] / 255 + 0.5)
						end
					end
				end
			end
		end
	end
	effects.Blur = num(effects.Blur)
	effects.Brightness = num(effects.Brightness)
	effects.Contrast = num(effects.Contrast)
	effects.Saturation = num(effects.Saturation)
	return effects
end

-- The character's health, for Roblox's own health bar (shown when hurt)
local function coreHealth()
	local character = Client.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local starterGui = Client.getService("StarterGui")
	if not humanoid or not starterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health) then
		return nil
	end
	return { Health = num(read(humanoid, "Health") or 100), MaxHealth = num(read(humanoid, "MaxHealth") or 100) }
end

local loadScreens =
	luau.load(fs.readFile(screensPath), { debugName = screensPath, environment = Client.environment() })()
local screens = loadScreens(Client)
local failures, built = 0, 0
local BUILD_LIMIT = 600 -- frames (10 fake seconds) for Build to finish

for _, screen in screens do
	if filter and not string.find(screen.Name, filter, 1, true) then
		continue
	end
	math.randomseed(7)
	local inset = if screen.Inset ~= nil then screen.Inset elseif screen.Topbar == "classic" then 36 else 58
	if screen.Topbar == false then
		inset = screen.Inset or 0
	end
	Client.reset({
		Viewport = screen.Viewport,
		Inset = inset,
		Touch = screen.Touch,
		PlayerName = screen.PlayerName,
		DisplayName = screen.DisplayName,
	})
	local state = Client.spawn(screen.Build)
	local frames = 0
	while not state.Done and frames < BUILD_LIMIT do
		Client.step(1 / 60)
		frames += 1
	end
	if not state.Done then
		failures += 1
		print(
			`FAIL {screen.Name}: Build was still waiting after {BUILD_LIMIT / 60}s on: {table.concat(
				Client.waiting(),
				", "
			)}`
		)
		continue
	end
	if not state.Ok then
		failures += 1
		print(`FAIL {screen.Name}: {state.Result}`)
		continue
	end
	local extra = screen.Frames or 30
	if extra > 0 then
		Client.step(extra / 60)
	end
	Client.layout()

	local stats = { objects = 0, hidden = 0, warnings = {} }
	local guis = {}
	for _, root in rootsOf(state.Result) do
		if root.Only then
			local gui = if root.Gui
				then exportScreenGui(root.Gui, { objects = 0, hidden = 0, warnings = {} })
				else {
					Name = "Gui",
					Enabled = true,
					DisplayOrder = 0,
					IgnoreGuiInset = true,
					ZIndexBehavior = "Sibling",
				}
			local node = exportObject(root.Only, gui.Name .. "." .. root.Only.Name, stats)
			gui.Children = { node }
			table.insert(guis, gui)
		else
			table.insert(guis, exportScreenGui(root.Gui, stats))
		end
	end
	local viewport = Client.camera.ViewportSize
	local data = {
		name = screen.Name,
		viewport = { math.floor(viewport.X), math.floor(viewport.Y) },
		inset = inset,
		topbar = if screen.Topbar == nil then (if inset == 36 then "classic" else "new") else screen.Topbar,
		backdrop = backdropOf(screen),
		effects = worldEffects(),
		health = coreHealth(),
		guis = guis,
		stats = { objects = stats.objects, hidden = stats.hidden },
		warnings = stats.warnings,
		errors = Client.errors(),
	}
	fs.writeFile(outDir .. "/" .. screen.Name .. ".json", serde.encode("json", data))
	built += 1
	local errorCount = #Client.errors()
	local note = if errorCount > 0 then ` ({errorCount} client errors)` else ""
	print(`ok   {screen.Name}: {#guis} ScreenGuis, {stats.objects} visible objects{note}`)
	for _, text in stats.warnings do
		print("     ! " .. text)
	end
end
print(`{built} built, {failures} failed`)
process.exit(if failures > 0 then 1 else 0)
