--[[
	MapLighting: the look of each map. The server applies the oval's afternoon when the game starts;
	each client then applies the preset of the map its player is on (a map's data names it), so a
	player in the city sees night while a player on the oval keeps the afternoon. Lighting changes
	made by a client affect only that client.

	Lighting.Technology can't be set by scripts: set it to Future in Studio for the intended look.
]]

local Lighting = game:GetService("Lighting")

local MapLighting = {}

MapLighting.presets = {
	-- the proving ground's late afternoon
	Afternoon = {
		clockTime = 16.4,
		brightness = 3,
		latitude = 38,
		ambient = Color3.fromRGB(40, 40, 44),
		outdoorAmbient = Color3.fromRGB(128, 128, 128),
		exposure = 0,
		diffuse = 1,
		specular = 1,
		shadowSoftness = 0.15,
		atmosphere = { density = 0.28, offset = 0.2, color = Color3.fromRGB(205, 186, 160), decay = Color3.fromRGB(110, 115, 128), glare = 0.35, haze = 1.4 },
		bloom = { intensity = 0.3, size = 28, threshold = 1.5 },
		grade = { brightness = 0, contrast = 0.06, saturation = 0.06, tint = Color3.fromRGB(255, 255, 255) },
		sunRays = { intensity = 0.04, spread = 0.55 },
	},
	-- the city at night: dark blue sky, a hazy horizon, strong bloom on lamps, signs and windows
	Night = {
		clockTime = 22.6,
		brightness = 1.2,
		latitude = 35,
		ambient = Color3.fromRGB(22, 24, 34),
		outdoorAmbient = Color3.fromRGB(64, 70, 96),
		exposure = 0.35,
		diffuse = 0.35,
		specular = 1,
		shadowSoftness = 0.3,
		atmosphere = { density = 0.34, offset = 0.05, color = Color3.fromRGB(54, 62, 86), decay = Color3.fromRGB(24, 26, 40), glare = 0, haze = 1.8 },
		bloom = { intensity = 0.9, size = 34, threshold = 0.85 },
		grade = { brightness = 0.02, contrast = 0.12, saturation = 0.08, tint = Color3.fromRGB(232, 236, 255) },
		sunRays = { intensity = 0, spread = 0.55 },
	},
}

local function ensure(className: string): Instance
	local object = Lighting:FindFirstChildOfClass(className)
	if object == nil then
		object = Instance.new(className)
		object.Parent = Lighting
	end
	return object
end

-- Apply a preset by name (unknown names fall back to the afternoon).
function MapLighting.apply(name: string?)
	local p = MapLighting.presets[name or "Afternoon"] or MapLighting.presets.Afternoon
	Lighting.ClockTime = p.clockTime
	Lighting.Brightness = p.brightness
	Lighting.GeographicLatitude = p.latitude
	Lighting.Ambient = p.ambient
	Lighting.OutdoorAmbient = p.outdoorAmbient
	Lighting.ExposureCompensation = p.exposure
	Lighting.EnvironmentDiffuseScale = p.diffuse
	Lighting.EnvironmentSpecularScale = p.specular
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = p.shadowSoftness

	local atmosphere = ensure("Atmosphere") :: Atmosphere
	atmosphere.Density = p.atmosphere.density
	atmosphere.Offset = p.atmosphere.offset
	atmosphere.Color = p.atmosphere.color
	atmosphere.Decay = p.atmosphere.decay
	atmosphere.Glare = p.atmosphere.glare
	atmosphere.Haze = p.atmosphere.haze

	local bloom = ensure("BloomEffect") :: BloomEffect
	bloom.Intensity = p.bloom.intensity
	bloom.Size = p.bloom.size
	bloom.Threshold = p.bloom.threshold

	local grade = ensure("ColorCorrectionEffect") :: ColorCorrectionEffect
	grade.Brightness = p.grade.brightness
	grade.Contrast = p.grade.contrast
	grade.Saturation = p.grade.saturation
	grade.TintColor = p.grade.tint

	local sunRays = ensure("SunRaysEffect") :: SunRaysEffect
	sunRays.Intensity = p.sunRays.intensity
	sunRays.Spread = p.sunRays.spread
end

return MapLighting
