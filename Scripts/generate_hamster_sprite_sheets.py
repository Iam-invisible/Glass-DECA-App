#!/usr/bin/env python3
"""Generate hamster cosmetic sprite sheets and transparent layer PNGs.

The artwork is intentionally vector-like and deterministic: all coordinates
use the same normalized 0..1 geometry as HamsterAvatar.swift so accessories
register against the existing app hamster without manual nudging.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "GeneratedAssets" / "HamsterSprites"
LAYERS = OUT / "layers"
PREVIEWS = OUT / "previews"
SHEETS = OUT / "contact_sheets"

CANVAS = 1024
AA = 4
W = CANVAS * AA
STROKE = 14 * AA


INK = "#704636"
FUR = "#F6C993"
FUR_DARK = "#B87545"
INNER_EAR = "#E64E69"
MUZZLE = "#F6C993"
BLUSH = "#EC6F82"
NOSE = "#704636"
WHITE = "#FFFFFF"
GOLD = "#D4AF37"
SILVER = "#E4E4EE"
SHIRT = "#F39A25"
SHIRT_DARK = "#B6662D"
SASH = "#1E9DD0"
MOUTH = "#D94D62"
TONGUE = "#F59AA5"
TILE_BORDER = "#EFFFF0"
TILE_COLORS = [
    "#F59B2F", "#7FD95B", "#23B8D8", "#EF6DA1", "#BCEB35",
    "#6F91CE", "#F4813C", "#A989D6", "#2ECAC5", "#E84E67",
]


def c(v: float) -> int:
    return round(v * W)


def box(cx: float, cy: float, w: float, h: float) -> tuple[int, int, int, int]:
    return (c(cx - w / 2), c(cy - h / 2), c(cx + w / 2), c(cy + h / 2))


def pt(x: float, y: float) -> tuple[int, int]:
    return (c(x), c(y))


def new_canvas() -> Image.Image:
    return Image.new("RGBA", (W, W), (0, 0, 0, 0))


def downsample(img: Image.Image) -> Image.Image:
    return img.resize((CANVAS, CANVAS), Image.Resampling.LANCZOS)


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


def draw_circle(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    d: float,
    fill: str,
    outline: str = INK,
    width: int = STROKE,
) -> None:
    draw_ellipse(draw, cx, cy, d, d, fill, outline, width)


def arc_points(
    cx: float,
    cy: float,
    rx: float,
    ry: float,
    start_deg: float,
    end_deg: float,
    steps: int = 48,
) -> list[tuple[int, int]]:
    return [
        pt(
            cx + rx * math.cos(math.radians(start_deg + (end_deg - start_deg) * i / steps)),
            cy + ry * math.sin(math.radians(start_deg + (end_deg - start_deg) * i / steps)),
        )
        for i in range(steps + 1)
    ]


def draw_poly(
    draw: ImageDraw.ImageDraw,
    points: Iterable[tuple[float, float]],
    fill: str,
    outline: str = INK,
    width: int = STROKE,
) -> None:
    pts = [pt(x, y) for x, y in points]
    draw.polygon(pts, fill=fill)
    draw.line(pts + [pts[0]], fill=outline, width=width, joint="curve")


def draw_dome(
    draw: ImageDraw.ImageDraw,
    cx: float,
    baseline_y: float,
    w: float,
    h: float,
    fill: str,
    outline: str = INK,
    width: int = STROKE,
    start_deg: float = 180,
    end_deg: float = 360,
) -> None:
    rx, ry = w / 2, h / 2
    arc = arc_points(cx, baseline_y, rx, ry, start_deg, end_deg, 64)
    draw.polygon(arc + [arc[0]], fill=fill)
    draw.line(arc + [arc[0]], fill=outline, width=width, joint="curve")


def draw_bowl(
    draw: ImageDraw.ImageDraw,
    cx: float,
    top_y: float,
    w: float,
    h: float,
    fill: str,
    outline: str = INK,
    width: int = STROKE,
) -> None:
    rx, ry = w / 2, h / 2
    arc = arc_points(cx, top_y, rx, ry, 0, 180, 64)
    draw.polygon(arc + [arc[0]], fill=fill)
    draw.line(arc + [arc[0]], fill=outline, width=width, joint="curve")


def draw_line(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: str = INK,
    width: int = STROKE,
    rounded: bool = True,
) -> None:
    scaled = [pt(x, y) for x, y in points]
    draw.line(scaled, fill=fill, width=width, joint="curve")
    if rounded:
        r = width / 2
        for x, y in (scaled[0], scaled[-1]):
            draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    w: float,
    h: float,
    radius: float,
    fill: str,
    outline: str = INK,
    width: int = STROKE,
) -> None:
    draw.rounded_rectangle(
        box(cx, cy, w, h),
        radius=c(radius),
        fill=fill,
        outline=outline,
        width=width,
    )


def alpha_paste(base: Image.Image, layer: Image.Image) -> None:
    base.alpha_composite(layer)


def rotated_link(angle: float, fill: str, outline: str = INK) -> Image.Image:
    patch = Image.new("RGBA", (150 * AA, 90 * AA), (0, 0, 0, 0))
    d = ImageDraw.Draw(patch)
    d.ellipse((20 * AA, 25 * AA, 130 * AA, 65 * AA), fill=fill, outline=outline, width=7 * AA)
    d.ellipse((50 * AA, 34 * AA, 100 * AA, 56 * AA), fill=(0, 0, 0, 0), outline=None)
    return patch.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)


def paste_center(base: Image.Image, patch: Image.Image, x: float, y: float) -> None:
    px, py = pt(x, y)
    base.alpha_composite(patch, (px - patch.width // 2, py - patch.height // 2))


def clear_head_hole(img: Image.Image) -> None:
    """Punch out the face area from hair masses intended to sit behind it."""
    d = ImageDraw.Draw(img)
    d.rounded_rectangle(box(0.50, 0.545, 0.64, 0.56), radius=c(0.13), fill=(0, 0, 0, 0))


def draw_shoulders(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.225, 0.820), (0.390, 0.780), (0.700, 1.015), (0.210, 1.015)], SHIRT, width=STROKE)
    draw_poly(d, [(0.430, 0.805), (0.510, 0.835), (0.672, 1.015), (0.570, 1.015)], SASH, width=9 * AA)
    draw_ellipse(d, 0.255, 0.855, 0.110, 0.170, FUR_DARK)
    draw_ellipse(d, 0.745, 0.855, 0.110, 0.170, FUR_DARK)


def draw_ears(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.225, 0.315), (0.315, 0.205), (0.370, 0.360)], FUR_DARK, width=STROKE)
    draw_poly(d, [(0.260, 0.305), (0.315, 0.242), (0.345, 0.335)], INNER_EAR, width=6 * AA)
    draw_poly(d, [(0.775, 0.315), (0.685, 0.205), (0.630, 0.360)], FUR_DARK, width=STROKE)
    draw_poly(d, [(0.740, 0.305), (0.685, 0.242), (0.655, 0.335)], INNER_EAR, width=6 * AA)


def draw_head(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    rounded_rect(d, 0.50, 0.560, 0.62, 0.54, 0.125, FUR, width=STROKE)
    draw_ellipse(d, 0.472, 0.318, 0.150, 0.034, "#FFE0AE", outline="#FFE0AE", width=1)


def draw_muzzle(img: Image.Image) -> None:
    # The reference face has no separate cream muzzle or cheek dots.
    return


def draw_eyes(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for ex in (0.365, 0.650):
        draw_ellipse(d, ex, 0.510, 0.030, 0.066, INK, outline=INK, width=1)


def draw_nose_mouth(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.505, 0.612, 0.082, 0.088, MOUTH, outline=INK, width=7 * AA)
    draw_poly(d, [(0.505, 0.594), (0.470, 0.558), (0.540, 0.558)], INK, outline=INK, width=1)
    draw_ellipse(d, 0.505, 0.635, 0.050, 0.030, TONGUE, outline=TONGUE, width=1)


def draw_whiskers(img: Image.Image) -> None:
    return


def draw_base(img: Image.Image, include_chain: Callable[[Image.Image], None] | None = None) -> None:
    draw_shoulders(img)
    if include_chain:
        include_chain(img)
    draw_ears(img)
    draw_head(img)
    draw_muzzle(img)
    draw_eyes(img)
    draw_nose_mouth(img)
    draw_whiskers(img)


def hair_buzz(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.455, 0.78, 0.48, "#60482F")
    for x in (0.35, 0.45, 0.55, 0.65):
        draw_line(d, [(x - 0.035, 0.365), (x + 0.035, 0.355)], "#4B3828", width=5 * AA)


def hair_side(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.455, 0.78, 0.50, "#3A2C22")
    draw_poly(d, [(0.24, 0.415), (0.42, 0.252), (0.75, 0.455), (0.55, 0.455)], "#4B3729")
    draw_line(d, [(0.43, 0.255), (0.36, 0.450)], "#2C2119", width=7 * AA)


def hair_long_back(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.50, 0.57, 0.95, 0.72, "#4A3426")
    clear_head_hole(img)


def hair_long_front(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.455, 0.80, 0.50, "#4A3426")
    draw_poly(d, [(0.31, 0.455), (0.42, 0.285), (0.52, 0.455)], "#5A4030")
    draw_poly(d, [(0.47, 0.455), (0.61, 0.280), (0.72, 0.455)], "#3E2B20")


def hair_long(img: Image.Image) -> None:
    hair_long_back(img)
    hair_long_front(img)


def hair_dreads(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for i, x in enumerate((0.20, 0.27, 0.34, 0.66, 0.73, 0.80)):
        drop = 0.30 if i in (0, 5) else 0.23
        rounded_rect(d, x, 0.45 + drop / 2, 0.065, drop, 0.032, "#3A281E")
    clear_head_hole(img)
    draw_dome(d, 0.50, 0.455, 0.78, 0.48, "#3A281E")
    for x in (0.41, 0.50, 0.59):
        rounded_rect(d, x, 0.385, 0.060, 0.17, 0.030, "#2D1F18")


def hair_afro(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x, y, dia in (
        (0.30, 0.30, 0.29), (0.42, 0.22, 0.31), (0.58, 0.22, 0.31),
        (0.70, 0.30, 0.29), (0.23, 0.43, 0.26), (0.77, 0.43, 0.26),
        (0.50, 0.36, 0.42),
    ):
        draw_circle(d, x, y, dia, "#2E2018")
    clear_head_hole(img)


def hair_spikes(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.455, 0.76, 0.42, "#2A2A32")
    for x, top_y, half in ((0.30, 0.165, 0.075), (0.40, 0.105, 0.080), (0.50, 0.075, 0.085), (0.60, 0.105, 0.080), (0.70, 0.165, 0.075)):
        draw_poly(d, [(x, top_y), (x + half, 0.335), (x - half, 0.335)], "#2A2A32")


def hair_mohawk(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(d, [(0.50, 0.085), (0.610, 0.430), (0.390, 0.430)], "#34343C")
    draw_poly(d, [(0.50, 0.130), (0.565, 0.420), (0.435, 0.420)], "#C4404A")


def hat_cap(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.405, 0.76, 0.48, "#265AA0")
    rounded_rect(d, 0.680, 0.402, 0.42, 0.075, 0.040, "#3E74B8")
    draw_line(d, [(0.49, 0.180), (0.49, 0.405)], "#1D477F", width=6 * AA)


def hat_beanie(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_dome(d, 0.50, 0.415, 0.78, 0.52, "#964646")
    rounded_rect(d, 0.50, 0.418, 0.76, 0.085, 0.042, "#7D383C")
    draw_line(d, [(0.34, 0.270), (0.34, 0.405)], "#7D383C", width=5 * AA)
    draw_line(d, [(0.50, 0.235), (0.50, 0.405)], "#7D383C", width=5 * AA)
    draw_line(d, [(0.66, 0.270), (0.66, 0.405)], "#7D383C", width=5 * AA)


def hat_visor(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    rounded_rect(d, 0.50, 0.390, 0.52, 0.075, 0.040, "#2F7D5C")
    rounded_rect(d, 0.70, 0.405, 0.42, 0.065, 0.034, "#41946E")
    draw_line(d, [(0.25, 0.390), (0.15, 0.355)], "#2F7D5C", width=10 * AA)
    draw_line(d, [(0.75, 0.390), (0.85, 0.355)], "#2F7D5C", width=10 * AA)


def hat_headphones(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    pts = arc_points(0.50, 0.42, 0.37, 0.37, 200, 340, 48)
    d.line(pts, fill="#33343C", width=35 * AA, joint="curve")
    for x in (0.135, 0.865):
        rounded_rect(d, x, 0.44, 0.12, 0.18, 0.035, "#33343C")
        rounded_rect(d, x, 0.44, 0.065, 0.115, 0.025, "#59606C", outline="#59606C", width=1)


def hat_top(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    rounded_rect(d, 0.50, 0.350, 0.72, 0.075, 0.030, "#1E1E24")
    rounded_rect(d, 0.50, 0.205, 0.44, 0.30, 0.025, "#1E1E24")
    rounded_rect(d, 0.50, 0.292, 0.44, 0.060, 0.015, "#963238")


def hat_crown(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_poly(
        d,
        [(0.25, 0.405), (0.25, 0.205), (0.36, 0.300), (0.43, 0.185), (0.50, 0.300), (0.57, 0.185), (0.64, 0.300), (0.75, 0.205), (0.75, 0.405)],
        GOLD,
    )
    for x in (0.25, 0.43, 0.57, 0.75):
        draw_circle(d, x, 0.200 if x in (0.25, 0.75) else 0.180, 0.040, "#F0D36B", outline=INK, width=5 * AA)


def face_stubble(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x, y in (
        (0.39, 0.675), (0.44, 0.735), (0.51, 0.760), (0.58, 0.730),
        (0.61, 0.675), (0.47, 0.690), (0.54, 0.705), (0.50, 0.815),
    ):
        draw_circle(d, x, y, 0.025, "#967C60", outline="#967C60", width=1)


def face_moustache(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.438, 0.710, 0.135, 0.075, "#4A3426")
    draw_ellipse(d, 0.562, 0.710, 0.135, 0.075, "#4A3426")


def face_goatee(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_ellipse(d, 0.50, 0.800, 0.16, 0.14, "#4A3426")


def face_chops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.245, 0.755):
        rounded_rect(d, x, 0.620, 0.105, 0.265, 0.050, "#5A3E2C")


def face_beard(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    draw_bowl(d, 0.50, 0.655, 0.54, 0.43, "#4A3426")
    draw_ellipse(d, 0.50, 0.700, 0.31, 0.17, MUZZLE, outline=INK, width=8 * AA)


def ear_studs(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.195, 0.805):
        draw_circle(d, x, 0.335, 0.056, SILVER, outline=INK, width=6 * AA)
        draw_circle(d, x - 0.010, 0.324, 0.014, WHITE, outline=WHITE, width=1)


def ear_hoops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.195, 0.805):
        d.ellipse(box(x, 0.350, 0.090, 0.105), outline=GOLD, width=11 * AA)
        d.ellipse(box(x, 0.350, 0.090, 0.105), outline=INK, width=4 * AA)


def ear_drops(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for x in (0.195, 0.805):
        draw_circle(d, x, 0.325, 0.042, GOLD, outline=INK, width=5 * AA)
        rounded_rect(d, x, 0.385, 0.038, 0.078, 0.020, GOLD, outline=INK, width=5 * AA)


def chain_thin(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    points = arc_points(0.50, 0.845, 0.23, 0.095, 20, 160, 64)
    d.line(points, fill=INK, width=12 * AA, joint="curve")
    d.line(points, fill=GOLD, width=7 * AA, joint="curve")


def chain_cuban(img: Image.Image) -> None:
    for i, deg in enumerate(range(25, 156, 13)):
        x = 0.50 + 0.23 * math.cos(math.radians(deg))
        y = 0.845 + 0.095 * math.sin(math.radians(deg))
        paste_center(img, rotated_link(deg - 90, GOLD), x, y)


def chain_pendant(img: Image.Image) -> None:
    chain_thin(img)
    d = ImageDraw.Draw(img)
    draw_circle(d, 0.50, 0.945, 0.115, GOLD, outline=INK, width=8 * AA)
    draw_circle(d, 0.50, 0.945, 0.060, "#F0D36B", outline="#F0D36B", width=1)


ASSETS: dict[str, Callable[[Image.Image], None]] = {
    "base.hamster": lambda img: draw_base(img),
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
    ("sheet_1_base", ["base.hamster"], 1),
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
    if asset_id == "base.hamster":
        draw_base(img)
    elif asset_id.startswith("chain."):
        draw_base(img, include_chain=ASSETS[asset_id])
    elif asset_id.startswith("hair."):
        draw_base(img)
        layer = new_canvas()
        ASSETS[asset_id](layer)
        alpha_paste(img, layer)
    elif asset_id.startswith("hat."):
        draw_base(img)
        ASSETS[asset_id](img)
    elif asset_id.startswith("face."):
        draw_shoulders(img)
        draw_ears(img)
        draw_head(img)
        draw_muzzle(img)
        ASSETS[asset_id](img)
        draw_eyes(img)
        draw_nose_mouth(img)
        draw_whiskers(img)
    elif asset_id.startswith("ear."):
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
    label_h = 96
    rows = math.ceil(len(asset_ids) / cols)
    sheet = Image.new("RGBA", (cols * CANVAS, rows * (CANVAS + label_h)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    label_font = font(34)
    for i, asset_id in enumerate(asset_ids):
        row, col = divmod(i, cols)
        x = col * CANVAS
        y = row * (CANVAS + label_h)
        tile_fill = TILE_COLORS[i % len(TILE_COLORS)]
        draw.rounded_rectangle(
            (x + 62, y + 58, x + CANVAS - 62, y + CANVAS - 58),
            radius=58,
            fill=tile_fill,
            outline=TILE_BORDER,
            width=26,
        )
        preview = Image.open(PREVIEWS / f"{asset_id}.png").convert("RGBA")
        thumb_size = 850
        preview = preview.resize((thumb_size, thumb_size), Image.Resampling.LANCZOS)
        sheet.alpha_composite(preview, (x + (CANVAS - thumb_size) // 2, y + 78))
        bbox = draw.textbbox((0, 0), asset_id, font=label_font)
        tx = x + (CANVAS - (bbox[2] - bbox[0])) / 2
        ty = y + CANVAS + 28
        draw.text((tx, ty), asset_id, font=label_font, fill=INK, stroke_width=3, stroke_fill=MUZZLE)
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
