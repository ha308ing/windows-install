setlocal enabledelayedexpansion
@REM %1 - iso dir

set "_isoDir=%1"
if "%_isoDir%" equ "" (
  goto :setISODir
) else (
  goto :checkISODir
)
:setISODir
:askISODir
set /p "_isoDir=Enter path to iso dir: " || goto :askISODir
:checkISODir
set "_isoDir="%_isoDir:"=%""
dir /b /a:d %_isoDir%
if errorlevel 1 goto :askISODir
@REM ask for path to oscdimg?
set "_oscdimgPath=%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
if not exist %_oscdimgPath% goto :noISO
set "PATH=%PATH%;%_oscdimgPath%"
set
set "_etfsboot="%_isoDir:"=%\boot\etfsboot.com""
set "_efisys="%_isoDir:"=%\efi\microsoft\boot\efisys.bin""
set "_source=%_isoDir%"
:askISOName
set /p "_target=Enter path to target iso: " || goto :askISOName
set "_target="%_target:"=%""
echo %_target%| findstr /ir "\.iso""$"
if errorlevel 1 (
  echo Target file should have iso extension..
  goto :askISOName
)
if exist %_target% (
  choice /c yn /m "ISO file already exist"
  if errorlevel 2 goto :askISOName
  if errorlevel 1 (
    del /q /f %_target%
    goto :setISOLabel
  )
)
:setISOLabel
set /p "_label=Enter iso label: " || goto :setISOLabel
set "_label="%_label:"=%""
oscdimg.exe -h -m -o -u2 -udfver102 -bootdata:2#p0,e,b%_etfsboot%#pEF,e,b%_efisys% -l%_label% %_source% %_target%
if errorlevel 1 call :retryISO
if not exist %_target% call :retryISO
echo ISO created successfully..

choice /c yn /m "Remove iso dir?"
if errorlevel 2 goto :noISODirRemove
if errorlevel 1 goto :yesISODirRemove
:yesISODirRemove
rmdir /s /q %_isoDir%
@REM RMDIR /S /Q images/original
:noISODirRemove
:noIso
exit /b

:retryISO
echo Failed to create ISO..
set "_isoDir="
set "_target="
set "_label="
goto :askISODir
exit /b
