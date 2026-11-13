# Redline Highway

*Working title.* An original high-speed highway driving and racing game for Roblox. This folder holds
**Phase 1**: the shared vehicle physics framework, the first prototype car (the Valenza GT12, built to
the Ferrari 812 Superfast's public engineering figures), a proving-ground test track, cameras and a
dashboard with telemetry. It also has the start of **Phase 2**, the car's sound system with
placeholder sounds (see `docs/AUDIO.md`); the start of **Phase 4**, highway traffic that follows,
passes and makes room using two standard traffic research models (IDM and MOBIL), on **two maps**:
the Redline Proving Ground oval and Sekirei Bay Loop, a night-time city expressway with tunnels; and
a first **close-pass score** with combos, the arcade layer of the game.

**Status:** written and checked outside Roblox, **not yet run in Roblox Studio.** The place file was
generated and checked for structure, and the drivetrain maths was tested in a Python copy (see
`docs/PROTOTYPE_GT12.md`). Expect a round of fixes on the first Play test; `docs/TEST_CHECKLIST_PHASE1.md`
says what to check.

## Open it on your PC

Get this folder onto your computer first. On GitHub, open the `claude/sharp-feynman-t035au` branch of
this repository and use **Code > Download ZIP**, or clone the repository and check out that branch.

**Option A: place file (simplest).** In Roblox Studio, use **File > Open from File** and pick
`redline-highway/build/RedlineHighway.rbxlx`.

**Option B: Rojo.** In this folder, run `rojo serve` and connect from the Rojo plugin in Studio, or run
`rojo build -o RedlineHighway.rbxlx` to make a place file. If you sync into a template place such as
Baseplate, delete its Baseplate and SpawnLocation first, because they overlap the track.

Then:
1. Select **Lighting** and set **Technology** to **Future** (scripts can't set it).
2. Press **Play**.
3. For sound, upload the two files in `assets/audio` and paste their IDs into
   **ReplicatedStorage > VehicleSystem > VehicleAudio > AudioAssets** (see `docs/AUDIO.md`). Without
   them the game runs silently. To hear the sounds first, play `assets/audio/preview/GT12_drive_preview.mp3`.

## Controls

| Key | Action |
|---|---|
| W / S | accelerate / brake (hold S when stopped to reverse) |
| A / D | steer |
| Space | handbrake |
| E / Q | shift up / down (switches to manual) |
| M | automatic / manual gearbox |
| B / V | ABS / traction control on or off |
| C | camera: chase, hood, cockpit |
| R | put the car back on the track |
| T / H | telemetry overlay / controls list |
| N | switch map (Oval / City); gamepad D-pad right |
| G | next car; gamepad D-pad left |

Gamepads work too: triggers for the pedals, left stick to steer, bumpers to shift, X for the
handbrake, Y for the camera.

## Files

| Path | What it is |
|---|---|
| `docs/DEVELOPMENT_PLAN.md` | The technical plan: Roblox limits, architecture, physics design, phases, milestones |
| `docs/PROTOTYPE_GT12.md` | The prototype's specification: sources, estimates and validation |
| `docs/TEST_CHECKLIST_PHASE1.md` | What to test in Studio and what to report |
| `docs/AUDIO.md` | The sound system: uploading the sounds, how it works, tuning, recordings |
| `docs/MAPS.md`, `docs/maps/` | The two maps: layouts, lengths, what to test, and top-down pictures |
| `assets/audio/` | The two sound files to upload, and a preview of the car driving |
| `src/` | All scripts, laid out by Studio service (see the plan for what each does) |
| `build/RedlineHighway.rbxlx` | Ready-to-open place file, generated from `src/` |
| `default.project.json` | Rojo project |
| `tools/build_place.py` | Rebuilds the place file from `src/` (Python 3, no other tools needed) |
| `tools/drivetrain_model.py` | Python copy of the drivetrain code for quick straight-line checks |
| `tools/luau_check.py` | Checks every script for syntax errors, typos and Roblox API mistakes (see below) |
| `tools/synth_audio.py` | Makes the placeholder sounds and their region tables (needs numpy and ffmpeg) |
| `tools/audio_preview.py` | Renders the preview drive with a Python copy of the game's sound mixer |
| `tools/traffic_model.py` | Python copy of the traffic simulation with collision and behaviour tests |
| `tools/close_pass_model.py` | Python copy of the close-pass scoring with tests |
| `tools/road_geometry.py` | Python copy of the road geometry with tests (closure, continuity, round trips, curve speeds) |
| `tools/map_pictures.py` | Draws the top-down map pictures in `docs/maps/` |
| `tools/render_models.py` | Draws every car's stand-in model to `docs/models/lineup.png` |

After editing anything in `src/`, run `python3 tools/build_place.py` to refresh the place file.

## Checking the code without Studio

`tools/luau_check.py` parses every script as Luau and checks it against Roblox's own API list:
syntax, undefined or misspelled variables, library functions, `require` paths, module members, and the
classes, services, properties, methods, events and enums the code uses. It needs only Python 3.

```
curl -s https://setup.rbxcdn.com/versionQTStudio        # prints a version, e.g. version-0123456789abcdef
curl -o API-Dump.json https://setup.rbxcdn.com/<version>-API-Dump.json
python3 tools/luau_check.py --api-dump API-Dump.json --verbose
```

It can't catch everything Roblox's own Script Analysis does (full type checking) or anything that
only goes wrong while the game runs, so the Play test is still the real test.
