#!/usr/bin/env python3
"""Check Redline Highway's close-pass scoring outside Roblox.

A line-for-line Python copy of src/ReplicatedStorage/Gameplay/ClosePass.luau, with tests. Keep the
two in step. Close-pass scoring is a fictional arcade mechanic layered on the realistic driving.

A pass counts when the player overtakes a traffic car at speed, faster than it by a margin, with a
small gap between the two cars' sides while they are alongside. Closer and faster passes score more.
Passes within a few seconds of each other build a combo multiplier; the combo is banked once the
chain ends, and lost if the player hits a car first.

The tests run on each map's real loop length (read from the game's map data by
tools/road_geometry.py), since the scorer measures who is ahead along the loop and must handle the
start line of each map.

Usage: python3 tools/close_pass_model.py
"""
import math
import pathlib
import sys

SETTINGS = dict(
    minSpeedKmh=120,  # the player must be at least this fast
    minRelativeKmh=30,  # and this much faster than the car being passed
    maxGap=2.0,  # m between the cars' sides for a pass to count
    closeGap=1.0,  # m, "close pass"
    insaneGap=0.5,  # m, "insane pass"
    basePoints=100,
    closenessPoints=400,  # added at the closest gaps
    speedRef=200,  # km/h where the speed factor is 1
    speedExponent=1.5,
    comboWindow=4.0,  # s to make the next pass and keep the combo going
    comboStep=0.5,  # added to the multiplier for each chained pass
    comboMax=5.0,
)


def clamp(x, a, b):
    return max(a, min(b, x))


class ClosePass:
    def __init__(self, settings, lap):
        self.settings = settings
        self.lap = lap
        self.tracks = {}  # cars alongside the player right now
        self.total = 0  # banked points
        self.combo = 0  # points in the current, unbanked combo
        self.multiplier = 1.0
        self.timer = 0.0  # time left to chain the next pass
        self.passes = 0
        self.events = []

    def wrap(self, d):
        return (d + self.lap / 2) % self.lap - self.lap / 2

    def update(self, dt, player, cars):
        """player and each car: s (m along the road), offset (m sideways), v (m/s along the road),
        length, width. cars: id -> car."""
        st = self.settings
        self.events.clear()
        if self.timer > 0:
            self.timer -= dt
            if self.timer <= 0:
                self.timer = 0.0
                if self.combo > 0:
                    self.total += self.combo
                    self.events.append(dict(kind="banked", points=self.combo, total=self.total))
                self.combo = 0
                self.multiplier = 1.0

        for car_id, car in cars.items():
            ds = self.wrap(car["s"] - player["s"])  # positive: the car is ahead
            alongside = abs(ds) < (player["length"] + car["length"]) / 2
            gap = abs(car["offset"] - player["offset"]) - (player["width"] + car["width"]) / 2
            track = self.tracks.get(car_id)
            if alongside:
                if track is None:
                    track = dict(minGap=gap, startedBehind=ds > 0, crashed=False)
                    self.tracks[car_id] = track
                else:
                    track["minGap"] = min(track["minGap"], gap)
                if gap < 0 and not track["crashed"]:
                    track["crashed"] = True
                    self.events.append(dict(kind="crash", lost=self.combo))
                    self.combo = 0
                    self.multiplier = 1.0
                    self.timer = 0.0
            elif track is not None:
                del self.tracks[car_id]
                if track["startedBehind"] and ds < 0 and not track["crashed"]:
                    self.score(player, car, track["minGap"])

        for car_id in list(self.tracks):
            if car_id not in cars:
                del self.tracks[car_id]

    def score(self, player, car, gap):
        st = self.settings
        speed = player["v"] * 3.6
        relative = (player["v"] - car["v"]) * 3.6
        if speed < st["minSpeedKmh"] or relative < st["minRelativeKmh"] or gap > st["maxGap"]:
            return
        closeness = clamp((st["maxGap"] - gap) / (st["maxGap"] - st["insaneGap"]), 0, 1)
        points = (st["basePoints"] + st["closenessPoints"] * closeness ** 1.5) \
            * (speed / st["speedRef"]) ** st["speedExponent"]
        if self.timer > 0:
            self.multiplier = min(st["comboMax"], self.multiplier + st["comboStep"])
        else:
            self.multiplier = 1.0
        gained = math.floor(points * self.multiplier + 0.5)
        self.combo += gained
        self.timer = st["comboWindow"]
        self.passes += 1
        label = "INSANE PASS" if gap <= st["insaneGap"] else ("CLOSE PASS" if gap <= st["closeGap"] else "NEAR MISS")
        self.events.append(dict(kind="pass", points=gained, label=label, gap=gap, multiplier=self.multiplier,
                                combo=self.combo))


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

LAP = 8484.0  # set to each map's loop length by main()
CAR = dict(length=4.7, width=1.85)
PLAYER = dict(length=4.657, width=1.971)


def drive(cp, seconds, player_v, cars, player_offset=0.0, start_s=0.0, dt=1 / 60):
    """Player drives straight at player_v (km/h); cars: id -> (s, offset, v km/h). Returns events."""
    events = []
    p = dict(PLAYER, s=start_s, offset=player_offset, v=player_v / 3.6)
    state = {cid: dict(CAR, s=s, offset=o, v=v / 3.6) for cid, (s, o, v) in cars.items()}
    t = 0.0
    while t < seconds:
        cp.update(dt, p, state)
        events += [dict(e, t=round(t, 2)) for e in cp.events]
        p["s"] = (p["s"] + p["v"] * dt) % LAP
        for c in state.values():
            c["s"] = (c["s"] + c["v"] * dt) % LAP
        t += dt
    return events


def side_offset(gap):
    """Sideways offset that leaves `gap` metres between the cars' sides."""
    return gap + (PLAYER["width"] + CAR["width"]) / 2


def check(name, ok, detail):
    print(("PASS " if ok else "FAIL ") + f"{name}: {detail}")
    return ok


def run_tests():
    results = []

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 3, 250, {1: (40, side_offset(0.4), 110)})
    passes = [e for e in ev if e["kind"] == "pass"]
    expected = math.floor((100 + 400) * (250 / 200) ** 1.5 + 0.5)
    results.append(check("insane pass at 250 km/h, 0.4 m", len(passes) == 1 and passes[0]["label"] == "INSANE PASS"
                         and passes[0]["points"] == expected, f"{passes} (expected {expected} points)"))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 3, 250, {1: (40, side_offset(3.0), 110)})
    results.append(check("3 m gap doesn't count", not any(e["kind"] == "pass" for e in ev), str(ev)))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 6, 100, {1: (20, side_offset(0.4), 60)})
    results.append(check("too slow (100 km/h) doesn't count", not any(e["kind"] == "pass" for e in ev), str(ev)))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 10, 250, {1: (40, side_offset(0.8), 110), 2: (120, -side_offset(0.8), 110),
                             3: (200, side_offset(1.5), 110)})
    passes = [e for e in ev if e["kind"] == "pass"]
    banked = [e for e in ev if e["kind"] == "banked"]
    mults = [p["multiplier"] for p in passes]
    results.append(check("three chained passes build a combo, then bank it",
                         mults == [1.0, 1.5, 2.0] and len(banked) == 1 and banked[0]["points"] == sum(p["points"] for p in passes),
                         f"multipliers {mults}, passes {[(p['label'], p['points']) for p in passes]}, banked {banked}"))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 6, 250, {1: (40, side_offset(0.8), 110), 2: (120, 1.0, 110)})
    crash = [e for e in ev if e["kind"] == "crash"]
    results.append(check("hitting a car loses the unbanked combo", len(crash) == 1 and crash[0]["lost"] > 0
                         and cp.total == 0 and cp.combo == 0, f"{crash}, total {cp.total}"))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 6, 130, {1: (-30, side_offset(0.5), 200)})
    results.append(check("being overtaken doesn't count", not any(e["kind"] == "pass" for e in ev), str(ev)))

    cp = ClosePass(SETTINGS, LAP)
    ev = drive(cp, 3, 250, {1: (20, side_offset(0.6), 110)}, start_s=LAP - 10)
    results.append(check("a pass across the lap's start line counts", sum(e["kind"] == "pass" for e in ev) == 1, str(ev)))

    return results


def main():
    global LAP
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import road_geometry
    results = []
    for map_id in road_geometry.MAP_IDS:
        LAP = road_geometry.load_road(map_id).length
        print(f"{map_id}: {LAP:,.0f} m loop")
        results += run_tests()
    ok = all(results)
    print("PASS: all close-pass tests" if ok else "FAIL: see above")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
