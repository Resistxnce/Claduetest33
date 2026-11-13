--[[
	InputController
	Keyboard and gamepad driving input. Keyboard pedals and steering ramp smoothly (digital keys
	would otherwise slam a 800 CV car); gamepad triggers and stick are used directly.

	InputController.state = { throttle 0-1, brake 0-1, steer -1 to 1, handbrake 0-1 }
	One-shot actions (shifts, camera, reset...) are delivered to listeners registered with on().
]]

local UserInputService = game:GetService("UserInputService")

local InputController = {}

InputController.state = { throttle = 0, brake = 0, steer = 0, handbrake = 0 }

local HOLD_KEYS = {
	[Enum.KeyCode.W] = "throttle",
	[Enum.KeyCode.Up] = "throttle",
	[Enum.KeyCode.S] = "brake",
	[Enum.KeyCode.Down] = "brake",
	[Enum.KeyCode.A] = "left",
	[Enum.KeyCode.Left] = "left",
	[Enum.KeyCode.D] = "right",
	[Enum.KeyCode.Right] = "right",
	[Enum.KeyCode.Space] = "handbrake",
	[Enum.KeyCode.ButtonX] = "handbrake",
}

local ACTION_KEYS = {
	[Enum.KeyCode.E] = "shiftUp",
	[Enum.KeyCode.ButtonR1] = "shiftUp",
	[Enum.KeyCode.Q] = "shiftDown",
	[Enum.KeyCode.ButtonL1] = "shiftDown",
	[Enum.KeyCode.M] = "toggleAuto",
	[Enum.KeyCode.B] = "toggleAbs",
	[Enum.KeyCode.V] = "toggleTc",
	[Enum.KeyCode.C] = "camera",
	[Enum.KeyCode.ButtonY] = "camera",
	[Enum.KeyCode.R] = "reset",
	[Enum.KeyCode.ButtonSelect] = "reset",
	[Enum.KeyCode.T] = "telemetry",
	[Enum.KeyCode.DPadUp] = "telemetry",
	[Enum.KeyCode.H] = "help",
}

local STICK_DEADZONE = 0.12

local held: { [string]: boolean } = {}
local pad = { throttle = 0, brake = 0, steer = 0 }
local keyboard = { throttle = 0, brake = 0, steer = 0 }
local listeners: { [string]: () -> () } = {}

function InputController.on(action: string, callback: () -> ())
	listeners[action] = callback
end

local function fire(action: string)
	local callback = listeners[action]
	if callback then
		task.spawn(callback)
	end
end

local function approach(current: number, target: number, rate: number, dt: number): number
	local step = rate * dt
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

function InputController.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return -- typing in chat or clicking UI
		end
		local hold = HOLD_KEYS[input.KeyCode]
		if hold then
			held[hold] = true
		end
		local action = ACTION_KEYS[input.KeyCode]
		if action then
			fire(action)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		local hold = HOLD_KEYS[input.KeyCode]
		if hold then
			held[hold] = false
		end
		if input.KeyCode == Enum.KeyCode.ButtonR2 then
			pad.throttle = 0
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
			pad.brake = 0
		elseif input.KeyCode == Enum.KeyCode.Thumbstick1 then
			pad.steer = 0
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local x = input.Position.X
			if math.abs(x) < STICK_DEADZONE then
				pad.steer = 0
			else
				pad.steer = (x - math.sign(x) * STICK_DEADZONE) / (1 - STICK_DEADZONE)
			end
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			pad.throttle = input.Position.Z
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
			pad.brake = input.Position.Z
		end
	end)

	UserInputService.WindowFocusReleased:Connect(function()
		table.clear(held)
	end)
end

-- Call once per frame before reading state.
function InputController.update(dt: number)
	keyboard.throttle = approach(keyboard.throttle, if held.throttle then 1 else 0, if held.throttle then 5 else 8, dt)
	keyboard.brake = approach(keyboard.brake, if held.brake then 1 else 0, if held.brake then 6 else 10, dt)

	local steerTarget = (if held.right then 1 else 0) - (if held.left then 1 else 0)
	local steerRate
	if steerTarget == 0 then
		steerRate = 4 -- self-centre quickly
	elseif math.sign(steerTarget) ~= math.sign(keyboard.steer) then
		steerRate = 6 -- quick change of direction
	else
		steerRate = 2.5
	end
	keyboard.steer = approach(keyboard.steer, steerTarget, steerRate, dt)

	local state = InputController.state
	state.throttle = math.max(keyboard.throttle, pad.throttle)
	state.brake = math.max(keyboard.brake, pad.brake)
	state.steer = if math.abs(pad.steer) > math.abs(keyboard.steer) then pad.steer else keyboard.steer
	state.handbrake = if held.handbrake then 1 else 0
end

return InputController
