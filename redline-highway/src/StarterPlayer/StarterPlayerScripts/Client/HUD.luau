--[[
	HUD
	Driving display: speed, gear, gearbox mode, RPM bar with redline and shift light, pedal bars,
	ABS state and camera mode. T shows a telemetry overlay (engine, clutch, G-forces, aero, per-wheel
	load, slip, slip angle, suspension travel, and timed 0-100 / 0-200 / 100-0 runs against the
	factory figures). H shows or hides the controls.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VehicleSystem = ReplicatedStorage:WaitForChild("VehicleSystem")
local Telemetry = require(VehicleSystem:WaitForChild("VehicleTelemetry"):WaitForChild("Telemetry"))
local VehicleSimulation = require(VehicleSystem:WaitForChild("CorePhysics"):WaitForChild("VehicleSimulation"))
local CameraController = require(script.Parent.CameraController)

local HUD = {}

local WHITE = Color3.fromRGB(240, 240, 240)
local GREY = Color3.fromRGB(150, 152, 158)
local AMBER = Color3.fromRGB(255, 176, 50)
local RED = Color3.fromRGB(235, 50, 50)
local PANEL = Color3.fromRGB(10, 10, 12)

local HELP_TEXT = table.concat({
	"CONTROLS",
	"W / S      accelerate / brake",
	"           (hold S when stopped to reverse)",
	"A / D      steer",
	"Space      handbrake",
	"E / Q      shift up / down (manual)",
	"M          automatic / manual gearbox",
	"B          ABS on / off",
	"V          traction control on / off",
	"C          camera: chase, hood, cockpit",
	"R          put the car back on the track",
	"T          telemetry     H  hide this",
	"",
	"Gamepad: RT / LT pedals, left stick",
	"steers, RB / LB shift, X handbrake,",
	"Y camera, Back resets",
}, "\n")

local refs: { [string]: any } = {}
local telemetryVisible = false
local lastTelemetryText = 0

local function make(className: string, properties: { [string]: any }, parent: Instance): any
	local object = Instance.new(className)
	for key, value in properties do
		(object :: any)[key] = value
	end
	object.Parent = parent
	return object
end

local function label(parent: Instance, properties: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = WHITE,
		TextSize = 16,
	}
	for key, value in properties do
		defaults[key] = value
	end
	return make("TextLabel", defaults, parent)
end

local function panelText(parent: Instance, name: string, properties: { [string]: any }): TextLabel
	local text = label(parent, {
		Name = name,
		Font = Enum.Font.Code,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.3,
	})
	for key, value in properties do
		(text :: any)[key] = value
	end
	make("UICorner", { CornerRadius = UDim.new(0, 8) }, text)
	make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 8) }, text)
	return text
end

local function formatTime(seconds: number?): string
	return if seconds then string.format("%.2f s", seconds) else "--"
end

local function telemetryText(sim): string
	local t = sim.telemetry
	local frame = Telemetry.frame
	local results = Telemetry.results
	local targets = sim.config.performanceTargets
	local lines = {
		string.format("%s   gear %s (%s)   clutch %3d%%", sim.config.displayName, t.gear, if t.auto then "auto" else "manual", math.floor(t.clutch * 100 + 0.5)),
		string.format("engine %5d rpm  %4d Nm      wheel torque %6d Nm", math.floor(t.rpm), math.floor(t.engineTorque), math.floor(t.wheelTorque)),
		string.format("speed %6.1f km/h    long %+.2f g    lat %+.2f g", t.speedKmh, frame.longG or 0, frame.latG or 0),
		string.format("pedal %3d%%  brake %3d%%  handbrake %3d%%  steer %+5.1f deg", math.floor(t.pedal * 100), math.floor(t.brake * 100), math.floor(t.handbrake * 100), t.steerDeg),
		string.format("drag %5d N    downforce front %5d N   rear %5d N", math.floor(t.drag), math.floor(t.downFront), math.floor(t.downRear)),
		"",
		"wheel     load N     slip    angle    travel    wheel rpm",
	}
	for _, id in VehicleSimulation.WHEEL_IDS do
		local w = sim.wheels[id]
		local travel = math.floor((w.staticLength - w.length) * 1000 + 0.5)
		table.insert(lines, string.format("%-5s %10d  %7.3f  %5.1f deg  %+5d mm  %8d", id, math.floor(w.load), w.slipRatio, math.deg(w.slipAngle), travel, math.floor(w.omega * 30 / math.pi)))
	end
	table.insert(lines, "")
	table.insert(lines, string.format("0-100 km/h   %-9s factory %.1f s", formatTime(results.zeroTo100), targets.zeroTo100))
	table.insert(lines, string.format("0-200 km/h   %-9s factory %.1f s", formatTime(results.zeroTo200), targets.zeroTo200))
	table.insert(lines, string.format("100-0 km/h   %s", if results.brake100 then string.format("%.1f m", results.brake100) else "--"))
	table.insert(lines, string.format("top speed    %.0f km/h  factory over %d km/h", results.topSpeed, targets.topSpeedKmh))
	table.insert(lines, string.format("%d fps", math.floor(frame.fps or 0)))
	return table.concat(lines, "\n")
end

local function update()
	local sim = Telemetry.sim
	refs.gui.Enabled = sim ~= nil
	if not sim or not sim.telemetry.rpm then
		return
	end
	local t = sim.telemetry
	local engine = sim.config.engine
	local maxRpm = engine.limiterRpm + 600

	refs.speed.Text = tostring(math.floor(math.abs(t.forwardKmh) + 0.5))
	refs.gear.Text = t.gear
	refs.mode.Text = if t.auto then "AUTO" else "MANUAL"
	local tcText = if not t.tractionControl then "tc off  " elseif t.tractionActive then "TC!  " else "TC  "
	refs.flags.Text = (if t.abs then "ABS  " else "abs off  ") .. tcText .. (if t.limiter then "LIMIT" else "")
	refs.flags.TextColor3 = if t.limiter then RED else GREY

	local share = math.clamp(t.rpm / maxRpm, 0, 1)
	refs.rpmFill.Size = UDim2.fromScale(share, 1)
	refs.rpmFill.BackgroundColor3 = if t.rpm > engine.limiterRpm - 900 then RED elseif t.rpm > engine.limiterRpm - 2400 then AMBER else WHITE
	refs.rpmText.Text = string.format("%d rpm", math.floor(t.rpm / 10 + 0.5) * 10)
	local nearLimit = t.rpm > engine.limiterRpm - 450
	refs.shiftLight.BackgroundTransparency = if nearLimit and (os.clock() * 8) % 2 < 1 then 0 else 1

	refs.throttleFill.Size = UDim2.fromScale(1, math.clamp(t.pedal, 0, 1))
	refs.brakeFill.Size = UDim2.fromScale(1, math.clamp(t.brake, 0, 1))
	refs.camera.Text = "Camera: " .. CameraController.mode() .. " (C)"

	if telemetryVisible and os.clock() - lastTelemetryText > 0.1 then
		lastTelemetryText = os.clock()
		refs.telemetry.Text = telemetryText(sim)
	end
end

function HUD.init()
	local gui = make("ScreenGui", { Name = "DriveHUD", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false }, Players.LocalPlayer:WaitForChild("PlayerGui"))
	refs.gui = gui

	local cluster = make("Frame", {
		Name = "Cluster",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(400, 150),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 12) }, cluster)

	refs.speed = label(cluster, { Font = Enum.Font.GothamBlack, TextSize = 64, Text = "0", Position = UDim2.fromOffset(40, 6), Size = UDim2.fromOffset(170, 72), TextXAlignment = Enum.TextXAlignment.Right })
	label(cluster, { Text = "km/h", TextSize = 16, TextColor3 = GREY, Position = UDim2.fromOffset(216, 46), Size = UDim2.fromOffset(60, 24), TextXAlignment = Enum.TextXAlignment.Left })
	refs.gear = label(cluster, { Font = Enum.Font.GothamBlack, TextSize = 64, Text = "1", Position = UDim2.fromOffset(300, 6), Size = UDim2.fromOffset(80, 72) })
	refs.mode = label(cluster, { Text = "AUTO", TextSize = 13, TextColor3 = GREY, Position = UDim2.fromOffset(300, 74), Size = UDim2.fromOffset(80, 16) })

	refs.shiftLight = make("Frame", { Position = UDim2.fromOffset(40, 88), Size = UDim2.fromOffset(340, 6), BackgroundColor3 = RED, BackgroundTransparency = 1, BorderSizePixel = 0 }, cluster)
	local rpmBack = make("Frame", { Position = UDim2.fromOffset(40, 100), Size = UDim2.fromOffset(340, 14), BackgroundColor3 = Color3.fromRGB(40, 40, 44), BorderSizePixel = 0 }, cluster)
	refs.rpmFill = make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, rpmBack)
	refs.redline = make("Frame", { Size = UDim2.new(0, 2, 1, 6), Position = UDim2.new(0, 0, 0, -3), BackgroundColor3 = RED, BorderSizePixel = 0 }, rpmBack)
	refs.rpmText = label(cluster, { Text = "0 rpm", TextSize = 14, TextColor3 = GREY, Position = UDim2.fromOffset(40, 120), Size = UDim2.fromOffset(160, 20), TextXAlignment = Enum.TextXAlignment.Left })
	refs.flags = label(cluster, { Text = "ABS", TextSize = 14, TextColor3 = GREY, Position = UDim2.fromOffset(220, 120), Size = UDim2.fromOffset(160, 20), TextXAlignment = Enum.TextXAlignment.Right })

	-- pedal bars down the left edge of the cluster
	local throttleBack = make("Frame", { Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(8, 122), BackgroundColor3 = Color3.fromRGB(40, 40, 44), BorderSizePixel = 0 }, cluster)
	refs.throttleFill = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.fromRGB(80, 200, 120), BorderSizePixel = 0 }, throttleBack)
	local brakeBack = make("Frame", { Position = UDim2.fromOffset(24, 14), Size = UDim2.fromOffset(8, 122), BackgroundColor3 = Color3.fromRGB(40, 40, 44), BorderSizePixel = 0 }, cluster)
	refs.brakeFill = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = RED, BorderSizePixel = 0 }, brakeBack)

	refs.camera = label(gui, { Text = "Camera: Chase (C)", TextSize = 14, TextColor3 = GREY, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -180), Size = UDim2.fromOffset(240, 20), TextXAlignment = Enum.TextXAlignment.Right })
	refs.telemetry = panelText(gui, "Telemetry", { Position = UDim2.fromOffset(16, 56), Size = UDim2.fromOffset(560, 370), Visible = false, Text = "" })
	refs.help = panelText(gui, "Help", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -24), Size = UDim2.fromOffset(340, 290), Text = HELP_TEXT })

	RunService.RenderStepped:Connect(update)
end

-- Call once a car exists so the redline marker sits at the right rpm.
function HUD.setVehicle(config)
	if refs.redline then
		local share = config.engine.limiterRpm / (config.engine.limiterRpm + 600)
		refs.redline.Position = UDim2.new(share, -1, 0, -3)
	end
end

function HUD.toggleTelemetry()
	telemetryVisible = not telemetryVisible
	refs.telemetry.Visible = telemetryVisible
end

function HUD.toggleHelp()
	refs.help.Visible = not refs.help.Visible
end

return HUD
