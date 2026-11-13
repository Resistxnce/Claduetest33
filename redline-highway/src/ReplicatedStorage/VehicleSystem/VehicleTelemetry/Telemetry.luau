--[[
	Telemetry
	Shares the latest simulation numbers with the HUD, and times standard performance runs so
	they can be compared with the factory figures:
	  0-100 and 0-200 km/h: start from a standstill and accelerate; timing starts when the car moves.
	  100-0 km/h braking: brake fully from above 100 km/h and hold the pedal until stopped.
	  Top speed: the highest speed reached since the car spawned.
]]

local Telemetry = {}

Telemetry.sim = nil -- the active VehicleSimulation
Telemetry.frame = {} -- extra per-frame values from the controller (G-forces, fps)
Telemetry.results = { zeroTo100 = nil, zeroTo200 = nil, brake100 = nil, topSpeed = 0 }

local run = { armed = false, start = nil, reached100 = false, brakeStart = nil, previousKmh = 0 }

function Telemetry.reset()
	Telemetry.results = { zeroTo100 = nil, zeroTo200 = nil, brake100 = nil, topSpeed = 0 }
	run = { armed = false, start = nil, reached100 = false, brakeStart = nil, previousKmh = 0 }
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
		run.reached100 = false
	elseif run.armed then
		run.start = run.start or now
		if brake > 0.5 then
			run.armed = false -- braking ends an acceleration run
		elseif speedKmh >= 100 and not run.reached100 then
			results.zeroTo100 = now - run.start
			run.reached100 = true
		elseif speedKmh >= 200 then
			results.zeroTo200 = now - run.start
			run.armed = false
		end
	end

	if brake > 0.9 and speedKmh <= 100 and run.previousKmh > 100 then
		run.brakeStart = position
	elseif brake < 0.5 then
		run.brakeStart = nil -- the pedal was released, so the stop doesn't count
	end
	run.previousKmh = speedKmh
end

return Telemetry
