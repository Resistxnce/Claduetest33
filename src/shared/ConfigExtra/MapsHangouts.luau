-- Lighting themes and map pool spots for the hangout maps (Gamer Bedroom and
-- Streamer House, laid out in src/server/Maps/Hangouts.luau). ConfigExtra
-- adds them to Config.Themes and Config.MapPool.
local rgb = Color3.fromRGB

return {
	Themes = {
		-- Gamer Bedroom: a sunny afternoon coming in through the window
		Bedroom = {
			ClockTime = 14.5, Brightness = 2.4, Ambient = rgb(128, 120, 140), OutdoorAmbient = rgb(150, 142, 162),
			Atmosphere = { Density = 0.12, Haze = 0.4, Color = rgb(225, 214, 235), Decay = rgb(150, 130, 170) },
			Tint = rgb(255, 248, 242), Contrast = 0.08, Saturation = 0.15, Bloom = 0.5,
		},
		-- Streamer House: sunset outside, warm lamps and neon signs inside
		Mansion = {
			ClockTime = 18, Brightness = 1.8, Ambient = rgb(116, 96, 122), OutdoorAmbient = rgb(140, 112, 142),
			Atmosphere = { Density = 0.16, Haze = 1, Color = rgb(255, 184, 196), Decay = rgb(130, 80, 120) },
			Tint = rgb(255, 242, 246), Contrast = 0.12, Saturation = 0.18, Bloom = 0.8,
		},
	},
	MapPool = { "GamerBedroom", "StreamerHouse" },
}
