
@REM %1 - mount dir
@REM ===========================================================================
:saveImage
echo Save image..
dism /unmount-image /mountdir:%1 /commit
if errorlevel 1 (
  echo Failed to commit and unmount umage. Retry..
  goto :saveImage
)
exit /b
