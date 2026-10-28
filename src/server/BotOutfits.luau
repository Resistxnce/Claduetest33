-- Outfits for the extra bot types and bosses (ConfigExtra/BotTypes) and for
-- the friendly lobby characters (LobbyNpcs.luau).
--
-- Bots.luau calls BotOutfits.dress(rig, typeName, gear) at the start of its
-- dressUp. It returns true when it dressed the bot, and false for types it
-- doesn't know (the game's own Noob, Tryhard, Admin...), which Bots.luau then
-- dresses as before. Bots.luau also adds BossLines to its boss trash talk.
-- LobbyNpcs.luau dresses its characters here too, and bends their arms by
-- Poses so they hold their props.
--
-- Every outfit is made of gear parts welded to the body, like the caps and
-- visors in Bots.luau. Sizes and spots below are for a normal-sized body and
-- get scaled to the real body part, so outfits still fit bigger bosses and
-- the Big Heads modifier. Pieces for a body part the rig doesn't have are
-- skipped.
local BotOutfits = {}

local rgb = Color3.fromRGB
local M = Enum.Material
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder

local PINK = rgb(255, 46, 99)
local WHITE = rgb(245, 245, 248)
local GOLD = rgb(255, 200, 60)
local AC_BLUE = rgb(60, 150, 255) -- the anti-cheat's color
local HAIR = { rgb(40, 30, 24), rgb(92, 60, 36), rgb(200, 150, 80), rgb(20, 20, 24), rgb(150, 70, 40) }
local GEAR_COLORS = { rgb(196, 40, 28), rgb(13, 105, 172), rgb(27, 27, 30), rgb(75, 151, 75), rgb(245, 205, 48) }

-- Cylinders lie along X. These turn one to stand up, or to point forward.
local UP = CFrame.Angles(0, 0, math.rad(90))
local FORWARD = CFrame.Angles(0, math.rad(90), 0)

-- How far the lobby characters bend their forearm up to hold their prop
-- (degrees). LobbyNpcs bends the elbow by this much (see Poses below), and
-- the prop is turned back by the same amount so it stays level.
local VENDOR_ELBOW = 115
local CURATOR_ELBOW = 95
local HOST_ELBOW = 85

-- The body part sizes the outfits are drawn for (a normal R15 body)
local BASE_SIZE = {
	Head = Vector3.new(1.2, 1.2, 1.2),
	UpperTorso = Vector3.new(2, 1.6, 1),
	LowerTorso = Vector3.new(2, 0.4, 1),
	UpperArm = Vector3.new(1, 1.17, 1),
	LowerArm = Vector3.new(1, 1.05, 1),
	Hand = Vector3.new(1, 0.3, 1),
	UpperLeg = Vector3.new(1, 1.22, 1),
	LowerLeg = Vector3.new(1, 1.19, 1),
	Foot = Vector3.new(1, 0.3, 1),
}

local function pick(list)
	return list[math.random(#list)]
end

-- A small random nudge, so no two bots look exactly alike
local function wobble(amount)
	return (math.random() - 0.5) * 2 * amount
end

local function deg(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y or 0), math.rad(z or 0))
end

-- Gear is welded on, can't be shot (shots go through to the body) and weighs
-- nothing. The same helper as Bots.luau's, so LobbyNpcs can dress rigs too.
function BotOutfits.gear(rig, attachTo, name, size, offset, color, material, shape)
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

-- Makes add(bodyPart, name, size, offset, color, material, shape) for one
-- rig. A turned piece gets one even scale so it keeps its shape.
local function outfitFor(rig, gear)
	return function(bodyName, name, size, offset, color, material, shape)
		local body = rig:FindFirstChild(bodyName)
		local base = BASE_SIZE[string.match(bodyName, "^Left(.+)") or string.match(bodyName, "^Right(.+)") or bodyName]
		if not body or not base then
			return nil
		end
		local scale = body.Size / base
		if offset.Rotation == CFrame.identity then
			size *= scale
		else
			size *= (scale.X + scale.Y + scale.Z) / 3
		end
		return gear(rig, body, name, size, CFrame.new(offset.Position * scale) * offset.Rotation, color, material, shape)
	end
end

-- Rounds a box piece into an egg shape (helmets, pauldrons, ponytails)
local function round(part)
	if part then
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
	end
	return part
end

-- Bold text on one face of a piece (badges, bibs, patches)
local function label(part, face, text, color)
	if not part then
		return
	end
	local surface = Instance.new("SurfaceGui")
	surface.Face = face
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 100
	surface.LightInfluence = 0
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.fromScale(0.06, 0.1)
	textLabel.Size = UDim2.fromScale(0.88, 0.8)
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextScaled = true
	textLabel.TextColor3 = color
	textLabel.Text = text
	textLabel.Parent = surface
	surface.Parent = part
end

-- A pair of shoes, with soles in another color if soleColor is given
local function shoes(add, size, color, soleColor)
	for _, side in { "Left", "Right" } do
		add(side .. "Foot", "Shoe", size, CFrame.new(0, 0.05, -0.08), color)
		if soleColor then
			add(side .. "Foot", "Sole", Vector3.new(size.X + 0.02, 0.1, size.Z + 0.02), CFrame.new(0, -0.1, -0.08), soleColor)
		end
	end
end

local OUTFITS = {}

-- Regular bots (24 gear parts at most) -------------------------------------------

local LEAF_GREENS = { rgb(74, 99, 52), rgb(98, 126, 58), rgb(54, 76, 40), rgb(126, 132, 72), rgb(86, 110, 44), rgb(110, 96, 60) }

-- A clump of leaves: a lumpy ball in a random green
local function leaves(add, bodyName, size, spot)
	return round(add(bodyName, "LeafClump", Vector3.new(size * (1 + wobble(0.15)), size * (0.8 + wobble(0.1)), size * (1 + wobble(0.15))), spot, pick(LEAF_GREENS), M.Grass))
end

-- Bush suit: a leafy hood with a twig, a camo face mask, and leaf clumps
-- all over the body so it looks like a bush from far away
function OUTFITS.Camper(add)
	round(add("Head", "GhillieHood", Vector3.new(1.56, 0.95, 1.58), CFrame.new(0, 0.42, 0.04), pick(LEAF_GREENS), M.Grass))
	add("Head", "GhillieDrape", Vector3.new(1.38, 1.1, 0.34), CFrame.new(0, -0.1, 0.56), pick(LEAF_GREENS), M.Grass)
	add("Head", "FaceMask", Vector3.new(1.26, 0.4, 1.26), CFrame.new(0, -0.32, 0), rgb(66, 84, 48), M.Fabric)
	leaves(add, "Head", 0.75, CFrame.new(-0.42 + wobble(0.05), 0.78, -0.1 + wobble(0.1)))
	leaves(add, "Head", 0.7, CFrame.new(0.4 + wobble(0.05), 0.74, 0.1 + wobble(0.1)))
	leaves(add, "Head", 0.8, CFrame.new(wobble(0.1), 0.86, 0.4))
	local twig = CFrame.new(0.3, 1.05, 0.15) * deg(8, 0, -20)
	add("Head", "Twig", Vector3.new(0.08, 0.8, 0.08), twig, rgb(92, 70, 46), M.Wood)
	leaves(add, "Head", 0.4, twig * CFrame.new(0, 0.42, 0))

	add("UpperTorso", "GhillieVest", Vector3.new(2.16, 1.66, 1.16), CFrame.new(0, 0.02, 0), pick(LEAF_GREENS), M.Grass)
	for _, side in { -1, 1 } do
		leaves(add, "UpperTorso", 1.05, CFrame.new(side * 0.78, 0.72, wobble(0.1)))
		leaves(add, "UpperTorso", 0.95, CFrame.new(side * 0.45 + wobble(0.1), wobble(0.2), 0.55))
	end
	leaves(add, "UpperTorso", 0.75, CFrame.new(-0.45, -0.35, -0.55))
	add("LowerTorso", "GhillieSkirt", Vector3.new(2.24, 0.8, 1.24), CFrame.new(0, -0.25, 0), pick(LEAF_GREENS), M.Grass)

	for _, side in { "Left", "Right" } do
		local sign = if side == "Left" then -1 else 1
		leaves(add, side .. "UpperArm", 0.8, CFrame.new(sign * 0.4, 0.1, wobble(0.15)))
		add(side .. "LowerArm", "ArmWrap", Vector3.new(1.14, 0.8, 1.14), CFrame.new(0, 0.05, 0), pick(LEAF_GREENS), M.Grass)
		leaves(add, side .. "UpperLeg", 0.75, CFrame.new(sign * 0.42, wobble(0.2), -0.1))
	end
	shoes(add, Vector3.new(1.08, 0.42, 1.18), rgb(60, 46, 32))
end

local HYPE = { PINK, rgb(60, 220, 255), rgb(170, 255, 60), rgb(255, 170, 30) }

-- Big glowing headset with a mic, a webcam clipped on top and a LIVE badge
function OUTFITS.Streamer(add)
	local hype = pick(HYPE)
	local dark = rgb(24, 24, 30)
	local trim = rgb(66, 26, 150)
	add("Head", "HeadsetBand", Vector3.new(1.56, 0.2, 0.34), CFrame.new(0, 0.62, 0.05), dark)
	for _, side in { -1, 1 } do
		add("Head", "HeadsetCup", Vector3.new(0.34, 0.92, 0.92), CFrame.new(side * 0.74, 0.04, 0.05), dark, M.SmoothPlastic, CYLINDER)
		add("Head", "HeadsetGlow", Vector3.new(0.06, 0.62, 0.62), CFrame.new(side * 0.92, 0.02, 0.05), hype, M.Neon, CYLINDER)
	end
	local micStart, micEnd = Vector3.new(-0.74, -0.2, -0.2), Vector3.new(-0.24, -0.32, -0.74)
	add("Head", "MicBoom", Vector3.new(0.08, 0.08, (micEnd - micStart).Magnitude), CFrame.lookAt((micStart + micEnd) / 2, micEnd), dark)
	add("Head", "Mic", Vector3.one * 0.22, CFrame.new(micEnd), rgb(50, 50, 58), M.SmoothPlastic, BALL)
	add("Head", "Webcam", Vector3.new(0.5, 0.26, 0.26), CFrame.new(0, 0.86, -0.2), dark)
	add("Head", "WebcamLens", Vector3.new(0.06, 0.18, 0.18), CFrame.new(0, 0.86, -0.34) * FORWARD, rgb(40, 80, 150), M.SmoothPlastic, CYLINDER)
	add("Head", "WebcamLight", Vector3.new(0.07, 0.07, 0.04), CFrame.new(0.17, 0.92, -0.34), rgb(255, 30, 40), M.Neon)

	add("UpperTorso", "LiveBadgeBack", Vector3.new(0.8, 0.4, 0.05), CFrame.new(0.52, 0.42, -0.52), WHITE)
	label(add("UpperTorso", "LiveBadge", Vector3.new(0.7, 0.3, 0.05), CFrame.new(0.52, 0.42, -0.55), rgb(255, 30, 50), M.Neon), Enum.NormalId.Front, "LIVE", WHITE)
	add("UpperTorso", "HoodDown", Vector3.new(1.8, 0.5, 0.66), CFrame.new(0, 0.84, 0.32), trim, M.Fabric)
	add("UpperTorso", "Pocket", Vector3.new(1.3, 0.46, 0.06), CFrame.new(0, -0.5, -0.52), trim, M.Fabric)
	for _, side in { -1, 1 } do
		add("UpperTorso", "Drawstring", Vector3.new(0.07, 0.5, 0.05), CFrame.new(side * 0.12, 0.5, -0.52), WHITE)
	end
	label(add("UpperTorso", "BackPrint", Vector3.new(1.5, 0.5, 0.04), CFrame.new(0, -0.1, 0.52), trim, M.Fabric), Enum.NormalId.Back, "FOLLOW", hype)
	for _, side in { "Left", "Right" } do
		add(side .. "UpperArm", "SleeveStripe", Vector3.new(1.04, 0.16, 1.04), CFrame.new(0, 0.05, 0), hype, M.Neon)
	end
	shoes(add, Vector3.new(1.08, 0.44, 1.22), WHITE, hype)
end

-- A Noob on the outside. The tells: one small pro item and a hidden rank pin.
function OUTFITS.Smurf(add)
	local band = rgb(24, 24, 28)
	local capped = math.random() < 0.3
	if capped then
		-- the same cap Noobs sometimes wear
		local color = pick(GEAR_COLORS)
		add("Head", "Cap", Vector3.new(1.25, 0.38, 1.25), CFrame.new(0, 0.48, 0), color)
		add("Head", "CapBrim", Vector3.new(1.08, 0.07, 0.6), CFrame.new(0, 0.37, -0.82), color)
	end
	local tell = if capped then 3 else math.random(3)
	if tell == 1 then
		add("Head", "Sweatband", Vector3.new(1.26, 0.18, 1.26), CFrame.new(0, 0.34, 0), band, M.Fabric)
		add("Head", "SweatbandLogo", Vector3.new(0.2, 0.08, 0.04), CFrame.new(0, 0.34, -0.64), GOLD, M.Neon)
		add("Head", "SweatbandKnot", Vector3.new(0.2, 0.2, 0.12), CFrame.new(0, 0.34, 0.66), band, M.Fabric)
		for _, side in { -1, 1 } do
			add("Head", "SweatbandTail", Vector3.new(0.1, 0.46, 0.04), CFrame.new(side * 0.12, 0.12, 0.7) * deg(0, 0, side * 14), band, M.Fabric)
		end
	elseif tell == 2 then
		add("Head", "ProVisorFrame", Vector3.new(0.9, 0.2, 0.06), CFrame.new(0, 0.12, -0.62), band)
		add("Head", "ProVisor", Vector3.new(0.8, 0.1, 0.04), CFrame.new(0, 0.12, -0.66), GOLD, M.Neon)
	else
		for _, side in { "Left", "Right" } do
			add(side .. "LowerArm", "Wristband", Vector3.new(1.06, 0.24, 1.06), CFrame.new(0, -0.38, 0), band, M.Fabric)
			add(side .. "LowerArm", "WristbandLogo", Vector3.new(0.3, 0.08, 0.04), CFrame.new(0, -0.38, -0.54), GOLD, M.Neon)
		end
	end
	-- A tiny Champion pin, easy to miss
	add("UpperTorso", "RankPin", Vector3.new(0.2, 0.2, 0.05), CFrame.new(-0.55, 0.45, -0.52) * deg(0, 0, 45), GOLD, M.Neon)
end

-- Running goggles, a bib, a trailing scarf, a glowing split timer and sneakers
function OUTFITS.Speedrunner(add)
	local hair = pick(HAIR)
	local shoe = pick({ rgb(170, 255, 60), rgb(60, 220, 255), PINK })
	local dark = rgb(30, 30, 36)
	local scarf = rgb(255, 214, 40)
	add("Head", "Hair", Vector3.new(1.26, 0.3, 1.28), CFrame.new(0, 0.5, 0.03), hair)
	for _, side in { -1, 1 } do
		add("Head", "HairSpike", Vector3.new(0.46, 0.26, 0.7), CFrame.new(side * 0.22, 0.6, 0.38) * deg(-28, side * 12, 0), hair)
	end
	add("Head", "GoggleStrap", Vector3.new(1.26, 0.16, 1.26), CFrame.new(0, 0.14, 0), dark)
	add("Head", "GoggleFrame", Vector3.new(0.96, 0.36, 0.14), CFrame.new(0, 0.12, -0.62), rgb(46, 46, 54))
	for _, side in { -1, 1 } do
		add("Head", "GoggleLens", Vector3.new(0.08, 0.3, 0.3), CFrame.new(side * 0.22, 0.12, -0.7) * FORWARD, rgb(80, 220, 255), M.Neon, CYLINDER)
		add("Head", "GoggleFin", Vector3.new(0.06, 0.16, 0.44), CFrame.new(side * 0.65, 0.2, -0.3) * deg(-14, 0, 0), shoe)
	end

	label(add("UpperTorso", "Bib", Vector3.new(0.9, 0.62, 0.05), CFrame.new(0, -0.12, -0.53), WHITE), Enum.NormalId.Front, "ANY%", rgb(20, 20, 24))
	for _, side in { -1, 1 } do
		add("UpperTorso", "Stripe", Vector3.new(0.14, 1.62, 1.04), CFrame.new(side * 0.88, 0, 0), WHITE)
	end
	add("UpperTorso", "Scarf", Vector3.new(1.3, 0.28, 1.12), CFrame.new(0, 0.86, 0), scarf, M.Fabric)
	add("UpperTorso", "ScarfTail", Vector3.new(0.34, 0.1, 1.2), CFrame.new(0.3, 0.74, 1.05) * deg(18, 10, 0), scarf, M.Fabric)
	add("UpperTorso", "ScarfTail", Vector3.new(0.3, 0.1, 0.95), CFrame.new(0.05, 0.62, 0.95) * deg(28, -6, 0), rgb(240, 186, 30), M.Fabric)

	add("LeftLowerArm", "TimerBand", Vector3.new(1.08, 0.32, 1.08), CFrame.new(0, -0.3, 0), dark)
	label(add("LeftLowerArm", "SplitTimer", Vector3.new(0.72, 0.3, 0.06), CFrame.new(0, -0.3, -0.56), rgb(40, 255, 130), M.Neon), Enum.NormalId.Front, "0:42.7", rgb(10, 30, 16))
	for _, side in { "Left", "Right" } do
		add(side .. "LowerLeg", "Sock", Vector3.new(1.06, 0.36, 1.06), CFrame.new(0, -0.42, 0), WHITE, M.Fabric)
	end
	shoes(add, Vector3.new(1.1, 0.42, 1.3), shoe, WHITE)
end

local HOODIES = { rgb(92, 94, 108), rgb(150, 36, 48), rgb(40, 62, 128), rgb(62, 112, 60) }

-- Baggy hoodie with the hood up, a laptop backpack and a giant energy drink
function OUTFITS.ScriptKiddie(add)
	local hoodie = pick(HOODIES)
	local lining = hoodie:Lerp(rgb(0, 0, 0), 0.45)
	local bag = rgb(30, 30, 34)
	add("Head", "HoodTop", Vector3.new(1.46, 0.3, 1.46), CFrame.new(0, 0.6, 0.06), hoodie, M.Fabric)
	for _, side in { -1, 1 } do
		add("Head", "HoodSide", Vector3.new(0.16, 1.26, 1.34), CFrame.new(side * 0.72, 0, 0.08), hoodie, M.Fabric)
	end
	add("Head", "HoodBack", Vector3.new(1.46, 1.36, 0.2), CFrame.new(0, -0.02, 0.72), hoodie, M.Fabric)
	add("Head", "HoodRim", Vector3.new(1.3, 0.18, 0.2), CFrame.new(0, 0.46, -0.66), lining, M.Fabric)

	add("UpperTorso", "Hoodie", Vector3.new(2.3, 1.96, 1.3), CFrame.new(0, -0.18, 0.02), hoodie, M.Fabric)
	add("UpperTorso", "HoodieHem", Vector3.new(2.32, 0.18, 1.32), CFrame.new(0, -1.08, 0.02), lining, M.Fabric)
	add("UpperTorso", "Pocket", Vector3.new(1.3, 0.5, 0.06), CFrame.new(0, -0.68, -0.65), lining, M.Fabric)
	label(add("UpperTorso", "Logo", Vector3.new(0.9, 0.3, 0.04), CFrame.new(0, -0.12, -0.66), hoodie, M.Fabric), Enum.NormalId.Front, "GG EZ", rgb(140, 255, 60))
	for _, side in { -1, 1 } do
		add("UpperTorso", "Drawstring", Vector3.new(0.07, 0.55, 0.05), CFrame.new(side * 0.24, 0.42, -0.67), WHITE)
		add("UpperTorso", "Strap", Vector3.new(0.26, 1.5, 0.08), CFrame.new(side * 0.58, 0.1, -0.68), bag, M.Fabric)
	end
	for _, side in { "Left", "Right" } do
		add(side .. "UpperArm", "Sleeve", Vector3.new(1.2, 1.24, 1.2), CFrame.new(0, 0.02, 0), hoodie, M.Fabric)
		add(side .. "LowerArm", "Sleeve", Vector3.new(1.18, 1.16, 1.18), CFrame.new(0, -0.12, 0), hoodie, M.Fabric)
	end

	add("UpperTorso", "Backpack", Vector3.new(1.5, 1.4, 0.5), CFrame.new(0, -0.1, 0.9), bag, M.Fabric)
	add("UpperTorso", "Laptop", Vector3.new(1.28, 0.95, 0.1), CFrame.new(0, 0.7, 0.86), rgb(196, 200, 210), M.Metal)
	add("UpperTorso", "LaptopSticker", Vector3.new(0.3, 0.3, 0.03), CFrame.new(0.28, 0.8, 0.92) * deg(0, 0, 12), PINK, M.Neon)
	-- The energy drink, clipped to the belt
	local can = CFrame.new(-0.95, -0.3, -0.82)
	add("LowerTorso", "EnergyDrink", Vector3.new(1, 0.56, 0.56), can * UP, rgb(24, 24, 28), M.Metal, CYLINDER)
	add("LowerTorso", "DrinkStripe", Vector3.new(0.38, 0.58, 0.58), can * CFrame.new(0, 0.05, 0) * UP, rgb(140, 255, 60), M.Neon, CYLINDER)
	add("LowerTorso", "DrinkLid", Vector3.new(0.06, 0.5, 0.5), can * CFrame.new(0, 0.52, 0) * UP, rgb(200, 205, 212), M.Metal, CYLINDER)
end

-- Anti-cheat field agent: round helmet with a visor, armored vest with a
-- badge, shoulder pads and a belt with pouches
function OUTFITS.Enforcer(add)
	local armor = rgb(66, 76, 98)
	local plate = rgb(100, 112, 138)
	local black = rgb(20, 22, 28)
	round(add("Head", "Helmet", Vector3.new(1.44, 1, 1.48), CFrame.new(0, 0.34, 0.02), armor))
	add("Head", "HelmetRim", Vector3.new(0.12, 1.5, 1.5), CFrame.new(0, 0.3, 0.02) * UP, plate, M.Metal, CYLINDER)
	local visor = add("Head", "Visor", Vector3.new(1.08, 0.38, 0.1), CFrame.new(0, 0.06, -0.66), black)
	if visor then
		visor.Reflectance = 0.2
	end
	add("Head", "VisorScan", Vector3.new(1, 0.05, 0.04), CFrame.new(0, 0.06, -0.72), AC_BLUE, M.Neon)
	add("Head", "Beacon", Vector3.new(0.34, 0.16, 0.22), CFrame.new(0, 0.86, 0.05), AC_BLUE, M.Neon)
	add("Head", "Radio", Vector3.new(0.22, 0.4, 0.32), CFrame.new(0.76, -0.02, 0.06), black)
	add("Head", "Antenna", Vector3.new(0.05, 0.7, 0.05), CFrame.new(0.8, 0.5, 0.14), black)

	add("UpperTorso", "Vest", Vector3.new(2.16, 1.5, 1.22), CFrame.new(0, 0, 0), armor)
	add("UpperTorso", "ChestPlate", Vector3.new(1.5, 0.96, 0.1), CFrame.new(0, 0.12, -0.64), plate, M.Metal)
	add("UpperTorso", "Badge", Vector3.new(0.34, 0.26, 0.05), CFrame.new(0.42, 0.36, -0.71), GOLD, M.Neon)
	add("UpperTorso", "BadgeTip", Vector3.new(0.24, 0.24, 0.05), CFrame.new(0.42, 0.24, -0.71) * deg(0, 0, 45), GOLD, M.Neon)
	label(add("UpperTorso", "AcPatch", Vector3.new(0.5, 0.28, 0.04), CFrame.new(-0.42, 0.36, -0.71), AC_BLUE), Enum.NormalId.Front, "AC", WHITE)
	label(add("UpperTorso", "BackPatch", Vector3.new(1.7, 0.4, 0.04), CFrame.new(0, 0.38, 0.63), AC_BLUE), Enum.NormalId.Back, "ANTI-CHEAT", WHITE)

	for _, side in { "Left", "Right" } do
		local sign = if side == "Left" then -1 else 1
		local pad = CFrame.new(sign * 0.08, 0.5, 0) * deg(0, 0, -sign * 12)
		add(side .. "UpperArm", "ShoulderPad", Vector3.new(1.24, 0.42, 1.24), pad, armor)
		add(side .. "UpperArm", "PadStripe", Vector3.new(1.26, 0.08, 1.26), pad * CFrame.new(0, -0.1, 0), AC_BLUE, M.Neon)
		add(side .. "Hand", "Glove", Vector3.new(1.08, 0.36, 1.08), CFrame.new(), black)
		add(side .. "LowerLeg", "KneePad", Vector3.new(1.06, 0.5, 0.24), CFrame.new(0, 0.38, -0.52), armor)
	end
	add("LowerTorso", "Belt", Vector3.new(2.08, 0.32, 1.1), CFrame.new(), black)
	for _, side in { -1, 1 } do
		add("LowerTorso", "Pouch", Vector3.new(0.42, 0.42, 0.3), CFrame.new(side * 0.6, -0.04, -0.62), rgb(58, 62, 52), M.Fabric)
	end
end

-- Bosses (40 gear parts at most) -------------------------------------------------

-- Pink hair and ponytail, chunky X-ray goggles, a purple hoodie with an eye
-- on the front and an ESP box printed on the back
function OUTFITS.WallhackWendy(add)
	local hair = rgb(255, 110, 190)
	local hoodie = rgb(84, 34, 160)
	local lens = rgb(60, 230, 255)
	local metal = rgb(40, 40, 52)
	round(add("Head", "Hair", Vector3.new(1.44, 0.96, 1.46), CFrame.new(0, 0.3, 0.04), hair))
	add("Head", "HairBack", Vector3.new(1.34, 1.2, 0.3), CFrame.new(0, -0.12, 0.56), hair)
	add("Head", "Fringe", Vector3.new(1.1, 0.3, 0.18), CFrame.new(0.08, 0.36, -0.6) * deg(0, 0, -14), hair)
	for _, side in { -1, 1 } do
		add("Head", "SideLock", Vector3.new(0.24, 1.35, 0.55), CFrame.new(side * 0.68, -0.22, -0.18), hair)
	end
	add("Head", "HairTie", Vector3.one * 0.3, CFrame.new(0, 0.5, 0.74), lens, M.Neon, BALL)
	round(add("Head", "Ponytail", Vector3.new(0.5, 1.3, 0.46), CFrame.new(0, -0.08, 0.98) * deg(-14, 0, 0), hair))

	add("Head", "GoggleStrap", Vector3.new(1.28, 0.2, 1.28), CFrame.new(0, 0.1, 0.02), metal)
	for _, side in { -1, 1 } do
		add("Head", "GoggleEye", Vector3.new(0.3, 0.46, 0.46), CFrame.new(side * 0.25, 0.1, -0.72) * FORWARD, metal, M.Metal, CYLINDER)
		add("Head", "XrayLens", Vector3.new(0.06, 0.38, 0.38), CFrame.new(side * 0.25, 0.1, -0.88) * FORWARD, lens, M.Neon, CYLINDER)
		local beam = add("Head", "XrayBeam", Vector3.new(2.2, 0.14, 0.14), CFrame.new(side * 0.25, 0.1, -2) * FORWARD, lens, M.Neon, CYLINDER)
		if beam then
			beam.Transparency = 0.75
		end
	end
	add("Head", "GoggleBridge", Vector3.new(0.2, 0.1, 0.12), CFrame.new(0, 0.14, -0.72), metal)
	add("Head", "GoggleDial", Vector3.new(0.14, 0.26, 0.26), CFrame.new(0.68, 0.1, -0.2), metal, M.Metal, CYLINDER)
	add("Head", "DialLight", Vector3.new(0.04, 0.14, 0.14), CFrame.new(0.76, 0.1, -0.2), hair, M.Neon, CYLINDER)

	add("UpperTorso", "HoodDown", Vector3.new(1.8, 0.5, 0.66), CFrame.new(0, 0.84, 0.32), rgb(150, 96, 235), M.Fabric)
	add("UpperTorso", "Pocket", Vector3.new(1.3, 0.46, 0.06), CFrame.new(0, -0.52, -0.52), hoodie, M.Fabric)
	for _, side in { -1, 1 } do
		add("UpperTorso", "Drawstring", Vector3.new(0.07, 0.36, 0.05), CFrame.new(side * 0.16, 0.6, -0.52), WHITE)
	end
	round(add("UpperTorso", "EyeLogo", Vector3.new(0.86, 0.44, 0.06), CFrame.new(0, 0.12, -0.52), WHITE))
	add("UpperTorso", "EyePupil", Vector3.new(0.06, 0.26, 0.26), CFrame.new(0, 0.12, -0.55) * FORWARD, lens, M.Neon, CYLINDER)
	for _, y in { 0.45, -0.65 } do
		add("UpperTorso", "EspBox", Vector3.new(1.2, 0.07, 0.04), CFrame.new(0.06, y, 0.53), PINK, M.Neon)
	end
	for _, x in { -0.5, 0.62 } do
		add("UpperTorso", "EspBox", Vector3.new(0.07, 1.17, 0.04), CFrame.new(x, -0.1, 0.53), PINK, M.Neon)
	end
	add("UpperTorso", "EspHealth", Vector3.new(0.07, 0.8, 0.04), CFrame.new(-0.66, -0.25, 0.53), rgb(80, 225, 120), M.Neon)

	for _, side in { "Left", "Right" } do
		add(side .. "LowerArm", "Cuff", Vector3.new(1.06, 0.22, 1.06), CFrame.new(0, -0.42, 0), hoodie, M.Fabric)
		add(side .. "LowerLeg", "LegWarmer", Vector3.new(1.08, 0.6, 1.08), CFrame.new(0, -0.22, 0), hair, M.Fabric)
		add(side .. "Hand", "Glove", Vector3.new(1.06, 0.34, 1.06), CFrame.new(), rgb(24, 22, 30), M.Fabric)
	end
	shoes(add, Vector3.new(1.1, 0.5, 1.24), WHITE, hoodie)
end

-- Golden armor, glowing eyes, a crown halo floating over the head and a
-- shimmering spawn-protection bubble that never wears off
function OUTFITS.GodModeGary(add)
	local gold = rgb(240, 190, 60)
	local glow = rgb(255, 214, 90)
	local white = rgb(250, 246, 235)
	local radius = 0.78
	for index = 0, 5 do
		local spot = CFrame.new(0, 1.05, 0) * CFrame.Angles(0, index * math.pi / 3, 0) * CFrame.new(0, 0, -radius)
		add("Head", "HaloBar", Vector3.new(2 * radius * math.tan(math.pi / 6) + 0.06, 0.12, 0.12), spot, glow, M.Neon)
		add("Head", "HaloPoint", Vector3.new(0.22, 0.22, 0.08), spot * CFrame.new(0, 0.2, 0) * deg(0, 0, 45), glow, M.Neon)
	end
	for _, side in { -1, 1 } do
		add("Head", "GlowEye", Vector3.new(0.16, 0.1, 0.04), CFrame.new(side * 0.15, 0.12, -0.6), glow, M.Neon)
	end

	add("UpperTorso", "ChestPlate", Vector3.new(2.12, 1.18, 1.14), CFrame.new(0, 0.2, 0), gold, M.Foil)
	add("UpperTorso", "Emblem", Vector3.new(0.06, 0.72, 0.72), CFrame.new(0, 0.22, -0.58) * FORWARD, white, M.SmoothPlastic, CYLINDER)
	add("UpperTorso", "EmblemCore", Vector3.new(0.06, 0.46, 0.46), CFrame.new(0, 0.22, -0.61) * FORWARD, glow, M.Neon, CYLINDER)
	add("LowerTorso", "Belt", Vector3.new(2.1, 0.34, 1.12), CFrame.new(0, 0.02, 0), gold, M.Foil)
	label(add("LowerTorso", "Buckle", Vector3.new(0.7, 0.3, 0.06), CFrame.new(0, 0.02, -0.58), rgb(40, 30, 10)), Enum.NormalId.Front, "GOD", glow)
	local cape = CFrame.new(0, -0.6, 0.62) * deg(-6, 0, 0)
	add("UpperTorso", "Cape", Vector3.new(1.9, 2.7, 0.08), cape, white, M.Fabric)
	add("UpperTorso", "CapeTrim", Vector3.new(1.92, 0.14, 0.1), cape * CFrame.new(0, -1.32, 0), glow, M.Neon)

	for _, side in { "Left", "Right" } do
		local sign = if side == "Left" then -1 else 1
		round(add(side .. "UpperArm", "Pauldron", Vector3.new(1.4, 0.84, 1.34), CFrame.new(sign * 0.1, 0.48, 0), gold, M.Foil))
		add(side .. "UpperArm", "PauldronTrim", Vector3.new(0.08, 1.24, 1.24), CFrame.new(sign * 0.1, 0.28, 0) * UP, glow, M.Neon, CYLINDER)
		add(side .. "LowerArm", "Bracer", Vector3.new(1.1, 0.6, 1.1), CFrame.new(0, -0.15, 0), gold, M.Foil)
		add(side .. "LowerLeg", "Greave", Vector3.new(1.1, 0.8, 1.12), CFrame.new(0, 0.05, -0.02), gold, M.Foil)
		add(side .. "UpperLeg", "GlowEdge", Vector3.new(0.08, 1.1, 0.08), CFrame.new(sign * 0.52, 0, -0.52), glow, M.Neon)
		add(side .. "LowerLeg", "GlowEdge", Vector3.new(0.08, 1.0, 0.08), CFrame.new(sign * 0.56, 0.05, -0.58), glow, M.Neon)
	end
	shoes(add, Vector3.new(1.08, 0.4, 1.2), white, gold)
	local bubble = round(add("UpperTorso", "GodBubble", Vector3.new(4.6, 6.6, 3.2), CFrame.new(0, -0.6, 0), glow, M.ForceField))
	if bubble then
		bubble.Transparency = 0.55
		bubble.CastShadow = false
	end
end

-- Glowing rings orbiting the body, a visor headset and a portal on the back
function OUTFITS.TPTyler(add)
	local purple = rgb(190, 80, 255)
	local cyan = rgb(60, 220, 255)
	local metal = rgb(84, 88, 112)
	add("Head", "Hair", Vector3.new(1.26, 0.32, 1.28), CFrame.new(0, 0.5, 0.03), rgb(110, 44, 190))
	add("Head", "HairStreak", Vector3.new(0.24, 0.34, 1.3), CFrame.new(0.3, 0.51, 0.03), cyan)
	add("Head", "Headset", Vector3.new(1.28, 0.16, 1.28), CFrame.new(0, 0.2, 0.02), metal)
	add("Head", "Visor", Vector3.new(1.04, 0.2, 0.08), CFrame.new(0, 0.1, -0.65), purple, M.Neon)
	for _, side in { -1, 1 } do
		add("Head", "Fin", Vector3.new(0.08, 0.5, 0.34), CFrame.new(side * 0.68, 0.42, 0.12) * deg(-24, 0, -side * 10), metal)
	end

	local function ring(bodyName, center, radius, color)
		for index = 0, 5 do
			local spot = center * CFrame.Angles(0, index * math.pi / 3, 0) * CFrame.new(0, 0, -radius)
			add(bodyName, "OrbitRing", Vector3.new(2 * radius * math.tan(math.pi / 6) + 0.1, 0.1, 0.1), spot, color, M.Neon)
		end
	end
	ring("UpperTorso", CFrame.new(0, 0.1, 0) * deg(12, 0, 6), 2.15, purple)
	ring("LowerTorso", CFrame.new(0, -1.6, 0) * deg(-8, 0, -6), 1.3, cyan)

	-- layers from the back of the body outward: { name, width, distance, color, material }
	for _, layer in {
		{ "PortalRim", 2.3, 0.58, purple, M.Neon },
		{ "PortalVoid", 1.96, 0.62, rgb(24, 8, 48), M.SmoothPlastic },
		{ "PortalSwirl", 1.4, 0.66, rgb(120, 40, 200), M.Neon },
		{ "PortalCore", 0.8, 0.72, cyan, M.Neon },
		{ "PortalEye", 0.34, 0.76, WHITE, M.Neon },
	} do
		add("UpperTorso", layer[1], Vector3.new(0.06, layer[2], layer[2]), CFrame.new(0, 0.1, layer[3]) * FORWARD, layer[4], layer[5], CYLINDER)
	end
	for index = 0, 2 do
		local spin = CFrame.new(0, 0.1, 0.69) * CFrame.Angles(0, 0, index * math.pi * 2 / 3)
		add("UpperTorso", "SwirlArm", Vector3.new(0.8, 0.09, 0.04), spin * CFrame.new(0.35, 0.36, 0) * deg(0, 0, 28), cyan, M.Neon)
	end

	add("UpperTorso", "CoreRim", Vector3.new(0.06, 0.66, 0.66), CFrame.new(0, 0.18, -0.52) * FORWARD, metal, M.Metal, CYLINDER)
	add("UpperTorso", "Core", Vector3.new(0.06, 0.46, 0.46), CFrame.new(0, 0.18, -0.55) * FORWARD, cyan, M.Neon, CYLINDER)
	for _, side in { -1, 1 } do
		add("UpperTorso", "Harness", Vector3.new(0.16, 1.9, 0.05), CFrame.new(0, 0, -0.51) * deg(0, 0, side * 35), metal)
	end
	for _, side in { "Left", "Right" } do
		add(side .. "LowerArm", "Gauntlet", Vector3.new(1.1, 0.6, 1.1), CFrame.new(0, -0.15, 0), metal, M.Metal)
		add(side .. "LowerArm", "GauntletGlow", Vector3.new(1.12, 0.1, 1.12), CFrame.new(0, -0.15, 0), purple, M.Neon)
		add(side .. "UpperLeg", "LegLine", Vector3.new(0.08, 1.1, 0.08), CFrame.new(if side == "Left" then -0.5 else 0.5, 0, -0.5), cyan, M.Neon)
	end
	shoes(add, Vector3.new(1.1, 0.5, 1.2), metal, cyan)
end

-- Lobby characters ------------------------------------------------------------

-- Turns a held prop so it stays level while the forearm is bent up by
-- elbow degrees, then moves it to a spot measured from the hand (in studs:
-- up and forward as the character stands)
local function held(elbow, x, up, forward)
	return CFrame.new(0, -0.05, 0) * CFrame.Angles(math.rad(-elbow), 0, 0) * CFrame.new(x, up, -forward)
end

-- Skin Spin vendor: sun visor, pink apron and a tray of glowing skin cards
function OUTFITS.Vendor(add)
	local hair = pick(HAIR)
	add("Head", "Hair", Vector3.new(1.26, 0.3, 1.28), CFrame.new(0, 0.5, 0.03), hair)
	add("Head", "VisorBand", Vector3.new(1.28, 0.2, 1.28), CFrame.new(0, 0.34, 0), WHITE)
	add("Head", "VisorBrim", Vector3.new(1.12, 0.07, 0.6), CFrame.new(0, 0.28, -0.88) * deg(-8, 0, 0), PINK)
	add("Head", "VisorLogo", Vector3.new(0.34, 0.1, 0.04), CFrame.new(0, 0.34, -0.65), PINK, M.Neon)

	label(add("UpperTorso", "ApronBib", Vector3.new(1.2, 1.3, 0.06), CFrame.new(0, 0, -0.53), PINK, M.Fabric), Enum.NormalId.Front, "SKIN\nSPIN", WHITE)
	for _, side in { -1, 1 } do
		add("UpperTorso", "ApronStrap", Vector3.new(0.12, 0.45, 0.06), CFrame.new(side * 0.45, 0.78, -0.5) * deg(0, 0, side * 25), PINK, M.Fabric)
	end
	add("LowerTorso", "Apron", Vector3.new(1.8, 1.5, 0.06), CFrame.new(0, -0.5, -0.55), PINK, M.Fabric)
	add("LowerTorso", "ApronPocket", Vector3.new(1.1, 0.4, 0.04), CFrame.new(0, -0.6, -0.6), rgb(200, 30, 76), M.Fabric)
	add("LowerTorso", "ApronTie", Vector3.new(0.4, 0.28, 0.14), CFrame.new(0, 0, 0.56), PINK, M.Fabric)
	for _, side in { "Left", "Right" } do
		add(side .. "UpperArm", "Sleeve", Vector3.new(1.06, 0.6, 1.06), CFrame.new(0, 0.3, 0), WHITE)
	end

	local tray = held(VENDOR_ELBOW, 0, 0.22, 0.15)
	add("RightHand", "Tray", Vector3.new(2, 0.08, 1.4), tray, rgb(40, 40, 48), M.Metal)
	add("RightHand", "TrayGlow", Vector3.new(2.1, 0.05, 1.5), tray * CFrame.new(0, -0.04, 0), PINK, M.Neon)
	-- Skin cards standing on the tray, fanned out, one per rarity color
	local cards = { rgb(60, 140, 255), rgb(170, 80, 255), rgb(255, 170, 40), rgb(255, 50, 70), rgb(240, 240, 250) }
	for index, color in cards do
		local offset = index - 3
		local card = tray * CFrame.new(offset * 0.36, 0.34, 0.1 + math.abs(offset) * 0.1) * deg(-10, 0, -offset * 8)
		label(add("RightHand", "SkinCard", Vector3.new(0.34, 0.56, 0.05), card, color, M.Neon), Enum.NormalId.Front, "?", WHITE)
	end
	shoes(add, Vector3.new(1.06, 0.36, 1.18), rgb(36, 36, 42))
end

-- Trophy Hall curator: suit, bow tie, round glasses, mustache and a trophy
function OUTFITS.Curator(add)
	local suit = rgb(32, 34, 52)
	local lapel = rgb(22, 24, 38)
	local gray = rgb(178, 178, 186)
	local gold = rgb(240, 190, 60)
	local shine = rgb(255, 214, 90)
	add("Head", "Hair", Vector3.new(1.26, 0.26, 1.28), CFrame.new(0, 0.5, 0.04), gray)
	add("Head", "HairBack", Vector3.new(1.26, 0.6, 0.22), CFrame.new(0, 0.18, 0.56), gray)
	add("Head", "Mustache", Vector3.new(0.46, 0.1, 0.08), CFrame.new(0, -0.12, -0.6), gray)
	for _, side in { -1, 1 } do
		add("Head", "GlassesRim", Vector3.new(0.04, 0.32, 0.32), CFrame.new(side * 0.19, 0.12, -0.62) * FORWARD, gold, M.Metal, CYLINDER)
		local lens = add("Head", "GlassesLens", Vector3.new(0.04, 0.24, 0.24), CFrame.new(side * 0.19, 0.12, -0.645) * FORWARD, rgb(215, 235, 255), M.SmoothPlastic, CYLINDER)
		if lens then
			lens.Reflectance = 0.3
		end
	end
	add("Head", "GlassesBridge", Vector3.new(0.14, 0.04, 0.04), CFrame.new(0, 0.14, -0.64), gold, M.Metal)

	add("UpperTorso", "Shirt", Vector3.new(0.56, 0.9, 0.04), CFrame.new(0, 0.35, -0.51), WHITE)
	for _, side in { -1, 1 } do
		add("UpperTorso", "Lapel", Vector3.new(0.3, 1, 0.05), CFrame.new(side * 0.3, 0.3, -0.53) * deg(0, 0, -side * 16), lapel)
		add("UpperTorso", "BowTie", Vector3.new(0.26, 0.22, 0.08), CFrame.new(side * 0.16, 0.66, -0.56) * deg(0, 0, side * 10), rgb(196, 40, 28))
	end
	add("UpperTorso", "BowTieKnot", Vector3.new(0.12, 0.14, 0.1), CFrame.new(0, 0.66, -0.58), rgb(150, 24, 18))
	add("UpperTorso", "PocketSquare", Vector3.new(0.26, 0.12, 0.05), CFrame.new(-0.62, 0.38, -0.53), PINK)
	for _, y in { -0.15, -0.5 } do
		add("UpperTorso", "Button", Vector3.new(0.1, 0.1, 0.04), CFrame.new(0, y, -0.52), gold, M.Metal)
	end
	add("LowerTorso", "Coattail", Vector3.new(1.9, 0.9, 0.08), CFrame.new(0, -0.45, 0.52) * deg(-4, 0, 0), suit, M.Fabric)
	for _, side in { "Left", "Right" } do
		add(side .. "LowerArm", "ShirtCuff", Vector3.new(1.04, 0.14, 1.04), CFrame.new(0, -0.46, 0), WHITE)
	end

	local base = held(CURATOR_ELBOW, 0, 0.28, 0.05)
	add("LeftHand", "TrophyBase", Vector3.new(0.62, 0.26, 0.62), base, rgb(70, 44, 30), M.Wood)
	add("LeftHand", "TrophyPlaque", Vector3.new(0.34, 0.12, 0.04), base * CFrame.new(0, 0, -0.32), gold, M.Metal)
	add("LeftHand", "TrophyStem", Vector3.new(0.3, 0.18, 0.18), base * CFrame.new(0, 0.28, 0) * UP, gold, M.Foil, CYLINDER)
	round(add("LeftHand", "TrophyBowl", Vector3.new(0.68, 0.56, 0.68), base * CFrame.new(0, 0.6, 0), gold, M.Foil))
	add("LeftHand", "TrophyCup", Vector3.new(0.32, 0.68, 0.68), base * CFrame.new(0, 0.86, 0) * UP, gold, M.Foil, CYLINDER)
	add("LeftHand", "TrophyRim", Vector3.new(0.06, 0.74, 0.74), base * CFrame.new(0, 1.03, 0) * UP, shine, M.Neon, CYLINDER)
	for _, side in { -1, 1 } do
		add("LeftHand", "TrophyHandle", Vector3.new(0.1, 0.34, 0.1), base * CFrame.new(side * 0.42, 0.8, 0) * deg(0, 0, side * 15), gold, M.Foil)
	end
	add("LeftHand", "TrophyStar", Vector3.new(0.2, 0.2, 0.05), base * CFrame.new(0, 0.82, -0.35) * deg(0, 0, 45), shine, M.Neon)
	shoes(add, Vector3.new(1.06, 0.36, 1.2), rgb(20, 16, 14))
end

-- Queue host: striped referee shirt, cap, headset, a whistle on a lanyard and
-- a glowing clipboard showing the queue
function OUTFITS.QueueHost(add)
	local black = rgb(22, 22, 26)
	local silver = rgb(210, 214, 222)
	for _, x in { -0.75, -0.25, 0.25, 0.75 } do
		add("UpperTorso", "RefStripe", Vector3.new(0.2, 1.62, 1.04), CFrame.new(x, 0, 0), black)
	end
	add("UpperTorso", "Collar", Vector3.new(1.2, 0.14, 0.8), CFrame.new(0, 0.82, 0.02), black)
	for _, side in { "Left", "Right" } do
		add(side .. "UpperArm", "Sleeve", Vector3.new(1.06, 0.66, 1.06), CFrame.new(0, 0.28, 0), WHITE)
		add(side .. "UpperArm", "SleeveStripe", Vector3.new(0.22, 0.68, 1.08), CFrame.new(0, 0.28, 0), black)
	end
	for _, side in { -1, 1 } do
		add("UpperTorso", "Lanyard", Vector3.new(0.07, 0.72, 0.04), CFrame.new(side * 0.15, 0.48, -0.54) * deg(0, 0, -side * 25), PINK, M.Neon)
	end
	add("UpperTorso", "Whistle", Vector3.new(0.3, 0.2, 0.2), CFrame.new(0, 0.1, -0.62), silver, M.Metal, CYLINDER)
	add("UpperTorso", "WhistleTip", Vector3.new(0.18, 0.08, 0.12), CFrame.new(0.2, 0.14, -0.62), silver, M.Metal)

	add("Head", "Cap", Vector3.new(1.26, 0.36, 1.26), CFrame.new(0, 0.48, 0), black)
	add("Head", "CapBrim", Vector3.new(1.08, 0.07, 0.6), CFrame.new(0, 0.34, -0.82), black)
	add("Head", "Earpiece", Vector3.new(0.12, 0.38, 0.38), CFrame.new(0.66, 0, 0), black, M.SmoothPlastic, CYLINDER)
	local micStart, micEnd = Vector3.new(0.68, -0.1, -0.1), Vector3.new(0.26, -0.3, -0.66)
	add("Head", "MicBoom", Vector3.new(0.06, 0.06, (micEnd - micStart).Magnitude), CFrame.lookAt((micStart + micEnd) / 2, micEnd), black)
	add("Head", "Mic", Vector3.one * 0.14, CFrame.new(micEnd), PINK, M.Neon, BALL)

	-- Clipboard held up and tilted back so people in front can read it
	local board = held(HOST_ELBOW, 0.05, 0.62, 0.2) * deg(35, 0, 0)
	add("LeftHand", "Clipboard", Vector3.new(1, 1.3, 0.06), board, rgb(110, 76, 46), M.Wood)
	local screen = add("LeftHand", "ClipboardScreen", Vector3.new(0.84, 1, 0.04), board * CFrame.new(0, -0.08, -0.04), rgb(60, 200, 255), M.Neon)
	label(screen, Enum.NormalId.Front, "QUEUE\nOPEN", rgb(15, 15, 21))
	add("LeftHand", "ClipboardClip", Vector3.new(0.42, 0.14, 0.12), board * CFrame.new(0, 0.6, -0.05), silver, M.Metal)

	add("LowerTorso", "Belt", Vector3.new(2.06, 0.24, 1.06), CFrame.new(0, 0.04, 0), black)
	shoes(add, Vector3.new(1.06, 0.36, 1.18), black, WHITE)
end

-- How the lobby characters hold their props: joint name -> extra turn.
-- LobbyNpcs applies these to the rig's joints.
BotOutfits.Poses = {
	Vendor = { RightElbow = CFrame.Angles(math.rad(VENDOR_ELBOW), 0, 0) },
	Curator = { LeftElbow = CFrame.Angles(math.rad(CURATOR_ELBOW), 0, 0) },
	QueueHost = { LeftElbow = CFrame.Angles(math.rad(HOST_ELBOW), 0, 0) },
}

-- Boss trash talk, merged into Bots.luau's LINES.Boss
BotOutfits.BossLines = {
	WallhackWendy = {
		"I saw you through 3 walls",
		"peekaboo",
		"walls? never heard of them",
		"cute hiding spot",
		"your cover isn't covering",
		"I know where you're going",
	},
	GodModeGary = {
		"can't touch this",
		"my health bar is just for show",
		"you're doing 0 damage bro",
		"I literally can't die",
		"keep trying, it's funny",
		"infinite HP, infinite drip",
	},
	TPTyler = {
		"behind you. again.",
		"blink and I'm gone",
		"you're aiming where I was",
		"teleport go brrr",
		"too slow",
		"where'd I go? lol",
	},
}

-- Dresses rig as typeName. Returns true if it knew the type (the extra bots
-- and bosses, and the lobby characters), false if not.
function BotOutfits.dress(rig, typeName, gear)
	local outfit = OUTFITS[typeName]
	if not outfit then
		return false
	end
	outfit(outfitFor(rig, gear or BotOutfits.gear))
	return true
end

return BotOutfits
