#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-0.1.0}"
BUNDLE_DIR="build/linux/x64/release/bundle"
APPDIR="build/appimage/LibreMIEL.AppDir"
OUT_DIR="dist/linux"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: no existe $BUNDLE_DIR. Ejecutá primero 'flutter build linux --release'." >&2
  exit 1
fi

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" \
         "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/scalable/apps" \
         "$OUT_DIR"

cp -a "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
cp packaging/linux/libremiel.desktop "$APPDIR/io.github.tiago_pujia.libremiel.desktop"
cp packaging/linux/libremiel.desktop "$APPDIR/usr/share/applications/io.github.tiago_pujia.libremiel.desktop"
cp packaging/linux/libremiel.svg "$APPDIR/io.github.tiago_pujia.libremiel.svg"
cp packaging/linux/libremiel.svg "$APPDIR/usr/share/icons/hicolor/scalable/apps/io.github.tiago_pujia.libremiel.svg"

cat > "$APPDIR/AppRun" << 'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="$HERE/usr/bin/lib:${LD_LIBRARY_PATH:-}"
exec "$HERE/usr/bin/libremiel" "$@"
EOF
chmod +x "$APPDIR/AppRun"

ARCH=x86_64 appimagetool --appimage-extract-and-run "$APPDIR" \
  "$OUT_DIR/LibreMIEL-${VERSION}-linux-x64.AppImage"
