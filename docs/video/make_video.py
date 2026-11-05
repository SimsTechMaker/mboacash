"""Builds the 45 s presentation video (1080x1920, 30 fps) of my-nkap.

1. flutter test docs/video/capture_test.dart with CAPTURE_OUT=<work folder>
2. python docs/video/make_video.py <project> <work folder> <output.mp4>

Screens come from the capture step, with made-up data. The music is
synthesised here, so there is no rights question.
"""
import math
import os
import subprocess
import sys
import wave

import fitz
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

PROJECT, WORK, OUT = sys.argv[1:4]
W, H, FPS, DURATION = 1080, 1920, 30, 45
FONT = lambda name, size: ImageFont.truetype(os.path.join(PROJECT, "assets", "fonts", f"IBMPlexSans-{name}.ttf"), size)
CREAM = (247, 244, 236, 255)
GOLD = (232, 163, 61, 255)
SOFT = (207, 227, 219, 255)


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ease(x):
    x = clamp(x)
    return 1 - (1 - x) ** 3


def ease_io(x):
    x = clamp(x)
    return x * x * (3 - 2 * x)


def background():
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    t = (x / W * 0.35 + y / H * 0.65)[..., None]
    top, bottom = np.array([29, 106, 86], np.float32), np.array([10, 42, 34], np.float32)
    rgb = top * (1 - t) + bottom * t
    return Image.fromarray(np.dstack([rgb, np.full((H, W), 255, np.float32)]).astype(np.uint8), "RGBA")


BG = background()


def fade(layer, alpha):
    """[layer] with its opacity multiplied by [alpha]."""
    if alpha >= 1:
        return layer
    out = layer.copy()
    out.putalpha(out.getchannel("A").point(lambda v: int(v * alpha)))
    return out


def wrap(text, font, width):
    lines, cur = [], ""
    for word in text.split(" "):
        test = f"{cur} {word}".strip()
        if font.getlength(test) <= width:
            cur = test
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def text_layer(text, size, color, weight="SemiBold", width=940, spacing=1.22):
    """Centred text on a transparent layer as wide as the video."""
    font = FONT(weight, size)
    lines = wrap(text, font, width)
    step = int(size * spacing)
    img = Image.new("RGBA", (W, step * len(lines) + int(size * 0.4)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, line in enumerate(lines):
        d.text((W / 2, i * step), line, font=font, fill=color, anchor="ma")
    return img


# ---------------------------------------------------------------- the logo

def load_logo():
    src = open(os.path.join(PROJECT, "docs", "logo", "make_logo.py"), encoding="utf-8").read()
    src = src[: src.index('render(1024).save(')]
    ns = {"__name__": "logo"}
    argv, sys.argv = sys.argv, ["make_logo.py", PROJECT]
    exec(compile(src, "make_logo.py", "exec"), ns)
    sys.argv = argv
    return ns


LOGO = load_logo()


def logo_parts(size):
    """The mark as separate layers: each dash of the trail, then the coin."""
    S = size * 2
    T = LOGO["Transform"](0, 0, S)
    parts = []
    for seg in LOGO["dashed"](LOGO["trail"]()):
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        LOGO["stamp"](ImageDraw.Draw(img), seg, LOGO["TRAIL_W"], CREAM, T)
        parts.append(img.resize((size, size), Image.LANCZOS))
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy, r = LOGO["COIN"]
    X, Y = T(cx, cy)
    R = r * T.s
    d.ellipse((X - R, Y - R + R * 0.09, X + R, Y + R + R * 0.09), fill=LOGO["GOLD_DARK"])
    d.ellipse((X - R, Y - R, X + R, Y + R), fill=LOGO["GOLD"])
    for stroke in LOGO["dollar_strokes"](cx, cy, LOGO["DOLLAR_K"]):
        LOGO["stamp"](d, stroke, LOGO["DOLLAR_W"], CREAM, T)
    return parts, img.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------- the phone

SCREEN_W, TOP, BEZEL, BAR, STATUS = 680, 470, 16, 103, 44
SCALE = SCREEN_W / 1080
SCREEN_H = H - TOP - BEZEL + 40


def status_bar():
    img = Image.new("RGBA", (SCREEN_W, STATUS), (246, 245, 240, 255))
    ImageDraw.Draw(img).text((34, STATUS / 2 + 4), "9:41", font=FONT("SemiBold", 22), fill=(30, 40, 36, 255), anchor="lm")
    return img


def phone_shell():
    w, h = SCREEN_W + 2 * BEZEL, SCREEN_H + 2 * BEZEL
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((0, 0, w - 1, h - 1), 62, fill=(12, 18, 16, 255))
    return img


def shadow():
    w, h = SCREEN_W + 2 * BEZEL, SCREEN_H + 2 * BEZEL
    img = Image.new("RGBA", (w + 160, h + 160), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((80, 90, w + 80, h + 90), 62, fill=(0, 0, 0, 130))
    return img.filter(ImageFilter.GaussianBlur(36))


SHELL, SHADOW, STATUS_IMG = phone_shell(), shadow(), status_bar()
MASK = Image.new("L", (SCREEN_W, SCREEN_H), 0)
ImageDraw.Draw(MASK).rounded_rectangle((0, 0, SCREEN_W - 1, SCREEN_H - 1), 48, fill=255)


def load_screen(name):
    img = Image.open(os.path.join(WORK, name + ".png")).convert("RGBA")
    return img.resize((SCREEN_W, int(img.height * SCALE)), Image.LANCZOS)


def phone(screen, scroll, ring=None, ring_a=0.0):
    """The phone with [screen] scrolled by [scroll] px; the app bar stays put."""
    view = Image.new("RGBA", (SCREEN_W, SCREEN_H), screen.getpixel((6, BAR + 6)))
    y0 = int(scroll)
    body = screen.crop((0, BAR + y0, SCREEN_W, min(screen.height, BAR + y0 + SCREEN_H)))
    view.paste(body, (0, STATUS + BAR))
    view.paste(screen.crop((0, 0, SCREEN_W, BAR)), (0, STATUS))
    view.paste(STATUS_IMG, (0, 0))
    if ring and ring_a > 0:
        x0, ya, x1, yb = [v * SCALE for v in ring]
        layer = Image.new("RGBA", view.size, (0, 0, 0, 0))
        grow = 6 * math.sin(ring_a * math.pi)
        ImageDraw.Draw(layer).rounded_rectangle(
            (x0 - grow, ya - y0 + STATUS - grow, x1 + grow, yb - y0 + STATUS + grow), 20, outline=GOLD, width=6
        )
        view.alpha_composite(fade(layer, clamp(ring_a * 4) * clamp((1 - ring_a) * 4)))
    out = SHELL.copy()
    out.paste(view, (BEZEL, BEZEL), MASK)
    return out


# ---------------------------------------------------------------- scenes

SCENES = [
    # start, end, screen, title, subtitle, scroll, ring, ring window
    (4.6, 11.0, "home", "Note tout. Vois tout.", "Ton solde, tes dépenses et ta prévision en un coup d'œil.", 640, None, None),
    (11.0, 18.0, "periods", "Ta période, ton rythme", "Ce qui te reste passe à la suivante, jamais à zéro.", 0, (60, 470, 530, 640), (2.0, 5.6)),
    (18.0, 24.4, "accounts", "L'épargne, à part", "L'argent utilisable d'un côté, ton épargne de l'autre.", 1120, (70, 225, 720, 425), (1.0, 3.0)),
    (24.4, 30.4, "agenda", "Rien n'est oublié", "Loyer, tontine, internet : programme, puis confirme.", 280, None, None),
    (30.4, 36.6, "summary", "Comprends ton argent", "Quand tu dépenses le plus, tes habitudes, tes petites dépenses.", 330, None, None),
]
LAYERS = {s[2]: (load_screen(s[2]), text_layer(s[3], 74, CREAM, "Bold"), text_layer(s[4], 40, SOFT, "Regular", width=880)) for s in SCENES}


def scene(frame, t, s):
    start, end, name, _, _, scroll, ring, window = s
    screen, title, sub = LAYERS[name]
    local, length = t - start, end - start
    out = ease(1 - (end - t) / 0.35) if end - t < 0.35 else 0
    alpha = clamp(local / 0.35) * (1 - out)
    frame.alpha_composite(fade(title, alpha), (0, 120 + int((1 - ease(local / 0.6)) * 30)))
    frame.alpha_composite(fade(sub, clamp((local - 0.2) / 0.4) * (1 - out)), (0, 225 + int((1 - ease((local - 0.2) / 0.6)) * 30)))
    rise = (1 - ease(local / 0.8)) * 900 + out * 120
    pos = ease_io((local - 1.6) / (length - 2.4)) * scroll
    ring_a = 0.0
    if ring:
        a, b = window
        ring_a = clamp((local - a) / (b - a)) if a <= local <= b else 0.0
    device = phone(screen, pos, ring, ring_a)
    x = (W - device.width) // 2
    y = TOP + int(rise)
    frame.alpha_composite(fade(SHADOW, 1 - out), (x - 80, y - 80))
    frame.alpha_composite(fade(device, 1 - out), (x, y))


def statement_page():
    doc = fitz.open(os.path.join(WORK, "statement.pdf"))
    px = doc[0].get_pixmap(dpi=120)
    img = Image.frombytes("RGB", (px.width, px.height), px.samples).convert("RGBA")
    img = img.resize((720, int(img.height * 720 / img.width)), Image.LANCZOS)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), 18, fill=255)
    img.putalpha(mask)
    return img


PDF = statement_page()
PDF_T = text_layer("Ton relevé PDF, prêt à imprimer", 66, CREAM, "Bold")
PDF_S = text_layer("Par mois, par période ou par compte.", 40, SOFT, "Regular")


def pdf_scene(frame, t):
    start, end = 36.6, 40.6
    local = t - start
    out = ease(1 - (end - t) / 0.35) if end - t < 0.35 else 0
    a = clamp(local / 0.35) * (1 - out)
    frame.alpha_composite(fade(PDF_T, a), (0, 130))
    frame.alpha_composite(fade(PDF_S, a), (0, 320))
    zoom = 1 + 0.06 * local / (end - start)
    page = PDF.resize((int(PDF.width * zoom), int(PDF.height * zoom)), Image.BILINEAR)
    page = page.rotate(-2.5 + 2.5 * ease(local / 1.2), expand=True, resample=Image.BICUBIC)
    y = 450 + int((1 - ease(local / 0.8)) * 500)
    frame.alpha_composite(fade(page, 1 - out), ((W - page.width) // 2, y))


# Intro and closing cards.
MARK_SIZE = 640
DASHES, COIN = logo_parts(MARK_SIZE)
NAME = text_layer("my-nkap", 120, CREAM, "Bold")
TAGLINE = text_layer("Où va mon argent ?", 56, GOLD, "SemiBold")
FACTS = text_layer("Hors ligne · Sans publicité · Français et English", 38, CREAM, "Medium")
PRIVATE = text_layer("Tes données restent sur ton téléphone.", 42, SOFT, "Regular")


def mark(frame, y, t0, t):
    """The trail draws itself, then the coin lands as the question mark's dot."""
    x = (W - MARK_SIZE) // 2
    for i, dash in enumerate(DASHES):
        a = clamp((t - t0 - i * 0.26) / 0.22)
        if a > 0:
            frame.alpha_composite(fade(dash, a), (x, y))
    tc = t - t0 - len(DASHES) * 0.26
    if tc > 0:
        fall = clamp(tc / 0.5)
        drop = (1 - fall**2) * -240
        bounce = math.exp(-6 * max(tc - 0.5, 0)) * math.sin(max(tc - 0.5, 0) * 16) * 22 if tc > 0.5 else 0
        frame.alpha_composite(fade(COIN, clamp(tc / 0.15)), (x, y + int(drop - abs(bounce))))


def intro(frame, t):
    out = ease(1 - (4.6 - t) / 0.4) if t > 4.2 else 0
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mark(layer, 360, 0.2, t)
    layer.alpha_composite(fade(NAME, clamp((t - 2.3) / 0.5)), (0, 1080 + int((1 - ease((t - 2.3) / 0.6)) * 30)))
    layer.alpha_composite(fade(TAGLINE, clamp((t - 2.8) / 0.5)), (0, 1240 + int((1 - ease((t - 2.8) / 0.6)) * 30)))
    frame.alpha_composite(fade(layer, 1 - out))


def outro(frame, t):
    local = t - 40.6
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    mark(layer, 290, -2.0, 0)
    mark_layer = layer
    frame.alpha_composite(fade(mark_layer, clamp(local / 0.5)))
    frame.alpha_composite(fade(NAME, clamp((local - 0.2) / 0.5)), (0, 990))
    frame.alpha_composite(fade(TAGLINE, clamp((local - 0.4) / 0.5)), (0, 1150))
    frame.alpha_composite(fade(PRIVATE, clamp((local - 0.9) / 0.5)), (0, 1300))
    frame.alpha_composite(fade(FACTS, clamp((local - 1.3) / 0.5)), (0, 1385))


def render_frame(n):
    t = n / FPS
    frame = BG.copy()
    if t < 4.6:
        intro(frame, t)
    elif t < 36.6:
        for s in SCENES:
            if s[0] <= t < s[1]:
                scene(frame, t, s)
    elif t < 40.6:
        pdf_scene(frame, t)
    else:
        outro(frame, t)
    # Fade in from and out to dark.
    edge = min(clamp(t / 0.4), clamp((DURATION - t) / 0.6))
    if edge < 1:
        frame = Image.blend(Image.new("RGBA", (W, H), (6, 24, 20, 255)), frame, edge)
    return frame.convert("RGB")


# ---------------------------------------------------------------- the music

def music(path):
    sr = 44100
    n = sr * DURATION
    out = np.zeros(n, np.float32)
    beat = 60 / 100
    note = lambda m: 440 * 2 ** ((m - 69) / 12)
    chords = [(57, 60, 64), (53, 57, 60), (48, 55, 64), (55, 59, 62)]  # Am F C G

    def add(start, sound):
        i = int(start * sr)
        j = min(n, i + len(sound))
        if i < n:
            out[i:j] += sound[: j - i]

    def pad(freq, length):
        t = np.arange(int(length * sr)) / sr
        env = np.minimum(t / 0.5, 1) * np.minimum((length - t) / 0.6, 1)
        return (np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * freq * 2.003 * t)) * env * 0.05

    def pluck(freq, gain=0.16):
        t = np.arange(int(0.7 * sr)) / sr
        return (np.sin(2 * np.pi * freq * t) + 0.5 * np.sin(2 * np.pi * freq * 3 * t) * np.exp(-t * 18)) * np.exp(-t * 7) * gain

    def kick():
        t = np.arange(int(0.25 * sr)) / sr
        return np.sin(2 * np.pi * (46 + 70 * np.exp(-t * 30)) * t) * np.exp(-t * 16) * 0.32

    def shaker(gain):
        t = np.arange(int(0.07 * sr)) / sr
        rng = np.random.default_rng(int(gain * 1000))
        return rng.standard_normal(len(t)) * np.exp(-t * 70) * gain

    bar = beat * 4
    pattern = [0, 2, 1, 2, 0, 1, 2, 1]
    for b in range(int(DURATION / bar) + 1):
        chord = chords[b % 4]
        start = b * bar
        for m in chord:
            add(start, pad(note(m), bar + 0.5))
        add(start, pad(note(chord[0] - 12), bar + 0.5) * 1.6)
        if start >= 2.4:
            for k, idx in enumerate(pattern):
                add(start + k * beat / 2, pluck(note(chord[idx] + 12), 0.12 + 0.05 * (k % 4 == 0)))
        if start >= 4.6 and start < 40.6:
            for k in range(4):
                add(start + k * beat, kick())
                add(start + k * beat + beat / 2, shaker(0.05))
                add(start + k * beat + beat * 0.75, shaker(0.03))
    t = np.arange(n) / sr
    out *= np.clip(t / 1.0, 0, 1) * np.clip((DURATION - t) / 2.5, 0, 1)
    out = out / np.max(np.abs(out)) * 0.8
    pcm = (out * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())


def main():
    if len(sys.argv) > 4:  # still frames at the given times, to check the layout
        for s in sys.argv[4:]:
            render_frame(int(float(s) * FPS)).save(os.path.join(WORK, f"frame_{s}.png"))
        return
    wav = os.path.join(WORK, "music.wav")
    music(wav)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    p = subprocess.Popen(
        ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}", "-r", str(FPS), "-i", "-", "-i", wav,
         "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", "-shortest", OUT],
        stdin=subprocess.PIPE,
    )
    for n in range(FPS * DURATION):
        p.stdin.write(render_frame(n).tobytes())
        if n % 150 == 0:
            print(n, flush=True)
    p.stdin.close()
    p.wait()
    print("done", p.returncode)


main()
