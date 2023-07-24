@REM %1 - mountdir
@REM %2 - packages list to remove
setlocal enabledelayedexpansion

if "%1" equ "" (
    call :inputMountDir
) else (
    set "_mountDir=%1"
)
set "_mountDir="%_mountDir:"=%""
dir /b /a:d %_mountDir%
if errorlevel 1 call :inputMountDir

if "%2" equ "" (
    call :inputPackagesList
) else (
    set "_packagesList=%2"
)
set "_packagesList="%_packagesList:"=%""
dir /b /a:-d %_packagesList%
if errorlevel 1 call :inputPackagesList

call :removePackages %_mountDir% %_packagesList%
exit /b

:inputMountDir
:askMountDir
set /p "_mountDir=Enter path to mount dir: " || goto :askMountDir
dir /b /a:d %_mountDir%
if errorlevel 1 (
    echo Dir not found. Try another..
    goto :askMountDir
)
exit /b

:inputPackagesList
:askPackagesList
set /p "_packagesList=Enter path file with packages to remove: " || goto :askPackagesList
dir /b /a:-d %_packagesList%
if errorlevel 1 (
    echo File not found. Try another..
    goto :askPackagesList
)
exit /b

:removePackages
@REM %1 - mount dir
@REM %2 - file with packages list to remove
powershell -noprofile -command "& {get-content %2 | foreach-object {Write-Host "Removing $_..."; $_packageName=(get-appxprovisionedpackage -path %1 | where-object -property displayname -eq -value $_).packagename;remove-appxprovisionedpackage -path %1 -packagename $_packageName } }"
exit /b