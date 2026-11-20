#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
FLUTTER_ARCH="${2:-x64}"

case "$FLUTTER_ARCH" in
  x64)
    APPIMAGE_ARCH="x86_64"
    ;;
  arm64)
    APPIMAGE_ARCH="aarch64"
    ;;
  *)
    echo "Error: arquitectura no soportada '$FLUTTER_ARCH' (usar 'x64' o 'arm64')." >&2
    exit 1
    ;;
esac

BUNDLE_DIR="build/linux/${FLUTTER_ARCH}/release/bundle"
APPDIR="build/appimage/LibreMIEL-${FLUTTER_ARCH}.AppDir"
OUT_DIR="dist/linux-${FLUTTER_ARCH}"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: no existe $BUNDLE_DIR. Ejecutá primero 'flutter build linux --release'." >&2
  exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$OUT_DIR"

cp -a "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
cp packaging/linux/libremiel.desktop "$APPDIR/io.github.tiago_pujia.libremiel.desktop"
cp packaging/linux/libremiel.desktop "$APPDIR/usr/share/applications/io.github.tiago_pujia.libremiel.desktop"
cp packaging/linux/libremiel.png "$APPDIR/io.github.tiago_pujia.libremiel.png"
cp packaging/linux/libremiel.png "$APPDIR/usr/share/icons/hicolor/256x256/apps/io.github.tiago_pujia.libremiel.png"

cat > "$APPDIR/AppRun" << 'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/usr/bin/libremiel" "$@"
EOF
chmod +x "$APPDIR/AppRun"

ARCH="$APPIMAGE_ARCH" appimagetool --appimage-extract-and-run "$APPDIR" \
  "$OUT_DIR/LibreMIEL-${VERSION}-linux-${FLUTTER_ARCH}.AppImage"
