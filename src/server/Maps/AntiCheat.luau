-- The anti-cheat maps: Anti-Cheat HQ, the anti-cheat team's bright office
-- (scanner gates, a giant ban hammer, glass offices and a server room), and
-- Ban Court, the wooden courtroom where cheaters get judged. Each one sets
-- its size and lighting theme, then places props with the kit and Props.luau.
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local rgb, M = Kit.rgb, Kit.M
local at = Kit.at

local Maps = {}

local FRONT = Enum.NormalId.Front

-- Anti-Cheat HQ: clean white and blue, with red for alarms
local HQ_WHITE = rgb(238, 241, 246)
local HQ_BLUE = rgb(30, 110, 230)
local HQ_NAVY = rgb(24, 36, 68)
local ALARM = rgb(235, 30, 45)
local GLASS = rgb(175, 215, 240)
local SCREEN = rgb(14, 26, 50)
local LEAF = rgb(62, 140, 72)

-- Ban Court: dark wood, marble, gold and a red carpet
local WOOD_DARK = rgb(74, 46, 28)
local WOOD = rgb(112, 70, 42)
local WOOD_LIGHT = rgb(150, 100, 62)
local MARBLE = rgb(228, 222, 210)
local CARPET = rgb(150, 22, 34)
local GOLD = rgb(222, 172, 64)
local WARM = rgb(255, 214, 160)

local WHITE = rgb(245, 245, 248)
local BLACK = rgb(20, 20, 24)
local DARK = rgb(38, 40, 48)
local STEEL = rgb(160, 166, 176)
local YELLOW = rgb(255, 210, 40)
local LIME = rgb(120, 255, 80)
local PINK = rgb(255, 46, 99)

-- Turns a round part (which lies along X) to face along Z, like a disc on a wall
local TURN = CFrame.Angles(0, math.rad(90), 0)

-- Helpers ----------------------------------------------------------------------

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

-- A round part lying along X, the way Roblox cylinders lie
local function tube(parent, name, length, diameter, cframe, color, material)
	local part = Kit.part(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- The same arena with its floor `y` studs higher, so props can stand on a stage
local function lifted(ctx, y)
	local raised = table.clone(ctx)
	raised.Center = ctx.Center + Vector3.new(0, y, 0)
	return raised
end

-- A bar from one arena spot to another, for slanted rails
local function beam(ctx, from, to, width, height, color, material)
	local a, b = ctx.Center + from, ctx.Center + to
	return Kit.part(ctx.Decor, "Rail", Vector3.new(width, height, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color, material)
end

-- Strips along the inside of all four outer walls: baseboards, paint bands,
-- wood paneling
local function wallBand(ctx, y, height, color, material, depth)
	depth = depth or 0.3
	local hx, hz = ctx.HalfX, ctx.HalfZ
	for _, spec in {
		{ Vector3.new(hx * 2, height, depth), 0, hz - depth / 2 },
		{ Vector3.new(hx * 2, height, depth), 0, -hz + depth / 2 },
		{ Vector3.new(depth, height, hz * 2 - depth * 2), hx - depth / 2, 0 },
		{ Vector3.new(depth, height, hz * 2 - depth * 2), -hx + depth / 2, 0 },
	} do
		Kit.part(ctx.Decor, "WallBand", spec[1], at(ctx, spec[2], y, spec[3]), color, material)
	end
end

-- Anti-Cheat HQ pieces ----------------------------------------------------------

-- A glass wall from (x1, z1) to (x2, z2) with a steel cap. Office walls
-- (`office` = true) also get a frosted band at eye height and, with `posts`,
-- steel posts at both ends to frame doorways. Glass is cover you can see
-- through.
local function glassWall(ctx, x1, z1, x2, z2, height, office, posts)
	local from, to = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
	local length = (to - from).Magnitude
	local frame = CFrame.lookAt(ctx.Center + (from + to) / 2, ctx.Center + to)
	local pane = Kit.part(ctx.Structure, "Glass", Vector3.new(0.3, height, length), frame * CFrame.new(0, height / 2, 0), GLASS, M.Glass, 0.6)
	Kit.part(ctx.Decor, "GlassCap", Vector3.new(0.5, 0.3, length), frame * CFrame.new(0, height + 0.15, 0), STEEL, M.Metal)
	if office then
		Kit.part(ctx.Decor, "FrostBand", Vector3.new(0.36, 1.2, length - 1), frame * CFrame.new(0, 4.8, 0), rgb(205, 225, 248), M.SmoothPlastic, 0.25)
	end
	if posts then
		for _, side in { -1, 1 } do
			Kit.part(ctx.Decor, "GlassPost", Vector3.new(0.5, height + 0.3, 0.5), frame * CFrame.new(0, (height + 0.3) / 2, side * (length / 2 - 0.25)), STEEL, M.Metal)
		end
	end
	return pane
end

-- A row of speed gates across X: waist-high steel cabinets with blue light
-- strips, green go lights and red glass wings, `lanes` lanes 3.6 wide. The
-- wings don't stop people or bullets; the cabinets do.
local function speedGates(ctx, x, z, lanes)
	for index = 0, lanes do
		local cx = x + (index - lanes / 2) * 4.8
		local cabinet = Kit.part(ctx.Structure, "SpeedGate", Vector3.new(1.2, 3.4, 4), at(ctx, cx, 1.7, z), rgb(205, 210, 218), M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(1.26, 0.16, 4.06), cabinet.CFrame * CFrame.new(0, 1.2, 0), HQ_BLUE)
		Kit.neon(ctx.Decor, Vector3.new(0.6, 0.6, 0.06), cabinet.CFrame * CFrame.new(0, 0.4, -2.03), LIME)
		if index < lanes then
			local wing = Kit.part(ctx.Decor, "GateWing", Vector3.new(1.7, 1.6, 0.1), at(ctx, cx + 1.45, 2.3, z), ALARM, M.Glass, 0.45)
			wing.CanCollide = false
			wing.CanQuery = false
		end
	end
end

-- A doorway sign hung over a gap in a glass wall, from (x1, z1) to (x2, z2)
local function doorSign(ctx, x1, z1, x2, z2, height, text, color)
	local from, to = Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z2)
	local length = (to - from).Magnitude
	local frame = CFrame.lookAt(ctx.Center + (from + to) / 2, ctx.Center + to)
	Kit.part(ctx.Decor, "DoorHeader", Vector3.new(0.5, 0.3, length), frame * CFrame.new(0, height + 0.15, 0), STEEL, M.Metal)
	local sign = Kit.part(ctx.Decor, "DoorSign", Vector3.new(0.3, 1.3, length - 1), frame * CFrame.new(0, height - 0.65, 0), HQ_NAVY)
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Kit.text(sign, face, { line(text, color, 0.12, 0.76) })
	end
end

-- Office desk, 6 wide: white top on blue side panels, a monitor and keyboard,
-- and an office chair. The chair is at -Z; the screen faces it.
local function officeDesk(ctx, x, z, rot, lines)
	local base = at(ctx, x, 0, z, rot)
	local desk = Kit.part(ctx.Structure, "Desk", Vector3.new(6, 0.3, 3), base * CFrame.new(0, 2.85, 0), HQ_WHITE)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "DeskSide", Vector3.new(0.3, 2.7, 2.8), base * CFrame.new(side * 2.8, 1.35, 0), HQ_BLUE)
	end
	Kit.part(ctx.Decor, "Monitor", Vector3.new(2.8, 1.7, 0.2), base * CFrame.new(0, 4.1, 0.9), BLACK)
	screen(ctx.Decor, Vector3.new(2.6, 1.5, 0.05), base * CFrame.new(0, 4.1, 0.78), SCREEN, lines)
	Kit.part(ctx.Decor, "Keyboard", Vector3.new(2, 0.1, 0.7), base * CFrame.new(0, 3.05, -0.4), DARK)
	local chair = base * CFrame.new(0.2, 0, -2.3)
	Kit.cylinder(ctx.Decor, "ChairPost", 1.7, 0.4, chair * CFrame.new(0, 0.85, 0), DARK, M.Metal)
	Kit.part(ctx.Decor, "ChairSeat", Vector3.new(2, 0.45, 2), chair * CFrame.new(0, 1.9, 0), HQ_NAVY, M.Fabric)
	Kit.part(ctx.Decor, "ChairBack", Vector3.new(1.9, 2.3, 0.35), chair * CFrame.new(0, 3.3, -0.95) * CFrame.Angles(math.rad(-8), 0, 0), HQ_NAVY, M.Fabric)
	return desk
end

-- Office plant: a round white pot with a blue rim and a leafy top, about 6.5 tall
local function plant(ctx, x, z, scale)
	scale = scale or 1
	local pot = Kit.cylinder(ctx.Structure, "Planter", 2.4 * scale, 2.6 * scale, at(ctx, x, 1.2 * scale, z), HQ_WHITE)
	Kit.cylinder(ctx.Decor, "PlanterRim", 0.3 * scale, 2.8 * scale, at(ctx, x, 2.35 * scale, z), HQ_BLUE)
	Kit.ball(ctx.Decor, "Leaves", 3.6 * scale, at(ctx, x, 4.2 * scale, z), LEAF, M.Grass)
	Kit.ball(ctx.Decor, "Leaves", 2.4 * scale, at(ctx, x + 0.8 * scale, 5.6 * scale, z - 0.5 * scale), LEAF:Lerp(rgb(140, 210, 110), 0.3), M.Grass)
	return pot
end

-- Server rack for the back rows (4 x 8.6 x 3.4): a vented door with blue
-- light strips and a blinking status light. The door faces -Z.
local function rack(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local body = Kit.part(ctx.Structure, "Rack", Vector3.new(4, 8.6, 3.4), base * CFrame.new(0, 4.3, 0), rgb(30, 32, 40), M.Metal)
	Kit.part(ctx.Decor, "RackDoor", Vector3.new(3.5, 7.8, 0.1), base * CFrame.new(0, 4.4, -1.73), rgb(58, 62, 74), M.DiamondPlate)
	for _, y in { 3, 5.6 } do
		Kit.neon(ctx.Decor, Vector3.new(2.6, 0.12, 0.05), base * CFrame.new(-0.2, y, -1.8), HQ_BLUE)
	end
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.24, 0.24, 0.05), base * CFrame.new(1.3, 7.3, -1.8), rgb(0, 255, 120)))
	return body
end

-- The giant REPORT button: a red dome on a hazard-striped pedestal (10 x 10
-- footprint, the dome's top 7.6 up) with its safety cover flipped open and a
-- report counter up on posts behind it (15 tall). Faces -Z.
local function giantReportButton(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local hazard = { { Text = "/ / / / / / / / / / / / / /", Color = BLACK, Position = UDim2.fromScale(0, -0.15), Size = UDim2.fromScale(1, 1.3) } }
	local step = Kit.part(ctx.Structure, "ButtonStep", Vector3.new(10, 0.8, 10), base * CFrame.new(0, 0.4, 0), YELLOW, M.SmoothPlastic)
	local pedestal = Kit.part(ctx.Structure, "ReportPedestal", Vector3.new(7, 3.6, 7), base * CFrame.new(0, 2.6, 0), rgb(44, 46, 56), M.Metal)
	local lip = Kit.part(ctx.Decor, "PedestalLip", Vector3.new(7.8, 0.6, 7.8), base * CFrame.new(0, 4.5, 0), YELLOW)
	for _, face in { FRONT, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Back } do
		Kit.text(step, face, hazard)
		Kit.text(lip, face, hazard)
	end
	Kit.cylinder(ctx.Decor, "ButtonRing", 0.9, 6.2, base * CFrame.new(0, 5.2, 0), STEEL, M.Metal)
	Kit.light(Kit.cylinder(ctx.Decor, "ButtonGlow", 0.2, 5.6, base * CFrame.new(0, 5.7, 0), ALARM, M.Neon), ALARM, 22, 2)
	Kit.ball(ctx.Decor, "Button", 5, base * CFrame.new(0, 5.1, 0), rgb(215, 18, 30))
	local sign = Kit.part(ctx.Decor, "ReportSign", Vector3.new(5.6, 2.4, 0.1), base * CFrame.new(0, 2.6, -3.55), ALARM)
	Kit.text(sign, FRONT, { line("REPORT", WHITE, 0.06, 0.58), line("PRESS IF SUS", WHITE, 0.68, 0.24, Enum.Font.GothamBold) })
	-- Safety cover, swung open on its hinge at the back
	Kit.part(ctx.Decor, "SafetyCover", Vector3.new(6, 0.15, 6), base * CFrame.new(0, 5.6, 3.3) * CFrame.Angles(math.rad(100), 0, 0) * CFrame.new(0, 0, -3), rgb(255, 110, 120), M.Glass, 0.45)
	-- Report counter on two posts behind
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "CounterPost", Vector3.new(0.5, 15, 0.5), base * CFrame.new(side * 4.4, 7.5, 4.6), DARK, M.Metal)
	end
	Kit.part(ctx.Decor, "CounterBox", Vector3.new(9.6, 3.4, 0.6), base * CFrame.new(0, 13.6, 4.6), DARK, M.Metal)
	screen(ctx.Decor, Vector3.new(9, 2.9, 0.05), base * CFrame.new(0, 13.6, 4.27), rgb(40, 6, 12), {
		line("REPORTS TODAY", WHITE, 0.08, 0.3, Enum.Font.GothamBold),
		line("99,999+", ALARM, 0.42, 0.5),
	})
	return pedestal
end

-- Loadout scanner by the gates: a conveyor that checks bags and guns for
-- hacks, 3.4 wide and 12 long along Z, with a scan tunnel and a screen
local function loadoutScanner(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local belt = Kit.part(ctx.Structure, "Conveyor", Vector3.new(3.4, 2.8, 12), base * CFrame.new(0, 1.4, 0), rgb(205, 210, 218), M.Metal)
	Kit.part(ctx.Decor, "Belt", Vector3.new(2.9, 0.1, 12.1), base * CFrame.new(0, 2.85, 0), BLACK, M.Fabric)
	local tunnel = Kit.part(ctx.Structure, "ScanTunnel", Vector3.new(4.2, 3.6, 4.6), base * CFrame.new(0, 4.6, 0), HQ_WHITE)
	Kit.text(tunnel, Enum.NormalId.Left, { line("LOADOUT CHECK", HQ_BLUE, 0.3, 0.3) })
	Kit.text(tunnel, Enum.NormalId.Right, { line("LOADOUT CHECK", HQ_BLUE, 0.3, 0.3) })
	for _, side in { -1, 1 } do
		-- Rubber flaps over the tunnel mouths
		Kit.part(ctx.Decor, "Flaps", Vector3.new(2.9, 1.7, 0.1), base * CFrame.new(0, 3.75, side * 2.33), rgb(50, 52, 60), M.Fabric)
	end
	Kit.neon(ctx.Decor, Vector3.new(4.25, 0.3, 4.65), base * CFrame.new(0, 6, 0), HQ_BLUE)
	-- A bag and a gun case riding the belt
	Kit.part(ctx.Decor, "Bag", Vector3.new(1.8, 1, 1.4), base * CFrame.new(0, 3.4, -4), PINK, M.Fabric)
	-- Screen on top of the tunnel, facing the way in
	screen(ctx.Decor, Vector3.new(3, 1.7, 0.1), base * CFrame.new(0, 7.3, -1.2) * CFrame.Angles(math.rad(-10), 0, 0), SCREEN, {
		line("BAG: CLEAN", LIME, 0.08, 0.36, Enum.Font.GothamBold),
		line("MOUSE: AIMBOT", ALARM, 0.56, 0.36, Enum.Font.GothamBold),
	})
	return belt
end

-- Front desk: a long white counter with a navy logo panel, monitors on the
-- staff side (+Z) and a take-a-number machine. Visitors stand at -Z.
local function frontDesk(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local desk = Kit.part(ctx.Structure, "FrontDesk", Vector3.new(12, 3.6, 2.4), base * CFrame.new(0, 1.8, 0), HQ_WHITE)
	Kit.part(ctx.Decor, "Countertop", Vector3.new(12.6, 0.3, 3), base * CFrame.new(0, 3.75, -0.1), rgb(46, 52, 66), M.Marble)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "DeskReturn", Vector3.new(2.4, 3.6, 5), base * CFrame.new(side * 7.2, 1.8, 1.3), HQ_WHITE)
		Kit.part(ctx.Decor, "Countertop", Vector3.new(2.8, 0.3, 5.4), base * CFrame.new(side * 7.2, 3.75, 1.3), rgb(46, 52, 66), M.Marble)
	end
	local logo = Kit.part(ctx.Decor, "Logo", Vector3.new(8, 2, 0.1), base * CFrame.new(0, 1.9, -1.25), HQ_NAVY)
	Kit.text(logo, FRONT, { line("ANTI-CHEAT", WHITE, 0.08, 0.5), line("REPORT A CHEATER HERE", HQ_BLUE, 0.64, 0.24, Enum.Font.GothamBold) })
	for _, side in { -1, 1 } do
		local monitor = base * CFrame.new(side * 3, 0, 0.3) * CFrame.Angles(0, math.pi, 0)
		Kit.part(ctx.Decor, "Monitor", Vector3.new(2.6, 1.6, 0.2), monitor * CFrame.new(0, 4.9, 0), BLACK)
		screen(ctx.Decor, Vector3.new(2.4, 1.4, 0.05), monitor * CFrame.new(0, 4.9, -0.12), SCREEN, {
			line(if side < 0 then "NEW REPORTS" else "SUS METER", WHITE, 0.1, 0.3, Enum.Font.GothamBold),
			line(if side < 0 then "1,337" else "97%", if side < 0 then YELLOW else ALARM, 0.45, 0.45),
		})
	end
	-- Take-a-number machine for visitors
	Kit.part(ctx.Decor, "TicketMachine", Vector3.new(0.8, 1.2, 0.8), base * CFrame.new(-5.4, 4.5, -0.6), ALARM)
	local ticket = Kit.part(ctx.Decor, "NowServing", Vector3.new(1.6, 0.8, 0.1), base * CFrame.new(-5.4, 5.6, -0.25), BLACK)
	Kit.text(ticket, FRONT, { line("NOW 420", ALARM, 0.1, 0.8) })
	return desk
end

-- Modern lobby bench: a navy cushion on a white box with a blue glow under it
local function lobbyBench(ctx, x, z, rot, length)
	local base = at(ctx, x, 0, z, rot)
	local bench = Kit.part(ctx.Structure, "Bench", Vector3.new(length, 1.6, 2.6), base * CFrame.new(0, 0.95, 0), HQ_WHITE)
	Kit.part(ctx.Decor, "BenchCushion", Vector3.new(length - 0.3, 0.5, 2.3), base * CFrame.new(0, 2, 0), HQ_NAVY, M.Fabric)
	Kit.neon(ctx.Decor, Vector3.new(length - 0.6, 0.15, 2.3), base * CFrame.new(0, 0.08, 0), HQ_BLUE)
	return bench
end

-- Ban Court pieces ----------------------------------------------------------------

-- Marble column with a square base and top
local function column(ctx, x, z, height)
	Kit.part(ctx.Structure, "ColumnBase", Vector3.new(3.4, 1, 3.4), at(ctx, x, 0.5, z), MARBLE, M.Marble)
	local shaft = Kit.cylinder(ctx.Structure, "Column", height - 2, 2.4, at(ctx, x, height / 2, z), MARBLE, M.Marble)
	Kit.part(ctx.Decor, "ColumnTop", Vector3.new(3.4, 1, 3.4), at(ctx, x, height - 0.5, z), MARBLE, M.Marble)
	return shaft
end

-- A brass chandelier hung on a chain: a gold ring of candle bulbs around a hub
local function chandelier(ctx, x, z, y, ceiling)
	Kit.part(ctx.Decor, "Chain", Vector3.new(0.25, ceiling - y, 0.25), at(ctx, x, (ceiling + y) / 2, z), GOLD, M.Metal)
	local hub = Kit.ball(ctx.Decor, "ChandelierHub", 1.4, at(ctx, x, y, z), GOLD, M.Metal)
	Kit.cylinder(ctx.Decor, "ChandelierRing", 0.4, 7, at(ctx, x, y - 0.6, z), GOLD, M.Metal)
	for index = 0, 3 do
		local angle = math.rad(45 + index * 90)
		local spot = at(ctx, x + math.cos(angle) * 3.1, y, z + math.sin(angle) * 3.1)
		Kit.cylinder(ctx.Decor, "Candle", 0.8, 0.35, spot, WARM, M.Neon)
	end
	Kit.light(hub, WARM, 48, 1.6)
	return hub
end

-- A long table for one side of the case: a wood top on panel legs, a name
-- card facing the gallery (-Z) and two chairs on the -Z side. Faces +Z.
local function counselTable(ctx, x, z, label, labelColor)
	local base = at(ctx, x, 0, z)
	local top = Kit.part(ctx.Structure, "CounselTable", Vector3.new(9, 0.35, 3.4), base * CFrame.new(0, 3, 0), WOOD_LIGHT, M.Wood)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "TableLeg", Vector3.new(0.6, 2.85, 3), base * CFrame.new(side * 4, 1.42, 0), WOOD_DARK, M.Wood)
		-- Chairs face the judge
		local chair = base * CFrame.new(side * 2.2, 0, -2.6)
		Kit.part(ctx.Decor, "ChairSeat", Vector3.new(2, 0.5, 2), chair * CFrame.new(0, 1.8, 0), CARPET, M.Fabric)
		Kit.part(ctx.Decor, "ChairLegs", Vector3.new(1.8, 1.55, 1.8), chair * CFrame.new(0, 0.78, 0), WOOD_DARK, M.Wood)
		Kit.part(ctx.Decor, "ChairBack", Vector3.new(2, 2.6, 0.35), chair * CFrame.new(0, 3.2, -0.9), WOOD_DARK, M.Wood)
	end
	Kit.part(ctx.Structure, "TablePanel", Vector3.new(7.4, 2, 0.2), base * CFrame.new(0, 1.8, 1.4), WOOD_DARK, M.Wood)
	local card = Kit.part(ctx.Decor, "NameCard", Vector3.new(3.2, 0.8, 0.12), base * CFrame.new(0, 3.6, -1.4) * CFrame.Angles(math.rad(-12), 0, 0), labelColor)
	Kit.text(card, FRONT, { line(label, WHITE, 0.12, 0.76) })
	Kit.part(ctx.Decor, "Laptop", Vector3.new(2, 0.12, 1.4), base * CFrame.new(2, 3.23, 0), DARK, M.Metal)
	return top
end

-- Witness stand: a raised wooden box with a rail, a seat and a mic. The
-- witness faces -Z.
local function witnessStand(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.part(ctx.Structure, "WitnessFloor", Vector3.new(6, 1.2, 6), base * CFrame.new(0, 0.6, 0), WOOD_DARK, M.WoodPlanks)
	local front = Kit.part(ctx.Structure, "WitnessStand", Vector3.new(6, 4.2, 0.6), base * CFrame.new(0, 2.1, -2.7), WOOD, M.Wood)
	Kit.part(ctx.Decor, "WitnessPanel", Vector3.new(4.6, 2.2, 0.1), base * CFrame.new(0, 2.2, -3.03), WOOD_LIGHT, M.Wood)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "WitnessSide", Vector3.new(0.6, 4.2, 4), base * CFrame.new(side * 2.7, 2.1, -0.4), WOOD, M.Wood)
	end
	Kit.part(ctx.Decor, "WitnessRail", Vector3.new(6.4, 0.3, 1), base * CFrame.new(0, 4.35, -2.7), GOLD, M.Metal)
	Kit.part(ctx.Decor, "WitnessSeat", Vector3.new(2.2, 0.5, 2.2), base * CFrame.new(0, 2.8, 0.8), CARPET, M.Fabric)
	Kit.part(ctx.Decor, "WitnessSeatBack", Vector3.new(2.2, 2.8, 0.4), base * CFrame.new(0, 4.2, 1.9), CARPET, M.Fabric)
	Kit.part(ctx.Decor, "MicArm", Vector3.new(0.12, 0.12, 1.4), base * CFrame.new(0.8, 5, -2.2) * CFrame.Angles(math.rad(-25), 0, 0), BLACK, M.Metal)
	Kit.ball(ctx.Decor, "Mic", 0.4, base * CFrame.new(0.8, 5.35, -1.6), BLACK)
	local sign = Kit.part(ctx.Decor, "WitnessSign", Vector3.new(3.6, 0.8, 0.1), base * CFrame.new(0, 3.85, -3.05), GOLD, M.Metal)
	Kit.text(sign, FRONT, { line("WITNESS", rgb(50, 30, 10), 0.1, 0.8) })
	return front
end

-- Jury box: a paneled wooden box with two raised rows of four seats. The
-- jury faces -Z.
local function juryBox(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local front = Kit.part(ctx.Structure, "JuryWall", Vector3.new(20, 3.6, 0.6), base * CFrame.new(0, 1.8, -4.7), WOOD, M.Wood)
	Kit.part(ctx.Decor, "JuryRail", Vector3.new(20.4, 0.3, 0.9), base * CFrame.new(0, 3.75, -4.7), GOLD, M.Metal)
	for index = -1, 1 do
		Kit.part(ctx.Decor, "JuryPanel", Vector3.new(4.6, 2, 0.1), base * CFrame.new(index * 6, 1.8, -5.03), WOOD_LIGHT, M.Wood)
	end
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "JurySide", Vector3.new(0.6, 3.6, 9.8), base * CFrame.new(side * 9.7, 1.8, -0.1), WOOD, M.Wood)
	end
	Kit.part(ctx.Structure, "JuryBack", Vector3.new(20, 4.6, 0.6), base * CFrame.new(0, 2.3, 4.5), WOOD, M.Wood)
	-- Two tiers, the back one higher
	Kit.part(ctx.Structure, "JuryTier", Vector3.new(18.8, 0.6, 4), base * CFrame.new(0, 0.3, -2.2), WOOD_DARK, M.WoodPlanks)
	Kit.part(ctx.Structure, "JuryTier", Vector3.new(18.8, 1.4, 4.4), base * CFrame.new(0, 0.7, 2), WOOD_DARK, M.WoodPlanks)
	for row, y in { 0.6, 1.4 } do
		local rowZ = if row == 1 then -2 else 2.2
		for seat = 0, 3 do
			local sx = -6.6 + seat * 4.4 + (row - 1) * 0.6
			Kit.part(ctx.Decor, "JurySeat", Vector3.new(2.2, 1.6, 2), base * CFrame.new(sx, y + 0.8, rowZ), CARPET, M.Fabric)
			Kit.part(ctx.Decor, "JurySeatBack", Vector3.new(2.2, 2.4, 0.4), base * CFrame.new(sx, y + 2.6, rowZ + 1.1), CARPET, M.Fabric)
		end
	end
	local sign = Kit.part(ctx.Decor, "JurySign", Vector3.new(4, 0.9, 0.1), base * CFrame.new(0, 2.9, -5.06), GOLD, M.Metal)
	Kit.text(sign, FRONT, { line("JURY", rgb(50, 30, 10), 0.1, 0.8) })
	return front
end

-- A tall court flag on a gold-topped pole, the flag hanging down beside it
local function flag(ctx, x, z, color, text)
	Kit.part(ctx.Decor, "FlagBase", Vector3.new(1.6, 0.6, 1.6), at(ctx, x, 0.3, z), GOLD, M.Metal)
	Kit.cylinder(ctx.Structure, "FlagPole", 13, 0.4, at(ctx, x, 6.8, z), WOOD_DARK, M.Wood)
	Kit.ball(ctx.Decor, "FlagTop", 0.9, at(ctx, x, 13.5, z), GOLD, M.Metal)
	local cloth = Kit.part(ctx.Decor, "Flag", Vector3.new(3.6, 6, 0.12), at(ctx, x + (if x < 0 then 2 else -2), 9.6, z), color, M.Fabric)
	for _, face in { FRONT, Enum.NormalId.Back } do
		Kit.text(cloth, face, { line(text, GOLD, 0.3, 0.3) })
	end
end

-- A vertical banner on a wall for the hall of shame: a cheater's name over
-- BANNED, hanging from a gold rod. Faces -Z.
local function shameBanner(ctx, x, y, z, rot, name)
	local frame = at(ctx, x, y, z, rot)
	Kit.part(ctx.Decor, "BannerRod", Vector3.new(5.4, 0.3, 0.3), frame * CFrame.new(0, 5.2, -0.3), GOLD, M.Metal)
	local banner = Kit.part(ctx.Decor, "Banner", Vector3.new(4.6, 10, 0.1), frame * CFrame.new(0, 0, -0.25), CARPET, M.Fabric)
	Kit.text(banner, FRONT, {
		line("BANNED", GOLD, 0.06, 0.12),
		line(name, WHITE, 0.4, 0.07),
		line("FOREVER", GOLD, 0.82, 0.08, Enum.Font.GothamBold),
	})
	return banner
end

-- Maps ------------------------------------------------------------------------------

Maps.AntiCheatHQ = {
	Name = "Anti-Cheat HQ", Theme = "AntiCheatHQ", HalfX = 64, HalfZ = 58,
	Build = function(ctx)
		local height = 22
		local hx, hz = ctx.HalfX, ctx.HalfZ
		Kit.floor(ctx, rgb(212, 218, 228), M.Marble)
		Kit.boundary(ctx, height, HQ_WHITE, M.SmoothPlastic)
		Kit.ceiling(ctx, height, rgb(242, 244, 248), M.SmoothPlastic)
		Kit.ceilingLights(ctx, height, rgb(236, 246, 255), 30)
		wallBand(ctx, 0.5, 1, HQ_NAVY, M.SmoothPlastic, 0.4)
		wallBand(ctx, 8.5, 1.2, HQ_BLUE, M.SmoothPlastic, 0.35)

		-- Blue carpet from the front doors to the statue, edged in light blue
		Kit.part(ctx.Decor, "Carpet", Vector3.new(10, 0.06, 46), at(ctx, 0, 0.03, -hz + 23), HQ_NAVY, M.Fabric)
		for _, side in { -1, 1 } do
			Kit.stripe(ctx, side * 5.2, -hz + 23, 46, 0.4, 0, rgb(120, 190, 255))
		end

		-- Front doors behind the spawn: glass onto a bright street, sign above
		Kit.part(ctx.Decor, "DoorFrame", Vector3.new(20, 11, 0.3), at(ctx, 0, 5.5, -hz + 0.15), HQ_NAVY, M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(18.6, 10, 0.1), at(ctx, 0, 5.2, -hz + 0.3), rgb(205, 228, 255), 0.15)
		Kit.part(ctx.Decor, "DoorGlass", Vector3.new(18.6, 10, 0.1), at(ctx, 0, 5.2, -hz + 0.45), GLASS, M.Glass, 0.5)
		Kit.part(ctx.Decor, "DoorBar", Vector3.new(0.5, 10, 0.3), at(ctx, 0, 5.2, -hz + 0.5), HQ_NAVY, M.Metal)
		Kit.sign(ctx, 0, 14, -hz + 0.6, 180, 22, 3.6, "ANTI-CHEAT HQ", HQ_BLUE, WHITE)

		-- Security line: a scanner gate right in front of the spawn, speed
		-- gates either side, low glass barriers and a loadout scanner. The far
		-- sides stay open.
		local lineZ = -34
		Props.scannerGate(ctx, 0, lineZ, 0, ALARM)
		for _, side in { -1, 1 } do
			speedGates(ctx, side * 15.4, lineZ, 2)
			glassWall(ctx, side * 4.4, lineZ, side * 10, lineZ, 3.6)
		end
		glassWall(ctx, -38, lineZ, -20.8, lineZ, 3.6)
		loadoutScanner(ctx, 26, lineZ, 0)
		glassWall(ctx, 28.8, lineZ, 38, lineZ, 3.6)

		-- Front desk on the left, waiting area on the right
		frontDesk(ctx, -42, -47, -90)
		lobbyBench(ctx, 44, -53, 0, 12)
		lobbyBench(ctx, 54.5, -44, 90, 10)
		plant(ctx, 56, -53)

		-- The giant ban hammer on a two-step round stage in the middle
		local stageZ = 4
		Kit.cylinder(ctx.Structure, "Stage", 0.8, 22, at(ctx, 0, 0.4, stageZ), HQ_WHITE, M.Marble)
		Kit.cylinder(ctx.Decor, "StageGlow", 0.12, 22.5, at(ctx, 0, 0.1, stageZ), ALARM, M.Neon)
		Kit.cylinder(ctx.Structure, "Stage", 0.8, 15, at(ctx, 0, 1.2, stageZ), rgb(205, 212, 224), M.Marble)
		Kit.cylinder(ctx.Decor, "StageGlow", 0.12, 15.4, at(ctx, 0, 0.9, stageZ), HQ_BLUE, M.Neon)
		Props.banHammerStatue(lifted(ctx, 1.6), 0, stageZ, 0, ALARM)
		Kit.light(Kit.cylinder(ctx.Decor, "SkylightRing", 0.3, 18, at(ctx, 0, height - 0.15, stageZ), rgb(225, 240, 255), M.Neon), rgb(225, 240, 255), 26, 1.5)

		-- Around the lobby: the giant report button, benches, help kiosks, plants
		giantReportButton(ctx, 28, -12, 0)
		lobbyBench(ctx, -24, -14, 0, 10)
		lobbyBench(ctx, 0, 27, 180, 12)
		for _, x in { -18, 18 } do
			local kiosk = Kit.part(ctx.Structure, "Kiosk", Vector3.new(2.6, 6.4, 1.4), at(ctx, x, 3.2, 24), HQ_WHITE)
			screen(ctx.Decor, Vector3.new(2.1, 3.4, 0.05), kiosk.CFrame * CFrame.new(0, 0.9, -0.72), SCREEN, {
				line("HOW TO", WHITE, 0.08, 0.12, Enum.Font.GothamBold),
				line("REPORT", ALARM, 0.22, 0.16),
				line("1. SPOT\n2. CLIP IT\n3. PRESS", WHITE, 0.46, 0.44, Enum.Font.GothamBold),
			})
		end
		for _, spot in { { -14, -24 }, { 14, -24 }, { -32, 30 }, { 32, 30 } } do
			plant(ctx, spot[1], spot[2])
		end

		-- The wall to the server room: two doorways and a window in the middle
		local wallZ = 42
		for _, span in { { -hx, -34 }, { -26, -12 }, { 12, 26 }, { 34, hx } } do
			Kit.part(ctx.Structure, "Wall", Vector3.new(span[2] - span[1], height, 1), at(ctx, (span[1] + span[2]) / 2, height / 2, wallZ), HQ_WHITE)
		end
		Kit.part(ctx.Structure, "Wall", Vector3.new(24, 3, 1), at(ctx, 0, 1.5, wallZ), HQ_WHITE)
		Kit.part(ctx.Structure, "Wall", Vector3.new(24, height - 11, 1), at(ctx, 0, 11 + (height - 11) / 2, wallZ), HQ_WHITE)
		Kit.part(ctx.Structure, "Glass", Vector3.new(24, 8, 0.4), at(ctx, 0, 7, wallZ), GLASS, M.Glass, 0.55)
		Kit.part(ctx.Decor, "WindowSill", Vector3.new(24.4, 0.4, 1.6), at(ctx, 0, 3.1, wallZ), HQ_NAVY, M.Metal)
		Kit.part(ctx.Decor, "Baseboard", Vector3.new(hx * 2, 1, 1.4), at(ctx, 0, 0.5, wallZ), HQ_NAVY)
		for _, x in { -30, 30 } do
			Kit.part(ctx.Structure, "Wall", Vector3.new(8, height - 10, 1), at(ctx, x, 10 + (height - 10) / 2, wallZ), HQ_WHITE)
			local sign = Kit.part(ctx.Decor, "DoorSign", Vector3.new(7, 1.4, 0.2), at(ctx, x, 11, wallZ - 0.6), HQ_NAVY)
			Kit.text(sign, FRONT, { line("SERVER ROOM", WHITE, 0.14, 0.72) })
			Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.8, 0.8, 0.3), at(ctx, x, 12.4, wallZ - 0.65), ALARM))
		end
		-- Logo over the window: the anti-cheat eye that sees everything
		local logo = Kit.part(ctx.Decor, "Logo", Vector3.new(30, 6, 0.4), at(ctx, 0, 16, wallZ - 0.7), HQ_NAVY)
		Kit.text(logo, FRONT, {
			{ Text = "ANTI-CHEAT HQ", Color = WHITE, Position = UDim2.fromScale(0.24, 0.1), Size = UDim2.fromScale(0.72, 0.52) },
			{ Text = "we see everything", Color = rgb(130, 190, 255), Font = Enum.Font.GothamBold, Position = UDim2.fromScale(0.24, 0.64), Size = UDim2.fromScale(0.72, 0.26) },
		})
		Kit.neon(ctx.Decor, Vector3.new(30.4, 0.3, 0.6), at(ctx, 0, 12.9, wallZ - 0.7), ALARM)
		Kit.part(ctx.Decor, "LogoEye", Vector3.new(5.6, 3.4, 0.2), at(ctx, 11.4, 16, wallZ - 1), WHITE)
		tube(ctx.Decor, "LogoIris", 0.2, 2.6, at(ctx, 11.4, 16, wallZ - 1.15) * TURN, HQ_BLUE)
		tube(ctx.Decor, "LogoPupil", 0.2, 1.2, at(ctx, 11.4, 16, wallZ - 1.3) * TURN, BLACK)

		-- Most wanted board left of the window, mod of the month on the right
		for index, poster in { { "Aimbot_Andy", 5000, "aimbot" }, { "RAGE_H4X0R", 50000, "rage hacking" }, { "Wallhack_Wendy", 25000, "wallhacks" } } do
			Props.wantedPoster(ctx, -27 + index * 4, wallZ - 0.5, 0, poster[1], poster[2], poster[3], 5.5)
		end
		local header = Kit.part(ctx.Decor, "WantedHeader", Vector3.new(11.6, 1.4, 0.2), at(ctx, -19, 9.1, wallZ - 0.6), ALARM)
		Kit.text(header, FRONT, { line("MOST WANTED", WHITE, 0.12, 0.76) })
		local award = Kit.part(ctx.Decor, "AwardFrame", Vector3.new(5, 6.4, 0.2), at(ctx, 19, 6.2, wallZ - 0.6), GOLD, M.Metal)
		local photo = Kit.part(ctx.Decor, "AwardPhoto", Vector3.new(4.2, 5.6, 0.1), award.CFrame * CFrame.new(0, 0, -0.12), HQ_NAVY)
		Kit.text(photo, FRONT, {
			line("MOD OF THE MONTH", GOLD, 0.04, 0.1, Enum.Font.GothamBold),
			line("Mod_Melissa", WHITE, 0.74, 0.1),
			line("1,000 BANS", rgb(130, 190, 255), 0.86, 0.08, Enum.Font.GothamBold),
		})
		-- Her portrait: a blocky head with a mod cap
		Kit.part(ctx.Decor, "Portrait", Vector3.new(1.4, 1.4, 0.05), photo.CFrame * CFrame.new(0, 0.9, -0.07), rgb(245, 205, 60))
		Kit.part(ctx.Decor, "Portrait", Vector3.new(2.4, 1.2, 0.05), photo.CFrame * CFrame.new(0, -0.5, -0.07), ALARM)
		Kit.part(ctx.Decor, "Portrait", Vector3.new(1.6, 0.45, 0.05), photo.CFrame * CFrame.new(0, 1.65, -0.09), HQ_BLUE)

		-- Glass offices down the left: the mod office and ban appeals
		local officeX = -40
		glassWall(ctx, officeX, -22, officeX, -6, 10, true, true)
		glassWall(ctx, officeX, 2, officeX, 18, 10, true, true)
		glassWall(ctx, officeX, 26, officeX, wallZ - 0.5, 10, true, true)
		glassWall(ctx, -hx, -22, officeX, -22, 10, true)
		glassWall(ctx, -hx, 8, officeX, 8, 10, true)
		doorSign(ctx, officeX, -6, officeX, 2, 10, "MOD OFFICE", WHITE)
		doorSign(ctx, officeX, 18, officeX, 26, 10, "BAN APPEALS", ALARM)
		officeDesk(ctx, -52, -13, 0, { line("BAN QUEUE", WHITE, 0.1, 0.3, Enum.Font.GothamBold), line("12 LEFT", YELLOW, 0.48, 0.4) })
		officeDesk(ctx, -52, -1, 0, { line("SUS METER", WHITE, 0.1, 0.3, Enum.Font.GothamBold), line("99%", ALARM, 0.45, 0.45) })
		Kit.part(ctx.Structure, "Cabinet", Vector3.new(2.6, 5, 2.4), at(ctx, -62.4, 2.5, 3), rgb(200, 205, 214), M.Metal)
		for _, y in { 1.2, 2.6, 4 } do
			Kit.part(ctx.Decor, "Drawer", Vector3.new(0.1, 1.1, 2), at(ctx, -61.05, y, 3), rgb(225, 228, 236), M.Metal)
		end
		-- Ban appeals is empty: just a closed sign and a bin full of letters
		local closed = Kit.part(ctx.Decor, "ClosedSign", Vector3.new(0.2, 1.4, 3.2), at(ctx, officeX - 0.3, 6.2, 14), WHITE)
		Kit.text(closed, Enum.NormalId.Left, { line("CLOSED", ALARM, 0.1, 0.8) })
		Kit.text(closed, Enum.NormalId.Right, { line("CLOSED", ALARM, 0.1, 0.8) })
		Kit.cylinder(ctx.Structure, "Bin", 3, 2.4, at(ctx, -52, 1.5, 22), rgb(70, 74, 86), M.Metal)
		for index = 0, 2 do
			Kit.part(ctx.Decor, "Appeal", Vector3.new(1.2, 0.1, 1.6), at(ctx, -52 + math.cos(index * 2.1) * 2, 0.05 + (index % 2) * 3.05, 22 + math.sin(index * 2.1) * 2, index * 40), WHITE)
		end
		local appeals = Kit.part(ctx.Decor, "AppealsBoard", Vector3.new(0.2, 3, 8), at(ctx, -hx + 0.5, 5.5, 22), HQ_NAVY)
		Kit.text(appeals, Enum.NormalId.Right, {
			line("APPEALS THIS YEAR", WHITE, 0.08, 0.22, Enum.Font.GothamBold),
			line("ACCEPTED: 0", ALARM, 0.42, 0.24),
			line("DENIED: 48,302", LIME, 0.72, 0.2, Enum.Font.GothamBold),
		})

		-- The watch room on the right: a wall of camera feeds and two desks
		glassWall(ctx, -officeX, -22, -officeX, -2, 10, true, true)
		glassWall(ctx, -officeX, 6, -officeX, 22, 10, true, true)
		glassWall(ctx, -officeX, 30, -officeX, wallZ - 0.5, 10, true, true)
		glassWall(ctx, -officeX, -22, hx, -22, 10, true)
		doorSign(ctx, -officeX, -2, -officeX, 6, 10, "WATCH ROOM", WHITE)
		doorSign(ctx, -officeX, 22, -officeX, 30, 10, "WATCH ROOM", WHITE)
		local feeds = {
			{ "CAM 1", "SPINBOT SPOTTED", ALARM },
			{ "CAM 2", "ALL CLEAN", LIME },
			{ "CAM 3", "SPEED HACK?", YELLOW },
			{ "CAM 4", "ALL CLEAN", LIME },
			{ "CAM 5", "AIMBOT 100%", ALARM },
			{ "CAM 6", "FLYING NOOB", YELLOW },
		}
		Kit.part(ctx.Decor, "VideoWall", Vector3.new(25.6, 10, 0.4), at(ctx, hx - 0.4, 8, 8, 90), BLACK)
		for index, feed in feeds do
			local row = (index - 1) // 3
			local column = (index - 1) % 3 - 1
			local frame = at(ctx, hx - 0.4, 5.6 + row * 4.8, 8 + column * 8.4, 90)
			screen(ctx.Decor, Vector3.new(8, 4.4, 0.05), frame * CFrame.new(0, 0, -0.22), rgb(18, 30, 52), {
				{ Text = feed[1], Color = WHITE, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.4, 0.2) },
				line(feed[2], feed[3], 0.38, 0.3),
				{ Text = "REC", Color = ALARM, Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.55, 0.06), Size = UDim2.fromScale(0.4, 0.2) },
			})
		end
		local watchSign = Kit.part(ctx.Decor, "WatchSign", Vector3.new(24, 1.8, 0.3), at(ctx, hx - 0.4, 16.2, 8, 90), HQ_NAVY)
		Kit.text(watchSign, FRONT, { line("LIVE WATCH  |  6 CAMERAS  |  0 CHEATERS ESCAPED", WHITE, 0.14, 0.72, Enum.Font.GothamBold) })
		officeDesk(ctx, 52, 3.5, 90, { line("CAM FEED", WHITE, 0.1, 0.3, Enum.Font.GothamBold), line("WATCHING", HQ_BLUE, 0.48, 0.4) })
		officeDesk(ctx, 52, 12.5, 90, { line("REPORTS", WHITE, 0.1, 0.3, Enum.Font.GothamBold), line("+3 NEW", YELLOW, 0.48, 0.4) })

		-- Server room behind the wall: a row of racks in the window, more in
		-- the back corners, and a cooling unit
		for _, x in { -6.6, -2.2, 2.2, 6.6, -36, 36 } do
			rack(ctx, x, if math.abs(x) < 10 then wallZ + 5.5 else hz - 4, 0)
		end
		for _, x in { -56, 56 } do
			local cooler = Kit.part(ctx.Structure, "Cooler", Vector3.new(8, 7, 4), at(ctx, x, 3.5, hz - 4), HQ_WHITE, M.Metal)
			Kit.text(cooler, FRONT, { line("COOLING", HQ_BLUE, 0.1, 0.16), line("| | | | | | | | | |", rgb(150, 160, 180), 0.4, 0.4) })
		end

		-- Red alarm lights high on the side walls
		for _, z in { -40, 20 } do
			for _, side in { -1, 1 } do
				Kit.blink(Kit.ball(ctx.Decor, "AlarmLight", 1.2, at(ctx, side * (hx - 0.4), 17, z), ALARM, M.Neon))
			end
		end
	end,
}

Maps.BanCourt = {
	Name = "Ban Court", Theme = "BanCourt", HalfX = 56, HalfZ = 64,
	Build = function(ctx)
		local height = 30
		local hx, hz = ctx.HalfX, ctx.HalfZ
		Kit.floor(ctx, rgb(122, 82, 54), M.WoodPlanks)
		Kit.boundary(ctx, height, rgb(214, 196, 166), M.Plaster)
		Kit.ceiling(ctx, height, rgb(66, 42, 28), M.WoodPlanks)
		-- Wood paneling around the bottom of the walls with a rail on top
		wallBand(ctx, 3.6, 7.2, WOOD, M.Wood, 0.3)
		wallBand(ctx, 7.3, 0.4, WOOD_DARK, M.Wood, 0.5)
		-- Ceiling beams across the hall
		for z = -hz + 12, hz - 12, 20 do
			Kit.part(ctx.Decor, "CeilingBeam", Vector3.new(hx * 2, 1.4, 1.6), at(ctx, 0, height - 0.7, z), WOOD_DARK, M.Wood)
		end

		-- Red carpet from the doors, up the aisle to the lectern
		Kit.part(ctx.Decor, "Carpet", Vector3.new(8, 0.06, 86), at(ctx, 0, 0.03, -hz + 43), CARPET, M.Fabric)
		for _, side in { -1, 1 } do
			Kit.stripe(ctx, side * 4.2, -hz + 43, 86, 0.4, 0, GOLD)
		end

		-- Big wooden doors behind the spawn, with the court's name above
		for _, side in { -1, 1 } do
			local door = Kit.part(ctx.Decor, "Door", Vector3.new(5.8, 12, 0.4), at(ctx, side * 3, 6, -hz + 0.5), WOOD_DARK, M.Wood)
			for _, y in { 2.6, -2.6 } do
				Kit.part(ctx.Decor, "DoorPanel", Vector3.new(4.4, 4, 0.1), door.CFrame * CFrame.new(0, y, 0.25), WOOD, M.Wood)
			end
			Kit.part(ctx.Decor, "DoorHandle", Vector3.new(0.3, 1.6, 0.3), door.CFrame * CFrame.new(-side * 2.3, 0, 0.4), GOLD, M.Metal)
		end
		Kit.part(ctx.Decor, "DoorArch", Vector3.new(14, 1.6, 0.8), at(ctx, 0, 12.8, -hz + 0.6), MARBLE, M.Marble)
		Kit.sign(ctx, 0, 16, -hz + 0.6, 180, 20, 3.4, "BAN COURT", GOLD, rgb(60, 14, 20))

		-- Public pews in two blocks either side of the aisle. Their backs make
		-- cover lines all the way up to the bar.
		for _, z in { -36, -27, -18 } do
			for _, side in { -1, 1 } do
				Props.pew(ctx, side * 16.5, z, 180, 19, CARPET)
			end
		end

		-- Gallery balconies along both side walls, held up by columns, with a
		-- ramp up from the entrance end
		local deckY, deckFrom, deckTo = 11, -40, 10
		local deckZ, deckLength = (deckFrom + deckTo) / 2, deckTo - deckFrom
		for _, side in { -1, 1 } do
			local inner = side * 42
			local middle = side * 49
			Kit.part(ctx.Structure, "Balcony", Vector3.new(14, 1, deckLength), at(ctx, middle, deckY - 0.5, deckZ), WOOD_DARK, M.WoodPlanks)
			Kit.part(ctx.Decor, "BalconyTrim", Vector3.new(0.6, 1.2, deckLength), at(ctx, inner - side * 0.1, deckY - 0.9, deckZ), GOLD, M.Metal)
			Kit.part(ctx.Structure, "Parapet", Vector3.new(0.6, 3.2, deckLength), at(ctx, inner + side * 0.3, deckY + 1.6, deckZ), WOOD, M.Wood)
			Kit.part(ctx.Structure, "Parapet", Vector3.new(14, 3.2, 0.6), at(ctx, middle, deckY + 1.6, deckTo - 0.3), WOOD, M.Wood)
			Kit.part(ctx.Structure, "Parapet", Vector3.new(5.4, 3.2, 0.6), at(ctx, side * 45.1, deckY + 1.6, deckFrom + 0.3), WOOD, M.Wood)
			Kit.part(ctx.Decor, "ParapetCap", Vector3.new(1, 0.3, deckLength), at(ctx, inner + side * 0.3, deckY + 3.35, deckZ), GOLD, M.Metal)
			for _, z in { -30, -8 } do
				column(ctx, inner + side * 1.4, z, deckY - 1)
			end
			-- The ramp climbs along the wall from the entrance end to the balcony,
			-- with a side wall that rises to rail height as it goes
			local rampLength = deckFrom + hz
			Kit.ramp(ctx, side * 52, deckFrom - rampLength / 2, 8, deckY, rampLength, 0, WOOD_DARK, M.WoodPlanks)
			Kit.wedge(ctx.Structure, "RampSide", Vector3.new(0.6, deckY + 3, rampLength), at(ctx, side * 47.7, (deckY + 3) / 2, deckFrom - rampLength / 2), WOOD, M.Wood)
			beam(ctx, Vector3.new(side * 47.7, 0.2, deckFrom - rampLength), Vector3.new(side * 47.7, deckY + 3.2, deckFrom), 0.8, 0.3, GOLD, M.Metal)
		end
		-- Hall of shame: banned cheaters' banners on the walls above the balconies
		for index, name in { "Aimbot_Andy", "RAGE_H4X0R", "LagSwitch_420", "GodMode_Gary" } do
			local side = if index <= 2 then -1 else 1
			shameBanner(ctx, side * (hx - 0.3), 20, -30 + ((index - 1) % 2) * 24, side * 90, name)
		end

		-- The bar: a low wooden rail between the public and the court, with a
		-- gate in the middle
		local barZ = -4
		for _, side in { -1, 1 } do
			Kit.part(ctx.Structure, "Bar", Vector3.new(30, 3, 0.8), at(ctx, side * 18, 1.5, barZ), WOOD, M.Wood)
			Kit.part(ctx.Decor, "BarRail", Vector3.new(30, 0.35, 1.2), at(ctx, side * 18, 3.15, barZ), WOOD_DARK, M.Wood)
			for _, x in { 3.4, 33.4 } do
				Kit.part(ctx.Structure, "BarPost", Vector3.new(1.2, 3.8, 1.2), at(ctx, side * x, 1.9, barZ), WOOD_DARK, M.Wood)
			end
			-- Gate leaves swung open toward the judge
			Kit.part(ctx.Decor, "Gate", Vector3.new(0.3, 2.4, 3), at(ctx, side * 2.6, 1.6, barZ + 1.6, side * 10), WOOD_LIGHT, M.Wood)
		end

		-- The court floor: counsel tables, a lectern and the evidence table
		counselTable(ctx, -13, 12, "ANTI-CHEAT", rgb(30, 90, 200))
		counselTable(ctx, 13, 12, "THE CHEATER", CARPET)
		local lectern = Kit.part(ctx.Structure, "Lectern", Vector3.new(2.6, 3.6, 2), at(ctx, 0, 1.8, 22), WOOD, M.Wood)
		-- The top slopes down toward the speaker, who stands on the gallery side
		Kit.wedge(ctx.Decor, "LecternTop", Vector3.new(3, 0.8, 2.4), lectern.CFrame * CFrame.new(0, 2.2, 0), WOOD_DARK, M.Wood)
		Kit.part(ctx.Decor, "LecternSeal", Vector3.new(1.6, 1.6, 0.1), lectern.CFrame * CFrame.new(0, 0.3, -1.05), GOLD, M.Metal)
		local evidence = Kit.part(ctx.Structure, "EvidenceTable", Vector3.new(7, 3, 3), at(ctx, 18, 1.5, 28), WOOD_DARK, M.Wood)
		Kit.part(ctx.Decor, "EvidenceCloth", Vector3.new(7.2, 0.1, 3.2), evidence.CFrame * CFrame.new(0, 1.55, 0), rgb(40, 60, 50), M.Fabric)
		local tag = Kit.part(ctx.Decor, "EvidenceSign", Vector3.new(4, 0.9, 0.1), evidence.CFrame * CFrame.new(0, 0.6, -1.55), YELLOW)
		Kit.text(tag, FRONT, { line("EXHIBIT A", BLACK, 0.1, 0.8) })
		-- Exhibit A: a glowing gaming keyboard, and a mouse with an aimbot sticker
		Kit.part(ctx.Decor, "Keyboard", Vector3.new(3, 0.2, 1.1), evidence.CFrame * CFrame.new(-1.4, 1.7, 0), BLACK)
		for index, color in { PINK, rgb(170, 80, 255), rgb(0, 220, 255) } do
			Kit.neon(ctx.Decor, Vector3.new(2.8, 0.05, 0.22), evidence.CFrame * CFrame.new(-1.4, 1.82, (index - 2) * 0.3), color)
		end
		local mouse = Kit.part(ctx.Decor, "Mouse", Vector3.new(0.7, 0.4, 1.1), evidence.CFrame * CFrame.new(1.6, 1.8, 0), BLACK)
		local sticker = Kit.part(ctx.Decor, "Sticker", Vector3.new(0.6, 0.05, 0.6), mouse.CFrame * CFrame.new(0, 0.22, 0.1), ALARM)
		Kit.text(sticker, Enum.NormalId.Top, { line("AIM", WHITE, 0.1, 0.8) })

		-- Stacks of evidence boxes on the open right side of the floor
		for _, spec in { { 34, 16, 10 }, { 30, 38, -14 }, { 44, 30, 30 } } do
			local box = Kit.box(ctx, spec[1], spec[2], 4.4, 3, 3.4, rgb(176, 136, 90), M.Cardboard, spec[3])
			Kit.text(box, FRONT, { line("EVIDENCE", rgb(60, 36, 20), 0.3, 0.4) })
			Kit.box(ctx, spec[1], spec[2], 3.4, 2.4, 2.8, rgb(196, 156, 104), M.Cardboard, spec[3] + 15, 3)
		end

		-- Jury box on the left, facing the middle of the court
		juryBox(ctx, -36, 26, -90)

		-- The judge's stage: the bench with the clerk and the witness stand
		-- either side, flags, curtains and the BANNED screen
		local stageZ, stageDepth = 52, 22
		Kit.part(ctx.Structure, "Stage", Vector3.new(48, 0.8, stageDepth), at(ctx, 0, 0.4, stageZ + 1), MARBLE, M.Marble)
		Kit.part(ctx.Decor, "StageTrim", Vector3.new(48.2, 0.2, 0.3), at(ctx, 0, 0.7, stageZ + 1 - stageDepth / 2), GOLD, M.Metal)
		local stage = lifted(ctx, 0.8)
		for _, side in { -1, 1 } do
			column(ctx, side * 27, stageZ - stageDepth / 2, height)
		end
		Props.judgeBench(stage, 0, stageZ, 0, "JUDGE MOD")
		witnessStand(stage, 13, stageZ - 2, 0)
		local clerk = Kit.part(ctx.Structure, "ClerkDesk", Vector3.new(7, 3.8, 2.4), at(ctx, -13, 2.7, stageZ - 2), WOOD, M.Wood)
		Kit.part(ctx.Decor, "ClerkTop", Vector3.new(7.4, 0.3, 2.8), clerk.CFrame * CFrame.new(0, 2.05, 0), WOOD_LIGHT, M.Wood)
		local plate = Kit.part(ctx.Decor, "ClerkPlate", Vector3.new(3.4, 0.7, 0.1), clerk.CFrame * CFrame.new(0, 1.2, -1.25), GOLD, M.Metal)
		Kit.text(plate, FRONT, { line("CLERK", rgb(50, 30, 10), 0.1, 0.8) })
		local stamp = Kit.part(ctx.Decor, "BanStamp", Vector3.new(1, 0.6, 1), clerk.CFrame * CFrame.new(2, 2.5, 0), ALARM)
		Kit.text(stamp, FRONT, { line("BAN", WHITE, 0.1, 0.8) })
		for _, side in { -1, 1 } do
			flag(stage, side * 21, hz - 5, if side < 0 then CARPET else rgb(30, 60, 140), "AC")
		end
		Props.jumbotron(ctx, 0, hz - 2.4, 0, "BANNED", "Aimbot_Andy: 47 headshots in 1 minute", ALARM, 13, height)
		-- Velvet curtains either side of the screen
		for _, side in { -1, 1 } do
			for fold = 0, 1 do
				local shade = CARPET:Lerp(Color3.new(0, 0, 0), fold * 0.25)
				Kit.part(ctx.Decor, "Curtain", Vector3.new(3.4, 26, 0.6), at(ctx, side * (12 + fold * 3.2), 13, hz - 0.6 - fold * 0.3), shade, M.Fabric)
			end
			Kit.part(ctx.Decor, "TieBack", Vector3.new(7, 0.5, 1.2), at(ctx, side * 13.6, 8, hz - 1.3), GOLD, M.Metal)
		end
		Kit.part(ctx.Decor, "Valance", Vector3.new(36, 2.4, 1), at(ctx, 0, height - 3.6, hz - 0.8), CARPET, M.Fabric)
		Kit.part(ctx.Decor, "ValanceTrim", Vector3.new(36, 0.3, 1.1), at(ctx, 0, height - 4.9, hz - 0.8), GOLD, M.Metal)

		-- Wanted posters on the paneling under the balconies
		Props.wantedPoster(ctx, -hx + 0.3, -20, -90, "TP_Tyler", 18000, "teleporting", 4.4)
		Props.wantedPoster(ctx, hx - 0.3, -20, 90, "LagSwitch_420", 12000, "lag switching", 4.4)
		Props.wantedPoster(ctx, hx - 0.3, -16, 90, "Wallhack_Wendy", 25000, "wallhacks", 4.4)

		-- Warm light: chandeliers down the aisle, a spotlight on the bench and
		-- sconces on the walls
		for _, z in { -32, -4, 24 } do
			chandelier(ctx, 0, z, 21, height)
		end
		local spot = Kit.neon(ctx.Decor, Vector3.new(2, 0.4, 2), at(ctx, 0, height - 1.6, 40), WARM)
		Kit.light(spot, WARM, 40, 2.5, "SpotLight")
		for _, side in { -1, 1 } do
			for _, z in { -32, 30 } do
				local sconce = Kit.neon(ctx.Decor, Vector3.new(0.8, 1.4, 0.8), at(ctx, side * (hx - 0.9), 8.8, z), WARM)
				Kit.part(ctx.Decor, "SconceBack", Vector3.new(0.3, 2.4, 1.4), at(ctx, side * (hx - 0.45), 8.6, z), GOLD, M.Metal)
				Kit.light(sconce, WARM, 26, 1.2)
			end
		end
	end,
}

return Maps
