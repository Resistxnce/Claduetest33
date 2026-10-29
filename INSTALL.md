# Adding these models to Earn ESP

Everything in `src/` uses the same layout as the game's Rojo project
(`EarnEsp/src`), so installing is: copy the files, then add a few hook lines to
five game files. Nothing in the game is replaced or reordered.

## 0. Get the files onto your PC

Pick one:

- **Easiest:** in the Claude Code session that works on the game on your PC
  (the one in `Downloads\Build\EarnEsp`), say: *"Clone
  github.com/Resistxnce/Claduetest33 and install the models into EarnEsp by
  following its INSTALL.md"*. It can do steps 1 to 3 for you.
- **By hand:** on the GitHub page, click **Code > Download ZIP** and unzip it.
  If you use git, run
  `git clone https://github.com/Resistxnce/Claduetest33` instead. Then do
  steps 1 and 2 yourself.

To get later updates, download the ZIP again or run `git pull`.

## 1. Copy the files

Copy this repo's `src/` folders into the game's `src/`, keeping the paths:

| From this repo | To the game | What it is |
|---|---|---|
| `src/shared/GunSpecsExtra/` (folder) | `src/shared/GunSpecsExtra/` | One part list per gun in `Guns/`: 13 new guns, plus new looks for the game's 8 guns |
| `src/shared/ConfigExtra/` (folder) | `src/shared/ConfigExtra/` | Stats for the new guns (`Weapons/`), bot types and waves, map lighting themes and map pool ids |
| `src/server/BotOutfits.luau` | `src/server/BotOutfits.luau` | Outfits for the new bots, bosses and lobby NPCs, plus boss trash talk |
| `src/server/LobbyNpcs.luau` | `src/server/LobbyNpcs.luau` | Friendly lobby characters (Skin Spin vendor and others) |
| `src/server/Maps/Props.luau` | `src/server/Maps/Props.luau` | New map props, written like `Kit.luau` |
| `src/server/Maps/Esports.luau` | `src/server/Maps/Esports.luau` | Esports Arena and LAN Cafe maps |
| `src/server/Maps/AntiCheat.luau` | `src/server/Maps/AntiCheat.luau` | Anti-Cheat HQ and Ban Court maps |
| `src/server/Maps/Hangouts.luau` | `src/server/Maps/Hangouts.luau` | Gamer Bedroom and Streamer House maps |
| `src/server/Maps/Studio.luau` | `src/server/Maps/Studio.luau` | Dev Studio and Classic Place maps |

`GunSpecsExtra` and `ConfigExtra` are folders with an `init.luau`. Rojo turns
each one into a single ModuleScript with its other files as children.

## 2. Add the hooks

**`src/shared/Config.luau`**: just above the last line (`return Config`):

```lua
-- Extra guns, bots and maps (src/shared/ConfigExtra)
require(script.Parent.ConfigExtra).apply(Config)
```

**`src/shared/GunModels.luau`**: just above the last line (`return GunModels`):

```lua
-- New guns and new looks for these ones (src/shared/GunSpecsExtra)
require(script.Parent.GunSpecsExtra).install(GunModels, SPECS, ROLES)
```

This adds the new part lists and part roles. It also swaps in a `makeParts`
that understands wedges, rounded parts and each gun's own Factory colors.
Everything else in GunModels stays the same. A gun in `Guns/` with the same
id as one of the game's guns replaces only that gun's look; its stats stay
in `Config.luau`. To keep an old look, delete that gun's file from `Guns/`.

**`src/server/Bots.luau`**: three small additions.

1. Under `local Hacks = require(script.Parent.Hacks)`:

   ```lua
   local BotOutfits = require(script.Parent.BotOutfits)
   ```

2. Right after the `LINES` table:

   ```lua
   -- Trash talk for the extra bosses (src/server/BotOutfits)
   for name, lines in BotOutfits.BossLines do
   	LINES.Boss[name] = lines
   end
   ```

3. In `dressUp`, right after the `if not head or not torso then return end` check:

   ```lua
   if BotOutfits.dress(rig, typeName, gear) then
   	return
   end
   ```

**`src/server/Map.luau`**: add the four new map modules to the list of
layout modules (keep any others already in it, like `"Extra"` or `"Island"`):

```lua
for _, moduleName in { "Classic", "Outdoor", "Indoor", "Esports", "AntiCheat", "Hangouts", "Studio" } do
```

**`src/server/Main.server.luau`**: right after `Map.build()`:

```lua
require(script.Parent.LobbyNpcs).start()
```

## 3. Check it

- Rebuild with `rojo build -o EarnEsp.rbxlx`. Before building, check that no
  `.luau` file starts with a BOM, as usual.
- In Studio, use DevTools to give yourself Credits
  (`game.ServerStorage.DevTools:Invoke("credits", 300000)`). Then open the cheat
  menu's Guns tab and buy each new gun. Each one should show up in first
  person, in third person and in the Skin Spin preview.
- Play the ranks. The new bots appear in the extra waves listed in
  `ConfigExtra/BotTypes.luau` (`ArenaWaves`). Each new boss's trash talk shows
  in chat bubbles.
- The new maps join the random map pool. To force one while testing, set a
  rank's `Maps` in `Config.Arenas` to `{ "EsportsArena" }` (or `LanCafe`,
  `AntiCheatHQ`, `BanCourt`).

## 4. Gunplay and movement feel

Do this after steps 1 to 3 work. It changes how shooting and moving feel:

- **Shooting:** recoil, aiming down sights (right click), reload/bolt/pump animations,
  gun sounds per class, and sharper tracers and impacts.
- **Moving:** a slide (C or Left Ctrl), landing dips, the lobby camera glide, and lobby
  lighting.

Copy these into the game's `src/`, keeping the paths:

| From this repo | What it is |
|---|---|
| `src/client/GunFeel.luau` | Recoil, aiming down sights, scope zoom, shot/reload sound timing, hit feedback |
| `src/client/GunProfiles.luau` | All the gun feel numbers, per class and per gun (tweak here) |
| `src/client/ViewmodelFeel.luau` | First-person poses: aiming, kick, equip, reload/bolt/pump, flash |
| `src/client/GunSounds.luau` | Layered gun sounds, with slots for Creator Store ids |
| `src/shared/GunEffects.luau` | Tracers, impacts per material, bullet holes, shells, explosions |
| `src/client/MoveFeel.luau` | Slide, momentum, camera bob and lean, landings, footsteps |
| `src/client/LobbyCam.luau` | The lobby camera glide and the round drop-in |
| `src/client/AtmosphereFeel.luau` | Lobby zones, per-map light extras, the lobby/round dip |
| `src/client/CameraFx.luau` | Replaces the game's CameraFx if it has one (same functions, plus extras) |

Then add the hooks:

- [docs/hooks/GUNPLAY.md](docs/hooks/GUNPLAY.md): `Gun.luau`, `Viewmodel.luau` and `Effects.luau`
- [docs/hooks/FEEL.md](docs/hooks/FEEL.md): `Main.client.luau`, `Movement.luau` and `Atmosphere.luau`

Every hooked line has a `feel:` comment, so `grep -rn "feel:" src` lists them all.
`docs/hooks/patches/` has the same changes as diffs against the older files they were
written on. Newer files have moved some lines, so add each hook by hand where the diff
doesn't apply. Then in Studio:

- Set **Lighting > Technology** to **Future**.
- Shoot every gun, aim with right click, reload, and slide while shooting.
- Check every hack still works.

## Notes

- `ConfigExtra.apply` skips any gun id, bot type, theme or map id that Config
  already has. So it's safe to move entries into `Config.luau` later and delete
  them from `ConfigExtra`.
- New guns slot into `Config.Weapons` by price, so the Guns tab stays in cost
  order.
- With the Factory skin (the default), each gun shows its own colors from the
  pictures, like the green Plasma Rifle or the tan Marksman Rifle. Every other
  skin recolors the gun's main body and glow, the same as before.
- The new guns have 45 to 95 parts each, up from about 15. That's still light
  for Roblox, but keep it in mind if bots ever carry a lot of them.
- New bots use only the abilities `Bots.luau` already has (Jams, Disarm, Lag,
  TeleportEvery, Spin, Hammer, Summons, Decoy), so no new bot code is needed.
- To give a new bot one of the new guns, set its `Gun` in
  `ConfigExtra/BotTypes.luau` once the guns are installed.
