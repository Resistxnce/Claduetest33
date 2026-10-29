-- Gunplay test: boots the real client (the game with the hooks in
-- docs/hooks + this repo's src), starts a Bots round and fires, aims, reloads and switches
-- every gun, moves, jumps and lands, toggles the weapon hacks and checks
-- recoil, aim-down-sights, spread, effects cleanup and that Client.errors()
-- stays empty. Every screen fails loudly (an error in Build) on any problem.
--
--   EARNESP_SRC=/path/to/hooked/src MODELS_SRC=src \
--     tools/preview/gui.sh tools/preview/tests/gunplay_screens.luau out/gunplay
return function(Client)
	local Enum = Client.Enum

	-- The preview has no ParticleEmitter:Emit (Roblox does); stand one in that
	-- counts bursts per emitter kind, so impacts can be checked
	local emitted = {}
	pcall(function()
		Client.roblox.implementMethod("ParticleEmitter", "Emit", function(self, count)
			emitted[self.Name] = (emitted[self.Name] or 0) + (count or 1)
		end)
	end)

	local function check(condition, message)
		if not condition then
			error("CHECK FAILED: " .. message, 2)
		end
	end

	local function noErrors(label)
		local errors = Client.errors()
		if #errors > 0 then
			error(`{label}: {#errors} client errors:\n` .. table.concat(errors, "\n---\n"), 0)
		end
	end

	local function say(...)
		print("     [test]", ...)
	end

	-- Walls of different materials. The preview's raycasts never hit (and
	-- can't be replaced), so impacts are fired at these directly.
	local wallMaterials = { Enum.Material.Concrete, Enum.Material.Metal, Enum.Material.Wood, Enum.Material.Grass, Enum.Material.Glass, Enum.Material.SmoothPlastic }
	local walls = {}
	local function makeWalls()
		table.clear(walls)
		local folder = Instance.new("Folder")
		folder.Name = "TestWalls"
		for index, material in wallMaterials do
			local part = Instance.new("Part")
			part.Name = "Wall" .. index
			part.Anchored = true
			part.Size = Vector3.new(20, 20, 1)
			part.Material = material
			part.Color = Color3.fromRGB(120 + index * 15, 110, 100)
			part.CFrame = CFrame.new(0, 5, -40)
			part.Parent = folder
			walls[index] = part
		end
		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Anchored = true
		floor.Size = Vector3.new(200, 1, 200)
		floor.Material = Enum.Material.Concrete
		floor.CFrame = CFrame.new(0, -0.5, 0)
		floor.Parent = folder
		walls.Floor = floor
		folder.Parent = Client.workspace
	end
	-- Right mouse button, which the preview never presses on its own
	local rightHeld = false

	local function giveGun(rig)
		local tool = Instance.new("Tool")
		tool.Name = "Gun"
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.3, 0.3, 1)
		handle.CFrame = CFrame.new(1, 4, -1)
		handle.Parent = tool
		tool.Parent = rig
	end

	local Gun, CameraFx, Viewmodel, GunFeel, Config
	local UserInputService = Client.UserInputService

	-- Joins, starts a Bots round with `weaponId` and returns the rig
	local function boot(weaponId, extra)
		rightHeld = false
		Client.UserInputService.IsMouseButtonPressed = function(_, kind)
			return kind == Enum.UserInputType.MouseButton2 and rightHeld
		end
		Client.setStat("Credits", 5000)
		local attributes = { Weapon = weaponId, ["Gun_" .. weaponId] = true }
		for key, value in extra or {} do
			attributes[key] = value
		end
		Client.setAttributes(attributes)
		local rig = Client.spawnCharacter({ Health = 100 })
		Client.run("Main")
		-- In game FEEL.md's Main.client hook starts CameraFx
		CameraFx = Client.require("CameraFx")
		CameraFx.start()
		Gun = Client.require("Gun")
		Viewmodel = Client.require("Viewmodel")
		GunFeel = Client.require("GunFeel")
		Config = Client.require("ReplicatedStorage.Shared.Config")
		Client.step(0.2)
		giveGun(rig)
		makeWalls()
		Client.setAttributes({
			RoundKind = "Bots",
			ArenaName = "Arena_1",
			ArenaDisplayName = "Bronze",
			MapName = "Skate Park",
			ArenaTheme = "Day",
			RoundStartsAt = Client.serverTime() - 5,
			RoundEndsAt = Client.serverTime() + 400,
			Wave = 1,
			Waves = 2,
			BotsAlive = 5,
			InRound = true,
		})
		Client.step(0.5)
		-- Level the camera so recoil is easy to read
		Client.camera.CFrame = CFrame.lookAt(Vector3.new(0, 5, 0), Vector3.new(0, 5, -10))
		UserInputService = Client.UserInputService
		return rig
	end

	local function shotsSent()
		local count = 0
		for _, entry in Client.sent() do
			if entry.Remote == "Fire" then
				count += 1
			end
		end
		return count
	end

	local function pitchDegrees()
		local pitch = Client.camera.CFrame:ToOrientation()
		return math.deg(pitch)
	end

	local function viewmodelModel()
		return Client.camera:FindFirstChild("Viewmodel")
	end

	-- Angle in degrees between the camera's look and a world point
	local function offCenter(position)
		local point = Client.camera.CFrame:PointToObjectSpace(position)
		return math.deg(math.atan2(math.sqrt(point.X * point.X + point.Y * point.Y), -point.Z))
	end

	local function fire(seconds)
		Gun.setTrigger(true)
		Client.step(seconds)
		Gun.setTrigger(false)
	end

	-- Fires, aims (or scopes), reloads and checks the viewmodel for one gun
	local function exerciseWeapon(weaponId)
		local weapon = Config.getWeapon(weaponId)
		Client.setAttributes({ Weapon = weaponId, ["Gun_" .. weaponId] = true })
		Client.step(0.45)
		local model = viewmodelModel()
		check(model ~= nil, weaponId .. ": viewmodel should show in a round")
		local before = shotsSent()
		fire(if weapon.SpinUp then 1.6 else math.max(0.6, weapon.FireInterval * 2.5))
		Client.step(0.2)
		check(shotsSent() > before, weaponId .. ": should have fired")

		-- Aim down sights (or scope) while firing
		rightHeld = true
		Client.step(0.35)
		if weapon.Scope then
			check(CameraFx.fov(70) < 70 * 0.9, weaponId .. ": scoping should zoom the camera")
		elseif GunFeel.isAiming() then
			check(CameraFx.fov(70) < 70, weaponId .. ": aiming should zoom a little")
		end
		fire(math.max(0.3, weapon.FireInterval * 1.5))
		rightHeld = false
		Client.step(0.3)

		-- Reload all the way through, sampling the animation on the way
		Gun.reload()
		local steps = math.ceil((weapon.Reload + 0.4) / 0.1)
		for _ = 1, steps do
			Client.step(0.1)
		end
		check(CameraFx.fov(70) > 69.9 and CameraFx.fov(70) < 70.1 or weapon.Scope ~= nil, weaponId .. ": zoom should be off again")
		say(string.format("%-14s parts %3d  fov %.1f  spread %.2f", weaponId, #model:GetChildren(), CameraFx.fov(70), Gun.spread()))
		noErrors(weaponId)
	end

	return {
		-- Pistol: shots, recoil through CameraFx (and that it partly recovers),
		-- No Recoil, aim down sights lines the sights up, spread tightens
		{ Name = "GunplayPistol", Backdrop = "sky", Frames = 4, Build = function()
			boot("Pistol")
			local startPitch = pitchDegrees()
			fire(0.05)
			Client.step(0.06)
			local kicked = pitchDegrees() - startPitch
			Client.step(1)
			local settled = pitchDegrees() - startPitch
			say(string.format("pistol kick %.2f deg, after recovery %.2f deg", kicked, settled))
			check(kicked > 0.6, "a pistol shot should kick the aim up")
			check(settled < kicked * 0.6 and settled > 0, "most of a pistol kick should drift back")
			check(shotsSent() == 1, "one shot")

			-- No Recoil: aim doesn't move
			Client.setAttributes({ Hack_NoRecoil = true })
			Client.step(0.3)
			local level = pitchDegrees()
			fire(0.05)
			Client.step(0.3)
			check(math.abs(pitchDegrees() - level) < 0.01, "No Recoil should keep the aim still")
			Client.setAttributes({ Hack_NoRecoil = false })

			-- Aim down sights
			local hipSpread = Gun.spread()
			rightHeld = true
			Client.step(0.4)
			check(Gun.isAiming(), "right click should aim down sights")
			check(math.abs(CameraFx.fov(70) - 70 * 0.86) < 0.5, "aiming should zoom to about 0.86")
			check(Gun.spread() < hipSpread, "aiming should tighten the spread")
			local model = viewmodelModel()
			local front = model:FindFirstChild("FrontSight")
			local rear = model:FindFirstChild("RearSightL")
			check(front and rear, "pistol sights")
			local frontOff = offCenter((front.CFrame * CFrame.new(0, front.Size.Y / 2, 0)).Position)
			say(string.format("aimed: front sight top %.2f deg off center", frontOff))
			check(frontOff < 0.3, "the front sight should sit in the middle of the screen")
			check(GunFeel.sightsLinedUp(), "the pistol aims with its sights lined up")
			local aimedSensitivity = UserInputService.MouseDeltaSensitivity
			say(string.format("aimed mouse sensitivity %.3f", aimedSensitivity))
			check(math.abs(aimedSensitivity - 0.86 ^ GunFeel.ZOOM_SENSITIVITY) < 0.01, "aiming slows the mouse to match the zoom")
			rightHeld = false
			Client.step(0.4)
			check(not Gun.isAiming(), "letting go stops aiming")
			check(math.abs(CameraFx.fov(70) - 70) < 0.05, "zoom back to normal")
			check(UserInputService.MouseDeltaSensitivity == 1, "the mouse is back to the player's own speed")

			-- Dying (or losing the gun) with right click held: no zoom, no aim left over
			rightHeld = true
			Client.step(0.4)
			check(Gun.isAiming(), "aiming again before dying")
			local rig = Client.player.Character
			rig:FindFirstChildOfClass("Humanoid").Health = 0
			rig:FindFirstChild("Gun"):Destroy()
			Client.step(0.3)
			say(string.format("dead with right click held: fov %.1f, aiming %s", CameraFx.fov(70), tostring(Gun.isAiming())))
			check(not Gun.isAiming(), "no aiming while dead")
			check(math.abs(CameraFx.fov(70) - 70) < 0.05, "the death camera isn't zoomed")
			check(GunFeel.spreadScale(Config.getWeapon("Pistol")) == 1, "no aim spread left over")
			check(UserInputService.MouseDeltaSensitivity == 1, "mouse speed restored on death")
			rightHeld = false
			noErrors("pistol")
		end },

		-- Every gun: switch, fire, aim or scope, reload
		{ Name = "GunplayEveryGun", Backdrop = "sky", Frames = 4, Build = function()
			boot("Pistol", { Hack_InfiniteAmmo = false })
			for _, weapon in Config.Weapons do
				exerciseWeapon(weapon.Id)
			end
			-- Effects stay capped
			Client.step(12)
			local effects = Client.workspace:FindFirstChild("GunEffects")
			local count = if effects then #effects:GetChildren() else 0
			say("GunEffects children after 12 s:", count)
			check(count <= 60, "effects should be cleaned up or pooled")
			noErrors("every gun")
		end },

		-- Rifle: automatic climb, optic sight alignment, hits and kills
		{ Name = "GunplayRifleAds", Backdrop = "sky", Frames = 4, Build = function()
			boot("Rifle")
			local startPitch = pitchDegrees()
			fire(1)
			local climbed = pitchDegrees() - startPitch
			Client.step(1.5)
			local after = pitchDegrees() - startPitch
			say(string.format("rifle: 1 s of fire climbed %.2f deg, %.2f deg after letting go", climbed, after))
			check(climbed > 1 and climbed < 9, "an automatic should climb gently")
			check(after < climbed, "some of the climb drifts back")

			rightHeld = true
			Client.step(0.45)
			local model = viewmodelModel()
			local lens = model:FindFirstChild("ScopeEyecup") or model:FindFirstChild("ScopeLens") or model:FindFirstChild("Optic")
			if lens then
				local off = offCenter(lens.CFrame.Position)
				say(string.format("aimed rifle: optic %.2f deg off center, see-through %.2f", off, lens.LocalTransparencyModifier))
				check(off < 0.3, "the optic should be centered when aiming")
				check(lens.LocalTransparencyModifier > 0.5, "the optic should fade so you can see through it")
			end
			fire(0.5)
			rightHeld = false
			Client.step(0.5)

			-- Hit feedback: hits, a headshot, kills (gathered once a frame)
			for _ = 1, 3 do
				Client.fireClient("HitConfirm", false, false, 21, Vector3.new(0, 5, -30), false)
			end
			Client.fireClient("HitConfirm", true, false, 42, Vector3.new(0, 6, -30), false)
			Client.step(0.1)
			Client.fireClient("HitConfirm", true, true, 42, Vector3.new(0, 6, -30), false)
			Client.fireClient("HitConfirm", false, true, 21, Vector3.new(2, 5, -30), true)
			Client.step(0.5)

			-- Reload: the magazine drops out (and fades) and a new one goes in
			local model = viewmodelModel()
			local mag, receiver = model:FindFirstChild("Magazine"), model:FindFirstChild("UpperReceiver")
			check(mag ~= nil and receiver ~= nil, "rifle magazine and receiver parts")
			local rest = receiver.CFrame:ToObjectSpace(mag.CFrame).Position
			Gun.reload()
			local reloadTime = Config.getWeapon("Rifle").Reload
			Client.step(reloadTime * 0.34)
			local out = (receiver.CFrame:ToObjectSpace(mag.CFrame).Position - rest).Magnitude
			say(string.format("magazine %.2f studs out at 34%% of the reload, fade %.2f", out, mag.LocalTransparencyModifier))
			check(out > 0.2, "the magazine should drop out")
			Client.step(reloadTime * 0.8)
			local back = (receiver.CFrame:ToObjectSpace(mag.CFrame).Position - rest).Magnitude
			check(back < 0.01 and mag.LocalTransparencyModifier == 0, "a full magazine is back in after the reload")
			noErrors("rifle")
		end },

		-- Hacks: No Spread, Rapid Fire, Infinite Ammo, Disarm, Triggerbot owned
		{ Name = "GunplayHacks", Backdrop = "sky", Frames = 4, Build = function()
			boot("SMG", { Hack_NoSpread = true, Hack_RapidFire = true, Hack_InfiniteAmmo = true, Hack_Triggerbot = true, Hack_MagicBullet = true })
			Client.step(0.2)
			check(Gun.spread() == 0, "No Spread should zero the spread")
			local before = shotsSent()
			fire(1)
			local fired = shotsSent() - before
			say("SMG with Rapid Fire, 1 s:", fired, "shots")
			check(fired >= 20, "Rapid Fire should halve the time between shots")
			Client.step(3)
			fire(0.5)
			check(shotsSent() - before > fired, "Infinite Ammo keeps firing without a reload")

			-- Disarmed: no shots, and the gun drops and greys out, then comes back
			local body = viewmodelModel():FindFirstChild("Receiver") or viewmodelModel():GetChildren()[1]
			local bodyColor = body.Color
			Client.setAttributes({ DisarmedUntil = Client.serverTime() + 5 })
			local disarmed = shotsSent()
			fire(0.5)
			check(shotsSent() == disarmed, "a disarmed player can't shoot")
			check(body.Color ~= bodyColor, "a disarmed gun greys out")
			Client.setAttributes({ DisarmedUntil = 0 })
			Client.step(0.3)
			check(body.Color == bodyColor, "the gun's colors come back after a disarm")

			-- The phone AIM button aims down sights like right click
			Gun.setAimHeld(true)
			Client.step(0.3)
			check(Gun.isAiming(), "the AIM button should aim down sights")
			Gun.setAimHeld(false)
			Client.step(0.3)
			check(not Gun.isAiming(), "letting go of AIM stops aiming")

			-- Leaving the round clears zoom and hides the gun
			rightHeld = true
			Client.step(0.3)
			Client.setAttributes({ InRound = false })
			Client.step(0.3)
			rightHeld = false
			check(math.abs(CameraFx.fov(70) - 70) < 0.05, "no zoom left over after the round")
			check(viewmodelModel() == nil, "no first-person gun in the lobby")
			noErrors("hacks")
		end },

		-- Moving: strafe lean, jump and land while shooting, then a Minigun spin
		{ Name = "GunplayMovement", Backdrop = "sky", Frames = 4, Build = function()
			local rig = boot("TommyGun")
			local humanoid = rig:FindFirstChildOfClass("Humanoid")
			local root = rig:FindFirstChild("HumanoidRootPart")
			humanoid.MoveDirection = Vector3.new(1, 0, 0)
			Gun.setTrigger(true)
			Client.step(0.5)
			humanoid.FloorMaterial = Enum.Material.Air
			root.AssemblyLinearVelocity = Vector3.new(0, 40, 0)
			Client.step(0.3)
			root.AssemblyLinearVelocity = Vector3.new(0, -60, 0)
			Client.step(0.3)
			humanoid.FloorMaterial = Enum.Material.Plastic
			root.AssemblyLinearVelocity = Vector3.zero
			Client.step(0.4)
			Gun.setTrigger(false)
			humanoid.MoveDirection = Vector3.new(0, 0, -1)
			Client.step(0.5)
			humanoid.MoveDirection = Vector3.zero

			-- Minigun spins up before it fires and spins down after
			Client.setAttributes({ Weapon = "Minigun", Gun_Minigun = true })
			Client.step(0.4)
			local before = shotsSent()
			Gun.setTrigger(true)
			Client.step(0.3)
			check(shotsSent() == before, "the Minigun shouldn't fire before it spins up")
			Client.step(1)
			check(shotsSent() > before, "the Minigun fires once spun up")
			Gun.setTrigger(false)
			Client.step(1.5)
			noErrors("movement")
		end },

		-- Impacts on every kind of surface, enemy hits, explosions and shells
		{ Name = "GunplayImpacts", Backdrop = "sky", Frames = 4, Build = function()
			boot("Rifle")
			local Effects = Client.require("ReplicatedStorage.Shared.Effects")
			local GunEffects = Client.require("ReplicatedStorage.Shared.GunEffects")
			for round = 1, 12 do
				for index, wall in walls do
					if typeof(index) == "number" then
						Effects.impact(Vector3.new(index, 5, -39.5), Vector3.new(0, 0, 1), "World", wall)
					end
				end
				Effects.impact(Vector3.new(0, 5, -30), Vector3.new(0, 0, 1), "Enemy", nil)
				Effects.impact(Vector3.new(0, 5, -30), Vector3.new(0, 0, 1), "World", nil)
				Client.step(0.05)
			end
			Effects.explosion(Vector3.new(0, 3, -20), 11)
			GunEffects.headshotPop(Vector3.new(0, 6, -20))
			for _ = 1, 30 do
				GunEffects.shell(CFrame.new(1, 5, -2), Vector3.new(6, 4, 0), "Brass", 0)
				GunEffects.tracer(Vector3.new(1, 4, -2), Vector3.new(0, 5, -80), Color3.new(1, 0.9, 0.6), "Bullet", true)
				Client.step(1 / 60)
			end
			GunEffects.tracer(Vector3.new(1, 4, -2), Vector3.new(0, 5, -80), Color3.new(0.5, 0.4, 1), "Rail")
			GunEffects.tracer(Vector3.new(1, 4, -2), Vector3.new(0, 5, -80), Color3.new(0.5, 0.4, 1), "Energy")
			GunEffects.muzzleFlash(CFrame.new(1, 4, -2), Color3.new(1, 0.8, 0.2), 1.2)
			local folder = Client.workspace:FindFirstChild("GunEffects")
			check(folder ~= nil, "effects folder")
			local holes = 0
			for _, child in folder:GetChildren() do
				if child.Name == "BulletHole" then
					holes += 1
				end
			end
			say("bullet holes:", holes, "effect parts:", #folder:GetChildren())
			check(holes <= 40, "bullet holes are capped at 40")

			-- Bullet holes lie flat on the surface: the disc's face (its X axis)
			-- along the normal, on walls, floors and slopes
			local slope = Vector3.new(0, 1, 1).Unit
			for _, normal in { Vector3.new(0, 0, 1), Vector3.new(0, 1, 0), slope, Vector3.new(-1, 0, 0) } do
				for _ = 1, 40 do
					Effects.impact(Vector3.new(0, 5, -39.5), normal, "World", walls[1])
				end
				for _, child in folder:GetChildren() do
					if child.Name == "BulletHole" and child.Parent then
						local facing = math.abs(child.CFrame.XVector:Dot(normal))
						check(facing > 0.99, string.format("a bullet hole should lie flat (normal %s, facing %.3f)", tostring(normal), facing))
					end
				end
			end
			say("bullet holes lie flat on walls, floors and slopes")

			-- The raycast's material wins over the part's (Terrain reports its
			-- voxel material that way): grass gets dirt, not sparks
			table.clear(emitted)
			Effects.impact(Vector3.new(6, 5, -39.5), Vector3.new(0, 0, 1), "World", walls[6], Enum.Material.Grass)
			check((emitted.Dust or 0) > 0 and (emitted.Sparks or 0) == 0, "a Grass material hit makes dust, not sparks")
			table.clear(emitted)
			Effects.impact(Vector3.new(2, 5, -39.5), Vector3.new(0, 0, 1), "World", walls[2])
			check((emitted.Sparks or 0) > 0, "a Metal wall throws sparks")

			-- The emitter count stays capped with many surface colors
			local tint = Instance.new("Part")
			tint.Anchored = true
			tint.Material = Enum.Material.Concrete
			for index = 1, 400 do
				tint.Color = Color3.fromHSV((index * 0.618) % 1, 0.3 + (index % 7) * 0.1, 0.3 + (index % 5) * 0.15)
				Effects.impact(Vector3.new(0, 5, -39.5), Vector3.new(0, 0, 1), "World", tint)
			end
			local emitterCount = 0
			for _, child in folder:GetDescendants() do
				if child:IsA("ParticleEmitter") then
					emitterCount += 1
				end
			end
			say("particle emitters after 400 surface colors:", emitterCount)
			check(emitterCount <= 64 + 10, "the particle emitters are capped")

			-- If something destroys the effects folder, the next effects make a
			-- new one and nothing errors (the pools start over)
			folder:Destroy()
			for _ = 1, 20 do
				Effects.impact(Vector3.new(0, 5, -39.5), Vector3.new(0, 0, 1), "World", walls[1])
				GunEffects.shell(CFrame.new(1, 5, -2), Vector3.new(6, 4, 0), "Brass", 0)
			end
			Client.step(0.2)
			folder = Client.workspace:FindFirstChild("GunEffects")
			check(folder ~= nil and folder:FindFirstChild("BulletHole") ~= nil, "a new effects folder with holes after the old one was destroyed")
			noErrors("impacts after the folder was destroyed")
			Client.step(12)
			holes = 0
			for _, child in folder:GetChildren() do
				if child.Name == "BulletHole" or child.Name == "Shell" or child.Name == "Tracer" then
					holes += 1
				end
			end
			check(holes == 0, "holes, shells and tracers clean up")
			noErrors("impacts")
		end },

		-- Safety: the Aimbot owns the aim, gun sounds can't steal the kill
		-- thump's voices, and a bug in the feel code can't stop a shot
		{ Name = "GunplaySafety", Backdrop = "sky", Frames = 4, Build = function()
			boot("Shotgun")
			Client.step(1.2) -- the preview clock starts at 0
			-- Hip fire still kicks
			local level = pitchDegrees()
			fire(0.05)
			Client.step(0.08)
			local kick = pitchDegrees() - level
			check(kick > 1, "a shotgun shot kicks the aim")
			Client.step(1.5)

			-- Aimbot held (right click): no kick, and no drift after letting go
			Client.setAttributes({ Hack_Aimbot = true })
			Client.step(0.1)
			Client.camera.CFrame = CFrame.lookAt(Vector3.new(0, 5, 0), Vector3.new(0, 5, -10))
			rightHeld = true
			Client.step(0.3)
			level = pitchDegrees()
			local before = shotsSent()
			fire(0.05)
			Client.step(0.15)
			check(shotsSent() == before + 1, "a shot with the Aimbot held")
			local aimbotKick = pitchDegrees() - level
			rightHeld = false
			Client.step(1)
			local drift = pitchDegrees() - level
			say(string.format("aimbot held: kick %.2f deg, after letting go %.2f deg (hip kick %.2f)", aimbotKick, drift, kick))
			check(math.abs(aimbotKick) < 0.01 and math.abs(drift) < 0.01, "the Aimbot owns the aim: no kick, no drift after")
			Client.setAttributes({ Hack_Aimbot = false })

			-- Voices: a kill thump, then a stream of Rapid Fire SMG shots that
			-- must not reuse (cut off) any of the kill and headshot voices
			Client.setAttributes({ Weapon = "SMG", Gun_SMG = true, Hack_RapidFire = true, Hack_InfiniteAmmo = true })
			Client.step(0.5)
			Client.fireClient("HitConfirm", true, true, 42, Vector3.new(0, 6, -30), false)
			Client.step(1 / 60)
			Client.step(1 / 60)
			-- (the preview's Sound:Play does nothing, so a voice being reused
			-- shows as its Volume and PlaybackSpeed being set again)
			local soundFolder = Client.game:GetService("SoundService"):FindFirstChild("GunSounds")
			check(soundFolder ~= nil, "gun sounds folder")
			local feedback = {}
			for _, sound in soundFolder:GetChildren() do
				if string.find(sound.Name, "^Kill") or string.find(sound.Name, "^Headshot") then
					feedback[sound] = { sound.Volume, sound.PlaybackSpeed }
				end
			end
			check(next(feedback) ~= nil, "a headshot kill plays its feedback sounds")
			local before = shotsSent()
			fire(1)
			local stolen = 0
			for sound, was in feedback do
				if sound.Volume ~= was[1] or sound.PlaybackSpeed ~= was[2] then
					stolen += 1
				end
			end
			local shotVoices = 0
			for _, sound in soundFolder:GetChildren() do
				if string.find(sound.Name, "^SMGShot") then
					shotVoices += 1
				end
			end
			say("SMG shots in 1 s:", shotsSent() - before, "SMG shot voices:", shotVoices, "kill/headshot voices reused:", stolen)
			check(shotsSent() - before >= 15 and shotVoices > 0 and stolen == 0, "gunfire never reuses the kill and headshot voices")

			-- A bug in a feel module: shots still reach the server, a reload
			-- still finishes (it can't get stuck), and the error shows in the output
			local GunSounds = Client.require("GunSounds")
			local realShot, realPlay = GunSounds.shot, GunSounds.play
			GunSounds.shot = function()
				error("test: a broken shot sound")
			end
			GunSounds.play = function()
				error("test: a broken gun sound")
			end
			Client.setAttributes({ Hack_InfiniteAmmo = false, Hack_RapidFire = false })
			Client.step(0.3)
			before = shotsSent()
			fire(0.3)
			local brokenShots = shotsSent() - before
			Gun.reload()
			Client.step(Config.getWeapon("SMG").Reload + 0.2)
			before = shotsSent()
			fire(0.3)
			local afterReload = shotsSent() - before
			GunSounds.shot, GunSounds.play = realShot, realPlay
			local errors = Client.errors()
			local sawError = false
			for _, message in errors do
				if string.find(message, "a broken shot sound", 1, true) or string.find(message, "a broken gun sound", 1, true) then
					sawError = true
				end
			end
			say("with broken sounds: shots", brokenShots, "shots after a reload", afterReload, "error reported:", sawError)
			check(brokenShots >= 3, "a broken feel module can't stop shots")
			check(afterReload >= 3, "a broken feel module can't leave a reload stuck")
			check(sawError, "the feel error still shows in the output")
			table.clear(errors)
			Client.setAttributes({ Hack_RapidFire = false })
			Client.step(0.5)
			noErrors("safety")
		end },

		-- A Legendary skin and a Sniper: scope zoom with the right button, shots while scoped
		{ Name = "GunplayScope", Backdrop = "sky", Frames = 4, Build = function()
			boot("Sniper", { Skin = "Gold", Skin_Gold = true })
			Client.step(1) -- the preview clock starts at 0, so wait out the first FireInterval
			rightHeld = true
			Client.step(0.3)
			local zoomed = CameraFx.fov(70)
			say(string.format("sniper scoped fov %.1f (Config Scope %d)", zoomed, Config.getWeapon("Sniper").Scope))
			check(math.abs(zoomed - Config.getWeapon("Sniper").Scope) < 1, "scoping should zoom to the Sniper's Scope")
			check(viewmodelModel() == nil, "the first-person gun hides while scoped")
			local scopedSensitivity = UserInputService.MouseDeltaSensitivity
			say(string.format("scoped mouse sensitivity %.3f", scopedSensitivity))
			check(math.abs(scopedSensitivity - (28 / 70) ^ GunFeel.ZOOM_SENSITIVITY) < 0.01, "the scope slows the mouse to match")
			local startPitch = pitchDegrees()
			local before = shotsSent()
			fire(0.05)
			Client.step(0.08)
			local kick = pitchDegrees() - startPitch
			say(string.format("scoped sniper kick %.2f deg, shots %d", kick, shotsSent() - before))
			check(shotsSent() - before == 1 and kick > 1, "a scoped sniper shot still kicks")
			rightHeld = false
			Client.step(1.5)
			check(viewmodelModel() ~= nil, "the gun is back after unscoping")
			check(math.abs(CameraFx.fov(70) - 70) < 0.05, "zoom gone after unscoping")
			check(UserInputService.MouseDeltaSensitivity == 1, "mouse speed back after unscoping")

			-- A scoped kill: the kill punch is scaled to the zoom, so it's a
			-- small nudge, not an 11% jerk
			rightHeld = true
			Client.step(0.3)
			Client.fireClient("HitConfirm", true, true, 100, Vector3.new(0, 6, -30), false)
			Client.step(1 / 60)
			Client.step(1 / 60)
			local punched = CameraFx.fov(70)
			say(string.format("scoped kill: fov %.2f (scope %.1f)", punched, zoomed))
			check(punched < zoomed and zoomed - punched < 3 * (28 / 70) + 0.05, "a scoped kill punch is scaled to the zoom")
			rightHeld = false
			Client.step(0.5)
			noErrors("scope")
		end },

		-- Bolt and pump guns cycle between shots, the Rocket hides its round when empty
		{ Name = "GunplayActions", Backdrop = "sky", Frames = 4, Build = function()
			-- How far a part has moved from where it sits on the gun
			local function moved(model, partName, anchorName, rest)
				local part, anchor = model:FindFirstChild(partName), model:FindFirstChild(anchorName)
				check(part ~= nil and anchor ~= nil, partName .. " and " .. anchorName .. " parts")
				local offset = anchor.CFrame:ToObjectSpace(part.CFrame)
				if rest then
					return (offset.Position - rest.Position).Magnitude, offset
				end
				return 0, offset
			end

			boot("BoltRifle")
			Client.step(1.2) -- the preview clock starts at 0
			local model = viewmodelModel()
			local _, boltRest = moved(model, "BoltKnob", "Receiver")
			fire(0.05)
			Client.step(0.35)
			local boltMove = moved(model, "BoltKnob", "Receiver", boltRest)
			say(string.format("bolt knob moved %.2f studs mid-cycle", boltMove))
			check(boltMove > 0.1, "the bolt should work between shots")
			Client.step(1)
			check(moved(model, "BoltKnob", "Receiver", boltRest) < 0.01, "the bolt goes home again")

			Client.setAttributes({ Weapon = "Shotgun", Gun_Shotgun = true })
			Client.step(0.5)
			model = viewmodelModel()
			local _, pumpRest = moved(model, "Pump", "Receiver")
			fire(0.05)
			Client.step(0.3)
			local pumpMove = moved(model, "Pump", "Receiver", pumpRest)
			say(string.format("pump moved %.2f studs mid-pump", pumpMove))
			check(pumpMove > 0.1, "the pump should slide back between shots")
			Client.step(1)
			fire(0.05)
			Client.step(1)
			Gun.reload()
			Client.step(3)

			Client.setAttributes({ Weapon = "Pistol", Gun_Pistol = true })
			Client.step(0.5)
			model = viewmodelModel()
			local _, slideRest = moved(model, "Slide", "Frame")
			fire(0.02)
			Client.step(1 / 60) -- the gun is placed before Gun fires each frame, so look one frame later
			local slideMove = moved(model, "Slide", "Frame", slideRest)
			say(string.format("pistol slide blew back %.2f studs", slideMove))
			check(slideMove > 0.05, "the pistol slide should blow back")
			Client.step(0.3)
			check(moved(model, "Slide", "Frame", slideRest) < 0.01, "the slide returns")

			Client.setAttributes({ Weapon = "Rocket", Gun_Rocket = true })
			Client.step(1.5)
			-- The Rocket aims from the shoulder (its side scope put the tube by your eye)
			rightHeld = true
			Client.step(0.4)
			check(Gun.isAiming() and not GunFeel.sightsLinedUp(), "the Rocket aims from the shoulder")
			check(CameraFx.fov(70) < 70, "the Rocket still zooms a little when aimed")
			rightHeld = false
			Client.step(0.4)
			model = viewmodelModel()
			fire(0.05)
			Client.step(0.3)
			local warhead
			for _, part in model:GetChildren() do
				if string.find(part.Name, "^Warhead") then
					warhead = part
					break
				end
			end
			check(warhead ~= nil, "rocket warhead part")
			say("rocket fired, warhead hidden:", warhead.LocalTransparencyModifier)
			check(warhead.LocalTransparencyModifier > 0.9, "the fired rocket should be gone until the reload")
			Client.step(3)
			check(warhead.LocalTransparencyModifier < 0.1, "a new rocket after the reload")

			Client.setAttributes({ Weapon = "Revolver", Gun_Revolver = true })
			Client.step(0.5)
			fire(2)
			Client.step(3)
			noErrors("actions")
		end },
	}
end
