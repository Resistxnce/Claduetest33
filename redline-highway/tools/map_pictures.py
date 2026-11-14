#!/usr/bin/env python3
"""Draw top-down pictures of Redline Highway's maps into docs/maps/ (PNG files, made with Pillow).

Each picture shows the road from above at its real width (with a minimum so it stays visible),
coloured by how it's built: on piers (elevated), in a tunnel or covered section, or at street
level / on an embankment. It also shows the direction of travel, distance markers every kilometre
along the road, the start line, named features, a scale bar, and under the plan an elevation
profile with the tunnels marked. Where the road passes over itself, the upper level is drawn on
top with a gap around it. The shapes come from the game's own map data (through
tools/road_geometry.py), so the pictures always match what the game builds.

Usage: python3 tools/map_pictures.py         -> docs/maps/oval.png and docs/maps/city.png
"""
import math
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from road_geometry import load_road  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "maps"
SS = 2  # drawn at twice the size, then scaled down for smooth edges
WIDTH = 1800  # final picture width, px
PIER_MIN = 6  # m: road this high stands on piers (as CityBuilder builds it)

# colours: a light chart surface, recessive context fills, and three road kinds in the validated
# categorical order (blue, orange, aqua); text in ink colours, never series colours
SURFACE = (252, 252, 251)
INK = (11, 11, 11)
INK_2 = (82, 81, 78)
MUTED = (150, 149, 144)
GRID = (226, 225, 220)
LAND = (240, 239, 236)
GRASS = (234, 240, 228)
WATER = (222, 233, 244)
VIADUCT = (176, 175, 170)
ELEVATED = (42, 120, 214)
TUNNEL = (235, 104, 52)
GRADE = (27, 175, 122)
KINDS = [("On piers (elevated)", ELEVATED), ("Tunnel or covered section", TUNNEL), ("Street level or embankment", GRADE)]

FONT_FILES = ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "DejaVuSans.ttf"]
BOLD_FILES = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "DejaVuSans-Bold.ttf"]


def font(size, bold=False):
    for name in (BOLD_FILES if bold else FONT_FILES):
        try:
            return ImageFont.truetype(name, size * SS)
        except OSError:
            continue
    return ImageFont.load_default(size=size * SS)


# Labels for each map: (text, s, side (-1 left of travel, 1 right), distance from the centre line in
# m). Each is anchored on its side of the road so it reads away from it.
LABELS = {
    "Oval": [
        ("Main straight 2.4 km, distance boards", 1300, 1, 60),
        ("Back straight 2.4 km", 6500, 1, 60),
        ("Covered gallery 300 m", 5750, -1, 60),
        ("Curve 1: R 650 m", 3542, 1, 70),
        ("Curve 2: R 650 m", 8184, 1, 70),
        ("Paddock (spawn)", 110, 1, 40),
    ],
    "City": [
        ("Seaside Straight 2.9 km", 1700, -1, 70),
        ("Kirameki JCT  R 380", 3300, 1, 170),
        ("Ward S-bends  R 260 / 240", 4150, 1, 90),
        ("Kagerou Tunnel 2.5 km", 6500, 1, 60),
        ("Tsukimi JCT: 270-degree loop, R 210", 9840, 1, 45),
        ("Hotaru Tunnel 0.6 km", 11250, -1, 60),
        ("Umikaze JCT  R 420", 11800, -1, 60),
    ],
}
# where the legend's top-left corner goes, as fractions of the plan; and where the scale bar starts
LEGEND_AT = {"Oval": (0.81, 0.01), "City": (0.33, 0.33)}
SCALE_AT = {"Oval": 0.0, "City": 0.36}
CROP_BELOW_SHORE = 1150  # m of bay shown below the shore (the viaducts run on across it)


class Canvas:
    def __init__(self, min_x, max_x, min_z, max_z, profile_height):
        self.scale = (WIDTH - 2 * 40) / (max_x - min_x) * SS  # px per metre, at drawing size
        self.min_x, self.min_z = min_x, min_z
        self.pad = 40 * SS
        self.top = 96 * SS  # title band
        self.plan_h = int((max_z - min_z) * self.scale)
        self.w = WIDTH * SS
        self.h = self.top + self.plan_h + profile_height * SS + 30 * SS
        self.image = Image.new("RGB", (self.w, self.h), SURFACE)
        self.draw = ImageDraw.Draw(self.image)

    def p(self, x, z):
        return (self.pad + (x - self.min_x) * self.scale, self.top + (z - self.min_z) * self.scale)

    def rect(self, x0, z0, x1, z1, fill):
        a, b = self.p(x0, z0), self.p(x1, z1)
        top = max(min(a[1], b[1]), self.top)
        bottom = min(max(a[1], b[1]), self.top + self.plan_h)
        if bottom > top:
            self.draw.rectangle([min(a[0], b[0]), top, max(a[0], b[0]), bottom], fill=fill)

    def text(self, xy, text, size=13, fill=INK, bold=False, anchor="la"):
        self.draw.text(xy, text, font=font(size, bold), fill=fill, anchor=anchor)


def classify(road, s):
    if road.section_at(s, "tunnel"):
        return TUNNEL
    if road.height_at(s)[0] - road.base >= PIER_MIN:
        return ELEVATED
    return GRADE


def bounds(road, extra_points):
    xs, zs = [], []
    for i in range(0, int(road.length), 10):
        x, z, _, _ = road.plan_at(i)
        xs.append(x)
        zs.append(z)
    for x, z in extra_points:
        xs.append(x)
        zs.append(z)
    return min(xs), max(xs), min(zs), max(zs)


def clip(a, b, x0, x1, z0, z1):
    """The part of segment a-b inside a rectangle (Liang-Barsky), or None."""
    t0, t1 = 0.0, 1.0
    dx, dz = b[0] - a[0], b[1] - a[1]
    for p, q in ((-dx, a[0] - x0), (dx, x1 - a[0]), (-dz, a[1] - z0), (dz, z1 - a[1])):
        if p == 0:
            if q < 0:
                return None
            continue
        r = q / p
        if p < 0:
            t0 = max(t0, r)
        else:
            t1 = min(t1, r)
    if t0 > t1:
        return None
    return (a[0] + dx * t0, a[1] + dz * t0), (a[0] + dx * t1, a[1] + dz * t1)


def flyover_lines(road):
    """Plan lines of the city's decorative viaducts: (start, end, data)."""
    decor = road.data.get("decor")
    if not decor:
        return []
    out = []
    for f in decor["flyovers"]:
        x, z, heading, _ = road.plan_at(f["s"])
        a = heading + math.radians(f["angle"])
        d = (math.cos(a), math.sin(a))
        start = (x - d[0] * f["back"], z - d[1] * f["back"])
        end = (x + d[0] * f["ahead"], z + d[1] * f["ahead"])
        out.append((start, end, f))
    return out


def crossings(road, step=4.0):
    """Places where the road passes over itself: (s of the lower level, s of the upper level)."""
    n = int(road.length / step)
    cells = {}
    pts = []
    for i in range(n):
        x, z, _, _ = road.plan_at(i * step)
        pts.append((x, z))
        cells.setdefault((int(x // 20), int(z // 20)), []).append(i)
    found = []
    for i, (x, z) in enumerate(pts):
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for j in cells.get((int(x // 20) + dx, int(z // 20) + dz), []):
                    if j > i and abs(road.delta(i * step, j * step)) > 200 and math.hypot(pts[j][0] - x, pts[j][1] - z) < step:
                        a, b = i * step, j * step
                        if road.height_at(a)[0] > road.height_at(b)[0]:
                            a, b = b, a
                        if not any(abs(road.delta(a, fa)) < 50 for fa, _ in found):
                            found.append((a, b))
    return found


def polyline(c, road, s0, s1, step=2.0):
    n = max(1, math.ceil((s1 - s0) / step))
    return [c.p(*road.plan_at(s0 + (s1 - s0) * k / n - (1e-9 if k == n else 0))[:2]) for k in range(n + 1)]


def draw_road(c, road, width_px, width_m):
    # runs of road built the same way, drawn as smooth polylines, lowest first
    step = 2.0
    n = int(math.ceil(road.length / step))
    runs = []
    start, colour = 0.0, classify(road, step / 2)
    for i in range(1, n + 1):
        s = min(i * step, road.length)
        kind = classify(road, s + step / 2) if i < n else None
        if kind != colour:
            runs.append((start, s, colour))
            start, colour = s, kind
    runs.sort(key=lambda run: road.height_at((run[0] + run[1]) / 2)[0])
    for s0, s1, colour in runs:
        c.draw.line(polyline(c, road, s0, s1, 8.0), fill=colour, width=width_px, joint="curve")
    # tunnels get a dashed centre line too, so they don't rely on colour alone
    for s0, s1, colour in runs:
        if colour == TUNNEL:
            s = s0
            while s < s1:
                c.draw.line(polyline(c, road, s, min(s + 30, s1)), fill=SURFACE, width=max(2, width_px // 4))
                s += 60
    # where the road passes over itself, redraw the upper level with a gap around it
    gap = 3 * SS
    for lower, upper in crossings(road):
        reach = width_m * 3
        pts = polyline(c, road, upper - reach, upper + reach, 1.0)
        c.draw.line(pts, fill=SURFACE, width=width_px + 2 * gap, joint="curve")
        c.draw.line(pts, fill=classify(road, upper), width=width_px, joint="curve")
        # note it beside the lower road, on its right, past the crossing
        x, z, heading, _ = road.plan_at(lower)
        clearance = road.height_at(upper)[0] - road.height_at(lower)[0]
        fx, fz = math.cos(heading), math.sin(heading)
        rx, rz = -fz, fx
        c.text(c.p(x + rx * 45 + fx * 25, z + rz * 45 + fz * 25), f"loop passes {clearance:.0f} m over the approach",
               size=11, fill=INK_2, anchor="lt")


def draw_arrows(c, road, every, size):
    s = every / 2
    while s < road.length:
        x, z, heading, _ = road.plan_at(s)
        tip = c.p(x + math.cos(heading) * size, z + math.sin(heading) * size)
        left = c.p(x - math.cos(heading - 0.5) * size, z - math.sin(heading - 0.5) * size)
        right = c.p(x - math.cos(heading + 0.5) * size, z - math.sin(heading + 0.5) * size)
        c.draw.polygon([tip, left, c.p(x, z), right], fill=INK)
        s += every


def draw_km_markers(c, road, width_m):
    for k in range(1, int(road.length / 1000) + 1):
        s = k * 1000.0
        x, z, heading, _ = road.plan_at(s)
        rx, rz = -math.sin(heading), math.cos(heading)
        # on the left of the direction of travel
        a = c.p(x - rx * width_m * 0.6, z - rz * width_m * 0.6)
        b = c.p(x - rx * (width_m * 0.6 + 40), z - rz * (width_m * 0.6 + 40))
        c.draw.line([a, b], fill=INK_2, width=2 * SS)
        t = c.p(x - rx * (width_m * 0.6 + 75), z - rz * (width_m * 0.6 + 75))
        c.text(t, f"{k} km", size=11, fill=INK_2, anchor="mm")


def draw_start(c, road, width_m):
    s = road.data["start"]
    x, z, heading, _ = road.plan_at(s)
    rx, rz = -math.sin(heading), math.cos(heading)
    half = width_m * 1.2
    c.draw.line([c.p(x - rx * half, z - rz * half), c.p(x + rx * half, z + rz * half)], fill=INK, width=4 * SS)
    t = c.p(x - rx * (half + 55), z - rz * (half + 55))
    c.text(t, "START", size=12, bold=True, anchor="mm")


def away_anchor(dx, dz):
    """A text anchor that puts text on the far side of a point in direction (dx, dz)."""
    if abs(dx) > abs(dz):
        return "lm" if dx > 0 else "rm"
    return "mt" if dz > 0 else "mb"


def draw_labels(c, road):
    for text, s, side, distance in LABELS.get(road.id, []):
        x, z, heading, _ = road.plan_at(s)
        rx, rz = -math.sin(heading) * side, math.cos(heading) * side
        c.text(c.p(x + rx * distance, z + rz * distance), text, size=13, fill=INK, anchor=away_anchor(rx, rz))


def draw_scale_bar(c, metres=1000, at=0.0):
    x0 = c.pad + at * (c.w - 2 * c.pad)
    y0 = c.top + c.plan_h - 30 * SS
    length = metres * c.scale
    for i in range(4):
        fill = INK if i % 2 == 0 else SURFACE
        c.draw.rectangle([x0 + length * i / 4, y0, x0 + length * (i + 1) / 4, y0 + 6 * SS], fill=fill, outline=INK, width=SS)
    for i, label in ((0, "0"), (2, f"{metres // 2} m"), (4, f"{metres} m")):
        c.text((x0 + length * i / 4, y0 - 4 * SS), label, size=11, fill=INK_2, anchor="mb")


def draw_legend(c, items, where):
    x = c.pad + where[0] * (c.w - 2 * c.pad) + 12 * SS
    y = c.top + where[1] * c.plan_h + 14 * SS
    c.draw.rectangle([x - 12 * SS, y - 10 * SS, x + 300 * SS, y + (len(items) * 22 + 6) * SS], fill=SURFACE, outline=GRID, width=SS)
    for label, kind, colour in items:
        cy = y + 9 * SS
        if kind == "line":
            c.draw.line([(x, cy), (x + 34 * SS, cy)], fill=colour, width=8 * SS)
            if colour == TUNNEL:
                c.draw.line([(x + 6 * SS, cy), (x + 16 * SS, cy)], fill=SURFACE, width=2 * SS)
        elif kind == "thin":
            c.draw.line([(x, cy), (x + 34 * SS, cy)], fill=colour, width=4 * SS)
        elif kind == "start":
            c.draw.line([(x + 17 * SS, cy - 8 * SS), (x + 17 * SS, cy + 8 * SS)], fill=INK, width=4 * SS)
        elif kind == "arrow":
            c.draw.polygon([(x + 30 * SS, cy), (x + 14 * SS, cy - 7 * SS), (x + 19 * SS, cy), (x + 14 * SS, cy + 7 * SS)], fill=INK)
        c.text((x + 46 * SS, cy), label, size=12, fill=INK, anchor="lm")
        y += 22 * SS


def draw_profile(c, road, top, height):
    """Height of the road surface along the loop, tunnels shaded."""
    left, right = c.pad + 44 * SS, c.w - c.pad
    bottom = top + height * SS - 26 * SS
    plot_top = top + 22 * SS
    hs = [road.height_at(i * 5.0)[0] - road.base for i in range(int(road.length / 5) + 1)]
    h_max = max(10.0, math.ceil(max(hs) / 5) * 5)

    def px(s):
        return left + (right - left) * s / road.length

    def py(h):
        return bottom - (bottom - plot_top) * h / h_max

    c.text((c.pad, top), "Elevation of the road surface above the street (m), along the loop", size=13, bold=True)
    for sec in road.sections:
        c.draw.rectangle([px(sec["from"]), plot_top, px(sec["to"]), bottom], fill=(251, 225, 214))
        c.text(((px(sec["from"]) + px(sec["to"])) / 2, plot_top + 4 * SS), sec.get("name", "tunnel"), size=11, fill=INK_2, anchor="ma")
    for h in range(0, int(h_max) + 1, 5):
        c.draw.line([(left, py(h)), (right, py(h))], fill=GRID, width=SS)
        c.text((left - 6 * SS, py(h)), f"{h}", size=11, fill=INK_2, anchor="rm")
    if max(hs) > PIER_MIN:
        for xx in range(int(left), int(right), 14 * SS):
            c.draw.line([(xx, py(PIER_MIN)), (xx + 6 * SS, py(PIER_MIN))], fill=MUTED, width=SS)
        c.text((right, py(PIER_MIN) - 3 * SS), f"piers above {PIER_MIN} m", size=10, fill=INK_2, anchor="rb")
    for k in range(0, int(road.length / 1000) + 1):
        c.draw.line([(px(k * 1000), bottom), (px(k * 1000), bottom + 4 * SS)], fill=INK_2, width=SS)
        c.text((px(k * 1000), bottom + 6 * SS), f"{k} km", size=11, fill=INK_2, anchor="ma")
    pts = [(px(i * 5.0), py(h)) for i, h in enumerate(hs)]
    c.draw.line(pts, fill=INK, width=2 * SS, joint="curve")


def render(map_id):
    road = load_road(map_id)
    data = road.data
    width_m = road.left_edge + road.right_edge
    lines = flyover_lines(road)
    extra = [pt for start, end, _ in lines for pt in (start, end)]
    min_x, max_x, min_z, max_z = bounds(road, extra)
    margin = 260
    min_x, max_x, min_z, max_z = min_x - margin, max_x + margin, min_z - margin - 120, max_z + margin
    decor = data.get("decor")
    if decor:
        max_z = min(max_z, decor["shore"] + CROP_BELOW_SHORE)
    profile_height = 190
    c = Canvas(min_x, max_x, min_z, max_z, profile_height)

    # context: land, water
    if decor:
        c.rect(min_x, min_z, max_x, decor["shore"], LAND)
        c.rect(min_x, decor["shore"], max_x, decor["farShore"], WATER)
        c.rect(min_x, decor["farShore"], max_x, max_z, LAND)
        sx, sy = c.p(max_x - 40, decor["shore"] + 500)
        c.text((sx, sy), "THE BAY", size=16, fill=MUTED, bold=True, anchor="rm")
    else:
        c.rect(min_x, min_z, max_x, max_z, GRASS)

    # decorative viaducts under the road, cut off at the picture's edge
    for start, end, f in lines:
        clipped = clip(start, end, min_x, max_x, min_z, max_z)
        if clipped:
            a, b = clipped
            c.draw.line([c.p(*a), c.p(*b)], fill=VIADUCT, width=max(3 * SS, int(12 * c.scale)))
            # name it out over the bay, where it's clear of the road
            seaward = a if a[1] > b[1] else b
            mx, my = c.p(seaward[0], seaward[1] - 250)
            total = (f["back"] + f["ahead"]) / 1000
            c.text((mx + 12 * SS, my), f"{f.get('name', 'viaduct')} ({total:.1f} km, to the far shore)", size=12,
                   fill=INK_2, anchor="lm")

    width_px = max(int(width_m * c.scale), 6 * SS)
    draw_road(c, road, width_px, width_m)
    draw_arrows(c, road, every=1500, size=max(30.0, 14 * SS / c.scale))
    draw_km_markers(c, road, width_m)
    draw_start(c, road, width_m)
    draw_labels(c, road)
    draw_scale_bar(c, 1000 if road.length > 5000 else 500, SCALE_AT.get(map_id, 0.0))

    # title and legend
    tunnels = [s for s in road.sections if s["kind"] == "tunnel"]
    tunnel_text = ", ".join(f"{s.get('name', 'tunnel')} {(s['to'] - s['from']) / 1000:.1f} km" for s in tunnels)
    c.text((c.pad, 20 * SS), f"{data['displayName']}  ({map_id} map)", size=22, bold=True)
    c.text((c.pad, 54 * SS),
           f"{road.length / 1000:.2f} km one-way loop, {road.lanes} lanes of {road.lane_width} m;  {tunnel_text};  "
           f"lighting: {data['lighting'].lower()}.  World axes: +X to the right, +Z down.", size=13, fill=INK_2)
    present = {classify(road, s) for s in range(0, int(road.length), 5)}
    items = [(label, "line", colour) for label, colour in KINDS if colour in present]
    if lines:
        items.append(("Decorative viaduct (scenery)", "thin", VIADUCT))
    items += [("Start line", "start", INK), ("Direction of travel", "arrow", INK)]
    draw_legend(c, items, LEGEND_AT.get(map_id, (0.8, 0.01)))

    draw_profile(c, road, c.top + c.plan_h + 16 * SS, profile_height)
    final = c.image.resize((c.w // SS, c.h // SS), Image.LANCZOS)
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"{map_id.lower()}.png"
    final.save(path, optimize=True)
    return path, final.size


def main():
    for map_id in ("Oval", "City"):
        path, size = render(map_id)
        print(f"{path.relative_to(ROOT)}: {size[0]} x {size[1]} px")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
