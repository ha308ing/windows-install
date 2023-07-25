@REM %1 - mountdir
@REM %2 - features list to enable
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
    call :inputFeaturesList
) else (
    set "_featuresList=%2"
)
set "_featuresList="%_featuresList:"=%""
dir /b /a:-d %_featuresList%
if errorlevel 1 call :inputFeaturesList

call :enableFeatures %_mountDir% %_featuresList%
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

:inputFeaturesList
:askFeaturesList
set /p "_featuresList=Enter path file with features to enable: " || goto :askFeaturesList
dir /b /a:-d %_featuresList%
if errorlevel 1 (
    echo File not found. Try another..
    goto :askFeaturesList
)
exit /b

:enableFeatures
@REM %1 - mount dir
@REM %2 - file with packages list to remove
powershell -noprofile -command "& {get-content %2 | foreach-object {Write-Host "Enabling $_..."; enable-windowsoptionalfeature -path %1 -featurename $_ } }"
exit /b
