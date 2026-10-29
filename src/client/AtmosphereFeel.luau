-- Extra polish on top of Atmosphere's lighting fades. Gives every place sun
-- rays, bloom size and glow threshold, exposure and haze glare that suit it
-- (worked out from its Config.Themes colors, or set in LOOKS below), adds a
-- soft depth of field on the League HQ Concourse only, and turns the switch
-- between the lobby and a round into a quick dip to dark and back instead of
-- a slow cross-fade. Walking between lobby zones (the Concourse, The Tunnel,
-- the Trophy Hall) stays a smooth fade with no dip.
--
-- The lobby's base lighting (ClockTime, colors, bloom) comes from
-- Config.Themes.Lobby / LobbyTunnel / LobbyTrophy, as STYLE.md 5.7 sets them.
-- Until Config has those (an older Config without LobbyTunnel), LEAGUE_HQ
-- below stands in with the same STYLE 5.7 values.
-- Atmosphere.luau calls AtmosphereFeel.prepare() and AtmosphereFeel.apply().
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local AtmosphereFeel = {}

local rgb = Color3.fromRGB

local SLOW = TweenInfo.new(1.2, Enum.EasingStyle.Sine) -- same as Atmosphere's fade
local QUICK = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) -- lobby <-> round
local DIP = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- STYLE.md 5.7, for an older Config.Themes that still has the warm sunset
-- lobby. Only used while Config.Themes has no LobbyTunnel; once it does,
-- Config is the one place these live.
local LEAGUE_HQ = {
	Lobby = { -- League HQ day: cool, crisp, bright hall
		ClockTime = 14.2, Brightness = 2.6, Ambient = rgb(118, 122, 134), OutdoorAmbient = rgb(150, 156, 170),
		Atmosphere = { Density = 0.26, Haze = 0.8, Color = rgb(214, 224, 240), Decay = rgb(120, 134, 168) },
		Tint = rgb(246, 248, 255), Contrast = 0.12, Saturation = 0.1, Bloom = 0.3,
	},
}

-- Extras laid over each theme (each is worked out from the theme when left out):
--   BloomSize, BloomThreshold  how wide the glow is, and how bright a thing must be to glow
--   SunRays                    sun ray strength (0 = none)
--   Exposure                   Lighting.ExposureCompensation (+ brightens dark maps)
--   Glare                      Atmosphere.Glare, the sun's halo in the haze
--   DepthOfField               { Far, Focus, Radius }: soft background blur (lobby only)
-- Any theme field (ClockTime, Bloom, ...) can be changed here too, but the
-- lobby ones belong in Config.Themes (STYLE 5.7).
AtmosphereFeel.LOOKS = {
	-- The Concourse. Bloom size, threshold and sun rays are STYLE's (5.1
	-- Lighting row). The blur is sharp out to about 115 studs, so the
	-- FINAL BOSS gate down the lane stays crisp from spawn; only the far
	-- skyline softens.
	Lobby = {
		BloomSize = 24, BloomThreshold = 1.7, SunRays = 0.04, Exposure = 0, Glare = 0.15,
		DepthOfField = { Far = 0.12, Focus = 60, Radius = 55 },
	},
	-- The Tunnel and the mode halls: indoors and dark, so no sun rays or
	-- glare; the pads must read, so no blur
	LobbyTunnel = { BloomSize = 24, BloomThreshold = 1.7, SunRays = 0, Exposure = 0, Glare = 0 },
	-- The Trophy Hall: a warm room, a little brass glow
	LobbyTrophy = { BloomSize = 24, BloomThreshold = 1.6, SunRays = 0.02, Exposure = 0, Glare = 0.05 },
	Day = { SunRays = 0.09, Glare = 0.3 },
	Warehouse = { SunRays = 0.12, BloomSize = 28, BloomThreshold = 1.3, Exposure = 0.1 },
	Night = { Exposure = 0.2, BloomSize = 30, BloomThreshold = 1.1, SunRays = 0 },
	ServerRoom = { Exposure = 0.25, BloomSize = 32, BloomThreshold = 1 },
	Mainframe = { Exposure = 0.2, BloomSize = 32, BloomThreshold = 1 },
	Duel = { Exposure = 0.15, BloomSize = 30, BloomThreshold = 1.05 },
	Fog = { SunRays = 0.02, BloomSize = 40, BloomThreshold = 1.4, Glare = 0 },
	-- Fullbright is a hack for seeing clearly, so nothing extra
	Fullbright = { SunRays = 0, Exposure = 0, Glare = 0, BloomSize = 24, BloomThreshold = 2 },
}

-- How many lobby <-> round dips have played (the tests read it)
AtmosphereFeel.dips = 0

local merged = {} -- [name] = theme with its look laid over
local first = true
local current = nil

-- Lobby, LobbyTunnel, LobbyTrophy, ...: every League HQ zone counts as the lobby
local function isLobby(name)
	return type(name) == "string" and string.sub(name, 1, 5) == "Lobby"
end
AtmosphereFeel.isLobby = isLobby

-- The extras a theme doesn't set, from how bright it is
local function fillExtras(look)
	local dark = look.Brightness < 1.3 or look.ClockTime < 6.5 or look.ClockTime > 18
	local function default(key, darkValue, brightValue)
		if look[key] == nil then
			look[key] = if dark then darkValue else brightValue
		end
	end
	default("BloomSize", 30, 22)
	default("BloomThreshold", 1.1, 1.6)
	default("SunRays", 0.01, 0.07)
	default("Exposure", 0.15, 0)
	default("Glare", 0, 0.2)
end

-- The theme Atmosphere should use for `name`: Config's theme (or STYLE 5.7's,
-- on an older Config) with LOOKS on top
local function lookFor(name, theme)
	local look = merged[name]
	if look then
		return look
	end
	look = table.clone(theme)
	local style = LEAGUE_HQ[name]
	if style and Config.Themes.LobbyTunnel == nil then
		for key, value in style do
			look[key] = value
		end
	end
	for key, value in AtmosphereFeel.LOOKS[name] or {} do
		look[key] = value
	end
	fillExtras(look)
	merged[name] = look
	return look
end

local function effect(name)
	return Lighting:FindFirstChild(name)
end

-- Ours: the lobby blur and the dip between lobby and round
local function ownEffect(className, name)
	local made = Lighting:FindFirstChild(name)
	if not made then
		made = Instance.new(className)
		made.Name = name
		made.Parent = Lighting
	end
	return made
end

-- Sets (info = nil) or tweens every property in `goals` on `instance`
local function change(instance, info, goals)
	if not instance then
		return
	end
	if info then
		TweenService:Create(instance, info, goals):Play()
	else
		for key, value in goals do
			instance[key] = value
		end
	end
end

-- The same values Atmosphere fades, so a join can start on them and a
-- lobby <-> round switch can land on them faster
local function setBase(look, info)
	change(Lighting, info, {
		ClockTime = look.ClockTime,
		Brightness = look.Brightness,
		Ambient = look.Ambient,
		OutdoorAmbient = look.OutdoorAmbient,
	})
	change(effect("Atmosphere"), info, {
		Density = look.Atmosphere.Density,
		Haze = look.Atmosphere.Haze,
		Color = look.Atmosphere.Color,
		Decay = look.Atmosphere.Decay,
	})
	change(effect("ColorCorrection"), info, { TintColor = look.Tint, Contrast = look.Contrast, Saturation = look.Saturation })
	change(effect("Bloom"), info, { Intensity = look.Bloom })
end

local function setExtras(name, look, info)
	change(Lighting, info, { ExposureCompensation = look.Exposure })
	change(effect("Bloom"), info, { Size = look.BloomSize, Threshold = look.BloomThreshold })
	change(effect("SunRays"), info, { Intensity = look.SunRays, Spread = 0.6 })
	change(effect("Atmosphere"), info, { Glare = look.Glare })

	-- Soft background blur in the lobby only. Walking to a lobby zone without
	-- it fades it out; in rounds it's switched off so it can't blur enemies
	-- (and costs nothing there).
	local depth = ownEffect("DepthOfFieldEffect", "FeelLobbyDepth")
	local blur = isLobby(name) and look.DepthOfField
	if blur then
		depth.Enabled = true
		depth.NearIntensity = 0
		depth.FocusDistance = blur.Focus
		depth.InFocusRadius = blur.Radius
		change(depth, info, { FarIntensity = blur.Far })
	elseif isLobby(name) and info then
		change(depth, info, { FarIntensity = 0 })
	else
		depth.FarIntensity = 0
		depth.Enabled = false
	end
end

-- Called by Atmosphere right after it picks a theme. Returns the theme to
-- use (with LOOKS laid over). The very first time, the lighting jumps
-- straight there, so joining doesn't start with a fade.
function AtmosphereFeel.prepare(name, theme)
	local look = lookFor(name, theme)
	if first then
		first = false
		setBase(look, nil)
		setExtras(name, look, nil)
		current = name
	end
	return look
end

-- Called by Atmosphere after its own fades have started (and before any
-- modifier, like Rain, tweens the same lighting, so the modifier wins)
function AtmosphereFeel.apply(name, look)
	local previous = current
	current = name
	if previous == nil or previous == name then
		return
	end
	local switching = isLobby(previous) ~= isLobby(name) and previous ~= "Fullbright" and name ~= "Fullbright"
	if switching then
		-- A quick dip to dark hides the jump between places, and the new
		-- lighting lands while it comes back
		AtmosphereFeel.dips += 1
		local dip = ownEffect("ColorCorrectionEffect", "FeelTransition")
		dip.Brightness = -0.45
		dip.Saturation = -0.3
		dip.Contrast = 0.1
		change(dip, DIP, { Brightness = 0, Saturation = 0, Contrast = 0 })
		setBase(look, QUICK)
		setExtras(name, look, QUICK)
	else
		-- Lobby zone to lobby zone, round to round, Fullbright: Atmosphere's
		-- slow fade, and the extras fade along with it
		setExtras(name, look, SLOW)
	end
end

return AtmosphereFeel
