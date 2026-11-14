#!/usr/bin/env python3
"""Render what a car sounds like, outside Roblox.

Drives the car with tools/drivetrain_model.py, runs line-for-line Python copies of the game's sound
code on every frame and plays the sound packs the way the game's Sounds do (each layer loops its
region at the mixer's volume and playback speed; one-shots play on voices). Settings come from the
car's configuration and the sheet tables, so the preview uses the same numbers as the game.

  EngineMix      src/ReplicatedStorage/VehicleSystem/VehicleAudio/EngineMix.luau
  TunnelMath     src/StarterPlayer/StarterPlayerScripts/Client/AudioEnvironment.luau
  TrafficMix     src/ReplicatedStorage/VehicleSystem/VehicleAudio/TrafficMix.luau

Writes to assets/audio/preview/ (each with a spectrogram picture):
  <car>_drive_preview.mp3     idle; a free rev to the limiter, held; a launch through the gears with
                              full-throttle upshifts; a hold on the limiter in 2nd; a lift-off; braking
  <car>_tunnel_preview.mp3    a pass through a tunnel at speed (reverb, slap echo, low-mid build-up,
                              level rise, easing in and out at the portals)
  Traffic_driveby_preview.mp3 traffic passing a roadside listener (distance roll-off, air absorption,
                              Doppler), in stereo
(<car> is GT12 for Prototype812, else the config id.)
Roblox's reverb and echo can't be copied exactly; the tunnel render approximates them (see
docs/AUDIO.md).

Usage: python3 tools/audio_preview.py [--car Prototype812] [--only drive|tunnel|driveby]
(needs numpy and ffmpeg; run tools/synth_audio.py first)
"""
import argparse
import inspect
import math
import pathlib
import random
import struct
import subprocess
import sys
import wave
import zlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import drivetrain_model as dm  # noqa: E402
from luau_table import load as luau_table  # noqa: E402

FS = 44100
FRAME = 1 / 60
AUDIO_DIR = ROOT / "assets" / "audio"
SHEETS = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleAudio" / "Sheets"
CONFIGS = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleConfigurations"
OUT_DIR = AUDIO_DIR / "preview"
EFFECT_LOOPS = ["squeal", "road", "wind", "whine"]


# --------------------------------------------------------------------------------------------
# Python copy of EngineMix.luau
# --------------------------------------------------------------------------------------------

HALF_PI = math.pi / 2


def clamp(x, a, b):
    return max(a, min(b, x))


def rpm_weights(points, rpm, out):
    n = len(points)
    for i in range(n):
        out[i] = 0
    if rpm <= points[0]:
        out[0] = 1
        return out
    if rpm >= points[-1]:
        out[-1] = 1
        return out
    for i in range(n - 1):
        a, b = points[i], points[i + 1]
        if rpm <= b:
            t = math.log(rpm / a) / math.log(b / a)
            out[i] = math.cos(t * HALF_PI)
            out[i + 1] = math.sin(t * HALF_PI)
            break
    return out


class EngineMix:
    def __init__(self, spec, engine_sheet, effects_sheet, rng):
        self.spec = spec
        loops = engine_sheet["loops"]
        self.loop_rpm = [loop.get("rpm", 0) for loop in loops]
        self.loop_gain = [loop.get("gain", 1) for loop in loops]
        self.has_gains = any("gain" in loop for loop in loops)
        self.engine_volume = [0.0] * len(loops)
        self.engine_speed = [1.0] * len(loops)
        self.limiter_free = None
        self.limiter_load = None
        self.turbo_loop = None
        self.turbo_base_hz = 1.0
        self.turbo_min_hz = 1.0
        self.turbo_max_hz = 1.0
        self.blow_off_names = []
        self.whine_loops = []
        pairs = {}
        for i, loop in enumerate(loops):
            if loop.get("load") in ("on", "off"):
                pairs.setdefault(math.floor(loop["rpm"] + 0.5), {"rpm": loop["rpm"]})[loop["load"]] = i
            elif loop.get("load") == "limiter":
                if loop.get("kind") == "free":
                    self.limiter_free = i
                else:
                    self.limiter_load = i
            elif loop.get("layer") == "turbo":
                self.turbo_loop = i
                self.turbo_base_hz = loop["baseHz"]
            elif loop.get("layer") == "supercharger":
                self.whine_loops.append(i)
        ordered = sorted(pairs.values(), key=lambda p: p["rpm"])
        self.points = [p["rpm"] for p in ordered]
        self.on_loop = [p.get("on", p.get("off")) for p in ordered]
        self.off_loop = [p.get("off", p.get("on")) for p in ordered]
        self.limiter_free = self.limiter_free if self.limiter_free is not None else self.limiter_load
        self.limiter_load = self.limiter_load if self.limiter_load is not None else self.limiter_free
        if engine_sheet.get("turbo"):
            self.turbo_min_hz = engine_sheet["turbo"]["minHz"]
            self.turbo_max_hz = engine_sheet["turbo"]["maxHz"]
        self.blow_off_names = [s["name"] for s in engine_sheet.get("oneShots", []) if s.get("layer") == "blowoff"]
        self.whine_loops.sort(key=lambda i: loops[i]["rpm"])
        self.whine_rpm = [loops[i]["rpm"] for i in self.whine_loops]
        self.whine_base_hz = [loops[i]["baseHz"] for i in self.whine_loops]
        self.whine_weights = [0.0] * len(self.whine_loops)
        self.whine_hz_per_rpm = 0.0
        if engine_sheet.get("supercharger"):
            sc = engine_sheet["supercharger"]
            self.whine_hz_per_rpm = sc["driveRatio"] * sc["pulsesPerRev"] / 60
        self.effects = {name: {"volume": 0.0, "speed": 1.0} for name in EFFECT_LOOPS}
        self.events = []
        self.weights = [0.0] * len(self.points)
        self.load = 0.0
        self.last_gear = 0
        self.upshift_timer = 0.0
        self.since_high_load = math.inf
        self.crackle_time = 0.0
        self.bump_cooldown = 0.0
        self.whine_hz = 1000.0
        self.crackle_names = []
        self.limiter_seen = math.inf
        self.since_shift = math.inf
        self.limiter_mix = 0.0
        self.free_mix = 0.0
        self.limiter_rpm = 0.0
        self.limiter_rpm_sheet = engine_sheet.get("limiterRpm", math.inf)
        self.pedal_peak = 0.0
        self.boost_peak = 0.0
        self.blow_off_cooldown = 0.0
        self.random = rng
        if effects_sheet:
            for loop in effects_sheet["loops"]:
                if loop["name"] == "whine" and "baseHz" in loop:
                    self.whine_hz = loop["baseHz"]
            self.crackle_names = [s["name"] for s in effects_sheet["oneShots"] if s["name"].startswith("crackle_")]

    def event(self, name, volume, speed, sheet="effects"):
        self.events.append((name, volume, speed, sheet))

    def update(self, dt, inp):
        spec = self.spec
        self.events.clear()
        rpm = max(inp["rpm"], 1)
        interior = spec["interior"]
        engine_gain = interior["engine"] if inp["interior"] else 1
        if self.has_gains:
            loud = spec["engineVolume"] * engine_gain
        else:
            loud = spec["engineVolume"] * engine_gain * (
                spec["idleLevel"] + (1 - spec["idleLevel"]) * clamp(rpm / spec["redlineRpm"], 0, 1.1) ** spec["rpmCurve"])

        gear = inp["gear"]
        if inp["shifting"] or gear != self.last_gear:
            self.since_shift = 0.0
        else:
            self.since_shift += dt

        if gear != self.last_gear:
            if gear > self.last_gear and self.last_gear >= 1:
                if self.load > 0.5 and inp["load"] > 0.5 and rpm > spec["shiftCutMinRpm"]:
                    self.upshift_timer = spec["shiftCutTime"]
                    self.event("shift_cut", spec["shiftCutVolume"] * loud, 1)
                self.event("shift_clunk", spec["shiftClunkVolume"] * engine_gain, 1)
            elif self.last_gear != 0 and gear != 0:
                self.event("shift_clunk", spec["shiftClunkVolume"] * 0.7 * engine_gain, 0.9)
            self.last_gear = gear
        self.upshift_timer = max(0, self.upshift_timer - dt)

        target = clamp(inp["load"], 0, 1)
        if self.upshift_timer > 0:
            target *= 0.3
        rate = spec["loadAttack"] if target > self.load else spec["loadRelease"]
        self.load += (target - self.load) * clamp(rate * dt, 0, 1)
        load = self.load

        if inp["limiter"] and self.since_shift > spec.get("limiterShiftMask", 0.15):
            self.limiter_seen = 0.0
        else:
            self.limiter_seen += dt
        near_limit = rpm > 0.92 * self.limiter_rpm_sheet
        limiter_target = 1 if (self.limiter_free is not None and self.limiter_seen < spec["limiterHold"]
                               and inp["pedal"] > 0.5 and near_limit) else 0
        limiter_rate = spec["limiterAttack"] if limiter_target > self.limiter_mix else spec["limiterRelease"]
        self.limiter_mix += (limiter_target - self.limiter_mix) * clamp(limiter_rate * dt, 0, 1)
        free_target = 1 if (inp["gear"] == 0 or inp["clutch"] < 0.5) else 0
        self.free_mix += (free_target - self.free_mix) * clamp(8 * dt, 0, 1)
        self.limiter_rpm += (rpm - self.limiter_rpm) * clamp(3 * dt, 0, 1)
        keep = 1 - self.limiter_mix

        on = math.sqrt(load)
        off = math.sqrt(1 - load) * (1 if self.has_gains else spec["offThrottleLevel"])
        rpm_weights(self.points, rpm, self.weights)
        for k, w in enumerate(self.weights):
            on_i, off_i = self.on_loop[k], self.off_loop[k]
            self.engine_volume[on_i] = loud * w * on * keep * self.loop_gain[on_i]
            self.engine_speed[on_i] = clamp(rpm / self.loop_rpm[on_i], spec["minPitch"], spec["maxPitch"])
            if off_i != on_i:
                self.engine_volume[off_i] = loud * w * off * keep * self.loop_gain[off_i]
                self.engine_speed[off_i] = clamp(rpm / self.loop_rpm[off_i], spec["minPitch"], spec["maxPitch"])
        if self.limiter_free is not None:
            free, in_gear = self.limiter_free, self.limiter_load
            mix = self.limiter_mix
            if free == in_gear:
                self.engine_volume[free] = loud * mix * self.loop_gain[free]
            else:
                self.engine_volume[free] = loud * mix * math.sqrt(self.free_mix) * self.loop_gain[free]
                self.engine_volume[in_gear] = loud * mix * math.sqrt(1 - self.free_mix) * self.loop_gain[in_gear]
                self.engine_speed[in_gear] = clamp(self.limiter_rpm / self.loop_rpm[in_gear], 0.97, 1.03)
            self.engine_speed[free] = clamp(self.limiter_rpm / self.loop_rpm[free], 0.97, 1.03)

        boost = clamp(inp["boost"], 0, 1)
        if self.turbo_loop is not None:
            hz = self.turbo_min_hz + (self.turbo_max_hz - self.turbo_min_hz) * math.sqrt(boost)
            self.engine_volume[self.turbo_loop] = spec["turboVolume"] * engine_gain * boost ** 1.2 * (0.35 + 0.65 * load)
            self.engine_speed[self.turbo_loop] = clamp(hz / self.turbo_base_hz, 0.3, 3)
        self.pedal_peak = max(inp["pedal"], self.pedal_peak - 3 * dt)
        self.boost_peak = max(boost, self.boost_peak - 2 * dt)
        self.blow_off_cooldown = max(0, self.blow_off_cooldown - dt)
        if (self.blow_off_names and inp["pedal"] < 0.2 and self.pedal_peak > 0.6
                and self.boost_peak > spec["blowOffMinBoost"] and self.blow_off_cooldown <= 0):
            self.blow_off_cooldown = 1
            self.pedal_peak = 0
            name = self.blow_off_names[self.random.randint(1, len(self.blow_off_names)) - 1]
            self.event(name, spec["blowOffVolume"] * engine_gain * self.boost_peak, 0.95 + 0.1 * self.random.random(), "engine")
        if self.whine_loops:
            rpm_weights(self.whine_rpm, rpm, self.whine_weights)
            idle_share = spec.get("superchargerIdleShare", 0.2)
            full_rpm = spec.get("superchargerFullRpm", 2500)
            rpm_floor = spec.get("superchargerRpmFloor", 0.3)
            level = (spec["superchargerVolume"] * engine_gain * (idle_share + (1 - idle_share) * boost)
                     * clamp(rpm / full_rpm, rpm_floor, 1))
            for k, index in enumerate(self.whine_loops):
                self.engine_volume[index] = level * self.whine_weights[k]
                self.engine_speed[index] = clamp(rpm * self.whine_hz_per_rpm / self.whine_base_hz[k], 0.25, 4)

        if load > 0.6:
            self.since_high_load = 0
        else:
            self.since_high_load += dt
        if (self.crackle_time <= 0 and inp["load"] < 0.1 and self.since_high_load < 0.3
                and rpm > spec["crackleMinRpm"] and not inp["limiter"] and self.crackle_names):
            self.crackle_time = spec["crackleDuration"]
        if self.crackle_time > 0:
            self.crackle_time -= dt
            if inp["load"] > 0.3:
                self.crackle_time = 0
            remaining = clamp(self.crackle_time / spec["crackleDuration"], 0, 1)
            rpm_share = clamp(rpm / 7000, 0.4, 1)
            chance = spec["crackleRate"] * remaining * remaining * rpm_share * dt
            if self.random.random() < chance:
                name = self.crackle_names[self.random.randint(1, len(self.crackle_names)) - 1]
                volume = spec["crackleVolume"] * engine_gain * (0.4 + 0.6 * self.random.random()) * rpm_share
                self.event(name, volume, 0.85 + 0.35 * self.random.random())

        self.bump_cooldown = max(0, self.bump_cooldown - dt)
        if inp["bump"] > spec["bumpMinSpeed"] and self.bump_cooldown <= 0:
            self.bump_cooldown = 0.15
            self.event("bump_knock", spec["bumpVolume"] * clamp(inp["bump"] / 2, 0.3, 1), 1)

        speed = inp["speed"]
        fx = self.effects
        slip_over = inp["slip"] - spec["squealStart"]
        squeal = clamp(slip_over / spec["squealRange"], 0, 1) * clamp(inp["slideSpeed"] / 1.5, 0, 1)
        fx["squeal"]["volume"] = spec["squealVolume"] * squeal ** 1.5 * (interior["squeal"] if inp["interior"] else 1)
        fx["squeal"]["speed"] = 0.92 + 0.18 * clamp(slip_over, 0, 1)
        fx["road"]["volume"] = spec["roadVolume"] * clamp(speed / 45, 0, 1) ** 1.2 * (interior["road"] if inp["interior"] else 1)
        fx["road"]["speed"] = 0.75 + 0.5 * clamp(speed / 80, 0, 1)
        wind = clamp(speed / 95, 0, 1.15)
        fx["wind"]["volume"] = spec["windVolume"] * wind * wind * (interior["wind"] if inp["interior"] else 1)
        fx["wind"]["speed"] = 0.7 + 0.6 * clamp(speed / 95, 0, 1)
        shaft_rpm = abs(inp["shaftRpm"])
        fx["whine"]["volume"] = (spec["whineVolume"] * engine_gain * clamp(shaft_rpm / 7000, 0, 1) * (0.4 + 0.6 * load)
                                 if gear != 0 else 0)
        fx["whine"]["speed"] = clamp(shaft_rpm / 60 * spec["whineTeeth"] / self.whine_hz, 0.2, 3)


# --------------------------------------------------------------------------------------------
# Playing the sheets like the game's Sounds
# --------------------------------------------------------------------------------------------

def decode(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-f", "s16le", "-ac", "1",
                          "-ar", str(FS), "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32767


class LoopLayer:
    def __init__(self, sheet_audio, region):
        a, b = round(region["loopStart"] * FS), round(region["loopEnd"] * FS)
        self.data = sheet_audio[a:b]
        self.pos = 0.0
        self.volume = 0.0

    def render(self, n, volume, speed):
        v0, self.volume = self.volume, volume
        if v0 < 1e-5 and volume < 1e-5:
            self.pos = (self.pos + speed * n) % len(self.data)
            return None
        p = self.pos + speed * np.arange(n)
        i = np.floor(p).astype(int)
        frac = p - i
        L = len(self.data)
        out = self.data[i % L] * (1 - frac) + self.data[(i + 1) % L] * frac
        self.pos = (self.pos + speed * n) % L
        return out * np.linspace(v0, volume, n, endpoint=False)


class Voice:
    def __init__(self, data, volume, speed):
        self.data, self.volume, self.speed, self.pos = data, volume, speed, 0.0

    def render(self, n):
        p = self.pos + self.speed * np.arange(n)
        p = p[p < len(self.data) - 1]
        if len(p) == 0:
            return None
        i = np.floor(p).astype(int)
        frac = p - i
        out = np.zeros(n)
        out[: len(p)] = (self.data[i] * (1 - frac) + self.data[i + 1] * frac) * self.volume
        self.pos += self.speed * n
        return out


# --------------------------------------------------------------------------------------------
# Python copy of TunnelMath (Client/AudioEnvironment.luau)
# --------------------------------------------------------------------------------------------

class TunnelMath:
    APPROACH_M = 12
    APPROACH_SHARE = 0.4
    EASE_M = 15
    MIN_RATE = 1.2
    DEFAULT_DECAY = 1.6
    DEFAULT_WET = -4
    LEVEL_RISE = 0.26
    LOW_GAIN = 5
    MID_GAIN = 1.5
    HIGH_GAIN = -2
    ECHO_WET = -14
    ECHO_FEEDBACK = 0.3

    @staticmethod
    def target(outside_m):
        if outside_m <= 0:
            return 1
        return clamp(1 - outside_m / TunnelMath.APPROACH_M, 0, 1) * TunnelMath.APPROACH_SHARE

    @staticmethod
    def ease(amount, target, speed, dt):
        rate = max(TunnelMath.MIN_RATE, 3 * speed / TunnelMath.EASE_M)
        return amount + (target - amount) * clamp(rate * dt, 0, 1)

    @staticmethod
    def wet_level(amount, wet):
        return -40 + (wet + 40) * math.sqrt(amount)

    @staticmethod
    def echo_delay(width_m):
        return clamp(width_m / 343, 0.02, 0.08)


# --------------------------------------------------------------------------------------------
# Python copy of TrafficMix.luau
# --------------------------------------------------------------------------------------------

class TrafficMix:
    SPEED_OF_SOUND = 343
    ROLLOFF_MIN_M = 6
    ROLLOFF_MAX_M = 450
    ENGINE_VOLUME = 1.6
    TYRE_VOLUME = 0.9
    PROFILES = {
        "car": dict(wheelRadius=0.32, gears=[3.6, 2.1, 1.4, 1.0, 0.8, 0.66], finalDrive=3.9, idleRpm=800,
                    maxRpm=6000, cruiseRpm=1700, pullRpm=3800),
        "truck": dict(wheelRadius=0.52, gears=[9.5, 6.6, 4.7, 3.4, 2.4, 1.7, 1.3, 1.0], finalDrive=3.4, idleRpm=600,
                      maxRpm=2100, cruiseRpm=1150, pullRpm=1700),
    }

    @staticmethod
    def engine_rpm(profile, speed, load):
        wheel_rpm = max(speed, 0) / (2 * math.pi * profile["wheelRadius"]) * 60
        want = profile["cruiseRpm"] + (profile["pullRpm"] - profile["cruiseRpm"]) * load
        gears = profile["gears"]
        chosen = 1
        for g in range(len(gears), 0, -1):
            if wheel_rpm * gears[g - 1] * profile["finalDrive"] >= want:
                chosen = g
                break
        rpm = wheel_rpm * gears[chosen - 1] * profile["finalDrive"]
        return clamp(rpm, profile["idleRpm"], profile["maxRpm"]), chosen

    @staticmethod
    def load(accel):
        return clamp(0.3 + accel / 2.0, 0, 1)

    @staticmethod
    def levels(profile, speed, load, rpm):
        engine = TrafficMix.ENGINE_VOLUME * (0.35 + 0.65 * load) * clamp(rpm / profile["pullRpm"], 0.2, 1.5) ** 0.7
        tyre = TrafficMix.TYRE_VOLUME * clamp(speed / 30.5, 0, 1.4) ** 1.6
        return engine, tyre

    @staticmethod
    def doppler(offset, source_vel, listener_vel):
        distance = float(np.linalg.norm(offset))
        if distance < 0.01:
            return 1
        to_listener = -offset / distance
        c = TrafficMix.SPEED_OF_SOUND
        approach = clamp(float(np.dot(source_vel, to_listener)), -0.5 * c, 0.5 * c)
        meet = clamp(float(-np.dot(listener_vel, to_listener)), -0.5 * c, 0.5 * c)
        return clamp((c + meet) / (c - approach), 0.5, 2)

    @staticmethod
    def air_absorption(distance_m):
        return -min(distance_m * 0.012, 8), -min(distance_m * 0.06, 30)

    @staticmethod
    def roll_off(distance_m):
        near, far = TrafficMix.ROLLOFF_MIN_M, TrafficMix.ROLLOFF_MAX_M
        if distance_m <= near:
            return 1
        if distance_m >= far:
            return 0
        linear = (far - distance_m) / (far - near)
        return min(near / distance_m, linear * linear)


# --------------------------------------------------------------------------------------------
# Approximations of Roblox's sound effects (for the tunnel and drive-by renders)
# --------------------------------------------------------------------------------------------

def bands(x):
    """Split into the EqualizerSoundEffect's three bands: below 400 Hz, 400 Hz-4 kHz, above 4 kHz."""
    n = len(x)
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(n, 1 / FS)
    low_w = 1 / np.sqrt(1 + (f / 400.0) ** 8)
    high_w = 1 - 1 / np.sqrt(1 + (f / 4000.0) ** 8)
    low = np.fft.irfft(spec * low_w, n=n)
    high = np.fft.irfft(spec * high_w, n=n)
    return low, x - low - high, high


def per_sample(values, n):
    """Per-frame values (one per 1/60 s) spread over n samples."""
    frames = np.arange(len(values)) * FRAME * FS
    return np.interp(np.arange(n), frames, values)


def reverb_ir(decay, rng):
    """Synthetic impulse response: diffuse noise decaying to -60 dB in `decay` seconds (highs
    faster), after a short pre-delay. Unit energy, so WetLevel 0 dB means equal energy."""
    n = int(min(decay * 1.2, 4.0) * FS)
    t = np.arange(n) / FS
    noise = rng.standard_normal(n)
    low, mid, high = bands(noise)
    ir = (low * np.exp(-6.91 * t / (decay * 1.15)) + mid * np.exp(-6.91 * t / decay)
          + high * np.exp(-6.91 * t / (decay * 0.5)))
    ir[: int(0.012 * FS)] = 0
    return ir / np.sqrt(np.sum(ir * ir))


def convolve(x, ir):
    n = len(x) + len(ir)
    size = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x)]


def echo(x, delay_s, feedback):
    d = max(1, int(delay_s * FS))
    y = np.zeros(len(x))
    for start in range(0, len(x), d):
        stop = min(start + d, len(x))
        if start >= d:
            y[start:stop] = x[start - d:stop - d] + feedback * y[start - d:stop - d]
    return y


# --------------------------------------------------------------------------------------------
# Driving a car through drivetrain_model.run()
# --------------------------------------------------------------------------------------------

def run_supports(name):
    return name in inspect.signature(dm.run).parameters


def simulate(car, seconds, pedal_fn, brake_fn, gear_fn, v0=0.0, start_gear=1):
    """drivetrain_model.run() with gear control. Uses run(config=, gear_fn=) when the drivetrain
    model has them; otherwise (only for the GT12, the model's built-in car) it steers the model's
    automatic gearbox to the wanted gear each frame."""
    if run_supports("gear_fn") and run_supports("config"):
        return dm.run(car, seconds, pedal_fn, brake_fn, v0=v0, start_gear=start_gear, config=car,
                      gear_fn=lambda t, v, rpm, gear: gear_fn(t, v, rpm, gear))
    if car != "Prototype812":
        sys.exit(f"tools/drivetrain_model.py can't drive {car} yet (its run() has no config= or gear_fn=)")
    original = dm.Trans.update_auto
    clock = {"t": 0.0}

    def steered(s, dt, inrpm, pedal):
        clock["t"] += dt
        s.since += dt
        s.timer = max(0, s.timer - dt)
        want = gear_fn(clock["t"], None, inrpm, s.gear)
        if want is not None and want != s.gear:
            s.shift(want)

    dm.Trans.update_auto = steered
    try:
        return dm.run(car, seconds, pedal_fn, brake_fn, v0=v0, start_gear=start_gear)
    finally:
        dm.Trans.update_auto = original


def car_params(car):
    """Torque curve, rear tyre radius, final drive and peak slip for the mixer's inputs."""
    if hasattr(dm, "load_car"):
        c = dm.load_car(car)
        return {"curve_torque": c.curve_torque, "rear_radius": c.rr, "final_drive": c.fd,
                "peak_slip": c.tire_rear["psr"]}
    return {"curve_torque": dm.curve_torque, "rear_radius": dm.RR_, "final_drive": dm.TR["fd"],
            "peak_slip": dm.TIRE["psr"]}


def mixer_inputs(row, pedal, params, interior=False):
    t, kmh, rpm, gear = row[0], row[1], row[2], row[3]
    v = kmh / 3.6
    torque_share = row[9] / max(params["curve_torque"](rpm), 1)
    return {
        "rpm": rpm,
        "load": clamp(max(torque_share, row[8]), 0, 1),
        "pedal": pedal,
        "clutch": row[4],
        "gear": gear,
        "shifting": row[14] if len(row) > 14 else False,
        "limiter": row[10],
        "boost": row[12] if len(row) > 12 else 0.0,
        "speed": v,
        "slip": max(abs(s) for s in row[5]) / params["peak_slip"],
        "slideSpeed": abs(row[11] * params["rear_radius"] - v),
        "shaftRpm": row[11] * params["final_drive"] * 30 / math.pi,
        "bump": 0.0,
        "interior": interior,
    }


class CarSound:
    """The player's car as the game plays it: EngineMix plus the Sounds of its two sheets."""

    def __init__(self, car, seed=7):
        self.spec = luau_table(CONFIGS / f"{car}.luau", "audio")
        self.engine_sheet = luau_table(SHEETS / f"{self.spec['engineSheet']}.luau")
        self.effects_sheet = luau_table(SHEETS / f"{self.spec['effectsSheet']}.luau")
        engine_audio = decode_cached(self.engine_sheet["asset"])
        effects_audio = decode_cached(self.effects_sheet["asset"])
        self.mix = EngineMix(self.spec, self.engine_sheet, self.effects_sheet, random.Random(seed))
        self.engine_layers = [LoopLayer(engine_audio, loop) for loop in self.engine_sheet["loops"]]
        self.effect_layers = {loop["name"]: LoopLayer(effects_audio, loop) for loop in self.effects_sheet["loops"]
                              if loop["name"] in EFFECT_LOOPS}
        self.shots = {"effects": {s["name"]: effects_audio[round(s["start"] * FS): round(s["stop"] * FS)]
                                  for s in self.effects_sheet["oneShots"]},
                      "engine": {s["name"]: engine_audio[round(s["start"] * FS): round(s["stop"] * FS)]
                                 for s in self.engine_sheet.get("oneShots", [])}}
        self.voices = []

    def frame(self, inp, speed_factor=1.0):
        """One 1/60 s frame of sound. speed_factor multiplies every playback speed (Doppler)."""
        n = round(FS * FRAME)
        mix = self.mix
        mix.update(FRAME, inp)
        buf = np.zeros(n)
        for i, layer in enumerate(self.engine_layers):
            r = layer.render(n, mix.engine_volume[i], mix.engine_speed[i] * speed_factor)
            if r is not None:
                buf += r
        for name, layer in self.effect_layers.items():
            r = layer.render(n, mix.effects[name]["volume"], mix.effects[name]["speed"] * speed_factor)
            if r is not None:
                buf += r
        for name, volume, speed, sheet in mix.events:
            if name in self.shots[sheet]:
                self.voices.append(Voice(self.shots[sheet][name], volume, speed * speed_factor))
                self.voices = self.voices[-8:]
        alive = []
        for voice in self.voices:
            r = voice.render(n)
            if r is not None:
                buf += r
                alive.append(voice)
        self.voices = alive
        return buf


_decoded = {}


def decode_cached(asset):
    """A pack's audio: assets/audio/<asset>.flac, or a single-car dev build in assets/audio/dev."""
    if asset not in _decoded:
        path = AUDIO_DIR / f"{asset}.flac"
        if not path.exists():
            path = AUDIO_DIR / "dev" / f"{asset}.flac"
        _decoded[asset] = decode(path)
    return _decoded[asset]


# --------------------------------------------------------------------------------------------
# The scripted drive
# --------------------------------------------------------------------------------------------

class DrivePlan:
    """Idle in neutral; a free rev to the limiter, held; a launch through the gears with
    full-throttle upshifts; a lift-off; braking; then a hold on the limiter in 2nd; a lift-off and
    braking to a stop. Gears are chosen here like paddle shifts."""

    def __init__(self, limiter_rpm):
        self.limiter = limiter_rpm
        self.events = [(0.0, "idle in neutral"), (2.0, "free rev to the limiter, held"), (4.0, "lift"),
                       (6.0, "launch, full-throttle upshifts"), (14.5, "lift-off"), (16.0, "braking"),
                       (19.0, "full throttle in 2nd, held on the limiter"), (24.5, "lift-off"), (26.0, "braking")]
        self.seconds = 30.0

    def pedal(self, t, v):
        if 2.0 <= t < 4.0 or 6.0 <= t < 14.5 or 19.0 <= t < 24.5:
            return 1.0
        return 0.0

    def brake(self, t, v):
        return 1.0 if (16.0 <= t < 18.6 or 26.0 <= t < 30.0) else 0.0

    def gear(self, t, v, rpm, gear):
        if t < 5.5:
            return 0
        if t < 14.5:  # launch: shift up just below the limiter, like the automatic at full pedal
            if gear < 1:
                return 1
            return gear + 1 if rpm > self.limiter - 150 and gear < 7 else gear
        if t < 19.0:  # lift and brake: drop gears to stay above 3,500 rpm, ending in 2nd
            return max(2, gear - 1) if rpm < 3500 and gear > 2 else gear
        return 2 if t < 26.0 else (max(1, gear - 1) if rpm < 2500 and gear > 1 else gear)


def render_drive(car, sound, plan):
    log = simulate(car, plan.seconds, plan.pedal, plan.brake, plan.gear, start_gear=0)
    params = car_params(car)
    out = []
    for row in log:
        out.append(sound.frame(mixer_inputs(row, plan.pedal(row[0], row[1] / 3.6), params)))
    return np.concatenate(out), log


def render_tunnel(car, sound, tunnel_start=140.0, tunnel_length=320.0, width_m=11.0, decay=None):
    """Full throttle from 100 km/h in 3rd, through a tunnel, heard by a chase camera at the car."""
    decay = decay or TunnelMath.DEFAULT_DECAY
    seconds = 12.0
    limiter = luau_table(CONFIGS / f"{car}.luau", "engine")["limiterRpm"]

    def gear(t, v, rpm, g):
        return g + 1 if rpm > limiter - 150 and g < 7 else g

    log = simulate(car, seconds, lambda t, v: 1.0, lambda t, v: 0.0, gear, v0=100 / 3.6, start_gear=3)
    params = car_params(car)
    dry, amounts, xs = [], [], []
    amount = 0.0
    for row in log:
        dry.append(sound.frame(mixer_inputs(row, 1.0, params)))
        x, v = row[7], row[1] / 3.6
        outside = max(tunnel_start - x, x - (tunnel_start + tunnel_length), 0.0)
        amount = TunnelMath.ease(amount, TunnelMath.target(outside), v, FRAME)
        amounts.append(amount)
        xs.append(x)
    dry = np.concatenate(dry)
    n = len(dry)
    a = per_sample(amounts, n)
    low, mid, high = bands(dry)
    eqd = (low * 10 ** (TunnelMath.LOW_GAIN * a / 20) + mid * 10 ** (TunnelMath.MID_GAIN * a / 20)
           + high * 10 ** (TunnelMath.HIGH_GAIN * a / 20))
    slap = echo(eqd, TunnelMath.echo_delay(width_m), TunnelMath.ECHO_FEEDBACK)
    with_echo = eqd + slap * 10 ** ((-40 + (TunnelMath.ECHO_WET + 40) * a) / 20) * (a > 0.002)
    wet = convolve(with_echo, reverb_ir(decay, np.random.default_rng(3)))
    wet_gain = 10 ** (np.array([TunnelMath.wet_level(v, TunnelMath.DEFAULT_WET) for v in a]) / 20) * (a > 0.002)
    out = (with_echo + wet * wet_gain) * (1 + TunnelMath.LEVEL_RISE * a)
    inside = [i for i, v in enumerate(amounts) if v > 0.5]
    return out, (log[inside[0]][0] if inside else None, log[inside[-1]][0] if inside else None), amounts


def render_driveby(car_for_gt=None):
    """Traffic passing a listener standing 6 m from the near lane: a car at 110 km/h, a truck at
    85 km/h, then (if given) the player's car flat out, as TrafficMix and Roblox's roll-off would
    play them. Returns stereo audio and a list of (time, label)."""
    effects = luau_table(SHEETS / "Driving_Effects.luau")
    tyre_region = next(loop for loop in effects["loops"] if loop["name"] == "tyre_roll")
    tyre_audio = decode_cached(effects["asset"])
    passes = [("car", 110, 6.0), ("truck", 85, 9.5)]
    out_l, out_r, labels = [], [], []
    t0 = 0.0
    for kind, kmh, lateral in passes:
        sheet = luau_table(SHEETS / f"{'TrafficCar' if kind == 'car' else 'TrafficTruck'}_Engine.luau")
        audio = decode_cached(sheet["asset"])
        on = next(loop for loop in sheet["loops"] if loop["load"] == "on")
        off = next(loop for loop in sheet["loops"] if loop["load"] == "off")
        layers = [LoopLayer(audio, on), LoopLayer(audio, off), LoopLayer(tyre_audio, tyre_region)]
        profile = TrafficMix.PROFILES[kind]
        v = kmh / 3.6
        seconds = 14.0
        frames = int(seconds / FRAME)
        mono, gains = [], []
        load = 0.3
        for k in range(frames):
            t = k * FRAME
            pos = np.array([-v * seconds / 2 + v * t, lateral, -1.0])  # listener at the origin, ears 1 m above the car
            rpm, _ = TrafficMix.engine_rpm(profile, v, load)
            dop = TrafficMix.doppler(pos, np.array([v, 0.0, 0.0]), np.zeros(3))
            engine, tyre = TrafficMix.levels(profile, v, load, rpm)
            dist = float(np.linalg.norm(pos))
            roll = TrafficMix.roll_off(dist)
            n = round(FS * FRAME)
            buf = np.zeros(n)
            for layer, volume, speed in (
                    (layers[0], engine * math.sqrt(load) * on.get("gain", 1) * roll, clamp(rpm / on["rpm"], 0.4, 2.5) * dop),
                    (layers[1], engine * math.sqrt(1 - load) * off.get("gain", 1) * roll, clamp(rpm / off["rpm"], 0.4, 2.5) * dop),
                    (layers[2], tyre * roll, (0.8 + 0.4 * clamp(v / 40, 0, 1)) * dop)):
                r = layer.render(n, volume, speed)
                if r is not None:
                    buf += r
            mono.append(buf)
            gains.append((pos[0] / dist, *TrafficMix.air_absorption(dist)))
        out = np.concatenate(mono)
        g = np.array(gains)
        low, mid, high = bands(out)
        out = low + mid * 10 ** (per_sample(g[:, 1], len(out)) / 20) + high * 10 ** (per_sample(g[:, 2], len(out)) / 20)
        pan = per_sample(g[:, 0], len(out))
        out_l.append(out * np.cos((pan + 1) * math.pi / 4))
        out_r.append(out * np.sin((pan + 1) * math.pi / 4))
        labels.append((t0, f"{kind} at {kmh} km/h, {lateral:g} m away"))
        t0 += seconds
    return np.stack([np.concatenate(out_l), np.concatenate(out_r)], axis=1), labels


# --------------------------------------------------------------------------------------------
# Output
# --------------------------------------------------------------------------------------------

def write_audio(audio, path_mp3):
    audio = np.tanh(audio / 0.9) * 0.9
    audio = audio * (0.89 / (np.max(np.abs(audio)) or 1))
    channels = 1 if audio.ndim == 1 else audio.shape[1]
    wav = path_mp3.with_suffix(".wav")
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(np.round(audio * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libmp3lame", "-b:a", "160k",
                    str(path_mp3)], check=True)
    wav.unlink()
    return audio


def write_png(path, rgb):
    h, w, _ = rgb.shape
    raw = b"".join(b"\x00" + rgb[y].astype(np.uint8).tobytes() for y in range(h))
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def spectrogram(audio, path, marks=(), fmin=50, fmax=12000, width=1400, height=420, dyn=70):
    """Log-frequency spectrogram with grid lines at 100 Hz, 1 kHz and 10 kHz and a white tick at
    the top for each marked time (seconds)."""
    if audio.ndim == 2:
        audio = audio.mean(axis=1)
    win, hop = 2048, max(1, (len(audio) - 2048) // width)
    window = np.hanning(win)
    cols = []
    for k in range(width):
        seg = audio[k * hop: k * hop + win]
        if len(seg) < win:
            seg = np.pad(seg, (0, win - len(seg)))
        cols.append(np.abs(np.fft.rfft(seg * window)))
    spec = np.array(cols).T
    f = np.fft.rfftfreq(win, 1 / FS)
    logf = np.geomspace(fmin, fmax, height)
    img = np.array([np.interp(logf, f, spec[:, c]) for c in range(width)]).T
    db = 20 * np.log10(img + 1e-9)
    db = np.clip((db - (db.max() - dyn)) / dyn, 0, 1)[::-1]
    stops = np.array([[0, 0, 4], [60, 15, 110], [180, 50, 90], [250, 140, 30], [252, 255, 164]], float)
    x = db * (len(stops) - 1)
    lo = np.floor(x).astype(int).clip(0, len(stops) - 2)
    fr = (x - lo)[..., None]
    rgb = stops[lo] * (1 - fr) + stops[lo + 1] * fr
    for fq in (100, 1000, 10000):
        row = height - 1 - int(np.interp(math.log(fq), np.log(logf), np.arange(height)))
        rgb[row, ::4] = [140, 140, 140]
    seconds = len(audio) / FS
    for t in marks:
        col = int(t / seconds * width)
        if 0 <= col < width:
            rgb[:14, col] = [255, 255, 255]
    write_png(path, rgb)


def main():
    ap = argparse.ArgumentParser(description="Render a car's sound previews (see the module docstring).")
    ap.add_argument("--car", default="Prototype812", help="config id, e.g. Prototype812")
    ap.add_argument("--name", default=None, help="file name prefix (default: the engine sheet's car label)")
    ap.add_argument("--only", choices=["drive", "tunnel", "driveby"], default=None)
    args = ap.parse_args()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    car = args.car
    prefix = args.name or ("GT12" if car == "Prototype812" else car)
    limiter = luau_table(CONFIGS / f"{car}.luau", "engine")["limiterRpm"]

    if args.only in (None, "drive"):
        plan = DrivePlan(limiter)
        audio, log = render_drive(car, CarSound(car), plan)
        mp3 = OUT_DIR / f"{prefix}_drive_preview.mp3"
        audio = write_audio(audio, mp3)
        spectrogram(audio, OUT_DIR / f"{prefix}_drive_preview_spectrogram.png", [t for t, _ in plan.events])
        shifts = [(round(log[i][0], 2), log[i - 1][3], log[i][3]) for i in range(1, len(log)) if log[i][3] != log[i - 1][3]]
        cuts = sum(1 for i in range(1, len(log)) if log[i][10] and not log[i - 1][10])
        print(f"Wrote {mp3.relative_to(ROOT)} ({len(audio) / FS:.1f} s): "
              + "; ".join(f"{t:g} s {label}" for t, label in plan.events))
        print(f"  top {max(r[1] for r in log):.0f} km/h, max {max(r[2] for r in log):.0f} rpm, {cuts} limiter cuts; "
              f"gear changes (time, from, to): {shifts}")

    if args.only in (None, "tunnel"):
        audio, (t_in, t_out), _ = render_tunnel(car, CarSound(car))
        mp3 = OUT_DIR / f"{prefix}_tunnel_preview.mp3"
        audio = write_audio(audio, mp3)
        spectrogram(audio, OUT_DIR / f"{prefix}_tunnel_preview_spectrogram.png", [t for t in (t_in, t_out) if t is not None])
        print(f"Wrote {mp3.relative_to(ROOT)} ({len(audio) / FS:.1f} s): inside the tunnel from "
              f"{t_in:.1f} s to {t_out:.1f} s")

    if args.only in (None, "driveby"):
        audio, labels = render_driveby()
        mp3 = OUT_DIR / "Traffic_driveby_preview.mp3"
        audio = write_audio(audio, mp3)
        spectrogram(audio, OUT_DIR / "Traffic_driveby_preview_spectrogram.png", [t for t, _ in labels])
        print(f"Wrote {mp3.relative_to(ROOT)} ({len(audio) / FS:.1f} s, stereo): "
              + "; ".join(f"{t:g} s {label}" for t, label in labels))


if __name__ == "__main__":
    main()
