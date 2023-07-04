:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

:askTargetDir
set /p targetDir=Enter target directory: 
set imageModified=%targetDir%\images\modified\install.wim

:askIsoPath
set /p iso="Enter path to iso (blank to select install.wim): "

if "%iso%"=="" goto askImagePath

if not exist %iso% (
  echo File not found. Try other iso path..
  pause
  goto askIsoPath
)

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
    ) else goto askTargetDir
)

echo Extracting..
7z x %iso% -o%targetDir%\iso 2>&1 >NUL
if errorlevel 1 (
    echo Extracting failed..
    goto askIsoPath
) else (
    echo Extracted successfully..
)

set imagePath=%targetDir%\iso\sources\install.wim
goto copyImageForMod

:askImagePath
set /p imagePath=Enter path to install.wim: 
if not exist !imagePath! goto :askIsoPath

:copyImageForMod
if not exist %imagePath% (
  echo install.wim is not found..
  goto askIsoPath
)

: Copy install.wim for modification
echo imagePath: %imagePath:"=%
echo imageModified: %imageModified:"=%
if "%imagePath:"=%" NEQ "%imageModified:"=%" (
  echo Copying install.wim..
  xcopy /Y %imagePath% %targetDir%\images\modified\ 2>&1 >NUL
)
if exist %imageModified% (
  echo Ok. install.wim is found..
) else (
  echo Not ok. install.wim is not found..
  goto askIsoPath
)

:selectImageIndex
: Get image info
dism /Get-ImageInfo /ImageFile:%imageModified%

: Select image index
set /p imageIndex=Select image index: 

: Get selected image index info
dism /Get-ImageInfo /ImageFile:%imageModified% /Index:%imageIndex% 2>NUL
if %errorlevel% NEQ 0 (
  echo Can't get info about image. Try another index..
  goto selectImageIndex
)
