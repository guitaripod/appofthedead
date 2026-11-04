#!/usr/bin/python3
"""Draw the text-free artwork of the 2.0 in-app event "Face the Judgment": the scale of Ma'at, cut from a raw capture
of the weighing, glowing on the night sky. Apple sets the event name over the card.

Usage: compose_event_art.py WEIGHING_RAW_PNG OUT_DIR
"""

import os
import sys

from PIL import Image, ImageChops, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_store_shots import hex_color, night_sky


def scale_cutout(raw):
    capture = Image.open(raw).convert("RGB")
    width, height = capture.size
    box = (int(width * 0.04), int(height * 0.36), int(width * 0.96), int(height * 0.66))
    art = capture.crop(box)
    mask = art.convert("L").point(lambda v: 0 if v < 60 else min(255, (v - 60) * 4))
    return art, mask


def compose(raw, size, art_width, center_y):
    canvas = night_sky(size, hex_color("#E5BA5C"), seed=77, center=(0.5, center_y + 0.1), reach=0.7, strength=0.35)
    art, mask = scale_cutout(raw)
    scale = art_width / art.width
    art = art.resize((art_width, int(art.height * scale)), Image.Resampling.LANCZOS)
    mask = mask.resize(art.size, Image.Resampling.LANCZOS)
    glow = Image.new("RGB", size, (0, 0, 0))
    x, y = (size[0] - art.width) // 2, int(size[1] * center_y - art.height / 2)
    glow.paste(art, (x, y), mask)
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    canvas = ImageChops.add(canvas, glow)
    canvas.paste(art, (x, y), mask)
    return canvas


def main():
    raw, out = sys.argv[1], sys.argv[2]
    compose(raw, (1920, 1080), 1100, 0.5).save(os.path.join(out, "card.png"), optimize=True)
    compose(raw, (1080, 1920), 960, 0.42).save(os.path.join(out, "details.png"), optimize=True)


if __name__ == "__main__":
    main()
