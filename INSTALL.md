# Adding these models to Earn ESP

Everything in `src/` uses the same layout as the game's Rojo project
(`EarnEsp/src`), so installing is: copy the files, then add a few hook lines to
five game files. Nothing in the game is replaced or reordered.

## 1. Copy the files

Copy this repo's `src/` folders into the game's `src/`, keeping the paths:

| From this repo | To the game | What it is |
|---|---|---|
| `src/shared/GunSpecsExtra/` (folder) | `src/shared/GunSpecsExtra/` | Part lists for the 10 new guns, plus 3 extra part roles |
| `src/shared/ConfigExtra/` (folder) | `src/shared/ConfigExtra/` | Gun stats, bot types and waves, map lighting themes and map pool ids |
| `src/server/BotOutfits.luau` | `src/server/BotOutfits.luau` | Outfits for the new bots, bosses and lobby NPCs, plus boss trash talk |
| `src/server/LobbyNpcs.luau` | `src/server/LobbyNpcs.luau` | Friendly lobby characters (Skin Spin vendor and others) |
| `src/server/Maps/Props.luau` | `src/server/Maps/Props.luau` | New map props, written like `Kit.luau` |
| `src/server/Maps/Esports.luau` | `src/server/Maps/Esports.luau` | Esports Arena and LAN Cafe maps |
| `src/server/Maps/AntiCheat.luau` | `src/server/Maps/AntiCheat.luau` | Anti-Cheat HQ and Ban Court maps |

`GunSpecsExtra` and `ConfigExtra` are folders with an `init.luau`. Rojo turns
each one into a single ModuleScript with its other files as children.

## 2. Add the hooks

**`src/shared/Config.luau`**: just above the last line (`return Config`):

```lua
-- Extra guns, bots and maps (src/shared/ConfigExtra)
require(script.Parent.ConfigExtra).apply(Config)
```

**`src/shared/GunModels.luau`**: right after the loop that fills
`SPECS.Minigun.Spinning`:

```lua
-- Extra guns (src/shared/GunSpecsExtra)
local Extra = require(script.Parent.GunSpecsExtra)
for name, role in Extra.Roles do
	ROLES[name] = role
end
for id, spec in Extra.Specs do
	SPECS[id] = spec
end
```

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

**`src/server/Map.luau`**: add the two new map modules to the list of
layout modules (keep any others already in it, like `"Extra"` or `"Island"`):

```lua
for _, moduleName in { "Classic", "Outdoor", "Indoor", "Esports", "AntiCheat" } do
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

## Notes

- `ConfigExtra.apply` skips any gun id, bot type, theme or map id that Config
  already has. So it's safe to move entries into `Config.luau` later and delete
  them from `ConfigExtra`.
- New guns slot into `Config.Weapons` by price, so the Guns tab stays in cost
  order.
- New bots use only the abilities `Bots.luau` already has (Jams, Disarm, Lag,
  TeleportEvery, Spin, Hammer, Summons, Decoy), so no new bot code is needed.
- To give a new bot one of the new guns, set its `Gun` in
  `ConfigExtra/BotTypes.luau` once the guns are installed.
