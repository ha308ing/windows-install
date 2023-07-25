setlocal enabledelayedexpansion
@REM %1 - image
@REM %2 - index
@REM %3 - vhd path

set "_image=%1"
if "%_image%" equ "" call :inputImage
set "_image="%_image:"=%""
dir /b /a:-d %_image%
if errorlevel 1 (
  echo Image file not found. Try another..
  call :inputImage
)

set "_index=%2"
if "%_index%" equ "" call :inputIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Index should be a number. Try another..
  call :inputIndex
)

set "_vhd=%3"
if "%_vhd%" equ "" call :inputVHD
set "_vhd="%_vhd:"=%""
echo %_vhd%| findstr /ir "\.vhdx""$"
if errorlevel 1 (
  echo File should have vhdx extension. Try another..
  call :inputVHD
)
dir /b /a:-d %_vhd%
if errorlevel 1 (
  choice /c yn /m "VHD is not found. Create?"
  if errorlevel 2 call :inputVHD
  if errorlevel 1 call :createVHD %_vhd%
)
dism /apply-image /imagefile:%_image% /index:%_index% /applydir:%_vhd%
exit /b

:inputImage
:askImage
set /p "_image=Enter path to image to apply: " || goto :askImage
set "_image="%_image:"=%"
dir /b /a:-d %_image%
if errorlevel 1 (
  echo Image file not found. Try another..
  goto :askImage
)
exit /b

:inputIndex
:askIndex
set /p "_index=Enter index of image to apply: " || goto :askIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Index should be a number. Try another..
  goto :askIndex
)
exit /b

:inputVHD
:askVHD
set /p "_vhd=Enter path to vhd: " || goto :askVHD
set "_vhd="%_vhd:"=%""
echo %_vhd%| findstr /ir "\.vhdx""$"
if errorlevel 1 (
  echo File should have vhdx extension. Try another..
  goto :askVHD
)
dir /b /a:-d %_vhd%
if errorlevel 1 (
  choice /c yn /m "VHD is not found. Create?"
  if errorlevel 2 goto :askVHD
  if errorlevel 1 call :createVHD %_vhd%
)
exit /b

:createVHD
@REM %1 - path to vhd
@REM %2 - size in mb
set "_size=%2"
if "%_size%" equ "" (
  goto :askVhdSize
) else (
  goto :checkVhdSize
)
:askVhdSize
set /p "_size=Enter size of vhd in MB" || goto :askVhdSize
:checkVhdSize
echo %_size%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 (
  echo Size should be a number in MB. Try another..
  goto :askVhdSize
)
(
  echo create vdisk file=%1 maximum=%2
  echo exit
) | diskpart
exit /b

