#!/usr/bin/env python3
"""Builds docs/assets/banner.png, the README header.

The app icon is the dark-appearance icon from the asset catalog, and the
counts come from the bundled cities.json, so the banner follows the app if
either changes. Rendered at 2x (2000 x 1000) and shown at 1000 x 500.

The motif is the world played as a song: every city in the catalog,
sorted west to east by longitude into columns, and each column drawn as an
equalizer bar as tall as the number of cities in it. The busy meridians of
Europe, Asia and the Americas become the loud beats.

Run from the repository root:  python3 docs/assets/make_banner.py
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / "Tourism Beats/Resources"
ICON = RESOURCES / "Assets.xcassets/Tourism_Beats_AppIcon.appiconset/Tourism_Beats_App_Icon_Dark.png"
CITIES = RESOURCES / "cities.json"
OUT = ROOT / "docs/assets/banner.png"

SCALE = 2
WIDTH, HEIGHT = 1000 * SCALE, 500 * SCALE

BACKGROUND = (0x12, 0x10, 0x16)  # AppColors.surface, dark, deepened
WORDMARK = (0xF5, 0xF0, 0xFA)    # AppColors.label, dark
SLOGAN = (0xB3, 0xA8, 0xC2)      # AppColors.secondaryLabel, dark
FOOTNOTE = (0x86, 0x7E, 0x94)
RULE = (0x2A, 0x24, 0x33)
QUIET = (0x2A, 0x24, 0x33)       # an empty stretch of ocean
# The brand ramp, west to east: AppColors.coral, magenta, violet.
RAMP = [(0xF2, 0x61, 0x40), (0xD9, 0x38, 0x80), (0x8C, 0x38, 0xCC)]

SERIF = "/System/Library/Fonts/NewYork.ttf"
SANS = "/System/Library/Fonts/SFNS.ttf"

COLUMNS = 48


def px(value: float) -> int:
    return round(value * SCALE)


def font(path: str, size: float, weight: str | None = None) -> ImageFont.FreeTypeFont:
    face = ImageFont.truetype(path, px(size))
    if weight:
        face.set_variation_by_name(weight)
    return face


def ramp(t: float) -> tuple[int, int, int]:
    """Coral through magenta to violet, for t from 0 to 1."""
    span = t * (len(RAMP) - 1)
    i = min(int(span), len(RAMP) - 2)
    f = span - i
    a, b = RAMP[i], RAMP[i + 1]
    return tuple(round(a[k] + (b[k] - a[k]) * f) for k in range(3))


def app_icon(size: int) -> Image.Image:
    icon = Image.open(ICON).convert("RGBA").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (size, size)], radius=round(size * 0.225), fill=255)
    icon.putalpha(mask)
    return icon


def equalizer(draw: ImageDraw.ImageDraw, cities: list[dict], left: int, right: int, baseline: int, tallest: int) -> None:
    """Draws the cities, west to east, as one bar per band of longitude."""
    counts = [0] * COLUMNS
    for city in cities:
        column = min(int((city["longitude"] + 180) / 360 * COLUMNS), COLUMNS - 1)
        counts[column] += 1
    loudest = max(counts)
    gap = px(5)
    width = (right - left - gap * (COLUMNS - 1)) / COLUMNS
    floor = width  # an empty band still shows, as a dot on the line
    for i, count in enumerate(counts):
        x = left + i * (width + gap)
        if count == 0:
            draw.ellipse([(x, baseline - floor), (x + width, baseline)], fill=QUIET)
            continue
        height = floor + (tallest - floor) * (count / loudest) ** 0.75
        draw.rounded_rectangle([(x, baseline - height), (x + width, baseline)], radius=width / 2, fill=ramp(i / (COLUMNS - 1)))


def main() -> None:
    cities = json.loads(CITIES.read_text())
    countries = {city["countryCode"] for city in cities}

    canvas = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    # Mark, wordmark and slogan.
    icon_size = px(140)
    icon = app_icon(icon_size)
    canvas.paste(icon, (px(96), px(76)), icon)
    # The icon's charcoal ground sits close to the banner's; a hairline
    # outline keeps its shape legible.
    draw.rounded_rectangle(
        [(px(96), px(76)), (px(96) + icon_size - 1, px(76) + icon_size - 1)],
        radius=round(icon_size * 0.225), outline=RULE, width=px(1),
    )
    draw.text((px(270), px(92)), "Tourism Beats", font=font(SERIF, 72), fill=WORDMARK)
    draw.text((px(274), px(180)), "Every city has a beat.", font=font(SANS, 22, "Regular"), fill=SLOGAN)

    # The world, west to east, as a song.
    left, right = px(96), px(904)
    equalizer(draw, cities, left, right, baseline=px(368), tallest=px(118))

    # Rule and footnotes.
    draw.line([(left, px(388)), (right, px(388))], fill=RULE, width=px(1))
    note = font(SANS, 16, "Regular")
    draw.text((left, px(410)), f"{len(cities)} cities in {len(countries)} countries, west to east", font=note, fill=FOOTNOTE)
    draw.text((right, px(410)), "music, food, trips and a bucket list", font=note, fill=FOOTNOTE, anchor="ra")

    canvas.save(OUT, optimize=True)
    print(OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
