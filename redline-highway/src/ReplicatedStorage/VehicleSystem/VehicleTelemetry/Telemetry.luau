--[[
	Telemetry
	Shares the latest simulation numbers with the HUD, and times standard performance runs so
	they can be compared with the factory figures (the car's performanceTargets):
	  0-60 mph, 0-100 and 0-200 km/h, and the quarter mile (time and speed at the line): start from a
	  standstill and accelerate; timing starts when the car moves (no rollout), and braking ends the run.
	  100-0 km/h braking: brake fully from above 100 km/h and hold the pedal until stopped.
	  Top speed: the highest speed reached since the car spawned.
]]

local Telemetry = {}

local QUARTER_MILE = 402.336 -- m
local SPEED_MARKS = { zeroTo60Mph = 96.56064, zeroTo100 = 100, zeroTo200 = 200 } -- km/h

Telemetry.sim = nil -- the active VehicleSimulation
Telemetry.frame = {} -- extra per-frame values from the controller (G-forces, fps)
Telemetry.results = { zeroTo100 = nil, zeroTo200 = nil, zeroTo60Mph = nil, quarterMile = nil, quarterMileKmh = nil, brake100 = nil, topSpeed = 0 }

local function newRun()
	return { armed = false, start = nil, distance = 0, lastPosition = nil, done = {}, brakeStart = nil, previousKmh = 0 }
end

local run = newRun()

function Telemetry.reset()
	Telemetry.results = { zeroTo100 = nil, zeroTo200 = nil, zeroTo60Mph = nil, quarterMile = nil, quarterMileKmh = nil, brake100 = nil, topSpeed = 0 }
	run = newRun()
end

-- now: seconds; speedKmh: car speed; brake: brake pedal 0-1; position: Vector3 in metres
function Telemetry.updateTimers(now: number, speedKmh: number, brake: number, position: Vector3)
	local results = Telemetry.results
	results.topSpeed = math.max(results.topSpeed, speedKmh)

	if speedKmh < 0.5 then
		if run.brakeStart then
			results.brake100 = (position - run.brakeStart).Magnitude
			run.brakeStart = nil
		end
		run.armed = true
		run.start = nil
		run.distance = 0
		run.done = {}
	elseif run.armed then
		run.start = run.start or now
		if run.lastPosition then
			run.distance += (position - run.lastPosition).Magnitude
		end
		if brake > 0.5 then
			run.armed = false -- braking ends an acceleration run
		else
			local elapsed = now - run.start
			local finished = true
			for key, kmh in SPEED_MARKS do
				if not run.done[key] and speedKmh >= kmh then
					results[key] = elapsed
					run.done[key] = true
				end
				finished = finished and run.done[key] == true
			end
			if not run.done.quarterMile and run.distance >= QUARTER_MILE then
				results.quarterMile = elapsed
				results.quarterMileKmh = speedKmh
				run.done.quarterMile = true
			end
			if finished and run.done.quarterMile then
				run.armed = false
			end
		end
	end
	run.lastPosition = position

	if brake > 0.9 and speedKmh <= 100 and run.previousKmh > 100 then
		run.brakeStart = position
	elseif brake < 0.5 then
		run.brakeStart = nil -- the pedal was released, so the stop doesn't count
	end
	run.previousKmh = speedKmh
end

return Telemetry
