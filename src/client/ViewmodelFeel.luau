-- Extra life for the first-person gun. Viewmodel calls in through small
-- "feel:" hooks, and this works out the pose:
--   * aiming down sights: the gun slides to the middle of the screen with its
--     sights lined up (see-through optics fade so you can look through them)
--   * a snappy kick on springs when you shoot (back, up and a little twist)
--   * a quick raise when you switch guns, a dip when you jump and land, a
--     lean when you strafe and a slow idle sway
--   * moving parts: on reload the gun tilts, the magazine drops away and a new
--     one comes in (shotguns load shells, revolvers spin the cylinder, rocket
--     launchers take a new rocket), bolts and pumps work between shots, pistol
--     slides blow back and lock when empty, and charging handles get pulled
--   * a little star-shaped muzzle flash in the gun's class color
-- GunFeel tells it how far you're aiming, your ammo, and when to cycle.
-- Everything Viewmodel calls runs guarded (GunEffects.guard): if the feel
-- code ever errors, the gun falls back to its plain pose and keeps working.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local GunEffects = require(Shared:WaitForChild("GunEffects"))
local GunProfiles = require(script.Parent.GunProfiles)

local player = Players.LocalPlayer

local ViewmodelFeel = {}

local PALETTE = GunEffects.PALETTE
local STEEL = Color3.fromRGB(58, 64, 80) -- disarmed guns grey toward this
local FANCY_SKINS = { Legendary = true, Mythic = true, Secret = true } -- their flash gets a skin-colored spike
local EQUIP_TIME = 0.32
local FLASH_TIME = 0.05
local SPRING_STEP = 1 / 120

-- A spring that pulls a Vector3 back to zero. Impulses go into V.
local function newSpring(stiffness, dampingRatio)
	return { K = stiffness, C = 2 * dampingRatio * math.sqrt(stiffness), X = Vector3.zero, V = Vector3.zero }
end

local function stepSpring(spring, dt)
	local steps = math.max(1, math.ceil(dt / SPRING_STEP))
	local h = dt / steps
	for _ = 1, steps do
		spring.V += (-spring.K * spring.X - spring.C * spring.V) * h
		spring.X += spring.V * h
	end
end

-- Kick springs (snappy, a touch of overshoot) and the softer jump/land springs.
-- An impulse of peak * PEAK_TO_* gives a first swing of about `peak`.
local kickMove = newSpring(320, 0.62)
local kickTurn = newSpring(260, 0.55)
local landMove = newSpring(140, 0.45)
local landTurn = newSpring(140, 0.45)
local PEAK_TO_MOVE = math.sqrt(320) / 0.49
local PEAK_TO_TURN = math.sqrt(260) / 0.52
local PEAK_TO_LAND = math.sqrt(140) / 0.55

local function smoothstep(from, to, t)
	local x = math.clamp((t - from) / (to - from), 0, 1)
	return x * x * (3 - 2 * x)
end

-- Rises from a to b, holds, falls from c to d
local function bump(t, a, b, c, d)
	return smoothstep(a, b, t) * (1 - smoothstep(c, d, t))
end

local function easeOutCubic(x)
	return 1 - (1 - x) ^ 3
end

local function backOut(x)
	local c1 = 1.25
	return 1 + (c1 + 1) * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

-- Turns `angles` around a pivot point (gun space)
local function around(pivot, angles)
	return CFrame.new(pivot) * angles * CFrame.new(-pivot)
end

local gun -- what we know about the gun that's built right now
local aim = 0 -- 0 hip to 1 fully aimed, eased (from GunFeel)
local ammo, emptyHidden = 1, false
local equipStart = nil
local wasHidden = false
local reload = nil -- { Start, Duration, Style, Count, Fired }
local action = nil -- { Start, Duration } for bolts and pumps
local slideShot = -math.huge
local slideLocked = false
local cylinderAngle, cylinderGoal = 0, 0
local flashUntil, flashRoll, flashScale = 0, 0, 1
local flashShowing = false
local lastRoot = CFrame.identity
local listener = nil -- GunFeel hears "Eject" and "Dump" here
local kickScale = 1 -- GunFeel halves the kick with No Recoil on
local reloadCount = 4 -- rounds a reload puts in (shotgun shells)
local disarmed, disarmAmount = false, 0
local greyed = nil -- [part] = its own color, while disarmed
local shotIndex = 0

-- What changes this frame (worked out in root, used in placeParts)
local magOffset, magFade = Vector3.zero, 0
local actionExtra = CFrame.identity
local handOffset = Vector3.zero
local clearFade, appliedClear = 0, -1

-- Character motion
local wasGrounded = nil
local lastVelocityY = 0
local strafe, ahead = 0, 0
local airY, airPitch = 0, 0

local function flashPiece(name, size, color, model)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = model
	return part
end

-- Whether a line from origin along direction passes through a part's box
-- (shrunk a little, so parts that only touch the line, like a front sight
-- post, don't count)
local function lineHitsBox(offset, size, origin, direction)
	local localOrigin = offset:PointToObjectSpace(origin)
	local localDirection = offset:VectorToObjectSpace(direction)
	local half = size * 0.45
	local enter, leave = 0.1, 50
	for _, axis in { "X", "Y", "Z" } do
		local from, step, limit = localOrigin[axis], localDirection[axis], half[axis]
		if math.abs(step) < 1e-6 then
			if math.abs(from) > limit then
				return false
			end
		else
			local t1, t2 = (-limit - from) / step, (limit - from) / step
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			enter, leave = math.max(enter, t1), math.min(leave, t2)
			if enter > leave then
				return false
			end
		end
	end
	return true
end

-- While aiming, parts in the way of the sight line (an optic's lenses and
-- tube) fade so you can look through them, and parts behind the rear sight
-- (the stock, right by your eye) fade out of the way
local function findClearParts(pieces, sight, distance)
	local clear, behind = {}, {}
	if not sight then
		return clear, behind
	end
	local direction = sight.Front - sight.Rear
	direction = if direction.Magnitude > 0.01 then direction.Unit else Vector3.new(0, 0, -1)
	local eye = sight.Rear - direction * distance
	-- A bead gun's eye sits over the grip, so the stock comb fades too
	local behindLimit = if sight.Bead then 0.3 else -0.12
	for _, item in pieces do
		local name = item.Part.Name
		local isArm = name == "LeftArm" or name == "RightArm" or name == "LeftHand" or name == "RightHand"
		if not isArm and name ~= "Flash" then
			local along = (item.Offset.Position - sight.Rear):Dot(direction)
			if along < behindLimit then
				table.insert(behind, item)
			elseif lineHitsBox(item.Offset, item.Part.Size, eye, direction) then
				table.insert(clear, item)
			end
		end
	end
	return clear, behind
end

-- Viewmodel calls this after building a gun's parts (and arms)
function ViewmodelFeel.onBuild(model, pieces, weaponId, muzzleOffset, flashPart, flashLight)
	gun = nil -- (if anything below fails, the new gun just gets the plain pose)
	local weapon = Config.getWeapon(weaponId)
	local profile = GunProfiles.get(weapon)
	local reloadInfo = GunProfiles.reloadFor(weaponId)
	local rule = GunProfiles.actionFor(weaponId)
	local sight = if profile.Aim then GunProfiles.sightFor(weaponId) else false

	local magNames = {}
	for _, entry in reloadInfo.Mag do
		magNames[entry.Name] = true
	end
	local info = {
		WeaponId = weaponId,
		Weapon = weapon,
		Profile = profile,
		Reload = reloadInfo,
		Rule = rule,
		Kind = rule.Kind,
		Travel = rule.Travel or 0.15,
		Mag = {},
		Action = {},
		Grip = GunProfiles.gripFor(weaponId),
		Eject = GunProfiles.ejectFor(weaponId),
		Muzzle = muzzleOffset,
		AimPose = nil,
	}
	local pivotY, pivotZ, bestX = muzzleOffset.Position.Y, 0, math.huge
	for _, item in pieces do
		local name = item.Part.Name
		if name == "LeftHand" then
			info.Hand = item
		elseif name == "LeftArm" then
			info.Arm = item
		elseif name == "LoadingPort" then
			info.Port = item.Offset.Position
		elseif not item.Spins then
			if magNames[name] then
				table.insert(info.Mag, item)
			elseif GunProfiles.picks(name, rule) then
				table.insert(info.Action, item)
				local position = item.Offset.Position
				if rule.Pivot and name == rule.Pivot then
					pivotY, pivotZ, bestX = position.Y, position.Z, -1
				elseif math.abs(position.X) < bestX then
					pivotY, pivotZ, bestX = position.Y, position.Z, math.abs(position.X)
				end
			end
		end
	end
	info.Pivot = Vector3.new(0, pivotY, pivotZ)

	-- The left arm ends at the support hand; knowing where lets the hand move
	-- (grab a magazine, work a pump)
	if info.Arm then
		info.Support = (info.Arm.Offset * CFrame.new(0, 0, -info.Arm.Part.Size.Z / 2)).Position
	end

	-- Where the gun sits when aimed: the rear sight straight ahead of your eye
	if sight then
		local rear, front = sight.Rear, sight.Front
		local line = front - rear
		local tilt = math.clamp(math.atan2(line.Y, -line.Z), math.rad(-4), math.rad(4))
		info.AimPose = CFrame.new(0, 0, -profile.Aim.Distance) * CFrame.Angles(-tilt, 0, 0) * CFrame.new(-rear)
	end
	info.Clear, info.Behind = findClearParts(pieces, sight, if profile.Aim then profile.Aim.Distance else 1)

	-- The flash: the Viewmodel's glow ball is the hot core; three petals and
	-- a spike in the gun's class color make the star
	local flash = profile.Flash
	if flashPart then
		flashPart.Color = PALETTE.Chalk
	end
	if flashLight then
		flashLight.Color = flash.Color
		flashLight.Brightness = 4 + flash.Size * 2
		flashLight.Range = 10 + flash.Size * 4
	end
	local petals = {}
	for index = 1, 3 do
		petals[index] = flashPiece("FlashPetal" .. index, Vector3.new(0.05, 0.6, 0.02), flash.Color, model)
	end
	info.Petals = petals
	local skin = Config.getSkin(player:GetAttribute("Skin") or "Default")
	local spikeColor = if FANCY_SKINS[skin.Rarity] then skin.Accent else flash.Color:Lerp(PALETTE.Chalk, 0.45)
	info.Spike = flashPiece("FlashSpike", Vector3.new(0.09, 0.09, 0.6), spikeColor, model)
	info.FlashSize = flash.Size
	info.Pieces = pieces

	gun = info
	reload, action = nil, nil
	slideLocked = false
	cylinderAngle, cylinderGoal = 0, 0
	appliedClear = -1
	greyed = nil
	equipStart = os.clock()
	wasHidden = false
end

-- Viewmodel calls this while the gun is hidden. byScope is true when it's
-- only hidden for a scope; anything else makes the gun raise again after.
function ViewmodelFeel.onHidden(byScope)
	if not byScope then
		wasHidden = true
	end
end

-- 0 (hip) to 1 (aimed), already eased; from GunFeel every frame
function ViewmodelFeel.setAim(amount)
	aim = amount
end

-- Rounds in the gun, so empty pistols lock their slide and empty launchers
-- hide their rocket
function ViewmodelFeel.setAmmo(current, infinite)
	ammo = if infinite then math.max(current, 1) else current
	if gun and gun.Kind == "Slide" and ammo <= 0 and not reload then
		slideLocked = true
	end
	emptyHidden = gun ~= nil and gun.Reload.HideWhenEmpty and ammo <= 0
end

-- GunFeel hears moving-part moments: listener(event, worldCFrame, gun)
function ViewmodelFeel.setListener(callback)
	listener = callback
end

-- How hard the gun kicks (1 normal, 0.5 with No Recoil)
function ViewmodelFeel.setKickScale(scale)
	kickScale = scale
end

-- Disarmed by a Moderator: the gun drops 15 degrees and greys out
function ViewmodelFeel.setDisarmed(on)
	disarmed = on
end

-- How many rounds the next reload puts in, before it starts
function ViewmodelFeel.setReloadCount(count)
	reloadCount = count
end

local function tell(event, offset)
	if listener and gun then
		listener(event, lastRoot * CFrame.new(offset or gun.Eject), gun)
	end
end

-- Called from Viewmodel.kick on every shot
function ViewmodelFeel.kick()
	if not gun then
		return
	end
	local weapon, profile = gun.Weapon, gun.Profile
	local spec = profile.ViewKick
	local power = math.clamp(weapon.Recoil / spec.Ref, 0.6, 1.6) * kickScale
	local aimCalm = 1 - 0.55 * aim
	local back = spec.Back * power * (1 - 0.3 * aim)
	local pitch = math.rad(spec.Pitch) * power * aimCalm
	local roll = math.rad(spec.Roll) * power * aimCalm
	kickMove.V += Vector3.new((math.random() - 0.5) * back * 0.5, back * 0.25, back) * PEAK_TO_MOVE
	kickTurn.V += Vector3.new(pitch, (math.random() - 0.5) * roll * 0.6, (math.random() - 0.5) * 2 * roll) * PEAK_TO_TURN

	-- Very fast guns (the Minigun) flash on every other shot
	shotIndex += 1
	if weapon.FireInterval >= 0.06 or shotIndex % 2 == 0 then
		flashUntil = os.clock() + FLASH_TIME
	end
	flashRoll = math.random() * math.pi
	flashScale = gun.FlashSize * (0.8 + math.random() * 0.4) * (1 - 0.35 * aim)

	if gun.Kind == "Slide" then
		slideShot = os.clock()
	elseif gun.Kind == "Cylinder" then
		cylinderGoal += math.pi / 3
	end
end

-- Starts a bolt or pump cycle `delay` seconds from now, lasting `duration`
function ViewmodelFeel.startAction(delay, duration)
	if gun and (gun.Kind == "Bolt" or gun.Kind == "Pump") then
		action = { Start = os.clock() + delay, Duration = duration, Ejected = false }
	end
end

function ViewmodelFeel.startReload(duration)
	if not gun then
		return
	end
	reload = {
		Start = os.clock(),
		Duration = math.max(duration, 0.2),
		Style = gun.Reload.Style,
		Count = math.clamp(reloadCount, 1, 6),
		Fired = {},
	}
	action = nil
end

function ViewmodelFeel.cancelReload()
	reload = nil
	slideLocked = false
end

-- The gun's ejection port in the world, for shells (nil when not built)
function ViewmodelFeel.ejectCFrame()
	if not gun then
		return nil
	end
	return lastRoot * CFrame.new(gun.Eject)
end

-- Fires a reload moment once
local function once(name, t, at)
	if t >= at and not reload.Fired[name] then
		reload.Fired[name] = true
		return true
	end
	return false
end

local function jolt(up, back, pitch)
	kickMove.V += Vector3.new(0, up, back) * PEAK_TO_MOVE
	kickTurn.V += Vector3.new(math.rad(pitch), 0, 0) * PEAK_TO_TURN
end

-- The reload pose at progress t (0-1). Also sets magOffset, magFade,
-- handOffset and the charging-handle motion.
local function reloadPose(t)
	local style = reload.Style
	local grip = gun.Grip
	local info = gun.Reload
	local direction = info.Direction
	local grab = if info.Center and gun.Support then info.Center - gun.Support else Vector3.new(0, -0.3, 0.2)

	if style == "Mag" then
		local timing = GunProfiles.RELOAD_TIMING.Mag
		local a = bump(t, 0, 0.14, 0.84, 1)
		local outStart, outEnd = timing.MagOut, timing.MagOut + 0.16
		local inStart, inEnd = timing.MagIn - 0.18, timing.MagIn
		if t >= outStart and t < inStart then
			local u = math.clamp((t - outStart) / (outEnd - outStart), 0, 1)
			magOffset = direction * (0.06 * math.min(u * 5, 1) + 1.3 * u * u)
			magFade = math.clamp((u - 0.55) / 0.45, 0, 1)
		elseif t >= inStart and t < inEnd then
			local u = (t - inStart) / (inEnd - inStart)
			magOffset = direction * 0.9 * (1 - easeOutCubic(u))
			magFade = 1 - math.clamp(u * 4, 0, 1)
		end
		-- The left hand grabs the old magazine, leaves with it and brings the new one
		if t < outStart then
			handOffset = grab * smoothstep(0.08, outStart, t)
		elseif t < inEnd then
			handOffset = grab + magOffset
		else
			handOffset = grab * (1 - smoothstep(inEnd, 0.86, t))
		end
		if once("Seat", t, inEnd) then
			jolt(0.035, -0.02, 2.5)
		end
		if once("Charge", t, timing.Charge) then
			jolt(0.01, 0.04, 1.5)
			slideLocked = false
			if gun.Kind == "Bolt" then
				-- Chamber a round
				action = { Start = os.clock(), Duration = reload.Duration * 0.18, Ejected = true }
			end
		end
		local charge = math.clamp((t - timing.Charge) / 0.1, 0, 1)
		if charge > 0 and charge < 1 and gun.Kind ~= "Bolt" and gun.Kind ~= "Pump" and gun.Kind ~= "Cylinder" then
			local back = if charge < 0.35 then charge / 0.35 else 1 - (charge - 0.35) / 0.65
			actionExtra = CFrame.new(0, 0, gun.Travel * back)
		end
		return CFrame.new(-0.1 * a, -0.06 * a, 0.06 * a) * around(grip, CFrame.Angles(math.rad(9) * a, math.rad(-6) * a, math.rad(-22) * a))
	elseif style == "Shells" then
		local timing = GunProfiles.RELOAD_TIMING.Shells
		local a = bump(t, 0, 0.12, 0.86, 1)
		local port = gun.Port or (grip + Vector3.new(0, -0.1, -0.5))
		local reachTo = if gun.Support then port + Vector3.new(0, -0.15, 0) - gun.Support else Vector3.zero
		local count = reload.Count
		local hand = 0
		for index = 1, count do
			local at = if count == 1 then timing.First else timing.First + (timing.Last - timing.First) * (index - 1) / (count - 1)
			hand = math.max(hand, bump(t, at - 0.07, at - 0.02, at + 0.01, at + 0.05))
			if once("Shell" .. index, t, at) then
				jolt(0.008, -0.02, -1.2)
			end
		end
		handOffset = reachTo * hand
		if once("Pump", t, timing.Pump) then
			action = { Start = os.clock(), Duration = reload.Duration * 0.13, Ejected = true }
		end
		return CFrame.new(-0.06 * a, -0.05 * a, 0.04 * a) * around(grip, CFrame.Angles(math.rad(14) * a, math.rad(-4) * a, math.rad(-28) * a))
	elseif style == "Cylinder" then
		local timing = GunProfiles.RELOAD_TIMING.Cylinder
		local a = bump(t, 0, timing.Open, 0.84, 1)
		local spin = math.pi * 4 * easeOutCubic(math.clamp((t - timing.Open) / (timing.Close - timing.Open), 0, 1))
		actionExtra = around(gun.Pivot, CFrame.Angles(0, 0, cylinderAngle + spin))
		if once("Dump", t, timing.Dump) then
			tell("Dump", gun.Pivot)
		end
		local hand = 0
		for index = 1, 3 do
			local at = timing.First + (timing.Last - timing.First) * (index - 1) / 2
			hand = math.max(hand, bump(t, at - 0.06, at - 0.02, at + 0.01, at + 0.05))
		end
		handOffset = (if gun.Support then gun.Pivot + Vector3.new(-0.2, -0.05, 0.1) - gun.Support else Vector3.zero) * hand
		if once("Close", t, timing.Close) then
			jolt(0.02, 0, 3)
		end
		return CFrame.new(-0.12 * a, -0.04 * a, 0.05 * a) * around(grip, CFrame.Angles(math.rad(18) * a, math.rad(8) * a, math.rad(40) * a))
	elseif style == "Front" then
		local timing = GunProfiles.RELOAD_TIMING.Front
		local a = bump(t, 0, 0.15, 0.82, 1)
		local inStart, inEnd = timing.MagIn - 0.22, timing.MagIn
		if t < inStart then
			magFade = 1
		elseif t < inEnd then
			local u = (t - inStart) / (inEnd - inStart)
			magOffset = direction * 1.4 * (1 - easeOutCubic(u))
			magFade = 1 - math.clamp(u * 5, 0, 1)
		end
		local carry = bump(t, inStart - 0.12, inStart, inEnd, inEnd + 0.14)
		handOffset = (grab + magOffset) * carry
		if once("Seat", t, inEnd) then
			jolt(0.03, 0.03, 3)
		end
		return CFrame.new(-0.05 * a, -0.12 * a, 0.08 * a) * around(grip, CFrame.Angles(math.rad(14) * a, 0, math.rad(-10) * a))
	end

	-- Anything else: dip and tilt, with a slap from the left hand
	local timing = GunProfiles.RELOAD_TIMING.Generic
	local a = bump(t, 0, 0.16, 0.8, 1)
	handOffset = Vector3.new(0, -0.5, 0.15) * bump(t, timing.MagOut, timing.MagOut + 0.12, timing.MagIn - 0.06, timing.MagIn)
	if once("Slap", t, timing.MagIn) then
		jolt(0.03, 0, 2)
		slideLocked = false
		if gun.Kind == "Bolt" then
			action = { Start = os.clock(), Duration = reload.Duration * 0.18, Ejected = true }
		end
	end
	return CFrame.new(0, -0.16 * a, 0.08 * a) * around(grip, CFrame.Angles(math.rad(-20) * a, math.rad(10) * a, math.rad(24) * a))
end

-- The bolt or pump cycle at progress u (0-1). Sets actionExtra and returns a cant.
local function actionPose(u)
	local grip = gun.Grip
	local cant = bump(u, 0, 0.15, 0.85, 1)
	if gun.Kind == "Bolt" then
		local lift = smoothstep(0, 0.18, u) * (1 - smoothstep(0.8, 1, u))
		local pull = smoothstep(0.18, 0.42, u) * (1 - smoothstep(0.55, 0.8, u))
		actionExtra = CFrame.new(0, 0, gun.Travel * pull) * around(gun.Pivot, CFrame.Angles(0, 0, math.rad(65) * lift))
		if u >= 0.42 and not action.Ejected then
			action.Ejected = true
			tell("Eject")
		end
		return around(grip, CFrame.Angles(math.rad(5) * cant, math.rad(-3) * cant, math.rad(-10) * cant))
	end
	-- Pump: the left hand rides the pump
	local pull = smoothstep(0, 0.42, u) * (1 - smoothstep(0.5, 0.92, u))
	actionExtra = CFrame.new(0, 0, gun.Travel * pull)
	handOffset += Vector3.new(0, 0, gun.Travel * pull)
	if u >= 0.42 and not action.Ejected then
		action.Ejected = true
		tell("Eject")
	end
	return CFrame.new(0, 0, 0.04 * cant) * around(grip, CFrame.Angles(math.rad(4) * cant, 0, math.rad(-5) * cant))
end

-- The gun's pose in camera space. hip is where it sits normally (Viewmodel's
-- BASE_OFFSET and the gun's View); bob, breathe and sway are Viewmodel's own.
function ViewmodelFeel.root(dt, hip, bob, breathe, sway)
	if not gun then
		return hip * bob * breathe * sway
	end
	dt = math.min(dt, 0.1)
	local now = os.clock()
	if wasHidden then
		wasHidden = false
		equipStart = now
	end

	-- How the character is moving
	local camera = workspace.CurrentCamera
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local grounded, velocityY, move = true, 0, Vector3.zero
	if humanoid then
		grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		move = humanoid.MoveDirection
	end
	if rootPart then
		velocityY = rootPart.AssemblyLinearVelocity.Y
	end
	if wasGrounded ~= nil and grounded ~= wasGrounded then
		if grounded then
			-- Landing: dip and nod down, harder after a long fall
			local strength = math.clamp(-lastVelocityY / 50, 0.3, 1.4)
			landMove.V += Vector3.new(0, -0.1 * strength, 0.02 * strength) * PEAK_TO_LAND
			landTurn.V += Vector3.new(math.rad(-3.5) * strength, 0, 0) * PEAK_TO_LAND
		else
			-- Take-off: the gun lags behind a little
			landMove.V += Vector3.new(0, -0.035, 0) * PEAK_TO_LAND
			landTurn.V += Vector3.new(math.rad(1.5), 0, 0) * PEAK_TO_LAND
		end
	end
	wasGrounded = grounded
	lastVelocityY = velocityY
	local airGoal = if grounded then 0 else math.clamp(-velocityY * 0.0015, -0.05, 0.05)
	local pitchGoal = if grounded then 0 else math.clamp(velocityY * 0.001, -0.035, 0.035)
	airY += (airGoal - airY) * math.min(1, dt * 10)
	airPitch += (pitchGoal - airPitch) * math.min(1, dt * 10)

	local look, right = camera.CFrame.LookVector, camera.CFrame.RightVector
	local flatLook, flatRight = Vector3.new(look.X, 0, look.Z), Vector3.new(right.X, 0, right.Z)
	local side = if flatRight.Magnitude > 0.01 then move:Dot(flatRight.Unit) else 0
	local forward = if flatLook.Magnitude > 0.01 then move:Dot(flatLook.Unit) else 0
	strafe += (side - strafe) * math.min(1, dt * 8)
	ahead += (forward - ahead) * math.min(1, dt * 6)

	stepSpring(kickMove, dt)
	stepSpring(kickTurn, dt)
	stepSpring(landMove, dt)
	stepSpring(landTurn, dt)

	-- Hip to aimed
	local e = aim
	local aimPose = gun.AimPose or (CFrame.new(hip.X * 0.35, hip.Y * 0.7 + 0.08, hip.Z + 0.15) * hip.Rotation)
	local base = if e > 0 then hip:Lerp(aimPose, e) else hip
	local calm = 1 - e

	-- Viewmodel's bob, breathe and sway, quieter while aiming, plus a slow idle sway
	local motion = CFrame.identity:Lerp(bob, 1 - 0.85 * e) * CFrame.identity:Lerp(breathe, 1 - 0.7 * e) * CFrame.identity:Lerp(sway, 1 - 0.7 * e)
	local still = (1 - math.min(1, move.Magnitude)) * (1 - 0.8 * e)
	local idle = CFrame.new(math.sin(now * 1.1) * 0.006 * still, math.sin(now * 2.2) * 0.004 * still, 0)
		* CFrame.Angles(math.sin(now * 2.2) * 0.003 * still, math.sin(now * 1.1) * 0.004 * still, 0)
	local leanAmount = 1 - 0.7 * e
	local lean = CFrame.new(-strafe * 0.035 * leanAmount, airY * calm, ahead * 0.03 * leanAmount)
		* CFrame.Angles(airPitch * calm, 0, -strafe * math.rad(5) * leanAmount)
	local land = CFrame.new(landMove.X * (1 - 0.5 * e)) * CFrame.Angles(landTurn.X.X * (1 - 0.5 * e), 0, 0)
	local turn = kickTurn.X
	local kick = CFrame.new(kickMove.X) * around(gun.Grip, CFrame.Angles(turn.X, turn.Y, turn.Z))

	-- Raise when switching guns
	local equip = CFrame.identity
	if equipStart then
		local t = (now - equipStart) / EQUIP_TIME
		if t >= 1 then
			equipStart = nil
		else
			local down = 1 - backOut(t)
			equip = CFrame.new(0.12 * down, -0.7 * down, 0.25 * down)
				* around(gun.Grip, CFrame.Angles(math.rad(-50) * down, math.rad(15) * down, math.rad(25) * down))
		end
	end

	-- Moving parts
	magOffset, magFade, handOffset = Vector3.zero, 0, Vector3.zero
	actionExtra = CFrame.identity
	if gun.Kind == "Slide" then
		local since = now - slideShot
		local back = if slideLocked then 1 elseif since < 0.022 then since / 0.022 elseif since < 0.09 then 1 - (since - 0.022) / 0.068 else 0
		actionExtra = CFrame.new(0, 0, gun.Travel * back)
	elseif gun.Kind == "Cylinder" then
		cylinderAngle += (cylinderGoal - cylinderAngle) * math.min(1, dt * 22)
		actionExtra = around(gun.Pivot, CFrame.Angles(0, 0, cylinderAngle))
	end
	local pose = CFrame.identity
	if reload then
		local t = (now - reload.Start) / reload.Duration
		if t >= 1 then
			reload = nil
			slideLocked = false
			emptyHidden = false
		else
			pose = reloadPose(t)
		end
	end
	if action then
		local u = (now - action.Start) / action.Duration
		if u >= 1 then
			action = nil
		elseif u >= 0 then
			pose *= actionPose(u)
		end
	end
	if emptyHidden and not reload then
		magFade = 1
	end
	clearFade = 0.85 * e
	disarmAmount += ((if disarmed then 1 else 0) - disarmAmount) * math.min(1, dt * 8)
	if disarmAmount > 0.001 then
		pose *= CFrame.new(0, -0.12 * disarmAmount, 0.05 * disarmAmount) * around(gun.Grip, CFrame.Angles(math.rad(-15) * disarmAmount, 0, 0))
	end

	return base * motion * idle * lean * land * kick * equip * pose
end

-- Viewmodel calls this after placing every part, with the gun's world
-- CFrame, to move the animated parts and show the flash
function ViewmodelFeel.placeParts(root)
	lastRoot = root
	if not gun then
		return
	end
	if #gun.Mag > 0 and (magFade > 0 or magOffset ~= Vector3.zero or gun.MagMoved) then
		local extra = CFrame.new(magOffset)
		for _, item in gun.Mag do
			item.Part.CFrame = root * extra * item.Offset
			item.Part.LocalTransparencyModifier = magFade
		end
		gun.MagMoved = magFade > 0 or magOffset ~= Vector3.zero
	end
	if actionExtra ~= CFrame.identity then
		for _, item in gun.Action do
			item.Part.CFrame = root * actionExtra * item.Offset
		end
	end
	if gun.Hand and handOffset ~= Vector3.zero then
		-- The forearm slides along with the hand (its shoulder end is off screen)
		local move = root * CFrame.new(handOffset)
		gun.Hand.Part.CFrame = move * gun.Hand.Offset
		if gun.Arm then
			gun.Arm.Part.CFrame = move * gun.Arm.Offset
		end
	end
	if math.abs(clearFade - appliedClear) > 0.01 then
		appliedClear = clearFade
		for _, item in gun.Clear do
			-- Glowing parts would still glow right in your eye, so they go all the way
			local full = item.Part.Material == Enum.Material.Neon
			item.Part.LocalTransparencyModifier = if full then math.min(1, clearFade / 0.85) else clearFade
		end
		for _, item in gun.Behind do
			item.Part.LocalTransparencyModifier = math.min(1, clearFade / 0.85)
		end
	end

	-- Grey the gun while disarmed, and give its colors back after
	if disarmed and not greyed then
		greyed = {}
		for _, item in gun.Pieces do
			local part = item.Part
			local name = part.Name
			local isArm = name == "LeftArm" or name == "RightArm" or name == "LeftHand" or name == "RightHand"
			if part.Parent and not isArm and not string.find(name, "^Flash") then
				greyed[part] = part.Color
				part.Color = part.Color:Lerp(STEEL, 0.5)
			end
		end
	elseif not disarmed and greyed then
		for part, color in greyed do
			part.Color = color
		end
		greyed = nil
	end

	local showFlash = os.clock() < flashUntil
	if showFlash then
		local base = root * gun.Muzzle * CFrame.Angles(0, 0, flashRoll)
		for index, petal in gun.Petals do
			petal.Size = Vector3.new(0.05 * flashScale, 0.62 * flashScale, 0.02)
			petal.CFrame = base * CFrame.Angles(0, 0, (index - 1) * math.pi / 3)
			petal.Transparency = 0.1
		end
		gun.Spike.Size = Vector3.new(0.09 * flashScale, 0.09 * flashScale, 0.55 * flashScale)
		gun.Spike.CFrame = base * CFrame.new(0, 0, -0.26 * flashScale)
		gun.Spike.Transparency = 0.15
		flashShowing = true
	elseif flashShowing then
		flashShowing = false
		for _, petal in gun.Petals do
			petal.Transparency = 1
		end
		gun.Spike.Transparency = 1
	end
end

-- Which gun is built right now (nil when none)
function ViewmodelFeel.weaponId()
	return gun and gun.WeaponId
end

-- Whether the built gun lines its sights up when aimed (false: it aims from the shoulder)
function ViewmodelFeel.hasSights()
	return gun ~= nil and gun.AimPose ~= nil
end

-- Viewmodel's hooks run guarded. root has to return a pose, so if it errors
-- the gun gets its plain pose for that frame.
for _, name in { "onBuild", "onHidden", "kick", "startReload", "cancelReload", "placeParts" } do
	ViewmodelFeel[name] = GunEffects.guard(ViewmodelFeel[name])
end
local guardedRoot = GunEffects.guard(ViewmodelFeel.root)
function ViewmodelFeel.root(dt, hip, bob, breathe, sway)
	return guardedRoot(dt, hip, bob, breathe, sway) or hip * bob * breathe * sway
end

return ViewmodelFeel
