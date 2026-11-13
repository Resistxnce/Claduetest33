#!/usr/bin/env python3
"""Check Redline Highway's traffic model outside Roblox.

A line-for-line Python copy of src/ReplicatedStorage/TrafficSystem (IDM car following, MOBIL lane
changes, driver profiles and the multi-lane road simulation). Keep it in step with the Luau.

  Car following: the Intelligent Driver Model (Treiber, Hennecke and Helbing, 2000).
  Lane changes:  MOBIL (Kesting, Treiber and Helbing, 2007), with a keep-right bias and a safety
                 limit on how hard the new follower would have to brake.

Runs these tests on the 4-lane, 8,484 m proving-ground loop:
  1. light and 2. heavy traffic for 10 simulated minutes: collisions, speeds, flow, lane use, lane
     change rate;
  3. a stopped car (a crashed player) blocking a lane: traffic queues and merges around it;
  4. a player at 300 km/h coming up behind traffic: nobody pulls out in front of it;
  5. a slow player blocking the fast lane: traffic passes on the right.

Usage: python3 tools/traffic_model.py
"""
import bisect
import math
import random

LAP = 2 * 2200 + 2 * math.pi * 650  # proving-ground loop, metres
LANES = 4
MAX_DECEL = 9.0  # m/s^2, the hardest any car can brake

# ---------------------------------------------------------------------------------------------
# DriverProfiles.luau
# ---------------------------------------------------------------------------------------------
# speed: desired speed (km/h) range; gap: desired time gap (s); minGap: standstill gap (m);
# accel, decel: comfortable acceleration and braking (m/s^2); politeness: MOBIL p;
# threshold: MOBIL switching threshold (m/s^2); laneMin: rightmost-only vehicles can't use lanes
# left of this; share: how common the profile is.
PROFILES = {
    "cautious": dict(speed=(95, 110), gap=1.8, minGap=2.5, accel=1.0, decel=1.5, politeness=0.5,
                     threshold=0.3, length=4.6, width=1.8, laneMin=1, share=0.25),
    "normal": dict(speed=(110, 130), gap=1.4, minGap=2.0, accel=1.4, decel=2.0, politeness=0.3,
                   threshold=0.2, length=4.7, width=1.85, laneMin=1, share=0.45),
    "aggressive": dict(speed=(130, 155), gap=0.9, minGap=1.5, accel=2.0, decel=2.5, politeness=0.1,
                       threshold=0.1, length=4.6, width=1.85, laneMin=1, share=0.15),
    "truck": dict(speed=(80, 90), gap=1.8, minGap=3.0, accel=0.6, decel=1.5, politeness=0.5,
                  threshold=0.3, length=14.0, width=2.5, laneMin=3, share=0.15),
}
KEEP_RIGHT_BIAS = 0.25  # m/s^2 added to the incentive for moving right (US-style keep right)
SAFE_DECEL = 4.0  # m/s^2, the most a new follower may have to brake for a lane change
LANE_CHANGE_TIME = 3.0  # seconds to move across one lane
DECISION_INTERVAL = (1.0, 2.0)  # seconds between a driver's lane-change decisions
MIN_TIME_IN_LANE = 4.0  # seconds after a lane change before the next one
OBSTACLE_PARAMS = dict(gap=1.0, minGap=2.0, accel=3.0, decel=6.0)  # how traffic expects a player to brake


# ---------------------------------------------------------------------------------------------
# IDM.luau
# ---------------------------------------------------------------------------------------------
def idm(p, v, v0, gap, dv):
    """Acceleration (m/s^2). gap: bumper-to-bumper distance to the leader (m, None = free road);
    dv: closing speed v - v_leader."""
    free = 1 - (v / v0) ** 4 if v0 > 0 else -1
    if gap is None:
        return max(p["accel"] * free, -MAX_DECEL)
    s_star = p["minGap"] + max(0.0, v * p["gap"] + v * dv / (2 * math.sqrt(p["accel"] * p["decel"])))
    return max(p["accel"] * (free - (s_star / max(gap, 0.1)) ** 2), -MAX_DECEL)


# ---------------------------------------------------------------------------------------------
# TrafficSimulation.luau
# ---------------------------------------------------------------------------------------------
class Sim:
    def __init__(self, length, lanes, loop=True, seed=1):
        self.length, self.lanes, self.loop = length, lanes, loop
        self.vehicles = []
        self.obstacles = []  # players: dict(s, lane (float, 1 = left), v, length)
        self.rng = random.Random(seed)
        self.time = 0.0
        self.next_id = 1
        self.lane_changes = 0
        self.order = {}

    # --- setup ---
    def pick_profile(self):
        r, acc = self.rng.random(), 0.0
        for name, p in PROFILES.items():
            acc += p["share"]
            if r <= acc:
                return name
        return "normal"

    def add(self, s, lane, profile_name, v=None):
        p = PROFILES[profile_name]
        v0 = self.rng.uniform(*p["speed"]) / 3.6
        veh = dict(id=self.next_id, s=s % self.length, v=v0 * 0.85 if v is None else v, a=0.0, lane=lane,
                   lanePos=float(lane), fromLane=lane, change=0.0, profile=p, name=profile_name, v0=v0,
                   decision=self.rng.uniform(*DECISION_INTERVAL), sinceChange=MIN_TIME_IN_LANE)
        self.next_id += 1
        self.vehicles.append(veh)
        return veh

    def populate(self, per_km_per_lane):
        for lane in range(1, self.lanes + 1):
            count = int(per_km_per_lane * self.length / 1000)
            spacing = self.length / max(count, 1)
            for k in range(count):
                name = self.pick_profile()
                if PROFILES[name]["laneMin"] > lane:
                    name = "normal"
                self.add(k * spacing + self.rng.uniform(0, spacing * 0.4), lane, name)

    # --- neighbours ---
    def ahead(self, s_from, s_to):
        d = s_to - s_from
        if self.loop:
            d %= self.length
        return d

    def build_order(self):
        """Per lane, everything occupying it (vehicles and obstacles), sorted by position."""
        order = {lane: [] for lane in range(1, self.lanes + 1)}
        for veh in self.vehicles:
            for lane in self.occupied(veh["lane"], veh["lanePos"], veh["change"] > 0, veh["fromLane"]):
                order[lane].append(veh)
        for ob in self.obstacles:
            base = math.floor(ob["lane"] + 0.5)
            lanes = {base}
            frac = ob["lane"] - base
            if frac > 0.2:
                lanes.add(base + 1)
            elif frac < -0.2:
                lanes.add(base - 1)
            for lane in lanes:
                if 1 <= lane <= self.lanes:
                    order[lane].append(ob)
        self.keys = {}
        for lane in order:
            order[lane].sort(key=lambda x: x["s"])
            self.keys[lane] = [x["s"] for x in order[lane]]
        self.order = order

    def occupied(self, lane, lane_pos, changing, from_lane):
        return (lane, from_lane) if changing and from_lane != lane else (lane,)

    def neighbours(self, veh, lane):
        """(leader, gap, follower, gap) in a lane, ignoring veh itself. Gaps are bumper to bumper."""
        items = self.order.get(lane)
        if not items:
            return None, None, None, None
        n = len(items)
        k = bisect.bisect_right(self.keys[lane], veh["s"])
        lead = None
        for j in range(n):
            idx = k + j
            if idx >= n:
                if not self.loop:
                    break
                idx %= n
            if items[idx] is not veh:
                lead = items[idx]
                break
        follow = None
        for j in range(1, n + 1):
            idx = k - j
            if idx < 0:
                if not self.loop:
                    break
                idx %= n
            if items[idx] is not veh and items[idx] is not lead:
                follow = items[idx]
                break
        lead_gap = self.ahead(veh["s"], lead["s"]) - (veh_len(veh) + veh_len(lead)) / 2 if lead else None
        follow_gap = self.ahead(follow["s"], veh["s"]) - (veh_len(veh) + veh_len(follow)) / 2 if follow else None
        return lead, lead_gap, follow, follow_gap

    def accel(self, veh, leader, gap):
        p, v = params(veh), veh["v"]
        return idm(p, v, desired(veh), gap, v - leader["v"] if leader else 0.0)

    # --- MOBIL ---
    def wants_change(self, veh, target):
        p = veh["profile"]
        if target < max(1, p["laneMin"]) or target > self.lanes:
            return False
        lead_old, gap_old, follow_old, gap_follow_old = self.neighbours(veh, veh["lane"])
        lead_new, gap_new, follow_new, gap_follow_new = self.neighbours(veh, target)
        if gap_new is not None and gap_new < p["minGap"]:
            return False
        if gap_follow_new is not None and gap_follow_new < params(follow_new)["minGap"]:
            return False
        a_c = self.accel(veh, lead_old, gap_old)
        a_c_new = self.accel(veh, lead_new, gap_new)
        a_n = a_n_new = 0.0
        if follow_new is not None:
            gap_n = (gap_follow_new + gap_new + veh_len(veh)) if gap_new is not None else None
            a_n = self.accel(follow_new, lead_new, gap_n)
            a_n_new = self.accel(follow_new, veh, gap_follow_new)
            if a_n_new < -SAFE_DECEL:
                return False
        a_o = a_o_new = 0.0
        if follow_old is not None and "profile" in follow_old:
            gap_o = (gap_follow_old + gap_old + veh_len(veh)) if gap_old is not None else None
            a_o = self.accel(follow_old, veh, gap_follow_old)
            a_o_new = self.accel(follow_old, lead_old, gap_o)
        incentive = a_c_new - a_c + p["politeness"] * ((a_n_new - a_n) + (a_o_new - a_o))
        bias = KEEP_RIGHT_BIAS if target > veh["lane"] else -KEEP_RIGHT_BIAS
        return incentive + bias > p["threshold"]

    # --- step ---
    def step(self, dt):
        self.build_order()
        for veh in self.vehicles:
            lead, gap, _, _ = self.neighbours(veh, veh["lane"])
            a = self.accel(veh, lead, gap)
            if veh["change"] > 0 and veh["fromLane"] != veh["lane"]:
                lead2, gap2, _, _ = self.neighbours(veh, veh["fromLane"])
                a = min(a, self.accel(veh, lead2, gap2))
            veh["a"] = a
            veh["decision"] -= dt
            veh["sinceChange"] += dt
            if veh["decision"] <= 0 and veh["change"] <= 0 and veh["sinceChange"] >= MIN_TIME_IN_LANE:
                veh["decision"] = self.rng.uniform(*DECISION_INTERVAL)
                for target in (veh["lane"] - 1, veh["lane"] + 1):
                    if self.wants_change(veh, target):
                        veh["fromLane"], veh["lane"] = veh["lane"], target
                        veh["change"], veh["sinceChange"] = LANE_CHANGE_TIME, 0.0
                        self.lane_changes += 1
                        # occupy the new lane at once, so nobody else picks the same gap this step
                        k = bisect.bisect_right(self.keys[target], veh["s"])
                        self.keys[target].insert(k, veh["s"])
                        self.order[target].insert(k, veh)
                        break
        for veh in self.vehicles:
            v = max(0.0, veh["v"] + veh["a"] * dt)
            veh["s"] = (veh["s"] + (veh["v"] + v) / 2 * dt) % self.length if self.loop else veh["s"] + (veh["v"] + v) / 2 * dt
            veh["v"] = v
            if veh["change"] > 0:
                veh["change"] = max(0.0, veh["change"] - dt)
                t = 1 - veh["change"] / LANE_CHANGE_TIME
                smooth = t * t * (3 - 2 * t)
                veh["lanePos"] = veh["fromLane"] + (veh["lane"] - veh["fromLane"]) * smooth
                if veh["change"] == 0:
                    veh["fromLane"] = veh["lane"]
            else:
                veh["lanePos"] = float(veh["lane"])
        self.time += dt


def veh_len(x):
    return x["profile"]["length"] if "profile" in x else x.get("length", 4.7)


def params(x):
    return x["profile"] if "profile" in x else OBSTACLE_PARAMS


def desired(x):
    return x["v0"] if "v0" in x else max(x["v"], 1.0)


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def overlaps(sim):
    """Pairs of traffic cars closer than touching, in a shared lane (or partly shared while changing).
    Players are left out: in these tests they don't brake or steer, so hitting traffic is expected."""
    bad = []
    for lane, items in sim.order.items():
        items = [x for x in items if "profile" in x]
        for a, b in zip(items, items[1:] + (items[:1] if sim.loop else [])):
            if a is b:
                continue
            d = sim.ahead(a["s"], b["s"])
            if d < (veh_len(a) + veh_len(b)) / 2 - 0.05:
                bad.append((lane, a.get("id", "player"), b.get("id", "player"), round(d, 2)))
    return bad


def run(sim, seconds, dt=0.05, on_step=None):
    collisions, worst_decel = [], 0.0
    for _ in range(int(seconds / dt)):
        if on_step:
            on_step(sim)
        sim.step(dt)
        sim.build_order()
        collisions += overlaps(sim)
        if sim.time > 20:  # after the starting positions have settled
            worst_decel = min(worst_decel, min(v["a"] for v in sim.vehicles))
    return collisions, worst_decel


def summary(sim, label, collisions, worst, seconds):
    speeds = [v["v"] * 3.6 for v in sim.vehicles]
    by_lane = {lane: sum(1 for v in sim.vehicles if v["lane"] == lane) for lane in range(1, LANES + 1)}
    lane_speed = {lane: round(sum(v["v"] * 3.6 for v in sim.vehicles if v["lane"] == lane) / max(by_lane[lane], 1))
                  for lane in by_lane}
    density = len(sim.vehicles) / (sim.length / 1000) / LANES
    flow = density * (sum(speeds) / len(speeds))
    print(f"{label}: {len(sim.vehicles)} cars ({density:.0f}/km/lane), mean {sum(speeds) / len(speeds):.0f} km/h, "
          f"flow {flow:.0f} cars/h/lane")
    print(f"  cars per lane (1 = left) {by_lane}, mean km/h per lane {lane_speed}")
    print(f"  lane changes {sim.lane_changes} ({sim.lane_changes / len(sim.vehicles) / (seconds / 60):.2f} per car per minute), "
          f"hardest braking after the first 20 s {worst:.1f} m/s^2, overlaps {len(collisions)}")
    return collisions


def main():
    results = []
    for label, density, seed, seconds in (("light traffic", 6, 1, 600), ("heavy traffic", 22, 2, 300)):
        sim = Sim(LAP, LANES, seed=seed)
        sim.populate(density)
        collisions, worst = run(sim, seconds)
        results.append(summary(sim, label, collisions, worst, seconds))
        if collisions:
            print("  first overlaps (lane, car, car, centre distance m):", collisions[:4])

    # 3. a crashed car stopped in lane 2
    sim = Sim(LAP, LANES, seed=3)
    sim.populate(12)
    wreck = dict(s=1000.0, lane=2.0, v=0.0, length=4.7)
    sim.obstacles.append(wreck)
    for veh in list(sim.vehicles):  # clear the wreck's spot
        if veh["lane"] == 2 and sim.ahead(veh["s"], wreck["s"]) < 15 or sim.ahead(wreck["s"], veh["s"]) < 15 and veh["lane"] == 2:
            sim.vehicles.remove(veh)
    collisions, worst = run(sim, 300)
    near = [v for v in sim.vehicles if v["lane"] == 2 and sim.ahead(v["s"], wreck["s"]) < 300]
    queued = [v for v in near if v["v"] < 1]
    print(f"stopped car in lane 2: overlaps {len(collisions)}, hardest braking {worst:.1f} m/s^2, "
          f"cars stopped behind it {len(queued)}, lane changes {sim.lane_changes}")
    results.append(collisions)

    # 4. a player at 300 km/h coming up from behind in lane 1 (the fast lane)
    sim = Sim(LAP, LANES, seed=4)
    sim.populate(10)
    player = dict(s=0.0, lane=1.0, v=300 / 3.6, length=4.66)
    sim.obstacles.append(player)
    cut_ins = []

    def drive(s):
        player["s"] = (player["s"] + player["v"] * 0.05) % s.length
        s.build_order()
        lead, gap, _, _ = s.neighbours(player, 1)
        moving_in = lead is not None and lead.get("lane") == 1 and lead.get("fromLane") != 1
        if moving_in and gap is not None and gap < 150 and lead["change"] > LANE_CHANGE_TIME - 0.5:
            cut_ins.append((round(s.time, 1), lead["id"], round(gap, 1)))

    for veh in list(sim.vehicles):
        if veh["lane"] == 1:
            sim.vehicles.remove(veh)  # an empty fast lane, so any car in it pulled out
    collisions, worst = run(sim, 120, on_step=drive)
    print(f"player at 300 km/h in the fast lane: cars that pulled out within 150 m in front of it: {len(cut_ins)} "
          f"{cut_ins[:3]}; overlaps {len(collisions)}")
    results.append(collisions)

    # 5. a slow player holding the fast lane at 80 km/h
    sim = Sim(LAP, LANES, seed=5)
    sim.populate(8)
    slow = dict(s=500.0, lane=1.0, v=80 / 3.6, length=4.66)
    sim.obstacles.append(slow)
    for veh in list(sim.vehicles):
        if veh["lane"] == 1 and abs(sim.ahead(veh["s"], slow["s"])) < 20:
            sim.vehicles.remove(veh)

    def creep(s):
        slow["s"] = (slow["s"] + slow["v"] * 0.05) % s.length

    collisions, worst = run(sim, 300, on_step=creep)
    sim.build_order()
    stuck = [v for v in sim.vehicles if v["lane"] == 1 and sim.ahead(v["s"], slow["s"]) < 200 and v["v0"] > slow["v"] + 5]
    print(f"slow player in the fast lane: faster cars still stuck behind it {len(stuck)}, overlaps {len(collisions)}")
    results.append(collisions)

    ok = all(not c for c in results)
    print("PASS: no overlaps in any test" if ok else "FAIL: overlaps found")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
