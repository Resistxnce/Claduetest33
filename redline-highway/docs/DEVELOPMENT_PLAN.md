# Redline Highway: technical development plan

*Working title. Updated 2026-11-13.*

A high-speed highway driving and racing game for Roblox, built around convincing car physics, dense
living traffic, deep tuning and strong audio. The gameplay idea (fast driving through traffic, close
passes, highway races) is a broad genre. Everything here is an original implementation: no maps,
branding, code, models, textures, UI or presentation from No Hesi or any other game.

## 1. Ground rules

1. **One excellent car before many average ones.** The first car is an original GT car built on the
   publicly documented engineering of the Ferrari 812 Superfast. Every later car reuses its framework.
2. **Data-driven vehicles.** One shared simulation; each car is a configuration file. No per-car code.
3. **The server decides what counts.** Money, race results, rewards and ownership are never trusted
   from the client.
4. **Small stages, each tested before the next.** A stage is done when it passes its test checklist
   in Studio, not when its script exists.
5. **Honest numbers.** Factory figures are cited. Estimates are labelled as estimates. Accuracy is
   claimed only after it is measured.

## 2. What exists now, and what can't be done from here

Built in this session (Phase 1 foundation, see section 9):

- This plan, the prototype's specification (`PROTOTYPE_GT12.md`) and a Phase 1 test checklist.
- The shared vehicle framework: engine, transmission, differential, tyres, suspension, brakes,
  aerodynamics and steering, driven by the prototype's configuration.
- A proving-ground test track, a stand-in (graybox) car built to the real car's dimensions, spawning,
  three cameras, a dashboard HUD and a telemetry overlay.
- Two ways to import it at home: a place file you open directly in Studio, and a Rojo project.

Limits of this session, stated plainly:

- **None of the code has been run.** This session has no Roblox Studio, so nothing has been
  play-tested or even type-checked. Expect a round of fixes the first time it runs. The test checklist
  says what to try and what to look for.
- **No 3D models or textures yet.** Real car models need Blender at home. The stand-in car uses the
  same part names the real model will use, so the model can be swapped in without code changes.
- **Placeholder audio.** The sound system (section 6) is built, with original sounds synthesized in
  Python as placeholders until there are recordings. Two files need uploading to Roblox before the
  game makes sound (`docs/AUDIO.md`).

When your PC is connected (Roblox Studio with its MCP server, Blender, the Obsidian vault), I can
run Play tests, read errors, take screenshots and iterate, which is how this should be developed.

## 3. Roblox constraints and the technique chosen for each

| Topic | What Roblox allows | Approach |
|---|---|---|
| Units | 1 stud = 28 cm and 1 Roblox mass unit (RMU) = 21.952 kg, per the Creator Hub units page. The physics engine itself is unit-free. | All car maths runs in metres, kilograms and newtons and is converted at the edge (`Units` module). World gravity is set to 9.81 m/s² = 35.04 studs/s² (the default 196.2 is cartoon gravity). |
| Car physics | Rigid bodies plus constraints. No built-in tyre model. | **Custom raycast suspension and tyre model** on the driver's machine. Each frame (`RunService.PreSimulation`), four suspension rays find the road. The simulation computes spring, damper, anti-roll and tyre forces, which are applied through `VectorForce` objects at each contact patch. Roblox integrates the rigid body. Wheel spin, engine and clutch are integrated inside the simulation in 8 sub-steps per frame for stability. |
| Mass and inertia | Mass and inertia come from part geometry. Massless parts add nothing. | An invisible root box sized like the car's real mass distribution, placed at the centre of mass, with density set so the car weighs exactly 1,705 kg. Body and wheel parts are massless. This gives correct weight, weight distribution and a realistic yaw inertia (about 2,600 kg·m²). |
| Network ownership | The client that owns an assembly simulates it. | The server spawns each player's car and gives that player network ownership, so driving is responsive. The server still owns money, races and rewards, and will sanity-check speed and position (Phase 7). |
| Materials | PBR through `SurfaceAppearance` (colour, normal, roughness, metalness maps). No custom shaders, no ray tracing. | Real paint, carbon, chrome and glass looks come from well-made texture sets plus "Future" lighting and a strong environment. Texture size: Roblox's texture spec page currently mentions up to 4096×4096, while an older version said 1024×1024; confirm in Studio when importing. |
| Mesh detail | The per-MeshPart triangle limit is unclear (third-party guides say 10k or about 20k). | Split the car into parts (body panels, glass, lights, wheels, interior), each under the limit. LOD versions for distance. Check every import in Studio's importer output. |
| Audio | `Sound`, `SoundGroup`, roll-off, and the newer audio API (`AudioPlayer`, `AudioEmitter`, `AudioListener`). | RPM-layered engine loops with crossfades, separate on-throttle and off-throttle layers, and event sounds (shifts, limiter, turbo, pops). Doppler is computed from relative speed and applied as pitch. Verify each feature works before relying on it. |
| Large maps | Streaming (`StreamingEnabled`), anchored geometry is cheap, moving physics is expensive. | Modular road pieces, streaming, LOD, and traffic that moves kinematically (see section 7). |

## 4. Project structure

The `src` folder mirrors where things go in Studio. The place file and Rojo both produce this layout.

```
ReplicatedStorage
  VehicleSystem                      shared by server and client
    Units                            unit conversion (studs, metres, RMU, newtons)
    VehicleConfigurations
      Prototype812                   the GT12 prototype (Ferrari 812 Superfast reference data)
    CorePhysics
      VehicleSimulation              ties everything together, one step per frame
      Steering                       speed-sensitive steering with Ackermann geometry
      Brakes                         brake torque, bias, ABS, handbrake
    EngineSimulation/Engine          torque curve, friction, idle, rev limiter, inertia
    TransmissionSimulation/Transmission   gears, DCT shifting, clutch, auto and manual modes
    DifferentialSystem/Differential  open, locked and clutch-type limited-slip
    SuspensionSystem/Suspension      springs, bump and rebound damping, bump stops, anti-roll bars
    TireSimulation/Tire              combined-slip "magic formula" tyre model and compounds
    Aerodynamics/Aero                drag and downforce that rise with speed
    VehicleTelemetry/Telemetry       collects numbers for the HUD and testing
    VehicleAudio
      EngineMix                      sound mixer: engine layers, events, tyres, wind (pure maths)
      AudioAssets                    asset IDs of the two uploaded sound files
      Sheets                         where each sound sits in its file (generated)
ServerScriptService
  Server
    Main                             starts the game: lighting, track, players
    TrackBuilder                     builds the proving-ground track
    VehicleModelBuilder              builds the stand-in car (same part names as the future mesh)
    VehicleSpawner                   spawns cars, seats players, sets network ownership
StarterPlayer / StarterPlayerScripts
  Client
    Main                             starts the client systems
    VehicleController                raycasts, runs the simulation, applies forces, moves wheels
    InputController                  keyboard and gamepad
    CameraController                 chase, hood and cockpit cameras
    HUD                              speedometer, tachometer, gear, telemetry overlay
    VehicleAudio                     plays the car's sounds from the mixer's output
```

Later phases add `VehicleVisuals`, `VehicleCameras`, `Customization` (shared) and
`Traffic`, `Races`, `Economy`, `DataService` (server), keeping the same pattern.

## 5. Vehicle simulation design

**Per frame, for each wheel:** a ray from the suspension mount finds the road. Compression and its
rate give the spring and damper force (separate bump and rebound damping, a progressive bump stop),
plus the anti-roll bar's share. That normal load feeds the tyre.

**Tyres:** a combined-slip model in the style of Pacejka's "magic formula". Slip ratio and slip angle
are normalised by their peak values and combined into one slip, which sets the total force. That
force is then split between braking/driving and cornering, so a tyre that is braking hard has less
cornering grip and vice versa (a friction ellipse). Grip falls slightly as load rises (load
sensitivity), and each compound has its own peak grip and peak slip. Below about 3 m/s the model
blends into a stable low-speed friction model, and a relaxation length smooths slip angle, avoiding
the jitter that raw tyre models show when parked.

**Drivetrain:** engine torque from a measured-shape torque curve, minus internal friction (engine
braking). A rev limiter cuts fuel with hysteresis. The clutch is a stiff, torque-limited coupling,
which handles launches, stalls and shifts in one model. The gearbox is a 7-speed dual-clutch with a
60 ms shift and a brief torque dip. The rear differential is a clutch-type limited-slip with preload
and separate power and coast locking. Wheel spin, clutch and engine speed are integrated in 8
sub-steps per frame. Configurations can instead use a torque-converter automatic (lock-up clutch,
up to 10 gears), turbo or supercharger boost, and on-demand all-wheel drive; see `VEHICLE_CONFIG.md`.

**Brakes:** per-axle maximum torque with front-rear bias, optional ABS that holds slip near the
tyre's peak, and a rear handbrake.

**Traction control:** caps engine and clutch torque at what the driven tyres can grip (with
headroom), then trims further while they slip past a target. It can be switched off (V).

**Aerodynamics:** drag ½ρ·CdA·v² at the centre of mass. Downforce ½ρ·ClA·v² applied separately at the
front and rear axles, so wings and splitters change balance as well as grip.

**Steering:** input rate-limited and smoothed. Maximum wheel angle falls with speed (30° when slow,
4.5° at 250 km/h) so keyboard players stay in control. Ackermann geometry turns the inside wheel more.

**Validation:** section 8 and `PROTOTYPE_GT12.md` list the factory targets. A simple point-mass
model was used to choose the gear ratios, grip and drag. Then `tools/drivetrain_model.py`, a
line-for-line Python copy of the game's engine, clutch, gearbox, differential, brake and tyre code,
drove the car in a straight line at 60 frames per second. That caught and fixed a launch that bogged
down, engine friction counted twice, and traction control that oscillated. In-game acceleration,
braking and top speed will be measured with the telemetry overlay and compared.

## 6. Audio design (Phase 2)

- **Engine:** 4 to 6 recorded loops across the RPM range for on-throttle and off-throttle, blended by
  RPM and load. Pitch-corrected between samples. Separate intake, exhaust and mechanical layers.
- **Events:** shift (DCT clunk and RPM drop), rev limiter, exhaust pops on lift-off, turbo spool and
  blow-off for turbo builds.
- **Driving:** tyre scrub and squeal from slip, road and wind noise from speed, suspension knocks from
  bump stops.
- **Interior versus exterior:** separate mixes per camera (muffled engine, louder wind and tyres inside).
- **Traffic:** 3D-positioned engine and tyre sounds for nearby traffic, with Doppler from relative speed.
- **Licensing:** only recordings you make, buy with a licence, or that Roblox's library permits.

**Built so far (M7):** the engine layers, events (shift crack and clunk, crackles, bump knock),
tyre squeal, road and wind noise, gearbox whine and the cockpit equaliser. Roblox counts uploads
against a monthly limit, so the sounds are packed into two files and each Sound plays its own region
(`PlaybackRegion` and `LoopRegion`). The mixer is pure maths (`VehicleAudio/EngineMix`), copied in
`tools/audio_preview.py`, which renders a drive to listen to. The current sounds are synthesized
placeholders (`tools/synth_audio.py`). Details are in `docs/AUDIO.md`.

Since then, each engine is synthesized from its own definition (firing order, bank numbering, crank
type, exhaust routing, turbo or supercharger), with limiter loops that stutter like a real fuel cut,
turbo whistle and blow-off, supercharger whine, tunnel reverb and echo near TunnelZone parts, and
positional traffic sound with distance fade, air absorption and Doppler. The synthesis was
calibrated against a freely licensed recording of a real V8 (spectral error about 4.5 dB).

## 7. Traffic design (Phase 4)

- **Road network:** lanes are centre lines in a lane graph (each lane knows its successors, its left
  and right neighbours, speed limit and merge points).
- **Car following:** the Intelligent Driver Model (Treiber, Hennecke and Helbing, 2000): each driver has
  a desired speed, time gap, minimum gap, comfortable acceleration and braking.
- **Lane changes:** MOBIL (Kesting, Treiber and Helbing, 2007): change lanes only if it helps you more
  than it hurts the cars behind, with a politeness factor and a safe-braking limit.
- **Personalities:** cautious, normal, aggressive and slow drivers, plus reaction delays and small
  random speed differences, so no two cars move alike.
- **Cost:** traffic moves along the lane graph without full physics (CFrame updates on the server at
  about 20 Hz, smoothed on clients). A traffic car switches to full physics only when hit. Spawning
  happens out of sight, in valid gaps, with density scaled to player count and server load.

**Built so far (first version, on the proving-ground loop):**
- `TrafficSystem/TrafficSimulation` runs IDM and MOBIL on the server, 20 times a second, with four
  driver profiles (cautious, normal, aggressive, truck). Players' cars count as vehicles the traffic
  must follow and not cut off.
- Each player gets the traffic within 1.2 km, 10 times a second, packed into 12 bytes per car.
  `TrafficRenderer` draws it on their computer with pooled stand-in cars, moved smoothly in one
  `BulkMoveTo` call per frame.
- `tools/traffic_model.py` is a Python copy of the simulation. In 10 simulated minutes of light
  traffic and 5 of heavy, it has no collisions. Heavy traffic flows at about 1,740 cars per hour per
  lane, which is realistic. Traffic keeps right, merges around a stopped car, never pulls out within
  150 m in front of a player doing 300 km/h, and passes a slow player on the right.
- Still to come:
  - general road networks (lane graph, merges, exits);
  - traffic cars that react physically when hit;
  - spawning and despawning around players instead of a fixed loop.

## 8. Prototype: Valenza GT12

An original car with fictional branding, built to the Ferrari 812 Superfast's public figures. Its
internal ID is `Prototype812`. Full details and sources are in `PROTOTYPE_GT12.md`.

| | Value | Status |
|---|---|---|
| Engine | 6,496 cc 65° V12, naturally aspirated | Ferrari factory figure |
| Power | 588 kW / 800 CV at 8,500 rpm | Ferrari factory figure |
| Torque | 718 Nm at 7,000 rpm | Ferrari factory figure |
| Max revs | 8,900 rpm | From the 812 GTS spec sheet (same engine); verify |
| Weight | 1,525 kg dry; 1,630 kg kerb (DIN); simulated with a 75 kg driver (1,705 kg) | Factory figures; driver is an assumption |
| Weight distribution | 47% front / 53% rear | Ferrari factory figure |
| Size | 4,657 × 1,971 × 1,276 mm; wheelbase 2,720 mm; track 1,672 / 1,645 mm | Published figures |
| Tyres | 275/35 ZR20 front, 315/35 ZR20 rear | Published figures |
| Gearbox | 7-speed dual-clutch, rear-wheel drive | Ferrari factory figure |
| Gear ratios | 2.98, 2.436, 1.992, 1.629, 1.331, 1.089, 0.89; final drive 4.0 | **Estimates** fitted to the performance figures |
| Drag and downforce | CdA 0.70 m²; ClA 0.18 front, 0.27 rear | **Estimates** |
| 0–100 / 0–200 / top speed | Factory: 2.9 s / 7.9 s / over 340 km/h | Python mirror of the game's drivetrain code: 3.37 s / 8.17 s / 339 km/h (see `PROTOTYPE_GT12.md`) |

## 9. Phases and milestones

Each milestone ends with a test pass in Studio. Later phases follow your master prompt's order.

**Phase 1: technical foundation (this session's code)**
- M1. The place opens, the track builds, the stand-in car spawns and you're seated in it.
- M2. The car rests level on its suspension with no jitter, and pulls away, steers and brakes.
- M3. The gearbox shifts automatically and manually. The HUD shows speed, RPM and gear, and the
  telemetry overlay shows loads, slip and suspension travel.
- M4. Chase, hood and cockpit cameras work and switch cleanly.
- M5. Measured 0–100 km/h, 0–200 km/h, 100–0 km/h braking and top speed are logged against factory
  targets, and parameters are tuned until the car is stable and close.

**Phase 2: the prototype car, complete**
- M6. Blender model to the specification: exterior, interior, separated wheels and brakes, LODs, PBR
  texture sets. Gated by the kit's mesh-qa checks. Swapped in for the stand-in car.
- M7. Engine and driving audio (section 6), with interior and exterior mixes. *System built with
  placeholder sounds; needs the sounds uploaded and a listen in Studio.*
- M8. Body movement (pitch, roll), suspension and wheel animation, brake glow, lights.

**Phase 3: customisation and tuning.** Parts database with compatibility rules, tuning UI, a dyno that
draws the real torque curve, saved builds. Each modification changes simulation parameters, never a
made-up "speed stat".

**Phase 4: traffic** (section 7). *First version built on the proving ground.* A first close-pass
score (Phase 6) is in too, so there is something to play: `Gameplay/ClosePass` with its Python copy
and tests in `tools/close_pass_model.py`. **Phase 5: environment:** highways with merges, exits, tunnels,
bridges and day/night. **Phase 6: gameplay:** races, close-pass scoring, money, progression, garage,
dealership, leaderboards. **Phase 7: multiplayer hardening:** server validation, saving with
`DataStoreService`, rate limits, anti-exploit checks, load testing. **Phase 8: more cars**, each with its
own data, model, audio and parts.

## 10. 3D asset pipeline (Phase 2)

- **Scale:** model in metres at real size; convert once on export so 1 stud = 0.28 m.
- **Pivots and names:** body at the car's centre of mass; wheels pivot at the hub. Required names:
  `Body` (model), `Wheel_FL`, `Wheel_FR`, `Wheel_RL`, `Wheel_RR`, `DriverSeat`, camera attachments
  `ChaseCamTarget`, `HoodCam` and `CockpitCam`.
- **Topology and UVs:** clean quads, no hidden interior faces, consistent texel density. Separate
  materials per surface (paint, carbon, chrome, rubber, glass, leather, Alcantara-style suede).
- **Textures:** colour, normal, roughness and metalness maps per material set, baked from a high-detail
  version where useful.
- **LOD:** at least high, medium and low versions; low uses simple shapes and a single texture.
- **Collision:** simple box or hull collision parts, never the visual mesh.
- **Checks:** the gamedev kit's `mesh-qa` gate before anything goes in the game, then Studio's
  importer output for triangle counts and texture sizes.

## 11. Licensing and originality

- Ferrari names, logos and designs are trademarks. The prototype uses the 812's public engineering
  figures only, with an original body and the fictional brand "Valenza". No ripped or unlicensed
  models, textures or sounds.
- No No Hesi maps, layouts, branding, UI or code. Public gameplay videos can be studied for the
  general feel, as with any genre.
- Close-pass scoring is a fictional arcade mechanic and should be presented that way.

## 12. Risks and open questions

- **Physics stability at 300+ km/h** with forces updated once per frame. Mitigations: sub-stepped
  wheel integration, lateral force limits, tyre relaxation, conservative bump stops. To be measured.
- **Keyboard driveability** of a realistic 800 CV rear-drive car. Mitigations: speed-sensitive
  steering, throttle ramping, optional traction control and stability assist (Phase 3 settings).
- **Mobile performance** with detailed cars and dense traffic. Mitigations: LOD, streaming, quality
  settings, kinematic traffic.
- **Asset sourcing**: models and especially engine audio need real effort or a budget.

## Sources

- Roblox Creator Hub, [Roblox units](https://create.roblox.com/docs/physics/units): 1 stud = 28 cm, 1 RMU = 21.952 kg.
- Roblox Creator Hub, [texture specifications](https://create.roblox.com/docs/en-us/art/modeling/texture-specifications.md).
- Ferrari 812 Superfast figures: [Ferrari press release](https://corporate.ferrari.com/en/ferrari-812-superfast-new-extreme-performance-v12-berlinetta) (power, torque, weights, performance); [autotijd.be](https://autotijd.be/en/specs/ferrari/812-superfast) (dimensions); [Ultimatecarpage](https://www.ultimatecarpage.com/spec/6773/Ferrari-812-Superfast.html), [Wikipedia](https://www.wikipedia.com/wiki/Ferrari_812_GTS) and [evo](https://www.evo.co.uk/ferrari/812-superfast/engine-transmission-and-technical-highlights) (tyres, brakes, track, 0–200 km/h).
- Treiber, Hennecke and Helbing (2000), "Congested traffic states in empirical observations and microscopic simulations", *Physical Review E* 62 (Intelligent Driver Model).
- Kesting, Treiber and Helbing (2007), "General lane-changing model MOBIL for car-following models", *Transportation Research Record* 1999.
- Pacejka (2012), *Tire and Vehicle Dynamics*, 3rd edition (magic formula tyre model).
