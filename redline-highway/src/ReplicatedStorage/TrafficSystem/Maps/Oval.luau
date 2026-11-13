--[[
	Map data: Redline Proving Ground, a 4-lane highway oval with 2.4 km straights and 650 m radius
	curves eased in by 200 m transition curves. Flat, so acceleration, braking and top-speed runs
	on the main straight measure the car and nothing else. A 300 m covered gallery on the back
	straight gives tunnel sound something to test.

	Read by TrafficSystem/RoadGeometry (see there for the meaning of each field) and by
	tools/road_geometry.py, which reads only plain numbers, strings and tables, so keep this module
	free of expressions. Distances are metres, angles degrees; positive curve angles turn right.
]]

return {
	id = "Oval",
	displayName = "Redline Proving Ground",
	lanes = 4,
	laneWidth = 3.75,
	shoulderLeft = 3.0,
	shoulderRight = 3.0,
	-- where s = 0 is (the start of the main straight), and the direction of travel there (0 = +X)
	origin = { -1200, 0, -652.5701219231985 },
	heading = 0,
	plan = {
		{ "straight", 2400 }, -- main straight, along +X
		{ "curve", 650, 180, 200 },
		{ "straight", 2400 }, -- back straight
		{ "curve", 650, 180, 200 },
	},
	-- points { s, height, vertical curve length }: level all round
	elevation = {
		{ 0, 0, 0 },
	},
	sections = {
		{ kind = "tunnel", style = "gallery", from = 5600, to = 5900, name = "Back Straight Gallery", reverb = 0.8 },
	},
	start = 150, -- start line, m along the main straight
	lighting = "Afternoon",
	-- traffic: cars per km per lane, random seed, first car id (ids stay unique across maps), and the
	-- distance kept clear around the start grid when the server starts
	traffic = { density = 5, seed = 812, idBase = 0, clearance = 200 },
}
