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
if exist MEOO11.BIN goto stale
if exist GBEO11.BIN goto stale
call SNAPSHOT 11
if not exist MEOO11.BIN goto nosnap
if not exist GBEO11.BIN goto nosnap
if not exist FIRM11.BIN goto nosnap
cd \MEBLAST
MEBLAST.COM J63_0396.BIN
cd \V207
DOSFlash.exe /f flshuefi.cpu J63
cd \
echo.
echo === STAGE 1 DONE. Press Ctrl-Alt-Del (soft reboot, NOT power off). ===
echo === Expect: "ME IN MANUFACTURING MODE". Then boot this stick, run STAGE2. ===
goto end
:stale
cd \
echo === STOP: TOOLS already holds a snapshot 11 (another board or an earlier run?). ===
echo === STAGE2 would restore THAT ME + GbE (MAC). Move *11/*12/*13.BIN off the stick first. ===
goto end
:nosnap
cd \
echo === STOP: snapshot 11 missing. Nothing was flashed. Fix TOOLS (fparts.txt?) and re-run. ===
:end
