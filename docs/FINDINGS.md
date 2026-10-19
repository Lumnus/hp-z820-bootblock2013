# Findings — HP Z820 boot block, seen from Linux

*CC BY-SA 4.0 — Kaloyan Naumov, 2026. Measured on one Z820 (618266-002, BIOS 03.96,
ME 8.1.10, Proxmox VE 9 / Linux 7.0) on 2026-10-19 with flashrom and HP's tools.*

These explain *why* the manufacturing-mode route is needed. None of them is required
reading to run the procedure.

## Flash layout (16 MB, Winbond W25Q128)

| Region | Range |
|---|---|
| Descriptor | 0x000000–0x000FFF |
| GbE (82579LM NVM, MAC) | 0x001000–0x002FFF |
| Platform data | 0x003000–0x004FFF |
| ME | 0x005000–0x50FFFF |
| BIOS | 0x510000–0xFFFFFF |
| … of which variables/settings | 0x510000–0x57FFFF (differs per machine and per boot) |
| … of which boot block | **0xFF0000–0xFFFFFF** (64 KB) |

Between the 2011 (`v00.71`) and 2013 (`v03.04`) boot blocks only five 4 KB blocks
differ: 0xFF0000 and 0xFFC000–0xFFFFFF.

## Two locks, not one

Normal state, read with `flashrom -p internal`:

* `PR0: 0x00ff0000-0x00ffffff is read-only` — a protected-range register set by the
  BIOS over the boot block.
* `BIOS region SMM protection is enabled` (BIOS_CNTL = 0x2b: BLE + BIOSWE + SMM_BWP),
  `SPI Configuration is locked down` (FLOCKDN = 1).

With the **E14** jumper fitted:

* **PR0 is gone** — the BIOS no longer sets the boot-block range lock.
* **SMM_BWP is still set.** A test write of 16 bytes into an empty 4 KB block of the
  BIOS region from Linux failed (`Write failed at 0xbc5000`); the block read back
  unchanged and the rest of the chip was unaffected.

So E14 is necessary but not sufficient: writes from the OS are still refused by the
chipset unless they come from SMM.

## HP's own flasher never writes the boot block

`hp-flash` (HP Linux Tools 3.26) talks to the BIOS through a software SMI
(port 0xB2, function 0xB88) with a `ROMIMAGE` / `V1.1` header in a shared physical
buffer. Sub-commands observed: 0x00 query, 0x03 transfer chunk, 0x09 flash,
0x0A and 0x12 (logo). The header carries offset/length of the transfer only — no
region or boot-block selector. The decision what to write is made by the BIOS's SMM
handler.

Run with E14 fitted and the same 03.96 image: "successfully reprogrammed", the BIOS
code region matched the HP image exactly afterwards, and the boot block was
**byte-identical to before**. The SMM handler skips 0xFF0000–0xFFFFFF regardless of E14.

## Why manufacturing mode works

After MEBLAST writes an uninitialised ME region and BIOS **2.07** is flashed, the next
soft reboot comes up in *ME manufacturing mode*, and BIOS 2.07 then leaves the
protected-range locks off, so Intel FPT can write the boot block (bibikalka1; BIOS
3.50+ keep the locks on even in this mode). Restoring the ME and GbE regions from the
pre-procedure snapshot ends manufacturing mode; flashing 3.96 afterwards restores the
current BIOS on top of the new boot block.

## An open lead (untested)

With the ME override header (E1) moved, the descriptor and ME regions become
`read-write` for flashrom under Linux. Whether the MEBLAST step could therefore be
replaced by writing the ME region from Linux — removing the first DOS boot — is
untested. Treat it as a question.

## Other observations on the same board

* BIOS 02.55 → 03.96 can be flashed from a running Linux with `hp-flash` 3.26 and HP's
  Z820 Linux SoftPaq (sp100128); HP's changelog only requires a stepping stone for
  boards still on 01.02.
* The GbE region (82579LM MAC + NVM) lives in the same chip. Back it up before any
  full-chip work; it was intact throughout.
