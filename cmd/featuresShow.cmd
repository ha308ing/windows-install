@REM %1 - mountdir
@REM %2 - path to output file
setlocal enabledelayedexpansion

if "%1" equ "" (
    call :inputMountDir
) else (
    set "_mountDir=%1"
)
set "_mountDir="%_mountDir:"=%""
dir /b /a:d %_mountDir%
if errorlevel 1 call :inputMountDir

call :showFeatures %_mountDir% %2
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

:showFeatures
@REM %1 - mount dir
@REM %2 - output file
if "%2" equ "" (
    powershell -noprofile -command "& { get-windowsoptionalfeature -path %1 | where-object -Property State -eq -value Disabled | sort-object -Property FeatureName | foreach-object { $_.FeatureName } }"
    goto :EOF
)
if "%2" neq "" (
    powershell -noprofile -command "& { get-windowsoptionalfeature -path %1 | where-object -Property State -eq -value Disabled | sort-object -Property FeatureName | foreach-object { $_.FeatureName } }" >%2
    goto :EOF
)
exit /b
