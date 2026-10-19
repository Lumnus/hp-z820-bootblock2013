#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Kaloyan Naumov
#
# fetch.sh <workdir>
#
# Downloads every third-party file the procedure needs from its original
# publisher, checks it against a pinned hash, and lays out a stick payload in
# <workdir>/payload. Nothing third-party is shipped in this repository.
#
#   HP     : BIOS 2.07, BIOS 3.96, ME8/MEBLAST SoftPaqs  (ftp.hp.com)
#   Intel  : fpt.exe, from bibikalka1's public IMET8.zip  (github.com)
#   FreeDOS: 1.4 LiteUSB                                  (ibiblio.org)
#
# The 2013 boot block is NOT downloaded as a separate file: it is the last
# 64 KB of HP's own BIOS 3.96 image and is cut out of it here.
#
# Needs: curl, 7z (p7zip-full), tar, unzip, md5sum, sha256sum.
set -euo pipefail

HERE=$(cd "$(dirname "$0")/.." && pwd)
W=${1:?usage: fetch.sh <workdir>}
mkdir -p "$W/dl" "$W/x"
W=$(cd "$W" && pwd)
cd "$W"

get() { # url dest hash-kind expected
    local url=$1 dst=$2 kind=$3 want=$4 got
    [ -f "$dst" ] || curl -sSfL -o "$dst" "$url"
    got=$("${kind}sum" "$dst" | cut -d' ' -f1)
    if [ "$got" != "$want" ]; then
        echo "HASH MISMATCH: $dst ($kind) got $got want $want" >&2; exit 1
    fi
    echo "ok  $dst"
}

HP=https://ftp.hp.com/pub/softpaq
# HP Z820 System BIOS 02.07 (DOS Flash)
get $HP/sp59001-59500/sp59187.exe   dl/sp59187.exe  md5 47b03dd2c4f29283a2fbd413d601725a
# HP Z820 System Linux BIOS 03.96 (carries the DOS Flash folder too); MD5 as published by HP
get $HP/sp100001-100500/sp100128.tgz dl/sp100128.tgz md5 30a759d6d99eca3a932acbd80a852eb3
# HP Workstations ME Firmware Update 8.1.10.1286 (contains MEBLAST.com)
get $HP/sp59501-60000/sp59993.exe   dl/sp59993.exe  md5 3e65d5b37d44a82503063c2432bf2933
# FreeDOS 1.4 LiteUSB, sha256 per freedos verify.txt
get https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.4/FD14-LiteUSB.zip \
    dl/FD14-LiteUSB.zip sha256 857dcd2ebf9d3d094320154db5fb5b830acba6fb98f981a95a0ca7ab3350338b
# Intel Flash Programming Tool, as bundled in bibikalka1's IMET8.zip (only fpt.exe is used)
get https://raw.githubusercontent.com/bibikalka1/HP_Z420_Z620_Z820_BOOTBLOCK2013_BIOS_mod/main/IMET8.zip \
    dl/IMET8.zip sha256 102415c937d446250a20238efc0df8ed381b20c3f132ef48159a21adea196d99

7z x -y -ox/sp59187 dl/sp59187.exe >/dev/null
mkdir -p x/sp100128 && tar xzf dl/sp100128.tgz -C x/sp100128
7z x -y -ox/sp59993 dl/sp59993.exe >/dev/null
unzip -oq dl/FD14-LiteUSB.zip -d x/freedos
unzip -oq dl/IMET8.zip -d x/imet8

FPT=$(find x/imet8 -name fpt.exe | head -1)
echo "52ac5906e78358c10aec03844716b668ed2945918fc3fecbc2f6decec4d72e2d  $FPT" | sha256sum -c --quiet
echo "ok  fpt.exe"

B396=$(find x/sp100128 -name 'J63_0396.bin' | head -1)
echo "90ee92922a781390d604ded1f8656003  $B396" | md5sum -c --quiet
B207=$(find x/sp59187 -iname 'J63_0207.BIN' | head -1)
MEB=$(find x/sp59993 -name 'MEBLAST.com' | head -1)
echo "434c2444457250cf64515f29adf298fb  $MEB" | md5sum -c --quiet
echo "f539d456b792594bc3ca59d4e0f4c23d4f1fee73370c1390b2da245400718d36  x/freedos/FD14LITE.img" | sha256sum -c --quiet

P=$W/payload; rm -rf "$P"; mkdir -p "$P"/{TOOLS,MEBLAST,V207,V396}
cp "$HERE"/stick/STAGE1.BAT "$HERE"/stick/STAGE2.BAT "$P"/
cp "$HERE"/stick/SNAPSHOT.BAT "$FPT" "$P"/TOOLS/
tail -c 65536 "$B396" > "$P"/TOOLS/BB2013.BIN
echo "710063142bc456314ba3da04976e9ee8814b8448993d6ba851b70c5011e3ba3f  $P/TOOLS/BB2013.BIN" | sha256sum -c --quiet
cp "$MEB" "$P"/MEBLAST/MEBLAST.COM
cp "$B396" "$P"/MEBLAST/J63_0396.BIN
D207=$(dirname "$B207"); cp "$D207"/DOSFlash.exe "$D207"/flshuefi.cpu "$P"/V207/; cp "$B207" "$P"/V207/J63_0207.BIN
D396=$(dirname "$B396"); cp "$D396"/DOSFlash.exe "$D396"/flshuefi.cpu "$P"/V396/; cp "$B396" "$P"/V396/J63_0396.BIN
for f in "$P"/*.BAT "$P"/TOOLS/*.BAT; do sed -i 's/\r*$/\r/' "$f"; done
cp x/freedos/FD14LITE.img "$W"/FD14LITE.img

echo
echo "payload ready: $P"
echo "2013 boot block: $(strings -n 6 "$P"/TOOLS/BB2013.BIN | grep -o 'CRTM_START J63 v[0-9.]*') $(strings -n 6 "$P"/TOOLS/BB2013.BIN | grep -m1 -oE '[0-9]{2}/[0-9]{2}/20[0-9]{2}')"
echo "next: scripts/build-stick.sh $W /dev/disk/by-id/usb-..."
