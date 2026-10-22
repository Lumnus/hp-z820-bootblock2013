#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Kaloyan Naumov
#
# build-stick.sh <workdir> /dev/disk/by-id/usb-<your-stick>
#
# WIPES the given USB stick and writes:
#   partition 1: FreeDOS 1.4 LiteUSB (bootable, legacy/CSM boot)   -> C:
#   partition 2: FAT32 "Z820BB" with the payload from fetch.sh     -> D:
#
# The target must be given by /dev/disk/by-id/usb-* path, never /dev/sdX:
# sdX letters move between boots and this script erases what it is pointed at.
set -euo pipefail

W=${1:?usage: build-stick.sh <workdir> /dev/disk/by-id/usb-...}
ID=${2:?usage: build-stick.sh <workdir> /dev/disk/by-id/usb-...}
case "$ID" in /dev/disk/by-id/usb-*) ;; *) echo "refusing: give a /dev/disk/by-id/usb-* path" >&2; exit 1;; esac
case "$ID" in *-part[0-9]*) echo "refusing: give the whole stick, not a partition" >&2; exit 1;; esac
DEV=$(readlink -f "$ID")
[ "$(lsblk -dno TRAN "$DEV")" = usb ] || { echo "refusing: $DEV is not a USB device" >&2; exit 1; }
[ -f "$W/FD14LITE.img" ] && [ -d "$W/payload" ] || { echo "run fetch.sh first" >&2; exit 1; }

lsblk -o NAME,SIZE,MODEL,LABEL "$DEV"
read -r -p "ERASE $DEV ($ID)? type YES: " ok; [ "$ok" = YES ] || exit 1

for p in "$DEV"?*; do umount "$p" 2>/dev/null || true; done
dd if="$W/FD14LITE.img" of="$DEV" bs=4M conv=fsync status=none
udevadm settle; blockdev --rereadpt "$DEV"; udevadm settle
END=$(sfdisk -l -o End "$DEV" | tail -1 | tr -d ' ')
echo "start=$((END + 2048)), type=c" | sfdisk -a -q "$DEV"
udevadm settle; blockdev --rereadpt "$DEV"; udevadm settle
P2=$(lsblk -lnpo NAME "$DEV" | sed -n 3p)
mkfs.vfat -F 32 -n Z820BB "$P2" >/dev/null
M=$(mktemp -d); mount -t vfat "$P2" "$M"
cp -r "$W/payload/." "$M/"
sync; (cd "$M" && find . -type f | sort); umount "$M"; rmdir "$M"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$DEV"
echo "stick ready. Boot it in legacy mode (F9 on HP), choose 'return to DOS', then: D:  STAGE1"
