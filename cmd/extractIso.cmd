@REM %1 - input iso
@REM %2 - extraction target
setlocal enabledelayedexpansion
set "_iso=%1"
if "%_iso%" neq "" goto :checkIso
:askIso
set /p "_iso=Enter path to iso: " || goto :askIso
:checkIso
set "_iso="%_iso:"=%""
echo %_iso%| findstr /ir "\.iso""$"
if errorlevel 1 (
    echo File should have iso extension. Try another..
    goto :askIso
)
dir /b /a:-d %_iso%
if errorlevel 1 (
    echo File not found. Try another..
    goto :askIso
)

set "_targetDir=%2"
if "%_targetDir%" neq "" goto :extractIso
:askTargetDir
set /p "_targetDir=Enter destination path: " || goto :askTargetDir
:extractIso
set "_targetDir="%_targetDir:"=%""

echo Extract iso..
echo Clear previous iso dir..
if exist %_targetDir% rd /s /q %_targetDir%
echo Extracting iso..
7z x %_iso% -o%_targetDir%
if errorlevel 1 (
    echo Failed to extract iso
) else (
    echo Iso extracted successfully
)
exit /b
