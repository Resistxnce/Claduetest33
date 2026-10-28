-- Lighting themes and map pool ids for the studio maps (Dev Studio and
-- Classic Place, built in src/server/Maps/Studio.luau). ConfigExtra.apply
-- adds the themes to Config.Themes and the ids to Config.MapPool. Each theme
-- has the same fields as the ones in Config.Themes.
local rgb = Color3.fromRGB

return {
	Themes = {
		-- Bright, warm office light: high ambient so the room reads clean and
		-- friendly under the ceiling panels
		DevStudio = {
			ClockTime = 13, Brightness = 2.2, Ambient = rgb(150, 144, 150), OutdoorAmbient = rgb(160, 156, 162),
			Atmosphere = { Density = 0.2, Haze = 0.6, Color = rgb(240, 232, 236), Decay = rgb(190, 172, 186) },
			Tint = rgb(255, 249, 244), Contrast = 0.08, Saturation = 0.1, Bloom = 0.4,
		},
		-- Old-school noon: flat bright light, a clear blue sky and punchy colors
		ClassicPlace = {
			ClockTime = 14.2, Brightness = 3, Ambient = rgb(128, 128, 136), OutdoorAmbient = rgb(140, 140, 150),
			Atmosphere = { Density = 0.16, Haze = 0.3, Color = rgb(200, 222, 248), Decay = rgb(120, 156, 210) },
			Tint = rgb(255, 255, 250), Contrast = 0.06, Saturation = 0.2, Bloom = 0.2,
		},
	},
	MapPool = { "DevStudio", "ClassicPlace" },
}
