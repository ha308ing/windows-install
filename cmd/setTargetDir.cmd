@REM %1 - targetDir variable (_targetDir)
set "__quote="%~dp0\quote.cmd""
set "__checkDir="%~dp0\checkDir.cmd""
echo Set Target Dir
:askTargetDir
@REM targetDir - directory to store modified image, extracted iso
set /p "%1=Enter target directory: " || goto :askTargetDir
call %__quote% %1
call %__checkDir% !%1!
if %errorlevel% equ 0 goto :targetDirOk
choice /c yn /m "Target dir does not exist. Create?"
if errorlevel 2 goto :askTargetDir
if errorlevel 1 goto :createTargetDir
:createTargetDir
mkdir !%1!
if errorlevel 1 (
  echo Failed to create target dir..
  goto :askTargetDir
)
call %__checkDir% !%1!
if errorlevel 1 goto :askTargetDir
:targetDirOk
exit /b
