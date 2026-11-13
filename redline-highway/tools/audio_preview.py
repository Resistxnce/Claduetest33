#!/usr/bin/env python3
"""Render what the GT12 sounds like on a drive, outside Roblox.

Drives the car with tools/drivetrain_model.py (idle, a full-throttle launch through the gears, a
lift-off, hard braking, then part throttle), runs a line-for-line Python copy of the game's mixer
(src/ReplicatedStorage/VehicleSystem/VehicleAudio/EngineMix.luau) on every frame, and plays the
sound sheets the way the game's Sounds do: each layer loops its region at the mixer's volume and
playback speed. Settings are read from the car's configuration and the sheet tables, so the preview
uses the same numbers as the game.

Writes assets/audio/preview/GT12_drive_preview.mp3 and a spectrogram picture beside it.
Usage: python3 tools/audio_preview.py   (needs numpy and ffmpeg; run tools/synth_audio.py first)
"""
import math
import pathlib
import random
import re
import struct
import subprocess
import sys
import zlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import drivetrain_model as dm  # noqa: E402

FS = 44100
FRAME = 1 / 60
AUDIO_DIR = ROOT / "assets" / "audio"
SHEETS = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleAudio" / "Sheets"
CONFIG = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleConfigurations" / "Prototype812.luau"
OUT_DIR = AUDIO_DIR / "preview"
EFFECT_LOOPS = ["squeal", "road", "wind", "whine"]


# --------------------------------------------------------------------------------------------
# Reading Luau data tables (the config's audio table and the generated sheets)
# --------------------------------------------------------------------------------------------

TOKEN = re.compile(r'\s*(?:(--[^\n]*)|([{}=,;])|("(?:[^"\\]|\\.)*")|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|([A-Za-z_]\w*))')


def parse_table(text):
    tokens = []
    pos = 0
    while pos < len(text):
        m = TOKEN.match(text, pos)
        if not m or m.end() == pos:
            if text[pos:].strip() == "":
                break
            raise ValueError(f"can't read Luau table near {text[pos:pos + 30]!r}")
        pos = m.end()
        comment, sym, string, number, name = m.groups()
        if comment:
            continue
        if sym:
            tokens.append(("sym", sym))
        elif string:
            tokens.append(("val", string[1:-1]))
        elif number:
            tokens.append(("val", float(number)))
        elif name in ("true", "false"):
            tokens.append(("val", name == "true"))
        else:
            tokens.append(("name", name))
    i = 0

    def value():
        nonlocal i
        kind, v = tokens[i]
        if kind == "sym" and v == "{":
            i += 1
            items, fields = [], {}
            while tokens[i] != ("sym", "}"):
                if tokens[i][0] == "name" and tokens[i + 1] == ("sym", "="):
                    key = tokens[i][1]
                    i += 2
                    fields[key] = value()
                else:
                    items.append(value())
                if tokens[i][0] == "sym" and tokens[i][1] in ",;":
                    i += 1
            i += 1
            return fields if fields else items
        i += 1
        return v

    return value()


def luau_table(path, key=None):
    text = path.read_text()
    if key:
        start = re.search(rf"\b{key}\s*=\s*\{{", text).end() - 1
    else:
        start = re.search(r"^return\s*\{", text, re.M).end() - 1
    depth = 0
    for j in range(start, len(text)):
        depth += {"{": 1, "}": -1}.get(text[j], 0)
        if depth == 0:
            return parse_table(text[start:j + 1])
    raise ValueError("unbalanced braces")


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
        self.loop_rpm = [loop["rpm"] for loop in engine_sheet["loops"]]
        self.engine_volume = [0.0] * len(self.loop_rpm)
        self.engine_speed = [1.0] * len(self.loop_rpm)
        pairs = {}
        for i, loop in enumerate(engine_sheet["loops"]):
            pairs.setdefault(math.floor(loop["rpm"] + 0.5), {"rpm": loop["rpm"]})[loop["load"]] = i
        ordered = sorted(pairs.values(), key=lambda p: p["rpm"])
        self.points = [p["rpm"] for p in ordered]
        self.on_loop = [p.get("on", p.get("off")) for p in ordered]
        self.off_loop = [p.get("off", p.get("on")) for p in ordered]
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
        self.random = rng
        if effects_sheet:
            for loop in effects_sheet["loops"]:
                if loop["name"] == "whine" and "baseHz" in loop:
                    self.whine_hz = loop["baseHz"]
            self.crackle_names = [s["name"] for s in effects_sheet["oneShots"] if s["name"].startswith("crackle_")]

    def event(self, name, volume, speed):
        self.events.append((name, volume, speed))

    def update(self, dt, inp):
        spec = self.spec
        self.events.clear()
        rpm = max(inp["rpm"], 1)
        interior = spec["interior"]
        engine_gain = interior["engine"] if inp["interior"] else 1
        loud = spec["engineVolume"] * engine_gain * (
            spec["idleLevel"] + (1 - spec["idleLevel"]) * clamp(rpm / spec["redlineRpm"], 0, 1.1) ** spec["rpmCurve"])

        gear = inp["gear"]
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

        on = math.sqrt(load)
        off = math.sqrt(1 - load) * spec["offThrottleLevel"]
        rpm_weights(self.points, rpm, self.weights)
        for k, w in enumerate(self.weights):
            on_i, off_i = self.on_loop[k], self.off_loop[k]
            self.engine_volume[on_i] = loud * w * on
            self.engine_speed[on_i] = clamp(rpm / self.loop_rpm[on_i], spec["minPitch"], spec["maxPitch"])
            if off_i != on_i:
                self.engine_volume[off_i] = loud * w * off
                self.engine_speed[off_i] = clamp(rpm / self.loop_rpm[off_i], spec["minPitch"], spec["maxPitch"])

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
# The drive
# --------------------------------------------------------------------------------------------

def pedal(t, v):
    if t < 2.0:
        return 0.0
    if t < 13.0:
        return 1.0
    if t < 19.0:
        return 0.0
    if t < 23.0:
        return 0.5
    return 0.0


def brake(t, v):
    return 1.0 if 16.0 <= t < 19.0 else 0.0


def write_png(path, rgb):
    h, w, _ = rgb.shape
    raw = b"".join(b"\x00" + rgb[y].astype(np.uint8).tobytes() for y in range(h))
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def spectrogram(audio, path, fmax=4000, width=1200, height=400):
    win, hop = 2048, max(1, len(audio) // width)
    window = np.hanning(win)
    cols = []
    for k in range(width):
        seg = audio[k * hop: k * hop + win]
        if len(seg) < win:
            seg = np.pad(seg, (0, win - len(seg)))
        cols.append(np.abs(np.fft.rfft(seg * window)))
    spec = np.array(cols).T
    nbins = int(fmax / (FS / win))
    spec = spec[:nbins]
    db = 20 * np.log10(spec + 1e-9)
    db = np.clip((db - (db.max() - 70)) / 70, 0, 1)
    rows = np.interp(np.linspace(0, nbins - 1, height), np.arange(nbins), np.arange(nbins)).astype(int)
    img = db[rows][::-1]
    stops = np.array([[0, 0, 4], [60, 15, 110], [180, 50, 90], [250, 140, 30], [252, 255, 164]], float)
    x = img * (len(stops) - 1)
    lo = np.floor(x).astype(int).clip(0, len(stops) - 2)
    f = (x - lo)[..., None]
    rgb = stops[lo] * (1 - f) + stops[lo + 1] * f
    write_png(path, rgb)


def main():
    spec = luau_table(CONFIG, "audio")
    engine_sheet = luau_table(SHEETS / f"{spec['engineSheet']}.luau")
    effects_sheet = luau_table(SHEETS / f"{spec['effectsSheet']}.luau")
    engine_audio = decode(AUDIO_DIR / f"{engine_sheet['asset']}.flac")
    effects_audio = decode(AUDIO_DIR / f"{effects_sheet['asset']}.flac")

    mix = EngineMix(spec, engine_sheet, effects_sheet, random.Random(7))
    engine_layers = [LoopLayer(engine_audio, loop) for loop in engine_sheet["loops"]]
    effect_layers = {loop["name"]: LoopLayer(effects_audio, loop) for loop in effects_sheet["loops"]}
    shots = {s["name"]: effects_audio[round(s["start"] * FS): round(s["stop"] * FS)] for s in effects_sheet["oneShots"]}
    voices = []

    log = dm.run("preview", 24.0, pedal, brake)
    n = round(FS * FRAME)
    out = []
    peak_slip = dm.TIRE["psr"]
    for row in log:
        t, kmh, rpm, gear = row[0], row[1], row[2], row[3]
        rear_slips, cut, rear_omega, torque = row[5], row[10], row[11], row[9]
        v = kmh / 3.6
        inp = {
            "rpm": rpm,
            "load": torque / max(dm.curve_torque(rpm), 1),
            "gear": gear,
            "shifting": False,
            "limiter": cut,
            "speed": v,
            "slip": max(abs(s) for s in rear_slips) / peak_slip,
            "slideSpeed": abs(rear_omega * dm.RR_ - v),
            "shaftRpm": rear_omega * dm.TR["fd"] * 30 / math.pi,
            "bump": 0.0,
            "interior": False,
        }
        mix.update(FRAME, inp)
        buf = np.zeros(n)
        for i, layer in enumerate(engine_layers):
            r = layer.render(n, mix.engine_volume[i], mix.engine_speed[i])
            if r is not None:
                buf += r
        for name, layer in effect_layers.items():
            r = layer.render(n, mix.effects[name]["volume"], mix.effects[name]["speed"])
            if r is not None:
                buf += r
        for name, volume, speed in mix.events:
            if name in shots:
                voices.append(Voice(shots[name], volume, speed))
                voices = voices[-6:]
        alive = []
        for voice in voices:
            r = voice.render(n)
            if r is not None:
                buf += r
                alive.append(voice)
        voices = alive
        out.append(buf)
    audio = np.concatenate(out)
    audio = np.tanh(audio / 0.9) * 0.9
    audio *= 0.89 / np.max(np.abs(audio))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    wav = OUT_DIR / "GT12_drive_preview.wav"
    import wave
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(np.round(audio * 32767).astype("<i2").tobytes())
    mp3 = OUT_DIR / "GT12_drive_preview.mp3"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libmp3lame", "-b:a", "160k",
                    str(mp3)], check=True)
    wav.unlink()
    spectrogram(audio, OUT_DIR / "GT12_drive_preview_spectrogram.png")

    shifts = [(round(log[i][0], 2), log[i - 1][3], log[i][3]) for i in range(1, len(log)) if log[i][3] != log[i - 1][3]]
    print(f"Wrote {mp3.relative_to(ROOT)} ({len(audio) / FS:.1f} s) and its spectrogram")
    print(f"Top speed {max(r[1] for r in log):.0f} km/h; gear changes (time, from, to): {shifts}")


if __name__ == "__main__":
    main()
