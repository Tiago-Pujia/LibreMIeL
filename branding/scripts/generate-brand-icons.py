#!/usr/bin/env python3
"""
Script de generación y normalización de iconos de marca para LibreMIeL.
Genera todas las resoluciones raster (PNG) en variantes cuadrada y circular,
y actualiza los recursos de los widgets nativos de Android.
"""

import os
import shutil
from pathlib import Path
from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
BRANDING_DIR = REPO_ROOT / "branding"
ICONS_DIR = BRANDING_DIR / "icons"
PNG_DIR = ICONS_DIR / "png"
ANDROID_RES_DIR = REPO_ROOT / "app" / "android" / "app" / "src" / "main" / "res"

SOURCE_PHOTO = Path("/home/tiago/GoogleDrive/Universidad/foto ds.png")

RESOLUTIONS = [512, 256, 128, 64, 48, 32]

ANDROID_DENSITIES = {
    "drawable": 192,
    "drawable-mdpi": 48,
    "drawable-hdpi": 72,
    "drawable-xhdpi": 96,
    "drawable-xxhdpi": 144,
    "drawable-xxxhdpi": 192,
}


def make_circular(img: Image.Image) -> Image.Image:
    """Aplica una máscara circular con antialiasing de alta calidad (supersampling 2x)."""
    w, h = img.size
    scale = 2
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, w * scale - 1, h * scale - 1), fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)

    circular = img.copy().convert("RGBA")
    circular.putalpha(mask)
    return circular


def main():
    if not SOURCE_PHOTO.exists():
        raise FileNotFoundError(f"No se encontró la foto fuente en: {SOURCE_PHOTO}")

    print(f"Cargando imagen fuente: {SOURCE_PHOTO}")
    source_img = Image.open(SOURCE_PHOTO).convert("RGBA")
    if source_img.size != (512, 512):
        source_img = source_img.resize((512, 512), Image.Resampling.LANCZOS)

    # 1. Copia maestra en branding/
    shutil.copy(SOURCE_PHOTO, BRANDING_DIR / "foto_ds.png")
    PNG_DIR.mkdir(parents=True, exist_ok=True)
    source_img.save(PNG_DIR / "master-512x512.png", format="PNG", optimize=True)

    # 2. Generar resoluciones estándar (cuadrada y circular)
    circular_master = make_circular(source_img)

    for size in RESOLUTIONS:
        size_dir = PNG_DIR / f"{size}x{size}"
        size_dir.mkdir(parents=True, exist_ok=True)

        # Cuadrada
        sq = source_img.resize((size, size), Image.Resampling.LANCZOS)
        sq.save(size_dir / f"libremiel-icon-square-{size}.png", format="PNG", optimize=True)
        # Nombre canónico sin sufijo en la carpeta
        sq.save(size_dir / "libremiel-icon-square.png", format="PNG", optimize=True)

        # Circular
        circ = circular_master.resize((size, size), Image.Resampling.LANCZOS)
        circ.save(size_dir / f"libremiel-icon-circle-{size}.png", format="PNG", optimize=True)
        circ.save(size_dir / "libremiel-icon-circle.png", format="PNG", optimize=True)
        # Alias general para app icon
        circ.save(size_dir / "libremiel-icon.png", format="PNG", optimize=True)

        print(f"  -> Generado {size}x{size} (square & circle)")

    # 3. Generar drawables para Android Widgets (ic_widget_logo.png)
    print("\nActualizando drawables de widgets Android...")
    for folder, size in ANDROID_DENSITIES.items():
        target_dir = ANDROID_RES_DIR / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        widget_icon = circular_master.resize((size, size), Image.Resampling.LANCZOS)
        out_file = target_dir / "ic_widget_logo.png"
        widget_icon.save(out_file, format="PNG", optimize=True)
        print(f"  -> {folder}/ic_widget_logo.png ({size}x{size})")

    print("\n¡Generación de branding e iconos completada exitosamente!")


if __name__ == "__main__":
    main()
