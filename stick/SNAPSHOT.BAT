@echo off
rem SPDX-License-Identifier: MIT
rem Copyright (c) 2026 Kaloyan Naumov
rem
rem SNAPSHOT <nn> - dump the SPI flash, whole and per region, with Intel FPT.
rem Files land in the current directory, suffixed with <nn>.
rem Region offsets are those of the HP Z820 16 MB flash layout.
if "%1"=="" goto usage
fpt.exe -d FIRM%1.BIN
if errorlevel 1 goto fail
fpt.exe -DESC -d FDOO%1.BIN
if errorlevel 1 goto fail
fpt.exe -GBE -d GBEO%1.BIN
if errorlevel 1 goto fail
fpt.exe -PDR -d PDRO%1.BIN
if errorlevel 1 goto fail
fpt.exe -ME -d MEOO%1.BIN
if errorlevel 1 goto fail
fpt.exe -BIOS -d BIOS%1.BIN
if errorlevel 1 goto fail
fpt.exe -d BBLK%1.BIN -A 0xFF0000 -L 0x010000
if errorlevel 1 goto fail
goto end
:fail
echo SNAPSHOT %1 FAILED - see TOOLS\ERROR.LOG. Do not continue.
goto end
:usage
echo usage: SNAPSHOT nn
:end
