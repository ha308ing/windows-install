@ECHO OFF
SETLOCAL
REM Windows Insider Installation

REM FOR /F "USEBACKQ" %%i IN (`dir /ad /b *_convert`) DO (
REM   SET isoDir=%%i
REM )

SET isoDir=.

FOR /F "USEBACKQ" %%i IN (`dir /b %isoDir%\*.iso`) DO (
  SET isoName=%%i
)

REM MKDIR iso
REM COPY %isoDir%\%isoName% iso\

7z x %isoDir%\%isoName% -oiso\

MKDIR images\modified
copy iso\sources\install.wim images\modified

CD images\modified
MKDIR mount

DISM /MOUNT-IMAGE /IMAGEFILE:install.wim /MOUNTDIR:mount /NAME:"Windows 10 Pro"


REM Image international servicing
DISM /IMAGE:mount /SET-TIMEZONE:"Russian Standard Time"
DISM /IMAGE:mount /SET-INPUTLOCALE:en-US;ru-RU
DISM /IMAGE:mount /SET-SYSLOCALE:ru-RU
DISM /IMAGE:mount /SET-USERLOCALE:ru-RU
DISM /IMAGE:mount /ENABLE-FEATURE /FEATURENAME:Microsoft-Hyper-V-All


REM Apply registry modifications
SET regsPath=E:\OneDrive\arkaev\windows-custom-setup\reg-offline\10
SET regSoftware=%regsPath%\offline_HKLM-Software.reg
SET regUser=%regsPath%\offline_HKCU.reg

REG LOAD HKLM\OFFLINE mount\Windows\System32\config\SOFTWARE
REG IMPORT %regSoftware%
REG UNLOAD HKLM\OFFLINE

REG LOAD HKLM\OFFLINE mount\Windows\System32\config\DEFAULT
REG IMPORT %regUser%
REG UNLOAD HKLM\OFFLINE

REG LOAD HKLM\OFFLINE mount\Users\Default\NTUSER.DAT
REG IMPORT %regUser%
REG UNLOAD HKLM\OFFLINE


REM Remove preinstalled apps
powershell -command "Get-AppxProvisionedPackage -Path mount | ForEach-Object { $name = '\"'+$_.DisplayName+'\"'; Write-Host $name }"

powershell -command "$apps = @( 'Microsoft.549981C3F5F10', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.Microsoft3DViewer', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.MixedReality.Portal', 'Microsoft.MSPaint', 'Microsoft.Office.OneNote', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.Wallet', 'Microsoft.WindowsCamera', 'microsoft.windowscommunicationsapps', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps', 'Microsoft.Xbox.TCUI', 'Microsoft.XboxApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay', 'Microsoft.XboxIdentityProvider', 'Microsoft.XboxSpeechToTextOverlay', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo' );  Get-AppxProvisionedPackage -Path mount | ForEach-Object { if ( $apps -contains $_.DisplayName ) { Write-Host Removing $_.DisplayName...; Remove-AppxProvisionedPackage -Path mount -PackageName $_.PackageName | Out-Null } }"


REM Copy preconfigured Edge User Data
SET edgeSettings=E:\OneDrive\arkaev\windows-custom-setup\edge-clean\Edge10.zip
7z x %edgeSettings% -omount\Users\Default\AppData\Local\Microsoft\


REM Copy unatted.xml files
SET xmlPath=E:\OneDrive\arkaev\windows-custom-setup\xml\10
SET unattendPanther=%xmlPath%\Panther\unattend.xml
REM SET unattendSysprep=%xmlPath%\Sysprep\unattend.xml

MKDIR mount\Windows\Panther\
COPY %unattendPanther% mount\Windows\Panther\

REM COPY %unattendSysprep% mount\Windows\System32\Sysprep\


REM Save image
DISM /UNMOUNT-IMAGE /MOUNTDIR:mount /COMMIT


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
(
ECHO sel vdisk file="E:\Hyper-V\win10-test\win10-test.vhdx"
ECHO attach vdisk
ECHO clean
ECHO convert gpt
ECHO sel part 1
ECHO delete part override
ECHO create part efi size=100
ECHO format quick fs=fat32 label="win10-efi"
ECHO assign letter=O
ECHO create part msr size=16
ECHO create part pri
ECHO format quick fs=ntfs label="win10-system"
ECHO assign letter=F
ECHO shrink minimum=450
ECHO create part pri size=450
ECHO format quick fs=ntfs label="win10-recovery"
ECHO set id="de94bba4-06d1-4d40-a16a-bfd50179d6ac"
ECHO exit
) | diskpart

DISM /APPLY-IMAGE /IMAGEFILE:install.wim /NAME:"Windows 10 Pro" /APPLYDIR:F:\

CD /D F:\Windows\System32
bcdboot F:\Windows /s O: /f UEFI
REM bcdedit /set {default} description "Windows 10 Pro"

(
ECHO remove letter=O
ECHO sel vdisk file="E:\Hyper-V\win10-test\win10-test.vhdx"
ECHO detach vdisk
ECHO exit
) | diskpart

GOTO exitVHD

:noVHD
ECHO No VHD
:exitVHD