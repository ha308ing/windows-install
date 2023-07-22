setlocal enabledelayedexpansion
@REM %1 - %_mountDir%
@REM ===========================================================================
set _mountDir=%1
if "%_mountDir%" equ "" call :askMountDir
echo DISM image servicing..
echo Image international servicing..
:setTimezone
dism /image:%_mountDir% /set-timezone:"Russian Standard Time"
if errorlevel 1 (
  echo Failed to set timezone..
    goto :setTimezone
) else ( echo Timezone set.. ) 
:setInputLocale
dism /image:%_mountDir% /set-inputlocale:en-US;ru-RU
if errorlevel 1 (
  echo Failed to set input locale..
    goto :setInputLocale
) else ( echo Input locale set.. ) 
:setSysLocale
dism /image:%_mountDir% /set-syslocale:ru-RU
if errorlevel 1 (
  echo Failed to set system locale..
    goto :setSysLocale
) else ( echo System locale set.. )
:setUserLocale
dism /image:%_mountDir% /set-userlocale:ru-RU
if errorlevel 1 (
  echo Failed to set user locale..
    goto :setUserLocale
) else ( echo User locale set.. ) 
exit /b

:askMountDir
set /p "_mountDir=Enter path to mount dir: " || goto :askMountDir
set "_mountDir="%_mountDir:"=%""
:checkMountDir
dir /b /a:d %_mountDir%
if %errorlevel% equ 0 exit /b
echo Dir not found. Try another..
goto :askMountDir
exit /b