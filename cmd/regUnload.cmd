@REM %1 - path to local loaded hive
:regUnload
reg unload %1
if errorlevel 1 (
  echo Failed to unload %1 hive. Retry..
  pause
  goto :regUnload
)
exit /b
