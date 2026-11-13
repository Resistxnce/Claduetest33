--[[
	SelfTest: a quick health check of the car, printed to the Output window a few seconds after it
	spawns. It runs while the car sits parked, and compares the simulation with the numbers it should
	settle at (docs/TEST_CHECKLIST_PHASE1.md, M2). When reporting a problem, paste the block it prints.
	It runs again after every respawn (R).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local Units = require(VehicleSystem:WaitForChild("Units"))
local VehicleSimulation = require(VehicleSystem:WaitForChild("CorePhysics"):WaitForChild("VehicleSimulation"))

local InputController = require(script.Parent:WaitForChild("InputController"))

local SETTLE_SECONDS = 4

local SelfTest = {}

local function thousands(x: number): string
	local s = tostring(math.floor(math.abs(x) + 0.5))
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return (if x < 0 then "-" else "") .. out
end

function SelfTest.run(controller)
	task.spawn(function()
		local frames, elapsed, slowest, driven = 0, 0, 0, false
		local connection = RunService.Heartbeat:Connect(function(dt)
			frames += 1
			elapsed += dt
			slowest = math.max(slowest, dt)
			local s = InputController.state
			if s.throttle > 0.05 or s.brake > 0.05 or math.abs(s.steer) > 0.05 or s.handbrake > 0 then
				driven = true
			end
		end)
		task.wait(SETTLE_SECONDS)
		connection:Disconnect()
		if controller.stopped then
			return
		end

		local sim = controller.sim
		local config = controller.config
		local root: BasePart = controller.root
		local lines = {}
		local passed, total = 0, 0
		local function check(ok: boolean, text: string)
			total += 1
			if ok then
				passed += 1
			end
			table.insert(lines, (if ok then "  ok    " else "  FAIL  ") .. text)
		end
		local function info(text: string)
			table.insert(lines, "  info  " .. text)
		end

		local fps = frames / math.max(elapsed, 1e-3)
		check(sim.telemetry.rpm ~= nil and fps > 30, string.format(
			"simulation running at %d fps on average (slowest frame %d ms)", math.floor(fps + 0.5),
			math.floor(slowest * 1000 + 0.5)))

		local gravity = Workspace.Gravity
		check(math.abs(gravity - Units.REALISTIC_GRAVITY) < 0.1, string.format(
			"gravity %.2f studs/s^2 (expected %.2f, which is 9.81 m/s^2)", gravity, Units.REALISTIC_GRAVITY))

		local massKg = root.AssemblyMass * Units.KG_PER_RMU
		local expectedKg = config.mass.kerbKg + config.mass.driverKg
		check(math.abs(massKg - expectedKg) < expectedKg * 0.02, string.format(
			"car mass %s kg (expected %s; much more means the driver's body isn't massless)",
			thousands(massKg), thousands(expectedKg)))

		if driven then
			info("the car was driven during the test, so the parked checks were skipped; press R to rerun")
		else
			local touching, loads, travel = 0, {}, {}
			local loadsOk, travelOk = true, true
			local expectedFront, expectedRear = 0, 0
			for _, id in VehicleSimulation.WHEEL_IDS do
				local w = sim.wheels[id]
				if w.contact then
					touching += 1
				end
				if w.front then
					expectedFront = w.staticLoad
				else
					expectedRear = w.staticLoad
				end
				if math.abs(w.load - w.staticLoad) > w.staticLoad * 0.12 then
					loadsOk = false
				end
				local mm = (w.suspension.rideLength - w.length) * 1000
				if math.abs(mm) > 20 then
					travelOk = false
				end
				table.insert(loads, id .. " " .. thousands(w.load))
				table.insert(travel, string.format("%s %+d", id, math.floor(mm + 0.5)))
			end
			check(touching == 4, string.format("wheels on the road: %d of 4", touching))
			check(loadsOk, string.format("wheel loads (N): %s (expected about %s front, %s rear)",
				table.concat(loads, "  "), thousands(expectedFront), thousands(expectedRear)))
			check(travelOk, "suspension compression from ride height (mm): " .. table.concat(travel, "  "))

			local creep = root.AssemblyLinearVelocity.Magnitude * Units.METERS_PER_STUD
			check(creep < 0.15, string.format("parked still: moving at %.2f m/s", creep))

			local cf = root.CFrame
			local pitch = math.deg(math.asin(math.clamp(cf.LookVector.Y, -1, 1)))
			local roll = math.deg(math.asin(math.clamp(cf.RightVector.Y, -1, 1)))
			check(math.abs(pitch) < 1 and math.abs(roll) < 1, string.format(
				"body level: pitch %.2f deg, roll %.2f deg", pitch, roll))

			local rpm = sim.telemetry.rpm or 0
			check(math.abs(rpm - config.engine.idleRpm) < 200, string.format(
				"idling at %s rpm (target %s)", thousands(rpm), thousands(config.engine.idleRpm)))
		end

		print(string.format("[Redline] Self-test, %d s after the car spawned:\n%s\n[Redline] Self-test: %d of %d passed."
			.. " Paste this block when you report a problem.", SETTLE_SECONDS, table.concat(lines, "\n"), passed, total))
	end)
end

return SelfTest
