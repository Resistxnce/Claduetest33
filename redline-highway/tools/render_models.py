#!/usr/bin/env python3
"""Render a picture of the game's car models, outside Roblox.

Builds each car's stand-in model with the same parts, sizes and positions as
src/ServerScriptService/Server/VehicleModelBuilder.luau (from the car's configuration), plus the
traffic stand-ins drawn by TrafficRenderer, and draws them with a small software renderer
(z-buffered triangles, flat shading, a soft ground shadow). Labels come from the configs.

Usage: python3 tools/render_models.py [output.png]     (needs numpy and Pillow)
Default output: docs/models/lineup.png
"""
import math
import pathlib
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from luau_table import load  # noqa: E402

CONFIGS = ROOT / "src" / "ReplicatedStorage" / "VehicleSystem" / "VehicleConfigurations"
PROFILES = ROOT / "src" / "ReplicatedStorage" / "TrafficSystem" / "DriverProfiles.luau"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

TILE_W, TILE_H = 760, 430


def rgb(c):
    if isinstance(c, dict) and c.get("call") == "Color3.fromRGB":
        return tuple(int(v) for v in c["args"])
    return (150, 150, 150)


def tyre_radius(width_mm, aspect, rim_in):
    return (rim_in * 25.4 + 2 * width_mm * aspect / 100) / 2000


# --------------------------------------------------------------------------------------------
# Models, as primitives in metres. Frame: X right, Y up, Z backward (forward is -Z), ground y = 0.
# --------------------------------------------------------------------------------------------

DEFAULT_BLOCKOUT = dict(
    profile=[[0, 0.5], [0.03, 0.66], [0.42, 0.86], [0.56, 1.25], [0.63, 1.276], [0.8, 1.02], [0.95, 0.93], [1, 0.9]],
    greenhouse=[0.42, 0.8], beltline=0.86, cabinWidth=0.72, sill=0.14)
SLICES = 24


def profile_height(profile, share):
    if share <= profile[0][0]:
        return profile[0][1]
    for a, b in zip(profile, profile[1:]):
        if share <= b[0]:
            t = (share - a[0]) / (b[0] - a[0]) if b[0] > a[0] else 0
            return a[1] + (b[1] - a[1]) * t
    return profile[-1][1]


def car_model(cfg):
    """Mirror of VehicleModelBuilder.build: (kind, size or (length, radius), centre, colour)."""
    mass, dims = cfg["mass"], cfg["dimensions"]
    front_z = -dims["wheelbase"] * (1 - mass["frontShare"])
    rear_z = dims["wheelbase"] * mass["frontShare"]
    ground = -mass["comHeight"]
    nose = front_z - dims["frontOverhang"]
    tail = nose + dims["length"]
    mid_z = (nose + tail) / 2
    shape = cfg.get("visual", {}).get("blockout") or DEFAULT_BLOCKOUT
    profile = shape["profile"]
    glass_from, glass_to = shape["greenhouse"]
    belt, sill = shape["beltline"], shape.get("sill", 0.14)
    paint = rgb(cfg.get("visual", {}).get("bodyColor"))
    carbon, dark, glass, chrome = (28, 28, 30), (18, 18, 20), (40, 52, 64), (200, 202, 206)
    w, L = dims["width"], dims["length"]

    def z_at(share):
        return nose + L * share

    parts = [("box", (w - 0.03, belt - sill, L - 0.1), (0, ground + (sill + belt) / 2, mid_z), paint)]
    sl = L / SLICES
    for i in range(SLICES):
        share = (i + 0.5) / SLICES
        top = profile_height(profile, share)
        z = z_at(share)
        if glass_from < share < glass_to:
            if top - 0.07 > belt:
                parts.append(("box", (w * shape["cabinWidth"], top - 0.07 - belt, sl + 0.01),
                              (0, ground + (belt + top - 0.07) / 2, z), glass))
        elif top > belt:
            parts.append(("box", (w - 0.12, top - belt, sl + 0.01), (0, ground + (belt + top) / 2, z), paint))
    pts = [[glass_from, profile_height(profile, glass_from)]]
    pts += [pt for pt in profile if glass_from < pt[0] < glass_to]
    pts.append([glass_to, profile_height(profile, glass_to)])
    for a, b in zip(pts, pts[1:]):
        dz, dy = (b[0] - a[0]) * L, b[1] - a[1]
        length = math.hypot(dz, dy)
        if length > 0.02:
            steep = abs(dy) > 0.35 * dz
            parts.append(("rbox", (w * shape["cabinWidth"], 0.04, length + 0.02),
                          (0, ground + (a[1] + b[1]) / 2 - 0.02, z_at((a[0] + b[0]) / 2)),
                          glass if steep else paint, -math.atan2(dy, dz)))
    nose_top, tail_top = profile_height(profile, 0.02), profile_height(profile, 0.98)
    parts += [
        ("box", (1.5, 0.22, 0.12), (0, ground + 0.3, nose + 0.04), dark),
        ("box", (w - 0.2, 0.03, 0.3), (0, ground + 0.135, nose + 0.15), carbon),
        ("box", (1.5, 0.16, 0.3), (0, ground + 0.22, tail - 0.12), carbon),
    ]
    for side in (-1, 1):
        parts.append(("box", (0.38, 0.07, 0.12), (side * 0.68, ground + nose_top - 0.08, nose + 0.12), (240, 244, 255)))
        parts.append(("box", (0.3, 0.08, 0.04), (side * 0.62, ground + tail_top - 0.12, tail), (255, 30, 30)))
        parts.append(("box", (0.22, 0.1, 0.12), (side * (w / 2 + 0.05), ground + belt + 0.08, z_at(glass_from) + 0.15), paint))
    tip_d = cfg.get("visual", {}).get("exhaustTipDiameter", 0.09)
    tips = cfg.get("visual", {}).get("exhaustTips") or [[-0.32, 0.26], [-0.2, 0.26], [0.2, 0.26], [0.32, 0.26]]
    for x, y in tips:
        parts.append(("cylz", (0.09, tip_d / 2), (x, ground + y, tail - 0.02), chrome))
    for front in (True, False):
        spec = cfg["tires"]["front" if front else "rear"]
        radius = tyre_radius(spec["widthMm"], spec["aspect"], spec["rimInches"])
        track = dims["trackFront" if front else "trackRear"]
        width = spec["widthMm"] / 1000
        rim = spec["rimInches"] * 0.0254 / 2
        for side in (-1, 1):
            centre = (side * track / 2, ground + radius, front_z if front else rear_z)
            parts.append(("cylx", (width, radius), centre, (16, 16, 16)))
            parts.append(("cylx", (width + 0.012, rim), centre, (168, 170, 174)))
    # shift so the ground is at y = 0
    return [(p[0], p[1], (p[2][0], p[2][1] - ground, p[2][2])) + tuple(p[3:]) for p in parts]


def traffic_model(name, p, paint):
    """Mirror of TrafficRenderer.makeCar."""
    truck = name == "truck"
    height = 3.8 if truck else 1.15
    parts = [("box", (p["width"], height, p["length"]), (0, 0.18 + height / 2, 0), paint)]
    if not truck:
        parts.append(("box", (p["width"] * 0.86, 0.5, p["length"] * 0.48), (0, 0.18 + height + 0.25, 0.15), (20, 24, 30)))
    return parts


# --------------------------------------------------------------------------------------------
# Triangles
# --------------------------------------------------------------------------------------------

def box_tris(size, centre):
    sx, sy, sz = (s / 2 for s in size)
    cx, cy, cz = centre
    v = np.array([[cx + dx * sx, cy + dy * sy, cz + dz * sz] for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)])
    faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    tris = []
    for a, b, c, d in faces:
        tris.append((v[a], v[b], v[c]))
        tris.append((v[a], v[c], v[d]))
    return tris


def cyl_tris(length, radius, centre, axis, n=28):
    cx, cy, cz = centre
    tris = []
    ring = []
    for k in range(n):
        t = 2 * math.pi * k / n
        u, w = radius * math.cos(t), radius * math.sin(t)
        ring.append((u, w))

    def point(along, u, w):
        if axis == "x":
            return np.array([cx + along, cy + u, cz + w])
        return np.array([cx + u, cy + w, cz + along])

    h = length / 2
    for k in range(n):
        u0, w0 = ring[k]
        u1, w1 = ring[(k + 1) % n]
        a, b, c, d = point(-h, u0, w0), point(h, u0, w0), point(h, u1, w1), point(-h, u1, w1)
        tris += [(a, b, c), (a, c, d)]
        tris.append((point(h, 0, 0), point(h, u1, w1), point(h, u0, w0)))
        tris.append((point(-h, 0, 0), point(-h, u0, w0), point(-h, u1, w1)))
    return tris


def rotated_box_tris(size, centre, angle):
    """Box rotated about the X axis by angle (radians), like CFrame.Angles(angle, 0, 0)."""
    c, s_ = math.cos(angle), math.sin(angle)
    out = []
    for t in box_tris(size, (0, 0, 0)):
        out.append(tuple(np.array([p[0] + centre[0], p[1] * c - p[2] * s_ + centre[1], p[1] * s_ + p[2] * c + centre[2]])
                         for p in t))
    return out


def triangles(parts):
    out = []
    for part in parts:
        kind, size, centre, colour = part[:4]
        if kind == "rbox":
            tris = rotated_box_tris(size, centre, part[4])
        elif kind == "box":
            tris = box_tris(size, centre)
        elif kind == "cylx":
            tris = cyl_tris(size[0], size[1], centre, "x")
        else:
            tris = cyl_tris(size[0], size[1], centre, "z")
        out += [(t, colour) for t in tris]
    return out


# --------------------------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------------------------

def render(parts, w=TILE_W, h=TILE_H, yaw=-38.0, pitch=15.0, fit=1.25):
    tris = triangles(parts)
    pts = np.array([p for t, _ in tris for p in t])
    lo, hi = pts.min(axis=0), pts.max(axis=0)
    centre = (lo + hi) / 2
    radius = np.linalg.norm(hi - lo) / 2

    yr, pr = math.radians(yaw), math.radians(pitch)
    # the camera sits ahead of the car (cars face -Z) and off to one side, looking back at it
    forward = np.array([math.sin(yr) * math.cos(pr), -math.sin(pr), math.cos(yr) * math.cos(pr)])
    eye = centre - forward * radius * 3.2
    f = forward / np.linalg.norm(forward)
    right = np.cross(f, np.array([0, 1, 0]))
    right /= np.linalg.norm(right)
    up = np.cross(right, f)
    focal = 1.0 / math.tan(math.radians(17))
    scale = min(w, h) * 0.5 * fit

    light = np.array([-0.45, 0.8, -0.35])
    light /= np.linalg.norm(light)

    zbuf = np.full((h, w), np.inf)
    img = np.zeros((h, w, 3))
    img[:] = np.array([236, 238, 241]) / 255.0

    # soft ground shadow from the footprint
    shadow = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(shadow)

    def project(p):
        d = p - eye
        z = d @ f
        return np.array([w / 2 + (d @ right) / z * focal * scale, h / 2 - (d @ up) / z * focal * scale, z])

    foot = [np.array([x, 0.0, z]) for x, z in ((lo[0] - 0.15, lo[2] - 0.2), (hi[0] + 0.15, lo[2] - 0.2),
                                                (hi[0] + 0.15, hi[2] + 0.2), (lo[0] - 0.15, hi[2] + 0.2))]
    sd.polygon([tuple(project(p)[:2]) for p in foot], fill=150)
    shadow = np.array(shadow.filter(ImageFilter.GaussianBlur(14))) / 255.0
    img *= (1 - 0.45 * shadow[..., None])

    for (a, b, c), colour in tris:
        n = np.cross(b - a, c - a)
        norm = np.linalg.norm(n)
        if norm < 1e-12:
            continue
        n /= norm
        centroid = (a + b + c) / 3
        if n @ (centroid - eye) > 0:  # back face
            continue
        shade = 0.38 + 0.62 * max(0.0, n @ light)
        col = np.array(colour) / 255.0 * shade
        pa, pb, pc = project(a), project(b), project(c)
        xs, ys = (pa[0], pb[0], pc[0]), (pa[1], pb[1], pc[1])
        x0, x1 = max(int(min(xs)), 0), min(int(max(xs)) + 1, w - 1)
        y0, y1 = max(int(min(ys)), 0), min(int(max(ys)) + 1, h - 1)
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        den = (pb[1] - pc[1]) * (pa[0] - pc[0]) + (pc[0] - pb[0]) * (pa[1] - pc[1])
        if abs(den) < 1e-9:
            continue
        l1 = ((pb[1] - pc[1]) * (gx - pc[0]) + (pc[0] - pb[0]) * (gy - pc[1])) / den
        l2 = ((pc[1] - pa[1]) * (gx - pc[0]) + (pa[0] - pc[0]) * (gy - pc[1])) / den
        l3 = 1 - l1 - l2
        inside = (l1 >= -1e-6) & (l2 >= -1e-6) & (l3 >= -1e-6)
        if not inside.any():
            continue
        z = l1 * pa[2] + l2 * pb[2] + l3 * pc[2]
        sub = zbuf[y0:y1 + 1, x0:x1 + 1]
        nearer = inside & (z < sub)
        sub[nearer] = z[nearer]
        img[y0:y1 + 1, x0:x1 + 1][nearer] = col
    return Image.fromarray(np.clip(img * 255, 0, 255).astype(np.uint8))


def main():
    out = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "docs" / "models" / "lineup.png"
    font = ImageFont.truetype(FONT, 20)
    small = ImageFont.truetype(FONT, 16)
    bold = ImageFont.truetype(FONT_BOLD, 24)

    tiles = []
    for path in sorted(CONFIGS.glob("*.luau")):
        cfg = load(path)
        dims = cfg["dimensions"]
        title = cfg.get("displayName", cfg["id"])
        ref = cfg.get("reference", "")
        line = (f"{dims['length']:.3f} x {dims['width']:.3f} x {dims['height']:.3f} m, "
                f"wheelbase {dims['wheelbase']:.3f} m, {cfg['mass']['kerbKg']:,} kg")
        tiles.append((render(car_model(cfg)), title, ref, line))

    profiles = load(PROFILES, key="DriverProfiles.profiles")
    for name, paint in (("normal", (60, 90, 140)), ("truck", (235, 235, 232))):
        p = profiles[name]
        label = "Traffic car (stand-in)" if name == "normal" else "Traffic truck (stand-in)"
        tiles.append((render(traffic_model(name, p, paint), fit=0.95 if name == "normal" else 0.9), label,
                      "drawn by TrafficRenderer", f"{p['length']} x {p['width']} m"))

    cols = 2
    rows = math.ceil(len(tiles) / cols)
    pad, head = 24, 92
    sheet = Image.new("RGB", (cols * TILE_W + (cols + 1) * pad, rows * (TILE_H + head) + (rows + 1) * pad + 70),
                      (250, 250, 251))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 20), "Redline Highway: every car model in the game so far (stand-in blockouts, to be remodelled in Blender)",
           font=bold, fill=(20, 20, 24))
    for i, (img, title, ref, line) in enumerate(tiles):
        x = pad + (i % cols) * (TILE_W + pad)
        y = 70 + pad + (i // cols) * (TILE_H + head + pad)
        sheet.paste(img, (x, y))
        d.text((x, y + TILE_H + 8), title, font=font, fill=(20, 20, 24))
        d.text((x, y + TILE_H + 34), ref, font=small, fill=(90, 92, 98))
        d.text((x, y + TILE_H + 56), line, font=small, fill=(90, 92, 98))
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    shown = out.relative_to(ROOT) if out.is_relative_to(ROOT) else out
    print(f"Wrote {shown}: {len(tiles)} models, {sheet.size[0]}x{sheet.size[1]}")


if __name__ == "__main__":
    main()
