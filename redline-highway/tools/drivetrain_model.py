#!/usr/bin/env python3
"""Straight-line check of the GT12 prototype's drivetrain, outside Roblox.

A line-for-line Python copy of the game's engine, clutch, gearbox, limited-slip differential,
brakes, traction control and tyre code (VehicleSimulation and the modules it uses), driven at
60 frames per second. The car body is a point mass with static plus load-transfer axle loads, so
suspension, steering and Roblox's own physics are not modelled. Keep it in step with the Luau
when the drivetrain changes.

Runs four tests: full-throttle launch to top speed, 100-0 km/h braking with ABS, idling, and a
part-throttle cruise followed by coasting.

Usage: python3 tools/drivetrain_model.py
"""
import math
G, RHO = 9.81, 1.225
def sign(x): return 1 if x > 0 else (-1 if x < 0 else 0)
def clamp(x, a, b): return max(a, min(b, x))
def rpm_of(w): return w * 30 / math.pi
def rad_of(r): return r * math.pi / 30
ENG = dict(idleRpm=1000, limiterRpm=8900, hyst=150, inertia=0.20, resp=18, fs=20, fr=0.0085,
           curve=[(1000,330),(2000,450),(3000,540),(3500,574),(4500,620),(5500,665),(6500,705),(7000,718),(7500,712),(8000,690),(8500,661),(8900,625)])
TR = dict(gears=[2.98,2.436,1.992,1.629,1.331,1.089,0.89], rev=2.8, fd=4.0, eff=0.92, shiftTime=0.06, shiftFrac=0.35,
          clutchMax=1100, stiff=400, launch=(2200,4500), up=(6200,8750), down=(2600,5200), minInt=0.25)
DIFF = dict(type="LimitedSlip", preload=120, powerLock=0.35, coastLock=0.20, stiffness=180)
BRK = dict(front=3800, rear=2000, hb=2500, target=0.12)
TIRE = dict(muLong=1.45, muLat=1.22, psr=0.10, psa=7.5, cL=1.35, cY=1.45, ls=0.08, nom=4400, relax=0.25, rr=0.012)
def tyre_radius(w, a, rim): return (rim * 25.4 + 2 * w * a / 100) / 2000
RF, RR_ = tyre_radius(275,35,20), tyre_radius(315,35,20)
MASS, FRONT, COMH, WB, CDA, CLF, CLR = 1705, 0.47, 0.45, 2.72, 0.70, 0.18, 0.27

def curve_torque(r):
    c = ENG["curve"]
    if r <= c[0][0]: return c[0][1] * clamp(r / c[0][0], 0, 1)
    for (r0,t0),(r1,t1) in zip(c, c[1:]):
        if r <= r1: return t0 + (t1-t0)*(r-r0)/(r1-r0)
    return c[-1][1]
class Engine:
    def __init__(s): s.omega = rad_of(ENG["idleRpm"]); s.throttle = 0; s.cut = False
    def net(s, pedal, dt):
        r = rpm_of(s.omega)
        if r >= ENG["limiterRpm"]: s.cut = True
        elif r < ENG["limiterRpm"] - ENG["hyst"]: s.cut = False
        target = 0 if s.cut else pedal
        if r < ENG["idleRpm"]: target = max(target, clamp((ENG["idleRpm"] - r) / 300, 0, 0.35))
        s.throttle += (target - s.throttle) * clamp(ENG["resp"] * dt, 0, 1)
        drive = curve_torque(r) * s.throttle
        fric = ENG["fs"] + ENG["fr"] * r if s.omega > 0 else 0
        return drive - fric * (1 - s.throttle)
class Trans:
    def __init__(s): s.gear, s.auto, s.timer, s.since = 1, True, 0.0, 10.0
    def ratio(s):
        if s.gear == 0: return 0
        if s.gear < 0: return -TR["rev"] * TR["fd"]
        return TR["gears"][s.gear-1] * TR["fd"]
    def shift(s, g):
        g = clamp(g, -1, len(TR["gears"]))
        if g == s.gear or s.since < TR["minInt"]: return False
        s.gear, s.timer, s.since = g, TR["shiftTime"], 0.0; return True
    def update_auto(s, dt, inrpm, pedal):
        s.since += dt; s.timer = max(0, s.timer - dt)
        if not s.auto or s.gear <= 0: return
        up = TR["up"][0] + (TR["up"][1]-TR["up"][0])*pedal; down = TR["down"][0] + (TR["down"][1]-TR["down"][0])*pedal
        if inrpm > up and s.gear < len(TR["gears"]): s.shift(s.gear+1)
        elif inrpm < down and s.gear > 1:
            lower = inrpm * TR["gears"][s.gear-2] / TR["gears"][s.gear-1]
            if lower < TR["up"][1] - 400: s.shift(s.gear-1)
    def engagement(s, erpm, inrpm, pedal, idle):
        if s.gear == 0: return 0
        e = 1
        if abs(s.gear) == 1 and inrpm < erpm - 150:
            lt = TR["launch"][0] + (TR["launch"][1]-TR["launch"][0])*pedal
            e = clamp((erpm - (lt - 600)) / 600, 0, 1)
        if erpm < idle - 150: e = min(e, clamp((erpm - 600) / (idle - 750), 0, 1))
        if s.timer > 0: e = min(e, TR["shiftFrac"])
        return e
    def clutch(s, we, wi, Ie, Ii, Te, Tl, cap, dt):
        if cap <= 0: return 0
        k = TR["stiff"]; pred = (we - wi) + dt*(Te/Ie + Tl/Ii)
        return clamp(k*pred/(1 + k*dt*(1/Ie + 1/Ii)), -cap, cap)
def diff_split(tin, wl, wr, inertia, dt):
    lock = DIFF["powerLock"] if tin >= 0 else DIFF["coastLock"]
    maxT = DIFF["preload"] + lock*abs(tin); d = wl - wr; eq = abs(d)*inertia/dt
    t = clamp(clamp(DIFF["stiffness"]*d, -maxT, maxT), -eq, eq); return tin/2 - t/2, tin/2 + t/2
def brake_torque(front, pedal, hb, slip, absOn):
    t = (BRK["front"] if front else BRK["rear"]) * pedal; hbt = 0 if front else BRK["hb"]*hb
    if absOn and pedal > 0 and hbt == 0 and slip < -BRK["target"]:
        t *= clamp(1 - (-slip - BRK["target"])/BRK["target"], 0.15, 1)
    return max(t, hbt)
def shape(s, c): return math.sin(c * math.atan(math.tan(math.pi/(2*c)) * s))
class Wheel:
    def __init__(s, front, radius, inertia):
        s.front, s.r, s.I, s.omega, s.slip, s.alpha, s.driven, s.share = front, radius, inertia, 0.0, 0.0, 0.0, not front, (1 if not front else 0)
        s.load = 0; s.drive = 0; s.brake = 0
    def tyre(s, load, vlong, vlat, ws, grip, dt):
        if load <= 0: s.alpha = 0; return 0, 0, 0, 0
        sr = (ws - vlong) / max(abs(vlong), 3)
        ta = math.atan2(vlat, max(abs(vlong), 0.5)); s.alpha += (ta - s.alpha) * clamp(abs(vlong)*dt/TIRE["relax"], 0.05, 1)
        lf = clamp(1 - TIRE["ls"]*(load/TIRE["nom"] - 1), 0.7, 1.15)
        sx, sy = sr/TIRE["psr"], s.alpha/math.radians(TIRE["psa"]); m = math.hypot(sx, sy)
        if m < 1e-6: return 0, 0, sr, s.alpha
        return TIRE["muLong"]*lf*load*shape(m, TIRE["cL"])*(sx/m), -TIRE["muLat"]*lf*load*shape(m, TIRE["cY"])*(sy/m), sr, s.alpha

def run(test, seconds, pedal_fn, brake_fn, v0=0.0, start_gear=1, dt=1/60, sub=8):
    eng, tr = Engine(), Trans(); tr.gear = start_gear
    wheels = [Wheel(True, RF, 1.6), Wheel(True, RF, 1.6), Wheel(False, RR_, 2.0), Wheel(False, RR_, 2.0)]
    for w in wheels: w.omega = v0 / w.r
    if v0 > 0:
        eng.omega = rad_of(min(8000, rpm_of(v0 / RR_ * tr.ratio())))
    v, x, t, a_prev, log = v0, 0.0, 0.0, 0.0, []
    tc_cut = 0.0
    rear = wheels[2:]
    while t < seconds:
        pedal, brake = pedal_fn(t, v), brake_fn(t, v)
        q = 0.5 * RHO * v * v
        transfer = MASS * a_prev * COMH / WB
        fl = (MASS * G * FRONT - transfer + q * CLF) / 2; rl = (MASS * G * (1 - FRONT) + transfer + q * CLR) / 2
        for w in wheels: w.load = max(fl if w.front else rl, 0)
        ir = rpm_of(abs(tr.ratio() * sum(w.omega for w in rear) / 2)) if tr.ratio() else 0
        tr.update_auto(dt, ir, pedal)
        h = dt / sub; fxsum = [0.0]*4
        for _ in range(sub):
            ratio = tr.ratio(); win = ratio * sum(w.omega for w in rear)/2 if ratio else 0
            eng_rpm = rpm_of(eng.omega)
            e = tr.engagement(eng_rpm, rpm_of(abs(win)), pedal, ENG["idleRpm"]); cap = e * TR["clutchMax"]
            drive_slip = max([(w.omega * w.r - v) / max(abs(v), 6) * sign(ratio) for w in rear] + [0]) if ratio else 0
            excess = drive_slip - 0.11
            tc_cut = min(1, tc_cut + h * 15 * excess / 0.11) if excess > 0 else max(0, tc_cut - h * 2)
            Te = eng.net(pedal, h)
            if ratio:
                available = sum(TIRE['muLong'] * w.load * w.r for w in rear)
                limit = available / (abs(ratio) * TR['eff']) * 1.3 * (1 - tc_cut)
                Te = min(Te, limit)
                cap = min(cap, limit)
            for w in wheels:
                fx, fy, w.slip, w.alphaOut = w.tyre(w.load, v, 0.0, w.omega*w.r, 1.0, h); w.fx = fx
                w.brake = brake_torque(w.front, brake, 0, w.slip, True)
            Tc, locked = 0.0, False
            if ratio != 0 and cap > 0:
                Ii, Tl = 0.02, 0.0
                for w in rear:
                    Ii += w.I / ratio**2
                    rolling = w.load * TIRE["rr"] * w.r
                    Tl += (w.fx * w.r + (w.brake + rolling) * sign(w.omega)) / ratio
                Tc = tr.clutch(eng.omega, win, ENG["inertia"], Ii, Te, Tl, cap, h); locked = abs(Tc) < cap * 0.999
            wt = Tc * ratio * TR["eff"]
            rear[0].drive, rear[1].drive = diff_split(wt, rear[0].omega, rear[1].omega, rear[0].I, h)
            eng.omega = clamp(eng.omega + h*(Te - Tc)/ENG["inertia"], rad_of(ENG["idleRpm"]*0.55), rad_of(ENG["limiterRpm"]+400))
            for i, w in enumerate(wheels):
                I = w.I + (ENG["inertia"]*ratio*ratio*w.share/2 if (w.driven and locked) else 0)
                drive = w.drive if w.driven else 0
                tt = w.fx * w.r
                lim = I*abs(w.omega - v/w.r)/h + abs(drive) + w.brake; tt = clamp(tt, -lim, lim)
                rolling = w.load * TIRE["rr"] * w.r
                nw = w.omega + h*(drive - tt - rolling*sign(w.omega))/I
                bs = h*w.brake/I
                nw = 0.0 if abs(nw) <= bs else nw - sign(nw)*bs
                w.omega = nw; fxsum[i] += tt / w.r
        fx_total = sum(f / sub for f in fxsum)
        drag = q * CDA if v > 0.01 else 0
        a = (fx_total - drag) / MASS
        if v < 0.4 and brake > 0.1: a = -v / dt  # parking hold
        v = max(0.0, v + a*dt); x += v*dt; t += dt; a_prev = a
        if any(math.isnan(w.omega) for w in wheels) or math.isnan(v): return {"error": "NaN at t=%.2f" % t}
        log.append((t, v*3.6, rpm_of(eng.omega), tr.gear, e, [w.slip for w in rear], a/G, x))
    return log

def first(log, cond):
    for row in log:
        if cond(row): return row
    return None
# 1. full-throttle launch to top speed
log = run("launch", 70, lambda t, v: 1.0, lambda t, v: 0.0)
r100, r200 = first(log, lambda r: r[1] >= 100), first(log, lambda r: r[1] >= 200)
top = max(r[1] for r in log)
print(f"launch: 0-100 {r100[0]:.2f}s  0-200 {r200[0]:.2f}s  top {top:.1f} km/h  final gear {log[-1][3]}  final rpm {log[-1][2]:.0f}")
for tt in (0.1, 0.3, 0.6, 1.0, 2.0, 3.0):
    row = first(log, lambda r: r[0] >= tt)
    print(f"  t={row[0]:.2f}s  {row[1]:6.1f} km/h  {row[2]:5.0f} rpm  gear {row[3]}  clutch {row[4]:.2f}  rear slip {row[5][0]:+.3f}  {row[6]:.2f} g")
shifts = [(log[i][0], log[i][1], log[i-1][2], log[i][3]) for i in range(1, len(log)) if log[i][3] != log[i-1][3]]
print("  shifts (time, km/h, rpm before, new gear):", [(round(a,2), round(b), round(c), d) for a,b,c,d in shifts])
# steadiness: wheel slip jitter at a steady 200 km/h cruise is checked via frame-to-frame rpm change in 7th
late = [r[2] for r in log if r[0] > 60]
print(f"  rpm range in the last 10 s: {min(late):.0f}-{max(late):.0f}")
# 2. braking from 100 km/h with ABS
log = run("brake", 10, lambda t, v: 0.0, lambda t, v: 1.0, v0=100/3.6, start_gear=2)
stop = first(log, lambda r: r[1] < 0.5)
print(f"brake 100-0 with ABS: {stop[7]:.1f} m in {stop[0]:.2f}s; peak decel {min(r[6] for r in log):.2f} g")
# 3. idle with no input
log = run("idle", 5, lambda t, v: 0.0, lambda t, v: 0.0)
print(f"idle 5 s: speed {log[-1][1]:.3f} km/h, rpm {log[-1][2]:.0f} (min {min(r[2] for r in log):.0f}, max {max(r[2] for r in log):.0f}), clutch {log[-1][4]:.2f}")
# 4. part throttle cruise then lift: engine braking and auto downshifts
log = run("cruise", 40, lambda t, v: 0.35 if t < 25 else 0.0, lambda t, v: 0.0)
print(f"35% pedal for 25 s: {first(log, lambda r: r[0] >= 25)[1]:.0f} km/h in gear {first(log, lambda r: r[0] >= 25)[3]}; after 15 s coasting: {log[-1][1]:.0f} km/h gear {log[-1][3]} rpm {log[-1][2]:.0f}")
