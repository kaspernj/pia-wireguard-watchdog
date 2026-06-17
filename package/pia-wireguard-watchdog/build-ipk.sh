#!/bin/sh
set -eu
umask 022

PKG_NAME="pia-wireguard-watchdog"
VERSION="0.1.4-1"
ARCH="all"

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
WORKSPACE="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$WORKSPACE/build/$PKG_NAME"
DIST_DIR="$WORKSPACE/dist"
PACKAGE_FILE="$DIST_DIR/${PKG_NAME}_${VERSION}_${ARCH}.ipk"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/control" "$BUILD_DIR/data" "$DIST_DIR"

cp -R "$SCRIPT_DIR/files/." "$BUILD_DIR/data/"
cp "$SCRIPT_DIR/control/"* "$BUILD_DIR/control/"

find "$BUILD_DIR/data" "$BUILD_DIR/control" -type d -exec chmod 0755 {} +
find "$BUILD_DIR/data" "$BUILD_DIR/control" -type f -exec chmod 0644 {} +
chmod 0755 "$BUILD_DIR/data/etc/init.d/pia-wireguard-watchdog"
chmod 0755 "$BUILD_DIR/data/usr/sbin/pia-wireguard-provision"
chmod 0755 "$BUILD_DIR/data/usr/sbin/pia-wireguard-watchdog"
chmod 0755 "$BUILD_DIR/control/postinst" "$BUILD_DIR/control/prerm"

printf "2.0\n" > "$BUILD_DIR/debian-binary"

(
  cd "$BUILD_DIR/control"
  tar --owner=0 --group=0 -czf "$BUILD_DIR/control.tar.gz" .
)

(
  cd "$BUILD_DIR/data"
  tar --owner=0 --group=0 -czf "$BUILD_DIR/data.tar.gz" .
)

rm -f "$PACKAGE_FILE"
(
  cd "$BUILD_DIR"
  tar --owner=0 --group=0 -czf "$PACKAGE_FILE" ./debian-binary ./data.tar.gz ./control.tar.gz
)

printf "%s\n" "$PACKAGE_FILE"
