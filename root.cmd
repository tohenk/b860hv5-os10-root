@echo off

:: ZTE B860H v5 OS 10 Root
:: Copyright (c) 2022 Toha <tohenk@yahoo.com>
::
:: Last Modified: Feb 20, 2022

title ZTE B860H v5 OS 10 Root
echo ZTE B860H v5 OS 10 Root
echo (c) 2022 Toha ^<tohenk@yahoo.com^>
echo --------------------------------
echo.

setlocal EnableDelayedExpansion

:: Change to current directory,
:: vista run as administrator always start from SYSDIR
%~d0
cd %~dp0
set CD=%~dp0

:: Must be run as admin, https://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights#11995662
net session >nul 2>&1
if not %ERRORLEVEL%==0 goto :err_need_admin

set BIN=%CD%bin
set CONFDIR=%CD%conf
set DATADIR=%CD%data
set TMPDIR=%CD%tmp

set FLASHTOOL=%BIN%\aml-flash-tool
set UPDATER=%FLASHTOOL%\update.exe
set CONFIMG=%CONFDIR%\conf.PARTITION
::set BOOTIMG=%DATADIR%\magisk_patched-23000_zMk2J.img
set EMPTYCONFIMG=%DATADIR%\conf.PARTITION
set MAGISKAPP=%DATADIR%\Magisk-v23.0.apk
set SCANOUT=%TMPDIR%\~dev.txt
set PINGOUT=%TMPDIR%\~ping.txt
set ADBOUT=%TMPDIR%\~adb.txt
set LOG=%TMPDIR%\~root.txt
set FIRMTMP=%TMPDIR%\~firmware.txt

set ADB="%BIN%\Minimal ADB and Fastboot\adb.exe"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"

echo Choose device firmware...
call :list_firmwares
if not [%FIRMWARE%]==[] (
  set BOOTIMG=%DATADIR%\%FIRMWARE%\boot.img
) else (
  echo Currently no root available, aborting...
  goto :end
)

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

echo Begin rooting...

echo ZTE B860H v5 OS 10 Root>%LOG%
echo.>>%LOG%

call :backup_conf "%CONFIMG%"
if not exist "%CONFIMG%" (
  echo Unable to backup CONF partition, exiting...
  echo.
  goto :end
)

call :wipe_cache_and_data
call :unlock_boot_loader
call :flash_boot_and_conf

echo.
echo Reboot your device and complete the setup
echo Connect using WiFi and note the IP address
echo Enable Developer Options and activate USB debugging

:: Ensure device is connected through its IP address

:input_device_ip
echo.
set /p IP="IP address of your device="
for /f "tokens=1,2,3,4 delims=." %%a in ("%IP%") do (
  if [%%a]==[] goto :input_device_ip
  if [%%b]==[] goto :input_device_ip
  if [%%c]==[] goto :input_device_ip
  if [%%d]==[] goto :input_device_ip
)
ping -n 1 %IP%>%PINGOUT%
findstr /c:"Destination host unreachable" /c:"Request timed out" %PINGOUT%>nul
if %ERRORLEVEL% equ 0 (
  echo Device not connected, please retry!
  goto :input_device_ip
)

:: Connect to ADB

%ADB% connect %IP%:5555>%ADBOUT%
findstr /c:"connected to" %ADBOUT%>nul
if not %ERRORLEVEL% equ 0 (
  echo ADB not connected, please retry!
  goto :input_device_ip
)

echo.
echo Make sure to allow this computer to access ADB
echo then Magisk App will be installed to your device
echo along with original CONF partition

%ADB% devices>>%LOG%

set /p NEXT="Press ENTER to install Magisk App..."
%ADB% install "%MAGISKAPP%">>%LOG%

set /p NEXT="Press ENTER to restore CONF partition..."
%ADB% push "%CONFIMG%" /sdcard>>%LOG%
%ADB% shell "su -c dd if=/sdcard/conf.PARTITION of=/dev/block/conf">>%LOG%

echo Done rooting...
echo.

goto :end

:list_firmwares
  set FIRMWARE=
  set N=0
  set X=0
  dir /ad /b %DATADIR%>%FIRMTMP%
  for /f "tokens=1" %%a in (%FIRMTMP%) do (
    if exist "%DATADIR%\%%a\boot.img" (
      set /a N+=1
      if [!X!]==[0] echo List of available firmwares:
      echo !N!. %%a
      if [!X!]==[0] set X=1
    )
  )
  if %N% equ 0 goto :eof
  set C=%N%
:list_firmwares_choose
  set /p C="Choose firware to root [%C%]? "
  if %C% lss 1 goto :list_firmwares_choose
  if %C% gtr %N% goto :list_firmwares_choose
  set N=0
  for /f "tokens=1" %%a in (%FIRMTMP%) do (
    if exist "%DATADIR%\%%a\boot.img" (
      set /a N+=1
      if !N! equ %C% set FIRMWARE=%%a
    )
  )
  goto :eof

:backup_conf
  set CONF=%~1
  set DIR=%~dp1
  set FILENAME=%~n1
  set FILEEXT=%~x1
  if not exist "%CONF%" goto :backup_conf_cont
  set CNTR=0
:backup_conf_check
  set /a CNTR+=1
  set NEWFILENAME=%FILENAME%%CNTR%%FILEEXT%
  if exist "%DIR%%NEWFILENAME%" goto :backup_conf_check
  echo Rename existing %CONF% to %NEWFILENAME%
  ren "%CONF%" "%NEWFILENAME%"
:backup_conf_cont
  call :backup_partition "%DIR%" conf:0x400000
  goto :eof

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

:flash_boot_and_conf
  call :do_flash_partition boot "%BOOTIMG%"
  call :do_flash_partition conf "%EMPTYCONFIMG%"
  goto :eof

:flash_partition
  set DIR=%~1
:flash_partition_loop
  set PART=%~2
  set IMG=%DIR%\%PART%.img
  if not [%PART%]==[] (
    call :do_flash_partition %PART% "%IMG%"
    shift
    goto :flash_partition_loop
  )
  goto :eof

:do_flash_partition
  set PARTITION=%~1
  set IMAGE=%~2
  if exist "%IMAGE%" (
    echo Flashing %PARTITION%...
    %UPDATER% partition %PARTITION% "%IMAGE%">>%LOG%
  )
  goto :eof

:wipe_cache_and_data
  echo Wiping cache and data...
  %UPDATER% bulkcmd "amlmmc erase cache">>%LOG%
  %UPDATER% bulkcmd "amlmmc erase data">>%LOG%
  goto :eof

:unlock_boot_loader
  echo Unlock boot loader...
  %UPDATER% bulkcmd "setenv -f lock 10100000">>%LOG%
  %UPDATER% bulkcmd "saveenv">>%LOG%
  goto :eof

:err_need_admin
  echo You need to be an Administrator
  goto :end

:end
endlocal