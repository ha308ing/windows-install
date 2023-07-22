@REM %1 - mount dir
setlocal enabledelayedexpansion

if "%1" equ "" (
    call :inputMountDir
    if errorlevel 1 goto :EOF
) else (
    set _mountDir=%1
)
set "_mountDir="%_mountDir:"=%""

dism /unmount-image /mountdir:%_mountDir% /discard
rmdir %_mountDir%
exit /b

:inputMountDir
:askMountDir
set /p "_mountDir=Enter path mount dir: "
set "_mountDir="%_mountDir:"=%""
:checkMountDir
call %~dp0checkDir %_mountDir%
if errorlevel 1 (
    choice /c yn /m "Directory not found. Use another?"
    if errorlevel 2 exit /b 1
    if errorlevel 1 (
        goto :askMountDir
    )
)
exit /b