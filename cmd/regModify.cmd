setlocal enabledelayedexpansion
@REM %1 - path to hive file to load
@REM %2 - path to reg file to import

set _hiveFile=%1
set _regFile=%2
if "%_hiveFile%" equ "" call :askFile _hiveFile "Enter path to hive file to load: "
if "%_regFile%" equ "" call :askFile _regFile "Enter path to reg file to import to %_hiveFile%: "
set "_hiveFile="%_hiveFile:"=%""
set "_regFile="%_regFile:"=%""
if not exist %_hiveFile% (
    echo File not found. Try another
    call :askFile _hiveFile "Enter path to hive file to load: "
)
if not exist %_regFile% (
    echo File not found. Try another
    call :askFile _regFile "Enter path to reg file to import to %_hiveFile%: "
)
set _localHive=HKLM\OFFLINE
call :regLoad %_localHive% %_hiveFile%
call :regImport %_regFile%
call :regUnload %_localHive%
exit /b


:regLoad
reg load %1 %2
if errorlevel 1 (
  echo Failed to load %2 registry. Retry..
  pause
  goto :regLoad
)
exit /b

:regImport
reg import %1
if errorlevel 1 (
  echo Failed to import %1 registry modification. Retry..
  pause
  goto :regImport
)
exit /b

:regUnload
reg unload %1
if errorlevel 1 (
  echo Failed to unload %1 hive. Retry..
  pause
  goto :regUnload
)
exit /b

:askFile
@REM %1 - var
@REM %2 - message
set /p "_var=%2" || goto :askFile
set "_var="%_var:"=%""
:checkFile
dir /b /a:-d %_var%
if %errorlevel% equ 0 (
    set %1=%_var%
    exit /b
)
echo File not found. Try another..
goto :askFile
exit /b