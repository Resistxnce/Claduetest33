-- Preview scenes for the new map props (src/server/Maps/Props.luau): one
-- scene per prop at the arena's center, plus a showroom with every prop laid
-- out at its real size.
return function(World)
	local Kit = World.require("ServerScriptService.Server.Maps.Kit")
	local Props = World.require("ServerScriptService.Server.Maps.Props")
	local rgb, M = Kit.rgb, Kit.M

	local NAMES = {
		"gamingDesk", "gamingChair", "pcTower", "serverRack", "vendingMachine", "arcadeCabinet",
		"couch", "beanbag", "snackCounter", "trophyCase", "jumbotron", "stageTruss", "bleachers",
		"casterDesk", "scannerGate", "laserFence", "banHammerStatue", "reportButton", "judgeBench",
		"pew", "wantedPoster", "lootCrate",
	}

	local scenes = {}
	for _, name in NAMES do
		table.insert(scenes, {
			Name = "Prop_" .. name,
			Kind = "prop",
			Build = function()
				local ctx = World.ctx(20, 20)
				Props[name](ctx, 0, 0, 0)
				return ctx.Model
			end,
		})
	end

	-- Every prop in one room, grouped like they'd be used: gaming and lounge
	-- on the left, the anti-cheat on the right, the esports stage at the back
	table.insert(scenes, {
		Name = "PropShowcase",
		Kind = "map",
		Views = { "overview", "ground" },
		Theme = "Day",
		Map = { HalfX = 60, HalfZ = 50 },
		Build = function()
			local ctx = World.ctx(60, 50, "PropShowcase", "Day")
			Kit.floor(ctx, rgb(52, 54, 66), M.SmoothPlastic)
			Kit.boundary(ctx, 14, rgb(34, 36, 46), M.Metal, rgb(255, 46, 99))

			-- Stage at the back
			Props.jumbotron(ctx, 0, 45, 0)
			Props.stageTruss(ctx, 0, 36, 0, 26, 14)
			Props.casterDesk(ctx, 0, 33, 0)
			Props.gamingChair(ctx, -1.5, 36, 0, rgb(0, 220, 255))
			Props.gamingChair(ctx, 1.5, 36, 0, rgb(255, 46, 99))
			Props.bleachers(ctx, -40, 38, -90, 4, 16)
			Props.bleachers(ctx, 40, 38, 90, 4, 16, rgb(0, 220, 255))

			-- Gaming and lounge (left)
			Props.gamingDesk(ctx, -50, 14, 0, rgb(255, 46, 99), rgb(255, 46, 99))
			Props.gamingDesk(ctx, -39, 14, 0, rgb(0, 220, 255), rgb(0, 220, 255))
			Props.pcTower(ctx, -32, 14, 0, rgb(170, 80, 255))
			for index = 0, 2 do
				Props.serverRack(ctx, -54 + index * 4.4, 0, 0)
			end
			Props.trophyCase(ctx, -38, 0, 0)
			Props.vendingMachine(ctx, -29, 0, 0)
			Props.arcadeCabinet(ctx, -22, 0, 0)
			Props.arcadeCabinet(ctx, -18, 0, 0, rgb(0, 220, 255), "NOOB INVADERS")
			Props.snackCounter(ctx, -40, -18, 0)
			Props.couch(ctx, -22, -18, 0)
			Props.beanbag(ctx, -27, -24, 20)
			Props.beanbag(ctx, -17, -24, -20, rgb(0, 220, 255))

			-- Anti-cheat (right)
			Props.scannerGate(ctx, 20, 14, 0)
			Props.laserFence(ctx, 9, 14, 0, 11)
			Props.laserFence(ctx, 31, 14, 0, 11)
			Props.banHammerStatue(ctx, 48, 16, 0)
			Props.judgeBench(ctx, 30, 0, 0)
			Props.pew(ctx, 30, -9, 180)
			Props.pew(ctx, 30, -14, 180)
			Props.reportButton(ctx, 12, -2, 0)
			-- Wanted posters hung on the left wall, facing into the room
			Props.wantedPoster(ctx, -60, -28, -90, "Aimbot_Andy", 5000, "aimbot")
			Props.wantedPoster(ctx, -60, -34, -90, "LagSwitch_420", 12000, "lag switching")
			Props.wantedPoster(ctx, -60, -40, -90, "RAGE_H4X0R", 50000, "rage hacking")
			for index, rarity in { rgb(170, 170, 180), rgb(60, 140, 255), rgb(170, 80, 255), rgb(255, 170, 40), rgb(255, 50, 70) } do
				Props.lootCrate(ctx, 2 + index * 6.5, -40, 0, rarity, index == 5)
			end
			return ctx.Model
		end,
	})

	return scenes
end
