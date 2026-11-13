--[[
	TrafficAudio: positional engine and tyre sound for the nearest traffic cars.
	(Work in progress: this placeholder only defines the interface Main.client uses.)
]]

local TrafficAudio = {}

-- renderer: the TrafficRenderer module (its cars() returns id -> { s, lanePos, v, profileIndex, body }).
function TrafficAudio.init(renderer)
	TrafficAudio.renderer = renderer
end

return TrafficAudio
