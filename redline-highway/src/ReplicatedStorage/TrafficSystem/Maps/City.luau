--[[
	Map data: Sekirei Bay Loop, a fictional night-time city expressway in the style of an elevated
	urban motorway: a 3-lane one-way loop of concrete viaducts with tight walls, two sodium-lit
	tunnels, sweeping junction curves, a 270-degree loop ramp that climbs over its own approach, and
	a 2.9 km straight along the bay. All names are invented.

	Route (s = 0 is the east end of the bay straight, heading west, bay on the left):
	  0 - 2600       Seaside Straight, on piers along the bay, 14 m up (continues from 12,387)
	  2600 - 3337    Kirameki JCT: right, R 380, climbing to 22 m
	  3337 - 5156    the Ward S-bends through dense city (R 260 left, R 240 right), then the descent
	  5100 - 7600    Kagerou Tunnel (2.5 km), with a gentle S (R 1100) near the far end
	  7600 - 9125    climb to the loop approach, 9 m up
	  9125 - 10225   Tsukimi JCT loop: left 270 degrees, R 210, climbing over the approach at s 10,382
	  10950 - 11550  Hotaru Tunnel (0.6 km) through the east S-bend
	  11587 - 12387  Umikaze JCT: right, R 420, back onto the bay

	Read by TrafficSystem/RoadGeometry (see there for the meaning of each field) and by
	tools/road_geometry.py, which reads only plain numbers, strings and tables, so keep this module
	free of expressions. The two long straights' lengths were solved so the loop closes exactly; if
	you change the plan, re-solve them (the road warns in Output when the loop doesn't close).
	Distances are metres, angles degrees; positive curve angles turn right.
]]

return {
	id = "City",
	displayName = "Sekirei Bay Loop",
	lanes = 3,
	laneWidth = 3.5,
	shoulderLeft = 0.75,
	shoulderRight = 1.25,
	origin = { 900, 0, 9000 },
	heading = 180,
	plan = {
		{ "straight", 2600 }, -- Seaside Straight
		{ "curve", 380, 90, 140 }, -- Kirameki JCT
		{ "straight", 400 },
		{ "curve", 260, -32, 90 }, -- Ward S-bends
		{ "straight", 160 },
		{ "curve", 240, 62, 90 },
		{ "straight", 250 },
		{ "curve", 300, 60, 110 }, -- down into Kagerou Tunnel
		{ "straight", 2087.939120501273 },
		{ "curve", 1100, 18, 120 },
		{ "straight", 500 },
		{ "curve", 1100, -18, 120 },
		{ "straight", 450 }, -- loop approach, under the loop's exit
		{ "curve", 210, -270, 110 }, -- Tsukimi JCT loop
		{ "straight", 300 },
		{ "curve", 450, 25, 120 }, -- east S-bend, through Hotaru Tunnel
		{ "straight", 250 },
		{ "curve", 450, -25, 120 },
		{ "straight", 179.59232962994145 },
		{ "curve", 420, 90, 140 }, -- Umikaze JCT
		{ "straight", 300 },
	},
	-- points { s, height above the street, vertical curve length }
	elevation = {
		{ 0, 14, 0 },
		{ 2350, 14, 300 },
		{ 3150, 22, 400 },
		{ 4250, 19, 300 },
		{ 4950, 0.5, 300 },
		{ 7700, 0.5, 300 },
		{ 8450, 9, 300 },
		{ 9000, 9, 300 },
		{ 10380, 21, 300 },
		{ 10850, 0.5, 300 },
		{ 11650, 0.5, 300 },
		{ 12150, 14, 300 },
	},
	sections = {
		{ kind = "tunnel", style = "box", from = 5100, to = 7600, name = "Kagerou Tunnel", reverb = 2.2 },
		{ kind = "tunnel", style = "box", from = 10950, to = 11550, name = "Hotaru Tunnel", reverb = 1.6 },
	},
	start = 150,
	lighting = "Night",
	traffic = { density = 6, seed = 1107, idBase = 30000, clearance = 200 },
	-- scenery for CityBuilder (and the map picture): the shore line (world z, m; water to the south,
	-- up to the far shore), and two decorative viaducts that cross the loop at a junction (s, at
	-- angle degrees to the road, deck top height in m) and run back and ahead (m) to ramps that meet
	-- the ground
	decor = {
		shore = 8970,
		farShore = 12500,
		flyovers = {
			{ name = "Kirameki Bay Viaduct", s = 2860, angle = 55, top = 6.5, back = 3750, ahead = 560, ramp = 300 },
			{ name = "Umikaze Bay Bridge", s = 12230, angle = -60, top = 23, back = 650, ahead = 3800, ramp = 420, towers = true },
		},
	},
}
