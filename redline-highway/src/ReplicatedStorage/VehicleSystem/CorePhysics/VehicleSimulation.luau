--[[
	VehicleSimulation
	The shared car simulation, driven entirely by a vehicle configuration. It works in SI units and
	never touches Roblox instances, so the same code runs every car.

	Each frame the client's VehicleController:
	  1. calls updateSteering() to get the front wheel angles,
	  2. raycasts each suspension and measures contact patch velocities in each wheel's frame,
	  3. calls step() with those contacts and the driver's inputs,
	  4. applies the returned wheel and aero forces to the car.

	Inside step(), wheel spin, clutch and engine are integrated in SUBSTEPS smaller steps with the
	car's velocity held constant, and tyre forces are averaged over them. This keeps the stiff parts
	(tyres, clutch, torque converter, differentials) stable while Roblox integrates the car body once
	per frame.

	The configuration chooses the gearbox (dual-clutch or torque-converter automatic), the drive
	layout (front, rear, or all-wheel drive with a fixed split or an on-demand centre coupling) and
	the engine's forced induction. docs/VEHICLE_CONFIG.md describes every setting. An automatic
	starts in park (neutral with the brakes holding the car) and pulls into drive when the driver
	first presses a pedal.
]]

local Units = require(script.Parent.Parent.Units)
local Engine = require(script.Parent.Parent.EngineSimulation.Engine)
local Transmission = require(script.Parent.Parent.TransmissionSimulation.Transmission)
local Differential = require(script.Parent.Parent.DifferentialSystem.Differential)
local Suspension = require(script.Parent.Parent.SuspensionSystem.Suspension)
local Tire = require(script.Parent.Parent.TireSimulation.Tire)
local Aero = require(script.Parent.Parent.Aerodynamics.Aero)
local Brakes = require(script.Parent.Brakes)
local Steering = require(script.Parent.Steering)

local VehicleSimulation = {}
VehicleSimulation.__index = VehicleSimulation

local SUBSTEPS = 8
local MAX_DAMPER_SPEED = 5 -- m/s; caps damper spikes from kerbs and landings
local MAX_BUMP_STOP_COMPRESSION = 0.08 -- m past the bump stop that still counts
local TC_REFERENCE_SPEED = 6 -- m/s; traction control allows more wheel slip below this speed
local WHEEL_IDS = { "FL", "FR", "RL", "RR" }
VehicleSimulation.WHEEL_IDS = WHEEL_IDS

local function sign(x: number): number
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	end
	return 0
end

function VehicleSimulation.new(config)
	local self = setmetatable({}, VehicleSimulation)
	self.config = config

	local mass = config.mass
	local dims = config.dimensions
	self.massKg = mass.kerbKg + mass.driverKg
	local g = Units.GRAVITY
	local frontCornerLoad = self.massKg * g * mass.frontShare / 2
	local rearCornerLoad = self.massKg * g * (1 - mass.frontShare) / 2
	-- the centre of mass sits nearer the axle that carries more weight
	self.frontAxleZ = -dims.wheelbase * (1 - mass.frontShare)
	self.rearAxleZ = dims.wheelbase * mass.frontShare

	self.wheels = {}
	for _, id in WHEEL_IDS do
		local front = string.sub(id, 1, 1) == "F"
		local left = string.sub(id, 2, 2) == "L"
		local axle = if front then config.suspension.front else config.suspension.rear
		local tire = Tire.new(if front then config.tires.front else config.tires.rear, config.tires.compounds)
		local track = if front then dims.trackFront else dims.trackRear
		local cornerLoad = if front then frontCornerLoad else rearCornerLoad
		local suspension = Suspension.new(axle, cornerLoad)
		local wheelCentreY = tire.radius - mass.comHeight -- at the default ride height
		self.wheels[id] = {
			id = id,
			front = front,
			left = left,
			tire = tire,
			suspension = suspension,
			staticLoad = cornerLoad,
			-- suspension mount in metres, relative to the centre of mass
			mount = Vector3.new(
				(if left then -1 else 1) * track / 2,
				wheelCentreY + axle.staticLength,
				if front then self.frontAxleZ else self.rearAxleZ
			),
			staticLength = axle.staticLength,
			rayLength = suspension.maxLength + tire.radius,
			driven = false,
			share = 0,
			omega = 0,
			spin = 0,
			steer = 0,
			length = suspension.rideLength,
			lengthVelocity = 0,
			contact = false,
			load = 0,
			grip = 1,
			vLong = 0,
			vLat = 0,
			fx = 0,
			fy = 0,
			slipRatio = 0,
			slipAngle = 0,
			driveTorque = 0,
			brakeTorque = 0,
		}
	end

	self.engine = Engine.new(config.engine)
	self.transmission = Transmission.new(config.transmission)
	local tr = self.transmission
	if tr.automatic then
		-- the converter's capacity follows from its stall speed (see Transmission.converter)
		local stallRpm = config.transmission.converter.stallRpm
		tr.converterK = Engine.fullLoadTorque(config.engine, stallRpm) / Units.rpmToRadPerSec(stallRpm) ^ 2
		tr.gear = 0
		tr.fromGear = 0
	end
	self.parked = tr.automatic
	self.steering = Steering.new(config.steering)
	self.absEnabled = config.brakes.abs.enabled
	local tractionControl = config.drivetrain.tractionControl
	self.tcEnabled = tractionControl ~= nil and tractionControl.enabled
	self.tcCut = 0 -- share of engine torque traction control is removing, 0 to 1
	self.reverseTimer = 0
	self.lastForwardSpeed = 0
	self.axles = self:_buildAxles()
	self.telemetry = {}
	return self
end

-- Driven axles, front first. With an on-demand centre coupling both axles are driven and their
-- shares are the base split, which also weights the gearbox speed in _inputOmega.
function VehicleSimulation:_buildAxles()
	local drivetrain = self.config.drivetrain
	local coupling = if drivetrain.layout == "AWD" then drivetrain.centreCoupling else nil
	local frontShare
	if drivetrain.layout == "FWD" then
		frontShare = 1
	elseif drivetrain.layout == "RWD" then
		frontShare = 0
	elseif coupling then
		frontShare = math.clamp(coupling.baseFrontShare, 0, 1)
	else
		frontShare = math.clamp(drivetrain.frontTorqueShare, 0, 1)
	end
	self.coupling = coupling
	self.frontShare = frontShare
	local axles = {}
	if frontShare > 0 or coupling then
		table.insert(axles, { left = self.wheels.FL, right = self.wheels.FR, share = frontShare, diff = drivetrain.frontDifferential, torque = 0 })
	end
	if frontShare < 1 or coupling then
		table.insert(axles, { left = self.wheels.RL, right = self.wheels.RR, share = 1 - frontShare, diff = drivetrain.rearDifferential, torque = 0 })
	end
	for _, axle in axles do
		for _, w in { axle.left, axle.right } do
			w.driven = true
			w.share = axle.share
		end
	end
	return axles
end

-- Gearbox input speed implied by the driven wheels (rad/s).
function VehicleSimulation:_inputOmega(ratio: number): number
	if ratio == 0 then
		return 0
	end
	local sum, weight = 0, 0
	for _, axle in self.axles do
		sum += (axle.left.omega + axle.right.omega) / 2 * axle.share
		weight += axle.share
	end
	return ratio * sum / math.max(weight, 1e-6)
end

-- In automatic mode, holding the brake at a standstill selects reverse, and holding the
-- accelerator in reverse selects first again.
function VehicleSimulation:_autoReverse(dt: number, input, forwardSpeed: number)
	local tr = self.transmission
	if not tr.auto then
		self.reverseTimer = 0
		return
	end
	local stopped = math.abs(forwardSpeed) < 0.6
	local wantsReverse = tr.gear >= 1 and stopped and input.brake > 0.5 and input.throttle < 0.1
	local wantsForward = tr.gear <= 0 and stopped and input.throttle > 0.5 and input.brake < 0.1
	if wantsReverse or wantsForward then
		self.reverseTimer += dt
		if self.reverseTimer > 0.35 then
			Transmission.shift(tr, if wantsReverse then -1 else 1)
			self.reverseTimer = 0
		end
	else
		self.reverseTimer = 0
	end
end

-- Step 1 of a frame: front wheel angles (radians, positive = right). Returns left, right.
function VehicleSimulation:updateSteering(dt: number, steerInput: number, forwardSpeed: number): (number, number)
	local dims = self.config.dimensions
	local left, right = Steering.update(self.steering, steerInput, math.abs(forwardSpeed) * 3.6, dt, dims.wheelbase, dims.trackFront)
	self.wheels.FL.steer = left
	self.wheels.FR.steer = right
	return left, right
end

--[[
	Step 3 of a frame.
	  input     { throttle, brake, steer, handbrake } (0 to 1; steer -1 to 1)
	  contacts  [wheelId] = { hit, distance (m, mount to road), vLong, vLat (m/s), grip }
	  forwardSpeed  car speed along its heading (m/s)
	  speed         total car speed (m/s)
	Afterwards each wheel's load, fx and fy (N) are the forces to apply, and the return value
	holds the aero forces: { drag, downFront, downRear } in newtons.
]]
function VehicleSimulation:step(dt: number, input, contacts, forwardSpeed: number, speed: number)
	local cfg = self.config
	local tr = self.transmission
	local engine = self.engine
	local automatic = tr.automatic
	local g = Units.GRAVITY
	self.lastForwardSpeed = forwardSpeed

	-- an automatic leaves park for drive when the driver first presses a pedal
	if self.parked and (input.throttle > 0.05 or input.brake > 0.05) then
		self.parked = false
		Transmission.shift(tr, 1)
	end
	if not self.parked then
		self:_autoReverse(dt, input, forwardSpeed)
	end
	local pedal, brakePedal = input.throttle, input.brake
	if tr.gear == -1 then
		pedal, brakePedal = input.brake, input.throttle
	end
	local handbrake = input.handbrake
	-- in park the brakes hold the car, standing in for the parking pawl
	local holdBrake = if self.parked then 1 else brakePedal
	-- an electronic top-speed limiter closes the throttle over the last 3 km/h
	local enginePedal = pedal
	local speedLimit = cfg.engine.speedLimitKmh
	if speedLimit then
		enginePedal = math.min(pedal, math.clamp((speedLimit - math.abs(forwardSpeed) * 3.6) / 3, 0, 1))
	end

	-- suspension loads
	for _, id in WHEEL_IDS do
		local w = self.wheels[id]
		local c = contacts[id]
		local s = w.suspension
		local length = if c.hit then c.distance - w.tire.radius else math.huge
		if c.hit and length <= s.maxLength then
			local velocity = if w.contact then (length - w.length) / dt else 0
			velocity = math.clamp(velocity, -MAX_DAMPER_SPEED, MAX_DAMPER_SPEED)
			local forceLength = math.max(length, s.minLength - MAX_BUMP_STOP_COMPRESSION)
			w.length = length
			w.lengthVelocity = velocity
			w.load = math.min(Suspension.force(s, forceLength, velocity), w.staticLoad * 6)
			w.contact = w.load > 0
			w.grip = c.grip
			w.vLong = c.vLong
			w.vLat = c.vLat
		else
			w.contact = false
			w.load = 0
			w.length = s.maxLength
			w.lengthVelocity = 0
		end
	end
	for _, pair in { { "FL", "FR" }, { "RL", "RR" } } do
		local l, r = self.wheels[pair[1]], self.wheels[pair[2]]
		local addLeft, addRight = Suspension.antiRoll(l.suspension, l.length, r.length, l.contact, r.contact)
		l.load = math.max(l.load + addLeft, 0)
		r.load = math.max(r.load + addRight, 0)
	end

	-- automatic gear choice, from the speed the wheels imply at the gearbox input
	local inputRpmNow = Units.radPerSecToRpm(math.abs(self:_inputOmega(Transmission.ratio(tr))))
	Transmission.updateAuto(tr, dt, inputRpmNow, pedal)

	-- drivetrain and tyres, in sub-steps
	local h = dt / SUBSTEPS
	local engineInertia = cfg.engine.inertia
	local efficiency = cfg.transmission.efficiency
	local minOmega = Units.rpmToRadPerSec(cfg.engine.idleRpm * 0.55)
	local maxOmega = Units.rpmToRadPerSec(cfg.engine.limiterRpm + 400)
	local engineTorqueSum, clutchTorqueSum, engagementSum = 0, 0, 0
	for _, id in WHEEL_IDS do
		local w = self.wheels[id]
		w.fxSum = 0
		w.fySum = 0
	end

	for _ = 1, SUBSTEPS do
		local ratio = Transmission.ratio(tr)
		local inputOmega = self:_inputOmega(ratio)
		local engagement = Transmission.engagement(tr, Engine.rpm(engine), Units.radPerSecToRpm(math.abs(inputOmega)), pedal, cfg.engine.idleRpm)
		local capacity = engagement * cfg.transmission.clutchMaxTorque
		local engineTorque = Engine.netTorque(engine, pedal, h)

		-- Traction control, acting like a launch and traction system: it caps engine and clutch
		-- torque at what the driven tyres can put down (plus headroom), then trims further while
		-- the driven wheels still slip more than the target. Capping the clutch matters at a
		-- standing start, where the spinning engine would otherwise dump its energy into wheelspin.
		if self.tcEnabled and ratio ~= 0 then
			local tc = cfg.drivetrain.tractionControl
			local driveSlip, available = 0, 0
			for _, axle in self.axles do
				for _, w in { axle.left, axle.right } do
					if w.contact then
						-- measured against at least TC_REFERENCE_SPEED so a standing start isn't choked
						local slip = (w.omega * w.tire.radius - w.vLong) / math.max(math.abs(w.vLong), TC_REFERENCE_SPEED)
						driveSlip = math.max(driveSlip, slip * sign(ratio))
						available += Tire.peakForce(w.tire, w.load, w.grip) * w.tire.radius
					end
				end
			end
			local excess = driveSlip - tc.targetSlip
			if excess > 0 then
				self.tcCut = math.min(1, self.tcCut + h * tc.rate * excess / tc.targetSlip)
			else
				self.tcCut = math.max(0, self.tcCut - h * tc.recovery)
			end
			local limit = available / (math.abs(ratio) * efficiency) * tc.headroom * (1 - self.tcCut)
			engineTorque = math.min(engineTorque, limit)
			capacity = math.min(capacity, limit)
		else
			self.tcCut = 0
		end

		for _, id in WHEEL_IDS do
			local w = self.wheels[id]
			if w.contact then
				local fx, fy, slipRatio, slipAngle = Tire.forces(w.tire, w.load, w.vLong, w.vLat, w.omega * w.tire.radius, w.grip, h)
				w.fxStep, w.fyStep, w.slipRatio, w.slipAngle = fx, fy, slipRatio, slipAngle
			else
				w.fxStep, w.fyStep, w.slipRatio, w.slipAngle = 0, 0, 0, 0
				w.tire.slipAngle = 0
			end
			w.brakeTorque = Brakes.torque(cfg.brakes, w.front, brakePedal, handbrake, w.slipRatio, self.absEnabled)
		end

		local clutchTorque = 0
		local locked = false
		if ratio ~= 0 and capacity > 0 then
			local inertiaInput = 0.02 -- gearbox internals
			local loadTorque = 0
			for _, axle in self.axles do
				for _, w in { axle.left, axle.right } do
					inertiaInput += w.tire.inertia / (ratio * ratio)
					local rolling = if w.contact then w.load * w.tire.compound.rollingResistance * w.tire.radius else 0
					local resist = w.fxStep * w.tire.radius + (w.brakeTorque + rolling) * sign(w.omega)
					loadTorque += resist / ratio
				end
			end
			clutchTorque = Transmission.clutchTorque(tr, engine.omega, inputOmega, engineInertia, inertiaInput, engineTorque, loadTorque, capacity, h)
			locked = math.abs(clutchTorque) < capacity * 0.999
		end

		local wheelTorque = clutchTorque * ratio * efficiency
		for _, axle in self.axles do
			local left, right = Differential.split(axle.diff, wheelTorque * axle.share, axle.left.omega, axle.right.omega, axle.left.tire.inertia, h)
			axle.left.driveTorque = left
			axle.right.driveTorque = right
		end

		engine.omega = math.clamp(engine.omega + h * (engineTorque - clutchTorque) / engineInertia, minOmega, maxOmega)

		for _, id in WHEEL_IDS do
			local w = self.wheels[id]
			local r = w.tire.radius
			local inertia = w.tire.inertia
			if w.driven and locked then
				inertia += engineInertia * ratio * ratio * w.share / 2
			end
			local drive = if w.driven then w.driveTorque else 0
			local tireTorque = w.fxStep * r
			if w.contact then
				-- the tyre can't drive the wheel past the speed where its slip would be zero
				local limit = inertia * math.abs(w.omega - w.vLong / r) / h + math.abs(drive) + w.brakeTorque
				tireTorque = math.clamp(tireTorque, -limit, limit)
			end
			local rolling = if w.contact then w.load * w.tire.compound.rollingResistance * r else 0
			local newOmega = w.omega + h * (drive - tireTorque - rolling * sign(w.omega)) / inertia
			local brakeStep = h * w.brakeTorque / inertia
			if math.abs(newOmega) <= brakeStep then
				newOmega = 0 -- brakes hold the wheel but can't spin it backwards
			else
				newOmega -= sign(newOmega) * brakeStep
			end
			w.omega = newOmega
			w.fxSum += tireTorque / r
			w.fySum += w.fyStep
		end

		engineTorqueSum += engineTorque
		clutchTorqueSum += clutchTorque
		engagementSum += engagement
	end

	-- frame forces
	for _, id in WHEEL_IDS do
		local w = self.wheels[id]
		w.fx = w.fxSum / SUBSTEPS
		w.fy = w.fySum / SUBSTEPS
		if w.contact then
			-- lateral force can't do more than stop the sideways motion within one frame
			local maxLateral = (w.load / g) * math.abs(w.vLat) / dt
			w.fy = math.clamp(w.fy, -maxLateral, maxLateral)
		end
		w.spin = (w.spin + w.omega * dt) % (2 * math.pi)
	end

	-- parking hold: with the brakes on at a near standstill, static friction holds the car
	if speed < 0.4 and (brakePedal > 0.1 or handbrake > 0.1) then
		for _, id in WHEEL_IDS do
			local w = self.wheels[id]
			if w.contact then
				local mass = w.load / g
				local maxHold = Tire.peakForce(w.tire, w.load, w.grip)
				w.fx = math.clamp(-w.vLong * mass / dt, -maxHold, maxHold)
				w.fy = math.clamp(-w.vLat * mass / dt, -maxHold, maxHold)
			end
		end
	end

	local drag, downFront, downRear = Aero.forces(cfg.aero, speed)

	local t = self.telemetry
	t.rpm = Engine.rpm(engine)
	t.gear = Transmission.gearLabel(tr)
	t.gearNumber = tr.gear
	t.auto = tr.auto
	t.shifting = Transmission.isShifting(tr)
	t.limiter = engine.limiterCut
	t.throttle = engine.throttle
	t.pedal = pedal
	t.brake = brakePedal
	t.handbrake = handbrake
	t.clutch = engagementSum / SUBSTEPS
	t.engineTorque = engineTorqueSum / SUBSTEPS
	t.clutchTorque = clutchTorqueSum / SUBSTEPS
	t.wheelTorque = t.clutchTorque * Transmission.ratio(tr) * efficiency
	t.speedKmh = speed * 3.6
	t.forwardKmh = forwardSpeed * 3.6
	t.steerDeg = math.deg(self.steering.angle)
	t.drag = drag
	t.downFront = downFront
	t.downRear = downRear
	t.abs = self.absEnabled
	t.tractionControl = self.tcEnabled
	t.tractionActive = self.tcCut > 0.02

	return { drag = drag, downFront = downFront, downRear = downRear }
end

-- Manual shifting. Selecting a paddle switches the gearbox to manual mode.
function VehicleSimulation:shiftUp()
	local tr = self.transmission
	tr.auto = false
	if tr.gear == -1 and math.abs(self.lastForwardSpeed) > 2 then
		return
	end
	Transmission.shift(tr, tr.gear + 1)
end

function VehicleSimulation:shiftDown()
	local tr = self.transmission
	tr.auto = false
	local target = tr.gear - 1
	if target == -1 and math.abs(self.lastForwardSpeed) > 2 then
		return -- no reverse while rolling
	end
	if target >= 1 then
		-- refuse a downshift that would over-rev the engine, like a real dual-clutch
		local spec = tr.spec
		local inputRpm = Units.radPerSecToRpm(math.abs(self:_inputOmega(Transmission.ratio(tr))))
		if inputRpm * spec.gearRatios[target] / spec.gearRatios[tr.gear] > self.config.engine.limiterRpm + 200 then
			return
		end
	end
	Transmission.shift(tr, target)
end

function VehicleSimulation:toggleAutomatic()
	local tr = self.transmission
	tr.auto = not tr.auto
	if tr.auto and tr.gear == 0 then
		Transmission.shift(tr, 1)
	end
end

function VehicleSimulation:toggleAbs()
	self.absEnabled = not self.absEnabled
end

function VehicleSimulation:toggleTractionControl()
	self.tcEnabled = not self.tcEnabled
end

return VehicleSimulation
