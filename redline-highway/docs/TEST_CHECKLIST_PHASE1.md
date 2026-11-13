# Phase 1 test checklist

None of this code has run in Roblox yet, so expect some errors on the first try. Work down the list
and stop at the first thing that fails. Then send me the exact text from Studio's **Output** window
(View > Output), a screenshot, and what you did. Red error lines name the script and line number.

## Setup

1. Open `build/RedlineHighway.rbxlx` in Roblox Studio (File > Open from File), or sync with Rojo
   (see the README).
2. In the Explorer, select **Lighting** and set **Technology** to **Future**. Scripts can't change
   this setting, and it makes the biggest visual difference.
3. Press **Play** (F5).

## M1. It loads and you're in the car

- [ ] Output shows `[Redline] Proving ground built in ... s (lap 8484 m)` with no red errors.
- [ ] A grey oval track with lane lines, barriers and light poles appears.
- [ ] A red stand-in car appears on the start grid and your avatar is sitting in it.
- [ ] The speed, gear and RPM panel shows at the bottom right, and the controls list at the bottom left.

## M2. It rests, drives, steers and stops

- [ ] Don't touch the controls for the first 4 seconds after the car appears. The Output window then
      prints a `[Redline] Self-test` block that checks the frame rate, gravity, the car's mass,
      wheel contact, wheel loads, ride height, creep, body angle and idle. Paste the whole block to
      me, whether it passes or not.

- [ ] Standing still, the car sits level and doesn't bounce, jitter or slide. In the telemetry
      overlay (press T), front wheel loads read about 3,900 N and rear loads about 4,400 N, with
      suspension travel near 0 mm.
- [ ] W pulls away smoothly. Engine RPM holds near 4,200 during the launch, then rises with speed.
- [ ] A and D steer. The car turns the way you press, and turning is gentler at high speed.
- [ ] S brakes to a stop in a straight line. "ABS" stays lit.
- [ ] Holding S at a standstill selects reverse (the gear shows R), and S then drives backwards.
- [ ] Space (handbrake) locks the rear wheels.
- [ ] R puts the car back on the nearest lane.

## M3. Gearbox and HUD

- [ ] Automatic mode shifts up near 8,750 rpm at full throttle and down as you slow.
- [ ] E and Q shift up and down and switch the mode to MANUAL; M switches back to AUTO.
- [ ] In manual, holding the revs at the limit shows LIMIT and flashes the shift light.
- [ ] B toggles ABS and V toggles traction control. The HUD shows "abs off" and "tc off".

## M4. Cameras

- [ ] C cycles chase, hood and cockpit cameras. The label above the dashboard says which.
- [ ] The chase camera stays behind the car at full speed instead of falling behind.
- [ ] The cockpit camera hides your avatar's head.

## M5. Performance against the factory figures

Use the 2.2 km main straight. The telemetry overlay (T) records each result.

- [ ] **0–100 / 0–200 km/h:** stop completely, then hold W. Model expectation: about 3.4 s / 8.2 s.
      Factory: 2.9 s / 7.9 s.
- [ ] **100–0 km/h braking:** go above 100 km/h, then hold S until stopped. Model expectation: about 28 m.
- [ ] **Top speed:** carry speed through a curve onto a straight. Model expectation: about 339 km/h,
      on the rev limiter in 7th.
- [ ] Frame rate stays smooth (the overlay shows fps).

## M7. Sound (after uploading the two sound files, see AUDIO.md)

- [ ] With both IDs pasted into AudioAssets, the Output shows no `[Redline] No sound asset ID` line.
- [ ] Idle is a steady, low burble. Revving up, the pitch rises smoothly, with no clicks, gaps or
      sudden steps in tone.
- [ ] Full throttle sounds harder than coasting at the same RPM. Lifting off changes the tone at once,
      and above about 4,000 rpm a few exhaust crackles follow.
- [ ] Full-throttle upshifts have a short crack and a clunk. Holding the limiter in manual (M, then E
      to a low gear) makes a bouncing sound.
- [ ] Hard ABS braking gives a light tyre hum. A handbrake slide squeals loudly. Driving straight
      doesn't squeal.
- [ ] Wind and road noise grow with speed. The cockpit camera (C) muffles the engine and wind.
- [ ] After R (respawn), the old car's sounds stop and the new car's start; nothing doubles up.
- [ ] Compare with `assets/audio/preview/GT12_drive_preview.mp3`. Tell me what sounds wrong or fake.

## Things to watch for

- The car hopping, bouncing or being launched into the air (suspension or force problems).
- Wheels jittering while parked.
- The car sliding sideways on its own, or spinning on gentle steering.
- Steering that feels far too twitchy or too slow.
- The camera snapping, shaking hard or clipping into the car.
- Anything you think feels wrong. Driving feel is the top priority.
