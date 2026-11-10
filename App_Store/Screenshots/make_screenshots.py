#!/usr/bin/env python3
"""Builds Tourism Beats' App Store listing screenshots from raw captures.

capture.sh saves each screen from the real app, dark appearance, 9:41:

    raw-iphone/     iPhone 18 Pro simulator, 1206 x 2622
    raw-duo-outer/  iPhone Duo simulator, folded (outer display), 1398 x 2034
    raw-duo-inner/  iPhone Duo simulator, unfolded (inner display), 2853 x 2007

Each is placed in a thin bezel on its screen's brand gradient, under a title
and subtitle, and written at the upload size for its App Store Connect class:

    iPhone-6.3-1206x2622/        "iPhone with Dynamic Island, medium" (required)
    iPhone-Duo-outer-1398x2034/  iPhone Duo, folded
    iPhone-Duo-inner-2853x2007/  iPhone Duo, unfolded

The unfolded display is wider than tall, so its captions run on one line
each. A class whose raw folder doesn't exist yet is skipped.

Output is opaque RGB PNG, since App Store Connect rejects alpha channels.
Each caption colour is checked against the brightest pixel behind it on every
finished image, and the build fails below WCAG AA (4.5:1), as it does for a
caption line that would end on a single word.

Run from this folder:  python3 make_screenshots.py   (needs Pillow)
"""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).parent
FONT = "/System/Library/Fonts/SFNS.ttf"  # SF Pro, variable

# The app's dark-appearance brand colours, each paired with the dark base of
# its own gradient.
GOLD = ((0xFF, 0xC7, 0x61), (0x3A, 0x2A, 0x0E))
INFO = ((0x7A, 0xAD, 0xFA), (0x13, 0x2A, 0x4A))
CORAL = ((0xFA, 0x7A, 0x59), (0x4A, 0x1A, 0x10))
VIOLET = ((0xAD, 0x61, 0xE6), (0x1E, 0x0E, 0x33))
MAGENTA = ((0xEB, 0x61, 0x9E), (0x3A, 0x0F, 0x25))
SAFE = ((0x6B, 0xD6, 0xB8), (0x0E, 0x3A, 0x30))

NEAR_BLACK = (0x0B, 0x0A, 0x0E)
TITLE = (0xFF, 0xFF, 0xFF)
BEZEL = (0x2B, 0x2A, 0x30)

# Points at @3x: title 36pt / 40pt line, subtitle 20pt / 24pt line.
SCALE = 3
TITLE_SIZE, TITLE_LINE = 36 * SCALE, 40 * SCALE
SUBTITLE_SIZE, SUBTITLE_LINE = 20 * SCALE, 24 * SCALE

# The listing order: the first three show on the install sheets.
SCREENS = [
    ("01-home", "544 cities.\nOne living globe.", "Spin the world and step\ninto any destination.", GOLD),
    ("02-city", "Feel a city\nbefore you go", "Local time, live weather and\na fresh fact on every visit.", INFO),
    ("09-suggested-plan", "Plan every day\nin one tap", "Top sights and meals, grouped\nso each day stays close.", CORAL),
    ("05-gastro-cities", "Eat your way\naround the world", "Fifteen gastronomic capitals,\nranked on the evidence.", MAGENTA),
    ("03-activities", "See what's\nworth seeing", "Ranked from travel guides\nand real-world popularity.", VIOLET),
    ("04-restaurants", "Find where\nto eat", "Standout local restaurants,\nranked above chains.", GOLD),
    ("06-music", "Hear what the\ncity is playing", "Top local songs, ready in\nApple Music or Spotify.", MAGENTA),
    ("07-advisories", "Travel safer\nand smarter", "Safety, visa rules and\nwalkability at a glance.", SAFE),
]

# folder, upload size, raw folder, type scale (None: from the width), screen
# share of the width, display corner radius as a share of the screen width,
# one-line captions
CLASSES = [
    ("iPhone-6.3-1206x2622", (1206, 2622), "raw-iphone", None, 0.80, 0.13, False),
    ("iPhone-Duo-outer-1398x2034", (1398, 2034), "raw-duo-outer", 1.0, 0.70, 0.09, False),
    ("iPhone-Duo-inner-2853x2007", (2853, 2007), "raw-duo-inner", 1.25, 0.74, 0.03, True),
]

MAX_TEXT_WIDTH = 0.88
MIN_CONTRAST = 4.5


def luminance(rgb: tuple[int, int, int]) -> float:
    def channel(value: int) -> float:
        c = value / 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(v) for v in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def check_text_contrast(canvas: Image.Image, box: tuple[int, int, int, int],
                        colours: dict[str, tuple[int, int, int]], label: str) -> None:
    """Fails if a caption colour drops below AA on the brightest pixel behind
    the captions, so no glow can wash the text out."""
    region = canvas.crop(box).convert("RGB")
    lightest = max(region.getdata(), key=luminance)
    for name, colour in colours.items():
        ratio = contrast(colour, lightest)
        if ratio < MIN_CONTRAST:
            raise ValueError(f"{label}: {name} contrast {ratio:.2f}:1 is below {MIN_CONTRAST}:1")


def check_balanced(text: str) -> None:
    for line in text.split("\n"):
        if len(line.split()) < 2:
            raise ValueError(f"Line would end on a single word: {line!r}")


def font(size: int, weight: str) -> ImageFont.FreeTypeFont:
    face = ImageFont.truetype(FONT, size)
    face.set_variation_by_name(weight)
    return face


def gradient(size: tuple[int, int], top: tuple[int, int, int]) -> Image.Image:
    """The screen's brand base fading to near-black by 70% of the height."""
    width, height = size
    image = Image.new("RGB", size)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = min(y / (height * 0.7), 1)
        colour = tuple(round(a + (b - a) * t) for a, b in zip(top, NEAR_BLACK))
        draw.line([(0, y), (width, y)], fill=colour)
    return image


def halo(canvas: Image.Image, box: tuple[int, int, int, int], radius: int,
         spread: int, tint: tuple[int, int, int], calm_until: int) -> None:
    """A soft light in the screen's colour, so the device lifts off the
    canvas. It fades out above the device, so the captions above
    `calm_until` keep the plain gradient behind them."""
    light = Image.new("RGB", canvas.size, (0, 0, 0))
    left, top, right, bottom = box
    ImageDraw.Draw(light).rounded_rectangle(
        [(left - spread, top - spread), (right + spread, bottom + spread)],
        radius=radius + spread, fill=tuple(round(c * 0.28) for c in tint),
    )
    light = light.filter(ImageFilter.GaussianBlur(spread))
    width, height = canvas.size
    ramp = max(top - calm_until, 1)
    fade = Image.new("L", (1, height))
    fade.putdata([max(0, min(255, round((y - calm_until) / ramp * 255))) for y in range(height)])
    fade = fade.resize((width, height))
    canvas.paste(ImageChops.add(canvas, ImageChops.multiply(light, Image.merge("RGB", [fade] * 3))))


def centred_lines(draw: ImageDraw.ImageDraw, lines: list[str], face: ImageFont.FreeTypeFont,
                  line_height: int, top: int, width: int, fill: tuple[int, int, int]) -> None:
    for index, line in enumerate(lines):
        if draw.textlength(line, font=face) > width * MAX_TEXT_WIDTH:
            raise ValueError(f"Too wide for the canvas: {line!r}")
        y = top + index * line_height
        draw.text((width / 2, y + line_height / 2), line, font=face, fill=fill, anchor="mm")


def compose(raw: Image.Image, title: str, subtitle: str, palette, size: tuple[int, int],
            unit: float | None, screen_share: float, corner: float, one_line: bool,
            label: str) -> Image.Image:
    width, height = size
    tint, base = palette
    if one_line:
        title, subtitle = title.replace("\n", " "), subtitle.replace("\n", " ")
    titles, subtitles = title.split("\n"), subtitle.split("\n")

    # Proportions follow the 1206-wide iPhone upload, unless a class sets its
    # own type scale.
    unit = unit if unit is not None else width / 1206
    title_top = round((80 if one_line else 140) * unit)
    subtitle_top = title_top + len(titles) * round(TITLE_LINE * unit) + round(20 * unit)
    text_bottom = subtitle_top + len(subtitles) * round(SUBTITLE_LINE * unit)

    # The screen with display-like corners in a thin bezel, bleeding off the
    # bottom edge.
    top = text_bottom + round(70 * unit)
    screen_width = round(width * screen_share)
    screen_height = round(raw.height * screen_width / raw.width)
    screen = raw.convert("RGB").resize((screen_width, screen_height), Image.LANCZOS)
    radius = round(screen_width * corner)
    bezel = round(12 * unit)
    left = (width - screen_width) // 2
    device = (left - bezel, top - bezel, left + screen_width + bezel, top + screen_height + bezel)

    canvas = gradient(size, base)
    halo(canvas, device, radius + bezel, round(60 * unit), tint, text_bottom)
    check_text_contrast(canvas, (0, title_top, width, text_bottom), {"title": TITLE, "subtitle": tint}, label)

    draw = ImageDraw.Draw(canvas)
    centred_lines(draw, titles, font(round(TITLE_SIZE * unit), "Bold"),
                  round(TITLE_LINE * unit), title_top, width, TITLE)
    centred_lines(draw, subtitles, font(round(SUBTITLE_SIZE * unit), "Regular"),
                  round(SUBTITLE_LINE * unit), subtitle_top, width, tint)

    draw.rounded_rectangle([device[:2], device[2:]], radius=radius + bezel, fill=BEZEL)
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), screen.size], radius=radius, fill=255)
    canvas.paste(screen, (left, top), mask)
    return canvas


def main() -> None:
    for _, title, subtitle, (tint, base) in SCREENS:
        check_balanced(title)
        check_balanced(subtitle)
        print(f"{title.split(chr(10))[0]!r}: title {contrast(TITLE, base):.1f}:1, "
              f"subtitle {contrast(tint, base):.1f}:1 on its base")

    for folder, size, raw_folder, unit, share, corner, one_line in CLASSES:
        if not (HERE / raw_folder).is_dir():
            print(f"{folder}: no {raw_folder}/ yet, skipped")
            continue
        out = HERE / folder
        out.mkdir(exist_ok=True)
        for old in out.glob("*.png"):
            old.unlink()
        for index, (name, title, subtitle, palette) in enumerate(SCREENS, start=1):
            path = HERE / raw_folder / f"{name}.png"
            if not path.exists():
                print(f"{folder}: no {raw_folder}/{name}.png, skipped")
                continue
            listing = f"{index:02d}-{name.split('-', 1)[1]}.png"
            compose(Image.open(path), title, subtitle, palette, size, unit, share, corner,
                    one_line, f"{folder}/{listing}").save(out / listing, optimize=True)
            print(f"{folder}/{listing}")


if __name__ == "__main__":
    main()
