#!/bin/bash
set -e

# Script to download Debian Bookworm installer images into the repo
# Run this on a Linux runner or WSL (do not run on /mnt Windows filesystem)

BASE_URL="https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/cdrom"
OUTDIR="config/includes.binary_debian-installer/images/cdrom"
GTKDIR="$OUTDIR/gtk"

mkdir -p "$OUTDIR" "$GTKDIR"

echo "Downloading vmlinuz and initrd for installer (cdrom)..."
if ! wget -q -O "$OUTDIR/vmlinuz" "$BASE_URL/vmlinuz"; then
  echo "Failed to download $BASE_URL/vmlinuz" >&2
  exit 1
fi
if ! wget -q -O "$OUTDIR/initrd.gz" "$BASE_URL/initrd.gz"; then
  echo "Failed to download $BASE_URL/initrd.gz" >&2
  exit 1
fi

echo "Downloading gtk vmlinuz and initrd..."
if ! wget -q -O "$GTKDIR/vmlinuz" "$BASE_URL/gtk/vmlinuz"; then
  echo "Failed to download $BASE_URL/gtk/vmlinuz" >&2
  exit 1
fi
if ! wget -q -O "$GTKDIR/initrd.gz" "$BASE_URL/gtk/initrd.gz"; then
  echo "Failed to download $BASE_URL/gtk/initrd.gz" >&2
  exit 1
fi

echo "Installer images downloaded to $OUTDIR and $GTKDIR"
