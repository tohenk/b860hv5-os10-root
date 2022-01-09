@echo off

:: AMLogic Backup Utility
:: Copyright (c) 2022 Toha <tohenk@yahoo.com>
::
:: Last Modified: Jan 09, 2022

title AMLogic Backup Utility
echo AMLogic Backup Utility
echo (c) 2022 Toha ^<tohenk@yahoo.com^>
echo --------------------------------
echo.

setlocal

:: Change to current directory,
:: vista run as administrator always start from SYSDIR
%~d0
cd %~dp0
set CD=%~dp0

:: Must be run as admin, https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights#11995662
net session >nul 2>&1
if not %ERRORLEVEL%==0 goto :err_need_admin

set BIN=%CD%bin
set TMPDIR=%CD%tmp
set OUTDIR=%CD%out

set FLASHTOOL=%BIN%\aml-flash-tool
set UPDATER=%FLASHTOOL%\update.exe
set SCANOUT=%TMPDIR%\~dev.txt
set LOG=%TMPDIR%\~backup.txt

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo Detecting device...
%UPDATER% scan>%SCANOUT%
findstr "port[0-9]*" %SCANOUT%>nul
if %ERRORLEVEL% equ 0 (
  echo Device connected...
  echo.
) else (
  echo Device not connected...
  goto :end
)

if exist "%OUTDIR%" rmdir /s /q "%OUTDIR%"
mkdir "%OUTDIR%"

::Partition Map for MMC device 1  --   Partition Type: AML
::
::Part   Start     Sect x Size Type  name
:: 00        0     8192    512 U-Boot bootloader
:: 01    73728   131072    512 U-Boot reserved
:: 02   221184  2048000    512 U-Boot cache
:: 03  2285568    16384    512 U-Boot env
:: 04  2318336    16384    512 U-Boot logo
:: 05  2351104    49152    512 U-Boot recovery
:: 06  2416640    16384    512 U-Boot misc
:: 07  2449408     8192    512 U-Boot conf
:: 08  2473984    16384    512 U-Boot dtbo
:: 09  2506752    16384    512 U-Boot cri_data
:: 10  2539520    32768    512 U-Boot param
:: 11  2588672    32768    512 U-Boot boot
:: 12  2637824    32768    512 U-Boot oem
:: 13  2686976    32768    512 U-Boot metadata
:: 14  2736128     4096    512 U-Boot vbmeta
:: 15  2756608    65536    512 U-Boot tee
:: 16  2838528    16384    512 U-Boot factory
:: 17  2871296  3686400    512 U-Boot super
:: 18  6574080  8695808    512 U-Boot data

echo Begin backup...
call :backup_partition "%OUTDIR%" bootloader:0x400000 reserved:0x4000000 cache:0x3e800000 env:0x800000 logo:0x800000 recovery:0x1800000 misc:0x800000 conf:0x400000 dtbo:0x800000 cri_data:0x800000 param:0x1000000 boot:0x1000000 oem:0x1000000 metadata:0x1000000 vbmeta:0x200000 tee:0x2000000 factory:0x800000 super:0x70800000 data:0x109600000
echo.
echo Backup done, copy "%OUTDIR%" to somewhere safe...
echo.

goto :end

:backup_partition
  set DIR=%~1
:backup_partition_loop
  set PART=%~2
  for /f "tokens=1,2 delims=:" %%a in ("%PART%") do (
    set PARTNAME=%%a
    set PARTSIZE=%%b
  )
  set IMG=%DIR%\%PARTNAME%.PARTITION
  if not [%PART%]==[] (
    call :do_backup_partition %PARTNAME% %PARTSIZE% "%IMG%"
    shift
    goto :backup_partition_loop
  )
  goto :eof

:do_backup_partition
  set PARTITION=%~1
  set SZ=%~2
  set IMAGE=%~3
  echo Backup partition %PARTITION%...
  %UPDATER% mread store %PARTITION% normal %SZ% "%IMAGE%">>%LOG%
  goto :eof

:err_need_admin
  echo You need to be an Administrator
  goto :end

:end
endlocal