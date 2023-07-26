setlocal enabledelayedexpansion
@REM %1 - vhd
@REM %2 - size

set "_vhdMinSizeMB=66560"
set "_vhd=%1"
set "_size=%2"
if "%_vhd%" equ "" call :inputVHD
set "_vhd="%_vhd:"=%""

call :checkVHD %_vhd%
if errorlevel 3 (
  call :inputVHD
  goto :checkOut
)
if errorlevel 2 (
  choice /c yn /m "VHD not found. Create?"
  if errorlevel 2 (
    call :inputVHD
    goto :checkOut
  )
  if errorlevel 1 (
    call :createVHD %_vhd% %_size%
    goto :checkOut
  )
)
if errorlevel 1 (
  call :inputVHD
  goto :checkOut
)
:checkOut
echo vhd: %_vhd%
exit /b

:inputVHD
:askVHD
set /p "_vhd=Enter path to vhd: " || goto :askVHD
call :checkVHD %_vhd%
if errorlevel 3 goto :askVHD
if errorlevel 2 (
  choice /c yn /m "VHD not found. Create?"
  if errorlevel 2 goto :askVHD
  if errorlevel 1 (
    call :createVHD %_vhd% %_size%
    exit /b
  )
)
if errorlevel 1 goto :askVHD
exit /b

:checkVHD
@REM %1 - vhd
set "_vhd=%1"
set "_vhd="%_vhd:"=%""
echo %_vhd%| findstr /ir "\.vhdx""$"
if errorlevel 1 (
  echo File should have vhdx extension. Try again..
  exit /b 3
)
dir /b /a:-d %_vhd%
if errorlevel 1 (
  @REM vhd not found ask to create
  exit /b 2
)
exit /b

:createVHD
@REM %1 - vhd
@REM %2 - size in MB
set "_size=%2"
if "%_size%" equ "" call :inputSize
echo %_size%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Size should be a number. Try another..
  call :inputSize
)
if %_size% lss %_vhdMinSizeMB% (
  echo VHD size should be larget than %_vhdMinSizeMB% MB. Try another..
  call :inputSize
)
(
  echo create vdisk file=%1 maximum=%_size%
  echo exit
) | diskpart
if not exist %_vhd% (
  set "_size="
  echo Failed to create VHD..
  call :inputVHD
  exit /b
)
exit /b

:inputSize
:askSize
set /p "_size=Enter vhd size in MB: " || goto :askSize
echo %_size%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Size should be a number. Try another..
  goto :askSize
)
if %_size% lss %_vhdMinSizeMB% (
  echo VHD size should be larget than %_vhdMinSizeMB% MB. Try another..
  goto :askSize
)
exit /b
