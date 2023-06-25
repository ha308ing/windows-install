:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

:askIsoPath
set /p iso=Enter path to iso: 

dir /b %iso% | findstr /ir \.iso$ >NUL

if errorlevel 1 (
    echo File must have iso extension
    goto askIsoPath
)

:askTargetDir
set /p targetDir=Enter target directory:

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
7z x %iso% -o%targetDir% >NUL 2>&1

if errorlevel 1 (
    echo Extracting failed
    goto :EOF
) else (
    echo Extracting successful
)

if exist %targetDir%\sources\install.wim (
    echo install.wim is found
) else (
    echo install.wim is not found
)

