-- The esports maps: Esports Arena (a tournament final on a stage in the middle
-- of an arena hall) and LAN Cafe (a neon gaming cafe full of desks). Each one
-- sets its size and lighting theme, then places props with the kit and
-- Props.luau. Small pieces only these maps use are built by the helpers below.
local Kit = require(script.Parent.Kit)
local Props = require(script.Parent.Props)

local rgb, M = Kit.rgb, Kit.M
local at = Kit.at
local FRONT, BACK = Enum.NormalId.Front, Enum.NormalId.Back

local Maps = {}

-- Shared colors (pink is the game's UI accent)
local PINK = rgb(255, 46, 99)
local CYAN = rgb(0, 220, 255)
local PURPLE = rgb(170, 80, 255)
local YELLOW = rgb(255, 210, 40)
local LIME = rgb(120, 255, 80)
local ORANGE = rgb(255, 140, 40)
local RED = rgb(255, 40, 50)
local WHITE = rgb(240, 240, 245)
local BLACK = rgb(20, 20, 24)
local DARK = rgb(36, 38, 46)
local STEEL = rgb(150, 154, 162)
local GOLD = rgb(240, 190, 60)

-- Turns a cylinder (which lies along X) to lie along Z instead
local TURN = CFrame.Angles(0, math.rad(90), 0)

-- Helpers ----------------------------------------------------------------------

-- One line of text for Kit.text, placed by its top and height (0 to 1)
local function line(text, color, top, height, font)
	return { Text = text, Color = color, Font = font, Position = UDim2.fromScale(0.05, top), Size = UDim2.fromScale(0.9, height) }
end

-- A round part lying along X, the way Roblox cylinders lie
local function tube(parent, name, length, diameter, cframe, color, material)
	local part = Kit.part(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- A round bar from one point to another (tripod legs, braces)
local function rod(parent, name, from, to, diameter, color, material)
	return tube(parent, name, (to - from).Magnitude, diameter, CFrame.lookAt((from + to) / 2, to) * TURN, color, material)
end

-- A glowing screen with text on its front
local function screen(parent, size, cframe, color, lines)
	local part = Kit.neon(parent, size, cframe, color)
	part.Name = "Screen"
	Kit.text(part, FRONT, lines)
	return part
end

-- Floor trim (cables, rugs) that nobody trips on or hides behind
local function flat(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	return part
end

-- The same arena with its floor `height` up, so props can stand on a stage
local function raised(ctx, height)
	return setmetatable({ Center = ctx.Center + Vector3.new(0, height, 0) }, { __index = ctx })
end

-- A bundle of cables lying on the floor between two spots
local function cable(ctx, x1, z1, x2, z2, color)
	local from, to = Vector3.new(x1, 0.08, z1), Vector3.new(x2, 0.08, z2)
	local frame = CFrame.lookAt(ctx.Center + (from + to) / 2, ctx.Center + to)
	return flat(Kit.part(ctx.Decor, "Cable", Vector3.new(0.45, 0.16, (to - from).Magnitude), frame, color or BLACK))
end

-- Esports Arena pieces ---------------------------------------------------------

-- Team desk for the stage: one long desk with a monitor, RGB keyboard and
-- chair per player and the team's name on the front panel. Players sit at -Z
-- facing +Z (like Kit.desk), so the name faces +Z, out at the crowd.
-- `screens` is a list of { big, small } texts, one per monitor.
local function teamDesk(ctx, x, z, rot, color, team, tag, screens)
	local base = at(ctx, x, 0, z, rot)
	local length = #screens * 3.6 + 0.8
	local desk = Kit.part(ctx.Structure, "TeamDesk", Vector3.new(length, 0.3, 3.2), base * CFrame.new(0, 2.85, 0), BLACK)
	local panel = Kit.part(ctx.Structure, "DeskPanel", Vector3.new(length, 2.5, 0.3), base * CFrame.new(0, 1.45, 1.45), DARK, M.Metal)
	Kit.text(panel, BACK, { line(team, color, 0.14, 0.48), line("GRAND FINAL", WHITE, 0.66, 0.2, Enum.Font.GothamBold) })
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(length, 0.15, 0.12), base * CFrame.new(0, 2.62, 1.62), color), color, 14, 1)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Structure, "DeskLeg", Vector3.new(0.4, 2.7, 3), base * CFrame.new(side * (length / 2 - 0.2), 1.35, 0), DARK, M.Metal)
	end
	for seat, text in screens do
		local sx = -length / 2 + 2.2 + (seat - 1) * 3.6
		Kit.part(ctx.Decor, "MonitorStand", Vector3.new(0.3, 1.1, 0.3), base * CFrame.new(sx, 3.5, 1.05), BLACK, M.Metal)
		Kit.part(ctx.Decor, "Monitor", Vector3.new(2.8, 1.65, 0.15), base * CFrame.new(sx, 4.65, 0.92), BLACK)
		screen(ctx.Decor, Vector3.new(2.6, 1.45, 0.05), base * CFrame.new(sx, 4.65, 0.82), rgb(16, 12, 40), {
			line(text[1], color, 0.1, 0.46),
			line(text[2], WHITE, 0.62, 0.26, Enum.Font.GothamBold),
		})
		Kit.neon(ctx.Decor, Vector3.new(1.9, 0.1, 0.62), base * CFrame.new(sx - 0.3, 3.05, -0.55), color)
		-- Gaming chair pulled up to the desk: base, gas lift, seat, tall back
		local chair = base * CFrame.new(sx, 0, -2.5)
		Kit.cylinder(ctx.Decor, "ChairBase", 0.25, 2.3, chair * CFrame.new(0, 0.13, 0), BLACK, M.Metal)
		Kit.cylinder(ctx.Decor, "GasLift", 1.5, 0.3, chair * CFrame.new(0, 0.95, 0), STEEL, M.Metal)
		Kit.part(ctx.Structure, "Chair", Vector3.new(2.1, 0.5, 2.1), chair * CFrame.new(0, 1.95, 0), BLACK, M.Fabric)
		local back = Kit.part(ctx.Decor, "ChairBack", Vector3.new(2.1, 3.4, 0.45), chair * CFrame.new(0, 2.2, -0.95) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 1.7, 0), color, M.Fabric)
		Kit.text(back, FRONT, { line(tag, WHITE, 0.12, 0.2), line(tostring(seat), BLACK, 0.4, 0.3) })
	end
	return desk
end

-- PA speaker stack: a tall cabinet with two woofers and a horn, with a line
-- array box tipped down at the crowd on top. Faces -Z.
local function speaker(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local cabinet = Kit.part(ctx.Structure, "Speaker", Vector3.new(4.4, 7, 3.6), base * CFrame.new(0, 3.5, 0), BLACK, M.Fabric)
	for _, y in { 1.9, 4.6 } do
		tube(ctx.Decor, "Woofer", 0.2, 3, base * CFrame.new(0, y, -1.85) * TURN, rgb(54, 54, 62), M.Metal)
	end
	Kit.part(ctx.Decor, "Horn", Vector3.new(3.2, 0.8, 0.2), base * CFrame.new(0, 6.35, -1.85), rgb(46, 46, 54), M.Metal)
	Kit.part(ctx.Decor, "LineArray", Vector3.new(4.4, 1.5, 3.2), base * CFrame.new(0, 7.85, 0.2) * CFrame.Angles(math.rad(-8), 0, 0), BLACK, M.Fabric)
	Kit.neon(ctx.Decor, Vector3.new(0.3, 0.3, 0.06), base * CFrame.new(1.75, 0.6, -1.83), LIME)
	return cabinet
end

-- Road case: a flight case with a metal rim round the lid and a stencilled
-- label on the front (-Z). Pass y to stack one on another.
local function roadCase(ctx, x, z, rot, size, label, color, y)
	local base = at(ctx, x, y or 0, z, rot)
	local case = Kit.part(ctx.Structure, "RoadCase", size, base * CFrame.new(0, size.Y / 2, 0), color or rgb(26, 26, 30))
	Kit.text(case, FRONT, { line(label, WHITE, 0.42, 0.3, Enum.Font.GothamBold) })
	Kit.part(ctx.Decor, "CaseRim", Vector3.new(size.X + 0.12, 0.3, size.Z + 0.12), base * CFrame.new(0, size.Y * 0.78, 0), STEEL, M.Metal)
	return case
end

-- Crowd barrier wrapped in a sponsor banner: 3.9 tall, so it's half cover
local function crowdBarrier(ctx, x, z, rot, length, sponsor, color, textColor)
	local base = at(ctx, x, 0, z, rot)
	local panel = Kit.part(ctx.Structure, "CrowdBarrier", Vector3.new(length, 3.2, 0.3), base * CFrame.new(0, 2, 0), color, M.Fabric)
	for _, face in { FRONT, BACK } do
		Kit.text(panel, face, { line(sponsor, textColor, 0.16, 0.68) })
	end
	tube(ctx.Decor, "BarrierRail", length + 0.3, 0.35, base * CFrame.new(0, 3.75, 0), STEEL, M.Metal)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "BarrierFoot", Vector3.new(0.5, 0.3, 2.6), base * CFrame.new(side * (length / 2 - 0.6), 0.15, 0), STEEL, M.Metal)
	end
	return panel
end

-- The tournament trophy on a lit pedestal, about 7.4 tall
local function trophy(ctx, x, z, title)
	local base = at(ctx, x, 0, z)
	local pedestal = Kit.part(ctx.Structure, "Pedestal", Vector3.new(2.6, 3.4, 2.6), base * CFrame.new(0, 1.7, 0), BLACK, M.Marble)
	Kit.text(pedestal, FRONT, { line(title, GOLD, 0.3, 0.16), line("CHAMPIONS", WHITE, 0.5, 0.1, Enum.Font.GothamBold) })
	Kit.light(Kit.neon(ctx.Decor, Vector3.new(2.8, 0.2, 2.8), base * CFrame.new(0, 3.5, 0), PINK), GOLD, 14, 1.5)
	Kit.part(ctx.Decor, "TrophyBase", Vector3.new(1.5, 0.6, 1.5), base * CFrame.new(0, 3.9, 0), rgb(30, 30, 34), M.Marble)
	Kit.cylinder(ctx.Decor, "Trophy", 1, 0.4, base * CFrame.new(0, 4.7, 0), GOLD, M.Metal)
	Kit.ball(ctx.Decor, "Trophy", 1.9, base * CFrame.new(0, 5.9, 0), GOLD, M.Metal)
	Kit.cylinder(ctx.Decor, "TrophyRim", 0.5, 2.05, base * CFrame.new(0, 6.75, 0), GOLD, M.Metal)
	for _, side in { -1, 1 } do
		tube(ctx.Decor, "TrophyHandle", 0.2, 1, base * CFrame.new(side * 1.1, 6, 0) * TURN, GOLD, M.Metal)
	end
	return pedestal
end

-- LED wall at the back of the stage between two light pillars, with the
-- event logo across it. Faces -Z. The braces behind it reach 2.5 down, to
-- the arena floor behind the stage.
local function ledWall(ctx, z, width, height, color)
	local wall = Kit.part(ctx.Structure, "LedWall", Vector3.new(width + 1, height + 1, 1), at(ctx, 0, 0.5 + height / 2, z), BLACK, M.Metal)
	local display = screen(ctx.Decor, Vector3.new(width, height, 0.1), at(ctx, 0, 0.5 + height / 2, z - 0.55), rgb(30, 8, 44), {
		line("BAN WAVE", color, 0.12, 0.34),
		line("INVITATIONAL", WHITE, 0.46, 0.14, Enum.Font.GothamBold),
		line("GRAND FINAL  -  BEST OF 5", rgb(255, 170, 200), 0.7, 0.1, Enum.Font.GothamBold),
	})
	Kit.light(display, color, 40, 1.2, "SurfaceLight", FRONT)
	for _, side in { -1, 1 } do
		local px = side * (width / 2 + 2.2)
		Kit.part(ctx.Structure, "LightPillar", Vector3.new(3, height + 4, 2.4), at(ctx, px, (height + 4) / 2, z), DARK, M.Metal)
		Kit.neon(ctx.Decor, Vector3.new(0.5, height + 3, 0.1), at(ctx, px, (height + 4) / 2, z - 1.25), if side < 0 then PINK else CYAN)
	end
	local header = Kit.neon(ctx.Decor, Vector3.new(width + 7.4, 1.4, 1.2), at(ctx, 0, height + 4.7, z), color)
	Kit.text(header, FRONT, { line("EARN ESP  //  CHEAT YOUR WAY TO THE TOP", BLACK, 0.12, 0.76, Enum.Font.GothamBold) })
	-- The back is bare frame with a stencil, held up by two slanted braces
	Kit.text(wall, BACK, {
		line("STAGE 1  -  BACK OF HOUSE", rgb(120, 122, 134), 0.3, 0.12, Enum.Font.GothamBold),
		line("NO PLAYERS PAST THIS POINT", YELLOW, 0.5, 0.08, Enum.Font.GothamBold),
	})
	for _, side in { -1, 1 } do
		flat(rod(ctx.Decor, "Brace", at(ctx, side * 9, height - 1, z + 0.5).Position, at(ctx, side * 9, -2.5, z + 6).Position, 0.4, STEEL, M.Metal))
	end
	return wall
end

-- Front-of-house booth: a low riser with the sound desk, a screen and a small
-- rack. The engineer faces +Z (the stage); the desk is waist-high cover.
local function fohBooth(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.part(ctx.Structure, "Riser", Vector3.new(10, 1, 7), base * CFrame.new(0, 0.5, 0), DARK, M.DiamondPlate)
	Kit.neon(ctx.Decor, Vector3.new(10.1, 0.12, 7.1), base * CFrame.new(0, 0.9, 0), PINK)
	local desk = Kit.part(ctx.Structure, "SoundDesk", Vector3.new(8, 2.4, 2.4), base * CFrame.new(-0.6, 2.2, 1.6), BLACK)
	for _, face in { FRONT, BACK } do
		Kit.text(desk, face, { line("FOH", PINK, 0.15, 0.4), line("SOUND + LIGHTS", WHITE, 0.6, 0.2, Enum.Font.GothamBold) })
	end
	-- Sloped mixing board with rows of faders
	local slope = math.atan2(0.6, 2.4)
	Kit.wedge(ctx.Decor, "MixingBoard", Vector3.new(8, 0.6, 2.4), base * CFrame.new(-0.6, 3.7, 1.6), rgb(54, 56, 66), M.Metal)
	local faders = Kit.neon(ctx.Decor, Vector3.new(7.4, 0.05, 2), base * CFrame.new(-0.6, 3.73, 1.6) * CFrame.Angles(-slope, 0, 0), rgb(40, 200, 255), 0.2)
	Kit.text(faders, Enum.NormalId.Top, { line("| | | | | | | | | | | | | | | |", rgb(10, 20, 40), 0.1, 0.8) })
	Kit.part(ctx.Decor, "MonitorStand", Vector3.new(0.3, 1, 0.3), base * CFrame.new(-0.6, 4.4, 2.6), BLACK, M.Metal)
	Kit.part(ctx.Decor, "Monitor", Vector3.new(3.4, 1.9, 0.15), base * CFrame.new(-0.6, 5.5, 2.65), BLACK)
	screen(ctx.Decor, Vector3.new(3.2, 1.7, 0.05), base * CFrame.new(-0.6, 5.5, 2.55), rgb(8, 24, 30), {
		line("STAGE MICS", CYAN, 0.1, 0.3, Enum.Font.GothamBold),
		line("|||||| |||| ||||||||", LIME, 0.5, 0.36),
	})
	-- A small rack of amps with blinking lights
	local rack = Kit.part(ctx.Structure, "AmpRack", Vector3.new(2, 4, 2), base * CFrame.new(4, 3, 1.8), rgb(28, 30, 36), M.Metal)
	Kit.text(rack, FRONT, { { Text = "=== AMP ===\n=== AMP ===\n=== DSP ===", Color = rgb(120, 124, 136), Font = Enum.Font.GothamBold, Position = UDim2.fromScale(0.08, 0.1), Size = UDim2.fromScale(0.84, 0.6) } })
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.3, 0.2, 0.06), base * CFrame.new(4.6, 4.4, 0.78), LIME))
	return desk
end

-- Broadcast camera on a tripod, on a small riser, aimed at +Z
local function cameraRiser(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	local riser = Kit.part(ctx.Structure, "Riser", Vector3.new(7, 1.2, 7), base * CFrame.new(0, 0.6, 0), DARK, M.DiamondPlate)
	for _, face in { FRONT, BACK } do
		Kit.text(riser, face, { line("CAM 2", YELLOW, 0.15, 0.7) })
	end
	local head = base * Vector3.new(0, 5, 0.4)
	for index = 0, 2 do
		local angle = math.rad(index * 120 + 30)
		rod(ctx.Decor, "TripodLeg", head, base * Vector3.new(math.sin(angle) * 1.6, 1.2, 0.4 + math.cos(angle) * 1.6), 0.18, BLACK, M.Metal)
	end
	local cam = base * CFrame.new(0, 5.75, 0.4)
	local body = Kit.part(ctx.Structure, "Camera", Vector3.new(1.3, 1.4, 2.8), cam, rgb(44, 46, 54), M.Metal)
	Kit.text(body, Enum.NormalId.Left, { line("LIVE", RED, 0.2, 0.6) })
	tube(ctx.Decor, "Lens", 1.6, 1, cam * CFrame.new(0, -0.05, 2.1) * TURN, BLACK, M.Metal)
	tube(ctx.Decor, "LensGlass", 0.06, 0.8, cam * CFrame.new(0, -0.05, 2.92) * TURN, rgb(90, 140, 255), M.Glass)
	Kit.part(ctx.Decor, "Viewfinder", Vector3.new(1, 0.8, 0.9), cam * CFrame.new(-0.9, 0.4, -1.2), BLACK)
	Kit.blink(Kit.neon(ctx.Decor, Vector3.new(0.35, 0.2, 0.35), cam * CFrame.new(0, 0.8, 1.1), RED))
	return riser
end

-- Sponsor kiosk: a counter with a lit sign on posts and drinks on top.
-- Customers stand at -Z.
local function kiosk(ctx, x, z, rot, name, color, textColor)
	local base = at(ctx, x, 0, z, rot)
	local counter = Kit.part(ctx.Structure, "Kiosk", Vector3.new(7, 3.5, 2.6), base * CFrame.new(0, 1.75, 0), color, M.SmoothPlastic)
	Kit.text(counter, FRONT, { line(name, textColor, 0.2, 0.5) })
	Kit.part(ctx.Decor, "KioskTop", Vector3.new(7.4, 0.25, 3), base * CFrame.new(0, 3.62, 0), WHITE, M.Marble)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "SignPost", Vector3.new(0.3, 5, 0.3), base * CFrame.new(side * 3.2, 6.2, 1), DARK, M.Metal)
	end
	local sign = Kit.neon(ctx.Decor, Vector3.new(7.4, 1.8, 0.4), base * CFrame.new(0, 9.4, 1), color)
	Kit.text(sign, FRONT, { line(name, textColor, 0.12, 0.76) })
	Kit.text(sign, BACK, { line(name, textColor, 0.12, 0.76) })
	Kit.cylinder(ctx.Decor, "Cooler", 1.2, 1.4, base * CFrame.new(2, 4.35, 0.2), WHITE)
	return counter
end

-- Cable drum lying on its side, wound with cable
local function cableReel(ctx, x, z, rot, color)
	local base = at(ctx, x, 0, z, rot)
	local core = tube(ctx.Structure, "CableReel", 2.4, 3.3, base * CFrame.new(0, 2.2, 0), color, M.Fabric)
	for _, side in { -1, 1 } do
		tube(ctx.Decor, "ReelSide", 0.3, 4.4, base * CFrame.new(side * 1.35, 2.2, 0), rgb(120, 86, 54), M.Wood)
	end
	return core
end

-- Work light on a pole, lighting up backstage
local function workLight(ctx, x, z, rot)
	local base = at(ctx, x, 0, z, rot)
	Kit.cylinder(ctx.Structure, "LightPole", 7, 0.4, base * CFrame.new(0, 3.5, 0), YELLOW, M.Metal)
	local head = Kit.part(ctx.Decor, "WorkLight", Vector3.new(2, 1.4, 0.8), base * CFrame.new(0, 7.4, -0.3) * CFrame.Angles(math.rad(-30), 0, 0), BLACK, M.Metal)
	local lamp = Kit.neon(ctx.Decor, Vector3.new(1.7, 1.1, 0.1), head.CFrame * CFrame.new(0, 0, -0.42), rgb(255, 244, 210))
	Kit.light(lamp, rgb(255, 238, 200), 34, 1.4, "SpotLight", FRONT)
	return lamp
end

-- Pipe-and-drape wall: a black curtain on a pipe frame, hiding backstage
local function drape(ctx, x, z, rot, length, height, label)
	local base = at(ctx, x, 0, z, rot)
	local curtain = Kit.part(ctx.Structure, "Drape", Vector3.new(length, height, 0.3), base * CFrame.new(0, height / 2, 0), rgb(16, 16, 20), M.Fabric)
	if label then
		Kit.text(curtain, FRONT, { { Text = label, Color = YELLOW, Position = UDim2.fromScale(0.3, 0.3), Size = UDim2.fromScale(0.4, 0.14) } })
	end
	tube(ctx.Decor, "DrapePipe", length + 0.4, 0.3, base * CFrame.new(0, height + 0.15, 0), STEEL, M.Metal)
	for _, side in { -1, 1 } do
		Kit.part(ctx.Decor, "DrapeStand", Vector3.new(0.3, height + 0.3, 0.3), base * CFrame.new(side * (length / 2 + 0.15), (height + 0.3) / 2, 0), STEEL, M.Metal)
	end
	return curtain
end

-- Portable team room backstage: a cabin with a door, a lit window, the
-- team's name over the door and an air conditioner on the roof. The door
-- side faces -Z.
local function teamRoom(ctx, x, z, rot, color, team)
	local base = at(ctx, x, 0, z, rot)
	local cabin = Kit.part(ctx.Structure, "TeamRoom", Vector3.new(16, 9, 10), base * CFrame.new(0, 4.5, 0), rgb(196, 198, 208), M.Metal)
	Kit.part(ctx.Decor, "RoofEdge", Vector3.new(16.6, 0.6, 10.6), base * CFrame.new(0, 9.3, 0), DARK, M.Metal)
	Kit.part(ctx.Decor, "Skirt", Vector3.new(16.2, 0.8, 10.2), base * CFrame.new(0, 0.4, 0), DARK, M.Metal)
	local door = Kit.part(ctx.Decor, "Door", Vector3.new(3.4, 6.8, 0.2), base * CFrame.new(-4.6, 4.2, -5.1), rgb(40, 42, 52), M.Metal)
	Kit.text(door, FRONT, { line("PLAYERS ONLY", WHITE, 0.3, 0.07, Enum.Font.GothamBold) })
	Kit.part(ctx.Decor, "DoorStep", Vector3.new(4.4, 0.8, 2), base * CFrame.new(-4.6, 0.4, -6), DARK, M.DiamondPlate)
	local window = Kit.neon(ctx.Decor, Vector3.new(6, 2.8, 0.15), base * CFrame.new(2.6, 5, -5.05), rgb(255, 214, 170), 0.3)
	Kit.text(window, FRONT, { line("=  =  =  =  =  =", rgb(150, 110, 80), 0.05, 0.9) })
	local sign = Kit.neon(ctx.Decor, Vector3.new(11, 1.5, 0.3), base * CFrame.new(1, 8.1, -5.2), color)
	Kit.text(sign, FRONT, { line(team .. "  //  TEAM ROOM", BLACK, 0.12, 0.76) })
	local aircon = Kit.part(ctx.Decor, "AirCon", Vector3.new(4, 1.4, 3), base * CFrame.new(4, 10.3, 1.5), STEEL, M.Metal)
	Kit.text(aircon, Enum.NormalId.Top, { line("( X )", rgb(90, 94, 104), 0.1, 0.8) })
	return cabin
end

-- Giant sponsor display: a can taller than a player on a plinth with the
-- brand on it. Good round cover.
local function giantCan(ctx, x, z, rot, name, body, band, textColor)
	local base = at(ctx, x, 0, z, rot)
	local plinth = Kit.part(ctx.Structure, "Plinth", Vector3.new(5.6, 1, 5.6), base * CFrame.new(0, 0.5, 0), BLACK, M.SmoothPlastic)
	Kit.text(plinth, FRONT, { line(name, body, 0.1, 0.8) })
	local can = Kit.cylinder(ctx.Structure, "GiantCan", 8, 4.4, base * CFrame.new(0, 5, 0), body, M.Metal)
	Kit.cylinder(ctx.Decor, "CanLabel", 3.2, 4.5, base * CFrame.new(0, 5, 0), band)
	Kit.cylinder(ctx.Decor, "CanRim", 0.4, 4, base * CFrame.new(0, 9.2, 0), STEEL, M.Metal)
	Kit.part(ctx.Decor, "PullTab", Vector3.new(1, 0.15, 1.6), base * CFrame.new(0.4, 9.45, 0.5) * CFrame.Angles(0, math.rad(25), 0), STEEL, M.Metal)
	local logo = Kit.part(ctx.Decor, "CanLogo", Vector3.new(2.8, 1.6, 0.1), base * CFrame.new(0, 5, -2.3), band)
	Kit.text(logo, FRONT, { line(name, textColor, 0.1, 0.8) })
	return can
end

Maps.EsportsArena = {
	Name = "Esports Arena", Theme = "Esports", HalfX = 64, HalfZ = 56,
	Build = function(ctx)
		local height = 30
		local stageHeight = 2.5
		Kit.floor(ctx, rgb(30, 30, 38), M.SmoothPlastic)
		Kit.boundary(ctx, height, rgb(24, 24, 32), M.SmoothPlastic, PINK)
		Kit.ceiling(ctx, height, rgb(16, 16, 22))
		for _, spot in { { -34, -32 }, { 34, -32 }, { -34, 36 }, { 34, 36 } } do
			local panel = Kit.neon(ctx.Decor, Vector3.new(12, 0.3, 3), at(ctx, spot[1], height - 0.2, spot[2]), rgb(225, 225, 255))
			Kit.light(panel, rgb(225, 225, 255), 40, 1.1, "SurfaceLight", Enum.NormalId.Bottom)
		end

		-- Glowing floor lines lead from the crowd up to the caster desk
		for _, side in { -1, 1 } do
			flat(Kit.neon(ctx.Decor, Vector3.new(0.4, 0.06, 34), at(ctx, side * 4, 0.03, -37), if side < 0 then PINK else CYAN))
		end

		-- The stage: a raised deck in the middle with a ramp at each end. Seen
		-- from the crowd (-Z), +X is on the left, so the cyan team's name is too.
		local stage = Kit.part(ctx.Structure, "Stage", Vector3.new(44, stageHeight, 22), at(ctx, 0, stageHeight / 2, 4), rgb(28, 28, 36), M.Metal)
		local fascia = Kit.neon(ctx.Decor, Vector3.new(44, 1.6, 0.1), stage.CFrame * CFrame.new(0, 0, -11.05), rgb(30, 8, 44))
		Kit.text(fascia, FRONT, {
			{ Text = "WALLHACK WOLVES", Color = CYAN, Align = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.02, 0.12), Size = UDim2.fromScale(0.34, 0.76) },
			{ Text = "SPINBOT SQUAD", Color = PINK, Align = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.64, 0.12), Size = UDim2.fromScale(0.34, 0.76) },
		})
		Kit.neon(ctx.Decor, Vector3.new(44.2, 0.2, 0.2), stage.CFrame * CFrame.new(0, 1.25, -11.05), PINK)
		Kit.cylinder(ctx.Decor, "StageRing", 0.06, 10, at(ctx, 0, stageHeight + 0.03, 2.5), PINK, M.Neon)
		Kit.cylinder(ctx.Decor, "StageLogo", 0.08, 9.2, at(ctx, 0, stageHeight + 0.04, 2.5), rgb(22, 22, 30))
		Kit.ramp(ctx, -26, 4, 8, stageHeight, 8, 90, rgb(40, 40, 50), M.DiamondPlate)
		Kit.ramp(ctx, 26, 4, 8, stageHeight, 8, -90, rgb(40, 40, 50), M.DiamondPlate)

		-- On the stage: the two teams face off across the logo, the trophy up
		-- front, the anti-cheat admin's table and the LED wall behind
		local onStage = raised(ctx, stageHeight)
		teamDesk(onStage, -11, 3, 115, PINK, "SPINBOT SQUAD", "SPN", {
			{ "ESP: ON", "12 / 2 / 4" },
			{ "AIMBOT", "LOCKED ON" },
			{ "SPINBOT", "360 NO SCOPE" },
		})
		teamDesk(onStage, 11, 3, -115, CYAN, "WALLHACK WOLVES", "WHW", {
			{ "WALLS: ON", "9 / 5 / 7" },
			{ "TRIGGER", "BOT READY" },
			{ "NO RECOIL", "LASER BEAM" },
		})
		trophy(onStage, 0, -3.5, "BAN WAVE CUP")
		local admin = Kit.part(onStage.Structure, "AdminTable", Vector3.new(5, 2.8, 2), at(onStage, 0, 1.4, 9.5), rgb(230, 230, 236))
		Kit.text(admin, FRONT, { line("ANTI-CHEAT", RED, 0.15, 0.36), line("ADMIN", rgb(40, 40, 50), 0.56, 0.26, Enum.Font.GothamBold) })
		Kit.part(onStage.Decor, "Laptop", Vector3.new(1.6, 0.1, 1.1), at(onStage, 0.6, 2.85, 9.7), DARK, M.Metal)
		screen(onStage.Decor, Vector3.new(1.6, 1, 0.06), at(onStage, 0.6, 3.35, 9.1) * CFrame.Angles(math.rad(-12), math.pi, 0), rgb(40, 6, 10), { line("SUS: 0%", LIME, 0.2, 0.6) })
		ledWall(onStage, 13.5, 28, 11, PINK)
		Props.stageTruss(onStage, 0, -5.2, 0, 40, 15, PINK)

		-- In front of the stage: casters and speakers
		Props.casterDesk(ctx, 0, -16, 0, PINK, "BAN WAVE CUP")
		speaker(ctx, -26, -11, 10)
		speaker(ctx, 26, -11, -10)
		cable(ctx, -3, -14.5, -3, -7.2)
		cable(ctx, 3.4, -14.5, 3.4, -7.2, rgb(40, 30, 60))

		-- Screens hung over the sides, angled toward the crowd
		Props.jumbotron(ctx, -38, -4, -35, "SPINBOT SQUAD", "ESP + AIMBOT = 12 KILLS", PINK, 14, height)
		Props.jumbotron(ctx, 38, -4, 35, "WALLHACK WOLVES", "THEY CAN SEE YOU", CYAN, 14, height)

		-- Bleachers along both sides, with gaps to run through
		for _, spec in { { -60.1, -30, -90, PINK }, { -60.1, 4, -90, PINK }, { 60.1, -30, 90, CYAN }, { 60.1, 4, 90, CYAN } } do
			Props.bleachers(ctx, spec[1], spec[2], spec[3], 3, 22, spec[4])
		end

		-- Sponsor lightboxes high on the walls (all made up)
		for _, spec in {
			{ -63.7, -30, 90, "FRAG FUEL", LIME },
			{ -63.7, 4, 90, "NOSCOPE NOODLES", ORANGE },
			{ 63.7, -30, -90, "LAGLESS FIBER", CYAN },
			{ 63.7, 4, -90, "CLUTCH CHIPS", YELLOW },
		} do
			local box = Kit.neon(ctx.Decor, Vector3.new(22, 4.5, 0.6), at(ctx, spec[1], 19, spec[2], spec[3]), spec[5])
			Kit.text(box, BACK, { line(spec[4], BLACK, 0.12, 0.76) })
		end

		-- The crowd floor: sound desk, camera, sponsor kiosks and barriers
		fohBooth(ctx, -24, -36, 0)
		cameraRiser(ctx, 24, -36, 0)
		cable(ctx, -21, -32.4, -21, -7.2)
		cable(ctx, 21, -32.4, 21, -7.2, rgb(40, 30, 60))
		crowdBarrier(ctx, -11, -26, 0, 10, "CLUTCH CHIPS", YELLOW, BLACK)
		crowdBarrier(ctx, 11, -26, 0, 10, "LAGLESS FIBER", rgb(0, 150, 200), WHITE)
		crowdBarrier(ctx, -40, -44, 20, 10, "NOSCOPE NOODLES", ORANGE, BLACK)
		crowdBarrier(ctx, 40, -44, -20, 10, "FRAG FUEL", LIME, BLACK)
		kiosk(ctx, -40, -11, -90, "FRAG FUEL", LIME, BLACK)
		kiosk(ctx, 40, -11, 90, "CLUTCH CHIPS", YELLOW, BLACK)
		giantCan(ctx, -44, -28, 15, "FRAG FUEL", LIME, BLACK, LIME)
		giantCan(ctx, 44, -28, -15, "CLUTCH CHIPS", YELLOW, RED, WHITE)

		-- Backstage, behind the LED wall: curtains, the team rooms, flight
		-- cases and cable
		drape(ctx, -39, 21, 0, 18, 9, "CREW ONLY")
		drape(ctx, 39, 21, 0, 18, 9, "CREW ONLY")
		teamRoom(ctx, -42, 51, 0, PINK, "SPINBOT SQUAD")
		teamRoom(ctx, 42, 51, 0, CYAN, "WALLHACK WOLVES")
		local case = Vector3.new(5, 3.6, 3.4)
		roadCase(ctx, -40, 32, 10, case, "STAGE LEFT")
		roadCase(ctx, -40, 32, 4, Vector3.new(4, 2.6, 3), "MICS", rgb(30, 34, 60), 3.6)
		roadCase(ctx, -18, 40, 90, case, "LIGHTS")
		roadCase(ctx, -12.5, 40, 90, case, "LIGHTS")
		roadCase(ctx, 2, 28, 0, Vector3.new(6, 3, 3.4), "SCREENS")
		roadCase(ctx, 24, 36, -15, case, "TEAM GEAR", rgb(120, 20, 50))
		roadCase(ctx, 24, 36, -10, Vector3.new(4, 2.6, 3), "KEYBOARDS", rgb(120, 20, 50), 3.6)
		roadCase(ctx, 54, 30, 90, Vector3.new(6, 4.4, 4), "SPARE PCS", rgb(30, 34, 60))
		Kit.crate(ctx, -54, 38, 6, 15, true)
		Kit.crate(ctx, 4, 46, 5, 30)
		cableReel(ctx, 12, 30, 90, rgb(30, 30, 34))
		cableReel(ctx, -20, 51, 0, rgb(190, 40, 40))
		cable(ctx, -2, 15.2, -2, 26.2)
		workLight(ctx, -16, 24, 160)
		workLight(ctx, 16, 24, -160)
	end,
}

-- LAN Cafe pieces ----------------------------------------------------------------

-- LAN desk block: a tall partition with a row of gaming stations on each
-- side, running along Z. Players sit facing the partition from both sides,
-- so the block is about 12 wide. Row letters go on the end panels and
-- station numbers above each screen. `screens` is a list of { big, small }
-- texts, used in turn starting after `skip` of them.
local function lanBlock(ctx, x, z, seats, color, row, screens, skip)
	local length = seats * 5.2 + 0.8
	local partition = Kit.part(ctx.Structure, "Partition", Vector3.new(0.5, 6, length), at(ctx, x, 3, z), rgb(52, 48, 70), M.Fabric)
	Kit.neon(ctx.Decor, Vector3.new(0.7, 0.2, length + 0.2), at(ctx, x, 6.1, z), color)
	for _, side in { -1, 1 } do
		local panel = Kit.part(ctx.Structure, "DeskEnd", Vector3.new(7.4, 3, 0.4), at(ctx, x, 1.5, z + side * (length / 2 + 0.2)), DARK, M.Metal)
		Kit.text(panel, if side < 0 then FRONT else BACK, { line("ROW " .. row, color, 0.15, 0.7) })
	end
	local count = 0
	for _, rot in { -90, 90 } do
		local base = at(ctx, x, 0, z, rot)
		Kit.part(ctx.Structure, "Desk", Vector3.new(length, 0.3, 3.2), base * CFrame.new(0, 2.85, -1.85), BLACK)
		local labels = {}
		for seat = 1, seats do
			count += 1
			local sx = -length / 2 + 3 + (seat - 1) * 5.2
			local text = screens[(skip + count - 1) % #screens + 1]
			Kit.part(ctx.Decor, "Monitor", Vector3.new(2.8, 1.65, 0.15), base * CFrame.new(sx, 4.6, -0.4), BLACK)
			screen(ctx.Decor, Vector3.new(2.6, 1.45, 0.05), base * CFrame.new(sx, 4.6, -0.5), rgb(14, 12, 34), {
				line(text[1], color, 0.1, 0.46),
				line(text[2], WHITE, 0.62, 0.26, Enum.Font.GothamBold),
			})
			Kit.neon(ctx.Decor, Vector3.new(1.9, 0.1, 0.62), base * CFrame.new(sx - 0.3, 3.05, -2.6), color)
			-- Gaming chair pulled up to the desk
			local chair = base * CFrame.new(sx, 0, -4.6)
			Kit.cylinder(ctx.Decor, "ChairBase", 0.25, 2.3, chair * CFrame.new(0, 0.13, 0), BLACK, M.Metal)
			Kit.cylinder(ctx.Decor, "GasLift", 1.5, 0.3, chair * CFrame.new(0, 0.95, 0), STEEL, M.Metal)
			Kit.part(ctx.Structure, "Chair", Vector3.new(2.1, 0.5, 2.1), chair * CFrame.new(0, 1.95, 0), BLACK, M.Fabric)
			Kit.part(ctx.Decor, "ChairBack", Vector3.new(2.1, 3.4, 0.45), chair * CFrame.new(0, 2.2, -0.95) * CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 1.7, 0), color, M.Fabric)
			-- The station number goes on the partition above the screen. Seen
			-- from this side, the partition's left edge is this row's +X end.
			local across = (sx + length / 2) / length
			table.insert(labels, { Text = row .. seat, Color = color, Position = UDim2.fromScale(1 - across - 0.05, 0.05), Size = UDim2.fromScale(0.1, 0.1) })
		end
		Kit.text(partition, if rot < 0 then Enum.NormalId.Right else Enum.NormalId.Left, labels)
	end
	return partition
end

-- Bar stool: a round seat on a post
local function stool(ctx, x, z, color)
	Kit.cylinder(ctx.Decor, "StoolPost", 3, 0.3, at(ctx, x, 1.5, z), STEEL, M.Metal)
	return Kit.cylinder(ctx.Structure, "Stool", 0.45, 1.7, at(ctx, x, 3.2, z), color, M.Fabric)
end

-- Round high table on one leg, chest-high cover
local function highTable(ctx, x, z, color)
	Kit.cylinder(ctx.Structure, "TableLeg", 3.8, 0.6, at(ctx, x, 1.9, z), STEEL, M.Metal)
	Kit.light(Kit.cylinder(ctx.Decor, "TableGlow", 0.12, 3.9, at(ctx, x, 3.75, z), color, M.Neon), color, 8, 0.6)
	return Kit.cylinder(ctx.Structure, "HighTable", 0.3, 3.8, at(ctx, x, 3.95, z), WHITE, M.Marble)
end

-- A stack of cardboard boxes with new gear, the top one turned a bit
local function boxStack(ctx, x, z, rot, label)
	local box = Kit.box(ctx, x, z, 4.4, 3.4, 3.4, rgb(170, 128, 82), M.Cardboard, rot)
	for _, face in { FRONT, BACK } do
		Kit.text(box, face, { line(label, rgb(70, 46, 26), 0.15, 0.3), line("FRAGILE - THIS SIDE UP", rgb(160, 30, 30), 0.6, 0.16, Enum.Font.GothamBold) })
	end
	Kit.box(ctx, x, z, 3.6, 2.6, 3, rgb(186, 144, 96), M.Cardboard, (rot or 0) + 18, 3.4)
	return box
end

-- A square pillar with glowing strips down two of its corners
local function pillar(ctx, x, z, height, color)
	local column = Kit.pillar(ctx, x, z, 3, height, rgb(46, 42, 62), M.SmoothPlastic)
	for _, corner in { -1, 1 } do
		Kit.neon(ctx.Decor, Vector3.new(0.3, height, 0.3), column.CFrame * CFrame.new(corner * 1.45, 0, -1.45), color)
	end
	return column
end

-- A poster on a wall, with its middle `y` up. (x, z) is on the wall's face
-- and the poster faces -Z when rot is 0.
local function poster(ctx, x, y, z, rot, color, title, subtitle, titleColor)
	local sheet = Kit.part(ctx.Decor, "Poster", Vector3.new(3.6, 5, 0.06), at(ctx, x, y, z, rot), color)
	Kit.text(sheet, FRONT, {
		line(title, titleColor or WHITE, 0.08, 0.36),
		line(subtitle, WHITE, 0.74, 0.14, Enum.Font.GothamBold),
	})
	return sheet
end

Maps.LanCafe = {
	Name = "LAN Cafe", Theme = "LanCafe", HalfX = 56, HalfZ = 50,
	Build = function(ctx)
		local height = 15
		Kit.floor(ctx, rgb(52, 44, 74), M.Carpet)
		Kit.boundary(ctx, height, rgb(40, 34, 56), M.SmoothPlastic, PURPLE)
		Kit.ceiling(ctx, height, rgb(22, 20, 30))

		-- Three blocks of gaming stations with 10-wide aisles between them, and
		-- glowing lines down the floor of the middle two aisles
		local screens = {
			{ "RANKED", "SEARCHING..." },
			{ "VICTORY", "+250 CR" },
			{ "ESP: ON", "I SEE YOU" },
			{ "GG EZ", "#1 OF 64" },
			{ "WAVE 5", "3 BOTS LEFT" },
			{ "AFK", "BRB PIZZA" },
			{ "BANNED", "BAN WAVE HIT" },
			{ "LOADING", "PLEASE WAIT" },
		}
		for index, spec in { { -22, PINK, "A" }, { 0, CYAN, "B" }, { 22, PURPLE, "C" } } do
			lanBlock(ctx, spec[1], 8, 3, spec[2], spec[3], screens, index * 3)
			local strip = Kit.neon(ctx.Decor, Vector3.new(1.4, 0.3, 18), at(ctx, spec[1], height - 0.2, 8), rgb(235, 230, 255))
			Kit.light(strip, rgb(235, 230, 255), 26, 1.2, "SurfaceLight", Enum.NormalId.Bottom)
		end
		for _, side in { -1, 1 } do
			flat(Kit.neon(ctx.Decor, Vector3.new(0.35, 0.06, 64), at(ctx, side * 11, 0.03, -10), if side < 0 then PINK else CYAN))
		end
		for _, spot in { { -30, -32 }, { 30, -32 }, { 0, 34 } } do
			local panel = Kit.neon(ctx.Decor, Vector3.new(10, 0.3, 3), at(ctx, spot[1], height - 0.2, spot[2]), rgb(255, 236, 214))
			Kit.light(panel, rgb(255, 230, 205), 34, 1.2, "SurfaceLight", Enum.NormalId.Bottom)
		end
		pillar(ctx, -38, -6, height, PINK)
		pillar(ctx, 38, -6, height, CYAN)
		pillar(ctx, -38, 24, height, PINK)
		pillar(ctx, 38, 24, height, CYAN)

		-- Front of the cafe: glass doors behind the player, the check-in
		-- podium and two high tables
		local doors = Kit.part(ctx.Decor, "Doors", Vector3.new(10, 8, 0.2), at(ctx, 0, 4, -49.85), rgb(170, 210, 240), M.Glass, 0.45)
		Kit.text(doors, BACK, { line("PING ZERO", WHITE, 0.3, 0.14), line("PUSH", rgb(220, 230, 240), 0.55, 0.08, Enum.Font.GothamBold) })
		local exit = Kit.neon(ctx.Decor, Vector3.new(3, 1, 0.2), at(ctx, 0, 9.2, -49.85), rgb(60, 255, 120))
		Kit.text(exit, BACK, { line("EXIT", BLACK, 0.1, 0.8) })
		local mat = flat(Kit.part(ctx.Decor, "Mat", Vector3.new(10, 0.06, 5), at(ctx, 0, 0.03, -47), rgb(24, 22, 32), M.Fabric))
		Kit.text(mat, Enum.NormalId.Top, { line("WELCOME, GAMERS", PINK, 0.3, 0.4) })
		local podium = Kit.part(ctx.Structure, "CheckIn", Vector3.new(5, 3.6, 2.2), at(ctx, 0, 1.8, -20), DARK, M.Metal)
		Kit.text(podium, FRONT, { line("CHECK IN", PINK, 0.15, 0.36), line("PICK A PC, ANY PC", WHITE, 0.6, 0.2, Enum.Font.GothamBold) })
		Kit.neon(ctx.Decor, Vector3.new(5.1, 0.15, 2.3), at(ctx, 0, 3.55, -20), PINK)
		screen(ctx.Decor, Vector3.new(2.4, 1.5, 0.1), at(ctx, 0, 4.5, -19.6) * CFrame.Angles(math.rad(-15), math.pi, 0), rgb(20, 10, 40), { line("FREE PCS: 2", LIME, 0.2, 0.6) })
		highTable(ctx, -16, -26, PINK)
		highTable(ctx, 16, -26, CYAN)

		-- West wall: snack bar with stools, a drink machine and the arcade
		Props.snackCounter(ctx, -53, -30, -90, YELLOW, "SNACK BAR")
		for _, z in { -33, -30, -27 } do
			stool(ctx, -49.4, z, RED)
		end
		Props.vendingMachine(ctx, -54.4, -16, -90, LIME, "FRAG FUEL")
		Props.arcadeCabinet(ctx, -54.45, 30, -90, PURPLE, "BOT BLASTER")
		Props.arcadeCabinet(ctx, -54.45, 33.6, -90, CYAN, "NOOB INVADERS")
		poster(ctx, -55.95, 6, -2, -90, rgb(110, 20, 60), "BAN WAVE II", "IN CAFES NOW", YELLOW)
		poster(ctx, -55.95, 6, 8, -90, rgb(20, 40, 110), "AIM TRAINER", "TUESDAYS 2X CREDITS", CYAN)
		poster(ctx, -55.95, 6, 18, -90, rgb(30, 90, 50), "BOT BLASTER", "HIGH SCORE: 99,999", LIME)

		-- North wall: the cafe's sign, tonight's bracket and boxes of new PCs
		Kit.sign(ctx, 0, 10.5, 49.6, 0, 30, 4.5, "PING ZERO  LAN CAFE", PINK)
		local bracket = Kit.neon(ctx.Decor, Vector3.new(16, 3.6, 0.2), at(ctx, 0, 5, 49.85), rgb(16, 12, 34))
		Kit.text(bracket, FRONT, {
			line("FRIDAY LAN  -  BAN WAVE CUP QUALIFIER", YELLOW, 0.08, 0.3),
			line("SPINBOT SQUAD vs WALLHACK WOLVES  |  8 PM", WHITE, 0.52, 0.26, Enum.Font.GothamBold),
		})
		boxStack(ctx, -28, 34, 10, "NEW PCs")
		boxStack(ctx, -6, 40, -8, "MONITORS")
		boxStack(ctx, 16, 36, 25, "CHAIRS")

		-- North-east corner: a small server closet with a window and a door
		local wall = rgb(58, 52, 74)
		Kit.part(ctx.Structure, "ClosetWall", Vector3.new(1, height, 4), at(ctx, 40.5, height / 2, 36), wall, M.SmoothPlastic)
		local side = Kit.part(ctx.Structure, "ClosetWall", Vector3.new(1, height, 6), at(ctx, 40.5, height / 2, 47), wall, M.SmoothPlastic)
		Kit.text(side, Enum.NormalId.Left, { line("NO FOOD", WHITE, 0.4, 0.06, Enum.Font.GothamBold), line("NO DRINKS", WHITE, 0.47, 0.06, Enum.Font.GothamBold) })
		Kit.part(ctx.Structure, "ClosetWall", Vector3.new(1, height - 8, 6), at(ctx, 40.5, 8 + (height - 8) / 2, 41), wall, M.SmoothPlastic)
		Kit.part(ctx.Structure, "ClosetWall", Vector3.new(15, 3.5, 1), at(ctx, 48.5, 1.75, 33.5), wall, M.SmoothPlastic)
		Kit.part(ctx.Structure, "ClosetGlass", Vector3.new(15, 5, 0.4), at(ctx, 48.5, 6, 33.5), rgb(150, 200, 240), M.Glass, 0.6)
		local top = Kit.part(ctx.Structure, "ClosetWall", Vector3.new(15, height - 8.5, 1), at(ctx, 48.5, 8.5 + (height - 8.5) / 2, 33.5), wall, M.SmoothPlastic)
		Kit.text(top, FRONT, { line("SERVER ROOM", CYAN, 0.12, 0.3), line("PING: 0 MS  -  UPTIME: 99.9%", WHITE, 0.5, 0.14, Enum.Font.GothamBold) })
		local doorSign = Kit.neon(ctx.Decor, Vector3.new(0.2, 1.2, 5), at(ctx, 39.9, 9, 41), CYAN)
		Kit.text(doorSign, Enum.NormalId.Left, { line("SERVER ROOM  -  STAFF ONLY", BLACK, 0.12, 0.76, Enum.Font.GothamBold) })
		flat(Kit.part(ctx.Decor, "RaisedFloor", Vector3.new(15, 0.08, 16), at(ctx, 48.5, 0.04, 42), rgb(120, 126, 138), M.DiamondPlate))
		Props.serverRack(ctx, 46, 47.9, 0, CYAN, "GAME SERVER 01")
		Props.serverRack(ctx, 50.6, 47.9, 0, PINK, "GAME SERVER 02")
		local cooler = Kit.part(ctx.Structure, "CoolingUnit", Vector3.new(2.5, 7, 4), at(ctx, 54.6, 3.5, 38), rgb(200, 204, 212), M.Metal)
		Kit.text(cooler, Enum.NormalId.Left, { line("COOLING", rgb(40, 90, 160), 0.1, 0.1), line("|||||||||||", rgb(120, 124, 134), 0.3, 0.4) })

		-- South-east corner: the lounge, on a carpeted step behind a planter,
		-- with a big TV on the wall
		local step = 0.8
		Kit.part(ctx.Structure, "LoungeFloor", Vector3.new(17, step, 23), at(ctx, 47.5, step / 2, -38.5), rgb(96, 46, 130), M.Carpet)
		Kit.neon(ctx.Decor, Vector3.new(0.2, 0.12, 23), at(ctx, 38.95, step - 0.1, -38.5), PINK)
		Kit.neon(ctx.Decor, Vector3.new(17, 0.12, 0.2), at(ctx, 47.5, step - 0.1, -27.05), PINK)
		local planter = Kit.part(ctx.Structure, "Planter", Vector3.new(14, 3, 2.4), at(ctx, 44, 1.5, -24), rgb(70, 52, 40), M.Wood)
		for index = -1, 1 do
			Kit.ball(ctx.Decor, "Plant", 3.4, planter.CFrame * CFrame.new(index * 4.4, 2.2, 0), rgb(70, 140, 70), M.Grass)
		end
		local lounge = raised(ctx, step)
		Props.couch(lounge, 42, -37, -90, rgb(74, 62, 120), 9)
		Props.beanbag(lounge, 48, -45, -120, CYAN)
		Props.beanbag(lounge, 48, -30, -60, PINK)
		Kit.part(lounge.Structure, "CoffeeTable", Vector3.new(2.6, 1.4, 5), at(lounge, 47.5, 0.7, -37), rgb(120, 80, 50), M.Wood)
		local pizza = Kit.part(lounge.Decor, "PizzaBox", Vector3.new(2, 0.3, 2), at(lounge, 47.5, 1.55, -38, 12), rgb(230, 214, 180), M.Cardboard)
		Kit.text(pizza, Enum.NormalId.Top, { line("PIZZA", RED, 0.3, 0.4) })
		Kit.part(lounge.Decor, "TvStand", Vector3.new(2, 2, 8), at(lounge, 54.9, 1, -37), BLACK)
		Kit.part(lounge.Decor, "Console", Vector3.new(1.4, 0.5, 2), at(lounge, 54.9, 2.25, -37), WHITE)
		Kit.part(ctx.Decor, "Tv", Vector3.new(0.4, 6, 10.4), at(ctx, 55.7, 7.3, -37), BLACK)
		screen(ctx.Decor, Vector3.new(9.9, 5.5, 0.05), at(ctx, 55.47, 7.3, -37, 90), rgb(30, 10, 60), {
			line("BOT BLASTER 2", YELLOW, 0.2, 0.3, Enum.Font.Arcade),
			line("PRESS START", WHITE, 0.62, 0.14, Enum.Font.Arcade),
		})

		-- East wall: house rules and more posters
		local rules = Kit.part(ctx.Decor, "Rules", Vector3.new(6, 6.5, 0.1), at(ctx, 55.95, 6.5, -8, 90), rgb(240, 236, 228))
		Kit.text(rules, FRONT, {
			line("HOUSE RULES", RED, 0.04, 0.12),
			{ Text = "1. NO CHEATING*\n2. NO RAGE QUITTING\n3. FOOD STAYS OFF KEYBOARDS\n4. GG AFTER EVERY MATCH\n\n*unless you bought the hack", Color = rgb(40, 40, 50), Font = Enum.Font.GothamBold, Align = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.08, 0.22), Size = UDim2.fromScale(0.84, 0.7) },
		})
		poster(ctx, 55.95, 6, 4, 90, rgb(60, 20, 110), "NOOB INVADERS", "THEY'RE BACK", PINK)
		poster(ctx, 55.95, 6, 14, 90, rgb(110, 60, 10), "LAN NIGHT", "EVERY FRIDAY", YELLOW)
	end,
}

return Maps
