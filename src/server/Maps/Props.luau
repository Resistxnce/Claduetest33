-- New map props for the esports, LAN and anti-cheat maps: gaming setups,
-- stage gear, lounge seating, and the anti-cheat's scanners, lasers and ban
-- court. Built from parts the same way as Kit.luau.
--
-- Every prop is Props.name(ctx, x, z, rot, ...): a spot measured from the
-- arena's center and a turn in degrees. Props stand on the floor (y = 0) and
-- face -Z when rot is 0, like Kit.desk: screens, signs and seats look toward
-- -Z. Solid parts you can hide behind or stand on go in ctx.Structure (X-Ray
-- sees through them); trim, screens and anything overhead go in ctx.Decor.
-- Each prop returns its main part.
local CollectionService = game:GetService("CollectionService")

local Kit = require(script.Parent.Kit)

local Props = {}

local rgb, M = Kit.rgb, Kit.M
local FRONT, BACK = Enum.NormalId.Front, Enum.NormalId.Back

-- Shared colors (pink is the game's UI accent)
local PINK = rgb(255, 46, 99)
local CYAN = rgb(0, 220, 255)
local PURPLE = rgb(170, 80, 255)
local YELLOW = rgb(255, 210, 40)
local LIME = rgb(120, 255, 80)
local RED = rgb(255, 40, 50)
local WHITE = rgb(240, 240, 245)
local BLACK = rgb(20, 20, 24)
local DARK = rgb(36, 38, 46)
local STEEL = rgb(150, 154, 162)
local GOLD = rgb(240, 190, 60)
local WOOD = rgb(132, 86, 54)

-- Turns a cylinder (which lies along X) to lie along Z instead
local TURN = CFrame.Angles(0, math.rad(90), 0)

-- Helpers ----------------------------------------------------------------------

local function darker(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount or 0.3)
end

-- A round part lying along X, the way Roblox cylinders lie
local function tube(parent, name, length, diameter, cframe, color, material)
	local part = Kit.part(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A glowing disc or ring, lying along X like tube()
local function glowDisc(parent, thickness, diameter, cframe, color)
	local part = tube(parent, "Glow", thickness, diameter, cframe, color, M.Neon)
	part.CastShadow = false
	return part
end

-- A round bar from one point to another, for truss tubes and slanted rails
local function rod(parent, name, from, to, diameter, color, material)
	local direction = (to - from).Unit
	local up = if math.abs(direction.Y) > 0.99 then Vector3.new(0, 0, 1) else Vector3.new(0, 1, 0)
	return tube(parent, name, (to - from).Magnitude, diameter, CFrame.lookAt((from + to) / 2, to, up) * TURN, color, material)
end

-- A squashed ball (beanbags). It still collides as a box.
local function blob(parent, name, size, cframe, color, material)
	local part = Kit.part(parent, name, size, cframe, color, material or M.Fabric)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Lasers, scan beams and glows: people and bullets go straight through
local function passThrough(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- One line of text for Kit.text, placed by its top and height (0 to 1)
local function line(text, color, top, height, font)
	return { Text = text, Color = color, Font = font, Position = UDim2.fromScale(0.05, top), Size = UDim2.fromScale(0.9, height) }
end

-- A glowing screen with text on its front
local function screen(parent, size, cframe, color, lines)
	local part = Kit.neon(parent, size, cframe, color)
	part.Name = "Screen"
	Kit.text(part, FRONT, lines)
	return part
end

-- 25000 -> "25,000"
local function withCommas(amount)
	local text = tostring(amount)
	local count
	repeat
		text, count = string.gsub(text, "^(%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return text
end

-- Gaming gear ----------------------------------------------------------------------

-- Gaming PC case, 1.1 wide, 2.3 tall, 2.3 deep: glass front with two fans,
-- glass side (on -X) showing the graphics card, cooler and RAM
local function buildTower(ctx, base, glow)
	local shell = rgb(40, 42, 50)
	local case = Kit.part(ctx.Structure, "PcTower", Vector3.new(0.55, 2.3, 1.95), base * CFrame.new(0.275, 1.15, 0.175), rgb(28, 29, 36), M.Metal)
	local shroud = Kit.part(ctx.Decor, "PcShroud", Vector3.new(0.55, 0.55, 2.3), base * CFrame.new(-0.275, 0.275, 0), shell, M.Metal)
	Kit.text(shroud, Enum.NormalId.Left, { line("EARN ESP", glow, 0.2, 0.6) })
	Kit.part(ctx.Decor, "PcTop", Vector3.new(0.55, 0.1, 2.3), base * CFrame.new(-0.275, 2.25, 0), shell, M.Metal)
	Kit.part(ctx.Decor, "PcBack", Vector3.new(0.55, 1.65, 0.1), base * CFrame.new(-0.275, 1.375, 1.1), shell, M.Metal)
	for _, y in { 1, 1.8 } do
		glowDisc(ctx.Decor, 0.1, 0.75, base * CFrame.new(0, y, -0.95) * TURN, glow)
		tube(ctx.Decor, "FanHub", 0.16, 0.42, base * CFrame.new(0, y, -0.95) * TURN, BLACK)
	end
	glowDisc(ctx.Decor, 0.1, 0.62, base * CFrame.new(-0.08, 1.75, 0.4), glow)
	tube(ctx.Decor, "Cooler", 0.16, 0.36, base * CFrame.new(-0.08, 1.75, 0.4), BLACK)
	Kit.part(ctx.Decor, "GraphicsCard", Vector3.new(0.4, 0.3, 1.4), base * CFrame.new(-0.2, 1.05, 0.3), rgb(30, 30, 36), M.Metal)
	Kit.neon(ctx.Decor, Vector3.new(0.04, 0.08, 1.3), base * CFrame.new(-0.42, 1.05, 0.3), glow)
	Kit.neon(ctx.Decor, Vector3.new(0.12, 0.5, 0.3), base * CFrame.new(-0.06, 1.75, -0.15), PURPLE)
	local glass = rgb(160, 180, 210)
	Kit.part(ctx.Decor, "PcGlass", Vector3.new(0.05, 2.3, 2.35), base * CFrame.new(-0.575, 1.15, 0), glass, M.Glass, 0.6)
	Kit.part(ctx.Decor, "PcGlass", Vector3.new(1.15, 2.3, 0.05), base * CFrame.new(-0.025, 1.15, -1.175), glass, M.Glass, 0.6)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.06, 2.1, 0.06), base * CFrame.new(0.52, 1.15, -1.21), glow), glow, 8, 0.8)
	return case
end

-- Racing-style gaming chair, 2.7 wide, 2.8 deep, 6.5 tall, with colored side
-- bolsters and stripes. You sit facing -Z.
local function buildChair(ctx, base, color)
	for index = 0, 4 do
		local spoke = base * CFrame.Angles(0, math.rad(index * 72), 0)
		Kit.part(ctx.Decor, "ChairLeg", Vector3.new(0.28, 0.2, 1.35), spoke * CFrame.new(0, 0.38, -0.7), BLACK, M.Metal)
		Kit.ball(ctx.Decor, "Caster", 0.34, spoke * CFrame.new(0, 0.17, -1.3), BLACK)
	end
	Kit.cylinder(ctx.Decor, "ChairHub", 0.35, 0.55, base * CFrame.new(0, 0.4, 0), BLACK, M.Metal)
	Kit.cylinder(ctx.Decor, "GasLift", 1.1, 0.26, base * CFrame.new(0, 1, 0), STEEL, M.Metal)
	Kit.part(ctx.Decor, "SeatPlate", Vector3.new(1.2, 0.15, 1.2), base * CFrame.new(0, 1.6, 0), BLACK, M.Metal)
	local seat = Kit.part(ctx.Structure, "GamingChair", Vector3.new(2, 0.45, 2.1), base * CFrame.new(0, 1.9, -0.05), BLACK, M.Fabric)
	Kit.part(ctx.Decor, "SeatStripe", Vector3.new(0.5, 0.04, 1.9), base * CFrame.new(0, 2.14, -0.05), color, M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "SeatBolster", Vector3.new(0.4, 0.3, 2.1), base * CFrame.new(side * 0.95, 2.25, -0.05), color, M.Fabric)
		Kit.part(ctx.Decor, "ArmPost", Vector3.new(0.2, 0.95, 0.3), base * CFrame.new(side * 1.25, 2.4, 0.1), BLACK, M.Metal)
		Kit.part(ctx.Decor, "ArmPad", Vector3.new(0.35, 0.15, 1.1), base * CFrame.new(side * 1.25, 2.92, 0), BLACK)
	end
	-- The backrest leans back a little from its bottom edge
	local back = base * CFrame.new(0, 2.1, 0.95) * CFrame.Angles(math.rad(10), 0, 0)
	local backrest = Kit.part(ctx.Decor, "ChairBack", Vector3.new(2, 3.4, 0.45), back * CFrame.new(0, 1.75, 0), BLACK, M.Fabric)
	Kit.text(backrest, BACK, { line("EARN", color, 0.12, 0.16), line("ESP", color, 0.3, 0.16) })
	Kit.part(ctx.Decor, "ChairHead", Vector3.new(1.4, 0.9, 0.45), back * CFrame.new(0, 3.9, 0), BLACK, M.Fabric)
	Kit.part(ctx.Decor, "BackStripe", Vector3.new(0.5, 2.4, 0.04), back * CFrame.new(0, 1.5, -0.24), color, M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "ChairWing", Vector3.new(0.35, 2.6, 0.6), back * CFrame.new(side * 1, 1.4, -0.12), color, M.Fabric)
		Kit.part(ctx.Decor, "BeltSlot", Vector3.new(0.22, 0.45, 0.05), back * CFrame.new(side * 0.45, 3.85, -0.24), rgb(8, 8, 10))
	end
	local pillow = Kit.part(ctx.Decor, "Pillow", Vector3.new(1, 0.5, 0.3), back * CFrame.new(0, 3.15, -0.35), color, M.Fabric)
	Kit.text(pillow, FRONT, { line("GG", WHITE, 0.1, 0.8) })
	return seat
end

-- Gaming desk: 8 wide, 3.6 deep, 3 tall, with three monitors, an RGB
-- keyboard, a mouse pad, a headset on its stand and a PC underneath. Give a
-- chair color to add a gaming chair pulled up to it.
function Props.gamingDesk(ctx, x, z, rot, color, chairColor)
	color = color or PINK
	local base = Kit.at(ctx, x, 0, z, rot)
	local desk = Kit.part(ctx.Structure, "GamingDesk", Vector3.new(8, 0.3, 3.6), base * CFrame.new(0, 2.85, 0), rgb(26, 27, 33))
	Kit.neon(ctx.Decor, Vector3.new(8, 0.1, 0.06), base * CFrame.new(0, 2.76, -1.82), color)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(7.6, 0.1, 0.1), base * CFrame.new(0, 2.76, 1.82), color), color, 12, 1)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "DeskLeg", Vector3.new(0.5, 2.7, 0.8), base * CFrame.new(side * 3.55, 1.35, 0.6), BLACK, M.Metal)
		Kit.part(ctx.Decor, "DeskFoot", Vector3.new(0.6, 0.2, 3.4), base * CFrame.new(side * 3.55, 0.1, 0), BLACK, M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(0.52, 1.8, 0.06), base * CFrame.new(side * 3.55, 1.4, 0.18), color)
	end
	-- Three monitors, the outer two turned in toward the player
	for _, spec in {
		{ 0, 0.95, 0, rgb(40, 20, 90), { line("VICTORY", YELLOW, 0.12, 0.42), line("+250 CR", LIME, 0.6, 0.26) } },
		{ -2.75, 0.55, -28, rgb(10, 50, 60), { line("ESP: ON", PINK, 0.12, 0.36), line("AIMBOT: ON", CYAN, 0.58, 0.26) } },
		{ 2.75, 0.55, 28, rgb(60, 14, 34), { line("GG EZ", WHITE, 0.12, 0.42), line("#1 OF 64", YELLOW, 0.6, 0.26) } },
	} do
		local frame = base * CFrame.new(spec[1], 0, spec[2]) * CFrame.Angles(0, math.rad(spec[3]), 0)
		Kit.part(ctx.Decor, "MonitorStand", Vector3.new(0.3, 1, 0.2), frame * CFrame.new(0, 3.5, 0.25), BLACK, M.Metal)
		Kit.part(ctx.Decor, "Monitor", Vector3.new(2.7, 1.6, 0.14), frame * CFrame.new(0, 4.45, 0.08), BLACK)
		screen(ctx.Decor, Vector3.new(2.55, 1.45, 0.04), frame * CFrame.new(0, 4.45, -0.01), spec[4], spec[5])
	end
	-- RGB keyboard, mouse pad and mouse
	Kit.part(ctx.Decor, "Keyboard", Vector3.new(2.3, 0.12, 0.8), base * CFrame.new(-0.3, 3.06, -0.95), BLACK)
	for index, rowColor in { PINK, PURPLE, CYAN } do
		Kit.neon(ctx.Decor, Vector3.new(2.15, 0.04, 0.17), base * CFrame.new(-0.3, 3.13, -0.95 + (index - 2) * 0.22), rowColor)
	end
	Kit.part(ctx.Decor, "MousePad", Vector3.new(1.4, 0.04, 1.1), base * CFrame.new(1.75, 3.02, -0.95), rgb(40, 40, 50), M.Fabric)
	Kit.part(ctx.Decor, "Mouse", Vector3.new(0.3, 0.14, 0.45), base * CFrame.new(1.85, 3.1, -0.95), BLACK)
	-- Headset hanging on a short stand in the front corner
	Kit.cylinder(ctx.Decor, "HeadsetStand", 0.08, 0.6, base * CFrame.new(-3.45, 3.04, -1.25), BLACK, M.Metal)
	Kit.cylinder(ctx.Decor, "HeadsetStand", 0.75, 0.1, base * CFrame.new(-3.45, 3.45, -1.25), STEEL, M.Metal)
	Kit.part(ctx.Decor, "Headset", Vector3.new(0.9, 0.14, 0.3), base * CFrame.new(-3.45, 3.89, -1.25), BLACK)
	for _, side in { -1, 1 } do
		tube(ctx.Decor, "EarCup", 0.22, 0.55, base * CFrame.new(-3.45 + side * 0.45, 3.56, -1.25), color)
	end
	buildTower(ctx, base * CFrame.new(2.7, 0, 0.2), color)
	if chairColor then
		buildChair(ctx, base * CFrame.new(0, 0, -2.8) * CFrame.Angles(0, math.pi, 0), chairColor)
	end
	return desk
end

-- A gaming chair on its own (2.9 x 3.4 footprint), facing -Z
function Props.gamingChair(ctx, x, z, rot, color)
	return buildChair(ctx, Kit.at(ctx, x, 0, z, rot), color or PINK)
end

-- A gaming PC standing on the floor (1.2 x 2.4 footprint)
function Props.pcTower(ctx, x, z, rot, color)
	return buildTower(ctx, Kit.at(ctx, x, 0, z, rot), color or PINK)
end

-- Server rack: 4 wide, 3.8 deep, 9.1 tall, with a glass door, rows of
-- servers with blinking lights, and a name plate on top
function Props.serverRack(ctx, x, z, rot, color, label)
	color = color or CYAN
	local base = Kit.at(ctx, x, 0, z, rot)
	local rack = Kit.part(ctx.Structure, "ServerRack", Vector3.new(4, 8.6, 3.2), base * CFrame.new(0, 4.3, 0.2), rgb(28, 30, 36), M.Metal)
	Kit.part(ctx.Decor, "RackBase", Vector3.new(4.1, 0.5, 0.4), base * CFrame.new(0, 0.25, -1.55), BLACK, M.Metal)
	local cap = Kit.part(ctx.Decor, "RackTop", Vector3.new(4.2, 0.5, 3.8), base * CFrame.new(0, 8.85, 0.1), BLACK, M.Metal)
	Kit.text(cap, FRONT, { line(label or "GAME SERVER 07", color, 0.15, 0.7, Enum.Font.GothamBold) })
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "RackPost", Vector3.new(0.3, 8.1, 0.4), base * CFrame.new(side * 1.85, 4.55, -1.6), rgb(48, 50, 58), M.Metal)
	end
	Kit.part(ctx.Decor, "RackDoor", Vector3.new(3.4, 8, 0.08), base * CFrame.new(0, 4.55, -1.72), rgb(170, 200, 230), M.Glass, 0.75)
	Kit.part(ctx.Decor, "RackHandle", Vector3.new(0.12, 1.4, 0.15), base * CFrame.new(1.5, 4.6, -1.84), STEEL, M.Metal)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(3.9, 0.12, 0.06), base * CFrame.new(0, 8.55, -1.82), color), color, 10, 0.6)
	-- Servers: drive bays with a light strip, every other one a vented switch
	local leds = { rgb(0, 255, 120), rgb(255, 170, 0), color }
	for row = 1, 7 do
		local y = 0.55 + row
		local server = Kit.part(ctx.Decor, "Server", Vector3.new(3.3, 0.85, 0.12), base * CFrame.new(0, y, -1.47), if row % 2 == 0 then rgb(66, 70, 80) else rgb(88, 92, 104))
		if row % 2 == 0 then
			Kit.text(server, FRONT, { { Text = "| | | | | | | | | | | |", Color = rgb(24, 26, 32), Align = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.05, 0.15), Size = UDim2.fromScale(0.7, 0.7) } })
		else
			Kit.neon(ctx.Decor, Vector3.new(2, 0.12, 0.04), base * CFrame.new(-0.4, y - 0.15, -1.54), color, 0.2)
		end
		Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.16, 0.16, 0.04), base * CFrame.new(1.3, y + 0.15, -1.54), leds[row % 3 + 1]))
	end
	-- Cable bundles down the back
	for index, cableColor in { CYAN, YELLOW, PINK } do
		Kit.cylinder(ctx.Decor, "Cables", 7.6, 0.25, base * CFrame.new(-1.3 + index * 0.35, 4.8, 1.93), cableColor)
	end
	return rack
end

-- Lounge and food ------------------------------------------------------------------

-- Energy drink machine: 4.4 wide, 3 deep, 7.4 tall. Cans line up behind lit
-- glass under the brand sign, with a price screen, keypad and pickup flap.
function Props.vendingMachine(ctx, x, z, rot, color, label)
	color = color or LIME
	label = label or "FRAG FUEL"
	local base = Kit.at(ctx, x, 0, z, rot)
	local body = Kit.part(ctx.Structure, "VendingMachine", Vector3.new(4.4, 7.4, 2.4), base * CFrame.new(0, 3.7, 0.3), rgb(24, 24, 30), M.Metal)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Kit.text(body, face, { line(label, color, 0.05, 0.1) })
	end
	local shell = rgb(38, 40, 48)
	Kit.part(ctx.Decor, "MachineTrim", Vector3.new(0.2, 6.1, 0.6), base * CFrame.new(-2.1, 3.05, -1.2), shell, M.Metal)
	Kit.part(ctx.Decor, "MachinePanel", Vector3.new(1.4, 6.1, 0.6), base * CFrame.new(1.5, 3.05, -1.2), shell, M.Metal)
	Kit.part(ctx.Decor, "MachineBottom", Vector3.new(2.8, 1.5, 0.6), base * CFrame.new(-0.6, 0.75, -1.2), rgb(64, 66, 76), M.Metal)
	local flap = Kit.part(ctx.Decor, "PickupFlap", Vector3.new(2.2, 0.55, 0.06), base * CFrame.new(-0.6, 0.85, -1.52), rgb(12, 12, 14))
	Kit.text(flap, FRONT, { line("PUSH", rgb(110, 112, 122), 0.2, 0.6, Enum.Font.GothamBold) })
	local sign = Kit.neon(ctx.Decor, Vector3.new(4.4, 1.3, 0.6), base * CFrame.new(0, 6.75, -1.2), color)
	Kit.text(sign, FRONT, { line(label, BLACK, 0.08, 0.58), line("ENERGY DRINK", BLACK, 0.68, 0.22, Enum.Font.GothamBold) })
	Kit.part(ctx.Decor, "MachineGlass", Vector3.new(2.8, 4.6, 0.08), base * CFrame.new(-0.6, 3.8, -1.46), rgb(210, 232, 255), M.Glass, 0.7)
	local backlight = Kit.neon(ctx.Decor, Vector3.new(2.8, 4.6, 0.05), base * CFrame.new(-0.6, 3.8, -0.93), rgb(200, 230, 245), 0.55)
	Kit.light(backlight, color, 14, 1)
	local canColors = { color, PINK, CYAN }
	for row = 0, 2 do
		local y = 1.55 + row * 1.5
		Kit.part(ctx.Decor, "Shelf", Vector3.new(2.8, 0.08, 0.5), base * CFrame.new(-0.6, y, -1.17), STEEL, M.Metal)
		for column = 0, 3 do
			Kit.cylinder(ctx.Decor, "Can", 0.95, 0.5, base * CFrame.new(-1.65 + column * 0.7, y + 0.52, -1.17), canColors[row + 1])
		end
	end
	screen(ctx.Decor, Vector3.new(0.9, 0.4, 0.05), base * CFrame.new(1.5, 5.4, -1.52), rgb(10, 30, 20), { line("3 CR", LIME, 0.1, 0.8) })
	local keypad = Kit.part(ctx.Decor, "Keypad", Vector3.new(0.8, 1, 0.06), base * CFrame.new(1.5, 4.4, -1.52), rgb(64, 66, 76), M.Metal)
	Kit.text(keypad, FRONT, { line("1 2 3\n4 5 6\n7 8 9", WHITE, 0.08, 0.84, Enum.Font.GothamBold) })
	Kit.neon(ctx.Decor, Vector3.new(0.12, 0.4, 0.06), base * CFrame.new(1.5, 3.5, -1.52), YELLOW)
	return body
end

-- Upright arcade cabinet: 3.2 wide, 2.7 deep, 7.8 tall, with a lit marquee,
-- a screen, two joysticks with buttons and a coin door
function Props.arcadeCabinet(ctx, x, z, rot, color, title)
	color = color or PURPLE
	title = title or "BOT BLASTER"
	local base = Kit.at(ctx, x, 0, z, rot)
	local cabinet = Kit.part(ctx.Structure, "ArcadeCabinet", Vector3.new(3, 3.3, 2.6), base * CFrame.new(0, 1.65, 0.2), BLACK)
	local top = Kit.part(ctx.Structure, "ArcadeTop", Vector3.new(3, 3.3, 1.9), base * CFrame.new(0, 5.15, 0.55), BLACK)
	Kit.text(top, BACK, { { Text = "| | | | | | | |", Color = rgb(60, 60, 72), Position = UDim2.fromScale(0.15, 0.1), Size = UDim2.fromScale(0.7, 0.25) } })
	Kit.part(ctx.Decor, "Marquee", Vector3.new(3, 1, 2.3), base * CFrame.new(0, 7.3, 0.35), BLACK)
	local marquee = Kit.neon(ctx.Decor, Vector3.new(2.8, 0.8, 0.06), base * CFrame.new(0, 7.3, -0.83), color)
	Kit.text(marquee, FRONT, { line(title, rgb(20, 12, 30), 0.12, 0.76, Enum.Font.Arcade) })
	Kit.light(marquee, color, 10, 0.8)
	Kit.part(ctx.Decor, "Bezel", Vector3.new(2.7, 2.3, 0.1), base * CFrame.new(0, 5, -0.45), rgb(12, 12, 16))
	screen(ctx.Decor, Vector3.new(2.4, 1.9, 0.05), base * CFrame.new(0, 5, -0.52), rgb(14, 10, 40), {
		line(title, YELLOW, 0.14, 0.3, Enum.Font.Arcade),
		line("INSERT COIN", WHITE, 0.62, 0.18, Enum.Font.Arcade),
	})
	-- Side panels follow the cabinet's outline: low front, sloped control
	-- panel, then the tall screen section
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "SideArt", Vector3.new(0.12, 3.5, 2.7), base * CFrame.new(side * 1.56, 1.75, 0.15), color)
		Kit.wedge(ctx.Decor, "SideArt", Vector3.new(0.12, 0.8, 0.7), base * CFrame.new(side * 1.56, 3.9, -0.85), color)
		Kit.part(ctx.Decor, "SideArt", Vector3.new(0.12, 4.3, 2), base * CFrame.new(side * 1.56, 5.65, 0.5), color)
	end
	Kit.part(ctx.Decor, "CoinDoor", Vector3.new(1.3, 1.5, 0.06), base * CFrame.new(0, 1.7, -1.13), rgb(60, 60, 68), M.Metal)
	for _, side in { -1, 1 } do
		Kit.neon(ctx.Decor, Vector3.new(0.18, 0.4, 0.05), base * CFrame.new(side * 0.3, 1.95, -1.17), rgb(255, 120, 40))
	end
	Kit.neon(ctx.Decor, Vector3.new(3, 0.15, 0.06), base * CFrame.new(0, 0.1, -1.13), color)
	-- Control panel, tipped toward the player, with a stick and two buttons each
	local deck = base * CFrame.new(0, 3.45, -0.55) * CFrame.Angles(math.rad(-12), 0, 0)
	Kit.part(ctx.Decor, "ControlPanel", Vector3.new(3, 0.3, 1.3), deck, rgb(44, 44, 54))
	for _, spec in { { -1.05, PINK, CYAN }, { 0.3, YELLOW, LIME } } do
		Kit.cylinder(ctx.Decor, "Joystick", 0.5, 0.1, deck * CFrame.new(spec[1], 0.4, -0.05), BLACK)
		Kit.ball(ctx.Decor, "Joystick", 0.32, deck * CFrame.new(spec[1], 0.68, -0.05), RED)
		for index = 1, 2 do
			Kit.cylinder(ctx.Decor, "Button", 0.12, 0.26, deck * CFrame.new(spec[1] + 0.15 + index * 0.3, 0.18, -0.05), spec[index + 1])
		end
	end
	return cabinet
end

-- Lounge couch: `length` wide (default 7) and 2.9 deep, with seat and back
-- cushions, rolled arms and two pillows. You sit facing -Z.
function Props.couch(ctx, x, z, rot, color, length)
	color = color or rgb(74, 62, 120)
	length = math.max(length or 7, 3)
	local base = Kit.at(ctx, x, 0, z, rot)
	local frame = darker(color, 0.35)
	local couch = Kit.part(ctx.Structure, "Couch", Vector3.new(length, 1, 2.9), base * CFrame.new(0, 0.75, 0), frame, M.Fabric)
	-- LED strip around the bottom
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(length + 0.08, 0.08, 2.98), base * CFrame.new(0, 0.3, 0), PINK), PINK, 8, 0.8)
	Kit.part(ctx.Structure, "CouchBack", Vector3.new(length, 3, 0.6), base * CFrame.new(0, 1.75, 1.15), frame, M.Fabric)
	local seats = math.max(1, math.floor((length - 1.4) / 1.8 + 0.5))
	local width = (length - 1.4) / seats
	for index = 1, seats do
		local cx = -(length - 1.4) / 2 + width * (index - 0.5)
		Kit.part(ctx.Decor, "Cushion", Vector3.new(width - 0.06, 0.55, 2.2), base * CFrame.new(cx, 1.5, -0.25), color, M.Fabric)
		Kit.part(ctx.Decor, "BackCushion", Vector3.new(width - 0.06, 1.6, 0.55), base * CFrame.new(cx, 2.55, 0.6) * CFrame.Angles(math.rad(12), 0, 0), color, M.Fabric)
	end
	for _, side in { -1, 1 } do
		local sx = side * (length / 2 - 0.35)
		Kit.part(ctx.Structure, "CouchArm", Vector3.new(0.7, 1.9, 2.9), base * CFrame.new(sx, 1.2, 0), frame, M.Fabric)
		tube(ctx.Decor, "CouchArm", 2.9, 0.8, base * CFrame.new(sx, 2.15, 0) * TURN, frame, M.Fabric)
		for _, zSide in { -1, 1 } do
			Kit.part(ctx.Decor, "CouchFoot", Vector3.new(0.3, 0.25, 0.3), base * CFrame.new(sx, 0.125, zSide * 1.2), BLACK, M.Wood)
		end
		local pillow = Kit.part(ctx.Decor, "Pillow", Vector3.new(1.2, 1.2, 0.35), base * CFrame.new(side * (length / 2 - 1.3), 2.4, 0.3) * CFrame.Angles(math.rad(14), 0, math.rad(side * 12)), PINK, M.Fabric)
		Kit.text(pillow, FRONT, { line(if side < 0 then "GG" else "EZ", WHITE, 0.2, 0.6) })
	end
	return couch
end

-- Beanbag: a squashy gaming beanbag about 4 wide and 3.6 tall with a slumped
-- back, piping round the middle and a controller left on the seat. You sit
-- facing -Z.
function Props.beanbag(ctx, x, z, rot, color)
	color = color or PINK
	local base = Kit.at(ctx, x, 0, z, rot)
	local bag = blob(ctx.Structure, "Beanbag", Vector3.new(4, 2, 4), base * CFrame.new(0, 0.95, 0), color)
	blob(ctx.Decor, "BeanbagBack", Vector3.new(3.8, 3.4, 2.2), base * CFrame.new(0, 1.85, 0.95) * CFrame.Angles(math.rad(22), 0, 0), color)
	for _, side in { -1, 1 } do
		blob(ctx.Decor, "BeanbagSide", Vector3.new(1.3, 1.6, 2.6), base * CFrame.new(side * 1.45, 1.55, 0.1), color)
	end
	blob(ctx.Decor, "BeanbagSeat", Vector3.new(2.6, 0.6, 2.4), base * CFrame.new(0, 1.8, -0.35), darker(color, 0.12))
	blob(ctx.Decor, "Piping", Vector3.new(4.06, 0.12, 4.06), base * CFrame.new(0, 0.95, 0), darker(color, 0.45))
	Kit.part(ctx.Decor, "Strap", Vector3.new(0.9, 0.16, 0.35), base * CFrame.new(0, 3.4, 1.55) * CFrame.Angles(math.rad(22), 0, 0), darker(color, 0.45), M.Fabric)
	-- A controller left on the seat
	local pad = base * CFrame.new(0.3, 2.15, -0.7) * CFrame.Angles(0, math.rad(20), 0)
	Kit.part(ctx.Decor, "Controller", Vector3.new(0.9, 0.18, 0.45), pad, BLACK)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "Controller", Vector3.new(0.3, 0.2, 0.45), pad * CFrame.new(side * 0.42, -0.02, 0.15), BLACK)
	end
	Kit.neon(ctx.Decor, Vector3.new(0.5, 0.04, 0.12), pad * CFrame.new(0, 0.1, -0.1), CYAN)
	return bag
end

-- Snack counter: 10 wide and 3.5 tall, with a register, a glass case of
-- snacks, drinks and popcorn, and a lit menu board on posts behind it.
-- Customers stand at the front (-Z).
function Props.snackCounter(ctx, x, z, rot, color, title)
	color = color or YELLOW
	local base = Kit.at(ctx, x, 0, z, rot)
	local counter = Kit.part(ctx.Structure, "SnackCounter", Vector3.new(10, 3.2, 2.4), base * CFrame.new(0, 1.6, 0), rgb(34, 36, 46))
	Kit.part(ctx.Decor, "Countertop", Vector3.new(10.4, 0.25, 2.8), base * CFrame.new(0, 3.325, 0), rgb(236, 236, 242), M.Marble)
	local band = Kit.part(ctx.Decor, "CounterSign", Vector3.new(9.4, 1.3, 0.06), base * CFrame.new(0, 2.05, -1.23), color)
	Kit.text(band, FRONT, { line(title or "SNACKS", BLACK, 0.1, 0.8) })
	for _, y in { 1.3, 2.8 } do
		Kit.neon(ctx.Decor, Vector3.new(9.6, 0.1, 0.08), base * CFrame.new(0, y, -1.24), color)
	end
	-- Register with a screen facing the customer
	Kit.part(ctx.Decor, "Register", Vector3.new(1.4, 0.6, 1.1), base * CFrame.new(-3.8, 3.75, 0.2), DARK)
	Kit.part(ctx.Decor, "CashDrawer", Vector3.new(1.3, 0.25, 0.06), base * CFrame.new(-3.8, 3.62, -0.37), STEEL, M.Metal)
	screen(ctx.Decor, Vector3.new(1.1, 0.7, 0.06), base * CFrame.new(-3.8, 4.45, 0.1) * CFrame.Angles(math.rad(15), 0, 0), rgb(10, 30, 40), {
		line("TOTAL", WHITE, 0.08, 0.36, Enum.Font.GothamBold),
		line("7 CR", CYAN, 0.5, 0.42),
	})
	-- Glass case of donuts and chips
	Kit.part(ctx.Decor, "SnackCase", Vector3.new(3.2, 1.3, 1.8), base * CFrame.new(1.2, 4.1, 0.1), rgb(200, 230, 255), M.Glass, 0.6)
	for index = 0, 2 do
		Kit.cylinder(ctx.Decor, "Donut", 0.22, 0.65, base * CFrame.new(0.1 + index * 0.6, 3.56, -0.3), PINK)
	end
	for index, bagColor in { RED, CYAN } do
		Kit.part(ctx.Decor, "Chips", Vector3.new(0.6, 0.8, 0.22), base * CFrame.new(0.3 + index * 0.9, 3.85, 0.45) * CFrame.Angles(math.rad(10), 0, 0), bagColor)
	end
	for _, spot in { { 3.9, 3.75 }, { 4.3, 3.75 }, { 4.1, 4.35 } } do
		Kit.cylinder(ctx.Decor, "Can", 0.6, 0.36, base * CFrame.new(spot[1], spot[2], -0.5), LIME, M.Metal)
	end
	Kit.cylinder(ctx.Decor, "Popcorn", 0.9, 0.7, base * CFrame.new(-1.8, 3.9, -0.5), RED)
	Kit.ball(ctx.Decor, "Popcorn", 0.72, base * CFrame.new(-1.8, 4.42, -0.5), rgb(255, 240, 180))
	-- Menu board on two posts behind the counter
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "MenuPost", Vector3.new(0.3, 9.4, 0.3), base * CFrame.new(side * 4.2, 4.7, 1.45), DARK, M.Metal)
	end
	local board = Kit.part(ctx.Decor, "MenuBoard", Vector3.new(8, 3.4, 0.25), base * CFrame.new(0, 7.6, 1.45), rgb(18, 18, 24))
	local lines = { line("MENU", color, 0.04, 0.22) }
	for index, item in { { "NACHOS", "5 CR" }, { "PIZZA SLICE", "8 CR" }, { "FRAG FUEL", "3 CR" }, { "CHIPS", "2 CR" } } do
		local top = 0.3 + (index - 1) * 0.17
		table.insert(lines, { Text = item[1], Color = WHITE, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.07, top), Size = UDim2.fromScale(0.6, 0.13) })
		table.insert(lines, { Text = item[2], Color = color, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.63, top), Size = UDim2.fromScale(0.3, 0.13) })
	end
	Kit.text(board, FRONT, lines)
	for _, y in { 5.8, 9.4 } do
		Kit.neon(ctx.Decor, Vector3.new(8.2, 0.2, 0.35), base * CFrame.new(0, y, 1.45), color)
	end
	Kit.light(board, color, 16, 0.8)
	return counter
end

-- A trophy cup: base block, stem, round bowl and rim, `scale` times 2.2 tall
local function trophyCup(parent, cframe, scale, color, handles)
	Kit.part(parent, "TrophyBase", Vector3.new(0.9, 0.45, 0.9) * scale, cframe * CFrame.new(0, 0.225 * scale, 0), BLACK)
	Kit.cylinder(parent, "Trophy", 0.5 * scale, 0.25 * scale, cframe * CFrame.new(0, 0.7 * scale, 0), color, M.Metal)
	Kit.ball(parent, "Trophy", scale, cframe * CFrame.new(0, 1.35 * scale, 0), color, M.Metal)
	Kit.cylinder(parent, "Trophy", 0.35 * scale, scale, cframe * CFrame.new(0, 1.8 * scale, 0), color, M.Metal)
	if handles then
		for _, side in { -1, 1 } do
			Kit.part(parent, "TrophyHandle", Vector3.new(0.15, 0.6, 0.15) * scale, cframe * CFrame.new(side * 0.62 * scale, 1.45 * scale, 0), color, M.Metal)
		end
	end
end

-- Trophy case: a glass cabinet 6 wide, 7 tall and 2.5 deep holding gold,
-- silver and bronze cups, a star award, a medal and an MVP plaque
function Props.trophyCase(ctx, x, z, rot, color)
	color = color or rgb(120, 24, 44)
	local base = Kit.at(ctx, x, 0, z, rot)
	local wood = rgb(70, 46, 30)
	local glass = rgb(225, 238, 255)
	local cabinet = Kit.part(ctx.Structure, "TrophyCase", Vector3.new(6, 1.6, 2.2), base * CFrame.new(0, 0.8, 0), wood, M.Wood)
	local label = Kit.part(ctx.Decor, "CaseLabel", Vector3.new(3, 0.55, 0.06), base * CFrame.new(0, 0.85, -1.13), GOLD, M.Metal)
	Kit.text(label, FRONT, { line("HALL OF FAME", rgb(50, 30, 10), 0.1, 0.8) })
	Kit.part(ctx.Decor, "CaseBack", Vector3.new(6, 5, 0.2), base * CFrame.new(0, 4.1, 1), wood, M.Wood)
	Kit.part(ctx.Decor, "Velvet", Vector3.new(5.6, 4.9, 0.05), base * CFrame.new(0, 4.1, 0.88), color, M.Fabric)
	Kit.part(ctx.Decor, "CaseTop", Vector3.new(6.3, 0.45, 2.45), base * CFrame.new(0, 6.825, 0), wood, M.Wood)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(5.6, 0.08, 0.15), base * CFrame.new(0, 6.55, -0.6), rgb(255, 236, 200)), rgb(255, 230, 190), 10, 1)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "CasePost", Vector3.new(0.25, 5, 0.25), base * CFrame.new(side * 2.875, 4.1, -0.975), wood, M.Wood)
		Kit.part(ctx.Decor, "CaseGlass", Vector3.new(0.08, 5, 1.9), base * CFrame.new(side * 2.96, 4.1, 0), glass, M.Glass, 0.8)
	end
	Kit.part(ctx.Decor, "CaseGlass", Vector3.new(5.5, 5, 0.08), base * CFrame.new(0, 4.1, -1.02), glass, M.Glass, 0.8)
	Kit.part(ctx.Decor, "CaseShelf", Vector3.new(5.6, 0.08, 1.8), base * CFrame.new(0, 4.4, 0), glass, M.Glass, 0.4)
	-- Bottom: the big gold cup between silver and bronze
	trophyCup(ctx.Decor, base * CFrame.new(0, 1.6, 0.1), 1.2, GOLD, true)
	trophyCup(ctx.Decor, base * CFrame.new(-1.7, 1.6, 0.1), 0.9, rgb(205, 210, 220))
	trophyCup(ctx.Decor, base * CFrame.new(1.7, 1.6, 0.1), 0.9, rgb(205, 125, 70))
	-- Top shelf: star award, a medal hung on the back, MVP plaque
	Kit.part(ctx.Decor, "TrophyBase", Vector3.new(0.7, 0.3, 0.7), base * CFrame.new(-1.6, 4.59, 0.1), BLACK)
	Kit.cylinder(ctx.Decor, "Trophy", 0.9, 0.2, base * CFrame.new(-1.6, 5.19, 0.1), GOLD, M.Metal)
	for _, turn in { 0, 45 } do
		Kit.part(ctx.Decor, "Star", Vector3.new(0.75, 0.75, 0.12), base * CFrame.new(-1.6, 5.95, 0.1) * CFrame.Angles(0, 0, math.rad(turn)), GOLD, M.Metal)
	end
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "Ribbon", Vector3.new(0.16, 0.8, 0.03), base * CFrame.new(side * 0.13, 5.6, 0.86) * CFrame.Angles(0, 0, math.rad(side * -20)), if side < 0 then PINK else CYAN)
	end
	tube(ctx.Decor, "Medal", 0.08, 0.6, base * CFrame.new(0, 5.05, 0.84) * TURN, GOLD, M.Metal)
	local plaque = Kit.part(ctx.Decor, "Plaque", Vector3.new(1, 1.2, 0.12), base * CFrame.new(1.6, 5.05, 0.6) * CFrame.Angles(math.rad(10), 0, 0), wood, M.Wood)
	Kit.text(plaque, FRONT, { line("MVP", GOLD, 0.1, 0.5), line("SEASON 1", WHITE, 0.66, 0.2, Enum.Font.GothamBold) })
	return cabinet
end

-- Esports stage ---------------------------------------------------------------------

-- Jumbotron: an 18 x 10.4 screen, its bottom edge `height` up (default 10),
-- standing on two legs (18 x 5 footprint). Give `ceiling` (the ceiling's
-- height) to hang it from two rods instead. Shows a big title with a line
-- under it, plus a LIVE badge and a ticker along the bottom.
function Props.jumbotron(ctx, x, z, rot, title, subtitle, color, height, ceiling)
	color = color or RED
	height = math.max(height or 10, 2)
	local base = Kit.at(ctx, x, 0, z, rot)
	local frameColor = rgb(32, 34, 42)
	for _, side in { -1, 1 } do
		if ceiling then
			local drop = math.max(0.2, ceiling - height - 10.4)
			Kit.part(ctx.Decor, "JumboRod", Vector3.new(0.4, drop, 0.4), base * CFrame.new(side * 6.5, height + 10.4 + drop / 2, 0.6), STEEL, M.Metal)
		else
			Kit.part(ctx.Structure, "JumboLeg", Vector3.new(1.4, height + 1, 1.4), base * CFrame.new(side * 6.5, (height + 1) / 2, 0.6), frameColor, M.Metal)
			Kit.part(ctx.Structure, "JumboFoot", Vector3.new(3, 0.5, 4.8), base * CFrame.new(side * 6.5, 0.25, 1.3), frameColor, M.DiamondPlate)
			Kit.wedge(ctx.Structure, "JumboBrace", Vector3.new(0.6, 3, 2.4), base * CFrame.new(side * 6.5, 2, 2.5) * CFrame.Angles(0, math.pi, 0), frameColor, M.Metal)
			Kit.neon(ctx.Decor, Vector3.new(0.12, height - 1, 0.12), base * CFrame.new(side * 6.5, height / 2, -0.13), color)
		end
	end
	local housing = Kit.part(ctx.Decor, "Jumbotron", Vector3.new(18, 10.4, 1.4), base * CFrame.new(0, height + 5.2, 0.6), frameColor, M.Metal)
	for _, y in { 2.6, 7.8 } do
		Kit.part(ctx.Decor, "JumboBeam", Vector3.new(16, 0.7, 0.6), base * CFrame.new(0, height + y, 1.6), rgb(96, 100, 112), M.DiamondPlate)
	end
	screen(ctx.Decor, Vector3.new(17, 9.4, 0.1), base * CFrame.new(0, height + 5.2, -0.15), rgb(8, 10, 24), {
		line(title or "BANNED", color, 0.24, 0.38),
		line(subtitle or "RAGE_H4X0R got caught", WHITE, 0.64, 0.12, Enum.Font.GothamBold),
	})
	local live = Kit.neon(ctx.Decor, Vector3.new(2.4, 0.9, 0.08), base * CFrame.new(-6.6, height + 9.1, -0.24), RED)
	Kit.text(live, FRONT, { line("LIVE", WHITE, 0.1, 0.8) })
	local ticker = Kit.neon(ctx.Decor, Vector3.new(17, 1.1, 0.08), base * CFrame.new(0, height + 1.2, -0.24), color)
	Kit.text(ticker, FRONT, { line("EARN ESP  |  CHEAT YOUR WAY TO THE TOP", BLACK, 0.15, 0.7, Enum.Font.GothamBold) })
	for _, y in { height - 0.15, height + 10.55 } do
		Kit.neon(ctx.Decor, Vector3.new(18.2, 0.3, 1.5), base * CFrame.new(0, y, 0.6), color)
	end
	Kit.light(housing, color, 30, 1, "SurfaceLight", FRONT)
	return housing
end

-- Stage truss arch: two square truss towers and a beam across the top with
-- stage lights hanging from it. `width` is between the towers (default 24)
-- and `height` is how tall the towers are (default 14).
function Props.stageTruss(ctx, x, z, rot, width, height, color)
	width = math.max(width or 24, 6)
	height = math.max(height or 14, 4)
	color = color or PINK
	local base = Kit.at(ctx, x, 0, z, rot)
	local metal = rgb(185, 188, 196)
	local half = 0.65 -- half the truss's thickness
	local function point(lx, y, lz)
		return base * Vector3.new(lx, y, lz)
	end
	local corners = { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }
	local block
	for _, side in { -1, 1 } do
		local cx = side * width / 2
		Kit.part(ctx.Decor, "TrussBase", Vector3.new(2.2, 0.3, 2.2), base * CFrame.new(cx, 0.15, 0), DARK, M.Metal)
		for _, corner in corners do
			rod(ctx.Decor, "TrussTube", point(cx + corner[1] * half, 0.3, corner[2] * half), point(cx + corner[1] * half, height, corner[2] * half), 0.22, metal, M.Metal)
		end
		-- Zigzag braces up the front face
		local steps = math.max(2, math.floor(height / 3))
		for step = 0, steps - 1 do
			local flip = if step % 2 == 0 then 1 else -1
			local y1 = 0.3 + step * (height - 0.3) / steps
			local y2 = 0.3 + (step + 1) * (height - 0.3) / steps
			rod(ctx.Decor, "TrussBrace", point(cx - flip * half, y1, -half), point(cx + flip * half, y2, -half), 0.12, metal, M.Metal)
		end
		block = Kit.part(ctx.Decor, "TrussCorner", Vector3.new(1.6, 1.6, 1.6), base * CFrame.new(cx, height + 0.8, 0), metal, M.Metal)
	end
	-- The beam across the top, between the corner blocks
	local span = width / 2 - 0.8
	local top = height + 0.8
	for _, corner in corners do
		rod(ctx.Decor, "TrussTube", point(-span, top + corner[1] * half, corner[2] * half), point(span, top + corner[1] * half, corner[2] * half), 0.22, metal, M.Metal)
	end
	local bays = math.max(2, math.floor(width / 3))
	for bay = 0, bays - 1 do
		local flip = if bay % 2 == 0 then 1 else -1
		local x1 = -span + bay * 2 * span / bays
		local x2 = -span + (bay + 1) * 2 * span / bays
		rod(ctx.Decor, "TrussBrace", point(x1, top - flip * half, -half), point(x2, top + flip * half, -half), 0.12, metal, M.Metal)
	end
	Kit.neon(ctx.Decor, Vector3.new(2 * span, 0.15, 0.15), base * CFrame.new(0, top - half - 0.1, -half - 0.05), color)
	-- Stage lights hang under the beam, aimed down and toward the front
	for index, along in { -0.35, -0.12, 0.12, 0.35 } do
		local lightColor = if index % 2 == 0 then WHITE else color
		local mount = base * CFrame.new(along * width, top - half - 0.55, 0)
		local aim = CFrame.lookAt(mount.Position, mount * Vector3.new(0, -1, -0.8)) * TURN
		tube(ctx.Decor, "StageLight", 1.2, 0.8, aim, BLACK, M.Metal)
		Kit.light(glowDisc(ctx.Decor, 0.08, 0.7, aim * CFrame.new(0.62, 0, 0), lightColor), lightColor, 30, 2, "SpotLight", Enum.NormalId.Right)
	end
	return block
end

-- Bleachers: rows of stepped seats you can stand on, lowest row at the front
-- (-Z). Each row is 1.4 up and 2.6 deep; `length` runs along X. 4 rows and 20
-- long by default.
function Props.bleachers(ctx, x, z, rot, rows, length, color)
	rows = math.max(math.floor(rows or 4), 1)
	length = math.max(length or 20, 4)
	color = color or PINK
	local base = Kit.at(ctx, x, 0, z, rot)
	local rise, tread = 1.4, 2.6
	local depth = rows * tread
	local topY = rows * rise
	local highest
	for row = 0, rows - 1 do
		local stepTop = (row + 1) * rise
		local rowZ = -depth / 2 + tread / 2 + row * tread
		highest = Kit.part(ctx.Structure, "Bleachers", Vector3.new(length, stepTop, tread), base * CFrame.new(0, stepTop / 2, rowZ), rgb(84, 88, 98), M.Concrete)
		if row == rows - 1 then
			Kit.text(highest, BACK, { line("EARN ESP", color, 0.2, 0.6) })
		end
		local seatColor = if row % 2 == 0 then color else darker(color, 0.35)
		Kit.part(ctx.Decor, "BleacherSeat", Vector3.new(length - 1.2, 0.35, 1), base * CFrame.new(0, stepTop + 0.175, rowZ + 0.6), seatColor)
		Kit.neon(ctx.Decor, Vector3.new(length, 0.1, 0.06), base * CFrame.new(0, stepTop - 0.1, rowZ - tread / 2 - 0.03), color)
	end
	-- Side walls follow the steps, with a glowing strip up the slope
	for _, side in { -1, 1 } do
		local sx = side * (length / 2 + 0.25)
		Kit.part(ctx.Structure, "BleacherSide", Vector3.new(0.5, rise, depth), base * CFrame.new(sx, rise / 2, 0), DARK, M.Metal)
		Kit.wedge(ctx.Structure, "BleacherSide", Vector3.new(0.5, topY, depth), base * CFrame.new(sx, rise + topY / 2, 0), DARK, M.Metal)
		local strip = rod(ctx.Decor, "BleacherGlow", base * Vector3.new(sx, rise, -depth / 2), base * Vector3.new(sx, rise + topY, depth / 2), 0.16, color, M.Neon)
		strip.CastShadow = false
	end
	-- Safety rail along the back of the top row
	local railZ = depth / 2 - 0.15
	for _, px in { -length / 2 + 0.4, 0, length / 2 - 0.4 } do
		Kit.part(ctx.Decor, "RailPost", Vector3.new(0.25, 3, 0.25), base * CFrame.new(px, topY + 1.5, railZ), STEEL, M.Metal)
	end
	for _, y in { 1.5, 3 } do
		Kit.part(ctx.Decor, "Rail", Vector3.new(length, 0.2, 0.2), base * CFrame.new(0, topY + y, railZ), STEEL, M.Metal)
	end
	return highest
end

-- Caster desk: a 9 wide desk with angled wings and a lit logo facing the crowd
-- (-Z). Two casters sit behind it with a mic and a monitor each.
function Props.casterDesk(ctx, x, z, rot, color, label)
	color = color or PINK
	local base = Kit.at(ctx, x, 0, z, rot)
	local shell = rgb(26, 27, 34)
	local topColor = rgb(232, 234, 240)
	local desk = Kit.part(ctx.Structure, "CasterDesk", Vector3.new(6, 3.2, 2.2), base * CFrame.new(0, 1.6, 0), shell)
	Kit.part(ctx.Decor, "DeskTop", Vector3.new(6.2, 0.25, 2.6), base * CFrame.new(0, 3.32, 0.05), topColor)
	Kit.neon(ctx.Decor, Vector3.new(6, 0.12, 0.05), base * CFrame.new(0, 0.3, -1.13), color)
	for _, side in { -1, 1 } do
		-- Each wing swings back from the front corner of the middle section
		local wing = base * CFrame.new(side * 3, 0, -1.1) * CFrame.Angles(0, math.rad(-side * 25), 0) * CFrame.new(side * 1.3, 0, 1.1)
		Kit.part(ctx.Structure, "CasterDesk", Vector3.new(2.6, 3.2, 2.2), wing * CFrame.new(0, 1.6, 0), shell)
		Kit.part(ctx.Decor, "DeskTop", Vector3.new(2.8, 0.25, 2.6), wing * CFrame.new(side * 0.1, 3.32, 0.05), topColor)
		Kit.neon(ctx.Decor, Vector3.new(2.4, 0.12, 0.05), wing * CFrame.new(0, 2.9, -1.13), color)
		Kit.neon(ctx.Decor, Vector3.new(2.4, 0.12, 0.05), wing * CFrame.new(0, 0.3, -1.13), color)
	end
	Kit.neon(ctx.Decor, Vector3.new(4.8, 2, 0.05), base * CFrame.new(0, 1.7, -1.12), color)
	local logo = Kit.part(ctx.Decor, "Logo", Vector3.new(4.5, 1.7, 0.06), base * CFrame.new(0, 1.7, -1.16), rgb(16, 16, 22))
	Kit.text(logo, FRONT, { line(label or "EARN ESP", color, 0.1, 0.5), line("LIVE CASTERS", WHITE, 0.66, 0.22, Enum.Font.GothamBold) })
	Kit.light(logo, color, 14, 0.8)
	for _, side in { -1, 1 } do
		-- A mic on a short stand, pointed back at the caster
		Kit.cylinder(ctx.Decor, "MicBase", 0.1, 0.5, base * CFrame.new(side * 1.5, 3.5, 0.5), BLACK, M.Metal)
		Kit.cylinder(ctx.Decor, "MicStand", 0.9, 0.08, base * CFrame.new(side * 1.5, 3.95, 0.5), STEEL, M.Metal)
		tube(ctx.Decor, "Mic", 0.55, 0.24, base * CFrame.new(side * 1.5, 4.45, 0.62) * TURN, BLACK)
		Kit.ball(ctx.Decor, "MicFoam", 0.34, base * CFrame.new(side * 1.5, 4.45, 0.9), color)
		-- A small monitor facing the caster
		local monitor = base * CFrame.new(side * 2.3, 0, -0.2) * CFrame.Angles(0, math.pi + math.rad(side * 15), 0)
		Kit.part(ctx.Decor, "MonitorStand", Vector3.new(0.2, 0.7, 0.15), monitor * CFrame.new(0, 3.75, 0.2), BLACK, M.Metal)
		Kit.part(ctx.Decor, "Monitor", Vector3.new(1.9, 1.15, 0.1), monitor * CFrame.new(0, 4.4, 0.08), BLACK)
		screen(ctx.Decor, Vector3.new(1.75, 1, 0.03), monitor * CFrame.new(0, 4.4, 0.02), rgb(10, 24, 50), {
			line("LIVE", RED, 0.1, 0.35),
			line("RED 3 - 5 BLUE", WHITE, 0.55, 0.3, Enum.Font.GothamBold),
		})
	end
	return desk
end

-- Anti-cheat -------------------------------------------------------------------------

-- Anti-cheat scanner gate: two pillars and a sign beam over a walkway 5 wide
-- and 8.6 tall. Red scan beams fill the gap, but nothing in it is solid.
function Props.scannerGate(ctx, x, z, rot, color)
	color = color or RED
	local base = Kit.at(ctx, x, 0, z, rot)
	local pillar
	for _, side in { -1, 1 } do
		pillar = Kit.part(ctx.Structure, "ScannerPillar", Vector3.new(1.6, 8.6, 2.4), base * CFrame.new(side * 3.3, 4.3, 0), rgb(196, 200, 210))
		Kit.part(ctx.Structure, "ScannerFoot", Vector3.new(1.9, 0.4, 3), base * CFrame.new(side * 3.45, 0.2, 0), DARK, M.Metal)
		Kit.part(ctx.Decor, "Hazard", Vector3.new(1.6, 0.6, 2.46), base * CFrame.new(side * 3.3, 1, 0), YELLOW)
		local emitter = passThrough(Kit.neon(ctx.Decor, Vector3.new(0.1, 7.4, 0.5), base * CFrame.new(side * 2.48, 4.5, 0), color))
		Kit.light(emitter, color, 12, 1)
		Kit.blink(Kit.cylinder(ctx.Decor, "Beacon", 0.5, 0.6, base * CFrame.new(side * 3.3, 10.65, 0), color, M.Neon))
	end
	local header = Kit.part(ctx.Decor, "ScannerSign", Vector3.new(8.4, 1.8, 2.8), base * CFrame.new(0, 9.5, 0), DARK, M.Metal)
	for _, face in { FRONT, BACK } do
		Kit.text(header, face, { line("ANTI-CHEAT", WHITE, 0.08, 0.3, Enum.Font.GothamBold), line("SCANNING...", color, 0.42, 0.5) })
	end
	local scanner = passThrough(Kit.neon(ctx.Decor, Vector3.new(5, 0.1, 1.6), base * CFrame.new(0, 8.55, 0), color))
	Kit.light(scanner, color, 16, 1.5, "SurfaceLight", Enum.NormalId.Bottom)
	-- Scan beams across the gap
	for y = 1.2, 8, 1.35 do
		CollectionService:AddTag(passThrough(Kit.neon(ctx.Decor, Vector3.new(5, 0.08, 0.08), base * CFrame.new(0, y, 0), color)), "Pulse")
	end
	-- Floor plate, with glowing lines where you step in and out
	passThrough(Kit.part(ctx.Decor, "ScanPad", Vector3.new(5, 0.06, 3.2), base * CFrame.new(0, 0.03, 0), rgb(30, 30, 36), M.DiamondPlate))
	for _, side in { -1, 1 } do
		passThrough(Kit.neon(ctx.Decor, Vector3.new(5, 0.05, 0.2), base * CFrame.new(0, 0.05, side * 1.5), color))
	end
	screen(ctx.Decor, Vector3.new(1.2, 0.8, 0.05), base * CFrame.new(-3.3, 5.6, -1.23), rgb(8, 30, 14), { line("SUS 0%", LIME, 0.15, 0.7) })
	screen(ctx.Decor, Vector3.new(1.2, 1.2, 0.05), base * CFrame.new(3.3, 5.4, -1.23), rgb(40, 8, 12), {
		line("CLEAN", LIME, 0.08, 0.36),
		line("CHEATER", RED, 0.56, 0.36),
	})
	return pillar
end

-- Laser fence: posts about every 5 studs along X with glowing beams between
-- them, `length` long (default 16). The beams don't stop people or bullets;
-- the posts do.
function Props.laserFence(ctx, x, z, rot, length, color)
	length = math.max(length or 16, 2)
	color = color or RED
	local base = Kit.at(ctx, x, 0, z, rot)
	local posts = math.max(2, math.floor(length / 5) + 1)
	local gap = length / (posts - 1)
	local first
	for index = 0, posts - 1 do
		local px = -length / 2 + index * gap
		Kit.part(ctx.Decor, "LaserBase", Vector3.new(1.3, 0.3, 1.3), base * CFrame.new(px, 0.15, 0), DARK, M.Metal)
		local post = Kit.part(ctx.Structure, "LaserPost", Vector3.new(0.7, 4.6, 0.7), base * CFrame.new(px, 2.6, 0), rgb(150, 154, 166), M.Metal)
		first = first or post
		Kit.neon(ctx.Decor, Vector3.new(0.74, 3.8, 0.2), base * CFrame.new(px, 2.6, 0), color)
		Kit.part(ctx.Decor, "LaserCap", Vector3.new(0.9, 0.25, 0.9), base * CFrame.new(px, 5.03, 0), DARK, M.Metal)
		Kit.blink(Kit.ball(ctx.Decor, "LaserLight", 0.45, base * CFrame.new(px, 5.25, 0), color, M.Neon))
		if index > 0 then
			for _, y in { 1.1, 2, 2.9, 3.8 } do
				CollectionService:AddTag(passThrough(Kit.neon(ctx.Decor, Vector3.new(gap - 0.7, 0.1, 0.1), base * CFrame.new(px - gap / 2, y, 0), color)), "Pulse")
			end
		end
	end
	local sign = Kit.part(ctx.Decor, "LaserSign", Vector3.new(1.1, 0.9, 0.06), first.CFrame * CFrame.new(0, 0.9, -0.38), YELLOW)
	Kit.text(sign, FRONT, { line("DANGER", BLACK, 0.06, 0.45), line("LASERS", BLACK, 0.55, 0.38, Enum.Font.GothamBold) })
	return first
end

-- Ban hammer statue: a giant hammer with BAN on its head standing on a 7 x 7
-- plinth (the plinth is cover). About 17 tall.
function Props.banHammerStatue(ctx, x, z, rot, color)
	color = color or rgb(210, 30, 45)
	local base = Kit.at(ctx, x, 0, z, rot)
	local stone = rgb(66, 68, 78)
	Kit.part(ctx.Structure, "StatueBase", Vector3.new(7, 0.8, 7), base * CFrame.new(0, 0.4, 0), stone, M.Slate)
	Kit.neon(ctx.Decor, Vector3.new(7.1, 0.12, 7.1), base * CFrame.new(0, 0.74, 0), color)
	local plinth = Kit.part(ctx.Structure, "Plinth", Vector3.new(5, 4.4, 5), base * CFrame.new(0, 3, 0), rgb(46, 48, 56), M.Marble)
	Kit.neon(ctx.Decor, Vector3.new(5.2, 0.2, 5.2), base * CFrame.new(0, 5.1, 0), color)
	Kit.part(ctx.Structure, "PlinthTop", Vector3.new(5.8, 0.6, 5.8), base * CFrame.new(0, 5.5, 0), stone, M.Slate)
	local plaque = Kit.part(ctx.Decor, "Plaque", Vector3.new(3.4, 1.4, 0.12), base * CFrame.new(0, 3.1, -2.56), GOLD, M.Metal)
	Kit.text(plaque, FRONT, { line("THE BAN HAMMER", rgb(50, 30, 10), 0.1, 0.45), line("no warnings, no appeals", rgb(50, 30, 10), 0.62, 0.26, Enum.Font.GothamBold) })
	-- The hammer leans a little, from where the handle meets the plinth
	local hammer = base * CFrame.new(0, 5.8, 0) * CFrame.Angles(0, 0, math.rad(8))
	Kit.cylinder(ctx.Decor, "Socket", 0.6, 1.6, hammer * CFrame.new(0, 0.3, 0), STEEL, M.Metal)
	Kit.cylinder(ctx.Decor, "Handle", 8, 1, hammer * CFrame.new(0, 4, 0), rgb(46, 32, 24), M.Wood)
	Kit.cylinder(ctx.Decor, "Grip", 2.4, 1.12, hammer * CFrame.new(0, 2.6, 0), BLACK, M.Fabric)
	for _, y in { 1.35, 3.85 } do
		Kit.cylinder(ctx.Decor, "GripRing", 0.2, 1.2, hammer * CFrame.new(0, y, 0), color, M.Neon)
	end
	Kit.cylinder(ctx.Decor, "Collar", 0.6, 1.5, hammer * CFrame.new(0, 7.7, 0), STEEL, M.Metal)
	local head = Kit.part(ctx.Decor, "HammerHead", Vector3.new(7.5, 3.4, 3.4), hammer * CFrame.new(0, 9.6, 0), color, M.Metal)
	for _, face in { FRONT, BACK } do
		Kit.text(head, face, { { Text = "BAN", Color = WHITE, Position = UDim2.fromScale(0.16, 0.1), Size = UDim2.fromScale(0.68, 0.8) } })
	end
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "HeadBand", Vector3.new(0.7, 3.7, 3.7), hammer * CFrame.new(side * 3.2, 9.6, 0), GOLD, M.Metal)
		tube(ctx.Decor, "HammerFace", 0.6, 3.2, hammer * CFrame.new(side * 4.05, 9.6, 0), STEEL, M.Metal)
		local lamp = Kit.part(ctx.Decor, "Uplight", Vector3.new(0.8, 0.5, 0.8), base * CFrame.new(side * 2.9, 1.05, -2.9), DARK, M.Metal)
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.6, 0.06, 0.6), lamp.CFrame * CFrame.new(0, 0.28, 0), WHITE), color, 22, 2, "SpotLight", Enum.NormalId.Top)
	end
	return plinth
end

-- Report button: a giant push button on a 3 x 3 pedestal with a flipped-up
-- safety cover and a REPORT sign. The top of the button is 4.6 up.
function Props.reportButton(ctx, x, z, rot, color)
	color = color or rgb(230, 30, 40)
	local base = Kit.at(ctx, x, 0, z, rot)
	Kit.part(ctx.Decor, "ButtonFoot", Vector3.new(3.6, 0.3, 3.6), base * CFrame.new(0, 0.15, 0), DARK, M.Metal)
	local pedestal = Kit.part(ctx.Structure, "ReportButton", Vector3.new(3, 2.9, 3), base * CFrame.new(0, 1.75, 0), rgb(44, 46, 56), M.Metal)
	Kit.part(ctx.Decor, "ButtonPlate", Vector3.new(3.4, 0.35, 3.4), base * CFrame.new(0, 3.375, 0), YELLOW)
	for index = -1, 1 do
		Kit.part(ctx.Decor, "HazardStripe", Vector3.new(0.5, 0.36, 0.05), base * CFrame.new(index * 1.15, 3.375, -1.71), BLACK)
	end
	Kit.cylinder(ctx.Decor, "ButtonRing", 0.4, 2.6, base * CFrame.new(0, 3.75, 0), STEEL, M.Metal)
	Kit.light(Kit.cylinder(ctx.Decor, "ButtonGlow", 0.12, 2.3, base * CFrame.new(0, 3.98, 0), color, M.Neon), color, 12, 1.5)
	Kit.ball(ctx.Decor, "Button", 2, base * CFrame.new(0, 3.6, 0), color)
	local sign = Kit.part(ctx.Decor, "ReportSign", Vector3.new(2.6, 1.3, 0.08), base * CFrame.new(0, 2, -1.54), color)
	Kit.text(sign, FRONT, { line("REPORT", WHITE, 0.08, 0.55), line("PRESS IF SUS", WHITE, 0.68, 0.22, Enum.Font.GothamBold) })
	-- Safety cover, flipped open on its hinge at the back
	Kit.part(ctx.Decor, "Hinge", Vector3.new(2.6, 0.2, 0.2), base * CFrame.new(0, 3.95, 1.35), STEEL, M.Metal)
	Kit.part(ctx.Decor, "SafetyCover", Vector3.new(2.8, 0.1, 2.8), base * CFrame.new(0, 3.95, 1.35) * CFrame.Angles(math.rad(105), 0, 0) * CFrame.new(0, 0, -1.4), rgb(255, 120, 130), M.Glass, 0.5)
	return pedestal
end

-- Judge's bench: a raised wooden bench 12 wide and 5.9 tall facing the court
-- (-Z), with panels, a seal, a nameplate and a gavel. The judge's platform
-- and tall chair sit behind it, so the whole prop is 8.4 deep.
function Props.judgeBench(ctx, x, z, rot, name, color)
	local wood = color or rgb(118, 74, 44)
	local light = wood:Lerp(rgb(255, 220, 170), 0.2)
	local dark = darker(wood, 0.35)
	local base = Kit.at(ctx, x, 0, z, rot)
	local bench = Kit.part(ctx.Structure, "JudgeBench", Vector3.new(12, 5.5, 3), base * CFrame.new(0, 2.75, 0), wood, M.Wood)
	Kit.part(ctx.Decor, "BenchTop", Vector3.new(12.6, 0.35, 3.6), base * CFrame.new(0, 5.675, -0.1), light, M.Wood)
	Kit.part(ctx.Decor, "Skirting", Vector3.new(12.3, 0.5, 3.3), base * CFrame.new(0, 0.25, 0), dark, M.Wood)
	for index = -1, 1 do
		Kit.part(ctx.Decor, "Panel", Vector3.new(3.2, 3.6, 0.12), base * CFrame.new(index * 3.9, 2.9, -1.55), light, M.Wood)
	end
	for _, px in { -5.85, -1.95, 1.95, 5.85 } do
		Kit.part(ctx.Decor, "Pilaster", Vector3.new(0.5, 4.3, 0.3), base * CFrame.new(px, 2.65, -1.6), dark, M.Wood)
	end
	-- Court seal on the middle panel
	tube(ctx.Decor, "Seal", 0.12, 2.4, base * CFrame.new(0, 3, -1.65) * TURN, GOLD, M.Metal)
	tube(ctx.Decor, "Seal", 0.14, 1.9, base * CFrame.new(0, 3, -1.66) * TURN, rgb(140, 20, 30))
	local seal = Kit.part(ctx.Decor, "Seal", Vector3.new(1.3, 0.8, 0.04), base * CFrame.new(0, 3, -1.74), rgb(140, 20, 30))
	Kit.text(seal, FRONT, { line("AC", GOLD, 0.05, 0.9) })
	local plate = Kit.part(ctx.Decor, "Nameplate", Vector3.new(5, 0.7, 0.1), base * CFrame.new(0, 5.12, -1.56), GOLD, M.Metal)
	Kit.text(plate, FRONT, { line(name or "JUDGE MOD", rgb(50, 30, 10), 0.1, 0.8) })
	-- Gavel resting on its block
	local gavel = base * CFrame.new(3, 5.85, -0.6) * CFrame.Angles(0, math.rad(30), 0)
	Kit.cylinder(ctx.Decor, "SoundBlock", 0.25, 1.1, gavel * CFrame.new(0, 0.125, 0), dark, M.Wood)
	tube(ctx.Decor, "Gavel", 1.2, 0.6, gavel * CFrame.new(0, 0.55, 0) * TURN, dark, M.Wood)
	tube(ctx.Decor, "GavelHandle", 1.8, 0.2, gavel * CFrame.new(1, 0.55, 0), light, M.Wood)
	-- Raised platform with a step, and the judge's tall chair
	Kit.part(ctx.Structure, "JudgePlatform", Vector3.new(12, 2.4, 3.4), base * CFrame.new(0, 1.2, 3.2), dark, M.WoodPlanks)
	Kit.part(ctx.Structure, "JudgeStep", Vector3.new(1.6, 1.2, 3.4), base * CFrame.new(6.8, 0.6, 3.2), dark, M.WoodPlanks)
	local leather = rgb(130, 22, 34)
	Kit.part(ctx.Decor, "JudgeChair", Vector3.new(1, 1, 1), base * CFrame.new(0, 2.9, 3.1), BLACK, M.Metal)
	Kit.part(ctx.Decor, "JudgeChair", Vector3.new(2.4, 0.5, 2.2), base * CFrame.new(0, 3.65, 3.1), leather, M.Fabric)
	Kit.part(ctx.Decor, "JudgeChair", Vector3.new(2.6, 5, 0.5), base * CFrame.new(0, 6.1, 4.4), leather, M.Fabric)
	Kit.part(ctx.Decor, "JudgeChair", Vector3.new(2.8, 0.4, 0.6), base * CFrame.new(0, 8.8, 4.4), GOLD, M.Metal)
	return bench
end

-- Pew: a long wooden bench with a tall back, for the court's public seats.
-- `length` runs along X (default 12) and people sit facing -Z. The back is
-- cover, so rows of pews make good cover lines.
function Props.pew(ctx, x, z, rot, length, color)
	length = math.max(length or 12, 4)
	local base = Kit.at(ctx, x, 0, z, rot)
	local trim = darker(WOOD, 0.3)
	local back = Kit.part(ctx.Structure, "Pew", Vector3.new(length, 3.8, 0.35), base * CFrame.new(0, 2.1, 0.95), WOOD, M.Wood)
	Kit.part(ctx.Decor, "PewCap", Vector3.new(length + 0.1, 0.3, 0.6), base * CFrame.new(0, 4.1, 0.95), trim, M.Wood)
	Kit.part(ctx.Structure, "PewSeat", Vector3.new(length, 0.35, 2), base * CFrame.new(0, 1.8, -0.1), WOOD, M.Wood)
	Kit.part(ctx.Decor, "PewCushion", Vector3.new(length - 0.9, 0.15, 1.7), base * CFrame.new(0, 2.05, -0.15), color or rgb(140, 28, 40), M.Fabric)
	Kit.part(ctx.Decor, "PewApron", Vector3.new(length, 0.5, 0.15), base * CFrame.new(0, 1.4, -1.05), trim, M.Wood)
	Kit.part(ctx.Decor, "BookRack", Vector3.new(length - 1, 0.7, 0.35), base * CFrame.new(0, 2.6, 1.3), trim, M.Wood)
	for index, bookColor in { rgb(150, 30, 40), rgb(40, 60, 140), rgb(30, 30, 34) } do
		Kit.part(ctx.Decor, "RuleBook", Vector3.new(0.5, 0.8, 0.18), base * CFrame.new(-length / 2 + index * length / 4, 2.95, 1.3), bookColor)
	end
	for _, side in { -1, 1 } do
		local sx = side * (length / 2 + 0.175)
		Kit.part(ctx.Structure, "PewEnd", Vector3.new(0.35, 3.2, 2.4), base * CFrame.new(sx, 1.6, 0), trim, M.Wood)
		tube(ctx.Decor, "PewArm", 2.4, 0.5, base * CFrame.new(sx, 3.2, 0) * TURN, trim, M.Wood)
		Kit.part(ctx.Decor, "PewPanel", Vector3.new(0.1, 2, 1.6), base * CFrame.new(sx + side * 0.2, 1.55, 0), WOOD, M.Wood)
	end
	if length >= 14 then
		Kit.part(ctx.Decor, "PewLeg", Vector3.new(0.3, 1.6, 1.8), base * CFrame.new(0, 0.8, -0.1), trim, M.Wood)
	end
	return back
end

-- Wanted poster for a wall. (x, z) is a spot on the wall's face; the poster
-- faces -Z, away from the wall, with its middle `height` up (default 5).
-- Shows the cheater's gamertag, what they did and the bounty in Credits.
function Props.wantedPoster(ctx, x, z, rot, gamertag, bounty, crime, height)
	local frame = Kit.at(ctx, x, height or 5, z, rot)
	local ink = rgb(66, 40, 22)
	Kit.part(ctx.Decor, "PosterBack", Vector3.new(3.7, 4.9, 0.04), frame * CFrame.new(0, 0, -0.02), rgb(176, 140, 90))
	local paper = Kit.part(ctx.Decor, "WantedPoster", Vector3.new(3.5, 4.7, 0.04), frame * CFrame.new(0, 0, -0.05), rgb(236, 220, 178))
	Kit.text(paper, FRONT, {
		line("WANTED", ink, 0.03, 0.16, Enum.Font.Antique),
		line("DEAD OR BANNED", ink, 0.19, 0.05, Enum.Font.GothamBold),
		line("FOR " .. string.upper(crime or "aimbot"), ink, 0.6, 0.06, Enum.Font.GothamBold),
		line(gamertag or "Aimbot_Andy", rgb(190, 20, 30), 0.67, 0.1),
		line("REWARD", ink, 0.79, 0.05, Enum.Font.GothamBold),
		line(withCommas(bounty or 5000) .. " CR", ink, 0.85, 0.11),
	})
	-- Mugshot: a noob in shades
	Kit.part(ctx.Decor, "Mugshot", Vector3.new(2, 1.5, 0.02), frame * CFrame.new(0, 0.4, -0.08), rgb(130, 140, 160))
	Kit.part(ctx.Decor, "Mugshot", Vector3.new(1.1, 0.5, 0.02), frame * CFrame.new(0, -0.1, -0.095), rgb(40, 90, 200))
	Kit.part(ctx.Decor, "Mugshot", Vector3.new(0.62, 0.62, 0.02), frame * CFrame.new(0, 0.47, -0.095), rgb(245, 205, 50))
	Kit.part(ctx.Decor, "Mugshot", Vector3.new(0.66, 0.14, 0.02), frame * CFrame.new(0, 0.55, -0.11), BLACK)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "Tape", Vector3.new(0.8, 0.25, 0.02), frame * CFrame.new(side * 1.6, 2.25, -0.08) * CFrame.Angles(0, 0, math.rad(side * -35)), rgb(235, 230, 205), M.SmoothPlastic, 0.15)
	end
	return paper
end

-- Loot crate: a 4.4 x 3.75 x 3.2 supply crate whose glowing seam, stripes
-- and badge use a rarity color (Config.Rarities has them). Pass beam = true
-- for a tall pillar of light above it, so players can spot it from far away.
function Props.lootCrate(ctx, x, z, rot, color, beam)
	color = color or rgb(255, 170, 40)
	local base = Kit.at(ctx, x, 0, z, rot)
	local metal = rgb(44, 48, 58)
	local crate = Kit.part(ctx.Structure, "LootCrate", Vector3.new(4.2, 3, 3), base * CFrame.new(0, 1.5, 0), metal, M.Metal)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Kit.text(crate, face, { line("SUPPLY", color, 0.3, 0.3) })
	end
	Kit.part(ctx.Decor, "CrateLid", Vector3.new(4.4, 0.6, 3.2), base * CFrame.new(0, 3.1, 0), darker(metal, 0.2), M.Metal)
	Kit.wedge(ctx.Decor, "CrateLid", Vector3.new(4.4, 0.35, 1.6), base * CFrame.new(0, 3.575, -0.8), metal, M.Metal)
	Kit.wedge(ctx.Decor, "CrateLid", Vector3.new(4.4, 0.35, 1.6), base * CFrame.new(0, 3.575, 0.8) * CFrame.Angles(0, math.pi, 0), metal, M.Metal)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(4.3, 0.12, 3.1), base * CFrame.new(0, 2.76, 0), color), color, 10, 0.6)
	for _, side in { -1, 1 } do
		Kit.neon(ctx.Decor, Vector3.new(0.2, 2.3, 3.06), base * CFrame.new(side * 1.2, 1.35, 0), color)
		Kit.part(ctx.Decor, "Handle", Vector3.new(0.2, 0.25, 1.4), base * CFrame.new(side * 2.2, 2.1, 0), BLACK, M.Metal)
		Kit.part(ctx.Decor, "Latch", Vector3.new(0.3, 0.55, 0.1), base * CFrame.new(side * 0.6, 2.76, -1.62), STEEL, M.Metal)
		for _, zSide in { -1, 1 } do
			Kit.part(ctx.Decor, "CornerGuard", Vector3.new(0.35, 3, 0.35), base * CFrame.new(side * 2, 1.5, zSide * 1.4), STEEL, M.Metal)
		end
	end
	-- Rarity badge: a glowing diamond on the front
	Kit.neon(ctx.Decor, Vector3.new(0.9, 0.9, 0.08), base * CFrame.new(0, 1.4, -1.52) * CFrame.Angles(0, 0, math.rad(45)), color)
	Kit.part(ctx.Decor, "Badge", Vector3.new(0.5, 0.5, 0.06), base * CFrame.new(0, 1.4, -1.57) * CFrame.Angles(0, 0, math.rad(45)), metal)
	if beam then
		passThrough(Kit.neon(ctx.Decor, Vector3.new(1.2, 30, 1.2), base * CFrame.new(0, 18.75, 0), color, 0.75))
	end
	return crate
end

return Props
