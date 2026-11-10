#!/usr/bin/env python3
"""Builds the App Store product page assets from the raw iPhone captures.

    Header 3840x1646.png, Header 5244x2950.png
        Five real screens in a gentle arc, the centre one raised, bleeding off
        the bottom edge. No text: Apple shows the app's name and icon around
        the header, and text here would compete with them.

    Search Results 3840x2560.png, 5244x2950.png, 1920x1280.png
        One headline and subtitle above three real screens. The headline is
        at least 6.5% of the asset's width, so it reads at search-row size.

Every asset is designed at its own aspect ratio, kept inside the centred 90%
safe zone, saved as opaque RGB, and its captions are checked against the
brightest pixel behind them (WCAG AA, 4.5:1).

Run from this folder after capture.sh has filled ../Screenshots/raw-iphone:
    python3 make_creative_assets.py   (needs Pillow)
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
RAW = HERE.parent / "Screenshots" / "raw-iphone"
FONT = "/System/Library/Fonts/SFNS.ttf"

NEAR_BLACK = (0x0B, 0x0A, 0x0E)
GLOWS = [(0x3A, 0x2A, 0x0E), (0x13, 0x2A, 0x4A), (0x3A, 0x0F, 0x25)]  # gold, info, magenta bases
TITLE = (0xFF, 0xFF, 0xFF)
SUBTITLE = (0xFF, 0xC7, 0x61)  # AppColors.gold, dark appearance
BEZEL = (0x2B, 0x2A, 0x30)
MIN_CONTRAST = 4.5

HEADER_SCREENS = ["03-activities", "06-music", "02-city", "09-suggested-plan", "05-gastro-cities"]
SEARCH_SCREENS = ["05-gastro-cities", "02-city", "09-suggested-plan"]
HEADLINE = "Feel a city before you go"
SUBHEADLINE = "Things to do, where to eat and a full trip plan in one tap."


def luminance(rgb: tuple[int, int, int]) -> float:
    def channel(value: int) -> float:
        c = value / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def font(size: int, weight: str) -> ImageFont.FreeTypeFont:
    face = ImageFont.truetype(FONT, size)
    face.set_variation_by_name(weight)
    return face


def backdrop(size: tuple[int, int]) -> Image.Image:
    """Near-black lit by soft glows in three of the app's brand bases."""
    width, height = size
    canvas = Image.new("RGB", size, NEAR_BLACK)
    glow = Image.new("RGB", size, (0, 0, 0))
    draw = ImageDraw.Draw(glow)
    for (cx, cy), colour in zip([(0.2, 0.75), (0.5, 0.95), (0.8, 0.75)], GLOWS):
        r = 0.35 * width
        draw.ellipse([(cx * width - r, cy * height - r), (cx * width + r, cy * height + r)],
                     fill=tuple(min(255, c * 2) for c in colour))
    return ImageChops.add(canvas, glow.filter(ImageFilter.GaussianBlur(width * 0.08)))


def device(raw: Image.Image, width: int) -> Image.Image:
    """A capture in a thin bezel with display-like corners, as RGBA."""
    height = round(raw.height * width / raw.width)
    screen = raw.convert("RGB").resize((width, height), Image.LANCZOS)
    radius, bezel = round(width * 0.13), max(4, round(width * 0.012))
    framed = Image.new("RGBA", (width + bezel * 2, height + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(framed).rounded_rectangle([(0, 0), framed.size], radius=radius + bezel, fill=BEZEL + (255,))
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), screen.size], radius=radius, fill=255)
    framed.paste(screen, (bezel, bezel), mask)
    return framed


def place(canvas: Image.Image, phone: Image.Image, centre_x: int, top: int, angle: float = 0) -> None:
    rotated = phone.rotate(angle, resample=Image.BICUBIC, expand=True) if angle else phone
    shadow = Image.new("RGBA", rotated.size, (0, 0, 0, 0))
    shadow.putalpha(rotated.getchannel("A").point(lambda a: a * 0.55))
    blur = shadow.filter(ImageFilter.GaussianBlur(phone.width * 0.05))
    x = centre_x - rotated.width // 2
    canvas.paste(blur, (x, top + round(phone.width * 0.04)), blur)
    canvas.paste(rotated, (x, top), rotated)


def header(size: tuple[int, int]) -> Image.Image:
    width, height = size
    canvas = backdrop(size).convert("RGBA")
    phone_width = round(min(width * 0.16, height * 0.55))
    spacing = phone_width * 1.12
    # Outermost first, so nearer screens overlap them.
    for offset in (-2, 2, -1, 1, 0):
        raw = Image.open(RAW / f"{HEADER_SCREENS[offset + 2]}.png")
        scale = 1 - abs(offset) * 0.08
        phone = device(raw, round(phone_width * scale))
        lift = abs(offset) ** 2 * 0.03 * height + abs(offset) * 0.04 * height
        place(canvas, phone, round(width / 2 + offset * spacing), round(height * 0.16 + lift), -offset * 3)
    return canvas.convert("RGB")


def search_results(size: tuple[int, int]) -> Image.Image:
    width, height = size
    canvas = backdrop(size).convert("RGBA")
    title_size = round(width * 0.068)
    title_face, subtitle_face = font(title_size, "Bold"), font(round(title_size * 0.5), "Regular")
    title_top = round(height * 0.07)
    subtitle_top = title_top + round(title_size * 1.25)
    text_bottom = subtitle_top + round(title_size * 0.75)

    lightest = max(canvas.convert("RGB").crop((0, title_top, width, text_bottom)).getdata(), key=luminance)
    for name, colour in (("headline", TITLE), ("subtitle", SUBTITLE)):
        ratio = contrast(colour, lightest)
        if ratio < MIN_CONTRAST:
            raise ValueError(f"{name} contrast {ratio:.2f}:1 is below {MIN_CONTRAST}:1")

    draw = ImageDraw.Draw(canvas)
    for text, face, top, colour in ((HEADLINE, title_face, title_top, TITLE),
                                    (SUBHEADLINE, subtitle_face, subtitle_top, SUBTITLE)):
        if draw.textlength(text, font=face) > width * 0.9:
            raise ValueError(f"Outside the safe zone: {text!r}")
        draw.text((width / 2, top), text, font=face, fill=colour, anchor="mt")

    phone_width = round(min(width * 0.24, (height - text_bottom) * 0.55))
    top = text_bottom + round(height * 0.06)
    for offset in (-1, 1, 0):
        raw = Image.open(RAW / f"{SEARCH_SCREENS[offset + 1]}.png")
        phone = device(raw, round(phone_width * (0.92 if offset else 1)))
        place(canvas, phone, round(width / 2 + offset * phone_width * 1.08),
              top + (round(height * 0.04) if offset else 0))
    return canvas.convert("RGB")


def main() -> None:
    for size in [(3840, 1646), (5244, 2950)]:
        name = f"Header {size[0]}x{size[1]}.png"
        header(size).save(HERE / name, optimize=True)
        print(name)
    for size in [(3840, 2560), (5244, 2950), (1920, 1280)]:
        name = f"Search Results {size[0]}x{size[1]}.png"
        search_results(size).save(HERE / name, optimize=True)
        print(name)


if __name__ == "__main__":
    main()
