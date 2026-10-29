-- Camera effects that every client system shares, so recoil, landing dips,
-- slides and explosions add up instead of fighting over the camera.
--
--   CameraFx.kick(pitch, yaw, recover)  aim kick in degrees; recover (0-1) is how much drifts back
--   CameraFx.shake(strength, duration)  a short shake, strength in degrees
--   CameraFx.punchFov(amount, duration) a quick field-of-view change that eases back
--   CameraFx.setTilt(name, degrees)     a held roll (leaning into a strafe or a slide)
--   CameraFx.setOffset(name, cframe)    a held camera offset (crouching in a slide, a landing dip)
--   CameraFx.setFovScale(name, scale)   a held zoom, like aiming down sights (0.8 = 20% closer)
--   CameraFx.fov(base)                  base field of view with zooms and punches, for whoever sets FieldOfView
--
-- Extras:
--   CameraFx.punch(pitch, yaw, roll)    a springy knock in degrees that bounces back (landings, getting hit)
--   CameraFx.bump(studs)                a springy drop straight down that bounces back (landings)
--   CameraFx.zoom(except)               the held zoom right now (1 = none), leaving out one name
--   CameraFx.clear()                    drops every shake, punch and held effect, everyone's (a hard reset)
--
-- Kicks turn the real camera, so your aim really moves (and drifts back by
-- `recover`). Shakes, punches, bumps, tilts and offsets are visual only: they're
-- added on top of the camera right after Roblox's camera scripts set it, and
-- taken off again before they run next frame (at Camera - 2), so they never
-- push your aim around. Something that turns the camera itself before the
-- camera scripts should bind at Camera - 1.
local RunService = game:GetService("RunService")

local CameraFx = {}

local RECOIL_SPEED = 18 -- how fast a kick reaches its peak
local RECOVER_SPEED = 6 -- how fast the recoverable part drifts back
local SHAKE_SPEED = 26 -- how fast a shake wobbles (higher is buzzier)
local SPRING_STIFFNESS = 260 -- punches and bumps: how hard they spring back
local SPRING_DAMPING = 20 -- and how quickly they settle (lower bounces more)
local SPRING_STEP = 1 / 120 -- springs move in small steps so a slow frame can't blow them up
local MIN_FOV, MAX_FOV = 1, 120 -- what Roblox allows

local pendingPitch, pendingYaw = 0, 0 -- kick still to apply
local returnPitch, returnYaw = 0, 0 -- part of past kicks still to drift back
local shakes = {} -- { Strength, Duration, Age, Seed }
local fovPunches = {} -- { Amount, Duration, Age }
local tilts = {} -- [name] = degrees
local offsets = {} -- [name] = CFrame
local fovScales = {} -- [name] = multiplier

-- Punch spring (pitch, yaw, roll in degrees) and bump spring (studs down)
local punchAngle, punchVelocity = Vector3.zero, Vector3.zero
local bumpDrop, bumpVelocity = 0, 0
local springTime = 0

-- What the camera was before the visual extras, so they can be taken off again
local lastCamera, lastBase, lastApplied = nil, nil, nil
local started = false

function CameraFx.kick(pitch, yaw, recover)
	recover = math.clamp(recover or 0.6, 0, 1)
	pendingPitch += pitch
	pendingYaw += yaw or 0
	returnPitch += pitch * recover
	returnYaw += (yaw or 0) * recover
end

function CameraFx.shake(strength, duration)
	table.insert(shakes, { Strength = strength, Duration = math.max(duration, 0.01), Age = 0, Seed = math.random() * 1000 })
end

function CameraFx.punchFov(amount, duration)
	table.insert(fovPunches, { Amount = amount, Duration = math.max(duration, 0.01), Age = 0 })
end

function CameraFx.setTilt(name, degrees)
	tilts[name] = if degrees and degrees ~= 0 then degrees else nil
end

function CameraFx.setOffset(name, cframe)
	offsets[name] = cframe
end

function CameraFx.setFovScale(name, scale)
	fovScales[name] = if scale and scale ~= 1 then scale else nil
end

function CameraFx.fov(base)
	for _, scale in fovScales do
		base *= scale
	end
	local extra = 0
	for _, punch in fovPunches do
		local t = math.min(punch.Age / punch.Duration, 1)
		extra += punch.Amount * (1 - t) ^ 2
	end
	return math.clamp(base + extra, MIN_FOV, MAX_FOV)
end

-- A knock that springs back with a little bounce. Each value is roughly the
-- peak in degrees: positive pitch looks up, positive roll leans left.
function CameraFx.punch(pitch, yaw, roll)
	-- With this stiffness and damping, a push of 38 peaks at about 1
	punchVelocity += Vector3.new(pitch or 0, yaw or 0, roll or 0) * 38
end

-- Drops the camera straight down by about `studs`, then springs back up
function CameraFx.bump(studs)
	bumpVelocity -= (studs or 0) * 38
end

-- The combined held zoom (1 = none). `except` leaves one name out, so an
-- effect can tell whether someone else is zoomed in.
function CameraFx.zoom(except)
	local total = 1
	for name, scale in fovScales do
		if name ~= except then
			total *= scale
		end
	end
	return total
end

function CameraFx.clear()
	pendingPitch, pendingYaw, returnPitch, returnYaw = 0, 0, 0, 0
	table.clear(shakes)
	table.clear(fovPunches)
	table.clear(tilts)
	table.clear(offsets)
	table.clear(fovScales)
	punchAngle, punchVelocity = Vector3.zero, Vector3.zero
	bumpDrop, bumpVelocity = 0, 0
end

-- Damped springs, moved in fixed small steps
local function stepSprings(dt)
	springTime += math.min(dt, 0.1)
	while springTime >= SPRING_STEP do
		springTime -= SPRING_STEP
		punchVelocity += (-punchAngle * SPRING_STIFFNESS - punchVelocity * SPRING_DAMPING) * SPRING_STEP
		punchAngle += punchVelocity * SPRING_STEP
		bumpVelocity += (-bumpDrop * SPRING_STIFFNESS - bumpVelocity * SPRING_DAMPING) * SPRING_STEP
		bumpDrop += bumpVelocity * SPRING_STEP
	end
	-- Settle completely once it's too small to see
	if punchAngle.Magnitude < 0.001 and punchVelocity.Magnitude < 0.01 then
		punchAngle, punchVelocity = Vector3.zero, Vector3.zero
	end
	if math.abs(bumpDrop) < 0.0005 and math.abs(bumpVelocity) < 0.005 then
		bumpDrop, bumpVelocity = 0, 0
	end
end

-- Before Roblox's camera scripts: take last frame's visual extras off,
-- unless something else has moved the camera since (a teleport, the aimbot)
local function restore()
	local camera = workspace.CurrentCamera
	if lastApplied and camera == lastCamera then
		local current = camera.CFrame
		if
			(current.Position - lastApplied.Position).Magnitude < 1e-3
			and (current.LookVector - lastApplied.LookVector).Magnitude < 1e-4
			and (current.UpVector - lastApplied.UpVector).Magnitude < 1e-4
		then
			camera.CFrame = lastBase
		end
	end
	lastApplied = nil
end

local function update(dt)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	dt = math.min(dt, 0.1)
	local cframe = camera.CFrame

	-- Aim kicks: move toward the pending kick, and let part of it drift back
	local stepPitch = pendingPitch * math.min(1, dt * RECOIL_SPEED)
	local stepYaw = pendingYaw * math.min(1, dt * RECOIL_SPEED)
	pendingPitch -= stepPitch
	pendingYaw -= stepYaw
	local backPitch = returnPitch * math.min(1, dt * RECOVER_SPEED)
	local backYaw = returnYaw * math.min(1, dt * RECOVER_SPEED)
	returnPitch -= backPitch
	returnYaw -= backYaw
	local pitch, yaw = stepPitch - backPitch, stepYaw - backYaw
	if pitch ~= 0 or yaw ~= 0 then
		cframe = CFrame.new(cframe.Position) * CFrame.Angles(0, math.rad(yaw), 0) * cframe.Rotation * CFrame.Angles(math.rad(pitch), 0, 0)
	end

	-- Visual-only extras on top
	local roll = 0
	for _, degrees in tilts do
		roll += degrees
	end
	local shakeX, shakeY, shakeRoll = 0, 0, 0
	for index = #shakes, 1, -1 do
		local shake = shakes[index]
		shake.Age += dt
		if shake.Age >= shake.Duration then
			table.remove(shakes, index)
		else
			-- Smooth noise instead of a new random angle every frame, so it
			-- rattles instead of flickering; it fades out fast at the end
			local fade = (1 - shake.Age / shake.Duration) ^ 2
			local t = shake.Age * SHAKE_SPEED
			local amount = shake.Strength * fade * 2
			shakeX += math.noise(t, shake.Seed) * amount
			shakeY += math.noise(shake.Seed, t) * amount
			shakeRoll += math.noise(t, 0.5, shake.Seed) * amount * 0.5
		end
	end
	for index = #fovPunches, 1, -1 do
		local punch = fovPunches[index]
		punch.Age += dt
		if punch.Age >= punch.Duration then
			table.remove(fovPunches, index)
		end
	end
	stepSprings(dt)

	local offset = CFrame.identity
	for _, extra in offsets do
		offset *= extra
	end
	if bumpDrop ~= 0 then
		offset = CFrame.new(cframe:VectorToObjectSpace(Vector3.new(0, bumpDrop, 0))) * offset
	end
	local angleX = shakeX + punchAngle.X
	local angleY = shakeY + punchAngle.Y
	local angleZ = shakeRoll + roll + punchAngle.Z

	lastCamera = camera
	if offset == CFrame.identity and angleX == 0 and angleY == 0 and angleZ == 0 then
		-- Nothing visual this frame: only the kick (if any) is left on the camera
		if cframe ~= camera.CFrame then
			camera.CFrame = cframe
		end
		lastApplied = nil
		return
	end
	camera.CFrame = cframe * offset * CFrame.Angles(math.rad(angleX), math.rad(angleY), math.rad(angleZ))
	lastBase = cframe
	lastApplied = camera.CFrame
end

function CameraFx.start()
	if started then
		return
	end
	started = true
	-- Before Roblox's camera scripts: take off last frame's extras. Camera - 2,
	-- so anything that turns the camera at Camera - 1 (the lobby glide) turns
	-- the clean camera, not one with a shake on it.
	RunService:BindToRenderStep("EarnEspCameraFxRestore", Enum.RenderPriority.Camera.Value - 2, restore)
	-- Right after Roblox's camera scripts, and before the viewmodel reads the camera
	RunService:BindToRenderStep("EarnEspCameraFx", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraFx
