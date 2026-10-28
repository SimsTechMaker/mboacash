"""Draws the carnet237 logo: a cream notebook with ring binding, "237" on the
cover and an orange bookmark, on the app's ledger green.

Outputs (in <project>/assets/icon/ and android res/drawable-*/):
  icon.png             1024 full icon (rounded square) for legacy launchers
  foreground.png       1024 adaptive foreground (transparent, safe zone)
  monochrome.png       1024 Android 13 themed icon silhouette
  logo-512.png         512 store/branding icon
  ic_stat_carnet.png   white notification silhouettes at each density
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

PROJECT = sys.argv[1]
FONT = os.path.join(PROJECT, "assets", "fonts", "IBMPlexSans-Bold.ttf")
OUT = os.path.join(PROJECT, "assets", "icon")
RES = os.path.join(PROJECT, "android", "app", "src", "main", "res")
os.makedirs(OUT, exist_ok=True)

GREEN = (29, 106, 86, 255)
GREEN_DARK = (19, 76, 61, 255)
CREAM = (247, 244, 236, 255)
PAGE = (226, 221, 207, 255)
ORANGE = (217, 130, 43, 255)
SS = 4  # supersampling factor for smooth edges


def notebook(draw, cx, cy, w, h, s, mono=False, text=True):
    """Notebook centred on (cx, cy), size w x h, in supersampled pixels."""
    x0, y0, x1, y1 = cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2
    r = int(w * 0.09)
    fg = (255, 255, 255, 255) if mono else CREAM
    # Page edges peeking out on the right, then the cover.
    if not mono:
        draw.rounded_rectangle((x0 + int(w * 0.05), y0 + int(h * 0.025), x1 + int(w * 0.035), y1 - int(h * 0.025)), r, fill=PAGE)
    draw.rounded_rectangle((x0, y0, x1, y1), r, fill=fg)
    # Spine band and binder rings.
    spine = int(w * 0.17)
    hole = (0, 0, 0, 0) if mono else GREEN
    if not mono:
        draw.rounded_rectangle((x0, y0, x0 + spine, y1), r, fill=(232, 228, 216, 255))
        draw.rectangle((x0 + spine - int(w * 0.012), y0, x0 + spine, y1), fill=(214, 208, 192, 255))
    ring_r = int(w * 0.04)
    for k in range(4):
        ry = y0 + int(h * (0.2 + k * 0.2))
        rx = x0 + spine // 2
        draw.ellipse((rx - ring_r, ry - ring_r, rx + ring_r, ry + ring_r), fill=hole)
    # Bookmark ribbon hanging from the top edge.
    bx = x1 - int(w * 0.24)
    bw = int(w * 0.12)
    ribbon = (0, 0, 0, 0) if mono else ORANGE
    by1 = y0 + int(h * 0.26)
    draw.polygon([(bx, y0), (bx + bw, y0), (bx + bw, by1), (bx + bw // 2, by1 - int(bw * 0.55)), (bx, by1)], fill=ribbon)
    if text:
        size = int(w * 0.36)
        font = ImageFont.truetype(FONT, size)
        label = "237"
        l, t, rr, b = draw.textbbox((0, 0), label, font=font)
        tx = x0 + spine + (w - spine - (rr - l)) // 2 - l
        ty = cy + int(h * 0.08) - (b - t) // 2 - t
        draw.text((tx, ty), label, font=font, fill=(0, 0, 0, 0) if mono else GREEN)
        # Underline: a ledger rule under the number.
        uy = ty + b + int(h * 0.05)
        draw.rounded_rectangle((tx + l, uy, tx + rr, uy + int(h * 0.022)), int(h * 0.011), fill=(0, 0, 0, 0) if mono else ORANGE)


def render(size, bg=True, mono=False, scale=0.62, text=True, rounded=True):
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if bg:
        if rounded:
            d.rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22), fill=GREEN)
        else:
            d.rectangle((0, 0, S, S), fill=GREEN)
        # Soft diagonal shade in the lower-right corner, clipped to the tile.
        shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(shade).polygon([(S, int(S * 0.45)), (S, S), (int(S * 0.45), S)], fill=GREEN_DARK[:3] + (150,))
        clip = Image.new("L", (S, S), 0)
        ImageDraw.Draw(clip).rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22) if rounded else 0, fill=255)
        shade.putalpha(Image.composite(shade.getchannel("A"), Image.new("L", (S, S), 0), clip))
        img = Image.alpha_composite(img, shade)
        d = ImageDraw.Draw(img)
    w = int(S * scale * 0.80)
    h = int(S * scale)
    notebook(d, S // 2 - int(S * 0.01), S // 2, w, h, SS, mono=mono, text=text)
    return img.resize((size, size), Image.LANCZOS)


render(1024).save(os.path.join(OUT, "icon.png"))
render(512).save(os.path.join(OUT, "logo-512.png"))
# Adaptive layers: 108dp canvas, safe zone is the central 66dp circle.
render(1024, bg=False, scale=0.50).save(os.path.join(OUT, "foreground.png"))
render(1024, bg=False, mono=True, scale=0.50).save(os.path.join(OUT, "monochrome.png"))

# Notification icon: white silhouette, no text (unreadable at 24 px).
for folder, px in {"drawable-mdpi": 24, "drawable-hdpi": 36, "drawable-xhdpi": 48, "drawable-xxhdpi": 72, "drawable-xxxhdpi": 96}.items():
    os.makedirs(os.path.join(RES, folder), exist_ok=True)
    render(px, bg=False, mono=True, scale=0.92, text=False).save(os.path.join(RES, folder, "ic_stat_carnet.png"))

print("ok")
