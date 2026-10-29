-- The lobby camera. When you join or come back from a round, the camera eases
-- out of first person to a spot behind you and turns toward the queue area
-- (the rank pads), instead of snapping there. Entering a round gets a quick
-- field of view "drop in". Main.client.luau calls these from updateCameraMode.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraFx = require(script.Parent.CameraFx)

local player = Players.LocalPlayer

local LobbyCam = {}

local ZOOM_OUT = 13 -- studs behind you once you're back in the lobby
local GLIDE_TIME = 0.9 -- seconds to turn toward the queue area
local LOBBY_PITCH = -9 -- degrees: looking a little down the lanes
local ROUND_FOV_PUNCH = 12 -- wider view for a moment as a round starts

-- The queue area: parts tagged QueueFocus (tag one in the lobby to choose,
-- like the RANKED gate), or else the lobby's pads (League HQ's PadBase) and
-- portals (the old lobby's PortalField), or else straight north (-Z), where
-- both the old portal row and the League HQ ranked lane are
local FOCUS_TAG = "QueueFocus"
local FOCUS_NAMES = { PadBase = true, PortalField = true, QueuePad = true, RankPad = true }
local NORTH = Vector3.new(0, 0, -1)

local glideId = 0
local cachedFocus = nil
local GLIDE_STEP = "EarnEspLobbyGlide"
local gliding = false
local raisedZoom = false -- whether we pushed CameraMinZoomDistance out (and must put it back)

-- Puts the zoom limit back, only if enterLobby raised it (so a Third Person
-- hack's own zoom limits are left alone)
local function lowerZoom()
	if raisedZoom then
		raisedZoom = false
		player.CameraMinZoomDistance = 0.5
	end
end

local function stopGlide()
	if gliding then
		gliding = false
		RunService:UnbindFromRenderStep(GLIDE_STEP)
	end
end

local function findFocus()
	local tagged = CollectionService:GetTagged(FOCUS_TAG)
	if #tagged > 0 then
		local sum = Vector3.zero
		local count = 0
		for _, item in tagged do
			if item:IsA("BasePart") then
				sum += item.Position
				count += 1
			elseif item:IsA("Model") then
				sum += item:GetPivot().Position
				count += 1
			end
		end
		if count > 0 then
			return sum / count
		end
	end
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		return nil
	end
	local sum, count = Vector3.zero, 0
	for _, item in lobby:GetDescendants() do
		if item:IsA("BasePart") and FOCUS_NAMES[item.Name] then
			sum += item.Position
			count += 1
		end
	end
	return if count > 0 then sum / count else nil
end

-- Which way to face from `position`, flat on the ground
local function queueDirection(position)
	cachedFocus = cachedFocus or findFocus()
	if cachedFocus then
		local flat = Vector3.new(cachedFocus.X - position.X, 0, cachedFocus.Z - position.Z)
		if flat.Magnitude > 4 then
			return flat.Unit
		end
	end
	return NORTH
end

local function angleBetween(from, to)
	return (to - from + math.pi) % (2 * math.pi) - math.pi
end

-- Turns the camera a little each frame, so your own mouse movement still
-- counts while it glides. Runs just before Roblox's camera scripts, and after
-- CameraFx has taken last frame's shakes off (Camera - 2), so it turns the
-- clean camera.
local function glide(id, direction)
	local camera = workspace.CurrentCamera
	local startPitch, startYaw = camera.CFrame:ToOrientation()
	local goalYaw = math.atan2(-direction.X, -direction.Z)
	local turnYaw = angleBetween(startYaw, goalYaw)
	local turnPitch = math.rad(LOBBY_PITCH) - startPitch
	local elapsed, done = 0, 0
	stopGlide()
	gliding = true
	RunService:BindToRenderStep(GLIDE_STEP, Enum.RenderPriority.Camera.Value - 1, function(dt)
		if id ~= glideId or player:GetAttribute("InRound") then
			stopGlide()
			return
		end
		elapsed += dt
		local t = math.min(elapsed / GLIDE_TIME, 1)
		local eased = 1 - (1 - t) ^ 3
		local step = eased - done
		done = eased
		local current = workspace.CurrentCamera
		local pitch, yaw = current.CFrame:ToOrientation()
		pitch = math.clamp(pitch + turnPitch * step, math.rad(-80), math.rad(80))
		yaw += turnYaw * step
		current.CFrame = CFrame.new(current.CFrame.Position) * CFrame.fromOrientation(pitch, yaw, 0)
		if t >= 1 then
			stopGlide()
		end
	end)
end

-- Back in the lobby (or just joined): ease out behind you, toward the queue
function LobbyCam.enterLobby()
	glideId += 1
	local id = glideId
	cachedFocus = nil
	-- Pushes the camera out of first person; Roblox's camera eases the zoom
	player.CameraMinZoomDistance = ZOOM_OUT
	raisedZoom = true
	local function start()
		if id ~= glideId or player:GetAttribute("InRound") then
			return
		end
		lowerZoom()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			glide(id, queueDirection(root.Position))
		end
	end
	task.delay(0.15, function()
		if player.Character then
			start()
		else
			-- Joining: wait for the character to arrive
			player.CharacterAdded:Once(function()
				task.delay(0.3, start)
			end)
		end
	end)
end

-- A round is starting: stop any glide and give the view a quick punch
function LobbyCam.enterRound()
	glideId += 1
	stopGlide()
	lowerZoom()
	CameraFx.punchFov(ROUND_FOV_PUNCH, 0.6)
end

return LobbyCam
