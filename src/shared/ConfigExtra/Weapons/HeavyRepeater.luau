-- Heavy Repeater: twin-barrel heavy gun fed from a 100-round ammo box. More damage
-- per second than the Rifle and no spin-up, but less than the Minigun and a long reload.
return {
	Id = "HeavyRepeater", Name = "Heavy Repeater", Cost = 32000, Damage = 18, FireInterval = 0.085, Magazine = 100, Reload = 3.6, Recoil = 1,
	Walk = 0.8, Spread = { Base = 0.9, PerShot = 0.2, Max = 4, Moving = 1.8 }, Description = "Twin barrels, 100-round box. Hold the trigger.",
}
