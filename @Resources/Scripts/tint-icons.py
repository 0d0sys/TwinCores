# tint-icons.py - re-tint the brand artwork to the active Watershed palette.
#
#   python tint-icons.py
#
# Reads the palette accents from @Resources\Watershed.inc and the brand
# originals from @Resources\Icons\*-brand.png, then rewrites
# brave-lion.png (duotone gradient Accent -> Accent2 through the lion's
# alpha mask) and bionic-worker.png (pixel-art hue remap: purple body ->
# Accent teal, yellow hat -> Accent3 gold, orange toolbox -> Accent2
# steel, blue hammer -> Accent; grays/outlines untouched, shading kept).
#
# Run this after switching the theme palette in Watershed.inc.

import colorsys
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.dirname(HERE)
ICONS = os.path.join(RES, 'Icons')
INC = os.path.join(RES, 'Watershed.inc')


def read_palette():
    text = open(INC, 'r', encoding='utf-8', errors='replace').read()
    out = {}
    for key in ('Accent', 'Accent2', 'Accent3'):
        m = re.search(r'^%s=([0-9]+),([0-9]+),([0-9]+)' % key, text, re.M)
        if not m:
            sys.exit('palette key %s not found in Watershed.inc' % key)
        out[key] = tuple(int(m.group(i)) for i in (1, 2, 3))
    return out


def hsv_of(rgb):
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in rgb))
    return h * 360, s, v


def from_hsv(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h / 360, s, v)
    return (int(round(r * 255)), int(round(g * 255)), int(round(b * 255)), 255)


def tint_worker(path, out, pal):
    from PIL import Image
    h_acc, s_acc = hsv_of(pal['Accent'])[:2]
    h_a2, s_a2 = hsv_of(pal['Accent2'])[:2]
    h_a3, s_a3 = hsv_of(pal['Accent3'])[:2]
    im = Image.open(path).convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            p = px[x, y]
            if p[3] == 0:
                continue
            h, s, v = hsv_of(p)
            if s < 0.22 or v < 0.12:
                continue  # grays / outlines stay
            if 235 <= h <= 330:      # purple body -> teal
                px[x, y] = from_hsv(h_acc, min(1, s * (s_acc / 0.65)), v)
            elif 35 <= h <= 75:      # yellow hat -> gold
                px[x, y] = from_hsv(h_a3, min(1, s * (s_a3 / 1.0)), v)
            elif h < 35:             # orange toolbox -> steel
                px[x, y] = from_hsv(h_a2, min(1, s * (s_a2 / 0.80)), v)
            elif 180 <= h <= 240:    # blue handle -> teal
                px[x, y] = from_hsv(h_acc, min(1, s * (s_acc / 1.0)), v)
    im.save(out)
    print('tinted', out)


def tint_lion(path, out, pal):
    from PIL import Image
    a, b = pal['Accent'], pal['Accent2']
    im = Image.open(path).convert('RGBA')
    w, h = im.size
    grad = Image.new('RGBA', (w, h))
    gp = grad.load()
    for x in range(w):
        t = x / max(1, w - 1)
        c = tuple(int(round(lo + (hi - lo) * t)) for lo, hi in zip(a, b)) + (255,)
        for y in range(h):
            gp[x, y] = c
    grad.putalpha(im.getchannel('A'))
    grad.save(out)
    print('tinted', out)


if __name__ == '__main__':
    pal = read_palette()
    tint_lion(os.path.join(ICONS, 'brave-lion-brand.png'),
              os.path.join(ICONS, 'brave-lion.png'), pal)
    tint_worker(os.path.join(ICONS, 'bionic-worker-brand.png'),
                os.path.join(ICONS, 'bionic-worker.png'), pal)
