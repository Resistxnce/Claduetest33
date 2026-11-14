--[[
	ScoreHUD: the close-pass score at the top of the screen. Shows the banked score, the current
	combo with its multiplier and a bar for the time left to chain the next pass, and short popups
	for each pass ("CLOSE PASS +540"), banked combos and crashes.

	Also the always-on parts of the screen: a notice banner (map and car names when they change,
	ScoreHUD.notice) and two buttons at the top right for changing map and car with a mouse or a
	touch screen (ScoreHUD.menu), which do the same as the N and G keys.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ScoreHUD = {}

local WHITE = Color3.fromRGB(240, 240, 240)
local AMBER = Color3.fromRGB(255, 176, 50)
local GREEN = Color3.fromRGB(120, 230, 140)
local RED = Color3.fromRGB(235, 60, 60)
local POPUP_TIME = 1.4
local POPUPS = 5

local gui: ScreenGui
local scoreLabel: TextLabel
local comboLabel: TextLabel
local timerBar: Frame
local popups = {}
local nextPopup = 1
local menu: ScreenGui
local noticeLabel: TextLabel
local noticeLeft = 0
local mapButton: TextButton

local function newLabel(parent: Instance, name: string, size: UDim2, position: UDim2, textSize: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Position = position
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = textSize
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.Text = ""
	label.Parent = parent
	return label
end

local function thousands(x: number): string
	local s = tostring(math.floor(math.abs(x) + 0.5))
	local out = string.reverse((string.gsub(string.reverse(s), "(%d%d%d)", "%1,")))
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return out
end

function ScoreHUD.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "ScoreHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	scoreLabel = newLabel(gui, "Score", UDim2.fromOffset(400, 34), UDim2.new(0.5, 0, 0, 14), 28, WHITE)
	comboLabel = newLabel(gui, "Combo", UDim2.fromOffset(400, 26), UDim2.new(0.5, 0, 0, 48), 22, AMBER)
	local track = Instance.new("Frame")
	track.Name = "ComboTimer"
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.new(0.5, 0, 0, 78)
	track.Size = UDim2.fromOffset(180, 4)
	track.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
	track.BackgroundTransparency = 0.3
	track.BorderSizePixel = 0
	track.Parent = gui
	timerBar = Instance.new("Frame")
	timerBar.Name = "Fill"
	timerBar.Size = UDim2.fromScale(0, 1)
	timerBar.BackgroundColor3 = AMBER
	timerBar.BorderSizePixel = 0
	timerBar.Parent = track
	for i = 1, POPUPS do
		popups[i] = { label = newLabel(gui, "Popup" .. i, UDim2.fromOffset(500, 30), UDim2.new(0.5, 0, 0.3, 0), 26, WHITE), age = math.huge }
	end
	ScoreHUD.set(nil)

	-- always on: the notice banner (fades out by itself) and the menu buttons
	menu = Instance.new("ScreenGui")
	menu.Name = "MapMenu"
	menu.ResetOnSpawn = false
	menu.IgnoreGuiInset = true
	menu.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	noticeLabel = newLabel(menu, "Notice", UDim2.fromOffset(700, 40), UDim2.new(0.5, 0, 0, 104), 32, WHITE)
	RunService.Heartbeat:Connect(function(dt)
		if noticeLeft > 0 then
			noticeLeft -= dt
			local fade = math.clamp(1 - noticeLeft / 0.6, 0, 1)
			noticeLabel.TextTransparency = fade
			noticeLabel.TextStrokeTransparency = 0.5 + 0.5 * fade
		end
	end)
end

-- Show a short line of text (a map's or car's name) under the score for a few seconds.
function ScoreHUD.notice(text: string, seconds: number?)
	noticeLabel.Text = text
	noticeLabel.TextTransparency = 0
	noticeLabel.TextStrokeTransparency = 0.5
	noticeLeft = seconds or 2.5
end

local function menuButton(name: string, text: string, y: number, onClick: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, y)
	button.Size = UDim2.fromOffset(190, 30)
	button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	button.BackgroundTransparency = 0.35
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = WHITE
	button.Text = text
	button.Parent = menu
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	button.Activated:Connect(onClick)
	return button
end

-- The two buttons at the top right: change map (N) and change car (G).
function ScoreHUD.menu(onMap: () -> (), onCar: () -> ())
	mapButton = menuButton("MapButton", "MAP  (N)", 64, onMap)
	menuButton("CarButton", "NEXT CAR  (G)", 100, onCar)
end

-- Show which map the player is on, on the map button.
function ScoreHUD.setMapName(name: string)
	if mapButton then
		mapButton.Text = string.upper(name) .. "   (N)"
	end
end

local function popup(text: string, color: Color3)
	local p = popups[nextPopup]
	nextPopup = nextPopup % POPUPS + 1
	p.label.Text = text
	p.label.TextColor3 = color
	p.age = 0
end

-- scorer: a ClosePass object (or nil to hide the display)
function ScoreHUD.set(scorer)
	gui.Enabled = scorer ~= nil
end

function ScoreHUD.update(dt: number, scorer)
	for _, e in scorer.events do
		if e.kind == "pass" then
			popup(string.format("%s  +%s", e.label, thousands(e.points)), if e.label == "INSANE PASS" then RED else WHITE)
		elseif e.kind == "banked" then
			popup("BANKED  +" .. thousands(e.points), GREEN)
		elseif e.kind == "crash" then
			popup(if e.lost > 0 then "CRASH  -" .. thousands(e.lost) else "CRASH", RED)
		end
	end
	scoreLabel.Text = "SCORE  " .. thousands(scorer.total)
	if scorer.combo > 0 then
		comboLabel.Text = string.format("x%.1f   +%s", scorer.multiplier, thousands(scorer.combo))
	else
		comboLabel.Text = ""
	end
	timerBar.Size = UDim2.fromScale(math.clamp(scorer.timer / scorer.settings.comboWindow, 0, 1), 1)
	for _, p in popups do
		if p.age < POPUP_TIME then
			p.age += dt
			local t = math.clamp(p.age / POPUP_TIME, 0, 1)
			p.label.Position = UDim2.new(0.5, 0, 0.3, -60 * t)
			p.label.TextTransparency = t * t
			p.label.TextStrokeTransparency = 0.5 + 0.5 * t
		else
			p.label.TextTransparency = 1
			p.label.TextStrokeTransparency = 1
		end
	end
end

return ScoreHUD
