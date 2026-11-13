#!/usr/bin/env python3
"""Straight-line check of any car's drivetrain, outside Roblox.

A line-for-line Python copy of the game's drivetrain code (VehicleSimulation and the modules it
uses): the engine with its turbo or supercharger, the dual-clutch and torque-converter automatic
gearboxes, the centre coupling and limited-slip differentials, brakes and ABS, traction control and
the tyre model. It drives the car at 60 frames per second. The body is a point mass with static plus
load-transfer axle loads, so suspension, steering and Roblox's own physics are not modelled. Keep it
in step with the Luau when the drivetrain changes.

Cars are read from their configuration files (VehicleConfigurations/<Id>.luau) with
tools/luau_table.py. For each car it runs a full-throttle launch to top speed, 100-0 km/h braking,
idling, a part-throttle cruise followed by coasting, and, where they apply, idle creep and the brake
hold for automatics, boost response for turbo engines and a free rev in neutral. It ends with a
table comparing the results with the car's performanceTargets.

Usage:
  python3 tools/drivetrain_model.py                 # Prototype812
  python3 tools/drivetrain_model.py <ConfigId>      # a configuration in VehicleConfigurations/
  python3 tools/drivetrain_model.py path/to/Car.luau
  python3 tools/drivetrain_model.py --all           # every configuration
  python3 tools/drivetrain_model.py <ConfigId> --curve   # also print the full-load torque curve

Other tools import run() from here (tools/audio_preview.py renders sound previews with it):
  run(test, seconds, pedal_fn, brake_fn, v0=0.0, start_gear=1, dt=1/60, sub=8, *, config=None, gear_fn=None)
    pedal_fn(t, v), brake_fn(t, v)  pedal positions 0 to 1 at time t (s) and speed v (m/s)
    config     a configuration id, a path to a .luau file, a table read with luau_table, or a Car
               (default Prototype812)
    gear_fn    optional manual gear selection, called every frame as gear_fn(t, v, rpm, gear); it
               returns the gear wanted (0 neutral, -1 reverse) or None. A returned gear switches the
               gearbox to manual, like the paddles in game. Gear 0 frees the engine to rev to its limiter.
    An automatic starting from rest in first starts in park, as in game, and pulls into drive when
    a pedal is pressed (or a gear is selected).
  Returns one row per frame, or {"error": ...} if the simulation produced NaN. Row fields:
     0 time (s)                1 speed (km/h)             2 engine rpm
     3 gear                    4 clutch engagement (automatic: lock-up engagement), last sub-step
     5 rear slip ratios [RL, RR]                          6 acceleration (g)
     7 distance (m)            8 throttle opening          9 mean engine torque (Nm)
    10 rev limiter cutting    11 mean rear wheel speed (rad/s)
    12 boost (0 to 1)         13 boost gauge pressure (bar, negative under vacuum)
    14 shifting (bool)        15 lock-up engagement (automatics; None otherwise)
    16 converter slip, 1 - turbine/engine speed (automatics in gear; None otherwise)
    17 front slip ratios [FL, FR]                         18 share of drive torque at the front axle
    19 mean drive torque at the wheels (Nm)               20 parked (bool)
    21 accelerator pedal (after the reverse swap)
  load_car(config) returns a Car with the values tools need: car.curve_torque(rpm),
  car.full_load_torque(rpm), car.rf / car.rr (tyre radii, m), car.fd (final drive),
  car.tire_front / car.tire_rear (compound values, the same keys as TIRE below), car.engine,
  car.trans, car.drive (the config's tables) and car.cfg (the whole configuration).
"""
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from luau_table import load as luau_load  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
VEHICLE_SYSTEM = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem"
CONFIG_DIR = VEHICLE_SYSTEM / "VehicleConfigurations"
COMPOUNDS_FILE = VEHICLE_SYSTEM / "TireSimulation" / "Compounds.luau"
DEFAULT_CONFIG = "Prototype812"

G, RHO = 9.81, 1.225
TC_REFERENCE_SPEED = 6  # VehicleSimulation.luau
GEARBOX_INERTIA = 0.02  # dual-clutch gearbox internals, VehicleSimulation.luau
MAX_VACUUM_BAR = 0.75  # Engine.luau
DEFAULT_TURBINE_INERTIA = 0.05  # Transmission.luau
DEFAULT_LOCKUP_STIFFNESS = 400
AUTO_SHIFT_MARGIN_RPM = 250
MIN_SHIFT_REMAINING = 0.03
SHIFT_SYNC_RAD_S = 5
MPH = 1.609344  # km/h per mph
QUARTER_MILE = 402.336  # m
FOOT = 0.3048  # m


def sign(x): return 1 if x > 0 else (-1 if x < 0 else 0)
def clamp(x, a, b): return max(a, min(b, x))
def rpm_of(w): return w * 30 / math.pi
def rad_of(r): return r * math.pi / 30
def tyre_radius(w, a, rim): return (rim * 25.4 + 2 * w * a / 100) / 2000


def opt(table, key, default):
    """Luau's `table.key or default`."""
    value = table.get(key) if table else None
    return default if value is None or value is False else value


# --- tyre compounds (TireSimulation/Compounds.luau and Tire.compound) ---
_shared_compounds = None


def shared_compounds():
    global _shared_compounds
    if _shared_compounds is None:
        _shared_compounds = luau_load(COMPOUNDS_FILE)
    return _shared_compounds


def tire_compound(name, car_compounds, depth=0):
    own = car_compounds.get(name) if car_compounds else None
    if own and depth < 4:
        base = own.get("base") or "Performance"
        merged = dict(tire_compound(base, None if base == name else car_compounds, depth + 1))
        for key, value in own.items():
            if key != "base":
                merged[key] = value
        return merged
    shared = shared_compounds().get(name)
    if not shared:
        print(f"warning: unknown tyre compound {name!r}; using Performance", file=sys.stderr)
        return shared_compounds()["Performance"]
    return shared


def short_tire(c):
    """A compound with the short keys of the old TIRE table."""
    return dict(muLong=c["muLong"], muLat=c["muLat"], psr=c["peakSlipRatio"], psa=c["peakSlipAngle"],
                cL=c["shapeLong"], cY=c["shapeLat"], ls=c["loadSensitivity"], nom=c["nominalLoad"],
                relax=c["relaxationLength"], rr=c["rollingResistance"])


# --- engine (EngineSimulation/Engine.luau) ---
def curve_torque_of(spec, r):
    c = spec["torqueCurve"]
    if r <= c[0][0]: return c[0][1] * clamp(r / c[0][0], 0, 1)
    for (r0, t0), (r1, t1) in zip(c, c[1:]):
        if r <= r1: return t0 + (t1-t0)*(r-r0)/(r1-r0)
    return c[-1][1]


def boost_ceiling(fi, r):
    return clamp((r - fi["boostStartRpm"]) / max(fi["fullBoostRpm"] - fi["boostStartRpm"], 1), 0, 1)


def full_load_torque(spec, r):
    torque = curve_torque_of(spec, r)
    fi = spec.get("forcedInduction")
    if fi:
        share = fi["offBoostTorqueShare"]
        torque *= share + (1 - share) * boost_ceiling(fi, r)
    return torque


class Engine:
    def __init__(s, spec):
        s.spec = spec
        s.omega = rad_of(spec["idleRpm"]); s.throttle = 0; s.cut = False
        s.boost = 0.0; s.delivered = 0.0; s.spool_rate = 0.0; s.dump_rate = 0.0
        fi = spec.get("forcedInduction")
        if fi and fi["type"] == "Turbo":
            share = clamp(fi["offBoostTorqueShare"], 0.05, 0.95)
            u90 = share + 0.9 * (1 - share)
            s.spool_rate = math.log(((1 - share) / share) / ((1 - u90) / u90)) / fi["spoolTime"]
            s.dump_rate = math.log(10) / fi["dumpTime"]

    def boost_bar(s):
        fi = s.spec.get("forcedInduction")
        if not fi: return 0
        share = fi["offBoostTorqueShare"]
        if s.delivered >= share: return (s.delivered - share) / (1 - share) * fi["maxBoostBar"]
        return (s.delivered / share - 1) * MAX_VACUUM_BAR

    def net(s, pedal, dt):
        spec = s.spec
        r = rpm_of(s.omega)
        if r >= spec["limiterRpm"]: s.cut = True
        elif r < spec["limiterRpm"] - spec["limiterHysteresisRpm"]: s.cut = False
        target = 0 if s.cut else pedal
        if r < spec["idleRpm"]: target = max(target, clamp((spec["idleRpm"] - r) / 300, 0, 0.35))
        s.throttle += (target - s.throttle) * clamp(spec["throttleResponse"] * dt, 0, 1)
        delivered = s.throttle
        fi = spec.get("forcedInduction")
        if fi:
            share = fi["offBoostTorqueShare"]
            demand = clamp((s.throttle - share) / (1 - share), 0, 1)
            boost_target = demand * boost_ceiling(fi, r)
            if fi["type"] == "Supercharger":
                s.boost = boost_target
            else:
                rate = s.dump_rate
                if boost_target > s.boost:
                    load = min(s.throttle, share + (1 - share) * s.boost)
                    rate = s.spool_rate * clamp(r / fi["fullBoostRpm"], 0.1, 3) * load
                s.boost += (boost_target - s.boost) * clamp(rate * dt, 0, 1)
            delivered = min(s.throttle, share + (1 - share) * s.boost)
        s.delivered = delivered
        drive = curve_torque_of(spec, r) * delivered
        fric = spec["friction"]["static"] + spec["friction"]["perRpm"] * r if s.omega > 0 else 0
        return drive - fric * (1 - s.throttle)


# --- gearbox (TransmissionSimulation/Transmission.luau) ---
def coupling_torque(k, we, wi, Ie, Ii, Te, Tl, cap, dt):
    pred = (we - wi) + dt*(Te/Ie + Tl/Ii)
    return clamp(k*pred/(1 + k*dt*(1/Ie + 1/Ii)), -cap, cap)


class Trans:
    def __init__(s, spec):
        s.spec = spec
        s.gear, s.auto, s.timer, s.since = 1, True, 0.0, 10.0
        s.automatic = spec["type"] == "Automatic"
        s.from_gear = 1
        s.shifting, s.shift_start = False, False
        s.shift_duration, s.shift_elapsed, s.turbine_omega, s.lockup, s.k = 0.0, 0.0, 0.0, 0.0, 0.0
        s.turbine_inertia = opt(spec, "turbineInertia", DEFAULT_TURBINE_INERTIA)

    def gear_ratio(s, g):
        sp = s.spec
        if g == 0: return 0
        if g < 0: return -sp["reverseRatio"] * sp["finalDrive"]
        return sp["gearRatios"][g-1] * sp["finalDrive"]

    def ratio(s): return s.gear_ratio(s.gear)

    def shift(s, g):
        sp = s.spec
        g = clamp(g, -1, len(sp["gearRatios"]))
        if g == s.gear or s.since < sp["minShiftInterval"]: return False
        if s.automatic and s.shifting: return False
        s.from_gear = s.gear
        s.gear, s.timer, s.since = g, sp["shiftTime"], 0.0
        if s.automatic:
            s.shifting = g >= 1 and s.from_gear >= 1
            s.shift_start = s.shifting
            s.shift_duration = opt(sp, "downshiftTime", sp["shiftTime"]) if g < s.from_gear else sp["shiftTime"]
            s.shift_elapsed = 0
            s.timer = s.shift_duration if s.shifting else 0
        return True

    def is_shifting(s):
        if s.automatic: return s.shifting
        return s.timer > 0

    def shift_direction(s):
        if not (s.automatic and s.shifting): return 0
        return 1 if s.gear > s.from_gear else -1

    def shift_clutch_torque(s, wt, target, Te, Ie):
        remaining = max(s.shift_duration - s.shift_elapsed, MIN_SHIFT_REMAINING)
        return Te - (Ie + s.turbine_inertia) * (target - wt) / remaining

    def advance_shift(s, dt, target):
        if not s.shifting: return
        s.shift_elapsed += dt
        direction = 1 if s.gear > s.from_gear else -1
        if (target - s.turbine_omega) * direction >= -SHIFT_SYNC_RAD_S or s.shift_elapsed >= 3 * s.shift_duration:
            s.shifting = False

    def choose_automatic_gear(s, inrpm, up, down):
        ratios = s.spec["gearRatios"]
        if inrpm > up:
            if s.gear < len(ratios): s.shift(s.gear + 1)
            return
        if inrpm >= down: return
        target = s.gear
        for g in range(s.gear - 1, 0, -1):
            r = inrpm * ratios[g-1] / ratios[s.gear-1]
            if r > up - AUTO_SHIFT_MARGIN_RPM: break
            target = g
            if r >= down + AUTO_SHIFT_MARGIN_RPM: break
        if target != s.gear: s.shift(target)

    def update_auto(s, dt, inrpm, pedal):
        s.since += dt; s.timer = max(0, s.timer - dt)
        if not s.auto or s.gear <= 0: return
        sp = s.spec
        lo_up, hi_up = sp["autoUpshiftRpm"]["light"], sp["autoUpshiftRpm"]["full"]
        lo_dn, hi_dn = sp["autoDownshiftRpm"]["light"], sp["autoDownshiftRpm"]["full"]
        up = lo_up + (hi_up-lo_up)*pedal; down = lo_dn + (hi_dn-lo_dn)*pedal
        if s.automatic:
            s.choose_automatic_gear(inrpm, up, down)
        elif inrpm > up and s.gear < len(sp["gearRatios"]): s.shift(s.gear+1)
        elif inrpm < down and s.gear > 1:
            lower = inrpm * sp["gearRatios"][s.gear-2] / sp["gearRatios"][s.gear-1]
            if lower < hi_up - 400: s.shift(s.gear-1)

    def update_lockup(s, dt, kmh, erpm, idle):
        lu = s.spec["lockup"]
        threshold = lu["minSpeedKmh"] - 3 if s.lockup > 0 else lu["minSpeedKmh"]
        step = dt / lu["engageTime"]
        if s.gear >= lu["minGear"] and kmh > threshold and erpm > idle - 150:
            s.lockup = min(1, s.lockup + step)
        else:
            s.lockup = max(0, s.lockup - 4 * step)

    def engagement(s, erpm, inrpm, pedal, idle):
        if s.gear == 0: return 0
        e = 1
        if abs(s.gear) == 1 and inrpm < erpm - 150:
            launch = s.spec["launchRpm"]
            lt = launch["min"] + (launch["max"]-launch["min"])*pedal
            e = clamp((erpm - (lt - 600)) / 600, 0, 1)
        if erpm < idle - 150: e = min(e, clamp((erpm - 600) / (idle - 750), 0, 1))
        if s.timer > 0: e = min(e, s.spec["shiftTorqueFraction"])
        return e

    def clutch(s, we, wi, Ie, Ii, Te, Tl, cap, dt):
        if cap <= 0: return 0
        return coupling_torque(s.spec["clutchStiffness"], we, wi, Ie, Ii, Te, Tl, cap, dt)

    def converter(s, a, b):
        c = s.spec["converter"]; k = s.k
        stall, coupling = c["torqueRatio"], c["couplingPoint"]
        sr = b / a
        if sr <= 0:
            imp = k * a * a
            return imp, stall * imp, 2 * k * a, 0, 2 * stall * k * a, 0
        if sr < coupling:
            m = (stall - 1) / coupling
            return k * a * a, k * (stall * a * a - m * a * b), 2 * k * a, 0, k * (2 * stall * a - m * b), -k * m * a
        if sr <= 1:
            kc = k / (1 - coupling)
            torque = kc * a * (a - b)
            return torque, torque, kc * (2 * a - b), -kc * a, kc * (2 * a - b), -kc * a
        ko = k / (1 - coupling) * opt(c, "overrunCapacity", 0.6)
        torque = -ko * b * (b - a)
        return torque, torque, ko * b, -ko * (2 * b - a), ko * b, -ko * (2 * b - a)

    def torque_ratio(s, a, b):
        c = s.spec["converter"]
        sr = max(b / a, 0)
        if sr >= c["couplingPoint"]: return 1
        return c["torqueRatio"] - (c["torqueRatio"] - 1) * sr / c["couplingPoint"]

    def automatic_torque(s, we, wt, Ie, Ii, Te, Tl, lock_cap, dt):
        imp, tur, pa, pb, qa, qb = s.converter(we, wt)
        alpha, beta = dt / Ie, dt / Ii
        m11, m12, m21, m22 = 1 + alpha * pa, alpha * pb, -beta * qa, 1 - beta * qb
        r1, r2 = alpha * (Te - imp), beta * (tur - Tl)
        det = m11 * m22 - m12 * m21
        da = (r1 * m22 - m12 * r2) / det
        db = (m11 * r2 - m21 * r1) / det
        imp += pa * da + pb * db
        tur += qa * da + qb * db
        lock = 0
        if lock_cap > 0:
            k = opt(s.spec["lockup"], "stiffness", DEFAULT_LOCKUP_STIFFNESS)
            lock = coupling_torque(k, we, wt, Ie, Ii, Te - imp, Tl - tur, lock_cap, dt)
        return imp + lock, tur + lock, lock


# --- differentials (DifferentialSystem/Differential.luau) ---
def diff_split(spec, tin, wl, wr, inertia, dt):
    kind = spec.get("type", "Open") if spec else "Open"
    if kind == "Open": return tin / 2, tin / 2
    if kind == "Locked":
        stiffness, maxT = 5000, math.inf
    else:
        lock = spec["powerLock"] if tin >= 0 else spec["coastLock"]
        stiffness, maxT = spec["stiffness"], spec["preload"] + lock*abs(tin)
    d = wl - wr; eq = abs(d)*inertia/dt
    t = clamp(clamp(stiffness*d, -maxT, maxT), -eq, eq); return tin/2 - t/2, tin/2 + t/2


def centre_split(spec, tin, wf, wr, rf, rr, i_f, i_r, dt):
    base = spec["baseFrontShare"]
    front = tin * base
    front_speed = wf * rf
    difference = wr * rr - front_speed
    deadband = spec["slipThreshold"] * max(abs(front_speed), 3)
    excess = max(abs(difference) - deadband, 0)
    if difference < 0: excess = -excess
    preload = opt(spec, "preload", 0)
    max_forward = preload + (spec["maxFrontShare"] - base) * abs(tin)
    max_back = preload + base * abs(tin)
    eq = abs(excess) / (dt * (rf / (2 * i_f) + rr / (2 * i_r)))
    transfer = clamp(clamp(spec["stiffness"] * excess, -max_back, max_forward), -eq, eq)
    front += transfer
    return front, tin - front


# --- brakes (CorePhysics/Brakes.luau) ---
def brake_torque(spec, front, pedal, hb, slip, abs_on):
    t = (spec["maxTorqueFront"] if front else spec["maxTorqueRear"]) * pedal
    hbt = 0 if front else spec["handbrakeTorque"]*hb
    target = spec["abs"]["targetSlip"]
    if abs_on and pedal > 0 and hbt == 0 and slip < -target:
        t *= clamp(1 - (-slip - target)/target, 0.15, 1)
    return max(t, hbt)


# --- tyres (TireSimulation/Tire.luau) ---
def shape(s, c): return math.sin(c * math.atan(math.tan(math.pi/(2*c)) * s))


class Wheel:
    def __init__(s, car, front):
        s.front = front
        s.r = car.rf if front else car.rr
        s.I = car.tires["front" if front else "rear"]["inertia"]
        s.c = car.compound_front if front else car.compound_rear
        s.omega, s.slip, s.alpha, s.driven, s.share = 0.0, 0.0, 0.0, False, 0
        s.load = 0; s.drive = 0; s.brake = 0; s.fx = 0

    def tyre(s, load, vlong, vlat, ws, grip, dt):
        c = s.c
        if load <= 0: s.alpha = 0; return 0, 0, 0, 0
        sr = (ws - vlong) / max(abs(vlong), 3)
        ta = math.atan2(vlat, max(abs(vlong), 0.5)); s.alpha += (ta - s.alpha) * clamp(abs(vlong)*dt/c["relaxationLength"], 0.05, 1)
        lf = clamp(1 - c["loadSensitivity"]*(load/c["nominalLoad"] - 1), 0.7, 1.15)
        sx, sy = sr/c["peakSlipRatio"], s.alpha/math.radians(c["peakSlipAngle"]); m = math.hypot(sx, sy)
        if m < 1e-6: return 0, 0, sr, s.alpha
        return (c["muLong"]*grip*lf*load*shape(m, c["shapeLong"])*(sx/m),
                -c["muLat"]*grip*lf*load*shape(m, c["shapeLat"])*(sy/m), sr, s.alpha)


class Axle:
    def __init__(s, left, right, share, diff):
        s.left, s.right, s.share, s.diff, s.torque = left, right, share, diff, 0


def build_axles(car, wheels):
    """VehicleSimulation:_buildAxles. Returns the driven axles (front first), the centre coupling and the front share."""
    d = car.drive
    coupling = d.get("centreCoupling") if d["layout"] == "AWD" else None
    if d["layout"] == "FWD": front_share = 1
    elif d["layout"] == "RWD": front_share = 0
    elif coupling: front_share = clamp(coupling["baseFrontShare"], 0, 1)
    else: front_share = clamp(d.get("frontTorqueShare", 0), 0, 1)
    axles = []
    if front_share > 0 or coupling: axles.append(Axle(wheels[0], wheels[1], front_share, d.get("frontDifferential")))
    if front_share < 1 or coupling: axles.append(Axle(wheels[2], wheels[3], 1 - front_share, d.get("rearDifferential")))
    for ax in axles:
        for w in (ax.left, ax.right):
            w.driven, w.share = True, ax.share
    return axles, coupling, front_share


def input_omega(ratio, axles):
    """VehicleSimulation:_inputOmega"""
    if ratio == 0: return 0
    total, weight = 0, 0
    for ax in axles:
        total += (ax.left.omega + ax.right.omega) / 2 * ax.share
        weight += ax.share
    return ratio * total / max(weight, 1e-6)


# --- configurations ---
class Car:
    """One configuration's values, read from its Luau table."""
    def __init__(s, cfg, source=""):
        s.cfg = cfg
        s.id = cfg.get("id") or source
        s.name = cfg.get("displayName") or s.id
        s.engine, s.trans, s.drive, s.brakes = cfg["engine"], cfg["transmission"], cfg["drivetrain"], cfg["brakes"]
        s.tires = cfg["tires"]
        s.targets = cfg.get("performanceTargets") or {}
        mass = cfg["mass"]
        s.mass = mass["kerbKg"] + mass["driverKg"]
        s.front, s.comh, s.wb = mass["frontShare"], mass["comHeight"], cfg["dimensions"]["wheelbase"]
        aero = cfg["aero"]
        s.cda, s.clf, s.clr = aero["dragArea"], aero["downforceAreaFront"], aero["downforceAreaRear"]
        compounds = s.tires.get("compounds")
        s.compound_front = tire_compound(s.tires["front"]["compound"], compounds)
        s.compound_rear = tire_compound(s.tires["rear"]["compound"], compounds)
        f, r = s.tires["front"], s.tires["rear"]
        s.rf = tyre_radius(f["widthMm"], f["aspect"], f["rimInches"])
        s.rr = tyre_radius(r["widthMm"], r["aspect"], r["rimInches"])
        s.fd = s.trans["finalDrive"]
        s.automatic = s.trans["type"] == "Automatic"
        s.fi = s.engine.get("forcedInduction")
        s.tire_front, s.tire_rear = short_tire(s.compound_front), short_tire(s.compound_rear)

    def curve_torque(s, rpm): return curve_torque_of(s.engine, rpm)
    def full_load_torque(s, rpm): return full_load_torque(s.engine, rpm)


_cars = {}


def config_path(config):
    p = pathlib.Path(config)
    if p.suffix == ".luau" or p.exists():
        return p
    return CONFIG_DIR / f"{config}.luau"


def load_car(config=None):
    """A Car from an id, a .luau path, a table read with luau_table, or a Car (returned as is)."""
    if isinstance(config, Car): return config
    if isinstance(config, dict): return Car(config)
    key = str(config or DEFAULT_CONFIG)
    if key not in _cars:
        path = config_path(key)
        _cars[key] = Car(luau_load(path), path.stem)
    return _cars[key]


# --- the drive (CorePhysics/VehicleSimulation.luau step, along a straight line) ---
def select_gear(tr, gear, v, input_rpm, limiter):
    """VehicleSimulation:shiftUp / shiftDown, for a jump to any gear: no reverse while rolling, and
    no downshift that would over-rev the engine. input_rpm: gearbox input speed the wheels imply."""
    gear = clamp(gear, -1, len(tr.spec["gearRatios"]))
    if (gear == -1 or tr.gear == -1) and abs(v) > 2: return
    if 1 <= gear < tr.gear:
        ratios = tr.spec["gearRatios"]
        if input_rpm * ratios[gear-1] / ratios[tr.gear-1] > limiter + 200: return
    tr.shift(gear)


def run(test, seconds, pedal_fn, brake_fn, v0=0.0, start_gear=1, dt=1/60, sub=8, *, config=None, gear_fn=None):
    car = load_car(config)
    E, T, D = car.engine, car.trans, car.drive
    eng, tr = Engine(E), Trans(T)
    wheels = [Wheel(car, True), Wheel(car, True), Wheel(car, False), Wheel(car, False)]
    axles, coupling, front_share = build_axles(car, wheels)
    rear = wheels[2:]
    tr.gear = start_gear
    parked = False
    if tr.automatic:
        stall = T["converter"]["stallRpm"]
        tr.k = full_load_torque(E, stall) / rad_of(stall) ** 2
        if v0 == 0 and start_gear == 1:
            parked, tr.gear, tr.from_gear = True, 0, 0
    for w in wheels: w.omega = v0 / w.r
    if v0 > 0:
        eng.omega = rad_of(min(E["limiterRpm"] - 900, rpm_of(v0 / car.rr * tr.ratio())))
        if tr.automatic and tr.gear >= T["lockup"]["minGear"] and v0 * 3.6 > T["lockup"]["minSpeedKmh"]:
            tr.lockup = 1
    tc = D.get("tractionControl")
    tc_on = bool(tc and tc.get("enabled"))
    abs_on = car.brakes["abs"]["enabled"]
    eff, Ie = T["efficiency"], E["inertia"]
    min_omega, max_omega = rad_of(E["idleRpm"]*0.55), rad_of(E["limiterRpm"]+400)
    speed_limit = E.get("speedLimitKmh")
    v, x, t, a_prev, log = v0, 0.0, 0.0, 0.0, []
    tc_cut = 0.0
    while t < seconds:
        pedal_in, brake_in = pedal_fn(t, v), brake_fn(t, v)
        if gear_fn is not None:
            want = gear_fn(t, v, rpm_of(eng.omega), tr.gear)
            if want is not None:
                # a gear request is the driver taking over: manual mode, out of park
                parked, tr.auto = False, False
                if want != tr.gear:
                    select_gear(tr, want, v, rpm_of(abs(input_omega(tr.ratio(), axles))), E["limiterRpm"])
        if parked and (pedal_in > 0.05 or brake_in > 0.05):
            parked = False
            tr.shift(1)
        pedal, brake = pedal_in, brake_in
        if tr.gear == -1: pedal, brake = brake_in, pedal_in
        hold_brake = 1 if parked else brake
        engine_pedal = pedal
        if speed_limit: engine_pedal = min(pedal, clamp((speed_limit - abs(v) * 3.6) / 3, 0, 1))
        q = 0.5 * RHO * v * v
        transfer = car.mass * a_prev * car.comh / car.wb
        fl = (car.mass * G * car.front - transfer + q * car.clf) / 2; rl = (car.mass * G * (1 - car.front) + transfer + q * car.clr) / 2
        for w in wheels: w.load = max(fl if w.front else rl, 0)
        ir = rpm_of(abs(input_omega(tr.ratio(), axles)))
        tr.update_auto(dt, ir, pedal)
        if tr.automatic: tr.update_lockup(dt, abs(v) * 3.6, rpm_of(eng.omega), E["idleRpm"])
        h = dt / sub; fxsum = [0.0]*4; te_sum = 0.0; wt_sum = 0.0; front_sum = 0.0; drive_sum = 0.0
        turbine = 0
        for _ in range(sub):
            ratio = tr.ratio()
            win = input_omega(ratio, axles)
            shifting = False
            if tr.automatic:
                if tr.shift_start:
                    tr.shift_start = False
                    tr.turbine_omega = input_omega(tr.gear_ratio(tr.from_gear), axles)
                shifting = tr.shifting
                turbine = tr.turbine_omega if shifting else win
                direction = tr.shift_direction()
                e = tr.lockup
                cap = e * T["lockup"]["maxTorque"]
                shift_pedal = engine_pedal
                if direction < 0 and eng.omega < win:
                    shift_pedal = max(engine_pedal, opt(T, "downshiftBlip", 0))
                Te = eng.net(shift_pedal, h)
                if direction > 0 and Te > 0:
                    Te *= 1 - T["shiftTorqueReduction"]
            else:
                e = tr.engagement(rpm_of(eng.omega), rpm_of(abs(win)), pedal, E["idleRpm"]); cap = e * T["clutchMaxTorque"]
                Te = eng.net(engine_pedal, h)
            if tc_on and ratio != 0:
                drive_slip, available = 0, 0
                for ax in axles:
                    for w in (ax.left, ax.right):
                        slip = (w.omega * w.r - v) / max(abs(v), TC_REFERENCE_SPEED)
                        drive_slip = max(drive_slip, slip * sign(ratio))
                        available += w.c["muLong"] * 1.0 * max(w.load, 0) * w.r
                excess = drive_slip - tc["targetSlip"]
                if excess > 0: tc_cut = min(1, tc_cut + h * tc["rate"] * excess / tc["targetSlip"])
                else: tc_cut = max(0, tc_cut - h * tc["recovery"])
                limit = available / (abs(ratio) * eff) * tc["headroom"] * (1 - tc_cut)
                # an automatic: a slipping converter multiplies the engine's torque (and, on the brakes,
                # this holds the engine where launch control would)
                if tr.automatic: Te = min(Te, limit / tr.torque_ratio(eng.omega, turbine))
                else: Te = min(Te, limit)
                cap = min(cap, limit)
            else:
                tc_cut = 0
            te_sum += Te
            for w in wheels:
                fx, fy, w.slip, w.alphaOut = w.tyre(w.load, v, 0.0, w.omega*w.r, 1.0, h); w.fx = fx
                w.brake = brake_torque(car.brakes, w.front, hold_brake, 0, w.slip, abs_on)
            Tc, load_e, locked = 0.0, 0.0, False
            if ratio != 0 and (cap > 0 or tr.automatic):
                Ii, Tl = (0 if tr.automatic else GEARBOX_INERTIA), 0.0
                if len(axles) == 1:
                    for ax in axles:
                        for w in (ax.left, ax.right):
                            Ii += w.I / ratio**2
                            rolling = w.load * w.c["rollingResistance"] * w.r
                            Tl += (w.fx * w.r + (w.brake + rolling) * sign(w.omega)) / ratio
                else:
                    # all-wheel drive: each axle counts by its share of the torque (reduced inertia of a split drive)
                    inverse, weighted = 0, 0
                    for ax in axles:
                        axle_inertia, axle_resist = 0, 0
                        for w in (ax.left, ax.right):
                            rolling = w.load * w.c["rollingResistance"] * w.r
                            axle_inertia += w.I
                            axle_resist += w.fx * w.r + (w.brake + rolling) * sign(w.omega)
                        inverse += ax.share * ax.share / axle_inertia
                        weighted += ax.share * axle_resist / axle_inertia
                    Ii += 1 / (ratio * ratio * inverse)
                    Tl = weighted / (ratio * inverse)
                if tr.automatic and shifting:
                    # the turbine runs free of the wheels, held back (or pulled up) by the shift clutches
                    Tc = tr.shift_clutch_torque(turbine, win, Te, Ie)
                    load_e, delivered, _ = tr.automatic_torque(eng.omega, turbine, Ie, tr.turbine_inertia, Te, Tc, cap, h)
                    tr.turbine_omega += h * (delivered - Tc) / tr.turbine_inertia
                elif tr.automatic:
                    # the converter sees the wheels through the gearbox's losses, plus its own turbine
                    load_e, Tc, lock = tr.automatic_torque(eng.omega, turbine, Ie, tr.turbine_inertia + Ii / eff, Te, Tl / eff, cap, h)
                    locked = cap > 0 and abs(lock) < cap * 0.999
                else:
                    Tc = tr.clutch(eng.omega, win, Ie, Ii, Te, Tl, cap, h); load_e = Tc
                    locked = abs(Tc) < cap * 0.999
            out_ratio = ratio
            if shifting and tr.gear < tr.from_gear and Tc > 0:
                out_ratio = tr.gear_ratio(tr.from_gear)  # the old gear's clutch still drives
            wt = Tc * out_ratio * eff
            if coupling:
                fa, ra = axles[0], axles[1]
                fa.torque, ra.torque = centre_split(coupling, wt, (fa.left.omega + fa.right.omega) / 2, (ra.left.omega + ra.right.omega) / 2,
                                                    fa.left.r, ra.left.r, fa.left.I, ra.left.I, h)
                front_sum += fa.torque; drive_sum += wt
            else:
                for ax in axles: ax.torque = wt * ax.share
            for ax in axles:
                ax.left.drive, ax.right.drive = diff_split(ax.diff, ax.torque, ax.left.omega, ax.right.omega, ax.left.I, h)
            eng.omega = clamp(eng.omega + h*(Te - load_e)/Ie, min_omega, max_omega)
            if shifting: tr.advance_shift(h, win)
            for i, w in enumerate(wheels):
                if w.driven and tr.automatic:
                    # the turbine, and the engine while the lock-up holds, turn with the wheels (not in a shift)
                    I = w.I
                    if not shifting:
                        I += (tr.turbine_inertia + (Ie if locked else 0)) * eff * ratio * ratio * w.share / 2
                else:
                    I = w.I + (Ie*ratio*ratio*w.share/2 if (w.driven and locked) else 0)
                drive = w.drive if w.driven else 0
                tt = w.fx * w.r
                lim = I*abs(w.omega - v/w.r)/h + abs(drive) + w.brake; tt = clamp(tt, -lim, lim)
                rolling = w.load * w.c["rollingResistance"] * w.r
                nw = w.omega + h*(drive - tt - rolling*sign(w.omega))/I
                bs = h*w.brake/I
                nw = 0.0 if abs(nw) <= bs else nw - sign(nw)*bs
                w.omega = nw; fxsum[i] += tt / w.r
            wt_sum += wt
        fx_total = sum(f / sub for f in fxsum)
        drag = q * car.cda * sign(v) if abs(v) > 0.01 else 0
        a = (fx_total - drag) / car.mass
        if abs(v) < 0.4 and hold_brake > 0.1: a = -v / dt  # parking hold
        v = min(0.0, v + a*dt) if tr.gear < 0 else max(0.0, v + a*dt)
        x += v*dt; t += dt; a_prev = a
        if any(math.isnan(w.omega) for w in wheels) or math.isnan(v) or math.isnan(eng.omega):
            return {"error": "NaN at t=%.2f" % t}
        if coupling: share = front_sum / drive_sum if abs(drive_sum) > 1 else front_share
        else: share = front_share
        conv_slip = None
        if tr.automatic: conv_slip = 1 - turbine / eng.omega if tr.ratio() != 0 else 0
        # row layout: see the module docstring (indices 0-11 are fixed; new fields go on the end)
        log.append((t, v*3.6, rpm_of(eng.omega), tr.gear, e, [w.slip for w in rear], a/G, x,
                    eng.throttle, te_sum / sub, eng.cut, sum(w.omega for w in rear) / 2,
                    eng.boost, eng.boost_bar(), tr.is_shifting(), tr.lockup if tr.automatic else None, conv_slip,
                    [w.slip for w in wheels[:2]], share, wt_sum / sub, parked, pedal))
    return log


# Values of the default car, kept for tools that used the old module constants.
_default = load_car(DEFAULT_CONFIG)
_e, _t = _default.engine, _default.trans
ENG = dict(idleRpm=_e["idleRpm"], limiterRpm=_e["limiterRpm"], hyst=_e["limiterHysteresisRpm"], inertia=_e["inertia"],
           resp=_e["throttleResponse"], fs=_e["friction"]["static"], fr=_e["friction"]["perRpm"],
           curve=[tuple(p) for p in _e["torqueCurve"]])
TR = dict(gears=list(_t["gearRatios"]), rev=_t["reverseRatio"], fd=_t["finalDrive"], eff=_t["efficiency"],
          shiftTime=_t["shiftTime"], shiftFrac=_t.get("shiftTorqueFraction"), clutchMax=_t.get("clutchMaxTorque"),
          stiff=_t.get("clutchStiffness"), launch=(_t["launchRpm"]["min"], _t["launchRpm"]["max"]) if _t.get("launchRpm") else None,
          up=(_t["autoUpshiftRpm"]["light"], _t["autoUpshiftRpm"]["full"]),
          down=(_t["autoDownshiftRpm"]["light"], _t["autoDownshiftRpm"]["full"]), minInt=_t["minShiftInterval"])
DIFF = dict(_default.drive["rearDifferential"])
BRK = dict(front=_default.brakes["maxTorqueFront"], rear=_default.brakes["maxTorqueRear"],
           hb=_default.brakes["handbrakeTorque"], target=_default.brakes["abs"]["targetSlip"])
TIRE = _default.tire_rear
RF, RR_ = _default.rf, _default.rr
MASS, FRONT, COMH, WB, CDA, CLF, CLR = _default.mass, _default.front, _default.comh, _default.wb, _default.cda, _default.clf, _default.clr


def curve_torque(r, config=None):
    return curve_torque_of(load_car(config).engine, r)


# --- configuration checks, for car builders (docs/VEHICLE_CONFIG.md lists every field) ---
SUSPENSION_KEYS = ["springRate", "bumpDamping", "reboundDamping", "staticLength", "bumpTravel", "droopTravel",
                   "bumpStopRate", "antiRollRate", "rollCenterHeight", "rideHeightOffset"]
REQUIRED = {
    "": ["id", "displayName", "mass", "dimensions", "engine", "transmission", "drivetrain", "suspension", "tires",
         "brakes", "aero", "steering", "performanceTargets", "visual"],
    "mass": ["kerbKg", "driverKg", "frontShare", "comHeight", "inertiaBox"],
    "mass.inertiaBox": ["width", "height", "length"],
    "dimensions": ["length", "width", "height", "wheelbase", "trackFront", "trackRear", "frontOverhang"],
    "engine": ["idleRpm", "limiterRpm", "limiterHysteresisRpm", "inertia", "torqueCurve", "friction", "throttleResponse"],
    "engine.friction": ["static", "perRpm"],
    "transmission": ["type", "gearRatios", "reverseRatio", "finalDrive", "efficiency", "shiftTime", "minShiftInterval",
                     "autoUpshiftRpm", "autoDownshiftRpm"],
    "transmission.autoUpshiftRpm": ["light", "full"], "transmission.autoDownshiftRpm": ["light", "full"],
    "drivetrain": ["layout", "rearDifferential", "frontDifferential"],
    "suspension.front": SUSPENSION_KEYS, "suspension.rear": SUSPENSION_KEYS,
    "tires.front": ["widthMm", "aspect", "rimInches", "compound", "inertia"],
    "tires.rear": ["widthMm", "aspect", "rimInches", "compound", "inertia"],
    "brakes": ["maxTorqueFront", "maxTorqueRear", "handbrakeTorque", "abs"], "brakes.abs": ["enabled", "targetSlip"],
    "aero": ["dragArea", "downforceAreaFront", "downforceAreaRear"],
    "steering": ["maxAngleLowSpeed", "maxAngleHighSpeed", "highSpeedKmh", "rate", "ackermann"],
    "visual": ["bodyColor", "driverSide"],
}
BY_KIND = {
    "DualClutch": {"transmission": ["shiftTorqueFraction", "clutchMaxTorque", "clutchStiffness", "launchRpm"],
                   "transmission.launchRpm": ["min", "max"]},
    "Automatic": {"transmission": ["shiftTorqueReduction", "converter", "lockup"],
                  "transmission.converter": ["stallRpm", "torqueRatio", "couplingPoint"],
                  "transmission.lockup": ["minGear", "minSpeedKmh", "engageTime", "maxTorque"]},
    "Turbo": {"engine.forcedInduction": ["type", "maxBoostBar", "offBoostTorqueShare", "boostStartRpm", "fullBoostRpm",
                                         "spoolTime", "dumpTime"]},
    "Supercharger": {"engine.forcedInduction": ["type", "maxBoostBar", "offBoostTorqueShare", "boostStartRpm", "fullBoostRpm"]},
    "Coupling": {"drivetrain.centreCoupling": ["baseFrontShare", "maxFrontShare", "slipThreshold", "stiffness"]},
    "LimitedSlip": ["preload", "powerLock", "coastLock", "stiffness"],
    "TractionControl": ["enabled", "targetSlip", "rate", "recovery", "headroom"],
}


def check_config(cfg):
    """Problems with a configuration: missing fields (errors) and values worth a second look (warnings)."""
    errors, warnings = [], []

    def at(path):
        node = cfg
        for key in [k for k in path.split(".") if k]:
            if not isinstance(node, dict) or key not in node: return None
            node = node[key]
        return node

    def need(table):
        for path, keys in table.items():
            node = at(path)
            if node is None:
                errors.append(f"missing {path}"); continue
            for key in keys:
                if not isinstance(node, dict) or key not in node:
                    errors.append(f"missing {(path + '.') if path else ''}{key}")
    need(REQUIRED)
    kind = at("transmission.type")
    if kind in BY_KIND: need(BY_KIND[kind])
    elif kind is not None: errors.append(f"transmission.type must be DualClutch or Automatic, not {kind!r}")
    fi = at("engine.forcedInduction")
    if fi is not None:
        if fi.get("type") in ("Turbo", "Supercharger"): need(BY_KIND[fi["type"]])
        else: errors.append("engine.forcedInduction.type must be Turbo or Supercharger")
    layout = at("drivetrain.layout")
    if layout not in ("RWD", "FWD", "AWD"): errors.append("drivetrain.layout must be RWD, FWD or AWD")
    if layout == "AWD":
        if at("drivetrain.centreCoupling") is not None: need(BY_KIND["Coupling"])
        elif at("drivetrain.frontTorqueShare") is None: errors.append("AWD needs drivetrain.centreCoupling or frontTorqueShare")
    for side in ("rearDifferential", "frontDifferential"):
        d = at("drivetrain." + side)
        if isinstance(d, dict):
            if d.get("type") == "LimitedSlip": need({"drivetrain." + side: BY_KIND["LimitedSlip"]})
            elif d.get("type") not in ("Open", "Locked"): errors.append(f"drivetrain.{side}.type must be Open, LimitedSlip or Locked")
    if at("drivetrain.tractionControl") is not None: need({"drivetrain.tractionControl": BY_KIND["TractionControl"]})
    if errors: return errors, warnings
    # values
    e, tr = cfg["engine"], cfg["transmission"]
    curve = e["torqueCurve"]
    if any(b[0] <= a[0] for a, b in zip(curve, curve[1:])): errors.append("engine.torqueCurve rpm must rise point to point")
    if curve[-1][0] < e["limiterRpm"]: warnings.append("engine.torqueCurve ends below limiterRpm (torque is held flat past the last point)")
    ratios = tr["gearRatios"]
    if not 1 <= len(ratios) <= 10: errors.append("transmission.gearRatios needs 1 to 10 gears")
    if any(b >= a for a, b in zip(ratios, ratios[1:])): errors.append("transmission.gearRatios must fall gear to gear")
    if tr["autoUpshiftRpm"]["full"] >= e["limiterRpm"]: warnings.append("autoUpshiftRpm.full is at or above limiterRpm: full-throttle upshifts happen on the limiter")
    steps = [a / b for a, b in zip(ratios, ratios[1:])]
    if steps and kind == "DualClutch":
        for p in (0, 0.5, 1):
            up = tr["autoUpshiftRpm"]["light"] + (tr["autoUpshiftRpm"]["full"] - tr["autoUpshiftRpm"]["light"]) * p
            dn = tr["autoDownshiftRpm"]["light"] + (tr["autoDownshiftRpm"]["full"] - tr["autoDownshiftRpm"]["light"]) * p
            if up / dn < max(steps) * 1.05:
                warnings.append(f"at {p:.0%} pedal the upshift/downshift rpm ratio {up / dn:.2f} is close to the largest gear step "
                                f"{max(steps):.2f}: the dual-clutch may shift back and forth")
    if fi:
        if not 0.05 < fi["offBoostTorqueShare"] < 0.95: errors.append("forcedInduction.offBoostTorqueShare must be between 0.05 and 0.95")
        if fi["fullBoostRpm"] <= fi["boostStartRpm"]: errors.append("forcedInduction.fullBoostRpm must be above boostStartRpm")
    if kind == "Automatic":
        c, lu = tr["converter"], tr["lockup"]
        if c["torqueRatio"] < 1: errors.append("converter.torqueRatio must be at least 1")
        if not 0.5 <= c["couplingPoint"] < 1: errors.append("converter.couplingPoint must be between 0.5 and 1")
        if c["stallRpm"] <= e["idleRpm"]: errors.append("converter.stallRpm must be above idleRpm")
        if not 1 <= lu["minGear"] <= len(ratios): errors.append("lockup.minGear must be a forward gear")
        if lu["maxTorque"] < max(p[1] for p in curve): warnings.append("lockup.maxTorque is below the peak engine torque: the lock-up will slip at full throttle")
    cc = at("drivetrain.centreCoupling")
    if layout == "AWD" and cc:
        if not 0 <= cc["baseFrontShare"] <= cc["maxFrontShare"] <= 1: errors.append("centreCoupling needs 0 <= baseFrontShare <= maxFrontShare <= 1")
        if cc["baseFrontShare"] > 0.3: warnings.append("centreCoupling.baseFrontShare above 0.3: see the known limitation in docs/VEHICLE_CONFIG.md")
    compounds = (cfg["tires"].get("compounds") or {})
    for axle in ("front", "rear"):
        name = cfg["tires"][axle]["compound"]
        if name not in compounds and name not in shared_compounds(): errors.append(f"tires.{axle}.compound {name!r} is not in Compounds.luau or tires.compounds")
    for name, own in compounds.items():
        base = own.get("base", "Performance")
        if base not in shared_compounds() and base not in compounds: errors.append(f"tires.compounds.{name}.base {base!r} doesn't exist")
    return errors, warnings


# --- tests and validation ---
def first(log, cond):
    for row in log:
        if cond(row): return row
    return None


def describe(car):
    e, tr, d = car.engine, car.trans, car.drive
    peak = max(car.full_load_torque(r) * rad_of(r) for r in range(500, e["limiterRpm"] + 1, 50)) / 1000
    fi = car.fi["type"].lower() if car.fi else "naturally aspirated"
    return (f"{car.name} ({car.id}): {peak:.0f} kW {fi}, {len(tr['gearRatios'])}-speed {tr['type']}, {d['layout']}"
            + (" with centre coupling" if d["layout"] == "AWD" and d.get("centreCoupling") else ""))


def shift_rows(log):
    """(index, time, km/h, rpm before, old gear, new gear) for each gear change."""
    return [(i, log[i][0], log[i][1], log[i-1][2], log[i-1][3], log[i][3]) for i in range(1, len(log)) if log[i][3] != log[i-1][3]]


def launch_gear_for_braking(car, v):
    """Brake tests start in 2nd (as the GT12's always has), or the next gear that keeps the engine
    below 85% of its limiter."""
    tr = Trans(car.trans)
    for g in range(2, len(car.trans["gearRatios"]) + 1):
        if rpm_of(v / car.rr * tr.gear_ratio(g)) < 0.85 * car.engine["limiterRpm"]: return g
    return len(car.trans["gearRatios"])


def brake_test(car, v0):
    log = run("brake", 10, lambda t, v: 0.0, lambda t, v: 1.0, v0=v0, start_gear=launch_gear_for_braking(car, v0), config=car)
    stop = first(log, lambda r: r[1] < 0.5)
    return log, stop


def boost_response(car, rpm):
    """Turbo lag: cruise at light throttle at this rpm in a middle gear, then floor it. Returns the
    seconds to 90% boost and the rpm then."""
    gear = min(3, len(car.trans["gearRatios"]))
    tr = Trans(car.trans)
    v0 = rad_of(rpm) / tr.gear_ratio(gear) * car.rr
    t_floor = 1.5
    log = run("boost", t_floor + 4, lambda t, v: 0.12 if t < t_floor else 1.0, lambda t, v: 0.0, v0=v0,
              start_gear=gear, config=car, gear_fn=lambda t, v, r, g: gear)
    row = first(log, lambda r: r[0] > t_floor and r[12] >= 0.9)
    start = first(log, lambda r: r[0] > t_floor)
    return (row[0] - t_floor, start[2], row[2]) if row else (None, start[2], None)


def table_row(name, model, target, unit, fmt="%.2f"):
    m = "--" if model is None else (fmt % model)
    if target is None:
        return f"  {name:22s} {m:>8s} {unit:5s}"
    diff = "" if model is None else f"{model - target:+.2f} {unit} ({(model - target) / target * 100:+.0f}%)"
    return f"  {name:22s} {m:>8s} {unit:5s} target {fmt % target:>7s}   {diff}"


def validate(car, curve=False):
    E, T = car.engine, car.trans
    print("== " + describe(car))
    results = {}
    # 1. full-throttle launch to top speed (automatics: also with the brake held first, as launch control does)
    seconds = 70
    log = run("launch", seconds, lambda t, v: 1.0, lambda t, v: 0.0, config=car)
    if isinstance(log, dict): print("  launch:", log["error"]); return
    if log[-1][1] - first(log, lambda r: r[0] >= seconds - 5)[1] > 1:
        seconds = 120  # still accelerating
        log = run("launch", seconds, lambda t, v: 1.0, lambda t, v: 0.0, config=car)
    r100, r200 = first(log, lambda r: r[1] >= 100), first(log, lambda r: r[1] >= 200)
    top = max(r[1] for r in log)
    fmt_t = lambda r: f"{r[0]:.2f}s" if r else "--"
    print(f"launch: 0-100 {fmt_t(r100)}  0-200 {fmt_t(r200)}  top {top:.1f} km/h  final gear {log[-1][3]}  final rpm {log[-1][2]:.0f}")
    clutch_name = "lock-up" if car.automatic else "clutch"
    for tt in (0.1, 0.3, 0.6, 1.0, 2.0, 3.0):
        row = first(log, lambda r: r[0] >= tt)
        print(f"  t={row[0]:.2f}s  {row[1]:6.1f} km/h  {row[2]:5.0f} rpm  gear {row[3]}  {clutch_name} {row[4]:.2f}  rear slip {row[5][0]:+.3f}  {row[6]:.2f} g"
              + (f"  boost {row[12]:.2f}" if car.fi else "") + (f"  converter slip {row[16]:.2f}" if car.automatic else "")
              + (f"  front {row[18]:.0%}" if car.drive["layout"] == "AWD" else ""))
    shifts = shift_rows(log)
    print("  shifts (time, km/h, rpm before, new gear):", [(round(t, 2), round(k), round(rp), g) for _, t, k, rp, _, g in shifts])
    late = [r[2] for r in log if r[0] > seconds - 10]
    print(f"  rpm range in the last 10 s: {min(late):.0f}-{max(late):.0f}")
    launches = {"from idle": log}
    if car.automatic:
        held = run("brake-torque launch", 62, lambda t, v: 1.0, lambda t, v: 1.0 if t < 2.0 else 0.0, config=car)
        moving = [r for r in held if r[0] >= 2.0]
        before = first(held, lambda r: r[0] >= 1.95)
        print(f"  brake-torque launch: {before[2]:.0f} rpm against the brake"
              + (f", boost {before[12]:.2f}" if car.fi else "") + "; 0-100 "
              + fmt_t(first([(r[0] - 2.0,) + r[1:] for r in moving], lambda r: r[1] >= 100)))
        launches["brake-torque"] = [(r[0] - 2.0,) + tuple(r[1:7]) + (r[7] - before[7],) + tuple(r[8:]) for r in moving]
    # acceleration figures: the better of the launches, as published figures use launch control
    def accel_figures(lg):
        out = {}
        for key, kmh in (("zeroTo60Mph", 60 * MPH), ("zeroTo100", 100), ("zeroTo100Mph", 100 * MPH), ("zeroTo200", 200)):
            row = first(lg, lambda r: r[1] >= kmh)
            out[key] = row[0] if row else None
        roll = first(lg, lambda r: r[7] >= FOOT)
        out["rollout"] = (out["zeroTo60Mph"] - roll[0]) if (roll and out["zeroTo60Mph"]) else None
        qm = first(lg, lambda r: r[7] >= QUARTER_MILE)
        out["quarterMile"], out["quarterMileKmh"] = (qm[0], qm[1]) if qm else (None, None)
        return out
    figures = [accel_figures(lg) for lg in launches.values()]
    best = {k: min((f[k] for f in figures if f[k] is not None), default=None) for k in figures[0] if k != "quarterMileKmh"}
    best["quarterMileKmh"] = max((f["quarterMileKmh"] for f in figures if f["quarterMileKmh"]), default=None)
    best["topSpeedKmh"] = top
    results.update(best)
    # 2. braking with ABS
    blog, stop = brake_test(car, 100 / 3.6)
    print(f"brake 100-0 with ABS: {stop[7]:.1f} m in {stop[0]:.2f}s; peak decel {min(r[6] for r in blog):.2f} g")
    results["brake100To0"] = stop[7]
    for key, mph in (("brake60MphTo0", 60), ("brake70MphTo0", 70)):
        results[key] = brake_test(car, mph * MPH / 3.6)[1][7]
    # 3. idle with no input (automatics start in park)
    log = run("idle", 5, lambda t, v: 0.0, lambda t, v: 0.0, config=car)
    print(f"idle 5 s: speed {log[-1][1]:.3f} km/h, rpm {log[-1][2]:.0f} (min {min(r[2] for r in log):.0f}, max {max(r[2] for r in log):.0f}), clutch {log[-1][4]:.2f}"
          + ("  (in park)" if car.automatic else ""))
    if car.automatic:
        # into drive with the brake on, then let it off: the converter's creep
        log = run("creep", 20, lambda t, v: 0.0, lambda t, v: 1.0 if t < 5 else 0.0, config=car)
        held = [r for r in log if 1 <= r[0] < 5]
        print(f"  drive, brake held: rpm {min(r[2] for r in held):.0f}-{max(r[2] for r in held):.0f}, speed {max(r[1] for r in held):.2f} km/h")
        creep = [r for r in log if r[0] >= 5]
        r1 = first(creep, lambda r: r[0] >= 6)
        print(f"  idle creep after the brake comes off: {r1[1]:.1f} km/h after 1 s, {creep[-1][1]:.1f} km/h after 15 s"
              f" (gear {creep[-1][3]}, rpm {creep[-1][2]:.0f}); peak {max(r[6] for r in creep):.2f} g")
    # 4. part-throttle cruise, then lift: engine braking and auto downshifts
    log = run("cruise", 40, lambda t, v: 0.35 if t < 25 else 0.0, lambda t, v: 0.0, config=car)
    print(f"35% pedal for 25 s: {first(log, lambda r: r[0] >= 25)[1]:.0f} km/h in gear {first(log, lambda r: r[0] >= 25)[3]}; after 15 s coasting: {log[-1][1]:.0f} km/h gear {log[-1][3]} rpm {log[-1][2]:.0f}")
    # 5. extras
    if car.fi and car.fi["type"] == "Turbo":
        for rpm in (0.75 * car.fi["fullBoostRpm"], min(1.5 * car.fi["fullBoostRpm"], E["limiterRpm"] - 1500)):
            secs, r0, r1 = boost_response(car, rpm)
            print(f"boost response, floored at {r0:.0f} rpm in 3rd: 90% boost after {secs:.2f} s (at {r1:.0f} rpm)" if secs is not None
                  else f"boost response, floored at {r0:.0f} rpm: never reached 90%")
    log = run("free rev", 4, lambda t, v: 1.0, lambda t, v: 0.0, config=car, gear_fn=lambda t, v, r, g: 0)
    rows = [r for r in log if r[0] >= 2]
    cuts = sum(1 for a, b in zip(rows, rows[1:]) if b[10] and not a[10]) / (rows[-1][0] - rows[0][0])
    hit = first(log, lambda r: r[10])
    print(f"free rev in neutral: limiter after {hit[0]:.2f} s; rpm {min(r[2] for r in rows):.0f}-{max(r[2] for r in rows):.0f}, {cuts:.1f} cuts/s")
    if car.automatic:
        print("  shift times in the launch (s, rpm drop):",
              [(f"{a}-{b}", round(sum(1 for r in launches['from idle'][i:i + 60] if r[14]) / 60, 2), round(rp - launches['from idle'][i + sum(1 for r in launches['from idle'][i:i + 60] if r[14])][2]))
               for i, _, _, rp, a, b in shifts if b > a])
        lock = first(launches["from idle"], lambda r: r[15] is not None and r[15] >= 1)
        if lock: print(f"  lock-up fully closed at {lock[1]:.0f} km/h in gear {lock[3]} ({lock[0]:.2f} s)")
    if curve:
        print("full-load torque and power (steady boost):")
        for r in range(1000, E["limiterRpm"] + 1, 500):
            tq = car.full_load_torque(r)
            print(f"  {r:5d} rpm  {tq:5.0f} Nm  {tq * rad_of(r) / 1000:5.0f} kW")
    # validation table
    targets = car.targets
    print("validation (model; targets from performanceTargets):")
    rows = [
        ("0-60 mph", results["zeroTo60Mph"], targets.get("zeroTo60Mph"), "s"),
        ("0-60 mph, 1-ft rollout", results["rollout"], targets.get("zeroTo60MphRollout"), "s"),
        ("0-100 km/h", results["zeroTo100"], targets.get("zeroTo100"), "s"),
        ("0-100 mph", results["zeroTo100Mph"], targets.get("zeroTo100Mph"), "s"),
        ("0-200 km/h", results["zeroTo200"], targets.get("zeroTo200"), "s"),
        ("quarter mile", results["quarterMile"], targets.get("quarterMile"), "s"),
        ("quarter mile trap", results["quarterMileKmh"], targets.get("quarterMileKmh"), "km/h"),
        ("top speed", results["topSpeedKmh"], targets.get("topSpeedKmh"), "km/h"),
        ("100-0 km/h braking", results["brake100To0"], targets.get("brake100To0"), "m"),
        ("60-0 mph braking", results["brake60MphTo0"], targets.get("brake60MphTo0"), "m"),
        ("70-0 mph braking", results["brake70MphTo0"], targets.get("brake70MphTo0"), "m"),
    ]
    for name, model, target, unit in rows:
        print(table_row(name, model, target, unit, "%.1f" if unit in ("km/h", "m") else "%.2f"))
    return results


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if "--all" in argv:
        args = sorted(p.stem for p in CONFIG_DIR.glob("*.luau"))
    failed = False
    for i, config in enumerate(args or [DEFAULT_CONFIG]):
        if i: print()
        path = config_path(config)
        errors, warnings = check_config(luau_load(path))
        for w in warnings: print(f"warning: {path.stem}: {w}")
        if errors:
            failed = True
            print(f"{path.stem}: can't run, the configuration has problems:")
            for e in errors: print("  " + e)
            continue
        validate(load_car(config), curve="--curve" in argv)
    if failed: sys.exit(1)


if __name__ == "__main__":
    main(sys.argv[1:])
