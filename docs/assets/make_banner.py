#!/usr/bin/env python3
"""Builds docs/assets/banner.png, the README header.

The app icon is the dark-appearance icon from the asset catalog, the land
is traced from the night Earth the home globe wears, and the lights are the
bundled cities.json, so the banner follows the app if any of them change.
Rendered at 2x (2000 x 1000) and shown at 1000 x 500.

The motif is the app's world at night: a dotted map with every city in the
catalog lit, and a few of them sending out rings like sound from a speaker.
Places to go, each with its own beat.

Run from the repository root:  python3 docs/assets/make_banner.py
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
RESOURCES = ROOT / "Tourism Beats/Resources"
ASSETS = RESOURCES / "Assets.xcassets"
ICON = ASSETS / "Tourism_Beats_AppIcon.appiconset/Tourism_Beats_App_Icon_Dark.png"
EARTH = ASSETS / "earth_night.imageset/earth_night.jpg"
CITIES = RESOURCES / "cities.json"
OUT = ROOT / "docs/assets/banner.png"

SCALE = 2
WIDTH, HEIGHT = 1000 * SCALE, 500 * SCALE

BACKGROUND = (0x09, 0x0A, 0x1A)  # AppGradients.launch, its outer navy
WORDMARK = (0xF5, 0xF0, 0xFA)    # AppColors.label, dark
SLOGAN = (0xB3, 0xAC, 0xCC)
FOOTNOTE = (0x82, 0x7E, 0x9E)
OUTLINE = (0x26, 0x25, 0x3D)
LAND = (0x33, 0x33, 0x5A)        # a dot of land with no city on it
CITY = (0xF2, 0xAD, 0x47)        # AppColors.gold, a city's light
GLOW = (0xF2, 0x61, 0x40)        # AppColors.coral, the light's halo
# The rings, west to east: AppColors.coral, magenta, violet.
RAMP = [(0xF2, 0x61, 0x40), (0xD9, 0x38, 0x80), (0x8C, 0x38, 0xCC)]

SERIF = "/System/Library/Fonts/NewYork.ttf"
SANS = "/System/Library/Fonts/SFNS.ttf"

# The map runs from just north of Tromsø to just south of Ushuaia, the
# catalog's northernmost and southernmost cities.
NORTH, SOUTH = 72.0, -57.0
# The ocean in the night Earth texture is one flat colour; land is anything else.
OCEAN = np.array([4, 6, 20])
DOT_PITCH = 6.2  # points between dots

# Cities that send out rings, spread around the world.
BEATING = ["New York", "London", "Lagos", "Mumbai", "Tokyo", "Buenos Aires", "Sydney"]


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


def land_mask() -> Image.Image:
    """Land as white on black, one pixel per quarter degree."""
    earth = Image.open(EARTH).convert("RGB").resize((1440, 720), Image.BOX)
    difference = np.abs(np.asarray(earth).astype(int) - OCEAN).max(axis=2)
    mask = Image.fromarray(((difference >= 2) * 255).astype(np.uint8))
    # Unlit forest can match the ocean exactly; closing fills those gaps.
    return mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(7)).filter(ImageFilter.MedianFilter(5))


class Projection:
    """Equirectangular, from longitude and latitude to canvas pixels."""

    def __init__(self, left: int, right: int, top: int) -> None:
        self.left, self.top = left, top
        self.scale = (right - left) / 360
        self.bottom = top + (NORTH - SOUTH) * self.scale

    def __call__(self, lon: float, lat: float) -> tuple[float, float]:
        return self.left + (lon + 180) * self.scale, self.top + (NORTH - lat) * self.scale


def world(canvas: Image.Image, cities: list[dict], project: Projection) -> None:
    mask = land_mask()
    draw = ImageDraw.Draw(canvas)

    # Land, as a grid of dots.
    pitch = px(DOT_PITCH)
    radius = pitch * 0.28
    y = project.top + pitch / 2
    while y < project.bottom:
        lat = NORTH - (y - project.top) / project.scale
        x = project.left + pitch / 2
        while x < project.left + 360 * project.scale:
            lon = (x - project.left) / project.scale - 180
            if mask.getpixel((min(int((lon + 180) * 4), 1439), min(int((90 - lat) * 4), 719))):
                draw.ellipse([(x - radius, y - radius), (x + radius, y + radius)], fill=LAND)
            x += pitch
        y += pitch

    # Rings around the beating cities, coloured by where they sit, west to east.
    rings = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(rings)
    by_name = {city["name"]: city for city in cities}
    for name in BEATING:
        city = by_name[name]
        cx, cy = project(city["longitude"], city["latitude"])
        colour = ramp((city["longitude"] + 180) / 360)
        for step, alpha in enumerate((230, 150, 80)):
            r = px(7 + step * 7)
            ring_draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], outline=colour + (alpha,), width=px(1.5))
    canvas.paste(rings, (0, 0), rings)

    # Every city, a light with a soft halo.
    # The halo layer is coral throughout, so blurring it spreads only its
    # alpha; a transparent-black layer would blur into dark rims that hide
    # the land around busy regions.
    glow = Image.new("RGBA", canvas.size, GLOW + (0,))
    lights = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    glow_draw, light_draw = ImageDraw.Draw(glow), ImageDraw.Draw(lights)
    for city in cities:
        cx, cy = project(city["longitude"], city["latitude"])
        g, r = px(3.2), px(1.3)
        glow_draw.ellipse([(cx - g, cy - g), (cx + g, cy + g)], fill=GLOW + (120,))
        light_draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], fill=CITY + (255,))
    glow = glow.filter(ImageFilter.GaussianBlur(px(2.5)))
    canvas.paste(glow, (0, 0), glow)
    canvas.paste(lights, (0, 0), lights)


def main() -> None:
    cities = json.loads(CITIES.read_text())
    countries = {city["countryCode"] for city in cities}

    canvas = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    # Mark, wordmark and slogan.
    left, right = px(96), px(904)
    icon_size = px(96)
    icon = app_icon(icon_size)
    canvas.paste(icon, (left, px(40)), icon)
    # The icon's charcoal ground sits close to the banner's; a hairline
    # outline keeps its shape legible.
    draw.rounded_rectangle(
        [(left, px(40)), (left + icon_size - 1, px(40) + icon_size - 1)],
        radius=round(icon_size * 0.225), outline=OUTLINE, width=px(1),
    )
    draw.text((px(216), px(42)), "Tourism Beats", font=font(SERIF, 56), fill=WORDMARK)
    draw.text((px(219), px(112)), "Every city has a beat.", font=font(SANS, 20, "Regular"), fill=SLOGAN)

    # The world at night, every city lit.
    project = Projection(left, right, top=px(156))
    world(canvas, cities, project)

    # Footnotes.
    note = font(SANS, 15, "Regular")
    draw.text((left, px(452)), f"{len(cities)} cities in {len(countries)} countries", font=note, fill=FOOTNOTE)
    draw.text((right, px(452)), "music, food, trips and a bucket list", font=note, fill=FOOTNOTE, anchor="ra")

    canvas.save(OUT, optimize=True)
    print(OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
