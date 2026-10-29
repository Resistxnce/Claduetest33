-- Preview scenes for the characters: every new bot type and boss, the lobby
-- characters holding their props, a lineup of everyone, and the bots in the
-- aiming pose they fight in.
--
--   tools/preview/preview.sh <this file> <outDir> [nameFilter]
return function(World)
	local BotOutfits = World.require("ServerScriptService.Server.BotOutfits")
	local BotTypes = World.require("ReplicatedStorage.Shared.ConfigExtra.BotTypes")
	local LobbyNpcs = World.require("ServerScriptService.Server.LobbyNpcs")

	local BOTS = { "ScriptKiddie", "Speedrunner", "Camper", "Streamer", "Smurf", "Enforcer", "WallhackWendy", "TPTyler", "GodModeGary" }
	local LOBBY = { "Vendor", "Curator", "QueueHost" }
	-- Bots.luau's aimPose
	local AIM_POSE = {
		RightShoulder = CFrame.Angles(math.rad(85), 0, math.rad(-8)),
		LeftShoulder = CFrame.Angles(math.rad(80), 0, math.rad(38)),
	}

	-- In game the rig's Motor6Ds bend the arms. The preview rig has no joint
	-- solver, so this turns the body parts below each joint around it instead
	-- (before the outfit goes on, so the gear follows).
	local function pose(rig, joints)
		local motors = {}
		for _, item in rig:GetDescendants() do
			if item:IsA("Motor6D") then
				motors[item.Name] = item
			end
		end
		for jointName, rotation in joints or {} do
			local joint = motors[jointName]
			if joint then
				local moving = { [joint.Part1] = true }
				local grew = true
				while grew do
					grew = false
					for _, motor in motors do
						if moving[motor.Part0] and not moving[motor.Part1] then
							moving[motor.Part1] = true
							grew = true
						end
					end
				end
				local part1 = joint.Part1
				local pivot = CFrame.new(part1.CFrame * Vector3.new(0, part1.Size.Y / 2, 0)) * joint.Part0.CFrame.Rotation
				local turn = pivot * rotation * pivot:Inverse()
				for part in moving do
					part.CFrame = turn * part.CFrame
				end
			end
		end
	end

	local function botRig(name, aiming)
		local botType = BotTypes.Types[name]
		local rig = World.rig(botType.Colors, botType.Scale)
		if aiming then
			pose(rig, AIM_POSE)
		end
		BotOutfits.dress(rig, name, World.gear)
		rig.Name = botType.Name or name
		return rig
	end

	local function lobbyRig(kind)
		local rig = World.rig(LobbyNpcs.Kinds[kind].Colors)
		pose(rig, BotOutfits.Poses[kind])
		BotOutfits.dress(rig, kind, World.gear)
		rig.Name = kind
		return rig
	end

	-- Stands rigs side by side, left to right as seen from the front (-X),
	-- a bit wider apart for big ones
	local function lineup(rigs)
		local model = Instance.new("Model")
		model.Name = "Lineup"
		local x = 0
		for _, rig in rigs do
			local _, size = rig:GetBoundingBox()
			local width = math.max(size.X, 4)
			rig:PivotTo(rig:GetPivot() - Vector3.new(x + width / 2, 0, 0))
			x += width + 1
			rig.Parent = model
		end
		return model
	end

	local scenes = {}
	for _, name in BOTS do
		table.insert(scenes, {
			Name = name,
			Kind = "npc",
			Build = function()
				return botRig(name)
			end,
		})
	end
	for _, kind in LOBBY do
		table.insert(scenes, {
			Name = "Lobby_" .. kind,
			Kind = "npc",
			Views = { "front", "three_quarter", "left" },
			Build = function()
				return lobbyRig(kind)
			end,
		})
	end
	table.insert(scenes, {
		Name = "NpcLineup",
		Kind = "npc",
		Views = { "front", "three_quarter" },
		Build = function()
			local rigs = {}
			for _, name in BOTS do
				table.insert(rigs, botRig(name))
			end
			for _, kind in LOBBY do
				table.insert(rigs, lobbyRig(kind))
			end
			return lineup(rigs)
		end,
	})
	table.insert(scenes, {
		Name = "BotsAiming",
		Kind = "npc",
		Views = { "front", "three_quarter" },
		Build = function()
			local rigs = {}
			for _, name in BOTS do
				table.insert(rigs, botRig(name, true))
			end
			return lineup(rigs)
		end,
	})
	return scenes
end
