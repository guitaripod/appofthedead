import math
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BURGUNDY = np.array([128, 0, 32], dtype=np.float32)
NIGHT = np.array([9, 4, 7], dtype=np.float32)
EMBER = np.array([255, 190, 110], dtype=np.float32)
GOLD = (214, 170, 82)
BONE = (236, 226, 204)
MARIGOLDS = [(247, 158, 18), (242, 120, 12), (250, 182, 40), (226, 96, 10), (255, 200, 70)]


def radial(w, h, cx, cy, radius):
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / radius
    return np.clip(d, 0, 1)


def background(w, h, cx, cy):
    t = radial(w, h, cx, cy, math.hypot(w, h) * 0.62) ** 0.85
    inner = np.array([34, 6, 14], dtype=np.float32)
    rgb = inner[None, None, :] * (1 - t[..., None]) + BURGUNDY[None, None, :] * 0.55 * t[..., None]
    vignette = radial(w, h, cx, cy, math.hypot(w, h) * 0.75) ** 2.2
    rgb = rgb * (1 - 0.55 * vignette[..., None]) + NIGHT[None, None, :] * 0.55 * vignette[..., None]
    return rgb


def stepped_rect(x0, y0, x1, y1, notch):
    return [
        (x0 + notch, y0), (x1 - notch, y0), (x1 - notch, y0 + notch), (x1, y0 + notch),
        (x1, y1 - notch), (x1 - notch, y1 - notch), (x1 - notch, y1), (x0 + notch, y1),
        (x0 + notch, y1 - notch), (x0, y1 - notch), (x0, y0 + notch), (x0 + notch, y0 + notch),
    ]


def draw_levels(img, cx, cy, w, h):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    levels = 9
    max_w, max_h = w * 0.86, h * 0.86
    min_w, min_h = w * 0.16, h * 0.16
    for i in range(levels):
        t = i / (levels - 1)
        ease = 1 - (1 - t) ** 1.6
        rw = max_w + (min_w - max_w) * ease
        rh = max_h + (min_h - max_h) * ease
        x0, y0, x1, y1 = cx - rw / 2, cy - rh / 2, cx + rw / 2, cy + rh / 2
        notch = max(10, min(rw, rh) * 0.045)
        depth = (i + 1) / levels
        fill = tuple(int(c) for c in (BURGUNDY * (1 - depth) * 0.42 + NIGHT * depth * 0.9)) + (int(90 + 150 * depth),)
        d.polygon(stepped_rect(x0, y0, x1, y1, notch), fill=fill)
        line = GOLD if i % 2 == 0 else BONE
        alpha = int(200 - 120 * t)
        d.line(stepped_rect(x0, y0, x1, y1, notch) + [stepped_rect(x0, y0, x1, y1, notch)[0]],
               fill=line + (alpha,), width=2 if i < 3 else 1)
    img.alpha_composite(layer)


def glow(img, cx, cy, radius, strength):
    w, h = img.size
    t = radial(w, h, cx, cy, radius)
    a = (1 - t) ** 2.4 * strength
    layer = np.zeros((h, w, 4), dtype=np.float32)
    layer[..., :3] = EMBER
    layer[..., 3] = a * 255
    img.alpha_composite(Image.fromarray(layer.clip(0, 255).astype(np.uint8), "RGBA"))


def petal_shape(size, color, rng):
    length = size
    width = size * rng.uniform(0.55, 0.75)
    pad = int(size * 0.3) + 2
    im = Image.new("RGBA", (int(width) + pad * 2, int(length) + pad * 2), color + (0,))
    d = ImageDraw.Draw(im)
    x0, y0 = pad, pad
    d.ellipse([x0, y0, x0 + width, y0 + length], fill=color + (240,))
    tip = tuple(min(255, c + 40) for c in color)
    d.ellipse([x0 + width * 0.18, y0 + length * 0.04, x0 + width * 0.82, y0 + length * 0.5], fill=tip + (150,))
    return im


def scatter_petal(img, x, y, size, rng, blur=0.0, alpha=1.0):
    color = rng.choice(MARIGOLDS)
    p = petal_shape(size, color, rng).rotate(rng.uniform(0, 360), resample=Image.BICUBIC, expand=True)
    if blur > 0:
        p = p.filter(ImageFilter.GaussianBlur(blur))
    if alpha < 1:
        a = np.array(p)
        a[..., 3] = (a[..., 3] * alpha).astype(np.uint8)
        p = Image.fromarray(a, "RGBA")
    img.alpha_composite(p, (int(x - p.width / 2), int(y - p.height / 2)))


def marigold(img, x, y, radius, rng, blur=0.0):
    layer = Image.new("RGBA", img.size, (240, 140, 20, 0))
    rings = 7
    for r in range(rings, 0, -1):
        ring_radius = radius * r / rings
        count = int(14 + 8 * r)
        size = radius * (0.5 - 0.035 * (rings - r))
        for k in range(count):
            angle = 2 * math.pi * k / count + rng.uniform(-0.15, 0.15)
            px = x + math.cos(angle) * ring_radius * 0.72
            py = y + math.sin(angle) * ring_radius * 0.72
            color = MARIGOLDS[(r + k) % len(MARIGOLDS)]
            shade = 1 - 0.28 * (r / rings)
            c = tuple(int(v * shade) for v in color)
            pet = petal_shape(max(6, size), c, rng)
            pet = pet.rotate(-math.degrees(angle) - 90 + rng.uniform(-20, 20), resample=Image.BICUBIC, expand=True)
            layer.alpha_composite(pet, (int(px - pet.width / 2), int(py - pet.height / 2)))
    d = ImageDraw.Draw(layer)
    d.ellipse([x - radius * 0.14, y - radius * 0.14, x + radius * 0.14, y + radius * 0.14], fill=(150, 60, 8, 230))
    shadow = layer.split()[3].filter(ImageFilter.GaussianBlur(radius * 0.18))
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sh.putalpha(shadow.point(lambda v: int(v * 0.55)))
    img.alpha_composite(sh, (int(radius * 0.06), int(radius * 0.1)))
    if blur > 0:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(layer)


def petal_trail(img, start, end, count, rng, spread):
    for i in range(count):
        t = (i / count) ** 0.8
        x = start[0] + (end[0] - start[0]) * t + rng.gauss(0, spread * (1 - t * 0.8))
        y = start[1] + (end[1] - start[1]) * t + rng.gauss(0, spread * 0.5 * (1 - t * 0.8))
        size = 26 * (1 - t) + 7 * t + rng.uniform(-3, 3)
        near = rng.random() < 0.18 and t < 0.35
        scatter_petal(img, x, y, size * (1.6 if near else 1), rng,
                      blur=4.5 if near else (0.6 if t > 0.6 else 0),
                      alpha=0.95 - 0.45 * t)


def dust(img, cx, cy, rng, n):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for _ in range(n):
        a = rng.uniform(0, 2 * math.pi)
        r = abs(rng.gauss(0, min(img.size) * 0.22))
        x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
        s = rng.uniform(0.8, 2.4)
        d.ellipse([x - s, y - s, x + s, y + s], fill=(255, 214, 150, int(rng.uniform(40, 150))))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.8)))


def grain(img, rng_seed, amount=6):
    arr = np.array(img).astype(np.int16)
    noise = np.random.default_rng(rng_seed).normal(0, amount, arr.shape[:2])
    arr[..., :3] = np.clip(arr[..., :3] + noise[..., None], 0, 255)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def render(w, h, portrait, out):
    rng = random.Random(1102 if portrait else 2410)
    cx, cy = w / 2, h * (0.6 if portrait else 0.52)
    img = Image.fromarray(np.concatenate(
        [background(w, h, cx, cy).clip(0, 255).astype(np.uint8), np.full((h, w, 1), 255, np.uint8)], axis=2), "RGBA")
    draw_levels(img, cx, cy, w, h)
    glow(img, cx, cy, min(w, h) * 0.55, 0.5)
    glow(img, cx, cy, min(w, h) * 0.12, 1.0)
    dust(img, cx, cy, rng, 160)
    if portrait:
        petal_trail(img, (w * 0.5, -40), (cx, cy), 70, rng, spread=w * 0.16)
        marigold(img, w * 0.14, h * 0.07, 118, rng)
        marigold(img, w * 0.9, h * 0.16, 92, rng)
        marigold(img, w * 0.06, h * 0.93, 88, rng, blur=3)
        marigold(img, w * 0.93, h * 0.88, 124, rng)
    else:
        petal_trail(img, (-40, h * 0.18), (cx, cy), 55, rng, spread=h * 0.14)
        petal_trail(img, (w + 40, h * 0.3), (cx, cy), 45, rng, spread=h * 0.12)
        marigold(img, w * 0.07, h * 0.14, 112, rng)
        marigold(img, w * 0.93, h * 0.82, 128, rng)
        marigold(img, w * 0.88, h * 0.1, 70, rng, blur=3.5)
        marigold(img, w * 0.1, h * 0.9, 78, rng, blur=2.5)
    glow(img, cx, cy, min(w, h) * 0.05, 0.9)
    img = grain(img, 7)
    img.convert("RGB").save(out)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    render(1920, 1080, False, f"{out_dir}/card.png")
    render(1080, 1920, True, f"{out_dir}/detail.png")
