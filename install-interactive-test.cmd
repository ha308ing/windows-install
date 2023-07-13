:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

:askTargetDir
@REM targetDir - directory to store modified image, extracted iso
set /p targetDir=Enter target directory: 
set targetDir="%targetDir:"=%"
:checkTargetDir
if not exist %targetDir% (
    set /p askCreateTargetDir="Target dir does not exist. Create? (y/N) "
    if /i "%askCreateTargetDir%" equ "y" (
        mkdir %targetDir%
        if errorlevel 1 (
          echo Failed to create target dir..
          goto askTargetDir
        )
        goto checkTargetDir
    ) else goto :askTargetDir
)
set imageModified="%targetDir:"=%\images\modified\install.wim"
set mountDir="%targetDir:"=%\mount"
set isoDir="%targetDir:"=%\iso"

@REM ask for iso or wim and decide by extension
@REM for iso creation ask info when needed
:askInputPath
set /p inputPath="Enter path to iso or wim: " || goto :askInputPath
set inputPath="%inputPath:"=%"
@REM no inputFormat? if wim -> skip iso?
set inputFormat=
set wimSource=
echo %inputPath%| findstr /ir "\.wim""$" >NUL
if %errorlevel% equ 0 (
  set inputFormat=wim
  set wimSource="%inputPath:"=%"
  @REM goto :inputFormatWIM
) else (
  echo %inputPath%| findstr /ir "\.iso""$" >NUL
  if !errorlevel! equ 0 (
    set inputFormat=iso
    set wimSource="%targetDir:"=%\iso\sources\install.wim"
    @REM goto :inputFormatISO
  ) else (
    echo Enter iso or wim..
    goto :askInputPath
  )
)
if not exist %inputPath% (
  echo File %inputPath% not found. Try another iso or wim..
  goto :askInputPath
)

if "%inputFormat%" equ "wim" goto :inputFormatWIM
@REM if "%inputFormat%" equ "iso" goto :inputFormatISO

:inputFormatISO
echo Extracting %inputPath% to %isoDir%..
if exist %isoDir% rd /s /q %isoDir%
7z x %inputPath% -o%isoDir% 2>&1 >NUL
if %errorlevel% equ 0 (
  echo Extracted successfully..
) else (
  echo Extracting failed..
  rd /s /q %isoDir%
  goto :askInputPath
)

:inputFormatWIM
if not exist %wimSource% (
  echo %wimSource% is not found. Try another iso or wim..
  goto :askInputPath
)

:copyImageForMod
: Copy install.wim for modification
if %wimSource% neq %imageModified% (
  echo Copying %wimSource% to %imageModified%..
  xcopy /-I /Y %wimSource% %imageModified%
  if !errorlevel! neq 0 (
    echo Failed to copy. Try another iso or wim..
    goto :askInputPath
  )
)

if not exist %imageModified% (
  echo %imageModified% not found. Try another iso or wim..
  goto :askInputPath
)

: Clear previous mount dir
:clearMountDir
echo Clear mount dir..
dism /unmount-image /mountdir:%mountdir% /discard >NUL
if exist %mountDir% rd /s /q %mountDir% >NUL
echo Create mount dir..
mkdir %mountDir%


:showImageIndex
: Get image info
cls
echo Available images:
dism /get-imageinfo /imagefile:%imageModified%
@REM if error - use another image

: Select image index
: set /p imageIndex=Select image index: 

: : Get selected image index info
: dism /Get-ImageInfo /ImageFile:%imageModified% /Index:%imageIndex%
: if %errorlevel% NEQ 0 (
:   echo Can't get info about image. Try another index..
:   goto selectImageIndex
: )
: Mount image
:inputImageIndex
set /p imageIndex="Select image index: " || goto :inputImageIndex
echo %imageIndex%| findstr /r "^[1-9][0-9]*$" >NUL
if errorlevel 1 goto :inputImageIndex
echo Mounting install image..
dism /mount-image /imagefile:%imagemodified% /index:%imageIndex% /mountdir:%mountdir%
if %errorlevel% neq 0 (
  echo Mounting failed..
  goto :showImageIndex
)

: DISM image servicing
cls
echo DISM image servicing..

echo Image international servicing..

dism /image:%mountDir% /set-timezone:"Russian Standard Time" >NUL
if errorlevel 0 ( echo Timezone set.. ) else ( echo Failed to set timezone.. )

dism /image:%mountDir% /set-inputlocale:en-US;ru-RU >NUL
if errorlevel 0 ( echo Input locale set.. ) else ( echo Failed to set input locale.. )

dism /image:%mountDir% /set-syslocale:ru-RU >NUL
if errorlevel 0 ( echo System locale set.. ) else ( echo Failed to set system locale.. )

dism /image:%mountDir% /set-userlocale:ru-RU >NUL
if errorlevel 0 ( echo User locale set.. ) else ( echo Failed to set user locale.. )

:enableFeatures
@REM do the same as with provisioned packages: file edition variant
cls
set featuresListPath="%targetDir:"=%\fl.txt"
echo Image features:
dism /image:%mountDir% /get-features /format:table 1>%featuresListPath%
type %featuresListPath%

echo "Enter features to enable (see %featuresListPath%): "
set /p inputFeatures= || goto :enableFeaturesExit

set failEnableFeatures=
set successEnableFeatures=
for /d %%i in (%inputFeatures%) do (
  @REM check if feature is present in image?
  dism /image:%mountDir% /enable-feature /featurename:%%i
  if %errorlevel% neq 0 (
    set failEnableFeatures=%failEnableFeatures%;%%i
  ) else (
    set successEnableFeatures=%successEnableFeatures%;%%i
  )
)

if "%successEnableFeatures%" equ "" goto :enableFeaturesFail
cls
echo Successfully enabled features:
for /d %%i in (%successEnableFeatures%) do (
  echo %%i
)
pause

:enableFeaturesFail
if "%failEnableFeatures%" equ "" goto :enableFeaturesExit
cls
echo Failed to enable features:
for /d %%i in (%failEnableFeatures%) do (
  echo %%i
)
:askReEnableFeatures
set /p reEnableFeatures=Try enable features again ^(y/n^)? 
if /i "!reEnableFeatures!" equ "y" goto :enableFeatures
if /i "!reEnableFeatures!" neq "n" goto :askReEnableFeatures

:enableFeaturesExit

: Registry modifications
cls
echo Registry modifications..

: SOFTWARE registry modifications
@REM Apply registry modifications
@REM SET regsPath=E:\OneDrive\arkaev\windows-custom-setup\reg-offline
:setRegSoftware
set /p regSoftware="Enter path to SOFTWARE registry modifications (blank to skip): " || goto :noRegSoftware
set regSoftware="%regSoftware:"=%"
if not exist %regSoftware% (
  echo  "%regSoftware%" is not found. Try another..
  pause
  goto :setRegSoftware
)
call :modifyRegistry SOFTWARE "%mountDir:"=%\Windows\System32\config\SOFTWARE" %regSoftware%
 :noRegSoftware

: USER registry modifications
@REM SET regUser=%regsPath%\offline_HKCU.reg
:setRegUser
set /p regUser="Enter path to USER registry modifications (blank to skip): " || goto :noRegUser
set regUser="%regUser:"=%"

if not exist %regUser% (
  echo %regUser% is not found. Try another..
  pause
  goto setRegUser
)

call :modifyRegistry USER "%mountDir:"=%\Windows\System32\config\DEFAULT" %regUser%

call :modifyRegistry USER "%mountDir:"=%\Users\Default\NTUSER.DAT" %regUser%

:noRegUser


: Remove preinstalled apps
@REM Remove preinstalled apps
cls
:getPackagesToRemoveList
echo Remove Provisioned Packages:
set /p packagesToDeletePath="Enter path to file with packages to delete (blank to generate file): "
if "%packagesToDeletePath%" equ "" goto :generatePackagesToRemoveList
set packagesToDeletePath="%packagesToDeletePath:"=%"
if not exist %packagesToDeletePath% (
  echo %packagesToDeletePath% not found. Try another..
  goto :getPackagesToRemoveList
) else (
  goto :removeProvisionedPackages
)
:generatePackagesToRemoveList
set packagesToDeletePath="%targetDir:"=%\pp.txt"
echo List of Provisined Packages:
@REM in case of preplaced pp.txt skip override
powershell -command "& { New-Item -Path %packagesToDeletePath% -Value \"\" -Force | Out-Null; Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { Add-Content -Path %packagesToDeletePath% -Value $_.DisplayName -Encoding oem } }"
echo.
echo Edit file %packagesToDeletePath% to contain only packages to delete.
echo or place your own list to delete
echo.
pause

:removeProvisionedPackages
cls
echo "Provisioned Packages to delete (from %packagesToDeletePath%):"
type %packagesToDeletePath%
set packagesToDelete=
for /f "tokens=* usebackq delims=" %%i in (%packagesToDeletePath%) do set packagesToDelete=!packagesToDelete!,'%%i'
set packagesToDelete=%packagesToDelete:~1%

powershell -command "& { $apps = @( %packagesToDelete% ); Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %mountDir% -PackageName $_.PackageName | Out-Null } } }"


: Copy preconfigured Edge User Data
@REM Copy preconfigured Edge User Data
REM SET edgeSettings=E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip
cls
echo Copy preconfigured Edge User Data..
:setEdge
set /p edgePath="Enter path to Edge settings archive (blank to skip): " || goto :noEdge
set edgePath="%edgePath:"=%"
set edgeTargetParent="%mountDir:"=%\Users\Default\AppData\Local\Microsoft"
set edgeTarget="%edgeTargetParent:"=%\Edge"

if exist %edgePath% (
  if exist %edgeTarget% rd /s /q %edgeTarget%
  7z x %edgePath% -o%edgeTargetParent%
  if %errorlevel% equ 0 (
    echo Edge settings extracted successfully..
  ) else (
    echo Failed to extract Edge settings..
    rd /s /q %edgeTarget%
  )
) else (
  echo %edgePath% is not found. Try another..
  pause
  goto :setEdge
)
:noEdge


: Copy unattend.xml files
@REM Copy unattend.xml files
cls
echo Copy unattend.xml files..
REM SET xmlPath=E:\OneDrive\arkaev\windows-custom-setup\xml
REM SET unattendPanther=%xmlPath%\Panther\unattend.xml
REM SET unattendSysprep=%xmlPath%\Sysprep\unattend.xml

:setUnattendPanther
set /p unattendPanther="Enter path to Panther\unattend.xml (blank to skip): " || goto :noUnattendPanther
set unattendPanther="%unattendPanther:"=%"

if exist %unattendPanther% (
  mkdir "%mountDir:"=%\Windows\Panther\"
  copy %unattendPanther% "%mountDir:"=%\Windows\Panther\"
) else (
  echo %unattendPanther% is not found. Try another..
  pause
  goto :setUnattendPanther
)
:noUnattendPanther

:setUnattendSysprep
set /p unattendSysprep="Enter path to Sysprep\unattend.xml (blank to skip): " || goto :noUnattendSysprep
set unattendSysprep="%unattendSysprep:"=%"
if exist %unattendSysprep% (
  copy %unattendSysprep% "%mountDir:"=%\Windows\System32\Sysprep\"
) else (
  echo %unattendSysprep% is not found. Try another..
  pause
  goto setUnattendSysprep
)
:noUnattendSysprep

:saveImage
@REM Save image
cls
echo Saving install image..
dism /unmount-image /mountdir:%mountdir% /commit
if errorlevel 1 (
  pause
  goto :saveImage
)
@REM Create ISO with modified image
@REM If no oscdimg no ISO, show warning and skip
if "%inputFormat%" neq "iso" goto :exitISO
set oscdimgPath=
where oscdimg 2>NUL >NUL
if errorlevel 0 (
  goto :askISO
)
set oscdimgPath="%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
dir %oscdimgPath% 2>NUL >NUL
if errorlevel 1 (
  @REM echo Program oscdimg is not present in system..
  goto :exitISO
)

cls
:askISO
set /p isISO=Create ISO (y/n)? 
if /i "%isISO%" equ "y" goto :yesISO
if /i "%isISO%" equ "n" goto :exitISO
goto :askISO

:yesISO
@REM MKDIR images\original
@REM MOVE iso\sources\install.wim images\original\
copy %imageModified% "%isoDir:"=%\sources\"
set PATH=%PATH%;%oscdimgPath:"=%
set etfsboot="%isoDir:"=%\boot\etfsboot.com"
set efisys="%isoDir:"=%\efi\microsoft\boot\efisys.bin"
set source=%isoDir%
:askISOName
set /p target="Enter iso name: " || goto :askISOName
echo %target%| findstr /ir "\.iso$" >NUL
if errorlevel 1 set target=%target%.iso
set target="%targetDir:"=%\%target%"
:setISOLabel
set /p label="Enter iso label: " || goto :setISOLabel
set label="%label:"=%"
OSCDIMG -h -m -o -u2 -udfver102 -bootdata:2#p0,e,b%etfsboot%#pEF,e,b%efisys% -l%label% %source% %target%
if %errorlevel% equ 0 (
  echo ISO created successfully..
) else (
  echo Failed to create ISO..
)
@REM rmdir /s /q %isoDir%
@REM RMDIR /S /Q images/original
:exitISO

cls
:askVHD
set /p isVHD=Modify VHD and apply image (y/n)? 
if /i "%isVHD%"=="n" goto :noVHD
if /i "%isVHD%"=="y" goto :yesVHD
goto askVHD

:yesVHD
set vhdSizeMinGB=65
: manually set %vhdSizeMinGB% * 1024 ^ 3
set vhdSizeMinB=000069793218560
: pasrtition size for system manually set 64 * 1024 ^ 3
@REM set partitionSizeSystemMinGB=0000000064
:setVHD
set /p vhdPath="Enter path to vhdx: " || goto :setVHD
: default path with quotes
set vhdPath="%vhdPath:"=%"
echo %vhdPath:"=%| findstr /ir "\.vhdx$" >NUL
if %errorlevel% neq 0 (
  echo VHD should have vhdx extension. Select another..
  goto :setVHD
) else (
  if not exist %vhdPath% (
    echo VHD (%vhdPath%) not found. Select another..
    goto :setVHD
  )
)

for /f "delims=" %%i in ('dir /b /s %vhdPath%') do (
  set sizeB=000000000000000%%~zi
)
if %sizeB:~-15% lss %vhdSizeMinB:~-15% (
  echo Selected VHD is smaller than %vhdSizeMinGB% GB. Select another..
  goto :setVHD
)

:setNumberOfPartitions
set /p numberOfPartitions=Enter number of partitions: 
echo %numberOfPartitions%| findstr /r "^[1-9][0-9]*$" >NUL
if %errorlevel% neq 0 (
  echo Use only numbers. Try another..
  goto :setNumberOfPartitions
)

:set vhdLabelPrefix
set /p labelPrefix="Enter vhd labels prefix: " || goto :vhdLabelPrefix

@REM get partitions labels and sizes

for /l %%i in (1,1,%numberOfPartitions%) do (
  set /p partitionLabel%%i=Enter partition %%i label: 
  call :getPartitionSize %%i %numberOfPartitions%
)

@REM get available letters
set partitionCounter=0

set lettersString="C D E F G H I J K L M N O P Q R S T U V W X Y Z"
set letters=!lettersString:"=!

:changeLetter
for /l %%i in (!partitionCounter!,1,%numberOfPartitions%) do (
  for %%j in ( !letters! ) do (
    dir "%%j:\" 2>NUL >NUL
    if errorlevel 1 (
      set "partitionLetter%%i=%%j"
      set /a partitionCounter+=1
    )
    set letters=!letters:~2!
    goto :changeLetter
  )
)

echo User defined partitions:
for /l %%i in (1,1,%numberOfPartitions%) do (
  echo Partition %%i. !partitionLetter%%i!:\ %labelPrefix%-!partitionLabel%%i! - !partitionSize%%i!
)
pause

cls
(
echo sel vdisk file=%vhdPath%
echo attach vdisk
echo clean
echo convert gpt
echo sel part 1
echo delete part override
echo create part efi size=100
echo format quick fs=fat32 label="%labelPrefix%-efi"
echo assign letter=%partitionLetter0%
echo create part msr size=16
if %numberOfPartitions% equ 1 (
  echo create part pri
) else (
  set /a partitionSize1+=500
  echo create part pri size=!partitionSize1!
)
if "%partitionLabel1%" equ "" (
  echo format quick fs=ntfs
) else (
  echo format quick fs=ntfs label="%labelPrefix%-%partitionLabel1%"
)
echo assign letter=%partitionLetter1%
echo shrink desired=450
echo create part pri size=450
echo format quick fs=ntfs label="%labelPrefix%-recovery"
echo set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
if %numberOfPartitions% gtr 1 (
  for /l %%i in (2,1,%numberOfPartitions%) do (
    if !partitionSize%%i! equ 0 (
      echo create part pri
    ) else (
      echo create part pri size=!partitionSize%%i!
    )
    if "!partitionLabel%%i!" equ "" (
      echo format quick fs=ntfs
    ) else (
      echo format quick fs=ntfs label="%labelPrefix%-!partitionLabel%%i!"
    )
    echo assign letter=!partitionLetter%%i!
  )
)
echo exit
) > diskpart-script.txt

diskpart /s "diskpart-script.txt"

if %errorlevel% equ 0 (
  echo Diskpart script completed successfully..
  @REM del "diskpart-script.txt"
) else (
  echo Diskpart script failed..
  @REM goto ?
)

dism /apply-image /imagefile:%imageModified% /index:%imageIndex% /applydir:%partitionLetter1%:\


:askCurrentBoot
set /p askCurrentBoot=Add to current boot manager (y/n)? 
if /i "%isVHD%" equ "y" (
  bcdboot %partitionLetter1%:\Windows
  :setBootDescription
  set /p bootDescription="Enter boot menu description: " || goto :setBootDescription
  bcdedit /set {default} description "%bootDescription%"
  goto :exitCurrentBoot
)
if /i "%isVHD%" neq "n" goto :askCurrentBoot
:exitCurrentBoot

bcdboot %partitionLetter1%:\Windows /s %partitionLetter0%: /f UEFI
(
  echo sel vol=%partitionLetter0%
  echo remove letter=%partitionLetter0%
  echo sel vdisk file=%vhdPath%
  echo detach vdisk
  echo exit
) | diskpart

:noVHD

cls
echo Operations complete..

exit /b

:modifyRegistry
@REM call :modifyRegistry HIVE_TYPE PATH_TO_HIVE PATH_TO_REG
@REM %1 - HIVE TYPE (USER, SOFTWARE)
@REM %2 - path to hive
@REM %3 - reg file to import
reg load HKLM\OFFLINE %2
if errorlevel 1 (
  echo Failed to load %1 registry..
  goto :exitModifyRegistry
)

reg import %3
if errorlevel 1 echo Failed to import %1 registry modification..

reg unload HKLM\OFFLINE
if errorlevel 1 echo Failed to unload %1 registry..

if %errorlevel% equ 0 echo %1 registry modification imported successfully..
:exitModifyRegistry
exit /b

:getPartitionSize
@REM %1 - %%i
@REM %2 - %numberOfPartitions%
@REM implement size requirements
:getNewSize
set /p partitionSize%1=Enter parition %1 size: 
@REM set currentSize=!size%1!
@REM echo currentSize: %currentSize%
if %1 equ %2 (
  if "!partitionSize%1!" equ "" set partitionSize%1=0
) else (
  echo !partitionSize%1!| findstr /r "^[1-9][0-9]*$" >NUL
  if errorlevel 1 (
    echo Use only numbers. Try another partition size..
    goto :getNewSize
  )
)
set /a partitionSize%1*=1024
exit /b
