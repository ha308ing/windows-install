:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

: Select step
:stepSelect
echo Select step:
echo     1. Extract iso
echo     2. Copy install image for modification
echo     3. Get install image info
echo     4. Mount install image
set /p step=

:askTargetDir
set /p targetDir=Enter target directory: 
set imageModified=%targetDir%\images\modified\install.wim

if %step% LSS 1 goto stepSelect
if %step% GTR 4 goto stepSelect

if %step% EQU 1 goto extractIso
if %step% EQU 2 goto copyImageForMod
if %step% EQU 3 goto getImageInfo
if %step% EQU 4 goto mountImage

:extractIso
:askIsoPath
set /p iso=Enter path to iso: 

if not exist %iso% (
  echo File not found. Try other iso path..
  pause
  goto askIsoPath
)

dir /b %iso% | findstr /ir \.iso$ >NUL
if errorlevel 1 (
    echo File must have iso extension
    goto askIsoPath
)

:checkTargetDir
if not exist %targetDir% (
    set /p askCreateTargetDir="Target dir does not exist. Create? (y/n) "
    if /i "!askCreateTargetDir!" equ "y" (
        mkdir %targetDir% 
        goto checkTargetDir
    )
    if /i "!askCreateTargetDir!" equ "n" (
        echo Answer is no..
        goto askTargetDir
    )
)

echo Extracting..
7z x %iso% -o%targetDir%\iso >NUL 2>&1

if errorlevel 1 (
    echo Extracting failed..
    goto :EOF
) else (
    echo Extracted successfully..
)

:copyImageForMod
if not exist %targetDir%\iso\sources\install.wim (
  echo install.wim is not found in iso dir..
  set /p askExtractIso="Extract iso? (y/n) "
  if /i "%askExtractIso%"=="y" (
    goto extractIso
  )
  if /i "%askExtractIso%"=="n" (
    echo Place install.wim to %targetDir%\iso\sources\install.wim and try again..
  )
  pause
  goto copyImageForMod
)
: Copy install.wim for modification
echo Copying install.wim..
xcopy /Y %targetDir%\iso\sources\install.wim %targetDir%\images\modified\ 2>&1 >NUL
if exist %imageModified% (
    echo Ok. install.wim is found..
) else (
    echo Not ok. install.wim is not found..
)

:getImageInfo
: Get image info
if not exist %imageModified% (
  echo install.wim is not found..
  set /p askCopyImage="Copy install.wim from iso dir? (y/n) "
  if /i "!askCopyImage!"=="y" (
    goto copyImageForMod
  )
  if /i "!askCopyImage!"=="n" (
    echo Place install.wim to %imageModified% and try again..
    pause
  )
  goto getImageInfo
)
dism /Get-ImageInfo /ImageFile:%imageModified%

:mountImage
: Select image index
:selectImageIndex
set /p imageIndex=Select image index: 

: Get selected image index info
dism /Get-ImageInfo /ImageFile:%imageModified% /Index:%imageIndex% 2>NUL
if %errorlevel% NEQ 0 (
  echo Can't get info about image. Try another index..
  goto selectImageIndex
)

: Create dir for dism mount
set mountDir=%targetDir%\mount
dism /unmount-image /mountdir:%mountdir% /discard 2>&1 >NUL
rd /s /q %mountDir%
echo Creating dir for mount..
mkdir %mountDir%

: Mount install image
echo Mounting install image..
DISM /MOUNT-IMAGE /IMAGEFILE:%imageModified% /MOUNTDIR:%mountDir% /index:%imageIndex% 2>&1 >NUL
if %errorlevel% neq 1 (
  echo Mounting failed..
)

: Install image servicing
REM Image international servicing
echo Image international servicing
DISM /IMAGE:%mountDir% /SET-TIMEZONE:"Russian Standard Time"
DISM /IMAGE:%mountDir% /SET-INPUTLOCALE:en-US;ru-RU
DISM /IMAGE:%mountDir% /SET-SYSLOCALE:ru-RU
DISM /IMAGE:%mountDir% /SET-USERLOCALE:ru-RU
DISM /IMAGE:%mountDir% /ENABLE-FEATURE /FEATURENAME:Microsoft-Hyper-V-All

: Apply registry modifications
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
  REG IMPORT %regSoftware%
  REG UNLOAD HKLM\OFFLINE
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
  REG IMPORT %regUser%
  REG UNLOAD HKLM\OFFLINE

  REG LOAD HKLM\OFFLINE %mountDir%\Users\Default\NTUSER.DAT
  REG IMPORT %regUser%
  REG UNLOAD HKLM\OFFLINE
) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setRegUser
)
:noRegUser

: Remove preinstalled apps
REM Remove preinstalled apps
powershell -command "Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { $name = '\"'+$_.DisplayName+'\"'; Write-Host $name }"

powershell -command "$apps = @( 'Clipchamp.Clipchamp', 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.GamingApp', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.People', 'Microsoft.Todos', 'Microsoft.WindowsCamera', 'microsoft.windowscommunicationsapps', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo', 'MicrosoftCorporationII.MicrosoftFamily', 'MicrosoftCorporationII.QuickAssist' );  Get-AppxProvisionedPackage -Path %mountDir% | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path %mountDir% -PackageName $_.PackageName | Out-Null } }"

: Copy preconfigured Edge User Data
REM Copy preconfigured Edge User Data
REM SET edgeSettings=E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge.zip

:setEdge
set /p edgeSettings="Enter path to Edge settings archive (blank to skip): "
if "%edgeSettings%"=="" (
  echo "Skipping Edge settings copy.."
  goto noEdge
)
if exist %edgeSettings% (
  7z x %edgeSettings% -o%mountDir%\Users\Default\AppData\Local\Microsoft\
) else (
  echo "Specified file is not found. Try another.."
  pause
  goto setEdge
)
:noEdge


: Copy unatted.xml files
REM Copy unatted.xml files
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
SET label=Windows 11 Insider
OSCDIMG -h -m -o -u2 -udfver102 -bootdata:2#p0,e,b"%etfsboot%"#pEF,e,b"%efisys%" -l"%label%" "%source%" "%target%"
RMDIR /S /Q iso
REM RMDIR /S /Q images/original
GOTO exitISO

:noISO
ECHO Not creating ISO

:exitISO


REM
REM             Apply image to VHDX
REM

REM Ask for vhd file, and partitions

:askVHD
SET /P isVHD=Modify VHD and apply image (y/n)? 
IF /I "%isVHD%"=="n" goto noVHD
IF /I "%isVHD%"=="y" goto yesVHD
GOTO askVHD

:yesVHD
set /p vhdFile="Enter path to vhdx file: "
if "%vhdFile%"=="" (
  echo "Skip vhd procedures.."
  pause
  goto noVHD
)
if not exist %vhdFile% (
  echo "VHD file is not found try another.."
  pause
  goto yesVHD
)
set /p labelPrefix="Enter prefix for partitions labels: "
(
ECHO sel vdisk file=%vhdFile%
ECHO attach vdisk
ECHO clean
ECHO convert gpt
ECHO sel part 1
ECHO delete part override
ECHO create part efi size=100
ECHO format quick fs=fat32 label="%labelPrefix%-efi"
ECHO assign letter=S
ECHO create part msr size=16
ECHO create part pri size=64970
ECHO format quick fs=ntfs label="%labelPrefix%-system"
ECHO assign letter=F
ECHO shrink minimum=450
ECHO create part pri size=450
ECHO format quick fs=ntfs label="%labelPrefix%-recovery"
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
ECHO create part pri
ECHO format quick fs=ntfs label="%labelPrefix%-data"
ECHO assign letter=G
ECHO exit
) | diskpart

DISM /APPLY-IMAGE  /ImageFile:%imageModified% /Index:%imageIndex% /APPLYDIR:F:\

CD /D F:\Windows\System32
bcdboot F:\Windows /s S: /f UEFI
bcdboot F:\Windows
set /p bootDescription="Enter boot menu description: "
bcdedit /set {default} description "%bootDescription%"
(
  echo sel vdisk file=%vhdFile%
  echo sel vol=S
  echo remove letter=S
  echo detach vdisk
  echo exit
) | diskpart
GOTO exitVHD

:noVHD
ECHO No VHD
:exitVHD
