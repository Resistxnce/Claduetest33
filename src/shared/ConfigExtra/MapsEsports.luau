-- Lighting and map pool entries for the esports maps (Maps/Esports.luau).
-- ConfigExtra.apply adds each theme to Config.Themes and each map id to
-- Config.MapPool, skipping any that are already there.
local rgb = Color3.fromRGB

return {
	Themes = {
		-- A dark arena hall: the stage, screens and neon do most of the lighting
		Esports = {
			ClockTime = 0, Brightness = 1, Ambient = rgb(104, 86, 126), OutdoorAmbient = rgb(80, 66, 108),
			Atmosphere = { Density = 0.36, Haze = 1.8, Color = rgb(120, 70, 140), Decay = rgb(46, 24, 70) },
			Tint = rgb(255, 238, 248), Contrast = 0.16, Saturation = 0.15, Bloom = 1,
		},
		-- A cozy late-night gaming cafe, warmer and brighter than the arena
		LanCafe = {
			ClockTime = 0, Brightness = 1.2, Ambient = rgb(124, 104, 140), OutdoorAmbient = rgb(94, 78, 120),
			Atmosphere = { Density = 0.3, Haze = 1.4, Color = rgb(130, 90, 150), Decay = rgb(60, 30, 80) },
			Tint = rgb(255, 242, 236), Contrast = 0.12, Saturation = 0.12, Bloom = 0.9,
		},
	},
	MapPool = { "EsportsArena", "LanCafe" },
}
