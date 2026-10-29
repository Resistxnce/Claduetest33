-- What makes shooting feel good. Gun calls in through small "feel:" hooks:
--   * recoil that really moves your aim, through CameraFx.kick: a quick kick
--     up with a little sideways drift that partly comes back. Heavy guns
--     punch harder; automatics climb gently. No Recoil switches it off.
--   * aiming down sights on right click (guns without a scope): the gun comes
--     to the middle of the screen, the view zooms a little and the spread
--     tightens. Scoped guns zoom to their Config Scope.
--   * shot sounds per gun class, reload and bolt/pump sounds timed with the
--     first-person animation, the Minigun's spin whine
--   * muzzle smoke, ejected shells, crisp tracers, explosion shake
--   * layered hit feedback: a headshot ding, a heavy kill thump and a tiny
--     camera punch on kills (the HUD draws hitmarkers and damage numbers)
-- The numbers live in GunProfiles; the sounds in GunSounds. Everything Gun
-- calls here runs guarded (GunEffects.guard): a bug in the feel code shows
-- in the output but can never stop a shot, a reload or Gun's frame.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local GunEffects = require(Shared:WaitForChild("GunEffects"))
local CameraFx = require(script.Parent.CameraFx)
local Toggles = require(script.Parent.Toggles)
local GunProfiles = require(script.Parent.GunProfiles)
local GunSounds = require(script.Parent.GunSounds)
local ViewmodelFeel = require(script.Parent.ViewmodelFeel)
local Viewmodel = require(script.Parent.Viewmodel)

local player = Players.LocalPlayer

local GunFeel = {}

local PALETTE = GunEffects.PALETTE

-- Kill pixels (Gun bursts 10 of each color): the player's ESP color, kept
-- up to date in update (STYLE section 6: "dissolves into 30 pixels in the ESP color")
GunFeel.CONFETTI = { PALETTE.Violet, PALETTE.Violet, PALETTE.Violet }

-- Set false if something else already zooms the camera for scopes (for
-- example a Movement that sets FieldOfView from Gun.scopeFov())
GunFeel.APPLY_SCOPE_ZOOM = true
GunFeel.SCOPE_BASE_FOV = 70 -- the normal field of view the Config Scope values are compared to

-- How much aiming and scopes slow the mouse down to match the zoom, so a
-- scoped Sniper doesn't turn 2.5 times faster than what you see.
-- 1 = exactly as much as the zoom, 0 = off (the mouse stays as it is).
GunFeel.ZOOM_SENSITIVITY = 0.8

-- Camera shakes from shots, kills and explosions (1 = as tuned, 0 = none).
-- The feel lane's CameraFx (the one with CameraFx.clear) takes shakes off the
-- camera again every frame. The older CameraFx leaves them in your aim, where
-- they'd add up to a random drift, so shakes are off with it.
GunFeel.SHAKE = if CameraFx.clear then 1 else 0

local menuOpen = function()
	return false
end
local aimProgress, aimEased = 0, 0
local currentZoom = 1 -- the zoom this module holds right now (aim x scope), 1 = none
local savedSensitivity = nil -- the mouse sensitivity from before zooming in
local aiming = false
local scopeProgress = 0
local lastWeaponId = nil
local wasInRound = false
local drift = 0
local shotCount = 0
local token = 0 -- bumped to cancel scheduled reload and bolt sounds
local pendingHit = nil -- hit confirms are gathered and played once per frame
local lastDryFire = 0
local aimButton = false -- the phone AIM button (Gun.setAimHeld)
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Exclude

local function smooth(x)
	return x * x * (3 - 2 * x)
end

local function profileOf(weapon)
	return GunProfiles.get(weapon)
end

-- Runs fn after `delay` unless a reload, refill or gun switch came first
local function later(delay, fn)
	local mine = token
	task.delay(delay, function()
		if token == mine then
			fn()
		end
	end)
end

local function playLater(delay, slot, volumeScale, speedScale)
	later(delay, function()
		GunSounds.play(slot, volumeScale, speedScale)
	end)
end

-- Where a shell lands (it bounces once there)
local function floorBelow(position)
	floorParams.FilterDescendantsInstances = { player.Character, workspace.CurrentCamera }
	local result = workspace:Raycast(position, Vector3.new(0, -20, 0), floorParams)
	return if result then result.Position.Y + 0.04 else nil
end

-- Alive and holding the gun (the same test the first-person gun uses)
local function holdingGun()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0 and character:FindFirstChild(Config.Gun.ToolName) ~= nil
end

-- Whether the Aimbot is pulling the camera right now (Aim.luau: Aimbot on and right click held)
local function aimbotHeld()
	return Toggles.isOn("Aimbot") and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local function characterVelocity()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root then root.AssemblyLinearVelocity else Vector3.zero
end

-- A spent shell flies out of the ejection port, to the right and up
local function ejectShell(cframe, kind)
	if not cframe or not kind then
		return
	end
	local velocity = cframe.RightVector * (5 + math.random() * 2.5)
		+ cframe.UpVector * (3.5 + math.random() * 2)
		- cframe.LookVector * (0.5 + math.random())
		+ characterVelocity()
	local spin = CFrame.Angles(0, math.rad(90), 0)
	GunEffects.shell(cframe * spin, velocity, kind, floorBelow(cframe.Position))
end

-- Moments from the first-person animation: a bolt or pump throwing a shell,
-- a revolver dumping its empties
local function onViewmodelEvent(event, cframe, gun)
	if event == "Eject" then
		ejectShell(cframe, gun.Profile.Shell or "Brass")
	elseif event == "Dump" then
		for index = 1, 6 do
			local angle = index * math.pi / 3
			local spot = cframe * CFrame.new(math.cos(angle) * 0.12, math.sin(angle) * 0.12, 0.2)
			local velocity = spot.LookVector * -(1 + math.random()) + Vector3.new(0, -2 - math.random() * 2, 0) + characterVelocity()
			GunEffects.shell(spot * CFrame.Angles(0, math.rad(90), 0), velocity, "Brass", floorBelow(spot.Position))
		end
	end
end

function GunFeel.start(isMenuOpen)
	if isMenuOpen then
		menuOpen = isMenuOpen
	end
	ViewmodelFeel.setListener(onViewmodelEvent)
	GunEffects.setEspColorSource(Toggles.espColor)
	GunEffects.setShellLandCallback(function(kind)
		if kind == "Shell" then
			GunSounds.play("ShellTink", 0.8, 0.55)
		else
			GunSounds.play("ShellTink")
		end
	end)
end

-- How far you're aimed down sights, 0 to 1
function GunFeel.aimAmount()
	return aimEased
end

function GunFeel.isAiming()
	return aiming
end

-- Aiming with the gun's sights lined up in the middle of the screen. False
-- for guns that aim from the shoulder (the Rocket), so a HUD that hides the
-- crosshair while aiming should keep it for those.
function GunFeel.sightsLinedUp()
	return aiming and ViewmodelFeel.hasSights()
end

-- The phone AIM button: held = aim down sights (or scope), like right click
function GunFeel.setAimHeld(held)
	aimButton = held == true
end

function GunFeel.aimHeld()
	return aimButton
end

-- Aiming down sights tightens the spread a little (Gun.spread multiplies by this)
function GunFeel.spreadScale(weapon)
	if aimEased <= 0 then
		return 1
	end
	local aim = profileOf(weapon).Aim
	return if aim then 1 + (aim.Spread - 1) * aimEased else 1
end

local function playHitFeedback(hit)
	if GunSounds.PLAY_HIT_TICK then
		GunSounds.play("HitTick")
	end
	if hit.Headshot then
		if GunSounds.PLAY_HEADSHOT_DING then
			GunSounds.play("HeadshotDing")
		end
		if hit.Position then
			GunEffects.headshotPop(hit.Position)
		end
	end
	if hit.Killed then
		GunSounds.play("KillConfirm")
		if hit.Headshot then
			GunSounds.play("KillHeadshot")
		end
		-- A tiny punch in, so kills land (scaled with the zoom, so it's the
		-- same small nudge through a scope as at the hip)
		CameraFx.punchFov((if hit.Headshot then -3 else -2) * currentZoom, 0.22)
		if GunFeel.SHAKE > 0 then
			CameraFx.shake(0.12 * GunFeel.SHAKE * currentZoom, 0.1)
		end
	end
end

-- Slows the mouse to match the zoom while zoomed, and gives the player's
-- own sensitivity back after
local function updateSensitivity(zoom)
	if GunFeel.ZOOM_SENSITIVITY > 0 and zoom < 0.999 then
		if not savedSensitivity then
			savedSensitivity = UserInputService.MouseDeltaSensitivity
		end
		local goal = savedSensitivity * zoom ^ GunFeel.ZOOM_SENSITIVITY
		if math.abs(UserInputService.MouseDeltaSensitivity - goal) > 1e-4 then
			UserInputService.MouseDeltaSensitivity = goal
		end
	elseif savedSensitivity then
		UserInputService.MouseDeltaSensitivity = savedSensitivity
		savedSensitivity = nil
	end
end

-- Every frame, from Gun's RenderStepped
function GunFeel.update(dt, weapon, scoped, reloading, spin, ammo, infinite)
	local profile = profileOf(weapon)
	local inRound = player:GetAttribute("InRound") == true

	-- A new gun (or a new round) raises with a sound and drops any aim
	if inRound and (weapon.Id ~= lastWeaponId or not wasInRound) then
		GunSounds.play("Equip")
		aimProgress = 0
		token += 1
	end
	lastWeaponId = weapon.Id
	wasInRound = inRound

	-- Aim down sights: right click, guns without a scope, only while alive
	-- and holding the gun (so the death and spectate camera never stays zoomed)
	local aimSpec = profile.Aim
	local armed = inRound and holdingGun()
	local wantAim = armed
		and aimSpec ~= false
		and weapon.Scope == nil
		and not reloading
		and not menuOpen()
		and (aimButton or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
	if wantAim ~= aiming then
		aiming = wantAim
		GunSounds.play(if wantAim then "AimIn" else "AimOut")
	end
	local aimTime = if aimSpec then aimSpec.Time else 0.15
	if armed then
		aimProgress = math.clamp(aimProgress + (if wantAim then dt else -dt * 1.3) / aimTime, 0, 1)
	else
		aimProgress = 0
	end
	aimEased = smooth(aimProgress)
	ViewmodelFeel.setAim(aimEased)
	local aimZoom = if aimSpec and armed then 1 + (aimSpec.Fov - 1) * aimEased else 1
	CameraFx.setFovScale("GunAim", aimZoom)

	-- Scopes zoom in fast and out at once
	scopeProgress = if scoped and armed then math.min(1, scopeProgress + dt / 0.08) else 0
	local scopeZoom = 1
	if GunFeel.APPLY_SCOPE_ZOOM and weapon.Scope and scopeProgress > 0 then
		local scale = weapon.Scope / GunFeel.SCOPE_BASE_FOV
		scopeZoom = 1 + (scale - 1) * smooth(scopeProgress)
	elseif scoped and armed and weapon.Scope then
		-- Something else zooms the scope (APPLY_SCOPE_ZOOM off): still match the mouse to it
		scopeZoom = weapon.Scope / GunFeel.SCOPE_BASE_FOV
	end
	CameraFx.setFovScale("GunScope", if GunFeel.APPLY_SCOPE_ZOOM then scopeZoom else 1)
	currentZoom = aimZoom * scopeZoom
	updateSensitivity(currentZoom)

	GunSounds.setSpin(if weapon.SpinUp and inRound then spin else 0)
	ViewmodelFeel.setAmmo(ammo, infinite)
	ViewmodelFeel.setKickScale(if Toggles.isOn("NoRecoil") then 0.5 else 1)
	-- Disarmed by a Moderator: the gun drops and greys out
	ViewmodelFeel.setDisarmed((player:GetAttribute("DisarmedUntil") or 0) > workspace:GetServerTimeNow())
	local esp = Toggles.espColor()
	for index in GunFeel.CONFETTI do
		GunFeel.CONFETTI[index] = esp
	end

	if pendingHit then
		local hit = pendingHit
		pendingHit = nil
		playHitFeedback(hit)
	end
end

-- After every shot, from the end of Gun's shoot() (after the shot has gone
-- to the server). shots is the list of points the bullets went to, muzzle
-- where they came from, ammoLeft what's left.
function GunFeel.onShot(weapon, scoped, interval, shots, muzzle, ammoLeft)
	local profile = profileOf(weapon)
	local camera = workspace.CurrentCamera
	shotCount += 1

	GunSounds.shot(weapon, profile.Class)

	-- Recoil through CameraFx so it adds up with everything else. While the
	-- Aimbot holds the camera on a target it owns the aim: a kick would be
	-- thrown away each frame, and the part that drifts back would pull the
	-- camera below the target after you let go. So only shake and punch then.
	local shake = profile.Shake * GunFeel.SHAKE * (if scoped then 0.4 else 1)
	if not Toggles.isOn("NoRecoil") then
		if not aimbotHeld() then
			local pitch = weapon.Recoil * profile.Kick * (if scoped then 0.5 else 1) * (1 - 0.2 * aimEased)
			drift = math.clamp(drift * 0.75 + (math.random() - 0.5) * 1.2, -1, 1)
			local yaw = (drift * 0.6 + (math.random() - 0.5) * 0.8) * pitch * profile.Drift * (1 - 0.4 * aimEased)
			local recover = if interval >= 0.35 then math.max(profile.Recover, 0.8) else profile.Recover
			CameraFx.kick(pitch, yaw, recover)
		end
		if shake > 0 then
			CameraFx.shake(shake, 0.14)
		end
		if profile.Punch > 0 then
			-- Field-of-view punches scale with the zoom, so a scope doesn't jerk
			CameraFx.punchFov(profile.Punch * currentZoom, 0.18)
		end
	elseif profile.Punch > 0 then
		CameraFx.punchFov(profile.Punch * 0.5 * currentZoom, 0.15)
	end

	-- Smoke, and a flash out in the world when the first-person gun isn't drawn
	local look = camera.CFrame.LookVector
	local fast = interval < 0.2
	if not fast or shotCount % 3 == 0 then
		local puffs = if profile.Class == "Shotgun" or profile.Class == "Sniper" or profile.Class == "Launcher" then 3 else 1
		GunEffects.smoke(muzzle, look, puffs)
	end
	local firstPerson = Viewmodel.isVisible() and ViewmodelFeel.weaponId() == weapon.Id
	if not firstPerson then
		GunEffects.muzzleFlash(GunEffects.facing(muzzle, look), profile.Flash.Color, profile.Flash.Size)
	end

	-- Shells fly out on the shot, or later from a bolt or pump
	local kind = GunProfiles.actionFor(weapon.Id).Kind
	if firstPerson and profile.Shell and kind ~= "Bolt" and kind ~= "Pump" and kind ~= "Cylinder" then
		ejectShell(ViewmodelFeel.ejectCFrame(), profile.Shell)
	end

	-- Bolts and pumps work between shots (the reload does it on the last one)
	if (kind == "Bolt" or kind == "Pump") and (ammoLeft > 0 or Toggles.isOn("InfiniteAmmo")) then
		local delay = math.min(0.12, interval * 0.15)
		if kind == "Bolt" then
			local duration = math.clamp(interval * 0.7, 0.3, 0.75)
			ViewmodelFeel.startAction(delay, duration)
			playLater(delay, "BoltUp")
			playLater(delay + duration * 0.3, "BoltBack")
			playLater(delay + duration * 0.68, "BoltForward")
		else
			local duration = math.clamp(interval * 0.6, 0.25, 0.5)
			ViewmodelFeel.startAction(delay, duration)
			playLater(delay + duration * 0.2, "PumpBack")
			playLater(delay + duration * 0.68, "PumpForward")
		end
	end

	-- Explosions shake the camera when they're close
	if weapon.Splash and shots[1] then
		local distance = (shots[1] - camera.CFrame.Position).Magnitude
		local reach = weapon.Splash * 5
		local closeness = math.clamp(1 - distance / reach, 0, 1)
		if closeness > 0 and GunFeel.SHAKE > 0 then
			CameraFx.shake(0.9 * closeness * GunFeel.SHAKE, 0.35)
		end
		GunSounds.play("Explosion", math.clamp(1.2 - distance / 250, 0.2, 1))
	end
end

-- Your bullet's tracer (rockets keep Effects.tracer)
function GunFeel.tracer(from, to, color, weapon)
	local profile = profileOf(weapon)
	local style = profile.Tracer
	if style == "Energy" or style == "Rail" then
		color = color:Lerp(profile.Flash.Color, 0.65)
	end
	-- The Minigun draws every 2nd bullet; fast guns skip most of the thin trail lines
	if weapon.FireInterval < 0.06 and shotCount % 2 == 1 then
		return
	end
	local trail = weapon.FireInterval >= 0.1 or shotCount % 3 == 0
	GunEffects.tracer(from, to, color, style, trail)
end

-- When a reload starts (instead of the old single reload sound). Schedules
-- the magazine, shell and bolt sounds to match the first-person animation.
function GunFeel.onReload(weapon, ammo)
	token += 1
	ViewmodelFeel.setAmmo(ammo, false)
	ViewmodelFeel.setReloadCount(weapon.Magazine - ammo)
	GunSounds.play("ReloadStart")
	local duration = weapon.Reload
	local info = GunProfiles.reloadFor(weapon.Id)
	local timing = GunProfiles.RELOAD_TIMING[info.Style]
	local kind = GunProfiles.actionFor(weapon.Id).Kind
	local function boltAt(start, length)
		playLater(start, "BoltUp")
		playLater(start + length * 0.3, "BoltBack")
		playLater(start + length * 0.68, "BoltForward")
	end

	if info.Style == "Mag" then
		playLater(timing.MagOut * duration, "MagOut")
		playLater(timing.MagIn * duration, "MagIn")
		if kind == "Bolt" then
			boltAt(timing.Charge * duration, duration * 0.18)
		else
			playLater(timing.Charge * duration, "Charge")
		end
	elseif info.Style == "Shells" then
		local count = math.clamp(weapon.Magazine - ammo, 1, 6)
		for index = 1, count do
			local at = if count == 1 then timing.First else timing.First + (timing.Last - timing.First) * (index - 1) / (count - 1)
			playLater(at * duration, "ShellIn", 1, 0.95 + index * 0.02)
		end
		playLater(timing.Pump * duration + duration * 0.13 * 0.2, "PumpBack")
		playLater(timing.Pump * duration + duration * 0.13 * 0.68, "PumpForward")
	elseif info.Style == "Cylinder" then
		playLater(timing.Open * duration, "CylinderOpen")
		for index = 1, 3 do
			playLater((timing.First + (timing.Last - timing.First) * (index - 1) / 2) * duration, "ShellIn", 0.8, 1.1)
		end
		playLater(timing.Close * duration, "CylinderClose")
	elseif info.Style == "Front" then
		playLater(timing.MagIn * duration, "MagIn", 1.2, 0.7)
	else
		playLater(timing.MagOut * duration, "MagOut")
		playLater(timing.MagIn * duration, "MagIn")
		if kind == "Bolt" then
			boltAt(timing.MagIn * duration, duration * 0.18)
		end
	end
end

-- When the gun is refilled at once (gun switch, new round): stop pending sounds
function GunFeel.onRefill()
	token += 1
	aimProgress = 0
end

-- A click when you pull the trigger mid-reload
function GunFeel.dryFire()
	local now = os.clock()
	if now - lastDryFire > 0.2 then
		lastDryFire = now
		GunSounds.play("DryFire")
	end
end

-- From the server's HitConfirm (one per bullet, so shotgun pellets are
-- gathered and played once a frame, keeping the best: kill > headshot > hit)
function GunFeel.onHitConfirm(headshot, killed, _damage, position)
	local hit = pendingHit or {}
	hit.Headshot = hit.Headshot or headshot == true
	hit.Killed = hit.Killed or killed == true
	if position and (headshot or not hit.Position) then
		hit.Position = position
	end
	pendingHit = hit
end

-- Everything Gun calls runs guarded (see GunEffects.guard)
for _, name in { "start", "update", "onShot", "tracer", "onReload", "onRefill", "dryFire", "onHitConfirm", "setAimHeld" } do
	GunFeel[name] = GunEffects.guard(GunFeel[name])
end
local guardedSpread = GunEffects.guard(GunFeel.spreadScale)
function GunFeel.spreadScale(weapon)
	return guardedSpread(weapon) or 1
end

return GunFeel
