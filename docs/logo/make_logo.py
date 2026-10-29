"""Draws the my-nkap logo, "où va mon argent ?": the trail the money leaves
draws a dotted question mark, and a gold $ coin is its dot. Ledger green tile,
cream trail, gold coin. The black master is docs/logo/concepts/a-trail-question.svg.

Usage: python docs/logo/make_logo.py <project>   then   dart run flutter_launcher_icons

Outputs (in <project>/assets/icon/ and android res/drawable-*/):
  icon.png             1024 full icon (rounded square) for legacy launchers
  foreground.png       1024 adaptive foreground (transparent, safe zone)
  monochrome.png       1024 Android 13 themed icon silhouette
  logo-512.png         512 store/branding icon
  splash_logo.png      launch screen artwork (before Android 12)
  ic_stat_carnet.png   white notification silhouettes at each density
"""
import math
import os
import sys

from PIL import Image, ImageDraw

PROJECT = sys.argv[1]
OUT = os.path.join(PROJECT, "assets", "icon")
RES = os.path.join(PROJECT, "android", "app", "src", "main", "res")
os.makedirs(OUT, exist_ok=True)

GREEN = (29, 106, 86, 255)
GREEN_DARK = (19, 76, 61, 255)
CREAM = (247, 244, 236, 255)
GOLD = (232, 163, 61, 255)
GOLD_DARK = (196, 124, 32, 255)
WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)
SS = 4  # supersampling factor for smooth edges

# Geometry on a 256 grid (same numbers as the SVG master).
HOOK = (128, 86, 50, 160, 385)  # arc centre x, y, radius, start and end angle (degrees, y down)
STEM_END = (128, 160)
TRAIL_W, DASH, GAP = 24, 18, 44  # stroke width and dash pattern, as an SVG stroke-dasharray with round caps
COIN = (128, 214, 32)
DOLLAR_K, DOLLAR_W = 30, 6.5


def cubic(p0, p1, p2, p3, n):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append(tuple(u**3 * a + 3 * u * u * t * b + 3 * u * t * t * c + t**3 * d for a, b, c, d in zip(p0, p1, p2, p3)))
    return out


def trail():
    """The question mark's hook and stem as a dense polyline."""
    cx, cy, r, a0, a1 = HOOK
    arc = [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / 600)), cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / 600))) for i in range(601)]
    x1, y1 = arc[-1]
    return arc + cubic((x1, y1), (x1 - 14, y1 + 10), (128, 140), STEM_END, 200)[1:]


def dollar_strokes(cx, cy, k):
    S = (
        cubic((cx + 0.34 * k, cy - 0.36 * k), (cx + 0.22 * k, cy - 0.54 * k), (cx - 0.38 * k, cy - 0.54 * k), (cx - 0.38 * k, cy - 0.22 * k), 120)
        + cubic((cx - 0.38 * k, cy - 0.22 * k), (cx - 0.38 * k, cy + 0.04 * k), (cx + 0.38 * k, cy - 0.06 * k), (cx + 0.38 * k, cy + 0.22 * k), 120)
        + cubic((cx + 0.38 * k, cy + 0.22 * k), (cx + 0.38 * k, cy + 0.54 * k), (cx - 0.22 * k, cy + 0.54 * k), (cx - 0.36 * k, cy + 0.36 * k), 120)
    )
    bar = [(cx, cy - 0.66 * k + (1.32 * k) * i / 100) for i in range(101)]
    return [S, bar]


class Transform:
    """Maps the 256 grid into a box of the supersampled image."""

    def __init__(self, x, y, size):
        self.x, self.y, self.s = x, y, size / 256

    def __call__(self, px, py):
        return (self.x + px * self.s, self.y + py * self.s)


def stamp(d, pts, width, color, T):
    """Round-capped stroke: discs stamped densely along the points."""
    rad = width / 2 * T.s
    for x, y in pts:
        X, Y = T(x, y)
        d.ellipse((X - rad, Y - rad, X + rad, Y + rad), fill=color)


def dashed(pts):
    """Splits a polyline into dashes of DASH units separated by GAP units."""
    out, run, dist, on = [], [pts[0]], 0.0, True
    for a, b in zip(pts, pts[1:]):
        dist += math.dist(a, b)
        if on:
            run.append(b)
        if on and dist >= DASH:
            out.append(run)
            on, dist = False, 0.0
        elif not on and dist >= GAP:
            on, dist, run = True, 0.0, [b]
    if on and len(run) > 1:
        out.append(run)
    return out


def mark(img, T, mono=False):
    d = ImageDraw.Draw(img)
    for seg in dashed(trail()):
        stamp(d, seg, TRAIL_W, WHITE if mono else CREAM, T)
    cx, cy, r = COIN
    X, Y = T(cx, cy)
    R = r * T.s
    if mono:
        d.ellipse((X - R, Y - R, X + R, Y + R), fill=WHITE)
    else:
        lift = R * 0.09
        d.ellipse((X - R, Y - R + lift, X + R, Y + R + lift), fill=GOLD_DARK)
        d.ellipse((X - R, Y - R, X + R, Y + R), fill=GOLD)
    # In the one-colour versions the $ is cut out of the coin.
    for s in dollar_strokes(cx, cy, DOLLAR_K):
        stamp(d, s, DOLLAR_W, CLEAR if mono else CREAM, T)


def render(size, bg=True, mono=False, scale=0.80, rounded=True):
    S = size * SS
    img = Image.new("RGBA", (S, S), CLEAR)
    if bg:
        d = ImageDraw.Draw(img)
        if rounded:
            d.rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22), fill=GREEN)
        else:
            d.rectangle((0, 0, S, S), fill=GREEN)
        # Soft diagonal shade in the lower-right corner, clipped to the tile.
        shade = Image.new("RGBA", (S, S), CLEAR)
        ImageDraw.Draw(shade).polygon([(S, int(S * 0.45)), (S, S), (int(S * 0.45), S)], fill=GREEN_DARK[:3] + (150,))
        clip = Image.new("L", (S, S), 0)
        ImageDraw.Draw(clip).rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22) if rounded else 0, fill=255)
        shade.putalpha(Image.composite(shade.getchannel("A"), Image.new("L", (S, S), 0), clip))
        img = Image.alpha_composite(img, shade)
    box = S * scale
    mark(img, Transform((S - box) / 2, (S - box) / 2, box), mono=mono)
    return img.resize((size, size), Image.LANCZOS)


render(1024).save(os.path.join(OUT, "icon.png"))
render(512).save(os.path.join(OUT, "logo-512.png"))
# Adaptive layers: 108dp canvas, safe zone is the central 66dp circle.
render(1024, bg=False, scale=0.64).save(os.path.join(OUT, "foreground.png"))
render(1024, bg=False, mono=True, scale=0.64).save(os.path.join(OUT, "monochrome.png"))

densities = {"drawable-mdpi": 1, "drawable-hdpi": 1.5, "drawable-xhdpi": 2, "drawable-xxhdpi": 3, "drawable-xxxhdpi": 4}
for folder, k in densities.items():
    os.makedirs(os.path.join(RES, folder), exist_ok=True)
    # Launch screen (Android < 12): the artwork on the green window background.
    render(int(120 * k), bg=False, scale=0.9).save(os.path.join(RES, folder, "splash_logo.png"))
    # Notification icon: white silhouette filling the 24 dp square.
    render(int(24 * k), bg=False, mono=True, scale=1.0).save(os.path.join(RES, folder, "ic_stat_carnet.png"))

print("ok")
