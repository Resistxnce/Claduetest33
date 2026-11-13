# Maps

Redline Highway has two maps, both in the same place, about 5 km apart so neither can be seen from
the other:

| | Redline Proving Ground ("Oval") | Sekirei Bay Loop ("City") |
|---|---|---|
| Picture | [docs/maps/oval.png](maps/oval.png) | [docs/maps/city.png](maps/city.png) |
| Length | 9.28 km (9,284 m) one-way loop | 12.69 km (12,687 m) one-way loop |
| Lanes | 4 lanes of 3.75 m, 3 m shoulders | 3 lanes of 3.5 m, shoulders 0.75 m (left) and 1.25 m (right) |
| Shape | two 2.4 km straights, two 180° curves of R 650 m with 200 m transitions | junction curves, S-bends, a 270° loop that climbs over itself, a 2.9 km bay straight |
| Height | level | 0.5 to 21.6 m above the street, grades up to 4.4% |
| Tunnels | covered gallery, 300 m | Kagerou Tunnel 2.5 km, Hotaru Tunnel 0.6 km |
| Light | late afternoon | night |
| Traffic | 5 cars per km per lane (about 180 cars) | 6 cars per km per lane (about 220 cars) |
| Parts (estimate) | about 4,700 | about 9,700 |

All names (the city, its junctions, tunnels and the brands on its billboards) are invented. The
city is an original route in the spirit of an elevated urban expressway; it copies no real road,
game or mod.

## Switching map and car

- **N** (gamepad: D-pad right), or the **map button** at the top right of the screen: go to the
  other map's start grid. The server allows one switch every 4 seconds.
- **G** (gamepad: D-pad left), or the **NEXT CAR** button: change to the next car, in alphabetical
  order of the configurations in `VehicleSystem/VehicleConfigurations`. The new car appears on the
  nearest lane; the server allows one change every 3 seconds and remembers the choice.
- **R** puts the car back on the nearest lane of the map you're on.

The car's name shows briefly under the score when it changes, and the map's name shows when you
arrive. Your banked close-pass score carries over between maps; an unbanked combo ends.

## Redline Proving Ground (the oval)

A highway test loop, built for measuring the car:

- **Main straight** (0 to 2.4 km, along +X): the start line at 150 m, the paddock and spawn point in
  the infield beside it, and distance boards every 100 m for 2 km (acceleration and braking runs).
- **Curve 1 and Curve 2**: R 650 m, each eased in and out by 200 m transition curves, so turning in
  at 250 km/h is smooth.
- **Back straight** (4.6 to 7.0 km): a 300 m covered gallery at 5.6 to 5.9 km (concrete roof, solid
  outer wall with an earth bank, open columns on the infield side, lamps), and a bridge over the
  road at 6.6 km.
- Concrete barriers, light poles every 60 m, four overhead sign gantries, a second bridge at 1.9 km,
  trees, grass and distant buildings.

## Sekirei Bay Loop (the city)

A night-time city expressway on concrete viaducts with tight parapet walls, sodium-lit tunnels,
sweeping junctions and a straight along the bay. Distances are along the loop from the start line
area (s = 0 is the east end of the bay straight; you drive west first, with the bay on your left):

| s (m) | Section | What it is |
|---|---|---|
| 0 to 2,600 | Seaside Straight | On piers over the water, 14 m up; with the 300 m before s = 0 it's a 2.9 km straight. Start line at 150 m. |
| 2,600 to 3,337 | Kirameki JCT | Right, R 380, climbing to 22 m. A decorative viaduct passes under it and runs 3.7 km across the bay. |
| 3,337 to 5,156 | Ward S-bends | Left R 260, right R 240, between glass noise screens and close buildings, then down to street level. |
| 5,100 to 7,600 | **Kagerou Tunnel** | 2.5 km box tunnel under a built-over deck with buildings on top; sodium lamps on both walls, jet fans, exit signs; a gentle S (R 1,100) near the far end. |
| 7,600 to 9,125 | Loop approach | Climbs to 9 m and passes under the loop's exit. |
| 9,125 to 10,225 | Tsukimi JCT loop | Left 270°, R 210, climbing to 20 m; at s ≈ 10,380 it crosses about 10 m over the approach. |
| 10,950 to 11,550 | **Hotaru Tunnel** | 0.6 km tunnel through the east S-bend (R 450), with a park on top. |
| 11,587 to 12,387 | Umikaze JCT | Right, R 420, back up to 14 m and onto the bay. A suspension bridge crosses overhead and runs out across the bay. |

Around it: dense buildings on both sides with lit windows and a few billboards, a taller skyline
farther back, piers in the water, the bay with a far shore, lamps every 40 m (alternating sides),
and six sign gantries.

**Speeds.** The tightest corner is the loop (R 210 m). Traffic takes it at about 65 to 90 km/h; a
grippy car can take it at about 170 km/h. The S-bends (R 240 to 260) go at about 175 km/h, and the
junction curves (R 380 to 420) at about 210 to 230 km/h.

## How the maps work (for developers)

- **Map data:** `ReplicatedStorage/TrafficSystem/Maps/Oval.luau` and `City.luau`.
  - The plan is straights and curves (radius, angle, transition length).
  - The elevation is points with vertical curves.
  - Sections are tunnels.
  - Also: lanes, lane width, shoulders, where the map sits in the world, start line, lighting
    preset, traffic settings, and (city) the shore and the decorative viaducts.

  The modules hold plain values only, so the Python tools can read them.
- **RoadGeometry** (`TrafficSystem/RoadGeometry.luau`) turns the data into an exact road.
  - Every piece is a straight or a circular arc. Transition curves are stored as arcs of stepped
    curvature, 8 m at most.
  - `road:frame(s, offset, height)` gives world position and direction, pitched with the grade.
  - `road:project(position)` gives road coordinates, tests about 3 to 5 pieces per call through a
    64 m grid, and picks the right level where the road passes over itself.
  - `road:speedLimits(...)` makes traffic's curve speeds.
  - `MapRegistry` lists the maps and builds each road once.
- **Builders** (server): `RoadKit` (shared road, wall, tunnel, gantry and part helpers), `TrackBuilder`
  (the oval) and `CityBuilder` (the city).
  - They build into `Workspace.Maps.Oval` and `Workspace.Maps.City`.
  - `MapService` builds both at startup, prints each map's part count, and keeps which map each
    player is on: the Player attribute `MapId` is "Oval" or "City".
- **Traffic:** one `TrafficService` per map. Players are only sent the traffic of their own map.
  - Each map's car ids start at its `traffic.idBase` (oval 1, city 30,001), so ids never clash.
  - Traffic slows for curves. Each driver profile has a sideways-acceleration comfort limit
    (cautious 2.0, normal 2.4, aggressive 3.0, trucks 1.6 m/s²) and brakes gently (1 m/s²)
    before a curve.
  - Trucks keep to the two right-hand lanes on both maps.
- **Lighting:** `Gameplay/MapLighting` has the "Afternoon" and "Night" presets.
  - The server sets the afternoon when the game starts.
  - Each client applies its own map's preset, which affects only that player.
  - Set Lighting.Technology to Future in Studio; scripts can't.
- **Tunnel sound** (for `AudioEnvironment`): every tunnel's inside is covered by invisible boxes
  tagged `TunnelZone`.
  - Each box is anchored, not colliding, not queryable and not touchable. It runs from the road to
    the ceiling and wall to wall.
  - The boxes end exactly at the portals and overlap by 1 m where they join.
  - Attributes: `ReverbDecay` (Kagerou 2.2 s, Hotaru 1.6 s, oval gallery 0.8 s), `TunnelName`
    and `MapId`.
- **Camera:** the chase camera moves in rather than through tunnel walls, ceilings and parapets.

### Changing a map

- **Edit and check.** Edit the map's data module, then run `python3 tools/road_geometry.py`. It
  checks the change: the loop must close, grades must stay at 6% or less, and vertical curves
  mustn't overlap.
- **Closure.** On the city, two straights were solved so the loop closes exactly. If you change the
  plan, re-solve two straights that point in different directions; the end position moves exactly
  with their lengths. The game warns in Output if a loop doesn't close.
- **Afterwards.** Run `python3 tools/traffic_model.py` and `python3 tools/map_pictures.py`.
- **Part count.** The main knobs are in `CityBuilder`: building density (the 0.72 and 0.6 chances
  per spot), `LAMP_SPACING`, `PIER_SPACING`, and the lane-line `DASH`/`GAP`.

## Checks done without Studio

| Tool | What it checks | Result |
|---|---|---|
| `tools/road_geometry.py` | Python copy of RoadGeometry, reading the real map data: closure, continuity, round trips, curve speeds, grades, speed | Both maps pass all 10 checks each |
| `tools/traffic_model.py` | Python copy of the traffic simulation on both maps: light and heavy traffic, a crash blocking a lane, a 300 km/h player, a slow player | No collisions in any test; no traffic pulls out in front of the fast player |
| `tools/close_pass_model.py` | Python copy of the close-pass scoring, with both maps' loop lengths | All 14 tests pass |
| `tools/map_pictures.py` | Draws `docs/maps/*.png` from the map data | |
| `tools/luau_check.py` | Every script parses and uses real Roblox API | 0 errors |

Details for each:
- **Road geometry.**
  - The loop closes to under a millionth of a millimetre.
  - Position, direction, height and grade are continuous across every piece and vertical curve to
    1e-8 m.
  - Road -> world -> road round trips agree to 1e-10 m, including on the city's two levels.
  - Every lane at traffic's curve speed stays within its comfort limit.
  - Crests keep a car on the ground past 800 km/h, and dips add at most 0.1 g at 300 km/h.
- **Traffic.**
  - City light traffic: 228 cars, mean 101 km/h. Heavy: 1,700 cars/h/lane.
  - In curves, cars use at most 108% of their sideways comfort limit, briefly at the start of a
    curve.
- **Pictures.** Oval and city, with road type, tunnels, distances, a scale bar and an elevation
  profile.

## What to test in Studio

1. **Startup.** Output shows the following, and no `[RoadGeometry] ... doesn't close` warning:
   - `[Redline] Map Oval (Redline Proving Ground) built in ... s: 9.3 km, 4 lanes, ... parts`;
   - `[Redline] Map City (Sekirei Bay Loop) built in ...: 12.7 km, 3 lanes, ... parts`;
   - `[Redline] Traffic on Oval: ...` and `[Redline] Traffic on City: ...`.

   Note the part counts and how long the build took.
2. **Spawn on the oval.** You spawn on the oval grid. The self-test shows the car, map and
   distance (`... on Redline Proving Ground, ... m along its 9.3 km road`), and
   `resting on the road` passes.
3. **Drive the oval.** Smooth transitions into both curves. The gallery on the back straight is lit
   inside, and the tunnel sound changes there if audio is set up. Check the bridges, gantries and
   distance boards.
4. **Switch to the city (N or the button).** "TO SEKIREI BAY LOOP" shows, then you're on the city
   grid at night with traffic (headlights and tail lights). Pressing N again within 4 s says
   "One moment...".
5. **Drive the whole city loop.** Look for:
   - gaps between road pieces on curves;
   - walls that are too low or too high;
   - floating or buried piers;
   - lamps or gantries cutting through anything.

   Places to check: Kagerou Tunnel (2.5 km, sodium lamps, lit enough to drive?), the loop and its
   crossing over the approach, Hotaru Tunnel, and the Umikaze bridge overhead.
6. **City traffic.** It slows for the loop and the S-bends without bunching into stops, and nobody
   drives through you.
7. **Respawn.** R puts you on the nearest lane of the current map, including on the loop's upper
   level, in a tunnel, and after dropping off a viaduct onto the street.
8. **Car change (G or NEXT CAR).** Once there's more than one car, G cycles them, shows the name,
   and spawns the new car level on the road. Different sizes must spawn at the right height.
9. **Back to the oval (N).** Afternoon light returns, and so does the oval's traffic.
10. **Camera.** The chase camera stays inside tunnels and doesn't go through parapets on tight
    curves.
11. **Tunnel zones.** In the command bar during Play:
    `print(#game:GetService("CollectionService"):GetTagged("TunnelZone"))` prints a number above 0.
12. **Frame rate.** Check it in the city at night with traffic (telemetry overlay, T), and report
    the fps in the tunnel and on the bay straight.
