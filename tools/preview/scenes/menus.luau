-- The game's real screens, built from gamesrc with Main.client.luau the way
-- the client starts them. "*Ref" screens use the viewport size of the Studio
-- screenshots in refs/ (1739x617) so they can be compared pixel for pixel.
local REF_VIEWPORT = { 1739, 617 }

return function(Client)
	-- Starts the whole client like a fresh join, with a stand-in character
	local function join(credits, attributes, health)
		Client.setStat("Credits", credits or 100)
		if attributes then
			Client.setAttributes(attributes)
		end
		Client.spawnCharacter({ Health = health or 100 })
		Client.run("Main")
	end

	-- A player a few hacks in: ESP Box and Triggerbot bought, some upgrades
	local SOME_HACKS = {
		Hack_EspBox = true,
		Hack_EspHealth = true,
		Hack_Triggerbot = true,
		Hack_Radar = true,
		Level_EspBox = 2,
		Bans = 1,
		Kills = 140,
		Weapon = "Rifle",
		Gun_Rifle = true,
	}

	local function hackMenu(tab, credits)
		return function()
			join(credits or 3200, SOME_HACKS)
			Client.require("HackMenu").openTab(tab)
		end
	end

	-- In a Bronze round on Skate Park, like refs/game_rifle_skatepark.jpeg
	local function inRound()
		join(296100, { Weapon = "Rifle", Gun_Rifle = true }, 95)
		-- a moment in the lobby first, like a real join
		Client.step(0.25)
		Client.setAttributes({
			RoundKind = "Bots",
			ArenaName = "Arena_1",
			ArenaDisplayName = "Bronze",
			MapName = "Skate Park",
			ArenaTheme = "Day",
			Modifier = "BigHeads",
			ModifierName = "Big Heads",
			RoundStartsAt = Client.serverTime() - 20,
			RoundEndsAt = Client.serverTime() + 472.5,
			Wave = 1,
			Waves = 1,
			BotsAlive = 5,
			InRound = true,
		})
	end

	return {
		{ Name = "Lobby", Backdrop = "lobby", Build = function()
			join(100)
		end },
		{ Name = "LobbyRef", Viewport = REF_VIEWPORT, Backdrop = "lobby", Build = function()
			join(100)
		end },
		{ Name = "LobbyPhone", Viewport = { 844, 390 }, Touch = true, Backdrop = "lobby", Build = function()
			join(100)
		end },
		{ Name = "HackVisual", Backdrop = "lobby", Build = hackMenu("Visual") },
		{ Name = "HackAim", Backdrop = "lobby", Build = hackMenu("Aim", 60000) },
		{ Name = "HackGuns", Backdrop = "lobby", Build = hackMenu("Guns") },
		{ Name = "HackBanWave", Backdrop = "lobby", Build = hackMenu("Ban Wave", 12000) },
		{ Name = "HackStore", Backdrop = "lobby", Build = hackMenu("Store") },
		{ Name = "HackQuests", Backdrop = "lobby", Build = hackMenu("Quests") },
		{ Name = "HackSearch", Backdrop = "lobby", Build = function()
			join(3200, SOME_HACKS)
			Client.pressKey(Enum.KeyCode.H)
			Client.type(Client.find("Hud.HackMenu.Search"), "esp")
		end },
		{ Name = "SkinSpin", Backdrop = "lobby", Build = function()
			join(4500, { Weapon = "Rifle", Skin = "Crimson", Skin_Crimson = true, Skin_Carbon = true, Skin_Galaxy = true, Pity = 17 })
			local SkinSpin = Client.require("SkinSpin")
			SkinSpin.start()
			SkinSpin.open()
		end },
		{ Name = "Round", Backdrop = "sky", Build = inRound },
		{ Name = "RoundRef", Viewport = REF_VIEWPORT, Backdrop = "sky", Build = inRound },
		-- The real screenshot behind the HUD (its own HUD blurs away)
		{ Name = "RoundOnScreenshot", Viewport = REF_VIEWPORT, Build = inRound, Backdrop = {
			Image = "../refs/game_rifle_skatepark.jpeg", Crop = { 2, 126, 1318, 468 }, Blur = 8, Dim = 0.05,
		} },
		{ Name = "RoundKillFeed", Backdrop = "sky", Build = function()
			inRound()
			Client.setAttributes({ Hack_EspBox = true, Hack_Radar = true, Hack_Triggerbot = true })
			Client.fireClient("KillFeed", "Noob_Bot", 25, false)
			Client.fireClient("KillFeed", "xX_Tryhard_Xx", 60, false)
			Client.fireClient("KillFeed", "Aimbot_Andy", 500, true)
			Client.fireClient("Notify", "Wave 2", Color3.fromRGB(255, 200, 60))
		end },
	}
end
