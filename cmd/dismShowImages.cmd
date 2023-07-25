setlocal enabledelayedexpansion
@REM %1 - wim file
set "_mountDir=%1"
if "%_mountDir%" neq "" goto :wiminfo
:askMountDir
set /p "_mountDir=Enter path to mount dir" || goto :askMountDir
set "_mountDir="%_mountDir:"=%"
:wiminfo
dism /get-wiminfo /wimfile:%_mountDir%
exit /b
