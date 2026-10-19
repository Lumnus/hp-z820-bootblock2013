@echo off
rem SPDX-License-Identifier: MIT
rem Copyright (c) 2026 Kaloyan Naumov
rem
rem STAGE 1 (normal mode, jumpers set: E14 on, ME override moved, PSWD off,
rem          a v1 Xeon fitted):
rem   snapshot 11 -> MEBLAST (uninitialised ME) -> flash BIOS 2.07.
rem After it finishes: press Ctrl-Alt-Del. The board power-cycles itself and
rem should come back reporting "MANAGEMENT PLATFORM (ME) IN MANUFACTURING MODE".
rem Then boot this stick again and run STAGE2.
rem
rem Method: bibikalka1 + BillDH2k, see README.md. This file only scripts it.
echo === STAGE 1: snapshot, MEBLAST, BIOS 2.07 ===
cd \TOOLS
call SNAPSHOT 11
cd \MEBLAST
MEBLAST.COM J63_0396.BIN
cd \V207
DOSFlash.exe /f flshuefi.cpu J63
cd \
echo.
echo === STAGE 1 DONE. Press Ctrl-Alt-Del (soft reboot, NOT power off). ===
echo === Expect: "ME IN MANUFACTURING MODE". Then boot this stick, run STAGE2. ===
