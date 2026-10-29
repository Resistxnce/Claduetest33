-- Feel tests: boots the real client (Main.client) in the preview, then
-- runs, slides, hops, flies, shoots, reloads, swaps guns, gets hit and moves
-- between the lobby and rounds, checking the camera, movement and lighting
-- numbers along the way. Every screen fails loudly if the game logs a client
-- error or a check fails.
--
-- The preview has no physics and no Roblox camera scripts, so this file adds
-- small stand-ins: a "physics" step that moves the character from
-- MoveDirection * WalkSpeed (or the slide / fly constraints), with gravity
-- and jumping, and a "camera script" at RenderPriority.Camera that rebuilds the
-- camera from its own look direction every frame, like Roblox's ClassicCamera.
return function(Client)
	-- The preview has no ParticleEmitter:Emit; in Roblox it bursts particles
	Client.roblox.implementMethod("ParticleEmitter", "Emit", function() end)

	local function check(ok, message)
		if not ok then
			error("CHECK FAILED: " .. message, 2)
		end
	end

	local function near(a, b, tolerance, message)
		check(math.abs(a - b) <= tolerance, `{message} (got {a}, wanted {b} +- {tolerance})`)
	end

	local function assertNoErrors(label)
		local errors = Client.errors()
		if #errors > 0 then
			error(`{label}: {#errors} client error(s):\n` .. table.concat(errors, "\n"), 2)
		end
	end

	-- Keys held down, for UserInputService:IsKeyDown / IsMouseButtonPressed
	local held = {}
	local function hold(key, on)
		held[key] = if on then true else nil
	end

	-- What the server builds in Lighting (Map.luau setupLighting)
	local function serverLighting()
		local Lighting = Client.lighting
		for className, name in { Atmosphere = "Atmosphere", BloomEffect = "Bloom", ColorCorrectionEffect = "ColorCorrection", SunRaysEffect = "SunRays" } do
			local made = Instance.new(className)
			made.Name = name
			made.Parent = Lighting
		end
	end

	-- A few lobby portals like the old lobby's (x = -57..57, z = -44)
	local function lobbyPortals()
		local lobby = Instance.new("Model")
		lobby.Name = "Lobby"
		for index = 1, 7 do
			local field = Instance.new("Part")
			field.Name = "PortalField"
			field.Size = Vector3.new(9.6, 15, 0.4)
			field.CFrame = CFrame.new((index - 4) * 19, 7.5, -44)
			field.Parent = lobby
		end
		lobby.Parent = Client.workspace
	end

	-- Physics and camera stand-ins ---------------------------------------------------

	local sim = {}

	local function startSim(spawnAt)
		sim.position = spawnAt
		sim.vy = 0
		sim.airborne = false
		sim.ground = spawnAt.Y
		sim.zoom = 12
		sim.wallZ = nil
		local run = Client.RunService
		local input = Client.UserInputService
		input.IsKeyDown = function(_, key)
			return held[key] == true
		end
		input.IsMouseButtonPressed = function(_, button)
			return held[button] == true
		end

		-- "Physics": after everything else in the frame, like Roblox
		run.Heartbeat:Connect(function(dt)
			local character = Client.player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not humanoid or not root then
				return
			end
			local horizontal
			local flying = humanoid.PlatformStand
			local fly, slide
			for _, child in root:GetChildren() do
				if child:IsA("LinearVelocity") and child.Enabled then
					if child.Name == "FeelSlide" then
						slide = child
					else
						fly = child
					end
				end
			end
			if flying and fly then
				local v = fly.VectorVelocity
				horizontal = Vector3.new(v.X, 0, v.Z)
				sim.vy = v.Y
			elseif slide then
				horizontal = Vector3.new(slide.PlaneVelocity.X, 0, slide.PlaneVelocity.Y)
			else
				horizontal = humanoid.MoveDirection * humanoid.WalkSpeed
			end
			if humanoid.Jump and not sim.airborne and not flying then
				sim.vy = humanoid.JumpPower
				sim.airborne = true
				-- Roblox's Humanoid goes into its Jumping state
				Client.signalOf(humanoid, "StateChanged"):Fire(Enum.HumanoidStateType.Running, Enum.HumanoidStateType.Jumping)
			end
			humanoid.Jump = false
			if sim.airborne and not flying then
				sim.vy -= Client.workspace.Gravity * dt
			end
			sim.position += (horizontal + Vector3.new(0, sim.vy, 0)) * dt
			-- An optional wall across the arena at z = sim.wallZ
			if sim.wallZ and sim.position.Z < sim.wallZ then
				sim.position = Vector3.new(sim.position.X, sim.position.Y, sim.wallZ)
				horizontal = Vector3.new(horizontal.X, 0, 0)
			end
			if not flying and sim.position.Y <= sim.ground then
				sim.position = Vector3.new(sim.position.X, sim.ground, sim.position.Z)
				sim.airborne = false
				sim.vy = 0
			elseif flying then
				sim.airborne = sim.position.Y > sim.ground + 0.01
			end
			-- sim.blip: frames the floor is briefly lost (a seam, a stair edge)
			local blip = (sim.blip or 0) > 0
			if blip then
				sim.blip -= 1
			end
			humanoid.FloorMaterial = if sim.airborne or flying or blip then Enum.Material.Air else Enum.Material.Plastic
			root.AssemblyLinearVelocity = horizontal + Vector3.new(0, sim.vy, 0)
			local _, rootYaw = root.CFrame:ToOrientation()
			root.CFrame = CFrame.new(sim.position) * CFrame.fromOrientation(0, rootYaw, 0)
			local head = character:FindFirstChild("Head")
			if head then
				head.CFrame = root.CFrame * CFrame.new(0, 1.5, 0)
			end
		end)

		-- "Camera script": rebuilds the camera from its look direction, first
		-- person in rounds and 12 studs behind you in the lobby
		run:BindToRenderStep("FakeCameraScript", Enum.RenderPriority.Camera.Value, function()
			local character = Client.player.Character
			local head = character and character:FindFirstChild("Head")
			if not head then
				return
			end
			local camera = Client.camera
			local look = camera.CFrame.LookVector
			local headPosition = head.CFrame.Position
			if Client.player.CameraMode == Enum.CameraMode.LockFirstPerson then
				camera.CFrame = CFrame.lookAt(headPosition, headPosition + look)
			else
				local zoom = math.max(sim.zoom, Client.player.CameraMinZoomDistance)
				camera.CFrame = CFrame.lookAt(headPosition - look * zoom, headPosition)
			end
		end)
	end

	-- Steps `seconds`, calling `each(dt)` before every frame
	local function run(seconds, each)
		local frames = math.max(1, math.floor(seconds * 60 + 0.5))
		for _ = 1, frames do
			if each then
				each(1 / 60)
			end
			Client.step(1 / 60)
		end
	end

	local function character()
		local model = Client.player.Character
		return model, model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
	end

	local function setMove(direction)
		local _, humanoid = character()
		humanoid.MoveDirection = direction
	end

	-- Gives the character the gun tool Gun.luau looks for
	local function giveGun()
		local model = character()
		local tool = Instance.new("Tool")
		tool.Name = "Gun"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 0.6, 2)
		handle.Parent = tool
		tool.Parent = model
	end

	local function join(attributes, spawnAt)
		serverLighting()
		lobbyPortals()
		Client.setStat("Credits", 25000)
		Client.setAttributes(attributes or {})
		Client.spawnCharacter({ Health = 100 })
		local _, _, root = character()
		-- Roblox R15 rigs have this (Fly and the slide attach to it)
		local rootAttachment = Instance.new("Attachment")
		rootAttachment.Name = "RootAttachment"
		rootAttachment.Parent = root
		spawnAt = spawnAt or Vector3.new(20, 3, 40)
		root.CFrame = CFrame.new(spawnAt)
		Client.camera.CFrame = CFrame.lookAt(spawnAt + Vector3.new(0, 4, 12), spawnAt)
		startSim(spawnAt)
		Client.run("Main")
	end

	local ROUND = {
		RoundKind = "Bots",
		ArenaName = "Arena_1",
		ArenaDisplayName = "Bronze",
		MapName = "Skate Park",
		ArenaTheme = "Day",
		Wave = 1,
		Waves = 1,
		BotsAlive = 5,
	}

	local function startRound(theme, extra)
		local values = table.clone(ROUND)
		values.ArenaTheme = theme or "Day"
		values.RoundStartsAt = Client.serverTime() - 5
		values.RoundEndsAt = Client.serverTime() + 400
		for key, value in extra or {} do
			values[key] = value
		end
		-- The server moves you to the arena, then flips InRound
		sim.position = Vector3.new(0, 3, 3000)
		sim.ground = 3
		Client.setAttributes(values)
		Client.setAttributes({ InRound = true })
		Client.camera.CFrame = CFrame.lookAt(sim.position + Vector3.new(0, 1.5, 0), sim.position + Vector3.new(0, 1.5, -10))
		run(0.5)
	end

	local function flatLook()
		local look = Client.camera.CFrame.LookVector
		return Vector3.new(look.X, 0, look.Z).Unit
	end

	local function pitchDegrees(cframe)
		local pitch = cframe:ToOrientation()
		return math.deg(pitch)
	end

	local function soundPlayed(name)
		return Client.getService("SoundService"):FindFirstChild("Feel" .. name) ~= nil
	end

	local function flatPosition()
		return Vector3.new(sim.position.X, 0, sim.position.Z)
	end

	-- Mashes slide, then jumps 0.15 s into each slide, `hops` times.
	-- Returns the top WalkSpeed, the average speed over the ground and the
	-- shortest time between two slide starts.
	local function slideHops(MoveFeel, hops)
		local _, humanoid = character()
		local top, starts = 0, {}
		local function watch()
			top = math.max(top, humanoid.WalkSpeed)
		end
		local fromPosition, fromTime = flatPosition(), Client.now()
		for _ = 1, hops do
			local waited = 0
			while not MoveFeel.isSliding() and waited < 3 do
				Client.pressKey(Enum.KeyCode.C)
				run(1 / 60, watch)
				waited += 1 / 60
			end
			check(MoveFeel.isSliding(), "slide-hop chain: each slide starts")
			table.insert(starts, Client.now())
			run(0.15, watch)
			humanoid.Jump = true
			run(0.1, watch)
		end
		local average = (flatPosition() - fromPosition).Magnitude / (Client.now() - fromTime)
		local shortest = math.huge
		for index = 2, #starts do
			shortest = math.min(shortest, starts[index] - starts[index - 1])
		end
		return top, average, shortest
	end

	return {
		-- Joining: League HQ lighting from the first frame, and the camera
		-- glides around to face the portals (the queue area)
		{
			Name = "FeelJoinLobby",
			Backdrop = "lobby",
			Frames = 1,
			Build = function()
				join({ Weapon = "Pistol" })
				-- STYLE.md 5.7 (this old Config has no LobbyTunnel, so AtmosphereFeel stands in)
				near(Client.lighting.ClockTime, 14.2, 0.01, "lobby starts on League HQ ClockTime")
				near(Client.lighting.Brightness, 2.6, 0.001, "League HQ brightness")
				local depth = Client.lighting:FindFirstChild("FeelLobbyDepth")
				check(depth ~= nil and depth.Enabled, "lobby depth of field is on")
				near(depth.FocusDistance + depth.InFocusRadius, 115, 0.01, "sharp out to the FINAL BOSS gate")
				near(Client.lighting.Bloom.Intensity, 0.3, 0.001, "lobby bloom")
				near(Client.lighting.Bloom.Size, 24, 0.001, "lobby bloom size")
				near(Client.lighting.Bloom.Threshold, 1.7, 0.001, "lobby bloom threshold")
				near(Client.lighting.SunRays.Intensity, 0.04, 0.001, "lobby sun rays")
				run(1.5)
				-- Facing the middle of the portal row from (20, 3, 40)
				local wanted = Vector3.new(0 - 20, 0, -44 - 40).Unit
				local facing = flatLook()
				check(facing:Dot(wanted) > 0.995, `camera faces the queue area (dot {facing:Dot(wanted)})`)
				near(pitchDegrees(Client.camera.CFrame), -9, 1.5, "lobby camera looks a little down")
				near(Client.player.CameraMinZoomDistance, 0.5, 0.001, "zoom limit is back to normal")
				-- Walk around the lobby (third person: footsteps, no head bob)
				setMove(Vector3.new(0, 0, -1))
				run(1)
				setMove(Vector3.zero)
				run(0.3)
				assertNoErrors("FeelJoinLobby")
			end,
		},

		-- Running, sliding, jumping out of a slide, landing, getting hit
		{
			Name = "FeelRoundSlide",
			Backdrop = "sky",
			Frames = 1,
			Build = function()
				join({ Weapon = "Rifle", Gun_Rifle = true })
				run(0.3)
				startRound("Day")
				giveGun()
				local MoveFeel = Client.require("MoveFeel")
				local CameraFx = Client.require("CameraFx")
				local _, humanoid = character()
				check(Client.player.CameraMode == Enum.CameraMode.LockFirstPerson, "first person in a round")

				-- Run forward
				setMove(Vector3.new(0, 0, -1))
				run(0.5)
				near(humanoid.WalkSpeed, 16, 0.01, "normal run speed")
				local runFov = Client.camera.FieldOfView
				near(runFov, 70, 0.5, "no speed FOV at run speed")

				-- Slide
				Client.pressKey(Enum.KeyCode.C)
				check(MoveFeel.isSliding(), "C starts a slide while running")
				run(1 / 60)
				check(humanoid.WalkSpeed > 30, `slide boosts speed (WalkSpeed {humanoid.WalkSpeed})`)
				check(humanoid.WalkSpeed <= 16 + MoveFeel.SLIDE.Boost + 0.01, "the boost is run speed + Boost")
				run(0.15)
				local pose = MoveFeel.viewmodelPose()
				check(pose.Position.Y < -0.05, `the gun lowers while sliding ({pose.Position.Y})`)
				-- A few frames off the ground (a seam, a stair edge) don't end it
				sim.blip = 4
				run(4 / 60)
				check(MoveFeel.isSliding(), "a moment off the ground keeps the slide")
				check(Client.camera.FieldOfView > runFov + 3, `slide punches the FOV ({Client.camera.FieldOfView})`)
				local head = character():FindFirstChild("Head")
				local drop = head.CFrame.Position.Y - Client.camera.CFrame.Position.Y
				check(drop > 0.8, `slide drops the camera ({drop} studs)`)
				local slideSpeedEarly = humanoid.WalkSpeed
				run(0.3)
				check(humanoid.WalkSpeed < slideSpeedEarly, "slide speed bleeds off")
				run(1)
				check(not MoveFeel.isSliding(), "slide ends")
				near(humanoid.WalkSpeed, 16, 0.5, "back to run speed after the slide")
				check(MoveFeel.viewmodelPose().Position.Magnitude < 1e-4, "gun pose back to normal")
				-- Can't spam: right after a slide ends, the next one is refused
				run(0.4)
				Client.pressKey(Enum.KeyCode.C)
				check(MoveFeel.isSliding(), "ready again")
				while MoveFeel.isSliding() do
					run(1 / 60)
				end
				Client.pressKey(Enum.KeyCode.LeftControl)
				run(1 / 60)
				check(not MoveFeel.isSliding(), "refused right after a slide (cooldown)")
				run(0.3)
				check(not MoveFeel.isSliding(), "a press long before it's ready doesn't start one later")
				run(0.5)

				-- Slide, then jump out of it: the speed carries into the air
				-- (with a slide animation set, to run that path too)
				MoveFeel.SLIDE.Animation = "rbxassetid://1"
				run(0.3)
				Client.pressKey(Enum.KeyCode.LeftControl)
				check(MoveFeel.isSliding(), "Left Ctrl slides too")
				run(0.15)
				humanoid.Jump = true
				run(2 / 60)
				check(not MoveFeel.isSliding(), "jumping ends the slide")
				check(humanoid.WalkSpeed > 24, `slide jump keeps the speed in the air ({humanoid.WalkSpeed})`)
				check(humanoid.WalkSpeed <= 16 + MoveFeel.SLIDE.Boost + 0.01, "kept speed is capped")
				check(soundPlayed("Jump"), "the Jumping state plays the jump sound")
				local airSpeed = humanoid.WalkSpeed
				run(0.3)
				check(humanoid.WalkSpeed > 20 and humanoid.WalkSpeed <= airSpeed, "air speed bleeds slowly")
				-- Landing, then the kept speed bleeds off on the ground
				run(1)
				near(humanoid.WalkSpeed, 16, 0.5, "kept speed is gone a while after landing")
				check(soundPlayed("Land"), "landing sound")
				check(not soundPlayed("HardLand"), "landing your own jump isn't a hard landing")

				-- Sliding into a wall stops the slide
				run(0.8)
				sim.wallZ = sim.position.Z - 6
				Client.pressKey(Enum.KeyCode.C)
				check(MoveFeel.isSliding(), "slide toward a wall")
				run(0.35)
				check(not MoveFeel.isSliding(), "hitting the wall ends the slide")
				sim.wallZ = nil
				run(0.6)

				-- A big fall (40 studs) lands hard: the thump plays
				sim.position = Vector3.new(sim.position.X, sim.ground + 40, sim.position.Z)
				sim.airborne, sim.vy = true, 0
				run(1)
				check(not sim.airborne, "landed after the fall")
				check(soundPlayed("HardLand"), "a big fall lands hard")
				run(0.5)

				-- Head bob while running in first person
				run(0.4)
				local bobbing = false
				for _ = 1, 30 do
					run(1 / 60)
					local headY = head.CFrame.Position.Y
					if math.abs(Client.camera.CFrame.Position.Y - headY) > 0.005 then
						bobbing = true
					end
				end
				check(bobbing, "head bob moves the camera while running")

				-- Getting shot from the right: knocked away, and a shake
				Client.fireClient("Damaged", Client.camera.CFrame * Vector3.new(30, 0, -10))
				Client.signalOf(humanoid, "HealthChanged"):Fire(78)
				run(0.1)
				local _, _, roll = Client.camera.CFrame:ToOrientation()
				check(math.deg(roll) > 0.3, `hit from the right leans the view left (roll {math.deg(roll)})`)
				run(0.6)
				setMove(Vector3.zero)
				run(0.6)

				-- Strafing right leans right
				setMove(Vector3.new(1, 0, 0))
				run(0.6)
				local _, _, lean = Client.camera.CFrame:ToOrientation()
				check(math.deg(lean) < -0.5, `strafing right leans right (roll {math.deg(lean)})`)
				-- Aiming down sights calms the lean (and the bob)
				CameraFx.setFovScale("Ads", 0.8)
				run(0.6)
				local _, _, aimLean = Client.camera.CFrame:ToOrientation()
				check(math.abs(aimLean) < math.abs(lean) * 0.5, `lean is calmer while aiming ({math.deg(aimLean)})`)
				CameraFx.setFovScale("Ads", nil)
				setMove(Vector3.zero)
				run(0.8)
				check(CameraFx.zoom() >= 0.999, "no zoom held")
				assertNoErrors("FeelRoundSlide")
			end,
		},

		-- Every Move hack still works with the feel changes on top
		{
			Name = "FeelRoundHacks",
			Backdrop = "sky",
			Frames = 1,
			Build = function()
				join({
					Weapon = "Pistol",
					Hack_SpeedHack = true,
					Level_SpeedHack = 4, -- fully upgraded: 45 run speed
					Hack_BunnyHop = true,
					Hack_SuperJump = true,
					Hack_FovChanger = true,
					Hack_Fly = true,
					Hack_Noclip = true,
					Hack_Teleport = true,
					Hack_GodMode = true,
					Hack_Spinbot = true,
					Hack_Spider = true,
					Hack_InfiniteJump = true,
				})
				run(0.3)
				startRound("Night", { Modifier = "LowGravity", ModifierName = "Low Gravity" })
				giveGun()
				local MoveFeel = Client.require("MoveFeel")
				local _, humanoid, root = character()
				near(Client.workspace.Gravity, 196.2 * 0.4, 0.01, "Low Gravity")
				near(humanoid.JumpHeight, 18, 0.01, "Super Jump")

				-- FOV Changer goes through CameraFx.fov
				setMove(Vector3.zero)
				run(0.8)
				near(Client.camera.FieldOfView, 95, 0.5, "FOV Changer")

				-- Speed Hack and Bunny Hop: hold Space and run
				setMove(Vector3.new(0, 0, -1))
				hold(Enum.KeyCode.Space, true)
				run(4)
				check(humanoid.WalkSpeed > 30, `hop chain builds speed ({humanoid.WalkSpeed})`)
				check(Client.camera.FieldOfView > 96, `going fast widens the view ({Client.camera.FieldOfView})`)
				check(humanoid.WalkSpeed <= 72.01, "hop chain stays under the 72 cap")
				check(not soundPlayed("HardLand"), "Super Jump hop landings aren't hard landings")
				hold(Enum.KeyCode.Space, false)
				run(2)
				near(humanoid.WalkSpeed, 45, 0.01, "Speed Hack run speed")

				-- Footsteps top out at about 5 a second, even at Speed Hack's 45
				local footstep = Client.getService("SoundService"):FindFirstChild("FeelFootstep")
				check(footstep ~= nil, "footsteps play")
				local steps, lastPitch = 0, footstep.PlaybackSpeed
				run(2, function()
					if footstep.PlaybackSpeed ~= lastPitch then
						steps += 1
						lastPitch = footstep.PlaybackSpeed
					end
				end)
				print(string.format("FEEL footsteps at 45 studs/s: %.1f a second", steps / 2))
				check(steps >= 8 and steps <= 11, `footsteps a second at 45 studs/s ({steps / 2})`)

				-- Slide with Speed Hack in Low Gravity, then hop out
				local before = humanoid.WalkSpeed
				Client.pressKey(Enum.KeyCode.C)
				check(MoveFeel.isSliding(), "slide with Speed Hack")
				run(1 / 60)
				check(humanoid.WalkSpeed > before + 10, "slide boost on top of Speed Hack")
				check(humanoid.WalkSpeed <= before + MoveFeel.SLIDE.Boost + 0.01, "Speed Hack slide is capped at run speed + Boost")
				run(0.3)
				humanoid.Jump = true
				run(0.5)
				check(humanoid.WalkSpeed > before, "slide hop keeps speed with Low Gravity")
				run(3)

				-- Spinbot turns you; Spider climbs
				local _, yawBefore = root.CFrame:ToOrientation()
				run(0.2)
				local _, yawAfter = root.CFrame:ToOrientation()
				check(math.abs(yawAfter - yawBefore) > 0.01, "Spinbot spins")
				check(humanoid.AutoRotate == false, "Spinbot takes over turning")

				-- Fly: F on, Left Ctrl flies down instead of sliding
				Client.pressKey(Enum.KeyCode.F)
				run(0.1)
				check(humanoid.PlatformStand, "Fly on")
				Client.pressKey(Enum.KeyCode.LeftControl)
				check(not MoveFeel.isSliding(), "no slide while flying")
				hold(Enum.KeyCode.Space, true)
				run(1)
				hold(Enum.KeyCode.Space, false)
				check(Client.camera.FieldOfView > 95, "flying fast widens the view")
				Client.pressKey(Enum.KeyCode.F)
				run(0.1)
				check(not humanoid.PlatformStand, "Fly off")
				-- Fall back down: a hard landing
				run(3)

				-- Noclip, God Mode, Teleport kick
				Client.pressKey(Enum.KeyCode.N)
				run(0.2)
				Client.pressKey(Enum.KeyCode.N)
				Client.pressKey(Enum.KeyCode.G)
				local sentGodMode = false
				for _, sent in Client.sent() do
					if sent.Remote == "Ability" and sent.Args[1] == "GodMode" then
						sentGodMode = true
					end
				end
				check(sentGodMode, "God Mode key asks the server")
				Client.pressKey(Enum.KeyCode.T)
				MoveFeel.teleported()
				run(0.5)
				setMove(Vector3.zero)
				run(0.5)
				assertNoErrors("FeelRoundHacks")
			end,
		},

		-- Shooting, reloading and swapping guns while moving and sliding
		{
			Name = "FeelRoundGunplay",
			Backdrop = "sky",
			Frames = 1,
			Build = function()
				join({
					Weapon = "Rifle",
					Gun_Rifle = true,
					Gun_SMG = true,
					Gun_Shotgun = true,
					Gun_Sniper = true,
					Gun_Minigun = true,
					Gun_Rocket = true,
					Hack_Aimbot = true,
					Hack_Triggerbot = true,
					Hack_AimAssist = true,
				})
				run(0.3)
				startRound("Warehouse")
				giveGun()
				local Gun = Client.require("Gun")
				local CameraFx = Client.require("CameraFx")
				local function shots()
					local count = 0
					for _, sent in Client.sent() do
						if sent.Remote == "Fire" then
							count += 1
						end
					end
					return count
				end

				setMove(Vector3.new(0, 0, -1))
				Gun.setTrigger(true)
				run(0.6)
				check(shots() > 3, `rifle fires while running ({shots()})`)
				Client.pressKey(Enum.KeyCode.C)
				run(0.5)
				Gun.setTrigger(false)
				Client.pressKey(Enum.KeyCode.R)
				run(2.2)
				Client.fireClient("HitConfirm", true, false, 42, Vector3.new(0, 4, 2980), false)
				Client.fireClient("HitConfirm", false, true, 21, Vector3.new(2, 4, 2985), false)

				for _, weapon in { "SMG", "Shotgun", "Sniper", "Minigun", "Rocket" } do
					Client.setAttributes({ Weapon = weapon })
					run(0.2)
					local before = shots()
					Gun.setTrigger(true)
					if weapon == "Sniper" then
						hold(Enum.UserInputType.MouseButton2, true) -- scoped, and Aimbot's key
						CameraFx.setFovScale("Ads", 0.4) -- what gunplay's zoom does
					end
					run(1.4)
					Gun.setTrigger(false)
					check(shots() > before, `{weapon} fires`)
					if weapon == "Sniper" then
						check(Client.camera.FieldOfView < 40, `held zoom shrinks the FOV ({Client.camera.FieldOfView})`)
						hold(Enum.UserInputType.MouseButton2, false)
						CameraFx.setFovScale("Ads", nil)
					end
					Client.pressKey(Enum.KeyCode.R)
					run(0.5)
				end
				-- Recoil through CameraFx.kick, the way gunplay does it
				for _ = 1, 8 do
					CameraFx.kick(0.8, 0.1, 0.6)
					run(0.1)
				end
				setMove(Vector3.zero)
				run(1)
				near(Client.camera.FieldOfView, 70, 0.6, "FOV settles back to 70")
				assertNoErrors("FeelRoundGunplay")
			end,
		},

		-- Shakes, punches and bumps are visual only: they must not move your
		-- aim. Kicks must move it, and drift back by `recover`.
		{
			Name = "FeelCameraNoDrift",
			Backdrop = "sky",
			Frames = 1,
			Build = function()
				join({ Weapon = "Pistol" })
				run(0.3)
				startRound("Day")
				local CameraFx = Client.require("CameraFx")
				setMove(Vector3.zero)
				run(0.5)
				local startPitch, startYaw = Client.camera.CFrame:ToOrientation()
				for _ = 1, 10 do
					CameraFx.shake(2, 0.4)
					CameraFx.punch(4, 3, 5)
					CameraFx.bump(1)
					CameraFx.setTilt("Test", 6)
					CameraFx.setOffset("Test", CFrame.new(0.3, -0.5, 0) * CFrame.Angles(0.05, 0.05, 0))
					run(0.1)
				end
				CameraFx.setTilt("Test", nil)
				CameraFx.setOffset("Test", nil)
				run(1.5)
				local pitch, yaw = Client.camera.CFrame:ToOrientation()
				near(math.deg(pitch), math.deg(startPitch), 0.01, "shakes and punches leave pitch alone")
				near(math.deg(yaw), math.deg(startYaw), 0.01, "shakes and punches leave yaw alone")

				-- A kick moves your aim, and 60% of it drifts back
				CameraFx.kick(5, 0, 0.6)
				run(0.12)
				local peak = Client.camera.CFrame:ToOrientation()
				check(math.deg(peak - startPitch) > 2.5, `kick moves the aim up ({math.deg(peak - startPitch)})`)
				run(2)
				pitch = Client.camera.CFrame:ToOrientation()
				near(math.deg(pitch - startPitch), 2, 0.1, "40% of the kick stays")

				-- punchFov eases back, setFovScale holds, and they add up
				CameraFx.setFovScale("Ads", 0.8)
				run(0.2)
				near(Client.camera.FieldOfView, 56, 0.2, "held zoom 0.8")
				CameraFx.punchFov(10, 0.5)
				run(1 / 60)
				check(Client.camera.FieldOfView > 62, "a punch on top of a zoom")
				run(0.6)
				near(Client.camera.FieldOfView, 56, 0.2, "punch eased back")
				CameraFx.clear()
				run(0.1)
				near(Client.camera.FieldOfView, 70, 0.01, "clear() drops the zoom")
				assertNoErrors("FeelCameraNoDrift")
			end,
		},

		-- Round over: lighting dips back to League HQ and the camera glides
		-- out behind you toward the queue area
		{
			Name = "FeelBackToLobby",
			Backdrop = "lobby",
			Frames = 1,
			Build = function()
				join({ Weapon = "Pistol" })
				run(0.3)
				startRound("Night")
				run(0.5)
				near(Client.lighting.ClockTime, 22, 0.01, "Night round lighting")
				near(Client.lighting.ExposureCompensation, 0.2, 0.001, "Night exposure from LOOKS")
				near(Client.lighting.Bloom.Threshold, 1.1, 0.001, "Night glow threshold")
				check(not Client.lighting.FeelLobbyDepth.Enabled, "no depth of field in rounds")
				check(Client.lighting:FindFirstChild("FeelTransition") ~= nil, "lobby -> round dip")
				-- Face away from the portals, then the round ends
				Client.camera.CFrame = CFrame.lookAt(Client.camera.CFrame.Position, Client.camera.CFrame.Position + Vector3.new(0, 0, 10))
				sim.position = Vector3.new(-25, 3, 35)
				Client.setAttributes({ InRound = false })
				check(Client.player.CameraMode == Enum.CameraMode.Classic, "back to the lobby camera")
				run(1 / 60)
				near(Client.lighting.ClockTime, 14.2, 0.01, "lighting switches the moment the round ends")
				run(1.6)
				near(Client.lighting.ClockTime, 14.2, 0.01, "back to League HQ lighting")
				check(Client.lighting.FeelLobbyDepth.Enabled, "lobby depth of field back on")
				local wanted = Vector3.new(0 + 25, 0, -44 - 35).Unit
				check(flatLook():Dot(wanted) > 0.99, `camera turned around to the queue area (dot {flatLook():Dot(wanted)})`)
				-- Fullbright toggles without the dip
				Client.setAttributes({ Hack_Fullbright = true })
				run(0.5)
				near(Client.lighting.ClockTime, 14, 0.01, "Fullbright")
				near(Client.lighting.ExposureCompensation, 0, 0.001, "Fullbright adds nothing")
				Client.setAttributes({ Hack_Fullbright = false })
				run(0.5)

				-- A round starting leaves zoom limits it didn't set alone (a
				-- Third Person hack's, say)
				Client.player.CameraMinZoomDistance = 6
				startRound("Day")
				near(Client.player.CameraMinZoomDistance, 6, 0.001, "enterRound leaves other zoom limits alone")
				Client.setAttributes({ InRound = false })
				run(1 / 60)
				near(Client.player.CameraMinZoomDistance, 13, 0.001, "back in the lobby: zoomed out")
				run(1)
				near(Client.player.CameraMinZoomDistance, 0.5, 0.001, "and the zoom limit put back")
				assertNoErrors("FeelBackToLobby")
			end,
		},

		-- Slide-hop chains can't stack speed: with no hacks they top out at
		-- run speed + Boost (34), and slides can't come faster than Recharge.
		-- With Speed Hack the cap is its run speed + Boost.
		{
			Name = "FeelSlideChain",
			Backdrop = "sky",
			Frames = 1,
			Build = function()
				join({ Weapon = "Pistol" })
				run(0.3)
				startRound("Day")
				local MoveFeel = Client.require("MoveFeel")
				local _, humanoid = character()
				setMove(Vector3.new(0, 0, -1))
				run(0.5)
				local top, average, shortest = slideHops(MoveFeel, 6)
				print(string.format("FEEL slide-hop chain, no hacks: top %.1f, average %.1f studs/s, slides every %.2f s or more", top, average, shortest))
				check(top <= 34.5, `no-hack slide-hops top out at 34 (got {top})`)
				-- The paid speed hacks stay better: Bunny Hop alone tops out at 16 * 1.6 = 25.6, Speed Hack runs at 30+
				check(average < 25.6, `no-hack slide-hops average under Bunny Hop's best (got {average})`)
				check(shortest >= MoveFeel.SLIDE.Recharge - 0.02, `slides at most every Recharge seconds ({shortest})`)
				run(2)
				near(humanoid.WalkSpeed, 16, 0.01, "back to run speed")

				-- Fully upgraded Speed Hack (45): capped at 63
				Client.setAttributes({ Hack_SpeedHack = true, Level_SpeedHack = 4 })
				run(0.5)
				near(humanoid.WalkSpeed, 45, 0.01, "Speed Hack run speed")
				local hackTop, hackAverage = slideHops(MoveFeel, 5)
				print(string.format("FEEL slide-hop chain, Speed Hack 45: top %.1f, average %.1f studs/s", hackTop, hackAverage))
				check(hackTop <= 63.5, `Speed Hack slide-hops top out at 63 (got {hackTop})`)
				setMove(Vector3.zero)
				run(1.5)
				assertNoErrors("FeelSlideChain")
			end,
		},

		-- Walking between League HQ zones (STYLE.md 5.7) fades without the
		-- lobby/round dip; a round from The Tunnel still gets the dip
		{
			Name = "FeelLobbyZones",
			Backdrop = "lobby",
			Frames = 1,
			Build = function()
				join({ Weapon = "Pistol" })
				run(0.5)
				local AtmosphereFeel = Client.require("AtmosphereFeel")
				local Config = Client.require("ReplicatedStorage.Shared.Config")
				local depth = Client.lighting.FeelLobbyDepth
				check(AtmosphereFeel.isLobby("Lobby") and AtmosphereFeel.isLobby("LobbyTunnel"), "lobby zones count as the lobby")
				check(not AtmosphereFeel.isLobby("Day") and not AtmosphereFeel.isLobby("Fullbright"), "maps don't")
				-- What a newer Atmosphere.themeName does as you walk (its Config has STYLE 5.7's zone themes)
				local rgb = Color3.fromRGB
				local themes = {
					LobbyTunnel = {
						ClockTime = 14.2, Brightness = 1.2, Ambient = rgb(52, 56, 70), OutdoorAmbient = rgb(70, 76, 96),
						Atmosphere = { Density = 0.32, Haze = 1.2, Color = rgb(70, 80, 110), Decay = rgb(40, 40, 70) },
						Tint = rgb(236, 238, 255), Contrast = 0.18, Saturation = 0.12, Bloom = 0.8,
					},
					LobbyTrophy = {
						ClockTime = 14.2, Brightness = 1.4, Ambient = rgb(96, 70, 52), OutdoorAmbient = rgb(110, 86, 66),
						Atmosphere = { Density = 0.3, Haze = 1.2, Color = rgb(255, 214, 170), Decay = rgb(140, 96, 70) },
						Tint = rgb(255, 240, 224), Contrast = 0.12, Saturation = 0.08, Bloom = 0.45,
					},
				}
				local function walkTo(name)
					local theme = themes[name] or Config.Themes[name] or Config.Themes.Lobby
					AtmosphereFeel.apply(name, AtmosphereFeel.prepare(name, theme))
					run(0.3)
				end
				local dips = AtmosphereFeel.dips
				walkTo("LobbyTunnel")
				check(AtmosphereFeel.dips == dips, "Concourse -> Tunnel: no dip")
				near(depth.FarIntensity, 0, 0.001, "no blur in The Tunnel")
				near(Client.lighting.SunRays.Intensity, 0, 0.001, "no sun rays in The Tunnel")
				walkTo("LobbyTrophy")
				check(AtmosphereFeel.dips == dips, "Tunnel -> Trophy Hall: no dip")
				walkTo("Lobby")
				check(AtmosphereFeel.dips == dips, "Trophy Hall -> Concourse: no dip")
				check(depth.Enabled and depth.FarIntensity > 0.1, "Concourse blur back")
				walkTo("LobbyTunnel")
				-- Queue on a Tunnel pad: the round gets the quick dip
				walkTo("Night")
				check(AtmosphereFeel.dips == dips + 1, "Tunnel -> round: the dip")
				check(not depth.Enabled, "no blur in rounds")
				walkTo("LobbyTunnel")
				check(AtmosphereFeel.dips == dips + 2, "round -> Tunnel: the dip")
				walkTo("Lobby")
				assertNoErrors("FeelLobbyZones")
			end,
		},
	}
end
