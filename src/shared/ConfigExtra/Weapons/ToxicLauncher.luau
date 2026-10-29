-- Toxic Launcher stats: a grenade launcher between the Minigun and the Rocket
-- Launcher. Less damage and splash than a rocket, but four shots per mag.
return {
	Id = "ToxicLauncher", Name = "Toxic Launcher", Cost = 60000, Damage = 80, Splash = 9, FireInterval = 0.85, Magazine = 4, Reload = 2.8, Recoil = 4.5,
	Walk = 0.9, Spread = { Base = 0.35, PerShot = 0.4, Max = 1.6, Moving = 1.2 }, Description = "Four toxic blasts per mag. Splash melts groups.",
}
