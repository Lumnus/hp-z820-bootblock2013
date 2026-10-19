# HP Z820 — 2013 boot block, software only, scripted

Upgrade the boot block of an HP **Z820** from the 2011 version to the **2013**
version (needed for Xeon E5 **v2** / Ivy Bridge-EP CPUs) **without a chip clip or
programmer**, using a FreeDOS USB stick and two batch files — and check the result
from Linux afterwards instead of trusting the BIOS screen.

This repository does not invent the method. It packages it:

* **The method** — triggering *ME manufacturing mode* (MEBLAST + BIOS 2.07) so that
  Intel FPT can write the whole flash chip, boot block included — is the work of
  **[bibikalka1](https://github.com/bibikalka1/HP_Z420_Z620_Z820_BOOTBLOCK2013_BIOS_mod)**,
  co-developed and tested with **BillDH2k**. Read his guide; it is the reference.
* **The groundwork** — flash layout, boot-block region, the hardware (clip) route,
  and years of collected HP workstation knowledge — is
  **[SuperThunder's guide](https://github.com/SuperThunder/HP_Z420_Z620_Z820_BootBlock_Upgrade)**.
* **Added here:** the procedure as two batch files on a reproducible FreeDOS 1.4
  stick, a fetch script that pulls every third-party file from its original
  publisher and checks it against a pinned hash, and a read-only Linux verifier.

## Status — read this

* **Tested once, on one board:** HP Z820, assembly **618266-002** (SP# 708464-001),
  PCB rev 1.01, BIOS 03.96, ME 8.1.10 already installed, 2× Xeon E5-2640 (v1),
  2026-10-19. Result verified on the chip: boot block went from
  `CRTM J63 v00.71, 12/28/2011` to `CRTM J63 v03.04, 03/06/2013`, byte-identical to
  the last 64 KB of HP's own 03.96 image; GbE region (MACs) unchanged; ME back to
  normal operation.
* **Made for and tested on the Z820 only.** The scripts use the Z820 (J63) files.
* The batch files in this repository are a cleaned-up repackaging of the ones that
  ran on that board (same commands, same order; the backup step is a re-written
  `SNAPSHOT.BAT` instead of the guide's `backup.bat`). Treat the first run on your
  board as a first run.
* **You can brick your board.** A power cut during the ~30 s boot-block write leaves
  a board that does not POST; recovery then needs a SPI programmer and your backup.
  No warranty — see the licences.

## Requirements

| | |
|---|---|
| Board | Z820 with the **E14** header present (assembly 618266-002/-003 and later). The earliest -001 boards have only pads there: this method does not apply — use the clip route. |
| Boot block | Still 2011? Check F10 → File → System Information → *Boot Block Date*, or `verify.py`. If it already says 03/06/2013 there is nothing to do. |
| CPU during the procedure | a **v1** Xeon (BIOS 2.07 refuses to flash on v2). |
| ME | 8.x. If the board is on ME 7, follow bibikalka1's Section 2 first. |
| Stick | ≥ 128 MB USB stick, legacy (CSM) boot enabled in F10. |
| Linux machine | to run `fetch.sh` / `build-stick.sh` (curl, p7zip, unzip, dosfstools, util-linux). `flashrom` on the Z820 itself for `verify.py`. |

## Procedure

1. **Back up first.** From Linux on the Z820: `flashrom -p internal --ifd -i bios -i gbe -r before.bin`
   (with the ME override jumper moved you can read the whole chip). Keep it off the
   machine. STAGE1 also takes a full FPT snapshot to the stick.
2. **Build the stick** (on any Linux box):
   ```
   scripts/fetch.sh ~/z820
   sudo scripts/build-stick.sh ~/z820 /dev/disk/by-id/usb-<your-stick>
   ```
3. **Jumpers** (box unplugged, standby LED out):
   * **E14** (2-pin, under PCIe slot 4): **on**.
   * **E1 / ME FO** (3-pin, ME flash override; under the CPU0 memory on PCB ≥ 1.01): move to the **other** position. Photograph before.
   * **PSWD** (password / downgrade protection): **off** (BIOS 2.07 is a downgrade).
4. **STAGE 1:** F9 → the *legacy* USB entry → FreeDOS installer → *No – return to DOS* →
   ```
   D:
   STAGE1
   ```
   Snapshot → MEBLAST → BIOS 2.07. Then **Ctrl-Alt-Del** (soft reboot, not power-off).
   The board power-cycles itself and reports **MANAGEMENT PLATFORM (ME) IN MANUFACTURING MODE**.
   No such message → stop, do not run STAGE2.
5. **STAGE 2:** boot the stick again → `D:` → `STAGE2`.
   Snapshot → **boot block write (~30 s, keep power)** → restore ME and GbE from the
   STAGE1 snapshot (this also leaves manufacturing mode) → snapshot → BIOS back to 3.96.
6. **Restore:** power off, unplug, E14 off, E1 back, PSWD on, BIOS reset button 10 s,
   boot, redo your F10 settings.
7. **Verify** from Linux on the Z820:
   ```
   sudo scripts/verify.py --hp-image ~/z820/payload/V396/J63_0396.BIN --gbe-backup before.bin
   ```

## What is *not* in this repository, and why

| Item | Owner | Where it comes from |
|---|---|---|
| BIOS 2.07 / 3.96 images, DOSFlash, flshuefi.cpu, MEBLAST | HP (proprietary) | `fetch.sh` downloads HP SoftPaqs sp59187, sp100128, sp59993 from ftp.hp.com |
| The 2013 boot block | HP | cut by `fetch.sh` from HP's own 3.96 image (last 64 KB) |
| fpt.exe | Intel (proprietary) | `fetch.sh` downloads bibikalka1's public IMET8.zip and uses only fpt.exe, pinned by sha256 |
| FreeDOS 1.4 | GPL | `fetch.sh`, from ibiblio.org, sha256 per FreeDOS' verify.txt |
| Any flash dump | yours | never publish one: it carries your serial number, MACs, UUID and ME state |

## Findings along the way

See [docs/FINDINGS.md](docs/FINDINGS.md): why E14 alone is not enough, why HP's own
flasher never writes the boot block, and what that means for doing it from Linux.

## Licences

* Scripts (`scripts/`, `stick/`): **MIT** — see [LICENSE](LICENSE).
* Documentation (`README.md`, `docs/`): **CC BY-SA 4.0** — see [LICENSES-CC-BY-SA-4.0.txt](LICENSES-CC-BY-SA-4.0.txt).
* bibikalka1's repository currently carries no licence; nothing from it is copied here.
  SuperThunder's guide is MIT.

Copyright © 2026 Kaloyan Naumov.
