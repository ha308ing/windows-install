@REM %1 - path to local reg (where to load)
@REM %2 - path to file to load
:regLoad
reg load %1 %2
if errorlevel 1 (
  echo Failed to load %2 registry. Retry..
  pause
  goto :regLoad
)
exit /b
