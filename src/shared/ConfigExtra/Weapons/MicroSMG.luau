-- Micro SMG stats: a boxy machine pistol, a side-grade to the SMG. Fires faster
-- with a quick reload, but each bullet is weaker and it sprays wider.
return {
	Id = "MicroSMG", Name = "Micro SMG", Cost = 1200, Damage = 10, FireInterval = 0.055, Magazine = 25, Reload = 1.25, Recoil = 0.6,
	Spread = { Base = 1.5, PerShot = 0.28, Max = 5.5, Moving = 1 }, Description = "Tiny bullet hose. Empties in a blink.",
}
