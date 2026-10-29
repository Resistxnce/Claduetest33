-- How moving feels. The slide: press C or Left Ctrl while running for a burst
-- of speed that bleeds off, and jump out of it to keep the speed (it works
-- with Bunny Hop, Speed Hack and Low Gravity). Plus the camera and sounds that
-- go with moving: a light head bob, a lean into strafes, a dip when you land
-- (bigger the further you fell), a wider view when you go fast, a knock and
-- shake when you get hit, and footsteps, jump and landing sounds.
--
-- The slide is a burst, not free speed: it never takes you past your run
-- speed + Boost, and a new slide needs Recharge seconds since the last one
-- started, so slide-hop chains can't stack up speed past the paid hacks.
--
-- Camera effects all go through CameraFx. Movement.luau calls MoveFeel.start(),
-- passes its walk speed through MoveFeel.walkSpeed() every frame, and calls
-- MoveFeel.teleported() after a Teleport. Viewmodel.luau can ask
-- MoveFeel.isSliding(), MoveFeel.runSpeed() and MoveFeel.viewmodelPose().
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraFx = require(script.Parent.CameraFx)
local Toggles = require(script.Parent.Toggles)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local MoveFeel = {}

local rgb = Color3.fromRGB
local CHALK = rgb(242, 244, 248) -- dust
local ESP_VIOLET = rgb(139, 92, 255) -- cheat color: Speed Hack sparks
local DUST_TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

-- The slide
MoveFeel.SLIDE = {
	Keys = { Enum.KeyCode.C, Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3 },
	Boost = 18, -- studs/s on top of your run speed when a slide starts (and the most you keep)
	MaxSpeed = 72, -- a slide never goes faster than this
	Friction = 26, -- studs/s lost each second while sliding
	MinTime = 0.35, -- a slide lasts at least this long, unless you jump out
	MaxTime = 1.1,
	Cooldown = 0.45, -- seconds after a slide ends before the next one
	Recharge = 1.25, -- and at least this long from one slide's start to the next, so slide-hops can't spam
	-- (with these numbers, free slide-hops average about 25 studs/s: under Bunny Hop's best and Speed Hack)
	Buffer = 0.25, -- press slide this long before you land (or before it's ready) and it starts then
	AirGrace = 0.1, -- seconds off the ground (a stair edge, a ramp crest) before a slide counts as leaving it
	Steer = 3, -- how fast a slide turns toward the way you're holding
	CameraDrop = 1.6, -- studs the camera drops
	Tilt = 3.5, -- degrees the camera leans
	FovPunch = 8, -- degrees of field of view kick when it starts
	GunDrop = 0.12, -- studs the gun (viewmodel) lowers while sliding
	GunRoll = 10, -- degrees the gun cants while sliding
	-- A slide animation for your character, so other players see you slide
	-- (without one they see you run fast). Paste an animation id you own,
	-- like "rbxassetid://1234567890".
	Animation = "",
}

-- Speed you keep when you jump (or slide) off the ground out of a slide
MoveFeel.MOMENTUM = {
	AirDecay = 8, -- studs/s lost each second in the air (one jump keeps most of it)
	GroundDecay = 60, -- and on the ground once the grace time is over
	Grace = 0.2, -- seconds on the ground before it bleeds off: time to hop again
}

MoveFeel.CAMERA = {
	Bob = 0.05, -- studs of head bob at running speed
	BobRoll = 0.3, -- degrees of roll per step
	StepLength = 4.6, -- studs per footstep at running speed
	MaxSteps = 5, -- footsteps per second at most: faster than that, strides get longer
	StrafeRoll = 1.6, -- degrees of lean when strafing at full speed
	FastFov = 0.12, -- up to 12% wider view when you go really fast
	FastFrom = 20, -- studs/s where the wider view starts
	FastFull = 55, -- and where it's at its widest
	LandDip = 1.1, -- studs the camera dips on a hard landing
	LandNod = 3.5, -- degrees it nods down on a hard landing
	HitShake = 0.9, -- degrees of shake for a big hit
	HitKnock = 1.5, -- degrees you get knocked away from where a shot came from
	ThirdPerson = 0.45, -- how strong the effects are when the camera is behind you
}

-- Movement sounds. These are sounds built into Roblox, so they work with no
-- uploads. For better ones, paste a Creator Store audio id here, like
-- Id = "rbxassetid://1234567890", then tune Volume and Speed. Vary is how
-- much the pitch changes each time (0.1 = up to 10% higher or lower).
MoveFeel.SOUNDS = {
	Footstep = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.2, Speed = 1.8, Vary = 0.12 },
	Jump = { Id = "rbxasset://sounds/action_jump.mp3", Volume = 0.3, Speed = 1.25, Vary = 0.08 },
	Land = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.5, Speed = 1.1, Vary = 0.08 },
	HardLand = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 1, Speed = 0.72, Vary = 0.05 },
	SlideStart = { Id = "rbxasset://sounds/action_jump_land.mp3", Volume = 0.45, Speed = 1.45, Vary = 0.1 },
	Slide = { Id = "rbxasset://sounds/action_falling.mp3", Volume = 0.5, Speed = 1.7, Vary = 0.08, Looped = true },
}

-- Roblox's own character sounds that these replace on your character
-- (other players keep theirs)
local REPLACED_DEFAULTS = { Running = true, Jumping = true, Landing = true }

-- State ---------------------------------------------------------------------------

local sliding = false
local slideSpeed = 0
local slideDir = Vector3.new(0, 0, -1)
local slideStart = -math.huge
local slideSide = 1 -- which way the camera leans in this slide
local cooldownUntil = 0
local bufferedAt = -math.huge
local carry = 0 -- speed kept from a slide
local normalSpeed = 16 -- what Movement asked for last frame

local wasOnGround = true
local groundTime, airTime, fallSpeed = 0, 0, 0
local stepPhase, lastStep = 0, 0
local bobAmount, strafeTilt, slideBlend, fovScale = 0, 0, 0, 1
local viewWeight = 1 -- 1 in first person, less when the camera is behind you
local lastHealth = 100
local lastHitAt = -math.huge

-- Per character
local slideForce, feet, dust, sparks
local slideAnimation, slideTrack
local characterConnections = {}

-- Sounds ---------------------------------------------------------------------------

local sounds = {}
local mutedDefaults = Instance.new("SoundGroup")
mutedDefaults.Name = "FeelMutedDefaults"
mutedDefaults.Volume = 0
mutedDefaults.Parent = SoundService

-- One reusable Sound per slot, so footsteps don't make new ones each step
local function getSound(name)
	local sound = sounds[name]
	if sound and sound.Parent then
		return sound
	end
	local spec = MoveFeel.SOUNDS[name]
	if not spec or spec.Id == "" then
		return nil
	end
	sound = Instance.new("Sound")
	sound.Name = "Feel" .. name
	sound.SoundId = spec.Id
	sound.Looped = spec.Looped == true
	sound.Volume = spec.Volume
	sound.Parent = SoundService
	sounds[name] = sound
	return sound
end

local function playSound(name, volumeScale, speedScale)
	local spec = MoveFeel.SOUNDS[name]
	local sound = getSound(name)
	if not sound then
		return
	end
	sound.Volume = spec.Volume * (volumeScale or 1)
	sound.PlaybackSpeed = spec.Speed * (speedScale or 1) * (1 + (math.random() * 2 - 1) * (spec.Vary or 0))
	sound.TimePosition = 0
	sound:Play()
end

local function muteDefault(child)
	if child:IsA("Sound") and REPLACED_DEFAULTS[child.Name] then
		child.SoundGroup = mutedDefaults
	end
end

-- Helpers --------------------------------------------------------------------------

local function getCharacter()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function flat(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function isSlideKey(input)
	return table.find(MoveFeel.SLIDE.Keys, input.KeyCode) ~= nil
end

-- The fastest a slide (or the speed kept from one) can take you right now:
-- your run speed plus Boost, and never past MaxSpeed
local function speedCap()
	local settings = MoveFeel.SLIDE
	return math.max(normalSpeed, math.min(normalSpeed + settings.Boost, settings.MaxSpeed))
end

-- Keeps up to `speed` after a slide (jumping out, or it running out)
local function keepSpeed(speed)
	carry = math.min(math.max(carry, speed), speedCap())
end

-- Lets go of every camera effect this module holds
local function clearCamera()
	CameraFx.setOffset("Slide", nil)
	CameraFx.setTilt("Slide", nil)
	CameraFx.setOffset("Bob", nil)
	CameraFx.setTilt("Bob", nil)
	CameraFx.setTilt("Strafe", nil)
	CameraFx.setFovScale("Speed", nil)
	bobAmount, strafeTilt, slideBlend, fovScale = 0, 0, 0, 1
end

-- Sliding --------------------------------------------------------------------------

local function endSlide()
	if not sliding then
		return
	end
	sliding = false
	-- Ready again Cooldown after it ends, and never sooner than Recharge after it started
	cooldownUntil = math.max(os.clock() + MoveFeel.SLIDE.Cooldown, slideStart + MoveFeel.SLIDE.Recharge)
	if slideForce then
		slideForce.Enabled = false
	end
	if dust then
		dust.Enabled = false
	end
	if slideTrack then
		slideTrack:Stop(0.15)
	end
end

-- Plays SLIDE.Animation on your character, if one is set
local function playSlideAnimation(humanoid)
	local id = MoveFeel.SLIDE.Animation
	if id == "" then
		return
	end
	if not slideTrack or not slideAnimation or slideAnimation.AnimationId ~= id then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			return
		end
		slideAnimation = Instance.new("Animation")
		slideAnimation.AnimationId = id
		slideTrack = animator:LoadAnimation(slideAnimation)
		slideTrack.Priority = Enum.AnimationPriority.Action
	end
	slideTrack:Play(0.1)
end

-- Starts a slide if you're running on the ground. Returns whether it did, and
-- if not, whether it's worth trying again in a moment (in the air, recharging).
local function startSlide()
	local settings = MoveFeel.SLIDE
	local _, humanoid, root = getCharacter()
	if sliding or not humanoid or not root or not slideForce or humanoid.Health <= 0 then
		return false, false
	end
	if humanoid.PlatformStand or humanoid.Sit then
		return false, false -- flying (Left Ctrl flies down) or sitting
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return false, true -- slide as soon as you land
	end
	if os.clock() < cooldownUntil then
		return false, true
	end
	local move = flat(humanoid.MoveDirection)
	local velocity = flat(root.AssemblyLinearVelocity)
	if move.Magnitude < 0.5 or velocity.Magnitude < 6 then
		return false, false -- only while running
	end

	sliding = true
	bufferedAt = -math.huge
	slideDir = move.Unit
	-- A burst from your run speed (not your current speed), so slides can't stack
	slideSpeed = speedCap()
	slideStart = os.clock()
	-- Lean into the slide's side, or a little left going straight
	local camera = workspace.CurrentCamera
	local lateral = flat(camera.CFrame.RightVector):Dot(slideDir)
	slideSide = if math.abs(lateral) > 0.3 then -math.sign(lateral) else 1

	slideForce.MaxForce = math.max(5e4, root.AssemblyMass * 6000)
	slideForce.PlaneVelocity = Vector2.new(slideDir.X, slideDir.Z) * slideSpeed
	slideForce.Enabled = true

	CameraFx.punchFov(settings.FovPunch * viewWeight, 0.45)
	CameraFx.punch(-1.2 * viewWeight, 0, 0)
	if dust then
		dust:Emit(10)
		dust.Enabled = true
	end
	if sparks and Toggles.isOn("SpeedHack") then
		sparks:Emit(8)
	end
	playSlideAnimation(humanoid)
	playSound("SlideStart")
	playSound("Slide", 0) -- the loop fades in and out with the slide (see update)
	return true, false
end

-- Starts a slide if you're running on the ground. Returns whether it did. In
-- the air or while it recharges, it starts as soon as it can (within Buffer).
-- (A phone button can call this too.)
function MoveFeel.slide()
	local started, retry = startSlide()
	if not started and retry then
		bufferedAt = os.clock()
	end
	return started
end

local function updateSlide(dt, humanoid, onGround, actualSpeed, verticalSpeed)
	local settings = MoveFeel.SLIDE
	if humanoid.PlatformStand or humanoid.Sit or humanoid.Health <= 0 then
		endSlide()
		return
	end
	-- A frame or two off the ground (a seam, a stair edge) doesn't end it;
	-- really leaving the ground (a ledge, a ramp launch) keeps the speed
	if not onGround and (airTime > settings.AirGrace or verticalSpeed > 8) then
		keepSpeed(slideSpeed)
		endSlide()
		return
	end
	local elapsed = os.clock() - slideStart
	if elapsed > 0.15 and actualSpeed < slideSpeed * 0.35 then
		endSlide() -- slid into a wall
		return
	end
	-- Less gravity, less friction: Low Gravity slides go further
	local friction = settings.Friction * math.sqrt(math.clamp(workspace.Gravity / 196.2, 0.2, 2))
	slideSpeed = math.max(0, slideSpeed - friction * dt)

	local move = flat(humanoid.MoveDirection)
	if move.Magnitude > 0.1 then
		local turned = slideDir:Lerp(move.Unit, math.min(1, dt * settings.Steer))
		if turned.Magnitude > 0.05 then
			slideDir = turned.Unit
		end
	end

	if (elapsed >= settings.MinTime and slideSpeed <= normalSpeed * 1.05) or elapsed >= settings.MaxTime then
		-- Whatever speed is left bleeds off on the ground instead of stopping dead
		keepSpeed(slideSpeed)
		endSlide()
		return
	end
	if slideForce then
		slideForce.PlaneVelocity = Vector2.new(slideDir.X, slideDir.Z) * slideSpeed
	end
end

-- Movement.luau passes its walk speed through this every frame, so slides
-- and the speed you keep from them win over normal running speed
function MoveFeel.walkSpeed(normal)
	normalSpeed = normal
	local speed = normal
	if sliding then
		speed = math.max(speed, slideSpeed)
	end
	if carry > speed then
		speed = math.max(speed, math.min(carry, speedCap()))
	end
	return speed
end

function MoveFeel.isSliding()
	return sliding
end

-- Your run speed (Speed Hack and Bunny Hop included), without slide speed.
-- Viewmodel bobs at this pace, so it doesn't shake while you slide.
function MoveFeel.runSpeed()
	return normalSpeed
end

-- A small pose for the gun while sliding: lowered and canted into the lean.
-- Viewmodel multiplies it into its bob (identity when not sliding).
function MoveFeel.viewmodelPose()
	if slideBlend <= 0.002 then
		return CFrame.identity
	end
	local settings = MoveFeel.SLIDE
	return CFrame.new(0.04 * slideBlend * slideSide, -settings.GunDrop * slideBlend, 0.05 * slideBlend)
		* CFrame.Angles(0, 0, math.rad(settings.GunRoll * slideSide * slideBlend))
end

-- Ground and air -----------------------------------------------------------------------

-- A real jump (the Humanoid's Jumping state), not walking off a ledge or Spider climbing
local function tookOff()
	playSound("Jump")
	CameraFx.punch(0.6 * viewWeight, 0, 0)
	if sliding then
		-- Slide jump: keep the speed, and a little extra kick so it feels like a launch
		keepSpeed(slideSpeed)
		endSlide()
		CameraFx.punchFov(4 * viewWeight, 0.3)
	end
end

local function landed(humanoid, speed, timeInAir)
	if timeInAir < 0.12 and speed < 15 then
		return -- a step or a bump
	end
	-- How fast your own jump lands (Super Jump and Low Gravity change it).
	-- Landing from your own jump is a small dip; only falls from higher than
	-- that get the big dip, the shake and the thump.
	local jumpLand = math.max(math.sqrt(2 * workspace.Gravity * math.max(humanoid.JumpHeight, 0.5)), 20)
	local soft = math.clamp(speed / jumpLand, 0, 1)
	local hard = math.clamp((speed - jumpLand * 1.15) / 70, 0, 1)
	local curved = hard ^ 1.5
	local camera = MoveFeel.CAMERA
	CameraFx.bump((0.12 + 0.08 * soft + camera.LandDip * curved) * viewWeight)
	CameraFx.punch(-(0.3 + 0.2 * soft + camera.LandNod * curved) * viewWeight, 0, 0)
	if hard > 0.4 then
		CameraFx.shake(0.5 * hard * viewWeight, 0.25)
		playSound("HardLand", hard)
		if dust then
			dust:Emit(math.floor(6 + 10 * hard))
		end
	else
		playSound("Land", 0.4 + 0.4 * soft + hard)
	end
end

-- Teleport: a quick warp kick (Movement.luau calls this)
function MoveFeel.teleported()
	fallSpeed, airTime = 0, 0
	CameraFx.punchFov(14, 0.4)
	CameraFx.shake(0.35, 0.15)
end

-- Getting hit ---------------------------------------------------------------------------

-- A shot from `fromPosition` knocks your view away from it
local function onDamaged(fromPosition)
	local camera = workspace.CurrentCamera
	local knock = MoveFeel.CAMERA.HitKnock * viewWeight
	lastHitAt = os.clock()
	if typeof(fromPosition) ~= "Vector3" or not camera then
		CameraFx.punch(knock * 0.4, 0, 0)
		return
	end
	local offset = camera.CFrame:PointToObjectSpace(fromPosition)
	local distance = math.max(offset.Magnitude, 1)
	local side = offset.X / distance -- 1 = from the right
	local front = -offset.Z / distance -- 1 = from straight ahead
	CameraFx.punch(knock * (0.25 + 0.35 * math.max(front, 0)), knock * 0.35 * side, knock * side)
end

local function onHealthChanged(health)
	local drop = lastHealth - health
	lastHealth = health
	if drop < 1 or health <= 0 then
		return
	end
	local size = math.clamp(drop / 35, 0.25, 1)
	local weight = viewWeight
	CameraFx.shake(MoveFeel.CAMERA.HitShake * size * weight, 0.16 + 0.14 * size)
	-- The server's Damaged event (with the shooter's position) can come just
	-- after this; only nod if it didn't, so a hit gets one knock, not two
	task.delay(0.06, function()
		if os.clock() - lastHitAt > 0.1 then
			-- No direction for this one (an explosion, a duel hit): a small nod
			CameraFx.punch(0.8 * size * weight, 0, 0)
		end
	end)
end

-- Each character ---------------------------------------------------------------------

local function setupCharacter(character)
	for _, connection in characterConnections do
		connection:Disconnect()
	end
	table.clear(characterConnections)
	sliding, carry, slideSpeed = false, 0, 0
	slideForce, feet, dust, sparks = nil, nil, nil, nil
	slideAnimation, slideTrack = nil, nil
	wasOnGround, groundTime, airTime, fallSpeed = true, 0, 0, 0
	clearCamera()

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= character then
		return
	end
	lastHealth = humanoid.Health

	-- Swap Roblox's footsteps and jump sounds for ours
	for _, child in root:GetChildren() do
		muteDefault(child)
	end
	table.insert(characterConnections, root.ChildAdded:Connect(muteDefault))
	table.insert(characterConnections, humanoid.HealthChanged:Connect(onHealthChanged))
	table.insert(characterConnections, humanoid.Died:Connect(function()
		endSlide()
		clearCamera()
	end))
	-- Jumps off the ground (Infinite Jump's air jumps already play their own sound)
	table.insert(characterConnections, humanoid.StateChanged:Connect(function(old, new)
		if
			new == Enum.HumanoidStateType.Jumping
			and old ~= Enum.HumanoidStateType.Freefall
			and old ~= Enum.HumanoidStateType.Jumping
			and not humanoid.PlatformStand
		then
			tookOff()
		end
	end))

	-- The slide pushes you along the ground with this; up and down stay free
	local attachment = root:FindFirstChild("RootAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "FeelSlideAttachment"
		attachment.Parent = root
	end
	slideForce = Instance.new("LinearVelocity")
	slideForce.Name = "FeelSlide"
	slideForce.Attachment0 = attachment
	slideForce.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	slideForce.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	slideForce.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	slideForce.RelativeTo = Enum.ActuatorRelativeTo.World
	slideForce.MaxForce = 1e4
	slideForce.Enabled = false
	slideForce.Parent = root

	-- Dust at your feet while sliding, and violet sparks with Speed Hack
	feet = Instance.new("Attachment")
	feet.Name = "FeelFeet"
	feet.Position = Vector3.new(0, -(root.Size.Y / 2 + humanoid.HipHeight) + 0.3, 0)
	feet.Parent = root
	dust = Instance.new("ParticleEmitter")
	dust.Name = "SlideDust"
	dust.Texture = DUST_TEXTURE
	dust.Color = ColorSequence.new(CHALK)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 2.4) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(0.35, 0.6)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Drag = 3
	dust.Acceleration = Vector3.new(0, 3, 0)
	dust.Rate = 45
	dust.Enabled = false
	dust.Parent = feet
	sparks = Instance.new("ParticleEmitter")
	sparks.Name = "SpeedSparks"
	sparks.Texture = SPARK_TEXTURE
	sparks.Color = ColorSequence.new(ESP_VIOLET)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.2, 0.4)
	sparks.Speed = NumberRange.new(6, 12)
	sparks.SpreadAngle = Vector2.new(60, 60)
	sparks.Drag = 6
	sparks.Enabled = false
	sparks.Parent = feet
end

-- Every frame ---------------------------------------------------------------------------

local function update(dt)
	dt = math.min(dt, 0.1)
	local character, humanoid, root = getCharacter()
	local camera = workspace.CurrentCamera
	if not humanoid or not root or not camera or humanoid.Health <= 0 then
		if sliding then
			endSlide()
		end
		if slideBlend > 0 or bobAmount > 0 or fovScale ~= 1 then
			clearCamera()
		end
		local loop = sounds.Slide
		if loop and loop.IsPlaying then
			loop:Stop()
		end
		return
	end

	-- First person gets the full effects; behind you (the lobby) gets less
	local head = character:FindFirstChild("Head")
	local closeUp = head ~= nil and (camera.CFrame.Position - head.Position).Magnitude < 4
	local weightGoal = if closeUp then 1 else MoveFeel.CAMERA.ThirdPerson
	viewWeight += (weightGoal - viewWeight) * math.min(1, dt * 8)

	local velocity = root.AssemblyLinearVelocity
	local flatVelocity = flat(velocity)
	local speed = flatVelocity.Magnitude
	local flying = humanoid.PlatformStand or humanoid.Sit
	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air and not flying

	-- Landing (taking off is the Jumping state, see setupCharacter)
	if onGround and not wasOnGround then
		landed(humanoid, fallSpeed, airTime)
	end
	if onGround then
		groundTime += dt
		airTime, fallSpeed = 0, 0
	else
		airTime += dt
		groundTime = 0
		fallSpeed = if flying then 0 else math.max(fallSpeed, -velocity.Y)
	end
	wasOnGround = onGround

	if sliding then
		updateSlide(dt, humanoid, onGround, speed, velocity.Y)
	elseif onGround and os.clock() - bufferedAt <= MoveFeel.SLIDE.Buffer then
		-- Pressed slide in the air or while it recharged: start it now if it can
		startSlide()
	end

	-- Speed kept from a slide bleeds off
	if carry > 0 then
		local momentum = MoveFeel.MOMENTUM
		if flying then
			carry = 0
		elseif not onGround then
			carry -= momentum.AirDecay * dt
		elseif not sliding and groundTime > momentum.Grace then
			carry -= momentum.GroundDecay * dt
		end
		if carry <= normalSpeed then
			carry = 0
		end
	end

	local settings = MoveFeel.CAMERA
	local zoomed = CameraFx.zoom("Speed") < 0.95 -- aiming down sights or scoped

	-- Slide camera: drop down and lean
	slideBlend += ((if sliding then 1 else 0) - slideBlend) * math.min(1, dt * (if sliding then 14 else 7))
	if slideBlend > 0.002 then
		local drop = MoveFeel.SLIDE.CameraDrop * slideBlend * viewWeight
		CameraFx.setOffset("Slide", CFrame.new(camera.CFrame:VectorToObjectSpace(Vector3.new(0, -drop, 0))))
		CameraFx.setTilt("Slide", MoveFeel.SLIDE.Tilt * slideSide * slideBlend * viewWeight)
	elseif slideBlend > 0 then
		slideBlend = 0
		CameraFx.setOffset("Slide", nil)
		CameraFx.setTilt("Slide", nil)
	end
	local loop = sounds.Slide
	if loop then
		if slideBlend > 0.02 then
			loop.Volume = MoveFeel.SOUNDS.Slide.Volume * slideBlend * math.clamp(slideSpeed / 30, 0.4, 1.2)
		elseif loop.IsPlaying then
			loop:Stop()
		end
	end

	-- Head bob and footsteps: one step every stride. Strides get longer above
	-- MaxSteps a second, so Speed Hack and slide speed don't buzz.
	local running = onGround and not sliding and speed > 1.5
	bobAmount += ((if running then math.clamp(speed / 16, 0, 1) else 0) - bobAmount) * math.min(1, dt * 10)
	if running then
		local stride = math.max(settings.StepLength, speed / settings.MaxSteps)
		stepPhase += speed * dt / stride * math.pi
		local step = math.floor(stepPhase / math.pi)
		if step ~= lastStep then
			lastStep = step
			local loudness = math.clamp(speed / 16, 0.3, 1.25)
			playSound("Footstep", loudness, 1 + math.clamp((speed - 16) / 60, 0, 0.15))
		end
	end
	local bob = bobAmount * settings.Bob * (if closeUp then 1 else 0) * (if zoomed then 0.35 else 1)
	if bob > 0.0005 then
		local swing = math.sin(stepPhase)
		local calm = math.clamp(20 / math.max(speed, 1), 0.4, 1) -- less roll when going fast
		CameraFx.setOffset("Bob", CFrame.new(swing * bob * 0.6, (math.abs(swing) - 0.5) * bob, 0))
		CameraFx.setTilt("Bob", swing * settings.BobRoll * calm * bob / settings.Bob)
	else
		CameraFx.setOffset("Bob", nil)
		CameraFx.setTilt("Bob", nil)
	end

	-- Lean into strafes (on the ground and in the air); calmer while aiming
	local right = flat(camera.CFrame.RightVector)
	local lateral = if right.Magnitude > 0.01 then right.Unit:Dot(flatVelocity) else 0
	local leanGoal = if flying or not closeUp
		then 0
		else -math.clamp(lateral / math.max(normalSpeed, 16), -1.25, 1.25) * settings.StrafeRoll * (if zoomed then 0.3 else 1)
	strafeTilt += (leanGoal - strafeTilt) * math.min(1, dt * 8)
	CameraFx.setTilt("Strafe", if math.abs(strafeTilt) > 0.01 then strafeTilt else nil)

	-- Wider view when you go fast (Speed Hack, slides, hop chains, flying)
	local travel = if flying then velocity.Magnitude else speed
	local fast = math.clamp((travel - settings.FastFrom) / (settings.FastFull - settings.FastFrom), 0, 1)
	local fovGoal = 1 + settings.FastFov * fast * (if zoomed then 0.25 else 1)
	fovScale += (fovGoal - fovScale) * math.min(1, dt * (if fovGoal > fovScale then 6 else 3))
	if math.abs(fovScale - 1) < 0.001 then
		fovScale = 1
	end
	CameraFx.setFovScale("Speed", fovScale)
end

function MoveFeel.start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and isSlideKey(input) then
			MoveFeel.slide()
		end
	end)

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
	-- Rounds and the lobby are far apart: don't carry a slide across
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		endSlide()
		carry, fallSpeed, airTime = 0, 0, 0
		bufferedAt = -math.huge
	end)
	Remotes.Damaged.OnClientEvent:Connect(onDamaged)

	-- Early in the frame, before the camera scripts and CameraFx
	RunService:BindToRenderStep("EarnEspMoveFeel", Enum.RenderPriority.Input.Value + 1, update)
end

return MoveFeel
