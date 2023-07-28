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
set "__setVHD="%~dp0cmd\vhdCreate.cmd""
set "__installMediaISOCreate="%~dp0cmd\installMediaISOCreate.cmd""

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
dir /b /a:-d %_wimSource%
if errorlevel 1 goto :askInputFile
echo.
echo Input file: %_inputFile%..
echo Input wim: %_wimSource%..

@REM copy wim file for modification
if %_wimSource% equ %_imageModified% (
  choice /c yn /m "Modify image?"
  if errorlevel 2 goto :noImageModification
  if errorlevel 1 goto :nowimCopy
)
mkdir "%_targetDir:"=%\images\modified"
copy /y %_wimSource% %_imageModified%
:nowimCopy

@REM mount image
if not exist %_imageModified% (
  echo Image file not found. Try another..
  goto :askInputFile
)
call %__dismShowImages% %_imageModified%
call :setIndex
call %__dismMountImage% %_imageModified% %_mountDir% %_index%

@REM dism intl servicing
choice /c yn /m "Do internalization servicing?"
if errorlevel 2 goto :noIntlServicing
if errorlevel 1 call %__dismIntlServicing% %_mountDir%
:noIntlServicing

@REM extract archive to mount?
set "_currentEdge="%_mountDir:"=%\Users\Default\AppData\Local\Microsoft\Edge""
if exist %_currentEdge% rmdir /s /q %currentEdge%
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
:noImageModification

@REM create iso?
if %_inputFormat% equ iso call :createIso

@REM apply image to vhd
choice /c yn /m "Apply image to vhd?"
if errorlevel 2 goto :noVDH
if errorlevel 1 goto :askVHD
:askVHD
set /p "_vhd=Enter path to vhd: " || goto :askVHD
set "_vhd="%_vhd:"=%""
call %__setVHD% %_vhd%
if errorlevel 1 goto :askVHD
set "_scriptPath="%_targetDir:"=%\diskpart-script-allocate.txt""
call :vhdAllocate %_vhd% %_scriptPath%
choice /c yn /m "Review %_scriptPath%. Use this file?"
if errorlevel 2 goto :askVHD
if errorlevel 1 goto :runDiskpartScript
:runDiskpartScript
diskpart /s %_scriptPath%
if %errorlevel% neq 0 (
  echo Diskpart script failed..
  goto :askVHD
)
echo Diskpart script completed successfully..

echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 call :setIndex
dism /apply-image /imagefile:%_imageModified% /index:%_index% /applydir:%_partitionLetter1%:\
if errorlevel 1 (
  echo Apply image failed.
  goto :askVHD
)

:askCurrentBoot
choice /c yn /m "Add to current boot manager?"
if errorlevel 2 goto :exitCurrentBoot
if errorlevel 1 goto :addToCurrentBoot
:addToCurrentBoot
bcdboot %_partitionLetter1%:\Windows
:setBootDescription
set /p "_bootDescription=Enter boot menu description: " || goto :setBootDescription
bcdedit /set {default} description "%_bootDescription%"
bcdedit /default {current}
:exitCurrentBoot

bcdboot %_partitionLetter1%:\Windows /s %_partitionLetter0%: /f UEFI
(
  echo sel vol=%_partitionLetter0%
  echo remove letter=%_partitionLetter0%
  echo sel vdisk file=%_vhd%
  echo detach vdisk
  echo exit
) | diskpart

:noVHD
exit /b

:setIndex
:askIndex
set /p "_index=Enter image index: " || goto :askIndex
echo %_index%| findstr /r "^[1-9][0-9]*$"
if errorlevel 1 goto :askIndex
exit /b


:vhdAllocate
@REM %1 - vhd
@REM %2 - script save path

set "_scriptPath=%2"
if "%_scriptPath%" equ "" (
  set _scriptPath=%~dp0diskpart-script-allocate.txt
)
set "_vhd=%1"
:setNumberOfPartitions
set /p "_numberOfPartitions=Enter number of partitions: "
echo %_numberOfPartitions%| findstr /r "^[1-9][0-9]*$" >NUL
if errorlevel 1 (
  echo Use only numbers. Try another..
  goto :setNumberOfPartitions
)

:set vhdLabelPrefix
set /p "_labelPrefix=Enter vhd labels prefix: " || goto :vhdLabelPrefix

@REM get partitions labels and sizes
for /l %%i in (1,1,%_numberOfPartitions%) do (
  set /p "_partitionLabel%%i=Enter partition %%i label: "
  if %%i lss %_numberOfPartitions% (
    call :getPartitionSize %%i %_numberOfPartitions%
  ) else (
    set _partitionSize%%i=0
  )
)

@REM get available letters
set "_letters=C D E F G H I J K L M N O P Q R S T U V W X Y Z"
set "_partitionCounter=0"

:changeLetter
for /l %%i in (!_partitionCounter!,1,%_numberOfPartitions%) do (
  for %%j in ( !_letters! ) do (
    @REM dir "%%j:\" 2>NUL >NUL
    @REM if errorlevel 1 (
    if not exist "%%j:\" (
      set _partitionLetter%%i=%%j
      set /a _partitionCounter+=1
    )
    set _letters=!_letters:~2!
    goto :changeLetter
  )
)

echo User defined partitions:
for /l %%i in (1,1,%_numberOfPartitions%) do (
  echo Partition %%i. !_partitionLetter%%i!:\ %_labelPrefix%-!_partitionLabel%%i! - !_partitionSize%%i!
)
pause
echo off
(
echo sel vdisk file=%_vhd%
echo attach vdisk
echo clean
echo convert gpt
echo sel part 1
echo delete part override
echo create part efi size=100
echo format quick fs=fat32 label="%_labelPrefix%-efi"
echo assign letter=%_partitionLetter0%
echo create part msr size=16
if %_numberOfPartitions% equ 1 (
  echo create part pri
) else (
  set /a _partitionSize1+=500
  echo create part pri size=!_partitionSize1!
)
if "%_partitionLabel1%" equ "" (
  echo format quick fs=ntfs
) else (
  echo format quick fs=ntfs label="%_labelPrefix%-%_partitionLabel1%"
)
echo assign letter=%_partitionLetter1%
echo shrink desired=450
echo create part pri size=450
echo format quick fs=ntfs label="%_labelPrefix%-recovery"
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
if %_numberOfPartitions% equ 1 goto :endPartitions
for /l %%i in (2,1,%_numberOfPartitions%) do (
  if !_partitionSize%%i! equ 0 (
    echo create part pri
  ) else (
    echo create part pri size=!_partitionSize%%i!
  )
  if "!_partitionLabel%%i!" equ "" (
    echo format quick fs=ntfs
  ) else (
    echo format quick fs=ntfs label="%_labelPrefix%-!_partitionLabel%%i!"
  )
  echo assign letter=!_partitionLetter%%i!
)
:endPartitions
echo exit
) > %_scriptPath%
echo on
@REM diskpart /s %_scriptPath%
@REM if %errorlevel% equ 0 (
@REM   echo Diskpart script completed successfully..
@REM   @REM del "diskpart-script.txt"
@REM ) else (
@REM   echo Diskpart script failed..
@REM   @REM goto ?
@REM )

exit /b

:getPartitionSize
@REM %1 - %%i
@REM %2 - %numberOfPartitions%
@REM implement size requirements
:getNewSize
set /p "_partitionSize%1=Enter parition %1 size in MB: "
@REM set currentSize=!size%1!
@REM echo currentSize: %currentSize%
if %1 equ %2 (
  if "!_partitionSize%1!" equ "" set _partitionSize%1=0
) else (
  echo !_partitionSize%1!| findstr /r "^[1-9][0-9]*$"
  if errorlevel 1 (
    echo Use only numbers. Try another partition size..
    goto :getNewSize
  )
)
set /a _partitionSize%1*=1024
exit /b

:createISO
choice /c yn /m "Create iso with modified image?"
if errorlevel 2 goto :noISO
if errorlevel 1 goto :yesISO
:yesISO
robocopy "%_targetDir:"=%\images\modified" "%_isoDir:"=%\sources" install.wim
call %__installMediaISOCreate% %_isoDir%
:noISO
exit /b
