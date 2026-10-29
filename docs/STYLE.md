# EARN ESP: LEAGUE HQ STYLE BIBLE

This is the single source of truth for every builder agent. If something is not written here, copy the closest thing that is, and never invent a new color, font, radius or metaphor.

Final mockups at 1280x720 (match them):
- `direction/final/1_lobby_plan.png`: lobby top-down, zones A/B/C
- `direction/final/2_play_menu.png`: Play menu
- `direction/final/3_cheat_menu_visual.png`: cheat menu, Visual tab, in a round
- `direction/final/4_cheat_menu_banwave.png`: cheat menu, Ban Wave tab, in the lobby
- `direction/final/5_skin_spin.png`: Skin Spin
- `direction/final/6_hud_round.png`: match HUD

The HTML sources are in `direction/final/src/` (`ui.css` is the kit, written so every rule maps to Frames).

Approved pitch mockups for screens that have no final mockup. Use their layout with the tokens below:
- `direction/pitch_ranked/9_store.png`
- `direction/pitch_ranked/8_round_intro.png`
- `direction/pitch_ranked/7_tunnel_queue.png`
- `direction/pitch_ranked/6_lobby_hub.png`

Non-negotiables:
1. The game name is **EARN ESP**. Mode names stay **Practice, Bronze, Silver, Gold, Diamond, Champion, Duel 1v1, Survival, Cheater Island**.
2. One kit: every screen is built from the components in section 3, through `Ui.luau`. No screen styles itself.
3. One color code that never changes meaning (section 2.1). Hot pink `#FF2E63` is retired. Champion pink `#FF3D7F` appears only on Champion things.
4. No image assets for UI. Everything is Frames, TextLabels, UICorner, UIStroke and UIGradient. Icons are built from Frames.
5. Cheats are obviously in-game powers. Never use the words exploit, executor, inject, script hub, or "hack the game" in player-facing text. Player-facing text says **cheats**; code ids keep `Hack_`.
6. The old lobby must be removed completely: the floating plaza, rock island, portal row, gantry and the gantry billboard. Do not keep it next to the new HQ. The old tagline returns only as the atrium back-wall sign (5.4).
7. Keep every existing feature (the checklist is in section 8).

---

## 1. Identity

### 1.1 The fiction (one paragraph)
Earn ESP is a pro league where cheating is the sport, and **League HQ** is its headquarters. You spawn in the bright, skylit Concourse at the end of a painted lane, with a violet line on the left, a yellow line on the right and white chevrons. The lane runs straight through the RANKED gate into **The Tunnel**, a dark ranked corridor with one glowing pad per rank, and the pink FINAL BOSS: ADMIN gate at the far end is visible from your very first step. Credits are your winnings and cheats are your loadout. Every arena is a server in the league's rotation ("Now joining: Shipping Yard, Server 07 of 23"). The anti-cheat is the league's referee crew: Moderators wear referee blue, and the Admin is the final boss. A Ban Wave means turning yourself in at the integrity desk for a permanent bonus, and your ban plays on the jumbotron for everyone in HQ. Off the Concourse is the **Trophy Hall**, the one warm room in HQ, with walnut walls, a carpet runner, brass chandeliers, and glass cases holding the trophy of every cheater boss you have banned. Behind it is the **Fan Market**, with the Skin Spin booth and the Pro Shop, and then **The Campsite**, a sunny blocky corner where you hang out by the fire while Auto Farm runs.

### 1.2 The color code (meaning is fixed)
| Color | Means | Never use it for |
|---|---|---|
| ESP Violet | cheats, ESP, "yours", owned cheat, switch ON | buttons that start things |
| Go Yellow | go / start / objective / picked / active dock tile. **Exactly one yellow GO button per screen** | decoration |
| Credit Mint | Credits, prices in CR, owned, gains, HP bar | warnings |
| Ban Red | ban, locked, danger, enemy boss HP, losses, damage taken | anything positive |
| Ref Blue | anti-cheat: Moderators, jams, UNDETECTED, patched | player stuff |
| Rank colors | ranks only (Bronze..Champion) | anything else |
| Rarity colors | skins only | anything else |
| Mode colors | the four non-ranked modes only | anything else |

### 1.3 Voice
Write like a sports broadcast caption mixed with a cheat menu's dry deadpan. The rules:
- Short and plain. Numbers come first, and every word earns its place.
- Gamer words are fine: noob, sweat, tryhard, HS, FFA, W. Movie-hacker words are not: no "mainframe breached", no green code, no "access granted".
- Titles, labels, buttons, tags and chips are written in ALL CAPS in the string itself, because Roblox has no text-transform. Body lines use sentence case and end with a period. Labels have no period.
- No exclamation marks, except in the tag `NEW!`. The countdown ends on `GO`, with no mark.
- Bots are **deleted**, bosses are **banned**, and the player gets **banned** by a Ban Wave. Use "eliminate" only in quest text. No gore words.
- Money is always `1,250 CR` (number, space, CR) up to 9,999 and `12.4K CR` / `1.2M CR` above that (`Ui.formatNumber` / `Ui.shortNumber`). Multipliers are `×1.5` (U+00D7). Counts are `0/1` with the `/1` in Fog.
- Glyphs: use only Latin-1 plus `×` and `·`. Arrows, infinity, check marks and padlocks are built from Frames, never typed.

### 1.4 Sample strings (copy these, and write new ones in the same voice)
**Pad screens and signs (in world)**
1. `BRONZE` / `0/1` / `NOOB BOTS · +10 CR CLEAR`
2. `SILVER` / `1/1` / `STARTING IN 3`
3. `GOLD` / `0/1` / `UNLOCK: TRIGGERBOT`
4. `CHAMPION` / `FINAL BOSS · ADMIN` / `NEEDS AIMBOT`
5. `PRACTICE` / `0/1` / `MOVING DUMMIES · FREE`
6. `DUEL 1V1` / `PLAYER 1 · VS · PLAYER 2` / `0/2` / `FIRST TO 5 · +150 CR WIN`
7. `SURVIVAL` / `0/4` / `ENDLESS WAVES · SQUAD OF 4`
8. `CHEATER ISLAND` / `0/12` / `EVERYONE HAS EVERYTHING` / `NEEDS 40 CHEATS`
9. Gate headers: `RANKED` · `DUEL` · `SURVIVAL` · `PRACTICE` · `QUARANTINE · 40 CHEATS`
10. `TROPHY HALL` / `CHAMPIONS LOUNGE` · `THE CAMPSITE` / `Auto Farm runs while you chill.` · `SKIN SPIN` · `PRO SHOP` / `PASSES · CREDITS · CODES` · `THE STANDS`
11. Jumbotron: `EARN ESP` / `LEAGUE HQ · SEASON 1`. Atrium back wall: `EARN ESP` / `CHEAT YOUR WAY TO THE TOP`

**Toasts (`Hud.notify`)**

12. `ESP HEALTH BAR UNLOCKED` (mint rail)
13. `Not enough Credits. You need 350 more.` (red rail)
14. `LEGIT PRESET ON · 6 CHEATS` (violet rail)
15. `QUEST DONE · FIRST BLOOD · +50 CR` (yellow rail)
16. `CODE REDEEMED · +500 CR` / `That code doesn't work.` / `You already used that code.`
17. `JOINED THE DUEL QUEUE · 1/2` / `LEFT THE QUEUE`
18. `Gold needs Triggerbot. Get it in Cheats [H].` (red rail)
19. `GOLD IS OPEN · GO GET AIMBOT_ANDY` (yellow rail)
20. `DAILY DROP · +100 CR · Come back tomorrow.` (mint rail)
21. `KEY TAKEN · F is already Fly.` (red rail)

**Buttons**

22. `QUEUE SILVER` · `START PRACTICE` · `FIND MATCH` · `CANCEL SEARCH` · `SPIN` · `×10` · `EQUIP` · `EQUIPPED` · `UPGRADE` · `MAX` · `REDEEM` · `HOLD TO GET BANNED` · `REMATCH` · `SET AS TITLE` · `BACK TO HQ` · `OPEN CHEATS`

**Empty states**

23. `No cheats match "flyy". Try ESP or Aim.`
24. `No runs yet. Be the first on the board.`
25. `Nobody's been banned yet. Could be you.`
26. `No skins yet. Spin to get your first.`
27. `Nobody in the queue. Step on to start one.`
28. `All quests done. New ones next update.`
29. `More passes soon.`

**Round intro**

30. `NOW JOINING` / `SHIPPING YARD` / `SERVER 07 OF 23`
31. Chips: `TWIST BIG HEADS` · `6 BOTS` · `BOSS NONE` · `+10 CR CLEAR`
32. `ANTI-CHEAT is asleep. Stay under 8 ON to keep it that way.`
33. `GET READY` / `Bots go live in 3`, then `GO`

**Kill feed**

34. `YOU · sweatlord_07 · HS · +12 CR`
35. `YOU · LagSwitch_420 · BOSS · +120 CR`
36. `ANTI-CHEAT is watching this server` (blue rail)
37. `MODERATOR joined the server` / `MODERATOR jammed your cheats` / `ADMIN_AntiCheat called 3 Moderators` (blue rail)

**HUD banners**

38. `BOT DELETED` + `×2` + `+6 CR`
39. `HEADSHOT` (under a damage number)
40. `BOSS BANNED` · `MOD DELETED`
41. `WAVE 1 CLEARED · +40 CR` / `WAVE 2 · BOSS INCOMING`
42. `SERVER CLEARED` / `BANNED FROM SERVER` (you died) / `Back to HQ in 3`
43. `JAMMED · cheats back in 3.2s` / `DISARMED · gun back in 1.4s` / `PATCHED · ESP Box is off for 10s`

**Ban Wave**

44. `Turn yourself in. Lose the cheats, keep the bonus forever.`
45. `Your ban plays on the jumbotron.`
46. Jumbotron: `BANNED` / `bacon_hair22 · BAN #2 · ×2.0 FOREVER`
47. `Finish your round first.` / `You need 12,400 more CR to get banned.`
48. `At ×2.0 you earn it all back fast. Most players are back in Silver in about 6 minutes.`

**Zone titles**

49. `LEAGUE HQ · ZONE B` / `THE TUNNEL` / `Ranked. One pad per rank. Unlock cheats to open the next.`
50. `LEAGUE HQ · ZONE C` / `TROPHY HALL` / `Every boss you ban ends up in here.`
51. `LEAGUE HQ · ZONE C` / `THE CAMPSITE` / `Sit by the fire. Auto Farm keeps going.`

**Tip pill**

52. `Walk onto a pad to queue` + `or` + `PLAY [P]` · `Press E to spin` · `Press E to shop` · `Step off to cancel`

---

## 2. Tokens (paste into `Ui.luau`)
Notation used in the rest of this file: `Color @0.4` means that color at BackgroundTransparency (or UIStroke / Text) Transparency 0.4. `(w, h, d)` is a Part Size in studs. `(x, y, z)` is a position in studs. UI boxes are `(x, y)` from the top-left in px at 1280x720. In layout descriptions, `…` means "right-aligned on the same row", and `●` / `›` stand for a Frame dot / chevron icon, never a typed glyph.


### 2.1 Palette
```lua
local rgb = Color3.fromRGB
Ui.C = {
	-- neutrals
	Ink      = rgb(11, 13, 18),    -- scrims, deepest backdrop, text shadow
	Graphite = rgb(17, 19, 24),    -- chips, keycaps, inputs, tracks, HUD backplates, sign panels
	Carbon   = rgb(32, 36, 44),    -- panel gradient top
	Carbon2  = rgb(23, 26, 32),    -- panel gradient bottom
	Slate    = rgb(39, 43, 53),    -- lane cards, rows, secondary buttons
	Slate2   = rgb(48, 53, 66),    -- hover + selected
	Steel    = rgb(58, 64, 80),    -- 1px strokes, dividers, switch off, not-owned rail
	Fog      = rgb(138, 147, 166), -- labels, secondary text, denominators
	Mist     = rgb(201, 206, 218), -- body text
	Chalk    = rgb(242, 244, 248), -- primary text, white icons
	-- meanings
	Violet     = rgb(139, 92, 255),  -- cheats / ESP / yours
	VioletDeep = rgb(106, 62, 224),  -- switch pressed, violet lip
	VioletText = rgb(185, 160, 255), -- violet words on dark
	Yellow     = rgb(255, 210, 63),  -- GO / objective / picked
	YellowLip  = rgb(201, 154, 0),
	YellowHover= rgb(255, 222, 110),
	Mint       = rgb(52, 227, 154),  -- Credits / owned / HP
	MintLip    = rgb(28, 158, 104),
	Red        = rgb(255, 59, 78),   -- ban / locked / danger
	RedLip     = rgb(168, 32, 45),
	RedText    = rgb(255, 120, 132),
	Blue       = rgb(61, 139, 255),  -- anti-cheat
	BlueText   = rgb(191, 214, 255),
}
Ui.RANK = {
	Bronze = rgb(224, 138, 74), Silver = rgb(195, 202, 214), Gold = rgb(255, 178, 26),
	Diamond = rgb(79, 209, 255), Champion = rgb(255, 61, 127),
}
Ui.MODE = {
	Practice = rgb(242, 244, 248), Duel = rgb(167, 123, 255), Survival = rgb(180, 240, 58), CheaterIsland = rgb(255, 59, 78),
}
-- Skins: read Config.Rarities[i].Color (Common 175,180,190 · Rare 60,140,255 · Epic 170,80,255 ·
-- Legendary 255,170,40 · Mythic 255,50,70 · Secret 240,240,250). Never hardcode new rarity colors.

-- Legacy names, so old code keeps working while it migrates
Ui.ACCENT, Ui.GREEN, Ui.RED, Ui.GOLD, Ui.CYAN = Ui.C.Violet, Ui.C.Mint, Ui.C.Red, Ui.C.Yellow, Ui.C.Blue
Ui.DARK, Ui.PANEL, Ui.PANEL_HOVER, Ui.TEXT, Ui.MUTED = Ui.C.Graphite, Ui.C.Slate, Ui.C.Slate2, Ui.C.Chalk, Ui.C.Fog
```
**Also change `Config.Arenas[i].Color`** to the `Ui.RANK` values (Bronze 224,138,74 · Silver 195,202,214 · Gold 255,178,26 · Diamond 79,209,255 · Champion 255,61,127), so pads, info bar, HUD and menus match.

RichText hex values (for `<font color>`):
- Mint `#34E39A`
- Fog `#8A93A6`
- Yellow `#FFD23F`
- RedText `#FF7884`
- VioletText `#B9A0FF`
- BlueText `#BFD6FF`
- Chalk `#F2F4F8`

**ESP and tracer color pickers** go in `Toggles.luau`. Their order is fixed, and the first entry is the default:
```lua
Toggles.ESP_COLORS = { rgb(139,92,255), rgb(52,227,154), rgb(255,210,63), rgb(255,59,78), rgb(79,209,255), rgb(242,244,248) }
-- 7th swatch "RAINBOW" only when RainbowChams is owned (UIGradient swatch, see 3.9)
Toggles.TRACER_COLORS = { rgb(255,236,190), rgb(139,92,255), rgb(52,227,154), rgb(255,210,63), rgb(255,59,78), rgb(79,209,255), rgb(242,244,248) }
```

**World palette** (in-world Parts):

| Name | RGB | Material | Use |
|---|---|---|---|
| Concourse Floor | 233,236,241 | SmoothPlastic | A floor |
| Grout | 214,219,227 | SmoothPlastic | 0.2-wide floor lines every 10 studs |
| HQ Wall | 242,244,248 | SmoothPlastic | Concourse-facing walls |
| Kick Band | 58,64,80 | SmoothPlastic | 0..1.2 base of Concourse walls |
| Truss | 58,64,80 | Metal | roof trusses, colonnade posts, mullions |
| Lane Floor | 21,23,29 | SmoothPlastic | the spine lane |
| Pad Top | 28,31,39 | SmoothPlastic | every pad, spawn pad |
| Sign Panel | 17,19,24 | SmoothPlastic | every screen and board |
| Tunnel Panel A / B | 43,47,56 / 53,58,69 | SmoothPlastic | Tunnel cladding, alternating 8-stud panels |
| Tunnel Rib | 74,81,96 | Metal | ribs every 8 studs |
| Tunnel Floor | 36,40,48 | SmoothPlastic | Tunnel |
| Duel Floor / Wall | 34,30,48 / 46,40,66 | SmoothPlastic | Duel Hall |
| Survival Floor / Wall | 88,92,100 / 70,74,82 | Concrete / CorrodedMetal | Survival Hall |
| Range Floor / Wall | 200,205,214 / 225,229,236 | SmoothPlastic | Practice Range |
| Quarantine Floor / Wall | 26,29,36 / 36,40,48 | SmoothPlastic | Quarantine |
| Hazard | 255,210,63 + 26,29,36 | SmoothPlastic | 2-stud alternating blocks |
| Walnut / Walnut Dark | 122,74,40 / 78,46,24 | WoodPlanks / Wood | Trophy Hall floor, lower walls, beams, case bases |
| Trophy Navy | 32,38,64 | SmoothPlastic | Trophy Hall upper walls |
| Carpet | 91,30,42 | Fabric | runner, sofas |
| Brass | 224,180,90 | Metal | trims, chandeliers, case tops |
| Case Glass | 207,232,255 | Glass, Transparency 0.6 | trophy cases, windows |
| Grass / Path / Bush | 125,190,90 / 167,169,174 / 94,170,70 | Grass / Slate / Grass | Campsite, planters |
| Tent / Stall Red / Log | 255,201,60 / 229,72,72 / 110,70,40 | Fabric / SmoothPlastic / Wood | Campsite |
| Lawn (exterior) | 111,174,78 | Grass | outside the plot |

Neon is used only for strips 0.4 studs or thinner, pad edges, ring icons, candle flames and the tent lights. A neon Part's color is always one of the meaning colors above.

### 2.2 Fonts
```lua
local GOTHAM = "rbxasset://fonts/families/GothamSSm.json"
Ui.F = {
	Hero    = Font.new(GOTHAM, Enum.FontWeight.Heavy,  Enum.FontStyle.Italic), -- map names, skin names
	Title   = Font.new(GOTHAM, Enum.FontWeight.Heavy,  Enum.FontStyle.Italic), -- panel titles
	Display = Font.new(GOTHAM, Enum.FontWeight.Heavy,  Enum.FontStyle.Italic), -- card names, tags, chips, tabs, buttons
	Num     = Font.new(GOTHAM, Enum.FontWeight.Heavy,  Enum.FontStyle.Italic), -- every number that matters
	Row     = Font.new(GOTHAM, Enum.FontWeight.Bold,   Enum.FontStyle.Normal), -- list row names, secondary buttons
	Label   = Font.new(GOTHAM, Enum.FontWeight.Bold,   Enum.FontStyle.Normal), -- section labels, units, keycaps
	Body    = Font.new(GOTHAM, Enum.FontWeight.Medium, Enum.FontStyle.Normal), -- sentences
}
Ui.FALLBACK = { -- Enum.Font for APIs or old code that need it (Kit.text signs, TextStroke labels)
	Hero = Enum.Font.GothamBlack, Title = Enum.Font.GothamBlack, Display = Enum.Font.GothamBlack, Num = Enum.Font.GothamBlack,
	Row = Enum.Font.GothamBold, Label = Enum.Font.GothamBold, Body = Enum.Font.GothamMedium,
}
function Ui.text(label, role) label.FontFace = Ui.F[role] end -- always set FontFace after Font
```
- Check italics in Studio on the first build. If GothamSSm Heavy Italic draws upright, set `Ui.ITALIC_FAMILY = "rbxasset://fonts/families/Montserrat.json"` and use it for Hero, Title, Display and Num only.
- Text is never outlined (`TextStrokeTransparency = 1`), except on world BillboardGui tags, which use a Graphite backplate instead.
- Roblox has no letter-spacing, so tracking is never faked with spaces.

### 2.3 Text sizes (px at 1280x720, before UIScale)
| Role | Font | Size | Color | Used for |
|---|---|---|---|---|
| Hero | Hero | 56–72 | Chalk | round intro map name (72), Skin Spin name (64), SERVER CLEARED (56) |
| Title | Title | 30 (Play 34) | Chalk | panel titles, always on the stripe |
| Display L | Display | 20–26 | Chalk | detail titles (24), rank names in Play (20), Ban Wave title (26) |
| Display M | Display | 15–18 | Chalk or meaning | card/tier names, boss name, quests card title |
| Display S | Display | 12–13 | Chalk/Fog | tabs (13), segmented control (12), status pill brand (13), dropdown value (12) |
| Row | Row | 14 caps | Chalk (owned) / Mist (not owned) | cheat/gun/quest row names |
| Body | Body | 13 | Mist | one-line descriptions in panels |
| Small | Body | 12 / 11 | Fog | row sub-lines (12), card lines (11) |
| Label | Label | 11 caps | Fog | section heads, units, chip units |
| Micro | Label | 9–10 caps | Fog | dock tile names, tiny hints, keycap legends |
| Num XL | Num | 52 | Chalk | HP, ammo |
| Num L | Num | 28 | Chalk | match timer, countdown ring (44) |
| Num M | Num | 14–18 | Chalk/Mint | chips, prices, stat values |
| Num S | Num | 10–12 | Chalk/Fog | kill feed CR, small chips, ESP distance |
| GO | Display | 24 (SPIN 28) | Graphite | yellow GO |
| Danger | Display | 20–22 | white | hold button |
| Button | Row | 13 caps | Chalk | secondary buttons |

### 2.4 Corner radii (`UICorner.CornerRadius`)
| Thing | Radius |
|---|---|
| Panel | `UDim.new(0, 10)` |
| Modal | `UDim.new(0, 12)` |
| Lane card / list row / group box / dropdown / input / swatch / secondary button / X button / toast / tooltip / HUD tile | `UDim.new(0, 6)` |
| GO / Danger / Dock tile / rank emblem tile | `UDim.new(0, 8)` |
| Tag / keycap / lock chip / hazard | `UDim.new(0, 4)` |
| Chips, pills, switches, price pills, badges, bars, radar | `UDim.new(0.5, 0)` |
| Rails (the 4px meaning bar) | `UDim.new(0.5, 0)` |

### 2.5 Strokes (`UIStroke`, ApplyStrokeMode Border, LineJoinMode Round)
| Thing | Thickness | Color | Transparency |
|---|---|---|---|
| Panel, chip, keycap, input, dropdown, group box, X button | 1 | Steel | 0.25 (panel) / 0 (others) |
| Selected lane card | 1.5 | its rail color | 0 |
| Price pill | 1 | Mint | 0.55 |
| Price pill, can't afford | 1 | Fog | 0.65 |
| Lock chip | 1 | Red | 0.55 |
| UNDETECTED chip | 1 | Blue | 0.4 |
| HUD cheat tile (on) | 1.5 | Violet | 0 |
| Search box focused | 1.5 | Violet | 0 |
| Keybind capturing | 1.5 | Violet (pulses 0↔0.6) | |

Dividers are 1px Frames in Steel at BackgroundTransparency 0.4. Do not use UIStroke for dividers.

### 2.6 Spacing scale
`2, 4, 6, 8, 10, 12, 16, 20, 24, 32`.
- Panel padding is 16 (cheat menu) or 20 (Play).
- Rows are 6 apart.
- Sections are 10–14 apart.
- Grid gutters are 10 (cards) and 20 (columns).
- Header heights are 64 (cheat menu) and 72 (Play).
- Footers are 50 (cheat menu) and 92 (Play).

| Row type | Height |
|---|---|
| Cheat row | 48 |
| Rank card | 64 |
| Quest row | 56 |
| Rarity card | 62 |
| Odds row | 38 |
| Ban Wave lose/keep row | 37 |
| Kill feed row | 30 |
| Toast | 40 |
| Tab | 38 |

### 2.7 Shadows and glows (Frames only)
- **Hard drop (panels, cards that float):**
  - A sibling Frame named `Shadow`, the same size and corner, Ink color, BackgroundTransparency 0.55.
  - Offset +6 Y for panels and +3 Y for secondary buttons, at ZIndex one below.
  - Put the panel and its shadow inside one holder (a `CanvasGroup` for menus so they can fade, a `Frame` for HUD) and tween the holder.
- **Lip (GO, Danger, buy-big):**
  - A Frame `Lip` in the lip color, the same size as the face, sitting 4px lower behind the face.
  - Pressed: the face moves down 3px (`Position + (0,3)`), so the lip shows only 1px.
- **Halo (used only on: the Skin Spin landed card, the round-intro PICKED row, and the Champion pad screen in world):**
  - Two Frames behind the target: +8px and +16px larger, corner +4/+8, in the meaning color, BackgroundTransparency 0.82 and 0.92.
  - They pulse 0.82↔0.9 at 1.2s Sine.
- **Light bar:**
  - A Frame 2–4px tall in a meaning color with `UIGradient.Transparency = NumberSequence.new({0,1},{0.5,0.2},{1,1})` (horizontal).
  - Used under the kill banner, on the Skin Spin screen edges for Legendary+, and for the Tunnel-style top edge on the jumbotron gui.
- **Vignette:** 4 edge Frames with a UIGradient Transparency ramp, as `Hud.vignette(color, transparency, thickness)` already does.
  - Black 0.6 / 140 always.
  - Red `Ui.C.Red` 0.25 / 200 when HP is low.
  - Blue `Ui.C.Blue` 0.55 / 160 when jammed or disarmed.
- **Text shadow (HUD numbers and banners only):** a duplicate TextLabel offset (2,2), Ink, TextTransparency 0.45, ZIndex below.
- **Neon edge in UI (in-world screens only):** a UIStroke of Thickness 3 in the meaning color at Transparency 0.5 on the screen's root Frame.
- Never use blur on UI elements. The world behind lobby menus gets `Lighting.BlurEffect` Size 12 while a menu is open, and none in rounds.

### 2.8 Motion
```lua
Ui.T = {
	Hover    = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- color/fill changes
	Press    = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- face down 3px / scale 0.96
	Open     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- panels: slide 12px from the dock side + GroupTransparency 1->0
	Close    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Snap     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- ESP bracket closes in from 12px further out
	Knob     = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- switch knob + track color
	Pop      = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- chip scale 1 -> 1.12, then back with the same info
	Punch    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- banners scale 1.15 -> 1
	Bar      = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- progress bars, rails steel->violet on buy
	ToastIn  = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- slide 16px down + fade in
	ToastOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
	Fade     = TweenInfo.new(0.40, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
	Hold     = TweenInfo.new(1.20, Enum.EasingStyle.Linear),                          -- danger hold-to-confirm
	Lighting = TweenInfo.new(1.20, Enum.EasingStyle.Sine),                            -- theme fades (already in Atmosphere)
}
```
Timings:
- List rows stagger in by 0.02s each, for the first 10 rows only.
- A toast holds 2.6s. A kill feed row lives 4s, then fades over 0.5s.
- The hitmarker fades over 0.3s.
- Damage numbers rise 28px over 0.6s and fade during the last 0.25s.
- The kill banner holds 1.4s. A zone title holds 2.5s. The round intro lasts 3s (`Config.RoundCountdown`).
- The countdown ring drains Linear.
- Skin Spin makes 22 bracket hops. The interval between hops eases from 0.05s to 0.32s (Quad In), for about 2.4s total.
- **No Elastic or Bounce easing anywhere. No idle wobble.** Only the ESP bracket, chips and banners move on their own.

### 2.9 Sound cues
Add these to `Config.Sounds`; they play through `Effects.sound(name)`. Every cue uses a built-in file plus a PlaybackSpeed, so it works today. Swap in Creator Store IDs later.
- Files marked `(v)` should be checked in Studio. If one is silent, use `rbxasset://sounds/volume_slider.ogg` at the same speed.

| Cue | When | Id | Volume | Speed |
|---|---|---|---|---|
| `UiHover` | hover any row/button | volume_slider.ogg | 0.12 | 2.2 |
| `UiSelect` (= old `Click`) | select a row, tab, swatch | volume_slider.ogg | 0.4 | 1.2 |
| `UiGo` | press a yellow GO | action_jump_land.mp3 | 0.6 | 0.8 |
| `UiDeny` | can't afford, locked, key taken | volume_slider.ogg | 0.5 | 0.55 |
| `ToggleOn` / `ToggleOff` | switch | volume_slider.ogg | 0.35 | 1.6 / 1.0 |
| `Purchase` (= old `Unlock`) | any buy succeeds | electronicpingshort.wav (v) | 0.5 | 1.0 |
| `PadJoin` | step on a pad (two-tone: play twice, 0.08s apart, speeds 1.0 then 1.33) | electronicpingshort.wav (v) | 0.5 | 1.0/1.33 |
| `PadLeave` | step off | electronicpingshort.wav (v) | 0.4 | 0.8 |
| `ChipJoin` | a count chip goes up | volume_slider.ogg | 0.3 | 1.8 |
| `Countdown` | each second of the ring | volume_slider.ogg | 0.5 | 1.4 |
| `RoundStart` | GO | action_jump_land.mp3 | 0.8 | 0.6 |
| `Hit` / `Headshot` / `Kill` | existing / headshot ding / existing | volume_slider.ogg | 0.6 / 0.7 / 1 | 1.6 / 2.4 / 0.8 |
| `BossSpawn` | boss appears | impact_explosion_03.mp3 | 0.7 | 0.5 |
| `Whistle` | Moderator spawns or jams | electronicpingshort.wav (v) | 0.6 | 2.2 |
| `Jam` | you get jammed | volume_slider.ogg | 0.6 | 0.4 |
| `BanGavel` (= old `Hammer`) | Ban Wave confirm, boss banned stamp | impact_explosion_03.mp3 | 1 | 0.7 |
| `SpinTick` | each Skin Spin hop | volume_slider.ogg | 0.25 | 2.0 |
| `SpinReveal` | land (Speed: Common 1.0, Rare 1.1, Epic 1.2, Legendary 1.3, Mythic 1.45, Secret 1.6) | electronicpingshort.wav (v) | 0.7 | by rarity |
| `ZoneEnter` | zone title shows | volume_slider.ogg | 0.2 | 0.9 |
| `Toast` | toast appears | volume_slider.ogg | 0.2 | 1.4 |
| `QuestDone` | quest completes | electronicpingshort.wav (v) | 0.6 | 1.2 |

---

## 3. Components (built once in `Ui.luau`, used everywhere)
Every component is a function on `Ui` that returns its root plus the parts that change. All sizes are design px at 1280x720. The **suggested API** is listed so that agents call the same thing.

### 3.1 Panel: `Ui.panel(parent, size, position, anchor) -> holder, body`
- `holder` is a CanvasGroup (menus) or a transparent Frame (HUD) containing `Shadow` and `Body`.
- `Body`:
  - Frame with BackgroundColor3 white plus a `UIGradient` (Rotation 90, `ColorSequence.new(Ui.C.Carbon, Ui.C.Carbon2)`), so the fill comes out as exactly those colors.
  - UICorner 10, UIStroke 1 Steel @0.25, ClipsDescendants true.
  - Menus over the lobby use BackgroundTransparency 0.02.
- `Shadow`: Ink @0.55, offset +6 Y.
- Open: holder starts 12px toward the dock (x−12) with GroupTransparency 1, then tweens with `Ui.T.Open`. Close: the reverse, with `Ui.T.Close`.
- Every open menu also adds the cursor-unlock `TextButton { Modal = true, Size = 1x1, BackgroundTransparency = 1 }`, which the old code already does.

### 3.2 Header with the stripe: `Ui.header(body, {title, subtitle, icon, height = 64}) -> header`
- Height 64 (72 for Play), with a bottom divider (1px Steel @0.4).
- Left side:
  - Optional 20px icon at 1.3 scale, in its meaning color.
  - TITLE: Title 30 Chalk, at x 50 with an icon or x 18 without.
  - **The stripe** sits 6px under the title baseline: two Frames 3px tall with corner pill, **Violet 38px wide, a 4px gap, then Yellow 18px wide**, left-aligned to the title. On Ban Wave the stripe is **Red 38 + Yellow 18**.
  - An optional keycap hint (3.19) sits to the right of the title, top-aligned.
  - Subtitle: Body 13 Fog, 12px right of the title block, one line.
- Right side, right-aligned with 10px gaps: chips (CR chip `lg` with a Mint stroke, count chips), status chip, then the X button.
- The X button is 36x36 Slate with a 1px Steel stroke and corner 6. The cross is two Frames 14x2.5 Chalk rotated ±45. Hover turns it Slate2, and pressing moves it +1px.

### 3.3 Tab rail (vertical): `Ui.tabRail(parent, tabs) -> rail, setActive(name), setBadge(name, text, color)`
- Width 188, padding 12/10, with a right divider. Tabs are 38 tall with a 3px gap and corner 6.
- Each tab, left to right:
  - A 4px rail Frame at x 5, inset 10 from top and bottom. It is transparent when idle, and the tab's meaning color when active.
  - 20px icon, then a 9px gap.
  - Name in Display 13 caps.
  - Right side: the count `4/13` in Label 10 Fog, then a ghost keycap (3.19, size sm) with the number key 1–5.
- Default tab colors: Visual..Misc use Violet. Guns uses Chalk. Quests uses Yellow and shows a yellow count badge. Ban Wave text is RedText with a Red rail. Store text is Mint with a Mint rail.
- States:
  - Idle: no fill, Fog text.
  - Hover: Slate fill, Chalk text.
  - Active: Slate2 fill, Chalk text, rail visible.
  - Disabled: Fog @0.5 and no hover.
  - Badge: 3.15 badge, right-aligned in place of the count. `JAM`/`PATCHED` are blue badges.
- After Misc comes a 1px divider with 6px margins, then Guns, Quests, Ban Wave, Store. A bottom-anchored info card (3.7 lane card on Graphite) is optional.
- Horizontal sub-tabs (Store): Slate pills 32 tall with Display 12 text. The active pill is Slate2 with a 3px bottom bar in its meaning color (Mint in Store).

### 3.4 List row = lane card: `Ui.lane(parent, {name, sub, rail, right, height = 48}) -> row`
- The universal card. A Frame in Slate with corner 6, padding 20 left and 14 right.
- **Rail:** a Frame 4px wide at x 7, inset 10px top and bottom, corner pill. **Its color is the row's meaning**:
  - Violet = owned cheat
  - Steel = not owned
  - Rank color = rank
  - Mint = gain or owned item
  - Red = loss
  - Blue = anti-cheat
  - Yellow = active quest or objective
- Text: name in Row 14 caps (Chalk if owned, Mist if not), sub-line in Small 12 Fog, one line with TextTruncate AtEnd.
- Right slot: switch / price pill / buy pill / lock chip / count chip / tag / keycap, with 8px gaps.
- States:
  - Hover: Slate2 (`Ui.T.Hover`) and the `UiHover` cue.
  - Selected: Slate2, a 1.5px UIStroke in the rail color, and **white ESP brackets** (3.20) snapping in.
  - Locked: the whole row at 62% opacity (GroupTransparency 0.38 if it is a CanvasGroup, otherwise TextTransparency 0.3 plus dimmed children), with a lock chip on the right.
  - Disabled: Fog text.
  - Pressed: Slate2 and the `UiSelect` cue.
- Section sub-headers inside lists (from the script hub reference):
  - An 18px row: Micro label in a meaning color (`YOURS` in VioletText, `BUY` in Mint, `DONE` in Fog), then a 1px Steel line filling the rest.

### 3.5 Switch: `Ui.switch(parent, on, onChanged) -> switch, set(on, jammed)`
- Track: 40x22 pill. Knob: 16x16 pill at x 3 when off, x 21 when on (`Ui.T.Knob`).
- Off: Steel track, Fog knob.
- On: Violet track, white knob.
- Jammed (on but not working): Blue track, white knob.
- Disabled: Steel @0.5.
- Hover: the track lightens 8% (Steel→Slate2, Violet→VioletText @0.2).
- Pressed: the knob widens to 20px for 0.06s.
- Plays `ToggleOn`/`ToggleOff`. The whole row is clickable, not only the switch.

### 3.6 Slider: `Ui.slider(parent, {label, min, max, step, value, unit, onChanged}) -> slider`
- Header row: Label 11 caps on the left; value on the right in Num 13 plus a unit in Label 10 Fog (`300 STUDS`, `90°`, `75%`).
- Track: 6px tall, Graphite with a 1px Steel stroke, pill, full width, 10px below the header.
- Fill: Violet, pill.
- Knob: 16x16 white pill centered on the value, with a drop Frame (Ink @0.55, +2px Y).
- Hover: the knob grows to 18.
- Drag: `InputBegan` on the track or knob, follow `InputChanged` until `InputEnded`, snapping to `step`. The value label updates live, and `onChanged` fires on release.
- Disabled: the fill turns Steel and the knob turns Fog.

### 3.7 Dropdown: `Ui.dropdown(parent, {label, options, value, onPick}) -> field`
- Closed:
  - Field 30 tall, Graphite, 1px Steel stroke, corner 6.
  - Value in Display 12 caps Chalk at x 10.
  - Chevron at right 11: two Frames 7x2 Fog rotated ±45, pointing down.
- Open:
  - A list Frame directly under the field (ZIndex +5): Graphite, 1px Steel stroke, a 4px Ink drop, padding 4.
  - Options are 26 tall, Display 12, Mist.
  - The selected option has Slate2 fill, a 3px Violet left bar and Chalk text. Hover is Slate.
  - The chevron flips to point up.
- Clicking outside or pressing Esc closes it.
- Used for: Chams Style, Target Priority, Menu Theme.

### 3.8 Segmented control: `Ui.segmented(parent, options, value, colors, onPick)`
- Track: Graphite, 1px Steel stroke, corner 6, padding 3, height 32 (28 when small).
- Options: Display 12 caps, Fog, 11px side padding.
- Active option: Slate2 fill, Chalk text, a 2px bottom bar in its meaning color.
- Presets: `LEGIT` Mint · `CUSTOM` Yellow · `RAGE` Red · `OFF` Steel. Aimbot Hitbox: Violet.

### 3.9 Color swatch row: `Ui.swatches(parent, colors, selected, onPick, {rainbow = owned})`
- Swatches are 26x26 with corner 6 and a 1px Ink @0.75 inner stroke. 6px gaps.
- Selected: small white ESP brackets (8px Ls, 2px thick, 5px outside).
- The rainbow swatch:
  - A white Frame with a UIGradient through Red→Yellow→Mint→Cyan→Violet→Red, rotating 360° every 4s while visible.
  - Locked: an Ink @0.45 overlay and a 2-Frame padlock (body 8x7 white with corner 1.5, shackle 5x6 with a 2px white border).
- Header row: Label `ESP COLOR` on the left, the chosen color's name on the right in Micro in that color.

### 3.10 Buttons
**GO (primary, yellow; exactly one per screen):** `Ui.goButton(parent, {text, size = (W, 56), keycap, count}) -> button`
- Holder (W, 60) containing:
  - `Lip`: YellowLip, at y 4.
  - `Face`: Yellow, corner 8. Text in Display 24 caps Graphite, centered.
  - Chevrons right of the text: three ">" built from two 4px bars each (12x12 box rotated 45°), at Transparency 0.65/0.35/0, 2px overlap.
  - Optional keycap hint inside the face at right 12 (`ENTER`, `SPACE`): Graphite @0.82 fill, 1px Graphite @0.65 stroke, text color 90,70,0.
  - Optional count chip (3.13) hanging off the top-right corner at (−10, −13).
- States:
  - Hover: face YellowHover, chevrons slide 4px right (`Ui.T.Hover`).
  - Pressed: face y+3 (`Ui.T.Press`) and the `UiGo` cue.
  - Disabled: face Slate, Fog text, lip hidden, chevrons hidden. The text explains why (`LOCKED`).
  - Busy: the text becomes three Num dots cycling every 0.3s.

**Secondary:** `Ui.button(parent, {text, size = (W, 36)})`
- Slate face, 1px Steel stroke, corner 6, drop Ink @0.55 at +3.
- Text in Row 13 caps Chalk.
- Hover Slate2. Pressed: y+2, drop at +1. Disabled: Fog text, no drop.
- Used for: EQUIP, ×10, SKIN SPIN, SET AS TITLE, CANCEL, RESET.

**Danger, hold to confirm:** `Ui.holdButton(parent, {text, size = (W, 56), seconds = 1.2, onConfirm})`
- Red face with a RedLip lip and corner 8. Display 22 caps white, with a hammer icon on the left. A Micro `1.2S` sits bottom-right at 80% opacity.
- `Fill`: a white Frame @0.82 inside the face, anchored left, Size X 0→1 over `Ui.T.Hold` while held.
- Releasing early tweens the fill back to 0 over 0.2s and plays `UiDeny`.
- Complete: a white flash (fill @0.4 for 0.1s), the `BanGavel` cue, then `onConfirm`.
- Disabled: Slate face, RedText label (`FINISH YOUR ROUND FIRST`, `NEED 12,400 MORE CR`).

**Buy (Credits):** `Ui.buyPill(parent, cost, onBuy)`, which is a price pill (3.11) that is also a button.
- Hover: fill Mint @0.86 and the stroke at 0.2.
- Pressed: y+1.
- Busy: `···`.
- Can't afford: Fog text and Fog stroke @0.65. Clicking anyway plays `UiDeny`, a 4px ×2 shake (0.2s) and a red toast saying how much more is needed.
- Success: `Purchase`, the rail tweens Steel→Violet (`Ui.T.Bar`), the switch appears ON, and a mint toast.

**Buy (Robux, Store):**
- Small: a price pill with a Steel stroke, Chalk text and the glyph `utf8.char(0xE002)` before the number.
- Featured card: a full-width GO-style yellow button (the one yellow on the Store tab).

### 3.11 Price pill: `Ui.price(parent, amount, {currency = "CR", affordable = true})`
- Graphite pill, height 28 (22 small), 12px padding. Text in Num 14 Mint plus `CR` in Label 10 at 85% opacity.
- 1px Mint @0.55 stroke. When you can't afford it: Fog text and Fog @0.65 stroke.

### 3.12 Rank chip and rank emblem
- Rank chip: a Tag (3.14) filled with the rank color and Graphite text (`SILVER`), 20–24 tall.
  - Locked rank: a ghost tag in the rank color at 0.6.
- Rank emblem tile (Play menu, Next Rank card):
  - 44x44, corner 8, rank color fill, with a 4px inner bottom Frame of Ink @0.75 as the lip.
  - Roman numeral I–V in Display 18 Graphite.
  - Locked: the tile is desaturated, which in practice means the color is lerped 70% toward Steel.

### 3.13 Count chip: `Ui.chip(parent, {value, of, unit, size = "md"})`
- Graphite pill with a 1px Steel stroke. Heights: 20 (sm), 26 (md), 34 (lg).
- Contents: Num value in Chalk, then `/N` in Fog, then an optional unit in Label 10 Fog (`OWNED`, `CHEATS`, `LEFT`, `WAVE`).
- Pops (`Ui.T.Pop` up and back) with the `ChipJoin` cue when the value rises.
- Variants:
  - A colored stroke for meaning: Mint for the CR chip, Red for BANS, Blue for UNDETECTED.
  - A 6px dot before the value (red `LEFT`, violet `ON`).

### 3.14 Tag and badge: `Ui.tag(parent, text, color, {ghost, size})`, `Ui.badge(parent, text, color)`
- Tag: 20 tall (sm 16), corner 4, Display 11 caps (sm 9), 7px padding.
  - Solid tags have a color fill and Graphite text. Text is white on Violet, Red and Blue fills.
  - Ghost tags are transparent with a 1px stroke and the text in the same color.
- The tag vocabulary:

| Tag | Color |
|---|---|
| `NEW!` | Yellow |
| `ON` | Violet, white text |
| `OWNED` | Mint |
| `EQUIPPED` / `PICKED` | Yellow |
| `CLEARED ×14` | Mint |
| `BOSS` | Red, white text |
| `MOD` | Blue, white text |
| `HS` | Yellow |
| `MAX` | Chalk |
| `BEST SELLER` | Yellow |
| `+20%` | Mint |
| rarity tags | rarity color; Mythic/Epic/Rare use white text |
| twist ghost tag | Yellow |
| `LAYER 2` | ghost, VioletText |

- Badge (notifications): an 18px pill with Num 10 text and 5px padding.
  - Red with white text: unseen counts on the dock.
  - Yellow with Graphite text: claimable quests.
  - Blue with white text: `JAM`, `PATCHED`.
  - It hangs off a corner at (−6, −6).

### 3.15 Lock chip: `Ui.lock(parent, text)`
- Height 24 (sm 20), corner 4.
- Fill Red at BackgroundTransparency 0.88, 1px Red @0.55 stroke, text in Label 11 caps RedText.
- A 2-Frame padlock at the left, 9px in. The body is 10x7 RedText with corner 1.5; the shackle is a 6x7 Frame with a 2px RedText UIStroke, sitting above the body (it is clipped at the bottom by being placed behind the body).
- Text: `NEEDS TRIGGERBOT`, `NEEDS 40 CHEATS`, `AFTER 5 BAN WAVES`.

### 3.16 Rarity card: `Ui.rarityCard(parent, {rarity, title, sub, owned, of, selected})`
- A lane card 62 tall on Slate @0.06 transparency, with the rail in the rarity color.
- Art tile: 42x42, corner 6.
  - UIGradient at 135°, from the rarity color to `rarity:Lerp(Graphite, 0.65)`.
  - A clipped stripe texture: 6 Frames 3px wide, white @0.9, rotated 45°.
  - A blocky gun silhouette made of 2 Ink @0.45 Frames.
  - A 4px accent bar in the skin's `Accent` color along the bottom.
- Name in Display 16 in the rarity color, sub-line in Small 11, count chip sm (`1/2`).
- Selected (spin landing): Slate2 fill, a 1.5px stroke in the rarity color, white brackets, and a halo (2.7) in the rarity color for 1.2s.
- Store and featured variants use the same art tile, scaled to 120x72.

### 3.17 Toast: `Ui.toast(text, railColor)`, called through `Hud.notify(text, color)`
- Graphite @0.08, 40 tall, corner 6, 1px Steel stroke, Ink drop +4. Padding 20 left, 14 right.
- 4px rail (color = meaning). Text in Row 13; a second fact may follow in Num 13 Mint (`+500 CR`).
- Top-center at y 150. Up to 3 stack downward with 6px gaps; the newest goes on top.
- `ToastIn`, holds 2.6s, `ToastOut`. Plays the `Toast` cue.
- `Hud.notify(text, color)` maps old colors: GREEN→Mint, RED→Red, ACCENT→Violet, GOLD→Yellow, CYAN→Blue. The text keeps its case; only titles are upper-cased.

### 3.18 Tooltip: `Ui.tooltip(target, text)`
- Appears after 0.35s of hover, 12px right and 12px below the cursor, clamped to the screen.
- Graphite, 1px Steel stroke, corner 6, Ink drop +3. Padding 8/10, max width 220.
- Body 12 Mist; an optional first line in Label 11 Chalk. No arrow.
- Used for: locked rows (what unlocks them and the price), stat bars, SUS meter, dock tiles, multipliers.

### 3.19 Keycap hint: `Ui.keycap(parent, key, {size = "md", ghost})`
- Height 22 (sm 18). Min width equals the height, padding 6 (sm 4), corner 4.
- Graphite fill, 1px Steel stroke, a 2px Ink @0.45 drop. Text in Label 11 Chalk (sm 9).
- The ghost variant has no fill, a Steel stroke and Fog text.
- Wide legends: `SPACE`, `ENTER`, `RMB`, `1–5`, `/`.
- **Graft from the wildcard pitch:**
  - The number keys 1–5 sit on the Visual..Misc tabs and switch tabs while the cheat menu is open.
  - Keycaps sit inside GO buttons (`ENTER`, `SPACE`), in footers (`1–5 TABS`, `H CLOSE`), on dock tiles (top-right corner, sm) and on HUD cheat tiles.
- Hidden on touch devices (`UserInputService.TouchEnabled and not KeyboardEnabled`).

### 3.20 ESP bracket: `Ui.bracket(target, color, {pad = 5, len = 12, thick = 2}) -> bracket`
- A transparent Frame sized `UDim2.new(1, pad*2, 1, pad*2)` at `(-pad, -pad)` on the target, holding 8 Frames: two per corner (a len×thick bar and a thick×len bar).
- Snap-in: it starts at pad+12 and tweens to pad with `Ui.T.Snap`.
- Colors:
  - White = menu focus.
  - Yellow = objective or picked.
  - Mint = best value (YOU KEEP ×2.0).
  - Violet = enemies, world only.
- This is the selection shape for the whole game.

### 3.21 Group box (labels on the border, from the purple aimbot menu): `Ui.group(parent, label) -> content`
- A Frame with no fill, a 1px Steel stroke and corner 6. Padding 16 top, 12 sides, 12 bottom.
- Label: Label 10 caps Fog on a TextLabel whose BackgroundColor3 equals the panel color at that height (use `Ui.C.Carbon2:Lerp(Ui.C.Carbon, 0.35)` = 25,28,34). It sits at (10, −7) with 6px side padding, so it cuts the border line.
- Used in every cheat detail column: `LOOK`, `RANGE`, `AIM`, `KEYS`, `LEVEL`, `MENU`.

### 3.22 Progress bar: `Ui.bar(parent, {value, color, height = 8, segments})`
- Track: Graphite with a 1px Steel stroke, pill. Fill: the meaning color, pill, tweened with `Ui.T.Bar`.
- Segmented variant: N Frames with 2–3px gaps, where filled segments are the color and empty ones Graphite with a Steel stroke. Used for HP (10 segments), boss HP (12), Ban Wave pips (5).
- Colors: quests Yellow, pity Yellow→Legendary gradient, SUS Yellow (turns Red at the Moderator line, which has a 1px Chalk tick), HP Mint→Yellow (≤50%)→Red (≤25%).

### 3.23 Search box
- 196x34, Graphite with a 1px Steel stroke, corner 6. A magnifier icon (ring + bar Frames) in Fog at 10px.
- Placeholder `Search cheats` in Body 12 Fog. A ghost keycap `/` at the right; pressing `/` focuses the box.
- Focused: 1.5px Violet stroke. With text in it, the keycap becomes an X clear button.

### 3.24 Modal: `Ui.modal({title, body, primary, secondary, danger})`
- Center 520 wide, auto height. The panel style with corner 12.
- Title in Display 24 with the stripe, body in Body 13 Mist, then a buttons row aligned right: secondary + GO, or secondary + Danger.
- Scrim: Ink @0.4 over the whole screen (ZIndex below the modal, above menus). Esc acts as secondary.
- Used for: duel match found (`MATCH FOUND · vs sweatlord_07 · 14 cheats`, 5s auto-accept ring), reset keybinds, Robux purchase result.

### 3.25 Dock tile: `Ui.dockTile(parent, {icon, text, color, keycap, badge})`
- 64x64, Carbon fill (32,36,44) at BackgroundTransparency 0.06, 1px Steel stroke, corner 8, Ink drop +4.
- A 20px icon above Micro 9 Display text. A 3px rail at x 4, inset 14px top and bottom, in the destination color.
- Active: the tile turns Yellow with Graphite icon and text, and gets a YellowLip drop; the rail is hidden.
- Hover: Slate2.
- Badge or keycap sits on the top-right corner.

### 3.26 Icons (Frames only, 20x20, Color3 = currentColor)
| Icon | Built from |
|---|---|
| `ring` (Play) | UICorner(1,0) + UIStroke 2, twice, plus a 2px dot |
| `box` (ESP) | 4 corner Ls + a 4px center square |
| `aim` | ring + 4 ticks |
| `bullet` | rounded rect + base |
| `move` | 2 chevrons |
| `dots` | 3 circles |
| `check` | rounded square + an L rotated −45 |
| `hammer` | head + handle, rotated −35 |
| `tag` | rounded rect + a hole |
| `gem` | rotated square outline |
| `gun` | barrel + grip + mag |
| `trophy` | cup + stem + base |
| `mag` | ring + bar |
| `shield` | outline, rounded bottom |
| `skull` | dome + jaw + 2 eye holes |
| `lock` | see 3.15 |
| `chevron` | 2 bars |
| `infinity` | two 9px rings overlapping 2px |

### 3.27 Prompt (custom ProximityPrompt UI, `Style = Custom`)
- A pill 48 tall, auto width, Graphite @0.08, 1px Steel stroke, corner 8.
- Left: a 28x28 keycap (`E`; on touch it becomes a tap circle).
- Then ObjectText in Micro Fog above ActionText in Display 14 caps.
- Hold progress: a 3px Yellow bar along the bottom inside the pill.
- Shows with `Ui.T.Open`. Prompt names are listed in 5.2.

---

## 4. Screens
Everything below lives in `Hud.gui` (ScreenGui `Hud`, DisplayOrder 10, IgnoreGuiInset true, ZIndexBehavior Sibling).

Z order:

| ZIndex | Layer |
|---|---|
| 1 | world-anchored HUD |
| 2–5 | HUD |
| 10 | menus |
| 20 | modals |
| 30 | toasts |
| 40 | round intro |
| 50 | Ban cinematic |

**Scaling.** Each top-level container gets a `UIScale`, anchored to its own screen edge:
- `s = math.clamp(math.min(vx / 1280, vy / 720), 0.6, 1.5)`.
- On touch devices, HUD tiles, the dock and mobile buttons use `math.max(s, 0.8)`.
- Menus on viewports under 900px wide switch to their compact layouts (4.4.9, 4.2).
- The Roblox top-left buttons own x 0–104, y 0–56. Nothing of ours goes there.

### 4.1 Lobby HUD (the pitch's `6_lobby_hub.png` and `7_tunnel_queue.png`, with these tokens)
| Element | Box at 1280x720 | Spec |
|---|---|---|
| Status pill | (112, 17), h 30, auto width | Graphite @0.12 with a Steel stroke. Ring icon (Violet) + `EARN ESP` Display 13, then 1px Steel dividers between facts. Facts: `LEAGUE HQ` (Label 11), `AUTO FARM +18 CR/MIN` (Mint dot when owned and on; otherwise `AUTO FARM OFF` in Fog) |
| Dock | (16, 120), 6 tiles 64 + 8 gap | PLAY [P] Yellow rail · CHEATS [H] Violet · GUNS Chalk · SKINS Epic purple · STORE Mint · BAN Red. The tile for whatever is open is Yellow. Unseen counts use a red badge (new skin, quest done). The dock replaces the old left quick buttons |
| Quests card | right 16, top 64, 252 wide | Panel without a header bar. `QUESTS` Display 15 with a check icon, `5/12` chip. Shows 3 unfinished quests as lane rows 56 tall with a Yellow rail: name in Row 13, `+250 CR` in Num 12 Mint on the right, a Yellow bar 6 tall below, and `18/25` in Num 11 Fog. A done-and-unseen quest shows a yellow `DONE` tag for 4s. Collapses to a 44px pill after 10s in the lobby, and expands on hover or click |
| Wallet | left 16, bottom 16 | Line 1: `3,250 CR` price pill lg (34) + `14/49 CHEATS` chip lg. Line 2: rank chip (current best rank) + `×1.5 BAN BONUS` chip sm (only if Bans > 0) |
| Tip pill | bottom-center, bottom 24, h 44 | Graphite @0.1 pill: ring icon + `Walk onto a pad to queue` Row 13, then `or` in Fog, then a mini GO (Yellow pill 30 tall `PLAY` + keycap `P`). Context swaps: near a prompt it shows nothing (the prompt is enough); on a pad it is replaced by the queue card |
| Objective marker | world BillboardGui on the next pad, AlwaysOnTop | Yellow ESP brackets (len 18, thick 3) around the pad's screen. A chip under them: Yellow `NEXT` tag + `BRONZE PAD` Display 13 + `48M` Num 12 Fog. Next pad = the highest unlocked rank not yet cleared; Practice for brand-new players |
| Zone title | top-center, y 60 | Micro `LEAGUE HQ · ZONE B` in Fog, `THE TUNNEL` Title 34 with the stripe centered, then a Graphite pill with the Body 13 line. Holds 2.5s, `ZoneEnter` cue, once per zone per visit. Zones are listed in `Config.LobbyZones` (5.7) |
| Queue card | bottom-center, bottom 22, 560x116 | Panel. Left: a 4px rail in the pad color, then the countdown ring (64px: a UIStroke 6px circle whose UIGradient Transparency rotation drains; Num 44 inside). Then `QUEUED` Label Yellow + `1/1 READY` chip, the mode name in Display 34, and chips `SERVER RANDOM OF 23` · `2 WAVES` · `+10 CR CLEAR`. Right: `STEP OFF TO CANCEL` Micro + `AUTO REQUEUE` switch. Duel/Survival/Cheater Island show `1/2 · WAITING` with no ring |
| Next Lane card | right 16, top 64 (replaces the Quests card inside The Tunnel) | `NEXT LANE` Display 15 + `RANK 3 OF 5`. A rank lane card: emblem, name, boss line, lock chip, buy pill for the needed cheat (buying works right here) |
| Toasts | top-center y 150 | 3.17 |
| Prompts | world | 3.27 |
| Trophy inspect card | left 16, top 120 (next to the dock, which hides while it is open), 300 wide | **Graft from the clubhouse pitch.** Panel: case icon tile, boss name Display 20, rank chip `DIAMOND BOSS`, flavor line (Body 12, see 5.5 C). Stat chips: `BANNED 3×` (Num) · `BEST 0:41` · `RANK DIAMOND`; hidden if the stat is missing. GO `REMATCH` (queues that rank; disabled with a lock if the rank is locked) + secondary `SET AS TITLE` (only if a title for that boss exists). Opened by `TrophyPrompt`, closed by walking 14 studs away or Esc |

### 4.2 Play menu (`final/2_play_menu.png`)
- Opened by PLAY [P], the dock, or the tip pill.
- Panel 1100x600 at (104, 60), sliding in from the dock. The world behind is blurred (BlurEffect 12) with an Ink @0.35 scrim.

| Box (panel-relative) | Content |
|---|---|
| Header 0..72 | `PLAY` Title 34 + stripe, keycap `P`, subtitle `Pick a lane. Every round drops you on a random server.` Right: `3,250 CR` chip lg (Mint stroke) · `14/49 CHEATS` chip lg · X |
| Left column x 20..576, y 88.. | Label row (22): `RANKED` (Chalk) `· THE TUNNEL` (Fog) … `CLIMB BY UNLOCKING CHEATS` (Micro, right). **5 rank cards**, 64 tall, 8 gap, in Tunnel order, each a lane with the rank rail. Each card: emblem tile 44, name Display 20 + optional `CLEARED ×14` mint tag, sub-line = `Config.Arenas[i].Description`. Right column: `0/1` chip + `+40 CR CLEAR` Micro Mint, **or** when locked: lock chip `NEEDS <CHEAT>` + price pill (gray if unaffordable) |
| Right column x 596..1080 | Label row: `MODES` … `● 59 PLAYING NOW` chip sm. **2x2 mode cards** 237x128, 10 gap, Slate, rail in the mode color. Each card: kicker icon + Label 10 in the mode color (`WARM UP` · `REAL PLAYERS` · `SQUAD OF 4` · `QUARANTINE · FFA`), name Display 21, one-line Small 12, and a ghost word Display 88 Chalk @0.95 in the bottom-right (`AIM` · `1V1` · `WAVE` · `FFA`). Chips row: Practice `FREE` tag + `0/1`; Duel `1/2` + `+150 CR WIN`; Survival `2/4` + `BEST: WAVE 12`; Cheater Island lock `NEEDS 40 CHEATS`. Then the **Selected card** (Graphite, 1px Steel stroke, rail in the selection color): `SELECTED` Label + rank tag + `RANKED · SOLO · 2 WAVES`, and chips `BOTS 6 TRYHARDS` · `BOSS LagSwitch_420` (Red stroke) · `SERVER RANDOM OF 23` · `35% TWIST` (Yellow stroke) |
| Footer 508..600 | Ring icon + `Or walk onto a pad` Row 13 / `Ranked pads are in The Tunnel, straight ahead from spawn.` Small 12 · `AUTO REQUEUE` switch · **GO 400x56** `QUEUE SILVER` with keycap `ENTER` and the count chip `0/1` |

- Selection uses white brackets on the selected card. Clicking a card selects it; double-click or ENTER queues.
- GO label by selection:
  - `QUEUE <RANK>`
  - `START PRACTICE`
  - `FIND MATCH` (Duel); while searching it becomes disabled-style Slate with Yellow text `CANCEL SEARCH 0:12`, and clicking it cancels
  - `QUEUE SURVIVAL`
  - Cheater Island and locked ranks: a disabled GO `LOCKED`, plus a buy pill to its left: `1,000 CR · GET TRIGGERBOT`
- Compact layout (under 900px wide): one column; ranks first, then modes in 2 columns, then Selected, all in a ScrollingFrame; the footer stays pinned.
- Hidden in rounds and while the cheat menu is open, as the old behavior already does.

### 4.3 Skin Spin (`final/5_skin_spin.png`)
- Full screen. Opened by `SkinSpinPrompt`, the SKINS dock tile, or the Guns tab's `SKIN SPIN` button.
- The camera tweens over 0.6s Sine to `SkinSpinCamera` (Zone C), FieldOfView 40, looking at `SkinSpinStage`.
- The current gun (GunModels) floats 1.8 studs above the stage, turning 30°/s. The stage's neon ring takes the shown skin's rarity color.
- Dock, status pill and wallet hide. A radial vignette sits over the screen (Ink 0 at 30% to 0.55 at 75%; build it from 4 vignette edges at 0.55).

| Box | Content |
|---|---|
| Title, top-center y 22 | Micro `FAN MARKET · BOOTH 1`, `SKIN SPIN` Title 36 + centered stripe, Small 12 `Skins work on every gun. Duplicates give back 40%.` |
| X | right 28, top 34 |
| Pool, left 28, top 92, 304 wide | Label `THE POOL` + chip `8/17 OWNED`. 6 rarity cards (3.16), 62 tall, 7 gap. Sub-line = the skin names in that rarity (`???` for Secret). Chip = owned/total |
| Name block, center, top 126 | Rarity tag + `NEW!` tag, the name in Hero 64 with a text shadow, and a Small 12 perk line (material · trim · `on every gun`) |
| Odds, right 28, top 92, 300 wide | Label `ODDS` … `PER SPIN`. 6 odds rows 38 tall (rarity rail, name Display 14 in the rarity color, % Num 15). Then the **pity card** (Graphite, Legendary rail): `LEGENDARY PITY` Label in Legendary, `34/50`, a 10px bar Yellow→Legendary, and `16 more spins and a Legendary+ is guaranteed.` |
| Bottom-left | `23,250 CR` price pill 34 + Micro `EQUIPPED: GALAXY` |
| Bottom-center | GO 300x62 `SPIN` (Display 28, keycap `SPACE`) with a price pill `1,500 CR` hanging under it; secondary 116x62 `×10` / `15,000 CR` (Num 11 Mint) |
| Bottom-right | `AUTO-SKIP ANIM` switch + secondary `EQUIP` 42 tall (`EQUIPPED` tag when equipped) |

Spin sequence:
1. Disable the buttons.
2. Brackets hop down the pool cards 22 times with `SpinTick`, each hop slower than the last.
3. The brackets land on the rolled rarity. The card gets its halo and the stage ring tweens to that color.
4. The name punches in (`Ui.T.Punch`) and `SpinReveal` plays.
5. Legendary and above also get light bars on the left and right screen edges in the rarity color for 0.6s.
6. A duplicate shows a mint toast `DUPLICATE · +600 CR BACK`.

Auto-skip jumps straight to step 4. ×10 runs ten quick reveals of 0.25s each, then shows a 2x5 results grid modal of rarity cards.

Clicking an owned skin card's sub-list (or the pool card while it is selected) opens a mini list of that rarity's skins to preview or equip, as the old click-to-equip behavior already does.

### 4.4 Cheat menu (`final/3_cheat_menu_visual.png`, `final/4_cheat_menu_banwave.png`)
- One panel, 900x590, everywhere.
  - Lobby: at (104, 64), next to the dock, with world blur.
  - Round: at (32, 100), below the match bug. No blur; instead an Ink gradient scrim from the left (0.62 at x 0 to 0 at 82% of the screen), so ESP stays readable on the right.
- Opened by H, the CHEATS / GUNS / STORE / BAN dock tiles (each opens its own tab), and `StorePrompt` / `QuestsPrompt`. Closed by H, Esc or X.
- Number keys 1–5 switch Visual..Misc while it is open and no TextBox has focus.

**Shell boxes (panel-relative):**
- Header 0..64:
  - Ring icon (Violet), `CHEATS` Title 30 + stripe.
  - Then a right-aligned group (UIListLayout Horizontal, Right, 10 gap): search 196x34, segmented control `LEGIT · CUSTOM · RAGE · OFF`, status chip, X.
- Columns from y 64 to 540:

| Column | x range | Width |
|---|---|---|
| Tab rail | 0..188 | 188 |
| List | 188..598 | 410 |
| Detail | 598..900 | 302 |

- "Wide" tabs (Guns, Quests, Ban Wave, Store) merge the list and detail columns into one 712-wide area.
- Footer 540..590:
  - `3,250 CR` price pill + `14/49 CHEATS` chip.
  - Right side: tab-specific facts, then keycaps `1–5 TABS` and `H CLOSE`.
  - On cheat tabs the facts are the SUS bar (110 wide, Yellow→Red at the line) + `12%` + `· 6 ON` + Yellow `Mods join at 8 ON` (the value is `Config.Sus.ModeratorAt`).
  - On Ban Wave the facts are `BANS 1 · CREDITS ×1.5 · DAMAGE ×1.25`.
- Status chip:
  - `UNDETECTED`: blue dot, Blue stroke, BlueText.
  - Jammed: `JAMMED 3.2s`, a Blue fill with white text.
  - Disarmed: `DISARMED 1.4s`.
- Presets:
  - `CUSTOM` is shown whenever the current switches don't match a preset.
  - Picking LEGIT, RAGE or OFF applies it (existing logic plus `Config.LegitPreset`) and shows the toast `LEGIT PRESET ON · 6 CHEATS`.
  - RAGE first shows a tooltip-style warning row under the control for 2s: `RAGE turns on all 14. SUS 93%. Mods will come.`
- Search:
  - Filters every cheat tab. The list header becomes `RESULTS FOR "esp" · 6`, and rows show their tab as a ghost tag.
  - Empty state: string 23. The tab rail shows no active tab while searching.
- Bottom of the tab rail: the `NEXT RANK` card (Graphite, rail in the next rank's color): rank tag + `needs Triggerbot`. Clicking it selects that cheat's row.

#### 4.4.1 Cheat tabs (Visual, Aim, Weapon, Move, Misc): list column
- Header row: tab name in Label (Chalk) + chip `4/13 OWNED` … `CLICK A ROW FOR SETTINGS` (Micro).
- Sub-headers `YOURS` (owned, in `Config.Hacks` order), then `BUY`: buyable first, then locked, then unaffordable, each group in `Config.Hacks` order.
- Rows are lane cards 48 tall (3.4):
  - Owned: Violet rail.
    - Right side: switch.
    - Upgradable cheats add **level pips** left of the switch: N squares 6x6, corner 1, Violet when reached, Graphite with a Steel stroke when not; max from `Config.Upgrades[id].MaxLevel`.
    - A cheat with a key adds a keycap sm with its key (`T`, `F`, `N`, `G`, `RMB`) left of the pips.
  - Not owned: Steel rail. Right side: buy pill (Mint) or gray price.
  - Locked (`Requires` not owned): row at 62%, lock chip `NEEDS <NAME>` (sm), no price. The price shows in the tooltip and the detail column.
  - Jammed: switches turn Blue (3.5) and a Blue lane row sits on top of the list: `JAMMED BY A MODERATOR · back in 3.2s`.
- The list is a ScrollingFrame (ScrollBarThickness 3, Steel @0.3) with a 44px Carbon2 fade at the bottom.

#### 4.4.2 Cheat tabs: detail column (for the selected row; the first row is selected by default)
1. **Preview card**, 270x112:
   - Graphite radial-ish fill (two stacked Frames with a UIGradient), a floor strip, and a ViewportFrame with a Noob dummy wearing the cheat's effect: ESP box, health rail, name tag, head dot, tracer line or skeleton, drawn with the same code the game uses (`Esp.luau` preview mode).
   - Tag `PREVIEW` (Violet) and the distance `24m` (Num 10).
   - Cheats without a visual (Move, Misc) show their icon at 48px in Violet plus a Body line of what it does.
2. **Name** Display 24 + `ON` tag (Violet) / `OFF` ghost / `NOT OWNED` ghost Fog. Right: `SUS +4%` Micro (each ON cheat adds 1/`Config.Sus.Full`).
3. **Description**: `Config.Hacks[i].Description`, rewritten into one Body 12 line plus one extra fact line when known (`Works on bots, bosses and players.`).
4. **Group boxes** (3.21), only those that apply to this tab:

| Tab | Group | Controls |
|---|---|---|
| Visual | `LOOK` | `ESP COLOR` swatches (Toggles.ESP_COLORS + rainbow if RainbowChams) · `CHAMS STYLE` dropdown (Toggles.SETTINGS.ChamsStyle: Glow/Outline/Solid/Ghost) |
| Visual | `RANGE` | `MAX RANGE` slider 50–500 step 10, default 300 STUDS (new `Toggles.number("EspRange")`) · FOV Changer selected: `FIELD OF VIEW` slider 70–120 step 1, default 90° · `KEYBIND` keycap (click to set) |
| Aim | `AIM` | `TARGET PRIORITY` dropdown (Crosshair/Closest/Lowest HP/Bosses) · `AIMBOT HITBOX` segmented (Head/Chest/Stomach) · `SHOW FOV CIRCLE` switch · `ASSIST STRENGTH` slider 25–100% (new) · `KEYBIND` keycap `RMB` for Aimbot |
| Weapon | `TRACERS` | `TRACER COLOR` swatches (Toggles.TRACER_COLORS) |
| Move | `KEYS` | keybind rows for Teleport `T`, Fly `F`, Noclip `N` (rebindable) |
| Misc | `KEYS` + `MENU` | God Mode `G`; `MENU THEME` dropdown (`LEAGUE` default · `MIDNIGHT` (Carbon 24,30,46 / Carbon2 16,20,32) · `CARBON` (Carbon 34,34,36 / Carbon2 24,24,26)). Themes change neutrals only, never accents. Then `ALL KEYBINDS` (a modal list: Cheats H, Play P, Reload R, Leave L, Aimbot RMB, Teleport T, Fly F, Noclip N, God Mode G; `RESET` secondary) |
| any upgradable | `LEVEL` | pips + `NEXT LV 3: +10 degrees of lock-on range` (Body 12; the text after the colon is `Config.Upgrades[id].Description`) + buy pill wide `UPGRADE · 9,000 CR` (`Config.upgradeCost`). At max: tag `MAX`, no button |

5. **Not owned:** the detail shows the price (Num 22 Mint) + a wide buy pill `BUY · 400 CR`. Locked shows a lock chip + `Unlock <Requires> first` + a link row to that cheat.

**Keybind capture:**
- Clicking a keycap turns it into `PRESS A KEY` with a pulsing Violet stroke. The next key press is saved; Esc cancels.
- A key that is already taken gets a Red stroke, `UiDeny`, and toast 21.
- Saved keys replace the hardcoded `hack.Key` values in `Toggles.keys[id]` (persist them if the save system allows).

**Buying flow:** see 3.10 Buy. A successful buy also sends the newly unlocked rank's toast (string 19) when the purchase opens a rank.

#### 4.4.3 Guns tab (wide 712)
- Left list 400 wide: one lane row 52 tall per gun from `Config.Weapons`.
  - Rail: Chalk if owned, Steel if not.
  - Name in Row 14, stats line in Small 12: `DMG 21 · 545 RPM · MAG 30` (pellets: `DMG 12×8`).
  - Right side: `EQUIPPED` Yellow tag + yellow brackets / secondary `EQUIP` / buy pill.
- Detail 312 wide:
  - ViewportFrame 280x120 with the gun turning, in its equipped skin.
  - Name Display 22 + skin rarity tag.
  - Description Body 12.
  - 4 stat bars: `DAMAGE` · `FIRE RATE` · `MAGAZINE` · `RANGE`. Label 10 on the left, a Chalk bar 150x8 scaled against the best gun.
  - Group `SKIN`: equipped skin chip + secondary `SKIN SPIN` (opens 4.3).
  - The single GO: `EQUIP` (when owned and not equipped). Otherwise a wide buy pill.

#### 4.4.4 Quests tab (wide)
- Top card (Graphite, Mint rail): `DAILY DROP` Display 15 · `DAY 3 STREAK` chip · `+300 CR` Num Mint · `NEXT IN 14H` Micro. If it is claimable, a GO `CLAIM`, which is the tab's one yellow.
- Then quest rows 56 tall:
  - Active: Yellow rail, name Row 14 + `Text` Small 12, a Yellow progress bar 8 under the text (60% width), chip `18/25` on the right and `+250 CR` Num 13 Mint.
  - Done: Mint rail, `DONE` tag, 60% opacity, sorted last under a `DONE` sub-header.
- Empty state: string 28.

#### 4.4.5 Ban Wave tab (wide; `final/4_cheat_menu_banwave.png`)
- Content padding 12/16, gap 8.
- Title row (40):
  - Red hammer icon, `BAN WAVE` Display 26 with the **red stripe**.
  - Body 12 Fog `Turn yourself in. Lose the cheats, keep the bonus forever.` (2 lines).
  - Right: chip `1 BAN SO FAR` with a Red stroke.
- `BAN LADDER · INTEGRITY DESK` label row, then 3 tier cards (106 tall, 8 gap, Slate, ghost word Display 62 @0.955):
  - **Layer 1 BAN WAVE:** Red rail, a Red 1.5 stroke when it is the next step. `LAYER 1` red tag + `NEXT: BAN #2` Micro RedText. Name Display 18, line Small 11 `Resets Credits, cheats, rank.` Then 5 pips 28x6: filled Red per ban, the next pip outlined Red.
  - **Layer 2 HARDWARE BAN:** Violet rail, ghost tag, lock `AFTER 5 BAN WAVES`.
  - **Layer 3 ACCOUNT DELETED:** Chalk rail, ghost tag, lock `AFTER 3 HARDWARE BANS`.
- Two columns, 12 gap:
  - `YOU LOSE` (RedText) / `BACK TO BRONZE`: rows 37 with a Red rail. `CREDITS 72,400 › 0 CR` · `CHEATS 14 › 0 /49` · `RANK Silver › Bronze`. The old value is Num 14 Fog, the chevron icon is Fog, and the new value is Num 16 RedText.
  - `YOU KEEP` (Mint) / `NEW TITLE: BANNED ×2`: rows with a Mint rail. `BAN BONUS · CREDITS ×1.5 › ×2.0` (selected: Mint brackets) · `BAN BONUS · DAMAGE +25% › +50%` · `GUNS, SKINS, TITLES` + `KEPT` tag.
  - Values come from `Config.BanWave` exactly as `multipliers()` computes them today.
- Payoff strip (34, Graphite, Yellow rail): chevrons + string 48.
- Action row:
  - Trophy icon, `Your ban plays on the jumbotron` Row 12 / `Everyone in League HQ sees it.`
  - Price pill `60,000 CR` (`Config.banWaveCost(bans)`).
  - **Hold button 300x52** `HOLD TO GET BANNED`. Disabled states as in 3.10. In a round it reads `FINISH YOUR ROUND FIRST`, and the tab-rail bottom card says `LOBBY ONLY · Finish your round first.`
- The hold button replaces the old "click again to confirm".

**Ban cinematic** (after the server confirms):
1. The menu closes.
2. A white flash covers the screen: Chalk @0.3, fading to 1 over 0.25s.
3. A centered stamp: a Frame with a 6px Red UIStroke and corner 6, `BANNED` in Hero 72 Red, rotated −8°, scaling 1.6→1 with `Ui.T.Punch`. `BanGavel` plays and the stamp holds 1.2s.
4. The server calls `Map.flashJumbotron("BANNED", "<name> · BAN #<n> · ×<mult> FOREVER", "Red", 6)`, so everyone sees it.
5. The player stays at spawn. A toast follows: `WELCOME BACK · ×2.0 FOREVER`.

#### 4.4.6 Store tab (wide; also opened by `StorePrompt`; layout from the pitch's `9_store.png`)
- Sub-tab pills: `PASSES` · `CREDITS` · `CODES`, with `NEW!` on any tab that has new items. Right: Micro `PRICES IN ROBUX`. The line `Passes are forever. Nothing here unlocks a rank.` sits under the tabs in Small 12.
- **Passes:**
  - Featured card 228x330 on the left: art tile with a Yellow gradient, giant `2×` in Hero, `BEST SELLER` tag.
    - `DOUBLE CREDITS` Display 20, then `Every kill, clear and Auto Farm tick pays twice. Stacks with your Ban Bonus.`
    - Chips `NOW ×1.5` · `WITH PASS ×3.0`.
    - The **yellow GO** shows the Robux price. When owned it becomes an `OWNED` Mint tag.
  - Grid on the right: 3 columns of 136x166 cards, 12 gap. Each card: art tile 120x72 (3.16 style, color = the item's color, glyph built from Frames or Display text), name Display 13, Small 11 line, and a Robux price pill or `OWNED` tag. Corner tags `NEW!` / `+20%`.
  - Cards come from `Config.GamePasses` and an optional `Config.DevProducts`. Any id = 0 shows a ghost `SOON` tag with no button (this replaces "NOT SET UP YET"). With only one pass, the grid shows string 29.
- **Codes:** a code TextBox 280x40 (Graphite, Label 13 caps, placeholder `ENTER CODE`) + Mint `REDEEM` button (a 120x40 secondary with a Mint fill and Graphite text) + Small `Codes are posted on the game page. The codes stall is at the Campsite.` Results are toasts (string 16).

#### 4.4.7 Mobile cheat menu
Under 900px wide:
- The tab rail becomes an icon-only rail, 56 wide.
- The list takes the rest of the width.
- The detail opens as a bottom sheet: 100% width, 62% height, corner 12 on the top, a drag bar, and a scrim.
- The footer hides its keycaps.
- A floating `H` keycap button (56px dock-tile style) in the HUD opens the menu. It is the existing `Hud.menuButton`, restyled.

### 4.5 Round intro "Now joining" (layout: pitch `8_round_intro.png`; letterbox graft from the fiction pitch)
- Runs while `RoundStartsAt - now > 0` (3s).
- **Letterbox:** two Ink Frames, 56 tall, top and bottom, sliding in over 0.2s and out over 0.25s at GO.
- Dim: Ink @0.45 behind the content.
- Left block at (96, 150):
  - Rank tag + Label `RANKED · WAVE 1 OF 2` (Duel: `DUEL · FIRST TO 5`; Practice: `PRACTICE · NO TIMER`).
  - Label `NOW JOINING` in Yellow, then the map name in Hero 72 with a text shadow.
  - Stripe + Label `SERVER 07 OF 23`: the map's index in `Config.MapPool` and `#Config.MapPool`.
  - Chips row: `TWIST BIG HEADS` (Yellow stroke, only if there is a modifier) · `6 BOTS` · `BOSS NONE` / `BOSS LAGSWITCH_420` · `+10 CR CLEAR` (Mint stroke).
  - Label `YOUR CHEATS`, then up to 7 HUD cheat tiles (4.6) + a `+8 OFF` tile.
  - The anti-cheat line: Blue hammer icon + `ANTI-CHEAT` Label BlueText + Body `is asleep. Stay under 8 ON to keep it that way.` When over the line: `is awake. Moderators join every wave.` in RedText.
- Right block at (836, 150), 380 wide:
  - Label `SERVER ROLL` … `RANDOM EVERY ROUND`.
  - 5 rows 42 tall, each `SERVER 05 · ROOFTOPS · 12 MS`. The list scrolls through `Config.MapPool` for 1.6s, decelerating, and lands on the real `MapName`. That row gets yellow brackets, the `PICKED` tag, a halo, and Chalk text; the others are Fog @0.5.
- Countdown ring at (1025, 520): 100px. A 6px Graphite ring with a Yellow UIStroke arc draining (UIGradient Rotation), Num 52 inside, `GET READY` Display 16 under it, then Small `Bots go live in 3`. Each second plays `Countdown`.
- At 0: the ring flashes `GO` Hero 72 Yellow with `Ui.T.Punch`, `RoundStart` plays, and everything fades out.
- This replaces the old big "3, 2, 1, FIGHT!".

### 4.6 Match HUD (`final/6_hud_round.png`). Every element:
| Element | Box at 1280x720 | Spec |
|---|---|---|
| Status pill (the old watermark) | (112, 17), h 30 | `EARN ESP` · `● 6 ON` (Violet dot) · `SUS` + bar 40x6 + `12%` Num 12 · `60 FPS · 24ms` Body 10 Fog. SUS fill is Yellow, turning Red at `Config.Sus.ModeratorAt / Config.Sus.Full`. Must end before x 500 |
| Match bug | top-center y 12 | Row 1: rank tag 24 tall · timer box 104x42 (Graphite @0.1, Steel stroke, Num 28 `4:18`, mini stripe at the bottom inside) · chip `WAVE 1/2`. Row 2 (y +49): Label `SERVER 07 · SHIPPING YARD` with a text shadow · chip `● 4 LEFT` (Red dot) · ghost Yellow tag for the twist (`BIG HEADS`). **Duel:** row 1 is `YOU 3` (Mint) – timer – `1 sweatlord_07` (RedText), row 2 `FIRST TO 5 · DUEL HALL SERVER`. **Practice:** row 1 `PRACTICE` tag + no timer + `DUMMIES 8` chip, row 2 `RANGE · NO CREDITS`, plus the hint `L LEAVE`. **Survival:** `WAVE 7` chip, no `/N` |
| Boss bar | center, y 96, 440x46 | A lane card on Graphite @0.1 with the rail in the round's rank color: `BOSS` tag, name Display 15, Micro `SILVER BOSS`, `620/900` Num 12 on the right, and 12 HP segments 6 tall (Red, the last-lost segment white @0.45 for 0.4s). Admin adds `PHASE 2` chip when it summons |
| Toasts | top-center y 150 | 3.17 |
| Jam / disarm / patch banner | center, y 200, 420x52 | A lane card with a Blue rail on Graphite @0.08 + the blue vignette. `JAMMED` Display 18 + `Moderator jammed your cheats` Small 12, a draining Blue bar under it, and a Num 14 seconds counter on the right. `DISARMED` also greys the viewmodel. `PATCHED` names the cheat with a strike line through it (a 1px Frame) |
| Radar | (16, 60), 128 circle | Graphite @0.38, Steel 1.5 stroke, inner ring @0.86, cross lines @0.92. A Violet view cone at @0.9. Blips 8px: bots in the ESP color, Moderators Blue, decoys hollow (stroke only), boss a Red 10px diamond, you a Chalk triangle. Micro label `RADAR · 120 STUDS` under it. Only with the Radar cheat on |
| Kill feed | right 16, top 14 | Toast-style rows 30 tall, rail 3 wide, max 5, 4s life. `YOU` Row 12 · bullet icon Fog · victim Mist · `HS` tag · `+12 CR` Num 12 Mint. Boss kills: a `BOSS` tag and a Red rail. Anti-cheat lines: a Blue rail, BlueText first word |
| Arraylist (active cheats) | right 16, under the kill feed (~y 124) | The cheat-client joke, kept: names of every ON cheat, right-aligned, Row 12 VioletText on Graphite @0.45, 20 tall, sorted longest first, max 10 + `+N`. Rainbow text only when Rainbow Chams is on. Hidden under 900px |
| Crosshair | center | 4 bars 2x8 Chalk, each with a 1px Ink stroke at @0.45. Gap = 7 + spread px (existing math). No center dot |
| FOV circle | center | Shown when Aimbot is on and the setting is on. A circle Frame with a UIStroke 1.5 Violet @0.45, radius from `Toggles.aimbotFov()` |
| Hitmarker | center | 4 diagonal bars 10x2.5 at ±10px offset, each with a 1px Ink stroke. Body hit Chalk, **headshot Yellow**, **kill Red** (bars 14x3, box 64). Fades over 0.3s (existing) |
| Damage numbers | world BillboardGui at the hit | Num 18 Chalk / headshot Num 22 Yellow + Micro `HEADSHOT`. Text shadow. Rises 28px over 0.6s |
| Damage direction | ring radius 120 around center | Red pill 56x6 pointing at the attacker, fading over 0.9s (existing) |
| Kill banner | center, y 548 | `BOT DELETED` Display 28 + `×2` Yellow tag (streak within 3s), then stripe · `+6 CR` Num 16 Mint · mirrored stripe. `Ui.T.Punch`, holds 1.4s. Variants: `BOSS BANNED` (Red stamp frame around it), `MOD DELETED` (BlueText) |
| Wave / round banners | center, y 250 | `WAVE 1 CLEARED` Display 34 + `+40 CR` chip; `WAVE 2 · BOSS INCOMING` with a Red tag; `SERVER CLEARED` Hero 56 + stripe + tally chips (`+46 CR KILLS` · `+40 CR CLEAR` · `= 86 CR`) for `Config.RoundEndDelay`; `BANNED FROM SERVER` Hero 56 RedText + `Back to HQ in 3` |
| Cheat tray | left 24, bottom 114 | Tiles 46x46 (Graphite @0.14, corner 6, a 1.5 Violet stroke when on, a Steel stroke when on cooldown): icon + Display 8 name, a keycap sm on the top-right corner, and a cooldown overlay (Ink @0.38 + Num 15 seconds). Order: keyed cheats first (Teleport T, Fly F, Noclip N, God Mode G, Aimbot RMB, Bunny Hop SPACE), then the most important passives (ESP, ASSIST) up to 5 tiles, then a `+2 MORE` chip |
| HP | left 24, bottom 56 | `97` Num 52 with a text shadow, `HP` Label, a 10-segment bar 20x8 (gap 3) in Mint/Yellow/Red, a lag segment white @0.45 that catches up over 0.6s. Low HP: red vignette pulse (existing) |
| Wallet | left 24, bottom 22 | `3,256 CR` price pill 26 (Graphite @0.14) + `×1.5 BAN BONUS` chip sm. The credit popup `+6` Num 22 Mint rises 46px from above the wallet (existing) |
| Ammo | right 24, bottom 22 | Skin tag (rarity color) + gun name Label `ASSAULT RIFLE`, `24` Num 52 + `/ 30` Num 20 Mist, then a tick bar (one 3x10 tick per round up to 30; bigger mags scale to 30 ticks). ≤3 left: the number turns Red. Reloading: the ticks refill left to right + `RELOADING` Label Yellow. Infinite Ammo: `INF` |
| Key hints | bottom-center, bottom 20 | Keycap + Label 10 pairs: `H CHEATS` · `R RELOAD` (not with Infinite Ammo) · `L LEAVE` (Practice) · keyed cheats that are on (`G GOD MODE`, `T TELEPORT`...). Max 5 |
| Scope (Sniper) | full screen | An Ink ring around a clear circle, 1px Chalk crosshair lines, a 2px Red center dot, and Ink @0.0 outside (existing structure, new colors) |
| Mobile buttons | right side | FIRE 90 circle (right 30, bottom 110): Graphite @0.25 with a 2px Violet stroke and `FIRE` Display 16. AIM 64 circle above-left of FIRE. RELOAD 56 circle left of FIRE. CHEATS: a 56 dock-tile-style button at right 20, y 40%. Keyed cheats get 52 circles (`T` `F` `N` `G`) in an arc above FIRE with cooldown overlays. Key hints and keycaps are hidden. Jump stays Roblox's |
| Spectate / death | | `BANNED FROM SERVER` banner, then back to HQ (existing flow) |

### 4.7 HUD outside rounds
Shown in the lobby only:
- status pill (lobby facts)
- dock
- quests card
- wallet
- tip pill
- toasts
- zone titles
- prompts

The kill feed, ammo, timer, radar and tray are hidden (existing `inRound` logic).

---

## 5. Lobby master plan (`final/1_lobby_plan.png`)

### 5.1 Global rules
- **Plot:** X −80..80, Z −65..65 (160 x 130), centered on (0, 0, 0). **The floor top is Y = 0 everywhere**: every floor slab is 1 thick with its center at Y −0.5. North is −Z, toward the ranks. Spawn faces north.
- **Model:** `workspace.Lobby` (Model) with Folders `ZoneA`, `ZoneB`, `ZoneC`, `Exterior`. Each zone builds only into its own folder.
- **Walls:**
  - Walls are 2 studs thick and are built **inside the owner's rectangle**, flush to the boundary.
  - Openings are left as gaps between wall segments, plus a lintel above them.
  - The wall owner builds the door frame and trim on both faces.
  - A neighbor may add up to 0.4 studs of cladding on its own side, leaving the door surround (opening + 2 studs each side) clear.
  - Wall-mounted signs may protrude up to 1 stud into a neighbor's space.
  - Each zone keeps a 2-stud prop-free strip along shared boundaries.
- **Heights:**

| Space | Height (Y) |
|---|---|
| Concourse | walls and roof to 28 |
| B rooms and Trophy Hall | 20 (roof slab Y 20..21) |
| Tunnel | ceiling slab Y 18..19 |
| RANKED gate | 16 tall |
| Duel / Survival gates and Trophy arch | 14 |
| Practice gate and Quarantine door | 12 |
| Campsite door | 14 |

- **The HQ stripe** runs along every Concourse-facing wall face: a Violet neon strip 0.3x0.3 at **Y 10.0** and a Yellow neon strip 0.3x0.3 at **Y 9.4**, broken at openings. Each wall owner builds it on its own wall: A on its west and south walls, B on the facade's Concourse face (X −80..40), C on its Trophy Hall wall's Concourse face (Z −20..24). A Kick Band Part (Steel, 1.2 tall, 0.2 proud) runs along the same faces.
- **Part rules:**
  - Everything is Anchored with smooth surfaces.
  - Neon Parts and small decor are `CastShadow = false`.
  - Decor above head height and all thin trim is `CanCollide = false`, `CanQuery = false`.
  - Only triggers are `CanTouch = true`.
  - No unions, no meshes, no textures. Use Kit helpers (`Kit.part`, `Kit.neon`, `Kit.cylinder`, `Kit.wedge`, `Kit.light`, `Kit.text`, `Kit.tree`, `Kit.fence`, `Kit.bench`, `Kit.sandbags`), with `ctx = { Model = folder, Structure = folder, Decor = folder, Center = Vector3.zero }`.
  - Seats are real `Seat` instances styled as benches, logs and sofas.
- **Budget:**

| Zone | Max parts |
|---|---|
| A | 1,000 |
| B | 1,300 |
| C | 1,100, of which exterior ≤ 350 |

  Keep StreamingEnabled on.
- **Signs (in-world SurfaceGui):**
  - A Sign Panel Part (Graphite) with `SurfaceGui { SizingMode = PixelsPerStud, PixelsPerStud = 50, LightInfluence = 0, Brightness = 1.4, Face = <given> }`.
  - Titles use `FontFace = Ui.F.Display` with TextScaled. Lines use Row or Label, TextScaled with a `UITextSizeConstraint`.
  - The stripe under a sign title is two Frames: Violet (0.12 x 0.025 of the gui) and Yellow (0.055 x 0.025) with a 0.012 gap.
  - The neon frame around a sign is 4 Neon Parts 0.25 thick in its meaning color.
  - **Facing:** a Part with no rotation has its Front face toward −Z. For a sign to face +Z (toward spawn), rotate it `CFrame.Angles(0, math.rad(180), 0)` and use Face Front. `math.rad(-90)` makes Front face +X, and `math.rad(90)` makes it face −X.

### 5.2 Map.luau contract (Zone A's agent edits Map.luau; B and C call this API)
```lua
Map.portals = {}                                   -- { {Part = trigger, Id = "Bronze"}, ... } read by Portals.luau (unchanged)
function Map.registerPortal(trigger: BasePart, id: string)   -- trigger:SetAttribute("PortalId", id); table.insert(Map.portals, {Part = trigger, Id = id})
function Map.registerPadScreen(id: string, slots: TextLabel) -- the screen's TextLabel named "Slots"
function Map.setPadSlots(id: string, text: string)           -- "1/2" -> every Slots label of id shows '1<font color="#8A93A6">/2</font>' (RichText)
function Map.registerBoard(key: string, rows: {TextLabel})   -- key = "Credits" | "Bans" | "Survival"; 8 rows each
function Map.setLeaderboards(creditLines, banLines, survivalLines?) -- empty board: Row1 = empty-state string in Fog
function Map.registerJumbotron(title: TextLabel, line: TextLabel)
function Map.flashJumbotron(title: string, line: string, colorName: string, seconds: number) -- then back to "EARN ESP / LEAGUE HQ · SEASON 1"
function Map.lobbySpawn(): CFrame                  -- Vector3.new(math.random(-3,3), 4, 54 + math.random(-3,3)), facing -Z
Map.buildLobby()  -- creates workspace.Lobby + folders; require(script.Parent.Lobby.ZoneA).build(folderA, Map), then ZoneB, ZoneC; sets Lighting
```

**Mode ids** (`PortalId` and `setPadSlots` ids) with their default slots:

| Id | Default slots |
|---|---|
| `Practice` | `0/1` |
| `Bronze`, `Silver`, `Gold`, `Diamond`, `Champion` | `0/1` |
| `Duel` | `0/2` |
| `Survival` | `0/4` |
| `CheaterIsland` | `0/12` |

**Pad flow** (Zone B's agent updates `Portals.luau`):
- Touching a trigger marks the player on that pad.
- Server: every 0.25s, check the HumanoidRootPart is still inside the trigger's box.
- Ranks and Practice:
  1. The screen shows `1/1`. The line changes to `STARTING IN 3`, `2`, `1`, and the client queue card shows.
  2. After 3s on the pad, call `Rounds.begin(player, id)`. Stepping off cancels and shows `PadLeave`.
- Duel: toggles `Duel.setQueued` (existing).
- Survival and CheaterIsland route to a `Modes[id]` handler table. If none exists yet, the screen line reads `OPENING SOON` and the player gets the toast `Survival opens soon.`

**Prompt names** (ProximityPrompt `Name`; all `Style = Custom`, `KeyboardKeyCode = E`, `HoldDuration = 0`, `MaxActivationDistance = 10`, `RequiresLineOfSight = false`):

| Prompt | Opens |
|---|---|
| `SkinSpinPrompt` | Skin Spin |
| `StorePrompt` | Store tab |
| `QuestsPrompt` | Quests tab |
| `DailyPrompt` | Daily Drop claim |
| `TrophyPrompt` | trophy inspect card; Attribute `BossId` |

**NpcSpot markers** are 2x0.2x2 Parts, Transparency 1, CanCollide/CanQuery/CanTouch false, with Attribute `NpcSpot`; their Front faces the way the NPC looks. The kinds are `QueueHost` (A), `Vendor` and `Curator` (C).

**Camera parts** (Zone C), both Transparency 1, CanCollide false:
- `SkinSpinCamera`: a Part whose CFrame is the camera.
- `SkinSpinStage`: the pedestal Part.

**Pad recipe** (every pad; Zone B):
1. `PadBase`: (w, 0.2, d) at (cx, 0.1, cz), Pad Top color.
2. `PadEdge` ×4: Neon 0.3 wide x 0.14 tall at Y 0.27 along the perimeter, in the pad color.
3. Ring icon: Cylinders with their axis along Y.
   - Chalk Neon, diameter 0.62·m, height 0.04, Y 0.22.
   - Pad Top, 0.5·m, Y 0.24.
   - Chalk Neon, 0.34·m, Y 0.26.
   - Pad Top, 0.24·m, Y 0.28.
   - Chalk Neon dot, 0.08·m, Y 0.30.
   - Here m = min(w, d). The Chalk Neon parts use Transparency 0.15.
4. `PadTrigger`: (w, 6, d) at (cx, 3.2, cz), Transparency 1, CanCollide false, CanQuery false, CanTouch true. `Map.registerPortal(trigger, id)`.
5. `PadScreen`: a Sign Panel 0.4 thick at the given CFrame. The frame is 4 neon strips in the pad color. Its SurfaceGui labels:
   - `Title`: (0.06, 0.07, 0.62, 0.2), Display, left-aligned, in the pad color.
   - `Icon`: the ring icon built from 2 ring Frames, top-right (0.8, 0.07, 0.14 square).
   - `Slots`: (0.06, 0.3, 0.62, 0.42), Num, Chalk, RichText.
   - `Line`: (0.06, 0.78, 0.88, 0.13), Row, Mist; a lock line is in RedText.

   Then `Map.registerPadScreen(id, Slots)`.
6. A PointLight on PadBase: pad color, Range 10, Brightness 1.2.

### 5.3 The three zones and their seams
| Zone | Rectangle | Owns | Shares |
|---|---|---|---|
| **A · Concourse** | X −80..40, Z −20..65 (120 x 85) | the Atrium + spawn, Concourse, The Stands, all leaderboards, the how-to board, the Quests kiosk, the jumbotron, gate banners, the Concourse roof. Walls: west X −80..−78 (Z −20..65) and south Z 63..65 (X −80..40), height 28. Lighting + Map.luau | Z = −20 with B (B's wall). X = 40 with C (C's wall) |
| **B · Tunnel + modes** | X −80..80, Z −65..−20 (160 x 45) | The Tunnel + Bronze..Champion pads, Practice Range, Duel Hall, Survival Hall, Quarantine / Cheater Island. Walls: **the facade Z −22..−20 (X −80..80)**, north Z −65..−63, west X −80..−78, east X 78..80, partitions. `Portals.luau` | Z = −20 with A (X −80..40) and with C (X 40..80) |
| **C · Trophy Hall wing + outside** | X 40..80, Z −20..65 (40 x 85), plus everything outside the plot and above Y 29 | Trophy Hall, Fan Market (Skin Spin booth, Pro Shop), The Campsite, the exterior (lawn, skyline, light towers, floating Cheater Island, rooftop sign, clouds). Walls: **X 40..42 (Z −20..65)**, Trophy Hall east X 78..80 and south Z 24..26, the Campsite fence | X = 40 with A; Z = −20 with B |

**Doorways (exact):**

| # | Opening | On wall (owner) | Span | Height | Frame / trim |
|---|---|---|---|---|---|
| 1 | Practice gate | Z −22..−20 (B) | X −72..−60 | 12 | Chalk neon frame + header `PRACTICE` |
| 2 | Duel gate | Z −22..−20 (B) | X −38..−24 | 14 | Duel violet neon + header `DUEL` |
| 3 | **RANKED gate** | Z −22..−20 (B) | X −10..10 | 16 | Chalk neon frame + header `RANKED` with 5 rank chips |
| 4 | Survival gate | Z −22..−20 (B) | X 24..38 | 14 | Survival lime neon + header `SURVIVAL` |
| 5 | Quarantine door | Z −22..−20 (B) | X 56..68 | 12 | hazard-striped jambs + Red neon + header on the Trophy Hall side `QUARANTINE · CHEATER ISLAND` |
| 6 | Trophy Hall arch | X 40..42 (C) | Z −4..8 | 14 | walnut frame with brass edge + sign `TROPHY HALL / CHAMPIONS LOUNGE` on the Concourse side |
| 7 | Campsite door | X 40..42 (C) | Z 38..52 | 14 | Steel frame in the glass wall + sign `THE CAMPSITE` |
| 8 | Sky window (glass, not walkable) | X 78..80 (B) | Z −56..−30, Y 4..16 | – | Glass (207,232,255) Transparency 0.35 |

### 5.4 Zone A: Concourse (X −80..40, Z −20..65)
| Item | Exact spec |
|---|---|
| Floor | `Floor_A` (120, 1, 85) at (−20, −0.5, 22.5), Concourse Floor. Grout lines 0.2 wide, 0.02 tall at Y 0.01, every 10 studs (X = −70..30, Z = −10..60) |
| Walls | West (2, 28, 85) at (−79, 14, 22.5); south (120, 28, 2) at (−20, 14, 64). HQ Wall color, kick band, HQ stripe |
| Roof | Y 28..29 over X −80..40. Solid Chalk strips (120 x 1 x 8) centered on the trusses at Z −12, 4, 20, 36, 52; Glass skylight strips (Transparency 0.45, 220,235,255) in the gaps (Z −20..−16, −8..0, 8..16, 24..32, 40..48, 56..65) |
| Trusses | Truss beams (120, 2, 1.2) at Y 26, Z −12, 4, 20, 36, 52. Each gets a white Neon light strip (100, 0.2, 0.6) on its underside at Y 24.9 and a SurfaceLight (Face Bottom, 240,244,255, Brightness 1.4, Range 26, Angle 120). Colonnade posts (1.6, 28, 1.6) at X −40, Z −12, 4, 20, 36, 52 |
| **Spine lane** | `Lane` (8, 0.1, 69) at (0, 0.05, 15.5), Lane Floor (spawn edge Z 49 to gate Z −19). Neon edges (0.3, 0.12, 69): **Violet at X −4.15, Yellow at X +4.15**. White chevrons (two Chalk SmoothPlastic bars 0.8x0.12x3.4 rotated ±45°, pointing −Z) at Z 40, 31, 22, 13, 4, −5, −14 |
| **LobbySpawn** | `SpawnLocation` named `LobbySpawn`, Size (10, 0.4, 10), CFrame (0, 0.2, 54), Pad Top color, Duration 0, Neutral true. Edges: left Violet, right Yellow, front and back Chalk neon. A Chalk ring icon on top. Faces −Z down the lane |
| Floor rings | Under the jumbotron at (0, 12): Violet Neon disc D20 (h 0.02) / floor-color disc D19.2 (h 0.04) / Violet D14 (h 0.06) / floor D13.2 (h 0.08). The lane sits on top |
| **Jumbotron** | `Jumbotron` (30, 10, 3) at (0, 22.5, 12), Graphite Metal (Y 17.5..27.5, between the trusses at Z 4 and 20). It hangs from a Truss-color beam (32, 0.5, 1.2) at (0, 27.75, 12) that touches the roof. Neon edge strips: top Violet, bottom Yellow (30.4, 0.4, 3.2). **South face** (`Face = Back`, +Z, toward spawn): `EARN ESP` Hero + stripe + `LEAGUE HQ · SEASON 1` (TextLabels `Title`, `Line`; `Map.registerJumbotron`). North face (`Front`): `TOP PLAYERS` + 5 rows mirroring the board. With its bottom at Y 17.5 and Z 12, a camera at (0, 9, 62) still sees the RANKED header top (Y 21.5) under it, and sees the Champion screen through the gate |
| Planters + benches | Planter (14, 2.4, 6) Concrete 221,226,234 at (±24, 1.2, 24), with 3 blocky bushes (Grass 94,170,70: cubes 4, 3, 2.5) on top. Benches (`Seat`, Graphite 10x1.2x2.5) at (±24, 0.6, 29) |
| HOW TO PLAY board | Sign Panel (14, 9, 0.6) at (−17, 7.5, 42), rotated 180 (faces +Z, toward spawn), on 2 Steel legs. `HOW TO PLAY` + stripe + 5 numbered rows: `1 Walk onto a pad to queue. Or press PLAY [P].` · `2 Delete every bot to earn Credits.` · `3 Press H to buy and switch cheats.` · `4 New cheats open harder ranks.` · `5 Ban Wave: start over, keep a bonus forever.` |
| Quests kiosk | Graphite box (6, 8, 3) at (17, 4, 42), a screen on its +Z face: `QUESTS` + `DAILY DROP AT THE CAMPSITE`, a Yellow neon top edge. `QuestsPrompt` inside |
| Gate banners (hung from the truss at Z −12) | Chalk banner Parts (8, 9, 0.3) at Y 23 on 2 rods: X −31 `1V1` / `FIRST TO 5`; X 31 infinity (2 ring Frames) / `ENDLESS WAVES`; X −66 `AIM` / `PRACTICE`. Text in Steel-dark (58,64,80), Display |
| **The Stands** (X −80..−40) | Board wall on the west wall's inner face (X −78), all facing +X (`CFrame.new(x,y,z) * CFrame.Angles(0, math.rad(-90), 0)`, Face Front). **MOST BANNED** (18, 13) at (−77.6, 11, −6), top neon Red. **TOP PLAYERS** (26, 16) at (−77.6, 12, 16), top Violet / bottom Yellow. **BEST SURVIVAL** (18, 13) at (−77.6, 11, 38), top Survival lime. Board gui: title (0.05, 0.04, 0.9, 0.12) Display + stripe at y 0.17, then 8 rows `Row1..Row8` (0.06, 0.22 + (i−1)·0.095, 0.88, 0.075) in Row font, left-aligned, ranks 1–3 tinted Gold/Silver/Bronze by RichText. Register with `Map.registerBoard`. Bleachers facing −X: 3 tiers (4 wide, 34 long, Z −1..33) at X −64 (top Y 1.5), −60 (3), −56 (4.5), Slate with a Chalk 0.2 nose strip, seats as `Seat`s on tier tops (6 per tier). Hanging sign `THE STANDS` (16, 3.5, 0.4) at (−40, 20, 16), faces +X, double-sided |
| Atrium back wall | Sign on the south wall's inner face: (40, 10, 0.4) at (0, 16, 62.6), faces −Z (no rotation): `EARN ESP` / `CHEAT YOUR WAY TO THE TOP` (the old tagline, kept as a nod) |
| QueueHost spot | NpcSpot `QueueHost` at (9, 0.1, −14), rotated 180 (faces +Z) |
| Lighting (Map.luau) | Writes `Config.Themes.Lobby` (5.7), `Lighting.GlobalShadows = true`. Technology **Future** (set in Studio Lighting properties). Bloom Size 24, Threshold 1.7. SunRays 0.04. |

**Sight line check:**
- A camera at (0, 7, 62) looking at (0, 6, −63) must see: the lane, the jumbotron above the frame center, the RANKED header (B), and the pink FINAL BOSS screen at the end of the Tunnel.
- Nothing in A may sit inside X −6..6 above Y 0.2 between Z −20 and Z 49, except the jumbotron and its beam (Y 17.5..28).

### 5.5 Zone B: The Tunnel + mode pads (X −80..80, Z −65..−20)
Rooms (partition walls 2 thick centered on X = −48, −14, 14, 48, from Z −63 to −22, 20 tall):

| Room | Interior | Floor / walls |
|---|---|---|
| Practice Range | X −78..−49 | Range Floor / Range Wall |
| Duel Hall | X −47..−15 | Duel |
| **The Tunnel** | X −13..13 | Tunnel |
| Survival Hall | X 15..47 | Survival |
| Quarantine | X 49..78 | Quarantine |

**Facade (Z −22..−20):**
- X −80..40 is 28 tall, HQ Wall color on the Concourse face, with the kick band and HQ stripe.
- X 40..80 is 20 tall in Steel (C clads its side).
- Openings are in 5.3.
- Headers are Sign Panels at Z −19.7, rotated 180:
  - `RANKED` (24, 5) at (0, 19, −19.7), with 5 rank chips (Frames in rank colors with Graphite Display text).
  - `DUEL` (12, 3) at (−31, 15.5, −19.7).
  - `SURVIVAL` (12, 3) at (31, 15.5, −19.7).
  - `PRACTICE` (12, 3) at (−66, 13.5, −19.7).
  - `QUARANTINE · CHEATER ISLAND` (12, 2.5) at (62, 13.5, −19.3), on the Trophy Hall side.
- Each gate gets a neon frame on the Concourse face: two jambs (0.3 x height) and a lintel, in the mode color (Chalk for RANKED and Practice).

**The Tunnel:**
- Floor (28, 1, 45) Tunnel Floor.
- Cladding panels on the inner faces X ±13, alternating Tunnel Panel A/B, each 8 long, Y 0..18.
- Ribs (Tunnel Rib) at Z −24, −32, −40, −48, −56: wall ribs (1, 18, 1.4) at X ±12.5 and a ceiling rib (26, 1, 1.4) at Y 17.5.
- Ceiling slab Y 18..19 Graphite. Roof Y 20..21.
- Lane continuation (8, 0.1, 31) at (0, 0.05, −35.5) with the same Violet/Yellow edges. Chevrons at Z −32, −41, −50 (Z −23 is left clear for the gate light falloff).
- Ceiling light strips: Neon (0.6, 0.2, L) at X ±6, Y 17.8:
  - White (242,244,248) for Z −28..−34
  - Diamond cyan (79,209,255) for Z −34..−48
  - Champion pink (255,61,127) for Z −48..−62
  - no strips for Z −20..−28 (the light falloff)
- **Ranked pads** (8x8 unless noted) and **screens** (Sign Panel 9x6, 0.4 thick, center Y 7):

| Id | Pad center | Screen CFrame | Title / Line |
|---|---|---|---|
| Bronze | (−8.5, −29) | `CFrame.new(-12.8, 7, -29) * CFrame.Angles(0, math.rad(-90), 0)` (faces +X) | `BRONZE` / `NOOB BOTS · +10 CR CLEAR` |
| Silver | (8.5, −29) | `CFrame.new(12.8, 7, -29) * CFrame.Angles(0, math.rad(90), 0)` (faces −X) | `SILVER` / `UNLOCK: ESP BOX` |
| Gold | (−8.5, −42) | `CFrame.new(-12.8, 7, -42) * CFrame.Angles(0, math.rad(-90), 0)` | `GOLD` / `UNLOCK: TRIGGERBOT` |
| Diamond | (8.5, −42) | `CFrame.new(12.8, 7, -42) * CFrame.Angles(0, math.rad(90), 0)` | `DIAMOND` / `UNLOCK: AIM ASSIST` |
| Champion | (0, −56), pad **12x8** | Sign Panel **16x9** at `CFrame.new(0, 9.5, -62.8) * CFrame.Angles(0, math.rad(180), 0)` (faces +Z), halo-style double neon frame, Neon pillars (0.6, 16, 0.6) at X ±9, Z −62.6 | `CHAMPION` / `FINAL BOSS · ADMIN` / `NEEDS AIMBOT` |

  Lines come from `Config.Arenas`: `Requires` gives `UNLOCK: <HACK NAME>`; with no requirement the line is the description + `+<ClearBonus> CR CLEAR`.

**Practice Range:**
- `Practice` pad 8x8 at (−64, −32), Chalk edges. Screen 9x6 at `CFrame.new(-77.8, 7, -32) * CFrame.Angles(0, math.rad(-90), 0)`: `PRACTICE` / `MOVING DUMMIES · FREE`.
- Firing counter (27, 3, 1.5) Steel at (−63.5, 1.5, −46.25).
- Lane dividers (0.4, 3, 13) at X −71, −64, −57, center Z −54.5.
- Static blocky target dummies (Dummy colors: orange 255,140,40 / white) at Z −60, X −74.5, −67.5, −60.5, −53.5. Decor only.

**Duel Hall:**
- Two pads 8x8 with Duel edges, **both `Duel`**: P1 at (−36, −38), P2 at (−26, −38). A SurfaceGui on each PadBase top (Face Top): `P1` / `P2` in Display Chalk.
- Screen 18x9 at `CFrame.new(-31, 9.5, -62.8) * CFrame.Angles(0, math.rad(180), 0)`: `DUEL 1V1` title. The middle is split in two halves, `PLAYER 1` | `VS` | `PLAYER 2` (from the campground reference's Player 1/2 screen), then `Slots` `0/2` and the line `FIRST TO 5 · +150 CR WIN`.
- Bleachers on the west wall: 2 tiers facing +X: X −44..−41 (top Y 1.5) and X −47..−44 (top Y 3), Z −58..−28, with `Seat`s.

**Survival Hall:**
- `Survival` pad **12x12** at (31, −40), Survival lime edges.
- Screen 18x9 at `CFrame.new(31, 9.5, -62.8) * CFrame.Angles(0, math.rad(180), 0)`: `SURVIVAL` / `0/4` / `ENDLESS WAVES · SQUAD OF 4`.
- Barricades: `Kit.sandbags` length 5 at (20, −30), (42, −30), (20, −52), (42, −52), plus 4 crates.

**Quarantine (Cheater Island):**
- `CheaterIsland` pad **14x20** at (64, −44), Red edges.
- Hazard border: alternating Hazard blocks 2x0.12x1 around the pad, 1 stud out.
- Cage: 4 posts (0.8, 10, 0.8) Truss color at the pad corners + 1, rails at Y 5 and 10.
- Screen 18x9 at `CFrame.new(64, 9.5, -62.8) * CFrame.Angles(0, math.rad(180), 0)`: `CHEATER ISLAND` / `0/12` / `EVERYONE HAS EVERYTHING`, and a red lock line `NEEDS 40 CHEATS`.
- Sky window: see doorway 8.

**Lights:** only PointLights on the pads (pad color) + SurfaceLights under the ceiling strips (Range 14, Brightness 0.8, color of the strip). Mode rooms get 2 SurfaceLights each (Range 20).

### 5.6 Zone C: Trophy Hall wing, Fan Market, Campsite, exterior (X 40..80, Z −20..65)
**West wall** (C):
- Z −20..24: solid, 28 tall, HQ Wall color on the Concourse face with the kick band and HQ stripe. The arch is doorway 6.
- Z 24..65: a **glass curtain**:
  - Glass panes (Transparency 0.55, 207,232,255), 28 tall.
  - Truss-colored mullions (1, 28, 2) every 8 studs (Z 24, 32, 40*, 48*, 56, 64; * = door jambs).
  - The Campsite door is doorway 7.

**Trophy Hall** (interior X 42..78, Z −20..24) **= the user's trophy room picture**:
- Floor (40, 1, 46) at (60, −0.5, 3) (Z −20..26), Walnut WoodPlanks.
- Walls:
  - East (2, 20, 44) at (79, 10, 2).
  - South (36, 20, 2) at (60, 10, 25).
  - Inner cladding: lower Walnut Y 0..8 (0.4 thick), a Brass chair rail (0.3) at Y 8, upper Trophy Navy Y 8..20.
  - The cladding skips X 54..70 on the north wall (Quarantine door surround).
- Roof (40, 1, 46) at Y 20.5, Walnut Dark. Beams (36, 1.2, 1.2) Walnut Dark at Y 18.8, Z −16, −8, 0, 8, 16.
- **Carpet runner**: (34, 0.06, 8) at (60, 0.03, 2), Carpet Fabric, with Brass edge strips (34, 0.07, 0.3) at Z −2 and Z 6. It runs straight from the arch.
- **Chandeliers** ×3 at (50, 15.5, 2), (60, 15.5, 2), (70, 15.5, 2):
  - A Brass ring (Cylinder D4, h 0.3, horizontal).
  - 6 candles (0.2, 0.6, 0.2 Chalk) with Neon flames (Ball 0.25, 255,214,140).
  - A chain rod (0.15, 3, 0.15) to the ceiling.
  - A PointLight (255,190,120), Range 22, Brightness 1.3, Shadows true.
- **Boss trophy cases** ×6:
  - Each case: a base (4, 3, 4) Walnut Dark, a glass box (4, 4, 4) Case Glass at Y 5, and a Brass top (4.2, 0.3, 4.2) at Y 7.15.
  - Trophy props sit inside at Y 3.6..6.5.
  - A Brass plaque on the carpet-facing side.
  - A `TrophyPrompt` in the base, with Attribute `BossId`.

  | Position | BossId | Prop | Plaque | Flavor (inspect card) |
  |---|---|---|---|---|
  | (48, −8) | `AimbotAndy` | golden gaming mouse (Foil 255,178,26) + a floating Gold Neon crosshair ring | `AIMBOT_ANDY · GOLD BOSS` | `Never missed a shot. Then he met you.` |
  | (56, −8) | `LagSwitch` | router (2, 0.5, 1.4) Graphite + 2 antennae + 3 cyan Neon LEDs tagged `BlinkLed` | `LAGSWITCH_420 · SILVER BOSS` | `Was here a second ago. Still buffering.` |
  | (64, −8) | `RageHacker` | RGB keyboard (3, 0.3, 1.2) Graphite with 8 Neon keys in Red/Yellow/Mint/Cyan/Violet | `RAGE_H4X0R · DIAMOND BOSS` | `Spins, screams, never misses. You took his keyboard.` |
  | (48, 12) | `Admin` | mini ban hammer: head (2, 1, 1) Chalk with a Champion Neon band, handle (0.3, 2.5, 0.3) Walnut Dark | `ADMIN_ANTICHEAT · FINAL BOSS` | `The league's own anti-cheat. Banned by a cheater.` |
  | (56, 12) | `PatchDay` | empty, a Fog `?` sign | `PATCH DAY · COMING SOON` | `Coming in a future update.` |
  | (64, 12) | `ReportButton` | empty | `THE REPORT BUTTON · COMING SOON` | `Coming in a future update.` |

  Cases at Z −8 face +Z and cases at Z 12 face −Z.
- **Rank trophy row** (graft from the clubhouse pitch):
  - 5 pedestals (3, 3.5, 3) Walnut Dark at X 74.5, Z −10, −4, 2, 8, 14.
  - Each holds a cup: base (1.6, 0.4, 1.6), stem (0.4, 1, 0.4), cup (Cylinder 1.6 x 1.4), and 2 handles, in Foil/Metal in the **rank color**. The Champion cup gets a pink Neon rim.
  - A plaque on each pedestal's −X face shows the rank name.
  - Above them on the east wall: plaque `LEAGUE TROPHIES · SEASON 1` (14, 2.5) at (77.6, 10, 2), facing −X.
- **Plush shelf**: shelf (11, 0.4, 1.6) on the north wall at (48.5, 6, −19.2). It holds 5 blocky plush bots, 1.6 tall, in `Config.BotTypes` colors (Noob, Tryhard, Sweat, Pro, Moderator), at X 44.5, 46.5, 48.5, 50.5, 52.5.
- **Lounge**:
  - Fireplace on the south wall: a Brick (120,70,50) surround (10, 9, 2) at (60, 4.5, 23), a firebox Neon (255,138,61) (4, 3, 0.5) with a `Fire` instance, and a PointLight (255,150,70) Range 20 Brightness 1.5.
  - Mantle in Walnut Dark.
  - Rug (14, 0.05, 8) at (60, 0.02, 19), color (110,40,48).
  - 2 sofas (`Seat` + back, Carpet Fabric 6x2.5x2.2) at (53, 0, 17.5) and (67, 0, 17.5), facing +Z.
- **Curator spot**: NpcSpot `Curator` at `CFrame.new(72, 0.1, 2) * CFrame.Angles(0, math.rad(90), 0)` (faces −X, toward the arch).
- **Concourse-side sign** over the arch: Sign Panel (16, 3.5, 0.4) at `CFrame.new(39.6, 16.5, 2) * CFrame.Angles(0, math.rad(90), 0)` (faces −X), `TROPHY HALL` in Brass Display on Walnut Dark + `CHAMPIONS LOUNGE` Label.

**Fan Market** (the Campsite's north strip, Z 26..34, backs against the Trophy Hall's south wall):

| Item | Spec |
|---|---|
| **SKIN SPIN booth** | Footprint X 44..56, Z 26..34. Counter `SkinSpinCounter` (10, 3.5, 2.5) Graphite at (50, 1.75, 32.5) holds **`SkinSpinPrompt`** (`ActionText "Spin"`, `ObjectText "Skin Spin"`). 4 posts (0.6, 9, 0.6). Awning (12, 0.4, 6) at Y 9 made of 6 stripes 2 wide alternating Stall Red / Chalk. Sign `SKIN SPIN` (12, 3) at Y 11.5 facing +Z + a second sign facing −X (toward the glass wall). Back wall panel (Graphite 12x9) on the Trophy Hall's south face with 4 vertical Neon tubes (0.2, 8, 0.2) in Rare/Epic/Legendary/Mythic colors at X 45, 47.5, 52.5, 55. Shelf (8, 3.25, 3) at (50, 1.625, 28.5). **`SkinSpinStage`**: Cylinder D5 h1 Graphite at (50, 3.75, 28.8) with a Neon ring D5.4 h0.12 on top (the client recolors it). **`SkinSpinCamera`**: `CFrame.lookAt(Vector3.new(50, 6.5, 42), Vector3.new(50, 5.6, 28.8))`. NpcSpot `Vendor` at (46, 0.1, 29.5), facing +Z |
| **PRO SHOP stall** (Store spot) | Footprint X 62..74, Z 26..34. Counter `StoreCounter` (10, 3.5, 2.5) at (68, 1.75, 32.5) holds **`StorePrompt`** (`"Shop"`, `"Pro Shop"`). Awning stripes Yellow / Chalk. Sign `PRO SHOP` + `PASSES · CREDITS · CODES`. Behind it: a pegboard (12, 7, 0.4) Steel on the wall at Y 5 with 6 blocky gun silhouettes (from `guns_wall.png`; Graphite bodies with an accent trim strip), plus a small `CODES` sign on the side |

**The Campsite** (Z 34..65, outdoors, sunny; **the user's campground picture**):
- Floor: Grass slab (40, 1, 39) at (60, −0.5, 45.5). Flowers: 20 blocky flowers (0.6 cubes on 0.2 stems, Red/Yellow/Chalk).
- Path: (16, 0.1, 6) at (50, 0.05, 45), Path color, from the door to the fire.
- Campfire at (60, 0, 52):
  - 8 stones (1.2 cubes, 120,120,125) in a ring of r 2.2.
  - 2 crossed logs, Neon embers, a `Fire` instance, and a PointLight (255,150,60) Range 18 Brightness 2.
  - 4 seat logs (Cylinder D1.4 L5 as `Seat`s) at r 6: (60, 46), (60, 58), (54, 52), (66, 52), turned tangent to the ring.
- Tent: Yellow tent A-frame from 2 wedges, 8 wide, 6 tall, 8 deep, centered (72, 0, 58), door flap 230,170,40.
- Daily Drop crate: (4, 3, 3) ESP Violet at (46, 1.5, 58) with a Yellow Neon latch and **`DailyPrompt`** (`"Claim"`, `"Daily Drop"`).
- String lights:
  - 4 posts (0.4, 9, 0.4) at (44, 36), (76, 36), (76, 62), (44, 62).
  - `RopeConstraint`s (Visible, Thickness 0.08, Color 60,50,40) between the posts.
  - Neon bulbs (Ball 0.5) every 3 studs, alternating 255,236,190 and Yellow, each without a light, plus 2 PointLights at the span middles.
- Blocky trees (stacked green cubes on a brown trunk, campground style) at (76, 44) and (52, 63).
- Fence: `Kit.fence` Wood 3 tall along X 79 (Z 26..64) and Z 64 (X 40..79), plus **invisible walls** (Transparency 1, CanCollide true, 16 tall) on the same lines.
- Zone sign over the door (Concourse side): Sign Panel (14, 3.5, 0.4) at `CFrame.new(39.6, 16.5, 45) * CFrame.Angles(0, math.rad(90), 0)`: `THE CAMPSITE` / `Auto Farm runs while you chill.`

**Exterior** (outside the plot; C):
- Lawn (600, 1, 600) at (0, −0.7, 0), Lawn Grass. Its top is Y −0.2, hidden under every zone floor.
- Sidewalk ring (Concrete 200,204,212, top Y −0.1), 10 wide around the plot.
- 20 blocky trees at radius 100–150.
- **Light towers** ×4 at (±100, 0, ±88):
  - Mast (2, 46, 2) Truss color.
  - Light bank (12, 6, 1.2) Graphite with 8 white Neon panels facing (0, 0, 0).
  - A SpotLight Range 60, Brightness 2, Angle 45.
- **Skyline**: 28 blocks at radius 220–320, about every 13°.
  - Footprint 24–48, height 40–110, colors from (150,160,178) to (98,106,124), SmoothPlastic, CanCollide false, CastShadow false.
  - 2–4 window strips each in Neon (255,236,190) at Transparency 0.5.
- **Floating Cheater Island** at (175, 28, −42), visible through the sky window and from the Campsite:
  - Grass top (40, 4, 34), 3 Rock blocks under it, 4 blocky trees.
  - A Red Neon ring (Cylinder D24 h0.3) and a tiny hazard sign `CHEATER ISLAND`.
- 3 far floating islands (a nod to the old lobby) at (−220, 50, −180), (200, 70, 230) and (−160, 40, 210), each 30–50 wide.
- **Rooftop sign** on the Trophy Hall roof: Sign Panel (30, 7, 1) at `CFrame.new(60, 24.5, 23.5) * CFrame.Angles(0, math.rad(180), 0)` (faces the Campsite). It reads `EARN ESP` + stripe + `LEAGUE HQ`, with Violet top and Yellow bottom neon edges and a SurfaceLight.
- Clouds: `workspace.Terrain` gets a `Clouds` instance with Cover 0.45, Density 0.55, Color white.

### 5.7 Lighting theme (`Config.Themes`; keep the key `Lobby`, replace its values)
```lua
Lobby = { -- League HQ day: cool, crisp, bright hall
	ClockTime = 14.2, Brightness = 2.6, Ambient = rgb(118, 122, 134), OutdoorAmbient = rgb(150, 156, 170),
	Atmosphere = { Density = 0.26, Haze = 0.8, Color = rgb(214, 224, 240), Decay = rgb(120, 134, 168) },
	Tint = rgb(246, 248, 255), Contrast = 0.12, Saturation = 0.1, Bloom = 0.3,
},
LobbyTunnel = { -- dark ranked corridor + mode halls
	ClockTime = 14.2, Brightness = 1.2, Ambient = rgb(52, 56, 70), OutdoorAmbient = rgb(70, 76, 96),
	Atmosphere = { Density = 0.32, Haze = 1.2, Color = rgb(70, 80, 110), Decay = rgb(40, 40, 70) },
	Tint = rgb(236, 238, 255), Contrast = 0.18, Saturation = 0.12, Bloom = 0.8,
},
LobbyTrophy = { -- warm walnut room
	ClockTime = 14.2, Brightness = 1.4, Ambient = rgb(96, 70, 52), OutdoorAmbient = rgb(110, 86, 66),
	Atmosphere = { Density = 0.3, Haze = 1.2, Color = rgb(255, 214, 170), Decay = rgb(140, 96, 70) },
	Tint = rgb(255, 240, 224), Contrast = 0.12, Saturation = 0.08, Bloom = 0.45,
},
```
`Config.LobbyZones` holds `{ Name, Kicker, Title, Line, Theme, Min = Vector2(x, z), Max = Vector2(x, z) }`.
- The first match wins. Concourse is the fallback.
- The client (`Atmosphere.themeName`) uses `Theme` when not in a round and not on Fullbright.

| Zone | Kicker | Theme | Box (X / Z) |
|---|---|---|---|
| THE TUNNEL | ZONE B | LobbyTunnel | X −14..14, Z −65..−20 |
| DUEL HALL | ZONE B | LobbyTunnel | −48..−14, −65..−20 |
| SURVIVAL HALL | ZONE B | LobbyTunnel | 14..48, −65..−20 |
| QUARANTINE | ZONE B | LobbyTunnel | 48..80, −65..−20 |
| PRACTICE RANGE | ZONE B | Lobby | −80..−48, −65..−20 |
| TROPHY HALL | ZONE C | LobbyTrophy | 40..80, −20..26 |
| THE CAMPSITE | ZONE C | Lobby | 40..80, 26..65 |
| THE STANDS | ZONE A | Lobby | −80..−40, −20..65 |
| CONCOURSE | ZONE A | Lobby | −40..40, −20..65 |

ClockTime is the same in all three themes, so the sun never jumps.

### 5.8 Landmarks, sight lines and the sign index
**Landmarks:** you should be able to see at least one from anywhere.

| Landmark | Where | Seen from |
|---|---|---|
| RANKED gate + header | (0, 0..21.5, −20) | spawn, the whole Concourse |
| FINAL BOSS · ADMIN screen + pink pillars | (0, 9.5, −62.8) | spawn, down the lane (110 studs) |
| Jumbotron | (0, 22.5, 12) | everywhere in A |
| TOP PLAYERS board | (−77.6, 12, 16) | the Concourse, through the colonnade |
| Trophy Hall arch + brass sign | X 40, Z 2 | spawn (front right) |
| Skin Spin booth neon tubes + striped awning | (50, *, 30) | the Concourse, through the glass curtain |
| Campfire glow + tent | (60, 52), (72, 58) | the Concourse, through the glass |
| Rooftop sign `EARN ESP · LEAGUE HQ` | (60, 24.5, 23.5) | the Campsite |
| Floating Cheater Island | (175, 28, −42) | the Quarantine sky window, the Campsite |
| Light towers | (±100, 0, ±88) | the Campsite, skylights |

**Sign index** (text, place, owner; details are in 5.4–5.6):

| Text | Place | Owner |
|---|---|---|
| `EARN ESP` / `LEAGUE HQ · SEASON 1` | jumbotron, south face | A |
| `TOP PLAYERS`, `MOST BANNED`, `BEST SURVIVAL` | The Stands wall | A |
| `HOW TO PLAY` (5 lines) | (−17, 7.5, 42) | A |
| `QUESTS` / `DAILY DROP AT THE CAMPSITE` | Quests kiosk | A |
| `THE STANDS` | colonnade (−40, 20, 16) | A |
| `1V1`, infinity, `AIM` banners | trusses at Z −12 | A |
| `EARN ESP` / `CHEAT YOUR WAY TO THE TOP` | atrium back wall | A |
| `RANKED` (+ 5 rank chips), `DUEL`, `SURVIVAL`, `PRACTICE` | facade headers | B |
| `QUARANTINE · CHEATER ISLAND` | Trophy Hall side of the facade | B |
| Every pad screen (Title / Slots / Line) | 5.5 | B |
| `TROPHY HALL` / `CHAMPIONS LOUNGE` | over the arch | C |
| `THE CAMPSITE` / `Auto Farm runs while you chill.` | over the glass door | C |
| `LEAGUE TROPHIES · SEASON 1`, rank plaques, boss plaques | Trophy Hall | C |
| `SKIN SPIN` (×2), `PRO SHOP` / `PASSES · CREDITS · CODES`, `CODES` | Fan Market | C |
| `EARN ESP` / `LEAGUE HQ` | rooftop | C |
| `CHEATER ISLAND` | floating island | C |

### 5.9 Build order and checks (each zone)
1. Floors.
2. Walls with openings.
3. The stripe and kick band.
4. Pads / hero props.
5. Signs.
6. Lights.
7. Decor.

Checks:
- Fly the seams: no gaps or z-fighting at X 40, Z −20, or the plot edge.
- Walk into every pad. `PortalId` must fire and the screen must update via `Map.setPadSlots`.
- `SkinSpinPrompt` and `StorePrompt` appear at 10 studs.
- Part count under budget (`#folder:GetDescendants()` of BaseParts).
- The spawn sight line (5.4).
- Everything shows in Future lighting at ClockTime 14.2.

---

## 6. Effects language (gunplay feel)
Every effect uses palette colors. The code goes in `Effects.luau`, `Gun.luau`, `Esp.luau` and `Viewmodel.luau`.

| Effect | Spec |
|---|---|
| **Your tracer** | Default `Toggles.TRACER_COLORS[1]` warm white (255,236,190), or the player's pick. Neon, 0.09 thick thinning to 0.02, Transparency 0.05, life 0.09s (existing). Shotgun pellets: 0.05 thick, 0.06s. Sniper: 0.14 thick, 0.18s, plus a ghost line at Transparency 0.6 for 0.4s. Minigun: every 2nd bullet. |
| Cheat tracers | **Magic Bullet** curve: Violet (139,92,255), 0.3s (existing curve). **Silent Aim** bent shot: Violet. **Wallbang**: Violet, plus 6 Violet pixels where it exits the wall |
| **Bot tracers** | Enemy pink-red (255,107,120), 0.05 thick, Transparency 0.35, 0.07s. Moderators: Blue (61,139,255). Bosses: Aimbot_Andy Gold (255,178,26); LagSwitch Diamond cyan (79,209,255) drawn as 2 offset segments (stutter); RAGE Red (255,59,78); Admin Champion pink (255,61,127) |
| **Muzzle flash** | `Effects.flash` warm (255,214,140). Size 0.6 (pistol/SMG/rifle), 0.9 (shotgun/sniper/revolver), 1.2 (rocket), minigun 0.7 on 50% of shots. PointLight Range 10, Brightness 3, 0.05s. Legendary and better skins add a second, 0.35 flash in the skin's `Accent` color |
| **Impact, world** | Sparks (255,210,120) + dust + bullet hole (22,22,22), as existing |
| **Impact, enemy** | Replaces the red spray with a **pixel hit**: 8 Chalk square pixels (PIXEL_TEXTURE, size 0.25→0) + 4 in the ESP color. Headshot: 12 Yellow pixels + `Headshot` cue |
| **Hitmarker** | Body Chalk · headshot Yellow · kill Red (4.6) |
| **Damage numbers** | Num 18 Chalk / headshot Num 22 Yellow + `HEADSHOT`; decoy hit shows `DECOY` in BlueText (bullets pass through) |
| **Kill: bot** | "Deleted": the body flashes Chalk for 0.05s, then dissolves into 30 pixels in the **ESP color** rising (Effects.pixels). A world `+N CR` (Num 16 Mint) rises 3 studs over 0.8s |
| **Kill: boss** | "Banned": a BillboardGui stamp 8x3 studs over the boss: a 3px Red stroke, `BANNED` Display Red, rotated −8°, punching 1.6→1 over 0.18s, holding 1.2s. 80 pixels mixed Red/Chalk. `BanGavel` cue. The kill banner reads `BOSS BANNED` |
| **Kill: Moderator** | Blue pixels + reversed `Whistle`; banner `MOD DELETED` in BlueText |
| **Bot spawn** | 30 Chalk pixels converging over 0.5s + a 0.3s white floor ring (Neon cylinder D4, Transparency 0.4→1) |
| **ESP (Esp.luau)** | Corner box 2px in the ESP color (Ls = 28% of the short side), with a 1px Ink outline. Health rail 4px left of the box (Mint >60%, Yellow >30%, Red otherwise). Name tag: Graphite @0.15 backplate, Row 10 Chalk. Distance `52m` Num 10, with `· WALL` in VioletText when blocked. Head dot 6px in the ESP color. ESP Line: 1px ESP color @0.4 from bottom-center. Skeleton 1.5px @0.2. Chams `Highlight`: Glow FillTransparency 0.75 / Outline 0; Outline Fill 1 / Outline 0; Solid Fill 0.35; Ghost Fill 0.85 / Outline 0.6. **Moderators always get a Blue `MOD` tag; bosses get a Red `BOSS` tag and their name in Display.** Decoys draw at 60% opacity. Rank Reveal adds a tag in the bot's rank color plus exact HP |
| **Jam** | From the Moderator: a Blue Neon ring (cylinder D2→24 over 0.35s, Transparency 0.4→1) + `Whistle`. On the player: blue vignette + JAMMED banner + Blue switches |
| **Disarm** | The viewmodel drops 15° and desaturates (gun parts lerp 50% to Steel) + DISARMED banner |
| **Admin hammer** | Windup: a floor ring (Neon cylinder D = 2·Radius, 0.1 thick) going from Champion to Red, pulsing Transparency 0.7↔0.4 for 1.2s. Slam: a white flash ball D6, a Red shockwave ring growing to D52 over 0.25s, a camera shake of 2 studs for 0.3s inside the radius, `BanGavel` |
| **Low HP** | Red vignette pulse (existing), now in `Ui.C.Red` |
| **Round start** | `GO` punch (4.5) + the arena spawn pad's neon in the rank color for 1s |
| **Server cleared** | A 60-pixel burst of Chalk + Violet + Yellow at the player + the SERVER CLEARED banner |
| **League kit in arenas** (optional, Map.buildArena) | A spawn pad in the lobby-pad style with the rank color, a wall server screen `SERVER 07 / SHIPPING YARD / BRONZE`, 2 vertical league banners with the stripe, and an anti-cheat camera prop (a box with a Neon dot going from Blue to Red as SUS rises) |
| **Cast colors** | Moderators keep the referee Blue torso (33,84,185) and white arms (existing). The Admin keeps white + red and gets a Champion-pink Neon belt |

---

## 7. Reference map (which picture each part comes from)
| Reference | Becomes |
|---|---|
| `refs/ui/queue_ranked_corridor.png` | **The Tunnel**: dark panels, pads in bays, big 0/1 wall screens, violet-left / yellow-right lane lines, white floor chevrons, ceiling strips. Also the count chip and the two-bar stripe used everywhere |
| `refs/ui/queue_hall_banners.png` | **The Concourse**: white hall, trusses, skylights, banners over the gates (1V1, infinity), floor pads with ring icons. Its bottom "Join the queue" toast became the tip pill |
| `refs/ui/lobby_trophy_room.png` | **The Trophy Hall**: walnut floor and walls, ceiling beams, chandeliers, carpet runner, glass cases, plush figure shelf, navy back wall |
| `refs/ui/lobby_campground.png` | **The Campsite + Fan Market**: yellow tent, campfire with logs, striped market stall (Skin Spin booth and Pro Shop awnings), blocky grass, trees and flowers, string lights. The Player 1 / Player 2 screen became the Duel screen; the ranks board became the board style |
| `refs/ui/styles_spin_screen.jpeg` | **Skin Spin** layout: rarity cards left, item center under a name header, odds + pity right, big SPIN bottom-center. The beveled glow frames are replaced by flat graphite cards with a rarity rail |
| `refs/ui/store_cards.png` | **Store** cards: saturated art tiles, `NEW!` corner tags, price pills, featured card. Color stays inside the art tile |
| `refs/ui/cheat_menu_mobile.png` | Cheat menu bones: tabs down the left, rows of named switches, ESP color swatches in a settings column; the mobile compact layout |
| `refs/ui/script_hub_dark.png` | The calm dark sidebar + content layout, compact rows, the search field, section sub-headers (`YOURS` / `BUY`), value rows (dropdowns) |
| `refs/ui/aimbot_menu_purple.png` | Violet as THE cheat color, **group boxes with labels on the border**, slider rows, the keybind row, the big wordmark title (`CHEATS` on the stripe) |
| `refs/guns_blocky_roblox.png`, `refs/guns_wall.png` | The Pro Shop pegboard of guns, gun previews in the Guns tab, the HUD skin tag + gun name |
| `refs/ui/current_lobby.jpeg`, `refs/game_*.jpeg` | Kept: rank colors (updated), the 0/1 pad screens, the HUD's information (CR, HP, ammo, timer, info bar, watermark, which is now the status pill). Replaced: the floating plaza, the portal row, pink-everything UI |
| `direction/pitch_clubhouse` (graft) | Rank trophies on pedestals + the trophy inspect card with REMATCH / SET AS TITLE |
| `direction/pitch_wildcard` (graft) | Keycap hints: 1–5 on tabs, ENTER/SPACE inside GO buttons, keycap footers |
| `direction/pitch_fiction` (graft) | Letterbox bars on the round intro; blue `JAM` / `PATCHED` badges on tabs |

---

## 8. Keep-every-feature checklist and suggested ownership
**Existing features → new home:**

| Existing feature | New home |
|---|---|
| CHEATS [H] / BAN WAVE / GUNS / SKIN SPIN / STORE buttons | dock (4.1) |
| PLAY panel + rank cards + PLAY button | Play menu (4.2) + pads |
| Practice / Duel queue and "SEARCHING... (CANCEL)" | Play menu + Duel pads |
| Hack rows: buy, switch, requires/locked, hotkey names, upgrade + LV | 4.4.1 / 4.4.2 |
| Search, Legit/Rage/Off presets | header (Custom added) |
| ESP color, tracer color, Chams Style, Target Priority, Aimbot Hitbox | detail groups |
| Anti-cheat status | status chip |
| Quests with progress + rewards | Quests tab + lobby card |
| Ban Wave (cost, multipliers, confirm) | Ban Wave tab, hold button |
| Store pass (2× Credits) + promo codes | Store tab + Pro Shop |
| Guns tab (buy, equip, stats, SKIN SPIN button) | 4.4.3 |
| Skin Spin (rarity list, odds, pity, spin, cost, duplicates refund, click to equip, back) | 4.3 |
| Credits pill + popup | HUD wallet |
| HP number + bar + lag bar + low-HP vignette | HUD |
| Ammo, max, reloading, infinite, weapon name | HUD |
| Timer, round info bar (rank, map, wave, left, modifier, duel score, practice) | match bug |
| Watermark (FPS, ms, SUS) | status pill |
| Kill feed | HUD |
| Boss bar | HUD |
| Radar | HUD |
| Crosshair with spread, FOV circle, hitmarker, damage numbers, damage arrows | HUD |
| 3-2-1 countdown | round intro ring |
| Sniper scope | HUD |
| Jam / disarm warning | jam banner (now blue) |
| `Hud.notify` banners | toasts + banners |
| Active hacks list | arraylist + cheat tray |
| Mobile CHEATS + FIRE buttons | mobile set (4.6) |
| Stats line (Bans, Damage ×, Credits ×) | wallet chip + Ban Wave footer |
| Leaderboards TOP PLAYERS / MOST BANNED | The Stands + jumbotron |
| HOW TO PLAY board | Atrium |
| Lobby spawn / `Map.lobbySpawn` | 5.4 |
| `Map.portals` + `setPadSlots` | 5.2 |
| `SkinSpinPrompt` + Skin Vendor / Curator / Queue Host NPCs | 5.6 / 5.4 |
| Lobby lighting theme fade | 5.7 |

**Suggested agent split** (8 agents; each owns only its files):
1. **UI Kit**: `client/Ui.luau` (tokens + every component in section 3), and the token parts of `shared/Config.luau` (Sounds) and `client/Toggles.luau` (colors, number settings, keybinds).
2. **Cheat Menu**: `client/HackMenu.luau` (4.4, all tabs).
3. **Lobby UI**: `client/PlayMenu.luau`, `client/SkinSpin.luau`, a new `client/LobbyHud.luau` (dock, quests card, wallet, tip pill, queue card, zone titles, prompts, trophy card), and the zone themes in `client/Atmosphere.luau`.
4. **Match HUD**: `client/Hud.luau` (status pill both modes, 4.5–4.7, toasts via `Ui.toast`).
5. **Gunplay feel**: `shared/Effects.luau`, plus effect hooks in `client/Gun.luau`, `client/Esp.luau`, `client/Viewmodel.luau` (section 6).
6. **Lobby Zone A**: `server/Map.luau` (contract 5.2, lighting 5.7, removing the old lobby) + `server/Lobby/ZoneA.luau`.
7. **Lobby Zone B**: `server/Lobby/ZoneB.luau` + `server/Portals.luau` (pad flow).
8. **Lobby Zone C**: `server/Lobby/ZoneC.luau` (Trophy Hall, Fan Market, Campsite, exterior).

Agents 2–5 use only `Ui.*` components and `Ui.C` / `Ui.F` / `Ui.T` tokens, never raw colors or Enum fonts. Agents 6–8 use only the world palette (2.1) and the contract (5.2).
