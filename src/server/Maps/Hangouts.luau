-- Hangout maps: the places gamers hang out, turned into arenas.
--   Gamer Bedroom: a kid's gaming bedroom at giant scale. Players are the
--   size of toys, so the desk, bed, can tower and toy bricks are the cover,
--   and a ramp of game boxes and books leads up onto the desk.
--   Streamer House: a content house mansion with a streaming balcony, a
--   lounge, a kitchen, a shallow pool and a hallway of award plaques.
-- Same format as Indoor.luau: each map sets its size and lighting theme
-- (see ConfigExtra/MapsHangouts.luau), then places props with the kit.
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local rgb, M = Kit.rgb, Kit.M
local at = Kit.at
local FRONT, BACK = Enum.NormalId.Front, Enum.NormalId.Back

local Maps = {}

local PINK = rgb(255, 46, 99)
local CYAN = rgb(0, 220, 255)
local PURPLE = rgb(150, 80, 230)
local YELLOW = rgb(255, 205, 40)
local LIME = rgb(130, 255, 70)
local RED = rgb(225, 40, 45)
local BLUE = rgb(30, 100, 220)
local GREEN = rgb(40, 170, 70)
local WHITE = rgb(242, 242, 246)
local BLACK = rgb(22, 22, 27)
local STEEL = rgb(160, 164, 172)
local GOLD = rgb(240, 190, 60)
local OAK = rgb(196, 150, 104)

-- Turns a cylinder (which lies along X) to lie along Z instead
local TURN = CFrame.Angles(0, math.rad(90), 0)

-- Helpers ----------------------------------------------------------------------

local function darker(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount or 0.3)
end

-- A spot in the arena as a world position
local function spot(ctx, x, y, z)
	return ctx.Center + Vector3.new(x, y, z)
end

-- A round part lying along X, the way Roblox cylinders lie
local function tube(parent, name, length, diameter, cframe, color, material)
	local part = Kit.part(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A squashed ball (pillows, clouds, grips). It still collides as a box.
local function blob(parent, name, size, cframe, color, material)
	local part = Kit.part(parent, name, size, cframe, color, material or M.Fabric)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- Water, glows and cables: people and bullets go straight through
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

-- A cable lying on the floor through a list of { x, z } points
local function cable(ctx, points, color)
	for index = 1, #points - 1 do
		local from = spot(ctx, points[index][1], 0.2, points[index][2])
		local to = spot(ctx, points[index + 1][1], 0.2, points[index + 1][2])
		passThrough(Kit.part(ctx.Decor, "Cable", Vector3.new(0.5, 0.4, (to - from).Magnitude + 0.4), CFrame.lookAt((from + to) / 2, to), color or BLACK))
	end
end

-- A poster on a wall: paper in a thin frame, facing -Z when rot is 0 (180,
-- 90 and -90 face the other walls). Returns the paper and its frame.
local function poster(ctx, x, y, z, rot, width, height, paperColor, frameColor, lines)
	local frame = at(ctx, x, y, z, rot)
	Kit.part(ctx.Decor, "PosterFrame", Vector3.new(width + 0.8, height + 0.8, 0.2), frame, frameColor)
	local paper = Kit.part(ctx.Decor, "Poster", Vector3.new(width, height, 0.1), frame * CFrame.new(0, 0, -0.12), paperColor)
	Kit.text(paper, FRONT, lines)
	return paper, frame
end

-- Gamer Bedroom props ---------------------------------------------------------------
-- About 4 cm to the stud, so a player is the size of an action figure.

-- A boxed video game lying flat with its title on the front and right side
-- and cover art on top. y is where its bottom sits.
local function gameBox(ctx, x, z, y, rot, size, color, title)
	local box = Kit.part(ctx.Structure, "GameBox", size, at(ctx, x, y + size.Y / 2, z, rot), color)
	for _, face in { FRONT, Enum.NormalId.Right } do
		Kit.text(box, face, { line(title, WHITE, 0.18, 0.64) })
	end
	local art = Kit.part(ctx.Decor, "BoxArt", Vector3.new(size.X - 1.4, 0.1, size.Z - 1.4), box.CFrame * CFrame.new(0, size.Y / 2 + 0.05, 0), darker(color, 0.45))
	Kit.text(art, Enum.NormalId.Top, { line(title, YELLOW, 0.3, 0.4) })
	return box
end

-- A big hardcover book leaning from one spot to another as a ramp: its top
-- face runs between the two spots. Covers, a page block showing on three
-- edges, a spine and the title on top.
local function book(ctx, from, to, width, color, title)
	local thickness = 1.6
	local length = (to - from).Magnitude
	local frame = CFrame.lookAt((from + to) / 2, to)
	local cover = Kit.part(ctx.Structure, "Book", Vector3.new(width, 0.3, length), frame * CFrame.new(0, -0.15, 0), color)
	Kit.text(cover, Enum.NormalId.Top, { line(title, WHITE, 0.32, 0.36) })
	Kit.part(ctx.Structure, "Book", Vector3.new(width, 0.3, length), frame * CFrame.new(0, -thickness + 0.15, 0), color)
	Kit.part(ctx.Decor, "Pages", Vector3.new(width - 0.7, thickness - 0.6, length - 0.4), frame * CFrame.new(0.15, -thickness / 2, 0), rgb(246, 240, 224))
	Kit.part(ctx.Decor, "Spine", Vector3.new(0.4, thickness, length), frame * CFrame.new(-width / 2 + 0.2, -thickness / 2, 0), darker(color, 0.25))
	return cover
end

-- An energy drink can (FRAG FUEL, from the vending machines) with its bottom
-- on `base`: a colored body with a band and a silver lid, 3.45 tall
local function can(ctx, base, color, band)
	local body = Kit.cylinder(ctx.Structure, "Can", 3.1, 2.6, base * CFrame.new(0, 1.55, 0), color, M.Metal)
	Kit.cylinder(ctx.Decor, "CanBand", 1.1, 2.66, base * CFrame.new(0, 1.75, 0), band, M.Metal)
	Kit.cylinder(ctx.Decor, "CanLid", 0.35, 2.3, base * CFrame.new(0, 3.275, 0), STEEL, M.Metal)
	return body
end

-- A can lying on its side on the floor, along X when rot is 0
local function tippedCan(ctx, x, z, rot, color, band)
	return can(ctx, at(ctx, x, 1.3, z, rot) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -1.725, 0), color, band)
end

-- A toy building brick `long` by `wide` studs with its bottom on `base`.
-- `bare` lists stud columns to leave off, where another brick sits on top.
local function brick(ctx, base, long, wide, color, bare)
	local pitch, height = 3, 3.6
	local body = Kit.part(ctx.Structure, "ToyBrick", Vector3.new(long * pitch, height, wide * pitch), base * CFrame.new(0, height / 2, 0), color)
	body.Reflectance = 0.06
	for column = 1, long do
		if not (bare and table.find(bare, column)) then
			for row = 1, wide do
				Kit.cylinder(ctx.Decor, "Stud", 0.9, 2.1, base * CFrame.new((column - (long + 1) / 2) * pitch, height + 0.45, (row - (wide + 1) / 2) * pitch), color)
			end
		end
	end
	return body
end

-- Headphones dropped on the floor, standing on their ear cups with the band
-- arching over: 11 wide and 9.6 tall
local function headphones(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	local shell = rgb(236, 236, 242)
	for _, side in { -1, 1 } do
		local cup = base * CFrame.new(side * 3.6, 2.8, 0)
		tube(ctx.Structure, "EarCup", 1.8, 5.6, cup, shell)
		tube(ctx.Decor, "EarCushion", 1, 4.8, cup * CFrame.new(-side * 1.2, 0, 0), BLACK, M.Fabric)
		passThrough(tube(ctx.Decor, "EarGlow", 0.25, 5.7, cup * CFrame.new(side * 0.6, 0, 0), color, M.Neon))
		tube(ctx.Decor, "EarLogo", 0.2, 2.6, cup * CFrame.new(side * 0.95, 0, 0), color)
	end
	-- The band: a half circle of short pieces from one cup to the other
	local radius, middle = 3.9, 5.5
	for index = 0, 5 do
		local a1, a2 = math.pi * index / 6, math.pi * (index + 1) / 6
		local p1 = Vector3.new(math.cos(a1) * radius, middle + math.sin(a1) * radius, 0)
		local p2 = Vector3.new(math.cos(a2) * radius, middle + math.sin(a2) * radius, 0)
		local turn = math.atan2(p2.Y - p1.Y, p2.X - p1.X)
		Kit.part(ctx.Decor, "Band", Vector3.new((p2 - p1).Magnitude + 0.3, 0.9, 1.5), base * CFrame.new((p1 + p2) / 2) * CFrame.Angles(0, 0, turn), shell)
	end
	Kit.part(ctx.Decor, "BandPad", Vector3.new(3.4, 0.6, 1.2), base * CFrame.new(0, middle + radius - 0.7, 0), color, M.Fabric)
end

-- A game controller lying on the floor (7.4 wide): grips, two sticks, a
-- d-pad, four colored buttons, a touch pad and a light bar along the front
local function controller(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	local body = Kit.part(ctx.Structure, "Controller", Vector3.new(7.4, 1.6, 3.6), base * CFrame.new(0, 1.5, -0.3), color)
	for _, side in { -1, 1 } do
		blob(ctx.Structure, "Grip", Vector3.new(2.8, 2.2, 5), base * CFrame.new(side * 3, 1.15, 0.9) * CFrame.Angles(0, math.rad(side * -18), 0), color, M.SmoothPlastic)
		Kit.cylinder(ctx.Decor, "Stick", 0.9, 1.4, base * CFrame.new(side * 1.5, 2.6, 0.7), BLACK)
		Kit.part(ctx.Decor, "Bumper", Vector3.new(2, 0.7, 0.8), base * CFrame.new(side * 2.6, 1.9, -2.3), darker(color, 0.4))
	end
	Kit.part(ctx.Decor, "DPad", Vector3.new(1.5, 0.3, 0.5), base * CFrame.new(-2.6, 2.4, -0.9), BLACK)
	Kit.part(ctx.Decor, "DPad", Vector3.new(0.5, 0.3, 1.5), base * CFrame.new(-2.6, 2.4, -0.9), BLACK)
	for _, button in { { 0, -0.55, LIME }, { 0.55, 0, PINK }, { 0, 0.55, CYAN }, { -0.55, 0, YELLOW } } do
		Kit.cylinder(ctx.Decor, "Button", 0.3, 0.55, base * CFrame.new(2.6 + button[1], 2.4, -0.9 + button[2]), button[3])
	end
	Kit.part(ctx.Decor, "TouchPad", Vector3.new(2.4, 0.12, 1.4), base * CFrame.new(0, 2.33, -0.9), darker(color, 0.5))
	Kit.neon(ctx.Decor, Vector3.new(2.6, 0.12, 0.3), base * CFrame.new(0, 2.3, -2.05), CYAN)
	return body
end

-- A game console standing on its end (12 tall): white shells around a black
-- core, with a glowing strip down the front (-Z)
local function console(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.cylinder(ctx.Decor, "ConsoleStand", 0.5, 5.4, base * CFrame.new(0, 0.25, 0), BLACK)
	local core = Kit.part(ctx.Structure, "Console", Vector3.new(1.6, 11, 7.4), base * CFrame.new(0, 6, 0), BLACK)
	for _, side in { -1, 1 } do
		local shell = Kit.part(ctx.Structure, "ConsoleShell", Vector3.new(0.9, 11.6, 8), base * CFrame.new(side * 1.25, 6.3, 0), WHITE)
		Kit.text(shell, if side < 0 then Enum.NormalId.Left else Enum.NormalId.Right, { line("GG BOX", rgb(190, 192, 205), 0.42, 0.14) })
	end
	Kit.neon(ctx.Decor, Vector3.new(0.3, 9.6, 0.1), base * CFrame.new(0, 6.2, -3.73), CYAN)
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.5, 0.5, 0.1), base * CFrame.new(0, 11.4, -3.73), WHITE))
	return core
end

-- A gaming chair at toy scale (about 25 tall): star base on casters, gas
-- lift, seat with colored bolsters, a tall backrest with wings and a
-- headrest. You sit facing -Z.
local function bigChair(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	for index = 0, 4 do
		local leg = base * CFrame.Angles(0, math.rad(index * 72), 0)
		Kit.part(ctx.Decor, "ChairLeg", Vector3.new(1, 0.8, 4.6), leg * CFrame.new(0, 1.5, -2.4), BLACK, M.Metal)
		Kit.ball(ctx.Decor, "Caster", 1.3, leg * CFrame.new(0, 0.65, -4.4), BLACK)
	end
	Kit.cylinder(ctx.Decor, "ChairHub", 1.2, 2, base * CFrame.new(0, 1.6, 0), BLACK, M.Metal)
	Kit.cylinder(ctx.Structure, "GasLift", 6.2, 1, base * CFrame.new(0, 5.2, 0), STEEL, M.Metal)
	local seat = Kit.part(ctx.Structure, "GamingChair", Vector3.new(8.4, 1.8, 8.6), base * CFrame.new(0, 9.2, -0.2), BLACK, M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "SeatBolster", Vector3.new(1.5, 1, 8.6), base * CFrame.new(side * 3.6, 10.3, -0.2), color, M.Fabric)
		Kit.part(ctx.Decor, "ArmPost", Vector3.new(0.7, 3.4, 1), base * CFrame.new(side * 4.7, 11, 0.6), BLACK, M.Metal)
		Kit.part(ctx.Decor, "ArmPad", Vector3.new(1.3, 0.6, 4.2), base * CFrame.new(side * 4.7, 12.9, 0), BLACK)
	end
	-- The backrest leans back a little from its bottom edge
	local back = base * CFrame.new(0, 9.4, 3.9) * CFrame.Angles(math.rad(10), 0, 0)
	local backrest = Kit.part(ctx.Structure, "ChairBack", Vector3.new(8.4, 13, 1.8), back * CFrame.new(0, 6.6, 0), BLACK, M.Fabric)
	Kit.text(backrest, BACK, { line("EARN", color, 0.14, 0.14), line("ESP", color, 0.3, 0.14) })
	Kit.part(ctx.Decor, "BackStripe", Vector3.new(2, 9.5, 0.1), back * CFrame.new(0, 5.8, -0.95), color, M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "ChairWing", Vector3.new(1.4, 9.6, 2.4), back * CFrame.new(side * 3.9, 5.4, -0.3), color, M.Fabric)
	end
	Kit.part(ctx.Decor, "ChairHead", Vector3.new(5.6, 3.4, 1.8), back * CFrame.new(0, 14.6, 0), BLACK, M.Fabric)
	return seat
end

-- A gaming PC at toy scale (11 tall): glowing fans and the graphics card
-- behind a glass side (+X), two more fans in the front (-Z)
local function bigTower(ctx, x, z, rot, glow)
	local base = at(ctx, x, 0, z, rot)
	local case = Kit.part(ctx.Structure, "PcTower", Vector3.new(5.2, 11, 11), base * CFrame.new(0, 5.7, 0), rgb(28, 29, 36), M.Metal)
	Kit.part(ctx.Decor, "PcFeet", Vector3.new(4.6, 0.2, 10), base * CFrame.new(0, 0.1, 0), BLACK)
	for _, y in { 8.2, 3.6 } do
		tube(ctx.Decor, "Fan", 0.1, 3.2, base * CFrame.new(2.62, y, -3), glow, M.Neon)
	end
	tube(ctx.Decor, "Cooler", 0.1, 2.8, base * CFrame.new(2.62, 8.3, 2.1), PURPLE, M.Neon)
	Kit.part(ctx.Decor, "GraphicsCard", Vector3.new(0.3, 1.6, 6.5), base * CFrame.new(2.7, 5.4, 1.4), rgb(40, 40, 48), M.Metal)
	Kit.neon(ctx.Decor, Vector3.new(0.1, 0.25, 6), base * CFrame.new(2.86, 4.8, 1.4), glow)
	Kit.part(ctx.Decor, "PcGlass", Vector3.new(0.1, 10.4, 10.4), base * CFrame.new(3, 5.7, 0), rgb(160, 180, 210), M.Glass, 0.6)
	for _, y in { 3.6, 7.8 } do
		local fan = tube(ctx.Decor, "Fan", 0.1, 3.4, base * CFrame.new(0, y, -5.55) * TURN, glow, M.Neon)
		tube(ctx.Decor, "FanHub", 0.2, 1.5, base * CFrame.new(0, y, -5.6) * TURN, BLACK)
		if y > 5 then
			Kit.light(fan, glow, 16, 1)
		end
	end
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.6, 0.15, 0.6), base * CFrame.new(1.4, 11.27, -4.3), glow))
	return case
end

Maps.GamerBedroom = {
	Name = "Gamer Bedroom", Theme = "Bedroom", HalfX = 70, HalfZ = 60,
	Build = function(ctx)
		local height = 50
		Kit.floor(ctx, rgb(178, 174, 184), M.Carpet)
		Kit.boundary(ctx, height, rgb(112, 136, 204), M.Plaster)
		Kit.ceiling(ctx, height, rgb(236, 236, 242), M.Plaster)
		-- Skirting boards along the bottom of the walls, an LED strip along the top
		for _, edge in { { 0, 59.7, 140, 0.6 }, { 0, -59.7, 140, 0.6 }, { 69.7, 0, 0.6, 120 }, { -69.7, 0, 0.6, 120 } } do
			Kit.part(ctx.Decor, "Skirting", Vector3.new(edge[3], 2.4, edge[4]), at(ctx, edge[1], 1.2, edge[2]), WHITE, M.Wood)
			Kit.neon(ctx.Decor, Vector3.new(edge[3], 0.5, edge[4]), at(ctx, edge[1], height - 2, edge[2]), PINK)
		end
		local lamp = Kit.cylinder(ctx.Decor, "CeilingLamp", 1.2, 16, at(ctx, 0, height - 0.6, 6), rgb(255, 244, 222), M.Neon)
		Kit.cylinder(ctx.Decor, "LampRim", 0.6, 17.4, at(ctx, 0, height - 0.3, 6), WHITE)
		Kit.light(lamp, rgb(255, 236, 205), 60, 1.6)

		-- Round gamer rug with a crosshair on it
		local rugColor = rgb(46, 46, 80)
		Kit.cylinder(ctx.Decor, "Rug", 0.2, 52, at(ctx, 2, 0.1, 6), PINK, M.Fabric)
		Kit.cylinder(ctx.Decor, "Rug", 0.4, 48, at(ctx, 2, 0.2, 6), rugColor, M.Fabric)
		for _, turn in { 0, 90 } do
			Kit.part(ctx.Decor, "RugLine", Vector3.new(40, 0.1, 1), at(ctx, 2, 0.45, 6, turn), PINK, M.Fabric)
		end
		Kit.cylinder(ctx.Decor, "RugRing", 0.2, 16, at(ctx, 2, 0.5, 6), PINK, M.Fabric)
		Kit.cylinder(ctx.Decor, "Rug", 0.3, 13.4, at(ctx, 2, 0.55, 6), rugColor, M.Fabric)
		Kit.cylinder(ctx.Decor, "RugDot", 0.2, 2.2, at(ctx, 2, 0.75, 6), PINK, M.Fabric)

		-- The desk along the left wall, 18 tall: run under it, or climb the
		-- ramp onto it. Drawers at the far end, the PC underneath.
		local deskColor = rgb(34, 34, 42)
		Kit.part(ctx.Structure, "Desk", Vector3.new(18, 1.2, 36), at(ctx, -60.6, 17.4, 16), deskColor)
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.15, 0.3, 36), at(ctx, -51.55, 17.2, 16), PINK), PINK, 18, 1)
		for _, x in { -53.2, -68 } do
			Kit.part(ctx.Structure, "DeskLeg", Vector3.new(1.6, 16.8, 1.6), at(ctx, x, 8.4, -0.8), BLACK, M.Metal)
		end
		Kit.neon(ctx.Decor, Vector3.new(0.1, 14, 0.5), at(ctx, -52.35, 8.4, -0.8), PINK)
		Kit.part(ctx.Structure, "Drawers", Vector3.new(16, 16.8, 10), at(ctx, -60.6, 8.4, 28.8), deskColor)
		for _, y in { 2.9, 8.4, 13.9 } do
			Kit.part(ctx.Decor, "Drawer", Vector3.new(0.2, 4.8, 9), at(ctx, -52.5, y, 28.8), rgb(54, 56, 68))
			Kit.part(ctx.Decor, "Handle", Vector3.new(0.4, 0.6, 3.6), at(ctx, -52.2, y + 1.3, 28.8), STEEL, M.Metal)
		end
		bigTower(ctx, -61, 6, 0, CYAN)
		-- Monitor, facing into the room, with the cheat menu up
		Kit.part(ctx.Decor, "MonitorFoot", Vector3.new(5, 0.4, 6), at(ctx, -65.4, 18.2, 16), BLACK, M.Metal)
		Kit.part(ctx.Decor, "MonitorNeck", Vector3.new(1, 7, 1.6), at(ctx, -66.4, 21.5, 16), BLACK, M.Metal)
		Kit.part(ctx.Structure, "Monitor", Vector3.new(0.9, 9.8, 17.4), at(ctx, -65.6, 26.7, 16), BLACK)
		Kit.part(ctx.Decor, "MonitorBack", Vector3.new(1.2, 6, 10), at(ctx, -66.6, 26.7, 16), BLACK)
		local screen = Kit.neon(ctx.Decor, Vector3.new(0.1, 9, 16.6), at(ctx, -65.1, 26.7, 16), rgb(26, 14, 52))
		Kit.text(screen, Enum.NormalId.Right, {
			line("AIMBOT: ON", PINK, 0.1, 0.28),
			line("ESP: ON", CYAN, 0.44, 0.2),
			line("SUS 0%", LIME, 0.72, 0.16),
		})
		Kit.light(screen, rgb(170, 120, 255), 22, 1)
		for _, note in { { 30.4, 23.6, YELLOW, "BUY AIMBOT" }, { 23.2, 8.4, PINK, "DON'T GET BANNED" } } do
			local sticky = Kit.part(ctx.Decor, "StickyNote", Vector3.new(0.05, 1.9, 1.9), at(ctx, -65.02, note[1], note[2]), note[3])
			Kit.text(sticky, Enum.NormalId.Right, { line(note[4], BLACK, 0.2, 0.6, Enum.Font.GothamBold) })
		end
		-- Keyboard with rainbow keys, mouse on its pad, speakers and a can
		Kit.part(ctx.Decor, "Keyboard", Vector3.new(3.6, 0.6, 11), at(ctx, -57.6, 18.3, 15), BLACK)
		for index, rowColor in { PINK, PURPLE, CYAN } do
			Kit.neon(ctx.Decor, Vector3.new(0.7, 0.12, 10.2), at(ctx, -58.7 + (index - 1) * 1.1, 18.62, 15), rowColor)
		end
		Kit.part(ctx.Decor, "MousePad", Vector3.new(6.5, 0.1, 7), at(ctx, -57.8, 18.05, 26.5), rgb(44, 40, 70), M.Fabric)
		blob(ctx.Decor, "Mouse", Vector3.new(2.8, 1.2, 1.8), at(ctx, -57.4, 18.6, 26.5), BLACK, M.SmoothPlastic)
		Kit.neon(ctx.Decor, Vector3.new(0.9, 0.1, 0.3), at(ctx, -57.9, 19.12, 26.5), PINK)
		for _, z in { 3.5, 28.5 } do
			Kit.part(ctx.Decor, "Speaker", Vector3.new(3.2, 5.2, 3.2), at(ctx, -66.4, 20.6, z), rgb(44, 46, 56))
			tube(ctx.Decor, "Woofer", 0.2, 2.2, at(ctx, -64.7, 19.8, z), BLACK)
			tube(ctx.Decor, "Tweeter", 0.2, 1, at(ctx, -64.7, 22, z), STEEL, M.Metal)
		end
		can(ctx, at(ctx, -56, 18, 4, 20), LIME, BLACK)

		-- Ramp onto the desk: a stack of game boxes, a book leaning up to it
		-- from the floor, and another book from the stack up to the desk
		gameBox(ctx, -61.4, -19.3, 0, -3, Vector3.new(15, 3.4, 11), rgb(214, 52, 52), "BLOCK QUEST 3")
		gameBox(ctx, -60.6, -18.6, 3.4, 7, Vector3.new(13.6, 3, 10.2), rgb(30, 160, 170), "TURBO KARTZ")
		gameBox(ctx, -61, -19, 6.4, 0, Vector3.new(12.5, 3, 9.6), rgb(124, 64, 210), "DUNGEON DASH")
		book(ctx, spot(ctx, -34.5, 0.1, -19), spot(ctx, -54.8, 9.4, -19), 9, rgb(226, 146, 30), "1001 CHEAT CODES")
		book(ctx, spot(ctx, -61, 9.4, -16.4), spot(ctx, -61, 18, -2.1), 9, rgb(40, 110, 230), "PRO GAMER GUIDE")

		bigChair(ctx, -42, 15, 90, PINK)

		-- Trash bin full of paper balls, with a couple that missed
		Kit.cylinder(ctx.Structure, "TrashBin", 10, 8, at(ctx, -40, 5, -40), rgb(86, 196, 170))
		Kit.cylinder(ctx.Decor, "BinRim", 0.8, 8.6, at(ctx, -40, 9.8, -40), WHITE)
		for _, paper in { { -39.2, 10.6, -39.4, 2.8 }, { -41.4, 10.4, -41.2, 2.4 }, { -34, 1.2, -36, 2.4 }, { -45.5, 1.1, -33, 2.2 } } do
			Kit.ball(ctx.Decor, "Paper", paper[4], at(ctx, paper[1], paper[2], paper[3]), rgb(236, 236, 228))
		end

		-- The bed along the right wall: legs tall enough to crawl under, a
		-- blanket hanging over the side, pillows and underglow
		local bedFrame = rgb(236, 230, 220)
		for _, leg in { { 47.4, 10.8 }, { 68.6, 10.8 }, { 47.4, 57.4 }, { 68.6, 57.4 } } do
			Kit.part(ctx.Structure, "BedLeg", Vector3.new(2.4, 6.5, 2.4), at(ctx, leg[1], 3.25, leg[2]), bedFrame, M.Wood)
		end
		Kit.part(ctx.Structure, "BedFrame", Vector3.new(24, 2.2, 49), at(ctx, 58, 7.6, 34), bedFrame, M.Wood)
		Kit.part(ctx.Structure, "Mattress", Vector3.new(23.2, 3.6, 48), at(ctx, 58, 10.5, 34.2), rgb(240, 242, 248), M.Fabric)
		local blanket = rgb(118, 70, 200)
		Kit.part(ctx.Decor, "Blanket", Vector3.new(24.4, 0.6, 32), at(ctx, 58, 12.6, 25.3), blanket, M.Fabric)
		Kit.part(ctx.Decor, "Blanket", Vector3.new(0.5, 5.4, 32), at(ctx, 45.75, 10.2, 25.3), blanket, M.Fabric)
		Kit.part(ctx.Decor, "Blanket", Vector3.new(24.4, 5.4, 0.5), at(ctx, 58, 10.2, 9.05), blanket, M.Fabric)
		for _, z in { 15, 20 } do
			Kit.part(ctx.Decor, "BlanketStripe", Vector3.new(24.5, 0.05, 2), at(ctx, 58, 12.92, z), CYAN, M.Fabric)
			Kit.part(ctx.Decor, "BlanketStripe", Vector3.new(0.55, 5.45, 2), at(ctx, 45.75, 10.2, z), CYAN, M.Fabric)
		end
		tube(ctx.Decor, "Sheet", 24.6, 1.4, at(ctx, 58, 12.95, 41.3), WHITE, M.Fabric)
		blob(ctx.Decor, "Pillow", Vector3.new(15, 3.4, 7.5), at(ctx, 58, 13.9, 52.5) * CFrame.Angles(math.rad(-8), 0, 0), WHITE)
		local pillow = Kit.part(ctx.Decor, "Pillow", Vector3.new(6.4, 6, 1.6), at(ctx, 51, 15.4, 47.5, -15) * CFrame.Angles(math.rad(15), 0, 0), PINK, M.Fabric)
		Kit.text(pillow, FRONT, { line("GG", WHITE, 0.2, 0.6) })
		Kit.part(ctx.Structure, "Headboard", Vector3.new(24.4, 19, 1.2), at(ctx, 58, 9.5, 59.3), rgb(72, 76, 96), M.Fabric)
		Kit.part(ctx.Decor, "HeadboardCap", Vector3.new(25, 1, 2), at(ctx, 58, 19.4, 59), bedFrame, M.Wood)
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.2, 0.25, 48), at(ctx, 45.95, 6.6, 34), PINK), PINK, 14, 1.2)
		Kit.neon(ctx.Decor, Vector3.new(23.6, 0.25, 0.2), at(ctx, 58, 6.6, 9.45), PINK)

		-- Toy chest and a shoebox next to the bed: jump from one to the other
		-- to get up on the bed
		Kit.part(ctx.Structure, "ToyChest", Vector3.new(9, 6, 13), at(ctx, 40.9, 3, 24), rgb(60, 130, 230), M.Wood)
		Kit.part(ctx.Structure, "ChestLid", Vector3.new(9.6, 1.2, 13.6), at(ctx, 40.9, 6.6, 24), rgb(40, 96, 190), M.Wood)
		local label = Kit.part(ctx.Decor, "ChestLabel", Vector3.new(0.2, 2.2, 6.5), at(ctx, 36.3, 3.4, 24), YELLOW)
		Kit.text(label, Enum.NormalId.Left, { line("TOYS", BLACK, 0.1, 0.8) })
		Kit.part(ctx.Decor, "Latch", Vector3.new(0.3, 1.4, 1.4), at(ctx, 36.2, 6, 24), GOLD, M.Metal)
		local shoebox = Kit.part(ctx.Structure, "Shoebox", Vector3.new(8, 3.2, 6), at(ctx, 39.5, 1.6, 12.5, 8), rgb(255, 140, 40))
		Kit.text(shoebox, FRONT, { line("KICKS", WHITE, 0.2, 0.6) })
		Kit.part(ctx.Structure, "ShoeboxLid", Vector3.new(8.4, 0.7, 6.4), at(ctx, 39.5, 3.55, 12.5, 8), WHITE)

		-- Nightstand with a lamp and an alarm clock (it's way past bedtime)
		Kit.part(ctx.Structure, "Nightstand", Vector3.new(10, 11, 9), at(ctx, 39.5, 5.5, 53.5), WHITE, M.Wood)
		Kit.part(ctx.Decor, "NightstandTop", Vector3.new(10.6, 0.6, 9.6), at(ctx, 39.5, 11.3, 53.5), OAK, M.Wood)
		Kit.part(ctx.Decor, "Drawer", Vector3.new(8.6, 3.8, 0.2), at(ctx, 39.5, 8.2, 48.9), rgb(226, 226, 232), M.Wood)
		Kit.part(ctx.Decor, "Handle", Vector3.new(3, 0.5, 0.4), at(ctx, 39.5, 8.6, 48.6), STEEL, M.Metal)
		Kit.cylinder(ctx.Decor, "LampBase", 0.6, 3.4, at(ctx, 41.5, 11.9, 55), BLACK)
		Kit.cylinder(ctx.Decor, "LampStem", 4, 0.5, at(ctx, 41.5, 14.2, 55), GOLD, M.Metal)
		local shade = Kit.cylinder(ctx.Decor, "LampShade", 3.8, 5.2, at(ctx, 41.5, 17.6, 55), rgb(255, 236, 200), M.Neon)
		Kit.light(shade, rgb(255, 220, 170), 24, 1.2)
		local clock = Kit.part(ctx.Decor, "AlarmClock", Vector3.new(4, 2.4, 1.8), at(ctx, 36.6, 12.8, 51.8, 15), BLACK)
		local clockFace = Kit.neon(ctx.Decor, Vector3.new(3.4, 1.7, 0.05), clock.CFrame * CFrame.new(0, 0, -0.92), rgb(30, 6, 10))
		Kit.text(clockFace, FRONT, { line("3:07 AM", RED, 0.15, 0.7) })

		-- TV stand against the back wall, open shelves you can hide in, a
		-- big TV on top and the console standing next to it
		Kit.part(ctx.Decor, "StandTop", Vector3.new(29, 0.8, 9.2), at(ctx, -20, 9.2, 55.3), OAK, M.Wood)
		Kit.part(ctx.Structure, "StandShelf", Vector3.new(28, 0.8, 8.6), at(ctx, -20, 0.4, 55.4), WHITE, M.Wood)
		for _, x in { -33.6, -20, -6.4 } do
			Kit.part(ctx.Structure, "StandSide", Vector3.new(0.8, 8, 8.6), at(ctx, x, 4.8, 55.4), WHITE, M.Wood)
		end
		Kit.part(ctx.Structure, "StandBack", Vector3.new(28, 8, 0.4), at(ctx, -20, 4.8, 59.5), WHITE, M.Wood)
		for index, caseColor in { RED, CYAN, YELLOW, GREEN } do
			Kit.part(ctx.Decor, "GameCase", Vector3.new(0.8, 4.6, 3.4), at(ctx, -32.6 + index * 1, 3.1, 56.5), caseColor)
		end
		for index, boxColor in { PURPLE, PINK } do
			Kit.part(ctx.Decor, "GameCase", Vector3.new(5, 0.9, 4), at(ctx, -12.5, 0.35 + index * 0.9, 56.2, index * 12), boxColor)
		end
		Kit.part(ctx.Decor, "TvFoot", Vector3.new(9, 0.4, 4), at(ctx, -20, 9.8, 56.4), BLACK, M.Metal)
		Kit.part(ctx.Decor, "TvNeck", Vector3.new(1.4, 2.4, 0.8), at(ctx, -20, 11, 57), BLACK, M.Metal)
		Kit.part(ctx.Structure, "Tv", Vector3.new(32, 18, 1.2), at(ctx, -20, 21, 57.6), BLACK)
		local tv = Kit.neon(ctx.Decor, Vector3.new(31, 17, 0.1), at(ctx, -20, 21, 56.95), rgb(20, 16, 40))
		Kit.text(tv, FRONT, { line("EARN ESP", PINK, 0.22, 0.34), line("PRESS ANY BUTTON", WHITE, 0.66, 0.1, Enum.Font.GothamBold) })
		Kit.light(tv, rgb(160, 120, 255), 30, 1.2)
		console(ctx, -1.5, 52, 0)
		controller(ctx, 8, 34, 25, rgb(36, 36, 44))
		cable(ctx, { { 6.6, 31.3 }, { 2.5, 40 }, { -1.5, 47.6 } })

		-- Wall socket with the TV plugged in
		Kit.part(ctx.Decor, "Socket", Vector3.new(4, 6.4, 0.3), at(ctx, -38, 6.5, 59.85), WHITE)
		for _, y in { 7.9, 5.1 } do
			local outlet = Kit.part(ctx.Decor, "Outlet", Vector3.new(2.6, 2.2, 0.1), at(ctx, -38, y, 59.65), rgb(222, 222, 228))
			Kit.text(outlet, FRONT, { line("| |", rgb(60, 60, 66), 0.1, 0.8) })
		end
		Kit.part(ctx.Decor, "Plug", Vector3.new(2.4, 2, 2), at(ctx, -38, 5.1, 58.6), BLACK)
		passThrough(Kit.part(ctx.Decor, "Cable", Vector3.new(0.6, 4.2, 0.6), at(ctx, -38, 2.2, 58.6), BLACK))
		cable(ctx, { { -38, 58.6 }, { -33.2, 58.6 } })

		-- Window with afternoon sun, curtains and a tree outside
		local sky = Kit.neon(ctx.Decor, Vector3.new(28, 22, 0.2), at(ctx, 16, 30, 59.88), rgb(150, 205, 255))
		Kit.light(sky, rgb(255, 246, 225), 60, 2, "SurfaceLight", FRONT)
		for _, cloud in { { 8, 36.5, 8, 3 }, { 11.5, 38, 5, 2.4 }, { 23, 34, 9, 2.6 } } do
			blob(ctx.Decor, "Cloud", Vector3.new(cloud[3], cloud[4], 0.1), at(ctx, cloud[1], cloud[2], 59.74), WHITE, M.Neon)
		end
		tube(ctx.Decor, "Sun", 0.1, 3.6, at(ctx, 26, 38.5, 59.76) * TURN, rgb(255, 236, 140), M.Neon)
		blob(ctx.Decor, "TreeTop", Vector3.new(10, 8, 0.1), at(ctx, 25, 22, 59.74), rgb(70, 150, 80), M.SmoothPlastic)
		local trim = WHITE
		Kit.part(ctx.Decor, "WindowFrame", Vector3.new(31.2, 1.6, 1), at(ctx, 16, 41.8, 59.5), trim, M.Wood)
		Kit.part(ctx.Decor, "WindowFrame", Vector3.new(31.2, 1.6, 1), at(ctx, 16, 18.2, 59.5), trim, M.Wood)
		for _, x in { 0.4, 31.6 } do
			Kit.part(ctx.Decor, "WindowFrame", Vector3.new(1.6, 25.2, 1), at(ctx, x, 30, 59.5), trim, M.Wood)
		end
		Kit.part(ctx.Decor, "Mullion", Vector3.new(0.9, 22, 0.8), at(ctx, 16, 30, 59.55), trim, M.Wood)
		Kit.part(ctx.Decor, "Mullion", Vector3.new(28, 0.9, 0.8), at(ctx, 16, 30, 59.55), trim, M.Wood)
		Kit.part(ctx.Decor, "WindowSill", Vector3.new(33, 1, 3.2), at(ctx, 16, 17.3, 58.6), trim, M.Wood)
		for _, side in { -1, 1 } do
			for fold = 0, 2 do
				local foldColor = if fold == 1 then darker(PURPLE, 0.25) else PURPLE
				Kit.part(ctx.Decor, "Curtain", Vector3.new(2.8, 31, 0.6), at(ctx, 16 + side * (14.9 + fold * 2.7), 29, if fold == 1 then 59.1 else 58.7), foldColor, M.Fabric)
			end
			Kit.ball(ctx.Decor, "RodEnd", 1.6, at(ctx, 16 + side * 23.4, 45.2, 58.9), WHITE)
		end
		tube(ctx.Decor, "CurtainRod", 46, 0.8, at(ctx, 16, 45.2, 58.9), WHITE, M.Metal)

		-- Posters, a shelf with a trophy, a neon sign and a pennant
		local _, frame = poster(ctx, -69.9, 39, 16, -90, 22, 14, rgb(16, 16, 22), PINK, {
			line("EARN ESP", WHITE, 0.05, 0.22),
			line("CHEAT YOUR WAY TO THE TOP", PINK, 0.84, 0.1, Enum.Font.GothamBold),
		})
		local sight = frame * CFrame.new(0, -0.4, 0)
		tube(ctx.Decor, "Crosshair", 0.05, 5.6, sight * CFrame.new(0, 0, -0.2) * TURN, PINK, M.Neon)
		for _, size in { Vector3.new(8, 0.5, 0.05), Vector3.new(0.5, 8, 0.05) } do
			Kit.neon(ctx.Decor, size, sight * CFrame.new(0, 0, -0.24), PINK)
		end
		tube(ctx.Decor, "Crosshair", 0.05, 4.4, sight * CFrame.new(0, 0, -0.29) * TURN, rgb(16, 16, 22))
		tube(ctx.Decor, "Crosshair", 0.05, 0.8, sight * CFrame.new(0, 0, -0.33) * TURN, PINK, M.Neon)
		poster(ctx, -54, 37, 59.9, 0, 11, 14, rgb(46, 22, 90), BLACK, {
			line("BOT", YELLOW, 0.08, 0.2, Enum.Font.Arcade),
			line("BLASTER", YELLOW, 0.3, 0.2, Enum.Font.Arcade),
			line("INSERT COIN", WHITE, 0.82, 0.08, Enum.Font.Arcade),
		})
		Kit.part(ctx.Decor, "Shelf", Vector3.new(16, 0.8, 3), at(ctx, -54, 24, 58.5), OAK, M.Wood)
		Kit.part(ctx.Decor, "TrophyBase", Vector3.new(2.4, 1.2, 2.4), at(ctx, -58, 25, 58.4), BLACK)
		Kit.cylinder(ctx.Decor, "Trophy", 1.6, 0.8, at(ctx, -58, 26.4, 58.4), GOLD, M.Metal)
		Kit.ball(ctx.Decor, "Trophy", 3, at(ctx, -58, 28.3, 58.4), GOLD, M.Metal)
		Kit.cylinder(ctx.Decor, "Trophy", 0.6, 3.1, at(ctx, -58, 29.6, 58.4), GOLD, M.Metal)
		for index, caseColor in { RED, BLUE, YELLOW } do
			Kit.part(ctx.Decor, "GameCase", Vector3.new(0.7, 4.2, 3), at(ctx, -52 + index * 0.8, 26.5, 58.4), caseColor)
		end
		Kit.sign(ctx, 69.5, 31, 34, 90, 18, 5, "GAME ON", PINK)
		local flag = at(ctx, 69.85, 30, -12)
		Kit.wedge(ctx.Decor, "Pennant", Vector3.new(0.2, 3, 12), flag * CFrame.new(0, 1.5, 0), CYAN, M.Fabric)
		Kit.wedge(ctx.Decor, "Pennant", Vector3.new(0.2, 3, 12), flag * CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, math.pi), CYAN, M.Fabric)
		Kit.part(ctx.Decor, "PennantStick", Vector3.new(0.5, 7.4, 0.5), flag * CFrame.new(0, 0, 6.2), WHITE, M.Wood)

		-- The door behind the spawn, with a sign hung on the handle
		Kit.part(ctx.Decor, "Door", Vector3.new(18, 38, 0.6), at(ctx, -36, 19, -59.7), rgb(240, 236, 228), M.Wood)
		for _, y in { 10, 28 } do
			Kit.part(ctx.Decor, "DoorPanel", Vector3.new(13, 14, 0.2), at(ctx, -36, y, -59.3), rgb(230, 226, 216), M.Wood)
		end
		for _, x in { -45.7, -26.3 } do
			Kit.part(ctx.Decor, "DoorFrame", Vector3.new(1.4, 39.4, 1), at(ctx, x, 19.7, -59.5), WHITE, M.Wood)
		end
		Kit.part(ctx.Decor, "DoorFrame", Vector3.new(20.8, 1.4, 1), at(ctx, -36, 38.7, -59.5), WHITE, M.Wood)
		Kit.part(ctx.Decor, "KnobPlate", Vector3.new(1.2, 3.6, 0.2), at(ctx, -29.5, 18, -59.3), GOLD, M.Metal)
		Kit.ball(ctx.Decor, "Knob", 1.8, at(ctx, -29.5, 18.6, -58.8), GOLD, M.Metal)
		local hanger = Kit.part(ctx.Decor, "DoorSign", Vector3.new(4.4, 6.4, 0.15), at(ctx, -29.5, 14, -58.9), PINK)
		Kit.text(hanger, BACK, { line("DO NOT DISTURB", WHITE, 0.1, 0.36), line("RANKED MATCH", BLACK, 0.58, 0.3, Enum.Font.GothamBold) })

		-- Floor clutter for cover: toy bricks, a can tower, headphones, a ball
		local stackA = at(ctx, -22, 0, -24, 15)
		brick(ctx, stackA, 4, 2, RED, { 1, 2 })
		brick(ctx, stackA * CFrame.new(-3, 3.6, 0), 2, 2, BLUE)
		brick(ctx, at(ctx, 8, 0, -16, -25), 4, 2, GREEN)
		local stackC = at(ctx, -12, 0, 30, 40)
		brick(ctx, stackC, 4, 2, YELLOW, { 2, 3 })
		brick(ctx, stackC * CFrame.new(0, 3.6, 0) * CFrame.Angles(0, math.rad(90), 0), 4, 2, RED)
		brick(ctx, at(ctx, -34, 0, 4, 10), 2, 2, PINK)
		-- A pyramid of FRAG FUEL cans, and a few knocked over
		local flavors = { { LIME, BLACK }, { PINK, WHITE }, { CYAN, BLACK }, { YELLOW, BLACK } }
		for row = 0, 3 do
			for index = 0, 3 - row do
				can(ctx, at(ctx, 22 + (index - (3 - row) / 2) * 2.7, row * 3.45, 4), flavors[row + 1][1], flavors[row + 1][2])
			end
		end
		tippedCan(ctx, 29, 8, 35, PINK, WHITE)
		tippedCan(ctx, 15, -1, -60, LIME, BLACK)
		headphones(ctx, 34, -26, 30, PINK)
		cable(ctx, { { 36.5, -30 }, { 40, -36 }, { 46, -38 } })
		Kit.ball(ctx.Structure, "Ball", 8, at(ctx, -16, 4, 10), rgb(255, 120, 40))
		tube(ctx.Decor, "BallStripe", 1.2, 8.15, at(ctx, -16, 4, 10) * CFrame.Angles(0, 0, math.rad(60)), WHITE)
	end,
}

-- Streamer House props ---------------------------------------------------------------

-- An award plaque for hitting a follower count, facing -Z from `frame` (its
-- middle). A dark frame, a metal plate, a crosshair badge and a label;
-- `scale` 1 is 5 x 6.4. Returns the frame part.
local function plaque(ctx, frame, scale, metal, title, subtitle)
	local back = Kit.part(ctx.Decor, "PlaqueFrame", Vector3.new(5, 6.4, 0.3) * scale, frame, rgb(26, 26, 32), M.Wood)
	local plate = Kit.part(ctx.Decor, "Plaque", Vector3.new(4.2 * scale, 5.6 * scale, 0.1), frame * CFrame.new(0, 0, -0.15 * scale - 0.05), metal, M.Metal)
	plate.Reflectance = 0.15
	Kit.text(plate, FRONT, { line(title, rgb(30, 30, 38), 0.66, 0.15), line(subtitle, rgb(30, 30, 38), 0.83, 0.08, Enum.Font.GothamBold) })
	-- The badge: a dark disc with a metal crosshair over it
	local badge = frame * CFrame.new(0, 0.75 * scale, -0.15 * scale - 0.12)
	tube(ctx.Decor, "Badge", 0.06, 2.6 * scale, badge * TURN, rgb(30, 30, 38))
	for _, size in { Vector3.new(3.2 * scale, 0.24 * scale, 0.05), Vector3.new(0.24 * scale, 3.2 * scale, 0.05) } do
		Kit.part(ctx.Decor, "Crosshair", size, badge * CFrame.new(0, 0, -0.06), darker(metal, 0.1), M.Metal)
	end
	return back
end

-- A potted plant: a round pot with two leafy balls
local function pottedPlant(ctx, x, z, scale, potColor)
	Kit.cylinder(ctx.Structure, "Pot", 3 * scale, 3.4 * scale, at(ctx, x, 1.5 * scale, z), potColor or WHITE)
	Kit.ball(ctx.Decor, "Leaves", 4.4 * scale, at(ctx, x, 4.4 * scale, z), GREEN, M.Grass)
	Kit.ball(ctx.Decor, "Leaves", 3 * scale, at(ctx, x + 0.9 * scale, 6.4 * scale, z - 0.5 * scale), rgb(70, 190, 90), M.Grass)
end

-- A ring light on a stand for streaming, 8.8 tall, facing -Z when rot is 0
local function ringLight(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.cylinder(ctx.Decor, "LightStand", 0.3, 2.4, base * CFrame.new(0, 0.15, 0), BLACK, M.Metal)
	Kit.cylinder(ctx.Decor, "LightPole", 5.4, 0.3, base * CFrame.new(0, 3, 0), BLACK, M.Metal)
	local ring = base * CFrame.new(0, 7, 0)
	local glow = tube(ctx.Decor, "RingLight", 0.2, 3.6, ring * TURN, WHITE, M.Neon)
	tube(ctx.Decor, "RingLight", 0.24, 2.6, ring * TURN, BLACK)
	Kit.light(glow, rgb(255, 245, 235), 14, 1.2)
	return glow
end

-- A pool lounger 6.6 long with its backrest at +X and a cushion
local function lounger(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	local bed = Kit.part(ctx.Structure, "Lounger", Vector3.new(6.6, 0.5, 2.6), base * CFrame.new(0, 1.3, 0), WHITE)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "LoungerLeg", Vector3.new(0.4, 1.05, 2.6), base * CFrame.new(side * 2.8, 0.525, 0), STEEL, M.Metal)
	end
	Kit.part(ctx.Decor, "Cushion", Vector3.new(4.2, 0.4, 2.3), base * CFrame.new(-1, 1.75, 0), color, M.Fabric)
	Kit.part(ctx.Decor, "LoungerBack", Vector3.new(2.6, 0.5, 2.4), base * CFrame.new(2.5, 2.2, 0) * CFrame.Angles(0, 0, math.rad(40)), color, M.Fabric)
	return bed
end

-- A pool table (12 x 6.6) with blue felt, corner pockets, a few balls and
-- a cue left lying on it
local function poolTable(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local wood = rgb(84, 50, 34)
	local body = Kit.part(ctx.Structure, "PoolTable", Vector3.new(11, 1.6, 5.6), base * CFrame.new(0, 2.2, 0), wood, M.Wood)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "TableLeg", Vector3.new(1.2, 1.4, 4.4), base * CFrame.new(side * 3.8, 0.7, 0), darker(wood, 0.3), M.Wood)
	end
	Kit.part(ctx.Decor, "Rails", Vector3.new(12, 0.5, 6.6), base * CFrame.new(0, 3.25, 0), wood, M.Wood)
	Kit.part(ctx.Decor, "Felt", Vector3.new(11, 0.06, 5.6), base * CFrame.new(0, 3.53, 0), rgb(36, 110, 190), M.Fabric)
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Kit.cylinder(ctx.Decor, "Pocket", 0.1, 0.8, base * CFrame.new(corner[1] * 5.45, 3.58, corner[2] * 2.75), BLACK)
	end
	for _, ball in { { -2.6, 0.8, WHITE }, { 2.2, -1.1, RED } } do
		Kit.ball(ctx.Decor, "PoolBall", 0.5, base * CFrame.new(ball[1], 3.81, ball[2]), ball[3])
	end
	Kit.part(ctx.Decor, "Cue", Vector3.new(0.18, 0.18, 9), base * CFrame.new(-0.5, 3.65, 0.3) * CFrame.Angles(0, math.rad(70), 0), OAK, M.Wood)
	return body
end

Maps.StreamerHouse = {
	Name = "Streamer House", Theme = "Mansion", HalfX = 70, HalfZ = 60,
	Build = function(ctx)
		local height = 26
		local upstairs = 12 -- the balcony floor's height
		local wallColor = rgb(236, 232, 226)
		Kit.floor(ctx, rgb(222, 218, 212), M.Marble)
		Kit.boundary(ctx, height, wallColor, M.Plaster)
		Kit.ceiling(ctx, height, rgb(246, 244, 240), M.Plaster)
		for _, edge in { { 0, 59.7, 140, 0.6 }, { 0, -59.7, 140, 0.6 }, { 69.7, 0, 0.6, 120 }, { -69.7, 0, 0.6, 120 } } do
			Kit.part(ctx.Decor, "Skirting", Vector3.new(edge[3], 1.2, edge[4]), at(ctx, edge[1], 0.6, edge[2]), rgb(40, 36, 44), M.Wood)
			Kit.neon(ctx.Decor, Vector3.new(edge[3], 0.4, edge[4]), at(ctx, edge[1], height - 1.6, edge[2]), PURPLE)
		end
		for _, x in { -24, 30 } do
			for _, z in { -30, 20 } do
				Kit.light(Kit.neon(ctx.Decor, Vector3.new(3, 0.2, 3), at(ctx, x, height - 0.1, z), rgb(255, 240, 215)), rgb(255, 230, 200), 36, 1.1)
			end
		end

		-- Foyer: the front door behind the spawn, a doormat and two plants
		for _, side in { -1, 1 } do
			Kit.part(ctx.Decor, "FrontDoor", Vector3.new(6, 14, 0.6), at(ctx, side * 3.1, 7, -59.7), rgb(40, 34, 32), M.Wood)
			Kit.part(ctx.Decor, "DoorHandle", Vector3.new(0.4, 4, 0.4), at(ctx, side * 0.9, 7.5, -59.2), GOLD, M.Metal)
			Kit.part(ctx.Decor, "DoorFrame", Vector3.new(1, 15, 1), at(ctx, side * 6.7, 7.5, -59.5), GOLD, M.Metal)
			pottedPlant(ctx, side * 15, -55, 1.3, BLACK)
		end
		Kit.part(ctx.Decor, "DoorFrame", Vector3.new(14.4, 1, 1), at(ctx, 0, 14.5, -59.5), GOLD, M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(12.4, 3.4, 0.2), at(ctx, 0, 16.6, -59.85), rgb(255, 200, 150), 0.3)
		-- A red carpet from the door to the big award in the middle
		Kit.part(ctx.Decor, "RedCarpet", Vector3.new(8, 0.12, 48), at(ctx, 0, 0.06, -34), rgb(170, 20, 40), M.Fabric)
		local mat = Kit.part(ctx.Decor, "Doormat", Vector3.new(10, 0.1, 5), at(ctx, 0, 0.17, -55.5), rgb(40, 40, 46), M.Fabric)
		Kit.text(mat, Enum.NormalId.Top, { line("GG", PINK, 0.15, 0.7) })

		-- Hallway of fame down the left side: a wall with three gaps hides it
		-- from the lounge, and award plaques hang along the outer wall
		local panel = rgb(62, 50, 74)
		for _, segment in { { -44, -30 }, { -20, -2 }, { 8, 26 }, { 36, 44 } } do
			local middle, length = (segment[1] + segment[2]) / 2, segment[2] - segment[1]
			Kit.wall(ctx, -51, middle, length, height, 90, wallColor, M.Plaster)
			Kit.part(ctx.Decor, "Wainscot", Vector3.new(2.3, 6, length + 0.3), at(ctx, -51, 3, middle), panel, M.Wood)
			Kit.part(ctx.Decor, "ChairRail", Vector3.new(2.5, 0.4, length + 0.5), at(ctx, -51, 6.2, middle), GOLD, M.Metal)
		end
		Kit.part(ctx.Decor, "Wainscot", Vector3.new(0.3, 6, 96), at(ctx, -69.85, 3, -4), panel, M.Wood)
		Kit.part(ctx.Decor, "ChairRail", Vector3.new(0.5, 0.4, 96), at(ctx, -69.75, 6.2, -4), GOLD, M.Metal)
		Kit.part(ctx.Decor, "Runner", Vector3.new(8, 0.16, 85), at(ctx, -61, 0.08, 0), rgb(130, 24, 50), M.Fabric)
		local silver, gold, diamond = rgb(206, 210, 220), GOLD, rgb(160, 230, 255)
		for index, award in {
			{ silver, "100K", "FOLLOWERS" },
			{ gold, "1M", "FOLLOWERS" },
			{ diamond, "10M", "FOLLOWERS" },
			{ gold, "CLUTCH", "CLIP OF THE YEAR" },
			{ rgb(255, 120, 150), "0 BANS", "NEVER CAUGHT" },
		} do
			plaque(ctx, at(ctx, -69.8, 10.6, -52 + index * 16, -90), 1.2, award[1], award[2], award[3])
		end
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.3, 0.3, 84), at(ctx, -69.6, 16, -4), rgb(255, 236, 200)), rgb(255, 230, 190), 30, 1)

		-- Lounge: two couches round a coffee table, facing the TV on the
		-- hallway wall, with an arc lamp and a rug
		Kit.part(ctx.Decor, "Rug", Vector3.new(20, 0.2, 26), at(ctx, -39, 0.1, 15), rgb(60, 50, 92), M.Fabric)
		Props.couch(ctx, -30, 17, 90, rgb(84, 70, 140), 9)
		Props.couch(ctx, -41, 4.5, 180, rgb(84, 70, 140), 5)
		Kit.part(ctx.Structure, "CoffeeTable", Vector3.new(4.5, 1.4, 8), at(ctx, -40, 0.9, 17), rgb(40, 36, 44), M.Wood)
		Kit.part(ctx.Decor, "TableTop", Vector3.new(5.5, 0.25, 9), at(ctx, -40, 1.725, 17), rgb(200, 220, 240), M.Glass, 0.3)
		Kit.cylinder(ctx.Decor, "Can", 1, 0.66, at(ctx, -39.6, 2.35, 14.5), LIME, M.Metal)
		Kit.cylinder(ctx.Decor, "Can", 1, 0.66, at(ctx, -40.4, 2.35, 19.4), PINK, M.Metal)
		Kit.part(ctx.Decor, "Tv", Vector3.new(0.6, 9, 16), at(ctx, -49.7, 9.5, 17), BLACK)
		local tv = Kit.neon(ctx.Decor, Vector3.new(0.1, 8.2, 15.2), at(ctx, -49.35, 9.5, 17), rgb(34, 14, 54))
		Kit.text(tv, Enum.NormalId.Right, {
			line("NEW VIDEO", YELLOW, 0.08, 0.16),
			line("I GOT BANNED??", WHITE, 0.32, 0.3),
			line("2.4M VIEWS", PINK, 0.74, 0.13),
		})
		Kit.light(tv, rgb(200, 120, 255), 24, 1)
		Kit.part(ctx.Decor, "Soundbar", Vector3.new(0.8, 0.8, 10), at(ctx, -49.6, 4, 17), BLACK)
		Kit.sign(ctx, -49.6, 18.5, 17, -90, 14, 3, "TEAM CLUTCH", PINK)
		Kit.cylinder(ctx.Decor, "LampBase", 0.4, 3, at(ctx, -26, 0.2, 29), BLACK, M.Metal)
		Kit.cylinder(ctx.Decor, "LampPole", 11, 0.4, at(ctx, -26, 5.9, 29), GOLD, M.Metal)
		Kit.part(ctx.Decor, "LampArm", Vector3.new(7, 0.4, 0.4), at(ctx, -29.3, 11.2, 29), GOLD, M.Metal)
		local shade = Kit.cylinder(ctx.Decor, "LampShade", 1.6, 2.8, at(ctx, -32.5, 10.3, 29), rgb(255, 232, 196), M.Neon)
		Kit.light(shade, rgb(255, 220, 170), 20, 1)

		-- Balcony along the back wall with the streaming room on it, up a
		-- ramp with glowing steps. Bots fight on the ground floor below.
		Kit.part(ctx.Structure, "Balcony", Vector3.new(64, 1, 14), at(ctx, -38, upstairs - 0.5, 53), rgb(80, 62, 52), M.WoodPlanks)
		for _, x in { -52, -30, -8 } do
			Kit.part(ctx.Structure, "Column", Vector3.new(1.6, upstairs - 1, 1.6), at(ctx, x, (upstairs - 1) / 2, 47), WHITE, M.Marble)
		end
		local railing = Kit.part(ctx.Decor, "Railing", Vector3.new(64, 3.4, 0.3), at(ctx, -38, upstairs + 1.7, 46.3), rgb(200, 225, 245), M.Glass, 0.6)
		railing.CanQuery = false -- you can shoot over and through it
		Kit.part(ctx.Decor, "Handrail", Vector3.new(64, 0.4, 0.5), at(ctx, -38, upstairs + 3.6, 46.3), GOLD, M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(64, 0.3, 0.2), at(ctx, -38, upstairs - 0.85, 45.95), PINK)
		Kit.ramp(ctx, 4, 53, 13, upstairs, 20, -90, wallColor, M.Marble)
		local slope = CFrame.lookAt(spot(ctx, 14, 0, 53), spot(ctx, -6, upstairs, 53))
		for step = 1, 4 do
			Kit.neon(ctx.Decor, Vector3.new(13, 0.08, 0.4), slope * CFrame.new(0, 0.04, -step * 4.7), PINK)
		end

		-- The streaming room: desk, ring lights, the LIVE sign, a follower
		-- goal and foam panels on the wall
		local up = table.clone(ctx)
		up.Center = ctx.Center + Vector3.new(0, upstairs, 0)
		Props.gamingDesk(up, -36, 56.4, 0, PINK, PINK)
		ringLight(up, -43.5, 57, 0)
		ringLight(up, -28.5, 57, 0)
		local live = Kit.neon(ctx.Decor, Vector3.new(11, 3.6, 0.4), at(ctx, -36, upstairs + 10.4, 59.7), RED)
		Kit.text(live, FRONT, { { Text = "LIVE", Color = WHITE, Position = UDim2.fromScale(0.3, 0.1), Size = UDim2.fromScale(0.62, 0.8) } })
		Kit.blink(Kit.ball(ctx.Decor, "LiveDot", 1.8, at(ctx, -32.4, upstairs + 10.4, 59.4), WHITE, M.Neon))
		Kit.light(live, RED, 24, 1.2)
		local goal = Kit.part(ctx.Decor, "FollowGoal", Vector3.new(12, 1.4, 0.2), at(ctx, -36, upstairs + 7.4, 59.8), rgb(20, 20, 26))
		Kit.text(goal, FRONT, { line("FOLLOW GOAL  9,998 / 10,000", WHITE, 0.08, 0.5, Enum.Font.GothamBold) })
		Kit.neon(ctx.Decor, Vector3.new(11.4, 0.3, 0.1), at(ctx, -36.05, upstairs + 6.95, 59.66), PINK)
		for _, x in { -48, -24 } do
			for column = 0, 1 do
				for row = 0, 1 do
					local tile = at(ctx, x - 1.1 + column * 2.2, upstairs + 4.4 + row * 2.2, 59.55)
					local flip = (column + row) % 2 == 1
					Kit.wedge(ctx.Decor, "Foam", Vector3.new(2.1, 2.1, 0.8), if flip then tile * CFrame.Angles(0, 0, math.pi) else tile, if flip then PINK else BLACK, M.Fabric)
				end
			end
		end

		-- Pool area: a shallow pool you can walk through (the water doesn't
		-- stop people or bullets), loungers, a float and a wall of windows
		Kit.part(ctx.Decor, "PoolDeck", Vector3.new(48, 0.1, 54), at(ctx, 46, 0.05, 33), rgb(156, 108, 74), M.WoodPlanks)
		Kit.part(ctx.Decor, "PoolFloor", Vector3.new(28, 0.1, 30), at(ctx, 46, 0.15, 31), rgb(50, 150, 210), M.CeramicTiles)
		passThrough(Kit.part(ctx.Decor, "Water", Vector3.new(28, 1, 30), at(ctx, 46, 0.75, 31), rgb(80, 205, 240), M.Glass, 0.35))
		for _, edge in { { 46, 15.2, 31.2, 1.6 }, { 46, 46.8, 31.2, 1.6 }, { 31.2, 31, 1.6, 30 }, { 60.8, 31, 1.6, 30 } } do
			Kit.part(ctx.Decor, "PoolEdge", Vector3.new(edge[3], 0.8, edge[4]), at(ctx, edge[1], 0.4, edge[2]), WHITE, M.Marble)
		end
		passThrough(Kit.neon(ctx.Decor, Vector3.new(28, 0.15, 0.3), at(ctx, 46, 0.3, 45.8), CYAN))
		passThrough(Kit.cylinder(ctx.Decor, "Float", 1, 6, at(ctx, 39, 1.25, 23), PINK))
		passThrough(Kit.cylinder(ctx.Decor, "Float", 1.06, 2.4, at(ctx, 39, 1.25, 23), rgb(80, 196, 236)))
		for _, z in { 20, 32 } do
			lounger(ctx, 25.5, z, 180, if z == 20 then PINK else CYAN)
		end
		Kit.cylinder(ctx.Decor, "UmbrellaBase", 0.6, 2.4, at(ctx, 25.5, 0.3, 26), BLACK)
		Kit.cylinder(ctx.Decor, "UmbrellaPole", 9, 0.4, at(ctx, 25.5, 4.5, 26), WHITE, M.Metal)
		Kit.cylinder(ctx.Decor, "Umbrella", 0.4, 10, at(ctx, 25.5, 9, 26), PINK, M.Fabric)
		Kit.cylinder(ctx.Decor, "Umbrella", 0.6, 5, at(ctx, 25.5, 9.4, 26), WHITE, M.Fabric)
		pottedPlant(ctx, 66, 10, 1.3, WHITE)
		pottedPlant(ctx, 66, 55, 1.3, WHITE)
		Kit.sign(ctx, 46, 18, 59.6, 0, 16, 4, "POOL PARTY", CYAN)
		-- Floor-to-ceiling windows on the right wall: sunset over a city
		for index, band in { { 5, 7, rgb(255, 160, 90) }, { 12, 7, rgb(255, 110, 140) }, { 19.5, 8, rgb(150, 90, 210) } } do
			local sky = Kit.neon(ctx.Decor, Vector3.new(0.2, band[2], 52), at(ctx, 69.85, band[1], 33), band[3])
			if index == 2 then
				Kit.light(sky, rgb(255, 150, 140), 40, 0.9, "SurfaceLight", Enum.NormalId.Left)
			end
		end
		for _, building in { { 14, 6, 6 }, { 23, 4, 9.5 }, { 46, 5, 6.5 } } do
			Kit.part(ctx.Decor, "City", Vector3.new(0.1, building[3], building[2]), at(ctx, 69.7, 1.5 + building[3] / 2, building[1]), rgb(46, 32, 66))
		end
		for _, z in { 7.3, 33, 58.7 } do
			Kit.part(ctx.Decor, "Mullion", Vector3.new(0.6, 22.6, 0.6), at(ctx, 69.6, 12.4, z), BLACK, M.Metal)
		end
		Kit.part(ctx.Decor, "WindowSill", Vector3.new(1, 1.5, 52), at(ctx, 69.4, 0.75, 33), WHITE, M.Marble)

		-- Planters split the pool from the kitchen
		for _, x in { 29, 58 } do
			Kit.box(ctx, x, 2, 14, 2.6, 3.2, rgb(70, 62, 58), M.Wood)
			blob(ctx.Decor, "Hedge", Vector3.new(13.4, 3.4, 3.4), at(ctx, x, 3.6, 2), GREEN, M.Grass)
		end

		-- Kitchen: counters and a fridge along the right wall, an island with
		-- bar stools, and lamps hanging over it
		local cabinet = rgb(44, 46, 58)
		Kit.part(ctx.Structure, "Counter", Vector3.new(6, 3.6, 30), at(ctx, 66.8, 1.8, -29), cabinet)
		Kit.part(ctx.Decor, "Countertop", Vector3.new(6.6, 0.4, 30.4), at(ctx, 66.5, 3.8, -29), WHITE, M.Marble)
		for _, z in { -40, -18 } do
			Kit.part(ctx.Decor, "Handle", Vector3.new(0.3, 0.3, 2.4), at(ctx, 63.65, 3, z), GOLD, M.Metal)
		end
		Kit.part(ctx.Structure, "UpperCabinet", Vector3.new(3.4, 5, 20), at(ctx, 68.3, 12, -31), cabinet)
		Kit.part(ctx.Decor, "Sink", Vector3.new(3, 0.1, 4.4), at(ctx, 65.8, 4.04, -36), rgb(150, 154, 162), M.Metal)
		Kit.part(ctx.Decor, "Faucet", Vector3.new(0.35, 3, 0.35), at(ctx, 68.2, 5.5, -36) * CFrame.Angles(0, 0, math.rad(-25)), STEEL, M.Metal)
		Kit.part(ctx.Decor, "Cooktop", Vector3.new(4, 0.1, 6), at(ctx, 66.2, 4.04, -22), BLACK)
		for _, z in { -23.4, -20.6 } do
			Kit.cylinder(ctx.Decor, "Burner", 0.06, 1.8, at(ctx, 66.2, 4.12, z), rgb(255, 70, 30), M.Neon)
		end
		Kit.part(ctx.Structure, "Fridge", Vector3.new(6, 13, 7), at(ctx, 66.8, 6.5, -47.4), rgb(196, 200, 208), M.Metal)
		for _, z in { -48, -46.8 } do
			Kit.part(ctx.Decor, "FridgeHandle", Vector3.new(0.4, 6, 0.3), at(ctx, 63.5, 7.5, z), STEEL, M.Metal)
		end
		Kit.neon(ctx.Decor, Vector3.new(0.1, 2.4, 1.6), at(ctx, 63.76, 8, -49.6), rgb(40, 90, 130))
		Kit.part(ctx.Structure, "Island", Vector3.new(5.6, 3.6, 16), at(ctx, 44, 1.8, -28), rgb(58, 44, 36), M.Wood)
		Kit.part(ctx.Decor, "IslandTop", Vector3.new(7.2, 0.4, 17.4), at(ctx, 43.6, 3.8, -28), WHITE, M.Marble)
		Kit.neon(ctx.Decor, Vector3.new(0.15, 0.15, 16), at(ctx, 41.15, 0.3, -28), PINK)
		for _, z in { -33, -28, -23 } do
			Kit.cylinder(ctx.Decor, "StoolPole", 2.8, 0.4, at(ctx, 38.6, 1.4, z), STEEL, M.Metal)
			Kit.cylinder(ctx.Structure, "Stool", 0.5, 2.2, at(ctx, 38.6, 3, z), PINK)
		end
		for _, z in { -32, -24 } do
			Kit.part(ctx.Decor, "LampCord", Vector3.new(0.1, 10, 0.1), at(ctx, 44, height - 5, z), BLACK)
			Kit.cylinder(ctx.Decor, "LampShade", 1.6, 2.6, at(ctx, 44, height - 10.8, z), GOLD, M.Metal)
			Kit.light(Kit.neon(ctx.Decor, Vector3.new(1.6, 0.2, 1.6), at(ctx, 44, height - 11.65, z), rgb(255, 230, 190)), rgb(255, 220, 170), 22, 1.2)
		end
		-- Snacks on the island: an open pizza box and a can
		local pizza = at(ctx, 43.6, 4, -26, 10)
		Kit.part(ctx.Decor, "PizzaBox", Vector3.new(3.4, 0.3, 3.4), pizza * CFrame.new(0, 0.15, 0), rgb(214, 180, 130))
		local lid = Kit.part(ctx.Decor, "PizzaLid", Vector3.new(3.4, 3.4, 0.1), pizza * CFrame.new(0, 1.8, 1.75) * CFrame.Angles(math.rad(-12), 0, 0), rgb(214, 180, 130))
		Kit.text(lid, FRONT, { line("PIZZA", RED, 0.3, 0.3) })
		Kit.cylinder(ctx.Decor, "Pizza", 0.12, 3, pizza * CFrame.new(0, 0.36, 0), rgb(240, 170, 60))
		Kit.cylinder(ctx.Decor, "Can", 1, 0.66, at(ctx, 43.2, 4.5, -21), LIME, M.Metal)
		Kit.sign(ctx, 46, 15, -59.6, 180, 16, 3.6, "STAY HYDRATED", LIME)

		-- Podcast corner: a backdrop wall with the show's name, a round table
		-- with two mics and stools, and a camera pointed at it
		local backdrop = Kit.part(ctx.Structure, "Backdrop", Vector3.new(14, 9, 1), at(ctx, -30, 4.5, -23), rgb(30, 26, 40))
		Kit.text(backdrop, FRONT, { line("THE CLUTCH CAST", PINK, 0.2, 0.22), line("EP. 142: WE GOT REPORTED", WHITE, 0.52, 0.1, Enum.Font.GothamBold) })
		Kit.text(backdrop, BACK, { line("TEAM CLUTCH", PINK, 0.3, 0.3) })
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(14.2, 0.3, 1.2), at(ctx, -30, 9.15, -23), PINK), PINK, 18, 1)
		Kit.cylinder(ctx.Structure, "PodcastTable", 0.3, 7, at(ctx, -30, 3, -29.5), OAK, M.Wood)
		Kit.cylinder(ctx.Decor, "TableStem", 2.8, 1.2, at(ctx, -30, 1.4, -29.5), BLACK, M.Metal)
		for _, side in { -1, 1 } do
			local x = -30 + side * 2.2
			Kit.cylinder(ctx.Structure, "Stool", 0.6, 2.4, at(ctx, x, 2.2, -25.4), BLACK)
			Kit.cylinder(ctx.Decor, "StoolPole", 1.9, 0.4, at(ctx, x, 0.95, -25.4), STEEL, M.Metal)
			-- A mic on a short stand, pointed at the host
			Kit.cylinder(ctx.Decor, "MicStand", 1.2, 0.2, at(ctx, x, 3.75, -28), BLACK, M.Metal)
			tube(ctx.Decor, "Mic", 0.9, 0.5, at(ctx, x, 4.5, -27.7) * TURN, BLACK)
			Kit.ball(ctx.Decor, "MicFoam", 0.6, at(ctx, x, 4.5, -27.2), if side < 0 then PINK else CYAN)
		end
		Kit.cylinder(ctx.Decor, "Tripod", 5, 0.3, at(ctx, -30, 2.5, -38), BLACK, M.Metal)
		Kit.part(ctx.Decor, "Camera", Vector3.new(1.6, 1.4, 2.4), at(ctx, -30, 5.6, -38), BLACK)
		tube(ctx.Decor, "Lens", 1, 1, at(ctx, -30, 5.6, -36.5) * TURN, rgb(40, 40, 50))

		-- Out in the middle: the giant 100M award on a dark marble circle, a
		-- pool table and a pile of packages from sponsors
		local award = at(ctx, 0, 0, 2)
		Kit.cylinder(ctx.Decor, "Inlay", 0.16, 20, award * CFrame.new(0, 0.08, 0), rgb(48, 40, 58), M.Marble)
		Kit.part(ctx.Structure, "Plinth", Vector3.new(7, 3, 5), award * CFrame.new(0, 1.5, 0), rgb(30, 30, 36), M.Marble)
		Kit.neon(ctx.Decor, Vector3.new(7.1, 0.2, 5.1), award * CFrame.new(0, 2.9, 0), CYAN)
		local trophy = plaque(ctx, award * CFrame.new(0, 8.2, 0), 1.6, diamond, "100M", "FOLLOWERS")
		trophy.Parent = ctx.Structure -- this one is big enough to hide behind
		poolTable(ctx, 4, 30, 0)
		local pile = at(ctx, 12, 0, -18, 20)
		for _, box in {
			{ Vector3.new(7, 5, 6), CFrame.new(0, 2.5, 0), "PR" },
			{ Vector3.new(5.6, 4, 5), CFrame.new(0.4, 7, 0.2) * CFrame.Angles(0, math.rad(18), 0), "MERCH" },
			{ Vector3.new(4.6, 3.6, 4.4), CFrame.new(6.4, 1.8, -1.2) * CFrame.Angles(0, math.rad(-12), 0), "FRAGILE" },
		} do
			local package = Kit.part(ctx.Structure, "Package", box[1], pile * box[2], rgb(196, 152, 100))
			Kit.text(package, FRONT, { line(box[3], rgb(80, 50, 30), 0.3, 0.4) })
			Kit.part(ctx.Decor, "Tape", Vector3.new(box[1].X + 0.06, box[1].Y + 0.06, 0.9), package.CFrame, rgb(230, 216, 170))
		end
	end,
}

return Maps
