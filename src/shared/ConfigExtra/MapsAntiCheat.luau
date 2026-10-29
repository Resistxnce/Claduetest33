-- Lighting themes and map pool entries for the anti-cheat maps
-- (src/server/Maps/AntiCheat.luau). ConfigExtra.apply adds them to
-- Config.Themes and Config.MapPool, skipping any that are already there.
local rgb = Color3.fromRGB

return {
	Themes = {
		-- Bright, cool office light: white walls, blue glass, red alarms
		AntiCheatHQ = {
			ClockTime = 14, Brightness = 2.4, Ambient = rgb(150, 160, 182), OutdoorAmbient = rgb(160, 172, 196),
			Atmosphere = { Density = 0.18, Haze = 0.6, Color = rgb(220, 232, 248), Decay = rgb(150, 166, 196) },
			Tint = rgb(240, 246, 255), Contrast = 0.08, Saturation = 0.06, Bloom = 0.5,
		},
		-- Warm, dim courtroom: dark wood, candle light and a red glow
		BanCourt = {
			ClockTime = 17.6, Brightness = 1.2, Ambient = rgb(134, 100, 76), OutdoorAmbient = rgb(120, 90, 68),
			Atmosphere = { Density = 0.36, Haze = 1.6, Color = rgb(170, 122, 84), Decay = rgb(92, 56, 36) },
			Tint = rgb(255, 236, 214), Contrast = 0.16, Saturation = 0.06, Bloom = 0.8,
		},
	},
	MapPool = { "AntiCheatHQ", "BanCourt" },
}
