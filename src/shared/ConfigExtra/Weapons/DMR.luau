-- Marksman Rifle: a scoped semi-auto between the Revolver and the Sniper. Hits hard,
-- fires as fast as you click, and zooms less than the Sniper.
return {
	Id = "DMR", Name = "Marksman Rifle", Cost = 14000, Damage = 80, FireInterval = 0.38, Magazine = 10, Reload = 2.5, Recoil = 3.5,
	Scope = 45, Walk = 0.95, Spread = { Base = 0.1, PerShot = 0.5, Max = 2.5, Moving = 2.5 }, Description = "Right click to scope. Shoots as fast as you click.",
}
