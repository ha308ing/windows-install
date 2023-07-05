:: install preconfigured windows to vhdx
@echo off & chcp 65001 >NUL & setlocal enabledelayedexpansion

:askTargetDir
set /p targetDir=Enter target directory: 
if not exist !targetDir! goto askTargetDir
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

:askIsoPath
set /p iso="Enter path to iso (blank to select install.wim): "
if "%iso%"=="" goto askImagePath

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
