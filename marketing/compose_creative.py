#!/usr/bin/python3
"""Compose the iOS 27 product page creative: the 21:9 Product Page Header and the 3:2 Search Results asset.

Usage: compose_creative.py RAW_DIR LOCALE [LOCALE ...]

The header is text-free: three framed iPhones (a guardian's question, the verdict, the weighing) fanned over the night
sky. The search asset sets the verdict beside the locale's Judgment caption from marketing/captions/<locale>.json.
Raw captures come from RAW_DIR/iphone/<locale>/ (falling back to en-US) and are framed with the `frames` CLI.
Output: marketing/creative/<locale>/header-3840x1646.png and search-3840x2560.png.
"""

import os
import sys
import json

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compose_store_shots import CAPTIONS, GOLD, PARCHMENT, balanced, frame, headline_font, hex_color, kicker_font, night_sky

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "creative")


def framed(raw_root, locale, name):
    path = os.path.join(raw_root, "iphone", locale, name)
    if not os.path.exists(path):
        path = os.path.join(raw_root, "iphone", "en-US", name)
    return frame(path, "iphone")


def place(canvas, device, height, center_x, top, angle=0.0):
    scale = height / device.height
    image = device.resize((int(device.width * scale), height), Image.Resampling.LANCZOS)
    if angle:
        image = image.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    mask = Image.new("L", canvas.size, 0)
    x = int(center_x - image.width / 2)
    mask.paste(image.split()[3], (x, top + 40))
    shadow.putalpha(mask.filter(ImageFilter.GaussianBlur(60)).point(lambda a: int(a * 0.6)))
    canvas = Image.alpha_composite(canvas, shadow)
    canvas.alpha_composite(image, (x, top))
    return canvas


def header(raw_root, locale):
    size = (3840, 1646)
    canvas = night_sky(size, hex_color("#E5BA5C"), seed=101, center=(0.75, 0.9), reach=0.9, strength=0.32).convert("RGBA")
    phone_height = 2300
    canvas = place(canvas, framed(raw_root, locale, "02-charon.png"), phone_height, 2180, 330, angle=7)
    canvas = place(canvas, framed(raw_root, locale, "03-weighing.png"), phone_height, 3240, 330, angle=-7)
    canvas = place(canvas, framed(raw_root, locale, "01-verdict.png"), phone_height + 120, 2710, 170)
    return canvas.convert("RGB")


def search(raw_root, locale):
    size = (3840, 2560)
    caption = json.load(open(os.path.join(CAPTIONS, f"{locale}.json")))["verdict"]
    canvas = night_sky(size, hex_color(caption.get("glow", "#E5BA5C")), seed=202, center=(0.72, 0.85), reach=0.8, strength=0.32).convert("RGBA")
    canvas = place(canvas, framed(raw_root, locale, "01-verdict.png"), 3000, 2780, 360)
    draw = ImageDraw.Draw(canvas)
    left, text_width = 300, 1500
    kicker = kicker_font(locale, 70)
    kicker_text = caption["kicker"] if any(ord(ch) > 0x2E80 for ch in caption["kicker"]) else " ".join(caption["kicker"].upper())
    draw.text((left, 880), kicker_text, font=kicker, fill=GOLD)
    size_pt = 190
    face = headline_font(locale, size_pt)
    lines = balanced(draw, caption["headline"], face, text_width)
    while len(lines) > 3 and size_pt > 120:
        size_pt -= 10
        face = headline_font(locale, size_pt)
        lines = balanced(draw, caption["headline"], face, text_width)
    y = 1010
    for line in lines:
        draw.text((left, y), line, font=face, fill=PARCHMENT)
        y += int(size_pt * 1.15)
    return canvas.convert("RGB")


def main():
    raw_root, locales = sys.argv[1], sys.argv[2:]
    for locale in locales:
        target = os.path.join(OUT, locale)
        os.makedirs(target, exist_ok=True)
        if locale == "en-US":
            header(raw_root, locale).save(os.path.join(target, "header-3840x1646.png"), optimize=True)
            print(f"{locale}/header-3840x1646.png")
        search(raw_root, locale).save(os.path.join(target, "search-3840x2560.png"), optimize=True)
        print(f"{locale}/search-3840x2560.png")


if __name__ == "__main__":
    main()
