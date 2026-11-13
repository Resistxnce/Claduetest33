#!/usr/bin/env python3
"""Make Redline Highway's placeholder sound sheets: original, synthesized engine and driving sounds.

Roblox counts every uploaded sound against a monthly limit, so the sounds are packed into two
"sheets" (one file each). The game plays each sound from its own region of a sheet using
Sound.PlaybackRegion and Sound.LoopRegion.

  assets/audio/GT12_Engine.flac      engine loops at 8 engine speeds, on and off throttle
  assets/audio/Driving_Effects.flac  tyre squeal, road and wind noise, gearbox whine, exhaust
                                     crackles, shift and suspension one-shots

It also writes the region tables the game reads:
  src/ReplicatedStorage/VehicleSystem/VehicleAudio/Sheets/GT12_Engine.luau
  src/ReplicatedStorage/VehicleSystem/VehicleAudio/Sheets/Driving_Effects.luau

How the engine is made: a 65-degree V12 fires 12 times per two crank turns. Bank A fires every
120 degrees and bank B 65 degrees after each bank A firing, so the gaps alternate 65 and 55 degrees,
which gives this layout its characteristic texture. Each firing sends a pressure pulse down that
bank's exhaust. The pulses pass through pipe resonances, a silencer and tailpipe, and are mixed with
intake roar, combustion rasp and valvetrain noise. On-throttle loops have strong, sharp pulses;
off-throttle loops have weak, uneven ones. Every loop is exactly a whole number of engine cycles,
and all filtering is circular, so each loop repeats without a click.

These are placeholders to build and tune the audio system with. Recorded engine sounds (made by
you or properly licensed) can replace them later without code changes: see docs/AUDIO.md.

Usage: python3 tools/synth_audio.py   (needs numpy and ffmpeg)
"""
import math
import pathlib
import subprocess
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO_DIR = ROOT / "assets" / "audio"
SHEET_DIR = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleAudio" / "Sheets"
FS = 44100
GAP = 0.02  # seconds of silence between regions

REDLINE = 8900
BANK_ANGLE = 65.0
ENGINE_POINTS = [1000, 1500, 2200, 3200, 4400, 5800, 7300, 8900]
ENGINE_LOOP_SECONDS = 0.8
WHINE_HZ = 1000.0


# --------------------------------------------------------------------------------------------
# Signal helpers. Loops are filtered in the frequency domain, which is circular: the output of a
# periodic input is itself exactly periodic, so loops join seamlessly.
# --------------------------------------------------------------------------------------------

def freqs(n):
    return np.fft.rfftfreq(n, 1 / FS)


def circular(x, response):
    return np.fft.irfft(np.fft.rfft(x) * response, n=len(x))


def linear(x, response_fn):
    """Non-circular filtering for one-shots (zero-padded)."""
    n2 = 2 * len(x)
    y = np.fft.irfft(np.fft.rfft(x, n2) * response_fn(np.fft.rfftfreq(n2, 1 / FS)), n=n2)
    return y[: len(x)]


def resonator(f, f0, q):
    """Causal analogue band-pass with unit gain at f0."""
    s = 1j * f / f0
    return (s / q) / (s * s + s / q + 1)


def lowpass(f, fc, q=0.707):
    s = 1j * f / fc
    return 1 / (s * s + s / q + 1)


def highpass(f, fc, q=0.707):
    s = 1j * np.maximum(f, 1e-9) / fc
    return (s * s) / (s * s + s / q + 1)


def gamma_pulse(f, tau):
    """Spectrum of the pulse (t/tau) * exp(1 - t/tau) for t >= 0: a fast rise and decay."""
    return math.e * tau / (1 + 2j * np.pi * f * tau) ** 2


def decay(f, tau):
    """Spectrum of exp(-t/tau), per sample."""
    return tau * FS / (1 + 2j * np.pi * f * tau)


def impulse_train(n, times, amps):
    x = np.zeros(n)
    pos = np.asarray(times) * FS
    i0 = np.floor(pos).astype(int)
    frac = pos - i0
    np.add.at(x, i0 % n, np.asarray(amps) * (1 - frac))
    np.add.at(x, (i0 + 1) % n, np.asarray(amps) * frac)
    return x


def unit(x):
    r = math.sqrt(float(np.mean(x * x)))
    return x / r if r > 0 else x


def finish(x, rms=0.1):
    """Normalize loudness, then soft-limit peaks."""
    x = unit(x - np.mean(x)) * rms
    return 0.97 * np.tanh(x / 0.97)


# --------------------------------------------------------------------------------------------
# Engine loops
# --------------------------------------------------------------------------------------------

def loop_length(rpm, seconds):
    cycle = 120.0 / rpm  # seconds per 720-degree engine cycle
    cycles = max(1, round(seconds / cycle))
    n = round(cycles * cycle * FS)
    return n, cycles, cycles * 120.0 * FS / n  # samples, cycles, exact engine speed of the loop


def engine_loop(point_rpm, on, rng):
    n, cycles, rpm = loop_length(point_rpm, ENGINE_LOOP_SECONDS)
    f = freqs(n)
    t = np.arange(n) / FS
    deg = 60.0 / (rpm * 360.0)  # seconds per crank degree
    x = rpm / REDLINE

    amp_jitter, time_jitter = (0.05, 0.2) if on else (0.16, 0.45)
    banks = []
    for offset in (0.0, BANK_ANGLE):
        cylinder = 1 + 0.04 * rng.standard_normal(6)  # each cylinder slightly different
        times, amps = [], []
        for c in range(cycles):
            for k in range(6):
                angle = c * 720.0 + k * 120.0 + offset + time_jitter * rng.standard_normal()
                a = cylinder[k] * (1 + amp_jitter * rng.standard_normal())
                if not on and rng.random() < 0.05 + 0.08 * x:
                    a *= 0.3  # lean, uneven combustion on the overrun
                times.append(angle * deg)
                amps.append(a)
        banks.append((times, amps))

    tau = (0.12 + 0.18 * (1 - x)) * 1e-3 if on else (0.30 + 0.30 * (1 - x)) * 1e-3
    pulse = gamma_pulse(f, tau)
    silencer = (lowpass(f, 3600 if on else 2200, 0.8) * (1 + 1.1 * resonator(f, 110, 1.2))
                * highpass(f, 30))
    exhaust = np.zeros(n)
    for b, (times, amps) in enumerate(banks):
        k = 1 + 0.07 * b  # the banks' pipes differ slightly in length
        headers = (0.5 + 1.4 * resonator(f, 160 * k, 4) + 1.0 * resonator(f, 480 * k, 4)
                   + 0.7 * resonator(f, 800 * k, 4) + 0.45 * resonator(f, 1450 * k, 3.5)
                   + 0.25 * resonator(f, 2600 * k, 3))
        exhaust += circular(impulse_train(n, times, amps), pulse * headers * silencer)

    all_times = banks[0][0] + banks[1][0]
    all_amps = banks[0][1] + banks[1][1]
    fire_hz = rpm / 60 * 6  # a whole number of cycles per loop, so these modulations repeat too
    intake = circular(rng.standard_normal(n) * (1 + 0.8 * np.cos(2 * np.pi * fire_hz * t)),
                      resonator(f, 420, 1.5) + 0.6 * resonator(f, 1100, 2))
    valvetrain = circular(rng.standard_normal(n) * (1 + 0.5 * np.cos(np.pi * fire_hz * t)),
                          resonator(f, 5500, 0.9))
    envelope = circular(impulse_train(n, all_times, all_amps), decay(f, 0.6e-3))
    rasp = circular(rng.standard_normal(n) * envelope, resonator(f, 2800, 0.8))

    if on:
        mix = (unit(exhaust) + (0.2 + 0.3 * x) * unit(intake) + 0.035 * unit(valvetrain)
               + (0.10 + 0.15 * x) * unit(rasp))
        drive = 1.4 + 0.8 * x
        mix = np.tanh(drive * mix / np.max(np.abs(mix))) / math.tanh(drive)
    else:
        mix = unit(exhaust) + 0.12 * unit(intake) + 0.05 * unit(valvetrain) + 0.03 * unit(rasp)
    return finish(mix), rpm


# --------------------------------------------------------------------------------------------
# Driving effects
# --------------------------------------------------------------------------------------------

def periodic_tone(n, base_hz, partials, vibrato, rng):
    """Tone with harmonics and a slow pitch wander that both repeat exactly every n samples."""
    period = n / FS
    t = np.arange(n) / FS
    f0 = round(base_hz * period) / period
    phase = 2 * np.pi * f0 * t
    for depth, cycles in vibrato:
        m = cycles / period
        p = rng.uniform(0, 2 * np.pi)
        phase -= f0 * depth / m * np.cos(2 * np.pi * m * t + p)
    return sum(a * np.sin(h * phase) for h, a in partials)


def squeal(rng):
    n = round(2.4 * FS)
    f = freqs(n)
    t = np.arange(n) / FS
    period = n / FS
    wander = [(0.012, 3), (0.008, 7), (0.006, 13), (0.004, 19)]
    tone = periodic_tone(n, 1150, [(1, 1.0), (2, 0.35), (3, 0.12)], wander, rng)
    tone2 = periodic_tone(n, 1690, [(1, 0.5), (2, 0.15)], [(0.015, 5), (0.008, 11)], rng)
    wobble = (0.75 + 0.12 * np.sin(2 * np.pi * (5 / period) * t + rng.uniform(0, 6))
              + 0.08 * np.sin(2 * np.pi * (11 / period) * t + rng.uniform(0, 6)))
    noise = circular(rng.standard_normal(n), resonator(f, 1400, 0.9) + 0.5 * resonator(f, 2600, 1.2))
    return finish(unit(tone + tone2) * wobble + 0.6 * unit(noise))


def road(rng):
    n = round(1.2 * FS)
    f = freqs(n)
    noise = circular(rng.standard_normal(n), lowpass(f, 650, 0.7) * (1 + 1.5 * resonator(f, 220, 1.2))
                     * highpass(f, 40) + 0.08 * resonator(f, 1200, 1.0))
    return finish(noise)


def wind(rng):
    n = round(1.2 * FS)
    f = freqs(n)
    t = np.arange(n) / FS
    period = n / FS
    noise = circular(rng.standard_normal(n), (resonator(f, 650, 0.6) + 0.5 * resonator(f, 1600, 1.0))
                     * highpass(f, 150))
    gust = 0.85 + 0.12 * np.sin(2 * np.pi * t / period) + 0.06 * np.sin(2 * np.pi * 3 * t / period + 1)
    return finish(noise * gust)


def whine(rng):
    n = round(0.5 * FS)
    f = freqs(n)
    tone = periodic_tone(n, WHINE_HZ, [(1, 1.0), (2, 0.3), (3, 0.08)], [], rng)
    noise = circular(rng.standard_normal(n), resonator(f, WHINE_HZ, 6))
    return finish(unit(tone) + 0.15 * unit(noise))


def fade(x, ms=3):
    k = int(ms * FS / 1000)
    x = x.copy()
    x[-k:] *= np.linspace(1, 0, k)
    return x


def crackle(rng):
    n = round(0.14 * FS)
    t = np.arange(n) / FS
    out = np.zeros(n)
    for i, (start, size) in enumerate([(0.0, 1.0)] + [(rng.uniform(0.012, 0.06), rng.uniform(0.25, 0.6))
                                                     for _ in range(rng.integers(1, 4))]):
        tt = np.clip(t - start, 0, None)
        on = t >= start
        burst = rng.standard_normal(n) * np.exp(-tt / rng.uniform(1.5e-3, 4e-3)) * on
        f0 = rng.uniform(1200, 2500)
        burst = linear(burst, lambda f, f0=f0: resonator(f, f0, 1.1) + 0.4 * highpass(f, 3000))
        thump = np.sin(2 * np.pi * rng.uniform(90, 150) * tt) * np.exp(-tt / 0.012) * on
        out += size * (unit(burst) * 0.6 + 0.8 * thump)
    return fade(0.9 * out / np.max(np.abs(out)))


def shift_cut(rng):
    n = round(0.2 * FS)
    x = impulse_train(n, [0.0, 0.012, 0.022], [1.0, 0.7, 0.45])
    y = linear(x, lambda f: gamma_pulse(f, 0.4e-3) * (0.5 + 1.4 * resonator(f, 160, 4) + resonator(f, 480, 4)
                                                       + 0.5 * resonator(f, 1450, 3.5)) * lowpass(f, 3600, 0.8)
               * highpass(f, 30))
    return fade(0.9 * y / np.max(np.abs(y)))


def damped(n, parts, noise=None, rng=None):
    t = np.arange(n) / FS
    y = sum(a * np.sin(2 * np.pi * f0 * t) * np.exp(-t / tau) for f0, tau, a in parts)
    if noise:
        y = y + noise * rng.standard_normal(n) * np.exp(-t / 1e-3)
    return fade(0.8 * y / np.max(np.abs(y)))


# --------------------------------------------------------------------------------------------
# Sheets
# --------------------------------------------------------------------------------------------

class Sheet:
    def __init__(self, name):
        self.name = name
        self.chunks = []
        self.length = 0
        self.loops = []
        self.oneshots = []

    def _add(self, x):
        start = self.length
        self.chunks.append(x)
        self.length += len(x)
        gap = np.zeros(round(GAP * FS))
        self.chunks.append(gap)
        self.length += len(gap)
        return start

    def loop(self, name, x, **extra):
        """Three copies; the game loops the middle one, so a slightly late loop point is harmless."""
        start = self._add(np.concatenate([x, x, x]))
        n = len(x)
        self.loops.append(dict(name=name, start=start / FS, loopStart=(start + n) / FS,
                               loopEnd=(start + 2 * n) / FS, stop=(start + 3 * n) / FS, **extra))

    def oneshot(self, name, x):
        start = self._add(x)
        self.oneshots.append(dict(name=name, start=start / FS, stop=(start + len(x)) / FS))

    def write(self):
        AUDIO_DIR.mkdir(parents=True, exist_ok=True)
        SHEET_DIR.mkdir(parents=True, exist_ok=True)
        audio = np.concatenate(self.chunks)
        pcm = np.clip(np.round(audio * 32767), -32768, 32767).astype("<i2")
        wav = AUDIO_DIR / f"{self.name}.wav"
        with wave.open(str(wav), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(FS)
            w.writeframes(pcm.tobytes())
        flac = AUDIO_DIR / f"{self.name}.flac"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "flac",
                        "-compression_level", "8", str(flac)], check=True)
        wav.unlink()
        self.write_luau()
        return flac, len(audio) / FS

    def write_luau(self):
        def fmt(v):
            if isinstance(v, str):
                return f'"{v}"'
            return f"{v:.6f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)

        lines = [
            "--[[",
            f"\tRegions of assets/audio/{self.name}.flac, in seconds. Generated by tools/synth_audio.py;",
            "\tdon't edit by hand. Loops: the game plays start..stop and loops loopStart..loopEnd.",
            "]]",
            "",
            "return {",
            f'\tasset = "{self.name}",',
            f"\tlength = {fmt(self.length / FS)},",
            "\tloops = {",
        ]
        for loop in self.loops:
            lines.append("\t\t{ " + ", ".join(f"{k} = {fmt(v)}" for k, v in loop.items()) + " },")
        lines.append("\t},")
        lines.append("\toneShots = {")
        for shot in self.oneshots:
            lines.append("\t\t{ " + ", ".join(f"{k} = {fmt(v)}" for k, v in shot.items()) + " },")
        lines.append("\t},")
        lines.append("}")
        (SHEET_DIR / f"{self.name}.luau").write_text("\n".join(lines) + "\n")


def main():
    rng = np.random.default_rng(812)

    engine = Sheet("GT12_Engine")
    for point in ENGINE_POINTS:
        for on in (True, False):
            x, rpm = engine_loop(point, on, rng)
            engine.loop(f"{'on' if on else 'off'}_{point}", x, rpm=round(rpm, 3), load="on" if on else "off")

    effects = Sheet("Driving_Effects")
    effects.loop("squeal", squeal(rng))
    effects.loop("road", road(rng))
    effects.loop("wind", wind(rng))
    effects.loop("whine", whine(rng), baseHz=WHINE_HZ)
    for k in range(1, 7):
        effects.oneshot(f"crackle_{k}", crackle(rng))
    effects.oneshot("shift_cut", shift_cut(rng))
    effects.oneshot("shift_clunk", damped(round(0.15 * FS), [(170, 0.025, 1.0), (410, 0.012, 0.6), (1300, 0.004, 0.3)],
                                          noise=0.5, rng=rng))
    effects.oneshot("bump_knock", damped(round(0.25 * FS), [(55, 0.04, 1.0), (120, 0.02, 0.6)], noise=0.2, rng=rng))

    for sheet in (engine, effects):
        path, seconds = sheet.write()
        print(f"Wrote {path.relative_to(ROOT)}: {seconds:.1f} s, {path.stat().st_size / 1e6:.2f} MB, "
              f"{len(sheet.loops)} loops, {len(sheet.oneshots)} one-shots")


if __name__ == "__main__":
    main()
