@REM %1 - path to loaded hive
@REM %2 - reg file to import
:regImport
reg import %1
if errorlevel 1 (
  echo Failed to import %1 registry modification. Retry..
  pause
  goto :regImport
)
exit /b
