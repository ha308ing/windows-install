:: install preconfigured windows to vhdx
cls & chcp 65001 & setlocal enabledelayedexpansion

set "__quote="%~dp0\cmd\quote.cmd""
set "__checkFile="%~dp0\cmd\checkFile.cmd""
set "__checkDir="%~dp0\cmd\checkDir.cmd""
set "__removeDir="%~dp0\cmd\removeDir.cmd""
set "__extractIso="%~dp0\cmd\extractIso.cmd""
set "__dismIntlServicing="%~dp0\cmd\dismIntlServicing.cmd""
set "__regModify="%~dp0\cmd\regModify.cmd""
set "__imageDiscard="%~dp0\cmd\imageDiscard.cmd""
set "__imageSave="%~dp0\cmd\imageSave.cmd""

set "__setTargetDir="%~dp0\cmd\setTargetDir.cmd""
set "__setInputFile="%~dp0\cmd\setInputFile.cmd""
set "__showImageIndexes="%~dp0\cmd\showImageIndexes.cmd""

set "_targetDir="
set "_imageModified="
set "_mountDir="
set "_isoDir="
set "_inputFile="
set "_inputFormat="
set "_wimSource="
set "_imageIndex="

@REM handle exit error codes in calls
:setTargetDir
call %__setTargetDir% _targetDir
echo Target dir set: %_targetDir%
set "_imageModified="%_targetDir:"=%\images\modified\install.wim""
set "_mountDir="%_targetDir:"=%\mount""
set "_isoDir="%_targetDir:"=%\iso""
echo %_imageModified%
echo %_mountDir%
echo %_isoDir%
:askInputFile
call %__setInputFile% _inputFile _inputFormat
echo Input file outside: %_inputFile%..
if "%_inputFormat%" equ "wim" goto :copyWim
if "%_inputFormat%" equ "iso" call :extractIso %_inputFile% %_isoDir%
if errorlevel 1 (
  echo Failed to extract iso..
  call %__removeDir% %_isoDir%
  goto :setTargetDir
)
echo Iso extracted..
set "_installSource="%_isoDir:"=%\sources\install.wim""
goto :copyImage
:copyWim
set "_installSource=%_inputFile%"
if %_installSource% equ %_imageModified% goto :skipCopy
:copyImage
echo Copy install.wim
robocopy "%_isoDir:"=%\sources" "%_targetDir:"=%\images\modified" "install.wim"
:skipCopy
echo image in modified
call %__showImageIndexes% %_imageModified%
:inputImageIndex
set /p "_imageIndex=Select image index: " || goto :inputImageIndex
call :checkNumber %_imageIndex%
if errorlevel 1 goto :inputImageIndex
echo Selected index: %_imageIndex%
:mountImage
echo Mount install image..
call %__imageDiscard% %_mountDir%
dism /mount-image /imagefile:%_imageModified% /index:%_imageIndex% /mountdir:%_mountDir%
if errorlevel 1 (
  echo Mounting failed..
  call %__imageDiscard% %_mountDir%
)
call %__dismIntlServicing% %_mountDir%
if errorlevel 1 echo Failed to service image
:modifyRegistry
echo Modify registry
:regSoftware
set /p "_softwareReg=Enter path to SOFTWARE hive reg modifications: (blank to skip)" || goto :regUser
call %__quote% %_softwareReg%
call %__checkFile% %_softwareReg%
if errorlevel 1 (
  echo Reg file is not found. Try another..
  goto :regSoftware
)
set "_hive="%_mountDir:"=%\Windows\System32\config\SOFTWARE""
call %__regModify% %_hive% %_softwareReg%
:regUser
set /p "_userReg=Enter path to USER hive reg modifications: (blank to skip)" || goto :noReg
call %__quote% %_userReg%
call %__checkFile% %_userReg%
if errorlevel 1 (
  echo Reg file is not found. Try another..
  goto :regSoftware
)
set "_hive="%_mountDir:"=%\Windows\System32\config\DEFAULT""
call %__regModify% %_hive% %_userReg%
set "_hive="%_mountDir:"=%\Users\Default\NTUSER.DAT""
call %__regModify% %_hive% %_userReg%
:noReg
copyImage.cmd "D:\Ivan\23493\iso\sources\install.wim" D:\Ivan\23493\images\modified
dismShowImages.cmd
dismMountImage.cmd 
dismIntlServicing.cmd D:\Ivan\23493\mount 
regModify.cmd "%_mountDir:"=%\Windows\System32\config\SOFTWARE"
regModify.cmd "%_mountDir:"=%\Windows\System32\config\DEFAULT"
regModify.cmd "%_mountDir:"=%\Users\Default\NTUSER.DAT"

@REM extract archive to mount?
:askExtract
choice /c yn /m "Extract any archive to mount dir?"
if errolevel 2 goto :noExtract
if errolevel 1 call :filesExtract.cmd
goto :askExtract
@REM  filesExtract.cmd "E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip" "%_mountDir:"=%\Users\Default\AppData\Local\Microsoft"
:noExtract

@REM copy to panther\unattend.xml
:askPanther
choice /c yn /m "Copy unattend.xml to Panther?"
if errolevel 2 goto :noPanther
if errolevel 1 call :copyUnattendPanther.cmd %_mountDir%
goto :askPanther
:noPanther

@REM copy to panther\unattend.xml
:askSysprep
choice /c yn /m "Copy unattend.xml to Sysprep?"
if errolevel 2 goto :noSysprep
if errolevel 1 call :copyUnattendSysprep.cmd %_mountDir%
goto :askSysprep
:noSysprep


dismDiscardImage.cmd 
dismCommitImage.cmd
call :copyEdgeSettings
call :copyUnattend
call :getFeaturesList
call :printFeaturesToEnable
call :enableFeatures
call :getPackagesList
call :printPackagesToRemove
call :removePackages
call %__imageSave% %_mountDir%
exit /b

@REM ===========================================================================
:copyEdgeSettings
echo Copy Edge settings..
:setEdge
set /p "_edgePath=Enter path to Edge settings archive (blank to skip): " || goto :noEdge
call %__quote% _edgePath
call %__checkFile% %_edgePath%
if errorlevel 1 (
  echo File not found. Try another..
  goto :setEdge
)
set "_edgeTargetParent="%_mountDir:"=%\Users\Default\AppData\Local\Microsoft""
set "_edgeTarget="%_edgeTargetParent:"=%\Edge""
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
echo Copy unattend files..

:setUnattendPanther
set /p "_unattendPanther=Enter path to Panther\unattend.xml (blank to skip): " || goto :skipUnattendPanther
call %__quote% _unattendPanther
call %__checkFile% %_unattendPanther%
if errorlevel 1 (
  echo File is not found. Try another..
  goto :setUnattendPanther
)
mkdir "%_mountDir:"=%\Windows\Panther\"
copy /Y %_unattendPanther% "%_mountDir:"=%\Windows\Panther\unattend.xml"

:skipUnattendPanther

:setUnattendSysprep
set /p "_unattendSysprep=Enter path to Sysprep\unattend.xml (blank to skip): " || goto :skipUnattendSysprep
call %__quote% _unattendSysprep
call %__checkFile% %_unattendSysprep%
if errorlevel 1 (
  echo File is not found. Try another..
  goto :setUnattendSysprep
)
copy /Y  %_unattendSysprep% "%_mountDir:"=%\Windows\System32\Sysprep\unattend.xml"
:skipUnattendSysprep
exit /b

@REM ===========================================================================
:getPackagesList
echo Get file with packages to remove..
:askPackagesPath
echo Enter path to list with packages to remove (blank to generate list):
set /p "_inputPackages="
if "%_inputPackages%" equ "" (
  set "_plPath="%_targetDir:"=%\pl.txt""
  call :generatePackagesList
  echo Edit %_plPath% so it has packages to remove..
    set "_inputPackages=%_plPath%"
)
call %__quote% _inputPackages
call %__checkFile% %_inputPackages%
if errorlevel 1 (
  echo File not found. Try another..
  goto :askPackagesPath
)
echo File with packages to remove: %_inputPackages%
exit /b

@REM ===========================================================================
:generatePackagesList
echo Generate packages list..
powershell -noprofile -command "& {get-appxprovisionedpackage  -Path %_mountDir% | sort-object -property featurename | select-object -property displayname | format-table -hidetableheaders}" > %_plPath%
type %_plPath%
exit /b

@REM ===========================================================================
:printPackagesToRemove
echo Packages to remove:
for /f "usebackq" %%i in (%_inputPackages%) do (
  echo %%i
)
choice /c yn /m "Continue with current list?"
if errorlevel 2 (
  echo Update %_inputPackages%..
  goto :printPackagesToRemove
)
if errorlevel 1 echo Continue with current list
exit /b

@REM ===========================================================================
:removePackages
echo Removing packages..
set "_packagesToRemove="
for /f "usebackq" %%i in (%_inputPackages%) do set "_packagesToRemove=!_packagesToRemove!,'%%i'"
set "_packagesToRemove=%_packagesToRemove:~1%"
powershell -noprofile -command "& { $apps = @( %_packagesToRemove% ); Get-AppxProvisionedPackage -Path %_mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %_mountDir% -PackageName $_.PackageName | Out-Null } } }"
exit /b

@REM ===========================================================================
:cleanScreen
@REM echo ===========================================================================
exit /b


@REM ===========================================================================
:clearMountDir
echo Clear mount dir..
dism /unmount-image /mountdir:%_mountDir% /discard
if exist %_mountDir% rmdir /s /q %_mountDir%
echo Create mount dir..
mkdir %_mountDir%
exit /b

@REM ===========================================================================
:checkNumber
@REM %1 - var value
echo %1| findstr /r "^[1-9][0-9]*$"
exit /b
