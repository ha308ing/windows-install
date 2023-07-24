setlocal enabledelayedexpansion
@REM %1 - mount dir
@REM %2 - unattend.xml for panther

set "_target=%1"
if "%_target%" equ "" call :inputTarget
set "_target="%_target:"=%""
dir /b /a:d %_target%
if errorlevel 1 (
  echo Mount dir not found. Try another..
  call  :inputTarget
)
set "_pantherDir="%_target:"=%\Windows\Panther""
if not exist %_pantherDir%  mkdir %_pantherDir%
set "_target="%_pantherDir:"=%\unattend.xml""

set "_source=%2"
if "%_source%" equ "" call :inputSource
set "_source="%_source:"=%""
call :checkXml %_source%
if errorlevel 1 (
  echo File must be .xml. Try another..
  goto :inputSource
)
if not exist %_source% (
  echo File is not found. Try another..
  call :inputSource
)

copy /y %_source% %_target%
exit /b

:inputSource
:askSource
set /p "_source=Enter path to xml file to copy to Panther: " || goto :askSource
set "_source="%_source:"=%""
call :checkXml %_source%
if errorlevel 1 (
  echo File must be .xml. Try another..
  goto :askSource
)
if not exist %_source% (
  echo File is not found. Try another..
  goto :askSource
)
exit /b

:inputTarget
:askTarget
set /p "_target=Enter path to mount dir: " || goto :askTarget
exit /b

:checkFile 
dir /b /a:-d %1
exit /b

:checkXml
echo %1| findstr /ir "\.xml""$"
exit /b
