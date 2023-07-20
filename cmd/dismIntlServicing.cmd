
@REM %1 - %_mountDir%
@REM ===========================================================================
if "%1" equ "" (
  echo Provide mount dir..
  exit /b 1
)
echo DISM image servicing..
echo Image international servicing..
:setTimezone
dism /image:%1 /set-timezone:"Russian Standard Time"
if errorlevel 1 (
  echo Failed to set timezone..
    goto :setTimezone
) else ( echo Timezone set.. ) 
:setInputLocale
dism /image:%1 /set-inputlocale:en-US;ru-RU
if errorlevel 1 (
  echo Failed to set input locale..
    goto :setInputLocale
) else ( echo Input locale set.. ) 
:setSysLocale
dism /image:%1 /set-syslocale:ru-RU
if errorlevel 1 (
  echo Failed to set system locale..
    goto :setSysLocale
) else ( echo System locale set.. )
:setUserLocale
dism /image:%1 /set-userlocale:ru-RU
if errorlevel 1 (
  echo Failed to set user locale..
    goto :setUserLocale
) else ( echo User locale set.. ) 
exit /b
