--[[
	Roblox asset IDs of the sound packs in assets/audio. Upload each file once (Creator Hub or
	Studio's Asset Manager, see docs/AUDIO.md), then paste its ID here, for example:
		GT12_Engine = "rbxassetid://1234567890",
	Several cars can share one pack (assets/audio/packs.json lists which); each car's sheet table
	names its pack. Leave a pack as "" to play without it. The game prints a reminder in the Output
	window while an ID is missing.
]]

return {
	GT12_Engine = "", -- the GT12's engine
	Driving_Effects = "", -- tyres, wind, road, gearbox, crackles, shifts, knocks, and traffic engines
	Engines_Pack1 = "", -- the next cars' engines (see assets/audio/packs.json)
}
