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
call :modifyRegistry
call :copyEdgeSettings
call :copyUnattend
call :getFeaturesList
call :printFeaturesToEnable
call :enableFeatures
call :getPackagesList
call :printPackagesToRemove
call :removePackages
call :saveImage
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
echo Set input file
:askInputFile
set /p "_inputFile=Enter path to iso or wim: " || goto :askInputFile
call :quote _inputFile
echo %_inputFile%| findstr /ir "\.wim""$" >NUL
if errorlevel 1 goto :setIso
:setWim
set "_inputFormat=wim"
set _wimSource=%_inputFile%
goto :setWimExit
:setIso
echo %_inputFile%| findstr /ir "\.iso""$" >NUL
if errorlevel 1 goto :askInputFile
set "_inputFormat=iso"
set _wimSource="%_targetDir:"=%\iso\sources\install.wim"
:setWimExit
call :checkInputFile %_inputFile% askInputFile
echo.
echo Input file: %_inputFile%..
exit /b

@REM ===========================================================================
:createImageModified
if "%_inputFormat%" equ "wim" goto :copyImageForMod
if "%_inputFormat%" equ "iso" goto :extractIso
echo Unsupported input format..
pause
exit /b 1
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
  pause
  exit /b 1
)
echo Extracted successfully..
:copyImageForMod
pause & cls
echo Copy image for modification..
if %_wimSource% equ %_imageModified% goto :createImageModifiedExit
echo Copy %_wimSource% to %_imageModified%..
xcopy /-I /Y %_wimSource% %_imageModified%
if errorlevel 1 (
  echo Failed to copy image for modification..
  pause
  exit /b 1
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
  pause
  exit /b 1
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
:modifyRegistry
pause & cls
echo Registry modification..
:setRegSoftware
set /p "_regSoftware=Enter path to SOFTWARE registry modifications (blank to skip): " || goto :setRegUser
call :quote _regSoftware
call :checkFile %_regSoftware%
if errorlevel 1 (
  echo File not found. Try another..
  pause
  goto :setRegSoftware
)
set "_hiveSoftware="%_mountDir:"=%\Windows\System32\config\SOFTWARE""
call :regLoadImportUnload SOFTWARE %_hiveSoftware% %_regSoftware%
:skipRegSoftware
pause & cls
:setRegUser
set /p "_regUser=Enter path to USER registry modifications (blank to skip): " || goto :skipRegUser
call :quote _regUser
call :checkFile %_regUser%
if errorlevel 1 (
  echo File not found. Try another..
  pause
  goto :setRegUser
)
set "_hiveDefault="%_mountDir:"=%\Windows\System32\config\DEFAULT""
call :regLoadImportUnload USER %_hiveDefault% %_regUser%
set "_hiveNTUSER="%_mountDir:"=%\Users\Default\NTUSER.DAT""
call :regLoadImportUnload USER %_hiveNTUSER% %_regUser%
:skipRegUser
exit /b

@REM ===========================================================================
:regLoadImportUnload
@REM call :modifyRegistry HIVE_TYPE PATH_TO_HIVE PATH_TO_REG
@REM %1 - HIVE TYPE (USER, SOFTWARE)
@REM %2 - path to hive
@REM %3 - reg file to import
:regLoad
reg load HKLM\OFFLINE %2
if errorlevel 1 (
  echo Failed to load %1 registry. Retry..
  pause
  goto :regLoad
)
:regImport
reg import %3
if errorlevel 1 (
  echo Failed to import %1 registry modification. Retry..
  pause
  goto :regImport
)
:regUnload
reg unload HKLM\OFFLINE
if errorlevel 1 (
  echo Failed to unload %1 registry. Retry..
  pause
  goto :regUnload
)
echo %1 registry modification imported successfully..
exit /b

@REM ===========================================================================
:copyEdgeSettings
pause & cls
echo Copy Edge settings..
:setEdge
set /p "_edgePath=Enter path to Edge settings archive (blank to skip): " || goto :noEdge
call :quote _edgePath
set "_edgeTargetParent="%_mountDir:"=%\Users\Default\AppData\Local\Microsoft""
set "_edgeTarget="%_edgeTargetParent:"=%\Edge""
call :checkFile %_edgePath%
if errorlevel 1 (
  echo File not found. Try another..
  pause
  goto :setEdge
)
if exist %_edgeTarget% rd /s /q %_edgeTarget%
7z x %_edgePath% -o%_edgeTargetParent%
if errorlevel 1 (
  echo Failed to extract Edge settings..
  rd /s /q %_edgeTarget%
)
echo Edge settings extracted successfully..
:noEdge
exit /b

@REM ===========================================================================
:copyUnattend
pause & cls
echo Copy unattend files..

:setUnattendPanther
set /p "_unattendPanther=Enter path to Panther\unattend.xml (blank to skip): " || goto :skipUnattendPanther
call :quote _unattendPanther
call :checkFile %_unattendPanther%
if errorlevel 1 (
  echo File is not found. Try another..
  pause
  goto :setUnattendPanther
)
mkdir "%_mountDir:"=%\Windows\Panther\"
xcopy /-I /Y %_unattendPanther% "%_mountDir:"=%\Windows\Panther\unattend.xml"
:skipUnattendPanther

:setUnattendSysprep
set /p "_unattendSysprep=Enter path to Sysprep\unattend.xml (blank to skip): " || goto :skipUnattendSysprep
call :quote _unattendSysprep
call :checkFile %_unattendSysprep%
if errorlevel 1 (
  echo File is not found. Try another..
  pause
  goto :setUnattendSysprep
)
xcopy /-I /Y  %_unattendSysprep% "%mountDir:"=%\Windows\System32\Sysprep\unattend.xml"
:skipUnattendSysprep
exit /b

@REM ===========================================================================
:saveImage
pause & cls
echo Save image..
dism /unmount-image /mountdir:%_mountdir% /commit
if errorlevel 1 (
  echo Failed to commit and unmount umage. Retry..
  pause
  call :saveImage
)
exit /b

@REM ===========================================================================
:getFeaturesList
pause & cls
echo Get file with features to enable..
:askFeaturesPath
echo Enter path to list with features to enable (blank to generate list):
set /p "_inputFeatures="
if %_inputFeatures% equ "" (
  set "_flPath="%_targetDir:"=%\fl.txt""
  call :generateFeaturesList
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
:generateFeaturesList
pause & cls
echo Generate features list..
powershell -noprofile -command "& {get-windowsoptionalfeature  -Path %_mountDir% | where-object -property state -value disabled -eq | sort-object -property featurename | select-object -property featurename} | format-table -hidetableheaders" > %_flPath%
type %_flPath%
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
for /f "usebackq" %%i in (%_inputFeatures%) do (
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
:getPackagesList
pause & cls
echo Get file with packages to remove..
:askPackagesPath
echo Enter path to list with packages to remove (blank to generate list):
set /p "_inputPackages="
if %_inputPackages% equ "" (
  set "_plPath="%_targetDir:"=%\pl.txt""
  call :generatePackagesList
  echo Edit %_plPath% so it has packages to remove..
  pause
  set "_inputPackages=%_plPath%"
)
call :quote _inputPackages
call :checkFile %_inputPackages%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askPackagesPath
)
echo File with packages to remove: %_inputPackages%
exit /b

@REM ===========================================================================
:generatePackagesList
pause & cls
echo Generate packages list..
powershell -noprofile -command "& {get-appxprovisionedpackage  -Path %_mountDir% | sort-object -property featurename | select-object -property displayname | format-table -hidetableheaders}" > %_plPath%
type %_plPath%
exit /b

@REM ===========================================================================
:printPackagesToRemove
pause & cls
echo Packages to remove:
for /f "usebackq" %%i in (%_inputPackages%) do (
  echo %%i
)
choice /c yn /m "Continue with current list?"
if errorlevel 2 (
  echo Update %_inputPackages%..
  pause
  goto :printPackagesToRemove
)
if errorlevel 1 echo Continue with current list
exit /b

@REM ===========================================================================
:removePackages
pause & cls
echo Removing packages..
set "_packagesToRemove="
for /f "usebackq" %%i in (%_inputPackages%) do set "_packagesToRemove=!_packagesToRemove!,'%%i'"
set "_packagesToRemove=%_packagesToRemove:~1%"
powershell -noprofile -command "& { $apps = @( %_packagesToRemove% ); Get-AppxProvisionedPackage -Path %_mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %_mountDir% -PackageName $_.PackageName | Out-Null } } }"
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
