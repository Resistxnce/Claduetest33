-- Friendly characters standing around the lobby: the Skin Vendor behind the
-- SKIN SPIN stall, the Curator by the Trophy Hall and the Queue Host by the
-- portal pads. They're just for looks: they have no IsBot attribute, so ESP,
-- aim hacks and guns ignore them. Main.server.luau calls LobbyNpcs.start()
-- right after Map.build().
--
-- A character stands on any part (or at any attachment) that has the
-- attribute NpcSpot set to its kind ("Vendor", "Curator" or "QueueHost"),
-- facing that part's front. Without one, start() finds a spot by itself
-- (see the finders below) and leaves out anyone it can't place.
local Players = game:GetService("Players")

local BotOutfits = require(script.Parent.BotOutfits)

local LobbyNpcs = {}

local rgb = Color3.fromRGB
local PINK = rgb(255, 46, 99)
local STAND_BEHIND = 2.2 -- studs between the Skin Spin part and the vendor
local HOST_DISTANCE = 7 -- studs from the portal pads toward the spawn

-- Name over their head and body colors. Their outfits are in BotOutfits.
LobbyNpcs.Kinds = {
	Vendor = {
		Name = "Skin Vendor",
		Colors = { Head = rgb(234, 184, 146), Torso = rgb(242, 243, 243), Legs = rgb(44, 48, 64) },
	},
	Curator = {
		Name = "Trophy Curator",
		Colors = { Head = rgb(204, 142, 105), Torso = rgb(32, 34, 52), Arms = rgb(32, 34, 52), Legs = rgb(32, 34, 52) },
	},
	QueueHost = {
		Name = "Queue Host",
		Colors = { Head = rgb(160, 95, 53), Torso = rgb(245, 245, 245), Legs = rgb(24, 24, 28) },
	},
}
local ORDER = { "Vendor", "Curator", "QueueHost" }

local function flat(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

-- Bends a joint's resting pose, like Bots.luau's aimPose. Rigs use either
-- Motor6Ds or AnimationConstraints, depending on the place's avatar settings.
local function rotateJoint(joint, rotation)
	if not joint then
		return
	end
	if joint:IsA("Motor6D") then
		joint.C0 *= rotation
	elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
		joint.Attachment0.CFrame *= rotation
	end
end

-- A small name tag in the cheat menu's style: dark pill, pink outline
local function namePill(head, text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NamePill"
	billboard.Size = UDim2.fromOffset(#text * 9 + 36, 28)
	billboard.StudsOffset = Vector3.new(0, head.Size.Y / 2 + 1.4, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = rgb(15, 15, 21)
	pill.BackgroundTransparency = 0.1
	pill.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = PINK
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = pill
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 4)
	label.Size = UDim2.new(1, -20, 1, -8)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = rgb(242, 242, 248)
	label.Text = text
	label.Parent = pill
	billboard.Parent = head
end

-- Builds one lobby character standing at cframe (a spot on the floor; it
-- faces cframe's front). Returns the model, or nil if it couldn't be built.
function LobbyNpcs.spawn(kind, cframe)
	local info = LobbyNpcs.Kinds[kind]
	if not info then
		warn("[LobbyNpcs] Unknown kind " .. tostring(kind))
		return nil
	end
	local colors = info.Colors
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = colors.Head
	description.TorsoColor = colors.Torso
	description.LeftArmColor = colors.Arms or colors.Head
	description.RightArmColor = colors.Arms or colors.Head
	description.LeftLegColor = colors.Legs
	description.RightLegColor = colors.Legs
	local ok, rig = pcall(Players.CreateHumanoidModelFromDescription, Players, description, Enum.HumanoidRigType.R15)
	if not ok then
		warn("[LobbyNpcs] Couldn't build the " .. kind .. ": " .. tostring(rig))
		return nil
	end
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		rig:Destroy()
		return nil
	end
	rig.Name = info.Name
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

	BotOutfits.dress(rig, kind, BotOutfits.gear)
	local pose = BotOutfits.Poses[kind] or {}
	for _, joint in rig:GetDescendants() do
		if pose[joint.Name] and (joint:IsA("Motor6D") or joint:IsA("AnimationConstraint")) then
			rotateJoint(joint, pose[joint.Name])
		end
	end
	local head = rig:FindFirstChild("Head")
	if head then
		namePill(head, info.Name)
	end

	root.Anchored = true
	-- The root sits HipHeight plus half its own height above the floor
	local lift = if humanoid.HipHeight > 0 then humanoid.HipHeight + root.Size.Y / 2 else 3
	rig:PivotTo(cframe * CFrame.new(0, lift, 0))
	rig.Parent = workspace:FindFirstChild("Lobby") or workspace
	return rig
end

-- Finding spots -------------------------------------------------------------------

-- The floor under a point (a little above it), or the point itself
local function floorAt(position)
	local result = workspace:Raycast(position + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0))
	return if result then result.Position else position
end

-- A spot on the floor at position, facing toward lookAt
local function standAt(position, lookAt)
	local floor = floorAt(position)
	local ahead = flat(lookAt - floor)
	if ahead.Magnitude < 0.1 then
		ahead = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(floor, floor + ahead)
end

-- The lowest point of a part, even when it's turned (like a pad cylinder)
local function bottomOf(part)
	local cframe, half = part.CFrame, part.Size / 2
	local reach = math.abs(cframe.RightVector.Y) * half.X + math.abs(cframe.UpVector.Y) * half.Y + math.abs(cframe.LookVector.Y) * half.Z
	return part.Position - Vector3.new(0, reach, 0)
end

-- Where players come from: the lobby's spawn pad, or the middle of the lobby
local function lobbyCenter()
	local lobby = workspace:FindFirstChild("Lobby")
	local spawn = (lobby or workspace):FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		return spawn.Position
	end
	return if lobby then lobby:GetPivot().Position else Vector3.zero
end

-- Behind the Skin Spin stall: past the far face of the prompt's part, on
-- the side away from players
local function vendorSpot(items, center)
	for _, item in items do
		if item:IsA("ProximityPrompt") and item.Name == "SkinSpinPrompt" then
			local part = item.Parent
			if part and part:IsA("Attachment") then
				part = part.Parent
			elseif part and part:IsA("Model") then
				part = part.PrimaryPart
			end
			if part and part:IsA("BasePart") then
				-- pick the part's own side axis that points most away from the players
				local away = flat(part.Position - center)
				local right, back = flat(part.CFrame.RightVector), flat(-part.CFrame.LookVector)
				local direction, depth
				if math.abs(away:Dot(right)) > math.abs(away:Dot(back)) then
					direction, depth = right * math.sign(away:Dot(right)), part.Size.X / 2
				else
					direction, depth = back * (if away:Dot(back) < 0 then -1 else 1), part.Size.Z / 2
				end
				local spot = Vector3.new(part.Position.X, bottomOf(part).Y, part.Position.Z) + direction.Unit * (depth + STAND_BEHIND)
				return standAt(spot, center)
			end
		end
	end
	return nil
end

-- In front of the Trophy Hall: a part named like "TrophyHall", or a sign
-- that says TROPHY
local function curatorSpot(items, center)
	for _, item in items do
		local part
		if item:IsA("BasePart") and string.find(string.lower(item.Name), "trophy") then
			part = item
		elseif item:IsA("TextLabel") and string.find(string.upper(item.Text), "TROPHY") then
			local surface = item:FindFirstAncestorWhichIsA("SurfaceGui")
			part = surface and surface.Parent
		end
		if part and part:IsA("BasePart") then
			local toward = flat(center - part.Position)
			toward = if toward.Magnitude > 0.1 then toward.Unit else Vector3.new(0, 0, 1)
			local spot = Vector3.new(part.Position.X, bottomOf(part).Y, part.Position.Z) + toward * (math.max(part.Size.X, part.Size.Z) / 2 + 4)
			return standAt(spot, center)
		end
	end
	return nil
end

-- Beside the queue pads: between the middle two pads, a few steps toward
-- the spawn. Uses pads named QueuePad or PortalPad, else the portals themselves.
local function hostSpot(items, center)
	local pads, portals = {}, {}
	for _, item in items do
		if item:IsA("BasePart") then
			if item.Name == "QueuePad" or item.Name == "PortalPad" then
				table.insert(pads, item)
			elseif item:GetAttribute("PortalId") then
				table.insert(portals, item)
			end
		end
	end
	if #pads == 0 then
		pads = portals
	end
	if #pads == 0 then
		return nil
	end
	-- Sort along the row (whichever way it runs)
	local low, high = pads[1].Position, pads[1].Position
	for _, pad in pads do
		low, high = low:Min(pad.Position), high:Max(pad.Position)
	end
	local alongX = high.X - low.X >= high.Z - low.Z
	table.sort(pads, function(a, b)
		return if alongX then a.Position.X < b.Position.X else a.Position.Z < b.Position.Z
	end)
	local middle = math.max(1, #pads // 2)
	local a, b = pads[middle], pads[math.min(#pads, middle + 1)]
	local spot = flat((a.Position + b.Position) / 2) + Vector3.new(0, math.min(bottomOf(a).Y, bottomOf(b).Y), 0)
	local toward = flat(center - spot)
	toward = if toward.Magnitude > 0.1 then toward.Unit else Vector3.new(0, 0, 1)
	if a == b then
		-- just one pad: stand off to its side
		spot += toward:Cross(Vector3.yAxis) * 6
	end
	return standAt(spot + toward * HOST_DISTANCE, center)
end

local FINDERS = { Vendor = vendorSpot, Curator = curatorSpot, QueueHost = hostSpot }

-- A spot someone marked with the NpcSpot attribute
local function markedSpot(items, kind)
	for _, item in items do
		if item:GetAttribute("NpcSpot") == kind then
			if item:IsA("BasePart") then
				return item.CFrame * CFrame.new(0, item.Size.Y / 2, 0)
			elseif item:IsA("Attachment") then
				return item.WorldCFrame
			end
		end
	end
	return nil
end

-- Places every lobby character it can find a spot for. Call once, after
-- the lobby is built.
function LobbyNpcs.start()
	-- Everything in the world except arenas and characters (their gear has
	-- names like TrophyCup too)
	local arenas = workspace:FindFirstChild("Arenas")
	local items = {}
	for _, item in workspace:GetDescendants() do
		local model = item:FindFirstAncestorWhichIsA("Model")
		local inCharacter = model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
		if not inCharacter and not (arenas and item:IsDescendantOf(arenas)) then
			table.insert(items, item)
		end
	end
	local center = lobbyCenter()
	local missing = {}
	for _, kind in ORDER do
		local spot = markedSpot(items, kind) or FINDERS[kind](items, center)
		if spot then
			-- building a rig can wait on avatar loading, so don't hold up the server starting
			task.spawn(LobbyNpcs.spawn, kind, spot)
		else
			table.insert(missing, kind)
		end
	end
	if #missing > 0 then
		warn("[LobbyNpcs] No spot for " .. table.concat(missing, ", ") .. '. Give a lobby part the attribute NpcSpot = "<kind>" to place one.')
	end
end

return LobbyNpcs
