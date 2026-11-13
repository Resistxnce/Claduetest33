--[[
	Tyre compounds. All values are simulation estimates, to be tuned in testing.

	muLong / muLat      peak friction coefficient at the nominal load (braking/driving, cornering)
	peakSlipRatio       slip ratio where the braking/driving peak occurs
	peakSlipAngle       slip angle in degrees where the cornering peak occurs
	shapeLong/shapeLat  magic formula shape factor C; sliding grip settles at sin(C * pi / 2) of the peak
	loadSensitivity     grip lost per 100% extra load (heavily loaded tyres grip less per newton)
	nominalLoad         load in N where mu applies as written
	relaxationLength    metres of travel for the slip angle to build up (tyre lag)
	rollingResistance   rolling resistance coefficient
]]

return {
	Street = {
		muLong = 1.05,
		muLat = 0.98,
		peakSlipRatio = 0.12,
		peakSlipAngle = 9,
		shapeLong = 1.35,
		shapeLat = 1.45,
		loadSensitivity = 0.10,
		nominalLoad = 4000,
		relaxationLength = 0.40,
		rollingResistance = 0.013,
	},
	Sport = {
		muLong = 1.30,
		muLat = 1.12,
		peakSlipRatio = 0.11,
		peakSlipAngle = 8,
		shapeLong = 1.35,
		shapeLat = 1.45,
		loadSensitivity = 0.09,
		nominalLoad = 4200,
		relaxationLength = 0.30,
		rollingResistance = 0.012,
	},
	-- Stock tyre for the GT12 prototype (a road performance tyre on 20-inch wheels).
	Performance = {
		muLong = 1.45,
		muLat = 1.22,
		peakSlipRatio = 0.10,
		peakSlipAngle = 7.5,
		shapeLong = 1.35,
		shapeLat = 1.45,
		loadSensitivity = 0.08,
		nominalLoad = 4400,
		relaxationLength = 0.25,
		rollingResistance = 0.012,
	},
	SemiSlick = {
		muLong = 1.62,
		muLat = 1.38,
		peakSlipRatio = 0.09,
		peakSlipAngle = 6.5,
		shapeLong = 1.40,
		shapeLat = 1.55,
		loadSensitivity = 0.07,
		nominalLoad = 4600,
		relaxationLength = 0.20,
		rollingResistance = 0.011,
	},
}
