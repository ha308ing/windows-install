:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

: Select step
:stepSelect
echo Select step:
echo     1. Extract iso
echo     2. Copy install image for modification
echo     3. Get install image info
echo     4. Mount install image
set /p step=

:askTargetDir
set /p targetDir=Enter target directory: 
set imageModified=%targetDir%\images\modified\install.wim

if %step% LSS 1 goto stepSelect
if %step% GTR 4 goto stepSelect

if %step% EQU 1 goto extractIso
if %step% EQU 2 goto copyImageForMod
if %step% EQU 3 goto getImageInfo
if %step% EQU 4 goto mountImage

:extractIso
:askIsoPath
set /p iso=Enter path to iso: 

if not exist %iso% (
  echo File not found. Try other iso path..
  pause
  goto askIsoPath

dir /b %iso% | findstr /ir \.iso$ >NUL
if errorlevel 1 (
    echo File must have iso extension
    goto askIsoPath
)

:checkTargetDir
if not exist %targetDir% (
    set /p askCreateTargetDir="Target dir does not exist. Create? (y/n) "
    if /i "!askCreateTargetDir!" equ "y" (
        mkdir %targetDir% 
        goto checkTargetDir
    )
    if /i "!askCreateTargetDir!" equ "n" (
        echo Answer is no..
        goto askTargetDir
    )
)

echo Extracting..
7z x %iso% -o%targetDir%\iso >NUL 2>&1

if errorlevel 1 (
    echo Extracting failed..
    goto :EOF
) else (
    echo Extracted successfully..
)

:copyImageForMod
if not exist %targetDir%\iso\sources\install.wim (
  echo install.wim is not found in iso dir..
  set /p askExtractIso="Extract iso? (y/n) "
  if /i "%askExtractIso%"=="y" (
    goto extractIso
  )
  if /i "%askExtractIso%"=="n" (
    echo Place install.wim to %targetDir%\iso\sources\install.wim and try again..
  )
  pause
  goto copyImageForMod
)
: Copy install.wim for modification
echo Copying install.wim..
xcopy /Y %targetDir%\iso\sources\install.wim %targetDir%\images\modified\ 2>&1 >NUL
if exist %imageModified% (
    echo Ok. install.wim is found..
) else (
    echo Not ok. install.wim is not found..
)

:getImageInfo
: Get image info
if not exist %imageModified% (
  echo install.wim is not found..
  set /p askCopyImage="Copy install.wim from iso dir? (y/n) "
  if /i "!askCopyImage!"=="y" (
    goto copyImageForMod
  )
  if /i "!askCopyImage!"=="n" (
    echo Place install.wim to %imageModified% and try again..
    pause
  )
  goto getImageInfo
)
dism /Get-ImageInfo /ImageFile:%imageModified%

:mountImage
: Select image index
:selectImageIndex
set /p imageIndex=Select image index: 

: Get selected image index info
dism /Get-ImageInfo /ImageFile:%imageModified% /Index:%imageIndex% 2>NUL
if %errorlevel% NEQ 0 (
  echo Can't get info about image. Try another index..
  goto selectImageIndex
)

: Create dir for dism mount
set mountDir=%targetDir%\mount
dir /b %mountDir% | findstr /r "." >NUL
if errorlevel 0 (
  echo Mount dir is not empty..
  echo     unmounting..
  dism /unmount-image /mountdir:%mountdir% /discard 2>&1 >NUL
  echo     deleting files..
  rd /s /q %mountDir%
  mkdir %mountDir%
)
echo Creating dir for mount..
mkdir %mountDir%
