@echo off & chcp 65001 > NUL & setlocal enabledelayedexpansion

:start
cls
echo Current dir^: %~dp0
set /p p=enter path^: 
set p=^"%p:"=%^"
echo You've entered: %p%
dir /b %p% 2>NUL >NUL
if %errorlevel% equ 0 (
  echo Path %p% is found.
  dir /b %p%
  echo errorlevel: %errorlevel%
  echo.
  echo After pushd:
  pushd %p%
  dir /b
  echo.
  echo After popd:
  popd
  dir /b
  echo.
  echo Second after popd:
  dir /b
  echo.
  echo After empty pushd:
  pushd
  dir /b
  echo.
  echo After popd:
  popd
  dir /b
  echo.
) else (
  echo Path %p% is not found. Try another..
  pause
  goto :start
)

