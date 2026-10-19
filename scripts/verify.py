#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Kaloyan Naumov
"""verify.py - check, from a running Linux system, what is actually on the chip.

Reads the BIOS (and GbE) regions with flashrom - read-only - twice, and reports:
  * which boot block is present (CRTM version + date), and whether it is
    byte-identical to the 2013 boot block cut from HP's BIOS 3.96 image;
  * whether the BIOS code (0x580000 onward) matches a given HP image;
  * optionally, whether the GbE region still matches a pre-procedure backup
    (MAC addresses / NIC NVM intact).

Usage (root):
  verify.py --hp-image J63_0396.bin [--gbe-backup full-before.bin]

Notes:
  * Works with the normal jumper state. The ME region is locked then, so a
    whole-chip read is refused; BIOS + GbE regions are readable.
  * 0x510000-0x57FFFF holds BIOS settings/variables and differs per machine.
"""
import argparse, os, re, subprocess, sys, tempfile

BB, BIOS_CODE, END = 0xFF0000, 0x580000, 0x1000000


def read_regions(regions):
    fd, path = tempfile.mkstemp(suffix=".bin"); os.close(fd)
    args = ["flashrom", "-p", "internal", "--ifd"]
    for r in regions:
        args += ["-i", r]
    subprocess.run(args + ["-r", path], check=True, capture_output=True)
    with open(path, "rb") as f:
        data = f.read()
    os.unlink(path)
    return data


def crtm(blob):
    v = re.search(rb"CRTM_START J\d\d v([0-9.]+)", blob)
    d = re.search(rb"(\d\d/\d\d/20\d\d) \d\d:\d\d:\d\d CRTM_END", blob)
    return (v.group(1).decode() if v else "?", d.group(1).decode() if d else "?")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hp-image", required=True, help="HP full BIOS image, e.g. J63_0396.bin")
    ap.add_argument("--gbe-backup", help="full 16 MB dump taken before the procedure")
    a = ap.parse_args()

    hp = open(a.hp_image, "rb").read()
    regions = ["bios", "gbe"] if a.gbe_backup else ["bios"]
    r1, r2 = read_regions(regions), read_regions(regions)
    ok = True

    stable = r1[BB:END] == r2[BB:END]
    print(f"two reads agree on boot block : {stable}"); ok &= stable
    v, d = crtm(r1[BB:END])
    print(f"boot block on chip            : CRTM v{v}, {d}")
    same = r1[BB:END] == hp[BB:END]
    print(f"== boot block in HP image     : {same}  (HP image: CRTM v{crtm(hp[BB:END])[0]}, {crtm(hp[BB:END])[1]})")
    ok &= same

    diff = [o for o in range(BIOS_CODE, BB, 4096) if r1[o:o + 4096] != hp[o:o + 4096]]
    print(f"BIOS code blocks != HP image  : {len(diff)}"); ok &= not diff

    if a.gbe_backup:
        bk = open(a.gbe_backup, "rb").read()
        g = r1[0x1000:0x3000] == bk[0x1000:0x3000]
        print(f"GbE region == backup          : {g}  (MAC {r1[0x1000:0x1006].hex(':')})"); ok &= g

    print("RESULT:", "OK" if ok else "MISMATCH - investigate before trusting the board")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
