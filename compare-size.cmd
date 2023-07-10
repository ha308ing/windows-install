@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:start
set min=0000000064
set /p user=Enter number: 
echo %user%| findstr /r ^[1-9][0-9]*$
echo You've entered: %user%
echo errorlevel: %errorlevel%
if %errorlevel% neq 0 (
  echo Use only numbers. Try another..
  goto :start
)

set user=0000000000%user%

echo %user:~-10% vs %min%
if %user:~-10% lss %min% (
  echo Entered number is smaller than min
) else (
  echo Entered number is larger than min
)

goto :start
