#!/usr/bin/env python3
"""Make Redline Highway's sound sheets: every car's engine, the driving effects and traffic.

Each car's engine is synthesized from its acoustic definition, assets/audio/engines/<ConfigId>.json
(the format is in docs/AUDIO.md):
  * firing events come from the firing order, which cylinders sit on which bank, the bank angle and
    the crank type (an even-firing crank, or a common-pin V whose gaps alternate with the bank angle);
  * each firing sends a blowdown pulse down its cylinder's primary pipe to a collector. The exhaust
    routing says which collector each cylinder feeds and how collectors merge (separate banks, an
    X-pipe, an H-pipe, a Y into one pipe, or hot-V cross-bank manifolds that give each turbo evenly
    spaced pulses). That decides which pulse pattern each tailpipe carries, which is why a
    cross-plane V8 burbles and a flat-plane V8 screams;
  * pipe lengths set the resonances; mufflers (valves open or closed), turbos (which smooth the
    pulses), the tailpipe radiation, intake roar, combustion and valvetrain noise complete the sound;
  * loops are made at steady engine speeds from idle to the limiter, on and off throttle, plus loops
    at the limiter with its cut pattern baked in (free revving and in gear), and forced-induction
    layers (a turbo whistle loop pitched by boost, blow-off one-shots, supercharger whine loops);
  * each loop's playback gain comes from the car's measured sound levels (idle, full throttle).
Every loop is a whole number of engine cycles (limiter loops a whole number of bounces), and all
filtering is circular, so each loop repeats without a click.

Roblox counts every upload against a monthly limit, so sounds are packed into a few files ("packs",
listed in assets/audio/packs.json); one pack can hold several cars. The game plays each sound from its
own region of a pack with Sound.PlaybackRegion and Sound.LoopRegion. Each car's regions are in its own
sheet table, src/ReplicatedStorage/VehicleSystem/VehicleAudio/Sheets/<sheet>.luau.

Usage (needs numpy and ffmpeg):
  python3 tools/synth_audio.py                    build every pack
  python3 tools/synth_audio.py --car RefM3G80     build only the pack that holds this car
  python3 tools/synth_audio.py --check RefM3G80   check a definition; print its firing and pulse pattern
  python3 tools/synth_audio.py --analyze REC --car RefM3G80 [--start S --end S]
                                                  engine-order analysis of a recording against the car
"""
import argparse
import copy
import json
import math
import pathlib
import subprocess
import sys
import wave
import zlib

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO_DIR = ROOT / "assets" / "audio"
ENGINE_DIR = AUDIO_DIR / "engines"
PACKS_FILE = AUDIO_DIR / "packs.json"
SHEET_DIR = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleAudio" / "Sheets"
FS = 44100
GAP = 0.02  # seconds of silence between regions
PRE_ROLL = 0.02  # seconds of a loop's end stored just before it (context for the resampler)
POST_ROLL = 0.25  # seconds of a loop's start stored after it, so a late loop jump lands on matching audio

WHINE_HZ = 1000.0
AIR_C = 343.0  # speed of sound in air at 20 C, m/s
TARGET_A_RMS = 0.075  # every loop is stored at this A-weighted RMS; its gain is in the sheet
REFERENCE_DBA = 95.0  # [A] an engine measured at this level plays at gain 1
LEVEL_COMPRESSION = 0.6  # [A] game dB per real dB: idle stays audible next to full throttle
IDLE_PULSE = 0.35  # [E] exhaust pulse strength when idling (light load, fuel on), full load = 1


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
# Acoustic building blocks: frequency responses applied with circular()
# --------------------------------------------------------------------------------------------

def gas_c(temp_k):
    """Speed of sound in hot exhaust gas (ratio of specific heats about 1.35), m/s."""
    return 19.7 * math.sqrt(temp_k)


def a_weighting(f):
    """IEC 61672 A-weighting as a linear amplitude factor."""
    f2 = np.maximum(np.asarray(f, dtype=float), 1e-3) ** 2
    ra = (12194.0 ** 2 * f2 * f2) / ((f2 + 20.6 ** 2) * np.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2))
                                     * (f2 + 12194.0 ** 2))
    return ra * 10 ** (2.0 / 20)


def a_rms(x):
    """A-weighted RMS of a loop."""
    y = np.fft.irfft(np.fft.rfft(x) * a_weighting(freqs(len(x))), n=len(x))
    return float(np.sqrt(np.mean(y * y)))


def pipe(f, length, c, g, loss_hz=5000.0):
    """A pipe's resonances, with unit gain at its peaks and a delay of length / c.

    g is the round-trip reflection (the two end reflection coefficients multiplied): g > 0 for a pipe
    acoustically open at both ends (peaks at n*c/2L), g < 0 for one closed at its source end (peaks at
    odd multiples of c/4L). Wall friction and radiation lower the high peaks (loss_hz)."""
    if length <= 0:
        return np.ones(len(f), dtype=complex)
    k = 2j * np.pi * f * length / c
    gf = g * np.exp(-f / loss_hz)
    return np.exp(-k) * (1 - abs(g)) / (1 - gf * np.exp(-2 * k))


def blowdown(f, rise_s, decay_s):
    """Spectrum of a blowdown pressure pulse: a fast rise and a slower decay, unit area."""
    return 1 / ((1 + 2j * np.pi * f * rise_s) * (1 + 2j * np.pi * f * decay_s))


def radiation(f, diameter_m, corner_hz=None):
    """A pipe end radiates the rate of change of its flow until ka ~ 1, then evenly. corner_hz
    overrides the corner (calibrated: real exhausts tilt less than the ideal far field)."""
    s = 1j * f / (corner_hz or AIR_C / (math.pi * diameter_m))
    return s / (1 + s)


def expansion_chamber(f, area_ratio, length, c):
    """Transmission of a simple expansion chamber (a silencer box): passbands at n * c / 2L."""
    m = area_ratio
    return 1 / np.sqrt(1 + 0.25 * (m - 1 / m) ** 2 * np.sin(2 * np.pi * f * length / c) ** 2)


def shift(f, seconds):
    return np.exp(-2j * np.pi * f * seconds)


def burst(n, times, amps, tau, rng):
    """Noise bursts (exponential decay tau) starting at each time: combustion and afterfire."""
    envelope = circular(impulse_train(n, times, amps), decay(freqs(n), tau)) / (tau * FS)
    return rng.standard_normal(n) * envelope


# --------------------------------------------------------------------------------------------
# Engine acoustic definitions: assets/audio/engines/<ConfigId>.json (format in docs/AUDIO.md)
# --------------------------------------------------------------------------------------------

class DefinitionError(Exception):
    pass


DEFAULTS = {
    "seed": None,  # random seed; default: from the car id
    "sheet": None,  # sheet (and Luau table) name; default "<id>_Engine"
    "engine": {
        "layout": "V",  # "V", "inline" or "flat"
        "bankAngleDeg": 90,
        "crank": "even",  # "crossplane", "flatplane", "even", "commonPin" (odd-firing V), "inline"
        "firingIntervalsDeg": None,  # optional cycle of gaps along the firing order, overrides crank
        "idleRpm": 800,
        "limiterRpm": 6500,
        "aspiration": "NA",  # "NA", "Turbo" or "Supercharger"
        "cylinderSpread": 0.06,  # how much cylinders differ from each other (puts half orders in the sound)
    },
    "exhaust": {
        "evoDeg": 130,  # exhaust valve opens this many crank degrees after the firing
        "pulseRiseDeg": 4,  # blowdown pulse rise, crank degrees
        "pulseDecayDeg": 30,  # and decay
        "minRiseMs": 0.06,  # the rise can't be quicker than this
        "gasTempK": 1000,  # in the primaries (sets pulse travel time and primary resonances)
        "pipeTempK": 700,  # downstream of the collectors
        "primaryReflection": -0.55,  # round-trip reflection of a primary (closed valve end)
        "pipeReflection": 0.45,  # of the pipes after the collector
        "rasp": 0.35,  # 0..1: how much full-load pulses sharpen (harmonic richness)
        "timingJitterDeg": 0.8,  # random spread of pulse timing, crank degrees (smears high harmonics)
        "shapeSpread": 0.25,  # random spread of pulse duration, share
        "flowNoise": 0.6,  # turbulent flow noise riding on the pulses, relative to the pulses
        "flowNoiseHz": 600,  # where that noise is strongest
        "offPulseSoftening": 1.0,  # off throttle, pulses rise this much slower
        "radiationHz": 500,  # corner of the tailpipe radiation tilt (calibrated; null = from the pipe diameter)
        "level": 1.0,
        "collectors": None,  # default: one per bank, see BANK_COLLECTOR
        "merge": {"type": "separate", "crossover": 0.0, "crossoverHz": 400, "pathM": 0.3},
        "outlets": None,  # default: one per collector, see OUTLET
        "muffler": {
            "valves": "open",  # "open", "closed", "auto" (open above openAboveRpm or openAboveLoad)
            "openAboveRpm": 3500,
            "openAboveLoad": 0.6,
            "openLowpassHz": 3800,
            "closedLowpassHz": 1300,
            "closedCutDb": 7,
            "chamberAreaRatio": 6,
            "chamberLengthM": 0.45,
        },
    },
    "intake": {
        "level": 0.25,  # relative to the exhaust at full load
        "intakeDeg": 400,  # induction pulse, crank degrees after the firing
        "runnerLengthM": 0.30,
        "airboxHz": 110,  # Helmholtz resonance of the plenum and airbox
        "snorkelLengthM": 0.5,
        "mouthDiameterM": 0.09,
        "filterLowpassHz": 2200,
    },
    "mechanical": {
        "combustion": 0.05,  # block-radiated combustion noise
        "valvetrain": 0.008,  # valve seating ticks
        "injectors": 0.006,  # direct-injection ticks (0 for port injection)
        "blockHz": [1800, 3300],
        "bayLowpassHz": 2500,
    },
    "idle": {"roughness": 0.08, "lope": 0.0},  # cycle-to-cycle variation at idle; cam lope 0..1
    "overrun": {"pulseLevel": 0.16, "burble": 0.0},  # off-throttle pulse strength; pops per second / 6
    "forcedInduction": None,
    "limiter": {
        "type": "fuelCut",  # "fuelCut", "ignitionCut" (afterfire pops) or "softCut" (partial cut)
        "free": {"bounceHz": 8.0, "dropRpm": 300, "cutShare": 0.45},  # free revving (neutral)
        "load": {"bounceHz": 6.0, "dropRpm": 140, "cutShare": 0.35},  # in gear
        "popChance": 0.0,  # chance of an afterfire pop per cut firing
        "cutLevel": 0.12,  # pulse strength of a cut cylinder (it only pumps air)
    },
    "loops": {"rpmPoints": None, "seconds": 1.0, "limiterSeconds": 1.25},
    "loudness": {"interior": {}, "exterior": {}, "loadRangeDb": 12.0},
    "notes": {},
}

BANK_COLLECTOR = {"primaryLengthM": 0.55, "lengthSpreadM": 0.02}
OUTLET = {"pipeLengthM": 2.4, "tailLengthM": 0.35, "diameterM": 0.09, "gain": 1.0, "offsetM": 0.0}
TURBO = {
    "count": 2,
    "pulseDamping": 0.55,  # 0..1: share of the pulse's sharp part the turbine takes out
    "dampingHz": 180,  # pulses are smoothed above this
    "whistleHz": [2500, 8500],  # whistle pitch from low to full boost
    "whistleLevel": 0.10,
    "whooshLevel": 0.08,  # broadband turbine and compressor noise in the main loops
    "blowOff": {"type": "recirculating", "level": 0.5, "variants": 3},
    "wastegateFlutter": 0.0,
}
SUPERCHARGER = {
    "kind": "roots",  # twin-rotor (Roots/TVS) or "centrifugal"
    "rotorLobes": 4,
    "driveRatio": 2.4,  # rotor turns per crank turn
    "pulsesPerRev": None,  # default: 2 * rotorLobes for a twin-rotor blower
    "whineLevel": 0.12,
    "whineRpm": [1800, 5200],  # crank speeds the whine loops are made at
}


def deep_merge(base, over):
    out = copy.deepcopy(base)
    for k, v in (over or {}).items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = deep_merge(out[k], v)
        else:
            out[k] = copy.deepcopy(v)
    return out


def definition_path(car):
    p = pathlib.Path(car)
    return p if p.suffix == ".json" else ENGINE_DIR / f"{car}.json"


def load_definition(car):
    path = definition_path(car)
    if not path.exists():
        raise DefinitionError(f"no acoustic definition at {path}")
    try:
        raw = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        raise DefinitionError(f"{path.name}: not valid JSON ({e})") from None
    d = deep_merge(DEFAULTS, raw)
    d["id"] = raw.get("id") or path.stem
    d["sheet"] = d["sheet"] or f"{d['id']}_Engine"
    d["seed"] = d["seed"] if d["seed"] is not None else zlib.crc32(d["id"].encode())
    validate(d)
    return d


def validate(d):
    e, x = d["engine"], d["exhaust"]
    where = d["id"]

    def fail(msg):
        raise DefinitionError(f"{where}: {msg}")

    order = e.get("firingOrder")
    if not order:
        fail("engine.firingOrder is missing")
    n = len(order)
    if sorted(order) != list(range(1, n + 1)):
        fail(f"engine.firingOrder must list cylinders 1..{n} once each, got {order}")
    e["cylinders"] = e.get("cylinders", n)
    if e["cylinders"] != n:
        fail(f"engine.cylinders is {e['cylinders']} but the firing order has {n}")
    banks = e.get("banks") or {"A": list(range(1, n + 1))}
    e["banks"] = banks
    listed = sorted(c for cyls in banks.values() for c in cyls)
    if listed != list(range(1, n + 1)):
        fail(f"engine.banks must hold every cylinder once, got {banks}")
    if not e["idleRpm"] < e["limiterRpm"]:
        fail("engine.idleRpm must be below engine.limiterRpm")
    if x["collectors"] is None:
        x["collectors"] = [dict(BANK_COLLECTOR, name=b, cylinders=list(c)) for b, c in banks.items()]
    else:
        x["collectors"] = [deep_merge(BANK_COLLECTOR, c) for c in x["collectors"]]
    names = [c.get("name") for c in x["collectors"]]
    if None in names or len(set(names)) != len(names):
        fail("every exhaust collector needs a unique name")
    fed = sorted(c for col in x["collectors"] for c in col["cylinders"])
    if fed != list(range(1, n + 1)):
        fail(f"exhaust collectors must take every cylinder once, got {fed}")
    if x["outlets"] is None:
        x["outlets"] = [dict(OUTLET, collectors=[c["name"]]) for c in x["collectors"]]
    else:
        x["outlets"] = [deep_merge(OUTLET, o) for o in x["outlets"]]
    for o in x["outlets"]:
        for name in o.get("collectors", []):
            if name not in names:
                fail(f"exhaust outlet refers to unknown collector {name!r}")
    merge = x["merge"]
    if merge["type"] not in ("separate", "xpipe", "hpipe", "y"):
        fail(f"exhaust.merge.type must be separate, xpipe, hpipe or y, got {merge['type']!r}")
    if merge["type"] in ("xpipe", "hpipe") and len(x["outlets"]) < 2:
        fail("an X- or H-pipe needs at least two outlets")
    if x["muffler"]["valves"] not in ("open", "closed", "auto"):
        fail("exhaust.muffler.valves must be open, closed or auto")
    fi = d.get("forcedInduction")
    if fi:
        kind = fi.get("type")
        if kind == "Turbo":
            d["forcedInduction"] = fi = deep_merge(TURBO, fi)
            lo, hi = fi["whistleHz"]
            if not 200 < lo < hi < 16000:
                fail("forcedInduction.whistleHz must be [low, high] in Hz")
        elif kind == "Supercharger":
            d["forcedInduction"] = fi = deep_merge(SUPERCHARGER, fi)
            if fi["pulsesPerRev"] is None:
                fi["pulsesPerRev"] = 2 * fi["rotorLobes"] if fi["kind"] == "roots" else fi.get("impellerBlades", 12)
        else:
            fail("forcedInduction.type must be Turbo or Supercharger")
        e["aspiration"] = kind
    lim = d["limiter"]
    lim.setdefault("rpm", e["limiterRpm"])
    if lim["type"] not in ("fuelCut", "ignitionCut", "softCut"):
        fail("limiter.type must be fuelCut, ignitionCut or softCut")
    loops = d["loops"]
    if not loops["rpmPoints"]:
        count = max(5, math.ceil(math.log(e["limiterRpm"] / e["idleRpm"]) / math.log(1.33)) + 1)
        loops["rpmPoints"] = [round(v / 50) * 50 for v in np.geomspace(e["idleRpm"], e["limiterRpm"], count)]
    pts = loops["rpmPoints"]
    if pts != sorted(pts) or pts[0] < 0.5 * e["idleRpm"] or pts[-1] > e["limiterRpm"] + 200:
        fail("loops.rpmPoints must ascend from about idle to the limiter")
    firing_angles(d)  # raises if the firing pattern is impossible


# --------------------------------------------------------------------------------------------
# Firing events
# --------------------------------------------------------------------------------------------

def firing_intervals(e):
    """Gaps (crank degrees) between successive firings along the firing order."""
    n = len(e["firingOrder"])
    if e.get("firingIntervalsDeg"):
        return list(e["firingIntervalsDeg"])
    if e["crank"] == "commonPin":
        # Two cylinders, one per bank, share each crankpin. The second fires one bank angle after
        # the first, so the gaps alternate bank angle and (pin spacing - bank angle).
        pin_spacing = 2 * 720.0 / n
        return [e["bankAngleDeg"], pin_spacing - e["bankAngleDeg"]]
    return [720.0 / n]


def firing_angles(d):
    """Crank angle (0..720) at which each cylinder fires, plus the bank of each cylinder."""
    e = d["engine"]
    order = e["firingOrder"]
    gaps = firing_intervals(e)
    angles, a = {}, 0.0
    for i, cyl in enumerate(order):
        angles[cyl] = a
        a += gaps[i % len(gaps)]
    if abs(a - 720.0) > 1e-6:
        raise DefinitionError(f"{d['id']}: the firing gaps add up to {a:g} degrees, not 720")
    if e["crank"] == "commonPin":
        bank_of = {c: b for b, cyls in e["banks"].items() for c in cyls}
        position = {c: cyls.index(c) for cyls in e["banks"].values() for c in cyls}
        for i in range(0, len(order), 2):
            a_, b_ = order[i], order[(i + 1) % len(order)]
            if bank_of[a_] == bank_of[b_] or position[a_] != position[b_]:
                raise DefinitionError(
                    f"{d['id']}: crank 'commonPin' needs the firing order to pair cylinders that share a pin "
                    f"(same place in each bank's front-to-back list); {a_} and {b_} don't")
    return angles


def pulse_gaps(angles, cylinders):
    """Gaps between the pulses that a group of cylinders sends into one pipe."""
    a = sorted(angles[c] for c in cylinders)
    return [round((a[(i + 1) % len(a)] - a[i]) % 720.0 or 720.0, 1) for i in range(len(a))]


def describe(d):
    """Text summary of the firing and pulse pattern, for the console and docs."""
    e, x = d["engine"], d["exhaust"]
    angles = firing_angles(d)
    order = e["firingOrder"]
    bank_of = {c: b for b, cyls in e["banks"].items() for c in cyls}
    angle = f" {e['bankAngleDeg']:g} deg" if e["layout"] in ("V", "flat") else ""
    lines = [f"{d['id']}: {e['cylinders']} cylinders, {e['layout']}{angle}, "
             f"crank {e['crank']}, {e['aspiration']}, idle {e['idleRpm']} rpm, limiter {e['limiterRpm']} rpm",
             "  firing gaps: " + "-".join(f"{g:g}" for g in pulse_gaps(angles, order)),
             "  bank sequence: " + " ".join(f"{c}{bank_of[c]}" for c in order)]
    for b, cyls in e["banks"].items():
        lines.append(f"  bank {b} pulse gaps: " + "-".join(f"{g:g}" for g in pulse_gaps(angles, cyls)))
    for col in x["collectors"]:
        gaps = pulse_gaps(angles, col["cylinders"])
        even = "even" if max(gaps) - min(gaps) < 1 else "uneven"
        lines.append(f"  collector {col['name']} {col['cylinders']}: pulse gaps "
                     + "-".join(f"{g:g}" for g in gaps) + f" ({even})")
    m = x["merge"]
    lines.append(f"  merge: {m['type']}" + (f", crossover {m['crossover']}" if m["type"] in ("xpipe", "hpipe") else "")
                 + f"; {len(x['outlets'])} outlet(s); valves {x['muffler']['valves']}")
    if e["crank"] == "flatplane" and len(e["banks"]) == 2:
        if any(bank_of[order[i]] == bank_of[order[(i + 1) % len(order)]] for i in range(len(order))):
            lines.append("  WARNING: a flat-plane V8 alternates banks; check the firing order and bank numbering")
    if e["crank"] == "crossplane" and len(e["banks"]) == 2:
        if all(bank_of[order[i]] != bank_of[order[(i + 1) % len(order)]] for i in range(len(order))):
            lines.append("  WARNING: this firing order alternates banks like a flat-plane crank; check the numbering")
    return "\n".join(lines)


# --------------------------------------------------------------------------------------------
# Engine sound
# --------------------------------------------------------------------------------------------

def steady_theta(rpm_target, seconds):
    """Crank angle per sample for a steady loop of a whole number of 720-degree cycles."""
    cycles = max(2, round(seconds * rpm_target / 120))
    n = round(cycles * 120 / rpm_target * FS)
    rpm = cycles * 120 * FS / n
    theta = np.arange(n + 1) * (6 * rpm / FS)
    return n, theta, rpm


def limiter_theta(top, drop, bounce_hz, cut_share, seconds):
    """Crank angle per sample for a loop of whole limiter bounces, and the cut phase per sample.

    Each bounce: the cut starts at the top and the engine slows by `drop` rpm, then fuel returns and
    it climbs back. The speeds are scaled very slightly so the loop is a whole number of cycles."""
    bounces = max(2, round(seconds * bounce_hz))
    n = round(bounces / bounce_hz * FS)
    phase = (np.arange(n + 1) * bounces / n) % 1.0
    q = cut_share
    rpm = np.where(phase < q, top - drop * 0.5 * (1 - np.cos(np.pi * phase / q)),
                   top - drop + drop * 0.5 * (1 - np.cos(np.pi * (phase - q) / (1 - q))))
    theta = np.concatenate([[0.0], np.cumsum((rpm[:-1] + rpm[1:]) * 0.5 * 6 / FS)])
    cycles = max(1, round(theta[-1] / 720))
    theta *= cycles * 720 / theta[-1]
    mean_rpm = theta[-1] / (6 * n / FS)
    return n, theta, float(mean_rpm), phase < q


class EngineModel:
    """Synthesizes one car's engine from its acoustic definition."""

    def __init__(self, d):
        self.d = d
        e = d["engine"]
        self.angles = firing_angles(d)
        self.cyls = e["firingOrder"]
        self.idle = e["idleRpm"]
        self.top = e["limiterRpm"]
        x = d["exhaust"]
        self.collector_of = {c: k for k, col in enumerate(x["collectors"]) for c in col["cylinders"]}
        rng = np.random.default_rng(d["seed"])
        # each cylinder breathes and burns slightly differently (fixed for the car): this puts the
        # half orders in the sound that every real engine has
        self.cyl_gain = {c: 1 + e["cylinderSpread"] * rng.standard_normal() for c in self.cyls}
        self.primary_len = {}
        for col in x["collectors"]:
            for c in col["cylinders"]:
                self.primary_len[c] = col["primaryLengthM"] + col["lengthSpreadM"] * rng.uniform(-1, 1)
        self.fi = d.get("forcedInduction")
        self.turbo = self.fi if self.fi and self.fi["type"] == "Turbo" else None

    # ---- events ------------------------------------------------------------------------------

    def event_times(self, theta, offset_deg):
        """Times (s) and cycle numbers of every cylinder's event at firing angle + offset."""
        n = len(theta) - 1
        total = theta[-1]
        cycles = round(total / 720)
        t = np.arange(n + 1) / FS
        out = {}
        for c in self.cyls:
            target = (self.angles[c] + offset_deg + 720.0 * np.arange(cycles)) % total
            out[c] = np.interp(target, theta, t) % (n / FS)
        return out

    def amplitudes(self, times, load, rpm, rng, cut=None, cut_level=0.12, soft=False):
        d = self.d
        rough = d["idle"]["roughness"] * math.sqrt(self.idle / max(rpm, 1)) * (1.6 - 0.6 * load)
        lope = d["idle"]["lope"] * max(0.0, 1 - (rpm - self.idle) / 1500)
        out, flags = {}, {}
        for c, ts in times.items():
            a = self.cyl_gain[c] * (1 + rough * rng.standard_normal(len(ts)))
            if lope > 0:  # big cam overlap: some cycles burn weakly at idle
                a *= 1 - lope * 0.6 * (rng.random(len(ts)) < 0.35)
            a = np.maximum(a, 0.05)
            cut_now = np.zeros(len(ts), dtype=bool)
            if cut is not None:
                idx = np.minimum((ts * FS).astype(int), len(cut) - 1)
                cut_now = cut[idx]
                if soft:  # a soft limiter cuts only some cylinders
                    cut_now &= rng.random(len(ts)) < 0.5
            out[c] = np.where(cut_now, a * cut_level, a)
            flags[c] = cut_now
        return out, flags

    # ---- components --------------------------------------------------------------------------

    def render(self, theta, rpm, load, rng, cut=None, valve_open=True):
        """Every sound component of one loop, unscaled. theta: crank angle per sample."""
        d, x = self.d, self.d["exhaust"]
        n = len(theta) - 1
        f = freqs(n)
        on = load > 0.5
        deg_s = 1 / (6 * rpm)  # seconds per crank degree
        lim = d["limiter"]
        fire = self.event_times(theta, 0.0)
        amps, cut_flags = self.amplitudes(fire, load, rpm, rng, cut, lim["cutLevel"], lim["type"] == "softCut")
        # Off throttle the engine idles (fuel on, light pulses) near idle speed, and above about 1.5x
        # idle the fuel is cut on the overrun, so the cylinders only pump air.
        fuel_on = min(1.0, max(0.0, (1.5 * self.idle - rpm) / (0.5 * self.idle)))
        light = d["overrun"]["pulseLevel"] + (IDLE_PULSE - d["overrun"]["pulseLevel"]) * fuel_on
        pulse_level = light + (1 - light) * load
        burning = fuel_on + (1 - fuel_on) * load  # share of cylinders burning fuel

        # exhaust: blowdown pulses into the primaries, summed at each collector
        evo = self.event_times(theta, x["evoDeg"])
        c_hot = gas_c(x["gasTempK"] if on else x["gasTempK"] * 0.75)
        cols = x["collectors"]
        # No two combustions are alike: each pulse is a little early or late, and its blowdown a
        # little quicker or slower (three pulse shapes, picked at random). This smears the high
        # harmonics into noise the way real exhaust sound does.
        spread = x["shapeSpread"]
        groups = (1 - spread, 1.0, 1 + spread)
        trains = np.zeros((len(groups), len(cols), n))
        jitter = x["timingJitterDeg"] * (1 if on else 1.6)
        for c in self.cyls:
            k = self.collector_of[c]
            ts = evo[c] + self.primary_len[c] / c_hot + rng.normal(0, jitter, len(evo[c])) * deg_s
            pick = rng.integers(0, len(groups), len(ts))
            for g in range(len(groups)):
                sel = pick == g
                if sel.any():
                    trains[g, k] += impulse_train(n, ts[sel], (amps[c] * pulse_level)[sel])
        rise = max(x["pulseRiseDeg"] * deg_s * (1 if on else x["offPulseSoftening"]), x["minRiseMs"] * 1e-3)
        fall = x["pulseDecayDeg"] * deg_s * (1 if on else 1.3)
        shaped = sum(np.fft.rfft(trains[g], axis=1) * blowdown(f, rise * m, fall * m)[None, :]
                     for g, m in enumerate(groups))
        for k, col in enumerate(cols):
            shaped[k] *= pipe(f, col["primaryLengthM"], c_hot, x["primaryReflection"])
        pressure = np.fft.irfft(shaped, n=n, axis=1)
        # strong pulses steepen as they travel: raise the shaped pulses to a power above 1
        peak = np.max(np.abs(pressure)) or 1.0
        gamma = 1 + x["rasp"] * load
        pressure = np.sign(pressure) * (np.abs(pressure) / peak) ** gamma * peak
        # turbulent flow noise rides on each pulse (valve, collector and tailpipe jets), then
        # travels through the same pipes and silencers
        if x["flowNoise"] > 0:
            hiss_shape = highpass(f, 0.4 * x["flowNoiseHz"], 0.7) * (0.5 + resonator(f, x["flowNoiseHz"], 0.6))
            for k in range(len(cols)):
                env = circular(np.maximum(pressure[k], 0), lowpass(f, 400))
                r = math.sqrt(float(np.mean(pressure[k] ** 2))) or 1.0
                noise = circular(rng.standard_normal(n) * env, hiss_shape)
                nr = math.sqrt(float(np.mean(noise ** 2))) or 1.0
                flow = (0.4 + 0.6 * load) * (0.35 + 0.65 * min(rpm / self.top, 1.0))  # faster gas, more hiss
                pressure[k] += x["flowNoise"] * flow * r / nr * noise
        # afterfire pops (limiter ignition cut, overrun burble) explode in the exhaust
        pops = self.pops(n, fire, cut_flags, load, rpm, rng)
        if pops is not None:
            pressure += pops * peak
        spectra = np.fft.rfft(pressure, axis=1)
        if self.turbo:
            t = self.turbo
            damp = t["pulseDamping"]
            spectra *= ((1 - damp) + damp * lowpass(f, t["dampingHz"], 0.6))[None, :]
        c_pipe = gas_c(x["pipeTempK"])
        names = [col["name"] for col in cols]
        merge = x["merge"]
        if merge["type"] in ("xpipe", "hpipe"):
            cross = merge["crossover"] * lowpass(f, merge["crossoverHz"], 0.7) * shift(f, merge["pathM"] / c_pipe)
        exhaust = np.zeros(len(f), dtype=complex)
        mf = x["muffler"]
        if valve_open:
            silencer = lowpass(f, mf["openLowpassHz"], 0.6) * (0.7 + 0.3 * expansion_chamber(f, 2.0, mf["chamberLengthM"], c_pipe))
        else:
            silencer = (lowpass(f, mf["closedLowpassHz"], 0.6) * lowpass(f, mf["closedLowpassHz"] * 2.5, 0.6)
                        * expansion_chamber(f, mf["chamberAreaRatio"], mf["chamberLengthM"], c_pipe)
                        * 10 ** (-mf["closedCutDb"] / 20))
        for o in x["outlets"]:
            own = [names.index(nm) for nm in o["collectors"]]
            if merge["type"] == "y":
                feed = spectra.mean(axis=0)
            else:
                feed = spectra[own].sum(axis=0)
                if merge["type"] in ("xpipe", "hpipe"):
                    others = [k for k in range(len(cols)) if k not in own]
                    feed = (1 - merge["crossover"] * lowpass(f, merge["crossoverHz"], 0.7)) * feed
                    if others:
                        feed = feed + cross * spectra[others].sum(axis=0)
            path = (pipe(f, o["pipeLengthM"], c_pipe, x["pipeReflection"]) * silencer
                    * pipe(f, o["tailLengthM"], gas_c(x["pipeTempK"] * 0.7), 0.35)
                    * radiation(f, o["diameterM"], x["radiationHz"]) * shift(f, o["offsetM"] / AIR_C))
            exhaust += o["gain"] * feed * path
        exhaust_t = np.fft.irfft(exhaust * highpass(f, 25), n=n)

        # intake: suction pulses through runners, plenum and airbox
        it = d["intake"]
        intake_times = self.event_times(theta, it["intakeDeg"])
        train = np.zeros(n)
        for c in self.cyls:
            train += impulse_train(n, intake_times[c], self.cyl_gain[c] * (0.25 + 0.75 * load) * np.ones(len(intake_times[c])))
        intake = circular(train, blowdown(f, max(20 * deg_s, 2e-4), 70 * deg_s)
                          * pipe(f, it["runnerLengthM"], 360.0, -0.5)
                          * (0.35 + resonator(f, it["airboxHz"], 1.8))
                          * pipe(f, it["snorkelLengthM"], AIR_C, 0.4)
                          * radiation(f, it["mouthDiameterM"]) * highpass(f, 30)
                          * lowpass(f, it["filterLowpassHz"], 0.6))  # the air filter element and airbox walls
        # throttle hiss at part throttle
        hiss = unit(circular(rng.standard_normal(n), resonator(f, 2500, 0.9)))
        intake = intake + hiss * (0.3 * math.sqrt(float(np.mean(intake ** 2))) * load * (1 - load) * 4)

        # combustion noise radiated by the block (none from cut cylinders), valvetrain and injector ticks
        mech = d["mechanical"]
        fire_t = np.concatenate([fire[c] for c in self.cyls])
        fire_a = np.concatenate([np.where(cut_flags[c], 0.0, amps[c]) for c in self.cyls]) * (0.3 + 0.7 * load) * burning
        block_hz = mech["blockHz"]
        bay = lowpass(f, mech["bayLowpassHz"], 0.6)  # heard through the engine bay and bodywork
        block = circular(burst(n, fire_t, fire_a, 0.7e-3, rng),
                         (resonator(f, block_hz[0], 1.3) + 0.7 * resonator(f, block_hz[1], 1.6)) * bay)
        ticks = np.zeros(n)
        tick_total = mech["valvetrain"] + mech["injectors"]
        for offset, level, hz in ((x["evoDeg"] + 230, mech["valvetrain"], 5200), (590, mech["valvetrain"], 6100),
                                  (-300, mech["injectors"] * burning, 3900)):
            if level <= 0:
                continue
            ev = self.event_times(theta, offset)
            tt = np.concatenate([ev[c] for c in self.cyls])
            click = circular(impulse_train(n, tt, np.ones(len(tt))), resonator(f, hz, 6) * highpass(f, 2000) * bay)
            ticks += level / tick_total * unit(click)
        parts = {"exhaust": exhaust_t, "intake": intake, "block": block, "ticks": ticks}
        if self.turbo:
            env = circular(np.abs(exhaust_t), lowpass(f, 60))
            env = 0.6 + 0.4 * env / (np.max(env) or 1)
            parts["whoosh"] = circular(rng.standard_normal(n) * env, resonator(f, 2800, 0.7) + 0.6 * resonator(f, 5200, 1.2)) \
                * load * (rpm / self.top)
        return parts

    def pops(self, n, fire, cut_flags, load, rpm, rng):
        """Afterfire pops: unburnt fuel lighting in the hot exhaust (ignition cut, overrun burble)."""
        d = self.d
        x = d["exhaust"]
        times, amps = [], []
        if d["limiter"]["type"] == "ignitionCut" and d["limiter"]["popChance"] > 0:
            for c in self.cyls:
                hit = cut_flags[c] & (rng.random(len(fire[c])) < d["limiter"]["popChance"])
                times += list(fire[c][hit] + x["evoDeg"] / (6 * rpm) + rng.uniform(1e-3, 6e-3, hit.sum()))
                amps += list(rng.uniform(1.2, 2.6, hit.sum()))
        burble = d["overrun"]["burble"]
        if load < 0.5 and burble > 0 and rpm > 2200:
            rate = burble * 6 * min(1.0, (rpm - 2200) / 3000)
            count = rng.poisson(rate * n / FS)
            times += list(rng.uniform(0, n / FS, count))
            amps += list(rng.uniform(0.6, 1.8, count))
        if not times:
            return None
        cols = len(d["exhaust"]["collectors"])
        out = np.zeros((cols, n))
        for tm, a in zip(times, amps):
            k = rng.integers(cols)
            out[k] += a * burst(n, [tm % (n / FS)], [1.0], 1.6e-3, rng) * 0.5
            out[k] += a * circular(impulse_train(n, [tm % (n / FS)], [1.0]), decay(freqs(n), 4e-3)) / (4e-3 * FS)
        return out

    def valve_open(self, rpm, load):
        m = self.d["exhaust"]["muffler"]
        if m["valves"] == "auto":
            return rpm >= m["openAboveRpm"] or load >= m["openAboveLoad"]
        return m["valves"] == "open"

    def mix(self, parts, scales):
        """Weights are each component's level relative to the exhaust at full load (RMS)."""
        d = self.d
        mech = d["mechanical"]
        w = {"exhaust": d["exhaust"]["level"], "intake": d["intake"]["level"],
             "block": mech["combustion"], "ticks": mech["valvetrain"] + mech["injectors"],
             "whoosh": self.turbo["whooshLevel"] if self.turbo else 0.0}
        return sum(w[k] * scales[k] * v for k, v in parts.items())

    @staticmethod
    def scales_of(parts):
        out = {}
        for k, v in parts.items():
            r = math.sqrt(float(np.mean(v * v)))
            out[k] = 1 / r if r > 0 else 0.0
        return out

    # ---- loops -------------------------------------------------------------------------------

    def rng_for(self, name):
        return np.random.default_rng([self.d["seed"], zlib.crc32(name.encode())])

    def steady_loop(self, point, load, name):
        """A steady-rpm loop. Each rpm point's components are scaled from its full-load render, so
        the balance between exhaust, intake and mechanical noise shifts naturally off throttle."""
        n, theta, rpm = steady_theta(point, self.d["loops"]["seconds"])
        ref = self.render(theta, rpm, 1.0, self.rng_for(name + "/ref"), valve_open=self.valve_open(rpm, 1.0))
        scales = self.scales_of(ref)
        parts = ref if load >= 1.0 else self.render(theta, rpm, load, self.rng_for(name),
                                                    valve_open=self.valve_open(rpm, load))
        y = self.mix(parts, scales)
        y -= np.mean(y)
        return finish_a(y), rpm

    def limiter_loop(self, kind):
        lim = self.d["limiter"]
        p = lim[kind]
        top = lim["rpm"] + (60 if kind == "free" else 20)  # the speed overshoots the limit a little
        n, theta, rpm_mean, cut = limiter_theta(top, p["dropRpm"], p["bounceHz"], p["cutShare"],
                                                self.d["loops"]["limiterSeconds"])
        name = f"limiter_{kind}"
        # scale like a full-load loop at this speed, so the cut phases are quieter than full throttle
        n_ref, theta_ref, rpm_ref = steady_theta(rpm_mean, 0.5)
        ref = self.render(theta_ref, rpm_ref, 1.0, self.rng_for(name + "/ref"))
        scales = self.scales_of(ref)
        ref_mix = self.mix(ref, scales)
        norm = TARGET_A_RMS / (a_rms(ref_mix - np.mean(ref_mix)) or 1)
        parts = self.render(theta, rpm_mean, 1.0, self.rng_for(name), cut=cut)
        y = self.mix(parts, scales)
        y = (y - np.mean(y)) * norm
        return 0.97 * np.tanh(y / 0.97), rpm_mean


def finish_a(x):
    """Store a loop at the common A-weighted level, soft-limiting peaks."""
    r = a_rms(x)
    y = x * (TARGET_A_RMS / r if r > 0 else 1)
    return 0.97 * np.tanh(y / 0.97)


# --------------------------------------------------------------------------------------------
# Forced induction layers
# --------------------------------------------------------------------------------------------

def turbo_whistle(fi, rng):
    """Compressor whistle and whoosh, at the middle of its pitch range (the game pitches it by boost)."""
    lo, hi = fi["whistleHz"]
    base = math.sqrt(lo * hi)
    n = round(1.0 * FS)
    f = freqs(n)
    tone = periodic_tone(n, base, [(1, 1.0), (2, 0.18), (3, 0.05)], [(0.004, 3), (0.003, 7), (0.002, 13)], rng)
    period = n / FS
    f0 = round(base * period) / period
    narrow = circular(rng.standard_normal(n), resonator(f, f0, 30))
    whoosh = circular(rng.standard_normal(n), resonator(f, 0.55 * f0, 0.7) + 0.5 * resonator(f, 1.6 * f0, 1.0))
    return finish(unit(tone) + 0.5 * unit(narrow) + 0.45 * unit(whoosh)), f0


def blow_off(fi, rng, variant):
    """A one-shot when the throttle shuts on boost: valve dump, recirculation whoosh or surge flutter."""
    kind = fi["blowOff"]["type"]
    lo, hi = fi["whistleHz"]
    dur = {"atmospheric": 0.55, "recirculating": 0.6, "flutter": 0.7}.get(kind, 0.6)
    n = round(dur * FS)
    t = np.arange(n) / FS
    f = freqs(n)
    out = np.zeros(n)
    # the turbo spins down: whistle sweeping down from near full boost
    sweep = hi * (0.75 + 0.1 * variant) * np.exp(-t / 0.35) + lo * 0.6 * (1 - np.exp(-t / 0.35))
    phase = 2 * np.pi * np.cumsum(sweep) / FS
    out += 0.25 * np.sin(phase) * np.exp(-t / 0.3)
    if kind == "atmospheric":  # "pssh": the valve dumps boost to the air
        hiss = linear(rng.standard_normal(n), lambda ff: resonator(ff, 3200 + 400 * variant, 1.1) + 0.6 * highpass(ff, 5000))
        out += unit(hiss) * 0.9 * np.minimum(t / 0.006, 1) * np.exp(-t / (0.16 + 0.04 * variant))
    elif kind == "recirculating":  # softer whoosh as boost is routed back to the intake
        hiss = linear(rng.standard_normal(n), lambda ff: resonator(ff, 2200 + 300 * variant, 0.9))
        out += unit(hiss) * 0.45 * np.minimum(t / 0.02, 1) * np.exp(-t / 0.22)
    else:  # flutter: the compressor surges against the shut throttle, "stu-tu-tu-tu"
        rate = 16 + 4 * variant
        k = np.arange(int(dur * rate))
        times = k / rate + 0.004 * rng.standard_normal(len(k))
        amps = np.exp(-k / (5.5 + variant))
        chuff = burst(n, np.clip(times, 0, dur - 0.01), amps, 5e-3, rng)
        out += 0.9 * unit(linear(chuff, lambda ff: resonator(ff, 650, 1.2) + 0.5 * resonator(ff, 1900, 1.5)))
    return fade(0.9 * out / np.max(np.abs(out)), 20)


def supercharger_whine(fi, crank_rpm, rng):
    """Rotor whine at one crank speed: each rotor lobe pushes a pocket of air, pulsesPerRev a turn."""
    base = crank_rpm / 60 * fi["driveRatio"] * fi["pulsesPerRev"]
    n = round(0.6 * FS)
    f = freqs(n)
    tone = periodic_tone(n, base, [(1, 1.0), (2, 0.45), (3, 0.22), (4, 0.1)], [(0.002, 5)], rng)
    period = n / FS
    f0 = round(base * period) / period
    air = circular(rng.standard_normal(n) * (1 + 0.6 * np.sin(2 * np.pi * f0 * np.arange(n) / FS)),
                   resonator(f, 2.2 * f0, 1.2) + 0.5 * highpass(f, 3000))
    return finish(unit(tone) + 0.35 * unit(air)), f0


# --------------------------------------------------------------------------------------------
# Loudness: each loop's playback gain from the car's measured sound levels
# --------------------------------------------------------------------------------------------

def level_dba(d, rpm, load):
    """Modelled level (dBA) at an engine speed and load, through the measured idle and full-throttle
    levels: rises in proportion to log(rpm), and loadRangeDb between closed and full throttle."""
    L = d["loudness"]
    src = L.get("interior") or {}
    idle_db = src.get("idleDbA", 58.0)
    wot_db = src.get("fullThrottleDbA", 88.0)
    load_range = L.get("loadRangeDb", 12.0)
    e = d["engine"]
    idle_load = 0.15
    slope = (wot_db - idle_db - load_range * (1 - idle_load)) / math.log10(e["limiterRpm"] / e["idleRpm"])
    slope = max(slope, 4.0)
    return idle_db + slope * math.log10(max(rpm, 0.5 * e["idleRpm"]) / e["idleRpm"]) + load_range * (load - idle_load)


def loop_gain(d, rpm, load):
    return 10 ** (LEVEL_COMPRESSION * (level_dba(d, rpm, load) - REFERENCE_DBA) / 20)


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


def tyre_roll(rng):
    """Tyre and road noise heard from outside a passing car: broadband, peaking near 1 kHz."""
    n = round(1.2 * FS)
    f = freqs(n)
    t = np.arange(n) / FS
    period = n / FS
    noise = circular(rng.standard_normal(n), (resonator(f, 950, 0.8) + 0.45 * resonator(f, 2100, 1.0)
                                              + 0.3 * resonator(f, 420, 1.0)) * highpass(f, 120))
    tread = 0.9 + 0.07 * np.sin(2 * np.pi * 7 / period * t) + 0.04 * np.sin(2 * np.pi * 17 / period * t + 1)
    return finish(noise * tread)


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
    """One sheet table: the sounds of one car (or of the driving effects) inside a pack file."""

    def __init__(self, name, source, meta=None):
        self.name = name
        self.source = source
        self.meta = meta or {}
        self.items = []  # (kind, name, audio, extra)
        self.loops = []
        self.oneshots = []

    def loop(self, name, x, **extra):
        self.items.append(("loop", name, x, extra))

    def oneshot(self, name, x, **extra):
        self.items.append(("oneshot", name, x, extra))

    def write_luau(self, pack, length):
        lines = [
            "--[[",
            f"\tRegions of assets/audio/{pack}.flac, in seconds, for {self.source}.",
            "\tGenerated by tools/synth_audio.py; don't edit by hand. Loops: the game plays start..stop and",
            "\tloops loopStart..loopEnd; gain is the loop's playback gain from the car's measured sound levels.",
            "]]",
            "",
            "return {",
            f'\tasset = "{pack}",',
            f"\tlength = {luau_value(length / FS)},",
        ]
        for k, v in self.meta.items():
            if v is not None:
                lines.append(f"\t{k} = {luau_value(v)},")
        for key, regions in (("loops", self.loops), ("oneShots", self.oneshots)):
            lines.append(f"\t{key} = {{")
            for r in regions:
                lines.append("\t\t" + luau_value(r) + ",")
            lines.append("\t},")
        lines.append("}")
        SHEET_DIR.mkdir(parents=True, exist_ok=True)
        (SHEET_DIR / f"{self.name}.luau").write_text("\n".join(lines) + "\n")


def luau_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, str):
        return f'"{v}"'
    if isinstance(v, float):
        return f"{v:.6f}".rstrip("0").rstrip(".")
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {luau_value(x)}" for k, x in v.items() if x is not None) + " }"
    if isinstance(v, (list, tuple)):
        return "{ " + ", ".join(luau_value(x) for x in v) + " }"
    return str(v)


def seam_ratio(x):
    """How big the jump at the loop point is next to the loop's ordinary sample-to-sample steps."""
    steps = np.abs(np.diff(x))
    return float(abs(x[0] - x[-1]) / (np.percentile(steps, 99) or 1))


class Pack:
    """One uploaded sound file holding one or more sheets."""

    def __init__(self, name):
        self.name = name
        self.sheets = []

    def write(self):
        chunks, pos = [], 0
        gap = np.zeros(round(GAP * FS))
        pre_n, post_n = round(PRE_ROLL * FS), round(POST_ROLL * FS)
        for sheet in self.sheets:
            sheet.loops, sheet.oneshots = [], []
            for kind, name, x, extra in sheet.items:
                if kind == "loop":
                    # stored once, with a little of its end before it and of its start after it. The
                    # sound starts at the loop start, so a loop that restarts from the playback start
                    # also lands on matching audio
                    reps = math.ceil(max(pre_n, post_n) / len(x)) + 1
                    tiled = np.tile(x, reps)
                    block = np.concatenate([tiled[len(tiled) - pre_n:], x, tiled[:post_n]])
                    start = pos + pre_n
                    sheet.loops.append(dict(name=name, start=start / FS, loopStart=start / FS,
                                            loopEnd=(start + len(x)) / FS, stop=(start + len(x) + post_n) / FS, **extra))
                else:
                    block = x
                    sheet.oneshots.append(dict(name=name, start=pos / FS, stop=(pos + len(x)) / FS, **extra))
                chunks += [block, gap]
                pos += len(block) + len(gap)
        audio = np.concatenate(chunks)
        AUDIO_DIR.mkdir(parents=True, exist_ok=True)
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
        for sheet in self.sheets:
            sheet.write_luau(self.name, len(audio))
        return flac, len(audio) / FS


# --------------------------------------------------------------------------------------------
# Engine-order analysis (calibrating against recordings)
# --------------------------------------------------------------------------------------------

def decode_audio(path, start=0.0, end=None):
    cmd = ["ffmpeg", "-loglevel", "error", "-ss", str(start)]
    if end is not None:
        cmd += ["-t", str(end - start)]
    cmd += ["-i", str(path), "-f", "s16le", "-ac", "1", "-ar", str(FS), "-"]
    raw = subprocess.run(cmd, check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32767


def track_rpm(x, cylinders, lo, hi, hop=0.02, win=0.16):
    """Engine speed over time from the firing-frequency harmonics (subharmonic summation with a
    smoothness term). Returns frame times, rpm per frame and a 0..1 confidence per frame."""
    nwin, nhop, nfft = int(win * FS), int(hop * FS), 1 << 15
    window = np.hanning(nwin)
    cand = np.geomspace(lo, hi, 500)
    fire = cand / 60 * cylinders / 2  # firing frequency of each candidate
    fft_f = np.fft.rfftfreq(nfft, 1 / FS)
    frames = range(0, max(1, len(x) - nwin), nhop)
    scores = []
    for i in frames:
        mag = np.abs(np.fft.rfft(x[i:i + nwin] * window, nfft))
        logmag = np.log(1e-7 + mag / (np.max(mag) or 1))
        s = np.zeros(len(cand))
        for h in range(1, 7):  # harmonics of the firing frequency
            s += 0.85 ** h * np.interp(h * fire, fft_f, logmag, right=-16)
        s -= 0.5 * np.interp(0.5 * fire, fft_f, logmag, right=-16)  # don't settle an octave low
        scores.append(s)
    scores = np.array(scores)
    # dynamic programming: best path with a penalty on big jumps between frames
    step = np.log(cand[1] / cand[0])
    cost = scores[0].copy()
    back = np.zeros(scores.shape, dtype=int)
    jump = np.abs(np.arange(len(cand))[:, None] - np.arange(len(cand))[None, :]) * step
    penalty = 40 * np.maximum(jump - 0.04, 0)  # free up to ~4% per frame
    for k in range(1, len(scores)):
        total = cost[None, :] - penalty
        back[k] = np.argmax(total, axis=1)
        cost = scores[k] + total[np.arange(len(cand)), back[k]]
    path = [int(np.argmax(cost))]
    for k in range(len(scores) - 1, 0, -1):
        path.append(back[k][path[-1]])
    path = path[::-1]
    conf = np.array([(scores[k][p] - np.median(scores[k])) for k, p in enumerate(path)])
    times = np.array([(i + nwin / 2) / FS for i in frames])
    return times, cand[path], conf / (np.max(conf) or 1)


def order_spectrum(x, times, rpms, max_order, per_cycle=1440):
    """Resample to the crank-angle domain (per_cycle samples per 720 degrees) and return order
    amplitudes at every half order up to max_order (relative, linear)."""
    t = np.arange(len(x)) / FS
    rpm_t = np.interp(t, times, rpms)
    theta = np.concatenate([[0.0], np.cumsum(rpm_t[:-1] * 6 / FS)])
    cycles = int(theta[-1] // 720)
    if cycles < 4:
        return None
    grid = np.arange(cycles * per_cycle) * (720.0 / per_cycle)
    y = np.interp(grid, theta, x)
    spec = np.abs(np.fft.rfft(y * np.hanning(len(y))))
    orders = np.arange(1, int(max_order * 2) + 1) / 2  # 0.5, 1.0, ...
    bins = (orders * 2 * cycles).astype(int)  # order k has 2k cycles per 720 degrees
    amp = np.array([np.max(spec[max(b - 1, 0):b + 2]) for b in bins])
    between = np.array([np.median(spec[b + cycles // 4: b + 3 * cycles // 4]) for b in bins])
    return orders, amp, between


def analyze_recording(path, d, start=0.0, end=None):
    """Print the engine-order spectrum of a recording next to the synthesized loop at the same rpm."""
    e = d["engine"]
    x = decode_audio(path, start, end)
    x = x - np.mean(x)
    times, rpms, conf = track_rpm(x, e["cylinders"], 0.6 * e["idleRpm"], 1.1 * e["limiterRpm"])
    good = conf > 0.3
    rpm = float(np.median(rpms[good])) if good.any() else float(np.median(rpms))
    max_order = 3 * e["cylinders"] / 2
    res = order_spectrum(x, times, rpms, max_order)
    print(f"{path}: {len(x) / FS:.1f} s, tracked {np.min(rpms):.0f}-{np.max(rpms):.0f} rpm (median {rpm:.0f})")
    if res is None:
        print("  too short to analyse")
        return
    orders, amp, between = res
    model = EngineModel(d)
    point = min(d["loops"]["rpmPoints"], key=lambda p: abs(math.log(p / rpm)))
    synth, srpm = model.steady_loop(point, 1.0, f"on_{point}")
    s_times = np.array([0.0, len(synth) / FS])
    s_res = order_spectrum(np.tile(synth, 4), s_times, np.array([srpm, srpm]), max_order)
    fire = e["cylinders"] / 2
    ref = amp[np.argmin(np.abs(orders - fire))]
    s_ref = s_res[1][np.argmin(np.abs(orders - fire))]
    print(f"  order  recording dB  synth dB (rel. firing order {fire:g}, synth at {srpm:.0f} rpm)   rec. harmonic/noise dB")
    for o, a, b, s in zip(orders, amp, between, s_res[1]):
        print(f"  {o:5.1f}  {20 * math.log10(a / ref + 1e-9):10.1f}  {20 * math.log10(s / s_ref + 1e-9):8.1f}"
              f"   {20 * math.log10(a / (b + 1e-12)):8.1f}")


# --------------------------------------------------------------------------------------------
# Building sheets and packs
# --------------------------------------------------------------------------------------------

def engine_sheet(d, verbose=True):
    """Every loop and one-shot of one car's engine."""
    model = EngineModel(d)
    e = d["engine"]
    fi = d["forcedInduction"]
    meta = {"car": d["id"], "idleRpm": e["idleRpm"], "limiterRpm": d["limiter"]["rpm"],
            "forcedInduction": fi["type"] if fi else None}
    sheet = Sheet(d["sheet"], f"{d['id']} (assets/audio/engines/{d['id']}.json)", meta)
    report = []
    loads = (("on", 1.0), ("off", 0.0)) if d["loops"].get("offThrottle", True) else (("on", 1.0),)
    for point in d["loops"]["rpmPoints"]:
        for label, load in loads:
            name = f"{label}_{point}"
            x, rpm = model.steady_loop(point, load, name)
            gain = loop_gain(d, rpm, load)
            sheet.loop(name, x, rpm=round(rpm, 3), load=label, gain=round(gain, 5))
            report.append((name, rpm, gain, x))
    if d["loops"].get("limiter", True):
        for kind in ("free", "load"):
            x, rpm = model.limiter_loop(kind)
            gain = loop_gain(d, d["limiter"]["rpm"], 1.0)
            sheet.loop(f"limiter_{kind}", x, rpm=round(rpm, 3), load="limiter", kind=kind, gain=round(gain, 5))
            report.append((f"limiter_{kind}", rpm, gain, x))
    if fi and fi["type"] == "Turbo":
        rng = model.rng_for("turbo")
        x, f0 = turbo_whistle(fi, rng)
        sheet.loop("turbo_whistle", x, layer="turbo", baseHz=round(f0, 3))
        report.append(("turbo_whistle", 0, 1, x))
        count = fi["blowOff"].get("variants", 3)
        for k in range(1, count + 1):
            sheet.oneshot(f"blowoff_{k}", blow_off(fi, model.rng_for(f"blowoff_{k}"), k - 1), layer="blowoff")
        sheet.meta["turbo"] = {"minHz": float(fi["whistleHz"][0]), "maxHz": float(fi["whistleHz"][1]),
                               "blowOff": fi["blowOff"]["type"]}
    if fi and fi["type"] == "Supercharger":
        for k, crank in enumerate(fi["whineRpm"], 1):
            x, f0 = supercharger_whine(fi, crank, model.rng_for(f"whine_{k}"))
            sheet.loop(f"sc_whine_{k}", x, layer="supercharger", rpm=float(crank), baseHz=round(f0, 3))
            report.append((f"sc_whine_{k}", crank, 1, x))
        sheet.meta["supercharger"] = {"driveRatio": float(fi["driveRatio"]), "pulsesPerRev": int(fi["pulsesPerRev"])}
    if verbose:
        print(describe(d))
        for name, rpm, gain, x in report:
            print(f"    {name:16s} {rpm:7.0f} rpm  gain {20 * math.log10(gain):6.1f} dB  peak {np.max(np.abs(x)):.2f}"
                  f"  A-rms {a_rms(x):.3f}  seam {seam_ratio(x):.2f}")
    return sheet


def effects_sheet():
    rng = np.random.default_rng(812)
    effects = Sheet("Driving_Effects", "the driving effects")
    effects.loop("squeal", squeal(rng))
    effects.loop("road", road(rng))
    effects.loop("wind", wind(rng))
    effects.loop("whine", whine(rng), baseHz=WHINE_HZ)
    effects.loop("tyre_roll", tyre_roll(rng))
    for k in range(1, 7):
        effects.oneshot(f"crackle_{k}", crackle(rng))
    effects.oneshot("shift_cut", shift_cut(rng))
    effects.oneshot("shift_clunk", damped(round(0.15 * FS), [(170, 0.025, 1.0), (410, 0.012, 0.6), (1300, 0.004, 0.3)],
                                          noise=0.5, rng=rng))
    effects.oneshot("bump_knock", damped(round(0.25 * FS), [(55, 0.04, 1.0), (120, 0.02, 0.6)], noise=0.2, rng=rng))
    return effects


def load_packs():
    return json.loads(PACKS_FILE.read_text())


def build_pack(name, spec, verbose=True):
    pack = Pack(name)
    if spec.get("effects"):
        pack.sheets.append(effects_sheet())
    missing = []
    for car in spec.get("engines", []):
        if not definition_path(car).exists():
            missing.append(car)
            continue
        pack.sheets.append(engine_sheet(load_definition(car), verbose))
    if not pack.sheets:
        print(f"Skipped {name}: none of its cars has a definition yet ({', '.join(missing)})")
        return None
    path, seconds = pack.write()
    mb = path.stat().st_size / 1e6
    limits = load_packs().get("limits", {})
    print(f"Wrote {path.relative_to(ROOT)}: {seconds:.1f} s, {mb:.2f} MB, sheets "
          + ", ".join(s.name for s in pack.sheets))
    if missing:
        print(f"  (not yet in this pack, no definition: {', '.join(missing)})")
    if seconds > limits.get("maxSeconds", 420) or mb > limits.get("maxMegabytes", 19.5):
        print(f"  WARNING: {name} is over the upload limits in packs.json; move a car to another pack")
    assets = (SHEET_DIR.parent / "AudioAssets.luau").read_text()
    if f"{name} =" not in assets:
        print(f"  NOTE: add {name} = \"\" to VehicleAudio/AudioAssets.luau")
    return path


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--car", help="build only the pack holding this car (its config id)")
    ap.add_argument("--check", help="check a definition and print its firing and pulse pattern")
    ap.add_argument("--analyze", help="engine-order analysis of a recording (needs --car)")
    ap.add_argument("--start", type=float, default=0.0)
    ap.add_argument("--end", type=float, default=None)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    try:
        if args.check:
            print(describe(load_definition(args.check)))
            return
        if args.analyze:
            if not args.car:
                ap.error("--analyze needs --car")
            analyze_recording(args.analyze, load_definition(args.car), args.start, args.end)
            return
        packs = load_packs()["packs"]
        if args.car:
            load_definition(args.car)
            chosen = {n: s for n, s in packs.items() if args.car in s.get("engines", [])}
            if not chosen:
                sys.exit(f"{args.car} isn't in any pack: add it to a pack's engines in {PACKS_FILE.relative_to(ROOT)}")
        else:
            chosen = packs
        for name, spec in chosen.items():
            build_pack(name, spec, verbose=not args.quiet)
    except DefinitionError as e:
        sys.exit(f"Definition error: {e}")


if __name__ == "__main__":
    main()
