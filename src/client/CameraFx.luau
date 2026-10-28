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
-- Kicks turn the real camera, so your aim really moves (and drifts back by
-- `recover`). Shakes, tilts and offsets are visual only: they're added on top
-- of the camera right after Roblox's camera scripts set it each frame.
local RunService = game:GetService("RunService")

local CameraFx = {}

local RECOIL_SPEED = 18 -- how fast a kick reaches its peak
local RECOVER_SPEED = 6 -- how fast the recoverable part drifts back

local pendingPitch, pendingYaw = 0, 0 -- kick still to apply
local returnPitch, returnYaw = 0, 0 -- part of past kicks still to drift back
local shakes = {} -- { Strength, Duration, Age }
local fovPunches = {} -- { Amount, Duration, Age }
local tilts = {} -- [name] = degrees
local offsets = {} -- [name] = CFrame
local fovScales = {} -- [name] = multiplier

function CameraFx.kick(pitch, yaw, recover)
	recover = math.clamp(recover or 0.6, 0, 1)
	pendingPitch += pitch
	pendingYaw += yaw or 0
	returnPitch += pitch * recover
	returnYaw += (yaw or 0) * recover
end

function CameraFx.shake(strength, duration)
	table.insert(shakes, { Strength = strength, Duration = math.max(duration, 0.01), Age = 0 })
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
		local t = punch.Age / punch.Duration
		extra += punch.Amount * (1 - t) ^ 2
	end
	return base + extra
end

local function update(dt)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
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
	local shakeX, shakeY = 0, 0
	for index = #shakes, 1, -1 do
		local shake = shakes[index]
		shake.Age += dt
		if shake.Age >= shake.Duration then
			table.remove(shakes, index)
		else
			local fade = 1 - shake.Age / shake.Duration
			shakeX += (math.random() - 0.5) * 2 * shake.Strength * fade
			shakeY += (math.random() - 0.5) * 2 * shake.Strength * fade
		end
	end
	for index = #fovPunches, 1, -1 do
		local punch = fovPunches[index]
		punch.Age += dt
		if punch.Age >= punch.Duration then
			table.remove(fovPunches, index)
		end
	end
	local offset = CFrame.identity
	for _, extra in offsets do
		offset *= extra
	end
	camera.CFrame = cframe * offset * CFrame.Angles(math.rad(shakeX), math.rad(shakeY), math.rad(roll))
end

function CameraFx.start()
	-- Right after Roblox's camera scripts, and before the viewmodel reads the camera
	RunService:BindToRenderStep("EarnEspCameraFx", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraFx
