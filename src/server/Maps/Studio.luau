-- Studio maps: Dev Studio, the bright and slightly messy office of the
-- (made-up) developers who ship patches against cheaters, and Classic Place,
-- a love letter to old-school blocky games with a studded baseplate,
-- primary-color bricks, truss ladders and a welcome arch.
--
-- Same format as the other map modules: each map sets its size and lighting
-- theme (themes live in ConfigExtra/MapsStudio.luau), then builds with Kit
-- and Props. The player spawns near (0, -HalfZ + 8) facing the middle, and
-- bots spawn in the far half, so both maps keep those areas open.
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local rgb, M = Kit.rgb, Kit.M
local at = Kit.at

local Maps = {}

local FRONT, BACK = Enum.NormalId.Front, Enum.NormalId.Back
local TURN = CFrame.Angles(0, math.pi, 0) -- turns a piece around to face +Z

local PINK = rgb(255, 46, 99) -- the game's UI accent
local CYAN = rgb(0, 200, 240)
local YELLOW = rgb(255, 214, 60)
local LIME = rgb(130, 230, 90)
local ORANGE = rgb(255, 150, 50)
local PURPLE = rgb(170, 90, 255)
local WHITE = rgb(246, 246, 242)
local BLACK = rgb(24, 24, 30)
local DARK = rgb(56, 58, 68)
local STEEL = rgb(172, 176, 184)
local CARDBOARD = rgb(190, 146, 98)
local LEAF = rgb(70, 150, 70)

-- Shared helpers -----------------------------------------------------------------

-- One line of text for Kit.text or paint(): x, y, width and height are 0 to 1
-- of the face. Leave x out to center it.
local function text(words, color, y, height, font, x, width, align)
	return {
		Text = words,
		Color = color,
		Font = font,
		Align = align or (if x then Enum.TextXAlignment.Left else nil),
		Position = UDim2.fromScale(x or 0.05, y),
		Size = UDim2.fromScale(width or 0.9, height),
	}
end

-- A picture on one face: flat colored blocks { color, x, y, width, height }
-- (0 to 1 of the face) with text on top. Set up like Kit.text. Give `area`
-- ({ x, y, width, height }) to squeeze the whole picture into part of the
-- face, like a screen inside a monitor's bezel.
local function paint(part, face, blocks, lines, area)
	area = area or { 0, 0, 1, 1 }
	local function place(x, y, width, height)
		return UDim2.fromScale(area[1] + x * area[3], area[2] + y * area[4]), UDim2.fromScale(width * area[3], height * area[4])
	end
	local surface = Kit.text(part, face, {})
	for _, block in blocks do
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = block[1]
		frame.Position, frame.Size = place(block[2], block[3], block[4], block[5])
		frame.ZIndex = 1
		frame.Parent = surface
	end
	for _, spec in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position, label.Size = place(spec.Position.X.Scale, spec.Position.Y.Scale, spec.Size.X.Scale, spec.Size.Y.Scale)
		label.Font = spec.Font or Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = spec.Color
		label.TextXAlignment = spec.Align or Enum.TextXAlignment.Center
		label.Rotation = spec.Rotation or 0
		label.Text = spec.Text
		label.ZIndex = 2
		label.Parent = surface
	end
	return surface
end

-- A glowing screen showing a picture (see paint)
local function screen(parent, size, cframe, background, blocks, lines)
	local part = Kit.neon(parent, size, cframe, background)
	part.Name = "Screen"
	paint(part, FRONT, blocks, lines)
	return part
end

-- Dev Studio ---------------------------------------------------------------------

local MARKER = Enum.Font.PermanentMarker
local BOLD = Enum.Font.GothamBold

-- What the desk monitors show: the team's tools (map editor, bug tracker, ban
-- stats, skin designer, cheat replays, team chat). Bright app screens, not
-- walls of code. Each is { background, blocks, lines }.
local MONITORS = {
	{ rgb(36, 40, 52), {
		{ rgb(110, 180, 255), 0.04, 0.17, 0.92, 0.47 },
		{ rgb(80, 170, 80), 0.04, 0.64, 0.92, 0.3 },
		{ rgb(165, 165, 175), 0.6, 0.36, 0.22, 0.28 },
		{ rgb(196, 40, 28), 0.6, 0.32, 0.22, 0.05 },
		{ rgb(245, 205, 50), 0.3, 0.42, 0.06, 0.08 },
		{ rgb(13, 105, 172), 0.29, 0.5, 0.08, 0.1 },
		{ rgb(75, 151, 75), 0.29, 0.6, 0.08, 0.1 },
	}, { text("MAP EDITOR", WHITE, 0.02, 0.12, BOLD) } },
	{ rgb(26, 28, 38), {
		{ PINK, 0, 0, 1, 0.16 },
		{ rgb(255, 60, 60), 0.05, 0.25, 0.05, 0.12 },
		{ ORANGE, 0.05, 0.47, 0.05, 0.12 },
		{ YELLOW, 0.05, 0.69, 0.05, 0.12 },
	}, {
		text("BUG TRACKER", WHITE, 0.02, 0.12, BOLD),
		text("aimbot too strong", WHITE, 0.24, 0.14, BOLD, 0.14, 0.8),
		text("spinbot makes QA dizzy", WHITE, 0.46, 0.14, BOLD, 0.14, 0.8),
		text("noob walks into wall", WHITE, 0.68, 0.14, BOLD, 0.14, 0.8),
	} },
	{ rgb(18, 24, 44), {
		{ CYAN, 0.12, 0.66, 0.12, 0.22 },
		{ CYAN, 0.3, 0.52, 0.12, 0.36 },
		{ PINK, 0.48, 0.4, 0.12, 0.48 },
		{ PINK, 0.66, 0.22, 0.12, 0.66 },
		{ WHITE, 0.08, 0.88, 0.84, 0.02 },
	}, { text("BANS THIS WEEK", WHITE, 0.03, 0.13, BOLD) } },
	{ rgb(40, 22, 62), {
		{ PURPLE, 0.2, 0.42, 0.46, 0.15 },
		{ rgb(70, 70, 80), 0.66, 0.45, 0.24, 0.06 },
		{ rgb(240, 190, 60), 0.32, 0.57, 0.08, 0.2 },
		{ rgb(240, 190, 60), 0.12, 0.44, 0.09, 0.12 },
		{ rgb(255, 150, 255), 0.24, 0.45, 0.3, 0.03 },
	}, { text("SKIN DESIGNER", WHITE, 0.03, 0.12, BOLD), text("GALAXY", rgb(220, 170, 255), 0.82, 0.12) } },
	{ rgb(16, 18, 24), {
		{ rgb(92, 110, 140), 0.05, 0.17, 0.9, 0.6 },
		{ rgb(120, 130, 120), 0.05, 0.6, 0.9, 0.17 },
		{ rgb(196, 40, 28), 0.46, 0.36, 0.08, 0.26 },
		{ rgb(255, 50, 60), 0.05, 0.8, 0.9, 0.15 },
	}, { text("REPLAY: RAGE_H4X0R", WHITE, 0.02, 0.12, BOLD), text("SPINBOT DETECTED", WHITE, 0.81, 0.13, BOLD) } },
	{ rgb(30, 32, 44), {
		{ rgb(64, 68, 90), 0.05, 0.2, 0.62, 0.18 },
		{ PINK, 0.33, 0.44, 0.62, 0.18 },
		{ rgb(64, 68, 90), 0.05, 0.68, 0.62, 0.18 },
	}, {
		text("TEAM CHAT", WHITE, 0.02, 0.12, BOLD),
		text("who broke the build", WHITE, 0.22, 0.14, BOLD, 0.08, 0.56),
		text("not me", WHITE, 0.46, 0.14, BOLD, 0.36, 0.56),
		text("ship it anyway", WHITE, 0.7, 0.14, BOLD, 0.08, 0.56),
	} },
}

-- Office chair facing -Z: round base, gas lift, cushioned seat, colored back
local function officeChair(ctx, cframe, color)
	Kit.cylinder(ctx.Decor, "ChairBase", 0.25, 2.1, cframe * CFrame.new(0, 0.2, 0), BLACK, M.Metal)
	Kit.cylinder(ctx.Decor, "ChairLift", 1.7, 0.3, cframe * CFrame.new(0, 1.15, 0), STEEL, M.Metal)
	Kit.part(ctx.Decor, "ChairSeat", Vector3.new(2, 0.45, 2), cframe * CFrame.new(0, 2.15, 0), DARK, M.Fabric)
	Kit.part(ctx.Decor, "ChairBack", Vector3.new(1.9, 2.4, 0.3), cframe * CFrame.new(0, 3.5, 0.95) * CFrame.Angles(math.rad(8), 0, 0), color, M.Fabric)
end

-- Little bits of mess left on the desks, picked in turn
local function deskMess(ctx, cframe, which)
	if which == 1 then
		Kit.cylinder(ctx.Decor, "Mug", 0.55, 0.45, cframe * CFrame.new(0, 0.275, 0), PINK)
	elseif which == 2 then
		Kit.cylinder(ctx.Decor, "Can", 0.65, 0.32, cframe * CFrame.new(0, 0.325, 0), LIME, M.Metal)
	elseif which == 3 then
		local box = Kit.part(ctx.Decor, "PizzaBox", Vector3.new(1.7, 0.22, 1.7), cframe * CFrame.new(-0.2, 0.11, 0) * CFrame.Angles(0, math.rad(14), 0), CARDBOARD, M.Cardboard)
		Kit.text(box, Enum.NormalId.Top, { text("PIZZA", rgb(200, 40, 30), 0.3, 0.4) })
	elseif which == 4 then
		Kit.ball(ctx.Decor, "Duck", 0.55, cframe * CFrame.new(0, 0.27, 0), YELLOW)
		Kit.ball(ctx.Decor, "Duck", 0.36, cframe * CFrame.new(0, 0.62, -0.12), YELLOW)
	elseif which == 5 then
		Kit.part(ctx.Decor, "Papers", Vector3.new(1, 0.15, 1.3), cframe * CFrame.new(0, 0.075, 0) * CFrame.Angles(0, math.rad(-9), 0), WHITE)
	end
end

-- Open-plan desk bench: `seats` desks along each side of a felt divider, 6
-- studs each, with dual monitors, a keyboard and mouse pad, an office chair
-- and a bit of mess. The divider is chest-high cover. `first` shifts which
-- screens show.
local function deskBench(ctx, x, z, rot, seats, felt, first)
	local base = at(ctx, x, 0, z, rot)
	local length = seats * 6
	local desk = Kit.part(ctx.Structure, "Desk", Vector3.new(length, 0.3, 6.4), base * CFrame.new(0, 2.85, 0), WHITE)
	-- Keyboards (1.8 wide) and mouse pads are painted on in front of every
	-- seat, on both sides
	local pads = {}
	for seat = 1, seats do
		local middle = (seat - 0.5) / seats
		for _, y in { 0.2, 0.8 } do
			table.insert(pads, { DARK, middle - 0.15 / seats, y - 0.05, 0.3 / seats, 0.1 })
			table.insert(pads, { rgb(64, 70, 96), middle + 0.18 / seats, y - 0.09, 0.17 / seats, 0.18 })
		end
	end
	paint(desk, Enum.NormalId.Top, pads, {})
	Kit.part(ctx.Structure, "Divider", Vector3.new(length - 0.2, 4.1, 0.3), base * CFrame.new(0, 2.35, 0), felt, M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "DeskLeg", Vector3.new(0.4, 2.7, 6), base * CFrame.new(side * (length / 2 - 0.3), 1.35, 0), DARK, M.Metal)
	end
	local index = first or 0
	for _, side in { -1, 1 } do
		for seat = 1, seats do
			index += 1
			-- Each desk is built facing -Z, then turned for the far side
			local spot = base * CFrame.new(-length / 2 + 3 + (seat - 1) * 6, 0, 0) * (if side > 0 then TURN else CFrame.identity)
			for screenIndex, turn in { -1, 1 } do
				local look = MONITORS[(index * 2 + screenIndex) % #MONITORS + 1]
				local monitor = Kit.part(ctx.Decor, "Monitor", Vector3.new(2.25, 1.45, 0.16), spot * CFrame.new(turn * 1.15, 4.05, -0.42) * CFrame.Angles(0, math.rad(turn * 10), 0), BLACK)
				paint(monitor, FRONT, { { look[1], 0, 0, 1, 1 }, table.unpack(look[2]) }, look[3], { 0.04, 0.05, 0.92, 0.84 })
			end
			-- Every third chair has wandered off to the coffee bar
			if index % 3 ~= 0 then
				officeChair(ctx, spot * CFrame.new((index % 2) * 0.6 - 0.3, 0, -4.2) * CFrame.Angles(0, math.rad(180 + (index % 4) * 9 - 13), 0), felt)
			end
			if index % 2 == 0 then
				deskMess(ctx, spot * CFrame.new(-2.2, 3, -1.6), index / 2 % 5 + 1)
			end
		end
	end
end

-- A cardboard box of merch with packing tape and a label on the front
local function merchBox(ctx, x, z, size, rot, y)
	local box = Kit.box(ctx, x, z, size.X, size.Y, size.Z, CARDBOARD, M.Cardboard, rot, y)
	Kit.part(ctx.Decor, "Tape", Vector3.new(0.7, 0.06, size.Z + 0.06), box.CFrame * CFrame.new(0, size.Y / 2 + 0.02, 0), rgb(214, 182, 130), M.SmoothPlastic)
	Kit.text(box, FRONT, {
		text("EARN ESP", PINK, 0.3, 0.22),
		text("MERCH - THIS SIDE UP", rgb(90, 60, 36), 0.56, 0.12, BOLD),
	})
	return box
end

-- A potted office plant
local function plant(ctx, x, z, scale)
	scale = scale or 1
	Kit.cylinder(ctx.Structure, "Planter", 2.2 * scale, 2.4 * scale, at(ctx, x, 1.1 * scale, z), WHITE, M.SmoothPlastic)
	Kit.ball(ctx.Decor, "Leaves", 4.4 * scale, at(ctx, x, 4.2 * scale, z), LEAF, M.Grass)
end

-- Coffee bar against the west wall: counter with an espresso machine, mugs and
-- stools on the room side, a shelf and a menu board on the wall behind
local function coffeeBar(ctx, z)
	local x = -ctx.HalfX + 8
	local counter = Kit.part(ctx.Structure, "CoffeeBar", Vector3.new(2.6, 3.3, 16), at(ctx, x, 1.65, z), rgb(150, 100, 66), M.WoodPlanks)
	Kit.text(counter, Enum.NormalId.Right, {
		text("HOTFIX", PINK, 0.12, 0.4),
		text("COFFEE", WHITE, 0.56, 0.3),
	})
	Kit.part(ctx.Decor, "Countertop", Vector3.new(3.2, 0.25, 16.6), at(ctx, x + 0.2, 3.42, z), rgb(236, 236, 240), M.Marble)
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(0.1, 0.15, 15.6), at(ctx, x + 1.35, 0.4, z), PINK), PINK, 10, 0.6)
	-- Espresso machine, turned to face the room
	local machine = at(ctx, x - 0.2, 3.55, z - 4, -90)
	Kit.part(ctx.Decor, "Espresso", Vector3.new(2.4, 1.6, 1.3), machine * CFrame.new(0, 0.8, 0.2), STEEL, M.Metal)
	local badge = Kit.neon(ctx.Decor, Vector3.new(2, 0.35, 0.05), machine * CFrame.new(0, 1.3, -0.47), PINK)
	Kit.text(badge, FRONT, { text("HOTFIX", WHITE, 0.1, 0.8) })
	Kit.part(ctx.Decor, "DripTray", Vector3.new(2.2, 0.12, 0.6), machine * CFrame.new(0, 0.06, -0.7), BLACK, M.Metal)
	for _, side in { -1, 1 } do
		Kit.cylinder(ctx.Decor, "Cup", 0.35, 0.34, machine * CFrame.new(side * 0.55, 0.3, -0.7), WHITE)
	end
	for index, color in { PINK, WHITE, CYAN } do
		Kit.cylinder(ctx.Decor, "Mug", 0.55, 0.45, at(ctx, x + 0.6, 3.82, z + 1 + index * 1.3), color)
	end
	-- Stools on the room side
	for _, offset in { -5, 0, 5 } do
		Kit.cylinder(ctx.Decor, "StoolPost", 2.5, 0.28, at(ctx, x + 3.6, 1.25, z + offset), STEEL, M.Metal)
		Kit.cylinder(ctx.Decor, "Stool", 0.4, 1.8, at(ctx, x + 3.6, 2.65, z + offset), PINK, M.Fabric)
	end
	-- Shelf of coffee bags and the menu board on the wall
	Kit.part(ctx.Decor, "Shelf", Vector3.new(1, 0.2, 12), at(ctx, -ctx.HalfX + 0.5, 6, z), WHITE)
	for index, color in { rgb(90, 56, 36), PINK, CYAN } do
		Kit.part(ctx.Decor, "CoffeeBag", Vector3.new(0.7, 1.3, 1), at(ctx, -ctx.HalfX + 0.6, 6.75, z - 5 + index * 2.6), color, M.Fabric)
	end
	local menu = Kit.part(ctx.Decor, "Menu", Vector3.new(10, 4.2, 0.3), at(ctx, -ctx.HalfX + 0.15, 10, z, -90), rgb(34, 30, 34))
	paint(menu, FRONT, { { PINK, 0, 0, 1, 0.24 } }, {
		text("HOTFIX COFFEE", WHITE, 0.03, 0.18),
		text("ESPRESSO", WHITE, 0.3, 0.15, BOLD, 0.06, 0.6),
		text("2 CR", YELLOW, 0.3, 0.15, BOLD, 0.62, 0.32, Enum.TextXAlignment.Right),
		text("PATCH-DAY LATTE", WHITE, 0.5, 0.15, BOLD, 0.06, 0.6),
		text("3 CR", YELLOW, 0.5, 0.15, BOLD, 0.62, 0.32, Enum.TextXAlignment.Right),
		text("CRUNCH-TIME BREW", WHITE, 0.7, 0.15, BOLD, 0.06, 0.6),
		text("5 CR", YELLOW, 0.7, 0.15, BOLD, 0.62, 0.32, Enum.TextXAlignment.Right),
	})
end

-- The giant whiteboard of patch notes, hung on the north wall
local function patchBoard(ctx, x)
	local frame = at(ctx, x, 9.6, ctx.HalfZ - 0.35)
	Kit.part(ctx.Decor, "BoardFrame", Vector3.new(31, 12, 0.3), frame * CFrame.new(0, 0, 0.1), STEEL, M.Metal)
	local board = Kit.part(ctx.Decor, "PatchNotes", Vector3.new(30, 11, 0.2), frame * CFrame.new(0, 0, -0.1), rgb(250, 250, 250))
	local ink = rgb(30, 34, 44)
	local blue = rgb(30, 80, 210)
	local red = rgb(215, 30, 40)
	local function note(words, color, y)
		return text(words, color, y, 0.105, MARKER, 0.04, 0.6)
	end
	local lines = {
		text("PATCH NOTES v2.4", blue, 0.03, 0.17, MARKER),
		note("- spinbot nerfed (again)", ink, 0.23),
		note("- aimbot misses on purpose now", ink, 0.35),
		note("- bots learned to strafe", ink, 0.47),
		note("+ Ban Hammer bonks 50% harder", red, 0.59),
		note("+ new skins in Skin Spin", blue, 0.71),
		note("? who keeps getting on the roof", ink, 0.83),
		text("SHIP IT!", red, 0.6, 0.16, MARKER, 0.66, 0.3),
		text("ESP is a feature", blue, 0.82, 0.1, MARKER, 0.64, 0.33),
	}
	lines[8].Rotation = -8 -- "SHIP IT!" is scribbled at a slant
	-- A marker doodle of a noob in the corner, with a red ring around it
	paint(board, FRONT, {
		{ red, 0.715, 0.2, 0.17, 0.33 },
		{ rgb(250, 250, 250), 0.722, 0.215, 0.156, 0.3 },
		{ rgb(245, 205, 50), 0.785, 0.24, 0.03, 0.06 },
		{ rgb(13, 105, 172), 0.775, 0.3, 0.05, 0.1 },
		{ rgb(75, 151, 75), 0.775, 0.4, 0.05, 0.1 },
	}, lines)
	Kit.part(ctx.Decor, "MarkerTray", Vector3.new(30, 0.3, 0.8), frame * CFrame.new(0, -5.75, -0.45), STEEL, M.Metal)
	for index, color in { blue, red, ink } do
		local marker = Kit.part(ctx.Decor, "Marker", Vector3.new(1, 0.28, 0.28), frame * CFrame.new(-10 + index * 1.4, -5.45, -0.5), color)
		marker.Shape = Enum.PartType.Cylinder
	end
	Kit.part(ctx.Decor, "Eraser", Vector3.new(1.4, 0.4, 0.55), frame * CFrame.new(8, -5.4, -0.5), DARK, M.Fabric)
end

-- Cork board of sticky notes: the bugs players keep reporting
local BUGS = {
	{ "aimbot too strong", YELLOW },
	{ "nerf spinbot!!", PINK },
	{ "LagSwitch_420 lagging again", CYAN },
	{ "bot stuck in vending machine", LIME },
	{ "ESP sees thru walls??", ORANGE },
	{ "RAGE_H4X0R ban evading", PINK },
	{ "rocket jump too fun", YELLOW },
	{ "add more hats", LIME },
	{ "who ate my pizza", CYAN },
	{ "noob walks into wall", YELLOW },
}

local function bugBoard(ctx, x)
	local frame = at(ctx, x, 9.2, ctx.HalfZ - 0.3)
	Kit.part(ctx.Decor, "BoardFrame", Vector3.new(17, 10.4, 0.3), frame * CFrame.new(0, 0, 0.05), rgb(120, 82, 52), M.Wood)
	local cork = Kit.part(ctx.Decor, "BugBoard", Vector3.new(16, 9.4, 0.2), frame * CFrame.new(0, 0, -0.15), rgb(204, 160, 110), M.Fabric)
	Kit.text(cork, FRONT, { text("BUGS TO SQUASH", rgb(120, 30, 40), 0.03, 0.12, MARKER) })
	for index, bug in BUGS do
		local column = (index - 1) % 5
		local row = math.floor((index - 1) / 5)
		local tilt = ((index * 37) % 13 - 6) -- a few degrees either way
		local spot = frame * CFrame.new(-6.2 + column * 3.1, 1.6 - row * 3.4, -0.29) * CFrame.Angles(0, 0, math.rad(tilt))
		local sticky = Kit.part(ctx.Decor, "StickyNote", Vector3.new(2.5, 2.5, 0.06), spot, bug[2])
		Kit.text(sticky, FRONT, { text(bug[1], rgb(40, 34, 30), 0.1, 0.8, MARKER) })
	end
end

-- A whiteboard on wheels split into TO DO, DOING and DONE, covered in notes.
-- Both sides are the same.
local function kanban(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "BoardLeg", Vector3.new(0.3, 7.6, 0.3), base * CFrame.new(side * 3.85, 3.9, 0), STEEL, M.Metal)
		Kit.part(ctx.Decor, "BoardFoot", Vector3.new(0.4, 0.35, 2.6), base * CFrame.new(side * 3.85, 0.35, 0), DARK, M.Metal)
	end
	local board = Kit.part(ctx.Structure, "Kanban", Vector3.new(7.4, 4.8, 0.2), base * CFrame.new(0, 5.2, 0), rgb(250, 250, 250))
	local ink = rgb(40, 44, 56)
	local blocks = { { ink, 0.333, 0.04, 0.006, 0.92 }, { ink, 0.666, 0.04, 0.006, 0.92 }, { ink, 0.03, 0.2, 0.94, 0.006 } }
	local colors = { YELLOW, PINK, CYAN, LIME, ORANGE }
	for column, count in { 4, 2, 5 } do
		for note = 1, count do
			local row, across = math.floor((note - 1) / 2), (note - 1) % 2
			table.insert(blocks, { colors[(column + note) % #colors + 1], (column - 1) / 3 + 0.03 + across * 0.15, 0.26 + row * 0.24, 0.12, 0.19 })
		end
	end
	local lines = {
		text("TO DO", ink, 0.05, 0.12, MARKER, 0.02, 0.3, Enum.TextXAlignment.Center),
		text("DOING", ink, 0.05, 0.12, MARKER, 0.35, 0.3, Enum.TextXAlignment.Center),
		text("DONE", ink, 0.05, 0.12, MARKER, 0.68, 0.3, Enum.TextXAlignment.Center),
	}
	paint(board, FRONT, blocks, lines)
	paint(board, BACK, blocks, lines)
end

-- A long, low storage cabinet (waist-high cover) with a wood top, a stack of
-- boxed games and a little plant on it
local function cabinet(ctx, x, z, rot, length)
	local base = at(ctx, x, 0, z, rot)
	local body = Kit.part(ctx.Structure, "Cabinet", Vector3.new(length, 3.4, 2.4), base * CFrame.new(0, 1.7, 0), WHITE)
	local doors = {}
	local count = math.max(1, math.floor(length / 3))
	for index = 0, count - 1 do
		table.insert(doors, { rgb(222, 224, 230), (index + 0.03) / count, 0.06, 0.94 / count, 0.88 })
		table.insert(doors, { DARK, (index + 0.46) / count, 0.14, 0.08 / count, 0.06 })
	end
	paint(body, FRONT, doors, {})
	paint(body, BACK, doors, {})
	Kit.part(ctx.Decor, "CabinetTop", Vector3.new(length + 0.3, 0.25, 2.7), base * CFrame.new(0, 3.525, 0), rgb(190, 146, 100), M.Wood)
	local games = Kit.part(ctx.Decor, "GameBoxes", Vector3.new(3.4, 1.6, 1.2), base * CFrame.new(-length / 2 + 2.4, 4.45, 0), WHITE)
	local spines = {}
	for index, color in { PINK, CYAN, PURPLE, YELLOW, BLACK, LIME, ORANGE } do
		table.insert(spines, { color, (index - 1) / 7 + 0.01, 0, 1 / 7 - 0.02, 1 })
	end
	paint(games, FRONT, spines, {})
	paint(games, BACK, spines, {})
	Kit.cylinder(ctx.Decor, "Pot", 1, 1.3, base * CFrame.new(length / 2 - 1.6, 4.15, 0), PINK)
	Kit.ball(ctx.Decor, "Leaves", 2.2, base * CFrame.new(length / 2 - 1.6, 5.3, 0), LEAF, M.Grass)
end

-- A one-person focus pod: a padded booth with a glass door, its inside (and
-- the door handle) painted on behind the glass. Solid cover. The door faces
-- -Z.
local function focusPod(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	local shell = Kit.part(ctx.Structure, "FocusPod", Vector3.new(5, 8, 5), base * CFrame.new(0, 4, 0), color, M.Fabric)
	paint(shell, FRONT, {
		{ rgb(44, 46, 60), 0.08, 0.05, 0.84, 0.93 },
		{ rgb(255, 236, 190), 0.3, 0.07, 0.4, 0.03 },
		{ rgb(30, 32, 40), 0.18, 0.5, 0.64, 0.05 },
		{ rgb(20, 26, 44), 0.34, 0.36, 0.32, 0.14 },
		{ color:Lerp(Color3.new(0, 0, 0), 0.35), 0.3, 0.7, 0.4, 0.28 },
		{ STEEL, 0.78, 0.42, 0.03, 0.2 },
	}, {})
	for _, face in { Enum.NormalId.Left, Enum.NormalId.Right } do
		Kit.text(shell, face, { text("FOCUS POD", WHITE, 0.06, 0.07), text("shh! deep in a bug", WHITE, 0.14, 0.05, BOLD) })
	end
	Kit.part(ctx.Decor, "PodGlass", Vector3.new(4.4, 7.2, 0.15), base * CFrame.new(0, 3.9, -2.58), rgb(200, 225, 245), M.Glass, 0.6)
	Kit.part(ctx.Decor, "PodRoof", Vector3.new(5.3, 0.4, 5.3), base * CFrame.new(0, 8.2, 0), DARK)
end

-- Framed posters of the studio's own games, for the walls. Each is a
-- background color, some blocky art and a title.
local POSTERS = {
	{ rgb(70, 30, 120), {
		{ YELLOW, 0.2, 0.2, 0.6, 0.36 },
		{ rgb(150, 156, 170), 0.3, 0.26, 0.4, 0.26 },
		{ CYAN, 0.38, 0.32, 0.08, 0.06 },
		{ CYAN, 0.54, 0.32, 0.08, 0.06 },
		{ rgb(60, 64, 76), 0.4, 0.44, 0.2, 0.04 },
	}, "BOT BLASTER II", "more bots. more blast." },
	{ rgb(16, 22, 60), {
		{ rgb(245, 205, 50), 0.15, 0.2, 0.1, 0.07 }, { rgb(245, 205, 50), 0.35, 0.2, 0.1, 0.07 },
		{ rgb(245, 205, 50), 0.55, 0.2, 0.1, 0.07 }, { rgb(245, 205, 50), 0.75, 0.2, 0.1, 0.07 },
		{ rgb(75, 151, 75), 0.25, 0.32, 0.1, 0.07 }, { rgb(75, 151, 75), 0.45, 0.32, 0.1, 0.07 },
		{ rgb(75, 151, 75), 0.65, 0.32, 0.1, 0.07 },
		{ PINK, 0.42, 0.56, 0.16, 0.06 }, { PINK, 0.48, 0.52, 0.04, 0.04 },
	}, "NOOB INVADERS", "insert coin" },
	{ PINK, {
		{ WHITE, 0.3, 0.16, 0.4, 0.015 }, { WHITE, 0.3, 0.58, 0.4, 0.015 },
		{ WHITE, 0.3, 0.16, 0.015, 0.435 }, { WHITE, 0.685, 0.16, 0.015, 0.435 },
		{ rgb(245, 205, 50), 0.45, 0.22, 0.1, 0.08 }, { rgb(13, 105, 172), 0.43, 0.3, 0.14, 0.14 },
		{ rgb(75, 151, 75), 0.43, 0.44, 0.14, 0.12 },
	}, "EARN ESP", "see everything" },
	{ rgb(250, 200, 50), {
		{ rgb(196, 40, 28), 0.25, 0.2, 0.5, 0.16 },
		{ rgb(80, 52, 36), 0.46, 0.36, 0.08, 0.3 },
		{ WHITE, 0.3, 0.24, 0.4, 0.08 },
	}, "BAN WAVE", "coming to a server near you" },
}

local function poster(ctx, x, z, rot, which)
	local look = POSTERS[which]
	local frame = Kit.part(ctx.Decor, "Poster", Vector3.new(4.4, 6, 0.12), at(ctx, x, 8.5, z, rot), BLACK)
	local blocks = { { look[1], 0, 0, 1, 1 }, table.unpack(look[2]) }
	paint(frame, FRONT, blocks, {
		text(look[3], WHITE, 0.68, 0.13),
		text(look[4], WHITE, 0.84, 0.07, BOLD),
	}, { 0.05, 0.04, 0.9, 0.92 })
end

-- A network cabinet with its servers painted on behind a glass door: the
-- plain twin of Props.serverRack (4 wide, 3.2 deep, 9 tall), facing -Z
local function networkCabinet(ctx, x, z, rot, color, label)
	local base = at(ctx, x, 0, z, rot)
	local body = Kit.part(ctx.Structure, "NetworkCabinet", Vector3.new(4, 9, 3.2), base * CFrame.new(0, 4.5, 0), rgb(28, 30, 36), M.Metal)
	local blocks = {}
	for row = 0, 7 do
		local y = 0.13 + row * 0.1
		table.insert(blocks, { if row % 2 == 0 then rgb(88, 92, 104) else rgb(66, 70, 80), 0.08, y, 0.84, 0.085 })
		table.insert(blocks, { ({ LIME, ORANGE, color })[row % 3 + 1], 0.76, y + 0.03, 0.06, 0.025 })
		table.insert(blocks, { color, 0.14, y + 0.055, 0.42, 0.012 })
	end
	paint(body, FRONT, blocks, { text(label, color, 0.025, 0.07, BOLD) })
	Kit.part(ctx.Decor, "RackDoor", Vector3.new(3.6, 8, 0.08), base * CFrame.new(0, 4.6, -1.65), rgb(170, 200, 230), M.Glass, 0.75)
end

-- The big screen hanging over the lounge: the next patch building, and the
-- countdown to the next ban wave on the back
local function buildScreen(ctx, z)
	local frame = at(ctx, 0, 12, z)
	local housing = Kit.part(ctx.Decor, "BigScreen", Vector3.new(24, 9, 0.8), frame, BLACK)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "ScreenRod", Vector3.new(0.3, 1.6, 0.3), frame * CFrame.new(side * 9, 5.3, 0), STEEL, M.Metal)
	end
	local percent = 0.73
	local face = screen(ctx.Decor, Vector3.new(23.2, 8.2, 0.06), frame * CFrame.new(0, 0, -0.43), rgb(20, 22, 42), {
		{ PINK, 0, 0, 1, 0.03 },
		{ rgb(48, 52, 82), 0.08, 0.56, 0.84, 0.14 },
		{ LIME, 0.08, 0.56, 0.84 * percent, 0.14 },
		{ rgb(190, 255, 160), 0.08, 0.56, 0.84 * percent, 0.03 },
	}, {
		text("BUILDING PATCH 2.4", WHITE, 0.1, 0.2),
		text("anti-cheat update - ships today", PINK, 0.33, 0.1, BOLD),
		text(math.floor(percent * 100) .. "%", rgb(20, 40, 16), 0.575, 0.1, nil, 0.1, 0.84 * percent - 0.04, Enum.TextXAlignment.Right),
		text("bugs left: 3      coffee left: 0", rgb(170, 178, 205), 0.78, 0.09, BOLD),
	})
	Kit.light(face, rgb(150, 160, 255), 28, 1, "SurfaceLight", FRONT)
	paint(housing, BACK, { { rgb(60, 10, 20), 0.03, 0.05, 0.94, 0.9 } }, {
		text("NEXT BAN WAVE IN", WHITE, 0.14, 0.18),
		text("04:20", rgb(255, 60, 70), 0.36, 0.4),
		text("cheaters beware", PINK, 0.8, 0.1, BOLD),
	})
	Kit.neon(ctx.Decor, Vector3.new(24.2, 0.3, 0.9), frame * CFrame.new(0, -4.6, 0), PINK)
end

-- Glass-walled meeting room in the north-west corner, door on its south side
local function meetingRoom(ctx)
	local west, north = -ctx.HalfX, ctx.HalfZ
	local east, south = west + 26, north - 26
	local glass = rgb(190, 222, 245)
	local wallHeight = 10
	-- South glass runs from the west wall to the door, then a short piece
	Kit.part(ctx.Structure, "Glass", Vector3.new(19, wallHeight, 0.4), at(ctx, west + 9.5, wallHeight / 2, south), glass, M.Glass, 0.55)
	Kit.part(ctx.Structure, "Glass", Vector3.new(2, wallHeight, 0.4), at(ctx, east - 1, wallHeight / 2, south), glass, M.Glass, 0.55)
	Kit.part(ctx.Structure, "Glass", Vector3.new(0.4, wallHeight, 26), at(ctx, east, wallHeight / 2, north - 13), glass, M.Glass, 0.55)
	Kit.part(ctx.Decor, "GlassFrame", Vector3.new(26.4, 0.5, 0.6), at(ctx, west + 13, wallHeight + 0.25, south), STEEL, M.Metal)
	Kit.part(ctx.Decor, "GlassFrame", Vector3.new(0.6, 0.5, 26), at(ctx, east, wallHeight + 0.25, north - 13), STEEL, M.Metal)
	for _, px in { west + 19, east - 2, east } do
		Kit.part(ctx.Decor, "GlassFrame", Vector3.new(0.5, wallHeight, 0.6), at(ctx, px, wallHeight / 2, south), STEEL, M.Metal)
	end
	-- Frosted band with the room's name, so nobody walks into the glass
	local band = Kit.part(ctx.Decor, "Frosting", Vector3.new(19, 1.4, 0.45), at(ctx, west + 9.5, 5, south), WHITE, M.Glass, 0.25)
	for _, face in { FRONT, BACK } do
		Kit.text(band, face, { text("WAR ROOM", PINK, 0.12, 0.76) })
	end
	-- Table, chairs, a laptop and the sprint screen
	local middle = at(ctx, west + 13, 0, north - 12)
	Kit.part(ctx.Structure, "MeetingTable", Vector3.new(13, 0.35, 4.6), middle * CFrame.new(0, 2.9, 0), WHITE)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "TableLeg", Vector3.new(0.8, 2.75, 2.6), middle * CFrame.new(side * 4.5, 1.37, 0), DARK, M.Metal)
	end
	for index, spot in { { -3.5, -1 }, { 3.5, -1 }, { -3.5, 1 }, { 3.5, 1 } } do
		local chair = middle * CFrame.new(spot[1], 0, spot[2] * 3.6) * (if spot[2] > 0 then TURN else CFrame.identity)
		Kit.part(ctx.Decor, "ChairSeat", Vector3.new(1.9, 0.45, 1.9), chair * CFrame.new(0, 1.9, 0), DARK, M.Fabric)
		Kit.part(ctx.Decor, "ChairBack", Vector3.new(1.9, 2.2, 0.3), chair * CFrame.new(0, 3, -0.9), if index % 2 == 0 then PINK else CYAN, M.Fabric)
	end
	local laptop = middle * CFrame.new(-1, 3.08, -0.6) * CFrame.Angles(0, math.rad(15), 0)
	Kit.part(ctx.Decor, "Laptop", Vector3.new(1.6, 0.08, 1.1), laptop, STEEL, M.Metal)
	screen(ctx.Decor, Vector3.new(1.6, 1, 0.06), laptop * CFrame.new(0, 0.5, 0.55) * CFrame.Angles(math.rad(-15), 0, 0) * TURN, rgb(20, 26, 44), { { PINK, 0.1, 0.55, 0.5, 0.15 } }, { text("SLIDES", WHITE, 0.15, 0.3, BOLD) })
	local tv = at(ctx, west + 13, 7.5, north - 0.3)
	Kit.part(ctx.Decor, "TV", Vector3.new(12, 6.6, 0.3), tv, BLACK)
	screen(ctx.Decor, Vector3.new(11.4, 6, 0.06), tv * CFrame.new(0, 0, -0.18), rgb(244, 244, 248), {
		{ PINK, 0, 0, 1, 0.2 },
		{ rgb(200, 204, 214), 0.1, 0.86, 0.8, 0.02 },
		{ rgb(200, 204, 214), 0.1, 0.4, 0.004, 0.46 },
		{ rgb(255, 120, 150), 0.12, 0.44, 0.16, 0.04 },
		{ rgb(255, 120, 150), 0.3, 0.54, 0.16, 0.04 },
		{ rgb(255, 120, 150), 0.48, 0.64, 0.16, 0.04 },
		{ rgb(255, 120, 150), 0.66, 0.76, 0.16, 0.04 },
	}, {
		text("SPRINT 42", WHITE, 0.03, 0.14),
		text("goal: catch RAGE_H4X0R", rgb(40, 44, 60), 0.24, 0.1, BOLD),
	})
end

-- Server closet in the north-east corner: block walls up to the ceiling, the
-- door propped open (against the rules on the sign), a server rack and a
-- network cabinet inside
local function serverCloset(ctx, height)
	local east, north = ctx.HalfX, ctx.HalfZ
	local west, south = east - 22, north - 20
	local wallColor = rgb(150, 158, 178)
	local doorLeft, doorRight = west + 4, west + 9
	local side = Kit.part(ctx.Structure, "Wall", Vector3.new(1, height, 20), at(ctx, west + 0.5, height / 2, north - 10), wallColor, M.Concrete)
	Kit.part(ctx.Structure, "Wall", Vector3.new(doorLeft - west, height, 1), at(ctx, (west + doorLeft) / 2, height / 2, south + 0.5), wallColor, M.Concrete)
	local front = Kit.part(ctx.Structure, "Wall", Vector3.new(east - doorRight, height, 1), at(ctx, (doorRight + east) / 2, height / 2, south + 0.5), wallColor, M.Concrete)
	Kit.part(ctx.Structure, "Wall", Vector3.new(doorRight - doorLeft, height - 8, 1), at(ctx, (doorLeft + doorRight) / 2, 8 + (height - 8) / 2, south + 0.5), wallColor, M.Concrete)
	-- Painted details: hazard band, a vent, a wired window onto the racks,
	-- cable conduit and a warning sticker
	local hazard = { { rgb(250, 200, 40), 0, 0.92, 1, 0.08 } }
	for index = 0, 15 do
		table.insert(hazard, { rgb(30, 30, 34), index / 16 + 0.01, 0.92, 1 / 32, 0.08 })
	end
	local frontArt = table.clone(hazard)
	for _, block in {
		{ rgb(210, 214, 222), 0.12, 0.34, 0.5, 0.2 },
		{ rgb(16, 26, 48), 0.14, 0.36, 0.46, 0.16 },
		{ rgb(40, 44, 56), 0.18, 0.38, 0.1, 0.14 }, { rgb(40, 44, 56), 0.32, 0.38, 0.1, 0.14 },
		{ CYAN, 0.2, 0.4, 0.02, 0.01 }, { LIME, 0.23, 0.43, 0.02, 0.01 }, { PINK, 0.34, 0.41, 0.02, 0.01 },
		{ rgb(120, 126, 140), 0.7, 0.62, 0.22, 0.12 },
		{ rgb(50, 54, 64), 0.72, 0.64, 0.18, 0.012 }, { rgb(50, 54, 64), 0.72, 0.67, 0.18, 0.012 },
		{ rgb(50, 54, 64), 0.72, 0.7, 0.18, 0.012 }, { rgb(50, 54, 64), 0.72, 0.73, 0.18, 0.012 },
		{ rgb(80, 84, 96), 0, 0.12, 1, 0.025 },
	} do
		table.insert(frontArt, block)
	end
	paint(front, FRONT, frontArt, { text("AUTHORIZED DEVS ONLY", rgb(200, 30, 40), 0.6, 0.05, BOLD, 0.1, 0.54) })
	local sideArt = table.clone(hazard)
	table.insert(sideArt, { rgb(80, 84, 96), 0, 0.12, 1, 0.025 })
	table.insert(sideArt, { rgb(80, 84, 96), 0.2, 0.12, 0.02, 0.8 })
	table.insert(sideArt, { rgb(250, 200, 40), 0.5, 0.44, 0.24, 0.16 })
	paint(side, Enum.NormalId.Left, sideArt, { text("HOT", rgb(30, 30, 34), 0.45, 0.07, nil, 0.5, 0.24), text("SERVERS", rgb(30, 30, 34), 0.52, 0.06, nil, 0.5, 0.24) })
	-- The door, hinged at the left of the opening and swung out into the room
	local door = Kit.part(ctx.Decor, "Door", Vector3.new(4.9, 7.9, 0.3), at(ctx, doorLeft, 3.95, south) * CFrame.Angles(0, math.rad(70), 0) * CFrame.new(2.45, 0, -0.15), rgb(118, 126, 146), M.Metal)
	for _, face in { FRONT, BACK } do
		paint(door, face, { { rgb(200, 220, 240), 0.3, 0.1, 0.4, 0.22 }, { STEEL, 0.8, 0.48, 0.08, 0.04 } }, {})
	end
	local sign = Kit.part(ctx.Decor, "ClosetSign", Vector3.new(6, 1.8, 0.1), at(ctx, (doorLeft + doorRight) / 2, 9.4, south - 0.05), rgb(200, 30, 40))
	Kit.text(sign, FRONT, { text("SERVER ROOM", WHITE, 0.08, 0.5), text("keep door shut!!", WHITE, 0.62, 0.3, BOLD) })
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.5, 0.5, 0.2), at(ctx, doorRight + 0.8, 9.4, south - 0.1), rgb(255, 40, 40)))
	Kit.part(ctx.Decor, "RaisedFloor", Vector3.new(21, 0.1, 19), at(ctx, west + 11.5, 0.05, north - 9.5), rgb(150, 156, 170), M.DiamondPlate)
	Props.serverRack(ctx, west + 10, north - 3.4, 0, CYAN, "GAME SERVER 01")
	networkCabinet(ctx, west + 15, north - 3.4, 0, PINK, "ANTI-CHEAT")
	local cooler = Kit.part(ctx.Decor, "CoolingUnit", Vector3.new(2, 6.5, 5), at(ctx, east - 1, 3.25, south + 6), rgb(225, 228, 232), M.Metal)
	Kit.text(cooler, Enum.NormalId.Left, { text("COOLING", rgb(60, 140, 220), 0.06, 0.08, BOLD), text("= = = = =", rgb(150, 156, 168), 0.3, 0.4, BOLD) })
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(6, 0.2, 1), at(ctx, west + 11, height - 0.3, north - 8), rgb(150, 210, 255)), rgb(120, 190, 255), 22, 1.2)
end

-- Merch corner: a pallet of boxes, an open box of hoodies, and a rack of
-- the studio's own hoodies
local function merchCorner(ctx)
	local east, south = ctx.HalfX, -ctx.HalfZ
	Kit.part(ctx.Decor, "Pallet", Vector3.new(9, 0.5, 5.5), at(ctx, east - 13, 0.25, south + 6), rgb(176, 136, 90), M.WoodPlanks)
	merchBox(ctx, east - 15, south + 6, Vector3.new(4, 3.2, 4), 0, 0.5)
	merchBox(ctx, east - 10.8, south + 6.2, Vector3.new(4, 3.2, 4), 6, 0.5)
	merchBox(ctx, east - 13, south + 5.8, Vector3.new(3.6, 2.8, 3.6), -12, 3.7)
	merchBox(ctx, east - 22, south + 5, Vector3.new(4.4, 3.6, 4.4), 8)
	-- Open box with a pink hoodie spilling out of it
	local open = Kit.box(ctx, east - 21, south + 11.5, 3.6, 2.6, 3.6, CARDBOARD, M.Cardboard, 24)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "Flap", Vector3.new(3.6, 0.08, 1.8), open.CFrame * CFrame.new(0, 1.3, side * 1.8) * CFrame.Angles(math.rad(side * 125), 0, 0) * CFrame.new(0, 0, side * 0.9), CARDBOARD, M.Cardboard)
	end
	Kit.part(ctx.Decor, "Hoodie", Vector3.new(3, 0.6, 2.6), open.CFrame * CFrame.new(0.2, 1.35, 0.1) * CFrame.Angles(0, 0, math.rad(6)), PINK, M.Fabric)
	-- Clothing rack along the east wall
	local rack = at(ctx, east - 2.5, 0, south + 11, 90)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "RackPost", Vector3.new(0.3, 6.4, 0.3), rack * CFrame.new(side * 4.5, 3.2, 0), STEEL, M.Metal)
	end
	Kit.part(ctx.Decor, "RackBar", Vector3.new(9.2, 0.25, 0.25), rack * CFrame.new(0, 6.3, 0), STEEL, M.Metal)
	for index, color in { PINK, BLACK, CYAN, WHITE } do
		local hanger = rack * CFrame.new(-3.6 + (index - 1) * 2.4, 4.6, 0) * CFrame.Angles(0, math.rad(90), 0)
		local hoodie = Kit.part(ctx.Decor, "Hoodie", Vector3.new(2.4, 3, 0.5), hanger, color, M.Fabric)
		Kit.text(hoodie, FRONT, { text(if index % 2 == 0 then "GG" else "EZ", if color == WHITE then PINK else WHITE, 0.2, 0.3) })
	end
	local standee = Kit.part(ctx.Decor, "MerchSign", Vector3.new(3.4, 4.6, 0.25), at(ctx, east - 26, 2.3, south + 13, -30) * CFrame.Angles(math.rad(-10), 0, 0), WHITE)
	paint(standee, FRONT, { { PINK, 0, 0, 1, 0.32 } }, {
		text("NEW", WHITE, 0.04, 0.24),
		text("HOODIE", rgb(40, 40, 50), 0.4, 0.16),
		text("DROP", rgb(40, 40, 50), 0.58, 0.16),
		text("50 CR", PINK, 0.8, 0.13, BOLD),
	})
end

-- Lounge under the big screen: a rug, beanbags turned to watch the build,
-- and a table with a half-eaten pizza and a controller
local function lounge(ctx, z)
	local rug = Kit.part(ctx.Decor, "Rug", Vector3.new(16, 0.06, 11), at(ctx, 0, 0.03, z), rgb(64, 70, 108), M.Fabric)
	paint(rug, Enum.NormalId.Top, {
		{ PINK, 0.04, 0.06, 0.92, 0.05 },
		{ PINK, 0.04, 0.89, 0.92, 0.05 },
		{ CYAN, 0.04, 0.16, 0.92, 0.02 },
		{ CYAN, 0.04, 0.82, 0.92, 0.02 },
	}, {})
	Props.beanbag(ctx, -4.6, z - 1, 168, YELLOW)
	Props.beanbag(ctx, 4.6, z - 0.6, 194, CYAN)
	Kit.cylinder(ctx.Structure, "LoungeTable", 1.4, 1.1, at(ctx, 0, 0.7, z + 3), DARK, M.Metal)
	Kit.cylinder(ctx.Decor, "LoungeTable", 0.3, 4.4, at(ctx, 0, 1.55, z + 3), WHITE)
	local pizza = Kit.part(ctx.Decor, "PizzaBox", Vector3.new(2, 0.22, 2), at(ctx, -0.5, 1.81, z + 3, 20), CARDBOARD, M.Cardboard)
	Kit.cylinder(ctx.Decor, "Pizza", 0.08, 1.7, pizza.CFrame * CFrame.new(0, 0.15, 0), rgb(240, 180, 70))
	Kit.part(ctx.Decor, "Controller", Vector3.new(0.9, 0.2, 0.5), at(ctx, 1.2, 1.8, z + 2.5, -25), BLACK)
end

-- A squashed ball. It still collides as a box.
local function blob(parent, name, size, cframe, color)
	local part = Kit.part(parent, name, size, cframe, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- A giant rubber duck, for talking bugs through (and hiding behind)
local function debugDuck(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	blob(ctx.Structure, "DebugDuck", Vector3.new(6, 4.6, 7.6), base * CFrame.new(0, 2.3, 0.3), YELLOW)
	Kit.wedge(ctx.Decor, "DuckTail", Vector3.new(2.4, 2.2, 2), base * CFrame.new(0, 4, 3.6), YELLOW)
	Kit.ball(ctx.Decor, "DuckHead", 3.8, base * CFrame.new(0, 5.6, -2), YELLOW)
	blob(ctx.Decor, "DuckBeak", Vector3.new(2, 0.8, 1.8), base * CFrame.new(0, 5.2, -3.9), ORANGE)
	for _, side in { -1, 1 } do
		Kit.ball(ctx.Decor, "DuckEye", 0.5, base * CFrame.new(side * 0.85, 6.3, -3.55), BLACK)
	end
end

-- Ping pong table: the studio's real "playtesting"
local function pingPong(ctx, x, z)
	local base = at(ctx, x, 0, z)
	local top = Kit.part(ctx.Structure, "PingPong", Vector3.new(9, 0.25, 5), base * CFrame.new(0, 2.6, 0), rgb(30, 80, 150))
	paint(top, Enum.NormalId.Top, {
		{ WHITE, 0, 0, 1, 0.03 },
		{ WHITE, 0, 0.97, 1, 0.03 },
		{ WHITE, 0, 0, 0.02, 1 },
		{ WHITE, 0.98, 0, 0.02, 1 },
		{ WHITE, 0.02, 0.49, 0.96, 0.02 },
	}, {})
	Kit.part(ctx.Decor, "Net", Vector3.new(0.12, 0.6, 5.4), base * CFrame.new(0, 3.02, 0), rgb(235, 235, 235), M.Fabric)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "TableLegs", Vector3.new(0.3, 2.45, 4), base * CFrame.new(side * 3, 1.25, 0), DARK, M.Metal)
	end
	local paddle = Kit.part(ctx.Decor, "Paddle", Vector3.new(0.12, 1.2, 1.1), base * CFrame.new(-2.6, 2.8, 1) * CFrame.Angles(0, math.rad(30), math.rad(90)), rgb(200, 30, 40))
	paddle.Shape = Enum.PartType.Cylinder
	Kit.ball(ctx.Decor, "Ball", 0.3, base * CFrame.new(1.6, 2.88, -1.2), rgb(255, 160, 40))
end

Maps.DevStudio = {
	Name = "Dev Studio", Theme = "DevStudio", HalfX = 68, HalfZ = 58,
	Build = function(ctx)
		local height = 18
		local hx, hz = ctx.HalfX, ctx.HalfZ
		Kit.floor(ctx, rgb(214, 178, 134), M.WoodPlanks)
		Kit.boundary(ctx, height, rgb(244, 242, 238), M.Plaster)
		Kit.ceiling(ctx, height, rgb(246, 246, 246), M.SmoothPlastic)
		Kit.ceilingLights(ctx, height, rgb(255, 250, 238), 34)
		-- A navy skirting band with a pink stripe all the way round
		for _, spec in { { 0, -hz + 0.1, 0, hx }, { 0, hz - 0.1, 0, hx }, { -hx + 0.1, 0, 90, hz }, { hx - 0.1, 0, 90, hz } } do
			Kit.part(ctx.Decor, "WallBand", Vector3.new(spec[4] * 2, 3, 0.2), at(ctx, spec[1], 1.5, spec[2], spec[3]), rgb(46, 52, 84), M.SmoothPlastic)
			Kit.part(ctx.Decor, "WallStripe", Vector3.new(spec[4] * 2, 0.4, 0.26), at(ctx, spec[1], 3.2, spec[2], spec[3]), PINK, M.SmoothPlastic)
		end
		-- Studio logo on the wall behind the player's spawn
		local logo = Kit.part(ctx.Decor, "Logo", Vector3.new(34, 7, 0.4), at(ctx, 0, 10.5, -hz + 0.3, 180), rgb(30, 34, 58))
		Kit.text(logo, FRONT, { text("DEV STUDIO", WHITE, 0.08, 0.52), text("we patch, you cheat", PINK, 0.66, 0.22, BOLD) })
		Kit.light(Kit.neon(ctx.Decor, Vector3.new(34.4, 0.3, 0.5), at(ctx, 0, 6.85, -hz + 0.35), PINK), PINK, 20, 1)

		-- Open-plan desks on carpet: one bench each side of the spawn, one at
		-- the back
		for _, spec in { { -36, -18, 23 }, { 36, -18, 23 }, { 0, 33, 17 } } do
			Kit.part(ctx.Decor, "Carpet", Vector3.new(spec[3], 0.06, 17), at(ctx, spec[1], 0.03, spec[2]), rgb(74, 84, 118), M.Carpet)
		end
		deskBench(ctx, -36, -18, 0, 3, rgb(232, 70, 110), 0)
		deskBench(ctx, 36, -18, 0, 3, rgb(40, 170, 185), 6)
		deskBench(ctx, 0, 33, 0, 2, rgb(240, 180, 50), 3)
		Kit.cylinder(ctx.Structure, "TrashBin", 2, 1.6, at(ctx, -24.5, 1, -23), DARK, M.Metal)
		Kit.ball(ctx.Decor, "PaperBall", 0.6, at(ctx, -23.4, 0.3, -25.2), WHITE)

		pingPong(ctx, 0, -27)
		lounge(ctx, 3)
		buildScreen(ctx, 13)
		patchBoard(ctx, -17)
		bugBoard(ctx, 21)
		kanban(ctx, -15, 23, 15)
		debugDuck(ctx, 31, 22, -35)
		meetingRoom(ctx)
		serverCloset(ctx, height)
		coffeeBar(ctx, -40)
		merchCorner(ctx)

		-- Columns holding the roof up, banded like the walls
		for _, spot in { { -21, 6 }, { 21, 6 } } do
			Kit.pillar(ctx, spot[1], spot[2], 2.6, height, rgb(244, 242, 238), M.Plaster)
			Kit.part(ctx.Decor, "PillarBand", Vector3.new(2.9, 0.5, 2.9), at(ctx, spot[1], 3.2, spot[2]), PINK)
		end
		-- Storage cabinets and focus pods split up the open floor
		cabinet(ctx, -40, 4, 0, 12)
		cabinet(ctx, 40, 4, 0, 12)
		focusPod(ctx, -hx + 3, -15, -90, rgb(90, 80, 160))
		focusPod(ctx, -hx + 3, -10, -90, PINK)
		focusPod(ctx, hx - 3, 14, 90, rgb(40, 170, 185))
		for index, spec in { { -hx + 0.1, 4, -90 }, { -hx + 0.1, 12, -90 }, { hx - 0.1, -14, 90 }, { hx - 0.1, -4, 90 } } do
			poster(ctx, spec[1], spec[2], spec[3], index)
		end
		-- Boxes of merch that never got unpacked, for cover in the back half
		merchBox(ctx, -54, 15, Vector3.new(4.4, 3.6, 4.4), 10)
		merchBox(ctx, -49.5, 17.5, Vector3.new(3.6, 3.2, 3.6), -20)
		merchBox(ctx, 52, 24, Vector3.new(4.4, 3.6, 4.4), -8)
		merchBox(ctx, 52.4, 24.2, Vector3.new(3.4, 2.8, 3.4), 30, 3.6)
		-- Water cooler and plants
		Kit.box(ctx, -hx + 1.5, 22, 1.8, 3.2, 1.8, WHITE, M.SmoothPlastic)
		Kit.cylinder(ctx.Decor, "WaterBottle", 2, 1.4, at(ctx, -hx + 1.5, 4.2, 22), rgb(120, 190, 255), M.Glass).Transparency = 0.3
		for _, spot in { { -hx + 3, 27.5 }, { -36, 29 }, { 40, 34 }, { hx - 3, -30 } } do
			plant(ctx, spot[1], spot[2], 1)
		end
	end,
}

-- Classic Place ------------------------------------------------------------------

-- Old-school brick colors
local BRIGHT_RED = rgb(196, 40, 28)
local BRIGHT_BLUE = rgb(13, 105, 172)
local BRIGHT_YELLOW = rgb(245, 205, 48)
local BRIGHT_GREEN = rgb(75, 151, 75)
local STONE = rgb(163, 162, 165)
local DARK_STONE = rgb(99, 95, 98)
local BRICK_YELLOW = rgb(215, 197, 154)
local REDDISH_BROWN = rgb(105, 64, 40)
local CLASSIC_WHITE = rgb(242, 243, 243)
local CLASSIC_BLACK = rgb(27, 42, 53)

-- Studs on top and the matching holes underneath, like the old days
local function studs(part)
	part.TopSurface = Enum.SurfaceType.Studs
	part.BottomSurface = Enum.SurfaceType.Inlet
	return part
end

-- A plain plastic brick with studs on top
local function brick(parent, name, size, cframe, color)
	return studs(Kit.part(parent, name, size, cframe, color, M.Plastic))
end

-- A truss you can climb like a ladder. Trusses come in 2-stud steps.
local function truss(parent, height, cframe, color)
	local part = Instance.new("TrussPart")
	part.Name = "Ladder"
	part.Anchored = true
	part.Size = Vector3.new(2, height, 2)
	part.CFrame = cframe
	part.Color = color
	part.Material = M.Plastic
	part.Parent = parent
	return part
end

-- A giant toy brick, 2.5 studs per bump: `long` x `wide` bumps (2 x 4 by
-- default), 3 tall, with real raised studs on top
local function toyBrick(ctx, x, z, rot, color, y, long, wide)
	long, wide = long or 4, wide or 2
	local base = at(ctx, x, y or 0, z, rot)
	local body = Kit.part(ctx.Structure, "ToyBrick", Vector3.new(long * 2.5, 3, wide * 2.5), base * CFrame.new(0, 1.5, 0), color, M.Plastic)
	for column = 1, long do
		for row = 1, wide do
			Kit.cylinder(ctx.Decor, "Stud", 0.55, 1.5, base * CFrame.new((column - (long + 1) / 2) * 2.5, 3.27, (row - (wide + 1) / 2) * 2.5), color, M.Plastic)
		end
	end
	return body
end

-- A tower of big studded bricks in classic colors, with a flag on top and a
-- truss ladder up its front (-Z)
local function brickTower(ctx, x, z, rot, colors, flagColor)
	local base = at(ctx, x, 0, z, rot)
	local size = 8
	for index, color in colors do
		brick(ctx.Structure, "TowerBrick", Vector3.new(size, 3.2, size), base * CFrame.new(0, (index - 0.5) * 3.2, 0), color)
	end
	local top = #colors * 3.2
	-- Four big raised studs on the top brick, like a giant 2 x 2
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Kit.cylinder(ctx.Decor, "Stud", 0.8, 2.4, base * CFrame.new(corner[1] * 2, top + 0.4, corner[2] * 2), colors[#colors], M.Plastic)
	end
	truss(ctx.Structure, math.ceil(top / 2) * 2, base * CFrame.new(0, math.ceil(top / 2), -size / 2 - 1), STONE)
	Kit.cylinder(ctx.Decor, "FlagPole", 7, 0.4, base * CFrame.new(size / 2 - 0.8, top + 3.5, size / 2 - 0.8), CLASSIC_WHITE, M.Plastic)
	Kit.part(ctx.Decor, "Flag", Vector3.new(3.4, 2.2, 0.2), base * CFrame.new(size / 2 - 2.6, top + 5.8, size / 2 - 0.8), flagColor, M.Plastic)
	Kit.ball(ctx.Decor, "FlagTop", 0.7, base * CFrame.new(size / 2 - 0.8, top + 7.1, size / 2 - 0.8), BRIGHT_YELLOW, M.Plastic)
end

-- A lookout deck on four legs, `height` up, with railings round three sides
-- and a truss ladder up the open front (-Z)
local function lookout(ctx, x, z, rot, height, deckColor)
	local base = at(ctx, x, 0, z, rot)
	local size = 14
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		brick(ctx.Structure, "DeckLeg", Vector3.new(1.6, height - 1, 1.6), base * CFrame.new(corner[1] * (size / 2 - 0.8), (height - 1) / 2, corner[2] * (size / 2 - 0.8)), STONE)
	end
	brick(ctx.Structure, "Deck", Vector3.new(size, 1, size), base * CFrame.new(0, height - 0.5, 0), deckColor)
	brick(ctx.Structure, "Railing", Vector3.new(size, 2, 0.6), base * CFrame.new(0, height + 1, size / 2 - 0.3), BRIGHT_YELLOW)
	for _, side in { -1, 1 } do
		brick(ctx.Structure, "Railing", Vector3.new(0.6, 2, size - 1.2), base * CFrame.new(side * (size / 2 - 0.3), height + 1, 0), BRIGHT_YELLOW)
		brick(ctx.Structure, "Railing", Vector3.new(size / 2 - 1.5, 2, 0.6), base * CFrame.new(side * (size / 4 + 0.75), height + 1, -size / 2 + 0.3), BRIGHT_YELLOW)
	end
	truss(ctx.Structure, height, base * CFrame.new(0, height / 2, -size / 2 - 1), STONE)
	Kit.cylinder(ctx.Decor, "FlagPole", 7, 0.35, base * CFrame.new(size / 2 - 0.3, height + 5.5, size / 2 - 0.3), CLASSIC_WHITE, M.Plastic)
	Kit.part(ctx.Decor, "Flag", Vector3.new(3.2, 2, 0.2), base * CFrame.new(size / 2 - 2, height + 7.8, size / 2 - 0.3), deckColor, M.Plastic)
end

-- The classic house: plastic walls, a doorway you can walk through, glass
-- windows, a red sloped roof with a chimney, and a table and chairs inside.
-- The door faces -Z.
local function classicHouse(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local width, depth, wallHeight, door = 22, 16, 10, 5
	local function wall(size, offset)
		return brick(ctx.Structure, "HouseWall", size, base * offset, BRICK_YELLOW)
	end
	wall(Vector3.new(width, wallHeight, 1), CFrame.new(0, wallHeight / 2, depth / 2 - 0.5))
	for _, side in { -1, 1 } do
		wall(Vector3.new(1, wallHeight, depth - 2), CFrame.new(side * (width / 2 - 0.5), wallHeight / 2, 0))
		wall(Vector3.new((width - door) / 2, wallHeight, 1), CFrame.new(side * (width + door) / 4, wallHeight / 2, -depth / 2 + 0.5))
	end
	wall(Vector3.new(door, wallHeight - 7, 1), CFrame.new(0, 7 + (wallHeight - 7) / 2, -depth / 2 + 0.5))
	-- Roof: two slopes meeting at a ridge, gables at the ends
	for _, side in { -1, 1 } do
		local slope = base * CFrame.new(0, wallHeight + 2.5, side * (depth / 4 + 0.5)) * (if side > 0 then TURN else CFrame.identity)
		Kit.wedge(ctx.Decor, "Roof", Vector3.new(width + 2, 5, depth / 2 + 1), slope, BRIGHT_RED, M.Plastic)
	end
	Kit.part(ctx.Decor, "RoofRidge", Vector3.new(width + 2.4, 0.6, 0.9), base * CFrame.new(0, wallHeight + 5.1, 0), rgb(150, 30, 22), M.Plastic)
	brick(ctx.Decor, "Chimney", Vector3.new(2.2, 6, 2.2), base * CFrame.new(width / 2 - 4.5, wallHeight + 4, 3.4), REDDISH_BROWN)
	-- Windows: glass in a white frame, on the front and both sides
	for _, spec in {
		{ CFrame.new(-6.75, 5.5, -depth / 2 - 0.05), 0 },
		{ CFrame.new(6.75, 5.5, -depth / 2 - 0.05), 0 },
		{ CFrame.new(-width / 2 - 0.05, 5.5, 0), 90 },
		{ CFrame.new(width / 2 + 0.05, 5.5, 0), 90 },
		{ CFrame.new(0, 5.5, depth / 2 + 0.05), 0 },
	} do
		local spot = base * spec[1] * CFrame.Angles(0, math.rad(spec[2]), 0)
		Kit.part(ctx.Decor, "WindowFrame", Vector3.new(4.4, 3.8, 0.12), spot, CLASSIC_WHITE, M.Plastic)
		Kit.part(ctx.Decor, "Window", Vector3.new(3.8, 3.2, 0.2), spot, rgb(160, 205, 240), M.Glass, 0.3)
	end
	-- Inside: wood floor, a table with two chairs, a hanging lamp
	Kit.part(ctx.Decor, "HouseFloor", Vector3.new(width - 2, 0.1, depth - 2), base * CFrame.new(0, 0.05, 0), rgb(160, 110, 70), M.WoodPlanks)
	Kit.part(ctx.Structure, "Table", Vector3.new(5, 0.4, 3), base * CFrame.new(0, 2.8, 2), REDDISH_BROWN, M.Wood)
	Kit.part(ctx.Decor, "TableLeg", Vector3.new(0.6, 2.6, 0.6), base * CFrame.new(0, 1.3, 2), REDDISH_BROWN, M.Wood)
	for _, side in { -1, 1 } do
		local chair = base * CFrame.new(side * 3.6, 0, 2) * CFrame.Angles(0, math.rad(side * 90), 0)
		Kit.part(ctx.Decor, "Chair", Vector3.new(2, 2, 2), chair * CFrame.new(0, 1, 0), BRIGHT_BLUE, M.Plastic)
		Kit.part(ctx.Decor, "ChairBack", Vector3.new(2, 2.4, 0.4), chair * CFrame.new(0, 3.2, -0.8), BRIGHT_BLUE, M.Plastic)
	end
	local lamp = Kit.neon(ctx.Decor, Vector3.new(1.2, 0.6, 1.2), base * CFrame.new(0, wallHeight - 1.5, 1), rgb(255, 236, 190))
	Kit.light(lamp, rgb(255, 230, 180), 18, 1.2)
end

-- The noob statue: a big classic blocky figure waving from a stone plinth
local function noobStatue(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local s = 2.5 -- one classic body unit
	local top = 3.2
	brick(ctx.Structure, "Plinth", Vector3.new(9, top, 9), base * CFrame.new(0, top / 2, 0), STONE)
	local plaque = Kit.part(ctx.Decor, "Plaque", Vector3.new(5.4, 1.5, 0.15), base * CFrame.new(0, 1.7, -4.55), rgb(235, 190, 70), M.Metal)
	Kit.text(plaque, FRONT, { text("THE FIRST NOOB", rgb(60, 40, 10), 0.08, 0.5), text("still says hi", rgb(60, 40, 10), 0.62, 0.3, BOLD) })
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "StatueLeg", Vector3.new(s, 2 * s, s), base * CFrame.new(side * 0.5 * s, top + s, 0), BRIGHT_GREEN, M.Plastic)
	end
	local torsoY = top + 3 * s
	Kit.part(ctx.Structure, "StatueTorso", Vector3.new(2 * s, 2 * s, s), base * CFrame.new(0, torsoY, 0), BRIGHT_BLUE, M.Plastic)
	Kit.part(ctx.Decor, "StatueArm", Vector3.new(s, 2 * s, s), base * CFrame.new(-1.5 * s, torsoY, 0), BRIGHT_YELLOW, M.Plastic)
	-- The waving arm swings up and out from the shoulder
	local shoulder = base * CFrame.new(1.3 * s, torsoY + 0.6 * s, 0) * CFrame.Angles(0, 0, math.rad(150))
	Kit.part(ctx.Decor, "StatueArm", Vector3.new(s, 2 * s, s), shoulder * CFrame.new(0, -0.5 * s, 0), BRIGHT_YELLOW, M.Plastic)
	local headY = torsoY + s + 0.6 * s
	Kit.cylinder(ctx.Decor, "StatueHead", 1.2 * s, 1.25 * s, base * CFrame.new(0, headY, 0), BRIGHT_YELLOW, M.Plastic)
	-- A blocky smile: two eyes and a mouth with turned-up corners
	local face = base * CFrame.new(0, headY, -0.6 * s)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "Eye", Vector3.new(0.3, 0.6, 0.2), face * CFrame.new(side * 0.42, 0.25, 0.08), CLASSIC_BLACK, M.SmoothPlastic)
		Kit.part(ctx.Decor, "Smile", Vector3.new(0.22, 0.3, 0.2), face * CFrame.new(side * 0.5, -0.38, 0.06), CLASSIC_BLACK, M.SmoothPlastic)
	end
	Kit.part(ctx.Decor, "Smile", Vector3.new(0.8, 0.2, 0.2), face * CFrame.new(0, -0.55, 0.02), CLASSIC_BLACK, M.SmoothPlastic)
end

-- A round pond with lily pads, a rubber duck and a humped wooden bridge
-- across it (along X). The water is flat, so you can walk on it.
local function pond(ctx, x, z)
	local water = rgb(70, 150, 220)
	for _, spec in { { 0, 0, 20 }, { 8, 5, 12 } } do
		Kit.cylinder(ctx.Decor, "Pond", 0.1, spec[3], at(ctx, x + spec[1], 0.05, z + spec[2]), water, M.Glass).Transparency = 0.15
	end
	for _, spot in { { -5, -5 }, { 9, 6 } } do
		Kit.cylinder(ctx.Decor, "LilyPad", 0.06, 2.2, at(ctx, x + spot[1], 0.13, z + spot[2]), rgb(60, 140, 60), M.Plastic)
	end
	Kit.ball(ctx.Decor, "Duck", 1, at(ctx, x + 4, 0.55, z - 5), BRIGHT_YELLOW, M.Plastic)
	Kit.ball(ctx.Decor, "Duck", 0.65, at(ctx, x + 4.4, 1.2, z - 5), BRIGHT_YELLOW, M.Plastic)
	-- Bridge: two ramps meeting in the middle, with a curb along each edge
	local rise, run = 1.6, 10
	for _, side in { -1, 1 } do
		local ramp = Kit.wedge(ctx.Structure, "Bridge", Vector3.new(4, rise, run), at(ctx, x + side * run / 2, rise / 2, z, -side * 90), REDDISH_BROWN, M.WoodPlanks)
		for _, edge in { -1, 1 } do
			local curb = ramp.CFrame * CFrame.new(edge * 1.8, 0, 0) * CFrame.Angles(-math.atan(rise / run), 0, 0) * CFrame.new(0, 0.3, 0)
			Kit.part(ctx.Decor, "BridgeCurb", Vector3.new(0.4, 0.6, math.sqrt(rise * rise + run * run)), curb, rgb(80, 48, 30), M.Wood)
		end
	end
end

-- A seesaw: a red plank tipped on a yellow stand, with handles at each end
local function seesaw(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.wedge(ctx.Structure, "SeesawStand", Vector3.new(1.4, 2, 1.2), base * CFrame.new(0, 1, -0.6), BRIGHT_YELLOW, M.Plastic)
	Kit.wedge(ctx.Structure, "SeesawStand", Vector3.new(1.4, 2, 1.2), base * CFrame.new(0, 1, 0.6) * TURN, BRIGHT_YELLOW, M.Plastic)
	local plank = base * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(10), 0, 0)
	brick(ctx.Structure, "Seesaw", Vector3.new(1.6, 0.4, 14), plank, BRIGHT_RED)
	for _, side in { -1, 1 } do
		brick(ctx.Decor, "SeesawHandle", Vector3.new(1.4, 1, 0.3), plank * CFrame.new(0, 0.7, side * 5.6), BRIGHT_BLUE)
	end
end

-- An old-school lamp post: a stone post with a glowing white globe
local function lampPost(ctx, x, z)
	brick(ctx.Structure, "LampPost", Vector3.new(0.8, 9, 0.8), at(ctx, x, 4.5, z), DARK_STONE)
	Kit.ball(ctx.Decor, "LampGlobe", 1.8, at(ctx, x, 9.8, z), rgb(255, 250, 230), M.Neon)
end

-- A blocky white cloud high over the map. Nothing can touch or hit it.
local function cloud(ctx, x, y, z, scale)
	for _, piece in { { 0, 0, 0, 26, 6, 14 }, { -9, 2.5, 1, 12, 5, 10 }, { 7, 3, -1, 14, 6, 11 } } do
		local part = Kit.part(ctx.Decor, "Cloud", Vector3.new(piece[4], piece[5], piece[6]) * scale, at(ctx, x + piece[1] * scale, y + piece[2] * scale, z + piece[3] * scale), CLASSIC_WHITE, M.SmoothPlastic, 0.05)
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
	end
end

Maps.ClassicPlace = {
	Name = "Classic Place", Theme = "ClassicPlace", HalfX = 70, HalfZ = 60,
	Build = function(ctx)
		local hx, hz = ctx.HalfX, ctx.HalfZ
		studs(Kit.floor(ctx, rgb(72, 148, 70), M.Plastic))
		-- A faint grid on the baseplate, like the old default texture
		for x = -60, 60, 20 do
			Kit.stripe(ctx, x, 0, hz * 2, 0.3, 0, rgb(64, 136, 62))
		end
		for z = -40, 40, 20 do
			Kit.stripe(ctx, 0, z, hx * 2, 0.3, 90, rgb(64, 136, 62))
		end
		Kit.boundary(ctx, 4, DARK_STONE, M.Plastic)
		for _, child in ctx.Structure:GetChildren() do
			if child.Name == "Wall" then
				studs(child)
			end
		end

		-- Spawn pad: black and white checkers, flat so you spawn right on it
		local pad = at(ctx, 0, 0, -hz + 8)
		Kit.part(ctx.Decor, "SpawnPad", Vector3.new(13, 0.3, 13), pad * CFrame.new(0, 0.15, 0), STONE, M.Plastic)
		Kit.part(ctx.Decor, "SpawnChecker", Vector3.new(12, 0.32, 12), pad * CFrame.new(0, 0.16, 0), CLASSIC_BLACK, M.Plastic)
		for row = 0, 3 do
			for column = 0, 3 do
				if (row + column) % 2 == 0 then
					Kit.part(ctx.Decor, "SpawnChecker", Vector3.new(3, 0.34, 3), pad * CFrame.new(-4.5 + column * 3, 0.17, -4.5 + row * 3), CLASSIC_WHITE, M.Plastic)
				end
			end
		end
		Kit.stripe(ctx, 0, -24, 42, 8, 0, STONE)

		-- Welcome arch over the path
		local arch = at(ctx, 0, 0, -30)
		for _, side in { -1, 1 } do
			brick(ctx.Structure, "ArchPillar", Vector3.new(3, 11, 3), arch * CFrame.new(side * 11, 5.5, 0), STONE)
			brick(ctx.Decor, "ArchBase", Vector3.new(4.2, 1.2, 4.2), arch * CFrame.new(side * 11, 0.6, 0), BRIGHT_RED)
			brick(ctx.Decor, "ArchCap", Vector3.new(4.2, 1.2, 4.2), arch * CFrame.new(side * 11, 15.6, 0), BRIGHT_RED)
		end
		local sign = brick(ctx.Decor, "WelcomeSign", Vector3.new(26, 4, 1.6), arch * CFrame.new(0, 13, 0), BRIGHT_BLUE)
		Kit.text(sign, FRONT, {
			text("Welcome!", CLASSIC_WHITE, 0.06, 0.62, Enum.Font.ArialBold),
			text("to Classic Place", BRIGHT_YELLOW, 0.7, 0.24, Enum.Font.ArialBold),
		})
		Kit.text(sign, BACK, { text("Have fun!", CLASSIC_WHITE, 0.14, 0.72, Enum.Font.ArialBold) })

		-- The big brick wall across the middle: three rows of chunky bricks,
		-- staggered like a real wall, with one brick missing to shoot through
		local reds = { BRIGHT_RED, rgb(178, 34, 24), rgb(210, 58, 42) }
		local rows = {
			{ { -16, 8 }, { -8, 8 }, { 0, 8 }, { 8, 8 }, { 16, 8 } },
			{ { -18, 4 }, { -12, 8 }, { -4, 8 }, { 12, 8 }, { 18, 4 } },
			{ { -16, 8 }, { -8, 8 }, { 0, 8 }, { 8, 8 }, { 16, 8 } },
		}
		for rowIndex, row in rows do
			for index, piece in row do
				local color = reds[(rowIndex + index) % #reds + 1]
				brick(ctx.Structure, "BrickWall", Vector3.new(piece[2], 3.2, 3), at(ctx, piece[1], (rowIndex - 0.5) * 3.2, 4), color)
			end
		end

		-- Towers, lookouts and the house
		brickTower(ctx, 38, -2, 0, { BRIGHT_BLUE, BRIGHT_YELLOW, BRIGHT_RED }, BRIGHT_BLUE)
		brickTower(ctx, -40, -30, 30, { BRIGHT_RED, BRIGHT_BLUE, BRIGHT_YELLOW }, BRIGHT_RED)
		lookout(ctx, -46, 38, 0, 10, BRIGHT_BLUE)
		lookout(ctx, 48, 38, 0, 10, BRIGHT_GREEN)
		classicHouse(ctx, 0, 42, 0)
		Kit.fence(ctx, -13, 31, -4, 31, CLASSIC_WHITE, 3.5)
		Kit.fence(ctx, 4, 31, 13, 31, CLASSIC_WHITE, 3.5)
		Kit.part(ctx.Decor, "MailboxPost", Vector3.new(0.4, 3.4, 0.4), at(ctx, 6, 1.7, 28), REDDISH_BROWN, M.Wood)
		Kit.part(ctx.Decor, "Mailbox", Vector3.new(1.2, 1.1, 2), at(ctx, 6, 3.9, 28), BRIGHT_BLUE, M.Plastic)
		Kit.part(ctx.Decor, "MailboxFlag", Vector3.new(0.12, 0.9, 0.3), at(ctx, 6.66, 4.4, 28.5), BRIGHT_RED, M.Plastic)
		noobStatue(ctx, -40, 6, -40)
		pond(ctx, 40, -40)
		seesaw(ctx, -52, -12, 0)
		for _, spot in { { -6, -22 }, { 6, -22 }, { -6, -8 }, { 6, -8 } } do
			lampPost(ctx, spot[1], spot[2])
		end
		-- Floating jump blocks up to the top of the east tower, obby style
		for _, spec in { { 24, 10, 2.6, BRIGHT_RED }, { 26.5, 4, 5, BRIGHT_BLUE }, { 30, -0.5, 7.4, BRIGHT_YELLOW } } do
			brick(ctx.Structure, "JumpBlock", Vector3.new(4, 1, 4), at(ctx, spec[1], spec[3] - 0.5, spec[2]), spec[4])
		end

		-- Giant toy bricks scattered about for cover, two of them stacked
		toyBrick(ctx, -20, -20, 0, BRIGHT_RED)
		toyBrick(ctx, -20, -20, 90, BRIGHT_YELLOW, 3, 2, 2)
		toyBrick(ctx, 24, -24, 25, BRIGHT_BLUE)
		toyBrick(ctx, -24, 22, 15, BRIGHT_YELLOW)
		toyBrick(ctx, 22, 20, -20, BRIGHT_GREEN)
		toyBrick(ctx, 0, 20, 90, BRIGHT_BLUE, 0, 2, 2)
		toyBrick(ctx, 56, 14, 0, BRIGHT_RED, 0, 2, 2)

		-- Trees round the edges and a few clouds in the sky
		for _, spec in { { -60, -46, 1.2, "Round" }, { 60, -44, 1.1, "Pine" }, { -60, 52, 1.2, "Pine" }, { 62, 54, 1.3, "Round" }, { -60, 16, 1, "Round" }, { 30, 52, 1, "Pine" } } do
			Kit.tree(ctx, spec[1], spec[2], spec[3], spec[4], if spec[4] == "Round" then rgb(60, 140, 50) else rgb(40, 110, 50))
		end
		for _, spec in { { -38, 74, 48, 1.2 }, { 30, 86, 54, 1 }, { 56, 78, 4, 1.1 }, { -56, 82, -14, 1 }, { 22, 92, -40, 0.9 }, { -18, 70, 16, 0.8 } } do
			cloud(ctx, spec[1], spec[2], spec[3], spec[4])
		end
	end,
}

return Maps
