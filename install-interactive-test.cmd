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
    ) else goto askTargetDir
)
echo Target dir %targetDir% created successfully..
set imageModified="%targetDir":"=%\images\modified\install.wim"
set mountDir="%targetDir:"=%\mount"
set isoDir="%targetDir:"=%\iso"

@REM ask for iso or wim and decide by extension
@REM for iso creation ask info when needed
:askInputPath
set /p inputPath=Enter path to iso or wim:  || goto :askInputPath
set inputPath="%inputPath:"=%"
@REM no inputFormat? if wim -> skip iso?
set inputFormat=
set wimSource=
echo %inputPath%| findstr \.wim\"$
if %errorlevel% equ 0 (
  set inputFormat=wim
  set wimSource="%inputPath:"=%"
  @REM goto :inputFormatWIM
) else (
  echo %inputPath%| findstr \.iso\"$
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
rd /s /q %isoDir%
7z x %isoPath% -o%isoDir% 2>&1 >NUL
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

: Clear previous mount dir
:clearMountDir
echo Clear mount dir..
dism /unmount-image /mountdir:%mountdir% /discard >NUL
rd /s /q %mountDir% >NUL
echo Create mount dir..
mkdir %mountDir%

: Mount image
:inputImageIndex
set /p imageIndex=Select image index: || goto :inputImageIndex
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
@REM do the same as with provisioned pacakges: file edition variant
cls
echo Image features:
dism /image:%mountDir% /get-features /format:table 1 > fl.txt
type fl.txt

echo Enter features to enable (see "fl.txt"): 
set /p inputFeatures=

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
set /p regSoftware=Enter path to SOFTWARE registry modifications ^(blank to skip^): || goto :noRegSoftware
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
set /p regUser=Enter path to USER registry modifications ^(blank to skip^): || goto :noRegUser
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
echo List of Provisined Packages:
powershell -command "& { New-Item -Path pp.txt -Value \"\" -Force | Out-Null; Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { Write-Host $_.DisplayName; Add-Content -Path pp.txt -Value $_.DisplayName -Encoding oem } }"


echo Edit file pp.txt to contain only package delete or place your own list to delete
pause
set packagesToDelete=
for /f "tokens=* delims=" %%i in (pp.txt) do set packagesToDelete=!packagesToDelete!,'%%i'
set packagesToDelete=%packagesToDelete:~1%

powershell -command "& { $apps = @( %packagesToDelete% ); Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %mountDir% -PackageName $_.PackageName | Out-Null } } }"


: Copy preconfigured Edge User Data
@REM Copy preconfigured Edge User Data
REM SET edgeSettings=E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip
cls
echo Copy preconfigured Edge User Data..
:setEdge
set /p edgeSettings="Enter path to Edge settings archive (blank to skip): " || goto :noEdge
set edgeSettings="%edgeSettings:"=%"

if exist %edgeSettings% (
  rd /s /q "%mountDir:"=%\Users\Default\AppData\Local\Microsoft\Edge\"
  7z x %edgeSettings% -o"%mountDir:"=%\Users\Default\AppData\Local\Microsoft\"
  if %errorlevel% equ 0 (
    echo Edge settings extracted successfully..
  ) else (
    echo Failed to extract Edge settings..
    rd /s /q "%mountDir:"=%\Users\Default\AppData\Local\Microsoft\Edge\"
  )
) else (
  echo %edgeSettings% is not found. Try another..
  pause
  goto :setEdge
)
:noEdge


: Copy unattend.xml files
REM Copy unattend.xml files
cls
echo Copy unattend.xml files..
REM SET xmlPath=E:\OneDrive\arkaev\windows-custom-setup\xml
REM SET unattendPanther=%xmlPath%\Panther\unattend.xml
REM SET unattendSysprep=%xmlPath%\Sysprep\unattend.xml

:setUnattendPanther
set /p unattendPanther="Enter path to Panther\unattend.xml (blank to skip): " || 
  goto :noUnattendPanther
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
echo Saving install image..
dism /unmount-image /mountdir:%mountdir% /commit

REM
REM             Create ISO with modified image
REM

REM If no oscdimg no iso, show warning and skip

:askISO
SET /P isISO=Create ISO (y/n)? 
IF /I "%isISO%"=="n" goto noISO
IF /I "%isISO%"=="y" goto yesISO
GOTO askISO

:yesISO
REM MKDIR images\original
REM MOVE iso\sources\install.wim images\original\
COPY images\modified\install.wim iso\sources\
SET PATH=%PATH%;%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg
SET etfsboot=iso\boot\etfsboot.com
SET efisys=iso\efi\microsoft\boot\efisys.bin
SET source=iso
SET target=%isoName%-modified.iso
:setIsoLabel
SET /p label=Enter iso label^: || goto :setIsoLabel
OSCDIMG -h -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%etfsboot%"#pEF,e,b"%efisys%" -l"%label%" "%source%" "%target%"
RMDIR /S /Q iso
REM RMDIR /S /Q images/original
GOTO exitISO

:noISO
ECHO Not creating ISO

:exitISO

:askVHD
SET /P isVHD=Modify VHD and apply image (y/n)? 
IF /I "%isVHD%"=="n" goto noVHD
IF /I "%isVHD%"=="y" goto yesVHD
GOTO askVHD

:yesVHD
:setVHD
set stepTitle=vhdx allocation
set vhdSizeMinGB=65
: manually set %vhdSizeMinGB% * 1024 ^ 3
set vhdSizeMinB=000069793218560
: pasrtition size for system manually set 64 * 1024 ^ 3
set partitionSizeSystemMinGB=0000000064
set /p vhd="%stepTitle%: Enter path to vhdx: "
if ^"%vhd%^" equ "" goto :setVHD
: default path with quotes
set vhd="%vhd:"=%"

echo %vhd:"=%| findstr /i /r "\.vhdx$" >NUL
if %errorlevel% neq 0 (
  echo %stepTitle%: vhdx should have vhdx extension. Select another..
  goto :setVHD
) else (
  if not exist %vhd% (
    echo %stepTitle%: vhdx ^(%vhd%^) not found. Select another..
    goto :setVHD
  )
)

for /f "delims=" %%i in ('dir /b /s %vhd%') do (
  set sizeB=00000%%~zi
  
  echo %stepTitle%: VHD size: !sizeB:~-15! B
  echo %stepTitle%: VHD min size: !vhdSizeMinB:~-15! B
  if !sizeB:~-15! lss !vhdSizeMinB:~-15! (
    echo %stepTitle%: Selected VHD is smaller than %vhdSizeMinGB% GB. Select another..
    goto :setVHD
  )
  echo B: !sizeB!
  set sizeKB=!sizeB:~0,-3!
  echo KB: !sizeKB!
  set sizeMB=!sizeKB:~0,-3!
  echo MB: !sizeMB!
  set sizeGB=!sizeMB:~0,-3!
  echo GB: !sizeGB!
)

:setNumberOfPartitions
set /p numberOfPartitions="%stepTitle%: Enter number of partitions: "
echo %numberOfPartitions%| findstr /r ^[1-9][0-9]*$ > NUL
if !errorlevel! neq 0 (
  echo Use only numbers. Try another..
  set /a partitionIndex-=1
  goto :setNumberOfPartitions
)

set /p labelPrefix="%stepTitle%: Enter vhd labels prefix: "

set partitionSizeSystem=all available

@REM if %numberOfPartitions% gtr 1 (
@REM :setPartitionSizeSystem
@REM set /p partitionSizeSystem="%stepTitle%: Enter system partition size: "
@REM echo %stepTitle%: Partition should be less than %sizeGB% GB
@REM if !partitionSizeSystem! geq %sizeGB% goto :setPartitionSizeSystem
@REM ask for sizes, first is system - check size
@REM create variables from 1, 0 for efi (e.g. 0-efi, 1-system,2-data)
@REM ask for labels?
@REM for last partition size=0 - which means all available space
@REM use sizes in GB?
:setPartitionSize
set partitionIndex=1
for /l %%i in (!partitionIndex!,1,%numberOfPartitions%) do (
  if "!partitionLabel%%i!" equ "" (
    if %%i equ 1 echo %stepTitle%: First partition for system:
    set /p "partitionLabel%%i=Enter partition %%i label: "
  )

  if %%i equ %numberOfPartitions% (
    set "partitionSize%%i=0"
  ) else (
    set /p "partitionSize%%i=Enter partition %%i size in GB: "
    echo !partitionSize%%i!| findstr /r ^[1-9][0-9]*$ > NUL
    if !errorlevel! neq 0 (
      echo Use only numbers. Try another..
      set /a partitionIndex-=1
      goto :setPartitionSize
    )
  )

  @REM prevent sizes larger than vhdx size
  @REM and other entered sizes

  if %%i equ 1 (
    if  %numberOfPartitions% gtr 1 (
      set "partitionSizeTemp=0000000000!partitionSize%%i!"
      if !partitionSizeTemp:~-10! lss !partitionSizeSystemMinGB! (
        @REM use number from variable instead of 64
        echo %stepTitle%: System partition must be larger than 64 GB. Enter another..
        set /a partitionIndex-=1
        goto :setPartitionSize
      ) else (
        set /a partitionIndex+=1
      )
    )
  )
  set /a "partitionSize%%i*=1024"
)
@REM )
@REM )

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

echo %stepTitle%: User defined partitions:
for /l %%i in (1,1,%numberOfPartitions%) do (
  echo Partition %%i. !partitionLetter%%i!:\ %labelPrefix%-!partitionLabel%%i! - !partitionSize%%i!
)

@REM echo %stepTitle%: partitionSizeSystem: %partitionSizeSystem%

(
ECHO sel vdisk file=%vhd%
ECHO attach vdisk
ECHO clean
ECHO convert gpt
ECHO sel part 1
ECHO delete part override
ECHO create part efi size=100
ECHO format quick fs=fat32 label="%labelPrefix%-efi"
ECHO assign letter=%partitionLetter0%
ECHO create part msr size=16
if %numberOfPartitions% equ 1 (
  ECHO create part pri
) else (
  set /a partitionSize1+=500
  ECHO create part pri size=!partitionSize1!
)
ECHO format quick fs=ntfs label="%labelPrefix%-%partitionLabel1%"
ECHO assign letter=%partitionLetter1%
ECHO shrink desired=450
ECHO create part pri size=450
ECHO format quick fs=ntfs label="%labelPrefix%-recovery"
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
if %numberOfPartitions% gtr 1 (
  for /l %%i in (2,1,%numberOfPartitions%) do (
    if !partitionSize%%i! equ 0 (
      ECHO create part pri
    ) else (
      ECHO create part pri size=!partitionSize%%i!
    )
    ECHO format quick fs=ntfs label="%labelPrefix%-!partitionLabel%%i!"
    ECHO assign letter=!partitionLetter%%i!
  )
)
ECHO exit
) > diskpart-script.txt

diskpart /s "diskpart-script.txt"

if %errorlevel% equ 0 (
  echo Diskpart script completed successfully. Removing script file..
  @REM del "diskpart-script.txt"
) else (
  echo Diskpart script failed..
  goto :EOF
  @REM goto ?
)

DISM /APPLY-IMAGE  /ImageFile:%imageModified% /Index:%imageIndex% /APPLYDIR:%partitionLetter1%:\


:askCurrentBoot
SET /P askCurrentBoot=Add to current boot manager (y/n)? 
IF /I "%isVHD%"=="n" goto exitCurrentBoot
IF /I "%isVHD%"=="y" (
  bcdboot %partitionLetter1%:\Windows
  :setBootDescription
  set /p bootDescription="Enter boot menu description: " || goto :setBootDescription
  bcdedit /set {default} description "%bootDescription%"
  goto exitCurrentBoot
)
goto :askCurrentBoot
:exitCurrentBoot

bcdboot %partitionLetter1%:\Windows /s %partitionLetter0%: /f UEFI
(
  echo sel vol=%partitionLetter0%
  echo remove letter=%partitionLetter0%
  echo sel vdisk file=%vhd%
  echo detach vdisk
  echo exit
) | diskpart

:exitVHD



exit /b

:modifyRegistry
@REM call :modifyRegistry HIVE_TYPE PATH_TO_HIVE PATH_TO_REG
@REM %1 - HIVE TYPE (USER, SOFTWARE)
@REM %2 - path to hive
@REM %3 - reg file to import
echo reg load HKLM\OFFLINE %2 ^>NUL
if errorlevel 0 (
  echo Failed to load %1 registry..
  goto :exitModifyRegistry
)

echo reg import %3 ^>NUL
if errorlevel 1 echo Failed to import %1 registry modification..

echo reg unload HKLM\OFFLINE ^>NUL
if errorlevel 1 echo Failed to unload %1 registry..

if %errorlevel% equ 0 echo %1 registry modification imported successfully..
:exitModifyRegistry
exit /b
