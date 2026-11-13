--[[
	TrafficMix: the maths of traffic sound heard from outside. Pure functions with no Roblox objects
	(apart from Vector3), used by Client/TrafficAudio and copied line for line in
	tools/audio_preview.py, which renders a roadside drive-by. Keep the two in step.

	Roblox spatializes each traffic Sound itself (direction, and distance with RollOffMode
	InverseTapered between ROLLOFF_MIN_M and ROLLOFF_MAX_M). On top of that:
	  * engine speed and load come from the car's road speed and acceleration through a simple
	    automatic gearbox, so a car pulling away revs and a cruising car hums;
	  * Doppler: pitch times (c + listener speed toward the source) / (c - source speed toward the
	    listener);
	  * air absorption: the equaliser's mid and high bands lose level with distance.
]]

local TrafficMix = {}

TrafficMix.SPEED_OF_SOUND = 343 -- m/s, air at 20 C
TrafficMix.ROLLOFF_MIN_M = 6 -- full volume within this distance
TrafficMix.ROLLOFF_MAX_M = 450 -- silent beyond it
TrafficMix.ENGINE_VOLUME = 1.6 -- Sound volume of a traffic engine at full load, within ROLLOFF_MIN_M
TrafficMix.TYRE_VOLUME = 0.9 -- tyre roar at 110 km/h

-- [E] Generic automatic gearboxes, only for the engine note (traffic moves without physics).
TrafficMix.PROFILES = {
	car = {
		wheelRadius = 0.32,
		gears = { 3.6, 2.1, 1.4, 1.0, 0.8, 0.66 },
		finalDrive = 3.9,
		idleRpm = 800,
		maxRpm = 6000,
		cruiseRpm = 1700, -- the gearbox keeps the engine at least this fast at light load
		pullRpm = 3800, -- and this fast at full load
	},
	truck = {
		wheelRadius = 0.52,
		gears = { 9.5, 6.6, 4.7, 3.4, 2.4, 1.7, 1.3, 1.0 },
		finalDrive = 3.4,
		idleRpm = 600,
		maxRpm = 2100,
		cruiseRpm = 1150,
		pullRpm = 1700,
	},
}

-- Engine speed for a road speed (m/s) and load (0-1): the highest gear that keeps the engine at or
-- above a target speed that rises with load. Returns rpm and gear.
function TrafficMix.engineRpm(profile, speed: number, load: number): (number, number)
	local wheelRpm = math.max(speed, 0) / (2 * math.pi * profile.wheelRadius) * 60
	local want = profile.cruiseRpm + (profile.pullRpm - profile.cruiseRpm) * load
	local gears = profile.gears
	local chosen = 1
	for g = #gears, 1, -1 do
		if wheelRpm * gears[g] * profile.finalDrive >= want then
			chosen = g
			break
		end
	end
	local rpm = wheelRpm * gears[chosen] * profile.finalDrive
	return math.clamp(rpm, profile.idleRpm, profile.maxRpm), chosen
end

-- Load (0-1) from the car's smoothed acceleration (m/s^2): cruising needs some, pulling away more.
function TrafficMix.load(accel: number): number
	return math.clamp(0.3 + accel / 2.0, 0, 1)
end

-- Engine and tyre volumes (before distance) for a road speed, load and engine speed.
function TrafficMix.levels(profile, speed: number, load: number, rpm: number): (number, number)
	local engine = TrafficMix.ENGINE_VOLUME * (0.35 + 0.65 * load) * math.clamp(rpm / profile.pullRpm, 0.2, 1.5) ^ 0.7
	local tyre = TrafficMix.TYRE_VOLUME * math.clamp(speed / 30.5, 0, 1.4) ^ 1.6
	return engine, tyre
end

-- Doppler pitch factor. offset: source position minus listener position (m); velocities in m/s.
function TrafficMix.doppler(offset: Vector3, sourceVel: Vector3, listenerVel: Vector3): number
	local distance = offset.Magnitude
	if distance < 0.01 then
		return 1
	end
	local toListener = -offset / distance
	local c = TrafficMix.SPEED_OF_SOUND
	local approach = math.clamp(sourceVel:Dot(toListener), -0.5 * c, 0.5 * c) -- source moving toward the listener
	local meet = math.clamp(-listenerVel:Dot(toListener), -0.5 * c, 0.5 * c) -- listener moving toward the source
	return math.clamp((c + meet) / (c - approach), 0.5, 2)
end

-- [E] Treble lost to the air (dB for the equaliser's mid and high bands) over a distance in metres.
-- ISO 9613-1 gives roughly 5 dB/km at 1 kHz and 20-80 dB/km at 4-8 kHz (20 C, 70% humidity); these
-- are stronger so that distance reads clearly in a game.
function TrafficMix.airAbsorption(distanceM: number): (number, number)
	return -math.min(distanceM * 0.012, 8), -math.min(distanceM * 0.06, 30)
end

-- Roblox's InverseTapered roll-off (the lesser of inverse and linear-squared). The game doesn't
-- call this (Roblox applies it); the preview does.
function TrafficMix.rollOff(distanceM: number): number
	local near, far = TrafficMix.ROLLOFF_MIN_M, TrafficMix.ROLLOFF_MAX_M
	if distanceM <= near then
		return 1
	end
	if distanceM >= far then
		return 0
	end
	local linear = (far - distanceM) / (far - near)
	return math.min(near / distanceM, linear * linear)
end

return TrafficMix
