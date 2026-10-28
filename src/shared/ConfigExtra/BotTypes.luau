-- The extra bot types and bosses, plus the waves they show up in.
-- ConfigExtra.apply adds Types to Config.BotTypes and puts each rank's
-- ArenaWaves at the end of that rank's round. Each type uses only the
-- fields Bots.luau already reads (see Config.BotTypes), so no new bot code
-- is needed. Their outfits and boss trash talk live in server/BotOutfits.
local rgb = Color3.fromRGB

local Types = {
	-- Hides in a bush suit and snipes from far away. Ducks into cover when hurt.
	Camper = {
		Health = 180, WalkSpeed = 8, FireInterval = 2.6, HitChance = 0.35, Damage = 12, Range = 320,
		Reaction = 0.9, -- waits for the perfect shot
		UsesCover = true, Credits = 25, Gun = "Sniper", Skin = "Forest",
		Colors = { Torso = rgb(70, 88, 50), Arms = rgb(70, 88, 50), Legs = rgb(84, 74, 52) },
	},
	-- Plays for the camera: jumps around a lot, aims so-so.
	Streamer = {
		Health = 200, WalkSpeed = 16, FireInterval = 1.2, HitChance = 0.2, Damage = 7, Range = 190,
		Reaction = 0.5, Strafe = true, Jumps = true, Credits = 28, Gun = "SMG", Skin = "Bubblegum",
		Colors = { Torso = rgb(130, 60, 255), Arms = rgb(130, 60, 255), Legs = rgb(36, 36, 48) },
	},
	-- Looks exactly like a Noob, plays like a Pro
	Smurf = {
		Health = 300, WalkSpeed = 18, FireInterval = 1.1, HitChance = 0.26, Damage = 8, Range = 220,
		Reaction = 0.3, Strafe = true, Jumps = true, UsesCover = true, Credits = 65, Gun = "Rifle",
		Colors = { Head = rgb(245, 205, 48), Torso = rgb(13, 105, 172), Arms = rgb(245, 205, 48), Legs = rgb(75, 151, 75) },
	},
	-- Very fast and always jumping, but rushes its shots
	Speedrunner = {
		Health = 120, WalkSpeed = 22, FireInterval = 1.4, HitChance = 0.16, Damage = 5, Range = 160,
		Reaction = 0.55, Strafe = true, Jumps = true, Credits = 7, Gun = "SMG", Skin = "Tiger",
		Colors = { Torso = rgb(255, 140, 20), Legs = rgb(32, 34, 44) },
	},
	-- Weak and sprays everywhere, but hard to pin down
	ScriptKiddie = {
		Health = 80, WalkSpeed = 14, FireInterval = 0.9, HitChance = 0.1, Damage = 4, Range = 140,
		Reaction = 0.75, Strafe = true, Jumps = true, Credits = 3, Gun = "Pistol", Skin = "Toxic",
		Colors = { Torso = rgb(46, 48, 58), Arms = rgb(46, 48, 58), Legs = rgb(60, 72, 104) },
	},
	-- Anti-cheat field agent. Its hits jam your hacks, like a Moderator's.
	Enforcer = {
		Health = 280, WalkSpeed = 15, FireInterval = 1.3, HitChance = 0.3, Damage = 7, Range = 210,
		Reaction = 0.45, Strafe = true, UsesCover = true, Jams = 3, Credits = 90, Tag = "AC", Gun = "Rifle", Skin = "Ocean",
		Colors = { Torso = rgb(30, 36, 48), Arms = rgb(30, 36, 48), Legs = rgb(24, 28, 36) },
	},

	-- Bosses -----------------------------------------------------------------

	-- Sees you through walls (great aim) and teleports around to flank
	WallhackWendy = {
		Boss = true, Name = "Wallhack_Wendy", Health = 1800, WalkSpeed = 16, FireInterval = 1.2, HitChance = 0.5,
		Damage = 8, Range = 280, Reaction = 0.2, Strafe = true, Scale = 1.15, TeleportEvery = 8, Credits = 350,
		Gun = "Sniper", Skin = "Midnight",
		Colors = { Torso = rgb(110, 50, 200), Arms = rgb(110, 50, 200), Legs = rgb(36, 30, 52) },
	},
	-- A huge, slow tank with a ton of health
	GodModeGary = {
		Boss = true, Name = "GodMode_Gary", Health = 8000, WalkSpeed = 8, FireInterval = 1, HitChance = 0.35,
		Damage = 10, Range = 240, Reaction = 0.4, Scale = 1.4, Credits = 2500, Gun = "Minigun", Skin = "Gold",
		Colors = { Torso = rgb(250, 246, 235), Arms = rgb(250, 246, 235), Legs = rgb(235, 225, 200) },
	},
	-- Teleports behind you every few seconds
	TPTyler = {
		Boss = true, Name = "TP_Tyler", Health = 2800, WalkSpeed = 18, FireInterval = 0.9, HitChance = 0.4,
		Damage = 7, Range = 220, Reaction = 0.25, Strafe = true, Jumps = true, Scale = 1.15,
		TeleportEvery = 4, -- seconds (RAGE_H4X0R waits 9)
		Credits = 700, Gun = "Shotgun", Skin = "Galaxy",
		Colors = { Torso = rgb(26, 28, 40), Arms = rgb(26, 28, 40), Legs = rgb(20, 22, 30) },
	},
}

-- One extra wave per rank, played after the rank's own waves. Each group is
-- { bot type, how many }.
local ArenaWaves = {
	Bronze = { { { "ScriptKiddie", 3 } } },
	Silver = { { { "Speedrunner", 3 }, { "ScriptKiddie", 2 } } },
	Gold = { { { "WallhackWendy", 1 }, { "Camper", 1 }, { "Streamer", 2 } } },
	Diamond = { { { "TPTyler", 1 }, { "Smurf", 2 }, { "Enforcer", 1 } } },
	Champion = { { { "GodModeGary", 1 }, { "Enforcer", 3 } } },
}

return { Types = Types, ArenaWaves = ArenaWaves }
