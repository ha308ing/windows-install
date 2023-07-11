@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:start
cls
set /p s=enter size in Bytes^: 
echo %s%| findstr /r ^[1-9][0-9]*$ >NUL
if errorlevel 1 (
  echo Use only numbers..
  pause
  goto :start
)
set sizeB=%s%
echo B: %sizeB%
set sizeKB=%sizeB:~0,-3%
echo KB: %sizeKB%
set /a sizeMB=%sizeB:~0,-3%/1049
echo MB: %sizeMB%
set /a sizeGB=%sizeB:~0,-6%/1073
echo GB: %sizeGB%
pause
goto :start
