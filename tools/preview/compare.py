"""Puts a reference picture above a model's render, scaled to the same width,
so the two can be compared shape for shape.

    python3 tools/preview/compare.py <reference.png> <render sheet.png> <out.png> [panel]

The render sheet is a PNG from render.mjs; panel picks which view to use
(0 = the first view, which is "side" for guns). Both pictures are trimmed to
what's drawn in them, so length, height and where things sit line up.
"""
import sys

from PIL import Image, ImageChops, ImageDraw

VIEW_W, VIEW_H, HEADER = 640, 440, 44
WIDTH = 1000


def trim(image, background, tolerance=18):
    bg = Image.new(image.mode, image.size, background)
    diff = ImageChops.difference(image, bg).convert("L").point(lambda v: 255 if v > tolerance else 0)
    box = diff.getbbox()
    return image.crop(box) if box else image


def main():
    ref_path, sheet_path, out_path = sys.argv[1:4]
    panel = int(sys.argv[4]) if len(sys.argv) > 4 else 0
    ref = Image.open(ref_path).convert("RGB")
    ref = trim(ref, ref.getpixel((0, 0)), 40)
    sheet = Image.open(sheet_path).convert("RGB")
    view = sheet.crop((panel * VIEW_W, HEADER, panel * VIEW_W + VIEW_W, HEADER + VIEW_H))
    view = view.crop((0, 30, VIEW_W, VIEW_H))  # skip the view's name tag
    view = trim(view, view.getpixel((VIEW_W - 2, VIEW_H - 32)))

    def fit(image):
        scale = WIDTH / image.width
        return image.resize((WIDTH, max(1, round(image.height * scale))), Image.LANCZOS)

    ref, view = fit(ref), fit(view)
    out = Image.new("RGB", (WIDTH + 20, ref.height + view.height + 80), (24, 26, 31))
    draw = ImageDraw.Draw(out)
    draw.text((10, 6), "REFERENCE", fill=(255, 220, 90))
    out.paste(ref, (10, 24))
    draw.text((10, ref.height + 34), "MODEL (same width)", fill=(255, 46, 99))
    out.paste(view, (10, ref.height + 52))
    out.save(out_path)


if __name__ == "__main__":
    main()
