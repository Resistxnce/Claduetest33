-- The effects your own gun makes on your screen: crisp tracers, a star muzzle
-- flash (when the first-person gun isn't showing), a smoke puff, shells that
-- fly out, tumble and fade, impacts that match what you hit (sparks on metal,
-- dust and chips on concrete, splinters on wood, dirt on grass, glints on
-- glass) with a small bullet hole, a headshot pop, and bigger explosions.
-- It's client-only: Effects.impact and Effects.explosion hand off to it on
-- the client. Particles come from a few reused emitters, shells and bullet
-- holes are pooled, and everything is capped so automatic guns can't flood
-- the workspace. Every effect runs guarded: if one ever errors, the error
-- still shows in the output, but the shot that called it goes on.
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GunEffects = {}

local rgb = Color3.fromRGB

-- League HQ colors (see direction/STYLE). Effects only use these, so every
-- flash and spark matches the menus.
GunEffects.PALETTE = {
	Violet = rgb(139, 92, 255), -- ESP Violet: cheats, energy guns
	Yellow = rgb(255, 210, 63), -- Go Yellow: sparks, headshots
	Flash = rgb(255, 214, 140), -- warm muzzle flash (STYLE section 6)
	Mint = rgb(52, 227, 154), -- Credit Mint: toxic shots, kill confetti
	Red = rgb(255, 59, 78), -- Ban Red: enemy hits, kills, the Ban Cannon
	Blue = rgb(61, 139, 255), -- Ref Blue: pulse and rail shots
	Chalk = rgb(242, 244, 248), -- Chalk: hot flash cores, smoke
	Brass = rgb(214, 168, 72), -- spent brass
	ShellRed = rgb(190, 38, 44), -- spent shotgun shells
	Hole = rgb(24, 24, 28), -- bullet holes
}
local PALETTE = GunEffects.PALETTE

local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local PIXEL_TEXTURE = "rbxasset://textures/particles/SquareParticle.png"

local MAX_TRACERS = 48 -- tracer parts alive at once
local MAX_SHELLS = 16 -- shells in the air at once (the oldest is reused)
local MAX_HOLES = 40 -- bullet holes at once (the oldest is reused)
local HOLE_LIFETIME = 10
local SHELL_LIFETIME = 0.8
local SHELL_GRAVITY = 70
local SMOKE_COLOR = rgb(205, 207, 214)

-- Shell looks: Size is a cylinder lying along X
local SHELLS = {
	Brass = { Size = Vector3.new(0.13, 0.05, 0.05), Color = PALETTE.Brass, Material = Enum.Material.Metal },
	Shell = { Size = Vector3.new(0.24, 0.1, 0.1), Color = PALETTE.ShellRed, Material = Enum.Material.SmoothPlastic },
	Big = { Size = Vector3.new(0.26, 0.09, 0.09), Color = PALETTE.Brass, Material = Enum.Material.Metal },
}

-- Which impact a surface gets
local SURFACE_NAMES = {
	Metal = { "Metal", "DiamondPlate", "CorrodedMetal", "Foil" },
	Stone = {
		"Concrete", "Brick", "Slate", "Cobblestone", "Granite", "Rock", "Pavement", "Asphalt", "Basalt",
		"Limestone", "Sandstone", "Marble", "Pebble", "Salt", "CrackedLava",
	},
	Wood = { "Wood", "WoodPlanks" },
	Dirt = { "Grass", "LeafyGrass", "Ground", "Sand", "Mud", "Snow" },
	Glass = { "Glass", "Ice", "Glacier", "Neon", "ForceField" },
}
local surfaceOf = {}
for surface, names in SURFACE_NAMES do
	for _, name in names do
		-- Older or newer Roblox versions may not have every material
		local ok, material = pcall(function()
			return Enum.Material[name]
		end)
		if ok and material then
			surfaceOf[material] = surface
		end
	end
end

local folder -- everything lives in workspace.GunEffects
local holder -- an invisible anchored part carrying the reused emitters
local emitters = {} -- [kind .. color] = { Kind, Attachment, Emitter, Used }
local emitterCount = 0
local MAX_EMITTERS = 64 -- past this, the oldest emitter of the same kind gets the new color instead of a new one being made
local tracerCount = 0
local shells = {} -- pooled { Part, Active, ... }
local shellIndex = 0
local holes = {} -- pooled { Part, ExpiresAt }
local holeIndex = 0
local flashParts -- the world muzzle flash star
local flashHideAt = 0
local stepConnection
local lastTink = 0
local onShellLand -- optional callback (GunSounds plays a tink)
local espColor = function() -- the player's ESP color, for enemy hits (GunFeel sets this)
	return PALETTE.Violet
end

local function fade(from, to)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) })
end

local function effectPart(name, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- The reused particle emitters. Each sits on its own attachment that's moved
-- to where the effect happens just before Emit(), so particles stay where
-- they were born (they're in world space). An emitter's Color applies to
-- its live particles too, so there's one emitter per kind and color (made
-- when first needed, up to MAX_EMITTERS).
local EMITTERS = {
	Sparks = {
		Texture = SPARK_TEXTURE, LightEmission = 1, LightInfluence = 0, Size = fade(0.22, 0),
		Lifetime = NumberRange.new(0.12, 0.3), Speed = NumberRange.new(14, 30), SpreadAngle = Vector2.new(55, 55),
		Acceleration = Vector3.new(0, -55, 0), Drag = 4, EmissionDirection = Enum.NormalId.Front,
	},
	Dust = {
		Texture = SMOKE_TEXTURE, LightInfluence = 1, Size = fade(0.35, 1.7), Transparency = fade(0.35, 1),
		Lifetime = NumberRange.new(0.35, 0.75), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(35, 35),
		Drag = 3, Acceleration = Vector3.new(0, 1.5, 0), EmissionDirection = Enum.NormalId.Front,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40),
	},
	Chips = {
		Texture = PIXEL_TEXTURE, LightInfluence = 1, Size = fade(0.13, 0.05),
		Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(8, 17), SpreadAngle = Vector2.new(50, 50),
		Acceleration = Vector3.new(0, -60, 0), Drag = 1.5, EmissionDirection = Enum.NormalId.Front,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-400, 400),
	},
	Glints = {
		Texture = SPARK_TEXTURE, LightEmission = 1, LightInfluence = 0, Size = fade(0.3, 0),
		Lifetime = NumberRange.new(0.2, 0.45), Speed = NumberRange.new(5, 12), SpreadAngle = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, -30, 0), Drag = 2, EmissionDirection = Enum.NormalId.Front,
	},
	Hit = {
		Texture = SPARK_TEXTURE, LightEmission = 1, LightInfluence = 0, Size = fade(0.4, 0),
		Lifetime = NumberRange.new(0.12, 0.28), Speed = NumberRange.new(8, 18), SpreadAngle = Vector2.new(60, 60),
		Drag = 6, EmissionDirection = Enum.NormalId.Front,
	},
	-- The "pixel hit" on enemies: square pixels that pop out and shrink
	Pixels = {
		Texture = PIXEL_TEXTURE, LightEmission = 0.6, LightInfluence = 0, Size = fade(0.25, 0),
		Lifetime = NumberRange.new(0.25, 0.45), Speed = NumberRange.new(5, 12), SpreadAngle = Vector2.new(65, 65),
		Drag = 5, Acceleration = Vector3.new(0, 4, 0), EmissionDirection = Enum.NormalId.Front,
		Rotation = NumberRange.new(0, 90),
	},
	Smoke = {
		Texture = SMOKE_TEXTURE, LightInfluence = 0.6, Size = fade(0.25, 1.1), Transparency = fade(0.55, 1),
		Lifetime = NumberRange.new(0.3, 0.55), Speed = NumberRange.new(1.5, 3.5), SpreadAngle = Vector2.new(15, 15),
		Drag = 5, Acceleration = Vector3.new(0, 2, 0), EmissionDirection = Enum.NormalId.Front,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-60, 60),
	},
	BlastSmoke = {
		Texture = SMOKE_TEXTURE, LightInfluence = 1, Size = fade(2, 6), Transparency = fade(0.3, 1),
		Lifetime = NumberRange.new(0.9, 1.6), Speed = NumberRange.new(3, 9), SpreadAngle = Vector2.new(180, 180),
		Drag = 2, Acceleration = Vector3.new(0, 4, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30),
	},
	Embers = {
		Texture = SPARK_TEXTURE, LightEmission = 1, LightInfluence = 0, Size = fade(0.35, 0),
		Lifetime = NumberRange.new(0.4, 0.9), Speed = NumberRange.new(18, 40), SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -45, 0), Drag = 2.5,
	},
}

local function stepEffects(dt)
	local now = os.clock()
	-- Shells: fly, tumble, bounce once off the floor and fade
	for _, shell in shells do
		if shell.Active then
			shell.Age += dt
			if shell.Age >= shell.Life then
				shell.Active = false
				shell.Part.Parent = nil
			else
				shell.Velocity += Vector3.new(0, -SHELL_GRAVITY * dt, 0)
				local position = shell.Position + shell.Velocity * dt
				if shell.FloorY and position.Y < shell.FloorY and shell.Velocity.Y < 0 then
					position = Vector3.new(position.X, shell.FloorY, position.Z)
					shell.Velocity = Vector3.new(shell.Velocity.X * 0.5, -shell.Velocity.Y * 0.3, shell.Velocity.Z * 0.5)
					shell.Spin *= 0.5
					if not shell.Bounced then
						shell.Bounced = true
						if onShellLand and now - lastTink > 0.12 then
							lastTink = now
							onShellLand(shell.Kind)
						end
					end
				end
				shell.Position = position
				shell.Rotation *= CFrame.fromAxisAngle(shell.Axis, shell.Spin * dt)
				shell.Part.CFrame = CFrame.new(position) * shell.Rotation
				local fadeStart = shell.Life - 0.25
				shell.Part.Transparency = if shell.Age > fadeStart then (shell.Age - fadeStart) / 0.25 else 0
			end
		end
	end
	-- The world muzzle flash only shows for a moment
	if flashParts and flashHideAt > 0 and now >= flashHideAt then
		flashHideAt = 0
		for _, part in flashParts.Parts do
			part.Transparency = 1
		end
		flashParts.Light.Enabled = false
	end
	-- Old bullet holes go away
	for _, hole in holes do
		if hole.ExpiresAt and now >= hole.ExpiresAt then
			hole.ExpiresAt = nil
			hole.Part.Parent = nil
		end
	end
end

-- Makes the folder, the emitter holder and the per-frame update the first
-- time an effect is used (only ever on the client)
local function ready()
	if not RunService:IsClient() then
		return false
	end
	if folder and folder.Parent and holder and holder.Parent == folder then
		return true
	end
	-- The old folder (if something removed it) goes with everything in it,
	-- and the pools start over: their parts may be destroyed now
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "GunEffects"
	folder.Parent = workspace
	holder = effectPart("EmitterHolder", Vector3.one * 0.1)
	holder.Transparency = 1
	holder.CFrame = CFrame.identity
	holder.Parent = folder
	table.clear(emitters)
	emitterCount = 0
	table.clear(shells)
	table.clear(holes)
	shellIndex, holeIndex = 0, 0
	flashParts = nil
	if not stepConnection then
		stepConnection = RunService.RenderStepped:Connect(stepEffects)
	end
	return true
end

-- The emitter for a kind of particle in a color (colors are rounded, so
-- similar surfaces share one)
local function emitterFor(kind, color)
	local r, g, b = math.floor(color.R * 31 + 0.5), math.floor(color.G * 31 + 0.5), math.floor(color.B * 31 + 0.5)
	local key = kind .. (r * 1024 + g * 32 + b)
	local now = os.clock()
	local entry = emitters[key]
	if entry then
		entry.Used = now
		return entry
	end
	local sequence = ColorSequence.new(Color3.new(r / 31, g / 31, b / 31))
	if emitterCount >= MAX_EMITTERS then
		-- Past the cap, the emitter of this kind that was used longest ago
		-- takes the new color (its last particles may change color too)
		local oldestKey, oldest = nil, nil
		for oldKey, old in emitters do
			if old.Kind == kind and (not oldest or old.Used < oldest.Used) then
				oldestKey, oldest = oldKey, old
			end
		end
		if oldest then
			emitters[oldestKey] = nil
			oldest.Emitter.Color = sequence
			oldest.Used = now
			emitters[key] = oldest
			return oldest
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = kind
	attachment.Parent = holder
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = kind
	emitter.Enabled = false
	emitter.Rate = 0
	for property, value in EMITTERS[kind] do
		emitter[property] = value
	end
	emitter.Color = sequence
	emitter.Parent = attachment
	entry = { Kind = kind, Attachment = attachment, Emitter = emitter, Used = now }
	emitters[key] = entry
	emitterCount += 1
	return entry
end

-- Emits `count` particles of a kind and color at a CFrame (facing -Z = Front)
local function emit(kind, cframe, count, color)
	if count <= 0 or not EMITTERS[kind] then
		return
	end
	local entry = emitterFor(kind, color or PALETTE.Chalk)
	entry.Attachment.CFrame = cframe
	entry.Emitter:Emit(count)
end

local function lighten(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

-- A CFrame at position looking along direction. Straight up or down the
-- usual up vector would leave lookAt undefined (floors, ceilings, shooting
-- at your feet), so another one is used there.
local function facing(position, direction)
	local length = direction.Magnitude
	local up = if length > 0 and math.abs(direction.Y / length) > 0.99 then Vector3.zAxis else Vector3.yAxis
	return CFrame.lookAt(position, position + direction, up)
end
GunEffects.facing = facing

-- Call with a function(kind) to hear shells land (GunFeel plays a tink)
function GunEffects.setShellLandCallback(callback)
	onShellLand = callback
end

-- Call with a function that returns the player's ESP color (Toggles.espColor)
function GunEffects.setEspColorSource(callback)
	espColor = callback
end

-- A crisp tracer: a bright short streak that flies from the muzzle to the
-- target, plus a thin line that fades fast. style: "Bullet" (default),
-- "Pellet" (streak only), "Sniper" (thicker, with a ghost line that
-- lingers), "Energy" (a fat glowing bolt), "Rail" (a thick beam that
-- lingers). trail = false skips the thin line (fast guns).
function GunEffects.tracer(from, to, color, style, trail)
	if not ready() then
		return
	end
	local offset = to - from
	local distance = offset.Magnitude
	if distance < 0.5 then
		return
	end
	local direction = offset / distance
	style = style or "Bullet"

	if style == "Rail" then
		-- A thick beam with a hot core that fades out over a third of a second
		for index, spec in { { 0.32, 0.35, color }, { 0.1, 0, lighten(color, 0.7) } } do
			local beam = effectPart("RailBeam", Vector3.new(spec[1], spec[1], distance))
			beam.Material = Enum.Material.Neon
			beam.Color = spec[3]
			beam.Transparency = spec[2]
			beam.CFrame = facing(from, direction) * CFrame.new(0, 0, -distance / 2)
			beam.Parent = folder
			local life = if index == 1 then 0.35 else 0.22
			TweenService:Create(beam, TweenInfo.new(life, Enum.EasingStyle.Quad), { Transparency = 1, Size = Vector3.new(0.02, 0.02, distance) }):Play()
			Debris:AddItem(beam, life + 0.05)
		end
		return
	end

	if tracerCount >= MAX_TRACERS then
		return
	end
	local energy = style == "Energy"
	local sniper = style == "Sniper"
	local speed = if energy then 420 elseif sniper then 1600 else 1100
	local streakLength = math.min(distance * 0.35, if energy then 3 elseif sniper then 10 else 7)
	local thickness = if energy then 0.16 elseif style == "Pellet" then 0.045 elseif sniper then 0.12 else 0.06
	local travel = math.clamp(distance / speed, 0.035, if energy then 0.35 else 0.14)

	local streak = effectPart("Tracer", Vector3.new(thickness, thickness, streakLength))
	streak.Material = Enum.Material.Neon
	streak.Color = if energy then color else lighten(color, 0.35)
	streak.Transparency = 0
	local startCenter = from + direction * (streakLength / 2)
	local endCenter = to - direction * (streakLength / 2)
	streak.CFrame = facing(startCenter, direction)
	streak.Parent = folder
	tracerCount += 1
	TweenService:Create(streak, TweenInfo.new(travel, Enum.EasingStyle.Linear), { CFrame = facing(endCenter, direction) }):Play()
	Debris:AddItem(streak, travel + 0.02)
	task.delay(travel + 0.02, function()
		tracerCount -= 1
	end)

	if trail ~= false and style ~= "Pellet" and tracerCount < MAX_TRACERS then
		local line = effectPart("TracerLine", Vector3.new(0.025, 0.025, distance))
		line.Material = Enum.Material.Neon
		line.Color = color
		line.Transparency = if energy then 0.3 elseif sniper then 0.6 else 0.55
		line.CFrame = facing(from, direction) * CFrame.new(0, 0, -distance / 2)
		line.Parent = folder
		tracerCount += 1
		local life = if energy then 0.18 elseif sniper then 0.4 else 0.1
		TweenService:Create(line, TweenInfo.new(life), { Transparency = 1 }):Play()
		Debris:AddItem(line, life + 0.02)
		task.delay(life + 0.02, function()
			tracerCount -= 1
		end)
	end
end

-- A star-shaped muzzle flash out in the world, for when the first-person gun
-- isn't drawn (scoped in, or a third-person camera). cframe faces -Z = out
-- of the barrel.
function GunEffects.muzzleFlash(cframe, color, size)
	if not ready() then
		return
	end
	if not flashParts or flashParts.Core.Parent ~= folder then
		local core = effectPart("FlashCore", Vector3.one * 0.3)
		core.Shape = Enum.PartType.Ball
		core.Material = Enum.Material.Neon
		core.Color = PALETTE.Chalk
		local list = { core }
		for index = 1, 3 do
			local petal = effectPart("FlashPetal" .. index, Vector3.new(0.06, 0.8, 0.02))
			petal.Material = Enum.Material.Neon
			table.insert(list, petal)
		end
		local spike = effectPart("FlashSpike", Vector3.new(0.12, 0.12, 0.8))
		spike.Material = Enum.Material.Neon
		table.insert(list, spike)
		local light = Instance.new("PointLight")
		light.Range = 14
		light.Brightness = 5
		light.Shadows = false
		light.Enabled = false
		light.Parent = core
		for _, part in list do
			part.Transparency = 1
			part.Parent = folder
		end
		flashParts = { Core = core, Parts = list, Light = light }
	end
	size = size or 1
	local roll = math.random() * math.pi
	local scale = size * (0.85 + math.random() * 0.3)
	local base = cframe * CFrame.Angles(0, 0, roll)
	flashParts.Core.Size = Vector3.one * 0.3 * scale
	flashParts.Core.CFrame = base
	flashParts.Core.Transparency = 0.1
	for index = 1, 3 do
		local petal = flashParts.Parts[index + 1]
		petal.Size = Vector3.new(0.06 * scale, 0.9 * scale, 0.02)
		petal.Color = color
		petal.CFrame = base * CFrame.Angles(0, 0, (index - 1) * math.pi / 3)
		petal.Transparency = 0.15
	end
	local spike = flashParts.Parts[5]
	spike.Size = Vector3.new(0.12 * scale, 0.12 * scale, 0.8 * scale)
	spike.Color = lighten(color, 0.4)
	spike.CFrame = base * CFrame.new(0, 0, -0.4 * scale)
	spike.Transparency = 0.2
	flashParts.Light.Color = color
	flashParts.Light.Enabled = true
	flashHideAt = os.clock() + 0.05
end

-- A small puff of smoke drifting out of the muzzle
function GunEffects.smoke(position, direction, amount)
	if not ready() then
		return
	end
	emit("Smoke", facing(position, direction), amount or 1, SMOKE_COLOR)
end

-- A spent shell flies out of `cframe` (world) with `velocity` and tumbles.
-- kind: "Brass", "Shell" or "Big". floorY (optional) is where it bounces.
function GunEffects.shell(cframe, velocity, kind, floorY)
	if not ready() then
		return
	end
	local look = SHELLS[kind] or SHELLS.Brass
	shellIndex = shellIndex % MAX_SHELLS + 1
	local shell = shells[shellIndex]
	if not shell then
		local part = effectPart("Shell", look.Size)
		part.Shape = Enum.PartType.Cylinder
		shell = { Part = part }
		shells[shellIndex] = shell
	end
	local part = shell.Part
	part.Size = look.Size
	part.Color = look.Color
	part.Material = look.Material
	part.Transparency = 0
	part.CFrame = cframe
	part.Parent = folder
	shell.Active = true
	shell.Kind = kind
	shell.Age = 0
	shell.Life = SHELL_LIFETIME + math.random() * 0.2
	shell.Position = cframe.Position
	shell.Rotation = cframe.Rotation
	shell.Velocity = velocity
	shell.Axis = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5 + 0.01).Unit
	shell.Spin = 18 + math.random() * 16
	shell.FloorY = floorY
	shell.Bounced = false
end

-- A bullet hole: a dark disc on the surface, reused from a pool
local function bulletHole(position, normal, surface, part, color)
	holeIndex = holeIndex % MAX_HOLES + 1
	local hole = holes[holeIndex]
	if not hole then
		local disc = effectPart("BulletHole", Vector3.new(0.02, 0.2, 0.2))
		disc.Shape = Enum.PartType.Cylinder
		disc.Material = Enum.Material.SmoothPlastic
		hole = { Part = disc }
		holes[holeIndex] = hole
	end
	local disc = hole.Part
	local size = if surface == "Metal" then 0.16 elseif surface == "Wood" then 0.2 else 0.22
	size *= 0.85 + math.random() * 0.3
	disc.Size = Vector3.new(0.02, size, size)
	-- Metal shows a bright dent, everything else a dark hole tinted by the surface
	disc.Color = if surface == "Metal" then rgb(150, 152, 160) else PALETTE.Hole:Lerp(color, 0.15)
	disc.Transparency = if surface == "Dirt" then 0.35 else 0.05
	-- The cylinder's round faces point along X, so turn X onto the normal
	-- (a disc is round, so it needs no random roll)
	disc.CFrame = facing(position + normal * 0.012, normal) * CFrame.Angles(0, math.rad(90), 0)
	disc.Parent = folder
	hole.ExpiresAt = os.clock() + HOLE_LIFETIME
end

-- What a hit surface looks like: its impact kind and color. Terrain gives
-- its voxel material in the raycast (Terrain.Material isn't it).
local function surfaceLook(part, material)
	material = material or (part and part.Material)
	local surface = material and surfaceOf[material] or "Other"
	local color = rgb(150, 150, 150)
	if part and part:IsA("Terrain") then
		local ok, terrainColor = pcall(part.GetMaterialColor, part, material)
		if ok and terrainColor then
			color = terrainColor
		end
	elseif part then
		color = part.Color
	end
	return surface, color
end

-- Where a bullet lands. kind is "Enemy" or "World"; part (optional) is what
-- was hit, so the impact matches its material and color; material
-- (optional) is the raycast's material, which matters for Terrain.
function GunEffects.impact(position, normal, kind, part, material)
	if not ready() then
		return
	end
	local outward = facing(position, normal)
	if kind == "Enemy" then
		-- The pixel hit: 8 Chalk pixels and 4 in the ESP color
		emit("Pixels", outward, 8, PALETTE.Chalk)
		emit("Pixels", outward, 4, espColor())
		emit("Hit", outward, 3, PALETTE.Chalk)
		return
	end

	local surface, color = surfaceLook(part, material)
	if surface == "Metal" then
		emit("Sparks", outward, 12, PALETTE.Yellow)
		emit("Sparks", outward, 4, PALETTE.Chalk)
		emit("Dust", outward, 1, rgb(90, 92, 98))
	elseif surface == "Stone" then
		emit("Dust", outward, 4, lighten(color, 0.35))
		emit("Chips", outward, 6, color)
		emit("Sparks", outward, 3, PALETTE.Yellow)
	elseif surface == "Wood" then
		emit("Chips", outward, 8, lighten(color, 0.15))
		emit("Dust", outward, 2, lighten(color, 0.4))
	elseif surface == "Dirt" then
		emit("Dust", outward, 5, color)
		emit("Chips", outward, 5, color)
	elseif surface == "Glass" then
		emit("Glints", outward, 10, lighten(color, 0.6))
		emit("Chips", outward, 4, lighten(color, 0.5))
	else
		emit("Dust", outward, 3, lighten(color, 0.4))
		emit("Chips", outward, 3, color)
		emit("Sparks", outward, 4, PALETTE.Yellow)
	end
	-- No holes on moving things or see-through parts
	if part and part.Anchored and part.Transparency < 0.5 then
		bulletHole(position, normal, surface, part, color)
	end
end

-- A quick yellow pop where a headshot landed: 12 Yellow pixels and a glint
function GunEffects.headshotPop(position)
	if not ready() then
		return
	end
	local up = facing(position, Vector3.yAxis)
	emit("Pixels", up, 12, PALETTE.Yellow)
	emit("Glints", up, 4, PALETTE.Chalk)
end

-- Extras on top of Effects.explosion: a shockwave ring, embers, rolling smoke
function GunEffects.explosion(position, radius)
	if not ready() then
		return
	end
	local ring = effectPart("Shockwave", Vector3.new(0.3, 2, 2))
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = PALETTE.Yellow
	ring.Transparency = 0.25
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = folder
	local size = radius * 2.3
	TweenService:Create(ring, TweenInfo.new(0.32, Enum.EasingStyle.Quad), { Size = Vector3.new(0.05, size, size), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.4)
	local center = CFrame.new(position)
	emit("Embers", center, 18, rgb(255, 150, 60))
	emit("Embers", center, 8, PALETTE.Yellow)
	emit("BlastSmoke", center, 7, rgb(70, 66, 64))
	emit("Chips", facing(position, Vector3.yAxis), 10, rgb(60, 58, 56))
end

-- Wraps a function so an error inside it never reaches whoever called it:
-- a bug in a cosmetic effect must not stop a shot, a reload or the frame.
-- The error still shows in the output (once per message, so a bug that
-- happens every shot doesn't flood it). The wrapped function returns fn's
-- first result, or nil after an error. GunFeel and ViewmodelFeel use it too.
local reported = {}
local function traceback(message)
	return if type(message) == "string" then debug.traceback(message, 2) else tostring(message)
end
function GunEffects.guard(fn)
	return function(...)
		local ok, result = xpcall(fn, traceback, ...)
		if ok then
			return result
		end
		if not reported[result] then
			reported[result] = true
			task.spawn(error, result, 0)
		end
		return nil
	end
end

for _, name in { "tracer", "muzzleFlash", "smoke", "shell", "impact", "headshotPop", "explosion" } do
	GunEffects[name] = GunEffects.guard(GunEffects[name])
end

return GunEffects
