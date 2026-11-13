#!/usr/bin/env python3
"""Check Redline Highway's road shapes outside Roblox.

A line-for-line Python copy of src/ReplicatedStorage/TrafficSystem/RoadGeometry.luau. It reads the
map data straight from the Luau modules in src/ReplicatedStorage/TrafficSystem/Maps, so the tests
always run on the maps the game builds. Keep the two in step.

Tests, for every map:
  1. the loop closes, and position, direction and height (and grade) are continuous across every
     piece boundary, every vertical curve and the start line;
  2. round trips: road coordinates -> world -> road, and world -> road -> world, on the road, at its
     edges and on and off the shoulders, including where the road passes over or under itself;
  3. curve radius against traffic speed: each driver profile's lateral acceleration in every lane
     stays within its comfort limit at the curve speeds traffic uses (and the speed limits brake in
     time);
  4. grades and vertical curves: no grade above 6 %, crests that keep a car on the ground at 400 km/h
     and dips that don't press it down by more than 0.6 g at 300 km/h;
  5. speed of the world -> road conversion (pieces tested per call, calls per second in Python).

Usage: python3 tools/road_geometry.py            (all tests)
       python3 tools/road_geometry.py --info     (lengths, curves, sections of each map)
"""
import math
import pathlib
import random
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from luau_table import load  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
MAPS_DIR = ROOT / "src" / "ReplicatedStorage" / "TrafficSystem" / "Maps"
MAP_IDS = ("Oval", "City")

TAU = 2 * math.pi
SPIRAL_STEP = 8  # m: transition curves are split into arcs no longer than this
BUCKET = 8  # m: lookup buckets for finding the piece at a distance s
CELL = 64  # m: grid cells for finding the pieces near a position
REACH = 40  # m beyond the road's edges that the grid covers
NEAR = 2  # m: heights within this of 1 m above the road cost nothing when choosing a piece


def wrap_angle(a):
    return (a + math.pi) % TAU - math.pi


def sign(x):
    return (x > 0) - (x < 0)


def cell_key(cx, cz):
    return (cx + 50000) * 100000 + (cz + 50000)


def point_on_piece(piece, t):
    """Position (x, z) and heading at distance t into a piece."""
    if piece["k"] == 0:
        return piece["x"] + t * piece["cos"], piece["z"] + t * piece["sin"], piece["heading"]
    heading = piece["heading"] + piece["k"] * t
    return piece["cx"] + math.sin(heading) / piece["k"], piece["cz"] - math.cos(heading) / piece["k"], heading


def project_on_piece(piece, x, z):
    """Where a plan position falls along a piece: distance t into it (not clamped) and offset."""
    if piece["k"] == 0:
        dx, dz = x - piece["x"], z - piece["z"]
        return dx * piece["cos"] + dz * piece["sin"], dz * piece["cos"] - dx * piece["sin"]
    dx, dz = x - piece["cx"], z - piece["cz"]
    distance = math.sqrt(dx * dx + dz * dz)
    angle = math.atan2(dx, -dz) if piece["k"] > 0 else math.atan2(-dx, dz)
    middle = piece["heading"] + piece["k"] * piece["length"] / 2
    return piece["length"] / 2 + wrap_angle(angle - middle) / piece["k"], 1 / piece["k"] - sign(piece["k"]) * distance


class Road:
    def __init__(self, data):
        self.id = data["id"]
        self.data = data
        self.lanes = data["lanes"]
        self.lane_width = data["laneWidth"]
        self.half_width = data["lanes"] * data["laneWidth"] / 2
        self.left_edge = self.half_width + data["shoulderLeft"]
        self.right_edge = self.half_width + data["shoulderRight"]
        self.base = data["origin"][1]

        # plan view: pieces of constant curvature (straights and arcs)
        pieces = []
        state = dict(x=data["origin"][0], z=data["origin"][2], heading=math.radians(data["heading"]), s=0.0)

        def add(length, k):
            piece = dict(s=state["s"], length=length, x=state["x"], z=state["z"], heading=state["heading"], k=k,
                         cos=math.cos(state["heading"]), sin=math.sin(state["heading"]), cx=0.0, cz=0.0)
            if k != 0:
                piece["cx"] = state["x"] - piece["sin"] / k
                piece["cz"] = state["z"] + piece["cos"] / k
                state["heading"] += k * length
                state["x"] = piece["cx"] + math.sin(state["heading"]) / k
                state["z"] = piece["cz"] - math.cos(state["heading"]) / k
            else:
                state["x"] += length * piece["cos"]
                state["z"] += length * piece["sin"]
            state["s"] += length
            pieces.append(piece)

        for element in data["plan"]:
            if element[0] == "straight":
                add(element[1], 0)
            else:
                radius, degrees = element[1], element[2]
                spiral = element[3] if len(element) > 3 else 0
                assert degrees != 0, f"{self.id}: a curve must turn"
                k = sign(degrees) / radius
                arc = math.radians(abs(degrees)) * radius - spiral
                assert arc >= -1e-6, f"{self.id}: transitions longer than the curve ({element})"
                n = math.ceil(spiral / SPIRAL_STEP)
                for i in range(1, n + 1):
                    add(spiral / n, k * (i - 0.5) / n)
                if arc > 1e-6:
                    add(arc, k)
                for i in range(n, 0, -1):
                    add(spiral / n, k * (i - 0.5) / n)
        self.pieces = pieces
        self.length = state["s"]
        self.closure = math.hypot(state["x"] - data["origin"][0], state["z"] - data["origin"][2])
        self.heading_error = wrap_angle(state["heading"] - math.radians(data["heading"]))
        self.turns = (state["heading"] - math.radians(data["heading"])) / TAU

        # lookup buckets: the piece where each BUCKET-metre stretch starts
        bucket_count = math.floor(self.length / BUCKET) + 1
        self.buckets = []
        index = 0
        for b in range(bucket_count):
            at = b * BUCKET
            while index < len(pieces) - 1 and pieces[index + 1]["s"] <= at:
                index += 1
            self.buckets.append(index)

        # elevation: pieces where height = y + grade * t + rate * t^2 / 2, t = s - start
        points = data["elevation"]
        assert points[0][0] == 0 and (points[0][2] if len(points[0]) > 2 else 0) == 0, \
            f"{self.id}: the profile must start at s = 0 with no vertical curve"
        count = len(points)

        def pvi(i):  # 0-based; the point after the last closes the loop at the first height
            if i >= count:
                return self.length, points[0][1], 0
            p = points[i]
            return p[0], p[1], (p[2] if len(p) > 2 else 0)

        grades = []
        for i in range(count):
            s0, y0, _ = pvi(i)
            s1, y1, _ = pvi(i + 1)
            assert s1 > s0, f"{self.id}: elevation points out of order at s = {s0}"
            grades.append((y1 - y0) / (s1 - s0))
        profile = [dict(s=0.0, y=points[0][1], grade=grades[0], rate=0.0)]
        for i in range(1, count):
            si, yi, curve = pvi(i)
            if curve > 0:
                profile.append(dict(s=si - curve / 2, y=yi - grades[i - 1] * curve / 2, grade=grades[i - 1],
                                    rate=(grades[i] - grades[i - 1]) / curve))
                profile.append(dict(s=si + curve / 2, y=yi + grades[i] * curve / 2, grade=grades[i], rate=0.0))
            else:
                profile.append(dict(s=si, y=yi, grade=grades[i], rate=0.0))
        for i in range(1, len(profile)):
            assert profile[i]["s"] >= profile[i - 1]["s"], f"{self.id}: vertical curves overlap near s = {profile[i]['s']:.0f}"
        assert profile[-1]["s"] <= self.length, f"{self.id}: the last vertical curve runs past the end of the loop"
        self.level_ends = abs(grades[-1] - grades[0]) < 1e-9
        self.profile = profile
        self.profile_buckets = []
        index = 0
        for b in range(bucket_count):
            at = b * BUCKET
            while index < len(profile) - 1 and profile[index + 1]["s"] <= at:
                index += 1
            self.profile_buckets.append(index)

        self.sections = sorted(data.get("sections", []), key=lambda sec: sec["from"])

        # grid of the pieces near each CELL x CELL square, for project()
        grid = {}
        reach = max(self.left_edge, self.right_edge) + REACH
        for i, piece in enumerate(pieces):
            steps = max(1, math.ceil(piece["length"] / 32))
            for j in range(steps):
                ax, az, _ = point_on_piece(piece, piece["length"] * j / steps)
                bx, bz, _ = point_on_piece(piece, piece["length"] * (j + 1) / steps)
                for cx in range(math.floor((min(ax, bx) - reach) / CELL), math.floor((max(ax, bx) + reach) / CELL) + 1):
                    for cz in range(math.floor((min(az, bz) - reach) / CELL), math.floor((max(az, bz) + reach) / CELL) + 1):
                        key = cell_key(cx, cz)
                        cell = grid.get(key)
                        if cell is None:
                            cell = []
                            grid[key] = cell
                        if not cell or cell[-1] != i:
                            cell.append(i)
        self.grid = grid
        self.all = list(range(len(pieces)))
        self.tested = 0  # pieces tested by project(), for the speed test

    # --- lookups ---
    def piece_index(self, s):
        i = self.buckets[math.floor(s / BUCKET)]
        while i < len(self.pieces) - 1 and self.pieces[i + 1]["s"] <= s:
            i += 1
        return i

    def plan_at(self, s):
        """(x, z, heading, curvature) of the centre line at distance s."""
        s %= self.length
        piece = self.pieces[self.piece_index(s)]
        x, z, heading = point_on_piece(piece, s - piece["s"])
        return x, z, heading, piece["k"]

    def height_at(self, s):
        """(height of the road surface, grade) at distance s."""
        s %= self.length
        profile = self.profile
        i = self.profile_buckets[math.floor(s / BUCKET)]
        while i < len(profile) - 1 and profile[i + 1]["s"] <= s:
            i += 1
        p = profile[i]
        t = s - p["s"]
        return self.base + p["y"] + (p["grade"] + p["rate"] * t / 2) * t, p["grade"] + p["rate"] * t

    def curvature_at(self, s):
        return self.plan_at(s)[3]

    def section_at(self, s, kind=None):
        s %= self.length
        for section in self.sections:
            if (kind is None or section["kind"] == kind) and section["from"] <= s < section["to"]:
                return section
        return None

    def frame(self, s, offset, height):
        """Position (x, y, z) at distance s, sideways offset and height above the road, and the unit
        direction of travel (which climbs with the grade)."""
        x, z, heading, _ = self.plan_at(s)
        y, grade = self.height_at(s)
        c, n = math.cos(heading), math.sin(heading)
        scale = 1 / math.sqrt(1 + grade * grade)
        return (x - n * offset, y + height, z + c * offset), (c * scale, grade * scale, n * scale)

    def centerline(self, s):
        return self.frame(s, 0, 0)

    def right_at(self, s):
        heading = self.plan_at(s)[2]
        return -math.sin(heading), 0.0, math.cos(heading)

    def lane_from_offset(self, offset):
        return offset / self.lane_width + (self.lanes + 1) / 2

    def offset_from_lane(self, lane_pos):
        return (lane_pos - (self.lanes + 1) / 2) * self.lane_width

    def point_at(self, s, lane_pos, height):
        return self.frame(s, self.offset_from_lane(lane_pos), height)

    def project(self, x, y, z, plan_only=False):
        """Road coordinates (s, offset, height above the road) of a world position. Where the road
        passes over itself, the level nearest the position wins."""
        candidates = self.grid.get(cell_key(math.floor(x / CELL), math.floor(z / CELL))) or self.all
        best_score, best_s, best_offset, best_height = math.inf, 0.0, 0.0, 0.0
        for i in candidates:
            piece = self.pieces[i]
            t, offset = project_on_piece(piece, x, z)
            along = -t if t < 0 else (t - piece["length"] if t > piece["length"] else 0.0)
            t = min(max(t, 0.0), piece["length"])
            s = piece["s"] + t
            edge = self.left_edge if offset < 0 else self.right_edge
            outside = max(0.0, abs(offset) - edge)
            score = outside * outside + along * along
            height = 0.0
            if not plan_only:
                height = y - self.height_at(s)[0]
                off = max(0.0, abs(height - 1) - NEAR)
                score += off * off
            if score < best_score:
                best_score, best_s, best_offset, best_height = score, s, offset, height
        self.tested += len(candidates)
        return best_s % self.length, best_offset, best_height

    def distance_to_road(self, x, z, skip_s=None, skip_range=0):
        """Plan distance (m) from a position to the road's paved surface (0 on it), counting only
        road within about 40 m (farther: inf), and ignoring road within skip_range of skip_s."""
        candidates = self.grid.get(cell_key(math.floor(x / CELL), math.floor(z / CELL)))
        if candidates is None:
            return math.inf
        best = math.inf
        for i in candidates:
            piece = self.pieces[i]
            t, offset = project_on_piece(piece, x, z)
            along = -t if t < 0 else (t - piece["length"] if t > piece["length"] else 0.0)
            s = piece["s"] + min(max(t, 0.0), piece["length"])
            if skip_s is None or abs(self.delta(skip_s, s)) > skip_range:
                edge = self.left_edge if offset < 0 else self.right_edge
                outside = max(0.0, abs(offset) - edge)
                best = min(best, math.sqrt(outside * outside + along * along))
        return best

    def delta(self, s_from, s_to):
        """Signed shortest distance along the loop from s_from to s_to."""
        return (s_to - s_from + self.length / 2) % self.length - self.length / 2

    def speed_limits(self, lateral, decel, step, top):
        """Highest speed (m/s) for each step-metre stretch of road: what keeps the innermost lane's
        lateral acceleration within `lateral` m/s^2, lowered ahead of curves so that braking at
        `decel` m/s^2 reaches the curve's speed in time."""
        n = math.ceil(self.length / step)
        inner = self.half_width - self.lane_width / 2  # the innermost lane centre, from the centre line
        limits = [top] * n
        for piece in self.pieces:
            k = abs(piece["k"])
            if k > 0:
                k_lane = k / (1 - k * inner)
                v = min(top, math.sqrt(lateral / k_lane))
                first = math.floor(piece["s"] / step)
                last = min(n - 1, math.floor((piece["s"] + piece["length"]) / step))
                for i in range(first, last + 1):
                    limits[i] = min(limits[i], v)
        for _ in range(2):  # twice round, so braking zones carry across the start line
            for i in range(n - 1, -1, -1):
                following = limits[(i + 1) % n]
                limits[i] = min(limits[i], math.sqrt(following * following + 2 * decel * step))
        return limits


# ---------------------------------------------------------------------------------------------
# Map data
# ---------------------------------------------------------------------------------------------

def load_map(map_id):
    return load(MAPS_DIR / f"{map_id}.luau")


def load_road(map_id):
    return Road(load_map(map_id))


# ---------------------------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------------------------

def check(results, name, ok, detail):
    print(("  PASS " if ok else "  FAIL ") + f"{name}: {detail}")
    results.append(ok)


def breakpoints(road):
    points = [p["s"] for p in road.pieces] + [p["s"] for p in road.profile]
    for p in road.profile:  # ends of vertical curves
        if p["rate"] != 0:
            pass
    return sorted(set(round(s, 9) for s in points))


def test_continuity(road, results):
    worst_pos = worst_dir = worst_h = worst_g = 0.0
    eps = 1e-7
    for s in breakpoints(road) + [0.0]:
        a = (s - eps) % road.length
        b = (s + eps) % road.length
        (pa, da), (pb, db) = road.centerline(a), road.centerline(b)
        worst_pos = max(worst_pos, math.dist(pa, pb) - 2 * eps)
        worst_dir = max(worst_dir, math.dist(da, db))
        ha, ga = road.height_at(a)
        hb, gb = road.height_at(b)
        worst_h = max(worst_h, abs(ha - hb))
        worst_g = max(worst_g, abs(ga - gb))
    check(results, "loop closes", road.closure < 1e-6 and abs(road.heading_error) < 1e-9,
          f"end is {road.closure * 1000:.6f} mm and {math.degrees(road.heading_error):.2e} deg from the start, "
          f"{road.turns:+.0f} turn(s)")
    check(results, "position, direction, height and grade are continuous",
          worst_pos < 1e-5 and worst_dir < 1e-6 and worst_h < 1e-6 and worst_g < 1e-6,
          f"largest jumps across {len(breakpoints(road))} boundaries: position {worst_pos:.1e} m, "
          f"direction {worst_dir:.1e}, height {worst_h:.1e} m, grade {worst_g:.1e}")
    check(results, "level at the start line", road.level_ends, "the last grade matches the first")


def test_round_trips(road, results, rng):
    worst_s = worst_o = worst_h = 0.0
    edge = min(road.left_edge, road.right_edge)
    for _ in range(4000):
        s = rng.uniform(0, road.length)
        offset = rng.uniform(-edge, edge) if rng.random() < 0.8 else rng.uniform(-road.left_edge - 10, road.right_edge + 10)
        height = rng.uniform(0, 3)
        (x, y, z), _ = road.frame(s, offset, height)
        s2, o2, h2 = road.project(x, y, z)
        worst_s = max(worst_s, abs(road.delta(s, s2)))
        worst_o = max(worst_o, abs(offset - o2))
        worst_h = max(worst_h, abs(height - h2))
    check(results, "road -> world -> road", worst_s < 1e-6 and worst_o < 1e-6 and worst_h < 1e-6,
          f"4,000 random points on and beside the road: worst errors s {worst_s:.1e} m, offset {worst_o:.1e} m, "
          f"height {worst_h:.1e} m")
    # world -> road -> world near the road
    worst = 0.0
    for _ in range(2000):
        s = rng.uniform(0, road.length)
        (x, y, z), _ = road.frame(s, rng.uniform(-edge, edge), rng.uniform(0.2, 2.5))
        x += rng.uniform(-1, 1)
        z += rng.uniform(-1, 1)
        s2, o2, h2 = road.project(x, y, z)
        (x2, y2, z2), _ = road.frame(s2, o2, h2)
        worst = max(worst, math.dist((x, y, z), (x2, y2, z2)))
    check(results, "world -> road -> world", worst < 1e-6, f"2,000 random positions: worst error {worst:.1e} m")


def test_crossings(road, results):
    """Where the road passes over itself, a car on either level must project onto its own level."""
    crossings = []
    step = 4.0
    n = int(road.length / step)
    pts = [road.centerline(i * step)[0] for i in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            if abs(road.delta(i * step, j * step)) < 200:
                continue
            if math.hypot(pts[i][0] - pts[j][0], pts[i][2] - pts[j][2]) < step:
                crossings.append((i * step, j * step, abs(pts[i][1] - pts[j][1])))
    if not crossings:
        check(results, "levels where the road crosses itself", True, "the road doesn't cross itself")
        return
    ok = True
    worst_clear = math.inf
    for sa, sb, clearance in crossings:
        worst_clear = min(worst_clear, clearance)
        for s in (sa, sb):
            for offset in (-3, 0, 3):
                (x, y, z), _ = road.frame(s, offset, 0.5)
                s2, _, h2 = road.project(x, y, z)
                if abs(road.delta(s, s2)) > 1e-6 or abs(h2 - 0.5) > 1e-6:
                    ok = False
    check(results, "levels where the road crosses itself", ok and worst_clear > 7,
          f"{len(crossings)} sample pairs, least vertical clearance {worst_clear:.1f} m")


def curve_list(road):
    """Circular parts of the curves: (s, radius, degrees)."""
    out = []
    for piece in road.pieces:
        if piece["k"] != 0 and piece["length"] > 2 * SPIRAL_STEP:
            out.append((piece["s"], 1 / piece["k"], math.degrees(piece["k"] * piece["length"])))
    return out


def test_curve_speeds(road, results, profiles, decel, step):
    """Each profile's speed limit keeps lateral acceleration within its comfort limit in every lane,
    and the limits fall no faster than the braking rate."""
    worst = 0.0
    worst_brake = 0.0
    for name, p in profiles.items():
        top = p["speed"][1] / 3.6
        limits = road.speed_limits(p["lateral"], decel, step, top)
        n = len(limits)
        for i in range(n):
            v = limits[i]
            for frac in (0.0, 0.5, 0.999):
                s = (i + frac) * step
                if s >= road.length:
                    continue
                k = road.curvature_at(s)
                for lane in range(1, road.lanes + 1):
                    offset = road.offset_from_lane(lane)
                    k_lane = abs(k / (1 - k * offset))
                    worst = max(worst, v * v * k_lane / p["lateral"])
            following = limits[(i + 1) % n]
            if following < v:
                worst_brake = max(worst_brake, (v * v - following * following) / (2 * step))
    check(results, "curve speeds keep lateral acceleration in comfort", worst <= 1 + 1e-9 and worst_brake <= decel + 1e-9,
          f"worst lane at the speed limit uses {worst * 100:.0f}% of the profile's limit; limits fall at up to "
          f"{worst_brake:.2f} m/s^2 (braking {decel})")
    tight = min((abs(r) for _, r, _ in curve_list(road)), default=math.inf)
    if tight < math.inf:
        speeds = ", ".join(f"{name} {math.sqrt(p['lateral'] * (tight - (road.half_width - road.lane_width / 2))) * 3.6:.0f}"
                           for name, p in profiles.items())
        print(f"  info: tightest curve R {tight:.0f} m; traffic takes it at (km/h) {speeds}")


def test_grades(road, results, max_grade=0.06):
    worst_grade = 0.0
    worst_crest = math.inf  # speed (km/h) at which a car leaves the ground on the sharpest crest
    worst_sag = 0.0  # extra g pressing down at 300 km/h in the sharpest dip
    for p in road.profile:
        worst_grade = max(worst_grade, abs(p["grade"]))
        if p["rate"] < 0:
            worst_crest = min(worst_crest, math.sqrt(9.81 / -p["rate"]) * 3.6)
        elif p["rate"] > 0:
            worst_sag = max(worst_sag, (300 / 3.6) ** 2 * p["rate"] / 9.81)
    for p, q in zip(road.profile, road.profile[1:] + [None]):
        end = q["s"] if q else road.length
        g_end = p["grade"] + p["rate"] * (end - p["s"])
        worst_grade = max(worst_grade, abs(g_end))
    check(results, f"grades at most {max_grade * 100:.0f}%", worst_grade <= max_grade + 1e-9,
          f"steepest {worst_grade * 100:.2f}%")
    check(results, "crests and dips", worst_crest >= 400 and worst_sag <= 0.6,
          f"sharpest crest lifts a car off at {worst_crest:.0f} km/h; sharpest dip adds {worst_sag:.2f} g at 300 km/h")


def test_speed(road, results, rng):
    pts = []
    for _ in range(3000):
        s = rng.uniform(0, road.length)
        (x, y, z), _ = road.frame(s, rng.uniform(-road.half_width, road.half_width), 0.5)
        pts.append((x, y, z))
    road.tested = 0
    start = time.perf_counter()
    for x, y, z in pts:
        road.project(x, y, z)
    elapsed = time.perf_counter() - start
    per_call = road.tested / len(pts)
    check(results, "world -> road is quick", per_call < 8,
          f"{per_call:.1f} pieces tested per call (of {len(road.pieces)}), {len(pts) / elapsed:,.0f} calls/s in Python")


def info(road):
    data = road.data
    print(f"{road.id} ({data['displayName']}): {road.length:,.1f} m, {road.lanes} lanes of {road.lane_width} m, "
          f"{len(road.pieces)} plan pieces, {len(road.profile)} elevation pieces")
    lo = min(road.height_at(i * 5)[0] for i in range(int(road.length / 5)))
    hi = max(road.height_at(i * 5)[0] for i in range(int(road.length / 5)))
    print(f"  height {lo - road.base:.1f} to {hi - road.base:.1f} m above the map's base")
    for s, r, deg in curve_list(road):
        print(f"  curve at s {s:7.0f}: R {abs(r):5.0f} m, {'right' if r > 0 else 'left '} {abs(deg):5.1f} deg (circular part)")
    for sec in road.sections:
        print(f"  {sec['kind']:8s} {sec['from']:7.0f} - {sec['to']:7.0f} m ({sec['to'] - sec['from']:5.0f} m) {sec.get('name', '')}")


def main(argv):
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
    import traffic_model  # the profiles and curve settings, shared with the traffic tests
    roads = [load_road(map_id) for map_id in MAP_IDS]
    if "--info" in argv:
        for road in roads:
            info(road)
        return 0
    results = []
    rng = random.Random(7)
    for road in roads:
        print(f"{road.id}: {road.length:,.1f} m, {road.lanes} lanes")
        test_continuity(road, results)
        test_round_trips(road, results, rng)
        test_crossings(road, results)
        test_curve_speeds(road, results, traffic_model.PROFILES, traffic_model.CURVE_DECEL, traffic_model.LIMIT_STEP)
        test_grades(road, results)
        test_speed(road, results, rng)
    ok = all(results)
    print("PASS: all road geometry tests" if ok else "FAIL: see above")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
