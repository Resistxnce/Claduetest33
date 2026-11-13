--[[
	Traffic driver profiles and the shared traffic settings.

	Each traffic car gets a profile, then its own desired speed within the profile's range, so no
	two cars drive alike. Values follow typical highway calibrations of the Intelligent Driver Model
	and MOBIL (Treiber and Kesting, "Traffic Flow Dynamics", 2013) and are tuned in testing.

	  speed       desired speed range, km/h
	  gap         desired time gap to the car ahead, s
	  minGap      gap kept when stopped, m
	  accel       comfortable acceleration, m/s^2
	  decel       comfortable braking, m/s^2
	  politeness  MOBIL politeness: how much the gains and losses of others count, 0 to 1
	  threshold   MOBIL threshold: how much better a lane must be before changing, m/s^2
	  length, width   body size, m
	  lateral     the most sideways acceleration the driver accepts in a curve, m/s^2; traffic slows
	              for curves so that it stays within this (comfortable values, Traffic Flow Dynamics
	              and highway design guides put typical drivers at 2 to 3 m/s^2)
	  rightLanes  if set, the profile only uses this many lanes on the right (trucks)
	  share       how common the profile is
]]

local DriverProfiles = {}

DriverProfiles.profiles = {
	cautious = { speed = { 95, 110 }, gap = 1.8, minGap = 2.5, accel = 1.0, decel = 1.5, politeness = 0.5, threshold = 0.3, length = 4.6, width = 1.8, lateral = 2.0, share = 0.25 },
	normal = { speed = { 110, 130 }, gap = 1.4, minGap = 2.0, accel = 1.4, decel = 2.0, politeness = 0.3, threshold = 0.2, length = 4.7, width = 1.85, lateral = 2.4, share = 0.45 },
	aggressive = { speed = { 130, 155 }, gap = 0.9, minGap = 1.5, accel = 2.0, decel = 2.5, politeness = 0.1, threshold = 0.1, length = 4.6, width = 1.85, lateral = 3.0, share = 0.15 },
	truck = { speed = { 80, 90 }, gap = 1.8, minGap = 3.0, accel = 0.6, decel = 1.5, politeness = 0.5, threshold = 0.3, length = 14.0, width = 2.5, lateral = 1.6, rightLanes = 2, share = 0.15 },
}
-- fixed order, so random choices are repeatable for a given seed
DriverProfiles.order = { "cautious", "normal", "aggressive", "truck" }

DriverProfiles.MAX_DECEL = 9.0 -- m/s^2, the hardest any car can brake
DriverProfiles.KEEP_RIGHT_BIAS = 0.25 -- m/s^2 added to the incentive for moving right
DriverProfiles.SAFE_DECEL = 4.0 -- m/s^2, the most a new follower may have to brake for a lane change
DriverProfiles.LANE_CHANGE_TIME = 3.0 -- seconds to move across one lane
DriverProfiles.DECISION_INTERVAL = { 1.0, 2.0 } -- seconds between a driver's lane-change decisions
DriverProfiles.MIN_TIME_IN_LANE = 4.0 -- seconds after a lane change before the next one
-- how traffic expects a player's car to brake, used in the lane-change safety check
DriverProfiles.PLAYER = { gap = 1.0, minGap = 2.0, accel = 3.0, decel = 6.0 }
-- Curves: each profile has a speed limit for every LIMIT_STEP metres of road, from its lateral
-- comfort and the curvature (RoadGeometry:speedLimits), lowered ahead of each curve so that slowing
-- at CURVE_DECEL gets there in time. A driver aims for the limit CURVE_LOOKAHEAD seconds ahead and
-- closes the difference over CURVE_RESPONSE seconds.
DriverProfiles.LIMIT_STEP = 10 -- m
DriverProfiles.CURVE_DECEL = 1.0 -- m/s^2
DriverProfiles.CURVE_LOOKAHEAD = 1.0 -- s
DriverProfiles.CURVE_RESPONSE = 1.0 -- s

return DriverProfiles
