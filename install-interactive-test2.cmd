:: install preconfigured windows to vhdx
cls & chcp 65001 & setlocal enabledelayedexpansion

set "__extractIso="%~dp0cmd\extractIso.cmd""
set "__dismMountImage="%~dp0cmd\dismMountImage.cmd""
set "__dismShowImages="%~dp0cmd\dismShowImages.cmd""
set "__dismIntlServicing="%~dp0cmd\dismIntlServicing.cmd""
set "__filesExtract="%~dp0cmd\filesExtract.cmd""
set "__copyUnattendPanther="%~dp0cmd\copyUnattendPanther.cmd""
set "__copyUnattendSysprep="%~dp0cmd\copyUnattendSysprep.cmd""
set "__featuresShow="%~dp0cmd\featuresShow.cmd""
set "__featuresEnable="%~dp0cmd\featuresEnable.cmd""
set "__packagesShow="%~dp0cmd\packagesShow.cmd""
set "__packagesRemove="%~dp0cmd\packagesRemove.cmd""
set "__dismCommitImage="%~dp0cmd\dismCommitImage.cmd""

@REM option when image already mounted?

@REM used vars:
@REM set "_imageModified="
@REM set "_mountDir="
@REM set "_isoDir="
@REM set "_inputFile="
@REM set "_inputFormat="
@REM set "_wimSource="
@REM set "_imageIndex="

@REM set target dir
:askTargetDir
set /p "_targetDir=Enter path to target dir: " || goto :askTargetDir
set "_targetDir="%_targetDir:"=%""
dir /b /a:d %_targetDir%
if errorlevel 1 (
  choice /c yn /m "Target dir not found."
  if errorlevel 2 goto :askTargetDir
  if errorlevel 1 mkdir %_targetDir%
)
set "_imageModified="%_targetDir:"=%\images\modified\install.wim""
set "_mountDir="%_targetDir:"=%\mount""
set "_isoDir="%_targetDir:"=%\iso""

@REM set input file
echo Set input file
:askInputFile
set /p "_inputFile=Enter path to iso or wim: " || goto :askInputFile
set "_inputFile="%_inputFile:"=%""
echo %_inputFile%| findstr /ir "\.wim""$"
if errorlevel 1 goto :setIso
:setWim
set "_inputFormat=wim"
set _wimSource=%_inputFile%
goto :setWimExit
:setIso
echo %_inputFile%| findstr /ir "\.iso""$"
if errorlevel 1 goto :askInputFile
dir /b /a:-d %_inputFile%
if errorlevel 1 goto :askInputFile
set "_inputFormat=iso"
call %__extractIso% %_inputFile% %_isoDir%
set _wimSource="%_isoDir:"=%\sources\install.wim"
:setWimExit
dir /b /a:-d %_inputFile%
if errorlevel 1 goto :askInputFile
echo.
echo Input file: %_inputFile%..

@REM backup wim file
if %_wimSource% equ %_imageModified% goto :noBackup
copy /y %_wimSource% %_imageModified%
:noBackup

@REM mount image
call %__dismShowImages% %_imageModified%
:askIndex
set /p "_index=Enter image index: " || goto :askIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 goto :askIndex
call %__dismMountImage% %_imageModified% %_mountDir% %_index%

@REM dism intl servicing
call %__dismIntlServicing% %_mountDir%

@REM extract archive to mount?
call %__filesExtract% "E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip" "%_mountDir:"=%\Users\Default\AppData\Local\Microsoft"
:askExtract
choice /c yn /m "Extract any archive to mount dir?"
if errorlevel 2 goto :noExtract
if errorlevel 1 call %__filesExtract%
goto :askExtract
:noExtract

@REM copy to panther\unattend.xml
call %__copyUnattendPanther% %_mountDir% "E:\OneDrive\arkaev\windows-custom-setup\xml\Panther\unattend.xml"
:askPanther
choice /c yn /m "Copy unattend.xml to Panther?"
if errorlevel 2 goto :noPanther
if errorlevel 1 call %__copyUnattendPanther% %_mountDir% 
goto :askPanther
:noPanther

@REM copy to panther\unattend.xml
call %__copyUnattendSysprep% %_mountDir% "E:\OneDrive\arkaev\windows-custom-setup\xml\Sysprep\unattend.xml"
:askSysprep
choice /c yn /m "Copy unattend.xml to Sysprep?"
if errorlevel 2 goto :noSysprep
if errorlevel 1 call %__copyUnattendSysprep% %_mountDir%
goto :askSysprep
:noSysprep

@REM enable features
choice /c yn /m "Enable features?"
if errorlevel 2 goto :noFeatures
if errorlevel 1 goto :yesFeatures
:yesFeatures
:askFeaturesList
set /p "_featuresList=Enter path to file with features to enable (blank to generate): " || goto :generateFeaturesList
set "_featuresList="%_featuresList:"=%""
dir /b /a:-d %_featuresList%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askFeaturesList
)
goto :enableFeatures
:generateFeaturesList
set "_featuresList="%_targetDir:"=%\features-to-enable.txt""
call %__featuresShow% %_mountDir% "%_featuresList%"
echo Edit %_featuresList% file to contain only features to enable..
pause
:enableFeatures
call %__featuresEnable% %_mountDir% %_featuresList%
:noFeatures

@REM remove packages
choice /c yn /m "Remove packages?"
if errorlevel 2 goto :noPackages
if errorlevel 1 goto :yesPackages
:yesPackages
:askPackagesList
set /p "_packagesList=Enter path to file with packages to remove (blank to generate): " || goto :generatePackagesList
set "_packagesList="%_packagesList:"=%""
dir /b /a:-d %_packagesList%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askPackagesList
)
goto :removePackages
:generatePackagesList
set "_packagesList="%_targetDir:"=%\packages-to-remove.txt""
call %__packagesShow% %_mountDir% "%_packagesList%"
echo Edit %_packagesList% file to contain only packages to remove..
pause
:removePackages
call %__packagesRemove% %_mountDir% %_packagesList%
:noPackages

@REM save image
call %__dismCommitImage% %_mountDir%
exit /b
