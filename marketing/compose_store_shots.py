#!/usr/bin/python3
"""Compose App of the Dead's App Store screenshots from raw simulator captures.

Usage: compose_store_shots.py RAW_DIR LOCALE [LOCALE ...]

RAW_DIR holds <device>/<locale>/NN-name.png raw captures (iphone 1320x2868, ipad 2064x2752, duo at any of its four
slot sizes: 1398x2034, 2034x1398, 2007x2853, 2853x2007). Each capture is framed with the `frames` CLI (the bezel), then
set on a night sky with a glow in the shot's color and a caption from marketing/captions/<locale>.json. A Duo shot keeps
its capture's size, so each lands in the App Store slot of its display and orientation. Output goes to
store/shots/<device>/<locale>/NN-name.png, ready for `midgar shots`.
"""

import json
import os
import random
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
APP = os.path.dirname(ROOT)
CAPTIONS = os.path.join(ROOT, "captions")
OUT = os.path.join(APP, "store", "shots")
FRAMES = os.path.expanduser("~/.local/bin/frames")

CANVAS = {"iphone": (1320, 2868), "ipad": (2064, 2752)}
DUO_SLOTS = {(1398, 2034), (2034, 1398), (2007, 2853), (2853, 2007)}
FRAME_COLOR = {"iphone": "Silver", "ipad": "Silver", "duo": "Star White"}
DEVICES = ("iphone", "ipad", "duo")
NIGHT_TOP = (12, 10, 17)
NIGHT_BOTTOM = (28, 19, 40)
GOLD = (229, 186, 92)
PARCHMENT = (243, 234, 216)
SERIF = "/System/Library/Fonts/NewYork.ttf"
SANS = "/System/Library/Fonts/SFNS.ttf"
CJK = {
    "ja": ("/System/Library/Fonts/ヒラギノ明朝 ProN.ttc", 2),
    "ko": ("/System/Library/Fonts/AppleSDGothicNeo.ttc", 6),
    "zh-Hans": ("/System/Library/Fonts/Supplemental/Songti.ttc", 0),
    "zh-Hant": ("/System/Library/Fonts/Supplemental/Songti.ttc", 2),
}
CLOSING = "？！。、，）」』：；?!.,)ぁぃぅぇぉっゃゅょァィゥェォッャュョー"
PARTICLES = "のはへをにがとでもや、"


def font(path, size, variation=None, index=0):
    face = ImageFont.truetype(path, size, index=index)
    if variation:
        try:
            face.set_variation_by_name(variation)
        except (OSError, ValueError):
            pass
    return face


def headline_font(locale, size):
    for key, (path, index) in CJK.items():
        if locale.startswith(key) and os.path.exists(path):
            return font(path, size, index=index)
    return font(SERIF, size, "Bold")


def kicker_font(locale, size):
    for key, (path, index) in CJK.items():
        if locale.startswith(key) and os.path.exists(path):
            return font(path, size, index=index)
    return font(SANS, size, "Semibold")


def hex_color(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def night_sky(size, glow, seed, center=(0.5, 0.62), reach=0.75, strength=0.5):
    width, height = size
    sky = Image.new("RGB", size)
    draw = ImageDraw.Draw(sky)
    for y in range(height):
        t = y / height
        draw.line([(0, y), (width, y)], fill=tuple(int(NIGHT_TOP[i] + (NIGHT_BOTTOM[i] - NIGHT_TOP[i]) * t) for i in range(3)))
    halo = Image.new("RGB", size, (0, 0, 0))
    halo_draw = ImageDraw.Draw(halo)
    radius = int(min(width, height * 0.75) * reach)
    cx, cy = int(width * center[0]), int(height * center[1])
    halo_draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=tuple(int(c * strength) for c in glow))
    halo = halo.filter(ImageFilter.GaussianBlur(radius * 0.45))
    sky = ImageChops.add(sky, halo)
    stars = ImageDraw.Draw(sky)
    rng = random.Random(seed)
    for _ in range(int(width * height / 9000)):
        x, y = rng.uniform(0, width), rng.uniform(0, height * 0.55)
        r = rng.uniform(0.8, 2.6)
        alpha = rng.uniform(0.25, 0.85)
        tone = tuple(int(PARCHMENT[i] * alpha + NIGHT_TOP[i] * (1 - alpha)) for i in range(3))
        stars.ellipse([x - r, y - r, x + r, y + r], fill=tone)
    return sky


def wrap(draw, text, face, max_width):
    words = text.split(" ")
    if len(words) == 1:
        lines, current = [], ""
        for ch in text:
            if draw.textlength(current + ch, font=face) > max_width and current:
                lines.append(current)
                current = ch.lstrip()
            else:
                current += ch
        return lines + ([current] if current else [])
    lines, current = [], ""
    for word in words:
        trial = f"{current} {word}".strip()
        if draw.textlength(trial, font=face) > max_width and current:
            lines.append(current)
            current = word
        else:
            current = trial
    return lines + ([current] if current else [])


def balanced(draw, text, face, max_width):
    """Wraps like `wrap`, then evens out a two-line headline so no word is left alone on its line."""
    lines = wrap(draw, text, face, max_width)
    words = text.split(" ")
    if len(lines) == 2 and len(words) == 1:
        return balanced_unspaced(draw, text, face, max_width, lines)
    if len(lines) != 2 or len(words) < 3:
        return lines
    best = lines
    best_width = max(draw.textlength(line, font=face) for line in lines)
    for cut in range(1, len(words)):
        first, second = " ".join(words[:cut]), " ".join(words[cut:])
        widest = max(draw.textlength(first, font=face), draw.textlength(second, font=face))
        if widest <= max_width and widest < best_width:
            best, best_width = [first, second], widest
    return best


def balanced_unspaced(draw, text, face, max_width, lines):
    """Splits an unspaced (Chinese or Japanese) headline near its middle, never opening a line with closing punctuation.

    Japanese breaks after a particle when one fits, so a word like 裁判官 is never cut in two."""
    cuts = [cut for cut in range(1, len(text)) if text[cut] not in CLOSING]
    if any(0x3040 <= ord(ch) <= 0x30FF for ch in text):
        after_particle = [cut for cut in cuts if text[cut - 1] in PARTICLES]
        return most_even_split(draw, text, face, max_width, after_particle, None) or most_even_split(draw, text, face, max_width, cuts, lines)
    return most_even_split(draw, text, face, max_width, cuts, lines)


def most_even_split(draw, text, face, max_width, cuts, fallback):
    """Picks the cut whose wider line is narrowest among those that fit `max_width`, or `fallback` when none fits."""
    best, best_width = fallback, float("inf")
    for cut in cuts:
        first, second = text[:cut], text[cut:]
        widest = max(draw.textlength(first, font=face), draw.textlength(second, font=face))
        if widest <= max_width and widest < best_width:
            best, best_width = [first, second], widest
    return best


def frame(raw, device):
    with tempfile.TemporaryDirectory() as out:
        result = subprocess.run(
            ["/usr/bin/python3", FRAMES, "--json", "-c", FRAME_COLOR[device], "-o", out, raw],
            capture_output=True, text=True, check=True,
        )
        info = json.loads(result.stdout)
        return Image.open(info["output"]).convert("RGBA")


def canvas_size(raw, device):
    """The slot a shot fills: fixed for iPhone and iPad, the capture's own size for a Duo display and orientation."""
    if device != "duo":
        return CANVAS[device]
    size = Image.open(raw).size
    assert size in DUO_SLOTS, (raw, size)
    return size


def caption_sizes(device, width, height):
    """Kicker and headline point sizes, from the width on phones and tablets and from the short side on a Duo."""
    if device == "duo":
        short = min(width, height)
        return int(short * 0.024), int(short * 0.066)
    return int(width * (0.031 if device == "iphone" else 0.021)), int(width * (0.088 if device == "iphone" else 0.06))


def compose(raw, device, locale, caption, index):
    width, height = canvas_size(raw, device)
    glow = hex_color(caption.get("glow", "#E5BA5C"))
    canvas = night_sky((width, height), glow, seed=index * 7 + len(locale))
    draw = ImageDraw.Draw(canvas)
    margin = int(width * 0.08)
    kicker_size, headline_size = caption_sizes(device, width, height)
    kicker = kicker_font(locale, kicker_size)
    y = int(height * 0.055)
    kicker_text = caption["kicker"].upper() if not any(ord(ch) > 0x2E80 for ch in caption["kicker"]) else caption["kicker"]
    spaced = " ".join(kicker_text) if not any(ord(ch) > 0x2E80 for ch in kicker_text) and len(kicker_text) < 30 else kicker_text
    kw = draw.textlength(spaced, font=kicker)
    draw.text(((width - kw) / 2, y), spaced, font=kicker, fill=GOLD)
    y += int(kicker_size * 2.0)
    size = headline_size
    while True:
        face = headline_font(locale, size)
        lines = balanced(draw, caption["headline"], face, width - 2 * margin)
        if len(lines) <= 2 or size < headline_size * 0.7:
            break
        size -= 4
    for line in lines:
        lw = draw.textlength(line, font=face)
        draw.text(((width - lw) / 2, y), line, font=face, fill=PARCHMENT)
        y += int(size * 1.18)
    y += int(height * 0.025)

    device_image = frame(raw, device)
    scale = device_scale(device_image, device, width, height, y)
    scaled = device_image.resize((int(device_image.width * scale), int(device_image.height * scale)), Image.Resampling.LANCZOS)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_mask = Image.new("L", canvas.size, 0)
    x = (width - scaled.width) // 2
    shadow_mask.paste(scaled.split()[3], (x, y + 30))
    shadow.putalpha(shadow_mask.filter(ImageFilter.GaussianBlur(40)).point(lambda a: int(a * 0.55)))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)
    canvas.alpha_composite(scaled, (x, y))
    return canvas.convert("RGB")


def device_scale(device_image, device, width, height, top):
    """Phones and tablets fill the width and run off the bottom edge; a landscape Duo fits whole below the caption."""
    if device == "duo" and width > height:
        return min(width * 0.86 / device_image.width, (height - top - height * 0.04) / device_image.height)
    return width * (0.9 if device == "iphone" else 0.86) / device_image.width


def main():
    raw_root, locales = sys.argv[1], sys.argv[2:]
    for locale in locales:
        captions = json.load(open(os.path.join(CAPTIONS, f"{locale}.json")))
        for device in DEVICES:
            source = os.path.join(raw_root, device, locale)
            if not os.path.isdir(source):
                continue
            target = os.path.join(OUT, device, locale)
            os.makedirs(target, exist_ok=True)
            for old in os.listdir(target):
                if old.endswith(".png"):
                    os.remove(os.path.join(target, old))
            for index, name in enumerate(sorted(f for f in os.listdir(source) if f.endswith(".png"))):
                key = name.split("-", 1)[1].rsplit(".", 1)[0]
                if key not in captions:
                    continue
                image = compose(os.path.join(source, name), device, locale, captions[key], index)
                assert image.size == canvas_size(os.path.join(source, name), device), (name, image.size)
                image.save(os.path.join(target, name), optimize=True)
                print(f"{device}/{locale}/{name}")


if __name__ == "__main__":
    main()
