# Gunplay: hooks to add

This makes shooting feel good: recoil through CameraFx, aim down sights, a
springy first-person gun with real reload, bolt and pump animations, gun sounds per
class, and better shot effects. Almost all of it lives in **new modules**. The
existing files only get small hooks, and every hooked line or block has a comment with `feel:`
(`grep -n "feel:"` finds all of them: 21 in Gun, 12 in Viewmodel, 4 in Effects).

The hooks were written against an older copy of the game. To add them to the game:

1. Copy the 5 new modules (and the rest of `src/client` from [FEEL.md](FEEL.md)).
2. Add the hooks below to Gun.luau, Viewmodel.luau and Effects.luau. Each hook says
   which existing line it goes after or replaces. `patches/gunplay.diff` has the same
   changes as a diff against the older files; `git apply --3way` may take most of it,
   but check each hook by hand on newer files.
3. Read "Porting traps" and "Needs from FEEL.md and the HUD" before testing.

## New files (copy as they are)

| File | What it does |
|---|---|
| `src/client/GunFeel.luau` | The runtime glue that Gun calls: recoil via `CameraFx.kick`, aim down sights (right click or the phone AIM button), the scope zoom and matching mouse sensitivity, shot/reload/bolt sound timing, shells, smoke, tracers, explosion shake, the layered hit feedback and the kill camera punch. |
| `src/client/GunProfiles.luau` | All the feel numbers, per class (Pistol, SMG, Rifle, Shotgun, Sniper, Heavy, Launcher, Energy) and per gun. It also reads each gun's part names (GunModels/GunSpecsExtra) to find its sights, magazine, bolt/pump/slide parts, ejection port and grip. **Tweak here.** |
| `src/client/ViewmodelFeel.luau` | The first-person pose that Viewmodel calls: hip to aimed, kick springs, equip raise, jump/land dip, strafe lean, idle, reload animations (magazine out/in with the left hand, shotgun shells, revolver cylinder, rocket from the front), bolt/pump/slide/charging-handle motion, the star muzzle flash, optic see-through while aiming, and the disarm drop + grey. |
| `src/client/GunSounds.luau` | Layered shot sounds per class, mechanical sounds, the Minigun spin loop, hit feedback, and pooled voices (one small pool per slot and layer, so gunfire can never cut off a kill thump). **`GunSounds.CUSTOM` is where Creator Store ids go** (see "Sound slots"). |
| `src/shared/GunEffects.luau` | Client-only effects: crisp tracers (streak + trail; sniper, energy and rail styles), the world muzzle flash star (used when the first-person gun is hidden), smoke, pooled tumbling shells, material impacts (sparks on metal, dust/chips on stone, splinters on wood, dirt, glass glints; Terrain uses the raycast's material), the enemy "pixel hit", pooled bullet holes lying flat on the surface, the headshot pop, and explosion extras. It also holds the League HQ effect palette and `GunEffects.guard` (below). |

Requires: `src/client/CameraFx.luau` (**this repo's version**, see below) and `src/client/Toggles.luau`, `Viewmodel`, `Config`,
`GunModels` (existing). The new modules don't require each other in a loop:
Gun -> GunFeel -> {ViewmodelFeel, Viewmodel, GunSounds, GunProfiles, CameraFx, Toggles, Config};
Viewmodel -> ViewmodelFeel -> GunProfiles -> {GunModels, GunEffects}; Effects -> GunEffects; GunSounds -> Config.

**Errors can't break shooting.** Every function Gun, Viewmodel and Effects call in the
new modules runs through `GunEffects.guard`: if it errors, the error still shows in the
output (once per message), but the caller carries on. So a bug in an effect, a sound or
a pose can never cancel a server shot, leave a reload stuck or stop Gun's frame
(`ViewmodelFeel.root` falls back to the plain pose for that frame). The shot effects
(`GunFeel.onShot`) also run only after `Remotes.Fire:FireServer(shots)`.

## Hooks in `src/client/Gun.luau` (21 marked lines)

1. **After** `local Viewmodel = require(script.Parent.Viewmodel)` insert:
   ```lua
   -- feel: recoil, aiming down sights, gun sounds and shot effects live in GunFeel
   local GunFeel = require(script.Parent.GunFeel)
   ```
2. **Replace** `local CONFETTI = { Color3.fromRGB(255, 46, 99), ... }` with:
   ```lua
   local CONFETTI = GunFeel.CONFETTI -- feel: kill pixels in your ESP color (was pink, yellow, cyan, green)
   ```
3. In `Gun.spread`, **after** the `if scoped then spread *= 0.2 end` block (before the `return math.min(...)`) insert:
   ```lua
   	-- feel: aiming down sights tightens the spread a little
   	spread *= GunFeel.spreadScale(weapon)
   ```
4. In `Gun.reload`, **replace** `Effects.sound("Reload")` with:
   ```lua
   	GunFeel.onReload(weapon, ammo) -- feel: reload sounds timed with the animation (was Effects.sound("Reload"))
   ```
   Keep it **before** `Viewmodel.startReload(weapon.Reload)`. It passes the ammo left, which the animation uses (the slide lock, the shotgun shell count).
5. In `refill()`, **after** `Viewmodel.cancelReload()` insert:
   ```lua
   	GunFeel.onRefill() -- feel: cancel pending reload and bolt sounds
   ```
6. In `aim()`, **replace** `return result.Position, result.Normal, hitEnemy` with:
   ```lua
   		return result.Position, result.Normal, hitEnemy, result.Instance, result.Material -- feel: also what was hit, for material impacts
   ```
   (`result.Material` is what makes grass and sand Terrain get the right impact: `Terrain.Material` isn't the voxel material.)
7. In `shoot()`, **replace** `local target, normal, hitEnemy = aim(camera, range)` with:
   ```lua
   		local target, normal, hitEnemy, hitPart, hitMaterial = aim(camera, range) -- feel: hitPart, hitMaterial
   ```
8. In `shoot()`, **replace** `Effects.tracer(muzzle, target, Toggles.tracerColor())` (the non-rocket one) with:
   ```lua
   			GunFeel.tracer(muzzle, target, Toggles.tracerColor(), weapon) -- feel: crisp tracer (was Effects.tracer)
   ```
   The rocket's `Effects.tracer(muzzle, target, ROCKET_COLOR, 0.25)` stays.
9. In `shoot()`, **replace** `Effects.impact(target, normal.Unit, if hitEnemy then "Enemy" else "World")` with:
   ```lua
   				Effects.impact(target, normal.Unit, if hitEnemy then "Enemy" else "World", hitPart, hitMaterial) -- feel: hitPart and hitMaterial pick the impact
   ```
10. In `shoot()`, **replace** `Effects.sound("Shot")` with:
    ```lua
    	-- feel: the shot sound moved to GunFeel.onShot below (was Effects.sound("Shot"))
    ```
11. At the end of `shoot()`, **replace** the old instant recoil block
    ```lua
    	if not Toggles.isOn("NoRecoil") then
    		local recoil = math.rad(weapon.Recoil * (if scoped then 0.5 else 1))
    		camera.CFrame *= CFrame.Angles(recoil, (math.random() - 0.5) * recoil * 0.5, 0)
    	end
    ```
    with:
    ```lua
    	-- feel: the old instant camera.CFrame recoil kick was removed; GunFeel.onShot kicks through CameraFx.
    	-- feel: shot sound, recoil, smoke, shells, bolt/pump, after the shot has gone to the server
    	GunFeel.onShot(weapon, scoped, fireInterval(), shots, muzzle, ammo)
    ```
    It must stay **after** `Remotes.Fire:FireServer(shots)` (and after `Viewmodel.kick` and the `bloom` line), so nothing cosmetic runs between taking the ammo and sending the shot.
    If the newer Gun.luau changed this block (for example for the Third Person hack), still remove any direct `camera.CFrame *=` recoil. Recoil only goes through CameraFx now.
12. **After** `function Gun.isTriggerHeld() ... end` insert:
    ```lua
    -- feel: whether you're aiming down sights (right click), for the HUD
    function Gun.isAiming()
    	return GunFeel.isAiming()
    end

    -- feel: for the on-screen AIM button on phones (aims down sights, or scopes)
    function Gun.setAimHeld(held)
    	GunFeel.setAimHeld(held)
    end
    ```
13. In `onHitConfirm`, **after** `Hud.hitmarker(headshot, killed)` insert:
    ```lua
    	GunFeel.onHitConfirm(headshot, killed, damage, position) -- feel: headshot ding, kill thump, kill camera punch
    ```
14. First line inside `function Gun.start(isMenuOpen)` insert:
    ```lua
    	GunFeel.start(isMenuOpen) -- feel: start GunFeel
    ```
15. In the `InputBegan` handler, **after** `triggerHeld = true` (the MouseButton1 branch) insert:
    ```lua
    			-- feel: a click if you pull the trigger mid-reload
    			if reloading then
    				GunFeel.dryFire() -- feel: dry-fire click
    			end
    ```
16. In the RenderStepped `scoped = ...` expression, **replace** `and not isMenuOpen()` with:
    ```lua
    			and not (isMenuOpen and isMenuOpen()) -- feel: Main may call Gun.start() without isMenuOpen
    ```
    The old copy's Main called `Gun.start()` with no argument, so a Sniper in a round errored every frame. FEEL.md's Main hook now passes `HackMenu.isOpen`. The guard is harmless either way.
17. In the same expression, **replace** `and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)` with:
    ```lua
    			and (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or GunFeel.aimHeld()) -- feel: or the phone AIM button
    ```
18. **After** `Viewmodel.setSpin(spin)` insert:
    ```lua
    		-- feel: aim down sights, scope zoom, Minigun whine, ammo for the first-person gun
    		GunFeel.update(dt, weapon, scoped, reloading, spin, ammo, infiniteAmmo())
    ```
    It must run before `Hud.setSpread(Gun.spread())` so the crosshair tightens while aiming.

If the newer Gun.luau has a Third Person path: GunFeel only needs `Viewmodel.isVisible()` to be false in third person. Then it draws a world muzzle-flash star at `muzzle` (the tool handle) instead of the first-person one.

## Hooks in `src/client/Viewmodel.luau` (12 marked lines)

Hooks 1 to 8 are gunplay; 9 to 12 are the slide pose from [FEEL.md](FEEL.md).

1. **After** `local GunModels = require(Shared:WaitForChild("GunModels"))` insert:
   ```lua
   -- feel: aiming down sights, kick springs, equip, jump/land, lean, reload and bolt/pump motion
   local ViewmodelFeel = require(script.Parent.ViewmodelFeel)
   ```
2. At the end of `build()`, **after** `flashLight.Parent = flashPart` insert:
   ```lua
   	ViewmodelFeel.onBuild(model, pieces, weaponId, muzzleOffset, flashPart, flashLight) -- feel: find the magazine, bolt and sights
   ```
   It has to come after the arms (`addArm`) and the flash are built: it finds the `LeftHand`/`LeftArm` pieces, recolors the flash and adds 4 flash-star parts to `model`.
3. In `Viewmodel.kick`, **after** `kick = math.min(kick + (strength or 1), 2.5)` insert:
   ```lua
   	ViewmodelFeel.kick() -- feel: spring kick, star flash, slide/cylinder
   ```
4. In `Viewmodel.startReload`, **after** `reloadDuration = duration` insert:
   ```lua
   	ViewmodelFeel.startReload(duration) -- feel: magazine out and in
   ```
5. In `Viewmodel.cancelReload`, **after** `reloadStart = nil` insert:
   ```lua
   	ViewmodelFeel.cancelReload() -- feel: stop the reload animation
   ```
6. In `update`, inside `if not show then`, **after** `lastPitch = nil` (before `return`) insert:
   ```lua
   		ViewmodelFeel.onHidden(hidden) -- feel: raise the gun again when it comes back (not after a scope)
   ```
   `hidden` is the module's scope flag (`Viewmodel.setHidden`). If the newer file hides the gun for Third Person through another flag, pass `true` only for the scope case, so the gun doesn't re-raise every time you unscope.
7. **Replace** `lastRoot = cameraCFrame * BASE_OFFSET * viewOffset * bob * breathe * sway * recoil * reload` with:
   ```lua
   	-- feel: ViewmodelFeel blends hip and aim-down-sights poses and adds the kick springs, equip, jump/land, lean
   	-- and reload/bolt poses; it replaces the old `recoil` and `reload` poses above
   	-- (was: lastRoot = cameraCFrame * BASE_OFFSET * viewOffset * bob * breathe * sway * recoil * reload)
   	lastRoot = cameraCFrame * ViewmodelFeel.root(dt, BASE_OFFSET * viewOffset, bob, breathe, sway)
   ```
   The old `recoil` and `reload` locals are still computed but no longer used. They can stay, or be deleted later.
   If the newer file adds a third-person offset to this line, keep it outside: `cameraCFrame * <thirdPersonOffset> * ViewmodelFeel.root(...)`.
8. **After** the `for index, item in pieces do ... end` loop that places the parts (end of `update`) insert:
   ```lua
   	ViewmodelFeel.placeParts(lastRoot) -- feel: magazine, bolt, pump, left hand, flash star, optic fade
   ```

Without hooks 9 to 12 the gun bobs at slide speed: `WalkSpeed` goes up to 34–72 while you
slide and right after, so the gun shakes at 3–6 Hz just when the camera drops and leans.

9. **After** `local GunModels = require(Shared:WaitForChild("GunModels"))` insert:
   ```lua
   local MoveFeel = require(script.Parent.MoveFeel) -- feel: slide pose and run-pace bob
   ```
10. In `update`, **after**
    `local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1 and humanoid.FloorMaterial ~= Enum.Material.Air`
    insert:
    ```lua
    	moving = moving and not MoveFeel.isSliding() -- feel: no running bob while sliding
    ```
11. **Replace** `bobTime += dt * (humanoid.WalkSpeed / 16) * 9` with:
    ```lua
    		-- feel: was `bobTime += dt * (humanoid.WalkSpeed / 16) * 9`; bob at run pace (not slide speed), at most about 5 bobs a second
    		bobTime += dt * (math.min(humanoid.WalkSpeed, MoveFeel.runSpeed(), 28) / 16) * 9
    ```
    The `28` caps the bob at about 5 a second, the same as the footsteps and camera bob.
    Without it, Speed Hack at 45 bobs the gun 8 times a second.
12. **After** `local bob = CFrame.new(math.sin(bobTime) * 0.045 * bobAmount, -math.abs(math.cos(bobTime)) * 0.04 * bobAmount, 0)` insert:
    ```lua
    	bob *= MoveFeel.viewmodelPose() -- feel: the gun lowers and cants while sliding
    ```
    `bob` goes through `ViewmodelFeel.root` (hook 7), which already calms it while aiming.

## Hooks in `src/shared/Effects.luau` (4 marked lines)

1. **After** `local Config = require(script.Parent.Config)` insert:
   ```lua
   -- feel: richer client-side impacts and explosions for your own gun
   local GunEffects = require(script.Parent.GunEffects)
   ```
2. At the end of `Effects.explosion`, **after** the `for index, color in {...} do ... end` loop insert:
   ```lua
   	-- feel: a shockwave ring, embers and smoke on the client
   	if RunService:IsClient() then
   		GunEffects.explosion(position, radius)
   	end
   ```
3. **Replace** `function Effects.impact(position, normal, kind)` with:
   ```lua
   function Effects.impact(position, normal, kind, part, material) -- feel: part and material (optional) are what was hit
   	-- feel: on the client, impacts match the surface (sparks on metal, dust on concrete...) with pooled holes
   	if RunService:IsClient() then
   		GunEffects.impact(position, normal, kind, part, material)
   		return
   	end
   ```
   The old server body stays below it, unchanged. GunEffects never runs on the server: it does nothing there and creates nothing when it's required.

## Porting traps (check these on the newer files)

- **`Effects.impact` returns early on the client.** Anything the newer PC `Effects.impact`
  does on the client below that hook (a new decal, a sound, a "BANNED" effect...) would be
  skipped without any error. Move such client-only additions into `GunEffects.impact`, or
  put them above the `if RunService:IsClient() then` hook.
- **Gun no longer plays `Config.Sounds.Shot` or `Config.Sounds.Reload`.** If the user already
  pasted Creator Store ids there on the PC, GunSounds still uses them: with
  `GunSounds.USE_CONFIG_SOUNDS = true` (the default), a `Config.Sounds.Shot` id that isn't a
  built-in `rbxasset://` sound plays for every gun whose `CUSTOM` shot slot is empty, and a
  custom `Config.Sounds.Reload` id plays as `ReloadStart`. For per-class sounds, copy the ids
  into `GunSounds.CUSTOM` instead.
- **Recoil:** remove every direct `camera.CFrame *=` recoil in the newer Gun (hook 11), or it
  kicks twice.

## Needs from FEEL.md and the HUD (check these when porting)

- **This repo's current `CameraFx.luau`.** An earlier CameraFx wrote shakes into
  `camera.CFrame` and never took them off, and Roblox's camera scripts build on
  `camera.CFrame`, so per-shot shakes (Shotgun 0.35, Launcher 0.6, Ban Cannon 0.8, kills,
  explosions up to 0.9) would add up to a random drift in your aim. The current one
  takes them off again at `Camera - 2`. GunFeel checks for it: `GunFeel.SHAKE` is 1 when
  `CameraFx.clear` exists (current version) and 0 otherwise, so with the old CameraFx there are
  simply no shakes. Recoil kicks, FOV punches and zooms work with either.
- **`CameraFx.start()` in Main.client** (FEEL.md hook). Without it the recoil kicks pile up and the camera never moves. If FEEL.md's hooks aren't added, add `require(script.Parent.CameraFx).start()` to Main.client.
- **FieldOfView through `CameraFx.fov(base)`** (FEEL.md hook in Movement). Aiming down sights (`"GunAim"` scale) and the scope zoom (`"GunScope"` scale) are `CameraFx.setFovScale` entries, so they only show if whoever sets FieldOfView uses `CameraFx.fov`.
- **Scope zoom:** in the old copy nothing used `Gun.scopeFov()`, so the Sniper never zoomed. GunFeel now zooms scoped guns to their `Config` `Scope` (`GunFeel.APPLY_SCOPE_ZOOM = true`). If the newer Movement/Main already sets FieldOfView from `Gun.scopeFov()`, set `GunFeel.APPLY_SCOPE_ZOOM = false`, or it zooms twice (the mouse sensitivity still follows the scope then). With FOV Changer on (base 95), the scope comes out a bit wider than Scope, because it's a scale against `GunFeel.SCOPE_BASE_FOV = 70`.
- **Mouse sensitivity:** while aiming or scoped, GunFeel sets `UserInputService.MouseDeltaSensitivity` to the player's value times `zoom ^ GunFeel.ZOOM_SENSITIVITY` and gives the old value back when the zoom ends (or you die, or the round ends). If another script on the PC also sets `MouseDeltaSensitivity`, set `GunFeel.ZOOM_SENSITIVITY = 0`.
- **Gun.start(isMenuOpen):** Main should pass `HackMenu.isOpen` (FEEL.md's Main hook does).
- **Aimbot:** while the Aimbot hack is on and right click is held, `Aim.luau` sets the camera every frame, so GunFeel doesn't kick the camera then (shakes and FOV punches still play). If the newer Aim.luau changes which button holds the Aimbot, update `aimbotHeld()` in GunFeel to match.
- **HUD (optional):**
  - `Gun.isAiming()` is there if the crosshair should hide or shrink while aiming. The spread already tightens through `Gun.spread()`. If the crosshair hides while aiming, keep it when `GunFeel.sightsLinedUp()` is false: the Rocket aims from the shoulder, with the crosshair.
  - `Gun.setAimHeld(held)` is for the phone AIM button in STYLE 4.6. It aims down sights, or scopes on Scope guns.
  - Hud.hitmarker still plays its own `Hit`/`Kill` sound. GunSounds adds only the headshot ding and the kill thump on top. If the HUD also adds STYLE's `Headshot` cue, set `GunSounds.PLAY_HEADSHOT_DING = false`. If it drops its hit tick, set `GunSounds.PLAY_HIT_TICK = true`.

## Knobs (all in plain tables)

- `GunProfiles.CLASSES`: per class `Kick` (camera kick x Config Recoil), `Recover`, `Drift`, `Shake`, `Punch`, `ViewKick`, `Aim` (Time, Fov 0.84-0.9, Spread 0.7-0.9, Distance; `false` = no ADS), `Flash`, `Shell`, `Tracer`.
- `GunProfiles.CLASS_BY_ID`: which class each of the 21 guns is. New guns are classed from their stats.
- `GunProfiles.BY_ID`: per-gun tweaks (Revolver, DMR, AutoCannon, ToxicLauncher, BanCannon, PulseRifle, Railgun).
- `GunProfiles.ACTIONS`: moving parts per gun, as Lua patterns on part names. Kinds: Slide, Bolt, Pump, Cylinder, Charge.
- `GunProfiles.MAG` and `RELOAD_BY_ID`: which parts are the magazine (`^Mag`, `^Drum`, `^Ammo`, `^Can%u`, ...), with mag wells skipped. Shotguns load shells, the Revolver uses its cylinder, the Rocket takes a new rocket from the front.
- `GunProfiles.RELOAD_TIMING`: when each reload step happens, as a share of the reload. The animation and the sounds both use it.
- `GunProfiles.SIGHTS`: sight-line overrides; `false` = aim from the shoulder. The Rocket uses `false`: looking through its side scope put the open end of the tube right beside the crosshair.
- `GunFeel.ZOOM_SENSITIVITY` (0.8): how much aiming and scopes slow the mouse to match the zoom (1 = exactly, 0 = off). A scoped Sniper (FOV 28) gets 0.48x, aiming a pistol 0.89x.
- `GunFeel.SHAKE`: scales every gun camera shake (auto: 1 with this repo's current CameraFx, 0 with an older one).
- `GunFeel.APPLY_SCOPE_ZOOM`, `GunFeel.SCOPE_BASE_FOV`: see "Scope zoom" above.
- `GunSounds.VOLUME`, `GunSounds.USE_CONFIG_SOUNDS`, `GunSounds.PLAY_HIT_TICK`, `GunSounds.PLAY_HEADSHOT_DING`.
- `GunEffects.PALETTE`: the League HQ colors used by every effect.

## Sound slots (paste Creator Store ids into `GunSounds.CUSTOM`)

Every slot works today with Roblox built-ins: `impact_explosion_03.mp3`, `action_jump_land.mp3`,
`action_get_up.mp3`, `volume_slider.ogg`, `action_jump.mp3`, `action_falling.mp3` and
`impact_water.mp3`. Each one is layered at different pitches, with +-4% pitch and +-10%
volume variation on every play. An id in `CUSTOM[slot].Id` replaces that slot's layers
(`Volume` and `Speed` are optional). Each slot has its own voices (6 per layer for shots,
3 for everything else), so fast guns can't cut off the hit feedback.

- **Shots:**
  - `PistolShot`
  - `RevolverShot`
  - `SMGShot` (SMG, Micro SMG, Tommy Gun)
  - `RifleShot` (Assault Rifle, DMR)
  - `ShotgunShot` (Pump Shotgun, Trench Gun)
  - `SniperShot` (Sniper, Bolt Rifle, Long Rifle)
  - `HeavyShot` (Minigun, Heavy Repeater)
  - `CannonShot` (Auto Cannon, Ban Cannon)
  - `LauncherShot`
  - `ToxicShot`
  - `EnergyShot` (Plasma)
  - `PulseShot`
  - `RailShot`
  - `Explosion`
- **Handling:**
  - `Equip`, `AimIn`, `AimOut`
  - `ReloadStart`, `MagOut`, `MagIn`, `Charge`, `ShellIn`
  - `CylinderOpen`, `CylinderClose`
  - `BoltUp`, `BoltBack`, `BoltForward`
  - `PumpBack`, `PumpForward`
  - `DryFire`, `ShellTink`
  - `MinigunSpin` (a loop)
- **Feedback:** `HitTick` (off by default), `HeadshotDing`, `KillConfirm`, `KillHeadshot`.

The best slots to replace first are the 8 class shots, `KillConfirm`, `HeadshotDing`, `MagIn` and `BoltForward`/`PumpForward`.

## Behavior kept

These all still work as before:

- Spread/bloom, and `Gun.spread()` for the HUD crosshair.
- `Gun.scopeFov()`.
- NoRecoil: no camera kick or shake, and half the gun kick.
- NoSpread, RapidFire (the bolt and pump cycles speed up with it), InfiniteAmmo (no reload, and the bolt keeps cycling), Triggerbot (it calls `Gun.tryShoot`).
- Aimbot: it owns the aim while held (no kick fights it, nothing drifts after you let go).
- MagicBullet: the curved tracer is unchanged.
- SilentAim, Wallbang, Disarm (it also drops and greys the gun now).
- HitConfirm: hitmarkers, damage numbers and kill pixels.
- Server-validated shots: the client still only sends `Remotes.Fire(shots)`, and the server is untouched.
- Minigun spin-up: the existing `spin`, plus a whine that follows it.

One old behavior is unchanged on purpose: Gun's own `scoped` flag (and so `Hud.setScoped`)
doesn't check that you're alive, as before. GunFeel's zoom, aim and mouse sensitivity do,
so dying with right click held no longer leaves the camera zoomed.

## Tests

`tools/preview/tests/gunplay_screens.luau` boots the real client and runs 9 screens. All of
them fail on any `Client.errors()`.

- Every one of the 21 guns: fire, aim or scope, reload.
- Pistol recoil and recovery, No Recoil, the sights centered within 0.3 degrees when aimed, aimed mouse sensitivity, and dying with right click held (no zoom, aim, spread or sensitivity left over).
- Rifle climb, the optic centered and see-through, magazine out and back in, and hit/headshot/kill feedback.
- Rapid Fire, No Spread, Infinite Ammo, the Disarm grey-out and restore, and the phone AIM button.
- Leaving the round clears the zoom.
- Strafing, jumping and landing, and the Minigun spin-up.
- Impacts on 6 materials, the 40-hole cap, bullet holes lying flat on walls, floors and slopes, the raycast material winning (grass gets dust, not sparks), the emitter cap with 400 surface colors, recovering after the effects folder is destroyed, and cleanup.
- Safety: the Aimbot held means no kick and no drift after; Rapid Fire SMG shots never reuse the kill/headshot voices; with GunSounds made to error, shots still reach the server, a reload still finishes, and the error is still reported.
- Sniper scope zoom to 28, scoped mouse sensitivity, its scoped kick, and a scoped kill punch scaled to the zoom.
- Bolt, pump and slide motion, the Rocket aiming from the shoulder, and the Rocket hiding its round until the reload.

Run it on a copy of the game's `src` with the hooks from this file and FEEL.md added:

```sh
EARNESP_SRC=/path/to/hooked/src MODELS_SRC=src tools/preview/gui.sh tools/preview/tests/gunplay_screens.luau out/gunplay
```

The `GunplaySafety` screen prints two `[client error] test: a broken ...` lines on purpose;
it checks they were reported and then clears them.

[`previews/gunplay_poses.png`](../../previews/gunplay_poses.png) shows 12 of the first-person
poses (hip, aimed, shots, reloads, bolt, pump).

## Check in Studio (can't be tested in the preview)

- **Particle bursts in one frame.** Impacts reuse one emitter per kind and color: the emitter's
  attachment is moved, then `Emit()`ed, sometimes several times in the same frame (8 shotgun
  pellets on one wall). Check with the Pump Shotgun on a wall that each pellet's sparks/dust
  appear at its own hole. If they all show at one spot, give each emitter kind a small ring of
  attachments (one per pellet) in `GunEffects.emit`.
- **Mouse sensitivity.** Check that the default camera slows down while scoped (it reads mouse
  deltas that `MouseDeltaSensitivity` scales).
- Sounds: the built-in stand-ins are only placeholders; Creator Store ids will sound much better.
