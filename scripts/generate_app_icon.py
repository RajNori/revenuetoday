#!/usr/bin/env python3
"""Generate 1024x1024 App Store icon for Revenue Today (spec-driven)."""

from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
BG = (0x0A, 0x0A, 0x0F)
EMERALD = (0x00, 0xC8, 0x96)
GLOW_ALPHA = int(round(255 * 0.20))
CHART_WHITE_ALPHA = int(round(255 * 0.08))
SYMBOL_FRAC = 0.55
GLOW_BLUR_RADIUS = 200
FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
    "/System/Library/Fonts/SFNSRounded.ttf",
]


def load_heavy_rounded_font() -> ImageFont.FreeTypeFont:
    for path in FONT_CANDIDATES:
        p = Path(path)
        if p.is_file():
            return ImageFont.truetype(str(p), size=400)
    return ImageFont.load_default()


def font_size_for_symbol_height(font_path: str, target_h: float) -> int:
    lo, hi = 80, 900
    best = lo
    while lo <= hi:
        mid = (lo + hi) // 2
        f = ImageFont.truetype(font_path, mid)
        bbox = f.getbbox("$")
        h = bbox[3] - bbox[1]
        if h <= target_h:
            best = mid
            lo = mid + 1
        else:
            hi = mid - 1
    return best


def main() -> None:
    out_path = Path(__file__).resolve().parent.parent / "RevenueToday" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"

    font_path = next((p for p in FONT_CANDIDATES if Path(p).is_file()), None)
    if not font_path:
        print("No suitable font found.", file=sys.stderr)
        sys.exit(1)

    target_h = SYMBOL_FRAC * SIZE
    fs = font_size_for_symbol_height(font_path, target_h)
    font = ImageFont.truetype(font_path, fs)

    # Solid background (no transparency)
    base = Image.new("RGB", (SIZE, SIZE), BG)
    layer = base.convert("RGBA")

    # Ghost chart (behind everything except background): upward micro-trend
    chart = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cd = ImageDraw.Draw(chart)
    ghost = (255, 255, 255, CHART_WHITE_ALPHA)
    n = 64
    pts: list[tuple[float, float]] = []
    for i in range(n):
        t = i / (n - 1)
        x = 72.0 + t * (SIZE - 144.0)
        # Gentle climb with tiny oscillation (micro chart)
        y = SIZE * 0.80 - (t**1.05) * SIZE * 0.48 + math.sin(t * math.pi * 5.5) * 5.0
        pts.append((x, y))
    cd.line(pts, fill=ghost, width=3)

    layer = Image.alpha_composite(layer, chart)

    # Radial glow: soft emerald blob, blurred (not a gradient on the glyph)
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = SIZE // 2, SIZE // 2
    # Core disc — blur spreads to ~200px-feel soft halo
    r0 = min(SIZE, SIZE) * 0.22
    gd.ellipse(
        (cx - r0, cy - r0, cx + r0, cy + r0),
        fill=(EMERALD[0], EMERALD[1], EMERALD[2], GLOW_ALPHA),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=GLOW_BLUR_RADIUS))
    layer = Image.alpha_composite(layer, glow)

    # Flat $ on top
    draw = ImageDraw.Draw(layer)
    draw.text(
        (SIZE // 2, SIZE // 2),
        "$",
        font=font,
        fill=(*EMERALD, 255),
        anchor="mm",
    )

    final = layer.convert("RGB")
    if final.size != (SIZE, SIZE):
        print("Unexpected size", final.size, file=sys.stderr)
        sys.exit(1)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    final.save(out_path, format="PNG", compress_level=6)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
