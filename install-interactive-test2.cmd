:: install preconfigured windows to vhdx
chcp 65001 & setlocal enabledelayedexpansion

set "_targetDir="
set "_imageModified="
set "_mountDir="
set "_isoDir="
set "_inputFile="
set "_inputFormat="
set "_wimSource="

call :setTargetDir
call :cleanScreen
echo Target dir: %_targetDir%
call :setInputFile
call :createImageModified
exit /b

@REM ===========================================================================
:setTargetDir
cls
echo Set Target Dir
:askTargetDir
@REM targetDir - directory to store modified image, extracted iso
set /p "_targetDir=Enter target directory: " || goto :askTargetDir
call :quote _targetDir
call :checkDir %_targetDir%
if %errorlevel% equ 0 goto :targetDirOk
choice /c yn /m "Target dir does not exist. Create?"
if errorlevel 2 goto :askTargetDir
if errorlevel 1 goto :createTargetDir
:createTargetDir
mkdir %_targetDir%
if errorlevel 1 (
  echo Failed to create target dir..
  goto :askTargetDir
)
call :checkTargetDir %_targetDir%
if errorlevel 1 goto :askTargetDir
:targetDirOk
set _imageModified="%_targetDir:"=%\images\modified\install.wim"
set _mountDir="%_targetDir:"=%\mount"
set _isoDir="%_targetDir:"=%\iso"
echo Target dir set: %_targetDir%
exit /b

@REM ===========================================================================
:setInputFile
pause & cls
echo Set Target Dir
:askInputFile
set /p "_inputFile=Enter path to iso or wim: " || goto :askInputFile
call :quote _inputFile
echo %_inputFile%| findstr /ir "\.wim""$" >NUL
if %errorlevel% equ 0 (
  goto :setWim
) else (
  goto :setIso
)
:setWim
set "_inputFormat=wim"
set _wimSource=%_inputFile%
goto :setWimExit
:setIso
echo %_inputFile%| findstr /ir "\.iso""$" >NUL
if errorlevel 1 goto :askInputFile
set "_inputFormat=iso"
set _wimSource="%targetDir:"=%\iso\sources\install.wim"
:setWimExit
call :checkInputFile %_inputFile% askInputFile
echo.
echo Input file: %_inputFile%..
exit /b

@REM ===========================================================================
:createImageModified
if "%_inputFormat%" equ "wim" goto :copyImageForMod
if "%_inputFormat%" equ "iso" goto :extractIso
goto :setInputFile
:extractIso
echo Extracting iso..
echo Clear previous iso dir..
if exist %_isoDir% rd /s /q %_isoDir%
cls
echo Extracting iso..
7z x %_inputFile% -o%_isoDir%
echo.
if errorlevel 1 (
  echo Extracting failed..
  echo Clear iso dir..
  rd /s /q %_isoDir%
  goto :askInputFile
)
echo Extracted successfully..
:copyImageForMod
pause & cls
echo Copy image for modification..
if %_wimSource% equ %_imageModified% goto :createImageModifiedExit
echo Copy %_wimSource% to %_imageModified%..
xcopy /-I /Y %_wimSource% %_imageModified%
if errorlevel 1 (
  echo Failed to copy. Try another iso or wim..
  goto :askInputFile
)
:createImageModifiedExit
echo Image for modification: %_imageModified%
exit /b

@REM ===========================================================================
:quote
set "%1="!%1:"=!""
exit /b

@REM ===========================================================================
:checkDir
@REM %1 - dir
dir /b /a:d %1 2>NUL >NUL
exit /b

@REM ===========================================================================
:cleanScreen
pause & cls
@REM echo ===========================================================================
exit /b


@REM ===========================================================================
:clearMountDir
echo Clear mount dir..
dism /unmount-image /mountdir:%_mountDir% /discard >NUL
if exist %_mountDir% rmdir /s /q %_mountDir% >NUL
echo Create mount dir..
mkdir %_mountDir%
exit /b


@REM ===========================================================================
:checkInputFile 
@REM %1 - file
@REM %2 - label
if not exist %1 (
  echo File %1 not found. Try another iso or wim..
  goto :%2
)
exit /b
