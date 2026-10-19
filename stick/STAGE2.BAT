@echo off
rem SPDX-License-Identifier: MIT
rem Copyright (c) 2026 Kaloyan Naumov
rem
rem STAGE 2 (only after the "ME IN MANUFACTURING MODE" message):
rem   snapshot 12 -> write 2013 boot block -> restore ME + GbE from snapshot 11
rem   -> snapshot 13 -> flash BIOS back to 3.96.
rem The boot block write takes ~30 s. Do NOT lose power during it.
rem
rem Method: bibikalka1 + BillDH2k, see README.md. This file only scripts it.
echo === STAGE 2: boot block 2013, restore ME + GbE, back to 3.96 ===
cd \TOOLS
call SNAPSHOT 12
fpt.exe -f BB2013.BIN -A 0xFF0000 -L 0x010000
fpt.exe -ME -f MEOO11.BIN
fpt.exe -GBE -f GBEO11.BIN
call SNAPSHOT 13
cd \V396
DOSFlash.exe /f flshuefi.cpu J63
cd \
echo.
echo === STAGE 2 DONE. Power off, unplug, restore jumpers (E14 off, ME override back, ===
echo === PSWD on), hold the BIOS reset button 10 s, boot, redo your F10 settings.     ===
