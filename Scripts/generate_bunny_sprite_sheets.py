#!/usr/bin/env python3
"""Generate bunny cosmetic sprite sheets and transparent layer PNGs.

This follows the original cosmetic asset list, but redraws the character in the
provided bunny-emotes style: cream fill, chunky rough dark outline, tall ears,
and tiny hand-drawn facial marks.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "GeneratedAssets" / "BunnySprites"
LAYERS = OUT / "layers"
PREVIEWS = OUT / "previews"
SHEETS = OUT / "contact_sheets"

CANVAS = 1024
AA = 4
W = CANVAS * AA

INK = "#120807"
BUNNY = "#FFFCF4"
CREAM = "#FFF7DF"
PINK = "#FF5C91"
BLUE = "#64CFF6"
YELLOW = "#FFC436"
GREEN = "#63E11A"
RED = "#FF4C45"
PURPLE = "#7D8AC4"
GREY = "#8E9185"
GOLD = "#E0B137"
SILVER = "#E8E8F0"
BROWN = "#3A221A"
CHARCOAL = "#20202A"

STROKE = 34 * AA
THIN = 16 * AA


def c(v: float) -> int:
    return round(v * W)


def pt(x: float, y: float) -> tuple[int, int]:
    return c(x), c(y)


def box(cx: float, cy: float, w: float, h: float) -> tuple[int, int, int, int]:
    return c(cx - w / 2), c(cy - h / 2), c(cx + w / 2), c(cy + h / 2)


def new_canvas() -> Image.Image:
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))


def downsample(img: Image.Image) -> Image.Image:
    return img.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)


def cubic(
    p0: tuple[float, float],
    p1: tuple[float, float],
    p2: tuple[float, float],
    p3: tuple[float, float],
    steps: int = 24,
) -> list[tuple[float, float]]:
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def bunny_outline() -> list[tuple[float, float]]:
    pts: list[tuple[float, float]] = []
    segments = [
        ((0.500, 0.905), (0.345, 0.905), (0.230, 0.850), (0.210, 0.705)),
        ((0.210, 0.705), (0.185, 0.570), (0.175, 0.380), (0.155, 0.190)),
        ((0.155, 0.190), (0.145, 0.070), (0.205, 0.040), (0.245, 0.060)),
        ((0.245, 0.060), (0.310, 0.085), (0.320, 0.235), (0.306, 0.412)),
        ((0.306, 0.412), (0.365, 0.430), (0.425, 0.430), (0.486, 0.412)),
        ((0.486, 0.412), (0.470, 0.230), (0.486, 0.075), (0.555, 0.052)),
        ((0.555, 0.052), (0.615, 0.035), (0.665, 0.085), (0.655, 0.190)),
        ((0.655, 0.190), (0.635, 0.390), (0.622, 0.565), (0.790, 0.705)),
        ((0.790, 0.705), (0.770, 0.850), (0.655, 0.905), (0.500, 0.905)),
    ]
    for seg in segments:
        part = cubic(*seg)
        pts.extend(part if not pts else part[1:])
    return pts


def draw_rough_line(
    draw: ImageDraw.ImageDraw,
    points: Iterable[tuple[float, float]],
    fill: str = INK,
    width: int = STROKE,
    closed: bool = False,
) -> None:
    scaled = [pt(x, y) for x, y in points]
    if closed:
        scaled.append(scaled[0])
    draw.line(scaled, fill=fill, width=width, joint="curve")
    for offset, alpha_width in [((-0.003, 0.002), int(width * 0.34)), ((0.003, -0.002), int(width * 0.22))]:
        shifted = [pt(x + offset[0], y + offset[1]) for x, y in points]
        if closed:
            shifted.append(shifted[0])
        draw.line(shifted, fill=fill, width=alpha_width, joint="curve")


def draw_poly(draw: ImageDraw.ImageDraw, points: Iterable[tuple[float, float]], fill: str, width: int = STROKE) -> None:
    pts = list(points)
    draw.polygon([pt(x, y) for x, y in pts], fill=fill)
    draw_rough_line(draw, pts, INK, width, closed=True)


def draw_ellipse(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    w: float,
    h: float,
    fill: str,
    outline: str = INK,
    width: int = STROKE,
) -> None:
    draw.ellipse(box(cx, cy, w, h), fill=fill, outline=outline, width=width)


def draw_circle(draw: ImageDraw.ImageDraw, cx: float, cy: float, d: float, fill: str, width: int = STROKE) -> None:
    draw_ellipse(draw, cx, cy, d, d, fill, INK, width)


def draw_arc_line(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    a0: float,
    a1: float,
    fill: str = INK,
    width: int = THIN,
    steps: int = 28,
) -> None:
    pts = []
    for i in range(steps + 1):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        pts.append((cx + rx * math.cos(a), cy + ry * math.sin(a)))
    draw_rough_line(draw, pts, fill, width)


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    w: float,
    h: float,
    radius: float,
    fill: str,
    width: int = STROKE,
) -> None:
    draw.rounded_rectangle(box(cx, cy, w, h), radius=c(radius), fill=fill, outline=INK, width=width)


def alpha_paste(base: Image.Image, layer: Image.Image) -> None:
    base.alpha_composite(layer)


def clear_face_hole(img: Image.Image) -> None:
    mask_draw = ImageDraw.Draw(img)
    mask_draw.polygon([pt(x, y) for x, y in bunny_outline()], fill=(0, 0, 0, 0))


def draw_base(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    outline = bunny_outline()
    d.polygon([pt(x, y) for x, y in outline], fill=BUNNY)
    draw_rough_line(d, outline, INK, STROKE, closed=True)
    draw_ellipse(d, 0.350, 0.618, 0.050, 0.050, INK, outline=INK, width=1)
    draw_ellipse(d, 0.585, 0.618, 0.050, 0.050, INK, outline=INK, width=1)
    draw_arc_line(d, 0.468, 0.715, 0.046, 0.036, 25, 158, INK, 13 * AA)
    draw_arc_line(d, 0.533, 0.715, 0.046, 0.036, 22, 155, INK, 13 * AA)


def hair_buzz(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.468, 0.430, 0.285, 0.105, 185, 355, BROWN, 36 * AA)
    draw_arc_line(d, 0.468, 0.432, 0.252, 0.082, 190, 350, BROWN, 28 * AA)
    for x in (0.35, 0.43, 0.51, 0.59):
        draw_rough_line(d, [(x - 0.025, 0.405), (x + 0.018, 0.392)], "#22120E", 7 * AA)


def hair_side(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.230, 0.445), (0.360, 0.335), (0.560, 0.365), (0.705, 0.455), (0.500, 0.455)], BROWN, 20 * AA)
    draw_rough_line(d, [(0.365, 0.342), (0.312, 0.460)], "#22120E", 9 * AA)


def hair_long(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.490, 0.605, 0.780, 0.640, BROWN, width=28 * AA)
    clear_face_hole(img)
    draw_poly(d, [(0.215, 0.450), (0.350, 0.335), (0.525, 0.455)], BROWN, 20 * AA)
    draw_poly(d, [(0.430, 0.455), (0.580, 0.330), (0.750, 0.455)], BROWN, 20 * AA)


def hair_dreads(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x, y, h in ((0.205, 0.545, 0.32), (0.265, 0.520, 0.28), (0.325, 0.500, 0.22), (0.690, 0.545, 0.31), (0.745, 0.515, 0.24)):
        rounded_rect(d, x, y, 0.060, h, 0.030, BROWN, 18 * AA)
    draw_arc_line(d, 0.470, 0.430, 0.305, 0.110, 185, 355, BROWN, 32 * AA)


def hair_afro(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x, y, dia in (
        (0.250, 0.350, 0.210), (0.360, 0.255, 0.240), (0.500, 0.235, 0.260),
        (0.630, 0.285, 0.235), (0.720, 0.410, 0.210), (0.235, 0.500, 0.190),
    ):
        draw_circle(d, x, y, dia, BROWN, 18 * AA)
    clear_face_hole(img)


def hair_spikes(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.470, 0.445, 0.300, 0.075, 185, 355, CHARCOAL, 38 * AA)
    for x, top in ((0.265, 0.235), (0.355, 0.170), (0.460, 0.135), (0.565, 0.180), (0.665, 0.255)):
        draw_poly(d, [(x, top), (x + 0.055, 0.400), (x - 0.060, 0.400)], CHARCOAL, 18 * AA)


def hair_mohawk(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.465, 0.110), (0.555, 0.455), (0.375, 0.455)], CHARCOAL, 20 * AA)
    draw_poly(d, [(0.465, 0.165), (0.520, 0.430), (0.410, 0.430)], "#E14250", 10 * AA)


def hat_cap(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.470, 0.430, 0.335, 0.125, 185, 355, "#2566B5", 54 * AA)
    rounded_rect(d, 0.640, 0.430, 0.330, 0.060, 0.035, "#3A87D5", 15 * AA)


def hat_beanie(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.470, 0.425, 0.325, 0.130, 185, 355, "#A4414B", 58 * AA)
    rounded_rect(d, 0.470, 0.448, 0.575, 0.065, 0.035, "#853642", 15 * AA)
    for x in (0.36, 0.47, 0.58):
        draw_rough_line(d, [(x, 0.310), (x, 0.430)], "#7A3038", 6 * AA)


def hat_visor(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    rounded_rect(d, 0.470, 0.420, 0.460, 0.065, 0.035, "#279060", 15 * AA)
    rounded_rect(d, 0.640, 0.430, 0.320, 0.055, 0.030, "#3FBF83", 13 * AA)


def hat_headphones(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.470, 0.390, 0.355, 0.330, 202, 338, CHARCOAL, 30 * AA)
    for x in (0.145, 0.795):
        rounded_rect(d, x, 0.485, 0.105, 0.165, 0.030, CHARCOAL, 15 * AA)
        rounded_rect(d, x, 0.485, 0.060, 0.105, 0.020, "#5B6270", 1)


def hat_top(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    rounded_rect(d, 0.470, 0.365, 0.540, 0.065, 0.030, CHARCOAL, 15 * AA)
    rounded_rect(d, 0.470, 0.220, 0.330, 0.270, 0.025, CHARCOAL, 15 * AA)
    rounded_rect(d, 0.470, 0.292, 0.330, 0.052, 0.010, "#A33140", 1)


def hat_crown(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.240, 0.455), (0.240, 0.265), (0.340, 0.355), (0.440, 0.220), (0.535, 0.355), (0.660, 0.265), (0.660, 0.455)], GOLD, 17 * AA)
    for x, y in ((0.240, 0.265), (0.440, 0.220), (0.660, 0.265)):
        draw_circle(d, x, y, 0.035, "#F7D95A", 6 * AA)


def face_stubble(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x, y in ((0.405, 0.695), (0.455, 0.742), (0.510, 0.760), (0.560, 0.724), (0.590, 0.682)):
        draw_ellipse(d, x, y, 0.018, 0.018, INK, outline=INK, width=1)


def face_moustache(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.458, 0.715, 0.115, 0.055, BROWN, outline=BROWN, width=1)
    draw_ellipse(d, 0.540, 0.715, 0.115, 0.055, BROWN, outline=BROWN, width=1)


def face_goatee(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.500, 0.780, 0.125, 0.105, BROWN, width=13 * AA)


def face_chops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.250, 0.745):
        rounded_rect(d, x, 0.645, 0.090, 0.230, 0.035, BROWN, 14 * AA)


def face_beard(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.500, 0.755, 0.470, 0.270, BROWN, width=18 * AA)
    draw_ellipse(d, 0.500, 0.715, 0.260, 0.135, BUNNY, outline=BUNNY, width=1)


def ear_studs(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.188, 0.795):
        draw_circle(d, x, 0.510, 0.045, SILVER, 7 * AA)


def ear_hoops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.190, 0.792):
        draw_ellipse(d, x, 0.535, 0.072, 0.090, (0, 0, 0, 0), outline=GOLD, width=9 * AA)


def ear_drops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.190, 0.792):
        draw_circle(d, x, 0.500, 0.032, GOLD, 6 * AA)
        rounded_rect(d, x, 0.560, 0.035, 0.070, 0.018, GOLD, 6 * AA)


def chain_thin(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_arc_line(d, 0.500, 0.870, 0.210, 0.065, 20, 160, GOLD, 10 * AA)


def chain_cuban(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for deg in range(24, 158, 15):
        x = 0.500 + 0.210 * math.cos(math.radians(deg))
        y = 0.870 + 0.065 * math.sin(math.radians(deg))
        draw_ellipse(d, x, y, 0.075, 0.035, GOLD, width=7 * AA)


def chain_pendant(img: Image.Image) -> None:
    chain_thin(img)
    d = ImageDraw.Draw(img)
    draw_circle(d, 0.500, 0.935, 0.090, GOLD, 7 * AA)


ASSETS: dict[str, Callable[[Image.Image], None]] = {
    "base.bunny": lambda img: draw_base(img),
    "hair.buzz": hair_buzz,
    "hair.side": hair_side,
    "hair.long": hair_long,
    "hair.dreads": hair_dreads,
    "hair.afro": hair_afro,
    "hair.spikes": hair_spikes,
    "hair.mohawk": hair_mohawk,
    "hat.cap": hat_cap,
    "hat.beanie": hat_beanie,
    "hat.visor": hat_visor,
    "hat.headphones": hat_headphones,
    "hat.top": hat_top,
    "hat.crown": hat_crown,
    "face.stubble": face_stubble,
    "face.moustache": face_moustache,
    "face.goatee": face_goatee,
    "face.chops": face_chops,
    "face.beard": face_beard,
    "ear.studs": ear_studs,
    "ear.hoops": ear_hoops,
    "ear.drops": ear_drops,
    "chain.thin": chain_thin,
    "chain.cuban": chain_cuban,
    "chain.pendant": chain_pendant,
}


GROUPS: list[tuple[str, list[str], int]] = [
    ("sheet_1_base", ["base.bunny"], 1),
    ("sheet_2_hair", ["hair.buzz", "hair.side", "hair.long", "hair.dreads", "hair.afro", "hair.spikes", "hair.mohawk"], 4),
    ("sheet_3_headwear", ["hat.cap", "hat.beanie", "hat.visor", "hat.headphones", "hat.top", "hat.crown"], 3),
    ("sheet_4_facial_hair", ["face.stubble", "face.moustache", "face.goatee", "face.chops", "face.beard"], 3),
    ("sheet_5_earrings", ["ear.studs", "ear.hoops", "ear.drops"], 3),
    ("sheet_6_chains", ["chain.thin", "chain.cuban", "chain.pendant"], 3),
]


def draw_accessory(asset_id: str) -> Image.Image:
    img = new_canvas()
    ASSETS[asset_id](img)
    return downsample(img)


def draw_preview(asset_id: str) -> Image.Image:
    img = new_canvas()
    if asset_id == "base.bunny":
        draw_base(img)
    elif asset_id.startswith("chain."):
        ASSETS[asset_id](img)
        draw_base(img)
    elif asset_id.startswith("hair."):
        layer = new_canvas()
        ASSETS[asset_id](layer)
        alpha_paste(img, layer)
        draw_base(img)
        alpha_paste(img, layer)
    elif asset_id.startswith("face."):
        draw_base(img)
        ASSETS[asset_id](img)
    else:
        draw_base(img)
        ASSETS[asset_id](img)
    return downsample(img)


def font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_sheet(name: str, asset_ids: list[str], cols: int) -> None:
    label_h = 88
    rows = math.ceil(len(asset_ids) / cols)
    sheet = Image.new("RGBA", (cols * CANVAS, rows * (CANVAS + label_h)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    label_font = font(34)
    for i, asset_id in enumerate(asset_ids):
        row, col = divmod(i, cols)
        x = col * CANVAS
        y = row * (CANVAS + label_h)
        preview = Image.open(PREVIEWS / f"{asset_id}.png").convert("RGBA")
        thumb = 850
        preview = preview.resize((thumb, thumb), Image.Resampling.LANCZOS)
        sheet.alpha_composite(preview, (x + (CANVAS - thumb) // 2, y + 45))
        bbox = draw.textbbox((0, 0), asset_id, font=label_font)
        tx = x + (CANVAS - (bbox[2] - bbox[0])) / 2
        ty = y + CANVAS + 22
        draw.text((tx, ty), asset_id, font=label_font, fill=INK, stroke_width=4, stroke_fill=BUNNY)
    sheet.save(SHEETS / f"{name}.png")


def main() -> None:
    for folder in (LAYERS, PREVIEWS, SHEETS):
        folder.mkdir(parents=True, exist_ok=True)

    for asset_id in ASSETS:
        layer = draw_accessory(asset_id)
        layer.save(LAYERS / f"{asset_id}.png")
        preview = draw_preview(asset_id)
        preview.save(PREVIEWS / f"{asset_id}.png")

    for name, asset_ids, cols in GROUPS:
        make_sheet(name, asset_ids, cols)

    print(f"Wrote {len(ASSETS)} transparent layers to {LAYERS}")
    print(f"Wrote {len(GROUPS)} labeled contact sheets to {SHEETS}")


if __name__ == "__main__":
    main()
