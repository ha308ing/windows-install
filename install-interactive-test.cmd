:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

:askTargetDir
set /p targetDir=Enter target directory: 
if not exist %targetDir% goto askTargetDir
set imageModified=%targetDir%\images\modified\install.wim
set mountDir=%targetDir%\mount

:checkTargetDir
if not exist %targetDir% (
    set /p askCreateTargetDir="Target dir does not exist. Create? (y/n) "
    if /i "!askCreateTargetDir!" equ "y" (
        mkdir %targetDir% 
        goto checkTargetDir
    ) else goto askTargetDir
)

@REM ask for iso or wim and decide by extension
@REM for iso creation ask info when needed
:askIsoPath
set /p iso="Enter path to iso (blank to select install.wim): " || goto :askImagePath

if not exist %iso% (
  echo File not found. Try other iso path..
  pause
  set iso=
  goto askIsoPath
)

dir /b %iso% | findstr /ir \.iso$ >NUL
if errorlevel 1 (
    echo File must have iso extension
    set iso=
    goto askIsoPath
)

echo Extracting..
rd /s /q %targetDir%\iso
7z x %iso% -o%targetDir%\iso 2>&1
if errorlevel 1 (
    echo Extracting failed..
    goto askIsoPath
) else (
    echo Extracted successfully..
)

set imagePath=%targetDir%\iso\sources\install.wim
goto copyImageForMod

:askImagePath
set /p imagePath="Enter path to install.wim (blank to select iso): "
if "%imagePath%"=="" goto askIsoPath
if not exist !imagePath! (
  echo install.wim file is not found..
  set imagePath=
  goto :askImagePath
)
dir /b %imagePath% | findstr /ir \.wim$ >NUL
if errorlevel 1 (
    echo File must have wim extension
    set imagePath=
    goto askImagePath
)

:copyImageForMod
if not exist %imagePath% (
  echo install.wim is not found..
  goto askIsoPath
)

: Copy install.wim for modification
if "%imagePath:"=%" NEQ "%imageModified:"=%" (
  echo Copying install.wim..
  xcopy /Y %imagePath% %targetDir%\images\modified\
)
if exist %imageModified% (
  echo Ok. install.wim is found..
) else (
  echo Not ok. install.wim is not found..
  goto askIsoPath
)

:selectImageIndex
: Get image info
dism /Get-ImageInfo /ImageFile:%imageModified%
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
echo Clearing mount dir..
dism /unmount-image /mountdir:%mountdir% /discard
rd /s /q %mountDir%
echo Creating dir for mount..
mkdir %mountDir%

: Mount image
set /p imageIndex=Select image index: 
echo Mounting install image..
DISM /MOUNT-IMAGE /IMAGEFILE:%imageModified% /MOUNTDIR:%mountDir% /index:%imageIndex%
if %errorlevel% neq 0 (
  echo Mounting failed..
  goto clearMountDir
)

: DISM image servicing
echo DISM image servicing..

echo Image international servicing..

DISM /IMAGE:%mountDir% /SET-TIMEZONE:"Russian Standard Time"
if errorlevel 0 ( echo Timezone set.. ) else ( echo Failed to set timezone.. )

DISM /IMAGE:%mountDir% /SET-INPUTLOCALE:en-US;ru-RU
if errorlevel 0 ( echo Input locale set.. ) else ( echo Failed to set input locale.. )

DISM /IMAGE:%mountDir% /SET-SYSLOCALE:ru-RU
if errorlevel 0 ( echo System locale set.. ) else ( echo Failed to set system locale.. )

DISM /IMAGE:%mountDir% /SET-USERLOCALE:ru-RU
if errorlevel 0 ( echo User locale set.. ) else ( echo Failed to set user locale.. )

DISM /IMAGE:%mountDir% /ENABLE-FEATURE /FEATURENAME:Microsoft-Hyper-V-All
if errorlevel 0 ( echo Hyper-V enabled.. ) else ( echo Failed to enable Hyper-V.. )


: Registry modifications
echo Registry modifications..

: SOFTWARE registry modifications
REM Apply registry modifications
REM SET regsPath=E:\OneDrive\arkaev\windows-custom-setup\reg-offline
:setRegSoftware
set /p regSoftware="Enter path to SOFTWARE registry modifications (blank to skip): "
if "%regSoftware%"=="" (
  echo "Skipping SOFTWARE registry modifications.."
  goto noRegSoftware
)
if exist %regSoftware% (

  REG LOAD HKLM\OFFLINE %mountDir%\Windows\System32\config\SOFTWARE
  if errorlevel 0 ( echo SOFTWARE registry loaded.. ) else ( echo Failed to load SOFTWARE registry.. )

  REG IMPORT %regSoftware%
  if errorlevel 0 ( echo SOFTWARE registry modification imported.. ) else ( echo Failed to load import SOFTWARE registry modification.. )

  REG UNLOAD HKLM\OFFLINE
  if errorlevel 0 ( echo SOFTWARE registry unloaded.. ) else ( echo Failed to unload SOFTWARE registry.. )

) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setRegSoftware
)
:noRegSoftware

: USER registry modifications
REM SET regUser=%regsPath%\offline_HKCU.reg
:setRegUser
set /p regUser="Enter path to USER registry modifications (blank to skip): "
if "%regUser%"=="" (
  echo "Skipping USER registry modifications.."
  goto noRegUser
)
if exist %regUser% (

  REG LOAD HKLM\OFFLINE %mountDir%\Windows\System32\config\DEFAULT
  if errorlevel 0 ( echo USER registry loaded.. ) else ( echo Failed to load USER registry.. )

  REG IMPORT %regUser%
  if errorlevel 0 ( echo USER registry modification imported.. ) else ( echo Failed to import USER registry modification.. )

  REG UNLOAD HKLM\OFFLINE
  if errorlevel 0 ( echo USER registry unloaded.. ) else ( echo Failed to unload USER registry.. )

  : default user NTUSER.DAT
  REG LOAD HKLM\OFFLINE %mountDir%\Users\Default\NTUSER.DAT
  if errorlevel 0 ( echo Default user registry loaded.. ) else ( echo Failed to load default user registry.. )

  REG IMPORT %regUser%
  if errorlevel 0 ( echo Default user registry modification imported.. ) else ( echo Failed to import default user registry modification.. )

  REG UNLOAD HKLM\OFFLINE
  if errorlevel 0 ( echo Default user registry unloaded.. ) else ( echo Failed to unload default user registry.. )

) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setRegUser
)
:noRegUser


: Remove preinstalled apps
REM Remove preinstalled apps
echo Removing preinstalled apps..

echo List of preinstalled apps:
powershell -command "Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { $name = '\"'+$_.DisplayName+'\"'; Write-Host $name }"

powershell -command "$apps = @( 'Clipchamp.Clipchamp', 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.GamingApp', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.People', 'Microsoft.Todos', 'Microsoft.WindowsCamera', 'microsoft.windowscommunicationsapps', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo', 'MicrosoftCorporationII.MicrosoftFamily', 'MicrosoftCorporationII.QuickAssist' );  Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %mountDir% -PackageName $_.PackageName | Out-Null } }"


: Copy preconfigured Edge User Data
REM Copy preconfigured Edge User Data
REM SET edgeSettings=E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip

echo Copy preconfigured Edge User Data..
:setEdge
set /p edgeSettings="Enter path to Edge settings archive (blank to skip): "
if "%edgeSettings%"=="" (
  echo "Skipping Edge settings copy.."
  goto noEdge
)
if exist %edgeSettings% (
  rd /s /q %mountDir%\Users\Default\AppData\Local\Microsoft\Edge\
  7z x %edgeSettings% -o%mountDir%\Users\Default\AppData\Local\Microsoft\
  if errorlevel 0 (
    echo Edge settings extracted successfully..
  ) else (
    echo Failed to extract Edge settings..
    rd /s /q %mountDir%\Users\Default\AppData\Local\Microsoft\Edge\
  )
) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setEdge
)
:noEdge


: Copy unattend.xml files
REM Copy unattend.xml files
echo Copy unattend.xml files..
REM SET xmlPath=E:\OneDrive\arkaev\windows-custom-setup\xml
REM SET unattendPanther=%xmlPath%\Panther\unattend.xml
REM SET unattendSysprep=%xmlPath%\Sysprep\unattend.xml

:setUnattendPanther
set /p unattendPanther="Enter path to Panther\unattend.xml (blank to skip): "
if "%unattendPanther%"=="" (
  echo "Skipping copy of Panther\unattend.."
  goto noUnattendPanther
)
if exist %unattendPanther% (
  MKDIR %mountDir%\Windows\Panther\
  COPY %unattendPanther% %mountDir%\Windows\Panther\
) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setUnattendPanther
)
:noUnattendPanther

:setUnattendSysprep
set /p unattendSysprep="Enter path to Sysprep\unattend.xml (blank to skip): "
if "%unattendSysprep%"=="" (
  echo "Skipping copy of Sysprep\unattend.."
  goto noUnattendSysprep
)
if exist %unattendSysprep% (
  COPY %unattendSysprep% %mountDir%\Windows\System32\Sysprep\
) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setUnattendSysprep
)
:noUnattendSysprep


:saveImage
REM Save image
echo Saving install image..
DISM /UNMOUNT-IMAGE /MOUNTDIR:%mountdir% /COMMIT

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
set vhd=^"%vhd:"=%^"

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
