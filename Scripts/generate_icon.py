#!/usr/bin/env python3
"""Generates the 1024x1024 App Store icon for SquareFit.

Run:  python3 Scripts/generate_icon.py
Requires Pillow (pip install Pillow).

The icon is rendered at 4x and downsampled for smooth edges. It is written
without an alpha channel and without rounded corners, as App Store Connect
requires (iOS applies the corner mask itself).
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "SquareFit/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
SIZE = 1024
SS = 4  # supersampling factor
S = SIZE * SS


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def gradient_background(top, bottom):
    """Vertical gradient with a slight diagonal lean."""
    img = Image.new("RGB", (S, S), top)
    px = img.load()
    for y in range(S):
        for x in range(0, S, 8):
            t = (y / S) * 0.8 + (x / S) * 0.2
            c = lerp(top, bottom, t)
            for dx in range(8):
                px[x + dx, y] = c
    return img


def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def main():
    top = (52, 120, 246)      # bright blue
    bottom = (98, 54, 220)    # indigo
    img = gradient_background(top, bottom)
    draw = ImageDraw.Draw(img)

    # Soft drop shadow beneath the white square card.
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    margin = int(S * 0.17)
    card = (margin, margin, S - margin, S - margin)
    rounded_rect(sd, (card[0], card[1] + int(S * 0.02), card[2], card[3] + int(S * 0.02)),
                 int(S * 0.06), (0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(S * 0.02))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(img)

    # The white square card: the "square" the app produces.
    rounded_rect(draw, card, int(S * 0.06), (255, 255, 255))

    # A landscape photo centred inside the square, leaving white bands top
    # and bottom, exactly what the app does to a landscape picture.
    card_w = card[2] - card[0]
    photo_h = int(card_w * 0.60)
    photo_margin = int(S * 0.045)
    photo_top = card[1] + (card_w - photo_h) // 2
    photo = (card[0] + photo_margin, photo_top, card[2] - photo_margin, photo_top + photo_h)

    # Photo background: sky gradient.
    sky = Image.new("RGB", (photo[2] - photo[0], photo[3] - photo[1]))
    spx = sky.load()
    w, h = sky.size
    sky_top, sky_bottom = (255, 176, 92), (255, 118, 128)
    for y in range(h):
        c = lerp(sky_top, sky_bottom, y / h)
        for x in range(w):
            spx[x, y] = c
    mask = Image.new("L", sky.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=int(S * 0.025), fill=255)
    img.paste(sky, (photo[0], photo[1]), mask)

    # Draw sun and mountains onto an overlay clipped to the photo.
    overlay = Image.new("RGBA", sky.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    r = int(h * 0.16)
    od.ellipse((int(w * 0.68) - r, int(h * 0.30) - r, int(w * 0.68) + r, int(h * 0.30) + r),
               fill=(255, 244, 214, 255))
    # Back mountain
    od.polygon([(0, h), (int(w * 0.38), int(h * 0.38)), (int(w * 0.72), h)], fill=(104, 70, 190, 255))
    # Front mountain
    od.polygon([(int(w * 0.30), h), (int(w * 0.66), int(h * 0.52)), (w, h)], fill=(64, 42, 150, 255))
    # Ground
    od.rectangle((0, int(h * 0.93), w, h), fill=(52, 34, 130, 255))
    overlay.putalpha(Image.composite(overlay.getchannel("A"), Image.new("L", sky.size, 0), mask))
    img.paste(overlay, (photo[0], photo[1]), overlay)

    # Downsample with a high-quality filter and save as opaque RGB PNG.
    final = img.resize((SIZE, SIZE), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    final.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} ({final.size[0]}x{final.size[1]}, mode {final.mode})")


if __name__ == "__main__":
    main()
