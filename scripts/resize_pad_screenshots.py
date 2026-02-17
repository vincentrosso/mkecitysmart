#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageColor, ImageOps


def iter_inputs(input_dir: Path) -> list[Path]:
    patterns = ("*.png", "*.PNG", "*.jpg", "*.JPG", "*.jpeg", "*.JPEG")
    files: set[Path] = set()
    for pattern in patterns:
        files.update(input_dir.glob(pattern))
    return sorted(files)


def resize_pad_image(
    input_path: Path,
    output_path: Path,
    target_w: int,
    target_h: int,
    bg_rgb: tuple[int, int, int],
) -> tuple[tuple[int, int], tuple[int, int]]:
    image = Image.open(input_path)
    image = ImageOps.exif_transpose(image)

    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGB")

    src_w, src_h = image.size
    scale = min(target_w / src_w, target_h / src_h)

    new_w = max(1, round(src_w * scale))
    new_h = max(1, round(src_h * scale))

    resized = image.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGB", (target_w, target_h), bg_rgb)
    left = (target_w - new_w) // 2
    top = (target_h - new_h) // 2

    if resized.mode == "RGBA":
        canvas.paste(resized, (left, top), resized)
    else:
        canvas.paste(resized, (left, top))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, format="PNG", optimize=True)

    return (src_w, src_h), (new_w, new_h)


def main() -> int:
    parser = argparse.ArgumentParser(description="Resize screenshots with padding (no crop).")
    parser.add_argument("--in", dest="input_dir", required=True, help="Input directory")
    parser.add_argument("--out", dest="output_dir", required=True, help="Output directory")
    parser.add_argument("--width", type=int, required=True, help="Target width")
    parser.add_argument("--height", type=int, required=True, help="Target height")
    parser.add_argument("--bg", default="#081D19", help="Background color (hex), default #081D19")

    args = parser.parse_args()

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)

    if not input_dir.exists() or not input_dir.is_dir():
        raise SystemExit(f"Input dir not found: {input_dir}")

    bg_rgb = ImageColor.getrgb(args.bg)

    inputs = iter_inputs(input_dir)
    if not inputs:
        raise SystemExit(f"No images found in: {input_dir}")

    for input_path in inputs:
        output_path = output_dir / input_path.name
        (src_w, src_h), (content_w, content_h) = resize_pad_image(
            input_path=input_path,
            output_path=output_path,
            target_w=args.width,
            target_h=args.height,
            bg_rgb=bg_rgb,
        )
        print(
            f"{input_path.name}: {src_w}x{src_h} -> {args.width}x{args.height} "
            f"(content {content_w}x{content_h})"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
