:: install preconfigured windows to vhdx
chcp 65001 & setlocal enabledelayedexpansion

set "_targetDir="
set "_imageModified="
set "_mountDir="
set "_isoDir="
set "_inputFile="
set "_inputFormat="
set "_wimSource="
set "_imageIndex="

@REM handle exit error codes in calls
call :setTargetDir
call :cleanScreen
echo Target dir: %_targetDir%
call :setInputFile
call :createImageModified
call :showImageIndexes
call :selectImage
call :dismIntlServicing
call :getFeaturesList
call :printFeaturesToEnable
call :enableFeatures
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
:showImageIndexes
pause & cls
echo Available images:
dism /get-imageinfo /imagefile:%_imageModified%
exit /b

@REM ===========================================================================
:selectImage
pause & cls
:inputImageIndex
set /p "_imageIndex=Select image index: " || goto :inputImageIndex
call :checkNumber %_imageIndex%
if errorlevel 1 goto :inputImageIndex
echo Selected index: %_imageIndex%
exit /b

@REM ===========================================================================
:mountImage
pause & cls
echo Mounting install image..
dism /mount-image /imagefile:%_imageModified% /index:%_imageIndex% /mountdir:%_mountDir%
if errorlevel 1 (
  echo Mounting failed..
  call :clearMountDir
  goto :showImageIndexes
)
exit /b

@REM ===========================================================================
:dismIntlServicing
pause & cls
echo DISM image servicing..
echo Image international servicing..
:setTimezone
dism /image:%_mountDir% /set-timezone:"Russian Standard Time" >NUL
if errorlevel 1 (
  echo Failed to set timezone..
  pause
  goto :setTimezone
) else ( echo Timezone set.. ) 
:setInputLocale
dism /image:%_mountDir% /set-inputlocale:en-US;ru-RU >NUL
if errorlevel 1 (
  echo Failed to set input locale..
  pause
  goto :setInputLocale
) else ( echo Input locale set.. ) 
:setSysLocale
dism /image:%_mountDir% /set-syslocale:ru-RU >NUL
if errorlevel 1 (
  echo Failed to set system locale..
  pause
  goto :setSysLocale
) else ( echo System locale set.. )
:setUserLocale
dism /image:%_mountDir% /set-userlocale:ru-RU >NUL
if errorlevel 1 (
  echo Failed to set user locale..
  pause
  goto :setUserLocale
) else ( echo User locale set.. ) 
exit /b

@REM ===========================================================================
:getFeaturesList
pause & cls
echo Get file with features to enable..
:askFeaturesPath
echo Enter path to list with features to enable (blank to generate list):
set /p "_inputFeatures="
if %_inputFeatures% equ "" (
  call :getFeaturesList
  set "_flPath="%_targetDir:"=%\fl.txt""
  echo Edit %_flPath% so it has features to enable..
  pause
  set "_inputFeatures=%_flPath%"
)
call :quote _inputFeatures
call :checkFile %_inputFeatures%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askFeaturesPath
)
echo File with features to enable: %_inputFeatures%
exit /b

@REM ===========================================================================
:printFeaturesToEnable
pause & cls
echo Features to enable:
for /f "usebackq" %%i in (%_inputFeatures%) do (
  echo %%i
)
choice /c yn /m "Continue with current list?"
if errorlevel 2 (
  echo Update %_inputFeatures%..
  pause
  goto :printFeaturesToEnable
)
if errorlevel 1 echo Continue with current list
exit /b

@REM ===========================================================================
:enableFeatures
pause & cls
echo Enabling features..
set "_failEnableFeatures="
set "_successEnableFeatures="
for /f "usebackq" %%i in (%inputFeatures%) do (
  @REM check if feature is present in image?
  dism /image:%_mountDir% /enable-feature /featurename:%%i
  if errorlevel 1 set "_successEnableFeatures=!_successEnableFeatures!;%%i"
  if errorlevel 0 set "_failEnableFeatures=!_failEnableFeatures!;%%i"
)
pause
cls
if "%_successEnableFeatures%" equ "" goto :enableFeaturesFail
echo Successfully enabled features:
for %%i in (%_successEnableFeatures%) do (
  echo %%i
)
pause
cls
:enableFeaturesFail
if "%_failEnableFeatures%" equ "" goto :enableFeaturesExit
echo Failed to enable features:
for %%i in (%_failEnableFeatures%) do (
  echo %%i
)
pause
cls
:askReEnableFeatures
choice /c yn /m "Try enable features again?"
if errorlevel 2 goto :enableFeaturesExit
if errorlevel 1 goto :enableFeatures
:enableFeaturesExit
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
:checkFile
@REM %1 - file
dir /b /a:-d %1 2>NUL >NUL
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

@REM ===========================================================================
:checkNumber
@REM %1 - var value
echo %1| findstr /r "^[1-9][0-9]*$" >NUL
exit /b