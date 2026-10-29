# Feel: movement, camera and atmosphere

What this adds, Rivals-style and arcade:

- **Slide**: press **C** or **Left Ctrl** (gamepad R3) while running.
  - You get a burst to your run speed + 18 that bleeds off over about 0.6 s. The camera drops and leans, the view punches wider, dust kicks up and a whoosh plays. With Speed Hack on, violet sparks fly.
  - Jump out of a slide and you keep the speed for the jump. It works with Bunny Hop, Speed Hack and Low Gravity. Sliding into a wall ends the slide.
  - Press slide just before you land, or just before it's ready again, and it starts the moment it can.
  - A frame or two off the ground (a stair edge, a part seam, a ramp crest) doesn't end the slide.
- **Balance**: the slide is a burst, not free speed, so the paid hacks stay worth buying.
  - The boost is always from your run speed, never your current speed, and the speed you keep after a slide is capped at the same number. Chains can't stack.
  - A new slide needs 1.25 s since the last one *started* (and 0.45 s since it ended).
  - In the test, chained slide-hops with no hacks top out at 34 studs/s and average 25.2. Bunny Hop alone tops out at 25.6, and Speed Hack runs at 30 to 45. With a fully upgraded Speed Hack (45), slide-hops top out at 63. The 72 cap holds with Bunny Hop on top.
- **Camera**:
  - a landing dip measured against your own jump: landing a normal jump, a Super Jump or a Low Gravity hop is a small dip; only falls from higher than your jump get the big dip, the shake and the thump
  - a light head bob and a lean when you strafe (first person only), both calmer while you aim down sights
  - footsteps and bob top out at about 5 steps a second, so Speed Hack doesn't buzz
  - a wider view when you go fast: Speed Hack, slides, hop chains and flying
  - when you get shot, the view is knocked away from the shooter and shakes, scaled by the damage (one knock per hit)
  - a small kick on a real jump, a warp kick on Teleport, and a quick FOV "drop in" when a round starts
- **Sounds**: footsteps timed to your steps (quieter when you move slowly, a little higher-pitched when fast), plus jump (only real jumps, not Spider climbs or ramp crests), land, hard land, slide start and a slide whoosh loop. All of them use Roblox built-in sounds and have slots for Creator Store ids (see below).
- **Atmosphere**:
  - the lobby's base lighting is STYLE.md 5.7's `Config.Themes.Lobby` / `LobbyTunnel` / `LobbyTrophy`; this adds STYLE's bloom size 24, threshold 1.7 and sun rays 0.04, and a soft depth of field on the Concourse only (sharp out to 115 studs, so the FINAL BOSS gate stays crisp from spawn)
  - every League HQ zone (`Lobby*`) counts as the lobby: walking Concourse → Tunnel → Trophy Hall is a smooth fade with no dip, and the sun never jumps
  - per-map sun rays, bloom size and glow threshold, exposure and haze glare, worked out from each `Config.Themes` entry
  - joining starts on the lobby look instead of fading into it
  - moving between the lobby (any zone) and a round is a quick dip to dark and back that lines up with the teleport
- **Lobby camera**: after a round (and on join), the camera eases out of first person and turns toward the queue area instead of snapping there.
- **CameraFx** (the shared camera layer) is improved. Every function keeps its meaning. Shakes, tilts and offsets are now truly visual: they no longer leak into your aim. The old version let Roblox's camera script read the shaken camera back each frame, so shakes added up into aim drift (a test checks this). New: `punch`, `bump`, `zoom`, `clear`.

Every existing hack still works: Fly, Noclip, Teleport, God Mode, Spinbot and Anti-Aim, Spider, Super Jump, FOV Changer, Speed Hack, Bunny Hop, Infinite Jump and Low Gravity. The lobby and round camera modes also still work.

## 1. Copy these files

All four are in this repo's `src/client/`:

| File | What it is |
|---|---|
| `src/client/CameraFx.luau` | Replaces the shared CameraFx (same functions, plus extras) |
| `src/client/MoveFeel.luau` | New: slide, momentum, camera bob, lean, landing, hits, footsteps, viewmodel slide pose |
| `src/client/LobbyCam.luau` | New: the lobby camera glide and the round drop-in |
| `src/client/AtmosphereFeel.luau` | New: lobby zone handling, per-map extras, lobby depth of field, the lobby/round dip |

The hooks below go in `Main.client.luau`, `Movement.luau` and `Atmosphere.luau`, plus 4 in
`Viewmodel.luau` (listed in [GUNPLAY.md](GUNPLAY.md), hooks 9 to 12). `patches/feel.diff` has
the same changes as a diff against the older files they were written on. On newer files, add
the hooks by hand. Every changed line has a comment containing `feel:`, or sits inside a block
that starts with one.

## 2. Hooks

### `src/client/Main.client.luau` (5 hooks)

**a.** After this line:

```lua
local Atmosphere = require(script.Parent.Atmosphere)
```

insert:

```lua
local CameraFx = require(script.Parent.CameraFx) -- feel: the shared camera effects layer
local LobbyCam = require(script.Parent.LobbyCam) -- feel: smooth lobby camera and round drop-in
```

(If the `CameraFx` require is already there, keep just one.)

**b.** Replace this line (a bug in this older copy: `Gun.start` uses `isMenuOpen`, so holding the Sniper in a round errored every frame):

```lua
Gun.start()
```

with:

```lua
-- feel: was `Gun.start()`; Gun.start needs isMenuOpen, or holding the Sniper in a round errors every frame
Gun.start(HackMenu.isOpen)
```

Skip this if your Main already passes something to `Gun.start`.

**c.** After this line:

```lua
Atmosphere.start()
```

insert:

```lua
CameraFx.start() -- feel: recoil kicks, shakes, slide and landing camera all go through this
```

`CameraFx.start()` is safe to call twice, so it doesn't matter if something else calls it too. It must run, though: punches and kicks only move while it runs.

**d.** In `updateCameraMode`, after this line in the `InRound` branch:

```lua
		task.delay(0.1, faceArena)
```

insert:

```lua
		LobbyCam.enterRound() -- feel: quick FOV drop-in as the round starts
```

In the newer Main, put this line **before** any Third Person (V) camera setup in that branch. `enterRound` only puts `CameraMinZoomDistance` back if `enterLobby` raised it, so it won't undo the Third Person hack's own zoom limits. Keeping it first means the Third Person setup always has the last word anyway.

**e.** In `updateCameraMode`'s `else` (lobby) branch, **replace** these lines:

```lua
		player.CameraMinZoomDistance = 12
		task.delay(0.15, function()
			player.CameraMinZoomDistance = 0.5
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				workspace.CurrentCamera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 5, 12), root.Position + Vector3.new(0, 2, -10))
			end
		end)
```

with:

```lua
		-- feel: replaces the zoom-out and the camera snap that were here; LobbyCam eases out and turns toward the queue area
		LobbyCam.enterLobby()
```

Leave the `player.CameraMode = Enum.CameraMode.Classic` line above it alone. The newer Main has a Third Person hack (V). If its lobby branch looks different, put `LobbyCam.enterLobby()` where the camera used to be zoomed out and turned. It does the same job: it pushes the zoom out to 13, then turns the camera toward the queue area over 0.9 s and puts the zoom limit back to 0.5.

### `src/client/Movement.luau` (5 hooks)

**a.** After this line:

```lua
local Targets = require(script.Parent.Targets)
```

insert:

```lua
local CameraFx = require(script.Parent.CameraFx) -- feel: FOV goes through CameraFx so zooms and punches add up
local MoveFeel = require(script.Parent.MoveFeel) -- feel: slide, momentum, camera bob/lean/landing, footsteps
```

**b.** In `teleport()`, after this line:

```lua
	Effects.sound("Teleport")
```

insert:

```lua
	MoveFeel.teleported() -- feel: warp kick on the camera
```

**c.** Right after this line:

```lua
function Movement.start()
```

insert:

```lua
	MoveFeel.start() -- feel: slide key, footsteps, landing and hit camera
```

**d.** After this line:

```lua
		humanoid.WalkSpeed = baseSpeed * (1 + hopBonus)
```

insert:

```lua
		humanoid.WalkSpeed = MoveFeel.walkSpeed(humanoid.WalkSpeed) -- feel: slides and the speed kept from them
```

It must come **after the last line that sets `humanoid.WalkSpeed`** in that frame. If your newer Movement multiplies by a gun's `Walk`, for example, put it after that. MoveFeel works out the slide cap from the number it's given here (run speed + 18, at most 72).

**e.** **Replace** this line:

```lua
		workspace.CurrentCamera.FieldOfView = if roundActive and Toggles.isOn("FovChanger") then 95 else 70
```

with:

```lua
		-- feel: was `FieldOfView = if ... then 95 else 70`; CameraFx.fov adds ADS zoom, speed and punches on top,
		-- feel: and a Scriptable camera (Skin Spin, cutscenes) sets its own FieldOfView while it runs
		if workspace.CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then -- feel: skip while Scriptable
			workspace.CurrentCamera.FieldOfView = CameraFx.fov(if roundActive and Toggles.isOn("FovChanger") then 95 else 70)
		end -- feel: end of the Scriptable check
```

If your newer line picks a different base (a scope FOV, a setting), keep that choice and just wrap it in `CameraFx.fov(...)`. Gunplay zooms with `CameraFx.setFovScale("GunAim"/"GunScope", ...)`, which only works through this wrap. Only one place should set `FieldOfView`, apart from a Scriptable camera (see section 4).

### `src/client/Atmosphere.luau` (4 hooks)

**a.** After this line:

```lua
local Toggles = require(script.Parent.Toggles)
```

insert:

```lua
local AtmosphereFeel = require(script.Parent.AtmosphereFeel) -- feel: lobby zones, richer map looks, lobby <-> round dip
```

**b.** In `applyTheme`, after this line:

```lua
	local theme = Config.Themes[name] or Config.Themes.Lobby
```

insert:

```lua
	theme = AtmosphereFeel.prepare(name, theme) -- feel: lay AtmosphereFeel.LOOKS over the theme (and start on it when joining)
```

**c.** In `applyTheme`, right after the Bloom tween block, which ends with:

```lua
	if bloom then
		TweenService:Create(bloom, FADE, { Intensity = theme.Bloom }):Play()
	end
```

insert:

```lua
	AtmosphereFeel.apply(name, theme) -- feel: sun rays, bloom size, exposure, lobby depth of field, lobby <-> round dip
```

**Rain and other modifiers:** put this line right after the Bloom block and **before** any modifier code (the newer Rain modifier) that tweens `Lighting`, `Atmosphere`, `ColorCorrection` or `Bloom`. On a lobby/round switch, `apply` starts quick tweens on those same properties. In TweenService the newest tween on a property wins, so the modifier's tweens must come after it. If Rain only changes the `theme` table before the base tweens, that works too.

**d.** In `Atmosphere.start()`, after this line:

```lua
	applyTheme(themeName())
```

insert:

```lua
	-- feel: switch the moment you enter or leave a round, so the lighting change lines up with the teleport
	player:GetAttributeChangedSignal("InRound"):Connect(function()
		applyTheme(themeName())
	end)
```

(The 0.25 s poll stays for Fullbright, modifiers and walking between lobby zones. The server sets `ArenaTheme` before `InRound`, so the right theme is already there.)

### `src/client/Viewmodel.luau` (4 hooks)

These are in [GUNPLAY.md](GUNPLAY.md) as Viewmodel hooks 9 to 12, so Viewmodel has one list.
Without them, the gun bobs at slide speed. `MoveFeel.SLIDE.GunDrop` and `GunRoll` tune the
slide pose.

## 3. Sounds: slots for Creator Store ids

All in `MoveFeel.SOUNDS` (top of `src/client/MoveFeel.luau`). Paste an id like `Id = "rbxassetid://1234567890"`, then tune `Volume` and `Speed`. `Vary` is the random pitch change each time (0.1 means up to 10%).

| Slot | Now (built in) | What to look for |
|---|---|---|
| `Footstep` | `action_jump_land.mp3` at 1.8x, quiet | A short single sneaker step on concrete (one step per file, not a loop) |
| `Jump` | `action_jump.mp3` | A light cloth/shoe "hup" or swoosh |
| `Land` | `action_jump_land.mp3` | A short soft landing thud |
| `HardLand` | `action_jump_land.mp3` at 0.72x | A heavy landing thump with a bit of debris (only for falls from higher than your jump) |
| `SlideStart` | `action_jump_land.mp3` at 1.45x | A shoe scuff, the moment you drop into a slide |
| `Slide` (looped) | `action_falling.mp3` at 1.7x | A fabric or gravel slide scrape, loopable. It fades with the slide's speed. |

Your own character's default Roblox `Running`, `Jumping` and `Landing` sounds are routed to a muted SoundGroup, so they don't double up with these. Other players keep theirs. `FreeFalling`, `Climbing`, `Swimming` and `Died` are untouched. The `Jump` sound plays on the Humanoid's Jumping state from the ground; Infinite Jump's air jumps keep Movement's own `Effects.sound("Jump")`.

Two optional slots: `MoveFeel.SLIDE.Animation = "rbxassetid://..."`, a slide animation you own, so other players see a slide instead of fast running; and the `QueueFocus` tag (below).

## 4. Studio settings and knobs

- **Lighting > Technology = Future** in Studio. Scripts can't change it, and the League HQ look and bloom thresholds assume it.
- **Lobby lighting comes from `Config.Themes`** (STYLE.md 5.7: `Lobby`, `LobbyTunnel`, `LobbyTrophy`, all at ClockTime 14.2). That is the one source of truth. These hooks don't change Config. While Config is still the old one (no `LobbyTunnel` key), `AtmosphereFeel` lays STYLE 5.7's `Lobby` values over the old warm sunset lobby, so the game already looks right. Once Config has the League HQ lobby themes, that stand-in switches itself off. When STYLE 5.7 changes, change Config, then `LEAGUE_HQ` in AtmosphereFeel only if you still run an old Config.
- **Lobby zones:** any theme name starting with `Lobby` counts as the lobby (`AtmosphereFeel.isLobby`). Walking between zones fades the extras along with Atmosphere's own 1.2 s fade. Only lobby ↔ round gets the quick dip. If the newer Atmosphere names a zone theme without the `Lobby` prefix, rename it or extend `isLobby`.
- **Extras per place:** `AtmosphereFeel.LOOKS` (`BloomSize`, `BloomThreshold`, `SunRays`, `Exposure`, `Glare`, `DepthOfField`).
  - `Lobby` (the Concourse) has STYLE's bloom size 24, threshold 1.7 and sun rays 0.04, plus the depth of field.
  - `LobbyTunnel` has no sun rays, glare or blur, so the pads read.
  - `LobbyTrophy` gets a little brass glow.
  - Themes not listed get values from their brightness and ClockTime.
  - Depth of field is only ever on in the lobby. It's switched off in rounds, so it can't blur enemies.
- **Queue area for the lobby camera:** by default it's the average of the parts named `PadBase` (League HQ pads), `PortalField` (old lobby), `QueuePad` or `RankPad` under `workspace.Lobby`. If there are none, it's straight north (-Z), which is where the ranks are in both the old lobby and League HQ. To choose it exactly, tag one part at the RANKED gate (about `(0, 10, -20)`) with the CollectionService tag **`QueueFocus`**.
- **Skin Spin and other scripted cameras:** STYLE 4.3 tweens the Skin Spin camera to FieldOfView 40. While `CameraType` is `Scriptable`, Movement no longer writes FieldOfView, so that tween works as written. If a scripted camera keeps `CameraType = Custom` instead, zoom with `CameraFx.setFovScale("SkinSpin", 40 / 70)` and clear it with `CameraFx.setFovScale("SkinSpin", nil)`. Don't set FieldOfView directly then.
- **Slide numbers:** `MoveFeel.SLIDE`:
  - `Boost` (18): run speed + this, which is also the most you keep after a slide. `MaxSpeed` (72) caps both.
  - `Friction`.
  - `MaxTime`.
  - `Cooldown` (0.45 s after it ends) and `Recharge` (1.25 s from one start to the next). Lowering `Recharge` makes slide-hop chains faster on average; at 1.1 they average 26.4 with no hacks, above Bunny Hop's best.
  - `Buffer`.
  - `AirGrace` (0.1 s off the ground before a slide counts as leaving it).
  - `CameraDrop`, `Tilt`, `FovPunch`, `GunDrop`, `GunRoll`, `Keys`.
- **Speed kept after a slide jump:** `MoveFeel.MOMENTUM` (`AirDecay` 8 studs/s per second in the air, `Grace`, `GroundDecay`).
- **Camera:** `MoveFeel.CAMERA` (bob, `MaxSteps` footsteps a second, strafe lean, fast-FOV, landing dip and nod for falls above your jump, hit knock and shake, `ThirdPerson` strength).
- **Keybinds** (newer PC version): to make the slide rebindable, add a "Slide" entry to your Keybinds module. Then change `isSlideKey` in MoveFeel to ask Keybinds instead of `MoveFeel.SLIDE.Keys`. It's one small function near the top.
- **Phones**: there's no slide button yet (that belongs in the HUD). A button only needs to call `MoveFeel.slide()`.

## 5. CameraFx notes (for every system that moves the camera)

Unchanged:
- `kick`, `shake`, `punchFov`, `setTilt`, `setOffset`, `setFovScale`, `fov`
- `setFovScale(name, 1)` and `setFovScale(name, nil)` both remove a zoom.

Changed:
- `fov()` now clamps to 1..120.
- Shakes use smooth noise (a rattle, not per-frame flicker), fade out faster at the end, and add a little roll.
- How visual effects stay visual: CameraFx binds a second step at `RenderPriority.Camera - 2` that takes last frame's visual extras off the camera before anything else reads it. It skips that if something else moved the camera in between (a teleport, `faceArena`, the aimbot), so those are never undone. Something that turns the camera itself before Roblox's camera scripts should bind at `Camera - 1`, so it turns the clean camera.

New:
- `CameraFx.punch(pitch, yaw, roll)`: a springy knock in degrees. Positive pitch looks up, positive yaw turns left, positive roll leans left. Each value is about the peak.
- `CameraFx.bump(studs)`: a springy drop straight down.
- `CameraFx.zoom(except)`: the held zoom product (MoveFeel uses `zoom("Speed")` to calm bob, lean and speed-FOV while you aim down sights).
- `CameraFx.clear()`: drops everything, including other systems' held zooms. Only use it for a hard reset.

Render order:

| Priority | What runs |
|---|---|
| `Input + 1` | MoveFeel |
| `Camera - 2` | CameraFx restore (takes last frame's extras off) |
| `Camera - 1` | LobbyCam glide (only while gliding) |
| `Camera` | Roblox's camera scripts |
| `Camera + 1` | CameraFx and Aim |
| `Camera + 2` | Viewmodel (reads `MoveFeel.viewmodelPose()`, set at `Input + 1`) |

Names MoveFeel holds in CameraFx:
- offsets: `Slide`, `Bob`
- tilts: `Slide`, `Bob`, `Strafe`
- FOV scale: `Speed`

Nothing else should use those names.

MoveFeel exports for other modules: `slide()`, `isSliding()`, `runSpeed()`, `viewmodelPose()`, `walkSpeed(normal)` (Movement only), `teleported()`.

If the HUD also shakes the camera on `Remotes.Damaged`, keep only one of the two (MoveFeel's is in `onDamaged` and `onHealthChanged`). A hit that comes with `Damaged` gets one directional knock. A health drop with no `Damaged` (an explosion, a duel hit) gets a small nod 0.06 s later.

## 6. Test

From this repo's root, on a copy of the game's `src` with these hooks and GUNPLAY.md's added:

```sh
EARNESP_SRC=/path/to/hooked/src MODELS_SRC=src tools/preview/gui.sh tools/preview/tests/feel_screens.luau out/feel
```

`feel_screens.luau` boots the real client (Main.client) and checks the movement, camera and lighting numbers in 8 screens:

| Screen | What it covers |
|---|---|
| `FeelJoinLobby` | STYLE 5.7 lighting from the first frame (ClockTime 14.2, brightness 2.6, bloom 0.3 / 24 / 1.7, sun rays 0.04, blur sharp to 115 studs); the glide ends facing the portals at about -9 degrees |
| `FeelRoundSlide` | run; slide (C and Left Ctrl) capped at run speed + Boost; the gun pose; 4 frames off the ground keep the slide; cooldown refusal right after a slide; slide jump keeps capped speed; the jump sound comes from the Jumping state; normal landing isn't hard; wall stop; a 40-stud fall is hard; head bob; a hit from the right leans left; strafe lean, calmer while aiming |
| `FeelRoundHacks` | full Speed Hack (45) + Bunny Hop + Super Jump + Low Gravity hop chains widen the view, stay under 72 and never count as hard landings; footsteps at 45 studs/s are about 5 a second; slide on top of Speed Hack, capped; FOV Changer, Spinbot, Fly (Left Ctrl doesn't slide while flying), Noclip, God Mode, Teleport kick |
| `FeelRoundGunplay` | the Rifle plus SMG, Shotgun, Sniper, Minigun and Rocket fire, reload and swap while running and sliding; hit confirms; held zoom; recoil kicks |
| `FeelCameraNoDrift` | 1 s of shakes, punches, bumps, rotated offsets and tilts leave aim exactly where it was; a kick of 5 keeps 40% |
| `FeelBackToLobby` | Night round lighting and exposure; no depth of field in rounds; the instant switch on round end; the camera turning back to the queue area; Fullbright; a round start leaves someone else's zoom limit alone |
| `FeelSlideChain` | 6 mashed slide-hops with no hacks: top 34, average under 25.6, never faster than `Recharge`; 5 with full Speed Hack: top 63 |
| `FeelLobbyZones` | Concourse ↔ Tunnel ↔ Trophy Hall: no dip, the Tunnel has no blur or sun rays, the Concourse blur comes back; Tunnel → round and round → Tunnel get the dip; no blur in rounds |

The preview has no physics or camera scripts, so the file adds stand-ins: a tiny physics step (MoveDirection × WalkSpeed, the slide and fly constraints, gravity, jumping that fires the Humanoid's Jumping state, an optional wall, and optional "floor lost" frames) and a stand-in for Roblox's ClassicCamera.

Each screen fails if `Client.errors()` isn't empty or a check fails. All 8 pass. They pass with the GUNPLAY.md hooks added too, including the 4 slide hooks in Viewmodel.
